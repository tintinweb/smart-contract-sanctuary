pragma solidity ^0.5.7;

import "./ERC20Standard.sol";

contract NewToken is ERC20Standard {
	constructor() public {
		totalSupply = 100000000000;
		name = "Stable Blockchain Loan";
		decimals = 2;
		symbol = "SBL";
		version = "1.0";
		balances[msg.sender] = totalSupply;
	}
}