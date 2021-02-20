pragma solidity ^0.5.7;

import "./ERC20Standard.sol";

contract TestCoin is ERC20Standard {
	constructor() public {
		totalSupply = 10000;
		name = "TestCoin";
		decimals = 2;
		symbol = "TCO";
		version = "1.0";
		balances[msg.sender] = totalSupply;
	}
}