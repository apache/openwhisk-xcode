# WhiskSwiftTools
A collection of tools to help developers use OpenWhisk on OS X.

More documentation coming soon!

## Features

### wsktool  
A small CLI tool that allows developers to create and install OpenWhisk "projects" containing sets of actions (JS and Swift), triggers, and rules with a single command `wsktool install`.  You can do the opposite with `wsktool uninstall`. 

### WhiskKit
A Swift 3 set of protocols and classes that lets you implement actions in Xcode.  Provides an Xcode to OpenWhisk bridge via wsktool that allows you to directly install Xcode-based OpenWhisk actions into OpenWhisk.

## Building
This code is built using the Xcode 8 beta 2 with the Swift 3 tech preview 2 toolchain.  

There is a dependency on an ObjC project [ZipArchive](https://github.com/ZipArchive/ZipArchive).  OS X CLI targets and frameworks don't play together very well. The "easiest" way to reference it is to add the code manually to WhiskSwiftTools.  Clone ZipArchive and install per the documentations on the ZipArchive readme. Copy the SSZipArchive folder into the project folder and link to the libz library. WhiskSwiftTOols includes bridging header file you can reference.
