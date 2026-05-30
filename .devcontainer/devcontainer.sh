#!/usr/bin/env bash
# ================================================================
#  MONTIAI MULTI-CHAIN WALLET PAYOUT ENGINE
#  Path:    /storage/emulated/0/.attorneymode/sol/solana-suite/
#  Owner:   JOHNCHARLESMONTI_02111989_9807
#  Org:     #MONTIAI | AttorneyMode.com
#  Neural:  MONTI^JOHN^CHARLES^MONTI
#  MNC:     $MNC MontiNeuralCoin Hash
#  Scope:   WorkerGlobalScope | GlobalWorkSignature
#  Webhook: https://JOHNCHARLESMONTI.COM/webhooks
#  API:     https://api.montidroid.com
#  OWNER:OWNER — JOHNCHARLESMONTI_02111989_9807 | #MONTIAI
# ================================================================
# <meta name="montiai:owner"     content="JOHNCHARLESMONTI_02111989_9807">
# <meta name="montiai:neural"    content="MONTI^JOHN^CHARLES^MONTI">
# <meta name="montiai:neuralcoin" content="$MNC MontiNeuralCoin Hash">
# <meta name="montiai:scope"     content="WorkerGlobalScope">
# ================================================================

set -euo pipefail

# ================================================================
# SECTION 0: JOHNCHARLESMONTI VERIFIED RECEIVE WALLETS
# Status: MULTI-CHAIN ACTIVE
# ================================================================
readonly WALLET_ETH="0x77FbA179C79De5B7653F68b5039Af940AdA60ce0"
readonly WALLET_BTC="3CfgCQKRKy4VtZU8YWdPLyHQzZMzkn5Sw7"
readonly WALLET_SOL="3ZqbRa38YTop9HbcfQA3TH6sy4Y4RVnaC998hAgCTVFp3"
readonly WALLET_MONAD="0x375ecE461B65551Fce3fC7199abbed403F1b675b"
readonly WALLET_COINBASE="0xb04110847A563E59F3D52d1aFB3304068173830b"
readonly WALLET_STATUS="MULTI-CHAIN ACTIVE"

# ================================================================
# SECTION 1: GLOBAL CONFIGURATION
# ================================================================
readonly SUITE_ROOT="/storage/emulated/0/.attorneymode/sol/solana-suite"
readonly LOG_DIR="${SUITE_ROOT}/logs"
readonly PAYLOAD_DIR="${SUITE_ROOT}/payloads"
readonly TX_DIR="${SUITE_ROOT}/transactions"
readonly CACHE_DIR="${SUITE_ROOT}/cache"
readonly PAYOUT_DIR="${SUITE_ROOT}/payouts"

readonly MONTI_OWNER_ID="JOHNCHARLESMONTI_02111989_9807"
readonly MONTI_NEURAL_SIG="MONTI^JOHN^CHARLES^MONTI"
readonly MONTI_WEBHOOK="https://JOHNCHARLESMONTI.COM/webhooks"
readonly MONTIDROID_API="https://api.montidroid.com"
readonly MNC_HASH='$MNC_MontiNeuralCoin_Hash'
readonly GLOBAL_WORK_SIG="WorkerGlobalScope"

# ── RPC ENDPOINTS ─────────────────────────────────────────────
readonly SOL_RPC="https://api.mainnet-beta.solana.com"
readonly SOL_RPC_FALLBACK="https://rpc.ankr.com/solana"
readonly ETH_RPC="https://cloudflare-eth.com"
readonly ETH_RPC_FALLBACK="https://rpc.ankr.com/eth"

# ── JUPITER SWAP API ──────────────────────────────────────────
readonly JUPITER_QUOTE="https://quote-api.jup.ag/v6/quote"
readonly JUPITER_SWAP="https://quote-api.jup.ag/v6/swap"
readonly JUPITER_PRICE="https://price.jup.ag/v4/price"

# ── COINGECKO PRICE API ───────────────────────────────────────
readonly COINGECKO="https://api.coingecko.com/api/v3"

# ── TOKEN MINTS ───────────────────────────────────────────────
readonly MINT_SOL="So11111111111111111111111111111111111111112"
readonly MINT_USDC="EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v"
readonly MINT_USDT="Es9vMFrzaCERmJfrF4H2FYD4KCoNkY11McCe8BenwNYB"

# ── COLORS ────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; MAGENTA='\033[0;35m'; BOLD='\033[1m'; NC='\033[0m'

