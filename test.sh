#!/bin/bash

################################################################################
# Testscript für Hetzner DynDNS
# 
# Führe verschiedene Tests durch, um sicherzustellen dass dyndns.sh
# richtig konfiguriert und funktioniert.
################################################################################

set -o pipefail

readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

# Zähler für Tests
tests_total=0
tests_passed=0
tests_failed=0

################################################################################
# Hilfsfunktionen
################################################################################

test_header() {
    echo -e "\n${BLUE}=== $1 ===${NC}\n"
}

test_pass() {
    ((tests_passed++))
    ((tests_total++))
    echo -e "${GREEN}✓ PASS${NC}: $1"
}

test_fail() {
    ((tests_failed++))
    ((tests_total++))
    echo -e "${RED}✗ FAIL${NC}: $1"
}

test_skip() {
    echo -e "${YELLOW}⊘ SKIP${NC}: $1"
}

test_info() {
    echo -e "${BLUE}ℹ INFO${NC}: $1"
}

summary() {
    echo -e "\n${BLUE}=== Testergebnis ===${NC}"
    echo -e "Gesamt: ${YELLOW}$tests_total${NC}"
    echo -e "Bestanden: ${GREEN}$tests_passed${NC}"
    echo -e "Fehlgeschlagen: ${RED}$tests_failed${NC}"
    
    if [[ $tests_failed -eq 0 ]] && [[ $tests_total -gt 0 ]]; then
        echo -e "\n${GREEN}✓ Alle Tests bestanden!${NC}"
        return 0
    else
        echo -e "\n${RED}✗ Einige Tests sind fehlgeschlagen${NC}"
        return 1
    fi
}

################################################################################
# Prerequisite Tests
################################################################################

test_prerequisites() {
    test_header "Voraussetzungen überprüfen"
    
    # curl
    if command -v curl &> /dev/null; then
        test_pass "curl ist installiert"
    else
        test_fail "curl ist NICHT installiert"
        return 1
    fi
    
    # jq
    if command -v jq &> /dev/null; then
        test_pass "jq ist installiert"
    else
        test_fail "jq ist NICHT installiert"
        return 1
    fi
    
    # bash
    if [[ ${BASH_VERSINFO[0]} -ge 4 ]]; then
        test_pass "Bash 4.0+ ist installiert (Version ${BASH_VERSION})"
    else
        test_fail "Bash 4.0+ erforderlich (aktuelle Version ${BASH_VERSION})"
        return 1
    fi
}

################################################################################
# Script Tests
################################################################################

test_script_exists() {
    test_header "Script-Existenz überprüfen"
    
    if [[ -f "./dyndns.sh" ]]; then
        test_pass "dyndns.sh existiert"
    else
        test_fail "dyndns.sh nicht gefunden"
        return 1
    fi
}

test_script_executable() {
    test_header "Script-Berechtigungen überprüfen"
    
    if [[ -x "./dyndns.sh" ]]; then
        test_pass "dyndns.sh ist ausführbar"
    else
        test_fail "dyndns.sh ist NICHT ausführbar"
        test_info "Führe aus: chmod +x dyndns.sh"
    fi
}

test_script_syntax() {
    test_header "Bash-Syntax überprüfen"
    
    if bash -n ./dyndns.sh 2>/dev/null; then
        test_pass "dyndns.sh hat korrekte Bash-Syntax"
    else
        test_fail "dyndns.sh hat Syntax-Fehler"
        bash -n ./dyndns.sh
    fi
}

test_help_output() {
    test_header "Help-Ausgabe überprüfen"
    
    local help_output
    help_output=$("./dyndns.sh" -h 2>&1)
    
    if echo "$help_output" | grep -q "VERWENDUNG"; then
        test_pass "Help-Text enthält 'VERWENDUNG'"
    else
        test_fail "Help-Text fehlerhaft"
    fi
    
    if echo "$help_output" | grep -q "ERFORDERLICHE PARAMETER"; then
        test_pass "Help-Text enthält 'ERFORDERLICHE PARAMETER'"
    else
        test_fail "Help-Text fehlerhaft"
    fi
    
    if echo "$help_output" | grep -q "BEISPIELE"; then
        test_pass "Help-Text enthält 'BEISPIELE'"
    else
        test_fail "Help-Text fehlerhaft"
    fi
}

################################################################################
# Konfiguration Tests
################################################################################

test_environment_variables() {
    test_header "Umgebungsvariablen-Unterstützung"
    
    if grep -q "HETZNER_AUTH_API_TOKEN" dyndns.sh; then
        test_pass "HETZNER_AUTH_API_TOKEN wird unterstützt"
    else
        test_fail "HETZNER_AUTH_API_TOKEN wird NICHT unterstützt"
    fi
    
    if grep -q "HETZNER_ZONE_NAME" dyndns.sh; then
        test_pass "HETZNER_ZONE_NAME wird unterstützt"
    else
        test_fail "HETZNER_ZONE_NAME wird NICHT unterstützt"
    fi
    
    if grep -q "HETZNER_ZONE_ID" dyndns.sh; then
        test_pass "HETZNER_ZONE_ID wird unterstützt"
    else
        test_fail "HETZNER_ZONE_ID wird NICHT unterstützt"
    fi
    
    if grep -q "HETZNER_RECORD_NAME" dyndns.sh; then
        test_pass "HETZNER_RECORD_NAME wird unterstützt"
    else
        test_fail "HETZNER_RECORD_NAME wird NICHT unterstützt"
    fi
}

