# Начало
## Окружение
### Фоновые процессы
Первым делом было решено заняться средой - это явно интереснее и я пока не успел достаточно нагрузить систему. Итак, обращаюсь к https://github.com/secs-dev/os-course/blob/main/doc/experiments/environment.md

> Стоит отметить, что на момент проверки окружения у меня открыт firefox с десятком вкладок, zed, Telegram и AmneziaVPN. Сижу я на KDE.  

Пробую `uptime`:
```shell
> uptime
00:00:19  up   3:34,  1 user,  load average: 1.06, 1.17, 1.25
```

Ого! Целых 1.06, что бесконечно больше нуля! Впрочем, немного ознакомившись с теорией, оказалось, что это число надо воспринимать относительно числа потоков на процессоре. У меня таковых 20, а значит я задействую не более чем 5-10% процессора (непосредственно метрика загрузки CPU 1-3%).

Попробую `top -bn1 | head -20`:
```shell
> top -bn1 | head -20
top - 00:05:17 up  3:39,  1 user,  load average: 0.98, 1.16, 1.22
Tasks: 483 total, 1 running, 475 sleep, 0 d-sleep, 0 stopped, 7 zombie
%Cpu(s):  0.5 us,  0.5 sy,  0.0 ni, 99.1 id,  0.0 wa,  0.0 hi,  0.0 si,  0.0 st 
MiB Mem :  31369.3 total,   8628.7 free,   8401.0 used,  14387.2 buff/cache     
MiB Swap:  80521.0 total,  80521.0 free,      0.0 used.  22968.3 avail Mem 

    PID USER      PR  NI    VIRT    RES    SHR S  %CPU  %MEM     TIME+ COMMAND
  16212 zhabka    20   0 2821652 167180 124172 S   4.8   0.5   0:05.06 Isolate+
      1 root      20   0   20236  16160  11504 S   0.0   0.1   0:03.21 systemd
      2 root      20   0       0      0      0 S   0.0   0.0   0:00.02 kthreadd
      3 root      20   0       0      0      0 S   0.0   0.0   0:00.00 pool_wo+
      4 root       0 -20       0      0      0 I   0.0   0.0   0:00.00 kworker+
      5 root       0 -20       0      0      0 I   0.0   0.0   0:00.00 kworker+
      6 root       0 -20       0      0      0 I   0.0   0.0   0:00.00 kworker+
      7 root       0 -20       0      0      0 I   0.0   0.0   0:00.00 kworker+
      8 root       0 -20       0      0      0 I   0.0   0.0   0:00.00 kworker+
     10 root       0 -20       0      0      0 I   0.0   0.0   0:00.00 kworker+
     11 root      20   0       0      0      0 I   0.0   0.0   0:00.47 kworker+
     13 root       0 -20       0      0      0 I   0.0   0.0   0:00.00 kworker+
     15 root      20   0       0      0      0 S   0.0   0.0   0:00.24 ksoftir+
```
Собственно говоря, 99.1% idle, самый прожорливый процесс - Isolate+, который, судя по всему, относится к firefox. Всё остальное - чисто системная история.

Вот мы и узнали, что моя система чиста и безгрешна. Теперь смотрим на процессор.

### О CPU (пункт 3)

