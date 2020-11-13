#!/bin/bash

mkdir -p compiled images

for i in sources/*.txt tests/*.txt; do
	echo "Compiling: $i"
    fstcompile --isymbols=syms.txt --osymbols=syms.txt $i | fstarcsort > compiled/$(basename $i ".txt").fst
done


# TODO 

echo "Testing the transducer 'converter' with the input 'tests/numero.txt'"
fstcompose compiled/numero.fst compiled/converter.fst | fstshortestpath | fstproject --project_output | fstrmepsilon | fsttopsort | fstprint --acceptor --isymbols=./syms.txt

echo "Testing the tranducer 'horas' with the input 'tests/horas_1.txt'"
fstcompose compiled/horas_1.fst compiled/horas.fst compiled/tested_horas.fst

echo "Testing the tranducer 'minutos' with the input 'tests/minutos_1.txt'"
fstcompose compiled/minutos_1.fst compiled/minutos.fst compiled/tested_minutos.fst 

echo "Building transducer text2num from 'horas', 'aux_:' and 'minutos'."
fstconcat compiled/horas.fst compiled/aux_:.fst > compiled/horas_:.fst
fstconcat compiled/horas_:.fst compiled/minutos.fst > compiled/text2num.fst


for i in compiled/*.fst; do
	echo "Creating image: images/$(basename $i '.fst').pdf"
    fstdraw --portrait --isymbols=syms.txt --osymbols=syms.txt $i | dot -Tpdf > images/$(basename $i '.fst').pdf
done