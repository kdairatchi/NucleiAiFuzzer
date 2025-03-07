#!/usr/bin/env bash
#
# nuclei_ai_kdairatchi.sh
#
# A comprehensive, AI-powered Nuclei scanner script that:
#   1) Loads queries from ai_queries.txt (grouped by category).
#   2) Prompts user to select categories to run.
#   3) Parses CLI arguments for concurrency, timeouts, output, etc.
#   4) Retries scans on transient errors.
#   5) Logs output to both terminal and a timestamped file.
#   6) Has color-coded output for better readability.
#   7) By kdairatchi.
#

############################
#    COLOR DEFINITIONS
############################
RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
BLUE="\033[34m"
BOLD="\033[1m"
RESET="\033[0m"

############################
#  DEFAULT CONFIGURATIONS
############################
TIMEOUT=10             # Time (seconds) for each request
MAX_RUNS=0            # 0 => unlimited
CUP_MODE=true         # Whether to include '-cup' by default
OUTPUT_DIR="nuclei_results"
CONCURRENCY=10
RETRY_COUNT=2
TARGETS=""
LOGFILE="nuclei_scan_$(date +%Y%m%d_%H%M%S).log"

############################
#     USAGE FUNCTION
############################
function usage() {
    echo -e "${BOLD}Usage:${RESET} $0 -f <targets.txt> [options]"
    echo -e "${BOLD}Options:${RESET}"
    echo -e "  ${YELLOW}-f <file>${RESET}       : The targets file (required)"
    echo -e "  ${YELLOW}-t <timeout>${RESET}    : Request timeout in seconds (default=${TIMEOUT})"
    echo -e "  ${YELLOW}-n <max_runs>${RESET}   : Number of queries to run (0=unlimited, default=0)"
    echo -e "  ${YELLOW}--cup / --no-cup${RESET}: Toggle nuclei '-cup' (default=on)"
    echo -e "  ${YELLOW}-o <outdir>${RESET}     : Output directory (default='${OUTPUT_DIR}')"
    echo -e "  ${YELLOW}-c <concur>${RESET}     : Concurrency level (default=${CONCURRENCY})"
    echo -e "  ${YELLOW}-r <retries>${RESET}    : How many times to retry on failure (default=${RETRY_COUNT})"
    echo -e "  ${YELLOW}-h, --help${RESET}      : Show this help message"
    echo
    exit 1
}

############################
#  PARSE CLI ARGUMENTS
############################
while [[ $# -gt 0 ]]; do
    case $1 in
        -f)
            TARGETS="$2"
            shift 2
            ;;
        -t)
            TIMEOUT="$2"
            shift 2
            ;;
        -n)
            MAX_RUNS="$2"
            shift 2
            ;;
        --cup)
            CUP_MODE=true
            shift
            ;;
        --no-cup)
            CUP_MODE=false
            shift
            ;;
        -o)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        -c)
            CONCURRENCY="$2"
            shift 2
            ;;
        -r)
            RETRY_COUNT="$2"
            shift 2
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo -e "${RED}[!] Unknown flag:${RESET} $1"
            usage
            ;;
    esac
done

# Validate required arguments
if [[ -z "$TARGETS" ]]; then
    echo -e "${RED}[!] Error: -f <file> is required.${RESET}"
    usage
fi
if [[ ! -f "$TARGETS" ]]; then
    echo -e "${RED}[!] Error: targets file '${TARGETS}' not found.${RESET}"
    exit 1
fi

mkdir -p "$OUTPUT_DIR"

# Start logging to file as well as console
exec > >(tee -a "$LOGFILE") 2>&1

echo -e "${BOLD}${BLUE}=========================================================${RESET}"
echo -e "${BOLD}${BLUE}    Nuclei AI Scanning Script by kdairatchi ${RESET}"
echo -e "${BOLD}${BLUE}=========================================================${RESET}"
echo
echo -e "${GREEN}Targets       :${RESET} $TARGETS"
echo -e "${GREEN}Timeout       :${RESET} $TIMEOUT s"
echo -e "${GREEN}Max Runs      :${RESET} $MAX_RUNS (0=unlimited)"
echo -e "${GREEN}CUP Mode      :${RESET} $CUP_MODE"
echo -e "${GREEN}Output Dir    :${RESET} $OUTPUT_DIR"
echo -e "${GREEN}Concurrency   :${RESET} $CONCURRENCY"
echo -e "${GREEN}Retries       :${RESET} $RETRY_COUNT"
echo -e "${GREEN}Log File      :${RESET} $LOGFILE"
echo

