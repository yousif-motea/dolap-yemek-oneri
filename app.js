// app.js — gelişmiş istemci (İyileştirilmiş Sürüm)
class SmartRecipeApp {
  constructor() {
    this.favorites = JSON.parse(localStorage.getItem("recipe_favorites")) || [];
    this.shoppingList =
      JSON.parse(localStorage.getItem("recipe_shopping_list")) || [];
    this.mealPlan = JSON.parse(localStorage.getItem("recipe_meal_plan")) || {};
    this.theme = localStorage.getItem("recipe_theme") || "light";
    this.currentView = "recipes";
    this.init();
  }

  init() {
    this.initTheme();
    this.initEventListeners();
    this.initDragAndDrop(); // <-- YENİ: Fonksiyon artık çalışıyor
    this.initAdvancedFilters();
    this.initNotifications();
    this.updateFavoriteButtons();
    this.loadInitialData();
  }

  // Tema
  initTheme() {
    document.documentElement.setAttribute("data-theme", this.theme);
    const themeToggle = document.querySelector(".theme-toggle");
    const themeIcon = themeToggle?.querySelector("i");
    if (themeIcon)
      themeIcon.className =
        this.theme === "dark" ? "fas fa-sun" : "fas fa-moon";
    themeToggle?.addEventListener("click", () => this.toggleTheme());
  }
  toggleTheme() {
    this.theme = this.theme === "light" ? "dark" : "light";
    document.documentElement.setAttribute("data-theme", this.theme);
    localStorage.setItem("recipe_theme", this.theme);
    const themeIcon = document.querySelector(".theme-toggle i");
    if (themeIcon)
      themeIcon.className =
        this.theme === "dark" ? "fas fa-sun" : "fas fa-moon";
    this.showNotification(
      `Tema ${this.theme === "dark" ? "koyu" : "açık"} moda geçirildi`,
      "info"
    );
  }

  // Events
  initEventListeners() {
    const pantryForm = document.querySelector(".add-form");
    pantryForm?.addEventListener("submit", (e) => this.handleAddToPantry(e));

    document.addEventListener("click", (e) => {
      const del = e.target.closest(".delete-pantry");
      if (del) this.handleDeletePantry(del);
    });

    document.addEventListener("click", (e) => {
      const favBtn = e.target.closest(".favorite-btn");
      if (favBtn) this.handleFavoriteToggle(favBtn);
    });

    document.addEventListener("click", (e) => {
      const actionCard = e.target.closest(".action-card");
      if (actionCard) this.handleQuickAction(actionCard);
    });

    const searchInput = document.getElementById("searchInput");
    searchInput?.addEventListener(
      "input",
      this.debounce(() => this.updateRecipes(), 400)
    );

    const minMatchSelect = document.getElementById("min_match");
    minMatchSelect?.addEventListener("change", () => this.updateRecipes());

    document.addEventListener("change", (e) => {
      if (e.target.name === "ingredients[]") this.updateRecipes();
    });
  }

  // Pantry
  async handleAddToPantry(e) {
    e.preventDefault();
    const form = e.target;
    const input = form.querySelector('input[name="ingredient"]');
    const ingredientName = input.value.trim();
    if (!ingredientName) return;

    // YENİ: Ekleme mantığı merkezi bir fonksiyona taşındı
    this.addPantryItem(ingredientName);
    input.value = ""; // Formu temizle
  }

  /**
   * YENİ: Dolaba malzeme eklemek için merkezi fonksiyon.
   * Hem form gönderimi hem de Sürükle-Bırak bunu kullanır.
   */
  async addPantryItem(name) {
    const form = document.getElementById("pantryForm"); // CSRF token'ı için formu bul
    if (!form) return;

    const formData = new FormData();
    formData.append("action", "add_pantry");
    formData.append("csrf", form.querySelector('input[name="csrf"]')?.value);
    formData.append("ingredient", name);

    try {
      const response = await fetch("index.php", {
        method: "POST",
        body: formData,
      });
      const data = await response.json();
      if (data.success) {
        this.showNotification(data.message || `${name} dolaba eklendi`);
        this.updatePantryList(data.pantry);
        this.updateRecipes();
      } else {
        throw new Error(data.message || "Malzeme eklenemedi");
      }
    } catch (err) {
      this.showNotification(`Hata: ${err.message}`, "error");
    }
  }

