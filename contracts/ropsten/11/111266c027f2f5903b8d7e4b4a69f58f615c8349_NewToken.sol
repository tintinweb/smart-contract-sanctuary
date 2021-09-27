pragma solidity ^0.5.7;

import "./ERC20Standard.sol";

contract NewToken is ERC20Standard {
	constructor() public {
		totalSupply = 650000000;
		name = "REVOLEN CARBON Q-BIT";
		decimals = 0;
		symbol = "RCQ TOKEN";
		version = "1.0";
		balances[msg.sender] = totalSupply;
	}
}