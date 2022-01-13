/**
 *Submitted for verification at Etherscan.io on 2022-01-13
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;
contract Mycontract {

    string _name;
    uint _balance;

    constructor(string memory name,uint balance){
            require(balance >= 500 ,"Balance greater zero and equal 500");
            _name = name;
            _balance = balance;
    }
    function getBalance() public view returns(uint balance){
        return _balance;
    }
    function getBalancev1() public pure returns(uint balance){
        return 50;
    }

    function deposite(uint amount) public {
            _balance +=amount;
    }


}