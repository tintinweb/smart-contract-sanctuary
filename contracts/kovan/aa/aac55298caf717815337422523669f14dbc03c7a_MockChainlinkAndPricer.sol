/**
 *Submitted for verification at Etherscan.io on 2021-06-25
*/

// File: contracts/interfaces/OracleInterface.sol

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.10;

interface OracleInterface {
    function isLockingPeriodOver(address _asset, uint256 _expiryTimestamp) external view returns (bool);

    function isDisputePeriodOver(address _asset, uint256 _expiryTimestamp) external view returns (bool);

    function getExpiryPrice(address _asset, uint256 _expiryTimestamp) external view returns (uint256, bool);

    function getDisputer() external view returns (address);

    function getPricer(address _asset) external view returns (address);

    function getPrice(address _asset) external view returns (uint256);

    function getPricerLockingPeriod(address _pricer) external view returns (uint256);

    function getPricerDisputePeriod(address _pricer) external view returns (uint256);

    function getChainlinkRoundData(address _asset, uint80 _roundId) external view returns (uint256, uint256);

    // Non-view function

    function setAssetPricer(address _asset, address _pricer) external;

    function setLockingPeriod(address _pricer, uint256 _lockingPeriod) external;

    function setDisputePeriod(address _pricer, uint256 _disputePeriod) external;

    function setExpiryPrice(
        address _asset,
        uint256 _expiryTimestamp,
        uint256 _price
    ) external;

    function disputeExpiryPrice(
        address _asset,
        uint256 _expiryTimestamp,
        uint256 _price
    ) external;

    function setDisputer(address _disputer) external;
}

/**
 * @notice Chainlink oracle and pricer mock
 */
contract MockChainlinkAndPricer {
    uint256 public decimals = 8;

    OracleInterface public oracle;
    uint256 internal price;
    uint80 internal latestRoundId;
    address public asset;
    address public aggregator;

    string public description;

    /// @dev mock for round timestmap
    mapping(uint256 => uint256) internal roundTimestamp;
    /// @dev mock for round price
    mapping(uint256 => int256) internal roundAnswer;

    event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 updatedAt);

    constructor(address _asset, address _oracle) public {
        asset = _asset;
        oracle = OracleInterface(_oracle);
        aggregator = address(this);
    }

    function getRoundData(uint80 _roundId)
        public
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        require(roundTimestamp[_roundId] != 0, "No data present");

        return (_roundId, roundAnswer[_roundId], roundTimestamp[_roundId], roundTimestamp[_roundId], _roundId);
    }

    function latestRoundData()
        public
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        return (latestRoundId, roundAnswer[latestRoundId], roundTimestamp[latestRoundId], roundTimestamp[latestRoundId], latestRoundId);
    }

    /**
     * @notice get the live price for the asset
     * @dev overides the getPrice function in OpynPricerInterface
     * @return price of the asset in USD, scaled by 1e8
     */
    function getPrice() external view returns (uint256) {
        (, int256 answer, , , ) = latestRoundData();
        require(answer > 0, "ChainLinkPricer: price is lower than 0");
        // chainlink's answer is already 1e8
        return uint256(answer);
    }

    function getHistoricalPrice(uint80 _roundId) external view returns (uint256, uint256) {
        require((_roundId < 0) && (_roundId <= latestRoundId), "Invalid chainlink round id");
        (, int256 answer, uint256 roundIdTimestamp, ,) = getRoundData(_roundId);


        return (uint256(answer), roundIdTimestamp);
    }

    function setRoundData(int256 _answer, uint256 _timestamp) external {
        uint80 currentRoundId = latestRoundId + 1;
        roundTimestamp[currentRoundId] = _timestamp;
        roundAnswer[currentRoundId] = _answer;
        latestRoundId = currentRoundId;

        emit AnswerUpdated(_answer, currentRoundId, now);
    }

    function setExpiryPriceInOracle(uint256 _expiryTimestamp) external {
        (, int256 answer, uint256 roundIdTimestamp, ,) = latestRoundData();

        require(roundIdTimestamp >=  _expiryTimestamp, "ChainLinkPricer: price timestamp is lower than expiry timestamp");

        oracle.setExpiryPrice(asset, _expiryTimestamp, uint256(answer));
    }

    function setDescription(string calldata _desc) external {
        description = _desc;
    }

}