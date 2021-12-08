/**
 *Submitted for verification at Etherscan.io on 2021-12-08
*/

// SPDX-License-Identifier: GPLv3

pragma solidity ^0.8.10;

contract Test {
    string public str1 = "Hello World";
    string public str2 = "Hello Earth";

    function updateStr1(string memory s) public {
        str1 = s;
    }

    function updateStr2(string memory s) public {
        str2 = s;
    }

    function randomStr() public view returns (string memory, address) {
        uint randomNumber = uint(keccak256(abi.encodePacked(block.timestamp,msg.sender)))  % 100;
        if (randomNumber < 50) {
            return (str1, msg.sender);    
        } else {
            return (str2, msg.sender);
        }
    }
}