#!/bin/bash

################################################################################
# Hetzner DynDNS - Konfigurationsbeispiel
#
# Dieses Skript zeigt verschiedene Konfigurationsmöglichkeiten für das
# dyndns.sh Script.
#
# Verwende es als Vorlage für deine eigene Konfiguration.
################################################################################

# ============================================================================
# BEISPIEL 1: Minimale Konfiguration (nur erforderliche Parameter)
# ============================================================================

example_minimal() {
    local api_token="your-hetzner-api-token-here"
    local zone_name="example.com"
    local record_name="dyn"
    
    # Einfacher Aufruf mit Umgebungsvariablen
    HETZNER_AUTH_API_TOKEN="$api_token" \
        /usr/local/bin/dyndns.sh -Z "$zone_name" -n "$record_name"
}

# ============================================================================
# BEISPIEL 2: IPv6-Support (AAAA-Record)
# ============================================================================

example_ipv6() {
    local api_token="your-hetzner-api-token-here"
    local zone_name="example.com"
    local record_name="dyn6"
    
    HETZNER_AUTH_API_TOKEN="$api_token" \
        /usr/local/bin/dyndns.sh -Z "$zone_name" -n "$record_name" -T AAAA
}

# ============================================================================
# BEISPIEL 3: Benutzerdefinierte TTL (Time To Live)
# ============================================================================

example_custom_ttl() {
    local api_token="your-hetzner-api-token-here"
    local zone_name="example.com"
    local record_name="dyn"
    local ttl="300"  # 5 Minuten
    
    HETZNER_AUTH_API_TOKEN="$api_token" \
        /usr/local/bin/dyndns.sh -Z "$zone_name" -n "$record_name" -t "$ttl"
}

# ============================================================================
# BEISPIEL 4: Zone-ID statt Zone-Name (schneller, keine Lookup erforderlich)
# ============================================================================

example_zone_id() {
    local api_token="your-hetzner-api-token-here"
    local zone_id="98jFjsd8dh1GHasdf7a8hJG7"  # Zone-ID
    local record_name="dyn"
    
    HETZNER_AUTH_API_TOKEN="$api_token" \
        /usr/local/bin/dyndns.sh -z "$zone_id" -n "$record_name"
}

# ============================================================================
# BEISPIEL 5: Konfiguration über Umgebungsvariablen
# ============================================================================

example_env_vars() {
    export HETZNER_AUTH_API_TOKEN="your-hetzner-api-token-here"
    export HETZNER_ZONE_NAME="example.com"
    export HETZNER_RECORD_NAME="dyn"
    export HETZNER_RECORD_TYPE="A"
    export HETZNER_RECORD_TTL="120"
    
    # Script läuft mit allen Einstellungen aus Umgebungsvariablen
    /usr/local/bin/dyndns.sh
}

# ============================================================================
# BEISPIEL 6: Konfiguration aus Datei laden
# ============================================================================

example_config_file() {
    local config_file="$HOME/.hetzner-dyndns.conf"
    
    # Lade die Konfiguration
    if [[ -f "$config_file" ]]; then
        # WICHTIG: Sichere Dateiberechtigungen!
        # chmod 600 ~/.hetzner-dyndns.conf
        set -a  # Exportiere alle Variablen
        source "$config_file"
        set +a
        
        /usr/local/bin/dyndns.sh
    else
        echo "Konfigurationsdatei nicht gefunden: $config_file"
        return 1
    fi
}

# ============================================================================
# BEISPIEL 7: Verbose-Debugging
# ============================================================================

example_verbose() {
    local api_token="your-hetzner-api-token-here"
    local zone_name="example.com"
    local record_name="dyn"
    
    HETZNER_AUTH_API_TOKEN="$api_token" \
        /usr/local/bin/dyndns.sh -Z "$zone_name" -n "$record_name" -v
}

# ============================================================================
# BEISPIEL 8: Mehrere Records (IPv4 und IPv6)
# ============================================================================

