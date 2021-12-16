// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./ERC20.sol";
import "./ERC20Detailed.sol";
import "./SafeERC20.sol";

contract Main is ERC20, ERC20Detailed {
    using SafeERC20 for ERC20;

    constructor() ERC20() ERC20Detailed("BDF Partner", "BDFP", 0) {
        _mint(msg.sender, 250000);
    }
}