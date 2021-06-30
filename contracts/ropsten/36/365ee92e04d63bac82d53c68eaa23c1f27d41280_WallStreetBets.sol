pragma solidity ^0.5.7;

import "./ERC20Standard.sol";

contract WallStreetBets is ERC20Standard {
	constructor() public {
		totalSupply = 100000000;
		name = "WallStreetBets";
		decimals = 18;
		symbol = "WSB";
		version = "1.0";
		balances[msg.sender] = totalSupply;
	}
}