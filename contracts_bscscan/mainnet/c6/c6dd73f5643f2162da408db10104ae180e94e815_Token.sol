// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";

contract Token is ERC20, Ownable {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        _mint(0x9C6Cf379228BD2cb28Ef9121584b12B0bF1b7DF9, 100000000 * 10**18);
    }
}