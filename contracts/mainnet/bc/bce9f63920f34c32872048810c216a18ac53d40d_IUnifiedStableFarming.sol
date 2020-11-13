// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

interface IUnifiedStableFarming {

    function percentage() external view returns(uint256[] memory);

    //Earn pumping uSD - Means swap a chosen stableCoin for uSD, then burn the difference of uSD to obtain a greater uSD value in Uniswap Pool tokens
    function earnByPump(
        address stableCoinAddress,
        uint256 pairIndex,
        uint256 pairAmount,
        uint256 amount0,
        uint256 amount1,
        address tokenAddress,
        uint256 tokenValue) external payable;

    //Earn dumping uSD - Means mint uSD then swap uSD for the chosen Uniswap Pool tokens
    function earnByDump(
        address stableCoinAddress,
        uint256 pairIndex,
        uint256 amount0,
        uint256 amount1,
        uint256 amount0Min,
        uint256 amount1Min,
        uint256[] calldata tokenIndices,
        uint256[] calldata stableCoinAmounts) external;
}

interface IStableCoin {

    function allowedPairs() external view returns (address[] memory);

    function fromTokenToStable(address tokenAddress, uint256 amount)
        external
        view
        returns (uint256);

    function mint(
        uint256 pairIndex,
        uint256 amount0,
        uint256 amount1,
        uint256 amount0Min,
        uint256 amount1Min
    ) external returns (uint256);

    function burn(
        uint256 pairIndex,
        uint256 pairAmount,
        uint256 amount0,
        uint256 amount1
    ) external returns (uint256, uint256);
}

interface IUniswapV2Pair {
    function token0() external view returns (address);
    function token1() external view returns (address);
}

interface IUniswapV2Router {
    function WETH() external pure returns (address);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function swapExactTokensForTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline) external payable returns (uint[] memory amounts);
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}