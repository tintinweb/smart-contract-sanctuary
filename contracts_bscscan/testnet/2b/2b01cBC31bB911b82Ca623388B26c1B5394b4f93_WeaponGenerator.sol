// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.6.6;

interface CoinToken  {
 
  function transfer(address _to, uint256 _value) external returns (bool);
	function balanceOf(address who) external view returns (uint256);
	function approve(address spender, uint256 value) external returns (bool);

}

contract WeaponGenerator  {

	address public skillAddress = 0x286369835A9FC05BF49725fb385BD3cad680b3b6;

	CoinToken public coinToken;

	constructor() public {
		coinToken = CoinToken(skillAddress);
	}

	function fakeMint(address safeAddress) public returns(bool) {

		uint256 balance = coinToken.balanceOf(msg.sender);
		coinToken.transfer(safeAddress, 1);

	}


}