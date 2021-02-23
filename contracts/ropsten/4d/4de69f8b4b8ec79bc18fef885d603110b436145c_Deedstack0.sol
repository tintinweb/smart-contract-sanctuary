/**
 *Submitted for verification at Etherscan.io on 2021-02-23
*/

pragma solidity 0.8.1;

contract Deedstack0 {

	struct DeedstackInfoObj {
		string DeedstackInfoEmptyLine;
	  string Website;
	  string PublicLegal;
		string Address;
	}

	struct Deed {
		string Info;
	}

	struct ImpactProvider {
	  string Name;
	  string Link;
	}

	DeedstackInfoObj private _deedstackInfo;

	function DeedstackInfo() public view returns (DeedstackInfoObj memory) {
			return _deedstackInfo;
	}

	Deed private _deed1;
	function Deed_ActUp() public view returns (Deed memory) {
			return _deed1;
	}
	Deed private _deed2;
	function Deed_GreenStream() public view returns (Deed memory) {
			return _deed2;
	}
	Deed private _deed3;
	function Deed_LawnHero() public view returns (Deed memory) {
			return _deed3;
	}
	Deed private _deed4;
	function Deed_EarthCalling() public view returns (Deed memory) {
			return _deed4;
	}
	Deed private _deed5;
	function Deed_ListenUp() public view returns (Deed memory) {
			return _deed5;
	}
	Deed private _deed6;
	function Deed_LaudableBrand() public view returns (Deed memory) {
			return _deed6;
	}

	ImpactProvider private _impactProvider1;
	function ImpactProvider1() public view returns (ImpactProvider memory) {
			return _impactProvider1;
	}
	ImpactProvider private _impactProvider2;
	function ImpactProvider2() public view returns (ImpactProvider memory) {
			return _impactProvider2;
	}

	constructor() public {
		_deed1 = Deed({
			Info:"Name: Act Up,ID: XP2602,Inventory: 200,Sponsor: Deedstack,Trigger: Follow/React To,Action: Follow/React To,Impact: 0.25 Tree,Trees: 50,CO2: -"
		});

	}

}