example_multiple_records() {
    local api_token="your-hetzner-api-token-here"
    local zone_name="example.com"
    
    # IPv4-Record
    HETZNER_AUTH_API_TOKEN="$api_token" \
        /usr/local/bin/dyndns.sh -Z "$zone_name" -n "dyn" -T A
    
    # IPv6-Record (mit Verzögerung)
    sleep 2
    
    HETZNER_AUTH_API_TOKEN="$api_token" \
        /usr/local/bin/dyndns.sh -Z "$zone_name" -n "dyn" -T AAAA
}

# ============================================================================
# BEISPIEL 9: Mit Fehlerbehandlung und Logging
# ============================================================================

example_with_error_handling() {
    local api_token="your-hetzner-api-token-here"
    local zone_name="example.com"
    local record_name="dyn"
    local log_file="/var/log/dyndns.log"
    
    {
        echo "=== DynDNS Update startet: $(date) ==="
        
        if HETZNER_AUTH_API_TOKEN="$api_token" \
           /usr/local/bin/dyndns.sh -Z "$zone_name" -n "$record_name"; then
            echo "✓ DynDNS Update erfolgreich: $(date)"
        else
            echo "✗ DynDNS Update fehlgeschlagen: $(date)"
            exit 1
        fi
    } | tee -a "$log_file"
}

# ============================================================================
# BEISPIEL 10: Cron-Integration mit Logger
# ============================================================================

example_cron_setup() {
    cat << 'EOF'
# Füge diese Zeilen in deine crontab ein (crontab -e):

# IPv4-Record alle 5 Minuten aktualisieren
*/5 * * * * HETZNER_AUTH_API_TOKEN='your-api-token' /usr/local/bin/dyndns.sh -Z example.com -n dyn -T A >> /var/log/dyndns.log 2>&1

# IPv6-Record alle 5 Minuten aktualisieren
*/5 * * * * HETZNER_AUTH_API_TOKEN='your-api-token' /usr/local/bin/dyndns.sh -Z example.com -n dyn -T AAAA >> /var/log/dyndns.log 2>&1

# Verwende einen anderen Cron-Eintrag pro Zone
*/5 * * * * HETZNER_AUTH_API_TOKEN='token1' /usr/local/bin/dyndns.sh -Z zone1.com -n dyn >> /var/log/dyndns-z1.log 2>&1
*/5 * * * * HETZNER_AUTH_API_TOKEN='token2' /usr/local/bin/dyndns.sh -Z zone2.com -n dyn >> /var/log/dyndns-z2.log 2>&1
EOF
}

# ============================================================================
# HILFSFUNKTIONEN FÜR DAS SETUP
# ============================================================================

# Zone-ID ermitteln
list_zones() {
    local api_token="$1"
    
    if [[ -z "$api_token" ]]; then
        echo "Fehler: API-Token erforderlich"
        echo "Verwendung: list_zones 'your-api-token'"
        return 1
    fi
    
    echo "=== Verfügbare Zonen ==="
    curl -s "https://api.hetzner.cloud/v1/zones" \
        -H "Authorization: Bearer $api_token" | jq '.zones[] | {id, name}'
}

# Zone-Records anzeigen
list_zone_records() {
    local api_token="$1"
    local zone_id="$2"
    
    if [[ -z "$api_token" ]] || [[ -z "$zone_id" ]]; then
        echo "Fehler: API-Token und Zone-ID erforderlich"
        echo "Verwendung: list_zone_records 'token' 'zone-id'"
        return 1
    fi
    
    echo "=== Records der Zone $zone_id ==="
    curl -s "https://api.hetzner.cloud/v1/zones/$zone_id/rrsets" \
        -H "Authorization: Bearer $api_token" | jq '.rrsets[] | {name, type, ttl, records}'
}

# ============================================================================
# KONFIGURATIONSDATEI-VORLAGE
# ============================================================================

