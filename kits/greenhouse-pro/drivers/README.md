# Greenhouse Pro — PicoClaw Driver Scripts

## bme280.py — Temperature, Humidity, Pressure

```python
"""BME280 driver for PicoClaw Greenhouse Pro Kit.
I2C address: 0x76 (SDO pulled low).
"""
import machine
import time

BME280_I2C_ADDR = 0x76
BME280_REG_ID = 0xD0
BME280_REG_CTRL_HUM = 0xF2
BME280_REG_CTRL_MEAS = 0xF4
BME280_REG_CONFIG = 0xF5
BME280_REG_PRESS_MSB = 0xF7

class BME280:
    def __init__(self, i2c, addr=BME280_I2C_ADDR):
        self.i2c = i2c
        self.addr = addr
        self.dig_T1 = 0
        self.dig_T2 = 0
        self.dig_T3 = 0
        self.dig_P1 = 0
        self.dig_P2 = 0
        self.dig_P3 = 0
        self.dig_P4 = 0
        self.dig_P5 = 0
        self.dig_P6 = 0
        self.dig_P7 = 0
        self.dig_P8 = 0
        self.dig_P9 = 0
        self.dig_H1 = 0
        self.dig_H2 = 0
        self.dig_H3 = 0
        self.dig_H4 = 0
        self.dig_H5 = 0
        self.dig_H6 = 0
        self.t_fine = 0
        
        chip_id = self._read_u8(BME280_REG_ID)
        if chip_id != 0x60:
            raise RuntimeError(f"BME280 not found at 0x{addr:02X}, chip_id=0x{chip_id:02X}")
        
        self._load_calibration()
        self._setup()

    def _read_u8(self, reg):
        return self.i2c.readfrom_mem(self.addr, reg, 1)[0]

    def _read_s16_le(self, reg):
        data = self.i2c.readfrom_mem(self.addr, reg, 2)
        return (data[1] << 8) | data[0]

    def _read_u16_le(self, reg):
        data = self.i2c.readfrom_mem(self.addr, reg, 2)
        return (data[1] << 8) | data[0]

    def _load_calibration(self):
        self.dig_T1 = self._read_u16_le(0x88)
        self.dig_T2 = self._read_s16_le(0x8A)
        self.dig_T3 = self._read_s16_le(0x8C)
        self.dig_P1 = self._read_u16_le(0x8E)
        self.dig_P2 = self._read_s16_le(0x90)
        self.dig_P3 = self._read_s16_le(0x92)
        self.dig_P4 = self._read_s16_le(0x94)
        self.dig_P5 = self._read_s16_le(0x96)
        self.dig_P6 = self._read_s16_le(0x98)
        self.dig_P7 = self._read_s16_le(0x9A)
        self.dig_P8 = self._read_s16_le(0x9C)
        self.dig_P9 = self._read_s16_le(0x9E)
        self.dig_H1 = self._read_u8(0xA1)
        self.dig_H2 = self._read_s16_le(0xE1)
        self.dig_H3 = self._read_u8(0xE3)
        e4 = self._read_u8(0xE4)
        e5 = self._read_u8(0xE5)
        e6 = self._read_u8(0xE6)
        self.dig_H4 = (e4 << 4) | (e5 & 0x0F)
        self.dig_H5 = ((e5 >> 4) & 0x0F) | (e6 << 4)
        self.dig_H6 = self._read_u8(0xE7)
        if self.dig_H6 > 127:
            self.dig_H6 -= 256

    def _setup(self):
        self.i2c.writeto_mem(self.addr, BME280_REG_CTRL_HUM, b'\x01')  # oversample humidity x1
        self.i2c.writeto_mem(self.addr, BME280_REG_CTRL_MEAS, b'\x27')  # oversample T/P x1, normal mode
        self.i2c.writeto_mem(self.addr, BME280_REG_CONFIG, b'\xA0')     # 1000ms standby, filter off

    def _compensate_T(self, adc_T):
        var1 = ((adc_T >> 3) - (self.dig_T1 << 1)) * (self.dig_T2 >> 11)
        var2 = (((((adc_T >> 4) - self.dig_T1) * ((adc_T >> 4) - self.dig_T1)) >> 12) * self.dig_T3) >> 14
        self.t_fine = var1 + var2
        return (self.t_fine * 5 + 128) >> 8

    def _compensate_P(self, adc_P):
        var1 = self.t_fine - 128000
        var2 = var1 * var1 * self.dig_P6
        var2 = var2 + ((var1 * self.dig_P5) << 17)
        var2 = var2 + (self.dig_P4 << 35)
        var1 = ((var1 * var1 * self.dig_P3) >> 8) + ((var1 * self.dig_P2) << 12)
        var1 = (((1 << 47) + var1) * self.dig_P1) >> 33
        if var1 == 0:
            return 0
        p = 1048576 - adc_P
        p = int((((p << 31) - var2) * 3125) / var1)
        var1 = (self.dig_P9 * (p >> 13) * (p >> 13)) >> 25
        var2 = (self.dig_P8 * p) >> 19
        p = ((p + var1 + var2) >> 8) + (self.dig_P7 << 4)
        return p

    def _compensate_H(self, adc_H):
        v_x1_u32r = self.t_fine - 76800
        v_x1_u32r = (((((adc_H << 14) - (self.dig_H4 << 20) - (self.dig_H5 * v_x1_u32r)) + 16384) >> 15) *
                     (((((((v_x1_u32r * self.dig_H6) >> 10) * (((v_x1_u32r * self.dig_H3) >> 11) + 32768)) >> 10) +
                        2097152) * self.dig_H2 + 8192) >> 14))
        v_x1_u32r = v_x1_u32r - (((((v_x1_u32r >> 15) * (v_x1_u32r >> 15)) >> 7) * self.dig_H1) >> 4)
        v_x1_u32r = max(0, min(v_x1_u32r, 419430400))
        return v_x1_u32r >> 12

    def read(self):
        data = self.i2c.readfrom_mem(self.addr, 0xF7, 8)
        adc_P = (data[0] << 12) | (data[1] << 4) | (data[2] >> 4)
        adc_T = (data[3] << 12) | (data[4] << 4) | (data[5] >> 4)
        adc_H = (data[6] << 8) | data[7]
        
        temperature = self._compensate_T(adc_T) / 100.0
        pressure = self._compensate_P(adc_P) / 25600.0
        humidity = self._compensate_H(adc_H) / 1024.0
        
        return {
            "temperature_c": round(temperature, 2),
            "humidity_pct": round(humidity, 2),
            "pressure_hpa": round(pressure, 2),
        }

    @staticmethod
    def dew_point(temp_c, humidity_pct):
        """Calculate dew point in °C using Magnus formula."""
        import math
        a, b = 17.27, 237.7
        gamma = (a * temp_c) / (b + temp_c) + math.log(humidity_pct / 100.0)
        return round((b * gamma) / (a - gamma), 2)

    @staticmethod
    def heat_index(temp_c, humidity_pct):
        """Calculate heat index in °C (Rothfusz regression)."""
        t = temp_c * 1.8 + 32  # to Fahrenheit
        rh = humidity_pct
        if t < 80:
            return round(temp_c, 2)
        hi = 0.5 * (t + 61.0 + ((t - 68.0) * 1.2) + (rh * 0.094))
        avg = (hi + t) / 2.0
        if avg < 80:
            return round((hi - 32) / 1.8, 2)
        hi = (-42.379 + 2.04901523 * t + 10.14333127 * rh
              - 0.22475541 * t * rh - 0.00683783 * t * t
              - 0.05481717 * rh * rh + 0.00122874 * t * t * rh
              + 0.00085282 * t * rh * rh - 0.00000199 * t * t * rh * rh)
        return round((hi - 32) / 1.8, 2)
```

