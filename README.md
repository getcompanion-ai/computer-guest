## computer-guest

<img width="3598" height="630" alt="Gemini_Generated_Image_d10lsxd10lsxd10l" src="https://github.com/user-attachments/assets/332ca256-2707-46af-b593-e5e3071a2263" />

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
