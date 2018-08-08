pragma solidity ^0.4.14;

contract ValueToken {
    string public symbol;
    string public name;
    uint8 public decimals;
    uint256 _totalSupply;
    uint256 _value;

    // Owner of this contract
    address public owner;
    address public centralBank;

    // Balances for each account
    mapping(address => uint256) balances;

    // Owner of account approves the transfer of an amount to another account
    mapping(address => mapping (address => uint256)) allowed;

    // Constructor
    function ValueToken() {
        name = "Cyber Turtle Token";
        symbol = "CTT";
        decimals = 2;
        _totalSupply = 164500;
        _value = 1118;
        centralBank = 0x77E370640B43a8A8Bf68C21fD068E312c89321eE;
        owner = msg.sender;
        balances[owner] = _totalSupply;
    }

    function totalSupply() constant returns (uint256 supply) {
        return _totalSupply;
    }

    function value() constant returns (uint256 returnValue) {
        return _value;
    }

    // What is the balance of a particular account?
    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    // Transfer the balance from owner&#39;s account to another account
    function transfer(address _to, uint256 _amount) returns (bool success) {
        if (balances[msg.sender] >= _amount
            && _amount > 0
            && balances[_to] + _amount > balances[_to]) {
            balances[msg.sender] -= _amount;
            balances[_to] += _amount;
            Transfer(msg.sender, _to, _amount);
            return true;
        } else {
            return false;
        }
    }

    // Send _value amount of tokens from address _from to address _to
    // The transferFrom method is used for a withdraw workflow, allowing contracts to send
    // tokens on your behalf, for example to "deposit" to a contract address and/or to charge
    // fees in sub-currencies; the command should fail unless the _from account has
    // deliberately authorized the sender of the message via some mechanism; we propose
    // these standardized APIs for approval:
    function transferFrom(
        address _from,
        address _to,
        uint256 _amount
    ) returns (bool success) {
        if (balances[_from] >= _amount
            && allowed[_from][msg.sender] >= _amount
            && _amount > 0
            && balances[_to] + _amount > balances[_to]) {
            balances[_from] -= _amount;
            allowed[_from][msg.sender] -= _amount;
            balances[_to] += _amount;
            Transfer(_from, _to, _amount);
            return true;
        } else {
            return false;
        }
    }

    // Allow _spender to withdraw from your account, multiple times, up to the _value amount.
    // If this function is called again it overwrites the current allowance with _value.
    function approve(address _spender, uint256 _amount) returns (bool success) {
        allowed[msg.sender][_spender] = _amount;
        Approval(msg.sender, _spender, _amount);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    // Ownership
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) onlyOwner {
        owner = _newOwner;
    }

    function transferCentralBanking(address _newCentralBank) onlyOwner {
        centralBank = _newCentralBank;
    }

    // Central bank functions
    modifier onlyCentralBank {
        require(msg.sender == centralBank);
        _;
    }

    function mint(uint256 _amount) onlyCentralBank {
        balances[owner] += _amount;
        _totalSupply += _amount;
        Transfer(0, this, _amount);
        Transfer(this, owner, _amount);
    }

    function burn(uint256 _amount) onlyCentralBank {
        require (balances[owner] >= _amount);
        balances[owner] -= _amount;
        _totalSupply -= _amount;
        Transfer(owner, this, _amount);
        Transfer(this, 0, _amount);
    }

    function updateValue(uint256 _newValue) onlyCentralBank {
        require(_newValue >= 0);
        _value = _newValue;
    }

    function updateValueAndMint(uint256 _newValue, uint256 _toMint) onlyCentralBank {
        require(_newValue >= 0);
        _value = _newValue;
        mint(_toMint);
    }

    function updateValueAndBurn(uint256 _newValue, uint256 _toBurn) onlyCentralBank {
        require(_newValue >= 0);
        _value = _newValue;
        burn(_toBurn);
    }

    // Events
    event Transfer(address indexed _from, address indexed _to, uint256 _amount);
    event Approval(address indexed _owner, address indexed _spender, uint256 _amount);
}