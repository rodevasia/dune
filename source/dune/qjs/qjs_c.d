module dune.qjs.qjs_c;

import core.stdc.stdint;

extern (C) nothrow @nogc
{

    union JSValueUnion
    {
        int int32;
        double float64;
        void* ptr;
        // For big integer, depending on platform (this is for 64-bit platforms)
        long short_big_int;
    }

    // Struct for JSValue, which contains a JSValueUnion and a tag
    struct JSValue
    {
        JSValueUnion u;
        ulong tag;
    }

    struct JSContext;
    struct JSMallocFunctions;
    struct JSMallocState;
    struct JSAtom;
    struct list_head;
    struct JSClass;
    struct JSRuntime;

    enum JSCFunctionEnum
    {
        JS_CFUNC_generic,
        JS_CFUNC_generic_magic,
        JS_CFUNC_constructor,
        JS_CFUNC_constructor_magic,
        JS_CFUNC_constructor_or_func,
        JS_CFUNC_constructor_or_func_magic,
        JS_CFUNC_f_f,
        JS_CFUNC_f_f_f,
        JS_CFUNC_getter,
        JS_CFUNC_setter,
        JS_CFUNC_getter_magic,
        JS_CFUNC_setter_magic,
        JS_CFUNC_iterator_next,
    }

    // dscanner:disable
    JSContext* JS_NewContext(JSRuntime* runtime);
    JSRuntime* JS_NewRuntime();
    JSValue JS_Eval(JSContext* ctx, const char* input, size_t input_len,
        const char* filename, int eval_flags);
    JSValue JS_GetGlobalObject(JSContext* ctx);
    JSValue JS_GetPropertyStr(JSContext* ctx, JSValue this_obj, const(char)* prop);
    JSValue JS_ToString(JSContext* ctx, JSValueConst val);
    const(char)* JS_ToCStringLen2(JSContext* ctx, size_t* plen, JSValueConst val, int cesu8);
    void JS_FreeContext(JSContext* ctx);
    void JS_FreeRuntime(JSRuntime* runtime);
    alias JSValueConst = const(JSValue);
    void JS_FreeCString(JSContext* ctx, const(char)* ptr);
    void __JS_FreeValue(JSContext* ctx, JSValue val);
    struct JSRefCountHeader
    {
        int ref_count;
    }

    // int JS_VALUE_GET_TAG(ref JSValue v) =>  cast(int)(cast(size_t)(v)&0xf)
    void __JS_FreeValueRT(JSRuntime* rt, JSValue val);
    JS_BOOL JS_IsError(JSContext* ctx, JSValueConst val);
    JSValue JS_GetException(JSContext* ctx);
    alias JS_FreeValueRT = __JS_FreeValueRT;
    alias JS_BOOL = int;
    void JS_RunGC(JSRuntime* rt);
    JSRuntime* JS_GetRuntime(JSContext* ctx);
    int JS_ToInt32(JSContext* ctx, int* pres, JSValueConst val);
    int JS_ToInt64(JSContext* ctx, long* pres, JSValueConst val);
    int JS_ToFloat64(JSContext* ctx, double* pres, JSValueConst val);
    JSValue JS_JSONStringify(JSContext*, JSValueConst value, JSValueConst replacer, JSValueConst space);
    void js_std_dump_error(JSContext*);
    void js_std_init_handlers(JSRuntime*);
    void js_std_free_handlers(JSRuntime*);
    void js_std_add_helpers(const(JSContext*), int argc, char** argv);
    JSValue JS_NewStringLen(JSContext*, const(char)*, size_t l);
    JSValue JS_NewError(JSContext* ctx);
    JSValue JS_ThrowSyntaxError(JSContext* ctx, const char* fmt, ...);
    JSValue JS_ThrowTypeError(JSContext* ctx, const char* fmt, ...);
    JSValue JS_ThrowReferenceError(JSContext* ctx, const char* fmt, ...);
    JSValue JS_ThrowRangeError(JSContext* ctx, const char* fmt, ...);
    JSValue JS_ThrowInternalError(JSContext* ctx, const char* fmt, ...);
    int JS_SetPropertyUint32(JSContext* ctx, JSValueConst this_obj,
        ulong idx, JSValue val);
    int JS_SetPropertyInt64(JSContext* ctx, JSValueConst this_obj,
        long idx, JSValue val);
    int JS_SetPropertyStr(JSContext* ctx, JSValueConst this_obj,
        const char* prop, JSValue val);
    JSValue JS_NewCFunction2(JSContext* ctx, JSValue function(JSContext* ctx, JSValueConst this_val, int argc, JSValueConst* argv),
        const char* name,
        int length, JSCFunctionEnum cproto, int magic);
    JSValue JS_NewObject(JSContext* ctx);
}
