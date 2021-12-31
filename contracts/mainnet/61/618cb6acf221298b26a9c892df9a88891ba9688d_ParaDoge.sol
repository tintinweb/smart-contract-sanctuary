/**
 *Submitted for verification at Etherscan.io on 2021-12-31
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.6.12;

library SafeMath {
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
      uint256 c = a + b;
      require(c >= a);
      return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
      require(b <= a);
      uint256 c = a - b;
      return c;
  }

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
    return c;
  }

  function ceil(uint256 a, uint256 m) internal pure returns (uint256) {
    uint256 c = add(a,m);
    uint256 d = sub(c,1);
    return mul(div(d,m),m);
  }
}

abstract contract ERC20 {
  function totalSupply() virtual public view returns (uint256);
  function balanceOf(address holder) virtual public view returns (uint256);
  function allowance(address holder, address spender) virtual public view returns (uint256);
  function transfer(address to, uint256 amount) virtual public returns (bool success);
  function approve(address spender, uint256 amount) virtual public returns (bool success);
  function transferFrom(address from, address to, uint256 amount) virtual public returns (bool success);

  event Transfer(address indexed from, address indexed to, uint256 amount);
  event Approval(address indexed holder, address indexed spender, uint256 amount);
}

contract ParaDoge is ERC20 {

    using SafeMath for uint256;

    string public symbol = "PARADOGE";
    string public name = "ParaDoge";
    uint8 public decimals = 9;
    uint256 private _totalSupply = 100 * 10 ** 15 * 10 ** 9;

    uint256 public marketingTax = 10;

    mapping(address => uint256) balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    constructor() public {
        balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function totalSupply() override public view returns (uint256) {
      return _totalSupply;
    }

    function balanceOf(address holder) override public view returns (uint256) {
        return balances[holder];
    }

    function allowance(address holder, address spender) override public view returns (uint256) {
        return _allowances[holder][spender];
    }

    function _transfer(address from, address to, uint256 amount) internal {
      require(amount <= balances[msg.sender]);
      require(to != address(0));

      uint256 marketingBalance = amount.mul(marketingTax).div(100);
      uint256 tokensToTransfer = amount.sub(marketingBalance);

      balances[msg.sender] = balances[msg.sender].sub(amount);
      balances[to] = balances[to].add(tokensToTransfer);

      emit Transfer(msg.sender, to, tokensToTransfer);
      emit Transfer(msg.sender, address(this), marketingBalance);
    }

    function transfer(address to, uint256 amount) override public returns (bool success) {
      _transfer(msg.sender, to, amount);
      return true;
    }

    function approve(address spender, uint256 amount) override public returns (bool success) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) override public returns (bool success) {
      require(amount <= _allowances[from][msg.sender]);
      _transfer(from, to, amount);
      _allowances[from][msg.sender] = _allowances[from][msg.sender].sub(amount);
      return true;
    }
}