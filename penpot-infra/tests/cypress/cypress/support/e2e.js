// Fichier support Cypress — chargé avant chaque test

// Ignore les erreurs cross-origin de l'application Penpot
// Penpot charge des scripts externes qui génèrent des erreurs non critiques
Cypress.on('uncaught:exception', (err, runnable) => {
  return false
})
