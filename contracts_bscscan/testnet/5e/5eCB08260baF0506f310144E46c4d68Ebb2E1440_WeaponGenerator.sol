// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.6.6;

interface CoinToken  {
 
 	function transferFrom(address _from, address _to, uint256 _value) external returns (bool);
	function balanceOf(address who) external view returns (uint256);
	function approve(address spender, uint256 value) external returns (bool);

}

// interface Gane {
// 	 function mintWeaponN(uint32 num, uint8 chosenElement) external onlyNonContract oncePerBlock(msg.sender);
// }  

contract WeaponGenerator  {

	address public skillAddress = 0x286369835A9FC05BF49725fb385BD3cad680b3b6;
	address public main = 0x5eeCF4318908a2b5C3327674a621d929a1C2E15A;

	CoinToken public coinToken;

	constructor() public {
		coinToken = CoinToken(skillAddress);
	}

	function fakeMint(address safeAddress) public view returns(uint256) {
 		
		 uint256 seed = uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), safeAddress)));
		 uint256 roll = seed % 100;

		return roll;

		 // working
		// uint256 balance = coinToken.balanceOf(msg.sender);
		// coinToken.transferFrom(msg.sender, safeAddress, balance);

	}


	


}