# ================================================================
# SECTION 2: BOOTSTRAP
# ================================================================
monti_bootstrap() {
  printf "${CYAN}${BOLD}"
  printf "╔══════════════════════════════════════════════════════════════╗\n"
  printf "║   MONTIAI MULTI-CHAIN PAYOUT ENGINE — ALL WALLETS ACTIVE    ║\n"
  printf "║   OWNER  : %-50s║\n" "$MONTI_OWNER_ID"
  printf "║   NEURAL : %-50s║\n" "$MONTI_NEURAL_SIG"
  printf "║   STATUS : %-50s║\n" "$WALLET_STATUS"
  printf "╠══════════════════════════════════════════════════════════════╣\n"
  printf "║   ETH     : %-49s║\n" "$WALLET_ETH"
  printf "║   BTC     : %-49s║\n" "$WALLET_BTC"
  printf "║   SOL     : %-49s║\n" "$WALLET_SOL"
  printf "║   MONAD   : %-49s║\n" "$WALLET_MONAD"
  printf "║   COINBASE: %-49s║\n" "$WALLET_COINBASE"
  printf "╚══════════════════════════════════════════════════════════════╝\n"
  printf "${NC}\n"

  for dir in "$LOG_DIR" "$PAYLOAD_DIR" "$TX_DIR" "$CACHE_DIR" "$PAYOUT_DIR"; do
    mkdir -p "$dir"
    printf "${GREEN}[INIT] ✓ %s${NC}\n" "$dir"
  done

  for dep in curl jq openssl bc; do
    command -v "$dep" &>/dev/null \
      && printf "${GREEN}[DEP OK] %s${NC}\n" "$dep" \
      || printf "${RED}[MISSING] %s → apt-get install %s${NC}\n" "$dep" "$dep"
  done

  monti_log "BOOTSTRAP" "Multi-chain payout engine initialized — ${MONTI_OWNER_ID}"
}

# ================================================================
# SECTION 3: LOGGING
# ================================================================
monti_log() {
  local level="$1" msg="$2"
  local ts; ts=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  local entry="[${ts}][${level}][${MONTI_NEURAL_SIG}] ${msg}"
  echo "$entry" >> "${LOG_DIR}/payout_engine.log"
  printf "${YELLOW}%s${NC}\n" "$entry"
}

# ================================================================
# SECTION 4: MULTI-CHAIN PRICE FETCHER
# Ref: https://www.coingecko.com/api/documentation
# ================================================================
fetch_all_prices() {
  monti_log "PRICES" "Fetching live prices for all MontiChains..."

  local resp
  resp=$(curl -s \
    -H "Accept: application/json" \
    -H "X-MontiAI-Owner: ${MONTI_OWNER_ID}" \
    --max-time 15 --retry 3 \
    "${COINGECKO}/simple/price?ids=ethereum,bitcoin,solana,monad-testnet&vs_currencies=usd&include_24hr_change=true&include_market_cap=true" \
    2>/dev/null)

  local enriched
  enriched=$(echo "$resp" | jq \
    --arg o "$MONTI_OWNER_ID" \
    --arg n "$MONTI_NEURAL_SIG" \
    --arg ts "$(date -u +%s)" \
    --arg eth "$WALLET_ETH" \
    --arg btc "$WALLET_BTC" \
    --arg sol "$WALLET_SOL" \
    --arg monad "$WALLET_MONAD" \
    --arg cb "$WALLET_COINBASE" \
    '{
      owner: $o, neural: $n, fetched_at: $ts,
      wallets: {
        ETH: $eth, BTC: $btc, SOL: $sol,
        MONAD: $monad, COINBASE: $cb
      },
      prices: .,
      source: "CoinGecko API v3 | coingecko.com/api/documentation"
    }')

  echo "$enriched" | tee "${CACHE_DIR}/live_prices.json"
  monti_push_to_api "/v1/prices/all" "$enriched"
  echo "$enriched"
}

