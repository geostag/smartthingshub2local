local capabilities = require "st.capabilities"
local Driver = require "st.driver"
local cosock = require "cosock"
local socket = cosock.socket
local log = require "log"

local CAP_ID = "geostag.mqttClimateBridge"
local climate_cap = capabilities[CAP_ID]

local function encode_mqtt_str(str)
  local len = #str
  return string.char(math.floor(len / 256), len % 256) .. str
end

local function encode_remaining_length(len)
  local bytes = ""
  repeat
    local encoded_byte = len % 128
    len = math.floor(len / 128)
    if len > 0 then
      encoded_byte = encoded_byte + 128
    end
    bytes = bytes .. string.char(encoded_byte)
  until len == 0
  return bytes
end

local function publish_to_mosquitto(device, topic, payload)
  local ip = device.preferences.brokerIp
  local port = tonumber(device.preferences.brokerPort) or 1883
  local user = device.preferences.mqttUser or ""
  local pass = device.preferences.mqttPass or ""

  if not ip or ip == "" then
    log.error("mqtt broker ip address missing")
    return
  end

  local tcp = socket.tcp()
  tcp:settimeout(3)

  local ok, err = tcp:connect(ip, port)
  if not ok then
    log.error(string.format("connection to mqtt broker (%s:%d) failed: %s", ip, port, tostring(err)))
    tcp:close()
    return
  end

  local client_id = "st_hub_" .. tostring(device.id):sub(1, 8)
  local connect_flags = 0x02
  local connect_payload = encode_mqtt_str(client_id)

  if user ~= "" then
    connect_flags = connect_flags + 0x80
    connect_payload = connect_payload .. encode_mqtt_str(user)
    if pass ~= "" then
      connect_flags = connect_flags + 0x40
      connect_payload = connect_payload .. encode_mqtt_str(pass)
    end
  end

  local var_header = encode_mqtt_str("MQTT") .. string.char(0x04, connect_flags, 0x00, 0x3C)
  local connect_packet = string.char(0x10) .. encode_remaining_length(#var_header + #connect_payload) .. var_header .. connect_payload

  tcp:send(connect_packet)
  local connack = tcp:receive(4)
  if not connack or string.byte(connack, 4) ~= 0 then
    log.error("mqtt broker access denied. Please check user and password")
    tcp:close()
    return
  end

  local pub_body = encode_mqtt_str(topic) .. tostring(payload)
  local publish_packet = string.char(0x30) .. encode_remaining_length(#pub_body) .. pub_body
  tcp:send(publish_packet)

  tcp:send(string.char(0xE0, 0x00))
  tcp:close()
  log.info(string.format("sent to '%s': %s", topic, tostring(payload)))
end

local function handle_publish_climate(driver, device, command)
  local temp = command.args.temperature
  local hum = command.args.humidity

  local json_payload = string.format('{"temperature": %.2f, "humidity": %.2f}', temp, hum)
 
  device:emit_event(climate_cap.lastPayload(json_payload))

  local topic = device.preferences.mqttTopic or "smartthings/climate/SENSOR"
  publish_to_mosquitto(device, topic, json_payload)
end

local function discovery_handler(driver, opts, should_continue)
  log.info("Creating MQTT climate publisher device")
  local metadata = {
    type = "LAN",
    device_network_id = "mosquitto-climate-pub-" .. tostring(os.time()),
    label = "Mosquitto climate publisher",
    profile = "mqtt-publisher",
    manufacturer = "Custom",
    model = "MQTT-Climate-Bridge",
    vendor_provided_label = "MQTT climate publisher"
  }
  driver:try_create_device(metadata)
end

local mqtt_driver = Driver("mqtt-publisher", {
  discovery = discovery_handler,
  capability_handlers = {
    [CAP_ID] = {
      ["publishClimate"] = handle_publish_climate
    }
  }
})

mqtt_driver:run()

