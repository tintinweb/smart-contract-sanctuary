// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "../interfaces/IOracle.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract ChainlinkOracle is IOracle {
	address public immutable override token;
	AggregatorV3Interface public immutable priceFeed;

	constructor(address token_, address priceFeed_) {
		require(token_ != address(0), "CO: ZR ADDR");
		token = token_;
		(, int256 price, , , ) = AggregatorV3Interface(priceFeed_).latestRoundData();
		require(price != 0, "BO: PF INV");
		priceFeed = AggregatorV3Interface(priceFeed_);
	}

	function query() external view override returns (uint256) {
		(, int256 price, , , ) = priceFeed.latestRoundData();
		return uint256(price);
	}
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

interface IOracle {
	function query() external view returns (uint256 price_);

	function token() external view returns (address token_);
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