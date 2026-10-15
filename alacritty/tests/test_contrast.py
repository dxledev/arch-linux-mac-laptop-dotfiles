import importlib.util
import json
from pathlib import Path
import shlex
import subprocess
import sys
import tempfile
import tomllib
import unittest


ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / ".config/noctalia/scripts/alacritty-contrast.py"
TEMPLATE = ROOT / ".config/noctalia/templates/alacritty-palette.toml"
sys.path.insert(0, str(SCRIPT.parent))
spec = importlib.util.spec_from_file_location("alacritty_contrast", SCRIPT)
generator = importlib.util.module_from_spec(spec)
spec.loader.exec_module(generator)


class ContrastTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.native = json.loads(subprocess.check_output([
            "noctalia", "theme", str(Path.home() / "Pictures/wallhaven-835ojy.jpg"),
            "--scheme", "m3-tonal-spot", "--both",
        ], text=True))

    def test_reference_parity_except_failing_foregrounds(self):
        for mode in ("dark", "light"):
            with self.subTest(mode=mode):
                source = {"mode": mode, "colors": self.native[mode]}
                palette, candidates, terminal = generator.normalize(source)
                plan = generator.reference.render_plan(palette, candidates, terminal, 4.5, 3, 0.06)
                rendered, _ = generator.generate(source)
                colors = tomllib.loads(rendered)["colors"]
                generator.validate(colors)
                for index, original in enumerate(plan["terminal"]):
                    section = "normal" if index < 8 else "bright"
                    actual = colors[section][generator.NAMES[index % 8]]
                    if index in (0, 8) or generator.reference.contrast_ratio(original, palette["base"]) >= 3:
                        self.assertEqual(actual, f"#{original}")
                    elif generator.reference.contrast_ratio(terminal[index], palette["base"]) >= 3:
                        self.assertEqual(actual, f"#{terminal[index]}")

    def test_monochrome_and_low_contrast_palettes(self):
        for mode in ("dark", "light"):
            for gray in ("#000000", "#333333", "#757575", "#777777", "#aaaaaa", "#ffffff"):
                with self.subTest(mode=mode, gray=gray):
                    source = {"mode": mode, "colors": dict.fromkeys(self.native[mode], gray)}
                    rendered, report = generator.generate(source)
                    generator.validate(tomllib.loads(rendered)["colors"])
                    self.assertIn("validation: PASS", report)
                    self.assertEqual(generator.generate(source), (rendered, report))

    def test_native_template_and_hook_dark_and_light(self):
        for mode in ("dark", "light"):
            with self.subTest(mode=mode), tempfile.TemporaryDirectory() as temporary:
                root = Path(temporary)
                native = root / "native.json"
                native.write_text(json.dumps(self.native))
                palette, output, report = (root / name for name in ("palette.toml", "theme.toml", "report.txt"))
                hook = shlex.join([sys.executable, str(SCRIPT), "--palette", str(palette),
                                   "--output", str(output), "--report", str(report)])
                config = root / "templates.toml"
                config.write_text("[templates.alacritty_contrast]\n"
                                  f"input_path = {json.dumps(str(TEMPLATE))}\n"
                                  f"output_path = {json.dumps(str(palette))}\n"
                                  f"post_hook = {json.dumps(hook)}\nhook_async = false\n")
                subprocess.run(["noctalia", "theme", "--theme-json", str(native),
                                "--default-mode", mode, "-c", str(config)],
                               check=True, capture_output=True, text=True)
                self.assertEqual(tomllib.loads(palette.read_text())["mode"], mode)
                generator.validate(tomllib.loads(output.read_text())["colors"])
                before = output.stat().st_mtime_ns
                subprocess.run([sys.executable, str(SCRIPT), "--palette", str(palette),
                                "--output", str(output), "--report", str(report)],
                               check=True, capture_output=True)
                self.assertEqual(before, output.stat().st_mtime_ns)
                old = output.read_bytes()
                palette.write_text('mode = "dark"\n[colors]\nbackground = "invalid"\n')
                failed = subprocess.run([sys.executable, str(SCRIPT), "--palette", str(palette),
                                         "--output", str(output), "--report", str(report)],
                                        capture_output=True)
                self.assertNotEqual(failed.returncode, 0)
                self.assertEqual(old, output.read_bytes())


if __name__ == "__main__":
    unittest.main()
