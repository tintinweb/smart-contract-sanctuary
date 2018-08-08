pragma solidity ^0.4.18;
library SafeMath {
  function times(uint a, uint b) public pure returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function minus(uint a, uint b) public pure returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function plus(uint a, uint b) public pure returns (uint) {
    uint c = a + b;
    assert(c>=a && c>=b);
    return c;
  }

}


contract JOICoin {
    using SafeMath for uint;

    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowed;
    uint256 public totalSupply;
    string public constant name = "JOI Coin";
    string public constant symbol = "JOI";
    uint256 public constant decimals = 18;  // decimal places
    address public master;

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);

    constructor(uint _initialSupply, address _master) public {
        totalSupply = _initialSupply;
        master = _master;
        balances[master] = _initialSupply;
    }

    function () public {
        require(false);
    }

    // solhint-disable-next-line no-simple-event-func-name
    function transfer(address _to, uint _value) public returns (bool success) {
        balances[msg.sender] = balances[msg.sender].minus(_value);
        balances[_to] = balances[_to].plus(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint _value) public returns (bool success) {
        uint _allowance = allowed[_from][msg.sender];

        balances[_to] = balances[_to].plus(_value);
        balances[_from] = balances[_from].minus(_value);
        allowed[_from][msg.sender] = _allowance.minus(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) public constant returns (uint balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public constant returns (uint remaining) {
        return allowed[_owner][_spender];
    }
}