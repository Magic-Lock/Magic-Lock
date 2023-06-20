import asyncio
import serial_asyncio
from bleak import BleakScanner, BLEDevice, AdvertisementData
from abc import ABC, abstractmethod

###################### Doors ######################
class Door(ABC):
    @abstractmethod
    def lock(): pass

    @abstractmethod
    def unlock(): pass

class MagicDoor(Door):
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

class PrintDoor(Door):
    def lock(self):
        print('Door LOCKED!')

    def unlock(self):
        print('Door UNLOCKED!')
###################################################
###################### Handles ####################
class DoorHandle(ABC):
    @abstractmethod
    def is_touched() -> bool: pass

    @abstractmethod
    async def loop(): pass

class MagicDoorHandle(DoorHandle):
    def __init__(self):
        self.magic = 0.0

    def is_touched(self) -> bool:
        return self.magic >= 10.0

    async def loop(self):
        reader, writer = await serial_asyncio.open_serial_connection(url="/dev/ttyACM0", baudrate=115200, timeout=1.0)

        while True:
            line = (await reader.readline()).decode('utf-8').rstrip()
            try:
                self.magic = float(line.split(' ')[0])
            except Exception as ex:
                print(ex)

class AlwaysTouchedDoorHandle(DoorHandle):
    def is_touched() -> bool:
        return True
    
    async def loop(self):
        return

###################################################

def is_raspberrypi():
    try:
        with io.open('/sys/firmware/devicetree/base/model', 'r') as m:
            if 'raspberry pi' in m.read().lower(): return True
    except Exception: pass
    return False

##################### Main code ###################
door: Door
door_handle: DoorHandle
if is_raspberrypi():
    door = MagicDoor()
    door_handle = MagicDoorHandle()
else:
    door = PrintDoor()
    door_handle = AlwaysTouchedDoorHandle()

door_open = None
async def detector():
    def callback(device: BLEDevice, advertisement_data: AdvertisementData):
        if device.name != "MOMENTUM TW 3": return
        global door_open

        if advertisement_data.rssi >= -75:
            if (not door_open) and door_handle.is_touched():
                door.unlock()
                door_open = True
        else:
            if door_open and not door_handle.is_touched():
                door.lock()
                door_open = False

    scanner = BleakScanner()
    scanner.register_detection_callback(callback)

    await scanner.start()
    while True:
        await asyncio.sleep(99)


async def main():
    await asyncio.gather(
        door_handle.loop(),
        detector()
    )

asyncio.run(main())
