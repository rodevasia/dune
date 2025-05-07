
import std.sumtype : SumType, match;

import argparse;
import dune.parser;
import dune.args.init : initFn;
import dune.args.start;
import std;
import dune.args.build;

@Command("help")
struct NoValue
{
}

struct DuneArgs
{
  SumType!(NoValue, Init, Start, Build) command;
}

mixin CLI!DuneArgs.main!(parseArgs);

void parseArgs(DuneArgs args)
{
  args.command.match!(
    (NoValue val) { alias T = DuneArgs; CLI!T.parseArgs!((T t) {})(["-h"]); },
    (Init init) => initFn(init),
    (Start start) => startFn(start),
    (Build build) => buildFn(build),
    // (Preview preview) => previewFn(preview)
  );
}

// void previewFn(Preview args)
// {

// }
