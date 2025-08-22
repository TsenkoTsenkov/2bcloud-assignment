import http from "http";
import url from "url";

const PORT = process.env.PORT || 3000;
console.log("test");
const server = http.createServer((req, res) => {
  const parsedUrl = url.parse(req.url, true);
  const path = parsedUrl.pathname;

  res.setHeader("Content-Type", "application/json");

  if (path === "/") {
    res.statusCode = 200;
    res.end(JSON.stringify({ message: "Hello World!" }));
  } else if (path === "/healthz") {
    res.statusCode = 200;
    res.end(
      JSON.stringify({
        status: "healthy",
        timestamp: new Date().toISOString(),
      }),
    );
  } else if (path === "/cpu-load") {
    const start = Date.now();
    let result = 0;

    while (Date.now() - start < 100) {
      for (let i = 0; i < 100000; i++) {
        result += Math.sqrt(i * Math.random());
      }
    }

    res.statusCode = 200;
    res.end(
      JSON.stringify({
        message: "CPU work completed",
        result: result,
        duration: Date.now() - start,
      }),
    );
  } else {
    res.statusCode = 404;
    res.end(JSON.stringify({ error: "Not Found" }));
  }
});

server.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
