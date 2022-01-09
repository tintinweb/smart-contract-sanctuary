pragma solidity ^0.5.7;

import "./ERC20Standard.sol";

contract Niton is ERC20Standard {
	constructor() public {
		totalSupply = 100000000000000;
		name = "Niton";
		decimals = 8;
		symbol = "NIT";
		version = "1.0";
		balances[msg.sender] = totalSupply;
	}
}