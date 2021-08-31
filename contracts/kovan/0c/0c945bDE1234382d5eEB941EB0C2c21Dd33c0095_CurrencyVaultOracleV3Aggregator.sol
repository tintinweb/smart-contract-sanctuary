/**
 *Submitted for verification at Etherscan.io on 2021-08-31
*/

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity >=0.6.0;

/// @title IFundValueCalculator interface
/// @author Enzyme Council <[email protected]>
interface IFundValueCalculator {
    function calcGav(address _vaultProxy)
        external
        returns (address denominationAsset_, uint256 gav_);

    function calcGrossShareValue(address _vaultProxy)
        external
        returns (address denominationAsset_, uint256 grossShareValue_);

    function calcNav(address _vaultProxy)
        external
        returns (address denominationAsset_, uint256 nav_);

    function calcNetShareValue(address _vaultProxy)
        external
        returns (address denominationAsset_, uint256 netShareValue_);

    function calcNetValueForSharesHolder(
        address _vaultProxy,
        address _sharesHolder
    ) external returns (address denominationAsset_, uint256 netValue_);
}

// File: @chainlink/contracts/src/v0.6/interfaces/AggregatorInterface.sol

pragma solidity >=0.6.0;

interface AggregatorInterface {
    function latestAnswer() external view returns (int256);

    function latestTimestamp() external view returns (uint256);

    function latestRound() external view returns (uint256);

    function getAnswer(uint256 roundId) external view returns (int256);

    function getTimestamp(uint256 roundId) external view returns (uint256);

    event AnswerUpdated(
        int256 indexed current,
        uint256 indexed roundId,
        uint256 updatedAt
    );
    event NewRound(
        uint256 indexed roundId,
        address indexed startedBy,
        uint256 startedAt
    );
}

// File: @chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol

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

// File: @chainlink/contracts/src/v0.6/interfaces/AggregatorV2V3Interface.sol

pragma solidity >=0.6.0;

interface AggregatorV2V3Interface is
    AggregatorInterface,
    AggregatorV3Interface
{}

// File: @chainlink/contracts/src/v0.6/tests/MockV3Aggregator.sol

pragma solidity >=0.6.0;

/**
 * @title MockV3Aggregator
 * @notice Based on the FluxAggregator contract
 * @notice Use this contract when you need to test
 * other contract's ability to read data from an
 * aggregator contract, but how the aggregator got
 * its answer is unimportant
 */
contract CurrencyVaultOracleV3Aggregator is AggregatorV2V3Interface {
    uint256 public constant override version = 0;

    uint8 public override decimals;
    int256 public override latestAnswer;
    uint256 public override latestTimestamp;
    uint256 public override latestRound;

    mapping(uint256 => int256) public override getAnswer;
    mapping(uint256 => uint256) public override getTimestamp;
    mapping(uint256 => uint256) private getStartedAt;

    address private vault;
    IFundValueCalculator private valueCalculator;

    constructor(
        uint8 _decimals,
        address _initialCalculator,
        address _vault
    ) public {
        decimals = _decimals;

        vault = _vault;
        valueCalculator = IFundValueCalculator(_initialCalculator);

        updateAnswer(_vault);
    }

    function updateAnswer(address _vault) public {
        (, uint256 _answer) = valueCalculator.calcGrossShareValue(_vault);

        latestAnswer = int256(_answer);
        latestTimestamp = block.timestamp;
        latestRound++;
        getAnswer[latestRound] = int256(_answer);
        getTimestamp[latestRound] = block.timestamp;
        getStartedAt[latestRound] = block.timestamp;
    }

    function updateRoundData(
        uint80 _roundId,
        address _vault,
        uint256 _timestamp,
        uint256 _startedAt
    ) public {
        (, uint256 _answer) = valueCalculator.calcGrossShareValue(_vault);

        latestRound = _roundId;
        latestAnswer = int256(_answer);
        latestTimestamp = _timestamp;
        getAnswer[latestRound] = int256(_answer);
        getTimestamp[latestRound] = _timestamp;
        getStartedAt[latestRound] = _startedAt;
    }

    function getRoundData(uint80 _roundId)
        external
        view
        override
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        return (
            _roundId,
            getAnswer[_roundId],
            getStartedAt[_roundId],
            getTimestamp[_roundId],
            _roundId
        );
    }

    function latestRoundData()
        external
        view
        override
        returns (
            uint80,
            int256,
            uint256,
            uint256,
            uint80
        )
    {
        return (
            uint80(latestRound),
            getAnswer[latestRound],
            getStartedAt[latestRound],
            getTimestamp[latestRound],
            uint80(latestRound)
        );
    }

    function description() external view override returns (string memory) {
        return "v0.6/tests/MockV3Aggregator.sol";
    }
}