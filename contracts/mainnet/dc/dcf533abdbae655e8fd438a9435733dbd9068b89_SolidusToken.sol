pragma solidity ^0.4.15;

contract SolidusToken {

    address owner = msg.sender;

    bool public purchasingAllowed = true;

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

    uint256 public totalContribution = 0;
    uint256 public totalSupply = 0;
    uint256 public totalBalancingTokens = 0;
    uint256 public tokenMultiplier = 600;

    function name() constant returns (string) { return "Solidus"; }
    function symbol() constant returns (string) { return "SOL"; }
    function decimals() constant returns (uint8) { return 18; }
    
    function balanceOf(address _owner) constant returns (uint256) { return balances[_owner]; }
    
    function transfer(address _to, uint256 _value) returns (bool success) {
        require(_to != 0x0);                               
        require(balances[msg.sender] >= _value);           
        require(balances[_to] + _value > balances[_to]); 
        balances[msg.sender] -= _value;                     
        balances[_to] += _value;                            
        Transfer(msg.sender, _to, _value);                  
        return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        require(_to != 0x0);                                
        require(balances[_from] >= _value);                 
        require(balances[_to] + _value > balances[_to]);  
        require(_value <= allowed[_from][msg.sender]);    
        balances[_from] -= _value;                        
        balances[_to] += _value;                          
        allowed[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
    }
    
    function approve(address _spender, uint256 _value) returns (bool success) {
        if (_value != 0 && allowed[msg.sender][_spender] != 0) {return false;}
        
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function allowance(address _owner, address _spender) constant returns (uint256) {
        return allowed[_owner][_spender];
    }

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    function enablePurchasing() {
        require(msg.sender == owner);
        purchasingAllowed = true;
    }

    function disablePurchasing() {
        require(msg.sender == owner);
        purchasingAllowed = false;
    }

    function getStats() constant returns (uint256, uint256, uint256, uint256, bool) {
        return (totalContribution, totalSupply, totalBalancingTokens, tokenMultiplier, purchasingAllowed);
    }

    function halfMultiplier() {
        require(msg.sender == owner);
        tokenMultiplier /= 2;
    }

    function burn(uint256 _value) returns (bool success) {
        require(msg.sender == owner);
        require(balances[msg.sender] > _value);
        balances[msg.sender] -= _value;
        totalBalancingTokens -= _value;
        totalSupply -= _value;  
        return true;
    }

    function() payable {
        require(purchasingAllowed);
        
        if (msg.value == 0) {return;}

        owner.transfer(msg.value);
        totalContribution += msg.value;

        uint256 tokensIssued = (msg.value * tokenMultiplier);
        
        totalSupply += tokensIssued*2;
        totalBalancingTokens += tokensIssued;

        balances[msg.sender] += tokensIssued;
        balances[owner] += tokensIssued;
        
        Transfer(address(this), msg.sender, tokensIssued);
    }
}