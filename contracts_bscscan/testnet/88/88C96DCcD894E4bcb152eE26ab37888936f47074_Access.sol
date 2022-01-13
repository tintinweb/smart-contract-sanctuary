/**
 *Submitted for verification at BscScan.com on 2022-01-13
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract Access {
    mapping(address => bool) public operators;
    //modfier
    modifier onlyOperator{
        require(operators[msg.sender],"Require operator permission");
        _;
    }
    constructor(){
        operators[msg.sender] = true;
    }
    //設定營運者
    function addOperator(address op) public onlyOperator {
        operators[op] = true;
    }
    //取消營運者
    function cancelOperator(address op) public onlyOperator {
        operators[op] = false;
    }
}