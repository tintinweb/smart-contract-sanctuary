// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Context.sol";
import "./ERC20Burnable.sol";

/**
 * @title H2OToken
 * @dev ERC20 Token, where all tokens are pre-assigned to the creator.
 * Note they can later distribute these tokens as they wish using `transfer` and other
 * `ERC20` functions.
 */
contract H2OToken is Context, ERC20, ERC20Burnable {

    /**
     * @dev Constructor that gives _msgSender() all of existing tokens.
     */
    constructor () ERC20("H2O Token", "H2O") {
        _mint(_msgSender(), 2000000000 * (10 ** uint256(decimals())));
    }
}