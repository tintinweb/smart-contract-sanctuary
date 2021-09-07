// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12;

import './IERC20.sol';

library tokenHelper {

  function getTokenBalance(address tokenAddress) public view returns (uint256){
    return IERC20(tokenAddress).balanceOf(address(this));
  }

  function getTokenBalanceOfAddr(address tokenAddress,address user) public view returns (uint256){
    return IERC20(tokenAddress).balanceOf(user);
  }

  function recoverERC20(address tokenAddress,address receiver) internal {
    IERC20(tokenAddress).transfer(receiver, getTokenBalance(tokenAddress));
  }

}