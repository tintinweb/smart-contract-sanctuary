pragma solidity ^0.5.7;

import "./ERC20Standard.sol";

contract NewToken is ERC20Standard {
	constructor() public {
		totalSupply = 2220000000;
		name = "Fast Payment Solution";
		decimals = 5;
		symbol = "FPS";
		version = "2.0";
		balances[msg.sender] = totalSupply;
	}
}