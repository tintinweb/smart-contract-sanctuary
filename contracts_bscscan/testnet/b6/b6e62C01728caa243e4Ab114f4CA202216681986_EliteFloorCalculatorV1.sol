// SPDX-License-Identifier: U-U-U-UPPPPP!!!
pragma solidity ^0.7.4;

/* ROOTKIT:
A floor calculator to use with ERC31337 AMM pairs
Ensures 100% of accessible funds are backed at all times
*/

import "./IFloorCalculator.sol";
import "./SafeMath.sol";
import "./PancakeLibrary.sol";
import "./IPancakeFactory.sol";
import "./TokensRecoverable.sol";
import "./EnumerableSet.sol";

contract EliteFloorCalculatorV1 is IFloorCalculator, TokensRecoverable
{
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    IERC20 immutable rootedToken;
    IPancakeFactory immutable pancakeFactory;
    EnumerableSet.AddressSet ignoredAddresses;

    constructor(IERC20 _rootedToken, IPancakeFactory _pancakeFactory)
    {
        rootedToken = _rootedToken;
        pancakeFactory = _pancakeFactory;
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
        for (uint i = 0; i < ignoredAddresses.length(); i++) 
        {
            total = total.add(rootedToken.balanceOf(ignoredAddresses.at(i)));
        }

        return total;
    }

    function calculateExcessInPool(IERC20 token, address pair, uint256 liquidityShare, uint256 rootedTokenTotalSupply, uint256 rootedTokenPoolsLiquidity) internal view returns (uint256)
    {
        uint256 freeRootedToken = (rootedTokenTotalSupply.sub(rootedTokenPoolsLiquidity)).mul(liquidityShare).div(1e12);

        uint256 sellAllProceeds = 0;
        if (freeRootedToken > 0) 
        {
            address[] memory path = new address[](2);
            path[0] = address(rootedToken);
            path[1] = address(token);
            uint256[] memory amountsOut = PancakeLibrary.getAmountsOut(address(pancakeFactory), freeRootedToken, path);
            sellAllProceeds = amountsOut[1];
        }

        uint256 backingInPool = token.balanceOf(pair);
        if (backingInPool <= sellAllProceeds) { return 0; }
        uint256 excessInPool = backingInPool - sellAllProceeds;

        return excessInPool;
    }

    function calculateExcessInPools(IERC20 baseToken, IERC20 eliteToken) public view returns (uint256)
    {
        address rootedElitePair = PancakeLibrary.pairFor(address(pancakeFactory), address(rootedToken), address(eliteToken));
        address rootedBasePair = PancakeLibrary.pairFor(address(pancakeFactory), address(rootedToken), address(baseToken));   
        
        uint256 rootedTokenTotalSupply = rootedToken.totalSupply().sub(ignoredAddressesTotalBalance());
        uint256 rootedTokenPoolsLiquidity = rootedToken.balanceOf(rootedElitePair).add(rootedToken.balanceOf(rootedBasePair));
        uint256 baseTokenPoolsLiquidity = eliteToken.balanceOf(rootedElitePair).add(baseToken.balanceOf(rootedBasePair));

        uint256 rootedLiquidityShareInElitePair = rootedToken.balanceOf(rootedElitePair).mul(1e12).div(rootedTokenPoolsLiquidity);
        uint256 eliteLiquidityShareInElitePair = eliteToken.balanceOf(rootedElitePair).mul(1e12).div(baseTokenPoolsLiquidity);
        uint256 avgLiquidityShareInElitePair = (rootedLiquidityShareInElitePair.add(eliteLiquidityShareInElitePair)).div(2);
        uint256 one = 1e12;

        uint256 excessInElitePool = calculateExcessInPool(eliteToken, rootedElitePair, avgLiquidityShareInElitePair, rootedTokenTotalSupply, rootedTokenPoolsLiquidity);
        uint256 excessInBasePool = calculateExcessInPool(baseToken, rootedBasePair, (one).sub(avgLiquidityShareInElitePair), rootedTokenTotalSupply, rootedTokenPoolsLiquidity);
        return excessInElitePool.add(excessInBasePool);
    }

    function calculateSubFloor(IERC20 baseToken, IERC20 eliteToken) public override view returns (uint256)
    {        
        uint256 excessInPools = calculateExcessInPools(baseToken, eliteToken);

        uint256 requiredBacking = eliteToken.totalSupply().sub(excessInPools);
        uint256 currentBacking = baseToken.balanceOf(address(eliteToken));
        if (requiredBacking >= currentBacking) { return 0; }
        return currentBacking - requiredBacking;
    }
}