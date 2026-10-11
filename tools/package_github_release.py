"""Package only public app artifacts and the verified published walkthrough."""
from pathlib import Path
import hashlib
import json
import subprocess
import sys
import zipfile

root = Path(__file__).resolve().parents[1]
subprocess.run([sys.executable, str(root / 'tools/stage_release.py')], check=True)
site = root / 'release/site'
manifest = json.loads((site / 'release.json').read_text(encoding='utf-8'))
version = manifest['version'].split('+')[0]
archive = root / 'release' / f'rideshare-{version}-portfolio-assets.zip'
allowed = {'demo', 'downloads', 'media', 'fonts'}
with zipfile.ZipFile(archive, 'w', zipfile.ZIP_DEFLATED) as bundle:
    for file in sorted(site.rglob('*')):
        if not file.is_file():
            continue
        relative = file.relative_to(site)
        if relative.parts[0] not in allowed and relative.as_posix() != 'release.json':
            raise SystemExit(f'Unexpected public artifact: {relative}')
        bundle.write(file, relative.as_posix())
    bundle.write(root / 'docs/GitHub-and-Portfolio-Handoff.md', 'PORTFOLIO-HANDOFF.md')
artifacts = [archive, site / 'downloads' / f'rideshare-{version}.apk',
             site / 'media/rideshare-walkthrough.mp4',
             site / 'media/rideshare-walkthrough.vtt',
             site / 'media/walkthrough-transcript.txt', site / 'media/walkthrough.json', site / 'release.json']
lines = []
for file in artifacts:
    with file.open('rb') as stream:
        digest = hashlib.file_digest(stream, 'sha256').hexdigest()
    lines.append(f'{digest}  {file.name}')
(root / 'release/SHA256SUMS.txt').write_text('\n'.join(lines) + '\n', encoding='utf-8')
print(f'Packaged {archive.name}: {archive.stat().st_size / 1024 / 1024:.1f} MB')
