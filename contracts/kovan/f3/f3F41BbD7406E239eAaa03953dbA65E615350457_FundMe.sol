// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "AggregatorV3Interface.sol";

contract FundMe {
    mapping(address => uint256) public addressToFundMapping;
    // decimal helper;

    address[] public funders;
    uint8 weiDecimal = 18;
    // always in wei
    address owner;
    uint256 MIN_USD = 50;
    AggregatorV3Interface public priceFeed;

    constructor(address _priceFeed) {
        priceFeed = AggregatorV3Interface(_priceFeed);
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "You are not the owner");
        _;
    }

    function fundersCount() public view returns (uint256) {
        return funders.length;
    }

    function fund() public payable returns (uint256) {
        uint256 minUsd = uint256(scaleNumber(int256(MIN_USD), 0, weiDecimal));
        require(getConversionRate(msg.value) >= minUsd, "Not enough eth");
        addressToFundMapping[msg.sender] += msg.value;
        funders.push(msg.sender);
        return msg.value;
    }

    function withdraw() public payable onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
        for (uint256 i = 0; i < funders.length; i++) {
            addressToFundMapping[funders[i]] = 0;
        }
        funders = new address[](0);
    }

    // Non-Eth Pair (ETH as the denominator e.g. USD/ETH)
    // has 8 decimal. See  https://docs.chain.link/docs/ethereum-addresses/
    // Alternatively, use the price feed .decimals()
    // returns in wei, so 10^18
    function getEthPrice() public view returns (uint256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        uint8 baseDecimal = priceFeed.decimals();
        price = scaleNumber(price, baseDecimal, weiDecimal);
        return uint256(price);
    }

    function getEntranceFee() public view returns (uint256) {
        uint256 minUsd = uint256(
            scaleNumber(int256(MIN_USD), 0, weiDecimal * 2)
        );
        uint256 price = getEthPrice();
        // 50 * 10 ** 36 / price per usd * 10**18
        // This is because returned value must be
        // decimal of 18 to return price per WEI
        return minUsd / price;
    }

    function getVersion() public view returns (uint256) {
        return priceFeed.version();
    }

    // input in wei, 10^9 for 1 Gwei, 10^18 for 1 Eth
    function getConversionRate(uint256 weiAmount)
        public
        view
        returns (uint256)
    {
        uint256 ethPrice = getEthPrice();
        uint256 ethAmountInUsd = ethPrice * weiAmount;
        //basedecimal is 18+18
        return uint256(scaleNumber(int256(ethAmountInUsd), 36, weiDecimal));
    }

    // Using scale number is actually a waste of gas fee,
    // so should be minimized in actual contract
    function scaleNumber(
        int256 number,
        uint8 decimal,
        uint8 targetDecimal
    ) internal pure returns (int256) {
        if (decimal > targetDecimal) {
            return number / int256(10**uint256(decimal - targetDecimal));
        } else if (decimal < targetDecimal) {
            return number * int256(10**uint256(targetDecimal - decimal));
        }
        return number;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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