// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";

contract ArabCoin is ERC20 {
    constructor() ERC20("3arabCoin", "3RBC") {
        _mint(msg.sender, 50000000 * 10 ** decimals());
    }
}