create_config_template() {
    cat > "$HOME/.hetzner-dyndns.conf" << 'EOF'
# Hetzner DynDNS - Konfigurationsdatei
# 
# Speicherort: ~/.hetzner-dyndns.conf
# Berechtigungen: chmod 600 ~/.hetzner-dyndns.conf
#
# Hinweis: Dieses Skript wird mittels "source" geladen, also sind
# alle bash-Variablen möglich.

# API-Token (erforderlich)
# Hole ihn von: https://console.hetzner.com/
HETZNER_AUTH_API_TOKEN="your-api-token-here"

# Zone-Name oder Zone-ID (erforderlich, verwende EINES davon)
HETZNER_ZONE_NAME="example.com"
# HETZNER_ZONE_ID="98jFjsd8dh1GHasdf7a8hJG7"

# Record-Name (erforderlich)
# Verwende "@" für den Zone-Apex (z.B. example.com)
# Verwende "dyn" für dyn.example.com
HETZNER_RECORD_NAME="dyn"

# Record-Type (optional, default: A)
# A = IPv4
# AAAA = IPv6
HETZNER_RECORD_TYPE="A"

# TTL in Sekunden (optional, default: 60)
# Empfohlen für DynDNS: 60-300 Sekunden
HETZNER_RECORD_TTL="120"

# Verbose-Modus (optional, default: false)
# Setzt auf "true" um Debug-Ausgaben zu sehen
HETZNER_VERBOSE="false"
EOF
    
    chmod 600 "$HOME/.hetzner-dyndns.conf"
    echo "✓ Konfigurationsdatei erstellt: $HOME/.hetzner-dyndns.conf"
    echo "  Bearbeite die Datei mit deinen Einstellungen:"
    echo "  nano $HOME/.hetzner-dyndns.conf"
}

# ============================================================================
# SYSTEMD-TIMER VORLAGE
# ============================================================================

create_systemd_timer() {
    local service_name="dyndns"
    local timer_file="/etc/systemd/system/${service_name}.timer"
    local service_file="/etc/systemd/system/${service_name}.service"
    
    echo "=== Systemd Timer Konfiguration ==="
    echo ""
    echo "Service-Datei: $service_file"
    echo "Timer-Datei: $timer_file"
    echo ""
    echo "Service ($service_file):"
    cat << 'EOF'
[Unit]
Description=Hetzner DNS DynDNS Update
After=network-online.target

[Service]
Type=oneshot
EnvironmentFile=%h/.hetzner-dyndns.conf
ExecStart=/usr/local/bin/dyndns.sh
StandardOutput=journal
StandardError=journal
SyslogIdentifier=dyndns
EOF
    
    echo ""
    echo "Timer ($timer_file):"
    cat << 'EOF'
[Unit]
Description=Hetzner DNS DynDNS Update Timer
Requires=dyndns.service

[Timer]
OnBootSec=1min
OnUnitActiveSec=5min
AccuracySec=1sec
Persistent=true

[Install]
WantedBy=timers.target
EOF
    
    echo ""
    echo "Aktivierung:"
    echo "  sudo systemctl daemon-reload"
    echo "  sudo systemctl enable --now dyndns.timer"
    echo "  sudo systemctl status dyndns.timer"
    echo ""
}

# ============================================================================
# INTERAKTIVES SETUP
# ============================================================================

