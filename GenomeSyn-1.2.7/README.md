# [GenomeSyn](http://cbi.gxu.edu.cn/GenomeSyn/)
We developed GenomeSyn as a new tool for constructing and visualizing genome synteny, its novel design and implementation can serve as a necessary complement to the study of genomic synteny and structural variation and its visualization tools.

An online service of GenomeSyn at: http://cbi.gxu.edu.cn/GenomeSyn/. 

![figure1-v9](https://user-images.githubusercontent.com/84839565/156312609-722f68de-4fc6-419f-9080-8072692ec0a1.png)


## Install

GenomeSyn is an executable file written in Perl, and users can run it directly. But before using GenomeSyn, the software dependency problem needs to be solved first. Users can download sample data for testing.
## Dependencies 
***1. MUMmer***

You can find MUMmer [here](https://github.com/mummer4/mummer/releases). We used Mummer-4.0.0beta2. Mummer version 4.x.x requires a recent version of the GCC compiler (g++ version >= 4.7), which is hard to install if you have no ***administrator authority***. You can ask your system administrator for some help in this case. 

```
$ wget https://github.com/mummer4/mummer/releases/download/v4.0.0beta2/mummer-4.0.0beta2.tar.gz 
$ tar -xvzf mummer-4.0.0beta2.tar.gz
$ current_path='pwd'
$ cd mummer-4.0.0beta2 
$ ./configure --prefix=`pwd` 
$ make 
# Add MUMmer tools to your PATH 
$ export PATH=$current_path/mummer-4.0.0beta2:$PATH 
```

***2. Perl and perl module***

```
$ wget https://cbi.gxu.edu.cn/rape/download_ext/localperl.zip
$ unzip localperl.zip
```

***3. Python and python module***

```
$ wget https://cbi.gxu.edu.cn/rape/download_ext/miniconda3.zip
$ unzip miniconda3.zip
```
We have integrated the required Perl (localperl) and [SVG]( https://cpan.metacpan.org/authors/id/M/MA/MANWAR/SVG-2.85.tar.gz ) and [BioPerl]( https://cpan.metacpan.org/authors/id/C/CJ/CJFIELDS/BioPerl-1.7.8.tar.gz ) package and Python (miniconda) and [svglib]( https://files.pythonhosted.org/packages/c0/2c/5ab28095c9ce09a6d341cb37c0ad3a7ffc65e5c5f2eaa2247c085679ca2f/svglib-1.1.0.tar.gz ) packages in the GenomeSyn installation package, after the GenomeSyn installation package is decompressed, use the "source ./install.sh" command to add the environment for running GenomeSyn to run GenomeSyn.
```
# add the environment variables
$ source ./install.sh
```

# Quick start

	eg. GenomeSyn -g1 ../data/rice_MH63.fa -g2 ../data/rice_ZS97.fa

	eg. GenomeSyn -t 3 -g1 ../data/rice_MH63.fa -g2 ../data/rice_ZS97.fa -cf1 ../data/rice_MH63vsZS97.delta.filter.coords

	eg. GenomeSyn -t 3 -g1 ../data/rice_MH63.fa -g2 ../data/rice_ZS97.fa -cf1 ../data/rice_MH63vsZS97.delta.filter.coords -cen1 ../data/rice_MH63_centromere.bed -cen2 ../data/rice_ZS97_centromere.bed -tel1 ../data/rice_MH63_telomere.bed -tel2 ../data/rice_ZS97_telomere.bed -TE1 ../data/rice_MH63_repeat.bed -TE2 ../data/rice_ZS97_repeat.bed -PAV1 ../data/rice_MH63_PAV.bed -PAV2 ../data/rice_ZS97_PAV.bed -NLR1 ../data/rice_MH63_NLR.bed -NLR2 ../data/rice_ZS97_NLR.bed -r MH63 -q ZS97 -GD1 ../data/rice_MH63_nonTEgene.gff3 -GD2 ../data/rice_ZS97_nonTEgene.gff3 -GC1 ../data/rice_MH63_GC_10000.bed -GC2 ../data/rice_ZS97_GC_10000.bed -GC_win 100000 -TE_min 40

	eg. GenomeSyn -t 3 -n3 12 -g1 ../data/rice_MH63.fa -g2 ../data/rice_ZS97.fa -g3 ../data/rice_R498.fasta -cf1 ../data/rice_MH63vsZS97.delta.filter.coords -cf2 ../data/rice_MH63vsR498.delta.filter.coords -cen1 ../data/rice_MH63_centromere.bed -cen2 ../data/rice_ZS97_centromere.bed -cen3 ../data/rice_R498_centromere.bed -tel1 ../data/rice_MH63_telomere.bed -tel2 ../data/rice_ZS97_telomere.bed -tel3 ../data/rice_R498_telomere.bed -TE2 ../data/rice_ZS97_repeat.bed -PAV1 ../data/rice_MH63_PAV.bed -PAV2 ../data/rice_ZS97_PAV.bed -NLR1 ../data/rice_MH63_NLR.bed -NLR2 ../data/rice_ZS97_NLR.bed -r MH63 -q1 ZS97 -q2 R498 -GD1 ../data/rice_MH63_nonTEgene.gff3 -GD2 ../data/rice_ZS97_nonTEgene.gff3 -GD3 ../data/rice_R498_IGDBv3_coreset.gff -GC2 ../data/rice_ZS97_GC_10000.bed -GC_win 100000 -TE_min 40
