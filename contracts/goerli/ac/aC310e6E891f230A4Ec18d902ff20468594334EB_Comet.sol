// SPDX-License-Identifier: ADD VALID LICENSE
pragma solidity ^0.8.0;

import "./CometStorage.sol";

contract Comet is CometStorage {
    struct AssetInfo {
        address asset;
        uint borrowCollateralFactor;
        uint liquidateCollateralFactor;
    }

    struct Configuration {
        address governor;
        address pauseGuardian;
        address priceOracle;
        address baseToken;

        AssetInfo[] assetInfo;
    }

    /// @notice The max number of assets this contract is hardcoded to support
    /// @dev Do not change this variable without updating all the fields throughout the contract.
    uint public constant maxAssets = 2;
    /// @notice The number of assets this contract actually supports
    uint public immutable numAssets;
    /// @notice Offsets for specific actions in the pause flag bit array
    uint8 public constant pauseSupplyOffset = 0;
    uint8 public constant pauseTransferOffset = 1;
    uint8 public constant pauseWithdrawOffset = 2;
    uint8 public constant pauseAbsorbOffset = 3;
    uint8 public constant pauseBuyOffset = 4;

    // Configuration constants
    address public immutable governor;
    address public immutable pauseGuardian;
    address public immutable priceOracle;
    address public immutable baseToken;

    address internal immutable asset00;
    address internal immutable asset01;

    uint internal immutable borrowCollateralFactor00;
    uint internal immutable borrowCollateralFactor01;

    uint internal immutable liquidateCollateralFactor00;
    uint internal immutable liquidateCollateralFactor01;

    // Storage
    mapping(address => mapping(address => bool)) public isAllowed;

    constructor(Configuration memory config) {
        require(config.assetInfo.length <= maxAssets, "too many asset configs");

         // Set configuration variables
        governor = config.governor;
        pauseGuardian = config.pauseGuardian;
        priceOracle = config.priceOracle;
        baseToken = config.baseToken;

        // Set asset info
        numAssets = config.assetInfo.length;

        asset00 = _getAsset(config.assetInfo, 0).asset;
        asset01 = _getAsset(config.assetInfo, 1).asset;

        borrowCollateralFactor00 = _getAsset(config.assetInfo, 0).borrowCollateralFactor;
        borrowCollateralFactor01 = _getAsset(config.assetInfo, 1).borrowCollateralFactor;

        liquidateCollateralFactor00 = _getAsset(config.assetInfo, 0).liquidateCollateralFactor;
        liquidateCollateralFactor01 = _getAsset(config.assetInfo, 1).liquidateCollateralFactor;
    }

    function _getAsset(AssetInfo[] memory assetInfo, uint i) internal pure returns (AssetInfo memory) {
        if (i < assetInfo.length)
            return assetInfo[i];
        return AssetInfo({
            asset: address(0),
            borrowCollateralFactor: uint256(0),
            liquidateCollateralFactor: uint256(0)
        });
    }

    /**
     * @notice Get the i-th asset info, according to the order they were passed in originally
     * @param i The index of the asset info to get
     * @return The asset info object
     */
    function getAssetInfo(uint i) public view returns (AssetInfo memory) {
        require(i < numAssets, "asset info not found");

        if (i == 0) return AssetInfo({asset: asset00, borrowCollateralFactor: borrowCollateralFactor00, liquidateCollateralFactor: liquidateCollateralFactor00 });
        if (i == 1) return AssetInfo({asset: asset01, borrowCollateralFactor: borrowCollateralFactor01, liquidateCollateralFactor: liquidateCollateralFactor01 });
        revert("absurd");
    }

    function assets() public view returns (AssetInfo[] memory) {
        AssetInfo[] memory result = new AssetInfo[](numAssets);

        for (uint i = 0; i < numAssets; i++) {
            result[i] = getAssetInfo(i);
        }

        return result;
    }

    function assetAddresses() public view returns (address[] memory) {
        address[] memory result = new address[](numAssets);

        for (uint i = 0; i < numAssets; i++) {
            result[i] = getAssetInfo(i).asset;
        }

        return result;
    }

    function allow(address manager, bool _isAllowed) external {
      allowInternal(msg.sender, manager, _isAllowed);
    }

    function allowInternal(address owner, address manager, bool _isAllowed) internal {
      isAllowed[owner][manager] = _isAllowed;
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
    ) external {
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

    /**
     * @return uint8 representation of the boolean input
     */
    function toUInt8(bool x) internal pure returns (uint8) {
        return x ? 1 : 0;
    }

    /**
     * @return Boolean representation of the uint8 input
     */
    function toBool(uint8 x) internal pure returns (bool) {
        return x != 0;
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