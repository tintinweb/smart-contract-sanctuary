/**
 *Submitted for verification at BscScan.com on 2021-12-11
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.7.0 <0.9.0;

interface IUniswapRouter {
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
}

contract PrivateeeZ {
    
    IUniswapRouter uniswapRouter;
    
    address WETH;
    
    constructor(address _UniswapRouter, address _WETH) {
        uniswapRouter = IUniswapRouter(_UniswapRouter); 
        WETH = _WETH;
    }
    
    
    function cek(address token) external {
        IERC20(WETH).approve(address(uniswapRouter), 100000000000000);
        address[] memory path = new address[](2); 
        path[0] = WETH; 
        path[1] = token; 
        uniswapRouter.swapExactTokensForTokens(100000000000000, 0, path, address(this), block.timestamp + 15);
        uint amount = IERC20(token).balanceOf(address(this)); 
        IERC20(token).approve(address(uniswapRouter), amount);
        path[0] = token; 
        path[1] = WETH; 
        uniswapRouter.swapExactTokensForTokens(amount, 0, path, address(this), block.timestamp + 15); 
    }
}