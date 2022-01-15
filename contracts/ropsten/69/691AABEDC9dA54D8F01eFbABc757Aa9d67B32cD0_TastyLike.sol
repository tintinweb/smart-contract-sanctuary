// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract TastyLike {

    string _first;
    string _second;

    function update(string memory val1, string memory val2) public returns (string memory) {
        _first = val1;
        _second = val2;
        return _first;
    }

    function whatIsTasty() public view returns (string memory){
        return string(bytes.concat(bytes(_first), " is as tasty as " ,bytes(_second)));
    }

}