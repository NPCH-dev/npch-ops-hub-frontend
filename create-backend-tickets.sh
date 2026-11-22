#!/usr/bin/env bash
# ============================================================
# NPCH Backend Ticket Creator
# Führe dieses Script EINMAL auf deinem Desktop aus.
# Voraussetzung: Du bist im Browser unter dev.processengine.de
# eingeloggt und hast den Token aus localStorage.
#
# Verwendung:
#   chmod +x create-backend-tickets.sh
#   TOKEN=$(node -e "const ls=require('fs').readFileSync('/dev/stdin','utf8').trim();console.log(ls)" <<< "DEINEN_TOKEN_HIER_EINFÜGEN")
#   bash create-backend-tickets.sh "DEINEN_TOKEN_HIER"
#
# Oder direkt:
#   bash create-backend-tickets.sh "eyJhbGci..."
# ============================================================

API="https://api.processengine.de/api/v1"
TOKEN="${1:?Bitte JWT-Token als ersten Parameter übergeben}"
AUTH="Authorization: Bearer $TOKEN"

post_ticket() {
  local id="$1" title="$2" sp="$3" priority="$4"
  local desc="$5"
  echo "→ Erstelle $id: $title"
  curl -s -X POST "$API/tickets" \
    -H "$AUTH" \
    -H "Content-Type: application/json" \
    -d "{\"ticket_id\":\"$id\",\"title\":\"$title\",\"description\":$(echo "$desc" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))'),\"status\":\"backlog\",\"story_points\":$sp,\"priority\":\"$priority\"}" \
    | python3 -c 'import json,sys; d=json.load(sys.stdin); print("  ✅ OK:", d.get("ticket_id","?"))' 2>/dev/null \
    || echo "  ⚠️  Fehler (evtl. schon vorhanden)"
}

# ── BE-019: Dashboard KPI ───────────────────────────────────
post_ticket "BE-019" "Dashboard KPI Endpoint" 3 "high" \
"Implementiere GET /api/v1/dashboard/kpis

Dieser Endpoint liefert Kennzahlen für die Dashboard-Seite.

Response-Format:
{
  \"revenue_mtd\": 42000.00,
  \"revenue_target\": 80000.00,
  \"open_orders\": 12,
  \"orders_in_progress\": 7,
  \"trainers_active\": 23,
  \"trainers_needed\": 5,
  \"invoices_overdue\": 3,
  \"invoices_overdue_amount\": 15400.00,
  \"approvals_pending\": 2,
  \"margin_avg_percent\": 34.5,
  \"bookings_this_month\": 18,
  \"training_days_this_month\": 45
}

