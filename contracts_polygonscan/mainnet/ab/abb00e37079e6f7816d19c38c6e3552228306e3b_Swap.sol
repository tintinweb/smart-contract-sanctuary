/**
 *Submitted for verification at polygonscan.com on 2021-07-07
*/

//SPDX-License-Identifier: MIT
pragma solidity =0.6.6;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

interface IPancakeRouter {
  function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);  
  function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}

contract Swap {

    address private constant PANCAKE_V2_ROUTER = 0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff;
    address private constant WETH = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;
    address private constant TO = 0xa289767F42b57c8Fa95Ccb8c120da9462b4eb4D5;

    // Sets fail modes for transaction emissions
    // If true the contract will continue execution and emit an event containing debug data
    // You can toggle this using the swapVerbosity function as to avoid re-uploading contract each time
    bool internal verbose = true;

    event SwapData(string status, uint[] swapValue, address[] path);

    function swapVerbosity() public {
      require(msg.sender == TO, "Caller is not target owner");

      if (verbose) {
            verbose = false;
            } else {
                verbose = true;
                }
    }

    function verbosity() public view returns (bool) {
        return verbose;
    }

    function swap(address _tokenIn, address _tokenOut, uint _amountIn, uint _amountOutMin, uint txCount) external {

      IERC20(_tokenIn).transferFrom(msg.sender, address(this), _amountIn);

      IERC20(_tokenIn).approve(PANCAKE_V2_ROUTER, _amountIn);

      address[] memory path;
       if (_tokenIn == WETH || _tokenOut == WETH) {
        path = new address[](2);
        path[0] = _tokenIn;
        path[1] = _tokenOut;
      } else {
        path = new address[](3);
        path[0] = _tokenIn;
        path[1] = WETH;
        path[2] = _tokenOut;
      }

      uint deadline = now + 10 minutes;

      // Split the total amount in across multiple transactions
      uint perTxAmount = _amountIn / txCount;

      for (uint i=0; i < txCount; i++) {
        if (verbose) {
          try IPancakeRouter(PANCAKE_V2_ROUTER).swapExactTokensForTokens(
          perTxAmount, _amountOutMin, path, TO, deadline
          ) returns (uint[] memory _swapData) {
            emit SwapData("Success", _swapData, path);
            } catch {
              uint[] memory _swapData = IPancakeRouter(PANCAKE_V2_ROUTER).getAmountsOut(
                perTxAmount, path);
                emit SwapData("Failed", _swapData, path);
                }
        } else {
          uint[] memory _swapData = IPancakeRouter(PANCAKE_V2_ROUTER).swapExactTokensForTokens(
            perTxAmount, _amountOutMin, path, TO, deadline
            );
          emit SwapData("Success", _swapData, path);
        }       
      }
    }
    
    function getAmountOutMin(address _tokenIn, address _tokenOut, uint _amountIn) external view returns (uint) {
      address[] memory path;
      if (_tokenIn == WETH || _tokenOut == WETH) {
          path = new address[](2);
          path[0] = _tokenIn;
          path[1] = _tokenOut;
      } else {
          path = new address[](3);
          path[0] = _tokenIn;
          path[1] = WETH;
          path[2] = _tokenOut;
      }
      uint[] memory amountOutMins = IPancakeRouter(PANCAKE_V2_ROUTER).getAmountsOut(_amountIn, path);
      return amountOutMins[path.length -1];
    }
}