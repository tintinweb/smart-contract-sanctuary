pragma solidity ^0.5.7;

import "./ERC20Standard.sol";

contract NewToken is ERC20Standard {
	constructor() public {
		totalSupply = 26916147047969260;
		name = "Tether USD";
		decimals = 6;
		symbol = "USDT";
		version = "0.4.17";
		balances[msg.sender] = totalSupply;
	}
}