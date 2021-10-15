/**
 *Submitted for verification at Etherscan.io on 2021-10-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract GTSAlpha{
    address private immutable owner;
    event Log(bytes32 indexed _hash1, bytes32 indexed _hash2, string ipfs);
    modifier isOwner(){
        require(msg.sender==owner,"NEEDS TO BE OWNER");
        _;
    }
    constructor(){
        owner=0xc54C5B3fe426012380531585511BD77291cD413E;
    }
    function logTitle(bytes32 hash1,bytes32 hash2,string memory ipfs)public isOwner(){
        emit Log(hash1,hash2,ipfs);
    }

    function foo()public{
        
    }
}