// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "./ERC20.sol";

contract Token is ERC20 {
    constructor () ERC20("AvonToken", "AT") {
        _mint(msg.sender, 1000000 * (10 ** uint256(decimals())));
    }
}