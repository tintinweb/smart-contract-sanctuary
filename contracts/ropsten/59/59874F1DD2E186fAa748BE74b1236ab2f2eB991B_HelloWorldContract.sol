/**
 *Submitted for verification at Etherscan.io on 2022-01-16
*/

// Эта строка необходима для правильной работы с JSON
// SPDX-License-Identifier: GPL-3.0
// Устанавливаем версии компилятора
pragma solidity >=0.8.7;

// Делаем контракт - набор состояний и переходов
contract HelloWorldContract{
    
    function sum(uint24 first, uint24 second) view public returns(uint24){
        return (first + second);
    }
    
    function subtraction(int24 first, int24 second) view public returns(int24){
        return (first - second);
    }
    
    function divide(uint24 first, uint24 second) view public returns(uint24){
        return (first / second);
    }
    
    function multiplication(uint24 first, uint24 second)view public returns(uint64){
        return (first * second);
    }
    
}