#!/usr/bin/env bash
set -euo pipefail

GRAPH_FILE="graph-rand.bin"
CORE=2
N=15
WARMUP_RUNS=1
OUT_CSV="results_stage1.csv"
SNAP_FILE="env_snapshot_before.txt"
DISABLE_BOOST=true
USE_CHRT=false

if [[ -x "/etc/profiles/per-user/zhabka/bin/time" ]]; then
    TIME_BIN="/etc/profiles/per-user/zhabka/bin/time"
elif command -v time >/dev/null && [[ "$(type -t time)" != "builtin" ]]; then
    TIME_BIN="$(which time)"
elif [[ -x "/usr/bin/time" ]]; then
    TIME_BIN="/usr/bin/time"
else
    echo "ОШИБКА: GNU time не найден!" >&2
    exit 1
fi

APP="./out/graph_traverse"

usage() {
    echo "Использование: $0 [-n <повторы>] [-c <ядро>] [-g <файл_графа>] [-o <csv>] [-b] [-r]"
    echo "  -n: количество зачётных измерений N (по умолчанию: $N)"
    echo "  -c: номер ядра CPU для taskset (по умолчанию: $CORE)"
    echo "  -g: путь к файлу графа (по умолчанию: $GRAPH_FILE)"
    echo "  -o: выходной CSV-файл (по умолчанию: $OUT_CSV)"
    echo "  -b: НЕ отключать Turbo Boost (по умолчанию буст глушится)"
    echo "  -r: использовать chrt -f 99 (Realtime FIFO, нужен sudo)"
    exit 1
}

while getopts "n:c:g:o:brh" opt; do
    case "$opt" in
        n) N="$OPTARG" ;;
        c) CORE="$OPTARG" ;;
        g) GRAPH_FILE="$OPTARG" ;;
        o) OUT_CSV="$OPTARG" ;;
        b) DISABLE_BOOST=false ;;
        r) USE_CHRT=true ;;
        h) usage ;;
        *) usage ;;
    esac
done

if [[ ! -f "$GRAPH_FILE" ]]; then
    echo "ОШИБКА: Файл графа '$GRAPH_FILE' не найден!" >&2
    exit 1
fi

if [[ ! -x "$APP" ]]; then
    echo "ОШИБКА: Бинарник '$APP' не скомпилирован! Выполните сборку." >&2
    exit 1
fi

ORIG_BOOST_STATE=""
cleanup() {
    echo -e "\n\033[0;33m>>> Завершение скрипта, очистка... \033[0m"
    if [[ "$DISABLE_BOOST" == true && -n "$ORIG_BOOST_STATE" ]]; then
        echo -e "\033[0;32mВосстановление исходного состояния Turbo Boost: $ORIG_BOOST_STATE\033[0m"
        echo "$ORIG_BOOST_STATE" | sudo tee /sys/devices/system/cpu/cpufreq/boost >/dev/null || true
    fi
}
trap cleanup EXIT INT TERM

echo -e "\n\033[0;34m================================================================="
echo " ШАГ 4.6: Фиксация окружения перед серией (Snapshot)"
echo -e "=================================================================\033[0m"

if [[ "$DISABLE_BOOST" == true ]]; then
    if [[ -f /sys/devices/system/cpu/cpufreq/boost ]]; then
        ORIG_BOOST_STATE=$(cat /sys/devices/system/cpu/cpufreq/boost)
        echo -e "\033[0;31mОтключение AMD Turbo Boost...\033[0m"
        echo 0 | sudo tee /sys/devices/system/cpu/cpufreq/boost >/dev/null
    else
        echo "[Предупреждение] Файл управления boost не найден."
    fi
fi

echo "Сбор снимка окружения в '$SNAP_FILE'..."
{
    echo "=== СНИМОК ОКРУЖЕНИЯ ПЕРЕД СТАРТОМ СЕРИИ ==="
    echo "Дата/Время: $(date -Iseconds)"
    echo "Целевое ядро (affinity): $CORE"
    echo "Бинарник time: $TIME_BIN"
    echo "Boost disabled: $DISABLE_BOOST"
    echo ""
    echo "--- 1. UPTIME & LOAD AVERAGE ---"
    uptime
    echo ""
    echo "--- 2. ТЕКУЩИЕ ПРОЦЕССЫ (TOP SNAPSHOT) ---"
    top -bn1 | head -n 25
    echo ""
    echo "--- 3. СОСТОЯНИЕ ЧАСТОТ CPU (ядро $CORE) ---"
    cpupower frequency-info || true
    if [[ -f "/sys/devices/system/cpu/cpu${CORE}/cpufreq/scaling_cur_freq" ]]; then
        echo "Текущая частота ядра $CORE: $(cat /sys/devices/system/cpu/cpu${CORE}/cpufreq/scaling_cur_freq) kHz"
    fi
    echo ""
    echo "--- 4. ТЕМПЕРАТУРА И ТЕРМОЗОНЫ ---"
    sensors 2>/dev/null || true
    echo ""
    echo "--- 5. СТАТИСТИКА ПАМЯТИ ---"
    free -h
} > "$SNAP_FILE"

