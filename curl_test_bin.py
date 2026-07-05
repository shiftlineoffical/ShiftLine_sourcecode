import subprocess
import os

curl = r'C:\Windows\System32\curl.exe'
url = 'https://script.google.com/macros/s/AKfycbyPzGLnkSJUNZHmq3HdOpgpMXZhxLYP75mO6HUSIIX_kGn2Ukcd75x7fFugf1OA/exec'
body = 'song=test%20song'
args = [
    curl,
    '-sSL',
    '--post302',
    '--post301',
    '-i',
    '-X',
    'POST',
    url,
    '-H',
    'User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    '-H',
    'Content-Type: application/x-www-form-urlencoded',
    '-H',
    'Accept: application/json',
    '-H',
    'Expect:',
    '-H',
    f'Content-Length: {len(body)}',
    '--data',
    body,
]
proc = subprocess.run(args, cwd=r'C:\Users\Public', capture_output=True)
temp = os.getenv('TEMP') or r'C:\Windows\Temp'
with open(os.path.join(temp, 'curl_test_stdout.bin'), 'wb') as f:
    f.write(proc.stdout)
with open(os.path.join(temp, 'curl_test_stderr.bin'), 'wb') as f:
    f.write(proc.stderr)
with open(os.path.join(temp, 'curl_test_info.txt'), 'w', encoding='utf-8') as f:
    f.write(f'RETURN_CODE={proc.returncode}\n')
    f.write('CMD=' + ' '.join(args) + '\n')
print('WROTE', temp)
