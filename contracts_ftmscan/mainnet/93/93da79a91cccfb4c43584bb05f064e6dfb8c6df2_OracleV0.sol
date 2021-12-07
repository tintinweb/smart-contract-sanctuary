/**
 *Submitted for verification at FtmScan.com on 2021-12-07
*/

pragma solidity ^0.8.9;

//import "@openzeppelin/contracts/interfaces/IERC20.sol";
interface IERC20 {
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

//import "IUniswapV2Router01.sol";
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

contract OracleV0 {
    address private constant SUSHI_ROUTER  = 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506;
    address private constant SPOOKY_ROUTER = 0xF491e7B69E4244ad4002BC14e878a34207E38c29;

    address private constant WFTM  = 0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83;
    address private constant USDC  = 0x04068DA6C83AFCFA0e13ba15A6696662335D5B75;
    address private constant ECHO  = 0x54477A1D1bb8C1139eEF754Fd2eFd4DDeE7933dd;
    address private constant EYE   = 0x496e1693A7B162c4f0Cd6a1792679cC48EcbCC8d;
    address private constant MUNNY = 0x195FE0c899434fB47Cd6c1A09ba9DA56A1Cca12C;

    // store some constant info here to save gas instead of calling public contract getters
    uint8 private constant WFTM_DECIMALS  = 18;
    uint8 private constant USDC_DECIMALS  =  6;
    uint8 private constant ECHO_DECIMALS  =  9;
    uint8 private constant EYE_DECIMALS   = 18;
    uint8 private constant MUNNY_DECIMALS = 18;

    // Custom functions
    function echoPriceInFTMSushi() public view returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = ECHO;
        path[1] = WFTM;
        return IUniswapV2Router01(SUSHI_ROUTER).getAmountsOut(1*(10**ECHO_DECIMALS), path)[1];
    }
    function echoPriceInUSDCSushi() public view returns (uint256) {
        address[] memory path = new address[](3);
        path[0] = ECHO;
        path[1] = WFTM;
        path[2] = USDC;
        return IUniswapV2Router01(SUSHI_ROUTER).getAmountsOut(1*(10**ECHO_DECIMALS), path)[2];
    }

    //function echoPriceInFTMSpooky() public view returns (uint256) {
    //    address[] memory path = new address[](2);
    //    path[0] = ECHO;
    //    path[1] = WFTM;
    //    return IUniswapV2Router01(SPOOKY_ROUTER).getAmountsOut(1*(10**ECHO_DECIMALS), path)[1];
    //}
    //function echoPriceInUSDCSpooky() public view returns (uint256) {
    //    address[] memory path = new address[](3);
    //    path[0] = ECHO;
    //    path[1] = WFTM;
    //    path[2] = USDC;
    //    return IUniswapV2Router01(SPOOKY_ROUTER).getAmountsOut(1*(10**ECHO_DECIMALS), path)[2];
    //}

    function eyePriceInFTMSpooky() public view returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = EYE;
        path[1] = WFTM;
        return IUniswapV2Router01(SPOOKY_ROUTER).getAmountsOut(1*(10**EYE_DECIMALS), path)[1];
    }
    function eyePriceInUSDCSpooky() public view returns (uint256) {
        address[] memory path = new address[](3);
        path[0] = EYE;
        path[1] = WFTM;
        path[2] = USDC;
        return IUniswapV2Router01(SPOOKY_ROUTER).getAmountsOut(1*(10**EYE_DECIMALS), path)[2];
    }

    function munnyPriceInFTMSpooky() public view returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = MUNNY;
        path[1] = WFTM;
        return IUniswapV2Router01(SPOOKY_ROUTER).getAmountsOut(1*(10**MUNNY_DECIMALS), path)[1];
    }
    function munnyPriceInUSDCSpooky() public view returns (uint256) {
        address[] memory path = new address[](3);
        path[0] = MUNNY;
        path[1] = WFTM;
        path[2] = USDC;
        return IUniswapV2Router01(SPOOKY_ROUTER).getAmountsOut(1*(10**MUNNY_DECIMALS), path)[2];
    }

    // Generic functions
    function exchangeRate(address _from, address _to, address _router) public view returns (uint256) {
        uint256 fromDecimals = IERC20(_from).decimals();

        address[] memory path = new address[](2);
        path[0] = _from;
        path[1] = _to;

        return IUniswapV2Router01(_router).getAmountsOut(1*(10**fromDecimals), path)[1];
    }

    function exchangeRateInWFTM(address _from, address _router) public view returns (uint256) {
        return exchangeRate(_from, WFTM, _router);
    }
    function exchangeRateInUSDC(address _from, address _router) public view returns (uint256) {
        return exchangeRate(_from, USDC, _router);
    }
    function exchangeRateInUSDCviaFTM(address _from, address _router) public view returns (uint256) {
        uint256 fromDecimals = IERC20(_from).decimals();

        address[] memory path = new address[](2);
        path[0] = _from;
        path[1] = WFTM;
        path[2] = USDC;

        return IUniswapV2Router01(_router).getAmountsOut(1*(10**fromDecimals), path)[2];
    }
}