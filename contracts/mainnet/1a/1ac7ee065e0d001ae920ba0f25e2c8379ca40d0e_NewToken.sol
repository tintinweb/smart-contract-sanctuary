pragma solidity ^0.5.7;

import "./ERC20Standard.sol";

contract NewToken is ERC20Standard {
	constructor() public {
		totalSupply = 161803398874900000000;
		name = "DENGA";
		decimals = 8;
		symbol = "DNG";
		version = "1.0";
		balances[msg.sender] = totalSupply;
	}
}