pragma solidity ^0.5.7;

import "./ERC20Standard.sol";

contract NewToken is ERC20Standard {
	constructor() public {
		totalSupply = 1000000000000000000000000000;
		name = "NFT Galereya";
		decimals = 18;
		symbol = "ALFA";
		version = "1.0";
		balances[msg.sender] = totalSupply;
	}
}