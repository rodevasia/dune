module dune.qjs.bindings.context;

import std.string : toStringz;

import dune.qjs.bindings.runtime;
import dune.qjs.qjs_c;

import dune.qjs.fetch;
import dune.qjs.bindings.func;
import std.process;

struct JsContext
{
    private JSContext* context;
    private JsRuntime runtime;
    this(JsRuntime runtime)
    {
        js_std_init_handlers(runtime.get);
        context = JS_NewContext(runtime.get);
        js_std_add_helpers(context, 0, null);
        js_add_fetch(&this);
        this.runtime = runtime;
    }

    ~this()
    {
        import std.stdio;

        if (context !is null)
        {
            js_std_free_handlers(runtime.get);
            JS_RunGC(runtime.get);
            JS_FreeContext(context);
            JS_FreeRuntime(runtime.get);
        }
    }

    @property JSContext* get() @safe => context;
    @property JsValue global() =>  JsValue(&this, JS_GetGlobalObject(context));
    @property JsValue* getProperty(string p) =>
        new JsValue(&this, JS_GetPropertyStr(context, this.global.cptr, p.toStringz()));
    @property JsValue* getProperty(JsValue obj, string p) =>
        new JsValue(&this, JS_GetPropertyStr(context, obj.cptr, p.toStringz()));
}
