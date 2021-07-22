/**
 *Submitted for verification at BscScan.com on 2021-07-22
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

interface Router {
  function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);  
  function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}

contract MyContract {
    
    address private constant PANCAKE_V1_ROUTER = 0xD99D1c33F9fC3444f8101754aBC46c52416550D1;
    address private constant PANCAKE_V2_ROUTER = 0xD99D1c33F9fC3444f8101754aBC46c52416550D1;
    address private constant WBNB = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd;
    
    function swapPancakeRouterV2_V1() external {
      
      address _token1 = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd;
      address _token2 = 0x31487d80abed475788c1FDcCa53DE631332e9ad1;
      uint _amount1 = 1000000000000000;
      address _to = 0xA8D92E4F707C84C140b60F425871a5E4370df574;
      
      IERC20(_token1).transferFrom(msg.sender, address(this), _amount1);
      IERC20(_token1).approve(PANCAKE_V2_ROUTER, _amount1);

      address[] memory path = new address[](2);
      path[0] = _token1;
      path[1] = _token2;
      
      uint _amountOut1 = this.getAmountOutMin(PANCAKE_V2_ROUTER, _token1, _token2, _amount1);
      _amountOut1 = (Router(PANCAKE_V2_ROUTER).swapExactTokensForTokens(_amount1, _amountOut1, path, address(this), block.timestamp))[path.length -1];
      
      IERC20(_token2).approve(PANCAKE_V1_ROUTER, _amountOut1);
      
      path[0] = _token2;
      path[1] = _token1;
      
      uint _amountOut2 = this.getAmountOutMin(PANCAKE_V1_ROUTER, _token2, _token1, _amountOut1);
      Router(PANCAKE_V1_ROUTER).swapExactTokensForTokens(_amountOut1, _amountOut2, path, _to, block.timestamp);
        
    }
    
    function getAmountOutMin(address _router, address _tokenIn, address _tokenOut, uint _amountIn) external view returns (uint) {
      address[] memory path = new address[](2);
      path[0] = _tokenIn;
      path[1] = _tokenOut;
      
      uint[] memory amountOutMins = Router(_router).getAmountsOut(_amountIn, path);
      return amountOutMins[path.length -1];
    }   
}