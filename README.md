# Time-FSTransducer

## **Objective**
The module must convert an hour that is written in full (_in portuguese_) into the corresponding numerical format **hh:mm**.

Some examples:
* _'oito horas e quinze minutos'_ -> 08:15
* _'oito e quinze'_ -> 08:15
* _'catorze e vinte cinco'_ -> 15:25
* _'dez horas e um quarto'_ -> 10:15

## **Transducers**

**Base transducers**:
* **horas** - Converts hours written in full to the 2-digit numeric format, considering numbers from the [0..23] range and the _'uma'_ and _'duas'_ variants. The word _'hora(s)'_ is optional. 
    - _'uma'_ -> 01
    - _'vinte e duas horas'_ -> 22

* **minutos** - Similar to the previous one, but considering numbers from the [0..59] range and considering the _'um'_ and _'dois'_ variants. The word _'minuto(s)'_ is optional. 
    - _'seis minutos'_ -> 06
    - _'vinte e um'_ -> 21

* **meias** - Converts the expression _'meia_' into an equivalent expression using numbers. 
    - _'meia'_ -> _'trinta'_

* **quartos** - Converts expressions using _'quarto'_ and _'quartos'_ into the equivalent expression using numbers. 
    - _'um quarto'_ -> _'quinze'_
    - _'dois quartos'_ -> _'trinta'_

More **complex transducers**, built using the base ones:
* **text2num** - Converts natural language normalized expressions that specify hours (“X [_'horas'_] e Y [_'minutos'_]”) into the numerical condensed form **hh:mm**. 
    - _'dez horas e quinze'_, _'dez e quinze minutos'_, _'dez horas e quinze minutos'_ -> 10:15
    - _'dez e zero'_ -> 10:00

* **lazy2num** - Being a variant of the previous one, accepts simpler expressions in the form "X [_'horas'_]". This transducer must also accept all the expressions accepted by text2num.fst.
    - _'dez'_ -> 10:00

* **rich2text** - Converts expressions that specify hours using _'meia'_ and _'quarto(s)'_ into the equivalent expression without those words. 
    - _'dez e um quarto'_ -> _'dez e quinze'_
    - _'dezoito e tres quartos'_ -> _'dezoito e quarenta e cinco'_

* **rich2num** - Converts any expression that specifies hours into its condensed numeric form **hh:mm**. 
    - _'dez'_ -> 10:00
    - _'dez e meia'_ -> 10:30
    - _'dez e quinze'_, _'dez e um quarto'_ -> 10:15

* **num2text** - Converts any hour in its condensed numerical form to the corresponding simplified text expressions always using the words _'hora(s)'_ and _'minuto(s)'_.
    - 10:15 -> _'dez horas e quinze minutos'_
