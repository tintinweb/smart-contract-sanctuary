/**
 *Submitted for verification at Etherscan.io on 2021-10-29
*/

// SPDX-License-Identifier: bsl-1.1

/*
  Copyright 2020 Unit Protocol: Artem Zakharov ([email protected]).
*/
pragma solidity ^0.8.0;

interface IERC20Like {
    function symbol() external view returns (string memory);
    function balanceOf(address) external view returns (uint);
    function decimals() external view returns (uint8);
    function transfer(address, uint256) external returns (bool);
    function transferFrom(address, address, uint256) external returns (bool);
    function totalSupply() external view returns (uint256);
}

/// @title Reader of MetadataOracle core data
interface ICoreMetadataOracleReader {

    struct Quote {
        uint256 price;
        uint32 updateTS;
    }


    /// @notice Gets a list of assets quoted by this oracle.
    function getAssets() external view returns (address[] memory);

    /// @notice Checks if an asset is quoted by this oracle.
    function hasAsset(address asset) external view returns (bool);

    /**
     * @notice Gets last known quotes for the assets.
     * @param assets Assets to query
     * @return quotes Prices and update timestamps for corresponding assets.
     */
    function quoteAssets(address[] calldata assets) external view returns (Quote[] memory quotes);
}


interface IOracleUsd {
    function assetToUsd(address asset, uint256 amount) external view returns (uint256);
}


/// @title MetadataOracle wrapper for Unit protocol
contract UnitMetadataOracle is IOracleUsd {
    ICoreMetadataOracleReader public immutable metadataOracle;
    uint256 public immutable maxPriceAgeSeconds;

    constructor(address metadataOracle_, uint256 maxPriceAgeSeconds_) {
        metadataOracle = ICoreMetadataOracleReader(metadataOracle_);
        maxPriceAgeSeconds = maxPriceAgeSeconds_;
    }

    /**
     * @notice Evaluates the cost of amount of asset in USD.
     * @dev reverts on non-supported asset or stale price.
     * @param asset evaluated asset
     * @param amount amount of asset in the smallest units
     * @return result USD value, scaled by 10**18 * 2**112
     */
    function assetToUsd(address asset, uint256 amount) external view override returns (uint256 result) {
        address[] memory input = new address[](1);
        input[0] = asset;
        ICoreMetadataOracleReader.Quote memory quote = metadataOracle.quoteAssets(input)[0];
        require(block.timestamp - quote.updateTS <= maxPriceAgeSeconds, 'STALE_PRICE');

        uint256 decimals = uint256(IERC20Like(asset).decimals());
        require(decimals < 256);
        int256 scaleDecimals = 18 - int256(decimals);

        result = quote.price * amount;
        if (scaleDecimals > 0)
            result *= uint256(10) ** uint256(scaleDecimals);
        else if (scaleDecimals < 0)
            result /= uint256(10) ** uint256(-scaleDecimals);
    }
}