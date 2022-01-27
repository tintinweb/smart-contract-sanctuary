// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

import "../interfaces/chainlink/AggregatorV3Interface.sol";
import { IOracle } from "../interfaces/IOracle.sol";
import { Helpers } from "../utils/Helpers.sol";

abstract contract OracleRouterBase is IOracle {
    uint256 constant MIN_DRIFT = uint256(70000000);
    uint256 constant MAX_DRIFT = uint256(130000000);

    /**
     * @dev The price feed contract to use for a particular asset.
     * @param asset address of the asset
     * @return address address of the price feed for the asset
     */
    function feed(address asset) internal view virtual returns (address);

    /**
     * @notice Returns the total price in 8 digit USD for a given asset.
     * @param asset address of the asset
     * @return uint256 USD price of 1 of the asset, in 8 decimal fixed
     */
    function price(address asset) external view override returns (uint256) {
        address _feed = feed(asset);

        require(_feed != address(0), "Asset not available");
        (, int256 _iprice, , , ) = AggregatorV3Interface(_feed)
            .latestRoundData();
        uint256 _price = uint256(_iprice);
        if (isStablecoin(asset)) {
            require(_price <= MAX_DRIFT, "Oracle: Price exceeds max");
            require(_price >= MIN_DRIFT, "Oracle: Price under min");
        }
        return uint256(_price);
    }

    function isStablecoin(address _asset) internal view returns (bool) {
        string memory symbol = Helpers.getSymbol(_asset);
        bytes32 symbolHash = keccak256(abi.encodePacked(symbol));
        return
            symbolHash == keccak256(abi.encodePacked("DAI")) ||
            symbolHash == keccak256(abi.encodePacked("USDC")) ||
            symbolHash == keccak256(abi.encodePacked("USDT"));
    }
}

contract OracleRouter is OracleRouterBase {
    /**
     * @dev The price feed contract to use for a particular asset.
     * @param asset address of the asset
     */
    function feed(address asset) internal pure override returns (address) {
        // DAI
        if (asset == address(0xd586E7F844cEa2F87f50152665BCbc2C279D8d70)) {
            // Chainlink: DAI/USD
            return address(0x51D7180edA2260cc4F6e4EebB82FEF5c3c2B8300);
        } else if (
            // USDCe
            asset == address(0xA7D7079b0FEaD91F3e65f86E8915Cb59c1a4C664)
        ) {
            // Chainlink: USDC/USD
            return address(0xF096872672F44d6EBA71458D74fe67F9a77a23B9);
        } else if (
            // USDTe
            asset == address(0xc7198437980c041c805A1EDcbA50c1Ce5db95118)
        ) {
            // Chainlink: USDT/USD
            return address(0xEBE676ee90Fe1112671f19b6B7459bC678B67e8a);
        } else if (
            // WAVAX
            asset == address(0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7)
        ) {
            // Chainlink: WAVAX/USD
            return address(0x0A77230d17318075983913bC2145DB16C7366156);
        } else {
            revert("Asset not available");
        }
    }
}

contract OracleRouterTestnet is OracleRouterBase {
    /**
     * @dev The price feed contract to use for a particular asset. Testnet hacks.
     * @param asset address of the asset
     */
    function feed(address asset) internal pure override returns (address) {
        // DAI
        if (asset == address(0x51BC2DfB9D12d9dB50C855A5330fBA0faF761D15)) {
            // Chainlink: USDT/USD ~1
            return address(0x7898AcCC83587C3C55116c5230C17a6Cd9C71bad);
        } else if (
            // rando USDC
            asset == address(0x3a9fC2533eaFd09Bc5C36A7D6fdd0C664C81d659)
        ) {
            // Chainlink: USDT/USD ~1
            return address(0x7898AcCC83587C3C55116c5230C17a6Cd9C71bad);
        } else if (
            // USDTe
            asset == address(0x02823f9B469960Bb3b1de0B3746D4b95B7E35543)
        ) {
            // Chainlink: USDT/USD ~1
            return address(0x7898AcCC83587C3C55116c5230C17a6Cd9C71bad);
        } else if (
            // WAVAX
            asset == address(0xd00ae08403B9bbb9124bB305C09058E32C39A48c)
        ) {
            // Chainlink: WAVAX/USD
            return address(0x5498BB86BC934c8D34FDA08E81D444153d0D06aD);
        } else {
            revert("Asset not available");
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
    function feed(address asset) internal view override returns (address) {
        return assetToFeed[asset];
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

interface IOracle {
    /**
     * @dev returns the asset price in USD, 8 decimal digits.
     */
    function price(address asset) external view returns (uint256);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

import { IBasicToken } from "../interfaces/IBasicToken.sol";

library Helpers {
    /**
     * @notice Fetch the `symbol()` from an ERC20 token
     * @dev Grabs the `symbol()` from a contract
     * @param _token Address of the ERC20 token
     * @return string Symbol of the ERC20 token
     */
    function getSymbol(address _token) internal view returns (string memory) {
        string memory symbol = IBasicToken(_token).symbol();
        return symbol;
    }

    /**
     * @notice Fetch the `decimals()` from an ERC20 token
     * @dev Grabs the `decimals()` from a contract and fails if
     *      the decimal value does not live within a certain range
     * @param _token Address of the ERC20 token
     * @return uint256 Decimals of the ERC20 token
     */
    function getDecimals(address _token) internal view returns (uint256) {
        uint256 decimals = IBasicToken(_token).decimals();
        require(
            decimals >= 4 && decimals <= 18,
            "Token must have sufficient decimal places"
        );

        return decimals;
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

interface IBasicToken {
    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}