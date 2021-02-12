/**
 *Submitted for verification at Etherscan.io on 2021-02-12
*/

pragma solidity >=0.4.25 <0.7.0;

contract Deedstack {

	string public deedstackInfo;
	string public deed1;
	string public deed2;
	string public deed3;
	string public deed4;
	string public deed5;
	string public deed6;
	string public impactProvider1;
	string public impactProvider2;

	constructor() public {
		deedstackInfo = '"Website":"deedstack.com","PublicLegal":"Deedstack, Inc. - a Benefit Corporation - P.O. Box 4860, Boulder, CO, 80306"';
		deed1 = '"Name":"Act Up","ID":"XP2602","Inventory":"200","Sponsor":"Deedstack","Trigger":"Follow/React To","Action":"Follow/React To","Impact":"0.25 Tree Plant","Trees":"50","CO2":"-"';
		deed2 = '"Name":"Green Stream","ID":"XP4066","Inventory":"100","Sponsor":"Deedstack","Trigger":"UGC Reply","Action":"Reply with Netflix Screen Photo","Impact":"1 Tree","Trees":"100","CO2":"-"';
		deed3 = '"Name":"Lawn Hero Earth Calling Listen Up Laudable Brand","ID":"XP9724","Inventory":"200","Sponsor":"Deedstack","Trigger":"Pledge Retweet","Action":"RT Pledge to naturalize","Impact":".50T, 100lb CO2","Trees":"100","CO2":"2000"';
		deed4 = '"Name":"Earth Calling Listen Up Laudable Brand","DeedID":"XP4208","Inventory":"200","Sponsor":"Deedstack","Trigger":"Reply with phone #brand","Action":"Reply with Phone #brand name","Impact":"35.3 lb CO2","Trees":"-","CO2":"7060"';
		deed5 = '"Name":"Listen Up","ID":"XP3925","Inventory":"200","Sponsor":"Deedstack","Trigger":"Pledge Retweet","Action":"Pledge to turn camera off","Impact":"20lb CO2","Trees":"-","CO2":"4000"';
		deed6 = '"Name":"Laudable Brand","ID":"XP1437","Inventory":"100","Sponsor":"Deedstack","Trigger":"Good Deed","Action":"Deedstack brand award","Impact":".50T, 100lb CO2","Trees":"50","CO2":"1000"';
		impactProvider1 = '"ImpactProviderName":"One Tree Planted","Link":"onetreeplanted.org"';
		impactProvider2 = '"ImpactProviderName":"Nori","Link":"nori.com"';
	}

}