  async handleDeletePantry(button) {
    const form = button.closest("form");
    const ingredientName = form
      .closest(".pantry-item")
      .querySelector(".pantry-name")?.textContent;
    if (
      !confirm(
        `"${ingredientName}" malzemesini silmek istediğinizden emin misiniz?`
      )
    )
      return;
    const formData = new FormData(form);
    try {
      const response = await fetch("index.php", {
        method: "POST",
        body: formData,
      });
      const data = await response.json();
      if (data.success) {
        this.showNotification(data.message || "Malzeme dolaptan silindi");
        this.updatePantryList(data.pantry);
        this.updateRecipes();
      } else {
        throw new Error(data.message || "Malzeme silinemedi");
      }
    } catch (err) {
      this.showNotification(`Hata: ${err.message}`, "error");
    }
  }

  updatePantryList(pantryData) {
    const pantryList = document.querySelector(".pantry-list");
    const pantryCard = pantryList?.closest(".card");
    if (!pantryList || !pantryCard) return;

    // Dolap temizle butonunu yönet
    const clearButton = pantryCard.querySelector('form[action="clear_pantry"]');
    if (clearButton) {
      clearButton.style.display =
        !pantryData || pantryData.length === 0 ? "none" : "block";
    }

    if (!pantryData || pantryData.length === 0) {
      pantryList.innerHTML = `
        <div class="empty-state">
          <i class="fas fa-inbox"></i>
          <p>Henüz malzeme eklemediniz.</p>
          <p class="help-text">Yukarıdan malzeme ekleyin veya listeden sürükleyin</p>
        </div>`;
      return;
    }
    pantryList.innerHTML = pantryData
      .map(
        (item) => `
      <div class="pantry-item">
        <span class="pantry-name">${this.escapeHTML(item.name)}</span>
        <form method="post" class="inline-form">
          <input type="hidden" name="csrf" value="${
            document.querySelector('input[name="csrf"]')?.value
          }" />
          <input type="hidden" name="action" value="delete_pantry" />
          <input type="hidden" name="delete_id" value="${item.id}" />
          <button type="submit" class="btn-icon delete-pantry" title="Sil"><i class="fas fa-times"></i></button>
        </form>
      </div>`
      )
      .join("");
  }

  // Favorites
  async handleFavoriteToggle(button) {
    const recipeCard = button.closest(".recipe-card");
    const recipeId = recipeCard?.dataset.recipeId;
    if (!recipeId) return;
    const formData = new FormData();
    formData.append("action", "toggle_favorite");
    formData.append("recipe_id", recipeId);
    formData.append(
      "csrf",
      document.querySelector('input[name="csrf"]')?.value
    );
    try {
      const response = await fetch("index.php", {
        method: "POST",
        body: formData,
      });
      const data = await response.json();
      if (data.success) {
        if (data.action === "added") {
          button.classList.add("active");
          if (!this.favorites.includes(recipeId)) this.favorites.push(recipeId);
          this.showNotification("Tarif favorilere eklendi");
        } else {
          button.classList.remove("active");
          this.favorites = this.favorites.filter((id) => id !== recipeId);
          this.showNotification("Tarif favorilerden kaldırıldı");
        }
        localStorage.setItem(
          "recipe_favorites",
          JSON.stringify(this.favorites)
        );
      } else {
        throw new Error(data.message || "İşlem başarısız");
      }
    } catch (err) {
      this.showNotification(`Hata: ${err.message}`, "error");
    }
  }

  // Tarifleri getir
  async updateRecipes() {
    const form = document.getElementById("ingredientForm");
    if (!form) return;
    const formData = new FormData(form);
    const params = new URLSearchParams(formData);
    params.append("q", document.getElementById("searchInput")?.value || "");
    params.append(
      "min_match",
      document.getElementById("min_match")?.value || "1"
    );
    params.append("action", "search_recipes");
    try {
      const response = await fetch(`index.php?${params}`);
      const data = await response.json();
      if (data.success) {
        this.renderRecipes(data.recipes);
      } else {
        throw new Error(data.message || "Tarifler yüklenemedi");
      }
    } catch (err) {
      console.error("Tarifler alınamadı:", err);
      this.showNotification("Tarifler yüklenirken hata oluştu", "error");
    }
  }

