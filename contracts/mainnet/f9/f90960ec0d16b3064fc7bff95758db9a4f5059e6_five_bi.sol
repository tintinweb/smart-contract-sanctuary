// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "./ERC20.sol";

contract five_bi is ERC20 {
    constructor() ERC20("5Bi", "5Bi") {
        _mint(msg.sender, 1_000_000_000 * (10 ** uint256(decimals())));
    }
}