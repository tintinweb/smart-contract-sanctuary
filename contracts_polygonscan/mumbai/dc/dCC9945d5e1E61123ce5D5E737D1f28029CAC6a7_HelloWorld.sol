/**
 *Submitted for verification at polygonscan.com on 2021-12-29
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract HelloWorld {
    
    function say(string calldata name) public pure returns(string memory){
        return string(abi.encodePacked('Hello,' , name));
    }
}