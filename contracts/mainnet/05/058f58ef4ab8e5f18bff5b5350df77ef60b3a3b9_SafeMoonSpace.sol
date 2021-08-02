// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "./ERC20.sol";

contract SafeMoonSpace is ERC20 {

    constructor () ERC20("SafeMoon Space", "SMOONS") {
        _mint(msg.sender, 85 * (10 ** uint256(decimals())));
    }
}