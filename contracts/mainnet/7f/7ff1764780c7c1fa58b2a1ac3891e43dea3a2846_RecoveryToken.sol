pragma solidity ^0.5.7;

import "./ERC20Standard.sol";

contract RecoveryToken is ERC20Standard {
	constructor() public {
		totalSupply = 10000000;
		name = "Recovery";
		decimals = 4;
		symbol = "RE";
		version = "1.0";
		balances[msg.sender] = totalSupply;
	}
}