  renderRecipes(recipes) {
    const recipesGrid = document.getElementById("recipesGrid");
    const resultsCount = document.querySelector(".results-count");
    if (!recipesGrid || !resultsCount) return;
    resultsCount.textContent = `(${recipes.length} bulundu)`;

    if (recipes.length === 0) {
      recipesGrid.innerHTML = `
        <div class="empty-state large">
          <i class="fas fa-search"></i>
          <h3>Tarif bulunamadı</h3>
          <p>Farklı malzemeler seçerek veya arama terimini değiştirerek tekrar deneyin.</p>
          <button class="btn btn-primary" onclick="app.updateRecipes()"><i class="fas fa-rotate"></i> Yenile</button>
        </div>`;
      return;
    }

    recipesGrid.innerHTML = recipes
      .map(
        (recipe) => `
      <div class="recipe-card ${recipe.is_complete ? "complete" : ""}" 
           data-recipe-id="${recipe.id}"
           data-prep-time="${recipe.prep_minutes || ""}"
           data-calories="${recipe.calories || ""}"
           data-difficulty="${recipe.difficulty || ""}">
        <div class="recipe-header">
          <h3 class="recipe-title">${this.escapeHTML(recipe.title)}</h3>
          <div class="recipe-actions">
            <button class="favorite-btn btn-icon ${
              recipe.is_favorite ? "active" : ""
            }" title="Favorilere Ekle">
              <i class="fas fa-heart"></i>
            </button>
          </div>
          <div class="recipe-meta">
            <div class="match-score">
              <div class="score-circle" style="--percentage: ${
                recipe.match_percentage
              }%; --color: ${
          recipe.match_percentage >= 80
            ? "#10b981"
            : recipe.match_percentage >= 50
            ? "#f59e0b"
            : "#ef4444"
        }">
                <span>${recipe.match_percentage}%</span>
              </div>
              <small>Eşleşme</small>
            </div>
            ${
              recipe.is_complete
                ? '<div class="complete-badge"><i class="fas fa-check-circle"></i> Tam Malzeme</div>'
                : ""
            }
          </div>
        </div>
        ${
          recipe.image_url
            ? `<div class="recipe-image"><img src="${this.escapeHTML(
                recipe.image_url
              )}" alt="${this.escapeHTML(recipe.title)}" /></div>`
            : ""
        }
        <div class="recipe-info">
          <div class="info-grid">
            ${
              recipe.prep_minutes
                ? `<div class="info-item"><i class="fas fa-clock"></i><span>${recipe.prep_minutes} dk</span></div>`
                : ""
            }
            ${
              recipe.calories
                ? `<div class="info-item"><i class="fas fa-fire"></i><span>${recipe.calories} kcal</span></div>`
                : ""
            }
            ${
              recipe.difficulty
                ? `<div class="info-item"><i class="fas fa-signal"></i><span class="difficulty-badge ${recipe.difficulty}">${recipe.difficulty}</span></div>`
                : ""
            }
            ${
              recipe.tags
                ? `<div class="info-item"><i class="fas fa-tags"></i><span>${this.escapeHTML(
                    recipe.tags
                  )}</span></div>`
                : ""
            }
          </div>
          <div class="ingredients-section">
            <h4><i class="fas fa-shopping-basket"></i> Malzemeler</h4>
            <div class="ingredients-chips">
              ${recipe.ingredients_have
                .map(
                  (ing) =>
                    `<span class="chip have"><i class="fas fa-check"></i>${this.escapeHTML(
                      ing
                    )}</span>`
                )
                .join("")}
              ${recipe.ingredients_missing
                .map(
                  (ing) =>
                    `<span class="chip miss"><i class="fas fa-times"></i>${this.escapeHTML(
                      ing
                    )}</span>`
                )
                .join("")}
            </div>
          </div>
          ${
            recipe.instructions
              ? `<details class="instructions"><summary><i class="fas fa-book-open"></i> Yapılışı</summary><div class="instructions-content">${this.escapeHTML(
                  recipe.instructions
                ).replace(/\n/g, "<br>")}</div></details>`
              : ""
          }
        </div>
      </div>`
      )
      .join("");

    this.updateFavoriteButtons();
  }

  // Placeholder implementasyonları
  initMobileMenu() {}

  /**
   * YENİ: Sürükle-Bırak fonksiyonu dolduruldu.
   */
  initDragAndDrop() {
    // "Dolabım" kartını (bırakma alanı) bul
    const dropZone = Array.from(document.querySelectorAll(".sidebar .card h2"))
      .find((h2) => h2.textContent.includes("Dolabım"))
      ?.closest("section.card");

    if (!dropZone) {
      console.warn("Sürükle-bırak için 'Dolabım' kartı bulunamadı.");
      return;
    }

    let dragCounter = 0;
    const originalBorder = dropZone.style.border;
    const originalTransform = dropZone.style.transform;

    dropZone.addEventListener("dragover", (e) => {
      e.preventDefault();
      e.stopPropagation();
      e.dataTransfer.dropEffect = "copy";
    });

    dropZone.addEventListener("dragenter", (e) => {
      e.preventDefault();
      e.stopPropagation();
      dragCounter++;
      dropZone.style.border = "2px dashed var(--primary)";
      dropZone.style.transform = "scale(1.02)";
      dropZone.style.transition = "all 0.2s ease";
    });

    dropZone.addEventListener("dragleave", (e) => {
      e.preventDefault();
      e.stopPropagation();
      dragCounter--;
      if (dragCounter === 0) {
        // Efekti sıfırla
        dropZone.style.border = originalBorder;
        dropZone.style.transform = originalTransform;
      }
    });

    dropZone.addEventListener("drop", (e) => {
      e.preventDefault();
      e.stopPropagation();
      dragCounter = 0; // Sayacı sıfırla
      // Efekti sıfırla
      dropZone.style.border = originalBorder;
      dropZone.style.transform = originalTransform;

      const ingredientName = e.dataTransfer.getData("text/plain");
      if (ingredientName) {
        this.addPantryItem(ingredientName); // Merkezi fonksiyonu çağır
      }
    });

    // Sürüklenen malzemeleri ayarla
    document.querySelectorAll(".ingredient-checkbox").forEach((item) => {
      item.addEventListener("dragstart", (e) => {
        // Malzeme adını checkbox'ın value'sundan al
        const name = item.querySelector('input[type="checkbox"]').value;
        e.dataTransfer.setData("text/plain", name);
        e.dataTransfer.effectAllowed = "copy";
      });
    });
  }

  initAdvancedFilters() {}
  applyAdvancedFilters() {}

  // Notification
  initNotifications() {
    if (!document.querySelector(".notification")) {
      const div = document.createElement("div");
      div.className = "notification";
      document.body.appendChild(div);
    }
  }
  showNotification(msg, type = "success") {
    const box = document.querySelector(".notification");
    if (!box) return;
    box.className = `notification ${type} show`;
    box.innerHTML = `<i class="fas fa-info-circle"></i> ${this.escapeHTML(
      msg
    )}`;
    setTimeout(() => {
      box.classList.remove("show");
    }, 2500);
  }

  // Misc
  debounce(func, wait) {
    let timeout;
    return (...args) => {
      clearTimeout(timeout);
      timeout = setTimeout(() => func.apply(this, args), wait);
    };
  }
  escapeHTML(str) {
    if (!str) return "";
    const div = document.createElement("div");
    div.textContent = str;
    return div.innerHTML;
  }
  updateFavoriteButtons() {
    document.querySelectorAll(".favorite-btn").forEach((btn) => {
      const recipeCard = btn.closest(".recipe-card");
      const recipeId = recipeCard?.dataset.recipeId;
      if (recipeId && this.favorites.includes(recipeId)) {
        btn.classList.add("active");
      } else {
        btn.classList.remove("active");
      }
    });
  }

  // Views (minimal)
  handleQuickAction(card) {
    const action = card.querySelector("span")?.textContent?.trim();
    if (!action) return;
    if (action.includes("Alışveriş")) return this.renderShoppingList();
    if (action.includes("Yemek Planla")) return this.renderMealPlanner();
    if (action.includes("Favorilerim")) return this.renderFavorites();

    /**
     * YENİ: Rastgele Tarif özelliği eklendi.
     */
    if (action.includes("Rastgele")) {
      const cards = document.querySelectorAll("#recipesGrid .recipe-card");
      if (cards.length === 0) {
        return this.showNotification(
          "Önce tarifleri yükleyin veya aratın.",
          "info"
        );
      }

      // Rastgele bir kart seç
      const randomCard = cards[Math.floor(Math.random() * cards.length)];

      // Karta git ve vurgula
      randomCard.scrollIntoView({ behavior: "smooth", block: "center" });

      const originalShadow = randomCard.style.boxShadow;
      const originalTransition = randomCard.style.transition;

      randomCard.style.transition = "all 0.3s ease-in-out";
      randomCard.style.boxShadow = `0 0 0 4px var(--primary), ${originalShadow}`;

      setTimeout(() => {
        randomCard.style.boxShadow = originalShadow;
        // Geçişi sıfırla
        setTimeout(() => {
          randomCard.style.transition = originalTransition;
        }, 300);
      }, 2000); // 2 saniye vurgula

      return;
    }
  }
  renderShoppingList() {
    const container = document.getElementById("recipesGrid");
    if (!container) return;
    const list = this.shoppingList || [];
    container.innerHTML = `
      <div class="panel">
        <div class="panel-header">
          <h3><i class="fas fa-shopping-cart"></i> Alışveriş Listesi</h3>
          <div class="panel-actions">
            <button class="btn btn-secondary" id="add-item-btn"><i class="fas fa-plus"></i> Öğe Ekle</button>
            <button class="btn btn-danger" id="clear-list-btn"><i class="fas fa-trash"></i> Temizle</button>
          </div>
        </div>
        <ul class="shopping-list">
          ${
            list.length
              ? list
                  .map(
                    (it, idx) => `
            <li class="shopping-item">
              <label><input type="checkbox" data-idx="${idx}" ${
                      it.done ? "checked" : ""
                    }/> <span class="${
                      it.done ? "done" : ""
                    }">${this.escapeHTML(it.name)}</span></label>
              <button class="btn-icon" data-remove="${idx}" title="Sil"><i class="fas fa-times"></i></button>
            </li>`
                  )
                  .join("")
              : `<div class="empty-state"><i class="fas fa-inbox"></i><p>Liste boş.</p></div>`
          }
        </ul>
      </div>`;

    const add = () => {
      const name = prompt("Eklenecek malzeme:");
      if (!name) return;
      this.shoppingList.push({ name, done: false });
      localStorage.setItem(
        "recipe_shopping_list",
        JSON.stringify(this.shoppingList)
      );
      this.renderShoppingList();
    };
    const clear = () => {
      if (!confirm("Listeyi temizlemek istiyor musunuz?")) return;
      this.shoppingList = [];
      localStorage.setItem(
        "recipe_shopping_list",
        JSON.stringify(this.shoppingList)
      );
      this.renderShoppingList();
    };
    document.getElementById("add-item-btn")?.addEventListener("click", add);
    document.getElementById("clear-list-btn")?.addEventListener("click", clear);

    container.querySelectorAll('input[type="checkbox"]').forEach((cb) => {
      cb.addEventListener("change", (e) => {
        const idx = Number(e.target.dataset.idx);
        this.shoppingList[idx].done = !!e.target.checked;
        localStorage.setItem(
          "recipe_shopping_list",
          JSON.stringify(this.shoppingList)
        );
        this.renderShoppingList();
      });
    });
    container.querySelectorAll("button[data-remove]").forEach((btn) => {
      btn.addEventListener("click", (e) => {
        const idx = Number(e.currentTarget.dataset.remove);
        this.shoppingList.splice(idx, 1);
        localStorage.setItem(
          "recipe_shopping_list",
          JSON.stringify(this.shoppingList)
        );
        this.renderShoppingList();
      });
    });
  }
  renderMealPlanner() {
    const container = document.getElementById("recipesGrid");
    if (!container) return;
    const days = [
      "Pazartesi",
      "Salı",
      "Çarşamba",
      "Perşembe",
      "Cuma",
      "Cumartesi",
      "Pazar",
    ];
    const plan = this.mealPlan || {};
    container.innerHTML = `
      <div class="panel">
        <div class="panel-header">
          <h3><i class="fas fa-calendar-alt"></i> Haftalık Yemek Planı</h3>
          <div class="panel-actions">
            <button class="btn btn-secondary" id="export-plan"><i class="fas fa-file-export"></i> Dışa Aktar</button>
            <button class="btn btn-danger" id="clear-plan"><i class="fas fa-trash"></i> Temizle</button>
          </div>
        </div>
        <div class="meal-grid">
          ${days
            .map(
              (d) => `
            <div class="meal-cell">
              <div class="meal-day">${d}</div>
              <div class="meal-title">${this.escapeHTML(plan[d] || "—")}</div>
              <div class="meal-actions">
                <button class="btn btn-sm btn-secondary" data-assign="${d}"><i class="fas fa-pen"></i> Ata</button>
                <button class="btn btn-sm btn-primary" data-pick="${d}"><i class="fas fa-magic"></i> Gridden Seç</button>
              </div>
            </div>`
            )
            .join("")}
        </div>
      </div>`;

    document.getElementById("clear-plan")?.addEventListener("click", () => {
      if (!confirm("Planı temizlemek istiyor musunuz?")) return;
      this.mealPlan = {};
      localStorage.setItem("recipe_meal_plan", JSON.stringify(this.mealPlan));
      this.renderMealPlanner();
    });
    document.getElementById("export-plan")?.addEventListener("click", () => {
      const data = JSON.stringify(this.mealPlan, null, 2);
      const blob = new Blob([data], { type: "application/json" });
      const url = URL.createObjectURL(blob);
      const a = document.createElement("a");
      a.href = url;
      a.download = "meal_plan.json";
      a.click();
      URL.revokeObjectURL(url);
      this.showNotification("Plan dışa aktarıldı.");
    });
    container.querySelectorAll("button[data-assign]").forEach((btn) => {
      btn.addEventListener("click", (e) => {
        const day = e.currentTarget.dataset.assign;
        const value = prompt(`${day} için yemek adı:`, plan[day] || "");
        if (value === null) return;
        this.mealPlan[day] = value.trim();
        localStorage.setItem("recipe_meal_plan", JSON.stringify(this.mealPlan));
        this.renderMealPlanner();
      });
    });
    container.querySelectorAll("button[data-pick]").forEach((btn) => {
      btn.addEventListener("click", (e) => {
        const day = e.currentTarget.dataset.pick;
        const firstCard = document.querySelector(".recipe-card .recipe-title");
        if (!firstCard) {
          this.showNotification("Seçilecek tarif yok.", "error");
          return;
        }
        this.mealPlan[day] = firstCard.textContent.trim();
        localStorage.setItem("recipe_meal_plan", JSON.stringify(this.mealPlan));
        this.renderMealPlanner();
      });
    });
  }
  async renderFavorites() {
    const container = document.getElementById("recipesGrid");
    const resultsCount = document.querySelector(".results-count");
    if (!container || !resultsCount) return;
    try {
      const res = await fetch("index.php?action=get_favorites");
      const data = await res.json();
      if (!data.success) throw new Error("Favoriler getirilemedi");
      resultsCount.textContent = `(${data.recipes.length} favori)`;
      if (data.recipes.length === 0) {
        container.innerHTML = `<div class="empty-state large"><i class="fas fa-heart-broken"></i><h3>Favori yok</h3><p>Tarif kartındaki kalp butonuyla favorilere ekleyebilirsin.</p></div>`;
        return;
      }
      this.renderRecipes(data.recipes);
    } catch (err) {
      this.showNotification(`Hata: ${err.message}`, "error");
    }
  }

  // Init
  async loadInitialData() {
    try {
      const pantryResponse = await fetch("index.php?action=get_pantry");
      const pantryData = await pantryResponse.json();
      if (pantryData.success) this.updatePantryList(pantryData.pantry);
      this.updateRecipes();
    } catch (err) {
      console.error("Başlangıç verileri yüklenirken hata:", err);
    }
  }
}

document.addEventListener("DOMContentLoaded", () => {
  window.app = new SmartRecipeApp();
});
