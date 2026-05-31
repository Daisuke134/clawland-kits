# Test Report — Greenhouse Pro Kit

This report defines the validation sequence for the Greenhouse Pro kit and
provides baseline readings to capture during first deployment.

## Test Scope

- Controller boot and sensor discovery
- Relay isolation and actuator mapping
- Baseline environmental readings
- Alert threshold sanity checks
- Short soak test after enclosure close-up

## Test Environment

| Item | Value |
|------|-------|
| Controller | Sipeed LicheeRV-Nano |
| Firmware | PicoClaw + Greenhouse Pro skill |
| Power | 5V/3A logic rail, 12V/2A actuator rail |
| Test duration | 30 minutes minimum |
| Network | Local Wi-Fi or Ethernet bridge |

## Boot Validation

1. Power on the controller with sensors attached but actuators disconnected.
2. Confirm the skill starts without import or bus errors.
3. Confirm the following devices are detected:
   - BME280 at `0x76`
   - SGP30 at `0x58`
   - BH1750 at `0x23`
   - One or more DS18B20 ROM addresses
4. Record boot-to-ready time.

## Baseline Reading Table

Capture this table after a 10-minute warm-up period:

| Metric | Expected initial range | Observed |
|--------|------------------------|----------|
| Air temperature | 10-40 C | |
| Relative humidity | 20-95% | |
| Pressure | 950-1050 hPa | |
| CO2 equivalent | 400-1200 ppm | |
| TVOC | 0-600 ppb | |
| Lux | 0-65,000 | |
| Soil moisture probe 1 | calibrated raw/percent | |
| Soil moisture probe 2 | calibrated raw/percent | |
| Rain analog level | dry baseline | |
| Reservoir float switch | open/closed | |

## Relay Mapping Test

Perform the following one channel at a time:

| Relay | Expected behavior | Pass/Fail |
|-------|-------------------|-----------|
| CH1 | Vent fan starts and stops cleanly | |
| CH2 | Irrigation valve opens without chatter | |
| CH3 | Misting pump starts with stable flow | |
| CH4 | Heater or auxiliary output toggles correctly | |

Notes:
- Never energize all inductive loads on the first pass.
- If a relay chatters, inspect supply sag and ground routing before retesting.

## Sensor Challenge Tests

### Temperature and Humidity

- Warm the BME280 slightly by hand or a warm air stream.
- Verify temperature rises smoothly and humidity trends downward.

### Light

- Cover BH1750 completely, then expose it to direct flashlight illumination.
- Verify lux values move by at least an order of magnitude.

### Soil Moisture

- Measure probe output in air, then insert into moist potting mix.
- Verify the calibrated value changes materially in the expected direction.

### Rain

- Wet the rain plate with a spray bottle.
- Confirm digital rain state flips and analog value changes.

## Alert Threshold Check

Verify the following examples trigger as designed:

| Condition | Expected action |
|-----------|-----------------|
| Air temperature > 30 C | Vent relay on + high-temp alert |
| Soil moisture < 30% | Irrigation relay on or irrigation-needed alert |
| Air temperature < 2 C | Heater relay on + frost alert |
| CO2 below local target floor | Notification only unless closed-loop CO2 injection exists |

## Soak Test

Run the kit for 30 minutes with the enclosure closed:

- No sensor disappears from the bus.
- No relay toggles unexpectedly.
- Controller temperature remains within safe limits.
- Enclosure shows no immediate condensation or cable strain.

## Sign-Off

| Checkpoint | Result |
|------------|--------|
| Sensor discovery complete | |
| Relay mapping complete | |
| Baseline readings captured | |
| Alerts verified | |
| 30-minute soak passed | |

If any row fails, do not deploy to the greenhouse until the cause is isolated and retested.
