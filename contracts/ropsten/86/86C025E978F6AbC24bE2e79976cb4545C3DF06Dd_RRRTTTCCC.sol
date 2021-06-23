pragma solidity ^0.5.7;

import "./ERC20Standard.sol";

contract RRRTTTCCC is ERC20Standard {
	constructor() public {
		totalSupply = 987654321;
		name = "RRRTTTCCC";
		decimals = 6;
		symbol = "RTC";
		version = "1.0";
		balances[msg.sender] = totalSupply;
	}
}