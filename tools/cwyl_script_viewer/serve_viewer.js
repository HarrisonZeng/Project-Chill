const fs = require("fs");
const http = require("http");
const path = require("path");

const PORT = Number(process.env.CWYL_VIEWER_PORT || 8787);
const HOST = "127.0.0.1";
const ROOT = path.resolve(__dirname, "..", "..");

const contentTypes = new Map([
  [".html", "text/html;charset=utf-8"],
  [".json", "application/json;charset=utf-8"],
  [".js", "text/javascript;charset=utf-8"],
  [".md", "text/markdown;charset=utf-8"]
]);

const server = http.createServer((request, response) => {
  const url = new URL(request.url, `http://${HOST}:${PORT}`);
  const requestedPath = decodeURIComponent(url.pathname);
  const filePath = path.normalize(path.join(ROOT, requestedPath));

  if (!filePath.startsWith(ROOT)) {
    response.writeHead(403);
    response.end("Forbidden");
    return;
  }

  fs.readFile(filePath, (error, data) => {
    if (error) {
      response.writeHead(404);
      response.end("Not found");
      return;
    }

    response.writeHead(200, {
      "cache-control": "no-store",
      "content-type": contentTypes.get(path.extname(filePath)) || "text/plain;charset=utf-8"
    });
    response.end(data);
  });
});

server.listen(PORT, HOST, () => {
  console.log(`CWYL Script Viewer: http://${HOST}:${PORT}/tools/cwyl_script_viewer/cwyl_script_viewer.html`);
});
