# WhiskSwiftTools
A collection of tools to help developers use OpenWhisk on OS X.  Implemented in Swift 3 because Swift 3.

More documentation coming soon!

## Features

### wsktool  
A CLI tool that allows developers to install OpenWhisk "projects" into the OpenWhisk backend.  A project contains sets of actions (JS and Swift), triggers, and rules which can be installed with a single command `wsktool install`.  You can do the opposite with `wsktool uninstall`.  You can see an [example of an OpenWhisk project here](https://github.com/openwhisk/openwhisk-package-jira/tree/master/src).

#### wsktool Project Structure
`wsktool` looks installs code based on the following project structure.  

```
_ Ignored files
- src
   |_ root-manifest.json
   |_ source_code.js                  // JS action in default package and namespace
   |_ action_source_code.swift        // Swift action in default package and namespace
   |_ mypackage1                      // package
          |_mypackage1-manifest.json  // Package specific settings
          |_source_code.js
   |_ mypackage2
          |_source_code.swift
          
```

`wsktool` looks for a `src` directory in the project home. It will walk this directory and install/delete OpenWhisk actions, triggers, and rules using the following conventions:

* Actions will be installed for each source code file under src using the filename as the action name.  The file extension indicate the desired runtime.
* Source code directly underneath src are installed without specifying a namespace or package
* Directories underneath src indicate packages.  The package name is the directory name
* Source code inside package directories are installed as members of the package
* The `root-manifest.json` contains definitions for triggers, rules, sequences, action parameters, and special runtime settings, e.g. Swift3 instead of Swift 2.
* You can also declare dependencies on other OpenWhisk packages installed in GitHub in the `root-manifest.json`. `wsktool` will automatically download, bind, and install these with the main project. 
* The `<package-name>-manifest.json` contains package specific settings for actions.  Settings here will override settings in `root-manifest.json`.
  
### WhiskKit
A Swift 3 set of protocols and classes that lets you implement actions in Xcode.  WhiskKit provides an Xcode to OpenWhisk bridge via `wsktool` that allows you to directly install WhiskKit actions into OpenWhisk.  To access the bridge, add dependency to the `root-manifest.json` where the `src` directory contains an Xcode project.  `wsktool` will search the project for Swift 3 actions.

## Building
This code is build using Xcode 8 Beta 3.  

There is a dependency on an ObjC project [ZipArchive](https://github.com/ZipArchive/ZipArchive).  OS X CLI targets and frameworks don't play together very well. The "easiest" way to reference it is to add the code manually to WhiskSwiftTools.  Clone ZipArchive and install per the documentations on the ZipArchive readme. Copy the SSZipArchive folder into the project folder and link to the `libz` library. WhiskSwiftTools includes bridging header file you can reference.

## Using

Run `wsktool` from the command line. `wsktool install` will install the OpenWhisk project from the current directory. You can also specify the directory with `wsktool install <project directory>`.  To activate the Xcode bridge, run `wsktool` in the root directory of an Xcode project where the project (*.xcodeproj) file is located, or add an Xcode project as a depedency in the `root-manifest.json` file.  We have an [example of an Xcode dependency](https://github.com/paulcastro/SwiftDummy).

`wsktool` looks for a property file ~/.wskprops to get your OpenWhisk credentials and namespace.  You get this when you install the [OpenWhisk CLI](https://new-console.ng.bluemix.net/openwhisk/cli), or you can create it yourself.  It looks like this:

```
APIHOST=openwhisk.ng.bluemix.net
NAMESPACE=<whatever namespace you are using>
AUTH=<auth token from openwhisk>
```

#### Xcode Integration
You can add wsktool to the build pipeline of Xcode by [adding a "Run Script" phase](https://developer.apple.com/library/ios/recipes/xcode_help-project_editor/Articles/AddingaRunScriptBuildPhase.html) to your project's build phases.  Create a Run Script, then add the following line:

```
/path/to/wsktool install $PROJECT_DIR
```
where `path/to/wsktool` is the location where you installed the `wsktool` binary. This will run wsktool every time you build your project and automatically upload actions to OpenWhisk.

### License

Copyright 2015-2016 IBM Corporation

Licensed under the [Apache License, Version 2.0 (the "License")](http://www.apache.org/licenses/LICENSE-2.0.html).

Unless required by applicable law or agreed to in writing, software distributed under the license is distributed on an "as is" basis, without warranties or conditions of any kind, either express or implied. See the license for the specific language governing permissions and limitations under the license.
