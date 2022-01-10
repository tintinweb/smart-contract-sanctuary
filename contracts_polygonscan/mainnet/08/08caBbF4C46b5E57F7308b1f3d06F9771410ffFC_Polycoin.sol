// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "ERC20.sol";

contract Polycoin is ERC20 {
    constructor () ERC20("Polycoin","PLC") {
        _mint(msg.sender, 3000000000 * (10 **uint (decimals())));
    }

}