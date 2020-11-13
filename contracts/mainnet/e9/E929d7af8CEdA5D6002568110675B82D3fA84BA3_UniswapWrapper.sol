// SPDX-License-Identifier: MIT;
pragma solidity =0.7.0;

interface Uniswap {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
    
    function getAmountsOut(
        uint amountIn,
        address[] memory path
    ) external view returns (uint[] memory amounts);
}

interface IERC20 {
    function balanceOf(address guy) external view returns (uint256);
    function transfer(address dst, uint256 wad) external returns (bool);
    function transferFrom(address src, address dst, uint256 wad) external returns (bool);
    function approve(address guy, uint256 wad) external returns (bool);
    function allowance(address src, address dst) external view returns (uint256);
}

contract UniswapWrapper {
    address private janitor;
    address constant weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address constant uniswap = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    constructor() {
        janitor = msg.sender;
    }

    function swap(
        address token_in,
        address token_out,
        uint256 amount_in,
        uint256 min_amount_out,
        address to
    ) external returns (bool) {
        IERC20 token = IERC20(token_in);
        token.transferFrom(msg.sender, address(this), amount_in);

        bool is_weth = token_in == weth || token_out == weth;
        address[] memory path = new address[](is_weth ? 2 : 3);
        path[0] = token_in;
        if (is_weth) {
            path[1] = token_out;
        } else {
            path[1] = weth;
            path[2] = token_out;
        }

        if (token.allowance(address(this), uniswap) == 0) {
            token.approve(uniswap, type(uint256).max);
        }
        Uniswap(uniswap).swapExactTokensForTokens(
            amount_in,
            min_amount_out,
            path,
            to,
            block.timestamp
        );
        return true;
    }

    function quote(address token_in, address token_out, uint256 amount_in) external view returns (uint256) {
        bool is_weth = token_in == weth || token_out == weth;
        address[] memory path = new address[](is_weth ? 2 : 3);
        path[0] = token_in;
        if (is_weth) {
            path[1] = token_out;
        } else {
            path[1] = weth;
            path[2] = token_out;
        }
        uint256[] memory amounts = Uniswap(uniswap).getAmountsOut(amount_in, path);
        return amounts[amounts.length - 1];
    }

    function dust(address _token) external returns (bool) {
        IERC20 token = IERC20(_token);
        return token.transfer(janitor, token.balanceOf(address(this)));
    }
}