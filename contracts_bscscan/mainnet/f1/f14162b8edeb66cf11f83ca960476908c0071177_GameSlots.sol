// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "./ERC20.sol";
import "./ERC20Burnable.sol";

contract GameSlots is ERC20, ERC20Burnable {
    constructor() ERC20("GEM Slots Token", "GEM") {
        _mint(0xD86a30C865936AF2516EDE53830FC9f791734E61,  10000000000 * 10 ** decimals());
        _mint(0x249aFaE22512d24B1829b0E9693Ba92B7B0C2efD, 190000000000 * 10 ** decimals());
        _mint(0x7D3b630324f80a664b178f699b548D9e30321a66, 400000000000 * 10 ** decimals());
        _mint(msg.sender, 400000000000 * 10 ** decimals());
    }
}