Implementierungshinweise:
- Datei: app/routers/dashboard.py (neu anlegen)
- Router prefix: /dashboard, tags: [\"dashboard\"]
- In main.py einbinden: from app.routers.dashboard import dashboard_router; app.include_router(dashboard_router, prefix='/api/v1')
- Auth: JWT required (Depends(get_current_user))
- Alle Werte aus der orders-Tabelle aggregieren (SQL COUNT, SUM etc.)
- revenue_mtd = SUM(invoice_amount) WHERE month = current month AND status != 'cancelled'
- open_orders = COUNT WHERE main_status IN ('SP01_INQUIRY','SP01_CLARIFICATION')
- Fehlende Tabellenspalten mit COALESCE 0 absichern
- FastAPI, SQLAlchemy async, return dict direkt (kein Pydantic-Schema nötig)
"

# ── BE-020: Inquiries / Pipeline ────────────────────────────
post_ticket "BE-020" "Inquiries Pipeline Endpoint" 3 "high" \
"Implementiere GET /api/v1/inquiries

Liefert offene Anfragen (SP-01-Status) für die Pipeline/Forecast-Seite.

Query-Parameter:
- assigned_to: string (optional, User-Email für 'meine Anfragen')
- limit: int = 50
- offset: int = 0

Response-Format (Liste):
[{
  \"id\": \"uuid\",
  \"seq\": \"NP-DACH-2026-0042\",
  \"customer_name\": \"Arvato Systems\",
  \"training_topic\": \"Python Advanced\",
  \"training_days\": 2,
  \"budget_estimate\": 4800.00,
  \"probability_percent\": 70,
  \"expected_close_date\": \"2026-12-15\",
  \"assigned_to\": \"max.muster@nobleprog.com\",
  \"main_status\": \"SP01_INQUIRY\",
  \"created_at\": \"2026-11-01T10:00:00Z\",
  \"last_activity_at\": \"2026-11-18T14:30:00Z\"
}]

Implementierung:
- Datei: app/routers/inquiries.py (neu)
- Router prefix: /inquiries
- In main.py einbinden
- Auth: JWT required
- WHERE main_status IN ('SP01_INQUIRY','SP01_CLARIFICATION','SP02_OFFER')
- ORDER BY created_at DESC
- assigned_to Filter auf das users-Feld 'assigned_sales' o.ä.
- Fehlende Spalten mit COALESCE absichern
"

# ── BE-021: Bookings List ────────────────────────────────────
post_ticket "BE-021" "Bookings List Endpoint" 3 "high" \
"Implementiere GET /api/v1/bookings

Buchungsliste für die #bookings-Seite.

Query-Parameter:
- status: string (optional, z.B. 'confirmed','pending','cancelled')
- limit: int = 50
- offset: int = 0

Response-Format:
[{
  \"id\": \"uuid\",
  \"booking_ref\": \"BK-DACH-2026-0018\",
  \"order_ref\": \"NP-DACH-2026-0042\",
  \"customer_name\": \"Arvato Systems\",
  \"training_topic\": \"Python Advanced\",
  \"start_date\": \"2026-12-10\",
  \"end_date\": \"2026-12-11\",
  \"location\": \"Berlin, Remote\",
  \"trainer_name\": \"Max Muster\",
  \"status\": \"confirmed\",
  \"participants\": 8,
  \"revenue\": 9600.00,
  \"main_status\": \"SP03_BOOKING_CONFIRMED\"
}]

Implementierung:
- Datei: app/routers/bookings.py (neu)
- Router prefix: /bookings
- In main.py einbinden
- Auth: JWT required
- JOIN auf orders-Tabelle (booking_ref, order_ref aus orders)
- ORDER BY start_date ASC (anstehende zuerst)
- Fehlende Spalten COALESCE absichern
"

# ── BE-022: Delivery Calendar ────────────────────────────────
post_ticket "BE-022" "Delivery Calendar Endpoint" 2 "normal" \
"Implementiere GET /api/v1/delivery/calendar

Liefert Trainings-Events für den Delivery-Kalender.

Query-Parameter:
- year: int (default: current year)
- month: int (default: current month)

Response-Format:
{
  \"events\": [{
    \"id\": \"uuid\",
    \"order_ref\": \"NP-DACH-2026-0042\",
    \"title\": \"Python Advanced — Arvato Systems\",
    \"trainer_name\": \"Max Muster\",
    \"start_date\": \"2026-12-10\",
    \"end_date\": \"2026-12-11\",
    \"location\": \"Berlin\",
    \"status\": \"confirmed\",
    \"color\": \"#0057B8\"
  }]
}

Implementierung:
- Datei: app/routers/delivery.py (neu)
- Router prefix: /delivery
- In main.py einbinden
- Auth: JWT required
- WHERE training_start_date BETWEEN first_day AND last_day des Monats
- ORDER BY training_start_date ASC
- color je nach status: confirmed=#0057B8, in_progress=#10b981, cancelled=#ef4444
"

# ── BE-023: Trainers List ────────────────────────────────────
post_ticket "BE-023" "Trainers DB Endpoint" 3 "normal" \
"Implementiere GET /api/v1/trainers

Trainerdatenbank für die #trainers-Seite.

Query-Parameter:
- skill: string (optional, Keyword-Suche)
- available: bool (optional)
- limit: int = 50

