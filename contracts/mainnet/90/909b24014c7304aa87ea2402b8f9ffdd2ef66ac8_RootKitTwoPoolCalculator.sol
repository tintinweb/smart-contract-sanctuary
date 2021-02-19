// SPDX-License-Identifier: J-J-J-JENGA!!!
pragma solidity ^0.7.4;

/* ROOTKIT:
A floor calculator (to use with ERC31337) for RootKit uniswap pairs
Ensures 100% of accessible funds are backed at all times
*/

import "./IFloorCalculator.sol";
import "./RootKit.sol";
import "./SafeMath.sol";
import "./UniswapV2Library.sol";
import "./IUniswapV2Factory.sol";
import "./TokensRecoverable.sol";

contract RootKitTwoPoolCalculator is IFloorCalculator, TokensRecoverable
{
    using SafeMath for uint256;
    uint256 public totalIgnored;

    RootKit immutable rootKit;
    IUniswapV2Factory immutable uniswapV2Factory;

    constructor(RootKit _rootKit, IUniswapV2Factory _uniswapV2Factory)
    {
        rootKit = _rootKit;
        uniswapV2Factory = _uniswapV2Factory;
    }    

    function setIgnoredAddresses(address[] memory ignoredAddresses) public ownerOnly()
    {
        totalIgnored = 0;
        for (uint i = 0; i < ignoredAddresses.length; i++) {
            totalIgnored = totalIgnored.add(rootKit.balanceOf(ignoredAddresses[i]));
        }
    }

    function addExtraIgnoreAddress(address extraToIgnore) public ownerOnly(){
        totalIgnored = totalIgnored.add(rootKit.balanceOf(extraToIgnore));
    }

    function calculateExcessInPool(IERC20 token, address pair, uint256 liquidityShare, uint256 rootKitTotalSupply, uint256 rootKitPoolsLiquidity) internal view returns (uint256)
    {
        uint256 freeRootKit = (rootKitTotalSupply.sub(rootKitPoolsLiquidity)).mul(liquidityShare).div(1e12);

        uint256 sellAllProceeds = 0;
        if (freeRootKit > 0) {
            address[] memory path = new address[](2);
            path[0] = address(rootKit);
            path[1] = address(token);
            uint256[] memory amountsOut = UniswapV2Library.getAmountsOut(address(uniswapV2Factory), freeRootKit, path);
            sellAllProceeds = amountsOut[1];
        }

        uint256 backingInPool = token.balanceOf(pair);
        if (backingInPool <= sellAllProceeds) { return 0; }
        uint256 excessInPool = backingInPool - sellAllProceeds;

        return excessInPool;
    }

    function calculateExcessInPools(IERC20 wrappedToken, IERC20 backingToken) public view returns (uint256)
    {
        address kethPair = UniswapV2Library.pairFor(address(uniswapV2Factory), address(rootKit), address(backingToken));
        address wethPair = UniswapV2Library.pairFor(address(uniswapV2Factory), address(rootKit), address(wrappedToken));   
        
        uint256 rootKitTotalSupply = rootKit.totalSupply().sub(totalIgnored);
        uint256 rootKitPoolsLiquidity = rootKit.balanceOf(kethPair).add(rootKit.balanceOf(wethPair));
        uint256 ethPoolsLiquidity = backingToken.balanceOf(kethPair).add(wrappedToken.balanceOf(wethPair));

        uint256 rootLiquidityShareInKethPair = rootKit.balanceOf(kethPair).mul(1e12).div(rootKitPoolsLiquidity);
        uint256 kethLiquidityShareInKethPair = backingToken.balanceOf(kethPair).mul(1e12).div(ethPoolsLiquidity);
        uint256 avgLiquidityShareInKethPair = (rootLiquidityShareInKethPair.add(kethLiquidityShareInKethPair)).div(2);
        uint256 one = 1e12;

        uint256 excessInKethPool = calculateExcessInPool(backingToken, kethPair, avgLiquidityShareInKethPair, rootKitTotalSupply, rootKitPoolsLiquidity);
        uint256 excessInWethPool = calculateExcessInPool(wrappedToken, wethPair, (one).sub(avgLiquidityShareInKethPair), rootKitTotalSupply, rootKitPoolsLiquidity);
        return excessInKethPool.add(excessInWethPool);
    }

    function calculateSubFloor(IERC20 wrappedToken, IERC20 backingToken) public override view returns (uint256) // backing token = keth
    {        
        uint256 excessInPools = calculateExcessInPools(wrappedToken, backingToken);

        uint256 requiredBacking = backingToken.totalSupply().sub(excessInPools);
        uint256 currentBacking = wrappedToken.balanceOf(address(backingToken));
        if (requiredBacking >= currentBacking) { return 0; }
        return currentBacking - requiredBacking;
    }
}