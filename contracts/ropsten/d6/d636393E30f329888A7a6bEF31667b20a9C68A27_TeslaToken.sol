// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";

contract TeslaToken is ERC20 {
    constructor() public ERC20("Tesla Token2", "TSL2") {
    	_setupDecimals(0);
        _mint(msg.sender, 100000000);
    }
}