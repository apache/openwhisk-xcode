# build docker images
echo Building base image from OpenWhisk Swift3 Action
(cd swift3Action; docker build -t swift3action:base .)
echo Building Swift Playground enabled version of  OpenWhisk Swift3 Action
docker build -t swift3action:playground .
