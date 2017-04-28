# Enabling OpenWhisk Swift3 Action to use REPL PLayground

## Test

```
./build.sh
./run.sh
```

Then inside container run basic test

```
time /usr/bin/swift /share/test0.swift
Hello World
```


and using dynamic library inside REPL calling SwiftyJSON:

```
time swift -I/swift3Action/spm-build/.build/debug -L /swift3Action/spm-build/.build/debug -lSwiftyJSON /share/test1.swift
Hello Joe Doe
```

## Current issues - unable to build dynamic version of OpenSSL library

Unable to build OpenSSL - to reproduce install editor

```
apt-get -y install nano emacs
```

Modify Package.swift

```
cd /swift3Action/spm-build/
emacs Packages/OpenSSL-0.2.2/Package.swift
```

to add

```
products.append(Product(name: "OpenSSL", type: .Library(.Dynamic), modules: "openssl"))
```

and then run

```
root@87f331718d1e:/swift3Action/spm-build# swift build
error: the product named OpenSSL references a module that could not be found: openssl
fix: reference only valid modules from the product
```


Using

```
products.append(Product(name: "OpenSSL", type: .Library(.Dynamic), modules: "OpenSSL"))
```

leads to

```
root@87f331718d1e:/swift3Action/spm-build# swift build
Linking ./.build/debug/libOpenSSL.so
<unknown>:0: error: no input files
<unknown>:0: error: build had 1 command failures
error: exit(1): /usr/bin/swift-build-tool -f /swift3Action/spm-build/.build/debug.yaml
```


Optimally this should work ...

```
time swift -I/swift3Action/spm-build/.build/debug -L /swift3Action/spm-build/.build/debug -lSwiftyJSON -lOpenSSL /share/test2.swift
<unknown>:0: error: missing required module 'OpenSSL'
``` 
