/**
 *Submitted for verification at Etherscan.io on 2021-04-25
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface UniInterface {
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline) external  payable returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external  returns (uint[] memory amounts);
    function WETH() external  pure returns (address);
}

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Uniswapper  {
    address private _uniRouter = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    UniInterface UniContract;
    
    constructor() {
        UniContract = UniInterface(_uniRouter);
    }

    function swapTokensForETH (
        address token,
        uint amountIn,
        uint amountOutMin,
        uint deadline)
        external {
            IERC20(token).transferFrom(msg.sender, address(this), amountIn);    
            address[] memory path = new address[](2);
            path[0] = token;
            path[1] = UniContract.WETH();
            IERC20(token).approve(address(UniContract), amountIn);
            UniContract.swapExactTokensForETH(amountIn, amountOutMin, path, msg.sender, deadline);
        }
        
    function swapETHForTokens (
        address token,
        uint amountOutMin,
        uint deadline)
        external {
            address[] memory path = new address[](2);
            path[0] = UniContract.WETH();
            path[1] = token;
            UniContract.swapExactETHForTokens(amountOutMin, path, msg.sender, deadline);
        }
        
}