Response-Format:
[{
  \"id\": \"uuid\",
  \"name\": \"Max Muster\",
  \"email\": \"max@example.com\",
  \"skills\": [\"Python\", \"Machine Learning\", \"Data Science\"],
  \"languages\": [\"DE\", \"EN\"],
  \"rate_per_day\": 1200.00,
  \"location\": \"Berlin\",
  \"available\": true,
  \"rating\": 4.8,
  \"trainings_delivered\": 23,
  \"last_active\": \"2026-11-15\"
}]

Implementierung:
- Datei: app/routers/trainers.py (neu)
- Router prefix: /trainers
- In main.py einbinden
- Auth: JWT required
- Tabelle: trainers (falls vorhanden) oder aus assignments/orders aggregieren
- Falls keine trainers-Tabelle: Distinct trainer_name aus orders zurückgeben
- skill-Filter: ILIKE '%skill%' auf skills-Feld
"

# ── BE-024: Approvals Full ───────────────────────────────────
post_ticket "BE-024" "Approvals Full CRUD Endpoint" 3 "high" \
"Implementiere vollständige Approvals-API:

GET /api/v1/approvals
  Query: status (pending/approved/rejected), limit, offset
  Response: [{
    \"id\": \"uuid\",
    \"order_ref\": \"NP-DACH-2026-0042\",
    \"customer_name\": \"Arvato Systems\",
    \"type\": \"margin_approval\",
    \"description\": \"Margin 18% — unter 20% Schwelle\",
    \"requested_by\": \"sales@nobleprog.com\",
    \"requested_at\": \"2026-11-20T10:00:00Z\",
    \"status\": \"pending\",
    \"amount\": 9600.00,
    \"priority\": \"high\"
  }]

POST /api/v1/approvals/{id}/approve
  Body: {\"comment\": \"Freigegeben\"}

POST /api/v1/approvals/{id}/reject
  Body: {\"comment\": \"Marge zu niedrig\"}

Implementierung:
- Datei: app/routers/approvals.py (neu oder erweitern falls vorhanden)
- Router prefix: /approvals
- In main.py einbinden
- Auth: JWT required
- Tabelle: approvals (anlegen falls nicht vorhanden:
    id UUID PK, order_id UUID FK, type VARCHAR, description TEXT,
    requested_by VARCHAR, requested_at TIMESTAMP, status VARCHAR DEFAULT 'pending',
    amount DECIMAL, priority VARCHAR DEFAULT 'normal',
    approved_by VARCHAR, approved_at TIMESTAMP, comment TEXT)
- Bei approve/reject: Status updaten + approved_by aus JWT-User setzen
"

# ── BE-025: Invoices ─────────────────────────────────────────
post_ticket "BE-025" "Invoices List Endpoint" 3 "high" \
"Implementiere GET /api/v1/invoices

Rechnungsliste für die #invoices-Seite.

Query-Parameter:
- status: string (optional: 'draft','sent','paid','overdue')
- limit: int = 50
- offset: int = 0

Response-Format:
[{
  \"id\": \"uuid\",
  \"invoice_ref\": \"RG-2026-00089\",
  \"order_ref\": \"NP-DACH-2026-0042\",
  \"customer_name\": \"Arvato Systems\",
  \"amount\": 9600.00,
  \"tax_amount\": 1824.00,
  \"total_amount\": 11424.00,
  \"issue_date\": \"2026-11-15\",
  \"due_date\": \"2026-12-15\",
  \"paid_date\": null,
  \"status\": \"sent\",
  \"days_overdue\": 0
}]

Implementierung:
- Datei: app/routers/invoices.py (neu)
- Router prefix: /invoices
- In main.py einbinden
- Auth: JWT required
- Tabelle: invoices (falls nicht vorhanden, aus orders aggregieren)
- days_overdue: GREATEST(0, EXTRACT(DAY FROM NOW() - due_date)) WHERE status != 'paid'
- ORDER BY due_date ASC (älteste zuerst)
"

# ── BE-026: Payments ─────────────────────────────────────────
post_ticket "BE-026" "Payments List Endpoint" 2 "normal" \
"Implementiere GET /api/v1/payments

Zahlungsliste für die #payments-Seite.

Response-Format:
[{
  \"id\": \"uuid\",
  \"invoice_ref\": \"RG-2026-00089\",
  \"order_ref\": \"NP-DACH-2026-0042\",
  \"customer_name\": \"Arvato Systems\",
  \"amount\": 11424.00,
  \"payment_date\": \"2026-11-28\",
  \"payment_method\": \"bank_transfer\",
  \"reference\": \"Rechnung RG-2026-00089\",
  \"status\": \"confirmed\"
}]

Implementierung:
- Datei: app/routers/payments.py (neu)
- Router prefix: /payments
- In main.py einbinden
- Auth: JWT required
- Tabelle: payments (falls nicht vorhanden: aus invoices WHERE paid_date IS NOT NULL)
- ORDER BY payment_date DESC
"

# ── BE-027: Today View ───────────────────────────────────────
post_ticket "BE-027" "Today View Endpoint — Was ist heute fällig" 3 "high" \
"Implementiere GET /api/v1/today

Aggregierter Tages-Überblick: Alles was heute fällig ist, quer über alle Module.

Response-Format:
{
  \"date\": \"2026-11-22\",
  \"summary\": {
    \"total_items\": 12,
    \"overdue\": 3,
    \"due_today\": 9
  },
  \"sections\": [
    {
      \"type\": \"approvals\",
      \"label\": \"Pending Approvals\",
      \"count\": 2,
      \"items\": [{\"id\": \"...\", \"title\": \"...\", \"priority\": \"high\", \"order_ref\": \"...\"}]
    },
    {
      \"type\": \"invoices_overdue\",
      \"label\": \"Overdue Invoices\",
      \"count\": 1,
      \"items\": [{\"id\": \"...\", \"title\": \"RG-2026-00089 — Arvato (3 Tage überfällig)\", \"amount\": 11424.00}]
    },
    {
      \"type\": \"trainings_today\",
      \"label\": \"Trainings Today\",
      \"count\": 2,
      \"items\": [{\"id\": \"...\", \"title\": \"Python Advanced — Berlin\", \"trainer\": \"Max Muster\"}]
    },
    {
      \"type\": \"tasks_due\",
      \"label\": \"Tasks Due Today\",
      \"count\": 4,
      \"items\": [{\"id\": \"...\", \"title\": \"SP-05 Trainer bestätigen\", \"order_ref\": \"NP-DACH-2026-0042\"}]
    },
    {
      \"type\": \"questions_open\",
      \"label\": \"Open Questions\",
      \"count\": 3,
      \"items\": [{\"id\": \"...\", \"title\": \"Anfrage Arvato — Rückfrage offen\"}]
    }
  ]
}

