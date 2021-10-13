pragma solidity 0.8.4;

/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Written by somewherecat
 * Copyright (C) 2021 Yamato Protocol (DeFiGeek Community Japan)
 */

import "./OracleMockBase.sol";
import "./Dependencies/AggregatorV3Interface.sol";

//solhint-disable max-line-length
//solhint-disable no-inline-assembly

contract ChainLinkMock is OracleMockBase, AggregatorV3Interface {
    uint8 private symbol;
    uint8 private ETHUSD = 1;
    uint8 private JPYUSD = 2;

    uint80 private lastRoundId;
    uint80 private lastPriceUpdateRoundId;

    // mapping from a specific roundId to previous values
    mapping(uint80 => int256) private prevAnswers;
    mapping(uint80 => uint256) private prevTimestamps;
    mapping(uint80 => uint80) private prevAnsweredInRounds;

    constructor(string memory _symbol) {
        symbol = getSymbolId(_symbol);
        require(symbol > 0, "Only ETH/USD and JPY/USD is supported.");

        lastRoundId = 30000000000000000001;
        lastPriceUpdateRoundId = 30000000000000000001;
        setPriceToDefault();
    }

    function getSymbolId(string memory _symbol) private view returns (uint8) {
        bytes32 value = keccak256(abi.encodePacked(_symbol));
        if (value == keccak256(abi.encodePacked("ETH/USD"))) {
            return ETHUSD;
        } else if (value == keccak256(abi.encodePacked("JPY/USD"))) {
            return JPYUSD;
        }
        return 0;
    }

    function setPriceToDefault() public override onlyOwner {
        if (symbol == ETHUSD) {
            lastPrice = 300000000000;
        } // 3000 USD
        if (symbol == JPYUSD) {
            lastPrice = 1000000;
        } // 0.010 JPYUSD = 100 USDJPY
    }

    function latestRoundData()
        public
        view
        virtual
        override
        returns (
            uint80 roundId, // The round ID.
            int256 answer, // The price.
            uint256 startedAt, // Timestamp of when the round started.
            uint256 updatedAt, // Timestamp of when the round was updated.
            uint80 answeredInRound // The round ID of the round in which the answer was computed.
        )
    {
        uint256 timestamp = prevTimestamps[lastRoundId];
        return (
            lastRoundId,
            lastPrice,
            timestamp,
            timestamp,
            lastPriceUpdateRoundId
        );
    }

    function simulatePriceMove(uint256 deviation, bool sign)
        internal
        override
        onlyOwner
    {
        uint80 currentRoundId = lastRoundId + 1;
        int256 answer;
        uint80 answeredInRound;
        if (deviation == 0) {
            // no deviation, hence answeredInRound == lastPriceUpdateRoundId
            answer = lastPrice;
            answeredInRound = lastPriceUpdateRoundId;
        } else {
            int256 change = lastPrice / 1000;
            change = change * int256(deviation);
            answer = sign ? lastPrice + change : lastPrice - change;

            lastPrice = answer;
            answeredInRound = currentRoundId;
            lastPriceUpdateRoundId = currentRoundId;
        }

        lastRoundId = currentRoundId;
        prevAnswers[currentRoundId] = answer;
        prevTimestamps[currentRoundId] = block.timestamp;
        prevAnsweredInRounds[currentRoundId] = answeredInRound;
    }

    function decimals() external view virtual override returns (uint8) {
        // For both ETH/USD and JPY/USD, decimals are static being 8
        return 8;
    }

    function getRoundData(uint80 _roundId)
        external
        view
        virtual
        override
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        uint256 timestamp = prevTimestamps[_roundId];
        require(
            timestamp != 0,
            "The specified round Id doesn't have a previous answer."
        );

        return (
            _roundId,
            prevAnswers[_roundId],
            timestamp,
            timestamp,
            prevAnsweredInRounds[_roundId]
        );
    }

    function description()
        external
        view
        virtual
        override
        returns (string memory)
    {
        return "Chainlink Mock for the Yamato protocol.";
    }

    function version() external view virtual override returns (uint256) {
        return 1;
    }
}

pragma solidity 0.8.4;

/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Written by somewherecat
 * Copyright (C) 2021 Yamato Protocol (DeFiGeek Community Japan)
 */

//solhint-disable max-line-length
//solhint-disable no-inline-assembly

import "./Dependencies/Ownable.sol";

// Base class to create a oracle mock contract for a specific provider
abstract contract OracleMockBase is Ownable {
    int256 internal lastPrice;
    uint256 private lastBlockNumber;

    function setLastPrice(int256 _price) public onlyOwner {
        lastPrice = _price;
        lastBlockNumber = block.number;
    }

    function setPriceToDefault() public virtual;

    function simulatePriceMove(uint256 deviation, bool sign) internal virtual;

    function simulatePriceMove() public onlyOwner {
        // Within each block, only once price update is allowed (volatility control)
        if (block.number != lastBlockNumber) {
            lastBlockNumber = block.number;

            uint256 randomNumber = uint256(
                keccak256(
                    abi.encodePacked(
                        msg.sender,
                        block.timestamp,
                        blockhash(block.number - 1)
                    )
                )
            );
            uint256 deviation = randomNumber % 11;
            bool sign = randomNumber % 2 == 1 ? true : false;
            simulatePriceMove(deviation, sign);
        }
    }
}

// SPDX-License-Identifier: MIT
// Code from https://github.com/smartcontractkit/chainlink/blob/master/evm-contracts/src/v0.6/interfaces/AggregatorV3Interface.sol

pragma solidity 0.8.4;

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
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

/**
 * Based on OpenZeppelin's Ownable contract:
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol
 *
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     *
     * NOTE: This function is not safe, as it doesn’t check owner is calling it.
     * Make sure you check it before calling it.
     */
    function _renounceOwnership() internal {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
}