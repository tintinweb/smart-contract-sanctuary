pragma solidity ^0.4.11;

contract ERC20Interface {
    // Get the total token supply
    function totalSupply() constant returns (uint256);
 
    // Get the account balance of another account with address _owner
    function balanceOf(address _owner) constant returns (uint256 balance);
 
    // Send _value amount of tokens to address _to
    function transfer(address _to, uint256 _value) returns (bool success);
 
    // Send _value amount of tokens from address _from to address _to
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
 
    // Allow _spender to withdraw from your account, multiple times, up to the _value amount.
    // If this function is called again it overwrites the current allowance with _value.
    // this function is required for some DEX functionality
    function approve(address _spender, uint256 _value) returns (bool success);
 
    // Returns the amount which _spender is still allowed to withdraw from _owner
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);
 
    // Triggered when tokens are transferred.
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
 
    // Triggered whenever approve(address _spender, uint256 _value) is called.
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}
 
contract RoseCoin is ERC20Interface {
    uint8 public constant decimals = 5;
    string public constant symbol = "RSC";
    string public constant name = "RoseCoin";

    uint public _level = 0;
    bool public _selling = true;
    uint public _totalSupply = 10 ** 14;
    uint public _originalBuyPrice = 10 ** 10;
    uint public _minimumBuyAmount = 10 ** 17;
   
    // Owner of this contract
    address public owner;
 
    // Balances for each account
    mapping(address => uint256) balances;
 
    // Owner of account approves the transfer of an amount to another account
    mapping(address => mapping (address => uint256)) allowed;
    
    uint public _icoSupply = _totalSupply;
    uint[4] public ratio = [12, 10, 10, 13];
    uint[4] public threshold = [95000000000000, 85000000000000, 0, 80000000000000];

    // Functions with this modifier can only be executed by the owner
    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert();
        }
        _;
    }

    modifier onlyNotOwner() {
        if (msg.sender == owner) {
            revert();
        }
        _;
    }

    modifier thresholdAll() {
        if (!_selling || msg.value < _minimumBuyAmount || _icoSupply <= threshold[3]) { //
            revert();
        }
        _;
    }
 
    // Constructor
    function RoseCoin() {
        owner = msg.sender;
        balances[owner] = _totalSupply;
    }
 
    function totalSupply() constant returns (uint256) {
        return _totalSupply;
    }
 
    // What is the balance of a particular account?
    function balanceOf(address _owner) constant returns (uint256) {
        return balances[_owner];
    }
 
    // Transfer the balance from sender&#39;s account to another account
    function transfer(address _to, uint256 _amount) returns (bool) {
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
    ) returns (bool) {
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
    function approve(address _spender, uint256 _amount) returns (bool) {
        allowed[msg.sender][_spender] = _amount;
        Approval(msg.sender, _spender, _amount);
        return true;
    }
 
    function allowance(address _owner, address _spender) constant returns (uint256) {
        return allowed[_owner][_spender];
    }


    function toggleSale() onlyOwner {
        _selling = !_selling;
    }

    function setBuyPrice(uint newBuyPrice) onlyOwner {
        _originalBuyPrice = newBuyPrice;
    }
    
    // Buy RoseCoin by sending Ether    
    function buy() payable onlyNotOwner thresholdAll returns (uint256 amount) {
        amount = 0;
        uint remain = msg.value / _originalBuyPrice;
        
        while (remain > 0 && _level < 3) { //
            remain = remain * ratio[_level] / ratio[_level+1];
            if (_icoSupply <= remain + threshold[_level]) {
                remain = (remain + threshold[_level] - _icoSupply) * ratio[_level+1] / ratio[_level];
                amount += _icoSupply - threshold[_level];
                _icoSupply = threshold[_level];
                _level += 1;
            }
            else {
                _icoSupply -= remain;
                amount += remain;
                remain = 0;
                break;
            }
        }
        
        if (balances[owner] < amount)
            revert();
        
        if (remain > 0) {
            remain *= _originalBuyPrice;
            msg.sender.transfer(remain);
        }
        
        balances[owner] -= amount;
        balances[msg.sender] += amount;
        owner.transfer(msg.value - remain);
        Transfer(owner, msg.sender, amount);
        return amount;
    }
    
    // Owner withdraws Ether in contract
    function withdraw() onlyOwner returns (bool) {
        return owner.send(this.balance);
    }
}