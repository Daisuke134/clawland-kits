# Assembly Guide — Greenhouse Pro Kit

This guide assumes the parts listed in [BOM.md](./BOM.md) and the wiring plan in
[WIRING.md](./WIRING.md).

## Build Targets

- Primary controller: Sipeed LicheeRV-Nano
- Enclosure: IP65-rated junction box with cable glands
- Power rails: 5V/3A for controller, 12V/2A for relays and actuators

## Tools

- Precision screwdriver set
- Wire stripper and ferrule crimper
- JST dupont jumper kit
- Heat gun or lighter for heat-shrink tubing
- Multimeter
- Label maker or masking tape marker

## Pre-Assembly Checklist

- Verify all sensor boards are present and visually undamaged.
- Bench-test the LicheeRV-Nano over USB before mounting it in the enclosure.
- Confirm the relay board is an optocoupled 4-channel module with separate coil power.
- Cut sensor leads to the final run length only after confirming greenhouse placement.

## Step 1 — Prepare the Enclosure

1. Drill one cable gland hole for low-voltage sensor leads and one for 12V actuator wiring.
2. Mount the controller standoffs so the LicheeRV-Nano does not touch the enclosure floor.
3. Reserve one side of the box for the relay board to keep high-current wiring away from the I2C bus.
4. Label the inside rails `3V3`, `5V`, `12V`, and `GND`.

## Step 2 — Install the Controller

1. Mount the LicheeRV-Nano to the standoffs.
2. Route a short 4-wire harness for the I2C backbone:
   - `3.3V`
   - `GND`
   - `SDA`
   - `SCL`
3. Add the DS18B20 pull-up resistor now so the 1-Wire bus does not get forgotten later.

## Step 3 — Build the Sensor Backbone

1. Connect BME280, SGP30, and BH1750 to the shared I2C harness.
2. Keep the I2C branch stubs short; if the bus exceeds 1 m total, use twisted-pair for SDA/GND and SCL/GND.
3. Mount the BME280 and SGP30 in a ventilated shield away from direct mist and irrigation spray.
4. Place BH1750 where it sees canopy light, not the shadow of the controller box.

## Step 4 — Install Soil and Weather Sensors

1. Insert capacitive moisture probes vertically at root depth.
2. Keep the probe electronics and header above the soil line.
3. Route DS18B20 probes alongside the irrigation path, but not touching metal pipes.
4. Mount the rain sensor where it sees actual rainfall and can dry quickly after the event.

## Step 5 — Relay and Actuator Wiring

1. Remove the relay board VCC/JD-VCC jumper.
2. Power relay logic from the controller side and relay coils from the 12V rail.
3. Connect relays in this order:
   - `CH1`: Vent fan
   - `CH2`: Irrigation solenoid
   - `CH3`: Misting pump
   - `CH4`: Heater or spare auxiliary load
4. Before attaching real actuators, test each relay with a multimeter and indicator LED load.

## Step 6 — First Boot

1. Flash PicoClaw and boot the board on the bench.
2. Copy `skill.yaml` and `alerts.yaml` into the device config path.
3. Run the sensor scan and verify:
   - BME280 reports temperature and humidity
   - SGP30 returns non-zero CO2 and TVOC after warm-up
   - BH1750 changes with flashlight exposure
   - DS18B20 probes enumerate on the 1-Wire bus
   - Soil ADC values move when the probe is inserted into wet soil
4. Toggle each relay once with no live irrigation line connected.

## Step 7 — Greenhouse Placement

1. Mount the enclosure above splash height.
2. Keep the controller box shaded to avoid self-heating bias in the air sensors.
3. Add drip loops before every enclosure entry point.
4. Separate 12V actuator cables from sensor cabling by at least 5 cm where possible.

## Calibration Pass

1. Air temperature: compare BME280 to a trusted handheld thermometer for 10 minutes.
2. Soil moisture: record dry-air value, field-capacity value, and saturated value for each soil type.
3. CO2: allow the SGP30 to warm for at least 15 seconds before judging baseline output.
4. Light: compare BH1750 noon sun and shaded canopy values to set alert thresholds.

## Maintenance Schedule

- Daily: confirm the dashboard updates and relay toggles are quiet when thresholds are normal.
- Weekly: inspect cable glands, probe seating, and condensation inside the enclosure.
- Monthly: re-check soil calibration and clean the rain sensor plate.
- Seasonal: inspect relay contacts and replace any actuator with rising current draw.

## Acceptance Criteria

- All sensors produce plausible data for 30 consecutive minutes.
- Each relay switches the correct actuator with no cross-triggering.
- Dashboard values remain stable through one full irrigation cycle.
- Enclosure remains dry after one watering or rain event.
