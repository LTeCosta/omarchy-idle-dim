# Changelog

## 1.0.0

- Dims the backlight `omarchy-hw-display` names to a share of its maximum after a stretch of idle time, respecting idle inhibitors and Omarchy's Stay Awake, and restores it on the next input, on reload and on shell exit.
- `idleSeconds` and `dimPercent` are read, live, from the plugin's entry in the `plugins` list of `~/.config/omarchy/shell.json`.
