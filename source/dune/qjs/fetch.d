module dune.qjs.fetch;
import dune.qjs.qjs_c;
import std.string, std.stdio;
import std.net.curl : get;
import std.conv : to;
import dune.qjs.bindings.context;

//  replica of js fetch get
extern (C) JSValue js_fetch_get(JSContext* ctx, JSValueConst this_val, int argc, JSValueConst* argv)
{
    if (argc < 1)
    {
        return JS_ThrowTypeError(ctx, "fetch requires URL");
    }
    const(char)* jsUrlString = JS_ToCStringLen2(ctx, null, argv[0], 0);
    string urlString = jsUrlString.to!string;
    JS_FreeCString(ctx, jsUrlString);
    if (urlString is null)
        return JS_NewError(ctx);

    string resp;
    try
    {
        resp = get(urlString).to!string;
    }
    catch (Exception e)
    {
        debug
        {
            import std.stdio : writeln;

            try
            {
                writeln(e);
            }
            catch (Exception)
            {
            }
        }
        return JS_ThrowInternalError(ctx, "httpGet failed: %s", e.msg.ptr);
    }
    return JS_NewStringLen(ctx, resp.toStringz(),resp.length);
}

void js_add_fetch(JsContext* ctx)
{
    try
    {
        JSValue cFunValue = JS_NewCFunction2(ctx.get, &js_fetch_get, "get", 0, JSCFunctionEnum.JS_CFUNC_generic, 0);
        JSValue newtworkObj = JS_NewObject(ctx.get);
        JS_SetPropertyStr(ctx.get, newtworkObj, "get", cFunValue);
        JS_SetPropertyStr(ctx.get, ctx.global.cptr, "network", newtworkObj);
    }
    catch (Exception e)
    {
        debug
        {
            import std.stdio : writeln;

            writeln(e);
        }
    }
}
