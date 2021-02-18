// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.7.4;

import "./ERC20.sol";

contract PurusToken is ERC20 {
    constructor() public ERC20("Purus Stock Option Tokens 1", "PSOT1") {
        _mint(msg.sender, 20000 ether);
    }
}