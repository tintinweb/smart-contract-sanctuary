// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

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

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.6;

interface IPriceOracle {
    function getPrice() external view returns (uint256);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.6;

import "../interfaces/IPriceOracle.sol";
import "../interfaces/AggregatorV3Interface.sol";

/// @title Implementation of an Oracle using ChainLink aggregators as a data source
contract ChainlinkOracle is IPriceOracle {
    AggregatorV3Interface public oracle;

    constructor (address oracleAddr) {
        require(oracleAddr != address(0), "oracle cannot be 0x0");
        oracle = AggregatorV3Interface(oracleAddr);
    }

    function getPrice() public view override returns (uint256) {
        (, int price, , ,) = oracle.latestRoundData();

        return uint256(price);
    }
}

