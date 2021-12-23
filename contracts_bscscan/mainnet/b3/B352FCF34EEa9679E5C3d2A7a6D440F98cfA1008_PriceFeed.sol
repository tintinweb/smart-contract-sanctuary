/**
 *Submitted for verification at BscScan.com on 2021-12-23
*/

// File: contracts/interfaces/IPriceFeed.sol

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface IPriceFeed {

    // --- Function ---
    function fetchPrice() external view returns (uint);
    function updatePrice() external returns (uint);
}

// File: contracts/interfaces/IBandStdReference.sol

pragma solidity 0.7.6;


interface IBandStdReference {

    /// Returns the price data for the given base/quote pair. Revert if not available.
    function getReferenceData(string memory _base, string memory _quote)
        external
        view
        returns (uint256 rate, uint256 lastUpdatedBase, uint256 lastUpdatedRate);

}

// File: contracts/interfaces/IChainlinkAggregator.sol


// Code from https://github.com/smartcontractkit/chainlink/blob/master/evm-contracts/src/v0.6/interfaces/AggregatorV3Interface.sol

pragma solidity 0.7.6;

interface IChainlinkAggregator {

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

// File: contracts/dependencies/openzeppelin/contracts/SafeMath.sol


pragma solidity 0.7.6;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
  /**
   * @dev Returns the addition of two unsigned integers, reverting on
   * overflow.
   *
   * Counterpart to Solidity's `+` operator.
   *
   * Requirements:
   * - Addition cannot overflow.
   */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, 'SafeMath: addition overflow');

    return c;
  }

  /**
   * @dev Returns the subtraction of two unsigned integers, reverting on
   * overflow (when the result is negative).
   *
   * Counterpart to Solidity's `-` operator.
   *
   * Requirements:
   * - Subtraction cannot overflow.
   */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    return sub(a, b, 'SafeMath: subtraction overflow');
  }

  /**
   * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
   * overflow (when the result is negative).
   *
   * Counterpart to Solidity's `-` operator.
   *
   * Requirements:
   * - Subtraction cannot overflow.
   */
  function sub(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b <= a, errorMessage);
    uint256 c = a - b;

    return c;
  }

  /**
   * @dev Returns the multiplication of two unsigned integers, reverting on
   * overflow.
   *
   * Counterpart to Solidity's `*` operator.
   *
   * Requirements:
   * - Multiplication cannot overflow.
   */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, 'SafeMath: multiplication overflow');

    return c;
  }

  /**
   * @dev Returns the integer division of two unsigned integers. Reverts on
   * division by zero. The result is rounded towards zero.
   *
   * Counterpart to Solidity's `/` operator. Note: this function uses a
   * `revert` opcode (which leaves remaining gas untouched) while Solidity
   * uses an invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   * - The divisor cannot be zero.
   */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return div(a, b, 'SafeMath: division by zero');
  }

  /**
   * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
   * division by zero. The result is rounded towards zero.
   *
   * Counterpart to Solidity's `/` operator. Note: this function uses a
   * `revert` opcode (which leaves remaining gas untouched) while Solidity
   * uses an invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   * - The divisor cannot be zero.
   */
  function div(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    // Solidity only automatically asserts when dividing by 0
    require(b > 0, errorMessage);
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  /**
   * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
   * Reverts when dividing by zero.
   *
   * Counterpart to Solidity's `%` operator. This function uses a `revert`
   * opcode (which leaves remaining gas untouched) while Solidity uses an
   * invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   * - The divisor cannot be zero.
   */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    return mod(a, b, 'SafeMath: modulo by zero');
  }

  /**
   * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
   * Reverts with custom message when dividing by zero.
   *
   * Counterpart to Solidity's `%` operator. This function uses a `revert`
   * opcode (which leaves remaining gas untouched) while Solidity uses an
   * invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   * - The divisor cannot be zero.
   */
  function mod(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b != 0, errorMessage);
    return a % b;
  }
}

// File: contracts/misc/PriceFeed.sol



pragma solidity 0.7.6;





