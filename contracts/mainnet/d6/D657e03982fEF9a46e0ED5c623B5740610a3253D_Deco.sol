pragma solidity ^0.4.13;

library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a / b;
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract ERC223ReceivingContract {
    function tokenFallback(address _from, uint256 _value, bytes _data) public;
}

contract ERC20ERC223 {
  uint256 public totalSupply;
  function balanceOf(address _owner) public constant returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  function transfer(address _to, uint256 _value, bytes _data) public returns (bool);
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool);
  function approve(address _spender, uint256 _value) public returns (bool success);
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining);
  
  event Transfer(address indexed _from, address indexed _to, uint256 indexed _value);
  event Transfer(address indexed _from, address indexed _to, uint256 indexed _value, bytes _data);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract Deco is ERC20ERC223 {

  using SafeMath for uint256;

  string public constant name = "Deco";
  string public constant symbol = "DEC";
  uint8 public constant decimals = 18;
  
  uint256 public constant totalSupply = 6*10**26; // 600,000,000. 000,000,000,000,000,000 units
    
  // Accounts
  
  mapping(address => Account) private accounts;
  
  struct Account {
    uint256 balance;
    mapping(address => uint256) allowed;
    mapping(address => bool) isAllowanceAuthorized;
  }  
  
  // Fix for the ERC20 short address attack.
  // http://vessenes.com/the-erc20-short-address-attack-explained/
  modifier onlyPayloadSize(uint256 size) {
    require(msg.data.length >= size + 4);
     _;
  }

  // Initialization

  function Deco() {
    accounts[msg.sender].balance = totalSupply;
    Transfer(this, msg.sender, totalSupply);
  }

  // Balance

  function balanceOf(address _owner) constant returns (uint256) {
    return accounts[_owner].balance;
  }

  // Transfers

  function transfer(address _to, uint256 _value) onlyPayloadSize(2 * 32) returns (bool) {
    performTransfer(msg.sender, _to, _value, "");
    Transfer(msg.sender, _to, _value);
    return true;
  }

  function transfer(address _to, uint256 _value, bytes _data) onlyPayloadSize(2 * 32) returns (bool) {
    performTransfer(msg.sender, _to, _value, _data);
    Transfer(msg.sender, _to, _value, _data);
    return true;
  }

  function transferFrom(address _from, address _to, uint256 _value) onlyPayloadSize(3 * 32) returns (bool) {
    require(hasApproval(_from, msg.sender));
    uint256 _allowed = accounts[_from].allowed[msg.sender];    
    performTransfer(_from, _to, _value, "");    
    accounts[_from].allowed[msg.sender] = _allowed.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

  function performTransfer(address _from, address _to, uint256 _value, bytes _data) private returns (bool) {
    require(_to != 0x0);
    accounts[_from].balance = accounts[_from].balance.sub(_value);    
    accounts[_to].balance = accounts[_to].balance.add(_value);
    if (isContract(_to)) {
      ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
      receiver.tokenFallback(_from, _value, _data);
    }    
    return true;
  }

  function isContract(address _to) private constant returns (bool) {
    uint256 codeLength;
    assembly {
      codeLength := extcodesize(_to)
    }
    return codeLength > 0;
  }

  // Approval & Allowance
  
  function approve(address _spender, uint256 _value) returns (bool) {
    require(msg.sender != _spender);
    // https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    if ((_value != 0) && (accounts[msg.sender].allowed[_spender] != 0)) {
      revert();
      return false;
    }
    accounts[msg.sender].allowed[_spender] = _value;
    accounts[msg.sender].isAllowanceAuthorized[_spender] = true;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return accounts[_owner].allowed[_spender];
  }

  function hasApproval(address _owner, address _spender) constant returns (bool) {        
    return accounts[_owner].isAllowanceAuthorized[_spender];
  }

  function removeApproval(address _spender) {    
    delete(accounts[msg.sender].allowed[_spender]);
    accounts[msg.sender].isAllowanceAuthorized[_spender] = false;
  }

}