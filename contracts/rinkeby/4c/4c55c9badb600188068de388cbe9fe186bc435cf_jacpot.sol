/**
 *Submitted for verification at Etherscan.io on 2021-09-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract jacpot{
    uint public randNonce=0;
    address public winner;
    uint public japot;

    function randMod(uint _modulus) public returns(uint){
        randNonce++;
        return uint(keccak256(abi.encodePacked(block.timestamp,msg.sender,randNonce))) % _modulus;
    }
    
    function betting(uint num) public payable{
        require(msg.value == 0.01 ether);
        if(num != randMod(10)){
        japot = japot + msg.value;
        }
        if(num == randMod(10)){
        japot = japot + msg.value;    
        payable(msg.sender).transfer(japot);
        japot = 0;
        winner=msg.sender;
        }
    }
}