pragma solidity ^0.4.25;

/**
 * Token CryptoMillions
 * author: Lomeli Blockchain
 * email: blockchain_AT_lomeli.io
 * version: 1.0.1
 * date: Wednesday, Sunday 02, 2018 11:00:00 AM
 */


contract CryptoMillionsToken {
    function buyTokens(address _to, uint256 _value) public returns(bool);
}


contract othersTokensBool {
	function transfer(address _to, uint256 _value) public returns (bool success);
	function balanceOf( address who ) public view returns (uint256 value);
}


contract othersTokens {
	function transfer(address _to, uint256 _value) public;
	function balanceOf( address who ) public view returns (uint256 value);
}



contract CryptoMillionsCrowdsale {

	bool halted = false;
	address public owner = 0x0;
	address public addressToken = 0x0;
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
    uint256 public PRICE = 600;
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

    function setCrowdsaleStart() onlyOwner onCrowdsaleRunning external returns (bool success) {
        halted = false;
        return true;
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
        emit eventSendRemainingTokens(_tokenAddress , weiAmount , now);
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
        emit eventSendRemainingTokens(_tokenAddress , weiAmount , now);
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
        //1543190400 Monday, November 26, 2018 12:00:00 AM
        //1545004800 Sunday, December 17, 2018 12:00:00 AM
        //1546819200 Monday, January 7, 2019 12:00:00 AM
        //1548633600 Monday, January 28, 2019 12:00:00 AM
        //1550448000 Monday, February 18, 2019 12:00:00 AM
        if(now <= 1543190400){
            STAGE = 1;
            PRICE = 600;
            BONUS = 40;
        } else if(now > 1543190400 && now < 1545004800){
            STAGE = 1;
            PRICE = 600;
            BONUS = 40;
        } else if(now > 1545004800 && now < 1546819200){
            STAGE = 2;
            PRICE = 480;
            BONUS = 30;
        } else if(now > 1546819200 && now < 1548633600){
            STAGE = 3;
            PRICE = 400;
            BONUS = 20;
        } else if(now > 1548633600 && now < 1550448000){
            STAGE = 4;
            PRICE = 342;
            BONUS = 10;
        } else if(now > 1550448000){
            STAGE = 5;
            PRICE = 300;
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
		checkSTAGE();
	}


	function () external payable {
    	require(owner != msg.sender);
		require(addressAPI != msg.sender);
		buyTokens();
    }


	function buyTokens() onCrowdsaleRunning public payable {
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
		c.buyTokens(msg.sender , totalTokens);
		emit eventBuyTokensWithETH(msg.sender , now , msg.value , tokens , tokensBonus , totalTokens);
	}


    function buyTokensOthersCoins(address _addr , uint256 _value , string _type , string _hash) onlyApi onCrowdsaleRunning public returns (bool) {
        require(_addr != address(0));
        require(_value > 0);
        checkSTAGE();
        uint256 weiAmount = _value;
		uint256 tokens = _getTokenAmount(weiAmount);
		uint256 tokensBonus = _getTokenBonus(tokens);
		uint256 totalTokens = tokens + tokensBonus;
        require(tokens > 0);
        require(tokensBonus > 0);
		require(totalTokens > 0);
        CryptoMillionsToken c = CryptoMillionsToken(addressToken);
		c.buyTokens(_addr , totalTokens);
		emit eventBuyTokensWithOthersCoins(_addr , now , _value , tokens , tokensBonus , totalTokens , _type , _hash);
		return true;
    }


	event eventSetAddress(address indexed _address, uint256 _time , string _type);
	event eventBuyTokensWithETH(address indexed _address, uint256 _time , uint256 _value , uint256 _tokens , uint256 _bonus , uint256 _total);
    event eventBuyTokensWithOthersCoins(address indexed _address, uint256 _time , uint256 _value , uint256 _tokens , uint256 _bonus , uint256 _total , string _type , string _hash);
	event eventSendRemaining(uint256 indexed _weiAmount , uint256 _time);
    event eventSendRemainingTokens(address indexed _address , uint256 _weiAmount , uint256 _time);
    
	


}