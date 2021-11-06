/**
 *Submitted for verification at Etherscan.io on 2021-11-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface KeeperCompatibleInterface {
  function checkUpkeep(
    bytes calldata checkData
  )
    external
    returns (
      bool upkeepNeeded,
      bytes memory performData
    );

  function performUpkeep(
    bytes calldata performData
  ) external;
}

interface ISwapRouter {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);
}

contract KeeperBase {
  error OnlySimulatedBackend();

  function preventExecution() internal view {
    if (tx.origin != address(0)) {
      revert OnlySimulatedBackend();
    }
  }
  modifier cannotExecute() {
    preventExecution();
    _;
  }
}

contract GetPrice is KeeperCompatibleInterface, KeeperBase {
    ISwapRouter public immutable swapRouter; //0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D

    address public constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address public constant WETH9 = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

    uint24 public constant poolFee = 3000;
    uint256 public targetPrice = 0;
    bool public targetReached = false;

    constructor(ISwapRouter _swapRouter) {
        swapRouter = _swapRouter;
    }
    
    function updateTargetPrice(uint256 input) external {
        targetPrice = input;
    }

    function getOutput(uint256 amountIn) internal returns (uint256 amountOut) {
        
        ISwapRouter.ExactInputSingleParams memory params =
            ISwapRouter.ExactInputSingleParams({
                tokenIn: DAI,
                tokenOut: WETH9,
                fee: poolFee,
                recipient: msg.sender,
                deadline: block.timestamp,
                amountIn: amountIn,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });

        amountOut = swapRouter.exactInputSingle(params);
    }
    
    
    function checkUpkeep(bytes calldata checkData) external override cannotExecute returns (bool upkeepNeeded, bytes memory performData) {
        uint256 price = getOutput(1);
        upkeepNeeded = targetPrice > price;
        performData = checkData;
    }

    function performUpkeep(bytes calldata performData) external override {
        targetReached = true;
        performData;
    }
    
}