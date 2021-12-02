// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MyMetaCoin {
    uint256 private initialBalance;
    address private owner;

    constructor(address _owner, uint256 _initialBalance) {
        owner = _owner;
        initialBalance = _initialBalance;
    }

    function getBalance() public view returns (uint256) {
        return initialBalance;
    }

    function setBalance(uint256 _initialBalance) public {
        initialBalance = _initialBalance;
    }
}