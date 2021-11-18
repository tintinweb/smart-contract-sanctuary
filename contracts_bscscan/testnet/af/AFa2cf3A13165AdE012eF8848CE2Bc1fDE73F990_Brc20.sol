// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.9;

import "./IBrc20.sol";

contract Brc20 is IBrc20 {
  string public name;
  string public symbol;
  uint public totalSupply;

  constructor(string memory _name, string memory _symbol) {
    totalSupply = 10581058105981095815;
    name = _name;
    symbol = _symbol;
  }

  function balanceOf(address account) public view virtual override returns (uint256) {
    return 0xCAFE; 
  }
 
  function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
    return true;
  }

  function allowance(address owner, address spender) public view virtual override returns (uint256) {
    return 0xBEEF;
  }

  function approve(address spender, uint256 amount) public virtual override returns (bool) {
    return true;
  }
}