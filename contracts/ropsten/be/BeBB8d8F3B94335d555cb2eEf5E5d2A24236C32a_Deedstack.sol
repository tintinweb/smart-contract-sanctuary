/**
 *Submitted for verification at Etherscan.io on 2021-02-12
*/

pragma solidity 0.8.1;

contract Deedstack {

	struct DeedstackInfo {
	  string Website;
	  string PublicLegal;
	}

	struct Deed {
	  string Name;
	  string ID;
		string Inventory;
		string Sponsor;
		string Trigger;
		string Action;
		string Impact;
		string Trees;
		string CO2;
	}

	struct ImpactProvider {
	  string Name;
	  string Link;
	}

	DeedstackInfo private _deedstackInfo;

	function deedstackInfo() public view returns (DeedstackInfo memory) {
			return _deedstackInfo;
	}

	Deed private _deed1;
	function deed1() public view returns (Deed memory) {
			return _deed1;
	}
	Deed private _deed2;
	function deed2() public view returns (Deed memory) {
			return _deed2;
	}
	Deed private _deed3;
	function deed3() public view returns (Deed memory) {
			return _deed3;
	}
	Deed private _deed4;
	function deed4() public view returns (Deed memory) {
			return _deed4;
	}
	Deed private _deed5;
	function deed5() public view returns (Deed memory) {
			return _deed5;
	}
	Deed private _deed6;
	function deed6() public view returns (Deed memory) {
			return _deed6;
	}

	ImpactProvider private _impactProvider1;
	function impactProvider1() public view returns (ImpactProvider memory) {
			return _impactProvider1;
	}
	ImpactProvider private _impactProvider2;
	function impactProvider2() public view returns (ImpactProvider memory) {
			return _impactProvider2;
	}

	constructor() public {

		_deedstackInfo = DeedstackInfo({
			Website:"Website: deedstack.com",
			PublicLegal:"PublicLegal: Deedstack, Inc. - a Benefit Corporation - P.O. Box 4860, Boulder, CO, 80306"
		});

		_deed1 = Deed({
			Name:"Name: Act Up",
			ID:"ID: XP2602",
			Inventory:"Inventory: 200",
			Sponsor:"Sponsor: Deedstack",
			Trigger:"FTrigger: ollow/React To",
			Action:"Action: Follow/React To",
			Impact:"Impact: 0.25 Tree Plant",
			Trees:"Trees: 50",
			CO2:"CO2: -"
		});

		_deed2 = Deed({
			Name:"Name: Green Stream",
			ID:"ID: XP4066",
			Inventory:"Inventory: 100",
			Sponsor:"Sponsor: Deedstack",
			Trigger:"Trigger: UGC Reply",
			Action:"Action: Reply with Netflix Screen Photo",
			Impact:"Impact: 1 Tree",
			Trees:"Trees: 100",
			CO2:"CO2: -"
		});

		_deed3 = Deed({
			Name:"Name: Lawn Hero Earth Calling Listen Up Laudable Brand",
			ID:"ID: XP9724",
			Inventory:"Inventory: 200",
			Sponsor:"Sponsor: Deedstack",
			Trigger:"Trigger: Pledge Retweet",
			Action:"Action: RT Pledge to naturalize",
			Impact:"Impact: .50T, 100lb CO2",
			Trees:"Trees: 100",
			CO2:"CO2: 2000"
		});

		_deed4 = Deed({
			Name:"Name: Earth Calling Listen Up Laudable Brand",
			ID:"ID: XP4208",
			Inventory:"Inventory: 200",
			Sponsor:"Sponsor: Deedstack",
			Trigger:"Trigger: Reply with phone #brand",
			Action:"Action: Reply with Phone #brand name",
			Impact:"Impact: 35.3 lb CO2",
			Trees:"Trees: -",
			CO2:"CO2: 7060"
		});

		_deed5 = Deed({
			Name:"Name: Listen Up",
			ID:"ID: XP3925",
			Inventory:"Inventory: 200",
			Sponsor:"Sponsor: Deedstack",
			Trigger:"Trigger: Pledge Retweet",
			Action:"Action: Pledge to turn camera off",
			Impact:"Impact: 20lb CO2",
			Trees:"Trees: -",
			CO2:"CO2: 4000"
		});

		_deed6 = Deed({
			Name:"Name: Laudable Brand",
			ID:"ID: XP1437",
			Inventory:"Inventory: 100",
			Sponsor:"Sponsor: Deedstack",
			Trigger:"Trigger: Good Deed",
			Action:"Action: Deedstack brand award",
			Impact:"Impact: .50T, 100lb CO2",
			Trees:"Trees: 50",
			CO2:"CO2: 1000"
		});

		_impactProvider1 = ImpactProvider({
			Name:"Name: One Tree Planted",
			Link:"Link: onetreeplanted.org"
		});

		_impactProvider2 = ImpactProvider({
			Name:"Name: Nori",
			Link:"Link: nori.com"
		});
	}

}