#!/bin/bash

mkdir -p compiled images

for i in sources/*.txt tests/*.txt; do
	echo "Compiling: $i"
    fstcompile --isymbols=syms.txt --osymbols=syms.txt $i | fstarcsort > compiled/$(basename $i ".txt").fst
done


# TRANSDUCERS

echo -e "\nBuilding transducers..."

echo "  text2num -> horas + aux_: + e_aux + minutos"
fstconcat compiled/horas.fst compiled/aux_:.fst > compiled/horas_:.fst 
fstconcat compiled/aux_e.fst compiled/minutos.fst > compiled/e_minutos.fst
fstconcat compiled/horas_:.fst compiled/e_minutos.fst > compiled/text2num.fst
fstrmepsilon compiled/text2num.fst compiled/text2num.fst

echo "  lazy2num -> horas_: + aux_00 + text2num"
fstunion compiled/e_minutos.fst compiled/aux_00.fst  > compiled/minutos_00.fst
fstconcat compiled/horas_:.fst compiled/minutos_00.fst > compiled/lazy2num.fst
fstrmepsilon compiled/lazy2num.fst compiled/lazy2num.fst


echo "  rich2text -> horas + aux_e + quartos + meias"
fstproject compiled/horas.fst > compiled/horas_text.fst
fstrmepsilon compiled/horas_text.fst compiled/horas_text.fst
fstproject compiled/aux_e.fst > compiled/e_text.fst
fstconcat compiled/horas_text.fst compiled/e_text.fst > compiled/horas_e_text.fst
fstconcat compiled/horas_e_text.fst compiled/meias.fst > compiled/horas_e_meia.fst
fstconcat compiled/horas_e_text.fst compiled/quartos.fst > compiled/horas_e_quarto.fst
fstunion compiled/horas_e_meia.fst compiled/horas_e_quarto.fst > compiled/rich2text.fst
fstrmepsilon compiled/rich2text.fst compiled/rich2text.fst

echo "  rich2num -> horas_e_meia + horas_e_quarto + lazy2num"
fstunion compiled/horas_e_meia.fst compiled/horas_e_quarto.fst > compiled/treated_time.fst
fstarcsort compiled/treated_time.fst compiled/treated_time.fst
fstarcsort compiled/lazy2num.fst compiled/lazy2num.fst
fstcompose compiled/treated_time.fst compiled/lazy2num.fst > compiled/treated2num.fst
fstunion compiled/treated2num.fst compiled/lazy2num.fst > compiled/rich2num.fst
fstrmepsilon compiled/rich2num.fst compiled/rich2num.fst

echo "  num2text -> horas + aux_: + e_aux + minutos + text2num"
fstinvert compiled/text2num.fst > compiled/num2text.fst
fstrmepsilon compiled/num2text.fst compiled/num2text.fst


# TESTS
echo -e "\nTesting transducers..."

#echo "'converter' -> input: 'tests/numero.txt'"
#fstcompose compiled/numero.fst compiled/converter.fst | fstshortestpath | fstproject --project_output | fstrmepsilon | fsttopsort | fstprint --acceptor --isymbols=./syms.txt

echo "  -> rich2num:"
echo -e "\tinput: tests/sleepA_89504.txt"
fstcompose compiled/sleepA_89504.fst compiled/rich2num.fst compiled/tested_sleepA_89504.fst 

echo -e "\tinput: tests/sleepB_89504.txt"
fstcompose compiled/sleepB_89504.fst compiled/rich2num.fst compiled/tested_sleepB_89504.fst 

echo -e "\tinput: tests/sleepC_89504.txt"
fstcompose compiled/sleepC_89504.fst compiled/rich2num.fst compiled/tested_sleepC_89504.fst 

echo -e "\tinput: tests/sleepD_890504.txt"
fstcompose compiled/sleepD_89504.fst compiled/rich2num.fst compiled/tested_sleepD_89504.fst 

echo -e "\tinput: tests/BREAD.txt"
echo -e "\tinput: tests/BREAD.txt"
echo -e "\tinput: tests/BREAD.txt"
echo -e "\tinput: tests/BREAD.txt"


echo "  -> num2text:"
echo -e "\tinput: tests/sleepE_89504.txt"
fstcompose compiled/sleepE_89504.fst compiled/num2text.fst compiled/tested_sleepE_89504.fst 
fstshortestpath compiled/tested_sleepE_89504.fst compiled/tested_sleepE_89504.fst

echo -e "\tinput: tests/BREAD.txt"

# IMAGES
echo -e "\nCreating images..."
for i in compiled/*.fst; do
	echo -e "  $(basename $i '.fst').pdf"
    fstdraw --portrait --isymbols=syms.txt --osymbols=syms.txt $i | dot -Tpdf > images/$(basename $i '.fst').pdf
done
