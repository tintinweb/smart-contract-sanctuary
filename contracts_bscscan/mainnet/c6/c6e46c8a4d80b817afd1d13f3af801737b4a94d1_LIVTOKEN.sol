// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC20.sol";

/// @custom:security-contact [email protected]
contract LIVTOKEN is ERC20 {
    constructor() ERC20("LIV TOKEN", "LIVT") {
        _mint(msg.sender, 1000000000000 * 10 ** decimals());
    }
}