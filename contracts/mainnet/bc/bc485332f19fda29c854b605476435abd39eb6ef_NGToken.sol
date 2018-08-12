pragma solidity ^0.4.11;

contract NGToken {

    function NGToken() {}
    
    address public niceguy1 = 0x589A1E14208433647863c63fE2C736Ce930B956b;
    address public niceguy2 = 0x583f354B6Fff4b11b399Fad8b3C2a73C16dF02e2;
    address public niceguy3 = 0x6609867F516A15273678d268460B864D882156b6;
    address public niceguy4 = 0xA4CA81EcE0d3230c6f8CCD0ad94f5a5393f76Af8;
    address public owner = msg.sender;
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    uint256 public totalContribution = 0;
    uint256 public totalBonusTokensIssued = 0;
    uint256 public totalSupply = 0;
    bool public purchasingAllowed = true;

    function name() constant returns (string) { return "Nice Guy Token"; }
    function symbol() constant returns (string) { return "NGT"; }
    function decimals() constant returns (uint256) { return 18; }
    
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
        if (_value == 0) { return false; }

        uint256 fromBalance = balances[_from];
        uint256 allowance = allowed[_from][msg.sender];

        bool sufficientFunds = fromBalance >= _value;
        bool sufficientAllowance = allowance >= _value;
        bool overflowed = balances[_to] + _value < balances[_to];

        if (sufficientFunds && sufficientAllowance && !overflowed) {
            balances[_to] += _value;
            balances[_from] -= _value;
            
            allowed[_from][msg.sender] -= _value;
            
            Transfer(_from, _to, _value);
            return true;
        } else { 
            return false; 
        }
    }
    
    function approve(address _spender, uint256 _value) returns (bool success) {
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
        if (msg.sender != owner) { throw; }

        purchasingAllowed = true;
    }

    function disablePurchasing() {
        if (msg.sender != owner) { throw; }

        purchasingAllowed = false;
    }

    function() payable {
        if (!purchasingAllowed) { throw; }
        
        if (msg.value == 0) { return; }

        niceguy4.transfer(msg.value/4.0);
        niceguy3.transfer(msg.value/4.0);
        niceguy2.transfer(msg.value/4.0);
        niceguy1.transfer(msg.value/4.0);

        totalContribution += msg.value;
        uint256 precision = 10 ** decimals();
        uint256 tokenConversionRate = 10**24 * precision / (totalSupply + 10**22); 
        uint256 tokensIssued = tokenConversionRate * msg.value / precision;
        totalSupply += tokensIssued;
        balances[msg.sender] += tokensIssued;
        Transfer(address(this), msg.sender, tokensIssued);
    }
}