interactive_setup() {
    clear
    
    echo "╔════════════════════════════════════════╗"
    echo "║   Hetzner DynDNS - Interaktives Setup   ║"
    echo "╚════════════════════════════════════════╝"
    echo ""
    
    read -p "API-Token eingeben: " api_token
    
    if [[ -z "$api_token" ]]; then
        echo "✗ API-Token erforderlich"
        return 1
    fi
    
    echo ""
    echo "=== Verfügbare Zonen ==="
    list_zones "$api_token" || return 1
    
    echo ""
    read -p "Zone-Name eingeben (z.B. example.com): " zone_name
    
    # Ermittle Zone-ID
    local zone_id
    zone_id=$(curl -s "https://api.hetzner.cloud/v1/zones?name=$zone_name" \
        -H "Authorization: Bearer $api_token" | jq -r '.zones[0].id')
    
    if [[ -z "$zone_id" ]] || [[ "$zone_id" == "null" ]]; then
        echo "✗ Zone nicht gefunden"
        return 1
    fi
    
    echo "✓ Zone-ID: $zone_id"
    echo ""
    
    echo "=== Records der Zone ==="
    list_zone_records "$api_token" "$zone_id" || return 1
    
    echo ""
    read -p "Record-Name eingeben (z.B. dyn): " record_name
    
    read -p "Record-Type eingeben (A/AAAA) [default: A]: " record_type
    record_type="${record_type:-A}"
    
    read -p "TTL eingeben [default: 60]: " record_ttl
    record_ttl="${record_ttl:-60}"
    
    echo ""
    echo "=== Zusammenfassung ==="
    echo "Zone: $zone_name ($zone_id)"
    echo "Record: $record_name ($record_type)"
    echo "TTL: $record_ttl"
    echo ""
    
    read -p "Speichere diese Konfiguration? (j/n): " save_config
    
    if [[ "$save_config" == "j" ]]; then
        cat > "$HOME/.hetzner-dyndns.conf" << EOF
HETZNER_AUTH_API_TOKEN="$api_token"
HETZNER_ZONE_NAME="$zone_name"
HETZNER_RECORD_NAME="$record_name"
HETZNER_RECORD_TYPE="$record_type"
HETZNER_RECORD_TTL="$record_ttl"
EOF
        
        chmod 600 "$HOME/.hetzner-dyndns.conf"
        echo "✓ Konfigurationsdatei erstellt: ~/.hetzner-dyndns.conf"
    fi
    
    echo ""
    read -p "Test-Update durchführen? (j/n): " test_update
    
    if [[ "$test_update" == "j" ]]; then
        source "$HOME/.hetzner-dyndns.conf"
        /usr/local/bin/dyndns.sh -v
    fi
}

# ============================================================================
# HAUPTMENÜ
# ============================================================================

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "${1:-menu}" in
        example1)
            example_minimal
            ;;
        example2)
            example_ipv6
            ;;
        example3)
            example_custom_ttl
            ;;
        example4)
            example_zone_id
            ;;
        example5)
            example_env_vars
            ;;
        example6)
            example_config_file
            ;;
        example7)
            example_verbose
            ;;
        example8)
            example_multiple_records
            ;;
        example9)
            example_with_error_handling
            ;;
        example10)
            example_cron_setup
            ;;
        list-zones)
            list_zones "${2:-}"
            ;;
        list-records)
            list_zone_records "${2:-}" "${3:-}"
            ;;
        create-config)
            create_config_template
            ;;
        systemd)
            create_systemd_timer
            ;;
        setup)
            interactive_setup
            ;;
        *)
            cat << 'EOF'
Hetzner DynDNS - Konfigurationsbeispiele

Verfügbare Beispiele:
  ./config-examples.sh example1      - Minimale Konfiguration
  ./config-examples.sh example2      - IPv6-Support
  ./config-examples.sh example3      - Benutzerdefinierte TTL
  ./config-examples.sh example4      - Zone-ID verwenden
  ./config-examples.sh example5      - Umgebungsvariablen
  ./config-examples.sh example6      - Konfigurationsdatei
  ./config-examples.sh example7      - Verbose-Debugging
  ./config-examples.sh example8      - Mehrere Records
  ./config-examples.sh example9      - Mit Fehlerbehandlung
  ./config-examples.sh example10     - Cron-Setup

Hilfsfunktionen:
  ./config-examples.sh list-zones <token>              - Zones auflisten
  ./config-examples.sh list-records <token> <zone-id>  - Records auflisten
  ./config-examples.sh create-config                   - Config-Datei erstellen
  ./config-examples.sh systemd                         - Systemd-Timer zeigen
  ./config-examples.sh setup                           - Interaktives Setup

EOF
            ;;
    esac
fi