################################################################################
# API Tests
################################################################################

test_api_connectivity() {
    test_header "API-Erreichbarkeit überprüfen"
    
    if curl -s "https://api.hetzner.cloud/v1/zones" \
        -H "Authorization: Bearer invalid-token" | jq . > /dev/null 2>&1; then
        test_pass "Hetzner API ist erreichbar"
    else
        test_fail "Hetzner API ist NICHT erreichbar"
    fi
}

test_ipv4_detection() {
    test_header "IPv4-Erkennung testen"
    
    local ipv4
    ipv4=$(curl -s "https://api.ipify.org?format=text" 2>/dev/null)
    
    if [[ $ipv4 =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        test_pass "Öffentliche IPv4 erkannt: $ipv4"
    else
        test_fail "Konnte öffentliche IPv4 nicht ermitteln"
    fi
}

test_ipv6_detection() {
    test_header "IPv6-Erkennung testen"
    
    local ipv6
    ipv6=$(curl -s -6 "https://api6.ipify.org?format=text" 2>/dev/null)
    
    if [[ -n "$ipv6" ]] && [[ "$ipv6" =~ ^[0-9a-fA-F:]+$ ]]; then
        test_pass "Öffentliche IPv6 erkannt: $ipv6"
    else
        test_skip "IPv6 ist auf diesem System nicht verfügbar"
    fi
}

################################################################################
# Konfigurationsdatei-Tests
################################################################################

test_config_example() {
    test_header "Config-Beispiele überprüfen"
    
    if [[ -f "config-examples.sh" ]]; then
        test_pass "config-examples.sh existiert"
        
        if bash -n config-examples.sh 2>/dev/null; then
            test_pass "config-examples.sh hat korrekte Syntax"
        else
            test_fail "config-examples.sh hat Syntax-Fehler"
        fi
    else
        test_fail "config-examples.sh nicht gefunden"
    fi
}

test_readme() {
    test_header "Dokumentation überprüfen"
    
    if [[ -f "README.md" ]]; then
        test_pass "README.md existiert"
        
        if grep -q "Installation" README.md; then
            test_pass "README enthält 'Installation'"
        else
            test_fail "README fehlt 'Installation'-Sektion"
        fi
        
        if grep -q "Beispiele" README.md; then
            test_pass "README enthält 'Beispiele'"
        else
            test_fail "README fehlt 'Beispiele'-Sektion"
        fi
        
        if grep -q "Cron" README.md; then
            test_pass "README enthält 'Cron'-Information"
        else
            test_fail "README fehlt 'Cron'-Information"
        fi
    else
        test_fail "README.md nicht gefunden"
    fi
}

################################################################################
# Integration Tests
################################################################################

test_no_token_error() {
    test_header "Fehlerbehandlung: Fehlender API-Token"
    
    local output
    output=$("./dyndns.sh" -Z "example.com" -n "dyn" 2>&1)
    
    if echo "$output" | grep -q "HETZNER_AUTH_API_TOKEN"; then
        test_pass "Script gibt aussagekräftige Fehlermeldung aus"
    else
        test_fail "Fehlermeldung nicht aussagekräftig"
    fi
}

test_help_flag() {
    test_header "Help-Flag testen"
    
    local exit_code
    "./dyndns.sh" -h > /dev/null 2>&1
    exit_code=$?
    
    if [[ $exit_code -eq 0 ]]; then
        test_pass "Help-Flag (-h) funktioniert korrekt"
    else
        test_fail "Help-Flag (-h) gibt Fehler zurück"
    fi
}

################################################################################
# Performance Tests
################################################################################

test_execution_time() {
    test_header "Performance überprüfen"
    
    local start_time
    local end_time
    local execution_time
    
    start_time=$(date +%s%N)
    bash -c 'source ./dyndns.sh' 2>/dev/null
    end_time=$(date +%s%N)
    
    execution_time=$(( (end_time - start_time) / 1000000 ))  # Millisekunden
    
    if [[ $execution_time -lt 1000 ]]; then
        test_pass "Script-Laden dauert weniger als 1 Sekunde ($execution_time ms)"
    else
        test_info "Script-Laden dauert $execution_time ms"
    fi
}

################################################################################
# Main Test Runner
################################################################################

main() {
    echo -e "${BLUE}"
    cat << 'EOF'
╔═══════════════════════════════════════════╗
║   Hetzner DynDNS - Test Suite               ║
╚═══════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    
    # Überprüfe ob wir im richtigen Verzeichnis sind
    if [[ ! -f "dyndns.sh" ]]; then
        echo -e "${RED}Fehler: dyndns.sh nicht gefunden${NC}"
        echo "Bitte führe dieses Script im Verzeichnis mit dyndns.sh aus"
        exit 1
    fi
    
    # Führe alle Tests aus
    test_prerequisites || exit 1
    test_script_exists
    test_script_executable
    test_script_syntax
    test_help_output
    test_environment_variables
    test_api_connectivity
    test_ipv4_detection
    test_ipv6_detection
    test_config_example
    test_readme
    test_no_token_error
    test_help_flag
    test_execution_time
    
    # Zeige Zusammenfassung
    summary
}

# Starte Tests
main "$@"
