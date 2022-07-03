FROM ubuntu:latest

RUN apt-get update
RUN DEBIAN_FRONTEND=noninteractive TZ=Europe/Berlin apt-get install -y build-essential clang bison flex libreadline-dev \
                     gawk tcl-dev libffi-dev git mercurial graphviz   \
                     xdot pkg-config python2 python3 libftdi-dev gperf \
                     libboost-program-options-dev autoconf libgmp-dev \
                     cmake curl cmake ninja-build g++ python3-dev python3-setuptools \
                     python3-pip
					 
WORKDIR /home/yosys
RUN mkdir tools
WORKDIR /home/yosys/tools

RUN git clone https://github.com/YosysHQ/yosys.git yosys
WORKDIR /home/yosys/tools/yosys
RUN make -j$(nproc)
RUN make install
WORKDIR /home/yosys/tools

RUN git clone https://github.com/YosysHQ/SymbiYosys.git SymbiYosys
WORKDIR /home/yosys/tools/SymbiYosys
RUN make install
WORKDIR /home/yosys/tools

RUN git clone https://github.com/SRI-CSL/yices2.git yices2
WORKDIR /home/yosys/tools/yices2
RUN autoconf
RUN ./configure
RUN make -j$(nproc)
RUN make install
WORKDIR /home/yosys/tools

RUN git clone https://github.com/Z3Prover/z3.git z3
WORKDIR /home/yosys/tools/z3
RUN python3 scripts/mk_make.py
WORKDIR /home/yosys/tools/z3/build
RUN make -j$(nproc)
RUN make install
WORKDIR /home/yosys/tools

RUN git clone --recursive https://github.com/sterin/super-prove-build
WORKDIR /home/yosys/tools/super-prove-build
RUN mkdir build
WORKDIR /home/yosys/tools/super-prove-build/build
RUN cmake -DCMAKE_BUILD_TYPE=Release -G Ninja ..
RUN ninja
RUN ninja package
RUN tar -C /usr/local -xf super_prove*.tar.gz
RUN touch /usr/local/bin/suprove 
RUN echo "#!/bin/bash" > /usr/local/bin/suprove
RUN echo "tool=super_prove; if [ \"$1\" != \"${1#+}\" ]; then tool=\"${1#+}\"; shift; fi" > /usr/local/bin/suprove
RUN echo "exec /usr/local/super_prove/bin/${tool}.sh \"$@\"" > /usr/local/bin/suprove
RUN chmod +x /usr/local/bin/suprove
WORKDIR /home/yosys/tools

RUN git clone https://bitbucket.org/arieg/extavy.git
WORKDIR /home/yosys/tools/extavy
RUN git submodule update --init
RUN mkdir build; cd build
RUN cmake -DCMAKE_BUILD_TYPE=Release ..
RUN make -j$(nproc)
RUN cp avy/src/{avy,avybmc} /usr/local/bin/
WORKDIR /home/yosys/tools

RUN git clone https://github.com/boolector/boolector
WORKDIR /home/yosys/tools/boolector
RUN ./contrib/setup-btor2tools.sh
RUN ./contrib/setup-lingeling.sh
RUN ./configure.sh
RUN make -C build -j$(nproc)
RUN cp build/bin/{boolector,btor*} /usr/local/bin/
RUN cp deps/btor2tools/bin/btorsim /usr/local/bin/
WORKDIR /home/yosys/tools

RUN git clone https://github.com/boolector/btor2tools
WORKDIR /home/yosys/tools/btor2tools
RUN ./configure.sh
RUN cmake . -DBUILD_SHARED_LIBS=OFF
RUN make -j$(nproc)
RUN make install
WORKDIR /home/yosys/tools
