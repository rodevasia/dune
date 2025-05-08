## Dune
A simple static HTML page generator with quick-js

#### Installation
- ##### Option 1 (Binary)
    Install the app you can download the binary (Linux) from the releases. 
- ##### Option 2 (DUB)
    Install using command:
    `dub run dune`
    this will ask you to fetch the code for first time running.
    If you want to directly run add the execute path to $PATH (Nix) or Environment Variable ( Win)
    then run `dune <options>`
- ##### Option 3 (Git)
```bash
git clone git@github.com:rodevasia/dune.git
cd dune && ./install.sh
```

NOTE: For Option 2 and 3 you must have installed `dmd` or `ldc` and [quickjs](https://github.com/bellard/quickjs/) with this [commit](https://github.com/bellard/quickjs/commit/a8b2d7c2b2751130000b74ac7d831fd75a0abbc3)
