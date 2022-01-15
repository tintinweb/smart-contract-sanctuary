/**
 *Submitted for verification at Etherscan.io on 2022-01-15
*/

// Эта строка необходима для правильной работы с JSON
// SPDX-License-Identifier: GPL-3.0
// Устанавливаем версии компилятора
pragma solidity >=0.8.7;

// Делаем контракт - набор состояний и переходов
contract HelloWorldContract{
    
    function sum(int8 first, int8 second) pure public returns(int8){
        return (first + second);
    }
    
    function subtraction(int8 first, int8 second) pure public returns(int8){
        return (first - second);
    }
    
    function divide(int8 first, int8 second) pure public returns(int8){
        return (first / second);
    }
    
    function multiplication(int8 first, int8 second)pure public returns(int8){
        return (first * second);
    }
    
}