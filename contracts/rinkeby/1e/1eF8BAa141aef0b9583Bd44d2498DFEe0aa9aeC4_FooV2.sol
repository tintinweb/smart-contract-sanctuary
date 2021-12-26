// contracts/FooV2.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract FooV2 {
    uint256 public X;

    function GetX() public view returns(uint256) {
        return X;
    }

    function SetX(uint256 x) public{
        X = x;
        emit FooEvent(x);
    }

    event FooEvent(uint256 x);
}