# FPGA 설계 프로젝트 - Stopwatch & Watch

> Verilog를 이용해 FPGA 보드에 Stopwatch와 Watch 기능 구현

---

## 📌 프로젝트 개요

- Verilog를 이용해 Basys3 FPGA 보드에 **Stopwatch**와 **Watch** 기능 구현
- FSM(Moore Machine) 기반 상태 제어
- FND Display를 통한 시간 출력

---

## 🛠️ 개발 환경

- Language: Verilog
- Tool: Vivado (Simulation)
- Board: Basys3 (Xilinx Artix-7)

---

## 🎮 입출력 소자

| 구분 | 소자 |
|------|------|
| 입력 | System Clock, Reset, 스위치 3개, 버튼 4개 |
| 출력 | FND Display (`fnd_digit[3:0]`, `fnd_data[7:0]`) |

### Switch

| | sw[2] | sw[1] | sw[0] |
|--|:-----:|:-----:|:-----:|
| 0 | sec.msec | watch | up count |
| 1 | hour.min | stopwatch | down count |

### Button

**Stopwatch**

| 버튼 | 기능 |
|------|------|
| `reset` | reset |
| `btn_l` | clear |
| `btn_r` | run / stop |

**Watch**

| 버튼 | 기능 |
|------|------|
| `reset` | reset |
| `btn_l` | FND 왼쪽 두 자리 선택 |
| `btn_r` | FND 오른쪽 두 자리 선택 |
| `btn_u` | 선택한 위치의 FND값 증가 |
| `btn_d` | 선택한 위치의 FND값 감소 |

---

## ⚙️ 기능 목록

### Stopwatch

- Run / Stop
- Up Count / Down Count
- Hour&Minute / Sec&msec 표시 모드 선택
- Clear (Stop 상태에서만 동작)
- Reset

### Watch

- Hour&Minute / Sec&msec 표시 모드 선택
- 시간 수정 (시, 분, 초)
- Reset 직후 별도의 Start 입력 없이 즉시 실행

---

## 🧱 Block Diagram

### Top Module (`top_stopwatch_watch`)

버튼 4개와 스위치 3개를 입력받아 FND에 표시될 데이터를 출력하는 최상위 모듈

| 모듈명 | Instance | 역할 |
|--------|----------|------|
| `btn_debounce` | U_BD_CLEAR / U_BD_RUNSTOP / U_BD_UP / U_BD_DOWN | 버튼 입력을 1clk 신호로 변환 |
| `stopwatch_control_unit` | U_SW_CONTROL_UNIT | Stopwatch 상태 결정 FSM |
| `watch_control_unit` | U_W_CONTROL_UNIT | Watch 상태 결정 FSM |
| `stopwatch_datapath` | U_STOPWATCH_PATH | Stopwatch 상태에 따라 FND 출력값 결정 |
| `watch_datapath` | U_WATCH_PATH | Watch 상태에 따라 FND 출력값 결정 |
| `mux_2x1_w_sw_sel` | U_Mux_W_SW_SEL | Stopwatch / Watch 데이터 중 FND 표시값 선택 |
| `fnd_controller` | U_FND_CNTL | 입력 데이터를 FND에 표시할 수 있는 형태로 변환 |

---

## 📦 모듈 상세 설명

### `btn_debounce`

버튼 입력값을 **1clk 신호**로 변환하여 출력하는 모듈

- 100kHz tick 생성 후 8-tap Shift Register로 Debounce 구현
- `q_reg`가 전부 1로 채워지면 `debounce = 1`
- `debounce` 신호 발생 후 **1clk 동안만** 신호 유지

---

### `stopwatch_control_unit`

Stopwatch의 상태를 결정하는 **FSM (Moore Machine)**

| 상태 | o_run_stop | o_clear | 전이 조건 |
|------|:----------:|:-------:|---------|
| `STOP` | 0 | 0 | `i_run_stop=1` → RUN / `i_clear=1` → CLEAR |
| `RUN` | 1 | 0 | `i_run_stop=1` → STOP (Clear 동작 안 함) |
| `CLEAR` | 0 | 1 | `i_run_stop=1` → RUN |

