pragma solidity ^0.7.0;

import "SafeMath.sol";
import "Ownable.sol";
import "LivePriceETH.sol";

contract UniTrader is Ownable, LivePrice {
    using SafeMath for uint256;

    UniSwapRouter UniSwap;
    UniSwapFactory Factory;

    uint256 oracleValueDivisor;
    uint256 decimals;
    address DAI;

    constructor() {

      UniSwap = UniSwapRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
      Factory = UniSwapFactory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);
      oracleValueDivisor = 10**8;
      decimals = 10**18;
      DAI = address(0x1968d970866AD1D2eB0F20b1431A0fBae2688346); // 0x6B175474E89094C44Da98b954EedeAC495271d0F

    }
    function swapETHtoDAI1(uint amountToSend, uint swapSlippage) public returns (uint256 amountOut) {
      require(0 < swapSlippage && swapSlippage <= 100, "Slippage out of bounds!");
        address[] memory path = new address[](2);
      path[0] = UniSwap.WETH();
      path[1] = DAI; // DAI
      uint priceFeed = uint(getLatestPrice());
      uint amountOutMin = amountToSend.mul(priceFeed).div(oracleValueDivisor).mul(100-swapSlippage).div(100); // Accounting for slippage
      uint[] memory tradeAmounts = UniSwap.swapExactETHForTokens{value: amountToSend}(amountOutMin, path, address(this), block.timestamp.add(180));
      amountOut = tradeAmounts[tradeAmounts.length - 1];
    }
        function swapETHtoDAI2(uint amountToSend, uint swapSlippage) public returns (uint256 amountOut) {
      require(0 < swapSlippage && swapSlippage <= 100, "Slippage out of bounds!");
        address[] memory path = new address[](2);
      path[0] = UniSwap.WETH();
      path[1] = DAI; // DAI
      uint priceFeed = uint(getLatestPrice());
      uint amountOutMin = amountToSend.mul(priceFeed).div(oracleValueDivisor).mul(100-swapSlippage).div(100); // Accounting for slippage
      UniSwap.swapExactETHForTokens{value: amountToSend}(amountOutMin, path, address(this), block.timestamp.add(180));
      TokenInterface intDAI = TokenInterface(DAI);
      amountOut = intDAI.balanceOf(address(this));
    }

            function swapETHtoDAI3(uint amountToSend) public returns (uint256 amountOut) {
        address[] memory path = new address[](2);
      path[0] = UniSwap.WETH();
      path[1] = DAI; // DAI
      UniSwap.swapExactETHForTokens{value: amountToSend}(0, path, address(this), block.timestamp.add(180));
      TokenInterface intDAI = TokenInterface(DAI);
      amountOut = intDAI.balanceOf(address(this));
    }

    function createUniPair() public {
        Factory.createPair(UniSwap.WETH(), DAI);
        UniSwap.addLiquidity(UniSwap.WETH(), DAI, 400000000000000000, 700, 300000000000000000, 500, address(this), 180);
    }


    receive() external payable {}
}


interface UniSwapRouter {
function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
  external
  payable
  returns (uint[] memory amounts);

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
  function WETH() external returns(address);
}
interface UniSwapFactory {
  function getPair(address tokenA, address tokenB) external view returns (address pair);
  function createPair(address tokenA, address tokenB) external returns (address pair);
}
interface TokenInterface {
    function balanceOf(address _address) external view returns(uint balance);
}