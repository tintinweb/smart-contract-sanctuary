/**
 *Submitted for verification at BscScan.com on 2021-10-30
*/

pragma solidity ^0.6.0;

interface TokenInterface {
    function approve(address, uint256) external;
    function transfer(address, uint) external;
    function transferFrom(address, address, uint) external;
    function deposit() external payable;
    function withdraw(uint) external;
    function balanceOf(address) external view returns (uint);
    function decimals() external view returns (uint);
}

interface IUniswapV2Router02 {
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
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
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
        function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    
    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IUniswapV2Factory {
  function getPair(address tokenA, address tokenB) external view returns (address pair);
  function allPairs(uint) external view returns (address pair);
  function allPairsLength() external view returns (uint);

  function feeTo() external view returns (address);
  function feeToSetter() external view returns (address);

  function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Pair {
  function balanceOf(address owner) external view returns (uint);

  function approve(address spender, uint value) external returns (bool);
  function transfer(address to, uint value) external returns (bool);
  function transferFrom(address from, address to, uint value) external returns (bool);

  function factory() external view returns (address);
  function token0() external view returns (address);
  function token1() external view returns (address);
  function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
  function price0CumulativeLast() external view returns (uint);
  function price1CumulativeLast() external view returns (uint);
}

contract UniswapHelpers {
    /**
     * @dev Return WETH address
     */
    function getAddressWETH() internal pure returns (address) {
        return 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c; // mainnet
        // return 0xd0A1E359811322d97991E03f863a0C30C2cF029C; // kovan
    }

    /**
     * @dev Return uniswap v2 router02 Address
     */
    function getUniswapAddr() internal pure returns (address) {
        return 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    }

    function getExpectedBuyAmt(
        IUniswapV2Router02 router,
        address[] memory paths,
        uint sellAmt
    ) internal view returns(uint buyAmt) {
        uint[] memory amts = router.getAmountsOut(
            sellAmt,
            paths
        );
        buyAmt = amts[1];
    }

    function getPaths(
        address buyAddr,
        address sellAddr
    ) internal pure returns(address[] memory paths) {
        paths = new address[](2);
        paths[0] = address(sellAddr);
        paths[1] = address(buyAddr);
    }
    
        function checkPair(
        IUniswapV2Router02 router,
        address[] memory paths
    ) internal view {
        address pair = IUniswapV2Factory(router.factory()).getPair(paths[0], paths[1]);
        require(pair != address(0), "No-exchange-address");
    }
    
    
        function changeEthAddress(address buy, address sell) internal pure returns(TokenInterface _buy, TokenInterface _sell){
        _buy = buy == getAddressWETH() ? TokenInterface(getAddressWETH()) : TokenInterface(buy);
        _sell = sell == getAddressWETH() ? TokenInterface(getAddressWETH()) : TokenInterface(sell);
    }

}

contract Scalper is UniswapHelpers {
        event LogCheck(
        address indexed buyToken,
        address indexed sellToken,
        uint256 buyAmt,
        uint256 sellAmt,
        uint256 expectedAmtOut,
        uint256 buyAmtWETH
    );
function checkWithFees(
        address buyAddr,
        address sellAddr,
        uint sellAmt
    ) external payable {
        (TokenInterface _buyAddr, TokenInterface _sellAddr) = changeEthAddress(buyAddr, sellAddr);
        address[] memory paths = getPaths(address(buyAddr), address(sellAddr));
        address[] memory pathsInverse = getPaths(address(sellAddr), address(buyAddr));
        
        IUniswapV2Router02 router = IUniswapV2Router02(getUniswapAddr());

        checkPair(router, paths);
    
         _sellAddr.approve(address(router), sellAmt);
        
        uint expectedAmt = getExpectedBuyAmt(router, paths, sellAmt);

        uint buyAmt = router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            sellAmt,
            expectedAmt,
            paths,
            msg.sender,
            now + 1
        )[1];
        
        uint expectedAmtOut = getExpectedBuyAmt(router, pathsInverse, buyAmt);
        
        _buyAddr.approve(address(router), buyAmt);
        
        uint buyAmtWETH = router.swapExactTokensForTokens(
            buyAmt,
            expectedAmtOut,
            pathsInverse,
            msg.sender,
            now + 1
        )[1];
        
        emit LogCheck(buyAddr, sellAddr, buyAmt, sellAmt, expectedAmtOut, buyAmtWETH);
    }
function check(
        address buyAddr,
        address sellAddr,
        uint sellAmt
    ) external payable {
        (TokenInterface _buyAddr, TokenInterface _sellAddr) = changeEthAddress(buyAddr, sellAddr);
        address[] memory paths = getPaths(address(buyAddr), address(sellAddr));
        address[] memory pathsInverse = getPaths(address(sellAddr), address(buyAddr));
        
        IUniswapV2Router02 router = IUniswapV2Router02(getUniswapAddr());

        checkPair(router, paths);
        
        _sellAddr.approve(address(router), sellAmt);
        
        uint expectedAmt = getExpectedBuyAmt(router, paths, sellAmt);

        uint buyAmt = router.swapExactTokensForTokens(
            sellAmt,
            expectedAmt,
            paths,
            msg.sender,
            now + 1
        )[1];
        
        uint expectedAmtOut = getExpectedBuyAmt(router, pathsInverse, buyAmt);
        
        _buyAddr.approve(address(router), buyAmt);
        
        uint buyAmtWETH = router.swapExactTokensForTokens(
            buyAmt,
            expectedAmtOut,
            pathsInverse,
            msg.sender,
            now + 1
        )[1];
        
        emit LogCheck(buyAddr, sellAddr, buyAmt, sellAmt, expectedAmtOut, buyAmtWETH);
    }    
    }