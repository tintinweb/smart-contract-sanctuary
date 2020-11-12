pragma solidity ^0.4.26;

library SafeMath {
  function safeMul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b > 0);
    uint256 c = a / b;
    assert(a == b * c + a % b);
    return c;
  }

  function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c>=a && c>=b);
    return c;
  }
}

contract Token {

    uint256 public totalSupply;

    function balanceOf(address _owner) view public returns (uint256 balance);

    function transfer(address _to, uint256 _value) public returns (bool success);

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

    function approve(address _spender, uint256 _value) public returns (bool success);

    function allowance(address _owner, address _spender) view public returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract StandardToken is Token {

    mapping (address => uint256) public _balances;
    mapping (address => mapping (address => uint256)) public _allowed;

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(_to != address(0));
        require(_value <= _balances[msg.sender]);
        require(_balances[_to] + _value > _balances[_to]);
        _balances[msg.sender] = SafeMath.safeSub(_balances[msg.sender], _value);
        _balances[_to] = SafeMath.safeAdd(_balances[_to], _value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_to != address(0));
        require(_value <= _balances[_from]);
        require(_value <= _allowed[_from][msg.sender]);
        require(_balances[_to] + _value > _balances[_to]);
        _balances[_to] = SafeMath.safeAdd(_balances[_to], _value);
        _balances[_from] = SafeMath.safeSub(_balances[_from], _value);
        _allowed[_from][msg.sender] = SafeMath.safeSub(_allowed[_from][msg.sender], _value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) view public returns (uint256 balance) {
        return _balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        require((_value == 0) || (_allowed[msg.sender][_spender] == 0));
        _allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) view public returns (uint256 remaining) {
        return _allowed[_owner][_spender];
    }
}

contract TokenERC20 is StandardToken {
    function () public payable {
        revert();
    }

    string public name = "LAS";
    uint8 public decimals = 18;
    string public symbol = "LAS";
    uint256 public totalSupply = 69000000*10**18;

    constructor() public {
        _balances[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }
}