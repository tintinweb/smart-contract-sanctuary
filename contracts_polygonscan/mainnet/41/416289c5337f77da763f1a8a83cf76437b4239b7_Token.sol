// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";

contract Token is ERC20 {

    constructor () ERC20("Eternals", "ETS") {
        _mint(msg.sender, 10000000000000 * (10 ** uint256(decimals())));
    }
}