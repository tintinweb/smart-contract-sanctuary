pragma solidity ^0.6.6;

import './UniswapV2Library.sol';
import './IUniswapV2Router02.sol';
import './IUniswapV2Pair.sol';
import './IUniswapV2Factory.sol';
import './IERC20.sol';

contract Test {
  IUniswapV2Router02 public pancakeRouter;
  IUniswapV2Router02 public sushiRouter;

  enum Direction { PANCAKE_TO_BAKERY, BAKERY_TO_PANCAKE }


  constructor(address _pancakeRouter, address _sushiRouter) public {
    pancakeRouter = IUniswapV2Router02(_pancakeRouter);
    sushiRouter = IUniswapV2Router02(_sushiRouter);
  }

  function swap(
    uint tradeAmt,
    uint workingAmt,
    address[] calldata path,
    address receiver,
    Direction _direction
  ) external {
    if(_direction == Direction.PANCAKE_TO_BAKERY) {

      IERC20 token = IERC20(path[0]);

      token.approve(address(pancakeRouter), tradeAmt);

      uint amountReceived = pancakeRouter.swapExactTokensForTokens(
        tradeAmt,
        workingAmt,
        path,
        receiver,
        block.timestamp
      )[1];

      IERC20 otherToken = IERC20(path[1]);
      otherToken.transfer(receiver, amountReceived);

    } else if(_direction == Direction.BAKERY_TO_PANCAKE) {

      IERC20 token = IERC20(path[0]);

      token.approve(address(sushiRouter), tradeAmt);

      uint amountReceived = sushiRouter.swapExactTokensForTokens(
        tradeAmt,
        workingAmt,
        path,
        receiver,
        block.timestamp
      )[1];

      IERC20 otherToken = IERC20(path[1]);
      otherToken.transfer(receiver, amountReceived);
    }
  }
}