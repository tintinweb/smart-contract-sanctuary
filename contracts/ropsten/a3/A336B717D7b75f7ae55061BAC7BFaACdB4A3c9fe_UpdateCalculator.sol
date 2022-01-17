/**
 *Submitted for verification at Etherscan.io on 2022-01-16
*/

// Эта строка необходима для правильной работы с JSON
// SPDX-License-Identifier: GPL-3.0
// Устанавливаем версии компилятора
pragma solidity >=0.8.7;



interface iCalculator{
    function sum(uint24 first, uint24 second) view external returns(uint24);
    function subtraction(int24 first, int24 second) view external returns(int24);
    function divide(uint24 first, uint24 second) view external returns(uint24);
    function multiplication(uint24 first, uint24 second)view external returns(uint64);
}

// Делаем контракт - набор состояний и переходов
contract UpdateCalculator{
    
    iCalculator calculator;

    constructor(address _adr){
        // приводим адрес к типу интерфейса
        calculator = iCalculator(_adr);
    }

    function SumNumbers(uint24[] memory _arr)public view returns (uint24){
        uint24 s = 0;
        for (uint i = 0; i < _arr.length; i++){
            s = calculator.sum(s, _arr[i]);
        }
        return s;
    }

    function MultyNumbers(uint24[] memory _arr)public view returns (uint24){
        uint24 s = 1;
        for (uint i = 0; i < _arr.length; i++){
            s = uint24(calculator.multiplication(s, _arr[i]));
        }
        return s;
    }
}