#!/bin/bash
# vnstat to MQTT publisher with Home Assistant auto-discovery
# Improved version with proper unit separation and configurable naming

# MQTT Configuration
MQTT_BROKER="172.17.17.1"
HA_PREFIX="homeassistant/sensor"

# Device & Sensor Naming Configuration
# Entity IDs will be formatted as: sensor.{host}_{interface}_{metric}
# Example: sensor.fw1_wan_rx
# Note: HA automatically prepends device name to sensor names
HOST="fw1"                    # Short hostname (lowercase)
INTERFACE="wan"               # Network interface being monitored (lowercase)
DEVICE_NAME="fw1"             # Device name in Home Assistant (lowercase)
DEVICE_MODEL="Alpine Linux"   # Optional: Device model
DEVICE_MANUFACTURER="Custom"  # Optional: Device manufacturer

# Construct sensor ID prefix from configuration
SENSOR_PREFIX="${HOST}_${INTERFACE}"

# Publish discovery configs once
if [ ! -f /tmp/.mqtt-discovered ]; then
    # Daily totals (data)
    mosquitto_pub -h "$MQTT_BROKER" -t "$HA_PREFIX/${SENSOR_PREFIX}_rx/config" -r -m "{
        \"name\":\"${INTERFACE} download today\",
        \"unique_id\":\"${SENSOR_PREFIX}_rx\",
        \"state_topic\":\"${HA_PREFIX}/${SENSOR_PREFIX}_rx/state\",
        \"unit_of_measurement\":\"GB\",
        \"device_class\":\"data_size\",
        \"state_class\":\"total_increasing\",
        \"icon\":\"mdi:download-network\",
        \"device\":{\"identifiers\":[\"${HOST}\"],\"name\":\"${DEVICE_NAME}\",\"model\":\"${DEVICE_MODEL}\",\"manufacturer\":\"${DEVICE_MANUFACTURER}\"}
    }"

    mosquitto_pub -h "$MQTT_BROKER" -t "$HA_PREFIX/${SENSOR_PREFIX}_tx/config" -r -m "{
        \"name\":\"${INTERFACE} upload today\",
        \"unique_id\":\"${SENSOR_PREFIX}_tx\",
        \"state_topic\":\"${HA_PREFIX}/${SENSOR_PREFIX}_tx/state\",
        \"unit_of_measurement\":\"GB\",
        \"device_class\":\"data_size\",
        \"state_class\":\"total_increasing\",
        \"icon\":\"mdi:upload-network\",
        \"device\":{\"identifiers\":[\"${HOST}\"],\"name\":\"${DEVICE_NAME}\",\"model\":\"${DEVICE_MODEL}\",\"manufacturer\":\"${DEVICE_MANUFACTURER}\"}
    }"

    # Real-time bandwidth (data rate)
    mosquitto_pub -h "$MQTT_BROKER" -t "$HA_PREFIX/${SENSOR_PREFIX}_bandwidth_rx/config" -r -m "{
        \"name\":\"${INTERFACE} rx rate\",
        \"unique_id\":\"${SENSOR_PREFIX}_bandwidth_rx\",
        \"state_topic\":\"${HA_PREFIX}/${SENSOR_PREFIX}_bandwidth_rx/state\",
        \"unit_of_measurement\":\"Mbit/s\",
        \"device_class\":\"data_rate\",
        \"state_class\":\"measurement\",
        \"icon\":\"mdi:download\",
        \"device\":{\"identifiers\":[\"${HOST}\"],\"name\":\"${DEVICE_NAME}\",\"model\":\"${DEVICE_MODEL}\",\"manufacturer\":\"${DEVICE_MANUFACTURER}\"}
    }"

    mosquitto_pub -h "$MQTT_BROKER" -t "$HA_PREFIX/${SENSOR_PREFIX}_bandwidth_tx/config" -r -m "{
        \"name\":\"${INTERFACE} tx rate\",
        \"unique_id\":\"${SENSOR_PREFIX}_bandwidth_tx\",
        \"state_topic\":\"${HA_PREFIX}/${SENSOR_PREFIX}_bandwidth_tx/state\",
        \"unit_of_measurement\":\"Mbit/s\",
        \"device_class\":\"data_rate\",
        \"state_class\":\"measurement\",
        \"icon\":\"mdi:upload\",
        \"device\":{\"identifiers\":[\"${HOST}\"],\"name\":\"${DEVICE_NAME}\",\"model\":\"${DEVICE_MODEL}\",\"manufacturer\":\"${DEVICE_MANUFACTURER}\"}
    }"

    # Packet rate (frequency)
    mosquitto_pub -h "$MQTT_BROKER" -t "$HA_PREFIX/${SENSOR_PREFIX}_rx_pps/config" -r -m "{
        \"name\":\"${INTERFACE} rx packets\",
        \"unique_id\":\"${SENSOR_PREFIX}_rx_pps\",
        \"state_topic\":\"${HA_PREFIX}/${SENSOR_PREFIX}_rx_pps/state\",
        \"unit_of_measurement\":\"pps\",
        \"state_class\":\"measurement\",
        \"icon\":\"mdi:package-down\",
        \"device\":{\"identifiers\":[\"${HOST}\"],\"name\":\"${DEVICE_NAME}\",\"model\":\"${DEVICE_MODEL}\",\"manufacturer\":\"${DEVICE_MANUFACTURER}\"}
    }"

    mosquitto_pub -h "$MQTT_BROKER" -t "$HA_PREFIX/${SENSOR_PREFIX}_tx_pps/config" -r -m "{
        \"name\":\"${INTERFACE} tx packets\",
        \"unique_id\":\"${SENSOR_PREFIX}_tx_pps\",
        \"state_topic\":\"${HA_PREFIX}/${SENSOR_PREFIX}_tx_pps/state\",
        \"unit_of_measurement\":\"pps\",
        \"state_class\":\"measurement\",
        \"icon\":\"mdi:package-up\",
        \"device\":{\"identifiers\":[\"${HOST}\"],\"name\":\"${DEVICE_NAME}\",\"model\":\"${DEVICE_MODEL}\",\"manufacturer\":\"${DEVICE_MANUFACTURER}\"}
    }"

    # Daily average bandwidth (data rate)
    mosquitto_pub -h "$MQTT_BROKER" -t "$HA_PREFIX/${SENSOR_PREFIX}_bandwidth_rx_avg/config" -r -m "{
        \"name\":\"${INTERFACE} rx avg today\",
        \"unique_id\":\"${SENSOR_PREFIX}_bandwidth_rx_avg\",
        \"state_topic\":\"${HA_PREFIX}/${SENSOR_PREFIX}_bandwidth_rx_avg/state\",
        \"unit_of_measurement\":\"Mbit/s\",
        \"device_class\":\"data_rate\",
        \"state_class\":\"measurement\",
        \"icon\":\"mdi:chart-line\",
        \"device\":{\"identifiers\":[\"${HOST}\"],\"name\":\"${DEVICE_NAME}\",\"model\":\"${DEVICE_MODEL}\",\"manufacturer\":\"${DEVICE_MANUFACTURER}\"}
    }"

    mosquitto_pub -h "$MQTT_BROKER" -t "$HA_PREFIX/${SENSOR_PREFIX}_bandwidth_tx_avg/config" -r -m "{
        \"name\":\"${INTERFACE} tx avg today\",
        \"unique_id\":\"${SENSOR_PREFIX}_bandwidth_tx_avg\",
        \"state_topic\":\"${HA_PREFIX}/${SENSOR_PREFIX}_bandwidth_tx_avg/state\",
        \"unit_of_measurement\":\"Mbit/s\",
        \"device_class\":\"data_rate\",
        \"state_class\":\"measurement\",
        \"icon\":\"mdi:chart-line\",
        \"device\":{\"identifiers\":[\"${HOST}\"],\"name\":\"${DEVICE_NAME}\",\"model\":\"${DEVICE_MODEL}\",\"manufacturer\":\"${DEVICE_MANUFACTURER}\"}
    }"

    touch /tmp/.mqtt-discovered
