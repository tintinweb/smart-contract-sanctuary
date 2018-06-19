pragma solidity ^0.4.12;

contract ElevenOfTwelve {
    
    // totalSupply = Maximum is 210000 Coins with 18 decimals;
    // Only 1/100 of the maximum bitcoin supply.
    // Nur 1/100 vom maximalen Bitcoin Supply.
    // ElevenOfTwelve IS A VERY SEXY COIN :-)
    // Buy and get rich!

    uint256 public totalSupply = 210000000000000000000000;
    uint256 public availableSupply= 210000000000000000000000;
    uint256 public circulatingSupply = 0;  	
    uint8   public decimals = 18;
  
    string  public standard = &#39;ERC20 Token&#39;;
    string  public name = &#39;ElevenOfTwelve&#39;;
    string  public symbol = &#39;11of12&#39;;            
    uint256 public crowdsalePrice = 100;                          	
    uint256 public crowdsaleClosed = 0;                 
    address public daoMultisig = msg.sender;
    address public owner = msg.sender;  

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;	
	
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);    
    
    function transfer(address _to, uint256 _value) returns (bool success) {
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }
	
    modifier onlyOwner {
        if (msg.sender != owner) throw;
        _;
    }
	
    function transferOwnership(address newOwner) onlyOwner {
        owner = newOwner;
    }	
	
    function () payable {
        if (crowdsaleClosed > 0) throw;		
        if (msg.value == 0) {
          throw;
        }		
        if (!daoMultisig.send(msg.value)) {
          throw;
        }		
        uint token = msg.value * crowdsalePrice;		
		availableSupply = totalSupply - circulatingSupply;
        if (token > availableSupply) {
          throw;
        }		
        circulatingSupply += token;
        balances[msg.sender] += token;
    }
	
    function setPrice(uint256 newSellPrice) onlyOwner {
        crowdsalePrice = newSellPrice;
    }
	
    function stoppCrowdsale(uint256 newStoppSign) onlyOwner {
        crowdsaleClosed = newStoppSign;
    }		

    function setMultisigAddress(address newMultisig) onlyOwner {
        daoMultisig = newMultisig;
    }	
	
}