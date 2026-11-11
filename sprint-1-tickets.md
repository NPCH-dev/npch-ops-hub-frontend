# Frontend Sprint 1 — Auth & Benutzerverwaltung

## Tickets

### fe-001: Login Screen
- Vollbild-Login-Formular (Email + Passwort)
- POST /api/v1/auth/login → JWT speichern
- Fehlerbehandlung (401, Netzwerkfehler)
- "Angemeldet bleiben" Checkbox
- SP: 3

### fe-002: Auth-Guard + Token-Management
- Token in localStorage, Ablauf prüfen
- Auto-Logout bei 401
- Refresh-Token-Flow (POST /api/v1/auth/refresh)
- SP: 2

### fe-003: Benutzerliste
- Tabelle: Name, Email, Rolle, Status, Erstellt
- GET /api/v1/users
- Suche/Filter nach Rolle
- SP: 3

### fe-004: Benutzer erstellen/bearbeiten
- Modal: Name, Email, Passwort, Rolle auswählen
- POST /api/v1/users, PATCH /api/v1/users/{id}
- Validierung
- SP: 3

### fe-005: Rollenverwaltung
- Rollen-Übersicht: management, coordination, finance, sales, recruitment, system
- Benutzer einer Rolle zuweisen
- SP: 2

### fe-006: Benutzereinstellungen
- Eigenes Profil bearbeiten (Name, Passwort ändern)
- Verbundene Konten: Gmail, Google Calendar (OAuth-Links)
- SP: 3

Gesamt: 16 SP
