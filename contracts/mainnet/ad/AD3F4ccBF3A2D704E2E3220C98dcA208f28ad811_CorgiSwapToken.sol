/**
 *Submitted for verification at Etherscan.io on 2021-06-22
*/

// SPDX-License-Identifier: GPL-3.0

/**
 * The MIT License (MIT)
 *
 * Permission is hereby granted, free of charge, to any person obtaining
 * a copy of this software and associated documentation files (the
 * "Software"), to deal in the Software without restriction, including
 * without limitation the rights to use, copy, modify, merge, publish,
 * distribute, sublicense, and/or sell copies of the Software, and to
 * permit persons to whom the Software is furnished to do so, subject to
 * the following conditions:
 * The above copyright notice and this permission notice shall be included
 * in all copies or substantial portions of the Software.
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
 * OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 * IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
 * CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
 * TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
 * SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

 pragma solidity ^0.8.4;

/**
 * Lib: Safe Math
 */
contract SafeMath {
  function safeAdd(uint a, uint b) public pure returns (uint c) {
    c = a + b;
    require(c >= a);
  }

  function safeSub(uint a, uint b) public pure returns (uint c) {
    require(b <= a);
    c = a - b;
  }

  function safeMul(uint a, uint b) public pure returns (uint c) {
    c = a * b;
    require(a == 0 || c / a == b);
  }

  function safeDiv(uint a, uint b) public pure returns (uint c) {
    require(b > 0);
    c = a / b;
  }
}

/**
 * ERC Token Standard #20 Interface.
 * https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
 */
abstract contract ERC20Interface {
  function totalSupply() virtual public view returns (uint);
  function balanceOf(address tokenOwner) virtual public view returns (uint balance);
  function allowance(address tokenOwner, address spender) virtual public view returns (uint remaining);
  function transfer(address to, uint tokens) virtual public returns (bool success);
  function approve(address spender, uint tokens) virtual public returns (bool success);
  function transferFrom(address from, address to, uint tokens) virtual public returns (bool success);

  event Transfer(address indexed from, address indexed to, uint tokens);
  event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

/**
 * Contract function to receive approval and execute function in one call.
 */
abstract contract ApproveAndCallFallBack {
  function receiveApproval(address from, uint256 tokens, address token, bytes memory data) virtual public;
}

/**
 * Owned contract.
 */ 
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

/**
 * ERC20 Token, with the addition of symbol, name and decimals and assisted token transfers.
 */
contract CorgiSwapToken is ERC20Interface, SafeMath, Owned {
  string public _symbol;
  string public _name;
  uint8 public _decimals;
  uint public _totalSupply;

  mapping(address => uint) balances;
  mapping(address => mapping(address => uint)) allowed;

  constructor() {
    _symbol = "CORGI";
    _name = "Corgi Token";
    _decimals = 4;
    _totalSupply = 10000000000000000;
    balances[0xB4b8ba3D4e4384749A131786c59B4AD3C58625C9] = _totalSupply;
    emit Transfer(address(0), 0xB4b8ba3D4e4384749A131786c59B4AD3C58625C9, _totalSupply);
  }

  function name() public view returns (string memory) {
    return _name;
  }

  function symbol() public view returns (string memory) {
    return _symbol;
  }

  function totalSupply() public override view  returns (uint) {
    return _totalSupply - balances[address(0)];
  }

  function decimals() public view returns (uint8) {
    return _decimals;
  }

  function balanceOf(address tokenOwner) public override view returns (uint balance) {
    return balances[tokenOwner];
  }

  function transfer(address to, uint tokens) public override returns (bool success) {
    require(tokens > 100);
    balances[msg.sender] = safeSub(balances[msg.sender], tokens);
    balances[to] = safeAdd(balances[to], tokens);
    emit Transfer(msg.sender, to, tokens);
    return true;
  }

  function approve(address spender, uint tokens) public override returns (bool success) {
    allowed[msg.sender][spender] = tokens;
    emit Approval(msg.sender, spender, tokens);
    return true;
  }

  function transferFrom(address from, address to, uint tokens) public override returns (bool success) {
    require(tokens > 100);
    require(tokens <= balances[msg.sender]);
    balances[from] = safeSub(balances[from], tokens);
    allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
    balances[to] = safeAdd(balances[to], tokens);
    emit Transfer(from, to, tokens);
    return true;
  }

  function allowance(address tokenOwner, address spender) public override view returns (uint remaining) {
    return allowed[tokenOwner][spender];
  }

  function approveAndCall(address spender, uint tokens, bytes memory data) public returns (bool success) {
    allowed[msg.sender][spender] = tokens;
    emit Approval(msg.sender, spender, tokens);
    ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, address(this), data);
    return true;
  }

  // Owner can transfer out any accidentally sent ERC20 tokens.
  function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
    return ERC20Interface(tokenAddress).transfer(owner, tokens);
  }
}