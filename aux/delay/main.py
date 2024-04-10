from http.server import HTTPServer, BaseHTTPRequestHandler

import asyncio
from evdev import InputDevice, categorize, ecodes, UInput

# HERE IS ALL OF OUR STATE!!!
# MUTATE IT AT WILL
DELAY = 3
DEBUG = False

# Change '/dev/input/eventX' to your keyboard's device path
device = InputDevice('/dev/input/event2')

ui = UInput()
DOING_IT_NOW = False
# END OF STATE


class RequestHandler(BaseHTTPRequestHandler):
    timeout = 5

    def do_PUT(self):
        global DOING_IT_NOW

        if self.path == '/grab':
            DOING_IT_NOW = True
            device.grab()

            self.send_response(200)
            self.send_header('Content-type', 'text/html')
            self.end_headers()
            self.wfile.write(b"grabbed")
        elif self.path == '/ungrab':
            DOING_IT_NOW = False
            device.ungrab()

            self.send_response(200)
            self.send_header('Content-type', 'text/html')
            self.end_headers()
            self.wfile.write(b"ungrabbed")
        else:
            self.send_error(404)

# Create HTTP server
server_address = ('localhost', 8000)  # Listen on all available interfaces on port 8000
httpd = HTTPServer(server_address, RequestHandler)
httpd.socket.settimeout(0.1)

async def handle_request():
    while True:
        print("Trying to handle request...")
        httpd.handle_request()
        await asyncio.sleep(1)

async def handle_key(ui, key_event, down):
    if not DOING_IT_NOW:
        return

    if DEBUG:
        if down == 1:
            print(f"{key_event.keycode} pressed")
        else:
            print(f"{key_event.keycode} released")

    await asyncio.sleep(DELAY)  # Delay in seconds

    if DEBUG:
        if down == 1:
            print(f"... {key_event.keycode}")
        else:
            print(f"... {key_event.keycode}")

    ui.write(ecodes.EV_KEY, key_event.scancode, down)  # key down
    ui.syn()

async def handle_events(device):
    global DOING_IT_NOW

    async for event in device.async_read_loop():
        if not DOING_IT_NOW:
            await asyncio.sleep(0.0)
            continue

        if event.type == ecodes.EV_KEY:
            key_event = categorize(event)
            if key_event.keystate == key_event.key_down:
                asyncio.create_task(handle_key(ui, key_event, 1))


            if key_event.keystate == key_event.key_up:
                asyncio.create_task(handle_key(ui, key_event, 0))


loop = asyncio.get_event_loop()
future = asyncio.gather(handle_request(), handle_events(device))

loop.run_until_complete(future)
