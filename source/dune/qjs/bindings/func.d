module dune.qjs.bindings.func;

import dune.qjs.qjs_c;
import dune.qjs.bindings.context;
import dune.qjs.bindings.runtime;
import std.stdio;
import std.conv : to;

enum JS_Tag : int
{

    /* all tags with a reference count are negative */
    FIRST = -11, /* first negative tag */
    BIG_DECIMAL = -11,
    BIG_INT = -10,
    BIG_FLOAT = -9,
    SYMBOL = -8,
    STRING = -7,
    MODULE = -3, /* used internally */
    FUNCTION_BYTECODE = -2, /* used internally */
    OBJECT = -1,

    INT = 0,
    BOOL = 1,
    NULL = 2,
    UNDEFINED = 3,
    UNINITIALIZED = 4,
    CATCH_OFFSET = 5,
    EXCEPTION = 6,
    FLOAT64 = 7, /* any larger tag is FLOAT64 if JS_NAN_BOXING */



}

enum JS_EVAL_TYPE_GLOBAL = (0 << 0); // global code (default)
enum JS_EVAL_TYPE_MODULE = (1 << 0); // module code
enum JS_EVAL_TYPE_DIRECT = (2 << 0); // direct call (internal use)
enum JS_EVAL_TYPE_INDIRECT = (3 << 0); // indirect call (internal use)
enum JS_EVAL_TYPE_MASK = (3 << 0);

enum JS_EVAL_FLAG_STRICT = (1 << 3); // force 'strict' mode
enum JS_EVAL_FLAG_COMPILE_ONLY = (1 << 5); // compile but do not run
enum JS_EVAL_FLAG_BACKTRACE_BARRIER = (1 << 6); // omit previous stack frames
enum JS_EVAL_FLAG_ASYNC = (1 << 7); // allow top-level await

struct JsValue
{
    JSValueUnion u;
    JS_Tag tag;
    private JSValue v;
    private JsContext* ctx;

    this(JsContext* ctx, JSValue v)
    {
        u = v.u;
        tag = parseJSTag(v.tag);
        this.v = v;
        this.ctx = ctx;
    }

    ~this()
    {
        import std.string;

        // if (tag == JS_Tag.STRING
        //     || tag == JS_Tag.SYMBOL
        //     || tag == JS_Tag.OBJECT
        //     || tag == JS_Tag.MODULE
        //     || tag == JS_Tag.FUNCTION_BYTECODE
        //     || tag == JS_Tag.BIG_DECIMAL
        //     || tag == JS_Tag.BIG_INT
        //     || tag == JS_Tag.BIG_FLOAT)
        // {
        //     // JS_FreeValue(ctx.get, v);
        // }

        bool hasRefCount = v.tag >= JS_Tag.FIRST;
        if (hasRefCount)
        {
            JSRefCountHeader* p = cast(JSRefCountHeader*)v.u.ptr;
            if (--p.ref_count <= 0)
            {
                __JS_FreeValue(ctx.get, v);
            }
        }
    }

    @property JSValue cptr() => v;
    @property bool isException() => tag == JS_Tag.EXCEPTION;

    private JS_Tag parseJSTag(long tagValue)
    {
        switch (tagValue)
        {
        case -11:
            return JS_Tag.BIG_DECIMAL;
        case -10:
            return JS_Tag.BIG_INT;
        case -9:
            return JS_Tag.BIG_FLOAT;
        case -8:
            return JS_Tag.SYMBOL;
        case -7:
            return JS_Tag.STRING;
        case -3:
            return JS_Tag.MODULE;
        case -2:
            return JS_Tag.FUNCTION_BYTECODE;
        case -1:
            return JS_Tag.OBJECT;
        case 0:
            return JS_Tag.INT;
        case 1:
            return JS_Tag.BOOL;
        case 2:
            return JS_Tag.NULL;
        case 3:
            return JS_Tag.UNDEFINED;
        case 4:
            return JS_Tag.UNINITIALIZED;
        case 5:
            return JS_Tag.CATCH_OFFSET;
        case 6:
            return JS_Tag.EXCEPTION;
        case 7:
            return JS_Tag.FLOAT64;
        default:
            {
                import std.conv : to;

                throw new Exception("Unknown JS_Tag: " ~ tagValue.to!string);
            }
        }
    }

