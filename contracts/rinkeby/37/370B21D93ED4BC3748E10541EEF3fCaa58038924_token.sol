// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 < 0.8.0;
// import * as SafeMath from './Safe_Math.sol';
import "./Safe_Math.sol";

contract token {
  using SafeMath for uint256;

  string public constant name = "NTOKEN";
  string public constant symbol = "NTK";
  uint8 public constant decimals = 18; 

  mapping(address => uint256) balances;
  mapping(address => mapping (address => uint256)) allowed;

  event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
  event Transfer(address indexed from, address indexed to, uint tokens);

  uint256 totalSupply_;

  constructor() {
    totalSupply_ = 10**36;
    balances[msg.sender] = totalSupply_;
  } 

  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  function balanceOf(address tokenOwner) public view returns (uint) {
    return balances[tokenOwner];
  }

  function transfer(address receiver, uint256 numTokens) public returns (bool) {
    require(numTokens <= balances[msg.sender]);
    balances[msg.sender] = balances[msg.sender].sub(numTokens);
    balances[receiver] = balances[receiver].add(numTokens);
    emit Transfer(msg.sender, receiver, numTokens);
    return true;
  }

  function approve(address delegate, uint256 numTokens) public returns (bool) {
    allowed[msg.sender][delegate] = numTokens;
    emit Approval(msg.sender, delegate, numTokens);
    return true;
  }

  function allowance(address owner, address delegate) public view returns (uint) {
    return allowed[owner][delegate];
  }

  function transferFrom(address owner, address buyer, uint256 numTokens) public returns (bool) {
    require(numTokens <= balances[owner]);
    require(numTokens <= allowed[owner][msg.sender]);
    balances[owner] = balances[owner].sub(numTokens);
    allowed[owner][msg.sender] = allowed[owner][msg.sender].sub(numTokens);
    balances[buyer] = balances[buyer].add(numTokens);
    emit Transfer(owner, buyer, numTokens);
    return true;
  }
}