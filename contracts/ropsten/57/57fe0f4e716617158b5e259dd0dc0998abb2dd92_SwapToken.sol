/**
 *Submitted for verification at Etherscan.io on 2022-01-04
*/

// SPDX-License-Identifier: MIT
pragma solidity =0.8.10;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IUniswapV2Router {
    function swapExactTokensForETH(
        uint amountIn, 
        uint amountOutMin, 
        address[] calldata path, 
        address to, 
        uint deadline
    )external returns (uint[] memory amounts);
    function swapExactETHForTokens(
        uint amountOutMin, 
        address[] calldata path, 
        address to, 
        uint deadline
    ) external payable returns (uint[] memory amounts);
}

contract SwapToken {
    address WETH = 0xc778417E063141139Fce010982780140Aa0cD5Ab;
    address DAI = 0xaD6D458402F60fD3Bd25163575031ACDce07538D;
    address ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    
    function DAItoETH(
        uint _amountIn,
        uint _amountOutMin,
        address _to
    ) external {
        IERC20(DAI).transferFrom(msg.sender, address(this), _amountIn);
        IERC20(DAI).approve(ROUTER, _amountIn);
    
        address[] memory path;
        path = new address[](2);
        path[0] = DAI;
        path[1] = WETH;
    
        IUniswapV2Router(ROUTER).swapExactTokensForETH(
            _amountIn, 
            _amountOutMin, 
            path, 
            _to, 
            block.timestamp + 120
        );
    }

    function ETHtoDAI(address _to) external payable {
        uint deadline = block.timestamp + 120;
        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = DAI;

        IUniswapV2Router(ROUTER).swapExactETHForTokens{value: msg.value}(0, path, _to, deadline);
        // msg.sender.transfer(msg.sender, address(this), _amountIn);
    }
}