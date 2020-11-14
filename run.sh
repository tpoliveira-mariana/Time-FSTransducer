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

echo "  -> horas:"
echo -e "\tinput: tests/horas_1.txt"
fstcompose compiled/horas_1.fst compiled/horas.fst compiled/tests/tested_horas.fst 

echo "  -> minutos:"
echo -e "\tinput: tests/minutos_1.txt"
fstcompose compiled/minutos_1.fst compiled/minutos.fst compiled/tests/tested_minutos.fst 

echo "  -> text2num:"
echo -e "\tinput: tests/text2num_1.txt"
fstcompose compiled/text2num_1.fst compiled/text2num.fst compiled/tests/tested_text2num_1.fst 

echo "  -> lazy2num:"
echo -e "\tinput: tests/lazy2num_1.txt"
fstcompose compiled/lazy2num_1.fst compiled/lazy2num.fst compiled/tests/tested_lazy2num_1.fst

echo -e "\tinput: tests/lazy2num_2.txt"
fstcompose compiled/lazy2num_2.fst compiled/lazy2num.fst compiled/tests/tested_lazy2num_2.fst  

echo -e "\tinput: tests/text2num_1.txt"
fstcompose compiled/text2num_1.fst compiled/lazy2num.fst compiled/tests/tested_lazy2num_3.fst 

echo "  -> rich2text:"
echo -e "\tinput: tests/rich2text_1.txt"
fstcompose compiled/rich2text_1.fst compiled/rich2text.fst compiled/tests/tested_rich2text_1.fst 

echo -e "\tinput: tests/rich2text_2.txt"
fstcompose compiled/rich2text_2.fst compiled/rich2text.fst compiled/tests/tested_rich2text_2.fst 

echo "  -> rich2num:"
echo -e "\tinput: tests/lazy2num_1.txt"
fstcompose compiled/lazy2num_1.fst compiled/rich2num.fst compiled/tests/tested_rich2num_1.fst 

echo -e "\tinput: tests/lazy2num_2.txt"
fstcompose compiled/lazy2num_2.fst compiled/rich2num.fst compiled/tests/tested_rich2num_2.fst 

echo -e "\tinput: tests/text2num_1.txt"
fstcompose compiled/text2num_1.fst compiled/rich2num.fst compiled/tests/tested_rich2num_3.fst 

echo -e "\tinput: tests/rich2num_1.txt"
fstcompose compiled/rich2num_1.fst compiled/rich2num.fst compiled/tests/tested_rich2num_4.fst 

echo -e "\tinput: tests/rich2num_2.txt"
fstcompose compiled/rich2num_2.fst compiled/rich2num.fst compiled/tests/tested_rich2num_5.fst 

echo "  -> num2text:"
echo -e "\tinput: tests/num2text_1.txt"
fstcompose compiled/num2text_1.fst compiled/num2text.fst compiled/tests/tested_num2text_1.fst 
fstshortestpath compiled/tests/tested_num2text_1.fst compiled/tests/tested_num2text_1.fst

# IMAGES
echo -e "\nCreating images..."
for i in compiled/*.fst; do
	echo -e "  $(basename $i '.fst').pdf"
    fstdraw --portrait --isymbols=syms.txt --osymbols=syms.txt $i | dot -Tpdf > images/$(basename $i '.fst').pdf
done

for i in compiled/tests/*.fst; do
	echo -e "  $(basename $i '.fst').pdf"
    fstdraw --portrait --isymbols=syms.txt --osymbols=syms.txt $i | dot -Tpdf > images/tests/$(basename $i '.fst').pdf
done