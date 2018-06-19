pragma solidity ^0.4.11;

library SafeMath {
  function mul(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }

  function max64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a < b ? a : b;
  }

}

// Interfacting Deployed Nertia Token 
contract KairosToken{
  function getExchangeRate() returns (uint256 exchangeRate);
  function balanceOf(address _owner) constant returns (uint256 balance);
  function getOwner() returns (address owner);
  function getDecimals() returns (uint256 decimals);
  function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
}


/**
 * ICO contract for the Nertia Token
 */
contract Crowdsale {

  using SafeMath for uint256;

  address public ethOwner;
  address public kairosOwner;

  KairosToken public token;

  mapping(address => uint256) etherBlance;

  uint256 public decimals;
  uint256 public icoMinCap;
    
  bool public isFinalized;
  uint256 public icoStartBlock;
  uint256 public icoEndBlock;
  uint256 public icoStartTime;
  uint256 public totalSupply;
  uint256 public exchangeRate;

  event Refund(address indexed _to, uint256 _value);
  event RefundError(address indexed _to, uint256 _value);
    
  function Crowdsale() {
    token          = KairosToken(0xa6C9e4D4B34D432d4aea793Fa8C380b9940a5279);
    decimals       = token.getDecimals();
    exchangeRate   = 20;
    isFinalized    = false;
    icoStartTime   = now;
    icoStartBlock  = block.number.add(15247);
    icoEndBlock    = icoStartBlock.add(152470);
    ethOwner       = 0x0fe777FA444Fae128169754877d51b665eE557Ee;
    kairosOwner    = 0xa6C9e4D4B34D432d4aea793Fa8C380b9940a5279;
    icoMinCap      = 15 * (10**6) * 10**decimals;
  }


  /// @dev Ends the funding period and sends the ETH home
  function finalize() external {
    if(isFinalized) throw;
    if(msg.sender != ethOwner) throw; // locks finalize to the ultimate ETH owner
    //if(totalSupply < icoMinCap) throw;      // have to sell minimum to move to operational
    if(block.number <= icoEndBlock) throw;
    
    // move to operational
    isFinalized = true;
    if(!ethOwner.send(this.balance)) throw;  // send the eth to Nertia Owner
  }


  function refund(){
    if(isFinalized) throw;
    if(block.number <= icoEndBlock) throw;
    if(msg.sender == token.getOwner() ) throw;

    uint256 userBalance = token.balanceOf(msg.sender);
    if(userBalance == 0) throw;

    uint256 userEthers = etherBlance[msg.sender];
    if(userEthers == 0) throw;    
    
    etherBlance[msg.sender] = 0;
    
    if(!token.transferFrom(msg.sender,kairosOwner, userBalance)) throw;

    if(msg.sender.send(userEthers)){
      Refund(msg.sender, userEthers);
    }else{
      etherBlance[msg.sender] = userEthers;
      RefundError(msg.sender, userEthers);
      throw;
    }
  }


  function () payable {
    if(isFinalized && msg.value <= 0) throw;

    if(block.number < icoStartBlock) throw;
    if(block.number > icoEndBlock) throw;

    // storing user ethers;
    etherBlance[msg.sender] += msg.value;

    // calculating bonus
    uint256 val = msg.value;
    uint256 bonus  =  calcBonus(val);
    uint256 level2bonus = calcLevel2Bonus(val);
    uint256 tokens = msg.value.add(level2bonus).add(bonus).mul(exchangeRate);    
    uint256 checkedSupply = totalSupply.add(tokens);
    totalSupply = checkedSupply;
    bool transfer = token.transferFrom( token.getOwner(),msg.sender, tokens);
    if(!transfer){
        totalSupply = totalSupply.sub(tokens);
        throw;
    }
  }
  
  // Calculating bounus tokens
  function calcBonus(uint256 _val) private constant returns (uint256){
    return _val.div(100).mul(getPercentage());            
  }  

  // Calculating bonus percentage 
  function getPercentage() private constant returns (uint){
    uint duration = now.sub(icoStartTime);
    if(duration > 21 days){
      return 0;
    } else if(duration <= 21 days && duration > 14 days){
      return 1;
    } else if(duration <= 14 days && duration > 7 days){
      return 3;
    } else {
      return 5;
    }
  }

  function calcLevel2Bonus(uint256 _val) private constant returns(uint256) {
    return _val.div(100).mul(level2Bonus(_val));
  }

  // calculating 2nd level bonus
  function level2Bonus(uint256 tokens) private constant returns(uint256) {
      if(tokens > 1000000){
        return 5;   
      }else if(tokens <= 999999 && tokens >= 100000){
        return 3;
      }else if(tokens <= 99999 && tokens >= 50000 ){
        return 2;
      }else if( tokens <= 49999 && tokens >= 10000){
        return 1;
      }
      return 0;
  }


}