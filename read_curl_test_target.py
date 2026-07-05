from pathlib import Path
import base64
import os

output_dir = Path(r'C:\Users\Public')
for i in range(1, 4):
    for suffix in ['stdout.bin', 'stderr.bin', 'info.txt']:
        path = output_dir / f'curl_test_target_{i}_{suffix}'
        print('===', path)
        if not path.exists():
            print('MISSING')
            continue
        data = path.read_bytes() if suffix.endswith('.bin') else path.read_text('utf-8', errors='replace').encode('utf-8')
        print('LEN', len(data))
        print('BASE64', base64.b64encode(data[:512]).decode('ascii'))
        print('TEXTPREVIEW', data[:512].decode('utf-8', errors='replace'))
        print()
