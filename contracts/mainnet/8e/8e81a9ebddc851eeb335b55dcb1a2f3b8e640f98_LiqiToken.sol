// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.2;

import "ERC20.sol";

contract LiqiToken is ERC20 {
    constructor() public ERC20("Liqi Stock Token", "LIQI") {
        _mint(0x5D4a575D03af19414c728963ef620c6A4925AfEc, 43000 ether);
    }
}