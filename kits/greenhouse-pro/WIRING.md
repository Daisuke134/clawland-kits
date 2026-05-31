# Wiring Guide — Greenhouse Pro Kit

## Board: Sipeed LicheeRV-Nano (SG2002)

### Pin Mapping

```
                    LicheeRV-Nano GPIO Header
                    ╔══════════════════════════╗
    3.3V  ── [1]   ║  1   2  ║  5V             ║
    SDA   ── [3]   ║  3   4  ║  5V             ║
    SCL   ── [5]   ║  5   6  ║  GND            ║
    GP4   ── [7]   ║  7   8  ║  GP14 (TX)      ║
    GND   ── [9]   ║  9  10  ║  GP15 (RX)      ║
   GP17   ── [11]  ║ 11  12  ║  GP18            ║
   GP27   ── [13]  ║ 13  14  ║  GND            ║
   GP22   ── [15]  ║ 15  16  ║  GP23            ║
    3.3V  ── [17]  ║ 17  18  ║  GP24            ║
   GP10   ── [19]  ║ 19  20  ║  GND            ║
    GP9   ── [21]  ║ 21  22  ║  GP25            ║
   GP11   ── [23]  ║ 23  24  ║  GP8             ║
    GND   ── [25]  ║ 25  26  ║  GP7             ║
    GP0   ── [27]  ║ 27  28  ║  GP1             ║
    GP5   ── [29]  ║ 29  30  ║  GND            ║
    GP6   ── [31]  ║ 31  32  ║  GP12            ║
   GP13   ── [33]  ║ 33  34  ║  GND            ║
   GP19   ── [35]  ║ 35  36  ║  GP16            ║
   GP26   ── [37]  ║ 37  38  ║  GP20            ║
    GND   ── [39]  ║ 39  40  ║  GP21            ║
                    ╚══════════════════════════╝
```

## I²C Bus (pins 3, 5)

All I²C sensors share SDA (pin 3) and SCL (pin 5) with unique addresses:

```
    3.3V ──────────────────────────────┬──────────┬──────────┬──────────┐
    GND  ──────────────────────────────┼──────────┼──────────┼──────────┤
    SDA  ──────────────────────────────┼──────────┼──────────┼──────────┤
    SCL  ──────────────────────────────┼──────────┼──────────┼──────────┤
                                       │          │          │          │
                                  ┌────┴────┐ ┌───┴───┐ ┌───┴───┐      │
                                  │ BME280  │ │ SGP30 │ │BH1750 │      │
                                  │ 0x76    │ │ 0x58  │ │ 0x23  │      │
                                  └─────────┘ └───────┘ └───────┘      │
                                                                        │
    4.7kΩ pull-ups on SDA/SCL to 3.3V (often built into breakout boards)
```

## 1-Wire Bus (pin 7)

```
    3.3V ────┬──── 4.7kΩ ────┬────────── Data bus (pin 7 / GPIO4)
             │               │
    DS18B20 #1               DS18B20 #2
    (soil probe 1)           (soil probe 2)
             │               │
    GND ─────┴───────────────┴──── GND
```

**Important**: Each DS18B20 has a unique 64-bit ROM address. The driver auto-discovers all probes on the bus. No address configuration needed.

## Soil Moisture Sensors (ADC, pin 37 / GPIO26)

```
    3.3V ──── VCC (red)
    GND  ──── GND (black)
    GPIO26 ──── AOUT (yellow) — analog output
```

**Note**: Capacitive v2.0 sensors are corrosion-resistant. Do NOT use resistive probes — they corrode in 2-4 weeks of continuous use.

## Rain Sensor YL-83 (pins 8, 13)

```
    3.3V ──── VCC
    GND  ──── GND
    GPIO14 ──── DO (digital output — LOW when raining)
    GPIO27 ──── AO (analog output — rain intensity)
```

## Relay Module (pins 35, 36, 11, 12)

4-channel optocoupler relay module, **active LOW**:

```
    LicheeRV-Nano            Relay Module
    ─────────────            ─────────────
    GPIO16 (pin 36) ──────── IN1 → CH1: Vent Fan
    GPIO17 (pin 11) ──────── IN2 → CH2: Irrigation Solenoid
    GPIO18 (pin 12) ──────── IN3 → CH3: Misting Pump
    GPIO19 (pin 35) ──────── IN4 → CH4: Heater/Aux
    5V (pin 2/4)   ──────── VCC (JD-VCC jumper REMOVED)
    GND (pin 9)    ──────── GND

    External 12V PSU ─────── JD-VCC + GND (for relay coils)
```

**⚠️ Safety**: Remove the VCC-JD-VCC jumper on the relay module. Power the relay coils from the 12V supply, NOT from the LicheeRV-Nano 5V pin. The Nano's 5V rail cannot supply enough current for 4 relay coils.

## Actuator Wiring (12V side)

```
    12V PSU (+) ───────┬──────────┬──────────┬──────────┬──────────┐
                       │          │          │          │          │
                  ┌────┴────┐ ┌───┴───┐ ┌───┴───┐ ┌───┴───┐      │
                  │ Relay 1 │ │Relay 2│ │Relay 3│ │Relay 4│      │
                  │   COM   │ │  COM  │ │  COM  │ │  COM  │      │
                  └────┬────┘ └───┬───┘ └───┬───┘ └───┬───┘      │
                       │          │          │          │          │
                       │ NO       │ NO       │ NO       │ NO       │
                       │          │          │          │          │
                  Vent Fan   Solenoid   Misting    Heater
                       │       Valve      Pump         │
                       │          │          │          │
    GND ───────────────┴──────────┴──────────┴──────────┘
```

## Assembly Checklist

- [ ] Mount LicheeRV-Nano in weatherproof junction box (IP65)
- [ ] Wire I²C bus first — verify with `i2c.scan()` showing 0x23, 0x58, 0x76
- [ ] Add DS18B20 probes with 4.7kΩ pull-up resistor
- [ ] Connect soil moisture sensors (keep electronics above soil line)
- [ ] Wire relay module with external 12V supply
- [ ] Test each relay individually before connecting actuators
- [ ] Secure all connections with heat-shrink tubing
- [ ] Drill cable glands for sensor cables exiting the box
- [ ] Mount sensors at representative positions (not near vents/heaters)

## Power Budget

| Component | Voltage | Current (max) | Power |
|-----------|---------|---------------|-------|
| LicheeRV-Nano | 5V | 500mA | 2.5W |
| BME280 | 3.3V | 1mA | 0.003W |
| SGP30 | 3.3V | 48mA | 0.16W |
| BH1750 | 3.3V | 0.2mA | 0.001W |
| DS18B20 ×2 | 3.3V | 4mA | 0.013W |
| Soil Moisture ×3 | 3.3V | 15mA | 0.05W |
| Rain Sensor | 3.3V | 15mA | 0.05W |
| Relay coils ×4 | 12V | 280mA | 3.36W |
| Vent Fan | 12V | 200mA | 2.4W |
| Solenoid Valve | 12V | 300mA | 3.6W |
| Misting Pump | 12V | 500mA | 6.0W |
| **Total 5V/3.3V** | — | ~583mA | **~2.8W** |
| **Total 12V** | — | ~1.28A | **~15.4W** |

**Recommended PSU**: 5V 3A + 12V 2A (or single ATX PSU with both rails).
