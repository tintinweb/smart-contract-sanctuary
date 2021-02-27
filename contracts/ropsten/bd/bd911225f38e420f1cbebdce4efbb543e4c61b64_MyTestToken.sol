pragma solidity ^0.8.0;

// SPDX-License-Identifier: UNLICENSED

import "./ERC20.sol";

contract MyTestToken is ERC20 {
    constructor() public ERC20("MyToken", "MTT") {
        super._mint(_msgSender(), 800000000 * 10 ** 18);
    }
}