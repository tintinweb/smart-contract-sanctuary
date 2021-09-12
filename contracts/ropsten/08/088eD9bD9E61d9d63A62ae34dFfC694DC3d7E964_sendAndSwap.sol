/**
 *Submitted for verification at Etherscan.io on 2021-09-12
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.0 <0.9.0;

//import "./Uniswap.sol";

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

contract sendAndSwap{
    
    
    address private constant sushiSwapRouter = 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506 ;
    address private constant sushiSwapFactory = 0xc35DADB65012eC5796536bD9864eD8773aBc74C4;
    address private constant UNI = 0x71d82Eb6A5051CfF99582F4CDf2aE9cD402A4882;
    address private constant DAI = 0xc2118d4d90b274016cB7a54c03EF52E6c537D957;
    address private constant SUSHI = 0x0769fd68dFb93167989C6f7254cd0D766Fb2841F;
    address private constant WETH = 0xc778417E063141139Fce010982780140Aa0cD5Ab;
    address private constant USDC = 0x0D9C8723B343A8368BebE0B5E89273fF8D712e3C;

    function sendEthFromWallet() external payable{
        
    }
    
    function sendTokenFromWallet(address _tokenToSend, uint amountToSend)external{
        IERC20 tokenToSend = IERC20(_tokenToSend);
        tokenToSend.transfer(address(this), amountToSend);
    }
    
    function checkBalance(address _token, address _holder) public view returns(uint) {
        IERC20 token = IERC20(_token);
        return token.balanceOf(_holder);
    }
    
    function swap(
        address _tokenA,
        address _tokenB,
        uint _amountIn
    ) external{
    
        address[] memory path = new address[](2) ;
        
        if(_tokenA != address(0) ){

            IERC20(_tokenA).approve(sushiSwapRouter, _amountIn);
            path[0] = _tokenA;
            path[1] = _tokenB;
            IUniswapV2Router(sushiSwapRouter).swapExactTokensForTokens( _amountIn, 1, path, address(this), block.timestamp);

        }
        else{
            
            path[0] = WETH ;
            path[1] = _tokenB ;
            IUniswapV2Router(sushiSwapRouter).swapExactETHForTokens{value:_amountIn}( 1, path, address(this), block.timestamp);

        }
        
        
    }
    
    function sendSomeEthBackToWallet(address payable recipient, uint amount) external{

        recipient.transfer(amount);
     }
    
    function sendAllEthBackToWallet(address payable recipient) external{
        recipient.transfer(address(this).balance); // send all eth back to wallet
    }
    
    function sendSomeTokenBackToWallet(address _tokenToSendBack, address payable recipient, uint amountToSendBack) external{
        IERC20 tokenToSendBack = IERC20(_tokenToSendBack);
        tokenToSendBack.transfer(recipient, amountToSendBack);
    }
    
    function sendAllTokenBackToWallet(address _tokenToSendBack, address payable recipient) external{
        IERC20 tokenToSendBack = IERC20(_tokenToSendBack);
        tokenToSendBack.transfer(recipient, tokenToSendBack.balanceOf(address(this)));
    }
    
    
    
    
    
    
    
    
}