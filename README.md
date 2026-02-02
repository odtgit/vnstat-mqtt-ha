# vnstat-mqtt-ha

A lightweight bridge to publish vnstat network statistics to MQTT with Home Assistant auto-discovery support.

## Overview

This script monitors network traffic using vnstat and publishes the data to MQTT, automatically configuring sensors in Home Assistant via MQTT discovery. The sensors provide numeric-only state values with proper unit configuration, enabling full graphing and statistical capabilities in Home Assistant.

## Features

- **Home Assistant Auto-Discovery**: Sensors automatically appear in Home Assistant
- **Proper Unit Separation**: State values are numeric only; units defined via `unit_of_measurement`
- **Multiple Metrics**:
  - Daily download/upload totals (GB)
  - Real-time bandwidth rates (Mbit/s)
  - Packet rates (packets per second)
  - Daily average bandwidth (Mbit/s)
- **Device Classes**: Proper `device_class` and `state_class` for optimal Home Assistant integration
- **Lightweight**: Runs every 10 minutes via cron

## Monitored Sensors

Sensor IDs follow the format: `{HOST}_{INTERFACE}_{metric}`

Example with default configuration (HOST=fw1, INTERFACE=wan):

| Sensor ID | Description | Unit | Type |
|-----------|-------------|------|------|
| `fw1_wan_rx` | Daily download total | GB | data_size |
| `fw1_wan_tx` | Daily upload total | GB | data_size |
| `fw1_wan_bandwidth_rx` | Current download rate | Mbit/s | data_rate |
| `fw1_wan_bandwidth_tx` | Current upload rate | Mbit/s | data_rate |
| `fw1_wan_rx_pps` | RX packet rate | pps | measurement |
| `fw1_wan_tx_pps` | TX packet rate | pps | measurement |
| `fw1_wan_bandwidth_rx_avg` | Daily average download | Mbit/s | data_rate |
| `fw1_wan_bandwidth_tx_avg` | Daily average upload | Mbit/s | data_rate |

Entity IDs in Home Assistant will be: `sensor.{HOST}_{INTERFACE}_{metric}` (e.g., `sensor.fw1_wan_rx`)

## Dependencies

### Required Packages

- **vnstat** (≥2.0): Network traffic monitor
- **jq**: JSON processor for parsing vnstat output
- **mosquitto-clients**: MQTT client tools (`mosquitto_pub`)
- **bash**: Shell interpreter

### Installation (Alpine Linux)

```bash
apk add vnstat jq mosquitto-clients bash
```

### Installation (Debian/Ubuntu)

```bash
apt-get install vnstat jq mosquitto-clients bash
```

## Configuration

### 1. Configure vnstat

Ensure vnstat is monitoring your network interface. Edit `/etc/vnstat.conf` to specify the interface:

```bash
# Example vnstat.conf
Interface "wan"              # Your network interface name
DatabaseDir "/var/lib/vnstat"
MonthRotate 1
UnitMode 0                   # 0 = IEC (KiB/MiB/GiB), 1 = old binary (KB/MB/GB)
RateUnitMode 1              # 0 = IEC (Kibit/s), 1 = SI (kbit/s)
RateUnit 1                  # 0 = bytes, 1 = bits
DefaultDecimals 2
```

See `vnstat.conf` in this repository for a complete example.

Start and enable vnstat:

```bash
# Alpine Linux
rc-service vnstatd start
rc-update add vnstatd

# Debian/Ubuntu (systemd)
systemctl start vnstat
systemctl enable vnstat
```

Verify vnstat is collecting data:

```bash
vnstat
```

### 2. Edit Script Variables

Edit `fw1-mqtt-pub.sh` and configure the variables at the top:

