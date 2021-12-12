/**
 *Submitted for verification at polygonscan.com on 2021-12-11
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract DemoNameIt {
    string private name;

    constructor(string memory _name) {
        name = _name;
    }

    function getName() public view returns (string memory) {
        return name;
    }

    function setName(string memory _name) public {
        name = _name;
    }
}