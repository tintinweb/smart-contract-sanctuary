// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "../ERC20.sol";

/// @custom:security-contact [email protected]
contract MediciEffect is ERC20 {
    constructor() ERC20("Medici Effect", "MEF") {
        _mint(msg.sender, 42000 * 10 ** decimals());
    }
}