module dune.args.build;

import std.file : write, mkdirRecurse, exists, dirEntries, SpanMode;
import std.path;
import std.compiler;
import std.stdio;
import std.string;
import std.conv : to;

import dune.parser;
import dune.logger_provider;

void buildFn(Build args)
{
    Log.config();
    string[] bp = args.path !is null ? args.path.split('/') : ["dist"];
    debug
    {
        bp = "a" ~ bp;
    }
    auto bPath = bp.buildPath;
    bPath.mkdirRecurse;
    assert(bPath.exists);
    string routesPath = "routes";
    debug
    {
        routesPath = "a/" ~ routesPath;
    }

    foreach (key; dirEntries(routesPath, SpanMode.depth))
    {
        auto r = parseRoute(key.name.buildPath);
        if (r !is null)
        {
            string fileName = key.name.split("/")[$ - 1];
            auto finalFile = bPath.buildPath(fileName);
            finalFile.write(r);
        }

    }
}
