#!/usr/bin/env python3
import evdev
from evdev import UInput, ecodes, AbsInfo
import select
import os
import time

# Device paths
dev1_path = '/dev/input/event0'
dev2_path = '/dev/input/event1'

# Capabilities (Player 1 includes BTN_BASE4)
capabilities_player1 = {
    ecodes.EV_KEY: [
        ecodes.BTN_TRIGGER, ecodes.BTN_THUMB, ecodes.BTN_THUMB2, ecodes.BTN_TOP,
        ecodes.BTN_TOP2, ecodes.BTN_PINKIE, ecodes.BTN_BASE, ecodes.BTN_BASE2,
        ecodes.BTN_BASE3, ecodes.BTN_BASE4
    ],
    ecodes.EV_ABS: [
        (ecodes.ABS_X, AbsInfo(value=127, min=0, max=255, fuzz=0, flat=15, resolution=0)),
        (ecodes.ABS_Y, AbsInfo(value=127, min=0, max=255, fuzz=0, flat=15, resolution=0)),
    ],
}

capabilities_player2 = {
    ecodes.EV_KEY: [
        ecodes.BTN_TRIGGER, ecodes.BTN_THUMB, ecodes.BTN_THUMB2, ecodes.BTN_TOP,
        ecodes.BTN_TOP2, ecodes.BTN_PINKIE, ecodes.BTN_BASE, ecodes.BTN_BASE2,
        ecodes.BTN_BASE3, ecodes.BTN_BASE4
    ],
    ecodes.EV_ABS: [
        (ecodes.ABS_X, AbsInfo(value=127, min=0, max=255, fuzz=0, flat=15, resolution=0)),
        (ecodes.ABS_Y, AbsInfo(value=127, min=0, max=255, fuzz=0, flat=15, resolution=0)),
    ],
}

def open_devices():
    while True:
        try:
            dev1 = evdev.InputDevice(dev1_path)
            dev2 = evdev.InputDevice(dev2_path)
            dev1.grab()
            dev2.grab()
            print("Devices successfully connected.")
            return dev1, dev2
        except Exception as e:
            print(f"Error opening devices: {e}. Retrying in 2 seconds...")
            time.sleep(2)

def reset_virtual_controllers():
    global ui_player1, ui_player2
    print("Resetting virtual controllers...")
    ui_player1.close()
    ui_player2.close()
    ui_player1 = UInput(capabilities_player1, name="Virtual Controller P1", version=0x3)
    ui_player2 = UInput(capabilities_player2, name="Virtual Controller P2", version=0x3)
    print("Virtual controllers reset.")

# Create virtual controllers
ui_player1 = UInput(capabilities_player1, name="Virtual Controller P1", version=0x3)
ui_player2 = UInput(capabilities_player2, name="Virtual Controller P2", version=0x3)

# Open devices
dev1, dev2 = open_devices()

try:
    while True:
        if not (dev1 and dev2):
            print("Devices disconnected. Reconnecting...")
            dev1, dev2 = open_devices()
            reset_virtual_controllers()

        fds = [dev1.fd, dev2.fd]
        r, w, x = select.select(fds, [], [])

        for fd in r:
            if fd == dev1.fd:
                d = dev1
                ui = ui_player1
                print("Player 1 event detected.")
            else:
                d = dev2
                ui = ui_player2
                print("Player 2 event detected.")

            for event in d.read():
                print(f"Device: {d.path}, Type: {event.type}, Code: {event.code}, Value: {event.value}")

                if event.type == ecodes.EV_KEY and event.code == ecodes.BTN_BASE4:
                    if d == dev2:  # Player 2's Start
                        print("Player 2 Start (BTN_BASE4) pressed.")
                        ui_player2.write_event(event)  # Route to Player 2
                        ui_player2.syn()
                    else:          #Player 1's BTN_BASE4
                        print("Player 1 BTN_BASE4 pressed.")
                        ui_player1.write_event(event)
                        ui_player1.syn()
                elif event.type in [ecodes.EV_KEY, ecodes.EV_ABS]:
                    if d == dev2:  # Route other Player 2 events to Player 1
                        print(f"Routing Player 2 event {event.code} to Player 1.")
                        ui_player1.write_event(event)
                        ui_player1.syn()
                    else:
                        ui_player1.write_event(event)
                        ui_player1.syn()

except (OSError, IOError) as e:
    print(f"Device error: {e}. Reconnecting devices and resetting controllers...")
    dev1, dev2 = open_devices()
    reset_virtual_controllers()

except KeyboardInterrupt:
    print("Exiting...")

finally:
    ui_player1.close()
    ui_player2.close()
    if dev1:
        dev1.ungrab()
    if dev2:
        dev2.ungrab()
