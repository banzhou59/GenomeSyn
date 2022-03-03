#!/bin/bash
##1.MUMmer
current_path=`pwd`
tar -zxvf mummer-4.0.0beta2.tar.gz
cd mummer-4.0.0beta2
./configure --prefix=`pwd`
make
cd ..
# Add MUMmer tools to your PATH
export PATH=$current_path/mummer-4.0.0beta2:$PATH
