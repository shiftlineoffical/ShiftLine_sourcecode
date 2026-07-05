import subprocess

curl = r'C:\Windows\System32\curl.exe'
url = 'https://script.google.com/macros/s/AKfycbyPzGLnkSJUNZHmq3HdOpgpMXZhxLYP75mO6HUSIIX_kGn2Ukcd75x7fFugf1OA/exec'
body = 'song=test%20song'
headers = [
    '-H', 'User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    '-H', 'Content-Type: application/x-www-form-urlencoded',
    '-H', 'Accept: application/json',
    '-H', 'Expect:',
    '-H', f'Content-Length: {len(body)}',
]
cmd = [curl, '-sSL', '--post302', '--post301', '-i', '-X', 'POST', url] + headers + ['--data', body]
print('COMMAND:')
print(' '.join(cmd))
print('---')
proc = subprocess.run(cmd, cwd=r'C:\Users\Public', capture_output=True, text=True)
print('RETURN CODE:', proc.returncode)
print('STDOUT:')
print(proc.stdout)
print('STDERR:')
print(proc.stderr)