## sgp30.py — CO₂ + TVOC Sensor

```python
"""SGP30 CO₂ + TVOC driver for PicoClaw Greenhouse Pro Kit.
I2C address: 0x58. Requires 15s warmup for accurate CO₂ readings.
"""
import machine
import time
import struct

SGP30_I2C_ADDR = 0x58
SGP30_CMD_INIT_AIR_QUALITY = 0x2003
SGP30_CMD_MEASURE_AIR_QUALITY = 0x2008
SGP30_CMD_GET_BASELINE = 0x2015
SGP30_CMD_SET_BASELINE = 0x201E
SGP30_CMD_GET_FEATURE_SET = 0x202F
SGP30_CMD_MEASURE_RAW = 0x2050
SGP30_CMD_SOFT_RESET = 0x0006

class SGP30:
    def __init__(self, i2c, addr=SGP30_I2C_ADDR):
        self.i2c = i2c
        self.addr = addr
        self._init_sensor()

    def _write_cmd(self, cmd):
        self.i2c.writeto(self.addr, struct.pack('>H', cmd))
        time.sleep_ms(12)

    def _read_word(self):
        data = self.i2c.readfrom(self.addr, 3)
        word = (data[0] << 8) | data[1]
        crc = data[2]
        if self._crc8(data[:2]) != crc:
            raise RuntimeError("SGP30 CRC mismatch")
        return word

    @staticmethod
    def _crc8(data):
        crc = 0xFF
        for byte in data:
            crc ^= byte
            for _ in range(8):
                if crc & 0x80:
                    crc = (crc << 1) ^ 0x31
                else:
                    crc <<= 1
            crc &= 0xFF
        return crc

    def _init_sensor(self):
        # Soft reset
        self.i2c.writeto(self.addr, struct.pack('>H', SGP30_CMD_SOFT_RESET))
        time.sleep_ms(20)
        # Init air quality
        self._write_cmd(SGP30_CMD_INIT_AIR_QUALITY)
        time.sleep_ms(15)

    def read(self):
        """Read CO₂ [ppm] and TVOC [ppb]. Returns dict."""
        self._write_cmd(SGP30_CMD_MEASURE_AIR_QUALITY)
        time.sleep_ms(15)
        co2 = self._read_word()
        tvoc = self._read_word()
        return {
            "co2_ppm": co2,
            "tvoc_ppb": tvoc,
        }

    def get_baseline(self):
        """Get current baseline values for persistence."""
        self._write_cmd(SGP30_CMD_GET_BASELINE)
        time.sleep_ms(12)
        return {
            "co2_baseline": self._read_word(),
            "tvoc_baseline": self._read_word(),
        }

    def set_baseline(self, co2_baseline, tvoc_baseline):
        """Restore baseline from previous session."""
        buf = struct.pack('>HHH', SGP30_CMD_SET_BASELINE, tvoc_baseline, co2_baseline)
        buf += bytes([self._crc8(buf[2:4]), self._crc8(buf[4:6])])
        self.i2c.writeto(self.addr, buf)
```

