/**
 *Submitted for verification at Etherscan.io on 2021-05-05
*/

pragma solidity =0.6.6;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

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
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

interface IWETH {
    function deposit() external payable;
    function depositTokens(uint256 _amount) external;
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address _sender, address _recipient, uint256 _amount) external returns (bool);
    function withdraw(uint) external;
    function withdrawTokens(uint256 _amount) external;
    function balanceOf(address _account) external view returns (uint256);
    function approve(address _spender, uint256 _amount) external returns (bool);
}

contract RootRouterWrapper {

    IUniswapV2Router02 router;
    address public KETH;
    address public WETH;
    address public TOKEN;

    constructor(address _router, address _KETH, address _WETH, address _TOKEN) public payable {
        router = IUniswapV2Router02(_router);
        KETH = _KETH;
        WETH = _WETH;
        TOKEN = _TOKEN;
        IWETH(KETH).approve(_router, 100000000000000000 * 1e18);
        IWETH(WETH).approve(_router, 100000000000000000 * 1e18);
        IWETH(TOKEN).approve(_router, 10000000000000000 * 1e18);
    }

    // This function overrides the swapExactTokensForETHSupportingFeeOnTransferTokens of the router
    // This function is used to trade TOKEN for WETH using KETH as middleware
    // This function will take the TOKEN and sell it for KETH and unwrap the KETH for WETH.
    // Path should be [TOKEN/KETH/WETH]
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external {
        IWETH(TOKEN).transferFrom(msg.sender, address(this), amountIn);
        uint256 tokenBalance = IWETH(TOKEN).balanceOf(address(this));
        address[] memory newPath = new address[](2);
        newPath[0] = path[0];
        newPath[1] = path[1];
        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(tokenBalance, amountOutMin, newPath, address(this), deadline);
        uint256 balance = IWETH(KETH).balanceOf(address(this));
        IWETH(KETH).withdrawTokens(balance);
        IWETH(WETH).transfer(to, balance);
    }

    // This function overrides the swapExactETHForTokensSupportingFeeOnTransferTokens
    // This function is used to trade WETH for TOKEN using KETH as middleware
    // This function will take the WETH wrap it to KETH and buy the TOKEN.
    // Path should be [WETH/KETH/TOKEN]
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    )
        external
        payable
    {
        uint256 amountIn = msg.value;
        IWETH(KETH).deposit{value: amountIn}();
        address[] memory newPath = new address[](2);
        newPath[0] = path[1];
        newPath[1] = path[2];
        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(amountIn, amountOutMin, newPath, to, deadline);
    }


}