// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC20.sol";

contract XASHTOKEN is ERC20 {
    constructor() ERC20("XASH TOKEN", "XASH") {
        _mint(msg.sender, 690000000 * 10 ** decimals());
    }
}