// contracts/GLDToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "ERC20.sol";

contract VLTTToken is ERC20 {
   constructor(uint256 initialSupply) ERC20("VoltCoin", "VLTT") {
       _mint(msg.sender, initialSupply);
   }
}