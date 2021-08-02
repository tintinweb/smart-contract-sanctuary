/**
 *Submitted for verification at Etherscan.io on 2021-08-01
*/

// SPDX-License-Identifier: GPLv2
pragma solidity >=0.4.22 <0.9.0;

contract HelloWorld {
    function hello(string memory _name) public pure returns(string memory){
        return string(abi.encodePacked("Hello, ", _name));
    }
}