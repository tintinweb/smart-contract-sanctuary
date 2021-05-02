// SPDX-License-Identifier: MIT
pragma solidity ^0.6.2;

import "erc20.sol";

contract Token is ERC20 {

    constructor () public ERC20("VIAGRA", "VIAGRA") {
        _mint(msg.sender, 1000000 * (10 ** uint256(decimals())));
    }
}