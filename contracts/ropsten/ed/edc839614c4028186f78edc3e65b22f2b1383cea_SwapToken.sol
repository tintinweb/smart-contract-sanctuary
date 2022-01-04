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
    function decimals() external view returns(uint);
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

interface IUniswapV2Pair{
    function token1() external view returns(IERC20);
    function token0() external view returns(IERC20);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}
interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

contract SwapToken {
    address WETH = 0xc778417E063141139Fce010982780140Aa0cD5Ab;
    address DAI = 0xaD6D458402F60fD3Bd25163575031ACDce07538D;
    address ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address FACTORY = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    
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

    function getDAIperETHPrice() external view returns (uint){
        address PAIR = IUniswapV2Factory(FACTORY).getPair(DAI,WETH);
        IUniswapV2Pair vpair = IUniswapV2Pair(PAIR);
        IERC20 token1 = IERC20(vpair.token1());

        (uint Res0, uint Res1,) = vpair.getReserves();
        uint res0 = Res0*(10**token1.decimals());
        return((res0)/Res1); // return amount of token0 needed to buy token1
    }
    function getETHperDAIPrice() external view returns (uint){
        address PAIR = IUniswapV2Factory(FACTORY).getPair(DAI,WETH);
        IUniswapV2Pair vpair = IUniswapV2Pair(PAIR);
        IERC20 token0 = IERC20(vpair.token0());

        (uint Res0, uint Res1,) = vpair.getReserves();
        uint res1 = Res1*(10**token0.decimals());
        return((res1)/Res0); // return amount of token1 needed to buy token0
    }
}