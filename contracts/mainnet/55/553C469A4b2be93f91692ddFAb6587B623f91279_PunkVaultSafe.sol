// SPDX-License-Identifier: MIT

pragma solidity 0.6.8;

import "./PunkVaultBase.sol";
import "./EnumerableSet.sol";
import "./ReentrancyGuard.sol";

contract PunkVaultSafe is PunkVaultBase, ReentrancyGuard {
    using EnumerableSet for EnumerableSet.UintSet;
    EnumerableSet.UintSet private reserves;
    bool private inSafeMode = true;

    event TokenBurnedSafely(uint256 punkId, address indexed to);

    function getReserves()
        internal
        view
        returns (EnumerableSet.UintSet storage)
    {
        return reserves;
    }

    function getInSafeMode() public view returns (bool) {
        return inSafeMode;
    }

    function turnOffSafeMode() public onlyOwner {
        inSafeMode = false;
    }

    function turnOnSafeMode() public onlyOwner {
        inSafeMode = true;
    }

    modifier whenNotInSafeMode {
        require(!inSafeMode, "Contract is in safe mode");
        _;
    }

    function simpleRedeem() public whenPaused nonReentrant {
        require(
            getERC20().balanceOf(msg.sender) >= 10**18,
            "ERC20 balance too small"
        );
        require(
            getERC20().allowance(msg.sender, address(this)) >= 10**18,
            "ERC20 allowance too small"
        );
        uint256 tokenId = reserves.at(0);
        getERC20().burnFrom(msg.sender, 10**18);
        reserves.remove(tokenId);
        getCPM().transferPunk(msg.sender, tokenId);
        emit TokenBurnedSafely(tokenId, msg.sender);
    }
}
