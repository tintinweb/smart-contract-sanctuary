// SPDX-License-Identifier: J-J-J-JENGA!!!
pragma solidity ^0.7.4;

/* ROOTKIT:
A floor calculator (to use with ERC31337) for EVN uniswap pairs
Ensures 100% of accessible funds are backed at all times

Calculator with extra features
- Checks floor by selling some of the total into different pools based on current liquidity
- result will change slightly 

*/

import "./IFloorCalculator.sol";
import "./SafeMath.sol";
import "./UniswapV2Library.sol";
import "./IUniswapV2Factory.sol";
import "./TokensRecoverable.sol";

contract EvnTwoPoolCalculator is IFloorCalculator, TokensRecoverable
{
    using SafeMath for uint256;

    IERC20 immutable evnToken;
    IUniswapV2Factory immutable uniswapV2Factory;


    constructor(IERC20 _evn, IUniswapV2Factory _uniswapV2Factory)
    {
        evnToken = _evn;
        uniswapV2Factory = _uniswapV2Factory;
    }    


    function calculateExcessInPool(IERC20 token, address pair, uint256 liquidityShare, uint256 evnTotalSupply, uint256 evnPoolsLiquidity) internal view returns (uint256)
    {
        uint256 freeEVN = (evnTotalSupply.sub(evnPoolsLiquidity)).mul(liquidityShare).div(1e18);

        uint256 sellAllProceeds = 0;
        if (freeEVN > 0) {
            address[] memory path = new address[](2);
            path[0] = address(evnToken);
            path[1] = address(token);
            uint256[] memory amountsOut = UniswapV2Library.getAmountsOut(address(uniswapV2Factory), freeEVN, path);
            sellAllProceeds = amountsOut[1];
        }

        uint256 backingInPool = token.balanceOf(pair);
        if (backingInPool <= sellAllProceeds) { return 0; }
        uint256 excessInPool = backingInPool - sellAllProceeds;

        return excessInPool;
    }

    function calculateExcessInPools(IERC20 wrappedToken, IERC20 backingToken) public view returns (uint256)
    {
        address tethPair = UniswapV2Library.pairFor(address(uniswapV2Factory), address(evnToken), address(backingToken));
        address wethPair = UniswapV2Library.pairFor(address(uniswapV2Factory), address(evnToken), address(wrappedToken));   
        
        uint256 evnTokenTotalSupply = evnToken.totalSupply();
        uint256 evnTokenPoolsLiquidity = evnToken.balanceOf(tethPair).add(evnToken.balanceOf(wethPair));
        uint256 ethPoolsLiquidity = backingToken.balanceOf(tethPair).add(wrappedToken.balanceOf(wethPair));

        uint256 rootLiquidityShareIntethPair = evnToken.balanceOf(tethPair).mul(1e18).div(evnTokenPoolsLiquidity);
        uint256 tethLiquidityShareIntethPair = backingToken.balanceOf(tethPair).mul(1e18).div(ethPoolsLiquidity);
        uint256 avgLiquidityShareIntethPair = (rootLiquidityShareIntethPair.add(tethLiquidityShareIntethPair)).div(2);
        uint256 one = (1e18);

        uint256 excessIntethPool = calculateExcessInPool(backingToken, tethPair, avgLiquidityShareIntethPair, evnTokenTotalSupply, evnTokenPoolsLiquidity);
        uint256 excessInWethPool = calculateExcessInPool(wrappedToken, wethPair, (one).sub(avgLiquidityShareIntethPair), evnTokenTotalSupply, evnTokenPoolsLiquidity);
        return excessIntethPool.add(excessInWethPool);
    }

    // When the floor is calculated from 2 pools it will return 0 if "available to sweep (sub floor)" is
    // greater than the "wETH in tETH the contract (current backing)" Move liquidity wETH > tETH to solve
    function calculateSubFloor(IERC20 wrappedToken, IERC20 backingToken) public override view returns (uint256) // backing token = teth
    {        
        uint256 excessInPools = calculateExcessInPools(wrappedToken, backingToken);

        uint256 requiredBacking = backingToken.totalSupply().sub(excessInPools);
        uint256 currentBacking = wrappedToken.balanceOf(address(backingToken));
        if (requiredBacking >= currentBacking) { return 0; }
        return currentBacking - requiredBacking;
    }
}