CPU у меня не просто с турбобустом, но ещё и с разными типами ядер. Посмотрим, что мне скажет предложенный `cpupower`:
```shell
> cpupower frequency-info
analyzing CPU 15:
  driver: amd-pstate-epp
  CPUs which run at the same hardware frequency: 15
  CPUs which need to have their frequency coordinated by software: 15
  energy performance preference: performance
  hardware limits: 623 MHz - 3.32 GHz
  available cpufreq governors: performance powersave
  current policy: frequency should be within 623 MHz and 3.32 GHz.
                  The governor "performance" may decide which speed to use
                  within this range.
  current CPU frequency: Unable to call hardware
  current CPU frequency: 2.00 GHz (asserted by call to kernel)
  boost state support:
    Supported: yes
    Active: yes
  amd-pstate limits:
    Highest Performance: 128. Maximum Frequency: 3.32 GHz.
    Nominal Performance: 77. Nominal Frequency: 2.00 GHz.
    Lowest Non-linear Performance: 24. Lowest Non-linear Frequency: 623 MHz.
    Lowest Performance: 24. Lowest Frequency: 599 MHz.
    Preferred Core Support: 0. Preferred Core Ranking: 128.
    
> cpupower frequency-info
analyzing CPU 1:
  driver: amd-pstate-epp
  CPUs which run at the same hardware frequency: 1
  CPUs which need to have their frequency coordinated by software: 1
  energy performance preference: performance
  hardware limits: 623 MHz - 5.09 GHz
  available cpufreq governors: performance powersave
  current policy: frequency should be within 623 MHz and 5.09 GHz.
                  The governor "performance" may decide which speed to use
                  within this range.
  current CPU frequency: Unable to call hardware
  current CPU frequency: 4.21 GHz (asserted by call to kernel)
  boost state support:
    Supported: yes
    Active: yes
  amd-pstate limits:
    Highest Performance: 196. Maximum Frequency: 5.09 GHz.
    Nominal Performance: 77. Nominal Frequency: 2.00 GHz.
    Lowest Non-linear Performance: 24. Lowest Non-linear Frequency: 623 MHz.
    Lowest Performance: 24. Lowest Frequency: 599 MHz.
    Preferred Core Support: 0. Preferred Core Ranking: 208.
```
Прекрасно, так 3.32 или 5.09? 
Выведя `cpupower --cpu all frequency-info`, можно увидеть то, о чём я говорил ранее, у меня 4(8) производительных ядер и 6(12) экономичных, соответственно.
Итак, далее нам предлагается `sudo cpupower frequency-set -g performance`. Но в данном случае это весьма бесполезно, так как `governor` уже в `performance`. 
Ничего неожиданного, максимальная частота не поднялась, а осталась колебаться в районе 1 ГГц.

Ладно, тогда тыкнем turbo boost. Впрочем, предложенный путь мне не подходит (у меня AMD), найдём подходящий.
Вот оно: `cat /sys/devices/system/cpu/cpufreq/boost`
Ну, ладно, отрубим временно турбобуст, ради науки:
`echo 0 | sudo tee /sys/devices/system/cpu/cpufreq/boost`

Как результат, все ядра перешли на 2 ГГц. Впрочем, местами мониторинг системы показывает 632 МГц на ядрах, очевидно, они просто падают в минимальные P-state'ы.


### Забегая в будущее (пункты 4, 5)
Далее предложено биндить какой-то процесс к ядру и менять найсовость процесса. Плавали, знаем. И займусь я этим уже во время исполнения основной задачи лабораторной. Пока что скип.
Впрочем, оставлю пока тут:
```shell
taskset -c 2 ./your_program ...      # закрепить новый процесс на ядро 2
taskset -cp 2 <pid>                  # закрепить уже запущенный процесс
sudo nice -n -5 taskset -c 2 ./your_program ...   # отрицательный nice → выше приоритет, нужен root
renice -n -5 -p <pid>                             # изменить приоритет уже запущенного процесса
```

### Кэши 
Кэш - штука очень многозначная, имеет значения от налички до какого-нибудь Intel Optane. Очень жаль, что эта секция не раскрывает тему кэшей. Однако `sync` всем пострадавшим от работы с флешками в линухе в молодости хорошо известен. По сути это про принудительный сброс кэша в оперативке на диск. Нужен он тут не просто так, слегка разобравшись, можно понять, что если мы не сделаем `sync`, то `echo 3 | sudo tee /proc/sys/vm/drop_caches` сбросит все файлы и то, что сейчас лежит в оперативке и неспешно тянется на диск, может дропнуться из той самой ОЗУ, сломав загрузку.
Что же, поехали:
`sync && echo 3 | sudo tee /proc/sys/vm/drop_caches`

---
В целом, на этом тема окружения заканчивается. Далее идёт специфическая работа. Вероятно, я ещё вернусь к настройке окружения, ведь помимо озвученных тут нюансов, у меня ещё и zram и swap и LUKS и ещё тонна нюансов, которые, похоже, предстоит обкашлять. 

