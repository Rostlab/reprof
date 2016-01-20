# Project Name

Reprof is a protein secondary structure and accessibility predictor from the Rost Lab. Prediction is either done from protein sequence alone or from an alignment - the latter should be used for optimal performance. The language choosen was Perl.

## HOWTO Install

### Environment preparation
From a clean installation we should proceed to execute the following commands:
```
sudo apt-get install git-core
git clone https://github.com/Rostlab/reprof.git
sudo apt-get install automake autoconf
sudo apt-get install pp-popularity-contest
sudo apt-get install libfann2
sudo apt-get install libai-fann-perl
```

### reprof Installation
Once the environment is ready the following commands install reprof in our system:
```
cd reprof/
autoreconf -vif
./configure
sudo make-ssl-cert
cd lib/RG/
make Reprof.pm
cd ../../
make
sudo make install
sudo ./Build
sudo cp -a lib/. /etc/perl/
```

### reprof execution
If we already have reprof installed in our computer these are the execution commands:

Prediction from BLAST PSSM (algorithm for comparing amino-acid sequences using position weighted matrix):
```
reprof -i examples/example.Q -o /tmp/example.Q.reprof
```

Prediction from FASTA file (text based file to represent amino acids using single letter codes):
```
reprof -i examples/example.fasta -o /tmp/example.fasta.reprof
```

Prediction from BLAST PSSM matrix file using the mutation mode:
```
reprof -i examples/example.Q -o /tmp/mutations_example.Q.reprof --mutations examples/mutations.txt
```

## Method Description

*Authors:*
* Guy Yachdav <yachdav@rostlab.org>
* Peter Hoenigschmid <hoenigschmid.peter@googlemail.com>
* Laszlo Kajan <lkajan@rostlab.org>


## External links

Algorithm: https://www.rostlab.org/papers/1996_phd/paper.html

Man page: http://manpages.ubuntu.com/manpages/vivid/man1/reprof.1.html
