from pathlib import Path
path = Path(r'\\192.168.0.41\ng_nas2\ShiftLine\プログラムデータ\play.lua')
text = path.read_text(encoding='utf-8')
old = '    local requestBody = "song=" .. song\n    local shellSafeBody = requestBody:gsub("["\\]", "\\%1"):gsub("%%", "%%%%")\n    local contentLength = tostring(#requestBody)\n'
new = '    local requestBody = "song=" .. song\n    local shellSafeBody = requestBody:gsub("[\\\\\"]", "\\\\%1"):gsub("%%", "%%%%")\n    local contentLength = tostring(#requestBody)\n'
if old not in text:
    raise SystemExit('old text not found')
path.write_text(text.replace(old, new), encoding='utf-8')
print('replaced')
