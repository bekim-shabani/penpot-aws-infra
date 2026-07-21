const { defineConfig } = require('cypress')

module.exports = defineConfig({
  e2e: {
    baseUrl: process.env.CYPRESS_BASE_URL || 'http://localhost:9001',
    specPattern: 'e2e/**/*.cy.js',

    // Timeouts allongés : infra preprod lente + SPA Penpot lourde (ClojureScript + wasm)
    defaultCommandTimeout: 15000,   // attente max d'un élément (était 10000)
    pageLoadTimeout: 120000,        // attente max du chargement de page (défaut 60000 → dépassé)

    // Re-tente 2x un test échoué en CI avant de le déclarer rouge (absorbe la flakiness réseau)
    retries: { runMode: 2, openMode: 0 },

    viewportWidth: 1280,
    viewportHeight: 720,
    screenshotsFolder: 'screenshots',
    videosFolder: 'videos',
    supportFile: 'cypress/support/e2e.js',
  }
})

