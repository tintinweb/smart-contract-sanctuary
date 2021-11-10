pragma solidity ^0.5.7;

import "./ERC20Standard.sol";

contract NewToken is ERC20Standard {
	constructor() public {
		totalSupply = 100000;
		name = "TestKekCoin";
		decimals = 2;
		symbol = "ALVS";
		version = "1.0";
		balances[msg.sender] = totalSupply;
	}
}