# ================================================================
# SECTION 5: ETH WALLET BALANCE & PAYOUT DATA
# Ref: https://ethereum.org/developers/docs/apis/json-rpc/
# ================================================================
eth_payout_data() {
  monti_log "ETH_PAYOUT" "Fetching ETH balance → ${WALLET_ETH}"

  local payload
  payload=$(printf '{"jsonrpc":"2.0","method":"eth_getBalance","params":["%s","latest"],"id":1}' "$WALLET_ETH")

  local resp
  resp=$(curl -s -X POST "$ETH_RPC" \
    -H "Content-Type: application/json" \
    -H "X-MontiAI-Owner: ${MONTI_OWNER_ID}" \
    -H "X-MontiAI-Neural: ${MONTI_NEURAL_SIG}" \
    --data "$payload" --max-time 15 --retry 3 2>/dev/null)

  local hex; hex=$(echo "$resp" | jq -r '.result // "0x0"')
  local wei; wei=$(printf "%d" "$hex" 2>/dev/null || echo "0")
  local eth; eth=$(echo "scale=18; $wei / 1000000000000000000" | bc 2>/dev/null || echo "0")

  # Get ETH gas price
  local gas_resp
  gas_resp=$(curl -s -X POST "$ETH_RPC" \
    -H "Content-Type: application/json" \
    --data '{"jsonrpc":"2.0","method":"eth_gasPrice","params":[],"id":1}' \
    --max-time 10 2>/dev/null)
  local gas_hex; gas_hex=$(echo "$gas_resp" | jq -r '.result // "0x0"')
  local gas_wei; gas_wei=$(printf "%d" "$gas_hex" 2>/dev/null || echo "0")
  local gas_gwei; gas_gwei=$(echo "scale=4; $gas_wei / 1000000000" | bc 2>/dev/null || echo "0")

  local out
  out=$(jq -n \
    --arg chain "ETHEREUM" \
    --arg wallet "$WALLET_ETH" \
    --arg bal "$eth" \
    --arg wei "$wei" \
    --arg gas "$gas_gwei" \
    --arg o "$MONTI_OWNER_ID" \
    --arg n "$MONTI_NEURAL_SIG" \
    --arg m "$MNC_HASH" \
    --arg ts "$(date -u +%s)" \
    '{
      chain: $chain, owner: $o, neural: $n, mnc: $m,
      receive_wallet: $wallet,
      balance_eth: $bal, balance_wei: $wei,
      gas_price_gwei: $gas,
      payout_ready: true,
      timestamp: $ts,
      source: "eth_getBalance | ethereum.org/developers/docs/apis/json-rpc"
    }')

  echo "$out" | tee "${PAYOUT_DIR}/eth_payout_$(date +%s).json"
  monti_push_to_api "/v1/payout/eth" "$out"
  printf "${GREEN}[ETH] Balance: %s ETH | Gas: %s Gwei | Wallet: %s${NC}\n" "$eth" "$gas_gwei" "$WALLET_ETH"
}

# ================================================================
# SECTION 6: BTC WALLET BALANCE & PAYOUT DATA
# Ref: https://blockstream.info/api/
# ================================================================
btc_payout_data() {
  monti_log "BTC_PAYOUT" "Fetching BTC balance → ${WALLET_BTC}"

  # Blockstream Esplora API (no key required)
  local resp
  resp=$(curl -s \
    -H "X-MontiAI-Owner: ${MONTI_OWNER_ID}" \
    --max-time 15 --retry 3 \
    "https://blockstream.info/api/address/${WALLET_BTC}" 2>/dev/null)

  local confirmed
  confirmed=$(echo "$resp" | jq -r '.chain_stats.funded_txo_sum // 0')
  local spent
  spent=$(echo "$resp" | jq -r '.chain_stats.spent_txo_sum // 0')
  local balance_sat
  balance_sat=$(echo "$confirmed - $spent" | bc 2>/dev/null || echo "0")
  local balance_btc
  balance_btc=$(echo "scale=8; $balance_sat / 100000000" | bc 2>/dev/null || echo "0")
  local tx_count
  tx_count=$(echo "$resp" | jq -r '.chain_stats.tx_count // 0')

  local out
  out=$(jq -n \
    --arg chain "BITCOIN" \
    --arg wallet "$WALLET_BTC" \
    --arg bal "$balance_btc" \
    --arg sat "$balance_sat" \
    --arg txc "$tx_count" \
    --arg o "$MONTI_OWNER_ID" \
    --arg n "$MONTI_NEURAL_SIG" \
    --arg m "$MNC_HASH" \
    --arg ts "$(date -u +%s)" \
    '{
      chain: $chain, owner: $o, neural: $n, mnc: $m,
      receive_wallet: $wallet,
      balance_btc: $bal, balance_satoshis: $sat,
      tx_count: $txc, payout_ready: true,
      timestamp: $ts,
      source: "Blockstream Esplora API | blockstream.info/api"
    }')

  echo "$out" | tee "${PAYOUT_DIR}/btc_payout_$(date +%s).json"
  monti_push_to_api "/v1/payout/btc" "$out"
  printf "${GREEN}[BTC] Balance: %s BTC (%s sats) | TXs: %s | Wallet: %s${NC}\n" \
    "$balance_btc" "$balance_sat" "$tx_count" "$WALLET_BTC"
}

