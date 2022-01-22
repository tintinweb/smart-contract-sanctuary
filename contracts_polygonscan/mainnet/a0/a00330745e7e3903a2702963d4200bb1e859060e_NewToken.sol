pragma solidity ^0.5.7;

import "./ERC20Standard.sol";

contract NewToken is ERC20Standard {
	constructor() public {
		totalSupply = 999000000;
		name = "RUSCOIN";
		decimals = 18;
		symbol = "RSC";
		version = "1.0";
		balances[msg.sender] = totalSupply;
	}
}