## Паспорт системы
К этому разделу я в самом деле подходил немного ранее, а потому у меня уже в наличии базовый passport.sh
```
echo -e "\n\033[0;31mUname output:\033[1;33m"
uname -a
echo -e "\n\033[0;31mLSCPU:\033[1;33m"
lscpu
lscpu -e
echo -e "\n\033[0;31mCache sizes:\033[1;33m"
cat /proc/cpuinfo | grep -i cache
echo -e "\n\033[0;31mRAM:\033[1;33m"
free -h
echo -e "\n\033[0;31mDisk info:\033[1;33m"
sudo lshw -class disk -class memory -short
echo -e "\n\033[0;31msmartctl:\033[1;33m"
sudo smartctl -a /dev/nvme1
echo -e "\n\033[0;31mDisk Rotation:\033[1;33m"
cat /sys/block/nvme1n1/queue/rotational
echo -e "\n\033[0;31mnproc:\033[1;33m"
nproc
echo -e "\n\033[0;31mnumactl:\033[1;33m"
numactl --hardware
```
Оценивая https://github.com/secs-dev/os-course/blob/main/doc/experiments/monitoring.md стоит отметить 
```shell
perf stat -e task-clock,context-switches,cpu-migrations,page-faults,\
cache-references,cache-misses,cycles,instructions \
  taskset -c 2 <program> ...
```
которого у меня нет. Впрочем, у меня и sysstat не было из:
```shell
vmstat 1        # свободная память, буферы/кэш, swap, %us/%sy/%id CPU, блочный IO (bi/bo)
mpstat -P ALL 1 # загрузка каждого логического CPU отдельно — проверка отсутствия миграций
pidstat -urd 1  # по конкретному PID: %CPU, память, диск (пакет sysstat)
iostat -x 1     # загрузка устройств хранения: %util, await (задержка), r/s, rkB/s
```

Далее ничего интересного. Похоже, пора приступать к основе.

## Работа
Вариант: `Read,Cache vs No Cache,7M,Rand`
Seed: `435169`
### Подгтовка тестовых данных
Будем действовать по порядку. Начинаем с генерации тестовых данных. Судя по варианту (к сожалению, они прописаны крайне не тривиально) надо готовить такие данные:
```shell
./graphgen.py -s 7M --seed 435169 --topology chain -b 0.5 --min-step-pages 2 -o 
Файл записан: graph-rand.bin
  размер файла:        7340032 байт (запрошено: 7340032)
  число вершин:        305833
  размер записи:       24 байт
  fan_out:             1
  page_size:           4096
  min_step_nodes:      342 (~8208 байт)
  root_index:          252860  (offset=6068680)
  рёбер всего:         305832
  доля вперёд/назад:   0.500 / 0.500 (запрошено backprob=0.5)
  доля 'коротких' переходов (< min_step_nodes): 0.008

/* ------------------------------------------------------------------------
 * Автоматически сгенерировано graphgen.py для текущих параметров:
 *   size=7M  fanout=1  backprob=0.5
 *   page_size=4096  min_step_pages=2.0
 *   seed=435169
 *
 *   node_count      = 305833
 *   record_size     = 24 байт
 *   min_step_nodes  = 342 (~8208 байт)
 *
 *   ВНИМАНИЕ: page_size/backprob/seed/min_step_nodes НЕ хранятся в самом
 *   файле (сознательно, чтобы читающая программа не могла подстроиться
 *   под гиперпараметры генерации) — они есть только здесь, в этом
 *   сгенерированном для СБОРКИ снипете, и в консольном выводе генератора.
 * ------------------------------------------------------------------------ */
#include <stdint.h>
#include <stddef.h>

#define GCACHEG_MAGIC        "GCACHEG1"   /* 8 байт, без завершающего нуля  */
#define GCACHEG_VERSION      1u
#define GCACHEG_FAN_OUT      1
#define GCACHEG_NODE_COUNT   305833ULL
#define GCACHEG_RECORD_SIZE  24u
#define GCACHEG_SENTINEL     0xFFFFFFFFFFFFFFFFULL  /* пустой слот children[] */

#pragma pack(push, 1)

/* Заголовок файла, ровно 40 байт, little-endian, без выравнивания.
 * Гиперпараметры генерации (page_size, backprob, seed, min_step_nodes)
 * в файл намеренно не пишутся. */
typedef struct {
    char     magic[8];             /* "GCACHEG1"                      */
    uint32_t version;
    uint64_t node_count;
    uint32_t record_size;          /* == sizeof(gcacheg_node_t)       */
    uint32_t fan_out;
    uint64_t root_index;           /* индекс стартовой вершины обхода */
    uint32_t flags;                /* bit0: 1 = граф ацикличен (DAG)  */
} gcacheg_header_t;

/* Запись одной вершины, 24 байт. */
typedef struct {
    int64_t  value;                    /* payload, можно менять при записи */
    uint32_t degree;                   /* фактическое число детей <= fan_out */
    uint32_t reserved;
    uint64_t children[GCACHEG_FAN_OUT]; /* индексы; неисп. слоты = SENTINEL  */
} gcacheg_node_t;

#pragma pack(pop)

_Static_assert(sizeof(gcacheg_header_t) == 40, "header size mismatch");
_Static_assert(sizeof(gcacheg_node_t) == GCACHEG_RECORD_SIZE, "record size mismatch");

/* offset(i) = header + i * record_size, O(1) доступ по индексу */
static inline uint64_t gcacheg_node_offset(uint64_t index) {
    return (uint64_t)sizeof(gcacheg_header_t) + index * (uint64_t)sizeof(gcacheg_node_t);
}
```
Т.е. да, поменяны только тривиальные характеристики, остальное украдено с методички.

