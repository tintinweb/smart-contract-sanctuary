pragma solidity ^0.4.19;

library SafeMath { //standard library for uint
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

//standard contract to identify owner
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
contract BineuroToken{
  function setCrowdsaleContract (address) public;
  function sendCrowdsaleTokens(address, uint256)  public;
  function burnTokens(address,address, address, uint) public;
  function getOwner()public view returns(address);
}

//Crowdsale contract
contract Crowdsale is Ownable{

  using SafeMath for uint;

  uint public decimals = 3;
  // Token contract address
  BineuroToken public token;

  // Constructor
  function Crowdsale(address _tokenAddress) public{
    token = BineuroToken(_tokenAddress);
    techSupport = msg.sender;

    token.setCrowdsaleContract(this);
    owner = token.getOwner();
  }

  address etherDistribution1 = 0x64f89e3CE504f1b15FcD4465b780Fb393ab79187;
  address etherDistribution2 = 0x320359973d7953FbEf62C4f50960C46D8DBE2425;

  address bountyAddress = 0x7e06828655Ba568Bbe06eD8ce165e4052A6Ea441;

  //Crowdsale variables
  uint public tokensSold = 0;
  uint public ethCollected = 0;

  // Buy constants
  uint public minDeposit = (uint)(500).mul((uint)(10).pow(decimals));

  uint public tokenPrice = 0.0001 ether;

  // Ico constants
  uint public icoStart = 1522141200; //27.03.2018  12:00 UTC+3
  uint public icoFinish = 1528156800; //27.03.2018  12:00 UTC+2

  uint public maxCap = 47000000 ether;

  //Owner can change end date
  function changeIcoFinish (uint _newDate) public onlyTechSupport {
    icoFinish = _newDate;
  }

  //check is now ICO
  function isIco(uint _time) public view returns (bool){
    if((icoStart <= _time) && (_time < icoFinish)){
      return true;
    }
    return false;
  }

  function timeBasedBonus(uint _time) public view returns(uint res) {
    res = 20;
    uint timeBuffer = icoStart;
    for (uint i = 0; i<10; i++){
      if(_time <= timeBuffer + 7 days){
        return res;
      }else{
        res = res - 2;
        timeBuffer = timeBuffer + 7 days;
      }
      if (res == 0){
        return (0);
      }
    }
    return res;
  }
  
  function volumeBasedBonus(uint _value)public pure returns(uint res) {
    if(_value < 5 ether){
      return 0;
    }
    if (_value < 15 ether){
      return 2;
    }
    if (_value < 30 ether){
      return 5;
    }
    if (_value < 50 ether){
      return 8;
    }
    return 10;
  }
  
  //fallback function (when investor send ether to contract)
  function() public payable{
    require(isIco(now));
    require(ethCollected.add(msg.value) <= maxCap);
    require(buy(msg.sender,msg.value, now)); //redirect to func buy
  }

  //function buy Tokens
  function buy(address _address, uint _value, uint _time) internal returns (bool){
    uint tokensForSend = etherToTokens(_value,_time);

    require (tokensForSend >= minDeposit);

    tokensSold = tokensSold.add(tokensForSend);
    ethCollected = ethCollected.add(_value);

    token.sendCrowdsaleTokens(_address,tokensForSend);
    etherDistribution1.transfer(this.balance/2);
    etherDistribution2.transfer(this.balance);

    return true;
  }

  function manualSendTokens (address _address, uint _tokens) public onlyTechSupport {
    token.sendCrowdsaleTokens(_address, _tokens);
    tokensSold = tokensSold.add(_tokens);
  }
  

  //convert ether to tokens (without decimals)
  function etherToTokens(uint _value, uint _time) public view returns(uint res) {
    res = _value.mul((uint)(10).pow(decimals))/(tokenPrice);
    uint bonus = timeBasedBonus(_time).add(volumeBasedBonus(_value));
    res = res.add(res.mul(bonus)/100);
  }

  bool public isIcoEnded = false;
  function endIco () public {
    require(!isIcoEnded);
    require(msg.sender == owner || msg.sender == techSupport);
    require(now > icoFinish + 5 days);
    token.burnTokens(etherDistribution1,etherDistribution2, bountyAddress, tokensSold);
    isIcoEnded = true;
  }
}