pragma solidity ^0.4.25;
library SafeMath {
    uint256 constant public MAX_UINT256 =
    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
    /*
    *  Adds two numbers, throws on overflow.
    */
    function safeAdd(uint256 x, uint256 y) pure  internal returns (uint256 z) {
        if (x > MAX_UINT256 - y) revert();
        return x + y;
    }
    /*
     *  Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
     */
    function safeSub(uint256 x, uint256 y) pure internal returns (uint256 z) {
        if (x < y)  revert();
        return x - y;
    }
}
contract ERC223 {
  uint public totalSupply;
  function balanceOf(address who) public constant returns (uint);
  function totalSupply()public constant returns (uint256 _supply);
}
contract WCG{
    using SafeMath for uint256;
    address owner;
    //The token holds to the message
   struct userToken{
        address buyer;
        uint currentPrice;
        uint _token;
        uint totalToKenPrice;
        uint charge;
        uint totalBuyPrice;
    }
    userToken[] _userTokenInfo;
    mapping(address => uint256) private balances;
    //Bonus pools
    mapping(address => uint256) private bonusPools;
    //capital pool 
    mapping(address => uint256) private capitalPool;
    string public name = "wcg";
    string public symbol = "WCG";
    uint256 public totalSupply = 0;
    
    uint constant initPrice = 0.01 ether;
    uint private presellUpToTime;
    uint  private presellToKenAmount;
    event transfer(address addr,address contractAddr,uint token,uint totalSupply);
  modifier onlyOwner(){
       require(msg.sender == owner);
        _;
  }
  modifier upToTimeOrTotalSupply(){
      require(now < presellUpToTime || totalSupply < presellToKenAmount);
      _;
  }
  function getUserTokenInfosLength()public view returns(uint length){
      length = _userTokenInfo.length;
  }
  
  function getUserTokenInfos(uint index)public view returns(address buyer,uint currentPrice,uint _token,uint totalToKenPrice,uint charge,uint totalBuyPrice){
     userToken storage _userToKen = _userTokenInfo[index];
     buyer = _userToKen.buyer;
     currentPrice = _userToKen.currentPrice;
     _token = _userToKen._token;
     totalToKenPrice = _userToKen.totalToKenPrice;
     charge = _userToKen.charge;
     totalBuyPrice = _userToKen.totalBuyPrice;
  }
  constructor(uint _presellToKen,uint _presellUpToTime)public{
      presellUpToTime = now + (_presellUpToTime * 1 days);
      owner = msg.sender;
      presellToKenAmount = _presellToKen* 1e18 / initPrice;
  }
  //Buy WCG
  function buyToKen(uint _token)public payable upToTimeOrTotalSupply{
      uint totalToKenPrice = buyPrice(_token);
      uint charge = computingCharge(totalToKenPrice);
      if( msg.value < totalToKenPrice+charge)revert();
      bonusPools[this] = SafeMath.safeAdd(bonusPools[this],charge);
      capitalPool[this] = SafeMath.safeAdd(capitalPool[this],totalToKenPrice);
      address(this).transfer(msg.value);
      balances[this] = SafeMath.safeAdd(balances[this],msg.value);
      _userTokenInfo.push(userToken(msg.sender,currentPrice(),_token,totalToKenPrice,charge,totalToKenPrice+charge));
      totalSupply =  SafeMath.safeAdd(totalSupply,_token);
      balances[msg.sender] = SafeMath.safeAdd(balances[msg.sender],_token);
      emit transfer(msg.sender,address(this),_token,totalSupply);
  }
  
  function()public payable{}
  function EthTurnWCG(uint eth)public pure returns(uint){
      return eth * 1e18 / (initPrice+initPrice/10);
  }
  function currentPrice()public pure returns(uint){
      return initPrice;
  }
  function buyPrice(uint _token)public pure returns(uint){
      return  _token * currentPrice();
  }
  function computingCharge(uint price)public pure returns(uint){
      return price / 10;
  }
  function getPresellToKenAmount()public view returns(uint){
      return presellToKenAmount;
  }
  function getPresellUpToTime()public constant returns(uint){
      return presellUpToTime;
  }
  function capitalPoolOf(address who) public constant returns (uint){
      return capitalPool[who];
  }
  function bonusPoolsOf(address who) public constant returns (uint){
      return bonusPools[who];
  }
  function balanceOf(address who) public constant returns (uint){
      return balances[who];
  }
  function totalSupply()public constant returns (uint256 _supply){
      return totalSupply;
  }
  function setPresellUpToTime(uint time)public onlyOwner{
      presellUpToTime = now + (time * 1 days);
  }

  function destroy()public onlyOwner {
      selfdestruct(owner);
  }

}