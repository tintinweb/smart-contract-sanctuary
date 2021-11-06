// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./F1DriverERC20.sol";

contract MaxVerstappen is F1DriverERC20 {

    constructor() F1DriverERC20("Max Verstappen", "VER33") {
        _mint(msg.sender, 2573000000000 * 10 ** decimals());
    }

}