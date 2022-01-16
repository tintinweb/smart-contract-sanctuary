// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import './interfaces/IDEXAVAXRouter.sol';

contract SellSomething {
  IDEXAVAXRouter router =
    IDEXAVAXRouter(0x60aE616a2155Ee3d9A68541Ba4544862310933d4);

  function sell(address token, uint256 amount) external {
    address[] memory path = new address[](2);
    path[0] = token;
    path[1] = 0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7; // WAVAX
    router.swapExactTokensForAVAXSupportingFeeOnTransferTokens(
      amount,
      0,
      path,
      msg.sender,
      block.timestamp
    );
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IDEXAVAXRouter {
  function factory() external pure returns (address);

  function WAVAX() external pure returns (address);

  function addLiquidity(
    address tokenA,
    address tokenB,
    uint256 amountADesired,
    uint256 amountBDesired,
    uint256 amountAMin,
    uint256 amountBMin,
    address to,
    uint256 deadline
  )
    external
    returns (
      uint256 amountA,
      uint256 amountB,
      uint256 liquidity
    );

  function addLiquidityAVAX(
    address token,
    uint256 amountTokenDesired,
    uint256 amountTokenMin,
    uint256 amountAVAXMin,
    address to,
    uint256 deadline
  )
    external
    payable
    returns (
      uint256 amountToken,
      uint256 amountAVAX,
      uint256 liquidity
    );

  function swapExactTokensForTokensSupportingFeeOnTransferTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external;

  function swapExactAVAXForTokensSupportingFeeOnTransferTokens(
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external payable;

  function swapExactTokensForAVAXSupportingFeeOnTransferTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external;
}