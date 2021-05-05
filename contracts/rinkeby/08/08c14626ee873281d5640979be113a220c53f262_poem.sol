/**
 *Submitted for verification at Etherscan.io on 2021-05-05
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.4.24;
contract poem{
    string public poem;
    
    function poem_push(string x) public{
        poem = x;
    }
}