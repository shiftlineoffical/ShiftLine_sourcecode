import subprocess
from pathlib import Path

curl = r'C:\Windows\System32\curl.exe'
url = 'https://script.google.com/macros/s/AKfycbyPzGLnkSJUNZHmq3HdOpgpMXZhxLYP75mO6HUSIIX_kGn2Ukcd75x7fFugf1OA/exec'
output_dir = Path(r'C:\Users\Public')
gets = [
    [curl, '-sSL', '-I', url],
    [curl, '-sSL', url],
    [curl, '-sSL', '--post302', '--post301', '-i', '-X', 'POST', url, '-H', 'Content-Type: application/x-www-form-urlencoded', '--data', 'song=test%20song'],
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
