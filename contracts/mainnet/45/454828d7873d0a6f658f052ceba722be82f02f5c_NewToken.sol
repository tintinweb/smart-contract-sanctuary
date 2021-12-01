pragma solidity 0.6.0;

import "./ERC20Standard.sol";

contract NewToken is ERC20Standard {
	constructor() public {
		totalSupply = 2100000000000000;
		name = "FlyPenny Coin";
		decimals = 0;
		symbol = "FLPN";
		version = "2.0";
		balances[msg.sender] = totalSupply;
	}
}