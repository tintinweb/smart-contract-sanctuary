/**
 *Submitted for verification at Etherscan.io on 2021-09-12
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.0 <0.9.0;

interface IERC20 {
    function totalSupply() external view returns (uint);

    function balanceOf(address account) external view returns (uint);

    function transfer(address recipient, uint amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

interface IUniswapV2Router {
    function getAmountsOut(uint amountIn, address[] memory path)
        external
        view
        returns (uint[] memory amounts);

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactTokensForETH(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactETHForTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    )   external
        returns (
            uint amountA,
            uint amountB,
            uint liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
}

interface IUniswapV2Factory {
  event PairCreated(address indexed token0, address indexed token1, address pair, uint);

  function getPair(address tokenA, address tokenB) external view returns (address pair);
  function allPairs(uint) external view returns (address pair);
  function allPairsLength() external view returns (uint);

  function feeTo() external view returns (address);
  function feeToSetter() external view returns (address);

  function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

contract testLiquidity{
    
    address private constant sushiSwapRouter = 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506 ;
    address private constant sushiSwapFactory = 0xc35DADB65012eC5796536bD9864eD8773aBc74C4;
    //address private constant ETH =  ?? 沒有這東西？
    address private constant UNI = 0x71d82Eb6A5051CfF99582F4CDf2aE9cD402A4882;
    address private constant DAI = 0xc2118d4d90b274016cB7a54c03EF52E6c537D957;
    address private constant SUSHI = 0x0769fd68dFb93167989C6f7254cd0D766Fb2841F;
    address private constant WETH = 0xc778417E063141139Fce010982780140Aa0cD5Ab;
    address private constant USDC = 0x0D9C8723B343A8368BebE0B5E89273fF8D712e3C;
    // factory的功能是？必要？
    
    
    event myLog(string myMessage, uint256 myVal);
    
    
    function addLiquidity(
        address _tokenA,
        address _tokenB,
        uint _amountA,
        uint _amountB
    ) external   {
        IERC20(_tokenA).transferFrom(msg.sender, address(this), _amountA);
        IERC20(_tokenB).transferFrom(msg.sender, address(this), _amountB);
        
        IERC20(_tokenA).approve(sushiSwapRouter, _amountA);
        IERC20(_tokenB).approve(sushiSwapRouter, _amountB);
        
        (uint256 amountA, uint256 amountB, uint256 liquidity) = 
            IUniswapV2Router(sushiSwapRouter).addLiquidity(
            _tokenA,
            _tokenB,
            _amountA,
            _amountB,
            1,
            1,
            address(this),
            block.timestamp
            );
        
    
        emit myLog("amountA", amountA);
        emit myLog("amountB", amountB);
        emit myLog("liquidity", liquidity);
        
        
    }
    
    
    function removeLiquidity(address _tokenA, address _tokenB ) external{
        address pair = IUniswapV2Factory(sushiSwapFactory).getPair(_tokenA, _tokenB);
        uint256 liquidity = IERC20(pair).balanceOf(address(this));
        
        IERC20(pair).approve(sushiSwapRouter, liquidity);
        (uint256 amountA, uint amountB) = 
        IUniswapV2Router(sushiSwapRouter).removeLiquidity(
        _tokenA,
        _tokenB,
        liquidity,
        1,
        1,
        address(this),
        block.timestamp
        );
    emit myLog("amountA", amountA);
    emit myLog("amountB", amountB);
    
    }
    
 
    
    
}


//  Swaps an exact amount of ETH for as many output tokens as possible, along the route determined by the path.
//  The first element of path must be WETH, the last is the output token, 
//  and any intermediate elements represent intermediate pairs to trade through
//  (if, for example, a direct pair does not exist).