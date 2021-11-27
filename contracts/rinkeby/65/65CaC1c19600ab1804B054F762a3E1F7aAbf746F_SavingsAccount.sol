// SPDX-License-Identifier: MIT

pragma solidity >=0.8 <0.9.0;

import "PriceFeedConsumer.sol";


contract SavingsAccount is PriceFeedConsumer {

    address public owner;
    uint256 public currentDate;
    uint256 public targetDate;
    uint256 public currentEthPrice;
    uint256 public ethBreakEvenPrice = 0;
    uint256[] public pricesFunded;
    uint256[] public valuesFunded;


    constructor(address _priceFeed, uint256 _targetDate) PriceFeedConsumer(_priceFeed) {
        owner = msg.sender;
        currentDate = block.timestamp;
        currentEthPrice = uint256(getLatestPrice());
        require(_targetDate > currentDate);
        targetDate = _targetDate;
    }

    // Anyone can fund the contract
    receive () external payable {
        currentEthPrice = uint256(getLatestPrice());
        pricesFunded.push(currentEthPrice);
        valuesFunded.push(msg.value);
        calculateEthBEP();
    }

  
  function calculateEthBEP() public {
      // BEP = SUM(amount * price)/balance
      require(pricesFunded.length == valuesFunded.length);
      uint256 valueTimesPriceSum = 0;
      for (uint256 i=0; i < pricesFunded.length ; i++) {
          valueTimesPriceSum += valuesFunded[i] * pricesFunded[i];
        }
        ethBreakEvenPrice = valueTimesPriceSum/address(this).balance;
  }
  
  function withdraw() public payable {
        require(msg.sender == owner);
        currentEthPrice = uint256(getLatestPrice());
        currentDate = block.timestamp;
        require(currentEthPrice > ethBreakEvenPrice || currentDate >= targetDate);
        payable(owner).transfer(address(this).balance);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "AggregatorV3Interface.sol";

contract PriceFeedConsumer {

    AggregatorV3Interface internal priceFeed;

    /**
     * Network: Kovan
     * Aggregator: ETH/USD
     * Address: 0x9326BFA02ADD2366b30bacB125260Af641031331
     */
    /**
     * Network: Mainnet
     * Aggregator: ETH/USD
     * Address: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
     */
    constructor(address AggregatorAddress) {
        priceFeed = AggregatorV3Interface(AggregatorAddress);
    }

    /**
     * Returns the latest price
     */
    function getLatestPrice() public view returns (int) {
        (
            uint80 roundID, 
            int price,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();
        return price;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
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