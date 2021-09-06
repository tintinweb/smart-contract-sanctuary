/**
 *Submitted for verification at Etherscan.io on 2021-09-06
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract StudioName {
    string name;

    constructor(string memory _name) {
       name = _name;
    }

    function getName() public view returns(string memory){
        return name;
    }

    function changeName(string memory newName) public{
         name = newName;
    }
}