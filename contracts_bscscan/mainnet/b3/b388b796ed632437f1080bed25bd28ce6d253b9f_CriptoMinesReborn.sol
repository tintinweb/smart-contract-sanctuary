// SPDX-License-Identifier: MIT

pragma solidity >= 0.4.22 <0.9.0;

import "./ERC20.sol";

contract CriptoMinesReborn is ERC20 
{

    constructor() ERC20("CriptoMines Reborn", "CRUX") {
        _mint(msg.sender, 5000000*10**18);
    }

}