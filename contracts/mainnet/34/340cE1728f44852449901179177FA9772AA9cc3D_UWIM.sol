pragma solidity ^0.5.7;

import "./ERC20Standard.sol";

contract UWIM is ERC20Standard {
	constructor() public {
		totalSupply = 500000000000000;
		name = "UWIM";
		decimals = 5;
		symbol = "UWIM";
		version = "1.0";
		balances[msg.sender] = totalSupply;
	}
}