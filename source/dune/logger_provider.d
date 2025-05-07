module dune.logger_provider;

import slf4d, slf4d.provider, slf4d.writer, slf4d.default_provider, slf4d
    .default_provider.formatters;

import std.conv : to;

class CustomProvider : LoggingProvider
{
    Levels logLevel;
    string logpath;
    LoggerFactory loggerFactory;

    this(Levels logLevel, string logpath = null, bool shortMode = false)
    {
        this.logLevel = logLevel;
        LogHandler[] handlers = [new CustomLogHandler(shortMode)];
        if (logpath !is null && logpath.length > 0)
        {
            handlers ~= new SerializingLogHandler(
                new DefaultStringLogSerializer(false),
                new RotatingFileLogWriter(logpath)
            );
        }
        auto baseHandler = new MultiLogHandler(handlers);
        this.loggerFactory = new DefaultLoggerFactory(baseHandler, logLevel);
    }

    LoggerFactory getLoggerFactory()
    {
        return this.loggerFactory;
    }
}

class CustomLogHandler : LogHandler
{
    private bool shortMode;
    this(bool shortMode = false)
    {
        shortMode = shortMode;
    }

    void handle(immutable LogMessage msg)
    {
        import std.stdio : writeln;

        if (!shortMode)
        {

            writeln(msg.sourceContext.moduleName ~ "(" ~ msg.sourceContext.lineNumber.to!string ~ "):" ~ formatLogLevel(
                    msg.level, true) ~ ": " ~ msg
                    .message);
        }
        else
        {
            writeln(formatLogLevel(msg.level, true) ~ ": " ~ msg
                    .message);
        }
    }
}

struct Log
{

    static void config(bool shortMode = false, string filepath = null)
    {
        auto custom = new CustomProvider(Levels.TRACE, filepath, shortMode);
        configureLoggingProvider(custom);
    }

    alias logInfo = info;
    alias logError = error;
    alias logWarn = warn;
}
