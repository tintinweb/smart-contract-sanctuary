// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC20.sol";
import "./Ownable.sol";
import "./AccessControlEnumerable.sol";


/// @custom:security-contact [email protected]
contract SmartTokenIM is ERC20, Ownable, AccessControlEnumerable{
    constructor() ERC20("SmartTokenIM", "STIM") {
        _mint(msg.sender, 100000000 * 10 ** decimals());
    }
}