// SPDX-License-Identifier: bsl-1.1

/*
  Copyright 2021 Unit Protocol: Artem Zakharov ([email protected]).
*/
pragma solidity 0.7.6;

pragma experimental ABIEncoderV2;

import "../interfaces/IVaultParameters.sol";
import "../interfaces/vault-managers/parameters/IVaultManagerParameters.sol";
import "../interfaces/vault-managers/parameters/IVaultManagerBorrowFeeParameters.sol";


/**
 * @notice Views collaterals in one request to save node requests and speed up dapps.
 *
 * @dev It makes no sense to clog a node with hundreds of RPC requests and slow a client app/dapp. Since usually
 *      a huge amount of gas is available to node static calls, we can aggregate asset data in a huge batch on the
 *      node's side and pull it to the client.
 */
contract AssetParametersViewer {
    IVaultParameters public immutable vaultParameters;

    IVaultManagerParameters public immutable vaultManagerParameters;
    IVaultManagerBorrowFeeParameters public immutable vaultManagerBorrowFeeParameters;

    struct AssetParameters {
        // asset address
        address asset;

        // Percentage with 3 decimals
        uint stabilityFee;

        // Percentage with 0 decimals
        uint liquidationFee;

        // Percentage with 0 decimals
        uint initialCollateralRatio;

        // Percentage with 0 decimals
        uint liquidationRatio;

        // Percentage with 3 decimals
        uint liquidationDiscount;

        // Devaluation period in blocks
        uint devaluationPeriod;

        // USDP mint limit
        uint tokenDebtLimit;

        // Oracle types enabled for this asset
        uint[] oracles;

        // Percentage with 0 decimals
        uint minColPercent;

        // Percentage with 0 decimals
        uint maxColPercent;

        // Percentage with 2 decimals (basis points)
        uint borrowFee;
    }


    constructor(address _vaultManagerParameters, address _vaultManagerBorrowFeeParameters) {
        IVaultManagerParameters vmp = IVaultManagerParameters(_vaultManagerParameters);
        vaultManagerParameters = vmp;
        vaultParameters = IVaultParameters(vmp.vaultParameters());
        vaultManagerBorrowFeeParameters = IVaultManagerBorrowFeeParameters(_vaultManagerBorrowFeeParameters);
    }

    /**
     * @notice Get parameters of one asset
     * @param asset asset address
     * @param maxOracleTypesToSearch since complete list of oracle types is unknown, we'll check types up to this number
     */
    function getAssetParameters(address asset, uint maxOracleTypesToSearch)
        public
        view
        returns (AssetParameters memory r)
    {
        r.asset = asset;
        r.stabilityFee = vaultParameters.stabilityFee(asset);
        r.liquidationFee = vaultParameters.liquidationFee(asset);

        r.initialCollateralRatio = vaultManagerParameters.initialCollateralRatio(asset);
        r.liquidationRatio = vaultManagerParameters.liquidationRatio(asset);
        r.liquidationDiscount = vaultManagerParameters.liquidationDiscount(asset);
        r.devaluationPeriod = vaultManagerParameters.devaluationPeriod(asset);

        r.tokenDebtLimit = vaultParameters.tokenDebtLimit(asset);

        r.minColPercent = vaultManagerParameters.minColPercent(asset);
        r.maxColPercent = vaultManagerParameters.maxColPercent(asset);

        r.borrowFee = vaultManagerBorrowFeeParameters.getBorrowFee(asset);

        // Memory arrays can't be reallocated so we'll overprovision
        uint[] memory foundOracleTypes = new uint[](maxOracleTypesToSearch);
        uint actualOraclesCount = 0;

        for (uint _type = 0; _type < maxOracleTypesToSearch; ++_type) {
            if (vaultParameters.isOracleTypeEnabled(_type, asset)) {
                foundOracleTypes[actualOraclesCount++] = _type;
            }
        }

        r.oracles = new uint[](actualOraclesCount);
        for (uint i = 0; i < actualOraclesCount; ++i) {
            r.oracles[i] = foundOracleTypes[i];
        }
    }

    /**
     * @notice Get parameters of many assets
     * @param assets asset addresses
     * @param maxOracleTypesToSearch since complete list of oracle types is unknown, we'll check types up to this number
     */
    function getMultiAssetParameters(address[] calldata assets, uint maxOracleTypesToSearch)
        external
        view
        returns (AssetParameters[] memory r)
    {
        uint length = assets.length;
        r = new AssetParameters[](length);
        for (uint i = 0; i < length; ++i) {
            r[i] = getAssetParameters(assets[i], maxOracleTypesToSearch);
        }
    }
}

// SPDX-License-Identifier: bsl-1.1

