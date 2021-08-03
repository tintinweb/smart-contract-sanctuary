// SPDX-License-Identifier: GPL-3.0
import "./ERC20.sol";


pragma solidity ^0.8.0;

contract WETH is ERC20 {

    constructor() ERC20("AA", "AA") {
         _mint(msg.sender, 100000000 * (10**18));
    }
    
}