### Сборка приложений
Говорить нечего, тут даже либ нет. Две команды clang и проехали.

### Этап 1: исследование graph_traverse (read/lseek)
Будем делать данный этап в формате скрипта `stage-1.sh`.
#### Снятие паспорта системы.
Паспортирование - штука подотчётная и мне она нужна будет всего пару раз, потому закинем её в условие:
```shell
if [[ "$VERBOSE" == true ]] && [[ "$PASSPORT" == true ]]; then
    bash passport.sh | tee "$PASSPORT_FILE"
elif [[ "$PASSPORT" == true ]]; then
    bash passport.sh > "$PASSPORT_FILE"
elif [[ "$VERBOSE" == true ]]; then
    bash passport.sh
fi
```

#### Подготовка окружения
По сути, с моим процессором и системой (учитывая настройки TLP и т.п.) у меня только два требования перед началом - подключиться к розетке и выключить турбобуст.
Добавим выключение турбобуста на время `stage-1` по флагу `-c` (к сожалению `-p` (pure) уже занят, поэтому будет `-b` (boost) `:D`)
```shell
if [[ "$BOOST" == true ]]; then
    echo -e "\n\033[0;31mDISABLING TURBOBOOST\033[1;33m"
    echo 0 | sudo tee /sys/devices/system/cpu/cpufreq/boost
fi
*** здесь будет код проверки ***
if [[ "$BOOST" == true ]]; then
    echo -e "\n\033[0;31mENABLING TURBOBOOST\033[1;33m"
    echo 1 | sudo tee /sys/devices/system/cpu/cpufreq/boost
fi
```
> Естественно, не одним турбобустом едины, но всё это я буду ещё и запускать на одном ядре (заодно, кстати, слегка расширю лабу тестами на экономичных и производительных ядрах в разных режимах) 
> По хорошему надо проверить ядро 2 (быстрое), ядро 6 (энергоэффективное), потенциально одновременно ядра 2 и 12 (борьба потоков), без ядер, с уходом в миграцию.

