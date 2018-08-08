pragma solidity ^0.4.8;

contract ERC20Interface {
    function totalSupply() public constant returns (uint256 supply);
    function balance() public constant returns (uint256);
    function balanceOf(address _owner) public constant returns (uint256);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract TokenFactoryAirdrop is ERC20Interface {
    string public constant symbol = "TFA";
    string public constant name = "TokenFactoryAirdrop";
    uint8 public constant decimals = 2;

    uint256 _totalSupply = 0;
    uint256 _airdropAmount = 28880000;
    uint256 _cutoff = _airdropAmount * 20000;

    mapping(address => uint256) balances;
    mapping(address => bool) initialized;

    // Owner of account approves the transfer of an amount to another account
    mapping(address => mapping (address => uint256)) allowed;

    function TokenFactoryAirdrop() {
        initialized[msg.sender] = true;
        balances[msg.sender] = _airdropAmount * 10000;
        _totalSupply = balances[msg.sender];
    }

    function totalSupply() constant returns (uint256 supply) {
        return _totalSupply;
    }

    // What&#39;s my balance?
    function balance() constant returns (uint256) {
        return getBalance(msg.sender);
    }

    // What is the balance of a particular account?
    function balanceOf(address _address) constant returns (uint256) {
        return getBalance(_address);
    }

    // Transfer the balance from owner&#39;s account to another account
    function transfer(address _to, uint256 _amount) returns (bool success) {
        initialize(msg.sender);

        if (balances[msg.sender] >= _amount
            && _amount > 0) {
            initialize(_to);
            if (balances[_to] + _amount > balances[_to]) {

                balances[msg.sender] -= _amount;
                balances[_to] += _amount;

                Transfer(msg.sender, _to, _amount);

                return true;
            } else {
                return false;
            }
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
        initialize(_from);

        if (balances[_from] >= _amount
            && allowed[_from][msg.sender] >= _amount
            && _amount > 0) {
            initialize(_to);
            if (balances[_to] + _amount > balances[_to]) {

                balances[_from] -= _amount;
                allowed[_from][msg.sender] -= _amount;
                balances[_to] += _amount;

                Transfer(_from, _to, _amount);

                return true;
            } else {
                return false;
            }
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

    // internal private functions
    function initialize(address _address) internal returns (bool success) {
        if (_totalSupply < _cutoff && !initialized[_address]) {
            initialized[_address] = true;
            balances[_address] = _airdropAmount;
            _totalSupply += _airdropAmount;
        }
        return true;
    }

    function getBalance(address _address) internal returns (uint256) {
        if (_totalSupply < _cutoff && !initialized[_address]) {
            return balances[_address] + _airdropAmount;
        }
        else {
            return balances[_address];
        }
    }
}