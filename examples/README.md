# Input Forge - examples

Runnable examples. These are **not** part of the shipped addon (don't copy
`examples/` into your game); they demonstrate how to wire Input Forge together.
Requires **Godot 4.7+**.

## Couch co-op (`couch_coop/couch_coop.tscn`)

Local multiplayer: each device that presses its join key gets its own square to
drive. Open the scene and run it (F6), then:

- **Keyboard zone 0:** WASD to move, Space to join + jump.
- **Keyboard zone 1:** Arrow keys to move, Enter to join + jump.
- **Any gamepad:** left stick / D-pad to move, A or Start to join + jump.
- Press the join input again to leave.

It builds its own InputMap at runtime (via `InputForgeMapWriter` event builders +
`InputMap`), so it works without project-level setup. It shows the core pattern:
`InputForgeJoinListener` -> `InputForgeDeviceSource.poll()` per physics tick.

## Netcode (`netcode/netcode_demo.gd`)

The command codec, end to end, headless:

```bash
godot --headless --path . --script res://examples/netcode/netcode_demo.gd
```

Expected output (a jump press is recovered even though its packet was dropped):

```
tick 1: first packet -> server adopts the baseline, emits NO press
  server.poll() pressed = []
tick 2: client presses jump -> delivered
  server.poll() pressed = ["jump"]
tick 3: client presses jump again, but the packet is LOST (not sent)
tick 4: next packet arrives; the counter delta recovers the lost press
  server.poll() pressed = ["jump"]
done
```
