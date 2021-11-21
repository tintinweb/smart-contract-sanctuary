// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC20.sol";
import "./Ownable.sol";
import "./AccessControlEnumerable.sol";


/// @custom:security-contact [email protected]
contract KarlFriedrichFundToken is ERC20, Ownable, AccessControlEnumerable{
    constructor() ERC20("Karl Friedrich Fund Token", "KFFT") {
        _mint(msg.sender, 1000000000 * 10 ** decimals());
    }
}