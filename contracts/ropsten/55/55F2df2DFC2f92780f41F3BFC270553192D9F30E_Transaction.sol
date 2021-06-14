pragma solidity >=0.4.22 <0.9.0;

import "./BEP20Token.sol";
import "./SafeMath.sol";


contract Transaction{
    using SafeMath for uint256;
    
    mapping(address => bool) public dropClaimers;
    
    address public tokenAddr;
    address payable public tokenOwner; //token owner is the owner of this contract too
    uint256 public tokensPerWei;
    uint256 public dropFees;
    uint256 public airDropQuota; // Quota of tokens for airdrops out of the total allowance.
    uint256 public tokensPerAirDrop;
    BEP20Token Token;
    
    
    constructor(
        address  _tokenAddress
        // address payable _tokenOwner
        ) 
        public
        {
        tokenAddr = _tokenAddress;
        tokenOwner = msg.sender;       
        Token = BEP20Token(address(tokenAddr));

        dropFees = 60000000000000;
        tokensPerWei = 10000000;
        airDropQuota = 3000000000000000000000;
        tokensPerAirDrop = 1000000000000000000000;

    }
    
    modifier onlyOwner(){
        require(tokenOwner == msg.sender);
        _;
    }
    
    function getOwner() external view returns(address){
        return tokenOwner;
    }

    function setTokensPerWei(uint256 _tokens) public onlyOwner {
        require(_tokens > 0, "Atleast 1 token should be equal to 1 wei");
        tokensPerWei = _tokens; // the price and fees is set in wei.
    }
    
    function setFees(uint256 _fees) public onlyOwner {
        require(_fees > 0, "Fees need to be greater than zero.");
        dropFees = _fees;
    }
    
    function setAirDropQuota(uint256 _value) public onlyOwner{
        require(_value > 0);
        airDropQuota = _value;
    }
    
    function getAirDropQuota() external view returns(uint256){
        return airDropQuota;
    }
    
    function setTokensPerAirDrop(uint256 _value) public onlyOwner{
        require(_value > 0);
        tokensPerAirDrop = _value;
    }

    function transferOwnership(address payable newOwner) public returns(bool){
        require(tokenOwner == msg.sender, "Only current owner can change ownership"); //only owner
        tokenOwner = newOwner;

        return true;
    }
    
    function buyToken() public payable returns(bool){
        require(msg.value >= tokensPerWei);
        uint256 _tokenAmount;
        _tokenAmount = msg.value.mul(tokensPerWei);
        
        tokenOwner.transfer(msg.value);
        Token.transferFrom(tokenOwner, msg.sender, _tokenAmount);
        
        return(true);
    }
    
    function getAirDrop() public payable {
      
        require(dropClaimers[msg.sender] == false, "You've already claimed the AirDrop");    
        require(dropFees <= msg.value, 'Insufficient ammount'); // sent wei > drop fees.
        require(airDropQuota >= tokensPerAirDrop, "Insufficient Airdrop Quota.");
                             
        tokenOwner.transfer(msg.value);
        
       
        Token.transferFrom(tokenOwner, msg.sender, tokensPerAirDrop);
        dropClaimers[msg.sender] = true;
        airDropQuota = airDropQuota.sub(tokensPerAirDrop); //reducing airDropQuota.
    }
}