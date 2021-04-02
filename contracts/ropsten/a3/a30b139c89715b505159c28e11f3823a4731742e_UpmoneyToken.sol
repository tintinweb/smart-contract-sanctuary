pragma solidity ^0.5.7;

import "./ERC20Standard.sol";

contract UpmoneyToken is ERC20Standard {
	constructor() public {
		totalSupply = 600000;
		name = "Up Money";
		decimals = 18;
		symbol = "UPMN";
		version = "1.0";
		balances[msg.sender] = totalSupply;
	}
}