from pathlib import Path
import re

root = Path(r'c:\Users\あほ\Documents\GitHub\ShiftLine_sourcecode')
files = sorted(root.glob('**/*.lua'))

replacements = [
    ('local string_format = string_format', 'local string_format = string.format'),
    ('local table_insert = table_insert', 'local table_insert = table.insert'),
    ('local table_remove = table_remove', 'local table_remove = table.remove'),
    ('local table_concat = table_concat', 'local table_concat = table.concat'),
    ('local math_floor = math_floor', 'local math_floor = math.floor'),
    ('local math_max = math_max', 'local math_max = math.max'),
    ('local math_min = math_min', 'local math_min = math.min'),
    ('local __tconcat = __tconcat', 'local __tconcat = table.concat'),
]

for path in files:
    text = path.read_text(encoding='utf-8')
    original = text

    if 'local string_format =' not in text and 'local string_format' not in text:
        lines = text.splitlines()
        insert_at = 0
        while insert_at < len(lines) and (not lines[insert_at].strip() or lines[insert_at].lstrip().startswith('--')):
            insert_at += 1
        lines[insert_at:insert_at] = [
            'local string_format = string.format',
            'local table_insert = table.insert',
            'local table_remove = table.remove',
            'local table_concat = table.concat',
            'local math_floor = math.floor',
            'local math_max = math.max',
            'local math_min = math.min',
            ''
        ]
        text = '\n'.join(lines) + ('\n' if original.endswith('\n') else '')

    for old, new in replacements:
        text = text.replace(old, new)

    text = re.sub(r'(?<![\w_.])table\.insert\b', 'table_insert', text)
    text = re.sub(r'(?<![\w_.])table\.remove\b', 'table_remove', text)
    text = re.sub(r'(?<![\w_.])table\.concat\b', 'table_concat', text)
    text = re.sub(r'(?<![\w_.])string\.format\b', 'string_format', text)
    text = re.sub(r'(?<![\w_.])math\.floor\b', 'math_floor', text)
    text = re.sub(r'(?<![\w_.])math\.max\b', 'math_max', text)
    text = re.sub(r'(?<![\w_.])math\.min\b', 'math_min', text)

    if text != original:
        path.write_text(text, encoding='utf-8')

print('updated lua files')
