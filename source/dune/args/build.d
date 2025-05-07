module dune.args.build;

import std.file;
import std.path;
import std.compiler;
import std.stdio;
import std.string;

import dune.parser;
import dune.logger_provider;

void buildFn(Build args)
{
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
        HtmlResult* r = parseRoute(key.name.buildPath);
        debug r.html.writeln;
        if (r.exception !is null)
        {
            Log.logError(r.exception.message, null, r.exception.filename);
            break;
        }
        debug "============================================".writeln;
    }
}
