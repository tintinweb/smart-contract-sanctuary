// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

interface IPriceFeed {
    function decimals() external view returns (uint8);

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

    function version() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./IPriceFeed.sol";

contract PriceFeedMock is IPriceFeed {
    uint8 override public decimals;

    uint256 override public version;

    struct Round {
        uint80 roundId;
        int256 answer;
        uint256 startedAt;
        uint256 updatedAt;
        uint80 answeredInRound;
    }

    mapping(uint80 => Round) internal _rounds;

    uint80 public latestRoundId;

    constructor(uint8 _decimals, uint256 _version) public {
        decimals = _decimals;
        version = _version;
    }

    function addRound(
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    ) public {
        _rounds[++latestRoundId] = Round(roundId, answer, startedAt, updatedAt, answeredInRound);
    }

    function getRoundData(uint80 _roundId)
        override
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
        roundId = _rounds[_roundId].roundId;
        answer = _rounds[_roundId].answer;
        startedAt = _rounds[_roundId].startedAt;
        updatedAt = _rounds[_roundId].updatedAt;
        answeredInRound = _rounds[_roundId].answeredInRound;
    }

    function latestRoundData()
        override
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        return getRoundData(latestRoundId);
    }
}

