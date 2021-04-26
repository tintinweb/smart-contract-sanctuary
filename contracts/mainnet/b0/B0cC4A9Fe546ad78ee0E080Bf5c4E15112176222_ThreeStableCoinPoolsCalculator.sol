// SPDX-License-Identifier: U-U-U-UPPPPP!!!
pragma solidity ^0.7.4;

/* ROOTKIT:
A floor calculator to use with ERC31337 AMM pairs
Ensures 100% of accessible funds are backed at all times
*/

import "./IERC20.sol";
import "./SafeMath.sol";
import "./EnumerableSet.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router02.sol";
import "./TokensRecoverable.sol";
import "./IFloorCalculator.sol";

contract ThreeStableCoinPoolsCalculator is IFloorCalculator, TokensRecoverable
{
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    IERC20 immutable rootedToken;
    IERC20 immutable fiatToken;
    address immutable rootedElitePair;
    address immutable rootedBasePair;
    address immutable rootedFiatPair;
    IUniswapV2Router02 immutable uniswapV2Router;
    EnumerableSet.AddressSet ignoredAddresses;

    constructor(IERC20 _rootedToken, IERC20 _eliteToken, IERC20 _baseToken, IERC20 _fiatToken, IUniswapV2Factory _uniswapV2Factory, IUniswapV2Router02 _uniswapV2Router)
    {
        rootedToken = _rootedToken;
        fiatToken = _fiatToken;
        uniswapV2Router = _uniswapV2Router;

        address _rootedElitePair = _uniswapV2Factory.getPair(address(_eliteToken), address(_rootedToken));
        rootedElitePair = _rootedElitePair;
        address _rootedBasePair = _uniswapV2Factory.getPair(address(_baseToken), address(_rootedToken));
        rootedBasePair = _rootedBasePair;
        address _rootedFiatPair = _uniswapV2Factory.getPair(address(_fiatToken), address(_rootedToken));
        rootedFiatPair = _rootedFiatPair;
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

    function calculateSubFloor(IERC20 baseToken, IERC20 eliteToken) public override view returns (uint256)
    {
        uint256 totalRootedInPairs = rootedToken.balanceOf(rootedElitePair).add(rootedToken.balanceOf(rootedBasePair)).add(rootedToken.balanceOf(rootedFiatPair));
        uint256 totalStableInPairs = eliteToken.balanceOf(rootedElitePair).add(baseToken.balanceOf(rootedBasePair)).add(fiatToken.balanceOf(rootedFiatPair).div(1e12));
        uint256 rootedCirculatingSupply = rootedToken.totalSupply().sub(totalRootedInPairs).sub(ignoredAddressesTotalBalance());
        uint256 amountUntilFloor = uniswapV2Router.getAmountOut(rootedCirculatingSupply, totalRootedInPairs, totalStableInPairs);

        uint256 totalExcessInPools = totalStableInPairs.sub(amountUntilFloor);
        uint256 previouslySwept = eliteToken.totalSupply().sub(baseToken.balanceOf(address(eliteToken)));
        
        if (previouslySwept >= totalExcessInPools) { return 0; }

        return totalExcessInPools.sub(previouslySwept);
    }
}