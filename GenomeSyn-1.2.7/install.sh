#!/bin/bash
current_path=`pwd`
#Add GenomeSyn to your PATH
export PATH=$current_path/bin:$PATH
# Add Perl module to your PATH
export PATH=$current_path/localperl/bin:$PATH
export PERL5LIB=$current_path/localperl/lib/:$PERL5LIB
export PERL5LIB=$current_path/localperl/lib/perl5:$PERL5LIB
#Add Python to your PATH
export PATH=$current_path/miniconda3/bin:$PATH
# Add MUMmer tools to your PATH
export PATH=$current_path/mummer-4.0.0beta2:$PATH
