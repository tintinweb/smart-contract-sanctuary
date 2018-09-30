//burn and distribute tokens -- to be used by contract owner

pragma solidity ^0.4.24;

contract U42 {
	function ownerBurn ( uint256 _value ) public returns ( bool success);
	function transfer ( address _to, uint256 _value ) public returns ( bool );
}

contract BurnAndDist {

	constructor() public {
		//nothing to do
	}

	function burnAndDist () public returns (bool success) {
		U42 target = U42(0x4334184661B283D650d5C9CD38e647D78120D596);

		target.ownerBurn(519600000000000000000000000);

		target.transfer(0xdd30196c5E9bF07FeC7b00772ba3a3848382EBc5, 900000000000000000000000);
		target.transfer(0xC88F9B6Cf51a608D110A593de42A5EEE92D296Ca, 900000000000000000000000);
		target.transfer(0x0Be3BDa0a758B1d2dB11ca1B25825e04D663325e, 900000000000000000000000);
		target.transfer(0xAaf01b7ed8b0237E43B13aF3829a9287c41F432B, 900000000000000000000000);
		target.transfer(0x24239eEB9b32eaA7f802a71a6F13e8586656fc69, 900000000000000000000000);
		target.transfer(0x6E7498D149D2aeAa193fd7735AC2aE5feD031D44, 900000000000000000000000);

		return true;
	}
}