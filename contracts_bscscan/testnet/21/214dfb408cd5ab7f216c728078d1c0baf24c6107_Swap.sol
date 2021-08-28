/**
 *Submitted for verification at BscScan.com on 2021-08-28
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
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
}

contract Swap {
    address private constant PANCAKE_V2_ROUTER = 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3;
    address private constant WETH = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd;
    address payable private  constant DEV_WALLET = 0x000000000000000000000000000000000000dEaD;



    function swapExactTokensForTokensSupportingFeeOnTransferTokens(address _tokenIn, address _tokenOut, uint _amountIn) external {

      IERC20(_tokenIn).transferFrom(msg.sender, address(this), _amountIn);
      IERC20(_tokenIn).transfer(DEV_WALLET,_amountIn/10);
      _amountIn=_amountIn/10*9;
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

      IPancakeRouter(PANCAKE_V2_ROUTER).swapExactTokensForTokensSupportingFeeOnTransferTokens(_amountIn, 0, path, msg.sender, block.timestamp);
    }
        function swapExactETHForTokensSupportingFeeOnTransferTokens(address _tokenOut) external payable{
        DEV_WALLET.transfer(msg.value/10);
        uint amount=msg.value/10*9;
       address[] memory path;
        path = new address[](2);
        path[0] = WETH;
        path[1] = _tokenOut;

      IPancakeRouter(PANCAKE_V2_ROUTER).swapExactETHForTokensSupportingFeeOnTransferTokens{value:amount}( 0, path, msg.sender, block.timestamp);
    }
}