pragma solidity ^0.4.13;

contract SafeMath {
    function safeAdd(uint256 x, uint256 y) internal returns(uint256) {
      uint256 z = x + y;
      assert((z >= x) && (z >= y));
      return z;
    }

    function safeSubtract(uint256 x, uint256 y) internal returns(uint256) {
      assert(x >= y);
      uint256 z = x - y;
      return z;
    }

    function safeMult(uint256 x, uint256 y) internal returns(uint256) {
      uint256 z = x * y;
      assert((x == 0)||(z/x == y));
      return z;
    }

}

contract Token {
    uint256 public totalSupply;
    function balanceOf(address _owner) constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
    function approve(address _spender, uint256 _value) returns (bool success);
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}


/*  ERC 20 token */
contract StandardToken is Token {

    function transfer(address _to, uint256 _value) returns (bool success) {
      if (balances[msg.sender] >= _value && _value > 0) {
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        Transfer(msg.sender, _to, _value);
        return true;
      } else {
        return false;
      }
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
      if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
        balances[_to] += _value;
        balances[_from] -= _value;
        allowed[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
      } else {
        return false;
      }
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
}

contract NBAT101 is StandardToken, SafeMath {

    string public constant name = "NBAT101";
    string public constant symbol = "NBAT101";
    uint256 public constant decimals = 18;
    string public version = "1.0";

    address public GDCAcc01;
    address public GDCAcc02;
    address public GDCAcc03;
    address public GDCAcc04;
    address public GDCAcc05;

    uint256 public constant factorial = 6;
    uint256 public constant GDCNumber1 = 200 * (10**factorial) * 10**decimals; //GDCAcc1代币数量
    uint256 public constant GDCNumber2 = 200 * (10**factorial) * 10**decimals; //GDCAcc2代币数量
    uint256 public constant GDCNumber3 = 200 * (10**factorial) * 10**decimals; //GDCAcc3代币数量
    uint256 public constant GDCNumber4 = 200 * (10**factorial) * 10**decimals; //GDCAcc4代币数量
    uint256 public constant GDCNumber5 = 200 * (10**factorial) * 10**decimals; //GDCAcc5代币数量

  

    // constructor
 
    function NBAT101(
      address _GDCAcc01,
      address _GDCAcc02,
      address _GDCAcc03,
      address _GDCAcc04,
      address _GDCAcc05
    )
    {
      GDCAcc01 = _GDCAcc01;
      GDCAcc02 = _GDCAcc02;
      GDCAcc03 = _GDCAcc03;
      GDCAcc04 = _GDCAcc04;
      GDCAcc05 = _GDCAcc05;

      balances[GDCAcc01] = GDCNumber1;
      balances[GDCAcc02] = GDCNumber2;
      balances[GDCAcc03] = GDCNumber3;
      balances[GDCAcc04] = GDCNumber4;
      balances[GDCAcc05] = GDCNumber5;

    }

    function transferLock(address _to, uint256 _value, bool flag) returns (bool success) {
      if (balances[msg.sender] >= _value && _value > 0 && flag) {
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        Transfer(msg.sender, _to, _value);
        return true;
      } else {
        return false;
      }
    }
}