/*
* PriceFeed for mainnet deployment, to be connected to Chainlink's live ETH:USD aggregator reference
* contract, and a wrapper contract bandOracle, which connects to BandMaster contract.
*
* The PriceFeed uses Chainlink as primary oracle, and Band as fallback. It contains logic for
* switching oracles based on oracle failures, timeouts, and conditions for returning to the primary
* Chainlink oracle.
*/
contract PriceFeed is IPriceFeed {
    using SafeMath for uint256;

    uint constant public DECIMAL_PRECISION = 1e18;

    IChainlinkAggregator public chainlinkOracle;  // Mainnet Chainlink aggregator
    IBandStdReference public bandOracle;  // Wrapper contract that calls the Band system

    string public bandBase;
    string public constant bandQuote = "USD";

    // Use to convert a price answer to an 18-digit precision uint
    uint constant public TARGET_DIGITS = 18;

    // Maximum time period allowed since Chainlink's latest round data timestamp, beyond which Chainlink is considered frozen.
    // For stablecoins we recommend 90000, as Chainlink updates once per day when there is no significant price movement
    // For volatile assets we recommend 14400 (4 hours)
    uint immutable public TIMEOUT;

    // Maximum deviation allowed between two consecutive Chainlink oracle prices. 18-digit precision.
    uint constant public MAX_PRICE_DEVIATION_FROM_PREVIOUS_ROUND =  5e17; // 50%

    /*
    * The maximum relative price difference between two oracle responses allowed in order for the PriceFeed
    * to return to using the Chainlink oracle. 18-digit precision.
    */
    uint constant public MAX_PRICE_DIFFERENCE_BETWEEN_ORACLES = 5e16; // 5%

    // The last good price seen from an oracle by Liquity
    uint public lastGoodPrice;

    struct ChainlinkResponse {
        uint80 roundId;
        uint256 answer;
        uint256 timestamp;
        bool success;
        uint8 decimals;
    }

    struct BandResponse {
        uint256 value;
        uint256 timestamp;
        bool success;
    }

    enum Status {
        chainlinkWorking,
        usingBandChainlinkUntrusted,
        bothOraclesUntrusted,
        usingBandChainlinkFrozen,
        usingChainlinkBandUntrusted
    }

    // The current status of the PricFeed, which determines the conditions for the next price fetch attempt
    Status public status;

    event LastGoodPriceUpdated(uint _lastGoodPrice);
    event PriceFeedStatusChanged(Status newStatus);

    // --- Dependency setters ---

    constructor(
        IChainlinkAggregator _chainlinkOracleAddress,
        IBandStdReference _bandOracleAddress,
        uint256 _timeout,
        string memory _bandBase
    ) {
        chainlinkOracle = _chainlinkOracleAddress;
        bandOracle = _bandOracleAddress;

        TIMEOUT = _timeout;

        bandBase = _bandBase;

        // Explicitly set initial system status
        status = Status.chainlinkWorking;

        // Get an initial price from Chainlink to serve as first reference for lastGoodPrice
        ChainlinkResponse memory chainlinkResponse = _getCurrentChainlinkResponse();
        ChainlinkResponse memory prevChainlinkResponse = _getPrevChainlinkResponse(chainlinkResponse.roundId, chainlinkResponse.decimals);

        require(
            !_chainlinkIsBroken(chainlinkResponse, prevChainlinkResponse) &&
            block.timestamp.sub(chainlinkResponse.timestamp) < _timeout,
            "PriceFeed: Chainlink must be working and current"
        );

        lastGoodPrice = _scaleChainlinkPriceByDigits(uint256(chainlinkResponse.answer), chainlinkResponse.decimals);
    }

    // --- Functions ---

    /*
    * fetchPrice():
    * Returns the latest price obtained from the Oracle. Called by Liquity functions that require a current price.
    *
    * Also callable by anyone externally.
    *
    * Non-view function - it stores the last good price seen by Liquity.
    *
    * Uses a main oracle (Chainlink) and a fallback oracle (Band) in case Chainlink fails. If both fail,
    * it uses the last good price seen by Liquity.
    *
    */
    function fetchPrice() external view override returns (uint) {
        (,uint price) = _fetchPrice();
        return price;
    }

    function updatePrice() external override returns (uint) {
        (Status newStatus, uint price) = _fetchPrice();
        lastGoodPrice = price;
        if (status != newStatus) {
            status = newStatus;
            emit PriceFeedStatusChanged(newStatus);
        }
        return price;
    }


    function _fetchPrice() internal view returns (Status, uint) {
        // Get current and previous price data from Chainlink, and current price data from Band
        ChainlinkResponse memory chainlinkResponse = _getCurrentChainlinkResponse();
        ChainlinkResponse memory prevChainlinkResponse = _getPrevChainlinkResponse(chainlinkResponse.roundId, chainlinkResponse.decimals);
        BandResponse memory bandResponse = _getCurrentBandResponse();

        // --- CASE 1: System fetched last price from Chainlink  ---
        if (status == Status.chainlinkWorking) {
            // If Chainlink is broken, try Band
            if (_chainlinkIsBroken(chainlinkResponse, prevChainlinkResponse)) {
                // If Band is broken then both oracles are untrusted, so return the last good price
                if (_bandIsBroken(bandResponse)) {
                    return (Status.bothOraclesUntrusted, lastGoodPrice);
                }
                /*
                * If Band is only frozen but otherwise returning valid data, return the last good price.
                */
                if (_bandIsFrozen(bandResponse)) {
                    return (Status.usingBandChainlinkUntrusted, lastGoodPrice);
                }

                // If Chainlink is broken and Band is working, switch to Band and return current Band price
                return (Status.usingBandChainlinkUntrusted, bandResponse.value);
            }

            // If Chainlink is frozen, try Band
            if (_chainlinkIsFrozen(chainlinkResponse)) {
                // If Band is broken too, remember Band broke, and return last good price
                if (_bandIsBroken(bandResponse)) {
                    return (Status.usingChainlinkBandUntrusted, lastGoodPrice);
                }

                // If Band is frozen or working, remember Chainlink froze, and switch to Band
                if (_bandIsFrozen(bandResponse)) {return (Status.usingBandChainlinkFrozen, lastGoodPrice);}

                // If Band is working, use it
                return (Status.usingBandChainlinkFrozen, bandResponse.value);
            }

            // If Chainlink price has changed by > 50% between two consecutive rounds, compare it to Band's price
            if (_chainlinkPriceChangeAboveMax(chainlinkResponse, prevChainlinkResponse)) {
                // If Band is broken, both oracles are untrusted, and return last good price
                 if (_bandIsBroken(bandResponse)) {
                    return (Status.bothOraclesUntrusted, lastGoodPrice);
                }

                // If Band is frozen, switch to Band and return last good price
                if (_bandIsFrozen(bandResponse)) {
                    return (Status.usingBandChainlinkUntrusted, lastGoodPrice);
                }

                /*
                * If Band is live and both oracles have a similar price, conclude that Chainlink's large price deviation between
                * two consecutive rounds was likely a legitmate market price movement, and so continue using Chainlink
                */
                if (_bothOraclesSimilarPrice(chainlinkResponse, bandResponse)) {
                    return (Status.chainlinkWorking, chainlinkResponse.answer);
                }

                // If Band is live but the oracles differ too much in price, conclude that Chainlink's initial price deviation was
                // an oracle failure. Switch to Band, and use Band price
                return (Status.usingBandChainlinkUntrusted, bandResponse.value);
            }

            // If Chainlink is working and Band is broken, remember Band is broken
            if (_bandIsBroken(bandResponse)) {
                return (Status.usingChainlinkBandUntrusted, chainlinkResponse.answer);
            }

            // If Chainlink is working, return Chainlink current price (no status change)
            return (Status.chainlinkWorking, chainlinkResponse.answer);
        }


        // --- CASE 2: The system fetched last price from Band ---
        if (status == Status.usingBandChainlinkUntrusted) {
            // If both Band and Chainlink are live, unbroken, and reporting similar prices, switch back to Chainlink
            if (_bothOraclesLiveAndUnbrokenAndSimilarPrice(chainlinkResponse, prevChainlinkResponse, bandResponse)) {
                return (Status.chainlinkWorking, chainlinkResponse.answer);
            }

            if (_bandIsBroken(bandResponse)) {
                return (Status.bothOraclesUntrusted, lastGoodPrice);
            }

            /*
            * If Band is only frozen but otherwise returning valid data, just return the last good price.
            * Band may need to be tipped to return current data.
            */
            if (_bandIsFrozen(bandResponse)) {return (Status.usingBandChainlinkUntrusted, lastGoodPrice);}

            // Otherwise, use Band price
            return (Status.usingBandChainlinkUntrusted, bandResponse.value);
        }

        // --- CASE 3: Both oracles were untrusted at the last price fetch ---
        if (status == Status.bothOraclesUntrusted) {
            /*
            * If both oracles are now live, unbroken and similar price, we assume that they are reporting
            * accurately, and so we switch back to Chainlink.
            */
            if (_bothOraclesLiveAndUnbrokenAndSimilarPrice(chainlinkResponse, prevChainlinkResponse, bandResponse)) {
                return (Status.chainlinkWorking, chainlinkResponse.answer);
            }

            // Otherwise, return the last good price - both oracles are still untrusted (no status change)
            return (Status.bothOraclesUntrusted, lastGoodPrice);
        }

        // --- CASE 4: Using Band, and Chainlink is frozen ---
        if (status == Status.usingBandChainlinkFrozen) {
            if (_chainlinkIsBroken(chainlinkResponse, prevChainlinkResponse)) {
                // If both Oracles are broken, return last good price
                if (_bandIsBroken(bandResponse)) {
                    return (Status.bothOraclesUntrusted, lastGoodPrice);
                }

                // If Chainlink is broken, remember it and switch to using Band

                if (_bandIsFrozen(bandResponse)) {return (Status.usingBandChainlinkUntrusted, lastGoodPrice);}

                // If Band is working, return Band current price
                return (Status.usingBandChainlinkUntrusted, bandResponse.value);
            }

            if (_chainlinkIsFrozen(chainlinkResponse)) {
                // if Chainlink is frozen and Band is broken, remember Band broke, and return last good price
                if (_bandIsBroken(bandResponse)) {
                    return (Status.usingChainlinkBandUntrusted, lastGoodPrice);
                }

                // If both are frozen, just use lastGoodPrice
                if (_bandIsFrozen(bandResponse)) {return (Status.usingBandChainlinkFrozen, lastGoodPrice);}

                // if Chainlink is frozen and Band is working, keep using Band (no status change)
                return (Status.usingBandChainlinkFrozen, bandResponse.value);
            }

            // if Chainlink is live and Band is broken, remember Band broke, and return Chainlink price
            if (_bandIsBroken(bandResponse)) {
                return (Status.usingChainlinkBandUntrusted, chainlinkResponse.answer);
            }

             // If Chainlink is live and Band is frozen, just use last good price (no status change) since we have no basis for comparison
            if (_bandIsFrozen(bandResponse)) {return (Status.usingBandChainlinkFrozen, lastGoodPrice);}

            // If Chainlink is live and Band is working, compare prices. Switch to Chainlink
            // if prices are within 5%, and return Chainlink price.
            if (_bothOraclesSimilarPrice(chainlinkResponse, bandResponse)) {
                return (Status.chainlinkWorking, chainlinkResponse.answer);
            }

            // Otherwise if Chainlink is live but price not within 5% of Band, distrust Chainlink, and return Band price
            return (Status.usingBandChainlinkUntrusted, bandResponse.value);
        }

        // --- CASE 5: Using Chainlink, Band is untrusted ---
         if (status == Status.usingChainlinkBandUntrusted) {
            // If Chainlink breaks, now both oracles are untrusted
            if (_chainlinkIsBroken(chainlinkResponse, prevChainlinkResponse)) {
                return (Status.bothOraclesUntrusted, lastGoodPrice);
            }

            // If Chainlink is frozen, return last good price (no status change)
            if (_chainlinkIsFrozen(chainlinkResponse)) {
                return (Status.usingChainlinkBandUntrusted, lastGoodPrice);
            }

            // If Chainlink and Band are both live, unbroken and similar price, switch back to chainlinkWorking and return Chainlink price
            if (_bothOraclesLiveAndUnbrokenAndSimilarPrice(chainlinkResponse, prevChainlinkResponse, bandResponse)) {
                return (Status.chainlinkWorking, chainlinkResponse.answer);
            }

            // If Chainlink is live but deviated >50% from it's previous price and Band is still untrusted, switch
            // to bothOraclesUntrusted and return last good price
            if (_chainlinkPriceChangeAboveMax(chainlinkResponse, prevChainlinkResponse)) {
                return (Status.bothOraclesUntrusted, lastGoodPrice);
            }

            // Otherwise if Chainlink is live and deviated <50% from it's previous price and Band is still untrusted,
            // return Chainlink price (no status change)
            return (Status.usingChainlinkBandUntrusted, chainlinkResponse.answer);
        }
    }

    // --- Helper functions ---

    /* Chainlink is considered broken if its current or previous round data is in any way bad. We check the previous round
    * for two reasons:
    *
    * 1) It is necessary data for the price deviation check in case 1,
    * and
    * 2) Chainlink is the PriceFeed's preferred primary oracle - having two consecutive valid round responses adds
    * peace of mind when using or returning to Chainlink.
    */
    function _chainlinkIsBroken(ChainlinkResponse memory _currentResponse, ChainlinkResponse memory _prevResponse) internal view returns (bool) {
        return _badChainlinkResponse(_currentResponse) || _badChainlinkResponse(_prevResponse);
    }

    function _badChainlinkResponse(ChainlinkResponse memory _response) internal view returns (bool) {
         // Check for response call reverted
        if (!_response.success) {return true;}
        // Check for an invalid roundId that is 0
        if (_response.roundId == 0) {return true;}
        // Check for an invalid timeStamp that is 0, or in the future
        if (_response.timestamp == 0 || _response.timestamp > block.timestamp) {return true;}
        // Check for non-positive price (original value returned from chainlink is int256)
        if (_response.answer <= 0) {return true;}
        /* if (int256(_response.answer) <= 0) {return true;} */

        return false;
    }

    function _chainlinkIsFrozen(ChainlinkResponse memory _response) internal view returns (bool) {
        return block.timestamp.sub(_response.timestamp) > TIMEOUT;
    }

    function _chainlinkPriceChangeAboveMax(ChainlinkResponse memory _currentResponse, ChainlinkResponse memory _prevResponse) internal pure returns (bool) {
        uint currentScaledPrice = _currentResponse.answer;
        uint prevScaledPrice = _prevResponse.answer;

        uint minPrice = (currentScaledPrice < prevScaledPrice) ? currentScaledPrice : prevScaledPrice;
        uint maxPrice = (currentScaledPrice >= prevScaledPrice) ? currentScaledPrice : prevScaledPrice;

        /*
        * Use the larger price as the denominator:
        * - If price decreased, the percentage deviation is in relation to the the previous price.
        * - If price increased, the percentage deviation is in relation to the current price.
        */
        uint percentDeviation = maxPrice.sub(minPrice).mul(DECIMAL_PRECISION).div(maxPrice);

        // Return true if price has more than doubled, or more than halved.
        return percentDeviation > MAX_PRICE_DEVIATION_FROM_PREVIOUS_ROUND;
    }

    function _bandIsBroken(BandResponse memory _response) internal view returns (bool) {
        // Check for response call reverted
        if (!_response.success) {return true;}
        // Check for an invalid timeStamp that is 0, or in the future
        if (_response.timestamp == 0 || _response.timestamp > block.timestamp) {return true;}
        // Check for zero price
        if (_response.value == 0) {return true;}

        return false;
    }

     function _bandIsFrozen(BandResponse  memory _bandResponse) internal view returns (bool) {
        return block.timestamp.sub(_bandResponse.timestamp) > TIMEOUT;
    }

    function _bothOraclesLiveAndUnbrokenAndSimilarPrice
    (
        ChainlinkResponse memory _chainlinkResponse,
        ChainlinkResponse memory _prevChainlinkResponse,
        BandResponse memory _bandResponse
    )
        internal
        view
        returns (bool)
    {
        // Return false if either oracle is broken or frozen
        if
        (
            _bandIsBroken(_bandResponse) ||
            _bandIsFrozen(_bandResponse) ||
            _chainlinkIsBroken(_chainlinkResponse, _prevChainlinkResponse) ||
            _chainlinkIsFrozen(_chainlinkResponse)
        )
        {
            return false;
        }

        return _bothOraclesSimilarPrice(_chainlinkResponse, _bandResponse);
    }

    function _bothOraclesSimilarPrice( ChainlinkResponse memory _chainlinkResponse, BandResponse memory _bandResponse) internal pure returns (bool) {
        uint scaledChainlinkPrice = _chainlinkResponse.answer;
        uint scaledBandPrice = _bandResponse.value;

        // Get the relative price difference between the oracles. Use the lower price as the denominator, i.e. the reference for the calculation.
        uint minPrice = (scaledBandPrice < scaledChainlinkPrice) ? scaledBandPrice : scaledChainlinkPrice;
        uint maxPrice = (scaledBandPrice >= scaledChainlinkPrice) ? scaledBandPrice : scaledChainlinkPrice;
        uint percentPriceDifference = maxPrice.sub(minPrice).mul(DECIMAL_PRECISION).div(minPrice);

        /*
        * Return true if the relative price difference is <= 3%: if so, we assume both oracles are probably reporting
        * the honest market price, as it is unlikely that both have been broken/hacked and are still in-sync.
        */
        return percentPriceDifference <= MAX_PRICE_DIFFERENCE_BETWEEN_ORACLES;
    }

    function _scaleChainlinkPriceByDigits(uint _price, uint _answerDigits) internal pure returns (uint) {
        /*
        * Convert the price returned by the Chainlink oracle to an 18-digit decimal for use by Liquity.
        * At date of Liquity launch, Chainlink uses an 8-digit price, but we also handle the possibility of
        * future changes.
        *
        */
        uint price;
        if (_answerDigits >= TARGET_DIGITS) {
            // Scale the returned price value down to Liquity's target precision
            price = _price.div(10 ** (_answerDigits - TARGET_DIGITS));
        }
        else if (_answerDigits < TARGET_DIGITS) {
            // Scale the returned price value up to Liquity's target precision
            price = _price.mul(10 ** (TARGET_DIGITS - _answerDigits));
        }
        return price;
    }

    // --- Oracle response wrapper functions ---

    function _getCurrentBandResponse() internal view returns (BandResponse memory bandResponse) {
        try bandOracle.getReferenceData(bandBase, bandQuote) returns
        (
            uint256 value,
            uint256 lastUpdatedBase,
            uint256 lastUpdatedQuote
        )
        {
            // If call to Band succeeds, return the response and success = true
            bandResponse.value = value;
            bandResponse.timestamp =  lastUpdatedBase < lastUpdatedQuote ? lastUpdatedBase : lastUpdatedQuote;
            bandResponse.success = true;

            return (bandResponse);
        }catch {
             // If call to Band reverts, return a zero response with success = false
            return (bandResponse);
        }
    }

    function _getCurrentChainlinkResponse() internal view returns (ChainlinkResponse memory chainlinkResponse) {
        // First, try to get current decimal precision:
        try chainlinkOracle.decimals() returns (uint8 decimals) {
            // If call to Chainlink succeeds, record the current decimal precision
            chainlinkResponse.decimals = decimals;
        } catch {
            // If call to Chainlink aggregator reverts, return a zero response with success = false
            return chainlinkResponse;
        }

        // Secondly, try to get latest price data:
        try chainlinkOracle.latestRoundData() returns
        (
            uint80 roundId,
            int256 answer,
            uint256 /* startedAt */,
            uint256 timestamp,
            uint80 /* answeredInRound */
        )
        {
            // If call to Chainlink succeeds, return the response and success = true
            chainlinkResponse.roundId = roundId;
            chainlinkResponse.answer = _scaleChainlinkPriceByDigits(uint256(answer), chainlinkResponse.decimals);
            chainlinkResponse.timestamp = timestamp;
            chainlinkResponse.success = true;
            return chainlinkResponse;
        } catch {
            // If call to Chainlink aggregator reverts, return a zero response with success = false
            return chainlinkResponse;
        }
    }

    function _getPrevChainlinkResponse(uint80 _currentRoundId, uint8 _currentDecimals) internal view returns (ChainlinkResponse memory prevChainlinkResponse) {
        /*
        * NOTE: Chainlink only offers a current decimals() value - there is no way to obtain the decimal precision used in a
        * previous round.  We assume the decimals used in the previous round are the same as the current round.
        */

        // Try to get the price data from the previous round:
        try chainlinkOracle.getRoundData(_currentRoundId - 1) returns
        (
            uint80 roundId,
            int256 answer,
            uint256 /* startedAt */,
            uint256 timestamp,
            uint80 /* answeredInRound */
        )
        {
            // If call to Chainlink succeeds, return the response and success = true
            prevChainlinkResponse.roundId = roundId;
            prevChainlinkResponse.answer = _scaleChainlinkPriceByDigits(uint256(answer), _currentDecimals);
            prevChainlinkResponse.timestamp = timestamp;
            prevChainlinkResponse.decimals = _currentDecimals;
            prevChainlinkResponse.success = true;
            return prevChainlinkResponse;
        } catch {
            // If call to Chainlink aggregator reverts, return a zero response with success = false
            return prevChainlinkResponse;
        }
    }
}