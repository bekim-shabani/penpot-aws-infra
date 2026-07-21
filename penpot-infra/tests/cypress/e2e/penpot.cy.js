// Tests E2E Penpot — Funky Wombat Studio
// Simule un designer qui se connecte et navigue dans l'application

describe('Penpot — Authentification et navigation', () => {

  // Récupération des credentials depuis les variables d'environnement GitLab CI/CD
  const email = Cypress.env('email')
  const password = Cypress.env('password')

  it('La page de connexion s affiche correctement', () => {
    cy.visit('/')
    // Vérifie que le formulaire de login est présent
    cy.get('input[type="email"]').should('be.visible')
    cy.get('button[type="submit"]').should('be.visible')
  })

  it('Un designer peut se connecter', () => {
    cy.visit('/')
    // Saisie de l email — le champ password apparaît après validation
    cy.get('input[type="email"]').type(email)
    cy.get('input[type="email"]').type('{enter}')
    // Saisie du mot de passe
    cy.get('input[type="password"]').type(password)
    // Clique sur le bouton de connexion
    cy.get('button[type="submit"]').click()
    // Vérifie qu on arrive sur le dashboard
    cy.url().should('include', '/dashboard')
  })

  it('Connexion avec mauvais mot de passe affiche une erreur', () => {
    cy.visit('/')
    // Vérifie que Penpot gère bien les erreurs d authentification
    cy.get('input[type="email"]').type(email)
    cy.get('input[type="email"]').type('{enter}')
    cy.get('input[type="password"]').type('mauvaismdp')
    cy.get('button[type="submit"]').click()
    // Un message d erreur doit apparaître
    cy.contains('Email or password is incorrect').should('be.visible')
  })

})
