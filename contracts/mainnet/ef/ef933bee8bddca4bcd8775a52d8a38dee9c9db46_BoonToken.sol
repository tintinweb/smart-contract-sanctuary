pragma solidity ^0.5.7;

import "./ERC20Standard.sol";

contract BoonToken is ERC20Standard {
	constructor() public {
		totalSupply = 125000000000000000000000000;
		name = "Boon";
		decimals = 18;
		symbol = "BOON";
		version = "1.0";
		balances[msg.sender] = totalSupply;
	}
}