#### Ознакомительные измерения
В скрипт stage-1 были добавлены следующие строчки:
```shell
/etc/profiles/per-user/zhabka/bin/time -v chrt -f 99 taskset -c 2 ./out/graph_traverse 1 graph-rand.bin
/etc/profiles/per-user/zhabka/bin/time -v chrt -f 99 taskset -c 2 ./out/graph_traverse --no-cache 1 graph-rand.bin
```
> (дада нихось-юзера видно издалека... так и живём)
Вывели они много интересного:
```
FIRST LAUNCH
Iteration 1/1 (read): traversing graph-rand.bin ... OK (305833 nodes processed)
        Command being timed: "chrt -f 99 taskset -c 2 ./out/graph_traverse 1 graph-rand.bin"
        User time (seconds): 0.01
        System time (seconds): 0.05
        Percent of CPU this job got: 97%
        Elapsed (wall clock) time (h:mm:ss or m:ss): 0:00.06
        Average shared text size (kbytes): 0
        Average unshared data size (kbytes): 0
        Average stack size (kbytes): 0
        Average total size (kbytes): 0
        Maximum resident set size (kbytes): 2176
        Average resident set size (kbytes): 0
        Major (requiring I/O) page faults: 0
        Minor (reclaiming a frame) page faults: 226
        Voluntary context switches: 1
        Involuntary context switches: 1
        Swaps: 0
        File system inputs: 0
        File system outputs: 0
        Socket messages sent: 0
        Socket messages received: 0
        Signals delivered: 0
        Page size (bytes): 4096
        Exit status: 0
Iteration 1/1 (read): traversing graph-rand.bin ... OK (305833 nodes processed)
        Command being timed: "chrt -f 99 taskset -c 2 ./out/graph_traverse --no-cache 1 graph-rand.bin"
        User time (seconds): 0.06
        System time (seconds): 0.73
        Percent of CPU this job got: 3%
        Elapsed (wall clock) time (h:mm:ss or m:ss): 0:23.39
        Average shared text size (kbytes): 0
        Average unshared data size (kbytes): 0
        Average stack size (kbytes): 0
        Average total size (kbytes): 0
        Maximum resident set size (kbytes): 2240
        Average resident set size (kbytes): 0
        Major (requiring I/O) page faults: 0
        Minor (reclaiming a frame) page faults: 232
        Voluntary context switches: 307033
        Involuntary context switches: 9
        Swaps: 0
        File system inputs: 2456216
        File system outputs: 0
        Socket messages sent: 0
        Socket messages received: 0
        Signals delivered: 0
        Page size (bytes): 4096
        Exit status: 0
```
307 тысяч контекстных свитчей, страшно. Оценим ещё и через perf и с шумом.
```shell
PERF METRICS:
Iteration 1/1 (read): traversing graph-rand.bin ... OK (305833 nodes processed)

 Performance counter stats for 'taskset -c 2 ./out/graph_traverse 1 graph-rand.bin':

                 3      context-switches                                                      
                 1      cpu-migrations                                                        
               131      page-faults                                                           
           431,601      cache-misses                                                          
       401,902,334      cycles                                                                
       738,103,121      instructions                                                          

       0.083981033 seconds time elapsed

       0.012968000 seconds user
       0.070831000 seconds sys


Iteration 1/1 (read): traversing graph-rand.bin ... OK (305833 nodes processed)

 Performance counter stats for 'taskset -c 2 ./out/graph_traverse --no-cache 1 graph-rand.bin':

           307,892      context-switches                                                      
                 1      cpu-migrations                                                        
               132      page-faults                                                           
        23,511,034      cache-misses                                                          
     5,089,095,630      cycles                                                                
     7,718,277,852      instructions                                                          

      24.155095480 seconds time elapsed

       0.071629000 seconds user
       1.260086000 seconds sys



STRESS METRICS:

WITH chrt REALTIME PRIOIRTY:
Iteration 1/1 (read): traversing graph-rand.bin ... OK (305833 nodes processed)
        Command being timed: "chrt -f 99 taskset -c 2 ./out/graph_traverse 1 graph-rand.bin"
        User time (seconds): 0.01
        System time (seconds): 0.06
        Percent of CPU this job got: 100%
        Elapsed (wall clock) time (h:mm:ss or m:ss): 0:00.08
        Average shared text size (kbytes): 0
        Average unshared data size (kbytes): 0
        Average stack size (kbytes): 0
        Average total size (kbytes): 0
        Maximum resident set size (kbytes): 2240
        Average resident set size (kbytes): 0
        Major (requiring I/O) page faults: 0
        Minor (reclaiming a frame) page faults: 226
        Voluntary context switches: 1
        Involuntary context switches: 1
        Swaps: 0
        File system inputs: 0
        File system outputs: 0
        Socket messages sent: 0
        Socket messages received: 0
        Signals delivered: 0
        Page size (bytes): 4096
        Exit status: 0

NO chrt REALTIME PRIOIRTY:
Iteration 1/1 (read): traversing graph-rand.bin ... OK (305833 nodes processed)
        Command being timed: "taskset -c 2 ./out/graph_traverse 1 graph-rand.bin"
        User time (seconds): 0.01
        System time (seconds): 0.06
        Percent of CPU this job got: 49%
        Elapsed (wall clock) time (h:mm:ss or m:ss): 0:00.15
        Average shared text size (kbytes): 0
        Average unshared data size (kbytes): 0
        Average stack size (kbytes): 0
        Average total size (kbytes): 0
        Maximum resident set size (kbytes): 2036
        Average resident set size (kbytes): 0
        Major (requiring I/O) page faults: 0
        Minor (reclaiming a frame) page faults: 149
        Voluntary context switches: 1
        Involuntary context switches: 30
        Swaps: 0
        File system inputs: 0
        File system outputs: 0
        Socket messages sent: 0
        Socket messages received: 0
        Signals delivered: 0
        Page size (bytes): 4096
        Exit status: 0

 STOPPING STRESS 
```

