FROM swift3action:base

ENV DEBIAN_FRONTEND noninteractive

ENV PYTHONIOENCODING utf-8

RUN sudo apt-get -y install libpython2.7

COPY add_dylib.py /

RUN /add_dylib.py

WORKDIR /swift3Action/spm-build/
RUN /bin/bash -c "/usr/bin/swift build"

CMD ["/bin/bash", "-c", "cd /swift3Action && PYTHONIOENCODING='utf-8' python -u swift3runner.py"]
