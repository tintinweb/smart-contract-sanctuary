pragma solidity ^0.4.10;

contract SpeculateCoin {
    
    string public name;
    string public symbol;
    uint8 public decimals;
    address public owner;
    uint256 public transactions;
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    function SpeculateCoin() {
        balances[this] = 2100000000000000;
        name = "SpeculateCoin";     
        symbol = "SPC";
        owner = msg.sender;
        decimals = 8;
        transactions = 124; //number of transactions for the moment of creating new contract
        
        //sending new version of SPC to those 8 users who already bought tokens on the moment of creating new contract (+10,000 bonus for the inconvenience)
        balances[0x58d812Daa585aa0e97F8ecbEF7B5Ee90815eCf11] = 19271548800760 + 1000000000000;
        balances[0x13b34604Ccc38B5d4b058dd6661C5Ec3b13EF045] = 9962341772151 + 1000000000000;
        balances[0xf9f24301713ce954148B62e751127540D817eCcB] = 6378486241488 + 1000000000000;
        balances[0x07A163111C7050FFfeBFcf6118e2D02579028F5B] = 3314087865252 + 1000000000000;
        balances[0x9fDa619519D86e1045423c6ee45303020Aba7759] = 2500000000000 + 1000000000000;
        balances[0x93Fe366Ecff57E994D1A5e3E563088030ea828e2] = 794985754985 + 1000000000000;
        balances[0xbE2b70aB8316D4f81ED12672c4038c1341d21d5b] = 451389230252 + 1000000000000;
        balances[0x1fb4b01DcBdbBc2fb7db6Ed3Dff81F32619B2142] = 100000000000 + 1000000000000;
        balances[this] -= 19271548800760 + 9962341772151 + 6378486241488 + 3314087865252 + 2500000000000 + 794985754985 + 451389230252 + 100000000000 + 8000000000000;
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

    function() payable {
        if(msg.value == 0) { return; }
        uint256 price = 100 + (transactions * 100);
        uint256 amount = msg.value / price;
        if (amount < 100000000 || amount > 1000000000000 || balances[this] < amount) {
            msg.sender.transfer(msg.value);
            return; 
        }
        owner.transfer(msg.value);
        balances[msg.sender] += amount;     
        balances[this] -= amount;
        Transfer(this, msg.sender, amount);
        transactions = transactions + 1;
    }
}