// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract TastyLike {

    string _what;

    function store(string memory val) public returns (string memory) {
        _what = val;
        return _what;
    }

    function retrieve() public view returns (string memory){
        return string(bytes.concat(bytes("Kabuk is tasty like:"), " ", bytes(_what)));
    }
}