pragma solidity ^0.5.7;

import "./ERC20Standard.sol";

contract DIGITALDOLLAR is ERC20Standard {
	constructor() public {
		totalSupply = 999000000000000000000;
		name = "Digital Dollar";
		decimals = 5;
		symbol = "DDO";
		version = "1.0";
		balances[msg.sender] = totalSupply;
	}
}