> Default State: **STOP**

---

### `watch_control_unit`

Watch의 시간 수정(up/down) 모드를 결정하는 **FSM (Moore Machine)**

| 상태 | o_up | o_down | 전이 조건 |
|------|:----:|:------:|---------|
| `NORMAL` | 0 | 0 | `i_up=1` → UP / `i_down=1` → DOWN |
| `UP` | 1 | 0 | `i_up=0` → NORMAL (버튼 누르면 1clk UP, 다음 clk NORMAL) |
| `DOWN` | 0 | 1 | `i_down=0` → NORMAL |

> Default State: **NORMAL**

---

### `watch_modify_sel`

Watch 시간을 수정할 FND 자리를 결정하는 **FSM (Moore Machine)**

| 상태 | sel_mod_btn | 수정 대상 | 전이 조건 |
|------|:-----------:|---------|---------|
| `LEFT` | 1 | hour, sec | `i_btn_r=1` → RIGHT |
| `RIGHT` | 0 | min, msec | `i_btn_l=1` → LEFT |

> Default State: **LEFT**

---

### `tick_gen_100hz`

**100Hz(10ms)** 마다 tick 신호 발생

- `run_stop_sw = 1` (Run 상태)일 때만 tick 발생
- `F_COUNT = 100_000_000 / 100`으로 분주

---

### `watch_tick_counter`

입력 tick과 파라미터 `TIMES`를 이용해 원하는 주파수의 tick 발생

```
10ms tick × TIMES(100) = 1sec tick  →  w_tick_sec
1sec tick  × TIMES(60)  = 1min tick  →  w_tick_min
1min tick  × TIMES(60)  = 1hour tick →  w_tick_hour
```

수정 대상은 `i_sel_modify`와 `sw_hm_sm`으로 특정:

| | msec | sec | min | hour |
|--|:----:|:---:|:---:|:----:|
| `hour_rst` | 0 | 0 | 0 | 1 |
| `i_sel_modify` (RIGHT=0, LEFT=1) | 0 | 1 | 0 | 1 |
| `sw_hm_sm` (s/ms=0, h/m=1) | 0 | 0 | 1 | 1 |

---

### `sw_tick_counter`

Stopwatch 카운터 모듈 — Up/Down Count 및 Clear 지원

- `mode = 1` (Down Count) : Run 상태에서 counter 감소, 0이 되면 TIMES-1로 wrap
- `mode = 0` (Up Count) : Run 상태에서 counter 증가, TIMES-1이 되면 0으로 wrap
- `reset | clear` 시 counter 0으로 초기화

---

### `fnd_controller`

입력 데이터를 FND Display에 표시할 수 있는 형태로 변환

- `digit_splitter` : hour, min, sec, msec 각각의 1의 자리, 10의 자리 분리
- `dot_onoff` : msec 100의 자리 dot을 0.5초마다 점멸
- `mux_8X1` : FND 요소별 출력값 선택
- `mux_2x1` : `sw[2]` 입력에 따라 h.m / s.ms 결정

---

## 📊 시뮬레이션 결과

### Watch Mode Change Simulation

- s.ms 모드, `modify_sel = LEFT` → up 신호 발생 시 **sec 값 증가**
- h.m 모드, `modify_sel = LEFT` → up 신호 발생 시 **hour 값 증가**
- `modify_sel = RIGHT` → up 신호 발생 시 **min 값 증가**
- msec 100번(0~99) count 후 sec 값 증가 → **tick 정상 동작 확인**

### Stopwatch Mode Change Simulation

- RUN (s.ms / stopwatch / up count) → 시간 증가
- STOP → 시간 멈춤
- CLEAR (이전 상태 STOP) → Clear 동작
- RUN (h.m / stopwatch / up count) → 시간 증가
- Down count → 시간 감소
- RUN 상태에서 Clear → **동작하지 않음 확인**

### Button Debounce Simulation

- 버튼 입력 800kHz 이상 유지 → `o_btn` 1 tick 출력
- 버튼 입력이 길게 들어오더라도 800kHz 지점에서 신호 **한 번만** 발생
