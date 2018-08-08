pragma solidity ^0.4.13;

contract SafeMath {
    function safeAdd(uint256 x, uint256 y) internal returns(uint256) {
      uint256 z = x + y;
      assert((z >= x) && (z >= y));
      return z;
    }

    function safeSubtrCPCE(uint256 x, uint256 y) internal returns(uint256) {
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

contract CPCE is StandardToken, SafeMath {

    string public constant name = "CPC";
    string public constant symbol = "CPC";
    uint256 public constant decimals = 18;
    string public version = "1.0";

    address public CPCEPrivateDeposit;
    address public CPCEIcoDeposit;
    address public CPCEFundDeposit;

    uint256 public constant factorial = 6;
    uint256 public constant CPCEPrivate = 150 * (10**factorial) * 10**decimals; //150m私募代币数量，共计1.5亿代币
    uint256 public constant CPCEIco = 150 * (10**factorial) * 10**decimals; //150m的ico代币数量，共计1.5亿代币
    uint256 public constant CPCEFund = 380 * (10**factorial) * 10**decimals; //380m的ico代币数量，共计3.8亿代币
  

    // constructor
    function CPCE()
    {
      CPCEPrivateDeposit = 0x335B73c9054eBa7652484B5dA36dB45dB92de4c3;
      CPCEIcoDeposit = 0x84d9E8671DaF07CEb5fa35137636B93dc395f118;
      CPCEFundDeposit = 0xd7BAD068E961cCBe95e318c7aC118833A613c762;

      balances[CPCEPrivateDeposit] = CPCEPrivate;
      balances[CPCEIcoDeposit] = CPCEIco;
      balances[CPCEFundDeposit] = CPCEFund;
    }
}