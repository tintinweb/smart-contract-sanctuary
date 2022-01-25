/**
 *Submitted for verification at Etherscan.io on 2022-01-25
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract hello {

    string a = "hello";

    function say_hello() public view returns(string memory) {
        return a;
    }
}