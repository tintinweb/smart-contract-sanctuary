// SPDX-License-Identifier: agpl-3.0

pragma solidity 0.6.12;

import "../interfaces/IPriceFeed.sol";

contract MockChainlinkFeed is IPriceFeed {
    uint8 private _decimals;
    int256 private _currentPrice;
    uint256 private _updatedAt;
    address public assetFeed;

    constructor(
        address _assetFeed,
        uint8 _answerDecimals,
        int256 _initialPrice
    ) public {
        _decimals = _answerDecimals;
        _currentPrice = _initialPrice;
        assetFeed = _assetFeed;
        _updatedAt = block.timestamp;
    }

    function setPrice(int256 newPrice) external returns (int256) {
        _currentPrice = newPrice;
        _updatedAt = block.timestamp;
        return _currentPrice;
    }

    function getLatestPrice() external override view returns (int256, uint256) {
        return (_currentPrice, _updatedAt);
    }

    function latestRoundData()
        external
        override
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        return (1, _currentPrice, 1, _updatedAt, uint80(_currentPrice));
    }

    function decimals() external override view returns (uint8) {
        return _decimals;
    }
}

// SPDX-License-Identifier: agpl-3.0

pragma solidity 0.6.12;

interface IPriceFeed {
    function getLatestPrice() external view returns (int256, uint256);

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

    function decimals() external view returns (uint8);
}

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}