## bh1750.py — Light Intensity Sensor

```python
"""BH1750 ambient light sensor driver for PicoClaw Greenhouse Pro Kit.
I2C address: 0x23 (ADDR pin LOW) or 0x5C (ADDR pin HIGH).
"""
import machine
import time

BH1750_I2C_ADDR = 0x23
BH1750_CMD_POWER_ON = 0x01
BH1750_CMD_RESET = 0x07
BH1750_CMD_CONT_HIGH_RES = 0x10  # 1 lux resolution, 120ms
BH1750_CMD_CONT_HIGH_RES2 = 0x11  # 0.5 lux resolution, 120ms

class BH1750:
    def __init__(self, i2c, addr=BH1750_I2C_ADDR):
        self.i2c = i2c
        self.addr = addr
        self.i2c.writeto(self.addr, bytes([BH1750_CMD_POWER_ON]))
        time.sleep_ms(10)
        self.i2c.writeto(self.addr, bytes([BH1750_CMD_CONT_HIGH_RES]))
        time.sleep_ms(180)

    def read(self):
        """Read illuminance in lux. Returns dict."""
        data = self.i2c.readfrom(self.addr, 2)
        lux = ((data[0] << 8) | data[1]) / 1.2
        return {"lux": round(lux, 1)}

    @staticmethod
    def dli(lux, hours=12):
        """Estimate Daily Light Integral (mol/m²/day) from lux.
        Conversion factor ~0.0185 for sunlight, ~0.0135 for LED.
        """
        return round(lux * 0.0185 * hours * 3600 / 1e6, 2)
```

## soil_moisture.py — Capacitive Soil Moisture Sensor