Неожиданно и приятно было увидеть >= 1 инструкции на такт, так же забавно честное распределение задач на ядре. 
Пожалуй, самая интересная статистика по ядру получается в perf. По сему попробуем то же самое на экономичном ядре. Очевидно, боттлнек IO нам не интересен, потому смотрим только случай с кэшем.

```shell
PERF METRICS:
Iteration 1/1 (read): traversing graph-rand.bin ... OK (305833 nodes processed)

 Performance counter stats for 'chrt -f 99 taskset -c 6 ./out/graph_traverse 1 graph-rand.bin':
                 1      context-switches                                                      
                 1      cpu-migrations                                                        
               202      page-faults                                                           
           417,245      cache-misses                                                          
       297,145,588      cycles                                                                
       739,116,638      instructions                                                          

       0.089885822 seconds time elapsed

       0.025196000 seconds user
       0.064503000 seconds sys
```

Разница - <5 процентов. Оказывается, разница между Zen 4 и Zen 4c только в частоте. Забавно ещё и то, что по тактам энергоэффективное ядро выигрывает, давая >2 IPC, что является следствием низкой частоты (задержки кэша те же, однако в меньшей частоте это будет ~30 тактов, а не ~50 как при высокой).

#### Гипотеза
У меня - один из худших для тестирования стендов
Ладно, не совсем, но всё же. С одной стороны, у меня SSD и куча кэша на ядрах, ну и распаянная DDR5, которая тут вряд-ли играет большую роль, но всё же. С другой - у меня btrfs (что вроде не так страшно, ибо задача на чтение, а файл был сгенерен единожды и более не перезаписывался (`graph-rand.bin: 1 extent found`)) и LUKS (что означает, что без кэша мы сверху дополнительно прогоняем всё через шифрование).

Чего я в общем ожидаю? Что всё будет плохо без кэша, шикарно с ним. На данный момент я не знаю точного устройства ОС, а потому не уверен, кэшируется ли что-то в cryptroot и имеет ли это вообще значение, из-за чего не могу дать точного ответа - улучшится ли no-cache картина при многократном последовательном запуске.

#### Планирование эксперимента
Так как доступ без кэша занимает почти 30 секунд, ограничимся выборкой из 10 на первый раз, далее прикинем всё по статистике.


