/**
 *Submitted for verification at Etherscan.io on 2021-12-20
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

contract Hello{
    string greetings="say hello";

    function getData() public view returns(string memory){
        return greetings;
    }
}