/**
 *Submitted for verification at Etherscan.io on 2022-01-15
*/

// Эта строка необходима для правильной работы с JSON
// SPDX-License-Identifier: GPL-3.0
// Устанавливаем версии компилятора
pragma solidity >=0.8.7;

// Делаем контракт - набор состояний и переходов
contract HelloWorldContract{
    
    function sum(uint8 first, uint8 second) pure public returns(uint8){
        return (first + second);
    }
    
    function subtraction(uint8 first, uint8 second) pure public returns(uint8){
        return (first - second);
    }
    
    function divide(uint8 first, uint8 second) pure public returns(uint8){
        return (first / second);
    }
    
    function multiplication(uint8 first, uint8 second)pure public returns(uint8){
        return (first * second);
    }
    
}