module dune.parser;

import std.json;
import std.stdio : File, writeln;
import std.array : empty, Appender, split;
import std.conv : to;
import std.path : buildPath;
import std.string : replace, indexOf;
import std.regex : ctRegex, regex, replaceAll, matchAll;
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

// @NamedArgument("preview")
// struct Preview
// {
// }

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
    string output;
    bool isException = true;
}

HtmlResult parseRoute(string path, string content = null)
{

    try
    {
        HtmlResult _htmlResult = HtmlResult.init;
        string unHtml = content !is null ? content : path.readText;
        Document dom = createDocument(unHtml);
        foreach (key; dom.root.children)
        {
            if (key.isCommentNode)
                key.destroy();
        }

        string resu = executeScript(path, dom);
        if (resu !is null)
            dom = createDocument(resu);

        auto includes = dom.querySelectorAll("include");
        if (!includes.empty)
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
                        if (result.isException)
                        {
                            Log.logError("File " ~ includePath ~ " not found", null, path);
                            return result;
                        }
                        dom = createDocument(dom.toString()
                                .replace(include.outerHTML, result.output));
                    }
                }
                else
                {
                    return HtmlResult(path ~ ": File " ~ includePath ~ " not found");
                }
            }

        if (resu is null)
        {
            resu = executeScript(path, dom);
            if (resu !is null)
                dom = createDocument(resu);
        }
        auto rexpSick = regex(`\{[a-zA-Z_$][\w$]*\}`);
        auto sickVars = dom.root.text.matchAll(rexpSick);
        if (!sickVars.empty)
        {
            string msg = "";
            string exceptionMsg = "";
            foreach (key; sickVars)
            {
                auto lineNum = logLine(path, key.to!string);
                msg ~= "variable " ~ key[0] ~ " is not defined or not available globally \n";
                exceptionMsg ~= path ~ "(" ~ lineNum.to!string ~ "): " ~ msg ~ "\n";
                Log.logError(msg, null, path, null, null, lineNum);
            }
            _htmlResult.output = exceptionMsg;
            return _htmlResult;
        }

        auto rexp = regex(`<\/?root>`);
        string html = dom.toString();
        html = replaceAll(html, rexp, "");
        _htmlResult.output = html;
        _htmlResult.isException = false;
        return _htmlResult;

    }
    catch (Exception e)
    {
        debug
        {
            import std.stdio : writeln;

            writeln(e);
        }
        Log.logError("Error while parsing");
        return HtmlResult.init;
    }
}

string executeScript(string path, Document dom,)
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
    return dom.toString;
}

auto logLine(string filename, string keyword)
{
    import std.array : array;

    auto lines = File(filename).byLine();
    int lineNumber = 1;

    foreach (line; lines)
    {
        auto rgx = regex(`\{[a-zA-Z_$][\w$]*\}`);
        auto varMatch = line.matchAll(rgx);
        if (!varMatch.empty)
        {
            return lineNumber;
        }
        lineNumber++;
    }
    return -1;
}
