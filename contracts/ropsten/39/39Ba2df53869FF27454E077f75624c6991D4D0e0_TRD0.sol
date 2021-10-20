pragma solidity ^0.8.7;

import "./ERC20Standard.sol";

contract TRD0 is ERC20Standard {
	constructor() public {
		totalSupply = 250000;
		name = "Trood Coin 0";
		decimals = 4;
		symbol = "TRD0";
		version = "1.0";
		balances[msg.sender] = totalSupply;
	}

	event Bought(uint256 amount);

	function buy() payable public {
		uint256 amountTobuy = msg.value;
		uint256 dexBalance = balanceOf(address(this));
		require(amountTobuy > 0, "You need to send some ether");
		require(amountTobuy <= dexBalance, "Not enough tokens in the reserve");
		this.transfer(msg.sender, amountTobuy*1000);
		emit Bought(amountTobuy*1000);
	}

}