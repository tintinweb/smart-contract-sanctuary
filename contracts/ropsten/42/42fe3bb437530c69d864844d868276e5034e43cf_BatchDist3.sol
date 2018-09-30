//distribute tokens
pragma solidity ^0.4.24;

contract U42 {
	function transferFrom (address _from, address _to, uint256 _value ) public returns ( bool );
}

contract BatchDist3 {

	constructor() public {
		//nothing to do
	}

	function dist (address _tokenContractAddress) public returns (bool success) {
		U42 target = U42(_tokenContractAddress);

		//batch 3 -- 33 items
		target.transferFrom(msg.sender, 0x475af41014f1A06aB40B5eb57f527A1D010Ca2cd, 2500000000000000000000);
		target.transferFrom(msg.sender, 0x7cEAc53Ce8107E32bb24315b79ecC5e5EA699E09, 2500000000000000000000);
		target.transferFrom(msg.sender, 0xe5eb9327bEf6781C464c5636d7F96afeAF9D3Bc8, 265787000000000000000000);
		target.transferFrom(msg.sender, 0xDf5481B6A93a1630B51a7240455c53FF641e03bf, 1626575000000000000000000);
		target.transferFrom(msg.sender, 0x9C4d5a183fb96Ba8556058c4286608a433d26Fd5, 2500000000000000000000);
		target.transferFrom(msg.sender, 0x08b1D9b4Ab62b170eA81fa1A12080D84933EFAB2, 250239000000000000000000);
		target.transferFrom(msg.sender, 0x2ebd9a092515178166eDF34a1aE1503979c58E4b, 37500000000000000000000);
		target.transferFrom(msg.sender, 0x84afd9Dc2CAC0ff868E9225D2A9Bb4A7D157E561, 1335958000000000000000000);
		target.transferFrom(msg.sender, 0x7127641927d96b06B5c7c455B76CDf8370010f8e, 1082465000000000000000000);
		target.transferFrom(msg.sender, 0x8F54D01cC72137dcdDfE4CFd35a82E16Abf689B5, 37500000000000000000000);
		target.transferFrom(msg.sender, 0x9Ecb0b26b218c289151Bc250E94f90AAB0F0eEA7, 154561000000000000000000);
		target.transferFrom(msg.sender, 0x777FFDAD4ED2eaBeB7a3daB851e8539436861c96, 2500000000000000000000);
		target.transferFrom(msg.sender, 0xFe53A75Ec66b8eb720E968F4276Ab4b10999Ad73, 25000000000000000000000);
		target.transferFrom(msg.sender, 0x37C3c0638883c604d857A0f5dEFc42CB054d51d0, 9950000000000000000000);
		target.transferFrom(msg.sender, 0x478B830b5369eFB50532759BfE3586Ce64De250F, 500000000000000000000000);
		target.transferFrom(msg.sender, 0xb4b378E93007a36D42D12a1DD5f9EaD27aa43dca, 402248000000000000000000);
		target.transferFrom(msg.sender, 0xDDfF36f9099fe31316F35e3877efcB0134E516B1, 359748000000000000000000);
		target.transferFrom(msg.sender, 0x80F3d74f1c4f48Fc158cFBDC61fB8E37b1B76F21, 750000000000000000000);
		target.transferFrom(msg.sender, 0xf8e73cABDe1eb290f1708Ab05C989f215eCe713E, 250000000000000000000000);
		target.transferFrom(msg.sender, 0xD65D398f500C4ABc8313fF132814Ef173F57850E, 62500000000000000000000);
		target.transferFrom(msg.sender, 0xB6C08B84DA23F2B986132B4b9D54fC02E1c1161E, 52500000000000000000000000);
		target.transferFrom(msg.sender, 0xaf5C23a1E845ee7273c46b309ef4E2Fa8BB868BA, 157500000000000000000000000);
		target.transferFrom(msg.sender, 0x09d1C2B52848b64f6fCEA71544b3Ff1c12e97942, 4317475450000000000000000);
		target.transferFrom(msg.sender, 0x025842922e685067dAf777000a4Cc64f49104D2e, 598000000000000000000);
		target.transferFrom(msg.sender, 0x1d26933d2900e187B591C54faabb1eb9e35f1CA6, 641700000000000000000);
		target.transferFrom(msg.sender, 0x36DF0fDB4E10c679a737Ca5110961fa7bd9805Ca, 230000000000000000000);
		target.transferFrom(msg.sender, 0x8D2121d35B17Fa5bC4FC68dFb2Bb64c59E1B4a53, 161000000000000000000);
		target.transferFrom(msg.sender, 0x956D26291dD758D7A4E4922F65E3C8B18B5650DF, 1152300000000000000000);
		target.transferFrom(msg.sender, 0xA060144B56588959B053985bac43Bd6b2AAdC2Cf, 156400000000000000000);
		target.transferFrom(msg.sender, 0xbA6F38D19622fec21a0BD4f9a3cba313651c598c, 5405580000000000000000);
		target.transferFrom(msg.sender, 0xc0A1004F4A0BdC06e503de028f81e5Ab0097e6A2, 230000000000000000000);
		target.transferFrom(msg.sender, 0xF72d9e08728aD1B7255b34828d01d0aBa4Cc62E2, 402500000000000000000);
		target.transferFrom(msg.sender, 0xfD5D74cE99863d2b43E7112d071435D70A5e5B7f, 230000000000000000000);
		//end of batch 3 -- 33 items

		return true;
	}
}