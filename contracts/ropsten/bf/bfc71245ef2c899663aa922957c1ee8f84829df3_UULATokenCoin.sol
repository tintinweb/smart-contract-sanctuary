pragma solidity ^0.4.13;

contract Ownable {
    address public owner;
    function Ownable() public {
        owner = msg.sender;
    }
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}

contract UULATokenCoin is Ownable {
    string public constant name = "Uulala";
    string public constant symbol = "UULA";
    uint32 public constant decimals = 4;
    uint public constant INITIAL_SUPPLY = 7500000000000;
    uint public totalSupply = 0;
    mapping (address => uint) balances;
    mapping (address => mapping(address => uint)) allowed;

    function UULATokenCoin () public {
        totalSupply = INITIAL_SUPPLY;
        balances[msg.sender] = INITIAL_SUPPLY;
    }

    function balanceOf(address _owner) public constant returns (uint balance) {
        return balances[_owner];
    }

    function transfer(address _to, uint _value) public returns (bool success) {
        if (balances[msg.sender] < _value || balances[msg.sender] + _value < balances[msg.sender]) {
            return false;
        }

        balances[msg.sender] -= _value;
        balances[_to] += _value;
        Transfer(msg.sender, _to, _value);

        return true;
    }

    function transferFrom(address _from, address _to, uint _value) public returns (bool success) {
        if (allowed[_from][msg.sender] < _value || balances[_from] < _value && balances[_to] + _value >= balances[_to]) {
            return false;
        }

        allowed[_from][msg.sender] -= _value;
        balances[_from] -= _value;
        balances[_to] += _value;
        Transfer(_from, _to, _value);

        return true;
    }

    function approve(address _spender, uint _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);

        return true;
    }

    function allowance(address _owner, address _spender) public constant returns (uint remaining) {
        return allowed[_owner][_spender];
    }

    function drop(address[] recipients, uint256[] values) public {
        require(recipients.length == values.length);

        uint256 sum = 0;
        uint256 i = 0;

        for (i = 0; i < recipients.length; i++) {
            sum += values[i];
        }
        require(sum <= balances[msg.sender]);

        for (i = 0; i < recipients.length; i++) {
            transfer(recipients[i], values[i]);
        }
    }

    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}