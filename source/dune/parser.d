module dune.parser;

import std.json;
import std.stdio : File, writeln;
import std.array : empty, Appender;
import std.conv : to;
import std.path : buildPath;
import std.string : replace;
import std.regex : ctRegex, regex, replaceAll;
import std.file : read, readText, exists;

import argparse;
import html.dom;
import html : createDocument, Document;

import dune.qjs.bindings.context;
import dune.qjs.bindings.runtime;
import dune.qjs.bindings.func;
import dune.logger_provider;
import std.bitmanip;

@Command("init")
struct Init
{
    @PositionalArgument(0)
    string name;
}

@Command("start")
struct Start
{
    @NamedArgument("port")
    ushort port;
    @Optional
    @NamedArgument("log-level")
    string lgLevel;

    @Optional
    @NamedArgument("log-path")
    string logPath;
}

@Command("build")
struct Build
{
    @Optional
    string path;
}

@NamedArgument("preview")
struct Preview
{
}

struct TemplateException
{
    string message;
    string filename;
    int line;
    int column;
    string source;
    string stack;
}

struct HtmlResult
{
    string html;
    TemplateException* exception;
}

HtmlResult* parseRoute(string path, string content = null)
{
    TemplateException* exception = new TemplateException;
    try
    {
        string unHtml = content !is null ? content : path.readText;
        Document dom = createDocument(unHtml);
        Node _body = dom.querySelector("body");
        if (_body !is null)
        {
            foreach (key; _body.children)
            {
                if (key.isCommentNode)
                    key.destroy();
            }
        }
        string resu = executeScript(path, dom);
        auto includes = dom.querySelectorAll("include");
        if (includes.empty)
            return null;
        foreach (Node include; includes)
        {
            string filename = cast(string) include["src"];
            auto includePath = filename.buildPath;
            debug
            {
                includePath = "a".buildPath(filename);
            }

            if (includePath.exists)
            {
                string includeContent = cast(string) includePath.read;
                if (include.isElementNode)
                {
                    auto result = parseRoute(includePath, includeContent);
                    if (result is null)
                        break;
                    // dom = createDocument(dom.toString().replace(include.outerHTML, ));
                }
            }
            else
            {
                exception = new TemplateException;
                exception.message = "File not found";
                exception.filename = includePath;
                exception.source = include.toString;
            }
        }

        auto rexp = regex(`<\/?root>`);
        string html = dom.toString();
        html = replaceAll(html, rexp, "");
        HtmlResult* r = new HtmlResult(html, exception);
        return r;

    }
    catch (Exception e)
    {
        debug
        {
            import std.stdio : writeln;

            writeln(e);
        }
        Log.logError("Error while parsing");
        HtmlResult* r = new HtmlResult("", exception);
        return r;
    }
}

string executeScript(string path, Document dom)
{
    // Execute scripts
    auto scripts = dom.querySelectorAll("script[type='text/qjs']");
    if (scripts.empty)
        return null;
    foreach (script; scripts)
    {
        if (!script["src"].empty)
        {
            JsRuntime runtime = new JsRuntime();
            JsContext* context = new JsContext(runtime);
            string filename = cast(string) script["src"];
            auto scriptPath = filename.buildPath;
            debug
            {
                scriptPath = buildPath(filename.replace("..", "./a"));
            }
            string scr = cast(string) scriptPath.read;
            jsEval(context, scr, JS_EVAL_TYPE_GLOBAL, "");
            JSONValue globalJson = parseJSON(context.global.toString);
            foreach (key, value; globalJson.object)
            {
                dom = createDocument(dom.toString().replace('{' ~ key ~ '}', value.toString.replace('"', "")));
            }
        }
    }
    import std.regex : matchAll, regex, replaceAll;
    import std.array : array;

    auto rexpSick = regex(`\{[a-zA-Z_$][\w$]*\}`);
    auto sickVars = dom.root.text.matchAll(rexpSick);
    if (!sickVars.empty)
    {
        string msg = "";
        foreach (key; sickVars)
        {
            logLine(path, key.to!string);
            msg ~= "variable " ~ key[0] ~ " is not defined or not available globally \n";
            Log.logError(msg);
        }
        return null;
    }
    return dom.toString;
}

void logLine(string filename, string keyword)
{
    import std.array : array;

    auto lines = File(filename).byLine();
    int lineNumber = 0;
    int position = 0;
    foreach (line; lines)
    {
        line.writeln;
        // auto pos = line
        // if (pos != -1)
        // {
        //     writeln("Found '", keyword, "' at line ", index + 1, ", column ", pos + 1);
        // }
    }
}
