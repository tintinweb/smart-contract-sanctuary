/**
 *Submitted for verification at Etherscan.io on 2021-04-30
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract Primitives {
    
    bytes32 com;
    function commitment() payable public{
        com = keccak256(abi.encodePacked(msg.value));    
    }
    
    address payable public first;
    uint first_value;
    
    function  atomic() payable public{
        if (msg.sender == first){
            first.transfer(first_value);
        }
        if(first_value>0){
            first.transfer(msg.value);
            payable(msg.sender).transfer(first_value);
        }
        else{
            first = payable(msg.sender);
            first_value = msg.value;
        }
    }
    
    function read() payable public returns (uint) {
        return msg.value;
    }
    
}