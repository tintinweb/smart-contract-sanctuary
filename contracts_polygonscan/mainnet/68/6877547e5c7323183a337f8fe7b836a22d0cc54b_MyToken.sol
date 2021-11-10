// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./ERC20.sol";

contract MyToken is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        //The total count is 1,000,000, and no additional issuance is allowed
        _mint(msg.sender, 1000000 * 10**uint(decimals()));
    }
}