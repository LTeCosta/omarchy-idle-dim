#!/bin/bash
# Dim the built-in display backlight while idle and restore it afterwards.
#   idle-dim.sh dim <percent>   save the current brightness and lower it to <percent>
#   idle-dim.sh restore         restore the saved brightness, if any
# The saved value lives in $XDG_RUNTIME_DIR, so it never survives a reboot.

set -u

state_dir="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/io.github.ltecosta.idle-dim"
saved="$state_dir/brightness"
stay_awake="$HOME/.local/state/omarchy/indicators/stay-awake"

case "${1:-}" in
dim)
  percent="${2:-}"
  [[ $percent =~ ^[0-9]+$ ]] && (( percent >= 1 && percent <= 100 )) || exit 2
  [[ -e $stay_awake || -e $saved ]] && exit 0

  device="$(omarchy-hw-display)" || exit 0
  IFS=, read -r _ _ current _ max < <(brightnessctl -m -d "$device")
  [[ $current =~ ^[0-9]+$ && $max =~ ^[0-9]+$ ]] || exit 1

  target=$(( max * percent / 100 ))
  (( target < 1 )) && target=1
  (( current > target )) || exit 0

  mkdir -p "$state_dir"
  printf '%s %s\n' "$device" "$current" >"$saved"
  brightnessctl -q -d "$device" set "$target"
  ;;
restore)
  [[ -r $saved ]] || exit 0
  read -r device value <"$saved"
  rm -f "$saved"
  [[ -n ${device:-} && ${value:-} =~ ^[0-9]+$ ]] || exit 1
  brightnessctl -q -d "$device" set "$value"
  ;;
*)
  echo "usage: idle-dim.sh dim <percent> | restore" >&2
  exit 2
  ;;
esac
