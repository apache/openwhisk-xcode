#!/usr/bin/env python3
#
# Copyright 2015-2016 IBM Corporation
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#


import os
import re
import sys
import json

# 
# find all paclages
# add dylib statements cusotmized ot package name
# rebuild all packages

def procesPackageFile(packageName, path):
    stmt = '\n\nproducts.append(Product(name: "{packageName}", type: .Library(.Dynamic), modules: "{packageName}"))'.format(packageName=packageName)
    # only patch select packages
    if packageName == 'SwiftyJSON' :
        print(packageName, path, stmt)
        with open(path, "a") as myfile:
            myfile.write(stmt + '\n')



def main():
    print("hello friend")
    for root, dirs, files in os.walk("/swift3Action/spm-build/Packages/"):
        for f in files:
            if f.endswith("Package.swift"):
                fullPath = os.path.join(root, f)
                parentDir = os.path.split(fullPath)[0]
                baseDir = os.path.basename(parentDir)
                # remove version from SwiftyJSON-14.2.0
                m = re.match("(.*)-[\d+\.]+", baseDir)
                packageName = m.group(1)
                #print("baseDir="+baseDir+" packageName="+packageName)
                procesPackageFile(packageName, fullPath)

if __name__ == "__main__":
    main()