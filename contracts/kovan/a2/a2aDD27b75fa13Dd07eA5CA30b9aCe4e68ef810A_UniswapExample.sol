// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;

import "./IUniswapV2Router02.sol";
import "./CHIBurner.sol";

contract UniswapExample is CHIBurner {
  IUniswapV2Router02 constant public uniRouter = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
  address constant public multiDaiKovan = 0x4F96Fe3b7A6Cf9725f59d353F723c1bDb64CA6Aa;

  function convertEthToDai(uint daiAmount) external payable {
    _convertEthToDai(daiAmount);
  }

  function convertEthToDaiWithGasRefund(uint daiAmount) external payable discountCHIFrom {
    _convertEthToDai(daiAmount);
  }

  function convertEthToDaiWithGasRefund2(uint daiAmount) external payable discountCHI {
    _convertEthToDai(daiAmount);
  }

  function getEstimatedETHforDAI(uint daiAmount) external view returns (uint256[] memory) {
    return uniRouter.getAmountsIn(daiAmount, _getPathForETHtoDAI());
  }

  function _getPathForETHtoDAI() private pure returns (address[] memory) {
    address[] memory path = new address[](2);
    path[0] = uniRouter.WETH();
    path[1] = multiDaiKovan;
    
    return path;
  }
  
  function _convertEthToDai(uint daiAmount) private {
    // using 'now' for convenience in Remix, for mainnet pass deadline from frontend!
    uint deadline = block.timestamp + 15;

    uniRouter.swapETHForExactTokens{ value: msg.value }(
      daiAmount,
      _getPathForETHtoDAI(),
      address(this),
      deadline
    );
    
    // refund leftover ETH to user
    (bool success,) = msg.sender.call{ value: address(this).balance }("");
    require(success, "refund failed");
  }
  
  // important to receive ETH
  receive() payable external {}
}