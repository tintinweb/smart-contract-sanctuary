/**
 *Submitted for verification at Etherscan.io on 2021-03-25
*/

/*
 * Origin Protocol
 * https://originprotocol.com
 *
 * Released under the MIT license
 * https://github.com/OriginProtocol/origin-dollar
 *
 * Copyright 2020 Origin Protocol, Inc
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */
// File: contracts/interfaces/chainlink/AggregatorV3Interface.sol

pragma solidity ^0.5.11;

interface AggregatorV3Interface {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    // getRoundData and latestRoundData should both raise "No data present"
    // if they do not have data to report, instead of returning unset values
    // which could be misinterpreted as actual reported values.
    function getRoundData(uint80 _roundId)
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

// File: contracts/interfaces/IOracle.sol

pragma solidity 0.5.11;

interface IOracle {
    /**
     * @dev returns the asset price in USD, 8 decimal digits.
     */
    function price(address asset) external view returns (uint256);
}

// File: contracts/oracle/OracleRouter.sol

pragma solidity 0.5.11;


contract OracleRouterBase is IOracle {
    uint256 constant MIN_DRIFT = uint256(70000000);
    uint256 constant MAX_DRIFT = uint256(130000000);

    /**
     * @dev The price feed contract to use for a particular asset.
     * @param asset address of the asset
     */
    function feed(address asset) internal view returns (address);

    /**
     * @notice Returns the total price in 8 digit USD for a given asset.
     * @param asset address of the asset
     * @return uint256 USD price of 1 of the asset, in 8 decimal fixed
     */
    function price(address asset) external view returns (uint256) {
        address _feed = feed(asset);
        require(_feed != address(0), "Asset not available");
        (
            uint80 roundID,
            int256 _iprice,
            uint256 startedAt,
            uint256 timeStamp,
            uint80 answeredInRound
        ) = AggregatorV3Interface(_feed).latestRoundData();
        uint256 _price = uint256(_iprice);
        require(_price <= MAX_DRIFT, "Oracle: Price exceeds max");
        require(_price >= MIN_DRIFT, "Oracle: Price under min");
        return uint256(_price);
    }
}

contract OracleRouter is OracleRouterBase {
    /**
     * @dev The price feed contract to use for a particular asset.
     * @param asset address of the asset
     */
    function feed(address asset) internal view returns (address) {
        // DAI
        if (asset == address(0x6B175474E89094C44Da98b954EedeAC495271d0F)) {
            return address(0xAed0c38402a5d19df6E4c03F4E2DceD6e29c1ee9);
            // USDC
        } else if (
            asset == address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48)
        ) {
            return address(0x8fFfFfd4AfB6115b954Bd326cbe7B4BA576818f6);
            // USDT
        } else if (
            asset == address(0xdAC17F958D2ee523a2206206994597C13D831ec7)
        ) {
            return address(0x3E7d1eAB13ad0104d2750B8863b489D65364e32D);
        } else {
            require(false, "Asset not available");
        }
    }
}

contract OracleRouterDev is OracleRouterBase {
    mapping(address => address) public assetToFeed;

    function setFeed(address _asset, address _feed) external {
        assetToFeed[_asset] = _feed;
    }

    /**
     * @dev The price feed contract to use for a particular asset.
     * @param asset address of the asset
     */
    function feed(address asset) internal view returns (address) {
        return assetToFeed[asset];
    }
}