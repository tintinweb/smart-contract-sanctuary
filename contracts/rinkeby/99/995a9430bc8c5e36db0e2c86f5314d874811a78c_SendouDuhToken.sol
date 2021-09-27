// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";

//import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract SendouDuhToken is ERC20 {
    constructor(uint256 initialSupply) ERC20("SENDOUDUH", "SDUD") {
        _mint(msg.sender, initialSupply);
    }

    // function mintMinerReward() public {
    //     _mint(block.coinbase, 1000);
    // }
}