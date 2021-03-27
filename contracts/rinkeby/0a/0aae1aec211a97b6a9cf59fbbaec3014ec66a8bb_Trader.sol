/**
 *Submitted for verification at Etherscan.io on 2021-03-26
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

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


interface IERC20Uniswap {
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

contract Trader { 
    IUniswapV2Router01 router;
    mapping(address => bool) public admins;
    address public weth;

    constructor(address admin, IUniswapV2Router01 routerAddress, address wethAddress) public {
        router = routerAddress;
        admins[admin] = true;
        weth = wethAddress;
    }
    
    // receive() external payable { ... }
    
    function setAdmin(address[] memory admin) public {
        require(admins[msg.sender],"not admin");

        for(uint256 i = 0; i < admin.length; i++){                
            admins[admin[i]] = true;
        }
    }

    function swapExactETHForTokens(uint256 amountOutMin, address[] calldata path, uint deadline) public payable {
        router.swapExactETHForTokens{value: msg.value}(amountOutMin,path,address(this),deadline);
    }

    function swapExactTokensForETH(uint amountOutMin, address[] calldata path, uint deadline) public {
        require(path.length == 2,"path wrong!");

        address tokenAddress = path[0];

        uint256 amountIn = IERC20Uniswap(tokenAddress).balanceOf(address(this));
        
        router.swapExactTokensForETH(amountIn,amountOutMin,path,address(this),deadline);
    }

    function withdraw(address tokenAddress) public {
        require(admins[msg.sender] == true, "not admin");

        if (tokenAddress == address(0)){
            payable(msg.sender).transfer(address(this).balance);
        }else{
            uint256 value = IERC20Uniswap(tokenAddress).balanceOf(address(this));
            IERC20Uniswap(tokenAddress).transfer(msg.sender, value);
        }
    }

    function setApporve(address tokenAddress) public {
        require(admins[msg.sender] == true, "not admin");

        IERC20Uniswap(tokenAddress).approve(address(router),type(uint256).max);
    }
   
}