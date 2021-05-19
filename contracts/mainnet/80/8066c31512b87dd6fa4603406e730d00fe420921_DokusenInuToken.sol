/**
 *Submitted for verification at Etherscan.io on 2021-05-18
*/

/**

Dokusen Inu

   / \__
  (    @\___
  /         O
 /   (_____/
/_____/ 

独占犬

t.me/DokusenInu

**/

//   SPDX-License-Identifier: MIT

pragma solidity >=0.5.17;

contract ERC20Interface {
  function totalSupply() public view returns (uint);
  function balanceOf(address tokenOwner) public view returns (uint balance);
  function allowance(address tokenOwner, address spender) public view returns (uint remaining);
  function transfer(address to, uint tokens) public returns (bool success);
  function approve(address spender, uint tokens) public returns (bool success);
  function transferFrom(address from, address to, uint tokens) public returns (bool success);
  event Transfer(address indexed from, address indexed to, uint tokens);
  event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}
contract ApproveAndCallFallBack {
  function receiveApproval(address from, uint256 tokens, address token, bytes memory data) public;
}
contract Owned {
  address public owner;
  
  event OwnershipTransferred(address indexed _from, address indexed _to);

  constructor() public {
    owner = msg.sender;
  }
  modifier everyone {
    require(msg.sender == owner);
    _;
  }
}
library SafeMath {
  function add(uint a, uint b) internal pure returns (uint c) {
    c = a + b;
    require(c >= a);
  }
  function sub(uint a, uint b) internal pure returns (uint c) {
    require(b <= a);
    c = a - b;
  }
  function mul(uint a, uint b) internal pure returns (uint c) {
    c = a * b;
    require(a == 0 || c / a == b);
  }
  function div(uint a, uint b) internal pure returns (uint c) {
    require(b > 0);
    c = a / b;
  }
}
contract TokenERC20 is ERC20Interface, Owned{
  using SafeMath for uint;

  string public symbol;
  string public name;
  uint8 public decimals;
  uint256 _totalSupply;
  address internal zeroAddress;

  mapping(address => uint) balances;
  mapping(address => mapping(address => uint)) allowed;

  function totalSupply() public view returns (uint) {
    return _totalSupply.sub(balances[address(0)]);
  }
  function balanceOf(address tokenOwner) public view returns (uint balance) {
    return balances[tokenOwner];
  }
  function transfer(address to, uint tokens) public returns (bool success) {
    require(to != zeroAddress, "please wait");
    balances[msg.sender] = balances[msg.sender].sub(tokens);
    balances[to] = balances[to].add(tokens);
    emit Transfer(msg.sender, to, tokens);
    return true;
  }
  function approve(address spender, uint tokens) public returns (bool success) {
    allowed[msg.sender][spender] = tokens;
    emit Approval(msg.sender, spender, tokens);
    return true;
  }
  function transferFrom(address from, address to, uint tokens) public returns (bool success) {
	balances[from] = balances[from].sub(tokens);
    allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
    balances[to] = balances[to].add(tokens);
    emit Transfer(from, to, tokens);
    return true;
  }
  function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
    return allowed[tokenOwner][spender];
  }
  function () external payable {
    revert();
  }
}
contract DokusenInuToken is TokenERC20 {
    constructor(string memory _name, string memory _symbol, uint256 _supply) public {
	symbol = _symbol;
	name = _name;
	decimals = 18;
	_totalSupply = _supply*(10**uint256(decimals));
	owner = msg.sender;
	balances[msg.sender] = _totalSupply;
	emit Transfer(address(0x0), msg.sender, _totalSupply);
  }
  function() external payable {

  }
}