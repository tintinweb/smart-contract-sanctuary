pragma solidity ^0.4.11;


contract ERC20Basic {
  uint256 public totalSupply = 0;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  function transfer(address _to, uint256 _value) returns (bool) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }
}


contract Ownable {
  address public owner;

  function Ownable() {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
}



contract AKM is BasicToken, Ownable {
  using SafeMath for uint256;
  
  string public constant name = "AKM Token";
  string public constant symbol = "AKM";
  uint256 public constant decimals = 8;
  
  uint256 public tokenPerWai = (10 ** (18 - decimals) * 1 wei) / 1250;
  uint256 public token = 10 ** decimals;
  uint256 public constant INITIAL_SUPPLY = 2800000;
  
  uint256 public creationTime;
  bool public is_started_bonuses = false;
  bool public is_started_payouts = true;
  
  function emissionPay(uint256 _ammount) private {
    uint256 ownBonus = _ammount.div(100).mul(25);
    totalSupply = totalSupply.add(_ammount.add(ownBonus));
    
    balances[msg.sender] = balances[msg.sender].add(_ammount);
    balances[owner] = balances[owner].add(ownBonus);
    
    if(msg.value > 10 ether) 
      Transfer(0, msg.sender, _ammount);
    Transfer(this, owner, ownBonus);
    Transfer(this, msg.sender, _ammount);
  }
  
  function extraEmission(uint256 _ammount) public onlyOwner {
    _ammount = _ammount.mul(token);
    totalSupply = totalSupply.add(_ammount);
    balances[owner] = balances[owner].add(_ammount);
    Transfer(this, owner, _ammount);
  }

  
  function AKM() {
    totalSupply = INITIAL_SUPPLY.mul(token);
    balances[owner] = totalSupply;
  }
  
  function startBonuses() public onlyOwner {
    if(!is_started_bonuses) {
      creationTime = now;
      is_started_bonuses = true;
    }
  }
  
  function startPayouts() public onlyOwner {
    is_started_payouts = true;
  }
  
  function stopPayouts() public onlyOwner {
    is_started_payouts = false;
  }
  
  function setTokensPerEther(uint256 _value) public onlyOwner {
     require(_value > 0);
     tokenPerWai = (10 ** 10 * 1 wei) / _value;
  }
  
  function getBonusPercent() private constant returns(uint256) {
    if(!is_started_bonuses) return 100;
    uint256 diff = now.sub(creationTime);
    uint256 diff_weeks = diff.div(1 weeks);
    if(diff_weeks < 1) // 0 ... 1 week
      return 130;
    else if(diff_weeks < 2)// 1 ... 2 week
      return 125;
    else if(diff_weeks < 3)// 2 ... 3 week
      return 120;
    else if(diff_weeks < 4)// 3 ... 4 week
      return 115;
    else if(diff_weeks < 5)// 4 ... 5 week
      return 110;
    else {
      is_started_bonuses = false;
      return 100;
    }
  }
  
  
  function() payable {
    assert(is_started_payouts);
    uint256 amount = msg.value.div(tokenPerWai);
    amount = amount.div(100).mul(getBonusPercent());
    emissionPay(amount);
    owner.transfer(msg.value);
  }
  
  
}