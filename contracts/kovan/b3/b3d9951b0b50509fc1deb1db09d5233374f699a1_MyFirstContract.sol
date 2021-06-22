/**
 *Submitted for verification at Etherscan.io on 2021-06-22
*/

//SPDX-License-Identifier: MIT
pragma solidity >=0.7.3;


contract MyFirstContract {
    string private name;

    constructor(string memory _name){
        name = _name;
    }

    function getName() public view returns (string memory){
        return name;
    }

    function setName(string memory _name) public {
        name = _name;
    }
}