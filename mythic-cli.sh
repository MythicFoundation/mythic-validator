#!/usr/bin/env bash
# =============================================================================
# Mythic CLI
# Lightweight CLI for the Mythic L2 AI-native blockchain.
#
# Install:
#   curl -sSf mythic.sh/cli | bash
#
# Usage:
#   mythic <command> [options]
#
# Commands:
#   validator install          Install Firedancer validator node
#   validator register         Register validator on-chain
#   validator status           Check validator and network status
#   validator claim            Claim staking rewards
#   validator logs             View validator service logs
#   fee info                   Current fee recommendation
#   supply                     MYTH supply and burn stats
#   version                    Show CLI version
# =============================================================================
set -euo pipefail

MYTHIC_CLI_VERSION="1.0.0"
MYTHIC_RPC="https://rpc.mythic.sh"
MYTHIC_API="https://mythic.sh"
MYTHIC_BIN_DIR="${HOME}/.mythic/bin"
MYTHIC_CONFIG_DIR="/etc/mythic"

# ── Self-Install ──────────────────────────────────────────────────────────────

cli_install() {
    echo ""
    echo "  Installing Mythic CLI v${MYTHIC_CLI_VERSION}..."
    mkdir -p "${MYTHIC_BIN_DIR}"

    # Download latest CLI to bin dir
    if curl -sSfL "${MYTHIC_API}/mythic-cli.sh" -o "${MYTHIC_BIN_DIR}/mythic" 2>/dev/null; then
        chmod +x "${MYTHIC_BIN_DIR}/mythic"
    else
        # Fallback: copy self
        cp "$0" "${MYTHIC_BIN_DIR}/mythic" 2>/dev/null || {
            echo "  Downloading CLI script..."
            curl -sSfL "${MYTHIC_API}/cli" -o "${MYTHIC_BIN_DIR}/mythic"
            chmod +x "${MYTHIC_BIN_DIR}/mythic"
        }
    fi

    # Add to PATH if not already there
    SHELL_RC=""
    if [ -f "${HOME}/.bashrc" ]; then
        SHELL_RC="${HOME}/.bashrc"
    elif [ -f "${HOME}/.zshrc" ]; then
        SHELL_RC="${HOME}/.zshrc"
    elif [ -f "${HOME}/.profile" ]; then
        SHELL_RC="${HOME}/.profile"
    fi

    if [ -n "${SHELL_RC}" ]; then
        if ! grep -q '\.mythic/bin' "${SHELL_RC}" 2>/dev/null; then
            echo '' >> "${SHELL_RC}"
            echo '# Mythic CLI' >> "${SHELL_RC}"
            echo 'export PATH="${HOME}/.mythic/bin:${PATH}"' >> "${SHELL_RC}"
            echo "  Added ~/.mythic/bin to PATH in $(basename "${SHELL_RC}")"
        fi
    fi

    echo "  Installed: ${MYTHIC_BIN_DIR}/mythic"
    echo ""
    echo "  Restart your shell or run:"
    echo "    export PATH=\"\${HOME}/.mythic/bin:\${PATH}\""
    echo ""
    echo "  Then run: mythic version"
    echo ""
}

# ── Banner ────────────────────────────────────────────────────────────────────

print_banner() {
    echo ""
    echo "    /\\"
    echo "   /  \\"
    echo "  / /\\ \\"
    echo " / /  \\ \\"
    echo "/ /    \\ \\"
    echo "\\ \\    / /"
    echo " \\ \\  / /"
    echo "  \\ \\/ /"
    echo "   \\  /"
    echo "    \\/"
    echo ""
    echo "  Mythic CLI v${MYTHIC_CLI_VERSION}"
    echo "  The AI-Native Blockchain"
    echo ""
}

# ── Validator Commands ────────────────────────────────────────────────────────

validator_install() {
    echo "Downloading and running Mythic validator installer..."
    echo ""
    curl -sSfL "${MYTHIC_API}/install" | sudo bash
}

