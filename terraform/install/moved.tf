moved {
  from = kubernetes_secret.opsdb_indoc_vre
  to   = kubernetes_secret.opsdb_indoc_vre["utility"]
}