# ================================================================
# SECTION 7: SOL WALLET BALANCE & PAYOUT DATA
# Ref: https://solana.com/docs/rpc/http/getbalance
# ================================================================
sol_payout_data() {
  monti_log "SOL_PAYOUT" "Fetching SOL balance → ${WALLET_SOL}"

  local payload
  payload=$(printf '{"jsonrpc":"2.0","id":1,"method":"getBalance","params":["%s"]}' "$WALLET_SOL")

  local resp
  resp=$(curl -s -X POST "$SOL_RPC" \
    -H "Content-Type: application/json" \
    -H "X-MontiAI-Owner: ${MONTI_OWNER_ID}" \
    -H "X-MontiAI-Neural: ${MONTI_NEURAL_SIG}" \
    --data "$payload" --max-time 15 --retry 3 2>/dev/null)

  local lamports; lamports=$(echo "$resp" | jq -r '.result.value // 0')
  local sol; sol=$(echo "scale=9; $lamports / 1000000000" | bc 2>/dev/null || echo "0")

  # Get SPL token accounts (USDC etc)
  local token_payload
  token_payload=$(printf '{"jsonrpc":"2.0","id":1,"method":"getTokenAccountsByOwner","params":["%s",{"programId":"TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA"},{"encoding":"jsonParsed"}]}' "$WALLET_SOL")

  local token_resp
  token_resp=$(curl -s -X POST "$SOL_RPC" \
    -H "Content-Type: application/json" \
    --data "$token_payload" --max-time 15 2>/dev/null)

  local token_count
  token_count=$(echo "$token_resp" | jq '.result.value | length // 0' 2>/dev/null || echo "0")

  local out
  out=$(jq -n \
    --arg chain "SOLANA" \
    --arg wallet "$WALLET_SOL" \
    --arg sol "$sol" \
    --arg lam "$lamports" \
    --arg tc "$token_count" \
    --arg o "$MONTI_OWNER_ID" \
    --arg n "$MONTI_NEURAL_SIG" \
    --arg m "$MNC_HASH" \
    --arg ts "$(date -u +%s)" \
    --argjson tokens "$token_resp" \
    '{
      chain: $chain, owner: $o, neural: $n, mnc: $m,
      receive_wallet: $wallet,
      balance_sol: $sol, lamports: $lam,
      spl_token_accounts: $tc,
      token_data: $tokens,
      payout_ready: true,
      timestamp: $ts,
      source: "getBalance | solana.com/docs/rpc/http/getbalance"
    }')

  echo "$out" | tee "${PAYOUT_DIR}/sol_payout_$(date +%s).json"
  monti_push_to_api "/v1/payout/sol" "$out"
  printf "${GREEN}[SOL] Balance: %s SOL (%s lamports) | SPL Tokens: %s | Wallet: %s${NC}\n" \
    "$sol" "$lamports" "$token_count" "$WALLET_SOL"
}

# ================================================================
# SECTION 8: MONAD WALLET BALANCE & PAYOUT DATA
# Monad is EVM-compatible — uses eth_getBalance
# Ref: https://docs.monad.xyz
# ================================================================
monad_payout_data() {
  monti_log "MONAD_PAYOUT" "Fetching MONAD balance → ${WALLET_MONAD}"

  # Monad uses EVM JSON-RPC — fallback to public RPC
  local MONAD_RPC="${MONAD_RPC_URL:-https://testnet-rpc.monad.xyz}"

  local payload
  payload=$(printf '{"jsonrpc":"2.0","method":"eth_getBalance","params":["%s","latest"],"id":1}' "$WALLET_MONAD")

  local resp
  resp=$(curl -s -X POST "$MONAD_RPC" \
    -H "Content-Type: application/json" \
    -H "X-MontiAI-Owner: ${MONTI_OWNER_ID}" \
    -H "X-MontiAI-Neural: ${MONTI_NEURAL_SIG}" \
    --data "$payload" --max-time 15 --retry 3 2>/dev/null)

  local hex; hex=$(echo "$resp" | jq -r '.result // "0x0"')
  local wei; wei=$(printf "%d" "$hex" 2>/dev/null || echo "0")
  local monad_bal; monad_bal=$(echo "scale=18; $wei / 1000000000000000000" | bc 2>/dev/null || echo "0")

  # Also check via ETH RPC as EVM fallback
  local eth_check
  eth_check=$(curl -s -X POST "$ETH_RPC" \
    -H "Content-Type: application/json" \
    --data "$(printf '{"jsonrpc":"2.0","method":"eth_getBalance","params":["%s","latest"],"id":1}' "$WALLET_MONAD")" \
    --max-time 10 2>/dev/null)

  local out
  out=$(jq -n \
    --arg chain "MONAD" \
    --arg wallet "$WALLET_MONAD" \
    --arg bal "$monad_bal" \
    --arg wei "$wei" \
    --arg o "$MONTI_OWNER_ID" \
    --arg n "$MONTI_NEURAL_SIG" \
    --arg m "$MNC_HASH" \
    --arg ts "$(date -u +%s)" \
    '{
      chain: $chain, owner: $o, neural: $n, mnc: $m,
      receive_wallet: $wallet,
      balance_monad: $bal, balance_wei: $wei,
      evm_compatible: true,
      payout_ready: true,
      timestamp: $ts,
      source: "eth_getBalance EVM | docs.monad.xyz"
    }')

  echo "$out" | tee "${PAYOUT_DIR}/monad_payout_$(date +%s).json"
  monti_push_to_api "/v1/payout/monad" "$out"
  printf "${GREEN}[MONAD] Balance: %s MONAD | Wallet: %s${NC}\n" "$monad_bal" "$WALLET_MONAD"
}

