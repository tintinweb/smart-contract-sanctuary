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
    ISwapRouter public swapRouter = ISwapRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    address public constant TOKEN_A = 0x1217D27e164aBfa2B7CBbF78DFed000e3e82abF1;
    address public constant TOKEN_B = 0xB35C71E38A03eF7Ea6B56092f37f89fe02049B80;

    uint24 public constant poolFee = 500;
    uint256 public targetPrice = 0;
    bool public targetReached = false;
    
    function updateTargetPrice(uint256 input) external {
        targetPrice = input;
    }

    function getOutput(uint256 amountIn) public returns (uint256 amountOut) {
        ISwapRouter.ExactInputSingleParams memory params =
            ISwapRouter.ExactInputSingleParams({
                tokenIn: TOKEN_B,
                tokenOut: TOKEN_A,
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
        uint256 price = getOutput(1 ether);
        upkeepNeeded = targetPrice > price;
        performData = checkData;
    }

    function performUpkeep(bytes calldata performData) external override {
        targetReached = true;
        performData;
    }
    
}