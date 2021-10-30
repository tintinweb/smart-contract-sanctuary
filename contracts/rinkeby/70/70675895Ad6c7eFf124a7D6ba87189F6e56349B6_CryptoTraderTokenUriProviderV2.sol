/**
 *Submitted for verification at Etherscan.io on 2021-10-30
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.6;



// Part: CryptoTraderInterface

interface CryptoTraderInterface {
    /**
     * Returns a uri for CryptTraderI (BTC) tokens
     */
    function btcTokenURI() external view returns (string memory);

    /**
     * Returns a uri for CryptTraderII (ETH) tokens
     */
    function ethTokenURI() external view returns (string memory);
}

// Part: smartcontractkit/[email protected]/AggregatorV3Interface

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

// File: CryptoTraderTokenUriProviderV2.sol

/**
 * Provides token metadata for CryptoTraderI and CryptoTraderII tokens
 */
contract CryptoTraderTokenUriProviderV2 is CryptoTraderInterface {
    AggregatorV3Interface private btcPriceFeed;
    AggregatorV3Interface private ethPriceFeed;
    address owner;

    /**
     * @dev Public constructor
     * _btcPriceFeed - address for the BTC/USD feed mainnet: 0xF4030086522a5bEEa4988F8cA5B36dbC97BeE88c
     * _ethPriceFeed - address for the ETH/USD feed mainnet: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
     */
    constructor(address _btcPriceFeed, address _ethPriceFeed) public {
        owner = msg.sender;

        btcPriceFeed = AggregatorV3Interface(_btcPriceFeed);
        ethPriceFeed = AggregatorV3Interface(_ethPriceFeed);
    }

    /**
     * @dev Returns the prev and current price of BTC in USD
     * prev price is the price for round: current round - round interval
     */
    function getBTCPrice() public view returns (uint256, uint256) {
        // current price data
        (uint80 roundId, int256 answer, , , ) = btcPriceFeed.latestRoundData();
        uint256 current = uint256(answer) /
            (10**uint256(btcPriceFeed.decimals()));

        // previous price data
        (, int256 prevAnswer, , , ) = btcPriceFeed.getRoundData(roundId - 50);
        uint256 prev = uint256(prevAnswer) /
            (10**uint256(btcPriceFeed.decimals()));

        return (prev, current);
    }

    /**
     * @dev Returns the prev and current price of ETH in USD
     * prev price is the price for round: current round - round interval
     */
    function getETHPrice() public view returns (uint256, uint256) {
        // current price data
        (uint80 roundId, int256 answer, , , ) = ethPriceFeed.latestRoundData();
        uint256 current = uint256(answer) /
            (10**uint256(ethPriceFeed.decimals()));

        // previous price data
        (, int256 prevAnswer, , , ) = ethPriceFeed.getRoundData(roundId - 50);
        uint256 prev = uint256(prevAnswer) /
            (10**uint256(ethPriceFeed.decimals()));

        return (prev, current);
    }

    /**
     * @dev Returns the token metadata URI for CryptoTraderI
     */
    function btcTokenURI() public view override returns (string memory) {
        return "BTC Test URI";
    }

    /**
     * @dev Returns the token metadata URI for CryptoTraderII
     */
    function ethTokenURI() public view override returns (string memory) {
        return "ETH Test URI";
    }
}