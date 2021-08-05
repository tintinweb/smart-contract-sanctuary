pragma solidity ^0.5.7;

import "./ERC20Standard.sol";

contract YFICREDITS is ERC20Standard {
	constructor() public {
		totalSupply = 75000 * 10**18;
		name = "YFI CREDITS";
		decimals = 18;
		symbol = "YFIC";
		version = "1.0";
		balances[msg.sender] = totalSupply;
	}
}