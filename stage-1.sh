#!/usr/bin/env bash
set -euo pipefail

VERBOSE=false
PASSPORT=false
BOOST=false
PASSPORT_FILE=""

STRESS_PID=""
cleanup() {
    if [[ -n "$STRESS_PID" ]] && kill -0 "$STRESS_PID" 2>/dev/null; then
        echo -e "\n\033[0;31mKilling background stress-ng (PID: $STRESS_PID)...\033[0m"
        kill -9 "$STRESS_PID" 2>/dev/null || true
        wait "$STRESS_PID" 2>/dev/null || true
    fi
}
trap cleanup EXIT INT TERM
while getopts "vp:b" opt; do
    case "$opt" in
        v)
            VERBOSE=true
            ;;
        p)
            PASSPORT=true
            PASSPORT_FILE="$OPTARG"
            ;;
        b)
            BOOST=true
            ;;
    esac
done

if [[ "$VERBOSE" == true ]] && [[ "$PASSPORT" == true ]]; then
    bash passport.sh | tee "$PASSPORT_FILE"
elif [[ "$PASSPORT" == true ]]; then
    bash passport.sh > "$PASSPORT_FILE"
elif [[ "$VERBOSE" == true ]]; then
    bash passport.sh
fi

if [[ "$BOOST" == true ]]; then
    echo -e "\n\033[0;31mDISABLING TURBOBOOST\033[1;33m"
    echo 0 | sudo tee /sys/devices/system/cpu/cpufreq/boost
fi
echo -e "\n\033[0;31mFIRST LAUNCH\033[1;33m"
echo -e "\n\033[0;31mTIME METRICS STRONG CORE:\033[1;33m"

/etc/profiles/per-user/zhabka/bin/time -v chrt -f 99 taskset -c 2 ./out/graph_traverse 1 graph-rand.bin

/etc/profiles/per-user/zhabka/bin/time -v chrt -f 99 taskset -c 2 ./out/graph_traverse --no-cache 1 graph-rand.bin

echo -e "\n\033[0;31mPERF METRICS:\033[1;33m"
perf stat -e context-switches,cpu-migrations,page-faults,cache-misses,cycles,instructions taskset -c 2 ./out/graph_traverse 1 graph-rand.bin
echo -e "\n\033[0;31mSTRACE METRICS:\033[1;33m"
time strace -c chrt -f 99 taskset -c 2 ./out/graph_traverse 1 graph-rand.bin
echo -e "\n\033[0;31mPERF NO CACHE METRICS:\033[1;33m"

perf stat -e context-switches,cpu-migrations,page-faults,cache-misses,cycles,instructions taskset -c 2 ./out/graph_traverse --no-cache 1 graph-rand.bin

echo -e "\n\033[0;31mSTRESS METRICS:\033[1;33m"
stress-ng --cpu 1 --taskset 2 --quiet &
STRESS_PID=$!
sleep 1

echo -e "\n\033[0;32mWITH chrt REALTIME PRIOIRTY:\033[0m"
/etc/profiles/per-user/zhabka/bin/time -v chrt -f 99 taskset -c 2 ./out/graph_traverse 1 graph-rand.bin

echo -e "\n\033[0;32mNO chrt REALTIME PRIOIRTY:\033[0m"
/etc/profiles/per-user/zhabka/bin/time -v taskset -c 2 ./out/graph_traverse 1 graph-rand.bin

echo -e "\n\033[0;31m STOPPING STRESS \033[0m"
kill -9 "$STRESS_PID" 2>/dev/null || true
wait "$STRESS_PID" 2>/dev/null || true
STRESS_PID=""

echo -e "\n\033[0;31mTIME METRICS WEAK CORE:\033[1;33m"

echo -e "\n\033[0;31mPERF METRICS:\033[1;33m"
perf stat -e context-switches,cpu-migrations,page-faults,cache-misses,cycles,instructions chrt -f 99 taskset -c 6 ./out/graph_traverse 1 graph-rand.bin

echo -e "\n\033[0;31mSTRESS METRICS:\033[1;33m"
stress-ng --cpu 1 --taskset 6 --quiet &
STRESS_PID=$!
sleep 1
perf stat -e context-switches,cpu-migrations,page-faults,cache-misses,cycles,instructions taskset -c 6 ./out/graph_traverse 1 graph-rand.bin

echo -e "\n\033[0;31m STOPPING STRESS \033[0m"
kill -9 "$STRESS_PID" 2>/dev/null || true
wait "$STRESS_PID" 2>/dev/null || true
STRESS_PID=""

if [[ "$BOOST" == true ]]; then
    echo -e "\n\033[0;31mENABLING TURBOBOOST\033[1;33m"
    echo 1 | sudo tee /sys/devices/system/cpu/cpufreq/boost
fi
