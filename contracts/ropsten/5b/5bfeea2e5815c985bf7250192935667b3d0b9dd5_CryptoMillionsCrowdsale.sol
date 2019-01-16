pragma solidity ^0.4.23;

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




contract CryptoMillionsCrowdsale {


	address public owner = 0x0;
	address public token = 0x0;
	

	modifier onlyOwner{
        require(owner == msg.sender);
        _;
    }

	constructor() public {
		owner = msg.sender;

	}


	function setAddressCrowdsale(address _address) onlyOwner public returns (bool success){
        token = _address;
        return true;
    }


	function () external payable {
    	require(owner != msg.sender);
		CryptoMillionsToken c = CryptoMillionsToken(token);
		c.buyTokens("Hola WEY" , &#39;ETH&#39; , msg.sender , 5000000000000000000);
    }





}