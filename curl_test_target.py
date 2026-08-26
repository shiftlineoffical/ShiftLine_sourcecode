import subprocess
from pathlib import Path

curl = r'C:\Windows\System32\curl.exe'
url = 'https://script.google.com/macros/s/AKfycbxY2r67YHH3sHB90RMLli2bTb_8uZDCYX0k97YaSwwo5yHdEkByn02Ys-dzXu9YP5eymQ/exec'
output_dir = Path(r'C:\Users\Public')
gets = [
    [curl, '-sSL', '-I', url],
    [curl, '-sSL', url],
    [curl, '-sSL', '-i', '--get', url, '--data-binary', 'song=test%20song&difficulty=4'],
]
for i, cmd in enumerate(gets, start=1):
    print('RUN', i, 'CMD=', cmd)
    proc = subprocess.run(cmd, cwd=output_dir, capture_output=True)
    out_file = output_dir / f'curl_test_target_{i}_stdout.bin'
    err_file = output_dir / f'curl_test_target_{i}_stderr.bin'
    info_file = output_dir / f'curl_test_target_{i}_info.txt'
    out_file.write_bytes(proc.stdout)
    err_file.write_bytes(proc.stderr)
    info_file.write_text(f'RETURN={proc.returncode}\nCMD={cmd}\n', encoding='utf-8')
    print('WROTE', out_file, err_file, info_file)
