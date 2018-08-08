pragma solidity ^0.4.8;

// Confirms to ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/issues/20
// Created for demonstration purposes, but... who knows!?
// Brian Fioca 6/23/17
contract Fiocoin {
    string public constant symbol = "FIOCOIN";
    string public constant name = "Fiocoin";
    uint8 public constant decimals = 0;
    uint256 _totalSupply = 514; // starting supply

    // Owner of this contract
    address public owner;

    // Balances for each account
    mapping(address => uint256) balances;

    // Owner of account approves the transfer of an amount to another account
    mapping(address => mapping (address => uint256)) allowed;

    // Enables the owner to freeze or unfreeze assets
    mapping (address => bool) public frozenAccount;

    // Triggered when tokens are transferred
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    // Triggered whenever approve(address _spender, uint256 _value) is called
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    // Used to freeze funds of an account
    event FrozenFunds(address target, bool frozen);

    // ============================
    // Ownership-related functions
    // ============================
    // Functions with this modifier can only be executed by the owner
    modifier onlyOwner() {
        if (msg.sender != owner) {
            throw;
        }
        _;
    }

    function owned() {
        owner = msg.sender;
    }

    function transferOwnership(address newOwner) onlyOwner {
        owner = newOwner;
    }
    // ============================


    // Constructor
    function Fiocoin() {
        owner = msg.sender;
        balances[owner] = _totalSupply;
    }

    // What is the current totalSupply?
    function totalSupply() constant returns (uint256 totalSupply) {
        return _totalSupply;
    }

    // What is the balance of a particular account?
    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    // Transfer the balance from owner&#39;s account to another account
    function transfer(address _to, uint256 _amount) returns (bool success) {
        if (frozenAccount[msg.sender]) throw;
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
    function transferFrom(address _from, address _to, uint256 _amount) returns (bool success) {
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

    // Fetch the current allowance of a spender
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    // allows owner to add tokens to the total supply
    function mintToken(address target, uint256 mintedAmount) onlyOwner {
        balances[target] += mintedAmount;
        _totalSupply += mintedAmount;
        Transfer(0, owner, mintedAmount);
        Transfer(owner, target, mintedAmount);
    }
}