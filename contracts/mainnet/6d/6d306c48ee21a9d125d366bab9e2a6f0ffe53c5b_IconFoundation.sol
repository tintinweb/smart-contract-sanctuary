pragma solidity ^0.4.13;

// ERC20 Standard
contract ERC20Interface {

    function totalSupply() constant returns (uint256 totalSupply);

    function balanceOf(address _owner) constant returns (uint256 balance);

    function transfer(address _to, uint256 _value) returns (bool success);

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);

    function approve(address _spender, uint256 _value) returns (bool success);

    function allowance(address _owner, address _spender) constant returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

// contract
contract IconFoundation is ERC20Interface {
    string public constant symbol = "ICX";
    string public constant name = "IconFoundation";
    uint8 public constant decimals = 7;
    uint256 _totalSupply = 4002300000000000;

    address public owner;

    mapping(address => uint256) balances;

    mapping(address => mapping (address => uint256)) allowed;

    mapping (address => bool) public frozenAccount;

    modifier onlyOwner {
        require (msg.sender == owner);
        _;
    }

    event FrozenFunds(address target, bool frozen);

    // constructor
    function IconFoundation() {
        owner = msg.sender;
        balances[owner] = _totalSupply;
    }

    function totalSupply() constant returns (uint256 totalSupply) {
        totalSupply = _totalSupply;
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function transfer(address _to, uint256 _amount) returns (bool success) {
        if (balances[msg.sender] >= _amount && _amount > 0 && balances[_to] + _amount > balances[_to]) {
            balances[msg.sender] -= _amount;
            balances[_to] += _amount;
            Transfer(msg.sender, _to, _amount);
            return true;
        }
        else {
            return false;
        }
    }

    function transferFrom(address _from, address _to, uint256 _amount) returns (bool success) {
        if (balances[_from] >= _amount && allowed[_from][msg.sender] >= _amount && _amount > 0 && balances[_to] + _amount > balances[_to]) {
            balances[_from] -= _amount;
            allowed[_from][msg.sender] -= _amount;
            balances[_to] += _amount;
            Transfer(_from, _to, _amount);
            return true;
        }
        else {
            return false;
        }
    }

    function approve(address _spender, uint256 _amount) returns (bool success) {
        allowed[msg.sender][_spender] = _amount;
        Approval(msg.sender, _spender, _amount);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    function transferOwnership(address newOwner) onlyOwner {
        owner = newOwner;
    }

    function freezeAccount(address target, bool freeze) onlyOwner {
        require (target != owner);
        frozenAccount[target] = freeze;
        FrozenFunds(target, freeze);
    }

}