// SPDX-License-Identifier: MIT
pragma solidity 0.7.0;

contract Dummy {
    uint256 x;
    constructor() {}
    function setX(uint256 _x) public {
        x = _x;
    }

    function getX() public returns(uint256) {
        return x;
    }

}