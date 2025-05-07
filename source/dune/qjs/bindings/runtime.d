module dune.qjs.bindings.runtime;
import dune.qjs.qjs_c : JSRuntime, JS_NewRuntime, JS_FreeRuntime, JS_RunGC;
import core.thread.osthread;
import core.time : seconds;
import std.stdio;

class JsRuntime
{
    private JSRuntime* runtime;

    this()
    {
        runtime = JS_NewRuntime();
    }

    JSRuntime* get() @safe
    {
        return runtime;
    }
}
