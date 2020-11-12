pragma solidity ^0.5.7;

import "./ERC20Standard.sol";

contract NewToken is ERC20Standard {
	constructor() public {
		totalSupply = 600000;
		name = "DirectEx";
		decimals = 18;
		symbol = "DRRS";
		version = "1.0";
		balances[msg.sender] = totalSupply;
	}
}
