// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./ERC20.sol";
import "./Owner.sol";
import "./ERC20Burnable.sol";

contract SV7 is ERC20, Ownable, ERC20Burnable {
    constructor () ERC20("7Plus Coin", "SV7", 18) {
        _mint(msg.sender, 200000000 * (10 ** uint256(decimals())));
    }
}