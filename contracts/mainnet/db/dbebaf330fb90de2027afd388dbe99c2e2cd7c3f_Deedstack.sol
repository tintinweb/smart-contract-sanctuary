/**
 *Submitted for verification at Etherscan.io on 2021-02-25
*/

pragma solidity 0.8.1;

contract Deedstack {

	struct InfoObj {
		string I;
	}

	struct Deed {
		string I;
	}

	struct IP {
	  string I;
	}

	InfoObj private i;
	function DeedstackInfo() public view returns (InfoObj memory) {
			return i;
	}

	Deed private d1;
	function Deed_ActUp() public view returns (Deed memory) {
			return d1;
	}
	Deed private d2;
	function Deed_GreenStream() public view returns (Deed memory) {
			return d2;
	}
	Deed private d3;
	function Deed_LawnHero() public view returns (Deed memory) {
			return d3;
	}
	Deed private d4;
	function Deed_EarthCalling() public view returns (Deed memory) {
			return d4;
	}
	Deed private d5;
	function Deed_ListenUp() public view returns (Deed memory) {
			return d5;
	}
	Deed private d6;
	function Deed_LaudableBrand() public view returns (Deed memory) {
			return d6;
	}

	IP private ip1;
	function ImpactProvider1() public view returns (IP memory) {
			return ip1;
	}
	IP private ip2;
	function ImpactProvider2() public view returns (IP memory) {
			return ip2;
	}

	constructor() public {
		d1 = Deed({
			I:"Name: Act Up,ID: XP2602,Inventory: 200,Sponsor: Deedstack,Trigger: Follow/React To,Action: Follow/React To,Impact: 0.25 Tree,Trees: 50,CO2: -"
		});

		d2 = Deed({
			I:"Name: Green Stream,ID: XP4066,Inventory: 100,Sponsor: Deedstack,Trigger: UGC Reply,Action: Reply with Netflix Screen Photo,Impact: 1 Tree,Trees: 100,CO2: -"
		});

		d3 = Deed({
			I:"Name: Lawn Hero,ID: XP9724,Inventory: 200,Sponsor: Deedstack,Trigger: Pledge Retweet,Action: RT Pledge to naturalize,Impact: 0.50 Tree & 100 lb CO2,Trees: 100,CO2: 2000 lb"
		});

		d4 = Deed({
			I:"Name: Earth Calling,ID: XP4208,Inventory: 200,Sponsor: Deedstack,Trigger: Reply with phone #brand,Action: Reply with Phone #brand name,Impact: 35.3 lb CO2,Trees: -,CO2: 7060 lb"
		});

		d5 = Deed({
			I:"Name: Listen Up,XP3925,Inventory: 200,Sponsor: Deedstack,Trigger: Pledge Retweet,Action: Pledge to turn camera off,Impact: 20 lb CO2,Trees: -,CO2: 4000 lb"
		});

		d6 = Deed({
			I:"Name: Laudable Brand,ID: XP1437,Inventory: 100,Sponsor: Deedstack,Trigger: Good Deed,Action: Deedstack brand award,Impact: 0.50 Tree & 100 lb CO2,Trees: 50,CO2: 1000 lb"
		});

		ip1 = IP({
			I:"Name: One Tree Planted,Link: www.onetreeplanted.org"
		});

		ip2 = IP({
			I:"Name: Nori,Link: www.nori.com"
		});

		i = InfoObj({
			I:"Website: deedstack.com,Public Legal Information: Deedstack Inc. - a Benefit Corporation,P.O. Box 4860, Boulder, CO, 80306"
		});
	}

}