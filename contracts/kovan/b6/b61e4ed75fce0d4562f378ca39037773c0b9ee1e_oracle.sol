/**
 *Submitted for verification at Etherscan.io on 2021-07-01
*/

// File: @chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

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

// File: oracle.sol


interface Oracle {
    function setEthererumPrice() external;
    function getEthererumPrice() external view returns(int);
    function setBitcoinPrice() external;
    function getBitcoinPrice() external view returns(int);
    function setBnbPrice() external;
    function getBnbPrice() external view returns(int);
}

contract oracle {
    AggregatorV3Interface internal priceFeed1;
    AggregatorV3Interface internal priceFeed2;
    AggregatorV3Interface internal priceFeed3;
    constructor() {
        priceFeed1=AggregatorV3Interface(0x9326BFA02ADD2366b30bacB125260Af641031331);
        priceFeed2=AggregatorV3Interface(0x6135b13325bfC4B00278B4abC5e20bbce2D6580e);
        priceFeed3=AggregatorV3Interface(0x8993ED705cdf5e84D0a3B754b5Ee0e1783fcdF16);
    }
    int ethereumPrice;
    int bitcoinPrice;
    int bnbPrice;
    function setEthererumPrice() public {
    
        (, int price, , ,) = priceFeed1.latestRoundData();
            ethereumPrice = price;
    }
    
    function getEthererumPrice() public view returns(int) {
            return ethereumPrice;
    }
    
    function setBitcoinPrice() public {
        (, int price, , ,) = priceFeed2.latestRoundData();
            bitcoinPrice = price;
    }
    
    function getBitcoinPrice() public view returns(int) {
            return bitcoinPrice;
    }
    
    function setBnbPrice() public {
        (, int price, , ,) = priceFeed3.latestRoundData();
            bnbPrice = price;
    }
    
    function getBnbPrice() public view returns(int) {
            return bnbPrice;
    }
}