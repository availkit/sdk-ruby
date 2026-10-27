#!/usr/bin/env python3
"""Packaging regression: private/cache/dependency files must never enter artifacts."""
import importlib.util
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tarfile
import tempfile
import zipfile

SENTINEL = b"NEVER_PACKAGE_LOCAL_PRIVATE_DATA"

def add_local_inputs(root):
    for name in ("private/config.json", ".local/request.json", "build/dependency.go",
                 "build/dependency.rb", "examples/node_modules/dependency.go",
                 "examples/vendor/dependency.rb", "test/private/config.json",
                 "lib/availkit/private/config.json", "examples/cache/leak.rb"):
        file = root / name
        file.parent.mkdir(parents=True, exist_ok=True)
        file.write_bytes(SENTINEL)
    (root / "private/source.go").write_bytes(SENTINEL)
    (root / "private/source.rb").write_bytes(SENTINEL)
    (root / ".local/linked.json").symlink_to(root / "private/config.json")

def run(command, cwd):
    return subprocess.run(command, cwd=cwd, stdout=subprocess.PIPE,
                          stderr=subprocess.STDOUT, check=False)

def main():
    source = Path(__file__).resolve().parents[1]
    ruby = os.environ.get("AVAILKIT_RUBY", "ruby")
    with tempfile.TemporaryDirectory(prefix="availkit-ruby-package-") as temporary:
        directory = Path(temporary)
        root = directory / "source"
        shutil.copytree(source, root)
        add_local_inputs(root)
        out = directory / "artifacts"
        result = run([ruby, str(root / "build.rb"), str(out)], root)
        assert result.returncode == 0, result.stdout.decode(errors="replace")
        listed = run([ruby, "-rjson", "-e", "s=Gem::Specification.load('availkit.gemspec'); abort unless s; puts JSON.generate(s.files)"], root)
        assert listed.returncode == 0, listed.stdout.decode(errors="replace")
        expected = set(json.loads(listed.stdout))
        artifact = out / "availkit-0.1.1.gem"
        with tarfile.open(artifact) as outer:
            stream = outer.extractfile("data.tar.gz")
            with tarfile.open(fileobj=stream, mode="r:gz") as data:
                names = {member.name for member in data if member.isfile()}
            assert names == expected
            stream = outer.extractfile("data.tar.gz")
            with tarfile.open(fileobj=stream, mode="r:gz") as data:
                for member in data:
                    assert not member.issym() and not member.islnk()
                    if member.isfile():
                        assert data.extractfile(member).read() != SENTINEL
            stream = outer.extractfile("data.tar.gz")
            with tarfile.open(fileobj=stream, mode="r:gz") as data:
                assert json.load(data.extractfile("runtime-policy.json"))["tested"]
        original = root / "lib/availkit/models.rb"
        original.unlink(); original.symlink_to(root / "private/source.rb")
        result = run([ruby, str(root / "build.rb"), str(directory / "rejected")], root)
        assert result.returncode != 0 and b"symlink package input rejected" in result.stdout
        original.unlink(); shutil.copy2(source / "lib/availkit/models.rb", original)
        shutil.rmtree(root / "examples")
        (root / "examples").symlink_to(root / "private", target_is_directory=True)
        result = run([ruby, str(root / "build.rb"), str(directory / "rejected-parent")], root)
        assert result.returncode != 0 and b"symlink package input rejected" in result.stdout
    print("PASS Ruby gem exact allowlist, private/cache/dependency exclusions and source/parent symlink rejection")

if __name__ == "__main__":
    main()
