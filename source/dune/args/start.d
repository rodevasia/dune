module dune.args.start;

import std.stdio;
import std.string : toLower;
import core.thread.osthread : Thread;
import std.process;
import core.stdc.ctype;

import slf4d;
import handy_httpd : HttpServer, ServerConfig, HttpRequestContext, Method, HttpStatus;

import dune.parser;
import dune.logger_provider;

void startFn(Start args)
{
  createServer(args.port, args.lgLevel, args.logPath);
}

void createServer(ushort port = 0, string lgLevel, string logPath)
{
  ushort PORT = 8080;
  if (port != 0)
  {
    PORT = port;
  }
  ServerConfig config = ServerConfig();
  config.port = PORT;
  HttpServer server = new HttpServer(&handle, config);
  Levels logLevel = Levels.INFO;
  switch (lgLevel.toLower)
  {
  case "debug":
    logLevel = Levels.DEBUG;
    break;
  case "trace":
    logLevel = Levels.TRACE;
    break;
  case "info":
    logLevel = Levels.INFO;
    break;
  case "warn":
    logLevel = Levels.WARN;
    break;
  case "error":
    logLevel = Levels.ERROR;
    break;
  default:
    break;
  }
  Log.config(true, logPath, logLevel);

  server.start();
  scope (exit)
  {
    server.stop();
  }

}

private void handle(ref HttpRequestContext ctx)
{
  string url = ctx.request.url;

  string[] paths = ["routes"];
  import std.string : empty;

  if (url.empty)
  {
    paths ~= "index.html";
  }
  else
  {
    import std.string : split;

    paths ~= url.split("/");
    paths[$ - 1] = paths[$ - 1] ~ ".html";
  }

  import std.string : replace;
  import std.file : exists, read;
  import std.path : buildPath;

  auto filePath = buildPath(paths);
  debug
  {
    import std.stdio : writeln;

    string temp = "a";
    filePath = buildPath(temp ~ paths);

  }
  if (filePath.exists)
  {
    auto html = parseRoute(filePath);
    if (!html.isException)
      ctx.response.writeBodyString(html.output, "text/html");
    else
      ctx.response.setStatus(HttpStatus.INTERNAL_SERVER_ERROR)
        .writeBodyString(error_template(html.output), "text/html");
  }
  else
  {
    ctx.response.setStatus(HttpStatus.NOT_FOUND);
    ctx.response.writeBodyString = "404 Not Found";
  }
}

string error_template(string msg)
{
  return `
  <!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Error</title>
    <style>
        html,body{
            background-color: rgb(1, 2, 10);
            color: white;
            display: flex;
            justify-content: center;
            /* align-items: center; */
            font-family: 'Lucida Sans', 'Lucida Sans Regular', 'Lucida Grande', 
            'Lucida Sans Unicode', Geneva, Verdana, sans-serif;
        }
        .error_container{
            width: 90vw;
            padding: 20px;
            margin-top: 5%;
            border: 1px solid rgb(34, 34, 54);
            border-radius: 20px;
            color: tomato;
        }
    </style>
</head>

<body>
    <div class="error_container">
        <h3>Error:</h3>
        <code>`
    ~ msg ~ `</code>
    </div>
</body>

</html>`;
}
