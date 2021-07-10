pragma solidity ^0.5.7;

import "./ERC20Standard.sol";

contract NewToken is ERC20Standard {
	constructor() public {
		totalSupply = 1618033988749000;
		name = "CUBEST";
		decimals = 3;
		symbol = "CBS";
		version = "1.0";
		balances[msg.sender] = totalSupply;
	}
}