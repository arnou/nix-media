#!/usr/bin/env python3
"""Local-only media center UI and Kodi launcher."""
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
import subprocess
import sys

PAGE = Path(sys.argv[1]).read_bytes()
KODI = sys.argv[2]

class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == '/health':
            body, content_type = b'ok', 'text/plain'
        elif self.path in ('/', '/index.html'):
            body, content_type = PAGE, 'text/html; charset=utf-8'
        else:
            self.send_error(404)
            return
        self.send_response(200)
        self.send_header('Content-Type', content_type)
        self.send_header('Content-Length', str(len(body)))
        self.send_header('Cache-Control', 'no-store')
        self.end_headers()
        self.wfile.write(body)

    def do_POST(self):
        # Prevent arbitrary web pages from launching local processes.
        if self.path != '/launch/kodi' or self.headers.get('Origin') != 'http://127.0.0.1:8765':
            self.send_error(403)
            return
        subprocess.Popen([KODI], start_new_session=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        self.send_response(204)
        self.send_header('Content-Length', '0')
        self.end_headers()

if __name__ == '__main__':
    ThreadingHTTPServer(('127.0.0.1', 8765), Handler).serve_forever()
