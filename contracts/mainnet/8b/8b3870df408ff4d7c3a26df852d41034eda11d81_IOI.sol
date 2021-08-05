/**
 *Submitted for verification at Etherscan.io on 2021-01-05
*/

pragma solidity ^0.6.0;
 
/**
ERC20 Token
 
Symbol          : IOI
Name            : IOI Token
Total supply    : 100000000
Decimals        : 6
 
*/
 
abstract contract ERC20Interface {
  string public name;
 string public symbol;
  uint8 public decimals;
  uint256 public totalSupply;
 function balanceOf(address _owner) public view virtual returns (uint256 balance);
  function transfer(address _to, uint256 _value) public virtual returns (bool success);
  function transferFrom(address _from, address _to, uint256 _value) public virtual returns (bool success);
  function approve(address _spender, uint256 _value) public virtual returns (bool success);
 function allowance(address _owner, address _spender) public view virtual returns (uint256 remaining);
  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}
 
 
contract Owned {
 address public owner;
 address public newOwner;
 
 event OwnershipTransferred(address indexed _from, address indexed _to);
 
 constructor () public {
   owner = msg.sender;
 }
 
 modifier onlyOwner {
   require(msg.sender == owner);
   _;
 }
 
 function transferOwnership(address _newOwner) public onlyOwner {
   newOwner = _newOwner;
 }
 
 function acceptOwnership() public {
   require(msg.sender == newOwner);
   emit OwnershipTransferred(owner, newOwner);
   owner = newOwner;
   newOwner = address(0);
 }
}
 
 
abstract contract TokenRecipient {
 function receiveApproval(address _from, uint256 _value, address _token, bytes memory _extraData) public virtual;
}
 
 
contract Token is ERC20Interface, Owned {
 
 mapping (address => uint256) _balances;
 mapping (address => mapping (address => uint256)) _allowed;
 
 event Burn(address indexed from, uint256 value);
  function balanceOf(address _owner) public view override returns (uint256 balance) {
   return _balances[_owner];
 }
 
 function transfer(address _to, uint256 _value) public override returns (bool success) {
   _transfer(msg.sender, _to, _value);
   return true;
 }
 
 function transferFrom(address _from, address _to, uint256 _value) public override returns (bool success) {
   require(_value <= _allowed[_from][msg.sender]);
   _allowed[_from][msg.sender] -= _value;
   _transfer(_from, _to, _value);
   return true;
 }
 
 function approve(address _spender, uint256 _value) public override returns (bool success) {
   _allowed[msg.sender][_spender] = _value;
   emit Approval(msg.sender, _spender, _value);
   return true;
 }
 
 function allowance(address _owner, address _spender) public view override returns (uint256 remaining) {
   return _allowed[_owner][_spender];
 }
 
  function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
   return ERC20Interface(tokenAddress).transfer(owner, tokens);
 }
 
  function approveAndCall(address _spender, uint256 _value, bytes memory _extraData) public returns (bool success) {
   TokenRecipient spender = TokenRecipient(_spender);
   approve(_spender, _value);
   spender.receiveApproval(msg.sender, _value, address(this), _extraData);
   return true;
 }
 
 function burn(uint256 _value) public returns (bool success) {
   require(_balances[msg.sender] >= _value);
   _balances[msg.sender] -= _value;
   totalSupply -= _value;
   emit Burn(msg.sender, _value);
   return true;
 }
 
  function burnFrom(address _from, uint256 _value) public returns (bool success) {
   require(_balances[_from] >= _value);
   require(_value <= _allowed[_from][msg.sender]);
   _balances[_from] -= _value;
   _allowed[_from][msg.sender] -= _value;
   totalSupply -= _value;
   emit Burn(_from, _value);
   return true;
 }
 
  function _transfer(address _from, address _to, uint _value) internal {
 
   require(_to != address(0x0));
  
   require(_balances[_from] >= _value);
  
   require(_balances[_to] + _value > _balances[_to]);
  
   uint previousBalances = _balances[_from] + _balances[_to];
  
   _balances[_from] -= _value;
  
   _balances[_to] += _value;
   emit Transfer(_from, _to, _value);
 
   assert(_balances[_from] + _balances[_to] == previousBalances);
 }
 
}
 
contract IOIToken is Token {
 
 constructor(string memory _name, string memory _symbol, uint8 _decimals, uint256 _initialSupply) public {
   name = _name;
   symbol = _symbol;
   decimals = _decimals;
   totalSupply = _initialSupply * 10 ** uint256(decimals);
   _balances[msg.sender] = totalSupply;
 }
 
  fallback() external payable {
   revert();
 }
 
  receive() external payable{
   revert();
 }
 
}
 
contract IOI is IOIToken {
 
 constructor() IOIToken ("IOI Token ", "IOI", 6, 100000000) public {}
 
}