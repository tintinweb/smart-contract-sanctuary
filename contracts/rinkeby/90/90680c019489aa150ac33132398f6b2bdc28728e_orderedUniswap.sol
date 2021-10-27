/**
 *Submitted for verification at Etherscan.io on 2021-10-27
*/

pragma solidity ^0.8.0;

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

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}


contract orderedUniswap{

    address internal constant UNISWAP_ROUTER_ADDRESS = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D ;//it works in every networks
    IUniswapV2Router02 internal uniswapRouter;
    
    address internal constant UNISWAP_FACTORY_ADDRESS = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f ;//it works in every networks
    IUniswapV2Factory internal uniswapFactory;
    
    constructor(){
        uniswapRouter = IUniswapV2Router02(UNISWAP_ROUTER_ADDRESS);
        uniswapFactory = IUniswapV2Factory(UNISWAP_FACTORY_ADDRESS);
    }
    
    function getPath(address tokenIn, address tokenOut) private view returns (address[] memory) {
        if(tokenIn == address(0)){
            address[] memory path = new address[](2);
            path[0] = uniswapRouter.WETH();
            path[1] = tokenOut;
            return path;
        }
        else if(tokenOut == address(0)){
            address[] memory path = new address[](2);
            path[0] = tokenIn;
            path[1] = uniswapRouter.WETH();
            return path;
        }
        else{
            address[] memory path = new address[](3);
            path[0] = tokenIn;
            path[1] = uniswapRouter.WETH();
            path[2] = tokenOut;
            return path;
        }
    }
    
    
    function exchange(
        address account,
        address tokenIn,
        address tokenOut,
        uint amountIn,
        uint amountOut)
        external{
            uint deadline = block.timestamp + 15; // using 'now' for convenience, for mainnet pass deadline from frontend!
            IERC20(tokenIn).transferFrom(account, address(this), amountIn);
            IERC20(tokenIn).approve(UNISWAP_ROUTER_ADDRESS, amountIn);
            if(tokenOut == address(0)){
                uniswapRouter.swapExactTokensForETH(amountIn,
                                                    amountOut,
                                                    getPath(tokenIn, tokenOut),
                                                    account,
                                                    deadline);
            }
            else{
                uniswapRouter.swapExactTokensForTokens(amountIn,
                                                       amountOut,
                                                       getPath(tokenIn, tokenOut),
                                                       account,
                                                       deadline);
            }
    }
                      
    
    receive() payable external {}
    
    function isTherePool(address tokenIn, address tokenOut) external view returns(bool){
        if(tokenIn == address(0)){
            tokenIn = 0xc778417E063141139Fce010982780140Aa0cD5Ab;
        }
        if(tokenOut == address(0)){
            tokenOut = 0xc778417E063141139Fce010982780140Aa0cD5Ab;
        }
        if(uniswapFactory.getPair(tokenIn, tokenOut) != address(0)){
            return true;
        }
        else{
            return false;
        }
    }
    
    function getAmountIn(address tokenIn,
                          address tokenOut,
                          uint amountOut)
                          external
                          view
                          returns(uint){
        return uniswapRouter.getAmountsIn(amountOut, getPath(tokenIn, tokenOut))[0];
    }
}