fi

# Get daily totals with 2 decimal places
DAILY_JSON=$(vnstat --json d 1)
DAILY_RX=$(echo "$DAILY_JSON" | jq -r '.interfaces[0].traffic.day[0].rx / 1073741824 | . * 100 | floor / 100')
DAILY_TX=$(echo "$DAILY_JSON" | jq -r '.interfaces[0].traffic.day[0].tx / 1073741824 | . * 100 | floor / 100')

# Publish numeric values only (units are in discovery config)
mosquitto_pub -h "$MQTT_BROKER" -t "$HA_PREFIX/${SENSOR_PREFIX}_rx/state" -m "$DAILY_RX"
mosquitto_pub -h "$MQTT_BROKER" -t "$HA_PREFIX/${SENSOR_PREFIX}_tx/state" -m "$DAILY_TX"

# Real-time traffic sampling (5 seconds)
JSON=$(vnstat -tr 5 --json)
RX_MBPS=$(echo "$JSON" | jq -r '.rx.bytespersecond * 8 / 1000000 | . * 100 | floor / 100')
TX_MBPS=$(echo "$JSON" | jq -r '.tx.bytespersecond * 8 / 1000000 | . * 100 | floor / 100')
RX_PPS=$(echo "$JSON" | jq -r '.rx.packets / 5 | floor')
TX_PPS=$(echo "$JSON" | jq -r '.tx.packets / 5 | floor')

