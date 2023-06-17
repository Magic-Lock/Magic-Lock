import asyncio
from bleak import BleakScanner, BLEDevice, AdvertisementData
from abc import ABC, abstractclassmethod

###################### Doors ######################
class Door(ABC):
    @abstractclassmethod
    def lock(): pass

    @abstractclassmethod
    def unlock(): pass

def MagicDoor(Door):
    def __init__(self, relais_pin = 27):
        import RPi.GPIO as GPIO
        self.GPIO = GPIO

        GPIO.setmode(GPIO.BCM)
        GPIO.setup(relais_pin, GPIO.OUT)
        self.relais_pin = relais_pin

    def lock(self):
        self.GPIO.output(self.relais_pin, 0)

    def unlock(self):
        self.GPIO.output(self.relais_pin, 1024)

def PrintDoor(Door):
    def lock(self):
        print('Door LOCKED!')

    def unlock(self):
        print('Door UNLOCKED!')
###################################################
###################### Handles ####################
class DoorHandle(ABC):
    @abstractclassmethod
    def is_touched() -> bool: pass

class MagicDoorHandle(DoorHandle):
    def is_touched() -> bool:
        return False

###################################################

def is_raspberrypi():
    try:
        with io.open('/sys/firmware/devicetree/base/model', 'r') as m:
            if 'raspberry pi' in m.read().lower(): return True
    except Exception: pass
    return False

##################### Main code ###################
door: Door
if is_raspberrypi():
    door = MagicDoor()
else:
    door = PrintDoor()

door_open = None
async def main():
    def callback(device: BLEDevice, advertisement_data: AdvertisementData):
        if device.name != "MOMENTUM TW 3": return
        global door_open

        if advertisement_data.rssi >= -75:
            if not door_open:
                door.unlock()
                door_open = True
        else:
            if door_open:
                door.lock()
                door_open = False

    scanner = BleakScanner()
    scanner.register_detection_callback(callback)

    await scanner.start()
    while True:
        await asyncio.sleep(99)

asyncio.run(main())
