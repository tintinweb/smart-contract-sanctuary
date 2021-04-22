//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC20, ERC20Detailed, SafeERC20, Address, SafeMath, IERC20} from "./imports.sol";

contract RooCoin is ERC20, ERC20Detailed {
  using SafeERC20 for IERC20;
  using Address for address;
  using SafeMath for uint256;
  
  constructor () public ERC20Detailed("RooCoin", "ROO", 18){
    _totalSupply =  400000000 *(10**uint256(18));
	_balances[msg.sender] = _totalSupply;
  }
  
}