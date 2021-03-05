// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
  function totalSupply() external view returns (uint256);
  function balanceOf(address account) external view returns (uint256);
}

contract xPpayExchangeRate {
  IERC20 private immutable xPpay;
  IERC20 private immutable ppay;

  constructor(address _xPpay, address _ppay) {
    xPpay = IERC20(_xPpay);
    ppay = IERC20(_ppay);
  }

  function getExchangeRate() public view returns( uint256 ) {
    return ppay.balanceOf(address(xPpay))*(1e18) / xPpay.totalSupply();
  }
  
  function toPPAY(uint256 xPpayAmount) public view returns (uint256 ppayAmount) {
    ppayAmount = xPpayAmount * ppay.balanceOf(address(xPpay)) / xPpay.totalSupply();
  }
  
  function toXPPAY(uint256 ppayAmount) public view returns (uint256 xPpayAmount) {
    xPpayAmount = ppayAmount * xPpay.totalSupply() / ppay.balanceOf(address(xPpay));
  }
}