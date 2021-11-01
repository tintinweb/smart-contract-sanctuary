// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "ERC20.sol";

contract SHIB20 is ERC20 {
    constructor() ERC20("SHIB20", "SHARES") {
        _mint(msg.sender, 600000000000000 * 10 ** decimals());
    }
}