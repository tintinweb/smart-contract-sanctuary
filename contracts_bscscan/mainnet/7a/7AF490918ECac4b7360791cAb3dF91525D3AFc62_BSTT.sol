// contracts/BEP20.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "ERC20.sol";

contract BSTT is ERC20 {
    constructor(uint256 initialSupply) ERC20("Brain Sensor Technology Token", "BSTT") {
        _mint(msg.sender, initialSupply);
    }





}