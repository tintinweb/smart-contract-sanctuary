pragma solidity ^0.4.19;

contract HCToken {
    address public owner;
    string public constant name = "Hash Credit Token";
    string public constant symbol = "HCT";
    uint256 public constant decimals = 6;
    uint256 public constant totalSupply = 15 * 100 * 1000 * 1000 * 10 ** decimals;
    
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;

    modifier onlyPayloadSize(uint size) {
        if (msg.data.length != size + 4) {
            throw;
        }
        _;
    }

    function HCToken() {
        owner = msg.sender;
        balances[owner] = totalSupply;
    }

    function transfer(address _to, uint _value) onlyPayloadSize(2 * 32) returns (bool success) {
        require(balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint _value) onlyPayloadSize(3 * 32) returns (bool success) {
        require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]);
        balances[_to] += _value;
        balances[_from] -= _value;
        allowed[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
    }
    
  
    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint _value) returns (bool success) {
        if ((_value != 0) && (allowed[msg.sender][_spender] != 0)) throw;

        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint remaining) {
        return allowed[_owner][_spender];
    }

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

}