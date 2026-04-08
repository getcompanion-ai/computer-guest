# Guest Image

This directory is a selective extraction point from the old
`agentcomputer/docker/computer` guest.

It is intentionally not a wholesale copy.

The first version only targets the minimal `microagentcomputer` guest contract:

- SSH on `2222`
- browser desktop access on `6080`
- user root access via `sudo`

The goal here is to keep the guest small, explicit, and easy to reason about,
while still reusing the proven parts of the old image where they are actually
useful.

## Import Rules

Keep:

- SSH server configuration
- desktop packages needed for a visible session
- `x11vnc`
- `noVNC` and `websockify`
- entropy support

Do not import yet:

- sandbox-agent
- agent-ui
- workspace/runtime shims
- old AgentComputer bootstrap services
- old multi-port service surface

## Expected Ports

- `2222` for SSH
- `6080` for browser VNC

## Runtime Shape

The guest is expected to boot from a normal Firecracker kernel plus rootfs and
start through a small custom init script rather than the older AgentComputer
runtime stack. That PID 1 helper is responsible for:

- bringing up guest networking
- starting SSH and desktop services
- staying alive as the runtime supervisor for the VM