/*
  Copyright 2020 Unit Protocol: Artem Zakharov ([email protected]).
*/
pragma solidity ^0.7.6;

interface IVaultParameters {
    function canModifyVault ( address ) external view returns ( bool );
    function foundation (  ) external view returns ( address );
    function isManager ( address ) external view returns ( bool );
    function isOracleTypeEnabled ( uint256, address ) external view returns ( bool );
    function liquidationFee ( address ) external view returns ( uint256 );
    function setCollateral ( address asset, uint256 stabilityFeeValue, uint256 liquidationFeeValue, uint256 usdpLimit, uint256[] calldata oracles ) external;
    function setFoundation ( address newFoundation ) external;
    function setLiquidationFee ( address asset, uint256 newValue ) external;
    function setManager ( address who, bool permit ) external;
    function setOracleType ( uint256 _type, address asset, bool enabled ) external;
    function setStabilityFee ( address asset, uint256 newValue ) external;
    function setTokenDebtLimit ( address asset, uint256 limit ) external;
    function setVaultAccess ( address who, bool permit ) external;
    function stabilityFee ( address ) external view returns ( uint256 );
    function tokenDebtLimit ( address ) external view returns ( uint256 );
    function vault (  ) external view returns ( address );
    function vaultParameters (  ) external view returns ( address );
}

// SPDX-License-Identifier: bsl-1.1

/*
  Copyright 2020 Unit Protocol: Artem Zakharov ([email protected]).
*/
pragma solidity ^0.7.6;

interface IVaultManagerParameters {
    function devaluationPeriod ( address ) external view returns ( uint256 );
    function initialCollateralRatio ( address ) external view returns ( uint256 );
    function liquidationDiscount ( address ) external view returns ( uint256 );
    function liquidationRatio ( address ) external view returns ( uint256 );
    function maxColPercent ( address ) external view returns ( uint256 );
    function minColPercent ( address ) external view returns ( uint256 );
    function setColPartRange ( address asset, uint256 min, uint256 max ) external;
    function setCollateral (
        address asset,
        uint256 stabilityFeeValue,
        uint256 liquidationFeeValue,
        uint256 initialCollateralRatioValue,
        uint256 liquidationRatioValue,
        uint256 liquidationDiscountValue,
        uint256 devaluationPeriodValue,
        uint256 usdpLimit,
        uint256[] calldata oracles,
        uint256 minColP,
        uint256 maxColP
    ) external;
    function setDevaluationPeriod ( address asset, uint256 newValue ) external;
    function setInitialCollateralRatio ( address asset, uint256 newValue ) external;
    function setLiquidationDiscount ( address asset, uint256 newValue ) external;
    function setLiquidationRatio ( address asset, uint256 newValue ) external;
    function vaultParameters (  ) external view returns ( address );
}

// SPDX-License-Identifier: bsl-1.1

/*
  Copyright 2021 Unit Protocol: Artem Zakharov ([email protected]).
*/
pragma solidity ^0.7.6;

interface IVaultManagerBorrowFeeParameters {

    /**
     * @notice 1 = 100% = 10000 basis points
     **/
    function BASIS_POINTS_IN_1() external view returns (uint);

    /**
     * @notice Borrow fee receiver
     **/
    function feeReceiver() external view returns (address);

    /**
     * @notice Sets the borrow fee receiver. Only manager is able to call this function
     * @param newFeeReceiver The address of fee receiver
     **/
    function setFeeReceiver(address newFeeReceiver) external;

    /**
     * @notice Sets the base borrow fee in basis points (1bp = 0.01% = 0.0001). Only manager is able to call this function
     * @param newBaseBorrowFeeBasisPoints The borrow fee in basis points
     **/
    function setBaseBorrowFee(uint16 newBaseBorrowFeeBasisPoints) external;

    /**
     * @notice Sets the borrow fee for a particular collateral in basis points (1bp = 0.01% = 0.0001). Only manager is able to call this function
     * @param asset The address of the main collateral token
     * @param newEnabled Is custom fee enabled for asset
     * @param newFeeBasisPoints The borrow fee in basis points
     **/
    function setAssetBorrowFee(address asset, bool newEnabled, uint16 newFeeBasisPoints) external;

    /**
     * @notice Returns borrow fee for particular collateral in basis points (1bp = 0.01% = 0.0001)
     * @param asset The address of the main collateral token
     * @return feeBasisPoints The borrow fee in basis points
     **/
    function getBorrowFee(address asset) external view returns (uint16 feeBasisPoints);

    /**
     * @notice Returns borrow fee for usdp amount for particular collateral
     * @param asset The address of the main collateral token
     * @return The borrow fee
     **/
    function calcBorrowFeeAmount(address asset, uint usdpAmount) external view returns (uint);
}