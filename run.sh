#!/bin/bash

mkdir -p compiled images

for i in sources/*.txt tests/*.txt; do
	echo "Compiling: $i"
    fstcompile --isymbols=syms.txt --osymbols=syms.txt $i | fstarcsort > compiled/$(basename $i ".txt").fst
done


# TRANSDUCERS

echo "Building transducers..."

echo "text2num -> 'horas' + 'aux_:' + 'e_aux' + 'minutos'"
fstconcat compiled/horas.fst compiled/aux_:.fst > compiled/horas_:.fst 
fstrmepsilon compiled/horas_:.fst compiled/horas_:.fst 

fstconcat compiled/aux_e.fst compiled/minutos.fst > compiled/e_minutos.fst
fstrmepsilon compiled/e_minutos.fst compiled/e_minutos.fst

fstconcat compiled/horas_:.fst compiled/e_minutos.fst > compiled/text2num.fst
fstrmepsilon compiled/text2num.fst compiled/text2num.fst

echo "lazy2num -> 'horas_:' + 'aux_00' + 'text2num'"
fstunion compiled/e_minutos.fst compiled/aux_00.fst  > compiled/minutos_00.fst
fstrmepsilon compiled/minutos_00.fst compiled/minutos_00.fst

fstconcat compiled/horas_:.fst compiled/minutos_00.fst > compiled/lazy2num.fst
fstrmepsilon compiled/lazy2num.fst compiled/lazy2num.fst

# TESTS
echo -e "\nTesting transducers..."

#echo "'converter' -> input: 'tests/numero.txt'"
#fstcompose compiled/numero.fst compiled/converter.fst | fstshortestpath | fstproject --project_output | fstrmepsilon | fsttopsort | fstprint --acceptor --isymbols=./syms.txt

echo "  -> horas:"
echo -e "\tinput: tests/horas_1.txt"
fstcompose compiled/horas_1.fst compiled/horas.fst compiled/tested_horas.fst 

echo "  -> minutos:"
echo -e "\tinput: tests/minutos_1.txt"
fstcompose compiled/minutos_1.fst compiled/minutos.fst compiled/tested_minutos.fst 

echo "  -> text2num:"
echo -e "\tinput: tests/text2num_1.txt"
fstcompose compiled/text2num_1.fst compiled/text2num.fst compiled/tested_text2num_1.fst 

echo "  -> lazy2num:"
echo -e "\tinput: tests/lazy2num_1.txt"
fstcompose compiled/lazy2num_1.fst compiled/lazy2num.fst compiled/tested_lazy2num_1.fst

echo -e "\tinput: tests/lazy2num_2.txt"
fstcompose compiled/lazy2num_2.fst compiled/lazy2num.fst compiled/tested_lazy2num_2.fst  

echo -e "\tinput: tests/text2num_1.txt"
fstcompose compiled/text2num_1.fst compiled/lazy2num.fst compiled/tested_lazy2num_3.fst 

# IMAGES
echo -e "\nCreating images..."
for i in compiled/*.fst; do
	echo -e "  $(basename $i '.fst').pdf"
    fstdraw --portrait --isymbols=syms.txt --osymbols=syms.txt $i | dot -Tpdf > images/$(basename $i '.fst').pdf
done