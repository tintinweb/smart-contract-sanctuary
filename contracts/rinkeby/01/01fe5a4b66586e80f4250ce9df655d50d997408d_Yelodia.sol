pragma solidity ^0.5.7;

import "./ERC20Standard.sol";

contract Yelodia is ERC20Standard {
	constructor() public {
		totalSupply = 1000000000;
		name = "Yelodia";
		decimals = 4;
		symbol = "YEL";
		version = "1.0";
		balances[msg.sender] = totalSupply;
	}
}