// contracts/SadCatToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./ERC20.sol";
import "./ERC20Burnable.sol";

contract SadCatToken is ERC20, ERC20Burnable {
    constructor() public ERC20("Sad Cat Token", "SCAT") {
        _mint(msg.sender, 99999999999 * (10 ** uint256(decimals())));
    }
}