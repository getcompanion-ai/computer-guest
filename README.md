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
