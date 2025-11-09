<?php
// db.php — geliştirilmiş PDO bağlantısı ve yardımcı fonksiyonlar

// Ortam değişkenleri
define('DB_HOST', getenv('DB_HOST') ?: '127.0.0.1');
define('DB_NAME', getenv('DB_NAME') ?: 'dolap_db');
define('DB_USER', getenv('DB_USER') ?: 'root');
define('DB_PASS', getenv('DB_PASS') ?: '');

function pdo()
{
    static $pdo = null;
    if ($pdo === null) {
        // PDO driver kontrolü
        if (!extension_loaded('pdo_mysql')) {
            die(json_encode(['success' => false, 'message' => "PDO MySQL driver yüklü değil"]));
        }

        $dsn = 'mysql:host=' . DB_HOST . ';dbname=' . DB_NAME . ';charset=utf8mb4';
        try {
            $pdo = new PDO($dsn, DB_USER, DB_PASS, [
                PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
                PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
                PDO::ATTR_EMULATE_PREPARES => false,
            ]);
        } catch (PDOException $e) {
            error_log("Database connection failed: " . $e->getMessage());
            die(json_encode(['success' => false, 'message' => "Veritabanına bağlanılamadı"]));
        }
    }
    return $pdo;
}

// Malzeme id getirir; yoksa oluşturur
function get_or_create_ingredient_id($name)
{
    $name = trim($name);
    if ($name === '') return null;

    $pdo = pdo();
    $stmt = $pdo->prepare("SELECT id FROM ingredients WHERE name = ?");
    $stmt->execute([$name]);
    $row = $stmt->fetch();

    if ($row) return (int) $row['id'];

    $stmt = $pdo->prepare("INSERT INTO ingredients (name) VALUES (?)");
    $stmt->execute([$name]);
    return (int) $pdo->lastInsertId();
}

// Dolaba malzeme ekle - JSON yanıt döner
function add_to_pantry($ingredient_name)
{
    $ingredient_id = get_or_create_ingredient_id($ingredient_name);
    if ($ingredient_id === null) {
        return ['success' => false, 'message' => 'Geçersiz malzeme adı'];
    }

    $pdo = pdo();
    // Aynı malzeme zaten varsa tekrar ekleme
    $exists = $pdo->prepare("SELECT 1 FROM pantry WHERE ingredient_id = ?");
    $exists->execute([$ingredient_id]);
    if ($exists->fetch()) {
        return ['success' => true, 'message' => 'Malzeme zaten dolapta mevcut'];
    }

    $stmt = $pdo->prepare("INSERT INTO pantry (ingredient_id) VALUES (?)");
    $success = $stmt->execute([$ingredient_id]);

    return [
        'success' => $success,
        'message' => $success ? 'Malzeme dolaba eklendi' : 'Malzeme eklenemedi'
    ];
}

// Dolaptan malzeme sil - JSON yanıt döner
function delete_pantry_item($id)
{
    $pdo = pdo();
    $stmt = $pdo->prepare("DELETE FROM pantry WHERE id = ?");
    $success = $stmt->execute([(int) $id]);

    return [
        'success' => $success,
        'message' => $success ? 'Malzeme silindi' : 'Malzeme silinemedi'
    ];
}

// Dolabı temizle - JSON yanıt döner
function clear_pantry()
{
    $pdo = pdo();
    $stmt = $pdo->prepare("DELETE FROM pantry");
    $stmt->execute();
    $count = $stmt->rowCount();

    return [
        'success' => true,
        'message' => "{$count} malzeme silindi"
    ];
}

// Dolap listesini getir
function list_pantry()
{
    $pdo = pdo();
    $sql = "SELECT p.id, i.name, p.added_at
            FROM pantry p
            JOIN ingredients i ON i.id = p.ingredient_id
            ORDER BY i.name ASC";
    return $pdo->query($sql)->fetchAll();
}

// Dolaptaki malzeme isimlerini getir
function list_pantry_names()
{
    $rows = list_pantry();
    return array_map(fn($r) => $r['name'], $rows);
}

