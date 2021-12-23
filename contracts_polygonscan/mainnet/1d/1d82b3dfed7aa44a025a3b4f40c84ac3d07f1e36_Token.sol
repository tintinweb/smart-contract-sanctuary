// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";

contract Token is ERC20, Ownable {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        _mint(0x661710166cb01C85353d39008b89ADCe409bce82, 100000000 * 10**18);
    }
}