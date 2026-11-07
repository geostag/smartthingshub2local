# smartthingshub2local
send data from smartthings hub to a local mqtt server

ATTENTION: completetly untested, use at own risk!

# setup

bash:
'''
smartthings edge:drivers:package mosquitto-publisher
smartthings edge:channels:create
smartthings edge:channels:assign <DRIVER_ID> --channel <CHANNEL_ID>

smartthings edge:channels:enroll <HUB_ID> --channel <CHANNEL_ID>
smartthings edge:drivers:install <DRIVER_ID> --hub <HUB_ID> --channel <CHANNEL_ID>
'''

in smartthings-rule.json:
- replace ZIGBEE_SENSOR_DEVICE_ID with your devices in question
- replace MQTT_PUBLISHER_DEVICE_ID by your newly created MQTT device

https://community.smartthings.com/t/custom-capability-with-list-of-supported-commands/232932
https://developer.smartthings.com/docs/automations/rules