############################
#   PROMPT CATEGORIES
############################
function ask_categories() {
    echo -e "${YELLOW}Choose categories to run (space separated). Possible options:${RESET}"
    echo -e "  1) reconnaissance"
    echo -e "  2) low-hanging-fruits"
    echo -e "  3) advanced-mixed-testing"
    echo -e "  4) sensitive-data-exposure"
    echo -e "  5) advanced-security-checks"
    echo -e "  6) all"
    read -p "Choice: " categories_input

    for choice in $categories_input; do
        case $choice in
            1) CATEGORIES_TO_RUN+=("reconnaissance") ;;
            2) CATEGORIES_TO_RUN+=("low-hanging-fruits") ;;
            3) CATEGORIES_TO_RUN+=("advanced-mixed-testing") ;;
            4) CATEGORIES_TO_RUN+=("sensitive-data-exposure") ;;
            5) CATEGORIES_TO_RUN+=("advanced-security-checks") ;;
            6) CATEGORIES_TO_RUN+=("reconnaissance" "low-hanging-fruits" "advanced-mixed-testing" "sensitive-data-exposure" "advanced-security-checks") ;;
            *) echo -e "${RED}[!] Unknown category index:${RESET} $choice" ;;
        esac
    done
}

CATEGORIES_TO_RUN=()
ask_categories

if [[ ${#CATEGORIES_TO_RUN[@]} -eq 0 ]]; then
    echo -e "${RED}[!] No categories selected. Exiting.${RESET}"
    exit 0
fi

############################
#  LOAD AI QUERIES
############################
if [[ ! -f ai_queries.txt ]]; then
    echo -e "${RED}[!] ai_queries.txt not found in current directory. Exiting.${RESET}"
    exit 1
fi

AI_QUERIES=()
CURRENT_CAT=""
while IFS= read -r line; do
    # skip empty lines
    [[ -z "$line" ]] && continue

    # check if line is a category header: # [something]
    if [[ "$line" =~ ^#\ \[(.+)\] ]]; then
        CURRENT_CAT="${BASH_REMATCH[1]}"
        continue
    fi

    # If the current category is among the user's choices, add line
    for cat in "${CATEGORIES_TO_RUN[@]}"; do
        if [[ "$CURRENT_CAT" == "$cat" ]]; then
            AI_QUERIES+=("$line")
            break
        fi
    done
done < ai_queries.txt

# If no queries found
if [[ ${#AI_QUERIES[@]} -eq 0 ]]; then
    echo -e "${RED}[!] No matching AI queries for the chosen categories.${RESET}"
    exit 0
fi

echo -e "${GREEN}[INFO] Loaded ${#AI_QUERIES[@]} queries across your chosen categories.${RESET}"
echo

############################
#    RETRY FUNCTION
############################
function run_nuclei_with_retry() {
    local cmd="$1"
    local max_retries="$2"
    local attempt=1
    local exit_code=0

    while [[ $attempt -le $max_retries ]]; do
        echo -e "${BLUE}[*] Attempt $attempt/$max_retries${RESET} => $cmd"
        eval "$cmd"
        exit_code=$?

        if [[ $exit_code -eq 0 ]]; then
            echo -e "${GREEN}[+] Success on attempt $attempt${RESET}"
            break
        else
            echo -e "${RED}[!] Nuclei failed with exit code $exit_code${RESET}"
        fi
        
        attempt=$((attempt + 1))
    done

    return $exit_code
}

############################
#      MAIN LOOP
############################
RUN_COUNT=0
for query in "${AI_QUERIES[@]}"; do
    # Check max runs limit
    if [[ "$MAX_RUNS" -ne 0 && "$RUN_COUNT" -ge "$MAX_RUNS" ]]; then
        echo -e "${YELLOW}[!] Reached max runs ($MAX_RUNS). Stopping now.${RESET}"
        break
    fi
    
    RUN_COUNT=$((RUN_COUNT + 1))
    echo -e "${BOLD}---------------------------------------------------${RESET}"
    echo -e "${BOLD}[Run #$RUN_COUNT] AI Query:${RESET} \"$query\""
    echo -e "${BOLD}---------------------------------------------------${RESET}"

    # Build command
    cmd="nuclei \
        -l \"$TARGETS\" \
        -ai \"$query\" \
        -timeout $TIMEOUT \
        -c $CONCURRENCY \
        -o \"$OUTPUT_DIR/ai_query_${RUN_COUNT}.txt\" \
    "
    if [ "$CUP_MODE" = true ]; then
        cmd="$cmd -cup"
    fi

    run_nuclei_with_retry "$cmd" "$RETRY_COUNT"
    echo
done

echo -e "${GREEN}==============================================${RESET}"
echo -e "${GREEN}[+] Completed $RUN_COUNT scans. Logs saved to $LOGFILE${RESET}"
echo -e "${GREEN}Output directory: $OUTPUT_DIR${RESET}"
echo -e "${GREEN}==============================================${RESET}"