Implementierung:
- Datei: app/routers/today.py (neu)
- Router prefix: /today
- In main.py einbinden
- Auth: JWT required
- Aggregiert aus: approvals, invoices, orders (training_start_date = today), tickets
- Datum immer current_date (UTC)
- items auf max. 10 pro Sektion begrenzen
"

# ── BE-028: Order Emails / Communication Trail ───────────────
post_ticket "BE-028" "Order Communication Trail Endpoint" 3 "high" \
"Implementiere GET /api/v1/orders/{order_id}/emails

Kommunikationsverlauf (E-Mails, Calls, Notes) zu einem Auftrag.

Response-Format:
[{
  \"id\": \"uuid\",
  \"type\": \"email\",
  \"direction\": \"inbound\",
  \"subject\": \"Re: Angebot Python Training\",
  \"from\": \"kunde@arvato.com\",
  \"to\": \"sales@nobleprog.com\",
  \"body_preview\": \"Vielen Dank für das Angebot...\",
  \"timestamp\": \"2026-11-18T14:30:00Z\",
  \"has_attachments\": false,
  \"gmail_message_id\": \"18c4a2b3d4e5f\"
},
{
  \"id\": \"uuid\",
  \"type\": \"note\",
  \"direction\": null,
  \"subject\": \"Call-Notiz\",
  \"from\": \"sales@nobleprog.com\",
  \"body_preview\": \"Kunde bestätigt Interesse, Budget 10k\",
  \"timestamp\": \"2026-11-15T10:00:00Z\"
}]

