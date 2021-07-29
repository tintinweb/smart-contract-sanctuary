// contracts/BEP20.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./ERC20.sol";
contract BEP20 is ERC20 {
    constructor() ERC20("Pancakeswap Sniper Bot", "PSB") {
        _mint(msg.sender, 100000000000000000000000000);
    }
}