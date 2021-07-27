/**
 *Submitted for verification at BscScan.com on 2021-07-27
*/

pragma solidity ^0.8.4;
// SPDX-License-Identifier: Unlicensed

contract HelloWorld {
    
    string public name = "";
    
    constructor (string memory _name) {
        name = _name;
    }

    function setName(string memory _name)  public {
        name = _name;
    }
}