validator_register() {
    local STAKE_AMOUNT=""
    local AI_FLAG=""

    while [ $# -gt 0 ]; do
        case "$1" in
            --stake)
                STAKE_AMOUNT="$2"
                shift 2
                ;;
            --ai)
                AI_FLAG="true"
                shift
                ;;
            *)
                shift
                ;;
        esac
    done

    if [ -z "${STAKE_AMOUNT}" ]; then
        echo "Usage: mythic validator register --stake <amount_sol> [--ai]"
        echo ""
        echo "Options:"
        echo "  --stake <amount>   SOL to stake with validator"
        echo "  --ai               Register as AI-capable validator (2x rewards)"
        exit 1
    fi

    IDENTITY="${MYTHIC_CONFIG_DIR}/validator-identity.json"
    VOTE="${MYTHIC_CONFIG_DIR}/vote-account.json"

    if [ ! -f "${IDENTITY}" ]; then
        echo "Error: Validator identity not found at ${IDENTITY}"
        echo "Run 'mythic validator install' first."
        exit 1
    fi

    IDENTITY_PUBKEY=$(solana-keygen pubkey "${IDENTITY}")
    VOTE_PUBKEY=$(solana-keygen pubkey "${VOTE}")

    echo "Registering validator on Mythic L2..."
    echo "  Identity: ${IDENTITY_PUBKEY}"
    echo "  Vote:     ${VOTE_PUBKEY}"
    echo "  Stake:    ${STAKE_AMOUNT} SOL"
    if [ "${AI_FLAG}" = "true" ]; then
        echo "  AI:       enabled (2x reward multiplier)"
    fi
    echo ""

    # Create vote account on-chain
    echo "Creating vote account..."
    solana create-vote-account "${VOTE}" "${IDENTITY}" \
        "${IDENTITY_PUBKEY}" \
        --url "${MYTHIC_RPC}" \
        --keypair "${IDENTITY}" \
        --commitment confirmed

    # Delegate stake
    echo "Delegating ${STAKE_AMOUNT} SOL stake..."
    solana delegate-stake "${VOTE_PUBKEY}" "${VOTE_PUBKEY}" \
        --url "${MYTHIC_RPC}" \
        --keypair "${IDENTITY}" \
        --force \
        --commitment confirmed 2>/dev/null || true

    # Register with staking program (if AI)
    if [ "${AI_FLAG}" = "true" ]; then
        echo "Registering as AI-capable validator..."
        solana program invoke MythStak11111111111111111111111111111111111 \
            --url "${MYTHIC_RPC}" \
            --keypair "${IDENTITY}" \
            2>/dev/null || echo "  Note: AI registration requires manual tx. See docs."
    fi

    echo ""
    echo "Validator registered. Start with: sudo systemctl start mythic-validator"
}

validator_status() {
    echo "Mythic Validator Status"
    echo "======================"
    echo ""

    # Local service status
    echo "-- Local Service --"
    if command -v systemctl >/dev/null 2>&1; then
        if systemctl is-active mythic-validator >/dev/null 2>&1; then
            echo "  Service:  running"
            UPTIME=$(systemctl show mythic-validator --property=ActiveEnterTimestamp 2>/dev/null | cut -d= -f2)
            echo "  Since:    ${UPTIME:-unknown}"
        else
            echo "  Service:  stopped"
        fi
    else
        echo "  Service:  systemd not available"
    fi

    # Identity
    if [ -f "${MYTHIC_CONFIG_DIR}/validator-identity.json" ]; then
        IDENTITY=$(solana-keygen pubkey "${MYTHIC_CONFIG_DIR}/validator-identity.json" 2>/dev/null || echo "unknown")
        echo "  Identity: ${IDENTITY}"
    fi

    echo ""

    # Network status from supply oracle
    echo "-- Network --"
    SUPPLY_DATA=$(curl -sSf "${MYTHIC_API}/api/supply/stats" 2>/dev/null || echo "")
    if [ -n "${SUPPLY_DATA}" ]; then
        _jqn() { echo "${SUPPLY_DATA}" | jq -r ".$1 // empty" 2>/dev/null || echo "${SUPPLY_DATA}" | grep -o "\"$1\"[[:space:]]*:[[:space:]]*[^,}]*" | head -1 | sed 's/.*:[[:space:]]*//' | tr -d '"'; }
        echo "  Epoch:    $(_jqn currentEpoch)"
        echo "  Burned:   $(_jqn totalBurned) MYTH"
        echo "  Rewards:  $(_jqn validatorRewards) MYTH"
    else
        echo "  Could not reach network. Check RPC: ${MYTHIC_RPC}"
    fi

    # Validator list
    echo ""
    echo "-- Validators --"
    VALIDATORS=$(curl -sSf "${MYTHIC_API}/api/supply/validators" 2>/dev/null || echo "")
    if [ -n "${VALIDATORS}" ]; then
        _jqv() { echo "${VALIDATORS}" | jq -r ".$1 // empty" 2>/dev/null || echo "${VALIDATORS}" | grep -o "\"$1\"[[:space:]]*:[[:space:]]*[^,}]*" | head -1 | sed 's/.*:[[:space:]]*//' | tr -d '"'; }
        echo "  Total:    $(_jqv count)"
        echo "  Active:   $(_jqv active)"
        echo "  Staked:   $(_jqv totalStake) MYTH"
    else
        echo "  Could not reach validator API."
    fi
    echo ""
}

