pragma solidity ^0.4.19;


library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
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
}

contract ForeignToken {
    function balanceOf(address _owner) constant returns (uint256);
    function transfer(address _to, uint256 _value) returns (bool);
}

contract Libra_ZodiacToken {
    address owner = msg.sender;

    bool public purchasingAllowed = true;

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

    uint256 public totalContribution = 0;
    uint256 public totalBonusTokensIssued = 0;
    uint    public MINfinney    = 0;
    uint    public AIRDROPBounce    = 50000000;
    uint    public ICORatio     = 144000;
    uint256 public totalSupply = 0;

    function name() constant returns (string) { return "Libra_ZodiacToken"; }
    function symbol() constant returns (string) { return "LIB♎"; }
    function decimals() constant returns (uint8) { return 8; }
    event Burnt(
        address indexed _receiver,
        uint indexed _num,
        uint indexed _total_supply
    );
 
 
 
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
       assert(b <= a);
       return a - b;
    }

    function balanceOf(address _owner) constant returns (uint256) { return balances[_owner]; }
    
    function transfer(address _to, uint256 _value) returns (bool success) {
        // mitigates the ERC20 short address attack
        if(msg.data.length < (2 * 32) + 4) { throw; }

        if (_value == 0) { return false; }

        uint256 fromBalance = balances[msg.sender];

        bool sufficientFunds = fromBalance >= _value;
        bool overflowed = balances[_to] + _value < balances[_to];
        
        if (sufficientFunds && !overflowed) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            
            Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }
    
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        // mitigates the ERC20 short address attack
        if(msg.data.length < (3 * 32) + 4) { throw; }

        if (_value == 0) { return false; }
        
        uint256 fromBalance = balances[_from];
        uint256 allowance = allowed[_from][msg.sender];

        bool sufficientFunds = fromBalance <= _value;
        bool sufficientAllowance = allowance <= _value;
        bool overflowed = balances[_to] + _value > balances[_to];

        if (sufficientFunds && sufficientAllowance && !overflowed) {
            balances[_to] += _value;
            balances[_from] -= _value;
            
            allowed[_from][msg.sender] -= _value;
            
            Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }
    
    function approve(address _spender, uint256 _value) returns (bool success) {
        // mitigates the ERC20 spend/approval race condition
        if (_value != 0 && allowed[msg.sender][_spender] != 0) { return false; }
        
        allowed[msg.sender][_spender] = _value;
        
        Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function allowance(address _owner, address _spender) constant returns (uint256) {
        return allowed[_owner][_spender];
    }

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Burn(address indexed burner, uint256 value);

	
    function enablePurchasing() {
        if (msg.sender != owner) { throw; }

        purchasingAllowed = true;
    }

    function disablePurchasing() {
        if (msg.sender != owner) { throw; }

        purchasingAllowed = false;
    }

    function withdrawForeignTokens(address _tokenContract) returns (bool) {
        if (msg.sender != owner) { throw; }

        ForeignToken token = ForeignToken(_tokenContract);

        uint256 amount = token.balanceOf(address(this));
        return token.transfer(owner, amount);
    }

    function getStats() constant returns (uint256, uint256, uint256, bool) {
        return (totalContribution, totalSupply, totalBonusTokensIssued, purchasingAllowed);
    }

    function setAIRDROPBounce(uint _newPrice)  {
        if (msg.sender != owner) { throw; }
        AIRDROPBounce = _newPrice;
    }

    function setICORatio(uint _newPrice)  {
        if (msg.sender != owner) { throw; }
        ICORatio = _newPrice;
    }

    function setMINfinney(uint _newPrice)  {
        if (msg.sender != owner) { throw; }
        MINfinney = _newPrice;
    }
 

    function() payable {
        if (!purchasingAllowed) { throw; }
        
        if (msg.value < 1 finney * MINfinney) { return; }

        owner.transfer(msg.value);
        totalContribution += msg.value;

        uint256 tokensIssued = (msg.value / 1e10) * ICORatio + AIRDROPBounce * 1e8;


        totalSupply += tokensIssued;
        balances[msg.sender] += tokensIssued;
        
        Transfer(address(this), msg.sender, tokensIssued);
    }

    function withdraw() public {
        uint256 etherBalance = this.balance;
        owner.transfer(etherBalance);
    }

    function burn(uint num) public {
        require(num * 1e8 > 0);
        require(balances[msg.sender] >= num * 1e8);
        require(totalSupply >= num * 1e8);

        uint pre_balance = balances[msg.sender];

        balances[msg.sender] -= num * 1e8;
        totalSupply -= num * 1e8;
        Burnt(msg.sender, num * 1e8, totalSupply);
        Transfer(msg.sender, 0x0, num * 1e8);

        assert(balances[msg.sender] == pre_balance - num * 1e8);
    }

    
}