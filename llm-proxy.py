#!/usr/bin/env python3
"""Simple proxy that rewrites model names for Cursor -> vLLM compatibility."""
import json
import http.client
from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import urlparse

TARGET_HOST = "100.106.202.64"
TARGET_PORT = 8000
TARGET_MODEL = "openai/gpt-oss-120b"

class ProxyHandler(BaseHTTPRequestHandler):
    def log_message(self, format, *args):
        print(f"[Proxy] {args[0]}")

    def do_POST(self):
        content_length = int(self.headers.get('Content-Length', 0))
        body = self.rfile.read(content_length)

        # Rewrite model name
        try:
            data = json.loads(body)
            original_model = data.get('model', 'unknown')
            if 'model' in data:
                data['model'] = TARGET_MODEL
            body = json.dumps(data).encode()
            print(f"[Proxy] Rewrote model: {original_model} -> {TARGET_MODEL}")
        except Exception as e:
            print(f"[Proxy] JSON parse error: {e}")

        # Forward request
        conn = http.client.HTTPConnection(TARGET_HOST, TARGET_PORT, timeout=120)
        try:
            headers = {'Content-Type': 'application/json', 'Content-Length': str(len(body))}
            conn.request('POST', self.path, body, headers)
            resp = conn.getresponse()

            self.send_response(resp.status)
            for k, v in resp.getheaders():
                if k.lower() not in ('transfer-encoding', 'connection'):
                    self.send_header(k, v)
            self.end_headers()
            self.wfile.write(resp.read())
        except Exception as e:
            print(f"[Proxy] Error: {e}")
            self.send_response(500)
            self.send_header('Content-Type', 'text/plain')
            self.end_headers()
            self.wfile.write(str(e).encode())
        finally:
            conn.close()

    def do_GET(self):
        conn = http.client.HTTPConnection(TARGET_HOST, TARGET_PORT, timeout=30)
        try:
            conn.request('GET', self.path)
            resp = conn.getresponse()

            self.send_response(resp.status)
            for k, v in resp.getheaders():
                if k.lower() not in ('transfer-encoding', 'connection'):
                    self.send_header(k, v)
            self.end_headers()
            self.wfile.write(resp.read())
        except Exception as e:
            self.send_response(500)
            self.send_header('Content-Type', 'text/plain')
            self.end_headers()
            self.wfile.write(str(e).encode())
        finally:
            conn.close()

if __name__ == "__main__":
    server = HTTPServer(("127.0.0.1", 8080), ProxyHandler)
    print(f"Proxy running on http://127.0.0.1:8080")
    print(f"Forwarding to http://{TARGET_HOST}:{TARGET_PORT}")
    print(f"All model requests will use: {TARGET_MODEL}")
    print("Configure Cursor with: http://127.0.0.1:8080/v1")
    server.serve_forever()