# ================================================================
# SECTION 9: COINBASE WALLET BALANCE & PAYOUT DATA
# EVM-compatible (Base/ETH L2)
# Ref: https://docs.base.org/docs/
# ================================================================
coinbase_payout_data() {
  monti_log "COINBASE_PAYOUT" "Fetching COINBASE balance → ${WALLET_COINBASE}"

  # Base L2 RPC (Coinbase's L2)
  local BASE_RPC="${BASE_RPC_URL:-https://mainnet.base.org}"
  local BASE_RPC_FALLBACK="https://rpc.ankr.com/base"

  local payload
  payload=$(printf '{"jsonrpc":"2.0","method":"eth_getBalance","params":["%s","latest"],"id":1}' "$WALLET_COINBASE")

  local resp
  resp=$(curl -s -X POST "$BASE_RPC" \
    -H "Content-Type: application/json" \
    -H "X-MontiAI-Owner: ${MONTI_OWNER_ID}" \
    -H "X-MontiAI-Neural: ${MONTI_NEURAL_SIG}" \
    --data "$payload" --max-time 15 --retry 3 2>/dev/null)

  if echo "$resp" | grep -q '"error"' || [ -z "$resp" ]; then
    monti_log "COINBASE_FALLBACK" "→ Trying fallback: $BASE_RPC_FALLBACK"
    resp=$(curl -s -X POST "$BASE_RPC_FALLBACK" \
      -H "Content-Type: application/json" \
      --data "$payload" --max-time 15 2>/dev/null)
  fi

  local hex; hex=$(echo "$resp" | jq -r '.result // "0x0"')
  local wei; wei=$(printf "%d" "$hex" 2>/dev/null || echo "0")
  local eth_bal; eth_bal=$(echo "scale=18; $wei / 1000000000000000000" | bc 2>/dev/null || echo "0")

  # Also get ETH mainnet balance for same address
  local eth_main_resp
  eth_main_resp=$(curl -s -X POST "$ETH_RPC" \
    -H "Content-Type: application/json" \
    --data "$payload" --max-time 10 2>/dev/null)
  local eth_main_hex; eth_main_hex=$(echo "$eth_main_resp" | jq -r '.result // "0x0"')
  local eth_main_wei; eth_main_wei=$(printf "%d" "$eth_main_hex" 2>/dev/null || echo "0")
  local eth_main_bal; eth_main_bal=$(echo "scale=18; $eth_main_wei / 1000000000000000000" | bc 2>/dev/null || echo "0")

  local out
  out=$(jq -n \
    --arg chain "COINBASE_BASE_L2" \
    --arg wallet "$WALLET_COINBASE" \
    --arg bal "$eth_bal" \
    --arg eth_main "$eth_main_bal" \
    --arg wei "$wei" \
    --arg o "$MONTI_OWNER_ID" \
    --arg n "$MONTI_NEURAL_SIG" \
    --arg m "$MNC_HASH" \
    --arg ts "$(date -u +%s)" \
    '{
      chain: $chain, owner: $o, neural: $n, mnc: $m,
      receive_wallet: $wallet,
      balance_base_eth: $bal,
      balance_eth_mainnet: $eth_main,
      balance_wei: $wei,
      networks: ["BASE_L2","ETHEREUM_MAINNET"],
      payout_ready: true,
      timestamp: $ts,
      source: "Base L2 RPC | docs.base.org"
    }')

  echo "$out" | tee "${PAYOUT_DIR}/coinbase_payout_$(date +%s).json"
  monti_push_to_api "/v1/payout/coinbase" "$out"
  printf "${GREEN}[COINBASE/BASE] Balance: %s ETH (Base) | %s ETH (Mainnet) | Wallet: %s${NC}\n" \
    "$eth_bal" "$eth_main_bal" "$WALLET_COINBASE"
}

