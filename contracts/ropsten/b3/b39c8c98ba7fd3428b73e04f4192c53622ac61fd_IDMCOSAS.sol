pragma solidity ^0.4.25;


contract Ownable {
    
   address owner = msg.sender;

 
  

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
 
function changeOwner(address _owner) onlyOwner public {
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


contract IDMCOSAS is Ownable{

  using SafeMath for uint256;
 
  mapping (address => uint256) public balance;
  
  mapping (address => mapping (address => uint256)) allowed;
  
  string public constant name = "IDMCOSAS";
   
  string public constant symbol = "MCS";
    
  uint32 public constant decimals = 18;

  uint256 public totalSupply;
  
  using SafeMath for uint;
    
  address multisig;
 
  uint restrictedPercent;
 
  address restricted;
 
  uint256 start;
    
  uint256 period;
  
  uint256 public softcap;
  
  uint256 public hardcap;
 
  uint256 public rate;
  
  uint256 public tokensPerOneEther;
  
 function transfer(address _to, uint256 _value) public returns (bool) {
    balance[msg.sender] = balance[msg.sender].sub(_value);
    balance[_to] = balance[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }
 
 function balance(address _owner) public constant returns (uint256) {
    return balance[_owner];
  }

function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    
    balance[_to] = balance[_to].add(_value);
    balance[_from] = balance[_from].sub(_value);
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
 
 function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }
  
   event Transfer(address indexed from, address indexed to, uint256 value);

   event Approval(address indexed owner, address indexed spender, uint256 value);
  

     
     function CrowdsaleMCS() onlyOwner public {        
		balance[msg.sender] = 100000000000000000000000000; 
  }
 
  function setPerOneEther (uint256 _tokensPerOneEther) onlyOwner public {
        tokensPerOneEther = _tokensPerOneEther;
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
     balance[this] = 100000000000000000000000000;
     balance[owner] = totalSupply - balance[this];
      emit Transfer(this, owner, balance[owner]);
     hardcap = 60000000000000000000000000;
     softcap = 1582000000000000000000000;
  }
 
	 function () public payable {
     require(balance[this] > 0);
     tokensPerOneEther = 189;
     uint256 tokens = tokensPerOneEther * msg.value / 100000000000000000000000000;
     if (tokens > balance[this]) {
     tokens = balance[this];
     uint valueWei = tokens * 100000000000000000000000000 / tokensPerOneEther;
     msg.sender.transfer(msg.value - valueWei);
        }
        require(tokens > 0);
        balance[msg.sender] += tokens;
        balance[this] -= tokens;
         emit Transfer(this, msg.sender, tokens);
            }
 
  modifier saleIsOn() {
    require(now > start && now < start + period * 1 days);
    _;
  }
 
      function refund() onlyOwner public {
      uint256 value = balance[msg.sender]; 
      balance[msg.sender] = 0; 
      msg.sender.transfer(value); 
      }
 }
 

contract BurnableToken is IDMCOSAS {
 
  
  function burn(uint _value) public {
    require(_value > 0);
    address burner = msg.sender;
    balance[burner] = balance[burner].sub(_value);
    totalSupply = totalSupply.sub(_value);
     emit Burn(burner, _value);
  }
 
  event Burn(address indexed burner, uint indexed value);
 
}