// contracts/GLDToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";

contract PriceConsumerV3 {

    AggregatorV3Interface internal priceFeed;

    // uint[] a = new uint[](7);

    address[] a;
    
    //  = [
    //   0x6135b13325bfC4B00278B4abC5e20bbce2D6580e,
    //   0x9326BFA02ADD2366b30bacB125260Af641031331,
    //   0x8993ED705cdf5e84D0a3B754b5Ee0e1783fcdF16,
    //   0x3eA2b7e3ed9EA9120c3d6699240d1ff2184AC8b3,
    //   0xDA5904BdBfB4EF12a3955aEcA103F51dc87c7C39,
    //   0x396c5E36DD0a0F5a5D33dae44368D4193f69a1F0
    // ];
    /**
     * Network: Kovan
     * Aggregator: ETH/USD
     * Address: 0x9326BFA02ADD2366b30bacB125260Af641031331
     */
    constructor() {
        priceFeed = AggregatorV3Interface(0x9326BFA02ADD2366b30bacB125260Af641031331);
        a.push(0x6135b13325bfC4B00278B4abC5e20bbce2D6580e);
        a.push(0x9326BFA02ADD2366b30bacB125260Af641031331);
        a.push(0x8993ED705cdf5e84D0a3B754b5Ee0e1783fcdF16);
        a.push(0x3eA2b7e3ed9EA9120c3d6699240d1ff2184AC8b3);
        a.push(0xDA5904BdBfB4EF12a3955aEcA103F51dc87c7C39);
        a.push(0x396c5E36DD0a0F5a5D33dae44368D4193f69a1F0);
    }

    /**
     * Returns the latest price
     */
    function getThePrice() public view returns (int) {
        (
            uint80 roundID, 
            int price,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();
        return price;
    }

    function getPrice() public view returns(int) {

      int total = 0;
      for (uint i=0; i<a.length; i++) {
         (
            uint80 roundID, 
            int price,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
        ) = AggregatorV3Interface(a[i]).latestRoundData();
        total+= price;
      }

      int length = int(a.length);

      // return length;

      return total / length;

    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

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

{
  "remappings": [],
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "evmVersion": "byzantium",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}