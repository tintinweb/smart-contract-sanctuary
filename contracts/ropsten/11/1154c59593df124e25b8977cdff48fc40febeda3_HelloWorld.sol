/**
 *Submitted for verification at Etherscan.io on 2021-12-13
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract HelloWorld {

    function hello() public pure returns(string memory){
        return "Hello World";
    }

    function helloExternal() external pure returns(string memory){
        return "Hello World External";
    }
}