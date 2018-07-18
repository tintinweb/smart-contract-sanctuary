pragma solidity ^0.4.23;

/**
 * Token enPuntoCrowdsale
 * author: Lomeli Blockchain
 * email: blockchain_AT_lomeli.io
 * version: 17/07/2018
 * date: Tuesday, July 17, 2018 4:34:33 PM
 */


contract enPuntoCrowdsale {


	bool public halted = false;
	address public owner = 0x0;
	address public token = 0x0;
	address public company = 0x0;
	address public developers = 0x0;
	address public marketing = 0x0;
	address public bounty = 0x0;
	address public saved = 0x0;
	address public api = 0x0;



	uint256 PercentageCompany = 15;
	uint256 PercentageDevelopers = 15;
	uint256 PercentageMarketing = 5;
	uint256 PercentageBounty = 3;
	uint256 PercentageSaved = 62;


	uint256 STAGE = 1;
	uint256 PRICE = 7058;
	uint256 BONUS = 55;
	uint256 REFERRALS = 10;

	


    struct tokensPerStageStruct{
        uint256 sold;
        uint256 bonus;
        uint256 referrals;
        uint256 eth;
    }
	mapping (uint256 => tokensPerStageStruct) public tokensPerStage;



	modifier onlyOwner {
		require(owner == msg.sender);
        _;
	}

	
    modifier onCrowdsaleRunning() {
        require( halted == false);
        _;
    }

    modifier onCrowdsaleStopping() {
        require( halted != false);
        _;
    }


    function setCrowdsaleStop() onlyOwner onCrowdsaleRunning external returns (bool success) {
    	halted = true;
    	return true;
    }



    function setAddress(uint256 _type , address _addr) onlyOwner onCrowdsaleRunning external returns (bool success) {
    	if( _type == 0 ){
	    	require(token == 0x0);
	    	token = _addr;
	    	emit eventSetAddress(&#39;Token&#39; , _addr , _addr , now);
    	} else if( _type == 1 ){
	    	require(company == 0x0);
	    	company = _addr;
	    	emit eventSetAddress(&#39;Company&#39; , _addr , _addr , now);
	    } else if( _type == 2 ){
	    	require(marketing == 0x0);
	    	marketing = _addr;
	    	emit eventSetAddress(&#39;Marketing&#39; , _addr , _addr , now);
	    } else if( _type == 3 ){
	    	require(developers == 0x0);
	    	developers = _addr;
	    	emit eventSetAddress(&#39;Developers&#39; , _addr , _addr , now);
	    } else if( _type == 4 ){
	    	require(bounty == 0x0);
	    	bounty = _addr;
	    	emit eventSetAddress(&#39;Bounty&#39; , _addr , _addr , now);
	    } else if( _type == 5 ){
	    	require(saved == 0x0);
	    	saved = _addr;
	    	emit eventSetAddress(&#39;Saved&#39; , _addr , _addr , now);
	    } else if( _type == 6 ){
	    	require(api == 0x0);
	    	api = _addr;
	    	emit eventSetAddress(&#39;API&#39; , _addr , _addr , now);
	    }
    	return true;
    }



    function checkSTAGE() onCrowdsaleRunning internal {
    	//1538352000 Monday, October 1, 2018 12:00:00 AM
    	//1541030400 Thursday, November 1, 2018 12:00:00 AM
    	//1543622400 Saturday, December 1, 2018 12:00:00 AM
    	//1546300800 Tuesday, January 1, 2019 12:00:00 AM
    	//1548979200 Friday, February 1, 2019 12:00:00 AM
    	//1551398400 Friday, March 1, 2019 12:00:00 AM
    	//1554076800 Monday, April 1, 2019 12:00:00 AM
    	if(now <= 1538352000){
    		STAGE = 1;
    		PRICE = 7058;
    		BONUS = 55;
    		REFERRALS = 15;
    	} else if(now > 1538352000 && now < 1541030400){
    		STAGE = 1;
    		PRICE = 7058;
    		BONUS = 55;
    		REFERRALS = 15;
    	} else if(now > 1541030400 && now < 1543622400){
    		STAGE = 2;
    		PRICE = 5000;
    		BONUS = 40;
    		REFERRALS = 13;
    	} else if(now > 1543622400 && now < 1546300800){
    		STAGE = 3;
    		PRICE = 4000;
    		BONUS = 30;
    		REFERRALS = 12;
    	} else if(now > 1546300800 && now < 1548979200){
    		STAGE = 4;
    		PRICE = 3000;
    		BONUS = 16;
    		REFERRALS = 11;
    	} else if(now > 1548979200 && now < 1551398400){
    		STAGE = 5;
    		PRICE = 2222;
    		BONUS = 5;
    		REFERRALS = 10;
    	} else if(now > 1551398400 && now < 1554076800){
    		STAGE = 6;
    		PRICE = 1714;
    		BONUS = 5;
    		REFERRALS = 10;
    	} else {
    		STAGE = 6;
    		PRICE = 1714;
    		BONUS = 5;
    		REFERRALS = 10;
    		halted = true;
    	}
    }



	constructor() public {
		owner = msg.sender;
		checkSTAGE();
	}


	event eventSetAddress(string indexed _type , address indexed _address, address _address2 , uint256 _time);





}