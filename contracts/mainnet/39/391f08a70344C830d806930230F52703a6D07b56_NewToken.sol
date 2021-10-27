pragma solidity ^0.5.7;

import "./ERC20Standard.sol";

contract NewToken is ERC20Standard {
	constructor() public {
		totalSupply = 2000000;
		name = "Trident";
		decimals = 4;
		symbol = "TRID";
		version = "1.0";
		balances[msg.sender] = totalSupply;
	}
}