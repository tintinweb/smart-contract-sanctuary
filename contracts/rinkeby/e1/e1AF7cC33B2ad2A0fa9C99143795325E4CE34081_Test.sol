// SPDX-License-Identifier: GPL-3.0

// Created by HolaNext
// Portions Contract

pragma solidity ^0.8.0;

interface ITest{
    function counter() external returns(uint);
}

contract Test{

    uint public counter;
    
    function Increase() public{
        counter +=1;
    }
}