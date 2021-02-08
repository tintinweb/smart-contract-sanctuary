/**
 *Submitted for verification at Etherscan.io on 2021-02-08
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IERC20 {
  function totalSupply() external view returns (uint256);
  function balanceOf(address account) external view returns (uint256);
}

contract xSushiExchangeRate {

  IERC20 xSushi;
  IERC20 sushi;

  constructor(address _xSushi, address _sushi) {
    xSushi = IERC20(_xSushi);
    sushi = IERC20(_sushi);
  }

  function getExchangeRate() public view returns (uint256) {
    return sushi.balanceOf(address(xSushi))*(10**18) / xSushi.totalSupply();
  }
}