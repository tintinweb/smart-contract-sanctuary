/**
 *Submitted for verification at Etherscan.io on 2022-01-15
*/

// Эта строка необходима для правильной работы с JSON
// SPDX-License-Identifier: GPL-3.0
// Устанавливаем версии компилятора
pragma solidity >=0.8.7;

interface iCalculator{
    function sum(int8 first, int8 second) pure external returns(int8);
    function subtraction(int8 first, int8 second) pure external returns(int8);
    function divide(int8 first, int8 second) pure external returns(int8);
    function multiplication(int8 first, int8 second)pure external returns(int8);
}

// Делаем контракт - набор состояний и переходов
contract UpdateCalculator{
    
    iCalculator calcutator;

    constructor(address _calculatorAddress){
        // приводим адрес к типу интерфейса
        calcutator = iCalculator(_calculatorAddress);
    }

    function SumNumbers(int8[] memory _arr)public view returns (int){
        int8 s = 0;
        for (uint i = 0; i < _arr.length; i++){
            s = calcutator.sum(s, _arr[i]);
        }
        return s;
    }

    function MultyNumbers(int8[] memory _arr)public view returns (int){
        int8 s = 0;
        for (uint i = 0; i < _arr.length; i++){
            s = calcutator.multiplication(s, _arr[i]);
        }
        return s;
    }
}