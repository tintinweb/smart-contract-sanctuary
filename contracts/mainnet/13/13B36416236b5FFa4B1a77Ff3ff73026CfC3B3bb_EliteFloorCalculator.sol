// SPDX-License-Identifier: P-P-P-PONZO!!!
pragma solidity ^0.7.4;

/* ROOTKIT:
A floor calculator to use with ERC31337 uniswap pairs
Ensures 100% of accessible funds are backed at all times
*/

import "./IFloorCalculator.sol";
import "./SafeMath.sol";
import "./UniswapV2Library.sol";
import "./IUniswapV2Factory.sol";
import "./TokensRecoverable.sol";
import "./EnumerableSet.sol";

contract EliteFloorCalculator is IFloorCalculator, TokensRecoverable
{
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    IERC20 immutable rootedToken;
    IUniswapV2Factory immutable uniswapV2Factory;
    EnumerableSet.AddressSet ignoredAddresses;

    constructor(IERC20 _rootedToken, IUniswapV2Factory _uniswapV2Factory)
    {
        rootedToken = _rootedToken;
        uniswapV2Factory = _uniswapV2Factory;
    }    

    function setIgnoreAddresses(address ignoredAddress, bool add) public ownerOnly()
    {
        if (add) 
        { 
            ignoredAddresses.add(ignoredAddress); 
        } 
        else 
        { 
            ignoredAddresses.remove(ignoredAddress); 
        }
    }

    function isIgnoredAddress(address ignoredAddress) public view returns (bool)
    {
        return ignoredAddresses.contains(ignoredAddress);
    }

    function ignoredAddressCount() public view returns (uint256)
    {
        return ignoredAddresses.length();
    }

    function ignoredAddressAt(uint256 index) public view returns (address)
    {
        return ignoredAddresses.at(index);
    }

    function ignoredAddressesTotalBalance() public view returns (uint256)
    {
        uint256 total = 0;
        for (uint i = 0; i < ignoredAddresses.length(); i++) {
            total = total.add(rootedToken.balanceOf(ignoredAddresses.at(i)));
        }

        return total;
    }

    function calculateExcessInPool(IERC20 token, address pair, uint256 liquidityShare, uint256 rootedTokenotalSupply, uint256 rootedTokenPoolsLiquidity) internal view returns (uint256)
    {
        uint256 freeRootedToken = (rootedTokenotalSupply.sub(rootedTokenPoolsLiquidity)).mul(liquidityShare).div(1e12);

        uint256 sellAllProceeds = 0;
        if (freeRootedToken > 0) {
            address[] memory path = new address[](2);
            path[0] = address(rootedToken);
            path[1] = address(token);
            uint256[] memory amountsOut = UniswapV2Library.getAmountsOut(address(uniswapV2Factory), freeRootedToken, path);
            sellAllProceeds = amountsOut[1];
        }

        uint256 backingInPool = token.balanceOf(pair);
        if (backingInPool <= sellAllProceeds) { return 0; }
        uint256 excessInPool = backingInPool - sellAllProceeds;

        return excessInPool;
    }

    function calculateExcessInPools(IERC20 wrappedToken, IERC20 backingToken) public view returns (uint256)
    {
        address kethPair = UniswapV2Library.pairFor(address(uniswapV2Factory), address(rootedToken), address(backingToken));
        address wethPair = UniswapV2Library.pairFor(address(uniswapV2Factory), address(rootedToken), address(wrappedToken));   
        
        uint256 rootedTokenotalSupply = rootedToken.totalSupply().sub(ignoredAddressesTotalBalance());
        uint256 rootedTokenPoolsLiquidity = rootedToken.balanceOf(kethPair).add(rootedToken.balanceOf(wethPair));
        uint256 ethPoolsLiquidity = backingToken.balanceOf(kethPair).add(wrappedToken.balanceOf(wethPair));

        uint256 rootLiquidityShareInKethPair = rootedToken.balanceOf(kethPair).mul(1e12).div(rootedTokenPoolsLiquidity);
        uint256 kethLiquidityShareInKethPair = backingToken.balanceOf(kethPair).mul(1e12).div(ethPoolsLiquidity);
        uint256 avgLiquidityShareInKethPair = (rootLiquidityShareInKethPair.add(kethLiquidityShareInKethPair)).div(2);
        uint256 one = 1e12;

        uint256 excessInKethPool = calculateExcessInPool(backingToken, kethPair, avgLiquidityShareInKethPair, rootedTokenotalSupply, rootedTokenPoolsLiquidity);
        uint256 excessInWethPool = calculateExcessInPool(wrappedToken, wethPair, (one).sub(avgLiquidityShareInKethPair), rootedTokenotalSupply, rootedTokenPoolsLiquidity);
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