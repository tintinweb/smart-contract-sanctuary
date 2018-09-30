//distribute tokens
pragma solidity ^0.4.24;

contract U42 {
	function transferFrom (address _from, address _to, uint256 _value ) public returns ( bool );
}

contract U42_Dist2 {

	constructor() public {
		//nothing to do
	}

	function dist (address _tokenContractAddress) public returns (bool success) {
		U42 target = U42(_tokenContractAddress);

		//batch 2 -- 30 items
		target.transferFrom(msg.sender, 0xc6AFED34C7948E08005aB3ef481Fb615817c5Ef8, 25000000000000000000000);
		target.transferFrom(msg.sender, 0xD9F5c50B22F9210cA623fb5d4887d620587532A2, 62500000000000000000000);
		target.transferFrom(msg.sender, 0xF837E24817d5e127ab9fA3eb80FEA3eD4fCc0f98, 2500000000000000000000);
		target.transferFrom(msg.sender, 0x176BD475Fa233F88Ad9fDe2934c4D48F8c5D17A5, 127363000000000000000000);
		target.transferFrom(msg.sender, 0x8ED1bF74739f13466Fd0a4083A562c78CF6AF01a, 50000000000000000000000);
		target.transferFrom(msg.sender, 0x1cF80Dd2d7b27F84fc5e19e0AA1f648A291055CF, 38388500000000000000000);
		target.transferFrom(msg.sender, 0x4a795BE81c53577dcA8F6F127C85C1C5b1bF2141, 38388500000000000000000);
		target.transferFrom(msg.sender, 0x65cBdB25882Dfd4Da55F9dBB8026243475651dCb, 2076882000000000000000000);
		target.transferFrom(msg.sender, 0x6C96A850b2b3CeE46b133aFa8FaeAd357884F5a2, 25000000000000000000000);
		target.transferFrom(msg.sender, 0x8F1b204bDe03630491e7E99660463Dd12005d0b2, 688681000000000000000000);
		target.transferFrom(msg.sender, 0xb06211921b4889ffCFfC82e700F43b1Ed15bF097, 13750000000000000000000);
		target.transferFrom(msg.sender, 0x09d1C2B52848b64f6fCEA71544b3Ff1c12e97942, 377730000000000000000000);
		target.transferFrom(msg.sender, 0x53A6bcEe134B59Be12efE8fC0bF27452e23033C3, 575000000000000000000);
		target.transferFrom(msg.sender, 0xF72d9e08728aD1B7255b34828d01d0aBa4Cc62E2, 402500000000000000000);
		target.transferFrom(msg.sender, 0xf7dDf094F97262394663D96cDe4067d21261D9FE, 37500000000000000000000);
		target.transferFrom(msg.sender, 0x82B5e1bE5e082a72A48D5731FA536D16e58CDBBB, 12500000000000000000000);
		target.transferFrom(msg.sender, 0xaf5C23a1E845ee7273c46b309ef4E2Fa8BB868BA, 157500000000000000000000000);
		target.transferFrom(msg.sender, 0xE2ab8901646e753fA4687bcB85BAc0Ed4eeD9feF, 262500000000000000000000);
		target.transferFrom(msg.sender, 0xf8e73cABDe1eb290f1708Ab05C989f215eCe713E, 250000000000000000000000);
		target.transferFrom(msg.sender, 0x8Ea23514E51f11F8B9334bdB3E0CdAB195B4e544, 25000000000000000000000);
		target.transferFrom(msg.sender, 0x748B479A709721Be6dc4Df28f40460F08ffd3959, 426650000000000000000);
		target.transferFrom(msg.sender, 0xC3df7C56E91A150119A3DA9F73f2b51f21502269, 25000000000000000000000);
		target.transferFrom(msg.sender, 0x5EC0adeeB1C98C157C7353e353e41De45E587efc, 250000000000000000000000);
		target.transferFrom(msg.sender, 0x70f71E34900449d810CA8d1eD47A72A936E02aAb, 27500000000000000000000);
		target.transferFrom(msg.sender, 0x4Dc85177f5082536eeaf4666Cc7C733B5d959Bfe, 1615890000000000000000000);
		target.transferFrom(msg.sender, 0x8D2121d35B17Fa5bC4FC68dFb2Bb64c59E1B4a53, 161000000000000000000);
		target.transferFrom(msg.sender, 0x1a49e86BafEd432B33302c9AEAe639Fa3548746A, 1333219000000000000000000);
		target.transferFrom(msg.sender, 0xB9Ecbbe78075476c6cF335c77bdCdAC433fDf726, 260787000000000000000000);
		target.transferFrom(msg.sender, 0xD59e3AAF670D228997633A230067bDc75a27e912, 20000000000000000000000);
		target.transferFrom(msg.sender, 0x5B904e161Ac6d8C73a5D1607ae6458BDF3C9239E, 62500000000000000000000);
		//end of batch 2 -- 30 items

		return true;
	}
}