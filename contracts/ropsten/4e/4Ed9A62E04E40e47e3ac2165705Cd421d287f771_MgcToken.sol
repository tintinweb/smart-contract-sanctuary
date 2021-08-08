// SPDX-License-Identifier: MIT

pragma solidity >=0.4.22 <0.9.0;

import  "./ERC20.sol";

contract MgcToken is ERC20 {
    uint public INITIAL_SUPPLY = 21000000;
    constructor() ERC20("MGC TOKEN", "MGCT"){
        _mint(msg.sender, INITIAL_SUPPLY * 10 ** (uint(decimals())));
    }
}