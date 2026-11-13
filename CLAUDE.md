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

---

## Entwicklungsregeln (IMMER beachten)

### Code-Entwicklung — Grundprinzip

**VOR jeder Implementierung: Bestehenden Code vom Git holen und darauf aufbauen — NIEMALS neu schreiben!**

1. `git pull origin main` ausführen, um aktuellen Stand zu holen
2. Bestehenden Code lesen und verstehen (`Read` Tool)
3. Nur gezielte Änderungen vornehmen (`Edit` Tool) — nicht die gesamte Datei neu schreiben
4. Commit mit aussagekräftiger Message, dann `git push origin main`

**Warum:** Jedes Neu-Schreiben riskiert, bestehende Bugfixes, Auth-Logik und API-Verbindungen zu überschreiben. Immer inkrementell entwickeln.

### Frontend-Architektur-Regeln

- **Single File SPA:** Alles in `index.html` — CSS, HTML, JS in einer Datei
- **Kein externes Framework:** Kein React, kein Vue — reines Vanilla JS
- **CSS Custom Properties:** Alle Farben als Tokens in `:root` definieren
- **Layout:** Fixed Header (`#topbar`, `--header-h: 56px`) + Fixed Sidebar (`#sidebar`, `--sidebar-w: 248px`) + scrollbarer `#main` mit `margin-left + margin-top`
- **Dark Sidebar immer:** `--sidebar-bg: #111420` wird NICHT im Light Mode überschrieben
- **Hash-Routing:** `navigate(page)` → setzt Hash, zeigt/versteckt `.page`-Divs
- **API-Calls:** Ausschließlich über den `api(path, opts)` Helper — niemals `fetch()` direkt
- **Token-Handling:** `CONFIG.authToken` + `localStorage`/`sessionStorage` — niemals in URL-Parametern

### Sicherheitsregeln (Absolut)

- ⛔ NIEMALS SSH auf `hpde-serv1.nobleprog.de`
- ⛔ NIEMALS Supabase Secret Key in Frontend-Code
- ⛔ NIEMALS Backend-Code direkt per Edit ändern (nur über n8n Agent)
- ⛔ NIEMALS Service Account JSON teilen oder committen
- ⛔ NIEMALS Supabase MCP für Daten-Schreiboperationen
- ⛔ NIEMALS direkte DB-Anfragen aus dem Frontend
- ✅ Alle Datenzugriffe über `api.processengine.de` Endpoints
- ✅ Bearer Token automatisch vom `api()` Helper mitgesendet

### n8n Developer Agent (Backend-Änderungen)

Backend-Code wird **ausschließlich** über den n8n Developer Agent geändert:
- **Workflow-ID:** `VlWgEiwV6LItYaVX`
- **Ablauf:** Ticket anlegen → Agent holt Ticket → LiteLLM → GitHub Commit auf `develop`
- **API nicht direkt erreichbar** vom Cloud-Container — alle Calls über n8n HTTP-Nodes

### Business-Kontext

**Kernprozess SP-01 → SP-08:**
```
SP-01 Anfrage → SP-02 Angebot → SP-03 Buchungsbestätigung → SP-04 Auftrag
→ SP-05 Trainer-Assignment → SP-06 Training → SP-07 Rechnung → SP-08 Zahlung
```

**User-Rollen:** `management`, `coordination`, `finance`, `sales`, `recruitment`, `system`, `admin`

**Aktuelle Phase:** Stufe 1 — Manual First (read-only Integrationen, keine Auto-Writes)

**Nummerierungsformate:**
- Buchungen: `BK-DACH-{YEAR}-{SEQUENCE:04d}`
- Aufträge: `NP-DACH-{YEAR}-{SEQUENCE:04d}`
- Rechnungen: `RG-{YEAR}-{SEQUENCE:05d}`

### Infrastruktur

| Komponente | Detail |
|------------|--------|
| Frontend-URL | `https://dev.processengine.de` |
| API-Base | `https://api.processengine.de/api/v1` |
| Backend-Container | `npch-b7` (Image: `ghcr.io/npch-dev/npch-ops-hub:backend`) — **aktuell: npch-b7, Nummer steigt mit jedem Deploy** |
| DB-Container | `npch-postgres` (PostgreSQL — NICHT Supabase) |
| n8n-Container | `n8n` auf Port `8008` |
| Server-Zugang | aaPanel Browser-UI (kein SSH auf `hpde-serv1.nobleprog.de`!) |
| LiteLLM | `http://62.238.89.247:4000` (SSH auf `62.238.89.247` erlaubt) |
| Env-Variablen Backend | Datei: `/www/wwwroot/backend.processengine.de/.env` — dort neue Vars hinzufügen, dann Container neu starten |

**Wichtig:** Der Backend-Container-Name (`npch-b3`, `npch-b4`, ...) erhöht sich bei jedem neu gebauten Deploy. Immer aktuellen Namen per `docker ps` prüfen, nie hartcodieren.

### Commit-Message-Format

```
feat(frontend): kurze Beschreibung

Längere Erklärung was und warum geändert wurde.

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
```

Präfixe: `feat` (neu), `fix` (Bugfix), `refactor`, `style` (CSS/Layout), `docs`
