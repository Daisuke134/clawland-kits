# Greenhouse Pro Kit

> Comprehensive greenhouse monitoring and automation kit — soil, climate, CO₂, ventilation control.
> Runs on PicoClaw + LicheeRV-Nano. Replaces $18K–24K/yr greenhouse attendant labor with a ~$120 one-time kit.

## Overview

The Greenhouse Pro kit monitors and controls the four critical greenhouse domains:

| Domain | Sensors | Actuators |
|--------|---------|-----------|
| **Soil** | Capacitive moisture, DS18B20 probe temp | Irrigation solenoid (relay) |
| **Air** | BME280 temp/humidity/pressure, SGP30 CO₂ | Vent fan, misting pump (relay) |
| **Light** | BH1750 lux sensor | Shade curtain (relay/stepper) |
| **Water** | Rain sensor, float switch (reservoir) | Inlet valve (relay) |

## Use Case

Small to medium greenhouse (10–100 m²). The kit prevents the top 4 greenhouse failures:
1. **Overheating** — vent fan auto-trigger at >30°C
2. **Underwatering** — soil moisture <30% → irrigation
3. **CO₂ starvation** — <400 ppm → alert (sealed greenhouses)
4. **Frost** — <2°C air temp → heater relay + alert

## ROI Calculation

| Item | Annual Cost |
|------|-------------|
| Part-time greenhouse attendant (10h/week @ min wage) | $7,200–18,000/yr |
| Crop loss from missed watering (1 event/yr) | $500–5,000 |
| Energy waste from manual vent control | $200–600 |
| **Kit cost (one-time)** | **$120** |
| **Year 1 savings** | **$7,900–23,600** |
| **Payback period** | **< 1 week** |

## Quick Start

1. Order parts from [BOM.md](./BOM.md)
2. Wire sensors per [WIRING.md](./WIRING.md)
3. Flash PicoClaw onto LicheeRV-Nano
4. Copy `skill.yaml` and `alerts.yaml` to the device
5. Run `picclaw skill install greenhouse-pro`
6. Access dashboard at `http://<device-ip>:8080`

## Board Support

| Board | RAM | NPU | Status |
|-------|-----|-----|--------|
| Sipeed LicheeRV-Nano | 256MB | 1 TOPS | ✅ Primary |
| ESP32-S3 + PicoClaw | 512KB PSRAM | ❌ | ✅ Supported |
| Raspberry Pi Pico W | 264KB | ❌ | ⚠️ Reduced features |

## Sensors

| Sensor | Interface | precision | Range |
|--------|-----------|-----------|-------|
| BME280 | I2C 0x76 | ±0.5°C, ±3% RH | -40–85°C, 0–100% RH |
| SGP30 | I2C 0x58 | ±15 ppm | 0–60,000 ppm |
| BH1750 | I2C 0x23 | ±1 lux | 1–65,535 lux |
| Capacitive Soil Moisture v2.0 | ADC | ±3% | 0–100% VWC |
| DS18B20 | 1-Wire | ±0.5°C | -55–125°C |
| Rain sensor (YL-83) | Digital + ADC | — | on/off + intensity |
