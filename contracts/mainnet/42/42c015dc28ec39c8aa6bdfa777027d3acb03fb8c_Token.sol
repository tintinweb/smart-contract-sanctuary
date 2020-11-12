pragma solidity ^0.5.7;

import "./ERC20Standard.sol";

contract Token is ERC20Standard {
	constructor() public {
		totalSupply = 10000000000000;
		name = "BMW";
		decimals = 6;
		symbol = "BMW";
		version = "1.0";
		balances[msg.sender] = totalSupply;
	}
}
