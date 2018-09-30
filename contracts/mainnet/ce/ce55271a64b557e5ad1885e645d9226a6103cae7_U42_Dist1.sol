//distribute tokens
pragma solidity ^0.4.24;

contract U42 {
	function transferFrom (address _from, address _to, uint256 _value ) public returns ( bool );
}

contract U42_Dist1 {

	constructor() public {
		//nothing to do
	}

	function dist (address _tokenContractAddress) public returns (bool success) {
		U42 target = U42(_tokenContractAddress);

		//batch 1 -- 30 items
		target.transferFrom(msg.sender, 0x74fBaA54034e56c33696BD4620956DE244A64622, 1826301369863010000000000);
		target.transferFrom(msg.sender, 0xfD5D74cE99863d2b43E7112d071435D70A5e5B7f, 230000000000000000000);
		target.transferFrom(msg.sender, 0xb5515d9EdC28D6D2d6Bee2879D0Dc4Bb12384a6a, 100000000000000000000000);
		target.transferFrom(msg.sender, 0xB6C7271bE1495b7904535e593fe0230DAee39c6E, 125000000000000000000000);
		target.transferFrom(msg.sender, 0x19B341bA9684479Ea4aAE77EF15B9854540Adc8e, 63750000000000000000000);
		target.transferFrom(msg.sender, 0x025842922e685067dAf777000a4Cc64f49104D2e, 598000000000000000000);
		target.transferFrom(msg.sender, 0x5c842A4F93bbD06b73A69C5Cb12a1430C6f37BA3, 136500000000000000000000);
		target.transferFrom(msg.sender, 0x05AE0683d8B39D13950c053E70538f5810737bC5, 136500000000000000000000);
		target.transferFrom(msg.sender, 0x465358B08b72CED3b72Bd05565c636791E22FbDD, 112500000000000000000000);
		target.transferFrom(msg.sender, 0x1d26933d2900e187B591C54faabb1eb9e35f1CA6, 641700000000000000000);
		target.transferFrom(msg.sender, 0xd1842e28342164b8613ceFA50F1e182b82C3304B, 187500000000000000000000);
		target.transferFrom(msg.sender, 0x1d1408eaB849FfF6DAC10E79FBB247555F84a604, 187500000000000000000000);
		target.transferFrom(msg.sender, 0xf4F490F7BB3B0440A898757A0876Fcef5b02Db10, 1250000000000000000000);
		target.transferFrom(msg.sender, 0x383E163cA4247633548973b4174c68a3BeD498A5, 2500000000000000000000);
		target.transferFrom(msg.sender, 0xcE820782D117e0B851CA5BeD64bD33975f59612c, 2556164000000000000000000);
		target.transferFrom(msg.sender, 0x2951f76ad5078aedb6CB5F61bf8203E8B3cf8c4E, 668578000000000000000000);
		target.transferFrom(msg.sender, 0x07E4286dcE50c0b1c26551cA0A250Dc0492204C4, 50000000000000000000000);
		target.transferFrom(msg.sender, 0x087aB63b03a9DB48dC8cE2380aA9327D0E7845b9, 25000000000000000000000);
		target.transferFrom(msg.sender, 0x2E5aD3Af0BFB366ffcECc22D6DB4025F3e85650B, 6250000000000000000000);
		target.transferFrom(msg.sender, 0xeEcEEE2C5D941e969fDd2C40E184af35F794bcc7, 64203000000000000000000);
		target.transferFrom(msg.sender, 0x2c26BfDD4442235A3Ee9E403f3d7F812E53470bB, 25000000000000000000000);
		target.transferFrom(msg.sender, 0xBaabf2E7791b3D93402aBd1faEEDF54f6b9c0342, 250000000000000000000000);
		target.transferFrom(msg.sender, 0xC84B023a1B922248328F4F9C61eA07Aff3085f4b, 10000000000000000000000);
		target.transferFrom(msg.sender, 0x80F3d74f1c4f48Fc158cFBDC61fB8E37b1B76F21, 938000000000000000000);
		target.transferFrom(msg.sender, 0x0b30dE228D47393D190CAd5348D1D1d360D3fF2d, 64443000000000000000000);
		target.transferFrom(msg.sender, 0x6876585122CE7715945a5E1dc701E883CABE8c37, 12500000000000000000000);
		target.transferFrom(msg.sender, 0x478B830b5369eFB50532759BfE3586Ce64De250F, 625000000000000000000000);
		target.transferFrom(msg.sender, 0x87ca4Bc3075fd2E22524cafB5610d6aAf2fC56ef, 659589000000000000000000);
		target.transferFrom(msg.sender, 0x9eCA18Db1B457E1Fc2D8771009a31A214bF0000B, 856755000000000000000000);
		target.transferFrom(msg.sender, 0xA7e9c87B52b858e83440e8966dd4B688B1178538, 308750000000000000000000);
		//end of batch 1 -- 30 items

		return true;
	}
}