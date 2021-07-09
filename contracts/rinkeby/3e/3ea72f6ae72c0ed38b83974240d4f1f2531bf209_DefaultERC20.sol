/**
 *Submitted for verification at Etherscan.io on 2021-07-09
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract DefaultERC20 is IERC20 {

  string public constant name = 'Default Network Token';
  string public constant symbol = 'DNT';
  uint8 public constant decimals = 18;

  mapping (address => uint256) private _balances;
  mapping (address => mapping (address => uint256)) private _allowances;
  uint256 private _totalSupply;

  constructor(){}

  function totalSupply() public view override returns (uint256) {
    return _totalSupply;
  }

  function balanceOf(address account) public view override returns (uint256) {
    return _balances[account];
  }

  function transfer(address recipient, uint256 amount) public override returns (bool) {
    _transfer(msg.sender, recipient, amount);
    return true;
  }

  function allowance(address owner, address spender) public view override returns (uint256) {
    return _allowances[owner][spender];
  }

  function approve(address spender, uint256 amount) public override returns (bool) {
    _approve(msg.sender, spender, amount);
    return true;
  }

  function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
    _transfer(sender, recipient, amount);

    uint256 currentAllowance = _allowances[sender][msg.sender];
    require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
    unchecked {
      _approve(sender, msg.sender, currentAllowance - amount);
    }

    return true;
  }

  function mint(address recipient, uint256 amount) public returns (bool) {
    _mint(recipient, amount);
    return true;
  }

  function _transfer(address sender, address recipient, uint256 amount) internal virtual {
      require(sender != address(0), "ERC20: transfer from the zero address");
      require(recipient != address(0), "ERC20: transfer to the zero address");

      uint256 senderBalance = _balances[sender];
      require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");

      /* unchecked is new in Solidity 0.8 as a way to replace the pre-existing SafeMath 
       * from checking for overflow operations. Previously contracts were required to import
       * the SafeMath library but all operations are "safe" by default—"unchecked" blocks
       * are used to prevent the default overflow checking behavior to save gas.
       *
       * "unchecked" is implemented here (taken from OpenZeppelin's ERC20 implementation):
       * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol
       * because the require statement functionally performs an overflow check; additional checks
       * would therefore be redundant.
       */

      unchecked {_balances[sender] = senderBalance - amount;}
      _balances[recipient] += amount;

      emit Transfer(sender, recipient, amount);
  }


  function _mint(address recipient, uint256 amount) internal {
    require(recipient != address(0), "ERC20: mint to the zero address");

    _totalSupply += amount;
    _balances[recipient] += amount;

    emit Transfer(address(0), recipient, amount);
  }

  function _approve(address owner, address spender, uint256 amount) internal {
    require(owner != address(0), "ERC20: approve from the zero address");
    require(spender != address(0), "ERC20: approve to the zero address");

    _allowances[owner][spender] = amount;

    emit Approval(owner, spender, amount);
  }
}