// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";

contract CreateERC20
{
    ERC20 public HvarCoin;

    constructor()
    {
        HvarCoin = new ERC20("HvarCoin", "HVAR", 1000000000, 2);
    }
}