"""Fingerprint active app/backend sources, excluding private credentials and generated output."""
from pathlib import Path
import hashlib, json
ROOT = Path(__file__).resolve().parents[1]
def source_sha():
    paths = []
    for relative in ['mobile/lib', 'mobile/assets', 'mobile/android/app/src/main', 'src/platform', 'database']:
        paths.extend(p for p in (ROOT / relative).rglob('*') if p.is_file())
    for relative in ['mobile/pubspec.yaml', 'mobile/pubspec.lock', 'mobile/android/app/build.gradle.kts',
                     'mobile/android/build.gradle.kts', 'mobile/android/settings.gradle.kts', 'mobile/android/gradle.properties']:
        path = ROOT / relative
        if path.is_file(): paths.append(path)
    lines = []
    for path in sorted(set(paths), key=lambda p: p.relative_to(ROOT).as_posix()):
        with path.open('rb') as stream: digest = hashlib.file_digest(stream, 'sha256').hexdigest()
        lines.append(path.relative_to(ROOT).as_posix() + ':' + digest)
    return hashlib.sha256('\n'.join(lines).encode('utf-8')).hexdigest()
if __name__ == '__main__': print(json.dumps({'sourceSha256': source_sha()}))
