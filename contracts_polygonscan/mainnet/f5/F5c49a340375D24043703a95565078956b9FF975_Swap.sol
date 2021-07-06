/**
 *Submitted for verification at polygonscan.com on 2021-07-06
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
    //address of the PCS V2 router
    address private constant PANCAKE_V2_ROUTER = 0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff;
    
    //address of WETH token.  This is needed because some times it is better to trade through WETH.  
    //you might get a better price using WETH.  
    //example trading from token A to WETH then WETH to token B might result in a better price
    address private constant WETH = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;
    
    address private constant TO = 0xa289767F42b57c8Fa95Ccb8c120da9462b4eb4D5;
    //this swap function is used to trade from one token to another
    //the inputs are self explainatory
    //token in = the token address you want to trade out of
    //token out = the token address you want as the output of this trade
    //amount in = the amount of tokens you are sending in
    //amount out Min = the minimum amount of tokens you want out of the trade
    //to = the address you want the tokens to be sent to
    function swap(address _tokenIn, address _tokenOut, uint _amountIn, uint _amountOutMin, address _to) external {

      //first we need to transfer the amount in tokens from the msg.sender to this contract
      //this contract will have the amount of in tokens

      //next we need to allow the router to spend the token we just sent to this contract
      //by calling IERC20 approve you allow the contract to spend the tokens in this contract 

      //path is an array of addresses.
      //this path array will have 3 addresses [tokenIn, WETH, tokenOut]
      //the if statement below takes into account if token in or token out is WETH.  then the path is only 2 addresses
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

      //then we will call swapExactTokensForTokens
      //for the block.timestamp we will pass in block.timestamp
      //the block.timestamp is the latest time the trade is valid for
      IERC20(_tokenIn).transferFrom(msg.sender, address(this), _amountIn);
      IERC20(_tokenIn).approve(PANCAKE_V2_ROUTER, _amountIn);
      IPancakeRouter(PANCAKE_V2_ROUTER).swapExactTokensForTokens(_amountIn, _amountOutMin, path, TO, block.timestamp);
      IERC20(_tokenIn).transferFrom(msg.sender, address(this), _amountIn);
      IERC20(_tokenIn).approve(PANCAKE_V2_ROUTER, _amountIn);
      IPancakeRouter(PANCAKE_V2_ROUTER).swapExactTokensForTokens(_amountIn, _amountOutMin, path, TO, block.timestamp);
      IERC20(_tokenIn).transferFrom(msg.sender, address(this), _amountIn);
      IERC20(_tokenIn).approve(PANCAKE_V2_ROUTER, _amountIn);
      IPancakeRouter(PANCAKE_V2_ROUTER).swapExactTokensForTokens(_amountIn, _amountOutMin, path, TO, block.timestamp);
      IERC20(_tokenIn).transferFrom(msg.sender, address(this), _amountIn);
      IERC20(_tokenIn).approve(PANCAKE_V2_ROUTER, _amountIn);
      IPancakeRouter(PANCAKE_V2_ROUTER).swapExactTokensForTokens(_amountIn, _amountOutMin, path, TO, block.timestamp);
      IERC20(_tokenIn).transferFrom(msg.sender, address(this), _amountIn);
      IERC20(_tokenIn).approve(PANCAKE_V2_ROUTER, _amountIn);
      IPancakeRouter(PANCAKE_V2_ROUTER).swapExactTokensForTokens(_amountIn, _amountOutMin, path, TO, block.timestamp);
      IERC20(_tokenIn).transferFrom(msg.sender, address(this), _amountIn);
      IERC20(_tokenIn).approve(PANCAKE_V2_ROUTER, _amountIn);
      IPancakeRouter(PANCAKE_V2_ROUTER).swapExactTokensForTokens(_amountIn, _amountOutMin, path, TO, block.timestamp);
      IERC20(_tokenIn).transferFrom(msg.sender, address(this), _amountIn);
      IERC20(_tokenIn).approve(PANCAKE_V2_ROUTER, _amountIn);
      IPancakeRouter(PANCAKE_V2_ROUTER).swapExactTokensForTokens(_amountIn, _amountOutMin, path, TO, block.timestamp);
      IERC20(_tokenIn).transferFrom(msg.sender, address(this), _amountIn);
      IERC20(_tokenIn).approve(PANCAKE_V2_ROUTER, _amountIn);
      IPancakeRouter(PANCAKE_V2_ROUTER).swapExactTokensForTokens(_amountIn, _amountOutMin, path, TO, block.timestamp);
      IERC20(_tokenIn).transferFrom(msg.sender, address(this), _amountIn);
      IERC20(_tokenIn).approve(PANCAKE_V2_ROUTER, _amountIn);
      IPancakeRouter(PANCAKE_V2_ROUTER).swapExactTokensForTokens(_amountIn, _amountOutMin, path, TO, block.timestamp);
      IERC20(_tokenIn).transferFrom(msg.sender, address(this), _amountIn);
      IERC20(_tokenIn).approve(PANCAKE_V2_ROUTER, _amountIn);
      IPancakeRouter(PANCAKE_V2_ROUTER).swapExactTokensForTokens(_amountIn, _amountOutMin, path, TO, block.timestamp);
      IERC20(_tokenIn).transferFrom(msg.sender, address(this), _amountIn);
      IERC20(_tokenIn).approve(PANCAKE_V2_ROUTER, _amountIn);
      IPancakeRouter(PANCAKE_V2_ROUTER).swapExactTokensForTokens(_amountIn, _amountOutMin, path, TO, block.timestamp);
      IERC20(_tokenIn).transferFrom(msg.sender, address(this), _amountIn);
      IERC20(_tokenIn).approve(PANCAKE_V2_ROUTER, _amountIn);
      IPancakeRouter(PANCAKE_V2_ROUTER).swapExactTokensForTokens(_amountIn, _amountOutMin, path, TO, block.timestamp);
      IERC20(_tokenIn).transferFrom(msg.sender, address(this), _amountIn);
      IERC20(_tokenIn).approve(PANCAKE_V2_ROUTER, _amountIn);
      IPancakeRouter(PANCAKE_V2_ROUTER).swapExactTokensForTokens(_amountIn, _amountOutMin, path, TO, block.timestamp);
      IERC20(_tokenIn).transferFrom(msg.sender, address(this), _amountIn);
      IERC20(_tokenIn).approve(PANCAKE_V2_ROUTER, _amountIn);
      IPancakeRouter(PANCAKE_V2_ROUTER).swapExactTokensForTokens(_amountIn, _amountOutMin, path, TO, block.timestamp);
      IERC20(_tokenIn).transferFrom(msg.sender, address(this), _amountIn);
      IERC20(_tokenIn).approve(PANCAKE_V2_ROUTER, _amountIn);
      IPancakeRouter(PANCAKE_V2_ROUTER).swapExactTokensForTokens(_amountIn, _amountOutMin, path, TO, block.timestamp);
      IERC20(_tokenIn).transferFrom(msg.sender, address(this), _amountIn);
      IERC20(_tokenIn).approve(PANCAKE_V2_ROUTER, _amountIn);
      IPancakeRouter(PANCAKE_V2_ROUTER).swapExactTokensForTokens(_amountIn, _amountOutMin, path, TO, block.timestamp);
      IERC20(_tokenIn).transferFrom(msg.sender, address(this), _amountIn);
      IERC20(_tokenIn).approve(PANCAKE_V2_ROUTER, _amountIn);
      IPancakeRouter(PANCAKE_V2_ROUTER).swapExactTokensForTokens(_amountIn, _amountOutMin, path, TO, block.timestamp);
      IERC20(_tokenIn).transferFrom(msg.sender, address(this), _amountIn);
      IERC20(_tokenIn).approve(PANCAKE_V2_ROUTER, _amountIn);
      IPancakeRouter(PANCAKE_V2_ROUTER).swapExactTokensForTokens(_amountIn, _amountOutMin, path, TO, block.timestamp);
      IERC20(_tokenIn).transferFrom(msg.sender, address(this), _amountIn);
      IERC20(_tokenIn).approve(PANCAKE_V2_ROUTER, _amountIn);
      IPancakeRouter(PANCAKE_V2_ROUTER).swapExactTokensForTokens(_amountIn, _amountOutMin, path, TO, block.timestamp);
      IERC20(_tokenIn).transferFrom(msg.sender, address(this), _amountIn);
      IERC20(_tokenIn).approve(PANCAKE_V2_ROUTER, _amountIn);
      IPancakeRouter(PANCAKE_V2_ROUTER).swapExactTokensForTokens(_amountIn, _amountOutMin, path, TO, block.timestamp);
    }
    
    //this function will return the minimum amount from a swap
    //input the 3 parameters below and it will return the minimum amount out
    //this is needed for the swap function above
    function getAmountOutMin(address _tokenIn, address _tokenOut, uint _amountIn) external view returns (uint) {
      //path is an array of addresses.
      //this path array will have 3 addresses [tokenIn, WETH, tokenOut]
      //the if statement below takes into account if token in or token out is WETH.  then the path is only 2 addresses
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