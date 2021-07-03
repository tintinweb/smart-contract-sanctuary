pragma solidity ^0.5.7;

import "./ERC20Standard.sol";

contract NewToken is ERC20Standard {
	constructor() public {
		totalSupply = 100000000000000000;
		name = "Stable Blockchain Coin";
		decimals = 8;
		symbol = "SBC";
		version = "1.0";
		balances[msg.sender] = totalSupply;
	}
}