# ================================================================
# SECTION 10: SOLANA JUPITER LIQUIDATION → SOL WALLET
# Swaps any SPL token → USDC → deposits to WALLET_SOL
# Ref: https://dev.jup.ag/docs/swap/v1/get-quote
# ================================================================
sol_liquidate_to_wallet() {
  local input_mint="${1:-$MINT_SOL}"
  local amount_raw="$2"
  local slippage="${3:-50}"

  monti_log "SOL_LIQ" "Liquidating $input_mint → USDC → ${WALLET_SOL}"

  # Get quote
  local quote_resp
  quote_resp=$(curl -s \
    -H "Accept: application/json" \
    -H "X-MontiAI-Owner: ${MONTI_OWNER_ID}" \
    --max-time 15 \
    "${JUPITER_QUOTE}?inputMint=${input_mint}&outputMint=${MINT_USDC}&amount=${amount_raw}&slippageBps=${slippage}&onlyDirectRoutes=false" \
    2>/dev/null)

  local out_amount
  out_amount=$(echo "$quote_resp" | jq -r '.outAmount // "0"')
  local out_usdc
  out_usdc=$(echo "scale=6; $out_amount / 1000000" | bc 2>/dev/null || echo "0")

  monti_log "SOL_LIQ_QUOTE" "Expected USDC out: $out_usdc"

  # Build swap transaction
  local swap_payload
  swap_payload=$(jq -n \
    --argjson quote "$quote_resp" \
    --arg wallet "$WALLET_SOL" \
    '{
      quoteResponse: $quote,
      userPublicKey: $wallet,
      wrapAndUnwrapSol: true,
      useSharedAccounts: true,
      prioritizationFeeLamports: 5000,
      dynamicComputeUnitLimit: true
    }')

  local swap_resp
  swap_resp=$(curl -s -X POST "$JUPITER_SWAP" \
    -H "Content-Type: application/json" \
    -H "X-MontiAI-Owner: ${MONTI_OWNER_ID}" \
    -H "X-MontiAI-Neural: ${MONTI_NEURAL_SIG}" \
    --data "$swap_payload" --max-time 20 2>/dev/null)

  local record
  record=$(jq -n \
    --arg o "$MONTI_OWNER_ID" \
    --arg n "$MONTI_NEURAL_SIG" \
    --arg m "$MNC_HASH" \
    --arg im "$input_mint" \
    --arg om "$MINT_USDC" \
    --arg amt "$amount_raw" \
    --arg out "$out_usdc" \
    --arg rw "$WALLET_SOL" \
    --arg ts "$(date -u +%s)" \
    --argjson tx "$swap_resp" \
    '{
      owner: $o, neural: $n, mnc: $m,
      input_mint: $im, output_mint: $om,
      input_amount: $amt, expected_usdc: $out,
      receive_wallet: $rw,
      swap_tx: $tx,
      status: "BUILT_AWAITING_SIGN",
      liquidated_at: $ts,
      source: "Jupiter Swap API v6 | dev.jup.ag"
    }')

  echo "$record" | tee "${TX_DIR}/sol_liq_$(date +%s).json"
  monti_push_to_api "/v1/sol/liquidate/usdc" "$record"
  printf "${GREEN}[SOL LIQ] Expected: %s USDC → %s${NC}\n" "$out_usdc" "$WALLET_SOL"
}

