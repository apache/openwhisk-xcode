# WhiskSwiftTools
A collection of tools to help developers use OpenWhisk on OS X.  Implemented in Swift 3 because Swift 3.

More documentation coming soon!

## Features

### wsktool  
A CLI tool that allows developers to install OpenWhisk "projects" into the OpenWhisk backend.  A project contains sets of actions (JS and Swift), triggers, and rules which can be installed with a single command `wsktool install`.  You can do the opposite with `wsktool uninstall`.  You can see an [example of an OpenWhisk project here](https://github.com/openwhisk/openwhisk-package-jira/tree/master/src).

Documentation on the structure of an OpenWhisk project is coming soon.  

`wsktool` supports referencing dependencies on OpenWhisk projects in Github.  It will automatically download, bind, and install these with the main project.

### WhiskKit
A Swift 3 set of protocols and classes that lets you implement actions in Xcode.  Provides an Xcode to OpenWhisk bridge via wsktool that allows you to directly install Xcode-based OpenWhisk actions into OpenWhisk.

## Building
This code is build using Xcode 8 Beta 2 and is compatible with Swift 3 Tech Preview 2.  

There is a dependency on an ObjC project [ZipArchive](https://github.com/ZipArchive/ZipArchive).  OS X CLI targets and frameworks don't play together very well. The "easiest" way to reference it is to add the code manually to WhiskSwiftTools.  Clone ZipArchive and install per the documentations on the ZipArchive readme. Copy the SSZipArchive folder into the project folder and link to the `libz` library. WhiskSwiftTools includes bridging header file you can reference.

## Using
wsktool looks for a property file ~/.wskprops to get your OpenWhisk credentials and namespace.  You get this when you install the [OpenWhisk CLI](https://new-console.ng.bluemix.net/openwhisk/cli), or you can create it yourself.  It looks like this:

```
APIHOST=openwhisk.ng.bluemix.net
NAMESPACE=<whatever namespace you are using>
AUTH=<auth token from openwhisk>
```

### License

Copyright 2015-2016 IBM Corporation

Licensed under the [Apache License, Version 2.0 (the "License")](http://www.apache.org/licenses/LICENSE-2.0.html).

Unless required by applicable law or agreed to in writing, software distributed under the license is distributed on an "as is" basis, without warranties or conditions of any kind, either express or implied. See the license for the specific language governing permissions and limitations under the license.
