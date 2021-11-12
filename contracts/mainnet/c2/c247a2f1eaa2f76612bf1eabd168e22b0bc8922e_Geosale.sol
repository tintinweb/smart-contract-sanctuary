/**
 *Submitted for verification at Etherscan.io on 2021-11-12
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract Geosale {
    uint256 price = 10000000000000000;
    address bene;
    mapping(address => uint8) public starter;
    
    constructor(){
        bene = msg.sender;
    }

    function buy(uint8 choice) public payable{
        require(msg.value == price);
        starter[msg.sender] = choice;
    }

    function recover() public{
        payable(bene).transfer(address(this).balance);
    }
}