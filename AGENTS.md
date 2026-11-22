# AGENTS.md — npch-ops-hub-frontend

**Einzige Regelquelle für alle Agents, die am Frontend arbeiten.**

n8n-Workflows laden diese Datei als ersten Schritt via HTTP GET:
```
GET https://raw.githubusercontent.com/NPCH-dev/npch-ops-hub-frontend/main/AGENTS.md
→ Inhalt als System-Prompt injizieren
→ Dann handeln
```

---

## Zweck dieses Repos

`npch-ops-hub-frontend` — Statisches Single-Page-App Frontend:
- Vanilla JS, kein React, kein Vue, kein Framework
- Eine Datei: `index.html` (alle Styles, Scripts, HTML)
- Hash-basiertes Routing (`#dashboard`, `#orders`, etc.)
- API-Zugriff ausschließlich über `api.processengine.de`

---

## Harte Regeln (ABSOLUT, keine Ausnahmen)

```
⛔ NIEMALS direkte DB- oder Supabase-Anfragen aus dem Frontend
⛔ NIEMALS Supabase Secret Key oder andere Secrets in Frontend-Code
⛔ NIEMALS fetch() direkt — immer über den api() Helper
⛔ NIEMALS Token in URL-Parametern — nur in localStorage/sessionStorage
⛔ NIEMALS externes Framework einführen (React, Vue, Angular)
⛔ NIEMALS mehr als 2 Fehlversuche — danach stoppen und Christian benachrichtigen
⛔ NIEMALS auf main pushen für Entwicklung — alles auf develop (bis Version 1 freigegeben)
```

```
✅ Alle Datenzugriffe über api.processengine.de Endpoints
✅ Bearer Token automatisch vom api() Helper mitgesendet
✅ CSS Custom Properties: alle Farben als Tokens in :root
✅ Vor jeder Änderung: aktuellen Stand von index.html lesen und vergleichen
✅ Nur gezielte Änderungen (Edit Tool) — niemals die gesamte Datei neu schreiben
✅ Doku-Update im selben Git-Commit wie die Code-Änderung
```

## Regel: Lesen vor Überschreiben

**KRITISCH für das Frontend:** `index.html` ist die einzige Datei.  
Jeder Agent, der etwas ändern will, MUSS zuerst den aktuellen Stand lesen.  
Vergleiche dann: Stimmt der erwartete Zustand mit dem tatsächlichen überein?  
Jedes Neu-Schreiben riskiert, bestehende Bugfixes, Auth-Logik und API-Verbindungen zu überschreiben.  
**Immer inkrementell entwickeln — niemals neu schreiben.**

## Regel: aaPanel nur auf Webservern

```
✅ aaPanel: NUR auf npch-vps3 (Dev-Webserver) und dem künftigen Prod-Webserver
⛔ aaPanel NIEMALS auf Helsinki, GPU-Server oder n8n-Servern
```

## API-Konfiguration

```javascript
const CONFIG = {
  apiBase: 'https://api.processengine.de/api/v1',
  authToken: '',      // wird nach Login gesetzt
  theme: 'dark'
};
```

API Helper:
```javascript
// Alle API-Calls über diesen Helper — niemals fetch() direkt
async function api(path, opts = {}) { ... }
```

## Deployment

```
Branch main → Auto-Deploy via deploy-webhook.php
Deploy kopiert *.html + *.png nach /www/wwwroot/dev.processengine.de
URL: https://dev.processengine.de
```

## Seitenstruktur

| Route | Status |
|-------|--------|
| `#dashboard` | Layout ✅ / API ⏳ |
| `#orders` | Live ✅ (HubSpot Master-Detail + AI Insights) |
| `#sprint` | Layout ✅ / API ⏳ |
| `#users` | Layout ✅ / API ⏳ |
| `#settings` | Layout ✅ / API ⏳ |
| `#approvals` | Layout ✅ / API ⏳ |
| `#questions` | Live ✅ |

## UI-Sprache

**ENGLISCH** — Alle UI-Texte, Labels, Buttons, Tooltips, Toast-Messages auf Englisch.

## Beim Fehler

- **Erster Fehler:** Stopp, Fehler dokumentieren, einmal neu versuchen
- **Zweiter Fehler:** STOPP. Christian benachrichtigen.

---

*Stand: 22.11.2026*