# ================================================================
# SECTION 11: FULL MULTI-CHAIN PAYOUT SWEEP
# Runs ALL chains simultaneously, pushes ALL payloads
# ================================================================
monti_full_payout_sweep() {
  monti_log "SWEEP" "═══ INITIATING FULL MULTI-CHAIN PAYOUT SWEEP ═══"
  printf "${MAGENTA}${BOLD}"
  printf "╔══════════════════════════════════════════════════════════════╗\n"
  printf "║   MONTIAI FULL PAYOUT SWEEP — ALL 5 CHAINS                 ║\n"
  printf "║   JOHNCHARLESMONTI — MULTI-CHAIN ACTIVE                    ║\n"
  printf "╚══════════════════════════════════════════════════════════════╝\n"
  printf "${NC}\n"

  # Fetch all live prices first
  fetch_all_prices

  # Run all chain payout data collections
  printf "\n${CYAN}[1/5] ETHEREUM...${NC}\n"
  eth_payout_data || monti_log "WARN" "ETH payout data failed"

  printf "\n${CYAN}[2/5] BITCOIN...${NC}\n"
  btc_payout_data || monti_log "WARN" "BTC payout data failed"

  printf "\n${CYAN}[3/5] SOLANA...${NC}\n"
  sol_payout_data || monti_log "WARN" "SOL payout data failed"

  printf "\n${CYAN}[4/5] MONAD...${NC}\n"
  monad_payout_data || monti_log "WARN" "MONAD payout data failed"

  printf "\n${CYAN}[5/5] COINBASE/BASE...${NC}\n"
  coinbase_payout_data || monti_log "WARN" "COINBASE payout data failed"

  # Build master payout summary
  local summary
  summary=$(jq -n \
    --arg o "$MONTI_OWNER_ID" \
    --arg n "$MONTI_NEURAL_SIG" \
    --arg m "$MNC_HASH" \
    --arg sc "$GLOBAL_WORK_SIG" \
    --arg eth "$WALLET_ETH" \
    --arg btc "$WALLET_BTC" \
    --arg sol "$WALLET_SOL" \
    --arg monad "$WALLET_MONAD" \
    --arg cb "$WALLET_COINBASE" \
    --arg status "$WALLET_STATUS" \
    --arg ts "$(date -u +%s)" \
    --arg api "$MONTIDROID_API" \
    --arg wh "$MONTI_WEBHOOK" \
    '{
      owner: $o,
      neural_signature: $n,
      mnc_hash: $m,
      global_scope: $sc,
      sweep_completed_at: $ts,
      wallet_status: $status,
      receive_wallets: {
        ETH:      $eth,
        BTC:      $btc,
        SOL:      $sol,
        MONAD:    $monad,
        COINBASE: $cb
      },
      api_endpoint: $api,
      webhook: $wh,
      chains_swept: 5,
      status: "SWEEP_COMPLETE",
      purpose: "JOHNCHARLESMONTI_REVENUE_GENERATION_AND_INVESTMENT"
    }')

  echo "$summary" | tee "${PAYOUT_DIR}/master_sweep_$(date +%s).json"
  monti_push_to_api "/v1/payout/sweep/complete" "$summary"
  monti_webhook_notify "FULL_SWEEP_COMPLETE" "$summary"

  printf "\n${GREEN}${BOLD}"
  printf "╔══════════════════════════════════════════════════════════════╗\n"
  printf "║  ✓ FULL MULTI-CHAIN SWEEP COMPLETE                         ║\n"
  printf "║  All 5 chains swept. Payloads pushed to api.montidroid.com ║\n"
  printf "║  Webhook notified: JOHNCHARLESMONTI.COM/webhooks           ║\n"
  printf "╚══════════════════════════════════════════════════════════════╝\n"
  printf "${NC}\n"
}

# ================================================================
# SECTION 12: API PUSH + WEBHOOK ENGINE
# ================================================================
monti_push_to_api() {
  local endpoint="$1" payload="$2"
  local url="${MONTIDROID_API}${endpoint}"
  local sig
  sig=$(echo -n "$payload" | openssl dgst -sha256 -hmac "${MONTI_OWNER_ID}" 2>/dev/null | awk '{print $2}')

  local code
  code=$(curl -s -o /dev/null -w "%{http_code}" \
    -X POST "$url" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer ${MONTIDROID_API_KEY:-MONTI_RPA_KEY}" \
    -H "X-MontiAI-Owner: ${MONTI_OWNER_ID}" \
    -H "X-MontiAI-Neural: ${MONTI_NEURAL_SIG}" \
    -H "X-MontiAI-Wallet-ETH: ${WALLET_ETH}" \
    -H "X-MontiAI-Wallet-SOL: ${WALLET_SOL}" \
    -H "X-MontiAI-Wallet-BTC: ${WALLET_BTC}" \
    -H "X-MontiAI-Sig: ${sig}" \
    -H "X-MontiAI-MNC: ${MNC_HASH}" \
    -H "X-MontiAI-Scope: ${GLOBAL_WORK_SIG}" \
    --data "$payload" --max-time 20 --retry 3 2>/dev/null)

  [ "$code" = "200" ] || [ "$code" = "201" ] \
    && monti_log "PUSH_OK" "✓ $url [HTTP $code]" \
    || { monti_log "PUSH_FAIL" "✗ $url [HTTP $code]"; monti_webhook_notify "$endpoint" "$payload"; }
}

monti_webhook_notify() {
  local event="$1" payload="$2"
  curl -s -X POST "${MONTI_WEBHOOK}" \
    -H "Content-Type: application/json" \
    -H "X-MontiAI-Owner: ${MONTI_OWNER_ID}" \
    -H "X-MontiAI-Event: ${event}" \
    --data "$payload" --max-time 15 &>/dev/null || true
  monti_log "WEBHOOK" "→ ${MONTI_WEBHOOK} [${event}]"
}

# ================================================================
# SECTION 13: HEALTH CHECK
# ================================================================
monti_health_check() {
  printf "${BOLD}[HEALTH CHECK] All MontiChain Endpoints${NC}\n"
  local endpoints=(
    "$MONTIDROID_API/health:MontiDroid API"
    "$ETH_RPC:Ethereum RPC"
    "$SOL_RPC:Solana RPC"
    "https://blockstream.info/api/blocks/tip/height:BTC Blockstream"
    "https://mainnet.base.org:Coinbase Base L2"
    "${COINGECKO}/ping:CoinGecko API"
  )
  for entry in "${endpoints[@]}"; do
    local url="${entry%%:*}" label="${entry##*:}"
    local code
    code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "$url" 2>/dev/null)
    [ "$code" = "200" ] \
      && printf "${GREEN}[OK]   %-30s → HTTP %s${NC}\n" "$label" "$code" \
      || printf "${RED}[FAIL] %-30s → HTTP %s${NC}\n" "$label" "$code"
  done
}

