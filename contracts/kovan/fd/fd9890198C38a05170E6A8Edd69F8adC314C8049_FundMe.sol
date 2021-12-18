/**
 *Submitted for verification at Etherscan.io on 2021-12-17
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;



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

// File: BrownieFundMe.sol

contract FundMe {
    mapping(address => uint256) public addressToAmountFunded;
    // AggregatorV3Interface internal priceFeed;

    // /**
    //  * Network: Kovan
    //  * Aggregator: ETH/USD
    //  * Address: 0x9326BFA02ADD2366b30bacB125260Af641031331
    //  */
    // constructor() {
    //     priceFeed = AggregatorV3Interface(0x9326BFA02ADD2366b30bacB125260Af641031331);
    // }

    mapping(string => address) internal assetToAddressMapping;

    function mapAssetToAddress(string memory _asset, address _address) public {
        assetToAddressMapping[_asset] = _address;
    }

    function getPriceOfAsset(string memory _asset)
        public
        view
        returns (uint256)
    {
        AggregatorV3Interface assetPriceFeed = AggregatorV3Interface(
            assetToAddressMapping[_asset]
        );
        uint256 latestPrice = getLatestPrice(assetPriceFeed);
        return latestPrice;
    }

    function fund() public payable {
        // What the ETH to USDC conversion rate is!
        // uint256 latestPriceInUSDC = getLatestPrice();
        // uint256 minimumUSDC = 50 * 10 ** 18;
        // require((msg.value*latestPriceInUSDC)/1*10**18 >= 500 * 10**18);

        addressToAmountFunded[msg.sender] += msg.value;
    }

    function getLatestPrice(AggregatorV3Interface _priceFeed)
        public
        view
        returns (uint256)
    {
        (, int256 price, , , ) = _priceFeed.latestRoundData();

        return uint256(price);
    }

    // function getConversionRate(uint256 ethAmount) public view returns(uint256){
    //     uint256 latestPrice = getLatestPrice();
    //     return ((ethAmount*latestPrice)/ 10 ** 10);
    // }

    // function getConversionRate(uint256 ethAmount)

    function fundsFromAddress(address _address) public view returns (uint256) {
        return addressToAmountFunded[_address];
    }
}