```python
"""Capacitive soil moisture sensor driver for PicoClaw Greenhouse Pro Kit.
Uses ADC on pin A0 (GPIO26). Corrosion-resistant v2.0.
Output: 0-100% volumetric water content (VWC) after calibration.
"""
import machine
import time

class SoilMoistureSensor:
    # Calibration constants — tune for your soil type
    DRY_AIR = 65535    # ADC reading in air (0% VWC)
    SATURATED = 18000  # ADC reading fully submerged (100% VWC)

    def __init__(self, pin=26, dry_air=None, saturated=None):
        self.adc = machine.ADC(pin)
        if dry_air is not None:
            self.DRY_AIR = dry_air  # instance override
        if saturated is not None:
            self.SATURATED = saturated

    def read_raw(self):
        """Read raw ADC value (12-bit: 0-4095)."""
        return self.adc.read_u16()

    def read(self):
        """Read soil moisture as percentage VWC. Returns dict."""
        raw = self.read_raw()
        # Map ADC to VWC: higher ADC = drier (capacitive sensor)
        if raw >= self.DRY_AIR:
            vwc = 0.0
        elif raw <= self.SATURATED:
            vwc = 100.0
        else:
            vwc = (self.DRY_AIR - raw) / (self.DRY_AIR - self.SATURATED) * 100.0
        return {
            "moisture_vwc_pct": round(vwc, 2),
            "raw_adc": raw,
        }

    def calibrate(self, known_dry=65535, known_wet=18000):
        """Override calibration constants."""
        self.DRY_AIR = known_dry
        self.SATURATED = known_wet
```

## ds18b20.py — Temperature Probe (1-Wire)

```python
"""DS18B20 1-Wire temperature probe driver for PicoClaw Greenhouse Pro Kit.
Connect to GPIO4 with 4.7kΩ pull-up to 3.3V.
"""
import machine
import onewire
import ds18x20
import time

class DS18B20Probe:
    def __init__(self, pin=4):
        self.ow = onewire.OneWire(machine.Pin(pin))
        self.ds = ds18x20.DS18X20(self.ow)
        self.roms = self.ds.scan()
        if not self.roms:
            raise RuntimeError("No DS18B20 found on 1-Wire bus")

    def read(self, index=0):
        """Read temperature from probe at index. Returns dict."""
        self.ds.convert_temp()
        time.sleep_ms(750)
        temp = self.ds.read_temp(self.roms[index])
        return {"temperature_c": round(temp, 2)}

    def read_all(self):
        """Read all probes on the bus. Returns list of dicts."""
        self.ds.convert_temp()
        time.sleep_ms(750)
        results = []
        for i, rom in enumerate(self.roms):
            temp = self.ds.read_temp(rom)
            results.append({
                "probe_index": i,
                "rom": ''.join(f'{b:02X}' for b in rom),
                "temperature_c": round(temp, 2),
            })
        return results
```

## rain_sensor.py — Rain Detection

```python
"""YL-83 rain sensor driver for PicoClaw Greenhouse Pro Kit.
Digital output on GPIO for rain/no-rain, ADC for intensity.
"""
import machine

class RainSensor:
    def __init__(self, digital_pin=14, analog_pin=27):
        self.digital = machine.Pin(digital_pin, machine.Pin.IN, machine.Pin.PULL_UP)
        self.analog = machine.ADC(analog_pin) if analog_pin is not None else None

    def is_raining(self):
        """True if rain detected (digital output LOW)."""
        return self.digital.value() == 0

    def read(self):
        """Read rain state + intensity. Returns dict."""
        raining = self.is_raining()
        intensity = None
        if self.analog and raining:
            raw = self.analog.read_u16()
            # ADC 0-65535 mapped to 0-100% intensity (lower ADC = more wet)
            intensity = round(max(0, (65535 - raw) / 65535 * 100), 2)
        return {
            "raining": raining,
            "intensity_pct": intensity,
        }
```

## relay_control.py — Relay / Actuator Control

