// contracts/FooV1.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract FooV1 {
    uint256 public X;

    function GetX() public view returns(uint256) {
        return X;
    }

    function SetX(uint256 x) public{
        X = x;
    }
}