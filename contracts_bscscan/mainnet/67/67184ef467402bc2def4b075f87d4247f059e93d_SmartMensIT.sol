// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC20.sol";
import "./Ownable.sol";
import "./AccessControlEnumerable.sol";


/// @custom:security-contact [email protected]
contract SmartMensIT is ERC20, Ownable, AccessControlEnumerable{
    constructor() ERC20("SmartMensIT", "SMIT") {
        _mint(msg.sender, 10000000 * 10 ** decimals());
    }
}