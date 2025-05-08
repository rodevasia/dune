#### Commands

##### Init

Commad : `dune init`
Usage :

```bash
dune init [-h] name

Required arguments:
  name
```

This will creates a new project directory.

##### Start

Usage: `dune start [--port PORT] [--log-level LGLEVEL] [--log-path LOGPATH] [-h]`

Optional arguments:
--port PORT default is 8080
--log-level debug,info,warn,error <i>Filters errors based on the level debug traces all info</i>
--log-path <i>Log file path</i>

##### Build

This will generate the output html
Usage: `dune build [--path PATH] [-h]`

Optional arguments:
--path PATH <i>destination path for built files</i>


#### Getting Started

 - Creating Project
    `dune init mywebsite && cd mywebsite`
This will generate our project and now the folder structor will be as below showcased:
```.
├── assets
│   ├── scripts
│   │   └── main.js
│   └── styles
│       └── index.css
└── routes
    └── index.html
```
Now lets run it by:
`dune start --port=4500`
You will see an empty page in browser if you open http://127.0.0.1:4500.
- Importing html file
you can use `<include src="<source>" ></include>` tag for importing html files.

Lets create a folder called `src` in the project.
Add an html page inside `src` called `navigation.html`.
```html
<header>
    <h1>My Website</h1>
    <nav>
      <a href="/">Home</a>
      <a href="/about">About</a>
      <a href="/services">Services</a>
      <a href="/contact">Contact</a>
    </nav>
  </header>
  
```
copy and paste the code to `navigation.html`.

In `index.html` import the navigation html file by
```html
... 
<body>
  <include src="src/navigation.html"></include>
...
```
If you reload the browser you will now see the page with navigation.

- dynamic variables
```html
index.html
....
<script type="text/qjs" src="assets/scripts/age.js" ></script>
....
<p> Age: {age}
```
```js
globalThis.age=0;
function someExecution(){
  globalThis.age=20;
}
someExecution();
```
In this example, once the page is compiled the value will be `<p> Age: 20 </p>`.
make sure the type is `text/qjs`. Normal js will be executed in the browser file qjs scripts will executed during compile time.
The server side script is very limited as for now only basic javascript properties are available. you can use `network.get` for fetch like property only for GET method. This method is synchronous, so compilation time depends on network capability as well, if you use this function.