validator_claim() {
    IDENTITY="${MYTHIC_CONFIG_DIR}/validator-identity.json"

    if [ ! -f "${IDENTITY}" ]; then
        echo "Error: Validator identity not found at ${IDENTITY}"
        exit 1
    fi

    IDENTITY_PUBKEY=$(solana-keygen pubkey "${IDENTITY}")
    echo "Claiming rewards for ${IDENTITY_PUBKEY}..."

    solana withdraw-from-vote-account \
        "${MYTHIC_CONFIG_DIR}/vote-account.json" \
        "${IDENTITY_PUBKEY}" ALL \
        --url "${MYTHIC_RPC}" \
        --keypair "${IDENTITY}" \
        --commitment confirmed 2>/dev/null || {
        echo "Note: Vote account reward withdrawal may require authorized withdrawer."
        echo "Check docs: ${MYTHIC_API}/docs/validators"
    }

    echo ""
    echo "Balance: $(solana balance "${IDENTITY_PUBKEY}" --url "${MYTHIC_RPC}" 2>/dev/null || echo 'check manually')"
}

validator_logs() {
    if command -v journalctl >/dev/null 2>&1; then
        journalctl -u mythic-validator -f --no-pager
    elif [ -f "/var/log/mythic/firedancer.log" ]; then
        tail -f /var/log/mythic/firedancer.log
    else
        echo "No logs found. Is the validator installed?"
        echo "  Run: mythic validator install"
    fi
}

# ── Fee Commands ──────────────────────────────────────────────────────────────

fee_info() {
    echo "Mythic Fee Recommendation"
    echo "========================="
    echo ""

    FEE_DATA=$(curl -sSf "${MYTHIC_API}/api/supply/fee-oracle" 2>/dev/null || echo "")
    if [ -n "${FEE_DATA}" ]; then
        _jq_field() { echo "${FEE_DATA}" | jq -r ".$1 // empty" 2>/dev/null || echo "${FEE_DATA}" | grep -o "\"$1\"[[:space:]]*:[[:space:]]*[^,}]*" | head -1 | sed 's/.*:[[:space:]]*//' | tr -d '"'; }
        REC_FEE=$(_jq_field recommendedFee)
        REC_LAMPORTS=$(_jq_field recommendedFeeLamports)
        REC_USD=$(_jq_field recommendedFeeUsd)
        SOL_BASE=$(_jq_field solBaseFeeUsd)
        DISCOUNT=$(_jq_field discountPercent)
        MYTH_PRICE=$(_jq_field "prices.mythUsd" 2>/dev/null || echo "${FEE_DATA}" | grep -o '"mythUsd"[[:space:]]*:[[:space:]]*[0-9.e-]*' | head -1 | sed 's/.*://' | tr -d ' ')
        SOL_PRICE=$(_jq_field "prices.solUsd" 2>/dev/null || echo "${FEE_DATA}" | grep -o '"solUsd"[[:space:]]*:[[:space:]]*[0-9.]*' | head -1 | sed 's/.*://' | tr -d ' ')
        LAST_UPDATE=$(_jq_field lastUpdate)

        echo "  Recommended Fee:  ${REC_FEE:-N/A} MYTH"
        echo "  In Lamports:      ${REC_LAMPORTS:-N/A}"
        echo "  In USD:           \$${REC_USD:-N/A}"
        echo ""
        echo "  Solana L1 Fee:    \$${SOL_BASE:-N/A}"
        echo "  Discount:         ${DISCOUNT:-25}% cheaper than L1"
        echo ""
        echo "  MYTH Price:       \$${MYTH_PRICE:-N/A}"
        echo "  SOL Price:        \$${SOL_PRICE:-N/A}"
        echo "  Fee Split:        50% validators / 10% foundation / 40% burn"
        echo "  Last Update:      ${LAST_UPDATE:-N/A}"
    else
        echo "  Fee oracle unavailable."
        echo "  Fee split:  50% validators / 10% foundation / 40% burn"
        echo "  Details:    ${MYTHIC_API}/api/supply/fee-oracle"
    fi
    echo ""
}

# ── Supply Command ────────────────────────────────────────────────────────────