# Publish numeric values only
mosquitto_pub -h "$MQTT_BROKER" -t "$HA_PREFIX/${SENSOR_PREFIX}_bandwidth_rx/state" -m "$RX_MBPS"
mosquitto_pub -h "$MQTT_BROKER" -t "$HA_PREFIX/${SENSOR_PREFIX}_bandwidth_tx/state" -m "$TX_MBPS"
mosquitto_pub -h "$MQTT_BROKER" -t "$HA_PREFIX/${SENSOR_PREFIX}_rx_pps/state" -m "$RX_PPS"
mosquitto_pub -h "$MQTT_BROKER" -t "$HA_PREFIX/${SENSOR_PREFIX}_tx_pps/state" -m "$TX_PPS"

# Daily average bandwidth
DAILY_RX_BYTES=$(echo "$DAILY_JSON" | jq -r '.interfaces[0].traffic.day[0].rx')
DAILY_TX_BYTES=$(echo "$DAILY_JSON" | jq -r '.interfaces[0].traffic.day[0].tx')

# Calculate seconds elapsed today
NOW=$(date +%s)
MIDNIGHT=$(date -d "today 00:00:00" +%s)
SECONDS_TODAY=$((NOW - MIDNIGHT))

# Average bandwidth = (total_bytes * 8) / seconds_elapsed / 1000000 for Mbit/s
if [ $SECONDS_TODAY -gt 0 ]; then
    RX_AVG=$(echo "$DAILY_RX_BYTES $SECONDS_TODAY" | awk '{printf "%.2f", ($1 * 8) / $2 / 1000000}')
    TX_AVG=$(echo "$DAILY_TX_BYTES $SECONDS_TODAY" | awk '{printf "%.2f", ($1 * 8) / $2 / 1000000}')
else
    RX_AVG="0.00"
    TX_AVG="0.00"
fi

# Publish numeric values only
mosquitto_pub -h "$MQTT_BROKER" -t "$HA_PREFIX/${SENSOR_PREFIX}_bandwidth_rx_avg/state" -m "$RX_AVG"
mosquitto_pub -h "$MQTT_BROKER" -t "$HA_PREFIX/${SENSOR_PREFIX}_bandwidth_tx_avg/state" -m "$TX_AVG"
