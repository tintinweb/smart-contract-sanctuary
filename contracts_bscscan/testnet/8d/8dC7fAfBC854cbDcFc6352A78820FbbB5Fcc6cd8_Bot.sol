/**
 *Submitted for verification at BscScan.com on 2021-12-01
*/

//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

interface IPancakeRouter {
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);

    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);
}

interface IERC20 {
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);
}

contract Bot {
    function swap1(
        address router,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable {
        IPancakeRouter(router).swapExactETHForTokens{value : msg.value}(amountOutMin, path, to, deadline);
    }

    function swap2(
        address router,
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external {
        IERC20(path[0]).transferFrom(msg.sender, address(this), amountIn);
        if (IERC20(path[0]).allowance(address(this), router) < amountIn) {
            IERC20(path[0]).approve(router, amountIn);
        }
        IPancakeRouter(router).swapExactTokensForETH(amountIn, amountOutMin, path, to, deadline);
    }
}