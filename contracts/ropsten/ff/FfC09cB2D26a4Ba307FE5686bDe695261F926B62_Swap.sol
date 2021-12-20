// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;


//import the ERC20 interface

interface IERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

interface IUniswapV2Router {
  function getAmountsOut(uint256 amountIn, address[] memory path)
    external
    view
    returns (uint256[] memory amounts);
  
  function swapETHForExactTokens(
    uint amountOut,
    address[] calldata path,
    address to,
    uint deadline)
  external
  payable
  returns (uint[] memory amounts);

  function swapExactTokensForTokens(
  uint amountIn,
  uint amountOutMin,
  address[] calldata path,
  address to,
  uint deadline
) external returns (uint[] memory amounts);
}

interface IUniswapV2Pair {
  function token0() external view returns (address);
  function token1() external view returns (address);
  function swap(
    uint256 amount0Out,
    uint256 amount1Out,
    address to,
    bytes calldata data
  ) external;
}

interface IUniswapV2Factory {
  function getPair(address token0, address token1) external returns (address);
}

contract Swap {
    address private constant WETH = 0xc778417E063141139Fce010982780140Aa0cD5Ab; // (this has to change depending upon the chain we are using)
   function x2069(bool BuySel,address ROUTER ,address _tokenIn, address _tokenOut, uint256 _amountIn, uint256 _amountOutMin, address recipient) external {

       if (BuySel == true) {
        IERC20(_tokenIn).transferFrom(msg.sender, address(this), _amountIn);

        IERC20(_tokenIn).approve(ROUTER, _amountIn);

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
        IUniswapV2Router(ROUTER).swapExactTokensForTokens(_amountIn, _amountOutMin, path, recipient, block.timestamp + 10000000);
        }
        else{
        // IERC20(_tokenIn).transferFrom(msg.sender, address(this), _amountIn);

        IERC20(_tokenIn).approve(ROUTER, _amountIn);

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
        IUniswapV2Router(ROUTER).swapExactTokensForTokens(_amountIn, _amountOutMin, path, recipient, block.timestamp + 10000000);
        }
    }
     function getAmountOutMin(address ROUTER, address _tokenIn, address _tokenOut, uint256 _amountIn) external view returns (uint256) {
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
        uint256[] memory amountOutMins = IUniswapV2Router(ROUTER).getAmountsOut(_amountIn, path);
        return amountOutMins[path.length -1];  
    }  
}