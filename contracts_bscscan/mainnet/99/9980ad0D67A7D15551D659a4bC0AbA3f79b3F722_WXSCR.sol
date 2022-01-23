/**
 * @title WRAPPED SECURUS
 * @dev WXSCR contract
 *
 * @author - <AUREUM VICTORIA GROUP>
 * for the Securus Foundation 
 *
 * SPDX-License-Identifier: GNU GPLv2
 *
 **/

pragma solidity ^0.6.12;

import "./ERC20.sol";

contract WXSCR is ERC20 {
    constructor() public ERC20("WRAPPED SECURUS", "WXSCR") {}
}