/**
 *Submitted for verification at Etherscan.io on 2021-06-10
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

contract AA {
    event Log(uint);
    receive() external payable {}
    fallback() external payable {}

    constructor () payable {
      owner = payable(msg.sender);
    }

    //function () payable external {}
    function getMoney() payable public {
        //emit Log(msg.value);
        payable(owner).transfer(msg.value);
        
    }
    function getBalance() public view returns (uint) {
        //emit Log("bbbbbb");
        return msg.sender.balance;
    }
    
    address payable public owner;

    
}