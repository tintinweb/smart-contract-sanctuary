// SPDX-License-Identifier: NOLICENSE

pragma solidity ^0.8.0;

import "./Interfaces.sol";
import './UniswapV2Library.sol';
import './Context.sol';
import './Ownable.sol';
import './Allowable.sol';

contract Arbitrage is Context, Ownable, Allowable  {
  address public pancakeFactory;
  uint constant deadline = 10 days;
  IUniswapV2Router02 public bakeryRouter;


  constructor(address _pancakeFactory, address _bakeryRouter) {
    pancakeFactory = _pancakeFactory;  
    bakeryRouter = IUniswapV2Router02(_bakeryRouter);
  }

  function startArbitrage(
    address token0, 
    address token1, 
    uint amount0, 
    uint amount1
  ) external onlyAllowed {
    address pairAddress = IUniswapV2Factory(pancakeFactory).getPair(token0, token1);
    require(pairAddress != address(0), 'This pool does not exist');
    
    IUniswapV2Pair(pairAddress).swap(
      amount0, 
      amount1, 
      address(this), 
      bytes('not empty')
    );
  }

  function pancakeCall(
    address, 
    uint _amount0, 
    uint _amount1, 
    bytes calldata
  ) external {
    address[] memory path = new address[](2);
    uint amountToken = _amount0 == 0 ? _amount1 : _amount0;
    
    address token0 = IUniswapV2Pair(msg.sender).token0();
    address token1 = IUniswapV2Pair(msg.sender).token1();

    require(
      msg.sender == UniswapV2Library.pairFor(pancakeFactory, token0, token1), 
      'Unauthorized'
    ); 
    require(_amount0 == 0 || _amount1 == 0);

    path[0] = _amount0 == 0 ? token1 : token0;
    path[1] = _amount0 == 0 ? token0 : token1;

    IERC20 token = IERC20(_amount0 == 0 ? token1 : token0);
    
    token.approve(address(bakeryRouter), amountToken);

    uint amountRequired = UniswapV2Library.getAmountsIn(
      pancakeFactory, 
      amountToken, 
      path
    )[0];
    uint amountReceived = bakeryRouter.swapExactTokensForTokens(
      amountToken, 
      amountRequired, 
      path, 
      msg.sender, 
      deadline
    )[1];

    IERC20 otherToken = IERC20(_amount0 == 0 ? token0 : token1);
    otherToken.transfer(msg.sender, amountRequired);
    otherToken.transfer(tx.origin, amountReceived - amountRequired);
  }
}