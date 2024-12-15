#!/usr/bin/env python3
import evdev
from evdev import UInput, ecodes, AbsInfo
import select
import os
import time

MERGE_STATE_PATH = "/tmp/merge_controller_enabled"

# Device paths
primary_controller_path = '/dev/input/event0'
secondary_controller_path = '/dev/input/event1'

# Combined capabilities for both controllers
controller_capabilities = {
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

def initialize_controllers():
    while True:
        try:
            primary_device = evdev.InputDevice(primary_controller_path)
            secondary_device = evdev.InputDevice(secondary_controller_path)
            primary_device.grab()
            secondary_device.grab()
            print("Controllers successfully initialized.")
            return primary_device, secondary_device
        except Exception as e:
            print(f"Error initializing controllers: {e}. Retrying in 2 seconds...")
            time.sleep(2)

def reset_virtual_devices():
    global virtual_primary_controller, virtual_secondary_controller
    print("Resetting virtual devices...")
    virtual_primary_controller.close()
    virtual_secondary_controller.close()
    virtual_primary_controller = UInput(controller_capabilities, name="Virtual Controller P1", version=0x3)
    virtual_secondary_controller = UInput(controller_capabilities, name="Virtual Controller P2", version=0x3)
    print("Virtual devices reset.")

def is_merge_enabled():
    try:
        with open(MERGE_STATE_PATH, "r") as f:
            return f.read().strip() == "True"
    except FileNotFoundError:
        return False

# Create virtual controllers
virtual_primary_controller = UInput(controller_capabilities, name="Virtual Controller P1", version=0x3)
virtual_secondary_controller = UInput(controller_capabilities, name="Virtual Controller P2", version=0x3)

# Initialize devices
primary_device, secondary_device = initialize_controllers()

try:
    while True:
        merge_enabled = is_merge_enabled()
        
        if not (primary_device and secondary_device):
            print("Controllers disconnected. Reconnecting...")
            primary_device, secondary_device = initialize_controllers()
            reset_virtual_devices()

        fds = [primary_device.fd, secondary_device.fd]
        r, w, x = select.select(fds, [], [])

        for fd in r:
            if fd == primary_device.fd:
                current_device = primary_device
                virtual_device = virtual_primary_controller
                print("Primary controller event detected.")
            else:
                current_device = secondary_device
                virtual_device = virtual_secondary_controller
                print("Secondary controller event detected.")

            for event in current_device.read():
                print(f"Device: {current_device.path}, Type: {event.type}, Code: {event.code}, Value: {event.value}")
                print(f"merge_enabled: {merge_enabled}")
                
                if merge_enabled:
                    if event.type == ecodes.EV_KEY and event.code == ecodes.BTN_BASE4:
                        # Maintain separate start button handling
                        target_device = (virtual_secondary_controller if current_device == secondary_device 
                                       else virtual_primary_controller)
                        print(f"Routing {'Secondary' if current_device == secondary_device else 'Primary'} "
                              f"controller event {event.code} (start) to respective controller.")
                        target_device.write_event(event)
                        target_device.syn()
                    elif event.type in [ecodes.EV_KEY, ecodes.EV_ABS]:
                        # Route all other events to primary controller when merged
                        print(f"Routing controller event {event.code} to Primary controller.")
                        virtual_primary_controller.write_event(event)
                        virtual_primary_controller.syn()
                else:
                    # Route events to their respective controllers when not merged
                    print(f"Routing controller event {event.code} to respective controller.")
                    virtual_device.write_event(event)
                    virtual_device.syn()

except (OSError, IOError) as e:
    print(f"Device error: {e}. Reconnecting controllers and resetting devices...")
    primary_device, secondary_device = initialize_controllers()
    reset_virtual_devices()

except KeyboardInterrupt:
    print("Exiting...")

finally:
    virtual_primary_controller.close()
    virtual_secondary_controller.close()
    if primary_device:
        primary_device.ungrab()
    if secondary_device:
        secondary_device.ungrab()