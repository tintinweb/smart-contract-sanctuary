// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "ERC20.sol";

/// @custom:security-contact [email protected]
contract Checkmate is ERC20 {
    constructor() ERC20("Checkmate", "CHM") {
        _mint(msg.sender, 100000000 * 10 ** decimals());
    }
}