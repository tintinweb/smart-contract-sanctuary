/**
 *Submitted for verification at Etherscan.io on 2021-11-25
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract InfoContract {
    string name;
    uint age;

    event InfoChanged(string _name, uint256 _age);

    function setInfo(string memory _name, uint256 _age) public {
        name = _name;
        age = _age;
        emit InfoChanged(_name, _age);
    }

    function getInfo() public view returns (string memory, uint256) {
        return (name, age);
    }
}