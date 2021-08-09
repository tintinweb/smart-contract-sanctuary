/**
 *Submitted for verification at polygonscan.com on 2021-08-09
*/

// File: contracts/PHXQuickOracle.sol

pragma solidity >=0.6.0;
interface UniswapV2Router02 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}
contract PHXQuickOracle {
    UniswapV2Router02 public routeV2 = UniswapV2Router02(0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff);
    address public WMATIC = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;
    address public PHX = 0x9C6BfEdc14b5C23E3900889436Edca7805170f01;
    address public USDC= 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
    address[] public path = [PHX,WMATIC,USDC];
    constructor() public {
    } 
    function decimals() external view returns (uint8){
        return 18;
    }
    function description() external view returns (string memory){
        return "PHX";
    }
    function version() external view returns (uint256){
        return 1;
    }

    // getRoundData and latestRoundData should both raise "No data present"
    // if they do not have data to report, instead of returning unset values
    // which could be misinterpreted as actual reported values.
    function getRoundData(uint80 _roundId)
        external
        view
        returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
        ){
        uint[] memory amounts = routeV2.getAmountsOut(1e18,path);
        int256 price = int256(amounts[amounts.length-1]);
        return (0,price,0,0,0);
    }
    function latestRoundData()
        external
        view
        returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
        ){
        uint[] memory amounts = routeV2.getAmountsOut(1e18,path);
        int256 price = int256(amounts[amounts.length-1]);
        return (0,price,0,0,0);
    }

}