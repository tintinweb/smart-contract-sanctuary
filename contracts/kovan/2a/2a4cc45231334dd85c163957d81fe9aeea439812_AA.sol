/**
 *Submitted for verification at Etherscan.io on 2021-06-10
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

contract AA {
    //event Log(string);
    receive() external payable {}
    fallback() external payable {}
    
    
    //function () payable external {}
    function getMoney() payable public {
        //emit Log("aaaaaaaaa");
        payable(msg.sender).transfer(1 ether);
        
    }
    function getBalance() public view returns (uint) {
        //emit Log("bbbbbb");
        return msg.sender.balance;
    }
}