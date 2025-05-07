module dune.logger_provider;

import slf4d, slf4d.provider, slf4d.writer, slf4d.default_provider, slf4d
    .default_provider.formatters;

class CustomProvider : LoggingProvider
{
    Levels logLevel;
    string logpath;
    LoggerFactory loggerFactory;

    this(Levels logLevel, string logpath = null, bool shortMode = false)
    {
        this.logLevel = logLevel;
        LogHandler[] handlers = [new CustomLogHandler()];
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
            writeln(formatLogLevel(msg.level, true) ~ " (" ~ msg.sourceContext.moduleName ~ ")" ~ ": " ~ msg
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
    this(bool shortMode)
    {
        auto custom = new CustomProvider(Levels.TRACE);
        configureLoggingProvider(custom);
    }

    alias logInfo = info;
    alias logError = error;
    alias logWarn = warn;
}