// Tüm malzemeleri getir
function get_all_ingredients()
{
    $pdo = pdo();
    $stmt = $pdo->prepare("
        SELECT name, 
               (SELECT COUNT(*) FROM pantry WHERE ingredient_id = ingredients.id) as count
        FROM ingredients 
        ORDER BY count DESC, name ASC
    ");
    $stmt->execute();
    return $stmt->fetchAll();
}

// Gelişmiş tarif arama (skorlu)
function search_recipes_scored($ingredients, $min_match = 1, $search_query = '')
{
    $pdo = pdo();

    // Seçim boşsa basit listeye dön
    if (empty($ingredients)) {
        return get_all_recipes_filtered($search_query);
    }

    // Skor için CASE bloklarını tek bir yerde kur
    $score_conditions = [];
    $ing_params = [];
    foreach ($ingredients as $ingredient) {
        $score_conditions[] = "CASE WHEN r.ingredients_text LIKE ? THEN 1 ELSE 0 END";
        $ing_params[] = '%' . $ingredient . '%';
    }
    $score_sql = implode(" + ", $score_conditions);

    // İç select: score'u hesapla (PLACEHOLDER'LAR SADECE BURADA!)
    $inner = "SELECT r.*, ($score_sql) AS score FROM recipes r";

    // Dış select: filtre ve sıralama (YENİ PLACEHOLDER YOK)
    $sql = "SELECT * FROM (" . $inner . ") t WHERE t.score >= " . (int)$min_match;

    $search_params = [];
    if (!empty($search_query)) {
        $sql .= " AND (t.title LIKE ? OR t.ingredients_text LIKE ? OR t.tags LIKE ?)";
        $sp = '%' . $search_query . '%';
        $search_params = [$sp, $sp, $sp];
    }

    $sql .= " ORDER BY t.score DESC, t.title ASC LIMIT 100";

    // Parametreler: malzeme LIKE'ları (N) + arama (0 veya 3)
    $params = array_merge($ing_params, $search_params);

    $stmt = $pdo->prepare($sql);
    $stmt->execute($params);
    return $stmt->fetchAll();
}



// Filtreli tüm tarifleri getir
function get_all_recipes_filtered($search_query = '')
{
    $pdo = pdo();

    if (empty($search_query)) {
        $sql = "SELECT id, title, ingredients_text, instructions, prep_minutes, calories, difficulty, tags, image_url
                FROM recipes 
                ORDER BY title ASC
                LIMIT 100";
        $stmt = $pdo->prepare($sql);
        $stmt->execute();
    } else {
        $sql = "SELECT id, title, ingredients_text, instructions, prep_minutes, calories, difficulty, tags, image_url
                FROM recipes 
                WHERE title LIKE ? OR ingredients_text LIKE ? OR tags LIKE ?
                ORDER BY title ASC
                LIMIT 100";
        $search_param = '%' . $search_query . '%';
        $stmt = $pdo->prepare($sql);
        $stmt->execute([$search_param, $search_param, $search_param]);
    }

    return $stmt->fetchAll();
}

// Tüm tarifleri getir
function get_all_recipes()
{
    $pdo = pdo();
    $stmt = $pdo->prepare("
        SELECT id, title, ingredients_text, instructions, prep_minutes, calories, difficulty, tags, image_url
        FROM recipes 
        ORDER BY title ASC
        LIMIT 100
    ");
    $stmt->execute();
    return $stmt->fetchAll();
}

// Recipe_ingredients tablosu için yardımcı fonksiyon
function get_recipe_ingredients($recipe_id)
{
    $pdo = pdo();
    $stmt = $pdo->prepare("
        SELECT i.name 
        FROM recipe_ingredients ri 
        JOIN ingredients i ON ri.ingredient_id = i.id 
        WHERE ri.recipe_id = ?
    ");
    $stmt->execute([$recipe_id]);
    return $stmt->fetchAll(PDO::FETCH_COLUMN);
}

// Favori kontrolü
function is_recipe_favorite($session_id, $recipe_id)
{
    $pdo = pdo();
    $stmt = $pdo->prepare("
        SELECT 1 FROM user_favorites 
        WHERE session_id = ? AND recipe_id = ?
    ");
    $stmt->execute([$session_id, $recipe_id]);
    return (bool) $stmt->fetch();
}

// Favori ekle/çıkar
function toggle_favorite($session_id, $recipe_id)
{
    $pdo = pdo();

    // Önce var mı kontrol et
    $exists = is_recipe_favorite($session_id, $recipe_id);

    if ($exists) {
        $stmt = $pdo->prepare("DELETE FROM user_favorites WHERE session_id = ? AND recipe_id = ?");
        $stmt->execute([$session_id, $recipe_id]);
        return 'removed';
    } else {
        $stmt = $pdo->prepare("INSERT INTO user_favorites (session_id, recipe_id) VALUES (?, ?)");
        $stmt->execute([$session_id, $recipe_id]);
        return 'added';
    }
}

// Kullanıcı favorilerini getir
function get_user_favorites($session_id)
{
    $pdo = pdo();
    $stmt = $pdo->prepare("
        SELECT r.* 
        FROM user_favorites uf
        JOIN recipes r ON uf.recipe_id = r.id
        WHERE uf.session_id = ?
        ORDER BY uf.created_at DESC
    ");
    $stmt->execute([$session_id]);
    return $stmt->fetchAll();
}

// Malzeme önerileri getir (autocomplete için)
function get_ingredient_suggestions($query)
{
    $pdo = pdo();
    $stmt = $pdo->prepare("
        SELECT name 
        FROM ingredients 
        WHERE name LIKE ? 
        ORDER BY 
            CASE WHEN name = ? THEN 1 
                 WHEN name LIKE ? THEN 2 
                 ELSE 3 
            END,
            name ASC
        LIMIT 10
    ");

    $searchTerm = $query . '%';
    $exactTerm = $query;
    $containsTerm = '%' . $query . '%';

    $stmt->execute([$searchTerm, $exactTerm, $containsTerm]);
    return $stmt->fetchAll(PDO::FETCH_COLUMN);
}

// İstatistikler
function get_stats()
{
    $pdo = pdo();

    $stats = [
        'total_recipes' => $pdo->query("SELECT COUNT(*) FROM recipes")->fetchColumn(),
        'total_ingredients' => $pdo->query("SELECT COUNT(*) FROM ingredients")->fetchColumn(),
        'popular_ingredients' => $pdo->query("
            SELECT i.name, COUNT(ri.recipe_id) as usage_count
            FROM ingredients i
            LEFT JOIN recipe_ingredients ri ON i.id = ri.ingredient_id
            GROUP BY i.id
            ORDER BY usage_count DESC
            LIMIT 5
        ")->fetchAll()
    ];

    return $stats;
}

// Tarif ekleme fonksiyonu (ileride kullanım için)
function add_recipe($title, $ingredients_text, $instructions, $prep_minutes = null, $calories = null, $tags = null, $image_url = null)
{
    $pdo = pdo();

    $stmt = $pdo->prepare("
        INSERT INTO recipes (title, ingredients_text, instructions, prep_minutes, calories, tags, image_url) 
        VALUES (?, ?, ?, ?, ?, ?, ?)
    ");

    $stmt->execute([
        $title,
        $ingredients_text,
        $instructions,
        $prep_minutes,
        $calories,
        $tags,
        $image_url
    ]);

    return $pdo->lastInsertId();
}

// Basit tarif arama (yedek fonksiyon)
function search_recipes($names)
{
    if (!$names)
        return get_all_recipes();

    $pdo = pdo();

    $wheres = [];
    $params = [];
    foreach ($names as $n) {
        $wheres[] = "ingredients_text LIKE ?";
        $params[] = '%' . $n . '%';
    }

    $sql = "SELECT id, title, ingredients_text, instructions, prep_minutes, calories, tags, image_url
            FROM recipes
            WHERE " . implode(" AND ", $wheres) . "
            ORDER BY title ASC
            LIMIT 100";

    $stmt = $pdo->prepare($sql);
    $stmt->execute($params);
    return $stmt->fetchAll();
}

// Yardımcı fonksiyonlar
if (!function_exists('norm')) {
    function norm($s)
    {
        $s = mb_strtolower(trim($s), 'UTF-8');
        $tr = ['ı' => 'i', 'İ' => 'i', 'ç' => 'c', 'ğ' => 'g', 'ö' => 'o', 'ş' => 's', 'ü' => 'u'];
        return strtr($s, $tr);
    }
}

if (!function_exists('parse_ingredients_text')) {
    function parse_ingredients_text($text)
    {
        $text = norm($text);
        $parts = preg_split('/[,;|\n]+/u', $text);
        $out = [];
        foreach ($parts as $p) {
            $p = trim($p);
            if ($p !== '') $out[] = $p;
        }
        return array_values(array_unique($out));
    }
}

// Veritabanı bağlantı testi
function test_db_connection()
{
    try {
        $pdo = pdo();
        $stmt = $pdo->query("SELECT 1");
        return $stmt->fetch() ? true : false;
    } catch (Exception $e) {
        return false;
    }
}

// Tablo var mı kontrol et
function check_tables_exist()
{
    $pdo = pdo();
    $tables = ['ingredients', 'recipes', 'recipe_ingredients', 'pantry', 'user_favorites'];
    $existing_tables = [];

    foreach ($tables as $table) {
        $stmt = $pdo->prepare("SHOW TABLES LIKE ?");
        $stmt->execute([$table]);
        if ($stmt->fetch()) {
            $existing_tables[] = $table;
        }
    }

    return $existing_tables;
}

// Veritabanı durum raporu
function get_database_status()
{
    $status = [
        'connection' => test_db_connection(),
        'tables' => check_tables_exist(),
        'stats' => get_stats()
    ];

    return $status;
}
