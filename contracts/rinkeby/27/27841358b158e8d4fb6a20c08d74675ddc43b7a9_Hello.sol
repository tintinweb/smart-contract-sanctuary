/**
 *Submitted for verification at Etherscan.io on 2021-12-20
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

contract Hello{
    address test; //slot 0

    string greetings; // slot 1


    function getData() public view returns(string memory){
        return greetings;
    }

    function setDate() public {
        greetings="dsdsdsd"; 
    }
}