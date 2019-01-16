pragma solidity ^0.4.25;

/**
 * Token CryptoMillions
 * author: Lomeli Blockchain
 * email: blockchain_AT_lomeli.io
 * version: 1.0.1
 * date: Wednesday, Sunday 02, 2018 11:00:00 AM
 */


contract CryptoMillionsKYC {
    function readKYC(address _to) view public returns (bool);
}



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
    bool startKYC = true;
	address owner = 0x0;
    address public addressContractForSale = 0x0;
	address public addressCryptoMillionsCrowdsale = 0x0;
    address public addressCryptoMillionsKYC = 0x0;
	address public addressForTeam = 0xFDF67223e0C00F36d783195d3d0EA140968C8667;
	address public addressForPartners = 0x5F3755d7783df0ed1AA71C05C115b33781BEb6AA;
    address public addressForAdvisors = 0x75cD9491444feaf50930d8398A38Ec619B205be1;
    address public addressForBounty = 0x935b8b804084a56A04bc7eC60dA9730A8022c8a8;
    

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    

    modifier onlyOwner{
        require(owner == msg.sender);
        _;
    }
    
    modifier onlyCrowdsale{
        require(addressCryptoMillionsCrowdsale == msg.sender);
        _;
    }


    modifier checkKYC{
        if(startKYC == true){
            CryptoMillionsKYC c = CryptoMillionsKYC(addressCryptoMillionsKYC);
            bool kycStatus = c.readKYC(msg.sender);
            require(kycStatus == true);
            _;
        } else {
            _;
        }
    }


    function setCheckKYC(bool _status) onlyOwner external returns (bool success) {
        startKYC = _status;
        emit eventStatusKYC(_status , now);
        return true;
    }


    function setAddress(uint256 _type , address _addr) onlyOwner external returns (bool success) {
        if( _type == 0 ){
            require(addressForTeam == 0x0);
            addressForTeam = _addr;
            emit eventSetAddress(_addr , now , &#39;Team&#39;);
		} else if( _type == 1 ){
			require(addressForPartners == 0x0);
            addressForPartners = _addr;
            emit eventSetAddress(_addr , now , &#39;Partners&#39;);
        } else if( _type == 2 ){
            require(addressForAdvisors == 0x0);
            addressForAdvisors = _addr;
            emit eventSetAddress(_addr , now , &#39;Advisors&#39;);
		} else if( _type == 3 ){
            require(addressForBounty == 0x0);
            addressForBounty = _addr;
            emit eventSetAddress(_addr , now , &#39;Bounty&#39;);
		}
        return true;
    }


    function setAddressCrowdsale(address _address) onlyOwner public returns (bool success){
        addressCryptoMillionsCrowdsale = _address;
        emit eventAddressCrowdsale(_address , now);
        return true;
    }


    function setAddressKYC(address _address) onlyOwner public returns (bool success){
        addressCryptoMillionsKYC = _address;
        emit eventAddressKYC(_address , now);
        return true;
    }


    constructor() public {
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


    function buyTokens(address _to , uint256 _value) onlyCrowdsale public returns (bool success) {
        require(balanceOf[addressContractForSale] >= _value);
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        balanceOf[addressContractForSale] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(addressContractForSale, _to, _value);
        emit eventBuyTokens(_to , _value , now);
        return true;
    }


    function transfer(address _to, uint256 _value) checkKYC public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }


    function transferFrom(address _from, address _to, uint256 _value) checkKYC public returns (bool success) {
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        require(allowance[_from][msg.sender] >= _value);
        balanceOf[_to] += _value;
        balanceOf[_from] -= _value;
        allowance[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }


    function approve(address _spender, uint256 _value) checkKYC public returns (bool success) {
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
    event eventAddressCrowdsale(address indexed _address, uint256 _date);
    event eventAddressKYC(address indexed _address, uint256 _date);
    event eventSetAddress(address indexed _address, uint256 _time , string _type);
    event eventBuyTokens(address indexed _address , uint256 _value , uint256 _date);
    event eventStatusKYC(bool indexed _value, uint256 _date);
    
    

}