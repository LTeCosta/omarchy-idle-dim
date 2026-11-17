"""Tests for the Idle Dim plugin's backlight script."""

import os
import subprocess
import tempfile
import unittest
from pathlib import Path

SCRIPT = Path(__file__).resolve().parents[1] / "idle-dim.sh"

# brightnessctl stand-in backed by a file holding the raw brightness.
FAKE_BRIGHTNESSCTL = """#!/bin/bash
value_file="$FAKE_BACKLIGHT"
args=()
for arg in "$@"; do
  case "$arg" in -q|-m) ;; -d) ;; *) args+=("$arg") ;; esac
done
device="${args[0]}"
if [[ ${args[1]:-} == set ]]; then
  printf '%s\\n' "$device ${args[2]}" >>"$FAKE_LOG"
  printf '%s\\n' "${args[2]}" >"$value_file"
else
  printf '%s,backlight,%s,%s%%,%s\\n' "$device" "$(<"$value_file")" 0 "$FAKE_MAX"
fi
"""


class IdleDimTest(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        self.root = Path(temporary.name)
        bin_dir = self.root / "bin"
        bin_dir.mkdir()
        (bin_dir / "brightnessctl").write_text(FAKE_BRIGHTNESSCTL)
        (bin_dir / "omarchy-hw-display").write_text("#!/bin/bash\necho nvidia_0\n")
        for tool in bin_dir.iterdir():
            tool.chmod(0o755)
        self.home = self.root / "home"
        self.runtime = self.root / "run"
        self.home.mkdir()
        self.runtime.mkdir()
        self.backlight = self.root / "backlight"
        self.log = self.root / "log"
        self.env = {
            "PATH": f"{bin_dir}:{os.environ['PATH']}",
            "HOME": str(self.home),
            "XDG_RUNTIME_DIR": str(self.runtime),
            "FAKE_BACKLIGHT": str(self.backlight),
            "FAKE_LOG": str(self.log),
            "FAKE_MAX": "100",
        }
        self.set_brightness(80)

    def set_brightness(self, value):
        self.backlight.write_text(f"{value}\n")

    def brightness(self):
        return int(self.backlight.read_text())

    def run_script(self, *args):
        return subprocess.run(
            ["bash", str(SCRIPT), *args], env=self.env, capture_output=True, text=True
        )

    def writes(self):
        return self.log.read_text().splitlines() if self.log.exists() else []

    def test_dim_then_restore(self):
        self.assertEqual(self.run_script("dim", "20").returncode, 0)
        self.assertEqual(self.brightness(), 20)
        self.assertEqual(self.run_script("restore").returncode, 0)
        self.assertEqual(self.brightness(), 80)
        self.assertFalse((self.runtime / "io.github.ltecosta.idle-dim/brightness").exists())

    def test_scales_to_device_maximum(self):
        self.env["FAKE_MAX"] = "1000"
        self.set_brightness(900)
        self.run_script("dim", "20")
        self.assertEqual(self.brightness(), 200)

    def test_never_raises_brightness(self):
        self.set_brightness(10)
        self.run_script("dim", "20")
        self.run_script("restore")
        self.assertEqual(self.writes(), [])

    def test_second_dim_keeps_original_value(self):
        self.run_script("dim", "20")
        self.run_script("dim", "20")
        self.run_script("restore")
        self.assertEqual(self.brightness(), 80)

    def test_stay_awake_skips_dimming(self):
        state = self.home / ".local/state/omarchy/indicators"
        state.mkdir(parents=True)
        (state / "stay-awake").touch()
        self.run_script("dim", "20")
        self.assertEqual(self.writes(), [])

    def test_restore_without_saved_value_is_a_no_op(self):
        self.assertEqual(self.run_script("restore").returncode, 0)
        self.assertEqual(self.writes(), [])

    def test_rejects_invalid_arguments(self):
        self.assertEqual(self.run_script("dim", "0").returncode, 2)
        self.assertEqual(self.run_script("dim", "abc").returncode, 2)
        self.assertEqual(self.run_script().returncode, 2)


if __name__ == "__main__":
    unittest.main()
