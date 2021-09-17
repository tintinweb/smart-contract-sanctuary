pragma solidity ^0.5.7;

import "./ERC20Standard.sol";

contract NewToken is ERC20Standard {
	constructor() public {
		totalSupply = 50000000000;
		name = "MagicBean";
		decimals = 0;
		symbol = "MB";
		version = "1.0";
		balances[msg.sender] = totalSupply;
	}
}