```python
"""4-channel relay control for PicoClaw Greenhouse Pro Kit.
Connect relay IN1-IN4 to GPIO16-GPIO19 (active LOW).
Relay channels:
  CH1 (GPIO16): Ventilation fan
  CH2 (GPIO17): Irrigation solenoid
  CH3 (GPIO18): Misting pump
  CH4 (GPIO19): Heater / auxiliary
"""
import machine
import time

CHANNELS = {
    "vent_fan":    machine.Pin(16, machine.Pin.OUT, value=1),  # active LOW
    "irrigation":  machine.Pin(17, machine.Pin.OUT, value=1),
    "misting":     machine.Pin(18, machine.Pin.OUT, value=1),
    "heater":      machine.Pin(19, machine.Pin.OUT, value=1),
}

def relay_on(channel):
    """Activate relay channel (active LOW)."""
    if channel in CHANNELS:
        CHANNELS[channel].value(0)

def relay_off(channel):
    """Deactivate relay channel."""
    if channel in CHANNELS:
        CHANNELS[channel].value(1)

def relay_toggle(channel, state):
    """Set relay to specific state."""
    if channel in CHANNELS:
        CHANNELS[channel].value(0 if state else 1)

def relay_pulse(channel, duration_ms=500):
    """Pulse relay on for duration_ms then off."""
    relay_on(channel)
    time.sleep_ms(duration_ms)
    relay_off(channel)

def all_off():
    """Deactivate all relays (safe state)."""
    for pin in CHANNELS.values():
        pin.value(1)

def status():
    """Return dict of all relay states."""
    return {name: "ON" if pin.value() == 0 else "OFF" for name, pin in CHANNELS.items()}
```

## greenhouse_pro.py — Main Orchestrator

