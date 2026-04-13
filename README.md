## computer-guest

<img width="3588" height="1184" alt="Gemini_Generated_Image_yxb12yyxb12yyxb1" src="https://github.com/user-attachments/assets/005a63e8-99c5-4fb9-9b86-7ace01f248ae" />


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
