// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./ERC20.sol";
import "./ERC20Detailed.sol";
import "./SafeERC20.sol";

contract Main is ERC20, ERC20Detailed {
    using SafeERC20 for ERC20;

    constructor() ERC20() ERC20Detailed("BuildDefiV1", "BDFv1", 9) {
        _mint(msg.sender, 10000000000 * (uint256(10)**9));
    }
}