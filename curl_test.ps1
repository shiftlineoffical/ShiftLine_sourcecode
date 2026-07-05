$curl = "C:\Windows\System32\curl.exe"
$url = "https://script.google.com/macros/s/AKfycbyPzGLnkSJUNZHmq3HdOpgpMXZhxLYP75mO6HUSIIX_kGn2Ukcd75x7fFugf1OA/exec"
$body = "song=test%20song"
$args = @(
    '-sSL',
    '--post302',
    '--post301',
    '-i',
    '-X', 'POST',
    $url,
    '-H', 'User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    '-H', 'Content-Type: application/x-www-form-urlencoded',
    '-H', 'Accept: application/json',
    '-H', 'Expect:',
    '-H', ('Content-Length: ' + $body.Length),
    '--data', $body
)
Set-Location -Path $env:TEMP
& $curl @args 2>&1 | Out-File -FilePath "$env:TEMP\curl_test_output.txt" -Encoding utf8
Write-Output "DONE"