```python
"""Greenhouse Pro Kit — main orchestrator for PicoClaw.
Reads all sensors, evaluates alert thresholds, controls actuators.
"""
import machine
import time
import json
import uasyncio as asyncio
from bme280 import BME280
from sgp30 import SGP30
from bh1750 import BH1750
from soil_moisture import SoilMoistureSensor
from ds18b20 import DS18B20Probe
from rain_sensor import RainSensor
from relay_control import relay_on, relay_off, relay_toggle, all_off, status

# I2C bus for BME280, SGP30, BH1750
i2c = machine.I2C(0, scl=machine.Pin(22), sda=machine.Pin(21), freq=100000)

# Alert thresholds (override via alerts.yaml)
THRESHOLDS = {
    "air_temp_max_c": 30.0,
    "air_temp_min_c": 2.0,
    "humidity_min_pct": 40.0,
    "humidity_max_pct": 90.0,
    "co2_max_ppm": 1500,
    "co2_min_ppm": 350,
    "soil_moisture_min_pct": 30.0,
    "lux_min": 5000,
    "lux_max": 85000,
}

# Relay duty cycle state
state = {
    "vent_fan_running": False,
    "irrigation_running": False,
    "misting_running": False,
    "heater_running": False,
    "last_irrigation_ts": 0,
    "last_misting_ts": 0,
}

# Irrigation cooldown: 30 minutes
IRRIGATION_COOLDOWN_S = 30 * 60
# Misting cooldown: 15 minutes
MISTING_COOLDOWN_S = 15 * 60
# Vent fan minimum run: 60 seconds
VENT_MIN_RUN_S = 60

def load_thresholds():
    """Load thresholds from alerts.yaml if present."""
    try:
        with open("alerts.yaml") as f:
            import yaml
            data = yaml.safe_load(f)
            if "greenhouse_pro" in data:
                THRESHOLDS.update(data["greenhouse_pro"])
    except Exception:
        pass

def read_all_sensors():
    """Read all sensors and return combined dict."""
    result = {"ts": time.time()}
    try:
        bme = BME280(i2c)
        result.update(bme.read())
        result["dew_point_c"] = BME280.dew_point(
            result["temperature_c"], result["humidity_pct"]
        )
        result["heat_index_c"] = BME280.heat_index(
            result["temperature_c"], result["humidity_pct"]
        )
    except Exception as e:
        result["bme280_error"] = str(e)

    try:
        sgp = SGP30(i2c)
        result.update(sgp.read())
    except Exception as e:
        result["sgp30_error"] = str(e)

    try:
        bh = BH1750(i2c)
        result.update(bh.read())
        result["dli"] = BH1750.dli(result["lux"])
    except Exception as e:
        result["bh1750_error"] = str(e)

    try:
        soil = SoilMoistureSensor(pin=26)
        result["soil"] = [soil.read()]
    except Exception as e:
        result["soil_error"] = str(e)

    try:
        ds = DS18B20Probe(pin=4)
        result["soil_temp"] = ds.read_all()
    except Exception as e:
        result["ds18b20_error"] = str(e)

    try:
        rain = RainSensor(digital_pin=14, analog_pin=27)
        result.update(rain.read())
    except Exception as e:
        result["rain_error"] = str(e)

    result["relays"] = status()
    return result

def evaluate_alerts(sensor_data):
    """Evaluate thresholds and return active alerts."""
    alerts = []
    t = sensor_data.get("temperature_c")
    h = sensor_data.get("humidity_pct")
    co2 = sensor_data.get("co2_ppm")
    soil = sensor_data.get("soil", [{}])[0]
    
    if t is not None:
        if t > THRESHOLDS["air_temp_max_c"]:
            alerts.append(f"HIGH_TEMP: {t}°C > {THRESHOLDS['air_temp_max_c']}°C")
        if t < THRESHOLDS["air_temp_min_c"]:
            alerts.append(f"FROST_RISK: {t}°C < {THRESHOLDS['air_temp_min_c']}°C")
    if h is not None:
        if h < THRESHOLDS["humidity_min_pct"]:
            alerts.append(f"LOW_HUMIDITY: {h}% < {THRESHOLDS['humidity_min_pct']}%")
        if h > THRESHOLDS["humidity_max_pct"]:
            alerts.append(f"HIGH_HUMIDITY: {h}% > {THRESHOLDS['humidity_max_pct']}%")
    if co2 is not None:
        if co2 > THRESHOLDS["co2_max_ppm"]:
            alerts.append(f"HIGH_CO2: {co2}ppm > {THRESHOLDS['co2_max_ppm']}ppm")
        if co2 < THRESHOLDS["co2_min_ppm"]:
            alerts.append(f"LOW_CO2: {co2}ppm < {THRESHOLDS['co2_min_ppm']}ppm")
    if soil.get("moisture_vwc_pct") is not None:
        if soil["moisture_vwc_pct"] < THRESHOLDS["soil_moisture_min_pct"]:
            alerts.append(f"DRY_SOIL: {soil['moisture_vwc_pct']}% < {THRESHOLDS['soil_moisture_min_pct']}%")
    
    return alerts

def control_actuators(sensor_data, alerts):
    """Respond to alerts by controlling relays."""
    now = time.time()
    
    # Vent fan: high temp or high humidity
    if any("HIGH_TEMP" in a or "HIGH_HUMIDITY" in a for a in alerts):
        if not state["vent_fan_running"]:
            relay_on("vent_fan")
            state["vent_fan_running"] = True
    elif state["vent_fan_running"]:
        relay_off("vent_fan")
        state["vent_fan_running"] = False

    # Heater: frost risk
    if any("FROST_RISK" in a for a in alerts):
        if not state["heater_running"]:
            relay_on("heater")
            state["heater_running"] = True
    elif state["heater_running"]:
        relay_off("heater")
        state["heater_running"] = False

    # Irrigation: dry soil (with cooldown)
    if any("DRY_SOIL" in a for a in alerts):
        if not state["irrigation_running"] and (now - state["last_irrigation_ts"]) > IRRIGATION_COOLDOWN_S:
            relay_on("irrigation")
            state["irrigation_running"] = True
            state["last_irrigation_ts"] = now
    elif state["irrigation_running"]:
        relay_off("irrigation")
        state["irrigation_running"] = False

    # Misting: low humidity (with cooldown)
    if any("LOW_HUMIDITY" in a for a in alerts):
        if not state["misting_running"] and (now - state["last_misting_ts"]) > MISTING_COOLDOWN_S:
            relay_on("misting")
            state["misting_running"] = True
            state["last_misting_ts"] = now
    elif state["misting_running"]:
        relay_off("misting")
        state["misting_running"] = False

def main():
    load_thresholds()
    all_off()
    print("Greenhouse Pro Kit — PicoClaw monitoring active")
    while True:
        data = read_all_sensors()
        alerts = evaluate_alerts(data)
        control_actuators(data, alerts)
        print(json.dumps({"sensors": data, "alerts": alerts}))
        time.sleep(60)  # 60-second polling cycle

if __name__ == "__main__":
    main()
```
