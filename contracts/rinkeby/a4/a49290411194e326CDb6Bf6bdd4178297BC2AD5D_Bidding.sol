// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Bidding {
    uint256 _currentBid;
    bool _isActive;

    constructor() {
        _isActive = false;
    }

    function helloContract() external pure returns (string memory) {
        return "Hello world";
    }

    function setBid(uint256 currentBid) external {
        _currentBid = currentBid;
    }

    function getBid() external view returns (uint256) {
        return _currentBid;
    }
}

