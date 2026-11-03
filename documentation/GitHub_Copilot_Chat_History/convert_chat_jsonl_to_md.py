# tools/convert_chat_jsonl_to_md.py
import json, pathlib, sys, os

# Allow optional command-line args: src and dst. If omitted, use defaults
cwd = pathlib.Path(__file__).resolve().parent
default_src = cwd / 'chat_transcript.jsonl'
default_dst_dir = cwd.parent / 'docs'
default_dst = default_dst_dir / 'chat_history.md'

src = pathlib.Path(sys.argv[1]) if len(sys.argv) > 1 else default_src
dst = pathlib.Path(sys.argv[2]) if len(sys.argv) > 2 else default_dst
lines = []
with src.open('r', encoding='utf-8') as f:
  for i,l in enumerate(f,1):
	  try:
		  obj = json.loads(l)
	  except:
		  continue
	  role = obj.get('role') or obj.get('sender') or 'unknown'
	  text = obj.get('message') or obj.get('content') or json.dumps(obj, ensure_ascii=False)
	  ts = obj.get('timestamp') or obj.get('time') or ''
	  lines.append(f"### {role} {ts}\n\n{text}\n\n---\n")
dst.parent.mkdir(parents=True, exist_ok=True)
dst.write_text("# Chat Transcript\n\n" + "\n".join(lines), encoding='utf-8')
print('Wrote', dst)


#git add docs/chat_transcript.jsonl docs/chat_history.md
#git commit -m "Add Copilot chat transcript and notes"
#git push origin master

# python convert_chat_jsonl_to_md.py .\docs\chat_transcript.jsonl .\docs\chat_history.md