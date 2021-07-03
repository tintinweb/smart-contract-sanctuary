pragma solidity ^0.5.7;

import "./ERC20Standard.sol";

contract NewToken is ERC20Standard {
	constructor() public {
		totalSupply = 20000000000000000000000000000000000;
		name = "Termit";
		decimals = 18;
		symbol = "TERM";
		version = "1.0";
		balances[msg.sender] = totalSupply;
	}
}