Implementierung:
- Datei: Ergänze in app/routers/orders.py oder neue Datei
- Endpoint: GET /orders/{order_id}/emails
- Auth: JWT required
- Tabelle: order_communications (anlegen falls nicht vorhanden:
    id UUID PK, order_id UUID FK, type VARCHAR (email/note/call),
    direction VARCHAR (inbound/outbound), subject VARCHAR,
    from_address VARCHAR, to_address VARCHAR, body_preview TEXT,
    timestamp TIMESTAMP, has_attachments BOOL, gmail_message_id VARCHAR)
- ORDER BY timestamp DESC
- Falls keine Daten: leere Liste zurückgeben []
- Hinweis: Gmail-Sync kommt später; zunächst manuelle Notes reichen
"

# ── BE-029: Users + Role Management ─────────────────────────
post_ticket "BE-029" "Users List und Role Management Endpoints" 3 "high" \
"Implementiere Users-API für Benutzerverwaltung:

GET /api/v1/users
  Response: [{
    \"id\": \"uuid\",
    \"email\": \"user@nobleprog.com\",
    \"full_name\": \"Max Muster\",
    \"role\": \"coordination\",
    \"is_active\": true,
    \"created_at\": \"2026-10-01T00:00:00Z\",
    \"last_login\": \"2026-11-21T08:00:00Z\"
  }]

GET /api/v1/auth/me
  Response: {\"id\": \"...\", \"email\": \"...\", \"full_name\": \"...\", \"role\": \"...\", \"is_active\": true}

PATCH /api/v1/users/{user_id}
  Body: {\"role\": \"coordination\", \"is_active\": true, \"full_name\": \"Max Muster\"}
  Auth: Admin only (role == 'admin')

POST /api/v1/users
  Body: {\"email\": \"...\", \"full_name\": \"...\", \"role\": \"coordination\", \"password\": \"...\"}
  Auth: Admin only

Implementierung:
- Datei: app/routers/users.py (neu oder erweitern)
- Router prefix: /users
- GET /auth/me: Prüfe ob schon vorhanden; falls ja, nur ergänzen
- PATCH: Nur für Admin-Rolle (aus JWT extrahieren)
- Tabelle: users (falls schon vorhanden, Felder ergänzen:
    last_login TIMESTAMP, full_name VARCHAR)
- In main.py einbinden
- Passwort-Hash via bcrypt (passlib)

WICHTIG: GET /auth/me MUSS funktionieren — das Frontend zeigt
Sidebar-Name + Role daraus. Falls schon vorhanden aber fehlerhaft:
bitte fixen (200 zurückgeben mit user-Objekt).
"

# ── BE-030: Dashboard KPI aggregation fix ───────────────────
post_ticket "BE-030" "Sprint Board Endpoint" 2 "normal" \
"Implementiere GET /api/v1/sprint/current

Aktuelles Sprint-Board für die #sprint-Seite.

Response-Format:
{
  \"sprint\": {
    \"id\": 1,
    \"name\": \"Sprint 1 — Auth & Users\",
    \"start_date\": \"2026-11-11\",
    \"end_date\": \"2026-11-24\",
    \"total_sp\": 16,
    \"completed_sp\": 10,
    \"in_progress_sp\": 4
  },
  \"tickets\": [{
    \"ticket_id\": \"fe-001\",
    \"title\": \"Login Screen\",
    \"story_points\": 3,
    \"status\": \"done\",
    \"priority\": \"high\",
    \"assigned_to\": null
  }]
}

Implementierung:
- Datei: app/routers/sprint.py (neu)
- Router prefix: /sprint
- In main.py einbinden
- Auth: JWT required
- Daten aus tickets-Tabelle aggregieren (falls vorhanden)
- Gruppe nach Status für Kanban-Columns
- Falls keine Sprint-Tabelle: Mock-Response mit aktuellen Ticket-Daten zurückgeben
"

echo ""
echo "============================================"
echo "✅ Alle Backend-Tickets erstellt!"
echo "Bitte im n8n UI Workflow 'VlWgEiwV6LItYaVX' manuell triggern"
echo "oder warten bis zum nächsten stündlichen Lauf."
echo "============================================"