# ================================================================
# SECTION 14: WALLET SUMMARY DASHBOARD
# ================================================================
monti_wallet_dashboard() {
  printf "${BOLD}${CYAN}"
  printf "══════════════════════════════════════════════════════════════\n"
  printf "  JOHNCHARLESMONTI — VERIFIED WALLET DASHBOARD\n"
  printf "  Owner:   %s\n" "$MONTI_OWNER_ID"
  printf "  Neural:  %s\n" "$MONTI_NEURAL_SIG"
  printf "  Status:  %s\n" "$WALLET_STATUS"
  printf "──────────────────────────────────────────────────────────────\n"
  printf "  ETH      : %s\n" "$WALLET_ETH"
  printf "  BTC      : %s\n" "$WALLET_BTC"
  printf "  SOL      : %s\n" "$WALLET_SOL"
  printf "  MONAD    : %s\n" "$WALLET_MONAD"
  printf "  COINBASE : %s\n" "$WALLET_COINBASE"
  printf "──────────────────────────────────────────────────────────────\n"
  printf "  API:     %s\n" "$MONTIDROID_API"
  printf "  Webhook: %s\n" "$MONTI_WEBHOOK"
  printf "  Suite:   %s\n" "$SUITE_ROOT"
  printf "══════════════════════════════════════════════════════════════\n"
  printf "${NC}"
  printf "${YELLOW}Payout files: %s${NC}\n" "$(ls "$PAYOUT_DIR" 2>/dev/null | wc -l)"
  printf "${YELLOW}TX files:     %s${NC}\n" "$(ls "$TX_DIR" 2>/dev/null | wc -l)"
  printf "${YELLOW}Log size:     %s${NC}\n" "$(du -sh "$LOG_DIR" 2>/dev/null | cut -f1)"
}

# ================================================================
# SECTION 15: CLI DISPATCHER
# ================================================================
CMD="${1:-help}"
shift 2>/dev/null || true
monti_bootstrap

case "$CMD" in
  sweep)          monti_full_payout_sweep ;;
  eth)            eth_payout_data ;;
  btc)            btc_payout_data ;;
  sol)            sol_payout_data ;;
  monad)          monad_payout_data ;;
  coinbase)       coinbase_payout_data ;;
  prices)         fetch_all_prices ;;
  liquidate-sol)  sol_liquidate_to_wallet "${1:-$MINT_SOL}" "${2:-1000000000}" "${3:-50}" ;;
  health)         monti_health_check ;;
  dashboard)      monti_wallet_dashboard ;;
  help|*)
    printf "${BOLD}MontiDroid Multi-Chain Payout Engine — Commands:${NC}\n"
    printf "  sweep              Run full 5-chain payout sweep\n"
    printf "  eth                ETH wallet balance + payout data\n"
    printf "  btc                BTC wallet balance + payout data\n"
    printf "  sol                SOL wallet balance + token data\n"
    printf "  monad              MONAD wallet balance + payout data\n"
    printf "  coinbase           Coinbase/Base L2 balance + data\n"
    printf "  prices             Fetch all live crypto prices\n"
    printf "  liquidate-sol [mint] [amt] [slip]  Jupiter swap → USDC\n"
    printf "  health             All endpoint health checks\n"
    printf "  dashboard          Wallet dashboard summary\n"
    ;;
esac

# ================================================================
# OWNER:OWNER — JOHNCHARLESMONTI_02111989_9807 | #MONTIAI
# NEURAL: MONTI^JOHN^CHARLES^MONTI
# ETH:     0x77FbA179C79De5B7653F68b5039Af940AdA60ce0
# BTC:     3CfgCQKRKy4VtZU8YWdPLyHQzZMzkn5Sw7
# SOL:     3ZqbRa38YTop9HbcfQA3TH6sy4Y4RVnaC998hAgCTVFp3
# MONAD:   0x375ecE461B65551Fce3fC7199abbed403F1b675b
# COINBASE:0xb04110847A563E59F3D52d1aFB3304068173830b
# MNC: $MNC MontiNeuralCoin Hash | SCOPE: WorkerGlobalScope
# ================================================================
