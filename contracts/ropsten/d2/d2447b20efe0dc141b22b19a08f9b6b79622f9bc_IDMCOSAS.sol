pragma solidity ^0.4.18;

///как я заебался не спать

contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}
 

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
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
 
contract BasicToken is ERC20Basic {
    
  using SafeMath for uint256;
 
  mapping(address => uint256) balances;
 
 function transfer(address _to, uint256 _value) public returns (bool) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }
 
 function balanceOf(address _owner) public constant returns (uint256 balance) {
    return balances[_owner];
  }
 
}
 
contract StandardToken is ERC20, BasicToken {
 
  mapping (address => mapping (address => uint256)) allowed;
 
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    var _allowance = allowed[_from][msg.sender];
    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }
 
 function approve(address _spender, uint256 _value) public returns (bool) {
 
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));
 
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }
 
 function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }
 
}
 
contract Ownable {
    
  address public owner;

 
  
  function Ownable() public {
    owner = msg.sender;
  }
 
modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
 
function changeOwner(address _owner) onlyOwner public {
        owner = _owner;
    }
}
 

contract BurnableToken is StandardToken {
 
  
  function burn(uint _value) public {
    require(_value > 0);
    address burner = msg.sender;
    balances[burner] = balances[burner].sub(_value);
    totalSupply = totalSupply.sub(_value);
    Burn(burner, _value);
  }
 
  event Burn(address indexed burner, uint indexed value);
 
}
 
contract IDMCOSAS is BurnableToken {
    
  string public constant name = "IDMCOSAS";
   
  string public constant symbol = "MCS";
    
  uint32 public constant decimals = 18;
  
}
 
contract CrowdsaleIDMCOSAS is Ownable {
    
  using SafeMath for uint;
    
  address multisig;
 
  uint restrictedPercent;
 
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
  
  mapping(address => uint) public balances;
  
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
     multisig = 0xAdf2E4D1a2471cFc44C219FB7086Ea9887358b71;
     restricted = 0xAdf2E4D1a2471cFc44C219FB7086Ea9887358b71;
     restrictedPercent = 15;
     rate = 60000000000000000000000000;
     start = 1535760000;
     period = 91;
     balanceOf[this] = 100000000000000000000000000;
     balanceOf[owner] = totalSupply - balanceOf[this];
     Transfer(this, owner, balanceOf[owner]);
     hardcap = 60000000000000000000000000;
     softcap = 1582000000000000000000000;
  }
 
	 function () public payable {
     require(balanceOf[this] > 0);
     tokensPerOneEther = 189;
     uint256 tokens = tokensPerOneEther * msg.value / 100000000000000000000000000;
     if (tokens > balanceOf[this]) {
     tokens = balanceOf[this];
     uint valueWei = tokens * 100000000000000000000000000 / tokensPerOneEther;
     msg.sender.transfer(msg.value - valueWei);
        }
        require(tokens > 0);
        balanceOf[msg.sender] += tokens;
        balanceOf[this] -= tokens;
        Transfer(this, msg.sender, tokens);
            }
 
  modifier saleIsOn() {
    require(now > start && now < start + period * 1 days);
    _;
  }
 
  function createTokens() saleIsOn public payable {
    multisig.transfer(msg.value);
    uint tokens = rate.mul(msg.value).div(1 ether);
    bonusTokens = 15000000000000000000000000;
    if(now < start + (period * 1 days).div(4)) {
      bonusTokens = tokens.div(4);
    } else if(now >= start + (period * 1 days).div(4) && now < start + (period * 1 days).div(4).mul(2)) {
      bonusTokens = tokens.div(10);
    } else if(now >= start + (period * 1 days).div(4).mul(2) && now < start + (period * 1 days).div(4).mul(3)) {
      bonusTokens = tokens.div(20);
    }
    uint tokensWithBonus = tokens.add(bonusTokens);
    token.transfer(msg.sender, tokensWithBonus);
    uint restrictedTokens = tokens.mul(restrictedPercent).div(100 - restrictedPercent);
    token.transfer(restricted, restrictedTokens);
  }
 
      function refund() onlyOwner public {
      require(this.balance < softcap && now > start + period * 1 days);
      uint256 value = balances[msg.sender]; 
      balances[msg.sender] = 0; 
      msg.sender.transfer(value); 
      }
 }