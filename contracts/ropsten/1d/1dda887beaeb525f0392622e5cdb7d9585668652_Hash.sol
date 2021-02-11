/**
 *Submitted for verification at Etherscan.io on 2021-02-11
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;


contract Hash{
    
    constructor(){
        
    }
    
    function getHash(string memory message,uint8 v, bytes32 r, bytes32 s,address signer) public view returns(bool state){
         state = ecrecover(keccak256(abi.encodePacked(message)),v,r,s)==signer;
    }
    
}