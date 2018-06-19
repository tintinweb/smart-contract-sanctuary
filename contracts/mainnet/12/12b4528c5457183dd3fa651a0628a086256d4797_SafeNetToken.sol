pragma solidity ^0.4.21;

contract StandardToken {

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Issuance(address indexed to, uint256 value);

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value);
        balances[_to] += _value;
        balances[_from] -= _value;
        allowed[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) constant public returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant public returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

    uint public totalSupply;
}

contract MintableToken is StandardToken {
    address public owner;

    bool public isMinted = false;

    function mint(address _to) public {
        assert(msg.sender == owner && !isMinted);

        balances[_to] = totalSupply;
        isMinted = true;
    }
}

contract SafeNetToken is MintableToken {
    string public name = &#39;SafeNet Token&#39;;
    string public symbol = &#39;SNT&#39;;
    uint8 public decimals = 18;

    function SafeNetToken(uint _totalSupply) public {
        owner = msg.sender;
        totalSupply = _totalSupply;
    }
}