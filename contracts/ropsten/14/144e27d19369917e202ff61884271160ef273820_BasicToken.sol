pragma solidity^0.4.24;
library SafeMath {
  function mul(uint a, uint b) internal returns (uint) {uint c = a * b;
    assert(a == 0 || c / a == b);   return c; }
  function div(uint a, uint b) internal returns (uint) {
   // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint c = a / b; // assert(a == b * c + a % b);
    // There is no case in which this doesn&#39;t hold
    return c;  }
  function sub(uint a, uint b) internal returns (uint) {
    assert(b <= a);
    return a - b; }
  function add(uint a, uint b) internal returns (uint) {
    uint c = a + b;
    assert(c >= a);
    return c; }
  function max64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a >= b ? a : b;  }
  function min64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a < b ? a : b;  }
  function max256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a >= b ? a : b;  }
  function min256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a < b ? a : b;  }
  function assert(bool assertion) internal {if (!assertion) {throw;} } }
contract ERC20Basic {
  uint public totalSupply;
  function balanceOf(address who)public constant returns (uint);
  function transfer(address to, uint value) ;
  event Transfer(address indexed from, address indexed to, uint value);
 string  public constant name = &quot;Reward Point Tokens&quot;;
 string public constant symbol = &quot;RPT&quot;;
 string public constant decimals = &quot;0&quot;;}
contract BasicToken is ERC20Basic {
  using SafeMath for uint;
  mapping(address => uint) balances;
  modifier onlyPayloadSize(uint size) {
     if(msg.data.length < size + 4) {throw;} _; }
  function transfer(address _to, uint _value) onlyPayloadSize(2 * 32) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value); }
  function balanceOf(address _owner) constant returns (uint balance) {
    return balances[_owner]; }}
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint);
  function transferFrom(address from, address to, uint value);
  function approve(address spender, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);}
contract StandardToken is BasicToken, ERC20 {
  mapping (address => mapping (address => uint)) allowed;
  function transferFrom(address _from, address _to, uint _value) onlyPayloadSize(3 * 32) {
    var _allowance = allowed[_from][msg.sender];
    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);}
  function approve(address _spender, uint _value) {
    if ((_value != 0) && (allowed[msg.sender][_spender] != 0)) throw;
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);}
  function allowance(address _owner, address _spender) constant returns (uint remaining) {
    return allowed[_owner][_spender];}}
contract ownable{address public owner;
   constructor () {owner = msg.sender;}
  modifier onlyOwner() {if (msg.sender != owner) {throw;}_;}
  function transferOwnership(address newOwner) onlyOwner 
  {if (newOwner != address(0)) {owner = newOwner;}}}
  contract MintableToken is StandardToken{
  event Mint(address indexed to, uint value);
  event MintFinished();
  bool public mintingFinished = false;
  uint public totalSupply = 0;
  modifier canMint() {
    if(mintingFinished) throw; _; }
  function mint(address _to, uint _amount)  canMint returns (bool) {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    return true; } 
  function finishMinting()  returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
}
contract Sender {
  function send(address _receiver) payable {
    _receiver.call.value(msg.value).gas(20317)();
  }
}
contract Receiver {
  uint public balance = 0;
  
  function () payable {
    balance += msg.value;
  }
}