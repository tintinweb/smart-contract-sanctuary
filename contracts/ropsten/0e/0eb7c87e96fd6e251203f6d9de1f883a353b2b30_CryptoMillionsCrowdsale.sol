pragma solidity ^0.4.25;

/**
 * Token CryptoMillionsCrowdsale
 * author: Lomeli Blockchain
 * email: blockchain_AT_lomeli.io
 * version: 17/07/2018
 * date: Wednesday, November 28, 2018 4:34:33 PM
 */




contract CryptoMillionsToken {
    function buyTokens(string _hash , string _type , address _to, uint256 _value) public returns(bool);
}


contract othersTokensBool {
	function transfer(address _to, uint256 _value) public returns (bool success);
	function balanceOf( address who ) public view returns (uint256 value);
}

contract othersTokens {
	function transfer(address _to, uint256 _value);
	function balanceOf( address who ) public view returns (uint256 value);
}



contract CryptoMillionsCrowdsale {

	bool halted = false;
	address public owner = 0x0;
	address public addressToken = 0xbe841FE631a16Ca7fC3c6B8B106E8cd3ba2eDd68;
	address public addressAPI = 0x0;
	address public addressMarketing = 0x0;
	address public addressLegal = 0x0;
	address public addressDevelopers = 0x0;
	address public addressOperations = 0x0;
	address public addressWarranty = 0x0;
	uint256 PercentageMarketing = 20;
    uint256 PercentageLegal = 5;
    uint256 PercentageOperations = 5;
    uint256 PercentageDevelopers = 20;
    uint256 PercentageWarranty = 50;
    uint256 public STAGE = 1;
    uint256 public PRICE = 7058;
    uint256 public BONUS = 40;
	

    modifier onlyOwner {
        require(owner == msg.sender);
        _;
    }

    modifier onlyApi {
        require(addressAPI == msg.sender);
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


	function sendRemainingTokens(address _tokenAddress) onlyOwner public returns (bool success){
		address _address = address(this);
		othersTokens c = othersTokens(_tokenAddress);
		uint256 weiAmount = c.balanceOf(_address);
        uint256 tokensMarketing = _getValueEther(weiAmount , PercentageMarketing);
        uint256 tokensLegals = _getValueEther(weiAmount , PercentageLegal);
        uint256 tokensDevelopers = _getValueEther(weiAmount , PercentageDevelopers);
        uint256 tokensOperations = _getValueEther(weiAmount , PercentageOperations);
        uint256 tokensWarranty = _getValueEther(weiAmount , PercentageWarranty);
		c.transfer(addressMarketing , tokensMarketing);
		c.transfer(addressLegal , tokensLegals);
		c.transfer(addressDevelopers , tokensDevelopers);
		c.transfer(addressOperations , tokensOperations);
		c.transfer(addressWarranty , tokensWarranty);
		return true;
	}




	function sendRemainingTokensBool(address _tokenAddress) onlyOwner public returns (bool success){
		address _address = address(this);
		othersTokensBool c = othersTokensBool(_tokenAddress);
		uint256 weiAmount = c.balanceOf(_address);
        uint256 tokensMarketing = _getValueEther(weiAmount , PercentageMarketing);
        uint256 tokensLegals = _getValueEther(weiAmount , PercentageLegal);
        uint256 tokensDevelopers = _getValueEther(weiAmount , PercentageDevelopers);
        uint256 tokensOperations = _getValueEther(weiAmount , PercentageOperations);
        uint256 tokensWarranty = _getValueEther(weiAmount , PercentageWarranty);
		c.transfer(addressMarketing , tokensMarketing);
		c.transfer(addressLegal , tokensLegals);
		c.transfer(addressDevelopers , tokensDevelopers);
		c.transfer(addressOperations , tokensOperations);
		c.transfer(addressWarranty , tokensWarranty);
		return true;
	}



	function sendRemainingETH() onlyOwner public returns (bool success){
		uint256 weiAmount = this.balance;
        uint256 ethMarketing = _getValueEther(weiAmount , PercentageMarketing);
        uint256 ethLegals = _getValueEther(weiAmount , PercentageLegal);
        uint256 ethDevelopers = _getValueEther(weiAmount , PercentageDevelopers);
        uint256 ethOperations = _getValueEther(weiAmount , PercentageOperations);
        uint256 ethWarranty = _getValueEther(weiAmount , PercentageWarranty);
		require(ethMarketing > 0);
		require(ethLegals > 0);
		require(ethDevelopers > 0);
		require(ethOperations > 0);
		require(ethWarranty > 0);
		addressMarketing.transfer(ethMarketing);
		addressLegal.transfer(ethLegals);
		addressDevelopers.transfer(ethDevelopers);
		addressOperations.transfer(ethOperations);
		addressWarranty.transfer(ethWarranty);
		emit eventSendRemaining(weiAmount , now);
		return true;
	}





    function setAddress(uint256 _type , address _addr) onlyOwner onCrowdsaleRunning external returns (bool success) {
        if( _type == 0 ){
            require(addressToken == 0x0);
            addressToken = _addr;
            emit eventSetAddress(_addr , now , &#39;Token&#39;);
		} else if( _type == 1 ){
			require(addressAPI == 0x0);
            addressAPI = _addr;
            emit eventSetAddress(_addr , now , &#39;API&#39;);
        } else if( _type == 2 ){
            require(addressMarketing == 0x0);
            addressMarketing = _addr;
            emit eventSetAddress(_addr , now , &#39;Marketing&#39;);
		} else if( _type == 3 ){
            require(addressLegal == 0x0);
            addressLegal = _addr;
            emit eventSetAddress(_addr , now , &#39;Legal&#39;);
		} else if( _type == 4 ){
            require(addressDevelopers == 0x0);
            addressDevelopers = _addr;
            emit eventSetAddress(_addr , now , &#39;Developers&#39;);
		} else if( _type == 5 ){
            require(addressOperations == 0x0);
            addressOperations = _addr;
            emit eventSetAddress(_addr , now , &#39;Operations&#39;);
		} else if( _type == 6 ){
            require(addressWarranty == 0x0);
            addressWarranty = _addr;
            emit eventSetAddress(_addr , now , &#39;Warranty&#39;);
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
        } else if(now > 1538352000 && now < 1541030400){
            STAGE = 1;
            PRICE = 7058;
            BONUS = 55;
        } else if(now > 1541030400 && now < 1543622400){
            STAGE = 2;
            PRICE = 5000;
            BONUS = 40;
        } else if(now > 1543622400 && now < 1546300800){
            STAGE = 3;
            PRICE = 4000;
            BONUS = 30;
        } else if(now > 1546300800 && now < 1548979200){
            STAGE = 4;
            PRICE = 3000;
            BONUS = 16;
        } else if(now > 1548979200 && now < 1551398400){
            STAGE = 5;
            PRICE = 2222;
            BONUS = 5;
        } else if(now > 1551398400 && now < 1554076800){
            STAGE = 6;
            PRICE = 1714;
            BONUS = 5;
        } else {
            STAGE = 6;
            PRICE = 1714;
            BONUS = 5;
        }
    }


    function _getTokenAmount(uint256 _weiAmount) internal view returns (uint256) {
        require(_weiAmount > 0);
        require(PRICE > 0);
        uint256 tokensForETH = (PRICE*_weiAmount);
        require(tokensForETH > 0);
        return tokensForETH;
    }


    function _getTokenBonus(uint256 _weiAmount) internal view returns (uint256) {
        require(_weiAmount > 0);
        require(PRICE > 0);
        require(BONUS > 0);
        uint256 tokensForBonus = ((_weiAmount*BONUS)/100);
        require(tokensForBonus > 0);
        return tokensForBonus;
    }

    function _getValueEther(uint256 _eth , uint256 _perc) internal pure returns (uint256) {
        require(_eth > 0);
        require(_perc > 0);
        uint256 eth = ((_eth*_perc)/100);
        require(eth > 0);
        return eth;
    }


	constructor() public {
		owner = msg.sender;

		addressMarketing = 0xa6b70eFCDd930Ea69ba13b3EE143F37E37d0Cb49;
		addressLegal = 0xa6b70eFCDd930Ea69ba13b3EE143F37E37d0Cb49;
		addressDevelopers = 0xa6b70eFCDd930Ea69ba13b3EE143F37E37d0Cb49;
		addressOperations = 0xa6b70eFCDd930Ea69ba13b3EE143F37E37d0Cb49;
		addressWarranty = 0xa6b70eFCDd930Ea69ba13b3EE143F37E37d0Cb49;
		
		checkSTAGE();
	}


	function () external payable {
    	require(owner != msg.sender);
		require(addressAPI != msg.sender);
		buyTokens();
    }




	function buyTokens() public payable {
		require(msg.sender != address(0));
        require(msg.value > 0);
		checkSTAGE();
		uint256 weiAmount = msg.value;
		uint256 tokens = _getTokenAmount(weiAmount);
		uint256 tokensBonus = _getTokenBonus(tokens);
		uint256 totalTokens = tokens + tokensBonus;
        require(tokens > 0);
        require(tokensBonus > 0);
		require(totalTokens > 0);
        uint256 ethMarketing = _getValueEther(weiAmount , PercentageMarketing);
        uint256 ethLegals = _getValueEther(weiAmount , PercentageLegal);
        uint256 ethDevelopers = _getValueEther(weiAmount , PercentageDevelopers);
        uint256 ethOperations = _getValueEther(weiAmount , PercentageOperations);
        uint256 ethWarranty = _getValueEther(weiAmount , PercentageWarranty);
		require(ethMarketing > 0);
		require(ethLegals > 0);
		require(ethDevelopers > 0);
		require(ethOperations > 0);
		require(ethWarranty > 0);
		addressMarketing.transfer(ethMarketing);
		addressLegal.transfer(ethLegals);
		addressDevelopers.transfer(ethDevelopers);
		addressOperations.transfer(ethOperations);
		addressWarranty.transfer(ethWarranty);
		CryptoMillionsToken c = CryptoMillionsToken(addressToken);
		c.buyTokens("Hola WEY" , &#39;ETH&#39; , msg.sender , totalTokens);
		emit eventBuyTokens(msg.sender , now , msg.value , tokens , tokensBonus , totalTokens);
	}


	event eventSetAddress(address _address, uint256 _time , string _type);
	event eventBuyTokens(address _address, uint256 _time , uint256 _value , uint256 _tokens , uint256 _bonus , uint256 _total);
	event eventSendRemaining(uint256 _weiAmount , uint256 _time);
	


}