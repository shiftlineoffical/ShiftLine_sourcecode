import re
import os
root = r'C:\Users\あほ\Documents\GitHub\ShiftLine_sourcecode'
path = os.path.join(root, 'lib', 'data', 'Songs', '黒魔-流星群に会えた夏', '流星群に会えた夏.sfl')
with open(path, 'r', encoding='utf-8') as f:
    data = f.read()

def trim(text):
    return text.strip()

def parseDiffHeader(header):
    m = re.match(r'^\s*([^,]+)\s*,\s*([^,]+)', header)
    if not m:
        return None, None
    idxToken = re.sub(r'\s+', '', m.group(1))
    levelToken = re.sub(r'\s+', '', m.group(2)) if m.group(2) else None
    try:
        idx = int(idxToken)
    except ValueError:
        idx = None
    return idx, levelToken


def extractSflDiffBlocks(data):
    blocks = []
    pos = 0
    while True:
        m = re.search(r'diff\s*\(', data[pos:])
        if not m:
            break
        openParen = pos + m.end() - 1
        headerStart = openParen + 1
        i = headerStart
        quoteChar = None
        headerEnd = None
        while i < len(data):
            ch = data[i]
            if quoteChar:
                if ch == '\\':
                    i += 2
                    continue
                elif ch == quoteChar:
                    quoteChar = None
            else:
                if ch == '"' or ch == "'":
                    quoteChar = ch
                elif ch == ')':
                    headerEnd = i
                    break
            i += 1
        if headerEnd is None:
            break
        header = data[headerStart:headerEnd]
        bodyStart = headerEnd + 1
        braceStart = data.find('{', bodyStart)
        if braceStart == -1:
            break
        depth = 0
        bodyEnd = None
        quoteChar = None
        i = braceStart
        while i < len(data):
            ch = data[i]
            if quoteChar:
                if ch == '\\':
                    i += 2
                    continue
                elif ch == quoteChar:
                    quoteChar = None
            else:
                if ch == '"' or ch == "'":
                    quoteChar = ch
                elif ch == '{':
                    depth += 1
                elif ch == '}':
                    depth -= 1
                    if depth == 0:
                        bodyEnd = i
                        break
            i += 1
        if bodyEnd is None:
            break
        body = data[braceStart + 1:bodyEnd]
        blocks.append((trim(header), trim(body)))
        pos = bodyEnd + 1
    return blocks

blocks = extractSflDiffBlocks(data)
print('blocks', len(blocks))
for header, body in blocks[:5]:
    print('HEADER:', repr(header))
    print('LEVEL:', parseDiffHeader(header))
    print('BODY preview:', repr(body[:120]))
    print('---')
