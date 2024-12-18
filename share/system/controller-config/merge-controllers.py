#!/usr/bin/env python3

"""
This script is designed to manage two Twin USB Gamepad devices in a Linux environment.
It assigns the gamepads as "Gamepad 1" and "Gamepad 2" based on their input event paths
and creates virtual devices ("Virtual Controller P1" and "Virtual Controller P2") for
each gamepad. The script also supports merging inputs from both controllers into a single
virtual device when enabled via a merge state file.

Key Features:
- Detects and initializes two gamepads dynamically based on their input paths.
- Creates virtual controllers for use in applications that require joystick input.
- Optionally merges input from both controllers into a single virtual controller when
  the merge state is enabled via `/tmp/merge_controller_enabled`.
- Handles device disconnection and reconnection gracefully.
- Logs all significant actions and events for debugging purposes.
"""

from evdev import UInput, ecodes, AbsInfo, InputDevice, list_devices
import select
import time
from datetime import datetime

# Configuration
MERGE_STATE_PATH = "/tmp/merge_controller_enabled"

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
primary_device = None
secondary_device = None

# Timestamp for Logs
def timestamp():
    return datetime.now().strftime("%Y-%m-%d %H:%M:%S")

# Automatically Assign Gamepad 1 and 2
def initialize_controllers():
    devices = [InputDevice(path) for path in list_devices()]
    gamepads = [device for device in devices if "Twin USB Gamepad" in device.name]
    gamepads = sorted(gamepads, key=lambda x: x.path)  # Sort by event path to ensure consistent ordering

    if len(gamepads) < 2:
        print(f"{timestamp()} - Not enough gamepads detected. Found: {len(gamepads)}")
        time.sleep(2)
        return None, None

    primary_device = gamepads[0]
    secondary_device = gamepads[1]

    print(f"{timestamp()} - Gamepad 1: {primary_device.path}, Gamepad 2: {secondary_device.path}")

    try:
        print(f"{timestamp()} - Grabbing devices...")
        primary_device.grab()
        secondary_device.grab()
        print(f"{timestamp()} - Devices grabbed successfully.")
    except Exception as e:
        print(f"{timestamp()} - Error grabbing devices: {e}")
        return None, None

    return primary_device, secondary_device

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
    global secondary_device  # Access the global secondary_device variable

    try:
        is_secondary = (current_device == secondary_device)
        target_device = virtual_secondary_controller if is_secondary else virtual_primary_controller

        print(f"{timestamp()} - Device: {current_device.path}, Type: {event.type}, Code: {event.code}, Value: {event.value}")

        if merge_enabled:
            target_device = virtual_primary_controller  # Merge all input to primary virtual controller

        target_device.write_event(event)
        target_device.syn()
    except Exception as e:
        print(f"{timestamp()} - Error handling event: {e}")

# Main Logic
def main():
    global virtual_primary_controller, virtual_secondary_controller
    global primary_device, secondary_device  # Make these global

    reset_virtual_devices()

    primary_device, secondary_device = initialize_controllers()
    previous_merge_state = is_merge_enabled()

    try:
        while True:
            merge_enabled = is_merge_enabled()

            if merge_enabled != previous_merge_state:
                print(f"{timestamp()} - Merge state changed to {'ENABLED' if merge_enabled else 'DISABLED'}")
                previous_merge_state = merge_enabled

            if not (primary_device and secondary_device):
                print(f"{timestamp()} - Reinitializing controllers...")
                primary_device, secondary_device = initialize_controllers()
                reset_virtual_devices()
                continue

            fds = [primary_device.fd, secondary_device.fd]
            ready, _, _ = select.select(fds, [], [], 1.0)

            if not ready:
                continue

            for fd in ready:
                current_device = primary_device if fd == primary_device.fd else secondary_device
                try:
                    for event in current_device.read():
                        handle_event(event, current_device, merge_enabled)
                except OSError as e:
                    print(f"{timestamp()} - Error reading from device {current_device.path}: {e}")
                    primary_device, secondary_device = initialize_controllers()
                    reset_virtual_devices()
                    break

    except KeyboardInterrupt:
        print(f"{timestamp()} - Exiting...")

    finally:
        if virtual_primary_controller:
            virtual_primary_controller.close()
            print(f"{timestamp()} - Virtual primary controller closed.")
        if virtual_secondary_controller:
            virtual_secondary_controller.close()
            print(f"{timestamp()} - Virtual secondary controller closed.")
        if primary_device:
            try:
                primary_device.ungrab()
                print(f"{timestamp()} - Released Gamepad 1")
            except Exception as e:
                print(f"{timestamp()} - Failed to release Gamepad 1: {e}")
        if secondary_device:
            try:
                secondary_device.ungrab()
                print(f"{timestamp()} - Released Gamepad 2")
            except Exception as e:
                print(f"{timestamp()} - Failed to release Gamepad 2: {e}")

if __name__ == "__main__":
    main()
