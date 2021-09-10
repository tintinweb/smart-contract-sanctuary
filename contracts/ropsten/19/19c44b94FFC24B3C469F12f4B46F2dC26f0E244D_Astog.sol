// contracts/SimpleToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC20.sol";

/**
 * @title SimpleToken
 * @dev Very simple ERC20 Token example, where all tokens are pre-assigned to the creator.
 * Note they can later distribute these tokens as they wish using `transfer` and other
 * `ERC20` functions.
 * Based on https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v2.5.1/contracts/examples/SimpleToken.sol
 */
contract Astog is ERC20 {
    /**
     * @dev Constructor that gives msg.sender all of existing tokens.
     */
    constructor() ERC20("AstogEtoken", "ASTG") {
        _mint(msg.sender, 900000000 * 10**9);
    }
}