cat "$SNAP_FILE"
echo -e "\n\033[0;32m[OK] Снимок окружения успешно зафиксирован в $SNAP_FILE\033[0m"

echo -e "\n\033[0;34m================================================================="
echo " ШАГ 4.7: Запуск серии измерений (N=$N, Warmup=$WARMUP_RUNS)"
echo " Вариант: Read, Cache vs No Cache, File=$GRAPH_FILE, Core=$CORE"
echo -e "=================================================================\033[0m"

echo "timestamp,run_type,run_id,mode,wall_s,user_s,sys_s,cpu_pct,vol_ctx,invol_ctx,maj_flt,min_flt,max_rss_kb" > "$OUT_CSV"

CMD_PREFIX="taskset -c $CORE"
if [[ "$USE_CHRT" == true ]]; then
    CMD_PREFIX="chrt -f 99 $CMD_PREFIX"
fi

# %e - elapsed real time (sec)
# %U - user CPU time (sec)
# %S - system CPU time (sec)
# %P - CPU percentage
# %w - voluntary context switches
# %c - involuntary context switches
# %F - major page faults
# %R - minor page faults
# %M - maximum resident set size (KB)
TIME_FMT="%e,%U,%S,%P,%w,%c,%F,%R,%M"

run_measurement() {
    local run_type="$1"
    local run_id="$2"
    local mode="$3"

    local extra_args=""
    if [[ "$mode" == "nocache" ]]; then
        extra_args="--no-cache"
    fi

    local ts
    ts=$(date +%s)

    $TIME_BIN -f "$ts,$run_type,$run_id,$mode,$TIME_FMT" -a -o "$OUT_CSV" \
        $CMD_PREFIX $APP $extra_args 1 "$GRAPH_FILE" > /dev/null
}

if (( WARMUP_RUNS > 0 )); then
    echo -e "\n\033[0;33m>>> Выполнение прогревочных запусков (warmup)... \033[0m"
    for (( w=1; w<=WARMUP_RUNS; w++ )); do
        echo -n "  [Warmup $w/$WARMUP_RUNS] mode=cache... "
        run_measurement "warmup" "$w" "cache"
        echo "OK"

        echo -n "  [Warmup $w/$WARMUP_RUNS] mode=nocache (займет ~24 сек)... "
        run_measurement "warmup" "$w" "nocache"
        echo "OK"
    done
fi

echo -e "\n\033[0;33m>>> Старт зачётной серии (интерливинг cache <-> nocache)... \033[0m"

START_SERIES_TS=$(date +%s)

for (( i=1; i<=N; i++ )); do
    echo -e "\n\033[1;36m[Итерация $i/$N]\033[0m"

    echo -n "  -> Запуск 'cache'   (ядро $CORE)... "
    RUN_START=$(date +%s%N)
    run_measurement "test" "$i" "cache"
    RUN_DUR=$(( ($(date +%s%N) - RUN_START) / 1000000 ))
    echo -e "\033[0;32mзавершено за ${RUN_DUR} ms\033[0m"

    echo -n "  -> Запуск 'nocache' (ядро $CORE, ожидание ~24с)... "
    RUN_START=$(date +%s%N)
    run_measurement "test" "$i" "nocache"
    RUN_DUR=$(( ($(date +%s%N) - RUN_START) / 1000000000 ))
    echo -e "\033[0;32mзавершено за ${RUN_DUR} s\033[0m"
done

TOTAL_TIME=$(( $(date +%s) - START_SERIES_TS ))
echo -e "\n\033[0;32m================================================================="
echo " Серия успешно завершена за $(( TOTAL_TIME / 60 )) мин $(( TOTAL_TIME % 60 )) сек!"
echo " Результаты сохранены в: $OUT_CSV"
echo -e "=================================================================\033[0m"

echo -e "\nПервые строки собранного CSV:"
head -n 5 "$OUT_CSV" | column -s, -t
echo "..."
echo -e "\nПоследние строки собранного CSV:"
tail -n 4 "$OUT_CSV" | column -s, -t
