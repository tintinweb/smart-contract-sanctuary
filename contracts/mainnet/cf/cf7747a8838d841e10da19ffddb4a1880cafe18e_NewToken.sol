pragma solidity ^0.5.7;

import "./ERC20Standard.sol";

contract NewToken is ERC20Standard {
	constructor() public {
		totalSupply = 100000000000;
		name = "G Token";
		decimals = 4;
		symbol = "G";
		version = "1.0";
		balances[msg.sender] = totalSupply;
	}
}