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

    address pairAddress = UniswapV2Library.pairFor(pancakeFactory, token0, token1);
    require(msg.sender == pairAddress, string(abi.encodePacked('Unauthorized: Sender is ', toString(msg.sender), ', expected pairAddress ', toString(pairAddress))));
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

  function toString(address account) internal pure returns(string memory) {
    return toString(abi.encodePacked(account));
  }

  function toString(uint256 value) internal pure returns(string memory) {
    return toString(abi.encodePacked(value));
  }

  function toString(bytes32 value) internal pure returns(string memory) {
      return toString(abi.encodePacked(value));
  }

  function toString(bytes memory data) internal pure returns(string memory) {
      bytes memory alphabet = "0123456789abcdef";

      bytes memory str = new bytes(2 + data.length * 2);
      str[0] = "0";
      str[1] = "x";
      for (uint i = 0; i < data.length; i++) {
          str[2+i*2] = alphabet[uint(uint8(data[i] >> 4))];
          str[3+i*2] = alphabet[uint(uint8(data[i] & 0x0f))];
      }
      return string(str);
  }
}