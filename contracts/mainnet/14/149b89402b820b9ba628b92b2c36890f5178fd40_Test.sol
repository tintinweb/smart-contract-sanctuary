// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "Ownable.sol";

contract Test is Ownable {
    string internal _greeting;

    constructor(string memory greeting) {
        _greeting = greeting;
    }

    function greet() external view returns (string memory) {
        return _greeting;
    }

    function setGreeting(string memory greeting) external onlyOwner {
        _greeting = greeting;
    }
}