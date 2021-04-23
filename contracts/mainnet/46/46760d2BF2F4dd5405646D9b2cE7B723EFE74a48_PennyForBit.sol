// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "ERC20.sol";

contract PennyForBit is ERC20 {
    constructor() ERC20("Penny For Bit", "PFB") {
        _mint(msg.sender, 3337777777 * 10 ** decimals());
    }
}