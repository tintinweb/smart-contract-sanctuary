// SPDX-License-Identifier: MIT
pragma solidity  ^0.8.0;

import "./ERC20.sol";


contract RLT is ERC20{
    constructor(address _revAddress) ERC20("Relife Token","RLT"){
        _mint(_revAddress, 2100000000 *  10 ** 18);
    }
}