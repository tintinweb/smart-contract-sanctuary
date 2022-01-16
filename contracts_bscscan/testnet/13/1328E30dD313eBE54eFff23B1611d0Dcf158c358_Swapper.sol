/**
 *Submitted for verification at BscScan.com on 2022-01-15
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

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


contract Router {
  function swapExactTokensForTokens(
    uint amountIn,
    uint amountOutMin,
    address[] calldata path,
    address to,
    uint deadline
  ) external returns (uint[] memory amounts)  {}
}

contract Swapper
{
  Router router = Router(0xD99D1c33F9fC3444f8101754aBC46c52416550D1);
  // ERC20 DAI_token  = ERC20(0x8a9424745056Eb399FD19a0EC26A14316684e274);
  // ERC20 USDT_token = ERC20(0x7ef95a0FEE0Dd31b22626fA2e10Ee6A223F8a684);




  
  function swapDAIToUSDC(uint amount, address _tokenIn, address _tokenOut ) public
  {


    IERC20(_tokenIn).transferFrom(
      msg.sender,
      address(this),
      amount
    );

    address[] memory path = new address[](2);
    path[0] = address(_tokenIn);
    path[1] = address(_tokenOut);

    IERC20(_tokenIn).approve(address(router), amount);

    router.swapExactTokensForTokens(
      amount,
      1,
      path,
      msg.sender,
      block.timestamp
    );
  }
}