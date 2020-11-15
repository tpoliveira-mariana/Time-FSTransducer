#!/bin/bash

set -e # exit on first error

mkdir -p compiled images

for i in sources/*.txt tests/*.txt; do
	echo "Compiling: $i"
	fstcompile --isymbols=syms.txt --osymbols=syms.txt $i | fstarcsort > compiled/$(basename $i ".txt").fst
done

# TRANSDUCERS
echo
echo "Building transducers..."

echo -e "\ttext2num -> horas . aux_e . minutos"
fstconcat compiled/horas.fst compiled/aux_e.fst > compiled/horas_e.fst
fstconcat compiled/horas_e.fst compiled/minutos.fst > compiled/text2num.fst
fstrmepsilon compiled/text2num.fst{,}
fstarcsort compiled/text2num.fst{,}

echo -e "\tlazy2num -> horas . aux_e . (minutos or aux_00)"
fstunion compiled/minutos.fst compiled/aux_00.fst  > compiled/minutos_or_00.fst
fstconcat compiled/horas_e.fst compiled/minutos_or_00.fst > compiled/lazy2num.fst
fstrmepsilon compiled/lazy2num.fst{,}
fstarcsort compiled/lazy2num.fst{,}

echo -e "\trich2text -> project(horas . aux_e) . (meias or quartos)"
fstproject compiled/horas_e.fst > compiled/horas_e_text.fst
fstunion compiled/meias.fst compiled/quartos.fst > compiled/meias_or_quartos.fst
fstconcat compiled/horas_e_text.fst compiled/meias_or_quartos.fst > compiled/rich2text.fst
fstrmepsilon compiled/rich2text.fst{,}
fstarcsort compiled/rich2text.fst{,}

echo -e "\trich2num -> lazy2num(rich2text) or lazy2num"
fstcompose compiled/rich2text.fst compiled/lazy2num.fst > compiled/treated2num.fst
fstunion compiled/treated2num.fst compiled/lazy2num.fst > compiled/rich2num.fst
fstrmepsilon compiled/rich2num.fst{,}
fstarcsort compiled/rich2num.fst{,}

echo -e "\tnum2text -> prune(invert(text2num))"
fstinvert compiled/text2num.fst > compiled/num2text.fst
fstprune --weight=0 compiled/num2text.fst{,}
fstrmepsilon compiled/num2text.fst{,}
fstarcsort compiled/num2text.fst{,}

# TESTS
echo
echo "Testing transducers..."

#echo "'converter' -> input: 'tests/numero.txt'"
#fstcompose compiled/numero.fst compiled/converter.fst | fstshortestpath | fstproject --project_output | fstrmepsilon | fsttopsort | fstprint --acceptor --isymbols=./syms.txt

echo " -> rich2num:"
for name in {sleep,wakeup}{A,B,C,D,E,F}_{89409,89504}; do
    echo -e "\tinput: tests/$name.txt"
    fstcompose "compiled/$name.fst" compiled/rich2num.fst "compiled/tested_$name.fst"
done

echo " -> num2text:"
for name in {sleep,wakeup}G_{89409,89504}; do
    echo -e "\tinput: tests/$name.txt"
    fstcompose "compiled/$name.fst" compiled/num2text.fst "compiled/tested_$name.fst"
    fstshortestpath "compiled/tested_$name.fst" "compiled/tested_$name.fst"
done

# IMAGES
echo -e "\nCreating images..."
for i in compiled/*.fst; do
	echo -e "  $(basename $i '.fst').pdf"
    fstdraw --portrait --isymbols=syms.txt --osymbols=syms.txt $i | dot -Tpdf > images/$(basename $i '.fst').pdf
done
