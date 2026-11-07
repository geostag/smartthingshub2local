# smartthingshub2local
Send climate data from SmartThings devices to a local MQTT broker.

ATTENTION: Completely untested; use at your own risk!

## Setup

The commands below use the [SmartThings CLI](https://developer.smartthings.com/docs/cli). Run them from the repository root:

```
smartthings edge:drivers:package mqtt-publisher
smartthings edge:channels:create
smartthings edge:channels:assign <DRIVER_ID> --channel <CHANNEL_ID>
smartthings edge:channels:enroll <HUB_ID> --channel <CHANNEL_ID>
smartthings edge:drivers:install <DRIVER_ID> --hub <HUB_ID> --channel <CHANNEL_ID>
```

The angle-bracket values are placeholders, not text to type literally. Use the driver ID reported after packaging (or retrieve it with `smartthings edge:drivers`), and the channel ID reported after creation (or retrieve it with `smartthings edge:channels`). Replace `<HUB_ID>` with your SmartThings hub's ID as well. Keep these IDs and use the same values in each command.

Channel enrollment subscribes the hub to the driver channel; it does not add a device or connect to the MQTT broker. After installing the driver, use the SmartThings app to scan for nearby devices. The driver's discovery handler creates the MQTT climate publisher device on the hub.

Open the new device's settings and set the broker IP address, port, and (if needed) MQTT username and password. Set the topic if you do not want to use the default `smartthings/climate/SENSOR`.

## Rule configuration

In [smartthings-rule.json](smartthings-rule.json):

- Replace `ZIGBEE_SENSOR_DEVICE_ID` with the ID or IDs of the climate sensors to monitor.
- Replace `MQTT_PUBLISHER_DEVICE_ID` with the device ID of the MQTT climate publisher created by discovery.
- Install the rule. When a monitored sensor's temperature or humidity changes, the rule calls `publishClimate` on the publisher device, which sends both values to the broker.

https://community.smartthings.com/t/custom-capability-with-list-of-supported-commands/232932
https://developer.smartthings.com/docs/automations/rules


