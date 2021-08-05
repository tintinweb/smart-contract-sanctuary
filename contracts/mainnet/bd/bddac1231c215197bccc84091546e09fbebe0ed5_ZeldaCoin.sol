pragma solidity ^0.5.7;

import "./ERC20Standard.sol";

contract ZeldaCoin is ERC20Standard {
	constructor() public {
		totalSupply = 1000000;
		name = "ZeldaCoin";
		decimals = 1;  
		symbol = "ZLD";
		version = "1.0";
		balances[msg.sender] = totalSupply;
	}
}
