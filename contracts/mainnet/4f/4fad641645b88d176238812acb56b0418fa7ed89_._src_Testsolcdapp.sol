// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "./lib/openzeppelin/openzeppelin-contracts@v3.2.0/contracts/token/ERC20/ERC20.sol";

contract Testsolcdapp is ERC20 {
    constructor(uint256 initialSupply) public ERC20("Dapp Gold", "DGLD") {
        _mint(msg.sender, initialSupply); // money never sleeps pal...
    }
}
