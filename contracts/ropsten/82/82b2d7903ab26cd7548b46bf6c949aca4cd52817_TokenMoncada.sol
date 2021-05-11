pragma solidity ^0.8.0;
// SPDX-License-Identifier:MIT
import "ERC20.sol";

contract TokenMoncada is ERC20 {

	constructor(uint256 initialSupply) ERC20("MoncadaToken", "MOT") {
        _mint(msg.sender, initialSupply);
    }
}