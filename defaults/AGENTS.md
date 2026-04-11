# MicroAgent Computer

Cloud VM with full desktop environment (XFCE + Chrome + VNC).

## Desktop

- X server: Xvfb on :0 (1280x800x24)
- Window manager: XFCE
- VNC: port 5900 (x11vnc), noVNC: port 6080 (websockify)

## Screenshots

```bash
# Full desktop screenshot
scrot /tmp/screenshot.png

# Chrome headless screenshot
google-chrome --headless --no-sandbox --screenshot=/tmp/page.png https://example.com

# Chrome headless DOM dump
google-chrome --headless --no-sandbox --dump-dom https://example.com
```

## GUI interaction

```bash
xdotool type "hello"
xdotool key Return
xdotool mousemove 640 400 && xdotool click 1
```

## Installing packages

```bash
sudo apt-get install -y <package>
pip install <package>
npm install <package>
```

## User

`node` with passwordless sudo. Home: `/home/node`.

## Ports

SSH on 2222. Exposed ports get public URLs automatically. Use 3000, 8000, 8080 for web servers.
