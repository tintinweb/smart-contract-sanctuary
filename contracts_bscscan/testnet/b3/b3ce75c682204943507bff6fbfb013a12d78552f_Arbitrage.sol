// SPDX-License-Identifier: NOLICENSE

pragma solidity ^0.8.0;

import "./Interfaces.sol";
import './UniswapV2Library.sol';
import './Context.sol';
import './Ownable.sol';
import './Allowable.sol';

contract Arbitrage is Context, Ownable, Allowable  {
  event StartArbitrage(address token0, address token1, uint amount0, uint amount1);
  event PancakeCall(address token0, address token1, uint amount0, uint amount1, address pairAddress);
  event Approved(address bakeryRouter, address token, uint amount);
  event Swapped(address path0, address path1, uint amountToken, uint amountReceived, uint amountRequired);
  event FinishArbitrage(address path0, address path1, uint amountToken, uint amountReceived, uint amountRequired, uint profit);

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
    uint amount1,
    bytes calldata exitAt
  ) external onlyAllowed {
    address pairAddress = IUniswapV2Factory(pancakeFactory).getPair(token0, token1);
    require(pairAddress != address(0), 'This pool does not exist');
    
    emit StartArbitrage(token0, token1, amount0, amount1);

    IUniswapV2Pair(pairAddress).swap(
      amount0, 
      amount1, 
      address(this), 
      exitAt
    );
  }

  function pancakeCall(
    address, 
    uint _amount0, 
    uint _amount1, 
    bytes calldata exitAtBytes
  ) external {
    bytes1 exitAt = exitAtBytes[0];
    address[] memory path = new address[](2);
    uint amountToken = _amount0 == 0 ? _amount1 : _amount0;
    
    address token0 = IUniswapV2Pair(msg.sender).token0();
    address token1 = IUniswapV2Pair(msg.sender).token1();

    address pairAddress = UniswapV2Library.pairFor(pancakeFactory, token0, token1);
    require(msg.sender == pairAddress, string(abi.encodePacked('Unauthorized: Sender is ', toString(msg.sender), ', expected pairAddress ', toString(pairAddress))));
    require(_amount0 == 0 || _amount1 == 0);

    emit PancakeCall(token0, token1, _amount0, _amount1, pairAddress);

    address path0 = _amount0 == 0 ? token1 : token0;
    address path1 = _amount0 == 0 ? token0 : token1;
    path[0] = path0;
    path[1] = path1;

    checkExit(exitAt, 0x01);

    IERC20 token = IERC20(path0);    
    token.approve(address(bakeryRouter), amountToken);
    emit Approved(address(bakeryRouter), path0, amountToken);

    checkExit(exitAt, 0x02);

    uint amountRequired = UniswapV2Library.getAmountsIn(
      pancakeFactory, 
      amountToken, 
      path
    )[0];

    checkExit(exitAt, 0x03);

    uint amountReceived = bakeryRouter.swapExactTokensForTokens(
      amountToken, 
      amountRequired, 
      path, 
      msg.sender, 
      block.timestamp + deadline
    )[1];
    emit Swapped(path0, path1, amountToken, amountReceived, amountRequired);

    checkExit(exitAt, 0x04);

    uint profit = amountReceived - amountRequired;
    require(profit > 0, string(abi.encodePacked('Not profitable! amountReceived = ', amountReceived, ', amountRequired = ', amountRequired)));

    IERC20 otherToken = IERC20(path1);
    otherToken.transfer(msg.sender, amountRequired);

    checkExit(exitAt, 0x05);
    
    otherToken.transfer(tx.origin, profit);
    
    checkExit(exitAt, 0x06);

    
    emit FinishArbitrage(path0, path1, amountToken, amountReceived, amountRequired, profit);
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

  function checkExit(bytes1 exitAt, bytes1 myStep) internal pure {
    require(exitAt == 0 || exitAt != myStep, 'Reverting as instructed');
  }
}