supply_info() {
    echo "MYTH Supply Stats"
    echo "================="
    echo ""

    SUPPLY=$(curl -sSf "${MYTHIC_API}/api/supply" 2>/dev/null || echo "")

    if [ -n "${SUPPLY}" ]; then
        _jq() { echo "${SUPPLY}" | jq -r ".$1 // empty" 2>/dev/null || echo "${SUPPLY}" | grep -o "\"$1\"[[:space:]]*:[[:space:]]*[^,}]*" | head -1 | sed 's/.*:[[:space:]]*//' | tr -d '"'; }
        echo "  Total Supply:       $(_jq totalSupply) MYTH"
        echo "  Circulating:        $(_jq circulating) MYTH"
        echo "  Burned:             $(_jq burned) MYTH"
        echo "  Burn Rate (24h):    $(_jq burnRate24h) MYTH"
        echo "  Burn Rate (7d):     $(_jq burnRateWeek) MYTH"
    else
        echo "  Could not reach API."
        echo "  Supply API: ${MYTHIC_API}/api/supply"
    fi

    STATS=$(curl -sSf "${MYTHIC_API}/api/supply/stats" 2>/dev/null || echo "")
    if [ -n "${STATS}" ]; then
        _jqs() { echo "${STATS}" | jq -r ".$1 // empty" 2>/dev/null || echo "${STATS}" | grep -o "\"$1\"[[:space:]]*:[[:space:]]*[^,}]*" | head -1 | sed 's/.*:[[:space:]]*//' | tr -d '"'; }
        echo ""
        echo "  Distribution:"
        echo "  Validator Rewards:  $(_jqs validatorRewards) MYTH"
        echo "  Current Epoch:      $(_jqs currentEpoch)"
    fi

    PRICE=$(curl -sSf "${MYTHIC_API}/price" 2>/dev/null || echo "")
    if [ -n "${PRICE}" ]; then
        _jqp() { echo "${PRICE}" | jq -r ".$1 // empty" 2>/dev/null || echo "${PRICE}" | grep -o "\"$1\"[[:space:]]*:[[:space:]]*[^,}]*" | head -1 | sed 's/.*:[[:space:]]*//' | tr -d '"'; }
        echo ""
        echo "  Market:"
        echo "  Price:              \$$(_jqp price)"
        echo "  Market Cap:         \$$(_jqp marketCap)"
        echo "  Volume (24h):       \$$(_jqp volume24h)"
    fi

    echo ""
}

# ── Help ──────────────────────────────────────────────────────────────────────

print_help() {
    print_banner
    echo "  Usage: mythic <command> [options]"
    echo ""
    echo "  Validator:"
    echo "    validator install                 Install Firedancer validator node"
    echo "    validator register --stake <n>    Register validator on-chain"
    echo "    validator status                  Check validator and network status"
    echo "    validator claim                   Claim staking rewards"
    echo "    validator logs                    View validator service logs"
    echo ""
    echo "  Network:"
    echo "    fee info                          Current fee info and burn stats"
    echo "    supply                            MYTH supply and burn stats"
    echo ""
    echo "  Other:"
    echo "    install                           Install this CLI to ~/.mythic/bin"
    echo "    version                           Show CLI version"
    echo "    help                              Show this help"
    echo ""
    echo "  Docs: https://mythic.sh/docs"
    echo ""
}

# ── Main Router ───────────────────────────────────────────────────────────────

main() {
    # When piped from curl with no args, self-install
    if [ $# -eq 0 ]; then
        if [ ! -t 0 ]; then
            # Piped from curl — install mode
            print_banner
            cli_install
            exit 0
        fi
        print_help
        exit 0
    fi

    case "$1" in
        install)
            print_banner
            cli_install
            ;;
        validator)
            shift
            case "${1:-}" in
                install)    validator_install ;;
                register)   shift; validator_register "$@" ;;
                status)     validator_status ;;
                claim)      validator_claim ;;
                logs)       validator_logs ;;
                *)          echo "Usage: mythic validator <install|register|status|claim|logs>"; exit 1 ;;
            esac
            ;;
        fee)
            shift
            case "${1:-}" in
                info)   fee_info ;;
                *)      echo "Usage: mythic fee <info>"; exit 1 ;;
            esac
            ;;
        supply)
            supply_info
            ;;
        version)
            echo "mythic ${MYTHIC_CLI_VERSION}"
            ;;
        help|--help|-h)
            print_help
            ;;
        *)
            echo "Unknown command: $1"
            echo "Run 'mythic help' for usage."
            exit 1
            ;;
    esac
}

main "$@"
