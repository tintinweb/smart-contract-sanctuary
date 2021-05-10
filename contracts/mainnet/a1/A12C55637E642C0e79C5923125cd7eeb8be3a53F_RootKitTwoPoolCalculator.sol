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
import "./IUniswapV2Router02.sol";
import "./TokensRecoverable.sol";
import "./EnumerableSet.sol";

contract RootKitTwoPoolCalculator is IFloorCalculator, TokensRecoverable
{
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    IERC20 immutable rootKit;
    IERC20 immutable keth;
    IERC20 immutable weth;
    address public immutable wethPair;
    address public immutable kethPair;
    IUniswapV2Factory immutable uniswapV2Factory;
    IUniswapV2Router02 immutable uniswapV2Router;
    EnumerableSet.AddressSet ignoredAddresses;

    constructor(IERC20 _rootKit, IERC20 _keth, IERC20 _weth, IUniswapV2Factory _uniswapV2Factory, IUniswapV2Router02 _uniswapV2Router)
    {
        rootKit = _rootKit;
        keth = _keth;
        weth = _weth;
        uniswapV2Factory = _uniswapV2Factory;
        uniswapV2Router = _uniswapV2Router;

        kethPair = _uniswapV2Factory.getPair(address(_keth), address(_rootKit));
        wethPair = _uniswapV2Factory.getPair(address(_weth), address(_rootKit));
    }    

    function setIgnoredAddress(address ignoredAddress, bool add) public ownerOnly()
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
            total = total.add(rootKit.balanceOf(ignoredAddresses.at(i)));
        }

        return total;
    }

        // returns the amount currently available to be swept
    function calculateSubFloor(IERC20 wrappedToken, IERC20 backingToken) public override view returns (uint256) // backing token = keth
    {
        uint256 totalRootInPairs = rootKit.balanceOf(kethPair).add(rootKit.balanceOf(wethPair));
        uint256 totalBaseAndEliteInPairs = backingToken.balanceOf(kethPair).add(wrappedToken.balanceOf(wethPair));
        uint256 rootKitCirculatingSupply = rootKit.totalSupply().sub(totalRootInPairs).sub(ignoredAddressesTotalBalance());

        uint256 amountUntilFloor = uniswapV2Router.getAmountOut(rootKitCirculatingSupply, totalRootInPairs, totalBaseAndEliteInPairs) * 100 / 94; //includes burn
        uint256 totalExcessInPools = totalBaseAndEliteInPairs.sub(amountUntilFloor);
        uint256 previouslySwept = backingToken.totalSupply().sub(wrappedToken.balanceOf(address(backingToken)));

        if (previouslySwept >= totalExcessInPools) { return 0; }

        return totalExcessInPools.sub(previouslySwept);
    }


    function getAbsoluteFloorPrice() public view returns (uint256)
    {
        uint256 totalRootInPairs = rootKit.balanceOf(kethPair).add(rootKit.balanceOf(wethPair));
        uint256 totalBaseAndEliteInPairs = keth.balanceOf(kethPair).add(weth.balanceOf(wethPair));
        uint256 rootKitCirculatingSupply = rootKit.totalSupply().sub(totalRootInPairs).sub(ignoredAddressesTotalBalance());

        uint256 amountUntilFloor = uniswapV2Router.getAmountOut(rootKitCirculatingSupply, totalRootInPairs, totalBaseAndEliteInPairs) * 100 / 94;
        uint256 totalExcessInPools = totalBaseAndEliteInPairs.sub(amountUntilFloor);
        uint256 newTotalRootInPairs = totalRootInPairs + rootKitCirculatingSupply * 100 / 94;

        uint256 priceForOneRootIfZeroHolders = uniswapV2Router.getAmountIn(1e18, totalExcessInPools, newTotalRootInPairs);

        return priceForOneRootIfZeroHolders;
    }
}