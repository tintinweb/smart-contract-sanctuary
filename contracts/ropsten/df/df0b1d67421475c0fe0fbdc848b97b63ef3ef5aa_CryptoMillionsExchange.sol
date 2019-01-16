pragma solidity ^0.4.25;

/**
 * Token CryptoMillions
 * author: Lomeli Blockchain
 * email: blockchain_AT_lomeli.io
 * version: 1.0.1
 * date: Wednesday, Sunday 02, 2018 11:00:00 AM
 */


contract CryptoMillionsExchange {

	bool halted = false;
	address public owner = 0x0;
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


    function setCrowdsaleStart() onlyOwner onCrowdsaleRunning external returns (bool success) {
        halted = false;
        return true;
    }


    function setCrowdsaleStop() onlyOwner onCrowdsaleRunning external returns (bool success) {
        halted = true;
        return true;
    }


    function setAddress(uint256 _type , address _addr) onlyOwner onCrowdsaleRunning external returns (bool success) {
        if( _type == 0 ){
            require(addressMarketing == 0x0);
            addressMarketing = _addr;
            emit eventSetAddress(_addr , now , &#39;Marketing&#39;);
		} else if( _type == 1 ){
            require(addressLegal == 0x0);
            addressLegal = _addr;
            emit eventSetAddress(_addr , now , &#39;Legal&#39;);
		} else if( _type == 2 ){
            require(addressDevelopers == 0x0);
            addressDevelopers = _addr;
            emit eventSetAddress(_addr , now , &#39;Developers&#39;);
		} else if( _type == 3 ){
            require(addressOperations == 0x0);
            addressOperations = _addr;
            emit eventSetAddress(_addr , now , &#39;Operations&#39;);
		} else if( _type == 4 ){
            require(addressWarranty == 0x0);
            addressWarranty = _addr;
            emit eventSetAddress(_addr , now , &#39;Warranty&#39;);
        }
        return true;
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
	}


	function () external payable {
    	require(owner != msg.sender);
		sendETH();
    }


	function sendETH() onCrowdsaleRunning public payable {
		require(msg.sender != address(0));
        require(msg.value > 0);
		uint256 weiAmount = msg.value;
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
		emit eventSendETH(msg.sender , msg.value , now);
	}


    event eventSetAddress(address indexed _address, uint256 _time , string _type);
    event eventSendETH(address indexed _address, uint256 _value , uint256 _time);
    

}