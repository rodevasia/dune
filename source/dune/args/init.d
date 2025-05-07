module dune.args.init;

import std.stdio : write,writeln, readln;
alias display= write;
import std.file : exists, mkdir, mkdirRecurse, rmdirRecurse, write;
import std.path : buildPath;

import dune.parser;

void initFn(Init args)
{

    if (exists(args.name))
    {
        "Directory already exists".writeln;
        "Do you want to delete and create new (Y/n) : ".display;
        auto choice = readln();
        import std.string : toLower, strip;

        if (choice.toLower().strip() == "y")
        {
            args.name.rmdirRecurse;
            createProject(args);
        }
        else
        {
            return;
        }
    }
    else
    {
        if(args.name.length){
            createProject(args);
        }else{
            "Please provide a valid project name".writeln;
            return;
        }
    }
}

private void createProject(Init args)
{
    args.name.mkdir;
    assert(args.name.exists);
    foreach (dir; ["routes", "assets"])
    {
        auto path = args.name.buildPath(dir);
        path.mkdirRecurse;
        assert(path.exists);
    }
    auto mainRoute = args.name.buildPath("routes", "index.html");
    foreach (assetDir, asset; [
            "scripts": ["main.js", "const title=`Document`;"],
            "styles": ["index.css"]
        ])
    {
        auto p = args.name.buildPath("assets", assetDir);
        p.mkdirRecurse;
        assert(p.exists);
        if (asset.length > 1)
        {
            auto assetPath = p.buildPath(asset[0]);
            assetPath.write(asset[1]);
        }
        else
        {
            auto assetPath = p.buildPath(asset[0]);
            assetPath.write("");
        }
    }
    enum templateHtml = q{
<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <link rel="stylesheet" href="../assets/styles/index.css">
    <link rel="apple-touch-icon" href="favicon.png">
    <script type="text/qjs" src="../assets/scripts/main.js"></script>
    <title>{title}</title>
</head>

<body>

    
</body>

</html>   };
    mainRoute.write(templateHtml);

}
