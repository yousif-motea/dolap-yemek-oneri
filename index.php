<?php
// index.php – Akıllı Yemek Öneri Sistemi (Modern Versiyon)
session_start();
header_remove("X-Powered-By");

require_once __DIR__ . '/db.php';

// Basit CSRF
if (empty($_SESSION['csrf'])) {
    $_SESSION['csrf'] = bin2hex(random_bytes(16));
}
$csrf = $_SESSION['csrf'];

function verify_csrf($token)
{
    return hash_equals($_SESSION['csrf'] ?? '', $token ?? '');
}

// Yardımcılar
function json_response($arr, $status = 200)
{
    http_response_code($status);
    header('Content-Type: application/json; charset=utf-8');
    echo json_encode($arr, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
    exit;
}

// Oturum kimliği (favoriler için)
$session_id = session_id();

// ---- AJAX/API Router ----
$method = $_SERVER['REQUEST_METHOD'];
$action = $_REQUEST['action'] ?? null;

// GET /?action=get_pantry
if ($method === 'GET' && $action === 'get_pantry') {
    $pantry = list_pantry();
    json_response(['success' => true, 'pantry' => $pantry]);
}

// GET /?action=get_favorites
if ($method === 'GET' && $action === 'get_favorites') {
    $fav_recipes = get_user_favorites($session_id);
    $pantry_names = list_pantry_names();
    $out = [];
    foreach ($fav_recipes as $r) {
        $ings = get_recipe_ingredients($r['id']);
        $have = array_values(array_intersect($ings, $pantry_names));
        $missing = array_values(array_diff($ings, $pantry_names));
        $pct = (count($ings) ? (int)round(count($have) * 100 / count($ings)) : 0);
        $out[] = [
            'id' => (int)$r['id'],
            'title' => $r['title'],
            'ingredients_text' => $r['ingredients_text'] ?? '',
            'instructions' => $r['instructions'] ?? '',
            'prep_minutes' => $r['prep_minutes'] ?? null,
            'calories' => $r['calories'] ?? null,
            'difficulty' => $r['difficulty'] ?? null,
            'tags' => $r['tags'] ?? null,
            'image_url' => $r['image_url'] ?? null,
            'ingredients_have' => $have,
            'ingredients_missing' => $missing,
            'match_percentage' => max(0, min(100, $pct)),
            'is_complete' => count($missing) === 0,
            'is_favorite' => true
        ];
    }
    json_response(['success' => true, 'recipes' => $out]);
}

// GET /?action=search_recipes
if ($method === 'GET' && $action === 'search_recipes') {
    $selected = array_map('trim', $_GET['ingredients'] ?? []);
    $min_match = (int)($_GET['min_match'] ?? 1);
    $q = trim($_GET['q'] ?? '');

    $recipes = search_recipes_scored($selected, $min_match, $q);
    $pantry_names = list_pantry_names();
    $out = [];

    foreach ($recipes as $r) {
        $ings = get_recipe_ingredients($r['id']);
        $have = array_values(array_intersect($ings, $pantry_names));
        $missing = array_values(array_diff($ings, $pantry_names));

        if (isset($r['match_percentage'])) {
            $pct = (int)$r['match_percentage'];
        } else if (!empty($selected)) {
            $have_sel = array_values(array_intersect($ings, $selected));
            $pct = count($ings) ? (int)round(count($have_sel) * 100 / count($ings)) : 0;
        } else {
            $pct = count($ings) ? (int)round(count($have) * 100 / count($ings)) : 0;
        }

        $out[] = [
            'id' => (int)$r['id'],
            'title' => $r['title'],
            'ingredients_text' => $r['ingredients_text'] ?? '',
            'instructions' => $r['instructions'] ?? '',
            'prep_minutes' => $r['prep_minutes'] ?? null,
            'calories' => $r['calories'] ?? null,
            'difficulty' => $r['difficulty'] ?? null,
            'tags' => $r['tags'] ?? null,
            'image_url' => $r['image_url'] ?? null,
            'ingredients_have' => $have,
            'ingredients_missing' => $missing,
            'match_percentage' => max(0, min(100, $pct)),
            'is_complete' => count($missing) === 0,
            'is_favorite' => is_recipe_favorite($session_id, $r['id'])
        ];
    }
    json_response(['success' => true, 'recipes' => $out]);
}

// POST işlemleri (CSRF zorunlu)
if ($method === 'POST') {
    $token = $_POST['csrf'] ?? '';
    if (!verify_csrf($token)) {
        json_response(['success' => false, 'message' => 'Geçersiz CSRF'], 400);
    }

    if ($action === 'add_pantry') {
        $name = trim($_POST['ingredient'] ?? '');
        $res = add_to_pantry($name);
        $res['pantry'] = list_pantry();
        json_response($res);
    }

    if ($action === 'delete_pantry') {
        $id = (int)($_POST['delete_id'] ?? 0);
        $res = delete_pantry_item($id);
        $res['pantry'] = list_pantry();
        json_response($res);
    }

    if ($action === 'clear_pantry') {
        $res = clear_pantry();
        $res['pantry'] = list_pantry();
        json_response($res);
    }

    if ($action === 'toggle_favorite') {
        $recipe_id = (int)($_POST['recipe_id'] ?? 0);
        $act = toggle_favorite($session_id, $recipe_id);
        json_response(['success' => true, 'action' => $act]);
    }

    json_response(['success' => false, 'message' => 'Bilinmeyen işlem'], 404);
}

// ---- Sayfa render (SSR) ----
$q = trim($_GET['q'] ?? '');
$min_match = (int)($_GET['min_match'] ?? 1);
$selected_ingredients = $_GET['ingredients'] ?? [];

$stats = get_stats();
$pantry = list_pantry();
$pantry_names = list_pantry_names();
$all_ingredients = get_all_ingredients();
?>
<!doctype html>
<html lang="tr">

<head>
    <meta charset="utf-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>PİŞİRİO - Akıllı Yemek Öneri Sistemi</title>
    <meta name="description" content="Dolabınızdaki malzemelerle yapabileceğiniz tarifleri keşfedin">
    <link rel="preconnect" href="https://fonts.googleapis.com" />
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin />
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.0/css/all.min.css" />
    <link rel="stylesheet" href="styles.css" />
</head>

<body>
    <div class="container">
        <!-- Header -->
        <header class="header">
            <div class="header-top">
                <div class="logo">
                    <i class="fas fa-utensils"></i>
                    <h1>PİŞİRİO</h1>
                </div>
                <div class="header-actions">
                    <button class="btn btn-secondary theme-toggle">
                        <i class="fas fa-moon"></i> Tema
                    </button>
                    <a class="btn btn-primary" href="?">
                        <i class="fas fa-rotate"></i> Yenile
                    </a>
                </div>
            </div>
            <p class="tagline">Dolabındaki malzemelerle anında yemek tarifi önerisi al</p>
        </header>

        <!-- Quick Actions -->
        <div class="quick-actions">
            <button class="action-card">
                <i class="fas fa-shopping-cart"></i>
                <span>Alışveriş Listesi</span>
            </button>
            <button class="action-card">
                <i class="fas fa-calendar-alt"></i>
                <span>Yemek Planla</span>
            </button>
            <button class="action-card">
                <i class="fas fa-heart"></i>
                <span>Favorilerim</span>
            </button>
            <button class="action-card">
                <i class="fas fa-random"></i>
                <span>Rastgele Tarif</span>
            </button>
        </div>

        <!-- Main Layout -->
        <div class="main-layout">
            <!-- Sidebar -->
            <aside class="sidebar">
                <!-- Malzeme Ekle -->
                <section class="card">
                    <h2><i class="fas fa-plus-circle"></i> Malzeme Ekle</h2>
                    <form method="post" class="add-form" id="pantryForm">
                        <input type="hidden" name="csrf" value="<?= htmlspecialchars($csrf) ?>" />
                        <input type="hidden" name="action" value="add_pantry" />
                        <div class="input-group">
                            <input type="text" name="ingredient" placeholder="örn. domates, soğan..." required autocomplete="off" />
                            <button type="submit" class="btn btn-primary">
                                <i class="fas fa-plus"></i>
                            </button>
                        </div>
                    </form>
                    <div class="help-text">
                        <i class="fas fa-lightbulb"></i> Malzemeleri sürükleyip dolap alanına bırakabilirsiniz
                    </div>
                </section>

                <!-- Malzeme Seçimi -->
                <section class="card">
                    <div class="card-header">
                        <h2><i class="fas fa-check-circle"></i> Malzeme Seçimi</h2>
                        <div class="card-actions">
                            <a href="?" class="btn btn-sm btn-secondary">Sıfırla</a>
                        </div>
                    </div>
                    <p class="help-text">
                        <i class="fas fa-info-circle"></i> Tarif aramak için malzemeleri seçin
                    </p>

                    <form method="get" class="ingredient-selector" id="ingredientForm">
                        <input type="hidden" name="min_match" id="min_match" value="<?= (int)$min_match ?>" />
                        <input type="hidden" name="q" id="q" value="<?= htmlspecialchars($q) ?>" />

                        <div class="ingredient-grid">
                            <?php foreach ($all_ingredients as $ingredient):
                                $isSelected = in_array($ingredient['name'], (array)$selected_ingredients, true);
                                $isInPantry = in_array($ingredient['name'], $pantry_names, true);
                            ?>
                                <label class="ingredient-checkbox <?= $isSelected ? 'selected' : '' ?>"
                                    draggable="true"
                                    title="Sürükleyip dolaba bırakın">
                                    <input type="checkbox"
                                        name="ingredients[]"
                                        value="<?= htmlspecialchars($ingredient['name']) ?>"
                                        <?= $isSelected ? 'checked' : '' ?> />
                                    <span class="checkmark"></span>
                                    <?= htmlspecialchars($ingredient['name']) ?>
                                    <span class="ingredient-count"><?= (int)$ingredient['count'] ?></span>
                                </label>
                            <?php endforeach; ?>
                        </div>
                    </form>
                </section>

                <!-- Dolabım -->
                <section class="card">
                    <div class="card-header">
                        <h2><i class="fas fa-clipboard-list"></i> Dolabım</h2>
                        <?php if ($pantry): ?>
                            <form method="post" class="inline-form">
                                <input type="hidden" name="csrf" value="<?= htmlspecialchars($csrf) ?>" />
                                <input type="hidden" name="action" value="clear_pantry" />
                                <button type="submit" class="btn btn-sm btn-danger" onclick="return confirm('Tüm malzemeleri silmek istediğinizden emin misiniz?')">
                                    <i class="fas fa-trash"></i>
                                </button>
                            </form>
                        <?php endif; ?>
                    </div>

                    <?php if ($pantry): ?>
                        <div class="pantry-list">
                            <?php foreach ($pantry as $p): ?>
                                <div class="pantry-item">
                                    <span class="pantry-name"><?= htmlspecialchars($p['name']) ?></span>
                                    <form method="post" class="inline-form">
                                        <input type="hidden" name="csrf" value="<?= htmlspecialchars($csrf) ?>" />
                                        <input type="hidden" name="action" value="delete_pantry" />
                                        <input type="hidden" name="delete_id" value="<?= (int)$p['id'] ?>" />
                                        <button type="submit" class="btn-icon delete-pantry" title="Sil">
                                            <i class="fas fa-times"></i>
                                        </button>
                                    </form>
                                </div>
                            <?php endforeach; ?>
                        </div>
                    <?php else: ?>
                        <div class="empty-state">
                            <i class="fas fa-inbox"></i>
                            <p>Henüz malzeme eklemediniz.</p>
                            <p class="help-text">Yukarıdan malzeme ekleyin</p>
                        </div>
                    <?php endif; ?>
                </section>

                <!-- İstatistikler -->
                <section class="card">
                    <h2><i class="fas fa-chart-bar"></i> İstatistikler</h2>
                    <div class="stats-grid">
                        <div class="stat-item">
                            <div class="stat-value"><?= (int)$stats['total_recipes'] ?></div>
                            <div class="stat-label">Toplam Tarif</div>
                        </div>
                        <div class="stat-item">
                            <div class="stat-value"><?= (int)$stats['total_ingredients'] ?></div>
                            <div class="stat-label">Toplam Malzeme</div>
                        </div>
                    </div>
                </section>
            </aside>

            <!-- Ana İçerik -->
            <main>
                <!-- Sonuçlar Header -->
                <section class="card results-header">
                    <h2>
                        <i class="fas fa-bowl-food"></i> Önerilen Tarifler
                        <span class="results-count">(…)</span>
                    </h2>
                    <?php if (!empty($selected_ingredients)): ?>
                        <div class="selected-indicator">
                            <strong>Seçili Malzemeler:</strong>
                            <?php foreach ($selected_ingredients as $ing): ?>
                                <span class="selected-tag">
                                    <?= htmlspecialchars($ing) ?>
                                    <span class="remove" onclick="removeIngredient('<?= htmlspecialchars($ing) ?>')">×</span>
                                </span>
                            <?php endforeach; ?>
                        </div>
                    <?php endif; ?>
                </section>

                <!-- Filtreler -->
                <section class="card">
                    <div class="filters">
                        <div class="search-box">
                            <i class="fas fa-search"></i>
                            <input id="searchInput"
                                type="text"
                                placeholder="Tarif, malzeme veya etiket ara…"
                                value="<?= htmlspecialchars($q) ?>" />
                        </div>
                        <form id="searchForm" class="filter-form">
                            <div class="filter-group-inline">
                                <label class="filter-label-inline">
                                    <i class="fas fa-equals"></i> Min eşleşen
                                </label>
                                <select id="min_match" name="min_match">
                                    <option value="1" <?= $min_match == 1 ? 'selected' : ''; ?>>1</option>
                                    <option value="2" <?= $min_match == 2 ? 'selected' : ''; ?>>2</option>
                                    <option value="3" <?= $min_match == 3 ? 'selected' : ''; ?>>3</option>
                                    <option value="4" <?= $min_match == 4 ? 'selected' : ''; ?>>4</option>
                                    <option value="5" <?= $min_match == 5 ? 'selected' : ''; ?>>5</option>
                                </select>
                            </div>
                        </form>
                    </div>

                    <!-- Tarifler Grid -->
                    <div class="recipes-grid" id="recipesGrid">
                        <div class="empty-state large">
                            <i class="fas fa-spinner fa-spin"></i>
                            <h3>Tarifler yükleniyor</h3>
                            <p>Lütfen bekleyin</p>
                        </div>
                    </div>
                </section>
            </main>
        </div>

        <!-- Footer -->
        <footer class="footer">
            <p>
                PİŞİRİO - Akıllı Yemek Öneri Sistemi &copy; <?= date('Y') ?> |
                <span id="stats"><?= (int)$stats['total_recipes'] ?> tarif, <?= (int)$stats['total_ingredients'] ?> malzeme</span>
            </p>
        </footer>
    </div>

    <!-- Notification -->
    <div class="notification"></div>

    <!-- Scripts -->
    <script src="app.js"></script>
    <script>
        // Malzeme kaldırma fonksiyonu
        function removeIngredient(ingredient) {
            const form = document.getElementById('ingredientForm');
            const checkboxes = form.querySelectorAll('input[name="ingredients[]"]');
            checkboxes.forEach(cb => {
                if (cb.value === ingredient) {
                    cb.checked = false;
                    cb.parentElement.classList.remove('selected');
                }
            });
            app.updateRecipes();
        }

        // Checkbox seçimi görsel güncelleme
        document.addEventListener('DOMContentLoaded', function() {
            document.querySelectorAll('.ingredient-checkbox input').forEach(checkbox => {
                checkbox.addEventListener('change', function() {
                    this.parentElement.classList.toggle('selected', this.checked);
                });
            });
        });
    </script>
</body>

</html>