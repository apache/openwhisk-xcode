# OpenWhisk Xcode Extension
> An Xcode Extension to run Swift OpenWhisk Functions in Playgrounds


## Installation

## Usage Example

To invoke the extension, simply select the function header then run the extension.

![Highlighting function](/xcode-playgrounds-extension/Readme_Images/SelectFunction.png)

The extension can be found in the Editor Menu, under OWPlaygrounds.  
![Run Extension from Editor menu](/xcode-playgrounds-extension/Readme_Images/RunExtension.png)

The first time the extension is run, it will create documentation for the function to populate the test.  

#### Parameters
To input test values into the playground, the format `- paramName : description of parameter (optional) : param value for playground ` is used.  
The parser looks only for `- paramName : : value`.  The description is not necessary, but the colons (:) seperating the paramName : Description : and test value are.  

![Placeholders parameter example](/xcode-playgrounds-extension/Readme_Images/DocumentationPlaceholders.png)

If the extension does not find all of the  paramaters that are used in the function inside the documentation, it will recreate the documentation header.  

#### Expected Output (Optional)

The expected output part of the documentation is optional. The playground can be used as a unit tester if a value is provided inside the expected output.  To provide a value, type any valid json after the `--`.  If the json can be parsed, it will input it into the playground and check with the results recieved after running the function with the specified parameter values.

`Note -`  The ` - Returns:` documentation line is not read by the extension and has no impact on the playgrounds.  It is created for personal documentation use.

## Running the Playground

The second time the extension is run, it check the function for all of the parameters used with `args["param"]`.  If it finds all of the parameters used in the function inside the documentation header, it will then attempt to open the OpenWhisk Playgrounds app, which spins up a server for testing functions.  

When looking to open up the playground, the extension looks for an app called `openwhisk-playground-osx.app`.  If you do not have the playground app, you will need to install it (instructions in [Installation](https://github.ibm.com/Avery-Lamp/openwhisk-xcode#installation) above).  The playground app will run the server for testing functions in the background, while the extension will open up http://localhost:6018 with the correct parameters to test the function.

## Tips and Tricks

One way to easily improve the speed of invoking the extension is to create a shortcut for it.  To do this, open Xcode Preferences -> Key Bindings, then search for OWPlaygrounds.  You can create your own shortcut to invoke the action.






License

Copyright 2015-2016 IBM Corporation

Licensed under the Apache License, Version 2.0 (the "License").

Unless required by applicable law or agreed to in writing, software distributed under the license is distributed on an "as is" basis, without warranties or conditions of any kind, either express or implied. See the license for the specific language governing permissions and limitations under the license.

