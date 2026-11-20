const http = require('http');
const https = require('https');
const fs = require('fs');
const path = require('path');
const { URL } = require('url');

const PORT = 8088;
const DIR = path.join(__dirname, 'build', 'web');

const MIME = {
  '.html': 'text/html',
  '.js': 'text/javascript',
  '.mjs': 'text/javascript',
  '.css': 'text/css',
  '.json': 'application/json',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.webp': 'image/webp',
  '.svg': 'image/svg+xml',
  '.wasm': 'application/wasm',
  '.ttf': 'font/ttf',
  '.otf': 'font/otf',
  '.woff': 'font/woff',
  '.woff2': 'font/woff2'
};

const server = http.createServer((req, res) => {
  // CORS Headers for all requests
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', '*');

  if (req.method === 'OPTIONS') {
    res.writeHead(204);
    res.end();
    return;
  }

  // Handle Design Assets Serving
  if (req.url.startsWith('/design-assets/')) {
    try {
      const filename = decodeURIComponent(req.url.replace('/design-assets/', '').split('?')[0]);
      const assetPath = path.join(__dirname, 'Movix - Movie Streaming App UI Kit (Community) (Copy)', filename);
      if (fs.existsSync(assetPath)) {
        res.writeHead(200, {
          'Content-Type': 'image/png',
          'Access-Control-Allow-Origin': '*',
          'Cache-Control': 'public, max-age=86400'
        });
        fs.createReadStream(assetPath).pipe(res);
        return;
      } else {
        res.writeHead(404);
        res.end('Design asset not found');
        return;
      }
    } catch (e) {
      res.writeHead(500);
      res.end('Error serving design asset');
      return;
    }
  }

  // Handle Image Proxy for Web CORS
  if (req.url.startsWith('/proxy-image')) {
    try {
      const parsedUrl = new URL(req.url, `http://${req.headers.host}`);
      const targetUrl = parsedUrl.searchParams.get('url');

      if (!targetUrl) {
        res.writeHead(400);
        res.end('Missing url param');
        return;
      }

      fetch(targetUrl, {
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)',
          'Referer': 'https://phimapi.com/'
        }
      })
      .then(async (remoteRes) => {
        if (!remoteRes.ok) {
          res.writeHead(remoteRes.status);
          res.end('Remote fetch failed');
          return;
        }

        const contentType = remoteRes.headers.get('content-type') || 'image/jpeg';
        res.writeHead(200, {
          'Content-Type': contentType,
          'Access-Control-Allow-Origin': '*',
          'Cache-Control': 'public, max-age=86400'
        });

        const arrayBuffer = await remoteRes.arrayBuffer();
        res.end(Buffer.from(arrayBuffer));
      })
      .catch((err) => {
        console.error('Proxy error:', err.message);
        res.writeHead(502);
        res.end('Proxy error');
      });
      return;
    } catch (e) {
      res.writeHead(500);
      res.end('Internal server error');
      return;
    }
  }

  let reqPath = decodeURI(req.url.split('?')[0]);
  if (reqPath === '/') reqPath = '/index.html';
  let filePath = path.join(DIR, reqPath);

  if (!fs.existsSync(filePath)) {
    filePath = path.join(DIR, 'index.html');
  }

  const ext = path.extname(filePath).toLowerCase();
  const contentType = MIME[ext] || 'application/octet-stream';

  fs.readFile(filePath, (err, content) => {
    if (err) {
      res.writeHead(500);
      res.end('Error loading file');
    } else {
      res.writeHead(200, { 'Content-Type': contentType });
      res.end(content);
    }
  });
});

server.listen(PORT, '127.0.0.1', () => {
  console.log(`Server running at http://127.0.0.1:${PORT}`);
});
