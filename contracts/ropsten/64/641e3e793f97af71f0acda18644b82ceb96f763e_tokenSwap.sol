/**
 *Submitted for verification at Etherscan.io on 2021-06-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;


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


//import the uniswap router
//the contract needs to use swapExactTokensForTokens
//this will allow us to import swapExactTokensForTokens into our contract

interface IUniswapV2Router {
  function getAmountsOut(uint256 amountIn, address[] memory path)
    external
    view
    returns (uint256[] memory amounts);
  
  function swapExactTokensForTokens(
  
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);
  
  function swapExactTokensForETH(
    uint amountIn,
    uint amountOutMin,
    address[] calldata path,
    address to,
    uint deadline)
        external
        returns (uint[] memory amounts);
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



contract tokenSwap {
    
    //address of the uniswap v2 router
    address private constant UNISWAP_V2_ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    
    address private constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    
    
    function swapTokensForETH(address _tokenIn, uint _amountIn,uint _amountOutMin, address _to) external {
        
      IERC20(_tokenIn).transferFrom(msg.sender, address(this), _amountIn);
      IERC20(_tokenIn).approve(UNISWAP_V2_ROUTER, _amountIn);
      
      address[] memory path;
      path = new address[](2);
      path[0] = _tokenIn;
      path[1] = WETH;
      
      IUniswapV2Router(UNISWAP_V2_ROUTER).swapExactTokensForETH(_amountIn, _amountOutMin, path, _to, block.timestamp + 240);
        
    }
    
     function getAmountOutMin(address _tokenIn, uint256 _amountIn) external view returns (uint) {
        // return IERC20(_tokenIn).totalSupply();
        require(_amountIn<3,'amount in not enough');
        address[] memory path;
        
            path = new address[](2);
            path[0] = _tokenIn;
            path[1] = WETH;
            
        uint256[] memory amountOutMins = IUniswapV2Router(UNISWAP_V2_ROUTER).getAmountsOut(_amountIn, path);
        return amountOutMins[path.length -1];
    
    }
    
}