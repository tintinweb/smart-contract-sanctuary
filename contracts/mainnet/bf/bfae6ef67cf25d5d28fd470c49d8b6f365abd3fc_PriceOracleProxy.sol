/**
 *Submitted for verification at Etherscan.io on 2021-03-02
*/

/*

    Copyright 2019 The Hydro Protocol Foundation

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/

pragma solidity ^0.6.7;

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


// asset ETH

contract PriceOracleProxy {
    address asset;
    AggregatorV3Interface internal priceFeed;
    
    constructor() public {
        priceFeed = AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);
        asset = 0x000000000000000000000000000000000000000E;
    }

    function getPrice(
        address _asset
    )
        external
        view
        returns (uint256)
    {
        require(asset == _asset, "ASSET_NOT_MATCH");
        (,int lastPrice,,,) = priceFeed.latestRoundData();
        require(lastPrice >= 0, "INVALID_NEGATIVE_PRICE");
        
        uint256 price = uint256(lastPrice);
        
        // convert 8 decimals to 18 decimals
        uint256 hydroPrice = price * 10 ** (18 - 8);
        require(hydroPrice / price == 10 ** (18 - 8), "MUL_ERROR");
        
        return hydroPrice;
    }
}