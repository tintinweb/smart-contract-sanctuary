// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";

// 72000000000000000000000000 = 72*10**6 * 10**18
contract MorningStar is ERC20 {
    constructor (
        uint256 initialSupply
        ) ERC20("MorningStar", "MorningStar") {
        _mint(msg.sender, initialSupply);
    }
}