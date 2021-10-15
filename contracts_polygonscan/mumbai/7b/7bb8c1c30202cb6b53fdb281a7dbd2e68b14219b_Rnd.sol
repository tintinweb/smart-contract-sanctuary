/**
 *Submitted for verification at polygonscan.com on 2021-10-15
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Rnd {
    mapping(uint256 => uint256) public rands;
    
    constructor(){
        for(uint256 i=0;i<30;i++){
            rands[i]=rand(100,i);
        }
    }
    
    function rand(uint256 _length,uint256 dynamic) public view returns(uint256) {
        uint256 random = uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp,dynamic)));
        return random%_length;
    }
}