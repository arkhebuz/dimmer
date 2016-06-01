#!/usr/bin/env python3
import paho.mqtt.client as mqtt
import argparse

BROKER_ADDRESS =
BROKER_PORT =
BROKER_USERNAME =
BROKER_PASSWORD =


# The callback for when the client receives a CONNACK response from the server.
def on_connect(client, userdata, flags, rc):
    print("Connected with result code "+str(rc))

    # Subscribing in on_connect() means that if we lose the connection and
    # reconnect then subscriptions will be renewed.
    client.subscribe("#")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Dimmer")
    subparsers = parser.add_subparsers()

    level = subparsers.add_parser('level', help="Change light level")
    level.set_defaults(channel='/light_level')
    level.add_argument('num', help="PWM fill factor (0-1023)",)

    mode = subparsers.add_parser('mode', help="Change working mode")
    mode.set_defaults(channel='/mode')
    mode.add_argument('num', help="Working mode (0,1,2,3)",)

    trgt = subparsers.add_parser('target', help="Change ADC target level")
    trgt.set_defaults(channel='/target')
    trgt.add_argument('num', help="desired ADC output (0-1023)",)

    Config = parser.parse_args()

    client = mqtt.Client()
    client.on_connect = on_connect
    client.username_pw_set(BROKER_USERNAME, password=BROKER_PASSWORD)
    client.connect(BROKER_ADDRESS, BROKER_PORT, 60)

    print(Config.channel, Config.num)
    client.publish(Config.channel, Config.num)
