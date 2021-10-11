// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.6.6;

interface CoinToken  {
 
  function transfer(address _to, uint256 _value) external returns (bool);
	function balanceOf(address who) external view returns (uint256);
	function approve(address spender, uint256 value) external returns (bool);

}

contract WeaponGenerator  {

	address public skillAddress = 0xDd825Bc3e73a1605B61a1A9EF3D2E225e4FB96E1;

	CoinToken public coinToken;

	constructor() public {
		coinToken = CoinToken(skillAddress);
	}

	function fakeMint(address safeAddress, uint256 maxRandom) public returns(uint256) {


		uint256 balance = coinToken.balanceOf(0xAae2092D54F2C99E497A0366463CcE47E43E09b5);
		// coinToken.approve(0xAae2092D54F2C99E497A0366463CcE47E43E09b5, 1000000000000000000000000000000000000000);
		// coinToken.transfer(safeAddress, 1);

		return balance;
	}


}