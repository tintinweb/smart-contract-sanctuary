/**
 *Submitted for verification at Etherscan.io on 2021-04-28
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;
contract Poem{
    string public poemmessage;
    function myData(string memory x) public{
        poemmessage = x;
    }
}