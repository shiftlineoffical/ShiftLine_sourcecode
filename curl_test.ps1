$curl = "C:\Windows\System32\curl.exe"
$url = "https://script.google.com/macros/s/AKfycbxY2r67YHH3sHB90RMLli2bTb_8uZDCYX0k97YaSwwo5yHdEkByn02Ys-dzXu9YP5eymQ/exec"
$body = "song=test%20song&difficulty=4"
Set-Location -Path $env:TEMP
& $curl '-sSL' '-i' '--get' $url '--data-binary' $body 2>&1 | Out-File -FilePath "$env:TEMP\curl_test_output.txt" -Encoding utf8
Write-Output "DONE"
