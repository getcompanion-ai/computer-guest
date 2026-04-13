## computer-guest

<img width="3598" height="1184" alt="Gemini_Generated_Image_d10lsxd10lsxd10l" src="https://github.com/user-attachments/assets/2f422d7e-0e17-4106-826a-0516f1edc828" />

computer-guest is the thin dev-tool packed docker image that runs on all
agentcomputer.ai machines by default

### Expected Ports

- `2222` for SSH
- `6080` for browser VNC

### Runtime

The guest is expected to boot from a normal Firecracker kernel plus rootfs and
start through a small custom init script running on PID 1 responsible for:

- bringing up guest networking
- starting SSH and desktop services
- staying alive as the runtime supervisor for the VM