#### Проведение серии измерений
Вайбим скрипт для сбора данных и статистику по нему. Времени хватило на 150 проверок, а посему из интереса сделаем их.
Аналогичную серию измерений проводим для mmap. 
Первичное измерение меня удивило. --no-cache версия справлялась за считанные милисекунды. 
Ответ оказался прост - я не очищал кэш, ну а ОС, следуя принципу работы mmap, просто крала всё из Page Cache. 
Решение - очищать кэш перед каждым запуском. 
```

[Итерация 15/15]
  -> Запуск 'cache'   (ядро 2)... Iteration 1/1 (read): traversing graph-rand.bin ... OK (305833 nodes processed)
завершено за 21 ms
  -> Запуск 'nocache' (ядро 2, )... 3
Iteration 1/1 (read): traversing graph-rand.bin ... OK (305833 nodes processed)
завершено за 61 ms

=================================================================
 Серия успешно завершена за 0 мин 4 сек!
 Результаты сохранены в: results_stage2.csv
=================================================================

Первые строки собранного CSV:
timestamp   run_type  run_id  mode     wall_s  user_s  sys_s  cpu_pct  vol_ctx  invol_ctx  maj_flt  min_flt  max_rss_kb
1790581357  warmup    1       cache    0.02    0.02    0.00   96%      1        1          0        340      8776
1790581358  warmup    1       nocache  0.05    0.02    0.00   59%      79       2          10       339      8740
1790581358  test      1       cache    0.02    0.02    0.00   93%      1        1          0        342      8776
1790581358  test      1       nocache  0.05    0.02    0.00   61%      75       6          10       340      8740
```
И вот уже казалось бы нормальные данные...
Но... 60мс на то, что читалось за 28с?... При том без кэша мажорные pagefltы происходят. LLMки подсказывают, что 10 обращений к SSD реальны и он попросту гоняет бОльшие объёмы за каждый запрос "на всякий случай".
Добавим в логи проверку загрузки файла в Page Cache через`fincore graph-rand.bin`. Также посмотрим на программу через `perf` с `block:block_rq_issue`.

```shell
> sync && echo 3 | sudo tee /proc/sys/vm/drop_caches
> sudo perf record -e major-faults,block:block_rq_issue taskset -c 2 ./out/graph_traverse_mmap 1 graph-rand.bin
> sudo perf script

graph_traverse_ 1264623 82545.600573:          1         major-faults:      777475998155 __memmove_avx512_unaligned_erms+0x95 (/nix/store/n51dhmdbik1kfrsm62j5knavmigwrl1a-glibc-2.42-84/lib/libc.so.6)
 graph_traverse_ 1264623 [002] 82545.601537: block:block_rq_issue: 259,1 RA 131072 () 2209576568 + 256 0x2,0,4 [graph_traverse_]
 graph_traverse_ 1264623 [002] 82545.601542: block:block_rq_issue: 259,1 RA 131072 () 2209576824 + 256 0x2,0,4 [graph_traverse_]
 graph_traverse_ 1264623 [002] 82545.601546: block:block_rq_issue: 259,1 RA 131072 () 2209577080 + 256 0x2,0,4 [graph_traverse_]
 graph_traverse_ 1264623 [002] 82545.601550: block:block_rq_issue: 259,1 RA 131072 () 2209577336 + 256 0x2,0,4 [graph_traverse_]
 graph_traverse_ 1264623 [002] 82545.601553: block:block_rq_issue: 259,1 RA 131072 () 2209577592 + 256 0x2,0,4 [graph_traverse_]
 graph_traverse_ 1264623 [002] 82545.601557: block:block_rq_issue: 259,1 RA 131072 () 2209577848 + 256 0x2,0,4 [graph_traverse_]
 graph_traverse_ 1264623 [002] 82545.601561: block:block_rq_issue: 259,1 RA 131072 () 2209578104 + 256 0x2,0,4 [graph_traverse_]
 graph_traverse_ 1264623 [002] 82545.601565: block:block_rq_issue: 259,1 RA 131072 () 2209578360 + 256 0x2,0,4 [graph_traverse_]
 graph_traverse_ 1264623 [002] 82545.601627: block:block_rq_issue: 259,1 RA 4096 () 2209578616 + 8 0x2,0,4 [graph_traverse_]
```
Так и получилось! За один major-fault ядро запросило целую кучу пакетов. Более того, кучу из них оно запросило заранее, до обхода. Ну и все эти пакеты по 128кб, что довольно быстро.
