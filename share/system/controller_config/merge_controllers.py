#!/usr/bin/env python3

import evdev
from evdev import UInput, ecodes, AbsInfo
import select
import os
import time
from datetime import datetime

# Configuration
MERGE_STATE_PATH = "/tmp/merge_controller_enabled"
PRIMARY_CONTROLLER_PATH = '/dev/input/event0'
SECONDARY_CONTROLLER_PATH = '/dev/input/event1'

# Device Capabilities
CONTROLLER_CAPABILITIES = {
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

# Globals
virtual_primary_controller = None
virtual_secondary_controller = None

# Timestamp for Logs
def timestamp():
    return datetime.now().strftime("%Y-%m-%d %H:%M:%S")

# Initialize Controllers
def initialize_controllers():
    while True:
        try:
            primary_device = evdev.InputDevice(PRIMARY_CONTROLLER_PATH)
            secondary_device = evdev.InputDevice(SECONDARY_CONTROLLER_PATH)
            primary_device.grab()
            secondary_device.grab()
            print(f"{timestamp()} - Controllers successfully initialized.")
            return primary_device, secondary_device
        except Exception as e:
            print(f"{timestamp()} - Error initializing controllers: {e}. Retrying in 2 seconds...")
            time.sleep(2)

# Reset Virtual Controllers
def reset_virtual_devices():
    global virtual_primary_controller, virtual_secondary_controller
    print(f"{timestamp()} - Resetting virtual devices...")

    if virtual_primary_controller:
        virtual_primary_controller.close()
    if virtual_secondary_controller:
        virtual_secondary_controller.close()

    virtual_primary_controller = UInput(CONTROLLER_CAPABILITIES, name="Virtual Controller P1", version=0x3)
    virtual_secondary_controller = UInput(CONTROLLER_CAPABILITIES, name="Virtual Controller P2", version=0x3)
    print(f"{timestamp()} - Virtual devices reset.")

# Check Merge State
def is_merge_enabled():
    try:
        with open(MERGE_STATE_PATH, "r") as f:
            return f.read().strip() == "True"
    except FileNotFoundError:
        return False

# Handle Input Events
def handle_event(event, current_device, merge_enabled):
    is_secondary = (current_device.path == SECONDARY_CONTROLLER_PATH)
    print(f"{timestamp()} - Device: {current_device.path}, Type: {event.type}, Code: {event.code}, Value: {event.value}")
    print(f"{timestamp()} - merge_enabled: {merge_enabled}")

    if merge_enabled:
        if event.type == ecodes.EV_KEY and event.code == ecodes.BTN_BASE4:
            target_device = virtual_secondary_controller if is_secondary else virtual_primary_controller
            print(f"{timestamp()} - Routing start event {event.code} to {'Secondary' if is_secondary else 'Primary'} controller.")
        else:
            target_device = virtual_primary_controller
            print(f"{timestamp()} - Routing event {event.code} to Primary controller.")
    else:
        target_device = virtual_secondary_controller if is_secondary else virtual_primary_controller
        print(f"{timestamp()} - Routing event {event.code} to respective controller.")

    target_device.write_event(event)
    target_device.syn()

# Main Logic
def main():
    global virtual_primary_controller, virtual_secondary_controller

    # Initialize Virtual Controllers
    reset_virtual_devices()

    primary_device, secondary_device = initialize_controllers()
    previous_merge_state = is_merge_enabled()

    try:
        while True:
            merge_enabled = is_merge_enabled()

            if merge_enabled != previous_merge_state:
                print(f"{timestamp()} - Merge state changed. Reinitializing...")
                primary_device.ungrab()
                secondary_device.ungrab()
                primary_device, secondary_device = initialize_controllers()
                reset_virtual_devices()
                previous_merge_state = merge_enabled

            if not (primary_device and secondary_device):
                print(f"{timestamp()} - Controllers disconnected. Reconnecting...")
                primary_device, secondary_device = initialize_controllers()
                reset_virtual_devices()

            # Wait for input with a 1-second timeout
            fds = [primary_device.fd, secondary_device.fd]
            ready, _, _ = select.select(fds, [], [], 1.0)

            if not ready:
                continue

            for fd in ready:
                current_device = primary_device if fd == primary_device.fd else secondary_device
                print(f"{timestamp()} - {'Primary' if current_device == primary_device else 'Secondary'} controller event detected.")
                for event in current_device.read():
                    handle_event(event, current_device, previous_merge_state)

    except (OSError, IOError) as e:
        print(f"{timestamp()} - Device error: {e}. Reconnecting and resetting...")
        primary_device, secondary_device = initialize_controllers()
        reset_virtual_devices()

    except KeyboardInterrupt:
        print(f"{timestamp()} - Exiting...")

    finally:
        if virtual_primary_controller:
            virtual_primary_controller.close()
        if virtual_secondary_controller:
            virtual_secondary_controller.close()
        if primary_device:
            try:
                primary_device.ungrab()
            except:
                pass
        if secondary_device:
            try:
                secondary_device.ungrab()
            except:
                pass

if __name__ == "__main__":
    main()
