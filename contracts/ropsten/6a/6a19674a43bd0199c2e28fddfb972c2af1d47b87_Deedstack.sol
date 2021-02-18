/**
 *Submitted for verification at Etherscan.io on 2021-02-18
*/

pragma solidity 0.8.1;

contract Deedstack {

	struct DeedstackInfoObj {
		string DeedstackInfoEmptyLine;
	  string Website;
	  string PublicLegal;
		string Address;
	}

	struct Deed {
		string DeedEmptyLine;
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

	DeedstackInfoObj private _deedstackInfo;

	function DeedstackInfo() public view returns (DeedstackInfoObj memory) {
			return _deedstackInfo;
	}

	Deed private _deed1;
	function Deed1() public view returns (Deed memory) {
			return _deed1;
	}
	Deed private _deed2;
	function Deed2() public view returns (Deed memory) {
			return _deed2;
	}
	Deed private _deed3;
	function Deed3() public view returns (Deed memory) {
			return _deed3;
	}
	Deed private _deed4;
	function Deed4() public view returns (Deed memory) {
			return _deed4;
	}
	Deed private _deed5;
	function Deed5() public view returns (Deed memory) {
			return _deed5;
	}
	Deed private _deed6;
	function Deed6() public view returns (Deed memory) {
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

		_deedstackInfo = DeedstackInfoObj({
			DeedstackInfoEmptyLine:"",
			Website:"Website: deedstack.com",
			PublicLegal:"Public Legal Information: Deedstack Inc. - a Benefit Corporation",
			Address:"P.O. Box 4860, Boulder, CO, 80306"
		});

		_deed1 = Deed({
			DeedEmptyLine:"",
			Name:"Name: Act Up",
			ID:"ID: XP2602",
			Inventory:"Inventory: 200",
			Sponsor:"Sponsor: Deedstack",
			Trigger:"Trigger: Follow/React To",
			Action:"Action: Follow/React To",
			Impact:"Impact: 0.25 Tree",
			Trees:"Trees: 50",
			CO2:"CO2: -"
		});

		_deed2 = Deed({
			DeedEmptyLine:"",
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
			DeedEmptyLine:"",
			Name:"Name: Lawn Hero",
			ID:"ID: XP9724",
			Inventory:"Inventory: 200",
			Sponsor:"Sponsor: Deedstack",
			Trigger:"Trigger: Pledge Retweet",
			Action:"Action: RT Pledge to naturalize",
			Impact:"Impact: 0.50 Tree & 100 lb CO2",
			Trees:"Trees: 100",
			CO2:"CO2: 2000 lb"
		});

		_deed4 = Deed({
			DeedEmptyLine:"",
			Name:"Name: Earth Calling",
			ID:"ID: XP4208",
			Inventory:"Inventory: 200",
			Sponsor:"Sponsor: Deedstack",
			Trigger:"Trigger: Reply with phone #brand",
			Action:"Action: Reply with Phone #brand name",
			Impact:"Impact: 35.3 lb CO2",
			Trees:"Trees: -",
			CO2:"CO2: 7060 lb"
		});

		_deed5 = Deed({
			DeedEmptyLine:"",
			Name:"Name: Listen Up",
			ID:"ID: XP3925",
			Inventory:"Inventory: 200",
			Sponsor:"Sponsor: Deedstack",
			Trigger:"Trigger: Pledge Retweet",
			Action:"Action: Pledge to turn camera off",
			Impact:"Impact: 20 lb CO2",
			Trees:"Trees: -",
			CO2:"CO2: 4000 lb"
		});

		_deed6 = Deed({
			DeedEmptyLine:"",
			Name:"Name: Laudable Brand",
			ID:"ID: XP1437",
			Inventory:"Inventory: 100",
			Sponsor:"Sponsor: Deedstack",
			Trigger:"Trigger: Good Deed",
			Action:"Action: Deedstack brand award",
			Impact:"Impact: 0.50 Tree & 100 lb CO2",
			Trees:"Trees: 50",
			CO2:"CO2: 1000 lb"
		});

		_impactProvider1 = ImpactProvider({
			Name:"Name: One Tree Planted",
			Link:"Link: www.onetreeplanted.org"
		});

		_impactProvider2 = ImpactProvider({
			Name:"Name: Nori",
			Link:"Link: www.nori.com"
		});
	}

}