# Idle Dim

An [Omarchy](https://omarchy.org) service plugin that dims the built-in display while you are away and brings it back the moment you return, before the screensaver or lock take over.

- After `idleSeconds` without input (300 by default) it lowers the backlight that `omarchy-hw-display` names to `dimPercent` of its maximum (20 by default). A backlight already at or below that is left alone.
- The next input restores the brightness it had. A reload or shell restart restores it too, so the display never stays dim.
- Idle inhibitors (a playing video, `omarchy toggle idle`) and Omarchy's Stay Awake keep the display as it is.
- External monitors are not touched.

## Requirements

Omarchy with `omarchy-hw-display` and `brightnessctl`.

## Install

```bash
scripts/install idle-dim
omarchy plugin enable io.github.ltecosta.idle-dim
```

## Settings

Set them on the plugin's entry in the `plugins` list of `~/.config/omarchy/shell.json`:

```json
{ "id": "io.github.ltecosta.idle-dim", "idleSeconds": 300, "dimPercent": 20 }
```

| Setting | Default | Range |
|---|---|---|
| `idleSeconds` | 300 | 30–7200 |
| `dimPercent` | 20 | 1–100 |

The shell log shows the values in use (`idle-dim: dims to 20% after 300 s idle`) and every dim and restore.

## State

While dimmed, the backlight's name and previous value are in `$XDG_RUNTIME_DIR/io.github.ltecosta.idle-dim/brightness`, which never outlives the session.

## Development

```bash
python3 -B -m unittest discover -s tests
```

The tests drive `idle-dim.sh` with stand-ins for `brightnessctl` and `omarchy-hw-display`.

## License

MIT
