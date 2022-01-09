//SPDX-License-Identifier: MIT

pragma solidity ^0.8;

import "AggregatorV3Interface.sol";

contract DETF {
    address[] public assetsAddresses;

    event AddressAdded(address _assetAddress);

    function isPresent(address _assetAddress) internal view returns (bool) {
        for (uint256 index = 0; index < assetsAddresses.length; index++) {
            if (assetsAddresses[index] == _assetAddress) {
                return true;
            }
        }
        return false;
    }

    function addAssetAddress(address _assetAddress) public {
        require(_assetAddress != address(0));
        require(!isPresent(_assetAddress));
        assetsAddresses.push(_assetAddress);
        emit AddressAdded(_assetAddress);
    }

    function getAssetPrice(address _assetAddress)
        private
        view
        returns (uint256)
    {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(_assetAddress);
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return uint256(price);
    }

    function getDETFCurrentPrice() public view returns (uint256) {
        uint256 totalPrice = 0;
        uint256 index = 0;
        for (; index < assetsAddresses.length; index++) {
            totalPrice += getAssetPrice(assetsAddresses[index]);
        }
        return totalPrice / index;
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