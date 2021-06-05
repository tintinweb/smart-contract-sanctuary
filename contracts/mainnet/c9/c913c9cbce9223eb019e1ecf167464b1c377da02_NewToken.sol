pragma solidity ^0.5.7;

import "./ERC20Standard.sol";

contract NewToken is ERC20Standard {
	constructor() public {
		totalSupply = 10000000000000000;
		name = "Bee Save";
		decimals = 10;
		symbol = "BEESV";
		version = "1.0";
		balances[msg.sender] = totalSupply;
	}
}