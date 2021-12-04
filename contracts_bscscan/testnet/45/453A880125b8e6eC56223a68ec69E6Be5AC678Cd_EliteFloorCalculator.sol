// SPDX-License-Identifier: U-U-U-UPPPPP!!!
pragma solidity ^0.7.4;

/* ROOTKIT:
A floor calculator to use with ERC31337 AMM pairs
Ensures 100% of accessible funds are backed at all times
*/

import "./IFloorCalculator.sol";
import "./SafeMath.sol";
import "./IPancakeRouter02.sol";
import "./IPancakeFactory.sol";
import "./TokensRecoverable.sol";
import "./EnumerableSet.sol";

contract EliteFloorCalculator is IFloorCalculator, TokensRecoverable {
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    IERC20 immutable rootedToken;
    address immutable rootedElitePair;
    address immutable rootedBasePair;
    IPancakeRouter02 immutable internal pancakeRouter;
    IPancakeFactory immutable internal pancakeFactory;
    EnumerableSet.AddressSet ignoredAddresses;

    constructor(IERC20 _rootedToken, IERC20 _eliteToken, IERC20 _baseToken, IPancakeFactory _pancakeFactory, IPancakeRouter02 _pancakeRouter) {
        rootedToken = _rootedToken;
        pancakeFactory = _pancakeFactory;
        pancakeRouter = _pancakeRouter;

        rootedElitePair = _pancakeFactory.getPair(address(_eliteToken), address(_rootedToken));
        rootedBasePair = _pancakeFactory.getPair(address(_baseToken), address(_rootedToken));
    }    

    function setIgnoreAddresses(address ignoredAddress, bool add) public ownerOnly() {
        if (add) {
            ignoredAddresses.add(ignoredAddress); 
        } else { 
            ignoredAddresses.remove(ignoredAddress); 
        }
    }

    function isIgnoredAddress(address ignoredAddress) public view returns (bool) {
        return ignoredAddresses.contains(ignoredAddress);
    }

    function ignoredAddressCount() public view returns (uint256) {
        return ignoredAddresses.length();
    }

    function ignoredAddressAt(uint256 index) public view returns (address) {
        return ignoredAddresses.at(index);
    }

    function ignoredAddressesTotalBalance() public view returns (uint256) {
        uint256 total = 0;
        for (uint i = 0; i < ignoredAddresses.length(); i++) {
            total = total.add(rootedToken.balanceOf(ignoredAddresses.at(i)));
        }

        return total;
    }

    function calculateSubFloor(IERC20 baseToken, IERC20 eliteToken) public override view returns (uint256) {
        uint256 totalRootedInPairs = rootedToken.balanceOf(rootedElitePair).add(rootedToken.balanceOf(rootedBasePair));
        uint256 totalBaseAndEliteInPairs = eliteToken.balanceOf(rootedElitePair).add(baseToken.balanceOf(rootedBasePair));
        uint256 rootedCirculatingSupply = rootedToken.totalSupply().sub(totalRootedInPairs).sub(ignoredAddressesTotalBalance());
        uint256 amountUntilFloor = pancakeRouter.getAmountOut(rootedCirculatingSupply, totalRootedInPairs, totalBaseAndEliteInPairs);
        uint256 totalExcessInPools = totalBaseAndEliteInPairs.sub(amountUntilFloor);
        uint256 previouslySwept = eliteToken.totalSupply().sub(baseToken.balanceOf(address(eliteToken)));
        
        if (previouslySwept >= totalExcessInPools) { return 0; }
        return totalExcessInPools.sub(previouslySwept);
    }
}