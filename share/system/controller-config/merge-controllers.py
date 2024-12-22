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
import sys
import time
from datetime import datetime
import logging

# Configuration
MERGE_STATE_PATH = "/tmp/merge_controller_enabled"

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    datefmt='%Y-%m-%d %H:%M:%S'
)

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
class ControllerManager:
    """
    Manages the initialization, event handling, and merging of game controllers.

    This class sets up virtual controllers, detects physical controllers, handles input events,
    and merges input from multiple controllers based on a configurable state.
    """
    def __init__(self, merge_state_path=MERGE_STATE_PATH):
        self.merge_state_path = merge_state_path
        self.virtual_primary_controller = None
        self.virtual_secondary_controller = None
        self.primary_device = None
        self.secondary_device = None
        self.previous_merge_state = False
        self.running = True

        self.setup_virtual_controllers()
        self.initialize_controllers()

    def setup_virtual_controllers(self):
        """Initialize or reset virtual controllers."""
        logging.info("Setting up virtual controllers...")
        if self.virtual_primary_controller:
            self.virtual_primary_controller.close()
        if self.virtual_secondary_controller:
            self.virtual_secondary_controller.close()

        try:
            self.virtual_primary_controller = UInput(CONTROLLER_CAPABILITIES, name="Virtual Controller P1", version=0x3)
            self.virtual_secondary_controller = UInput(CONTROLLER_CAPABILITIES, name="Virtual Controller P2", version=0x3)
            logging.info("Virtual controllers initialized successfully.")
        except Exception as e:
            logging.error(f"Failed to initialize virtual controllers: {e}", exc_info=True)
            sys.exit(1)

    def initialize_controllers(self):
        """Detect and initialize primary and secondary game controllers."""
        logging.info("Initializing physical controllers...")
        devices = [InputDevice(path) for path in list_devices()]
        gamepads = [device for device in devices if "Twin USB Gamepad" in device.name]
        gamepads = sorted(gamepads, key=lambda x: x.path)  # Ensure consistent ordering

        if len(gamepads) < 2:
            logging.warning(f"Not enough gamepads detected. Found: {len(gamepads)}. Required: 2.")
            self.primary_device = None
            self.secondary_device = None
            return

        self.primary_device, self.secondary_device = gamepads[:2]
        logging.info(f"Gamepad 1: {self.primary_device.path}, Gamepad 2: {self.secondary_device.path}")

        try:
            logging.info("Grabbing devices...")
            self.primary_device.grab()
            self.secondary_device.grab()
            logging.info("Devices grabbed successfully.")
        except Exception as e:
            logging.error(f"Error grabbing devices: {e}", exc_info=True)
            self.primary_device = None
            self.secondary_device = None

    def is_merge_enabled(self):
        """Check if merge state is enabled by reading the specified file."""
        try:
            with open(self.merge_state_path, "r") as f:
                state = f.read().strip()
                return state.lower() == "true"
        except FileNotFoundError:
            logging.debug(f"Merge state file not found at {self.merge_state_path}. Defaulting to False.")
            return False
        except Exception as e:
            logging.error(f"Error reading merge state: {e}", exc_info=True)
            return False

    def handle_event(self, event, current_device, merge_enabled):
        """Process and route input events to the appropriate virtual controller."""
        try:
            is_secondary = (current_device == self.secondary_device)
            
            if merge_enabled:
                if event.type == ecodes.EV_KEY and event.code == ecodes.BTN_BASE4:
                    # Route Start button to respective virtual controller
                    target_device = self.virtual_secondary_controller if is_secondary else self.virtual_primary_controller
                    logging.info(f"Routing Start event (BTN_BASE4) from {'Secondary' if is_secondary else 'Primary'} device to {'Secondary' if is_secondary else 'Primary'} virtual controller.")
                else:
                    # Merge all other inputs to Primary virtual controller
                    target_device = self.virtual_primary_controller
                    logging.debug(f"Merging event {ecodes.KEY[event.code] if event.code in ecodes.KEY else event.code} to Primary virtual controller.")
            else:
                # Route events to respective virtual controllers
                target_device = self.virtual_secondary_controller if is_secondary else self.virtual_primary_controller
                logging.debug(f"Routing event {ecodes.KEY[event.code] if event.code in ecodes.KEY else event.code} to {'Secondary' if is_secondary else 'Primary'} virtual controller.")
            
            target_device.write_event(event)
            target_device.syn()

            logging.debug(f"Event handled: Device={current_device.path}, Type={event.type}, Code={event.code}, Value={event.value}")
        except Exception as e:
            logging.error(f"Error handling event: {e}", exc_info=True)

    def release_devices(self):
        """Release grabbed devices and close virtual controllers."""
        logging.info("Releasing resources...")
        if self.virtual_primary_controller:
            self.virtual_primary_controller.close()
            logging.info("Virtual primary controller closed.")
        if self.virtual_secondary_controller:
            self.virtual_secondary_controller.close()
            logging.info("Virtual secondary controller closed.")

        if self.primary_device:
            try:
                self.primary_device.ungrab()
                logging.info("Released Gamepad 1.")
            except Exception as e:
                logging.error(f"Failed to release Gamepad 1: {e}", exc_info=True)
        if self.secondary_device:
            try:
                self.secondary_device.ungrab()
                logging.info("Released Gamepad 2.")
            except Exception as e:
                logging.error(f"Failed to release Gamepad 2: {e}", exc_info=True)

    def run(self):
        """Main loop to process input events."""
        logging.info("Starting main event loop.")
        while self.running:
            merge_enabled = self.is_merge_enabled()

            if merge_enabled != self.previous_merge_state:
                logging.info(f"Merge state changed to {'ENABLED' if merge_enabled else 'DISABLED'}.")
                self.previous_merge_state = merge_enabled

            if not (self.primary_device and self.secondary_device):
                self.initialize_controllers()
                if not (self.primary_device and self.secondary_device):
                    logging.debug("Controllers not initialized. Retrying in 5 seconds...")
                    time.sleep(5)
                    continue
                self.setup_virtual_controllers()

            fds = [self.primary_device.fd, self.secondary_device.fd]
            try:
                ready, _, _ = select.select(fds, [], [], 1.0)
            except select.error as e:
                logging.error(f"Select error: {e}", exc_info=True)
                time.sleep(1)
                continue

            if not ready:
                continue

            for fd in ready:
                current_device = self.primary_device if fd == self.primary_device.fd else self.secondary_device
                try:
                    for event in current_device.read():
                        if event.type in [ecodes.EV_KEY, ecodes.EV_ABS]:
                            self.handle_event(event, current_device, merge_enabled)
                except OSError as e:
                    logging.error(f"Error reading from device {current_device.path}: {e}", exc_info=True)
                    self.initialize_controllers()
                    self.setup_virtual_controllers()
                    break  # Exit the for-loop and restart the while-loop

        self.release_devices()
        logging.info("Main loop exited.")

def main():
    """
    Initialize the ControllerManager and start the main event loop.
    """
    manager = ControllerManager()
    manager.run()

if __name__ == "__main__":
    main()
