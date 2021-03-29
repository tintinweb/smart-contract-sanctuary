/**
 *Submitted for verification at Etherscan.io on 2021-03-29
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

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


/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SignedSafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SignedSafeMath {
    /**
     * @dev Returns the multiplication of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two signed integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(int256 a, int256 b) internal pure returns (int256) {
        return a / b;
    }

    /**
     * @dev Returns the subtraction of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        return a - b;
    }

    /**
     * @dev Returns the addition of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        return a + b;
    }
}


contract GoldGramConvertorPriceConsumer {
    using SignedSafeMath for int;
    AggregatorV3Interface internal priceFeed;
    
    int gramPerTroyOunceForDivision = 311034768;
    
    /**
     * Network: Mainnet
     * Aggregator: XAU/USD
     * Address: 0x214eD9Da11D2fbe465a6fc601a91E62EbEc1a0D6
     */
    constructor() {
        priceFeed = AggregatorV3Interface(0x214eD9Da11D2fbe465a6fc601a91E62EbEc1a0D6);
    }

    /**
     * Returns the latest price
     */
    function getLatestPrice() public view returns (int) {
        (, int price,,,) = priceFeed.latestRoundData();
         
        int priceConvertedForDivision = price.mul(10000000);
        
        return (priceConvertedForDivision.div(gramPerTroyOunceForDivision));
    }
}