```bash
# MQTT Configuration
MQTT_BROKER="172.17.17.1"                # Your MQTT broker IP
HA_PREFIX="homeassistant/sensor"         # MQTT discovery prefix

# Device & Sensor Naming Configuration
HOST="fw1"                               # Short hostname for entity IDs
INTERFACE="wan"                          # Network interface (must match vnstat)
DEVICE_NAME="FW1"                        # Friendly device name in Home Assistant
DEVICE_MODEL="Alpine Linux"              # Optional: Device model
DEVICE_MANUFACTURER="Custom"             # Optional: Device manufacturer
```

**Naming Examples:**

- With `HOST="router"` and `INTERFACE="eth0"`:
  - Entity IDs: `sensor.router_eth0_rx`, `sensor.router_eth0_tx`, etc.
  - Friendly names: "Router ETH0 Download (Today)", "Router ETH0 Upload (Today)", etc.

- With `HOST="gateway"` and `INTERFACE="wan"`:
  - Entity IDs: `sensor.gateway_wan_rx`, `sensor.gateway_wan_tx`, etc.
  - Friendly names: "Gateway WAN Download (Today)", "Gateway WAN Upload (Today)", etc.

### 3. Install Script

```bash
# Copy script to system location
cp fw1-mqtt-pub.sh /usr/local/bin/
chmod +x /usr/local/bin/fw1-mqtt-pub.sh

# Test the script
/usr/local/bin/fw1-mqtt-pub.sh
```

### 4. Configure Cron

Add to crontab to run every 10 minutes:

```bash
crontab -e
```

Add line:
```
*/10 * * * * /usr/local/bin/fw1-mqtt-pub.sh >/dev/null 2>&1
```

## Home Assistant Integration

Sensors will automatically appear in Home Assistant under:
- **Device**: Your configured `DEVICE_NAME` (e.g., "FW1")
- **Integration**: MQTT

No manual configuration needed in Home Assistant - the script handles auto-discovery.

### Example Sensor Card

```yaml
type: entities
title: Network Stats
entities:
  - entity: sensor.fw1_wan_rx
  - entity: sensor.fw1_wan_tx
  - entity: sensor.fw1_wan_bandwidth_rx
  - entity: sensor.fw1_wan_bandwidth_tx
```

### Example Graph Card

```yaml
type: history-graph
title: WAN Bandwidth
entities:
  - entity: sensor.fw1_wan_bandwidth_rx
    name: Download
  - entity: sensor.fw1_wan_bandwidth_tx
    name: Upload
hours_to_show: 24
refresh_interval: 0
```

### Example Statistics Card

```yaml
type: statistic
entity: sensor.fw1_wan_bandwidth_rx
period:
  calendar:
    period: day
stat_type: mean
name: Average Download Today
```

## How It Works

1. **Discovery Phase**: On first run, the script publishes MQTT discovery messages with sensor configuration including `unit_of_measurement`, `device_class`, and `state_class`
2. **Data Collection**: Uses `vnstat --json` to fetch network statistics
3. **Data Publishing**: Publishes numeric-only values to MQTT state topics
4. **Home Assistant**: Automatically creates sensors and applies units from discovery config

## Files

- `fw1-mqtt-pub.sh` - Main script with configurable naming and unit separation
- `fw1-mqtt-pub.sh.orig` - Original script (for reference)
- `vnstat.conf` - Example vnstat configuration
- `README.md` - This file

## Troubleshooting

### Sensors not appearing in Home Assistant

1. Check MQTT broker is accessible:
   ```bash
   mosquitto_pub -h 172.17.17.1 -t test -m "hello"
   ```

2. Check Home Assistant MQTT integration is configured

3. Force re-discovery:
   ```bash
   rm /tmp/.mqtt-discovered
   /usr/local/bin/fw1-mqtt-pub.sh
   ```

### Values not updating

1. Check cron is running:
   ```bash
   crontab -l
   ps aux | grep cron
   ```

2. Check vnstat is collecting data:
   ```bash
   vnstat
   ```

3. Run script manually to check for errors:
   ```bash
   /usr/local/bin/fw1-mqtt-pub.sh
   ```

## License

MIT

## Author

Created for home network monitoring with Home Assistant integration.
