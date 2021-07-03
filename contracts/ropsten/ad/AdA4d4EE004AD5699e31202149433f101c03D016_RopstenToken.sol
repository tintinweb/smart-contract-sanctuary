// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Token.sol";

contract RopstenToken is Token {
    function setDecimals(uint8 decimals_) external onlyOwner {
        _decimals = decimals_;
    }
}