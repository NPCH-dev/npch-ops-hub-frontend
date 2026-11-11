# NPCH Ops Hub — Frontend

Statisches SPA für das NobleProg DACH Operations Hub.

## Repo & Deploy

- **Repo:** `NPCH-dev/npch-ops-hub-frontend`
- **Main Branch:** `main` → Auto-Deploy auf `https://dev.processengine.de`
- **Develop Branch:** `develop` → Feature-Entwicklung, PR → main
- **Deploy:** `deploy-webhook.php` kopiert `*.html` + `*.png` nach `/www/wwwroot/dev.processengine.de`

## Architektur

- **Single File SPA:** `index.html` — alle Seiten, Styles, Scripts in einer Datei
- **Routing:** Hash-basiert (`#dashboard`, `#users`, `#settings`, etc.)
- **API:** Alle Daten via `https://api.processengine.de/api/v1/` (FastAPI Backend)
- **Auth:** JWT Bearer Token, gespeichert in `localStorage` / `sessionStorage`

## Sicherheitsregeln

- ⛔ **NIEMALS** direkte DB- oder Supabase-Anfragen aus dem Frontend
- ⛔ Supabase Secret Key oder andere Secrets niemals in Frontend-Code
- ✅ Alle Datenzugriffe ausschließlich über `api.processengine.de` Endpoints
- ✅ Bearer Token wird automatisch vom `api()` Helper mitgesendet

## API-Konfiguration (`CONFIG`)

```javascript
const CONFIG = {
  apiBase: 'https://api.processengine.de/api/v1',
  authToken: '',      // wird nach Login gesetzt
  theme: 'dark'
};
```

API-URL kann in Einstellungen (`#settings`) überschrieben werden (gespeichert in `localStorage`).

## Auth-Flow

1. `checkAuth()` — prüft Token in `localStorage` / `sessionStorage`
2. Login: `POST /api/v1/auth/login` mit `application/x-www-form-urlencoded` (username + password)
3. Response: `{ access_token: "..." }` → wird in Storage + `CONFIG.authToken` gespeichert
4. `logout()` — löscht Token, zeigt Login-Screen

## Seitenstruktur

| Route | Funktion | Status |
|-------|----------|--------|
| `#dashboard` | KPI-Übersicht | Layout ✅ / API ⏳ |
| `#orders` | Auftragsliste | Layout ✅ / API ⏳ |
| `#sprint` | Sprint Board | Layout ✅ / API ⏳ |
| `#users` | Benutzerverwaltung | Layout ✅ / API ⏳ |
| `#settings` | Einstellungen + Profil | Layout ✅ / API ⏳ |
| `#approvals` | Freigaben | Layout ✅ / API ⏳ |

## Sprint 1 — Auth & Benutzerverwaltung

Tickets: `sprint-1-tickets.md` (16 SP total)

| Ticket | Titel | SP | Status |
|--------|-------|----|----|
| fe-001 | Login Screen | 3 | ✅ Layout done |
| fe-002 | Auth-Guard + Token-Management | 2 | ✅ Layout done |
| fe-003 | Benutzerliste | 3 | ✅ Layout done |
| fe-004 | Benutzer erstellen/bearbeiten | 3 | ✅ Layout done |
| fe-005 | Rollenverwaltung | 2 | ⏳ API connect |
| fe-006 | Benutzereinstellungen | 3 | ✅ Layout done |

## Backend-Repo

Zugehöriges Backend: `NPCH-dev/npch-ops-hub` (`/home/claude/npch-ops-hub`)  
Spec: `docs/spec.md` im Backend-Repo
