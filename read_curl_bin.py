from pathlib import Path
import base64
import os

temp = Path(os.getenv('TEMP') or r'C:\Windows\Temp')
for name in ['curl_test_info.txt', 'curl_test_stdout.bin', 'curl_test_stderr.bin']:
    path = temp / name
    print('===', path)
    if not path.exists():
        print('MISSING')
        continue
    data = path.read_bytes()
    print('LEN', len(data))
    print('BASE64', base64.b64encode(data[:512]).decode('ascii'))
    print('TEXTPREVIEW', data[:512].decode('utf-8', errors='replace'))
    print()
