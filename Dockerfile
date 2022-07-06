FROM ubuntu:latest

RUN apt-get update
RUN DEBIAN_FRONTEND=noninteractive TZ=Europe/Berlin apt-get install -y build-essential clang bison flex libreadline-dev \
                     gawk tcl-dev libffi-dev git mercurial graphviz   \
                     xdot pkg-config python2 python3 libftdi-dev gperf \
                     libboost-program-options-dev autoconf libgmp-dev \
                     cmake curl cmake ninja-build g++ python3-dev python3-setuptools \
                     python3-pip python2-dev 
ENV PATH="/root/.local/bin:$PATH" 		     
					 
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
RUN sed -i 's/bool isSolved () { return m_Trivial || m_State || !m_State; }/ bool isSolved () { return bool{m_Trivial || m_State || !m_State}; }/' avy/src/ItpGlucose.h
RUN sed -i 's/return tobool (m_pSat->modelValue(x));/boost::logic::tribool y = tobool (m_pSat->modelValue(x));\n        return bool{y};/' avy/src/ItpGlucose.h
RUN sed -i 's/bool isSolved () { return m_Trivial || m_State || !m_State; }/bool isSolved () { return bool{m_Trivial || m_State || !m_State}; }/' avy/src/ItpMinisat.h
RUN mkdir build
WORKDIR /home/yosys/tools/extavy/build
RUN cmake -DCMAKE_BUILD_TYPE=Release ..
RUN make -j$(nproc)
RUN cp avy/src/avy /usr/local/bin/
RUN cp avy/src/avybmc /usr/local/bin/
WORKDIR /home/yosys/tools

RUN git clone https://github.com/boolector/boolector
WORKDIR /home/yosys/tools/boolector
RUN ./contrib/setup-btor2tools.sh
RUN ./contrib/setup-lingeling.sh
RUN ./configure.sh
RUN make -C build -j$(nproc)
RUN cp build/bin/boolector /usr/local/bin/
RUN cp build/bin/btor* /usr/local/bin/
RUN cp deps/btor2tools/bin/btorsim /usr/local/bin/
WORKDIR /home/yosys/tools

RUN git clone https://github.com/boolector/btor2tools
WORKDIR /home/yosys/tools/btor2tools
RUN ./configure.sh
RUN cmake . -DBUILD_SHARED_LIBS=OFF
RUN make -j$(nproc)
RUN make install
WORKDIR /home/yosys/tools

RUN curl -sSL https://get.haskellstack.org/ | sh
RUN git clone git clone https://github.com/zachjs/sv2v.git
WORKDIR /home/yosys/tools/sv2v
RUN make
RUN stack install
WORKDIR /home/yosys/tools

WORKDIR /home/yosys

CMD ["/bin/bash"]
