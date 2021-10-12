/**
 *Submitted for verification at BscScan.com on 2021-10-11
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

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
    address private constant PANCAKE_V2_ROUTER = 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3;
    
    //address of WETH token.  This is needed because some times it is better to trade through WETH.  
    //you might get a better price using WETH.  
    //example trading from token A to WETH then WETH to token B might result in a better price
    //TokenToken in BUSD testnet: 0x78867BbEeF44f2326bF8DDd1941a4439382EF2A7
    address private constant WETH = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd;
    
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
      IERC20(_tokenIn).transferFrom(msg.sender, address(this), _amountIn);

      //next we need to allow the router to spend the token we just sent to this contract
      //by calling IERC20 approve you allow the contract to spend the tokens in this contract 
      IERC20(_tokenIn).approve(PANCAKE_V2_ROUTER, _amountIn);

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
      //for the deadline we will pass in block.timestamp
      //the deadline is the latest time the trade is valid for
      IPancakeRouter(PANCAKE_V2_ROUTER).swapExactTokensForTokens(_amountIn, _amountOutMin, path, _to, block.timestamp);
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