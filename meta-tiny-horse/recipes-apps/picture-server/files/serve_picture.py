#!/usr/bin/env python3
import argparse
import mimetypes
import sys
from functools import partial
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import urlsplit


class PictureHandler(BaseHTTPRequestHandler):
    def __init__(self, *args, picture, **kwargs):
        self.picture = Path(picture)
        try:
            self.data = self.picture.read_bytes()
        except OSError as exc:
            self.data = None
            self.error = exc
        self.content_type = (
            mimetypes.guess_type(self.picture.name)[0] or "application/octet-stream"
        )
        super().__init__(*args, **kwargs)

    def do_GET(self):
        self._respond(send_body=True)

    def do_HEAD(self):
        self._respond(send_body=False)

    def _respond(self, send_body):
        path = urlsplit(self.path).path
        if path not in ("/", "/" + self.picture.name):
            self.send_error(404)
            return

        if self.data is None:
            self.send_error(404, f"Picture unavailable: {self.error}")
            return

        self.send_response(200)
        self.send_header("Content-Type", self.content_type)
        self.send_header("Content-Length", str(len(self.data)))
        self.send_header("Cache-Control", "no-store")
        self.end_headers()
        if send_body:
            self.wfile.write(self.data)

    def log_message(self, fmt, *args):
        sys.stderr.write("%s - %s\n" % (self.address_string(), fmt % args))


def default_picture():
    for candidate in (
        Path("/usr/share/picture-server/tinyhorse.jpg"),
        Path("tinyhorse.jpg"),
    ):
        if candidate.is_file():
            return str(candidate)
    return "/usr/share/picture-server/tinyhorse.jpg"


def main():
    parser = argparse.ArgumentParser(description="Serve a tiny horse over HTTP.")
    parser.add_argument(
        "picture",
        nargs="?",
        default=default_picture(),
        help="path to the tiny horse (default: tinyhorse.jpg)",
    )
    parser.add_argument(
        "--host", default="0.0.0.0", help="address to bind (default: 0.0.0.0)"
    )
    parser.add_argument(
        "--port", type=int, default=8000, help="port to listen on (default: 8000)"
    )
    args = parser.parse_args()

    picture = Path(args.picture)
    if not picture.is_file():
        sys.stderr.write(f"warning: {picture} not found yet; add it to start serving\n")

    server = ThreadingHTTPServer(
        (args.host, args.port), partial(PictureHandler, picture=picture)
    )
    print(f"Serving {picture} at http://{args.host}:{args.port}/", flush=True)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()


if __name__ == "__main__":
    main()
