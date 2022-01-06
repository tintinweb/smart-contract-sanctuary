// SPDX-License-Identifier: ADD VALID LICENSE
pragma solidity ^0.8.0;

import "./CometStorage.sol";

contract Comet is CometStorage {
    struct Configuration {
        address governor;
        address pauseGuardian;
        address priceOracle;
        address baseToken;
    }

    // Constants for pause flag offsets
    uint8 public immutable pauseSupplyOffset = 0;
    uint8 public immutable pauseTransferOffset = 1;
    uint8 public immutable pauseWithdrawOffset = 2;
    uint8 public immutable pauseAbsorbOffset = 3;
    uint8 public immutable pauseBuyOffset = 4;

    // Configuration constants
    address public immutable governor;
    address public immutable pauseGuardian;
    address public immutable priceOracle;
    address public immutable baseToken;

    constructor(Configuration memory config) {
        // Set configuration variables
        governor = config.governor;
        pauseGuardian = config.pauseGuardian;
        priceOracle = config.priceOracle;
        baseToken = config.baseToken;
    }

    /**
     * @return uint8 representation of the boolean input
     */
    function toUInt8(bool x) private pure returns (uint8) {
        return x ? 1 : 0;
    }

    /**
     * @return Boolean representation of the uint8 input
     */
    function toBool(uint8 x) private pure returns (bool) {
        return x != 0;
    }

    /**
     * @notice Pauses different actions within Comet
     * @param supplyPaused Boolean for pausing supply actions
     * @param transferPaused Boolean for pausing transfer actions
     * @param withdrawPaused Boolean for pausing withdraw actions
     * @param absorbPaused Boolean for pausing absorb actions
     * @param buyPaused Boolean for pausing buy actions
     */
    function pause(
        bool supplyPaused,
        bool transferPaused,
        bool withdrawPaused,
        bool absorbPaused,
        bool buyPaused
    ) public {
        require(msg.sender == governor || msg.sender == pauseGuardian, "Unauthorized");

        totals.pauseFlags =
            uint8(0) |
            (toUInt8(supplyPaused) << pauseSupplyOffset) |
            (toUInt8(transferPaused) << pauseTransferOffset) |
            (toUInt8(withdrawPaused) << pauseWithdrawOffset) |
            (toUInt8(absorbPaused) << pauseAbsorbOffset) |
            (toUInt8(buyPaused) << pauseBuyOffset);
    }

    /**
     * @return Whether or not supply actions are paused
     */
    function isSupplyPaused() public view returns (bool) {
        return toBool(totals.pauseFlags & (uint8(1) << pauseSupplyOffset));
    }

    /**
     * @return Whether or not transfer actions are paused
     */
    function isTransferPaused() public view returns (bool) {
        return toBool(totals.pauseFlags & (uint8(1) << pauseTransferOffset));
    }

    /**
     * @return Whether or not withdraw actions are paused
     */
    function isWithdrawPaused() public view returns (bool) {
        return toBool(totals.pauseFlags & (uint8(1) << pauseWithdrawOffset));
    }

    /**
     * @return Whether or not absorb actions are paused
     */
    function isAbsorbPaused() public view returns (bool) {
        return toBool(totals.pauseFlags & (uint8(1) << pauseAbsorbOffset));
    }

    /**
     * @return Whether or not buy actions are paused
     */
    function isBuyPaused() public view returns (bool) {
        return toBool(totals.pauseFlags & (uint8(1) << pauseBuyOffset));
    }
}

// SPDX-License-Identifier: XXX ADD VALID LICENSE
pragma solidity ^0.8.0;

/**
 * @title Compound's Comet Storage Interface
 * @dev Versions can enforce append-only storage slots via inheritance.
 * @author Compound
 */
contract CometStorage {
    // 512 bits total = 2 slots
    struct Totals {
        // 1st slot
        uint96 trackingSupplyIndex;
        uint96 trackingBorrowIndex;
        uint64 baseSupplyIndex;
        // 2nd slot
        uint64 baseBorrowIndex;
        uint72 totalSupplyBase;
        uint72 totalBorrowBase;
        uint40 lastAccrualTime;
        uint8 pauseFlags;
    }
    Totals public totals;
}