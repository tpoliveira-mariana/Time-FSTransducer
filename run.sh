#!/bin/bash

mkdir -p compiled images

for i in sources/*.txt tests/*.txt; do
	echo "Compiling: $i"
	fstcompile --isymbols=syms.txt --osymbols=syms.txt $i | fstarcsort > compiled/$(basename $i ".txt").fst
done


# TRANSDUCERS
echo
echo "Building transducers..."

echo -e "\ttext2num -> horas + aux_: + e_aux + minutos"
fstconcat compiled/horas.fst compiled/aux_:.fst > compiled/horas_:.fst 
fstconcat compiled/aux_e.fst compiled/minutos.fst > compiled/e_minutos.fst
fstconcat compiled/horas_:.fst compiled/e_minutos.fst > compiled/text2num.fst
fstrmepsilon compiled/text2num.fst compiled/text2num.fst

echo -e "\tlazy2num -> horas_: + aux_00 + text2num"
fstunion compiled/e_minutos.fst compiled/aux_00.fst  > compiled/minutos_00.fst
fstconcat compiled/horas_:.fst compiled/minutos_00.fst > compiled/lazy2num.fst
fstrmepsilon compiled/lazy2num.fst compiled/lazy2num.fst

echo -e "\trich2text -> horas + aux_e + quartos + meias"
fstproject compiled/horas.fst > compiled/horas_text.fst
fstrmepsilon compiled/horas_text.fst compiled/horas_text.fst
fstproject compiled/aux_e.fst > compiled/e_text.fst
fstconcat compiled/horas_text.fst compiled/e_text.fst > compiled/horas_e_text.fst
fstconcat compiled/horas_e_text.fst compiled/meias.fst > compiled/horas_e_meia.fst
fstconcat compiled/horas_e_text.fst compiled/quartos.fst > compiled/horas_e_quarto.fst
fstunion compiled/horas_e_meia.fst compiled/horas_e_quarto.fst > compiled/rich2text.fst
fstrmepsilon compiled/rich2text.fst compiled/rich2text.fst

echo -e "\trich2num -> rich2text + lazy2num"
fstunion compiled/horas_e_meia.fst compiled/horas_e_quarto.fst > compiled/treated_time.fst
fstarcsort compiled/treated_time.fst compiled/treated_time.fst
fstarcsort compiled/lazy2num.fst compiled/lazy2num.fst
fstcompose compiled/treated_time.fst compiled/lazy2num.fst > compiled/treated2num.fst
fstunion compiled/treated2num.fst compiled/lazy2num.fst > compiled/rich2num.fst
fstrmepsilon compiled/rich2num.fst compiled/rich2num.fst


echo -e "\tnum2text -> horas + aux_: + e_aux + minutos + text2num"
fstinvert compiled/text2num.fst > compiled/num2text.fst
fstrmepsilon compiled/num2text.fst compiled/num2text.fst

# TESTS
echo
echo "Testing transducers..."

#echo "'converter' -> input: 'tests/numero.txt'"
#fstcompose compiled/numero.fst compiled/converter.fst | fstshortestpath | fstproject --project_output | fstrmepsilon | fsttopsort | fstprint --acceptor --isymbols=./syms.txt

echo " -> rich2num:"
for name in {sleep,wakeup}{A,B,C,D,E}_{89409,89504}; do
    echo -e "\tinput: tests/$name.txt"
    fstcompose "compiled/$name.fst" compiled/rich2num.fst "compiled/tested_$name.fst"
done

echo " -> num2text:"
for name in {sleep,wakeup}F_{89409,89504}; do
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
