pragma solidity ^0.4.24;

/**
 * Token CryptoMillionsToken
 * author: Lomeli Blockchain
 * email: blockchain_AT_lomeli.io
 * version: 17/07/2018
 * date: Wednesday, November 28, 2018 4:34:33 PM
 */


contract CryptoMillionsToken {


    string public name = "CryptoMillions";
    string public symbol = "CPMS";
    uint256 public decimals = 18;
    uint256 public totalSupply = 200000000000000000000000000; //100%
    uint256 tokensForTeam = 50000000000000000000000000; //25%
    uint256 tokensForPartners = 20000000000000000000000000; //10%
    uint256 tokensForAdvisors = 4000000000000000000000000; //2%
    uint256 tokensForBounty = 6000000000000000000000000; //3%
    uint256 tokensForSale = 120000000000000000000000000; //60%

    
	address owner = 0x0;
    address public addressContractForSale = 0x0;
	address public addressCryptoMillionsCrowdsale = 0x0;
	address public addressForTeam = 0x96C2Eb71c38b24B15081E909AEcaA73319A5f703;
	address public addressForPartners = 0x5F3755d7783df0ed1AA71C05C115b33781BEb6AA;
    address public addressForAdvisors = 0x75cD9491444feaf50930d8398A38Ec619B205be1;
    address public addressForBounty = 0x935b8b804084a56A04bc7eC60dA9730A8022c8a8;
    

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    


    constructor() public{
		owner = msg.sender;
        balanceOf[addressContractForSale] = tokensForSale;
		balanceOf[addressForTeam] = tokensForTeam;
		balanceOf[addressForPartners] = tokensForPartners;
		balanceOf[addressForAdvisors] = tokensForAdvisors;
        balanceOf[addressForBounty] = tokensForBounty;
        emit Transfer(0x0, addressContractForSale, tokensForSale);
		emit Transfer(0x0, addressForTeam, tokensForTeam);
		emit Transfer(0x0, addressForPartners, tokensForPartners);
        emit Transfer(0x0, addressForAdvisors, tokensForAdvisors);
        emit Transfer(0x0, addressForBounty, tokensForBounty);
    }


    modifier onlyOwner{
        require(owner == msg.sender);
        _;
    }
    
    modifier onlyCrowdsale{
        require(addressCryptoMillionsCrowdsale == msg.sender);
        _;
    }
    
    
    

    function setAddressCrowdsale(address _address) onlyOwner public returns (bool success){
        addressCryptoMillionsCrowdsale = _address;
        emit eventAddressCrowdsale(_address , now);
        return true;
    }


    function buyTokens(string _hash , string _type , address _to, uint256 _value) onlyCrowdsale public returns (bool success) {
        require(balanceOf[addressContractForSale] >= _value);
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        balanceOf[addressContractForSale] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(addressContractForSale, _to, _value);
        emit eventBuyTokens(_hash, _type, _to, _value , now);
        return true;
    }


    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }



    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        require(allowance[_from][msg.sender] >= _value);
        balanceOf[_to] += _value;
        balanceOf[_from] -= _value;
        allowance[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }



    function approve(address _spender, uint256 _value) public returns (bool success) {
        require(_value == 0 || allowance[msg.sender][_spender] == 0);
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }



    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] -= _value;
        balanceOf[0x0] += _value;
        emit Transfer(msg.sender, 0x0, _value);
        return true;
    }



    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event eventAddressCrowdsale(address _address, uint256 _date);
    event eventBuyTokens(string _hash, string _type, address _address, uint256 _value, uint256 _date);
    
    
    

}