// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract TastyLike {

    string what;

    function store(string memory val) public returns (string memory) {
        what = val;
        return what;
    }

    function retrieve() public view returns (string memory){
        return string(bytes.concat(bytes("Kabuk is tasty like:"), " ", bytes(what)));
    }
}