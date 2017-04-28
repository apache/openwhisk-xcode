

# Need to use --privileged=true or REPL fails see:
# https://bugs.swift.org/browse/SR-54

docker run --privileged=true -it -v  $(pwd):/share  swift3action:playground /bin/bash
