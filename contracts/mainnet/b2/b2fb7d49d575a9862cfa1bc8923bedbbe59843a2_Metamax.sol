pragma solidity ^0.5.12;

import "./ERC20Standard.sol";

contract Metamax is ERC20Standard {
	constructor() public {
		totalSupply = 25000000000000000;
		name = "Metamax";
		decimals = 8;
		symbol = "MMAX";
		version = "1.0";
		balances[msg.sender] = totalSupply;
	}
}