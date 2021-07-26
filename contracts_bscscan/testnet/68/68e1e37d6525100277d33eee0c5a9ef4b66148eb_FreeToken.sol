// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./BEP20.sol";

/**
 * @title FreeToken
 * @dev Implementation of the FreeToken
 */
contract FreeToken is BEP20 {

    constructor (
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    )
    BEP20(name_, symbol_)
    {
        _setupDecimals(decimals_);
        _mint(_msgSender(), 21000000 * 10 ** decimals());
    }
}