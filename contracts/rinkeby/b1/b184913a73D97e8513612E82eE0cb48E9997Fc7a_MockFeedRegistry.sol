//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "../interface/FeedRegistryInterface.sol";
import "@chainlink/contracts/src/v0.8/Denominations.sol";

/** This contract is built to simulate oracle prices. Only latestAnswer and decimals are implemented properly.
 ** Set answer of an address pair with setPrice. Set decimals with setDecimals()
 **/

contract MockFeedRegistry is FeedRegistryInterface{
    mapping(address => mapping(address => uint8)) private decimal;
    mapping(address => mapping(address => int256)) private answers;

    function decimals(
        address base,
        address quote
    )
        external view override
        returns (uint8)
    {
        if (decimal[base][quote] > 0){
            return decimal[base][quote];
        }
        else {
            return 18;
        }
    }

    function latestRoundData(
        address base,
        address quote
    )
        external view override
        returns (
            uint80 id,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        return (0, 0, 0, 0, 0);
    }

    function latestAnswer(
        address base,
        address quote
    )
        external view override
        returns (int256 answer)
    {
        if(answers[base][quote] > 0){
            return answers[base][quote];
        }
        return 1e18;
    }

    function latestTimestamp(
        address base,
        address quote
    )
        external view override
        returns (uint256 timestamp)
    {
        return 0;
    }

    function latestRound(
        address base,
        address quote
    )
        external view override
        returns (uint256 roundId)
    {
        return 0;
    }

    function isFeedEnabled(
        address aggregator
    )
        external view override
        returns (bool)
    {
        return true;
    }

    function setDecimals(
        address base,
        address quote,
        uint8 _decimal
    )
        external
    {
        decimal[base][quote] = _decimal;
    }

    function setAnswer(
        address base,
        address quote,
        int256 _answer
    )
        external
    {
        answers[base][quote] = _answer;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface FeedRegistryInterface {
    function decimals(address base, address quote)
        external
        view
        returns (uint8);

    function latestRoundData(address base, address quote)
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );

    // V2 AggregatorInterface

    function latestAnswer(address base, address quote)
        external
        view
        returns (int256 answer);

    function latestTimestamp(address base, address quote)
        external
        view
        returns (uint256 timestamp);

    function latestRound(address base, address quote)
        external
        view
        returns (uint256 roundId);

    function isFeedEnabled(address aggregator) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library Denominations {
  address public constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
  address public constant BTC = 0xbBbBBBBbbBBBbbbBbbBbbbbBBbBbbbbBbBbbBBbB;

  // Fiat currencies follow https://en.wikipedia.org/wiki/ISO_4217
  address public constant USD = address(840);
  address public constant GBP = address(826);
  address public constant EUR = address(978);
  address public constant JPY = address(392);
  address public constant KRW = address(410);
  address public constant CNY = address(156);
  address public constant AUD = address(36);
  address public constant CAD = address(124);
  address public constant CHF = address(756);
  address public constant ARS = address(32);
  address public constant PHP = address(608);
  address public constant NZD = address(554);
  address public constant SGD = address(702);
  address public constant NGN = address(566);
  address public constant ZAR = address(710);
  address public constant RUB = address(643);
  address public constant INR = address(356);
  address public constant BRL = address(986);
}