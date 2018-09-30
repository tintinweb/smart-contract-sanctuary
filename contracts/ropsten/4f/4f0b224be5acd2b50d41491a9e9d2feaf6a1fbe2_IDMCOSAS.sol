pragma solidity ^0.4.25;


contract Ownable {
    
  address public owner;

 function Owner() public {
    owner = msg.sender;
  }
 
modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
 
function changeOwner(address _owner) onlyOwner payable public {
        owner = _owner;
    }
}
 
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure  returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure  returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}
 
contract IDMCOSAS {
 
 
    uint256 public totalSupply;
   function balanceOf(address _owner) public constant returns (uint256 balance) {
    return balances[_owner];
  }
  function transfer(address _to, uint256 _value) public returns (bool) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }
  
   function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }
   function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
   
    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] -= _value;
    emit Transfer(_from, _to, _value);
    return true;
  }
  function approve(address _spender, uint256 _value) public returns (bool) {
 
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));
 
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }
 
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
  
   
  using SafeMath for uint256;
 
  mapping(address => uint256) balances;
 
  
  mapping (address => mapping (address => uint256)) allowed;
 
  
  function burn(uint256 _value) public {
    require(_value > 0);
    address burner = msg.sender;
    balances[burner] = balances[burner].sub(_value);
    totalSupply = totalSupply.sub(_value);
    emit Burn(burner, _value);
  }
 
  event Burn(address indexed burner, uint256 indexed value);
 
    
  string public constant name = "IDMCOSAS";
   
  string public constant symbol = "MCS";
    
  uint256 public constant decimals = 18;
  
}
 
contract CrowdsaleIDMCOSAS is Ownable {
    
  using SafeMath for uint256;
    
  address multisig;
 
  uint256 restrictedPercent;
 
  address restricted;
 
  IDMCOSAS public token = new IDMCOSAS();
 
  uint256 start;
    
  uint256 period;
  
  uint256 public softcap;
  
  uint256 public hardcap;
 
  uint256 public rate;
  
  uint256 public totalSupply;
  
  uint256 public tokensPerOneEther;
  
  uint256 public bonusTokens;
  
  mapping (address => uint256) public balanceOf;
  
  event Transfer(address indexed from, address indexed to, uint256 value);
  
  mapping(address => uint256) public balances;
  
    function CrowdsaleMCS() onlyOwner public {        
		balances[msg.sender] = 100000000000000000000000000; 
  }
 
  function setPerOneEther (uint256 _tokensPerOneEther) onlyOwner public {
        tokensPerOneEther = _tokensPerOneEther;
    }
    
    function setbonusTokens (uint256 _bonusTokens) onlyOwner public {
        bonusTokens = _bonusTokens;
    }
    
     function setrate (uint256 _rate) onlyOwner public {
        rate = _rate;
    }
    
     function setsetperiod (uint256 _period) onlyOwner public {
        period = _period;
    }

    function sethardcap (uint256 _hardcap) onlyOwner public {
        hardcap = _hardcap;
    }
  
     function Crowdsale() public payable {
     totalSupply = 100000000 * 1 ether;
     multisig = 0xF167854446A3E7eeB12d0Fb51c38bB53d8b5435f;
     restricted = 0xF167854446A3E7eeB12d0Fb51c38bB53d8b5435f;
     restrictedPercent = 15;
     rate = 60000000000000000000000000;
     start = 1535760000;
     period = 91;
     balanceOf[this] = 100000000000000000000000000;
     balanceOf[owner] = totalSupply - balanceOf[this];
     emit Transfer(this, owner, balanceOf[owner]);
     hardcap = 60000000000000000000000000;
     softcap = 1582000000000000000000000;
  }
 
	 function () public payable {
     require(balanceOf[this] > 0);
     tokensPerOneEther = 189;
     uint256 tokens = tokensPerOneEther * msg.value / 100000000000000000000000000;
     if (tokens > balanceOf[this]) {
     tokens = balanceOf[this];
     uint256 valueWei = tokens * 100000000000000000000000000 / tokensPerOneEther;
     msg.sender.transfer(msg.value - valueWei);
        }
        require(tokens > 0);
        balanceOf[msg.sender] += tokens;
        balanceOf[this] -= tokens;
        emit Transfer(this, msg.sender, tokens);
            }
 
  modifier saleIsOn() {
    require(now > start && now < start + period * 1 days);
    _;
  }
 
  function createTokens() saleIsOn public payable {
    multisig.transfer(msg.value);
    uint256 tokens = rate.mul(msg.value).div(1 ether);
    bonusTokens = 0;
    if(now < start + (period * 1 days).div(4)) {
      bonusTokens = tokens.div(4);
    } else if(now >= start + (period * 1 days).div(4) && now < start + (period * 1 days).div(4).mul(2)) {
      bonusTokens = tokens.div(10);
    } else if(now >= start + (period * 1 days).div(4).mul(2) && now < start + (period * 1 days).div(4).mul(3)) {
      bonusTokens = tokens.div(20);
    }
    uint256 tokensWithBonus = tokens.add(bonusTokens);
    token.transfer(msg.sender, tokensWithBonus);
    uint256 restrictedTokens = tokens.mul(restrictedPercent).div(100 - restrictedPercent);
    token.transfer(restricted, restrictedTokens);
  }
 
      function refund() onlyOwner public {
      require(balanceOf[this] < softcap && now > start + period * 1 days);
      uint256 value = balances[msg.sender]; 
      balances[msg.sender] = 0; 
      msg.sender.transfer(value); 
      }
 }