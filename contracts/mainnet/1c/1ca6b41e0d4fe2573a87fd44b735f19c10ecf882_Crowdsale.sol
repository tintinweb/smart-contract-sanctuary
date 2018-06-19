pragma solidity ^0.4.20;

library SafeMath { //standart library for uint
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0 || b == 0){
        return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }

  function pow(uint256 a, uint256 b) internal pure returns (uint256){ //power function
    if (b == 0){
      return 1;
    }
    uint256 c = a**b;
    assert (c >= a);
    return c;
  }
}

//standart contract to identify owner
contract Ownable {

  address public owner;

  address public newOwner;

  address public techSupport;

  address public newTechSupport;

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  modifier onlyTechSupport() {
    require(msg.sender == techSupport || msg.sender == owner);
    _;
  }

  function Ownable() public {
    owner = msg.sender;
  }

  function transferOwnership(address _newOwner) public onlyOwner {
    require(_newOwner != address(0));
    newOwner = _newOwner;
  }

  function acceptOwnership() public {
    if (msg.sender == newOwner) {
      owner = newOwner;
    }
  }

  function transferTechSupport (address _newSupport) public{
    require (msg.sender == owner || msg.sender == techSupport);
    newTechSupport = _newSupport;
  }

  function acceptSupport() public{
    if(msg.sender == newTechSupport){
      techSupport = newTechSupport;
    }
  }

}

//Abstract Token contract
contract HeliosToken{
  function setCrowdsaleContract (address) public;
  function sendCrowdsaleTokens(address, uint256) public;
  function endIco() public;
}

//Crowdsale contract
contract Crowdsale is Ownable{

  using SafeMath for uint;

  uint decimals = 2;
  // Token contract address
  HeliosToken public token;

  // Constructor
  function Crowdsale(address _tokenAddress) public{
    token = HeliosToken(_tokenAddress);
    techSupport = 0xcDDC1cE0b7D4C9B018b8a4b8f7Da2678D56E8619;

    token.setCrowdsaleContract(address(this));
    owner = 0xA957c13265Cb1b101401d10f5E0b69E0b36ef000;
  }

  //Crowdsale variables
  uint public preIcoTokensSold = 0;
  uint public tokensSold = 0;
  uint public ethCollected = 0;

  mapping (address => uint) contributorBalances;

  uint public tokenPrice = 0.001 ether;

  //preIco constants
  uint public constant preIcoStart = 1525168800; //1525168800
  uint public constant preIcoFinish = 1527847200;
  uint public constant preIcoMinInvest = 50*(uint(10).pow(decimals)); //50 Tokens
  uint public constant preIcoMaxCap = 500000*(uint(10).pow(decimals)); //500000 Tokens

  // Ico constants
  uint public constant icoStart = 1530439200; 
  uint public constant icoFinish = 1538388000; 
  uint public constant icoMinInvest = 10*(uint(10).pow(decimals)); //10 Tokens

  uint public constant minCap = 1000000 * uint(10).pow(decimals);

  function isPreIco (uint _time) public pure returns(bool) {
    if((preIcoStart <= _time) && (_time < preIcoFinish)){
      return true;
    }
  }
  
  //check is now ICO
  function isIco(uint _time) public pure returns (bool){
    if((icoStart <= _time) && (_time < icoFinish)){
      return true;
    }
    return false;
  }

  function timeBasedBonus(uint _time) public pure returns(uint) {
    if(isPreIco(_time)){
      if(preIcoStart + 1 weeks > _time){
        return 20;
      }
      if(preIcoStart + 2 weeks > _time){
        return 15;
      }
      if(preIcoStart + 3 weeks > _time){
        return 10;
      }
    }
    if(isIco(_time)){
      if(icoStart + 1 weeks > _time){
        return 20;
      }
      if(icoStart + 2 weeks > _time){
        return 15;
      }
      if(icoStart + 3 weeks > _time){
        return 10;
      }
    }
    return 0;
  }
  
  event OnSuccessfullyBuy(address indexed _address, uint indexed _etherValue, bool indexed isBought, uint _tokenValue);

  //fallback function (when investor send ether to contract)
  function() public payable{
    require(isPreIco(now) || isIco(now));
    require(buy(msg.sender,msg.value, now)); //redirect to func buy
  }

  //function buy Tokens
  function buy(address _address, uint _value, uint _time) internal returns (bool){
    
    uint tokensToSend = etherToTokens(_value,_time);

    if (isPreIco(_time)){
      require (tokensToSend >= preIcoMinInvest);
      require (preIcoTokensSold.add(tokensToSend) <= preIcoMaxCap);
      
      token.sendCrowdsaleTokens(_address,tokensToSend);
      preIcoTokensSold = preIcoTokensSold.add(tokensToSend);

      tokensSold = tokensSold.add(tokensToSend);
      distributeEther();

    }else{
      require (tokensToSend >= icoMinInvest);
      token.sendCrowdsaleTokens(_address,tokensToSend);

      contributorBalances[_address] = contributorBalances[_address].add(_value);

      tokensSold = tokensSold.add(tokensToSend);

      if (tokensSold >= minCap){
        distributeEther();
      }
    }

    emit OnSuccessfullyBuy(_address,_value,true, tokensToSend);
    ethCollected = ethCollected.add(_value);

    return true;
  }

  address public distributionAddress = 0x769EDcf3756A3Fd4D52B739E06dF060b7379C4Ef;
  function distributeEther() internal {
    distributionAddress.transfer(address(this).balance);
  }
  
  event ManualTokensSended(address indexed _address, uint indexed _value, bool );
  
  function manualSendTokens (address _address, uint _tokens) public onlyTechSupport {
    token.sendCrowdsaleTokens(_address, _tokens);
    tokensSold = tokensSold.add(_tokens);
    emit OnSuccessfullyBuy(_address,0,false,_tokens);
  }

  function manualSendEther (address _address, uint _value) public onlyTechSupport {
    uint tokensToSend = etherToTokens(_value, 0);
    tokensSold = tokensSold.add(tokensToSend);
    ethCollected = ethCollected.add(_value);

    token.sendCrowdsaleTokens(_address, tokensToSend);
    emit OnSuccessfullyBuy(_address,_value,false, tokensToSend);
  }
  
  //convert ether to tokens (without decimals)
  function etherToTokens(uint _value, uint _time) public view returns(uint res) {
    if(_time == 0){
        _time = now;
    }
    res = _value.mul((uint)(10).pow(decimals))/tokenPrice;
    uint bonus = timeBasedBonus(_time);
    res = res.add(res.mul(bonus)/100);
  }

  event Refund(address indexed contributor, uint ethValue);  

  function refund () public {
    require (now > icoFinish && tokensSold < minCap);
    require (contributorBalances[msg.sender] != 0);

    msg.sender.transfer(contributorBalances[msg.sender]);

    emit Refund(msg.sender, contributorBalances[msg.sender]);

    contributorBalances[msg.sender] = 0;
  }
  
  function endIco () public onlyTechSupport {
    require(now > icoFinish + 5 days);
    token.endIco();
  }
  
}