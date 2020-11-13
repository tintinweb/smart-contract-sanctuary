// SPDX-License-Identifier: MIT

pragma solidity ^0.6.8;

import "./Context.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./SafeERC20.sol";

interface SAFE {
  function balanceOf(address owner) external view returns (uint256);
}

interface SAFE2 {
  function mint(address account, uint256 amount) external;
}

/**
 * @title SAFE2 Migration
 * @dev SAFE2 Mintable Token with migration from legacy contract. Used as an inbetween for COVER.
 */
contract Migration is Context, Ownable {
    using SafeMath for uint256;

    address public safe;

    address public safe2;

    uint256 public constant migrationDuration = 5 days; // 10/01/2020 @ 12:00am (UTC)

    uint256 public constant startTime = 1601078400; // set to now for testing 09/26/2020 @ 12:00am (UTC)

    constructor(address _safe, address _safe2) public {
        require(_safe != address(0), "Cannot set SAFE as 0");
        require(_safe2 != address(0), "Cannot set SAFE2 as 0");
        safe = _safe;
        safe2 = _safe2;
    }

    /**
     * @dev Migrate a users' entire balance
     *
     * One way function. SAFE1 tokens are BURNED. SAFE2 tokens are minted.
     */
    function migrate() external {
        require(block.timestamp >= startTime, "SAFE2 migration has not started");
        require(block.timestamp < startTime + migrationDuration, "SAFE2 migration has ended");

        // Current balance of SAFE for user.
        uint256 safeBalance = SAFE(safe).balanceOf(_msgSender());

        // Make sure we don't migrate 0 balance.
        require(safeBalance > 0, "No SAFE");


        // BURN SAFE1 - UNRECOVERABLE.
        SafeERC20.safeTransferFrom(
            IERC20(safe),
            _msgSender(),
            0x000000000000000000000000000000000000dEaD,
            safeBalance
        );

        // Mint new SAFE2 for the user.
        SAFE2(safe2).mint(_msgSender(), safeBalance);
    }
}