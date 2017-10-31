FROM amazonlinux:latest

RUN yum -y update && yum install -y python36-devel git unzip which java-1.8.0-openjdk-devel gcc gcc-c++ patch && pip-3.6 install numpy wheel

ENV BAZEL_VERSION 0.5.4


WORKDIR /

RUN mkdir /bazel && \
	    cd /bazel && \
	    curl -H "User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/57.0.2987.133 Safari/537.36" -fSsL -O https://github.com/bazelbuild/bazel/releases/download/$BAZEL_VERSION/bazel-$BAZEL_VERSION-installer-linux-x86_64.sh && \
	    curl -H "User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/57.0.2987.133 Safari/537.36" -fSsL -o /bazel/LICENSE.txt https://raw.githubusercontent.com/bazelbuild/bazel/master/LICENSE && \
	    chmod +x bazel-*.sh && \
	    ./bazel-$BAZEL_VERSION-installer-linux-x86_64.sh && \
	    cd / && \
	    rm -f /bazel/bazel-$BAZEL_VERSION-installer-linux-x86_64.sh

RUN git clone https://github.com/tensorflow/tensorflow.git && \
    cd tensorflow && \
    git checkout r1.4

WORKDIR /tensorflow

RUN touch /usr/include/stropts.h

ENV PYTHON_BIN_PATH /usr/bin/python3

ENV PYTHON_LIB_PATH /usr/lib/python3.6/dist-packages

RUN tensorflow/tools/ci_build/builds/configured CPU \
	bazel build -c opt --copt=-mavx --copt=-mavx2 --copt=-mfma --copt=-mfpmath=both --copt=-msse4.1 --copt=-msse4.2 --cxxopt="-D_GLIBCXX_USE_CXX11_ABI=0"  --jobs 1 --local_resources 6000,4.0,1.0 --define with_s3_support=true tensorflow/tools/pip_package:build_pip_package && \
	bazel-bin/tensorflow/tools/pip_package/build_pip_package /target/pip && \
	rm -rf /root/.cache && \
	rm -rf /tensorflow
