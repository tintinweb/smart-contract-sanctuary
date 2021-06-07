/**
 *Submitted for verification at Etherscan.io on 2021-06-07
*/

//SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.7.0 <0.9.0;

contract basictest {
    
    mapping(bytes32 => bytes32) public pixels;
    
    function test_num(bytes32 id, bytes32 content) public {
        pixels[id] = content;
    }

}

//44093
//26981
//44144