    string toString()
    {
        import std.conv : to;

        switch (tag)
        {
        case JS_Tag.STRING:
            return fromJsCString(ctx, &this).to!string;
            break;
        case JS_Tag.INT:
            int a = jsToInt(ctx, &this);
            return a.to!string;
            break;
        case JS_Tag.BIG_INT:
            long b = jsToLong(ctx, &this);
            return b.to!string;
            break;
        case JS_Tag.BIG_FLOAT:
        case JS_Tag.FLOAT64:
            double c = jsToDouble(ctx, &this);
            return c.to!string;
            break;
        case JS_Tag.BOOL:
            return jsToBool(ctx, &this).to!string;
            break;
        case JS_Tag.OBJECT:
            JSValue undefined = JSValue(JSValueUnion.init, JS_Tag.UNDEFINED);
            JsValue* JsUndefined = new JsValue(ctx, undefined);
            return jsJSONStringify(ctx, &this, JsUndefined, JsUndefined);
            break;
        default:
            return null;
        }

    }
}

JsValue* jsEval(JsContext* ctx, string input, int eval_flags = JS_EVAL_TYPE_GLOBAL, string filename)
{
    try
    {
        import std.string : toStringz;

        const(char)* inputStr = input.toStringz();
        const(char)* filenameStr = filename.toStringz();
        // Implement convertion of JS_Eval to corresponding data type
        JsValue* val = new JsValue(ctx, JS_Eval(ctx.get, inputStr, input.length, filenameStr, eval_flags));
        if (val.isException)
        {
            string except = getException(ctx);
            throw new Exception("Exception in script:" ~ input ~ " " ~ except);
        }
        return val;
    }
    catch (Exception e)
    {
        writeln(e);
        return null;
    }
}

string fromJsCString(JsContext* ctx, JsValue* jv) => JS_ToCStringLen2(ctx.get, null, jv.v, 0)
    .to!string;

string jsToString(JsContext* ctx, JsValue* val) => JS_ToString(ctx.get, val.v).to!string;

int jsToInt(JsContext* ctx, JsValue* val)
{
    int result;
    int s = JS_ToInt32(ctx.get, &result, val.v);
    if (s is 0)
    {
        return result;
    }
    else
    {
        throw new Exception("Failed to convert to int");
    }
}

long jsToLong(JsContext* ctx, JsValue* val)
{
    long result;
    int s = JS_ToInt64(ctx.get, &result, val.v);

    if (s is 0)
    {
        return result;
    }
    else
    {
        throw new Exception("Failed to convert to long");
    }
}

double jsToDouble(JsContext* ctx, JsValue* val)
{
    double result;
    int s = JS_ToFloat64(ctx.get, &result, val.v);
    if (s is 0)
    {
        return result;
    }
    else
    {
        throw new Exception("Failed to convert to double");
    }
}

string getException(JsContext* ctx)
{
    auto e = new JsValue(ctx, JS_GetException(ctx.get));
    return fromJsCString(ctx, e);
}

string jsJSONStringify(JsContext* ctx, JsValue* value, JsValue* replacer, JsValue* space)
{
    JSValue v = JS_JSONStringify(ctx.get, value.v, replacer.v, space.v);
    // ctx.freeValue(v);
    JsValue* val = new JsValue(ctx, v);
    if (val.isException())
    {
        string except = getException(ctx);
        throw new Exception("Exception in script:" ~ except);
    }
    return val.toString;
}

bool jsToBool(JsContext* ctx, JsValue* val)
{
    return jsToInt(ctx, val) is 1;
}
