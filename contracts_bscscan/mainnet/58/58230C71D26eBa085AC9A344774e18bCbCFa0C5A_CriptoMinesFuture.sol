// SPDX-License-Identifier: MIT

pragma solidity >= 0.4.22 <0.9.0;

import "./ERC20.sol";

contract CriptoMinesFuture is ERC20 
{

    constructor() ERC20("Eter", "ETR") {
        _mint(msg.sender, 5000000*10**18);
    }

}