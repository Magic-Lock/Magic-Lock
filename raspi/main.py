import asyncio
import io
import serial_asyncio
from aiohttp import web
from abc import ABC, abstractmethod
import time

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
        self.GPIO.output(self.relais_pin, 1024)

    def unlock(self):
        self.GPIO.output(self.relais_pin, 0)

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
        self.magic = [0.0, 0.0, 0.0, 0.0, 0.0]

    def is_touched(self) -> bool:
        return all(m >= 10.0 for m in self.magic)

    async def loop(self):
        reader, writer = await serial_asyncio.open_serial_connection(url="/dev/ttyACM0", baudrate=115200, timeout=1.0)

        while True:
            line = (await reader.readline()).decode('utf-8').rstrip()
            try:
                magic = float(line.split(' ')[0])
                self.magic = [*self.magic[1:], magic]
            except Exception as ex:
                print(ex)

class AlwaysTouchedDoorHandle(DoorHandle):
    def is_touched(self) -> bool:
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
    print("This is a Raspberry Pi!")
    door = MagicDoor()
    door_handle = MagicDoorHandle()
else:
    print("This is not a Raspberry Pi!")
    door = PrintDoor()
    door_handle = AlwaysTouchedDoorHandle()

door.lock()
door_open = False

async def detector():
    async def unlock(request):
        print('Unlock request')
        if door_handle.is_touched():
            door.unlock()
            print('Door unlocked')
            return web.Response(text="Unlocked")
        print('Handle not touched')
        return web.Response(text="Handle not touched")

    async def lock(request):
        print('Lock request')
        if not door_handle.is_touched():
            door.lock()
            print('Door locked!')
            return web.Response(text="Locked")
        print('Handle still touched')
        return web.Response(text="Handle still touched")

    app = web.Application()
    app.add_routes([
        web.get('/unlock', unlock),
        web.get('/lock', lock)
    ])

    runner = web.AppRunner(app)
    await runner.setup()
    site = web.TCPSite(runner)
    await site.start()

    await asyncio.Event().wait()

async def main():
    await asyncio.gather(
        door_handle.loop(),
        detector()
    )

asyncio.run(main())
