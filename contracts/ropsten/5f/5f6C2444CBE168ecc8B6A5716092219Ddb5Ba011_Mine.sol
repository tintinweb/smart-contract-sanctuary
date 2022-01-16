/**
 *Submitted for verification at Etherscan.io on 2022-01-16
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract Mine{

    address public creator;

    constructor()payable{
        creator = msg.sender;
    }

    function withdraw(uint withdraw_amount) public{
        require(withdraw_amount <= 0.001 ether);
        payable(msg.sender).transfer(withdraw_amount);
    }


    fallback () payable external {}
    receive () payable external {}

}