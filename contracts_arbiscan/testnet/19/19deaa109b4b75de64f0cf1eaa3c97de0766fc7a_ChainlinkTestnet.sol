/**
 *Submitted for verification at arbiscan.io on 2022-01-26
*/

// Sources flattened with hardhat v2.6.4 https://hardhat.org

// File @chainlink/contracts/src/v0.8/interfaces/[email protected]

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


// File contracts/Interfaces/IPriceFeed.sol


pragma solidity ^0.8.10;

interface IPriceFeed {
	struct ChainlinkResponse {
		uint80 roundId;
		int256 answer;
		uint256 timestamp;
		bool success;
		uint8 decimals;
	}

	struct TellorResponse {
		bool ifRetrieve;
		uint256 value;
		uint256 timestamp;
		bool success;
	}

	struct RegisterOracle {
		AggregatorV3Interface chainLinkOracle;
		uint256 tellorId;
		bool isRegistered;
	}

	enum Status {
		chainlinkWorking,
		usingTellorChainlinkUntrusted,
		bothOraclesUntrusted,
		usingTellorChainlinkFrozen,
		usingChainlinkTellorUntrusted
	}

	// --- Events ---
	event PriceFeedStatusChanged(Status newStatus);
	event LastGoodPriceUpdated(
		address indexed token,
		uint256 _lastGoodPrice
	);
	event RegisteredNewOracle(
		address indexed token,
		address indexed chainLinkAggregator,
		uint256 indexed tellorId
	);

	// --- Function ---
	function addOracle(
		address _token,
		address _chainlinkOracle,
		uint256 _tellorId
	) external;

	function fetchPrice(address _token) external returns (uint256);
}


// File contracts/TestContracts/PriceFeedTestnet.sol


pragma solidity ^0.8.10;

/*
 * PriceFeed placeholder for testnet and development. The price is simply set manually and saved in a state
 * variable. The contract does not connect to a live Chainlink price feed.
 */
contract PriceFeedTestnet is IPriceFeed {
	uint256 private _price = 200 * 1 ether;

	// --- Functions ---

	// View price getter for simplicity in tests
	function getPrice() external view returns (uint256) {
		return _price;
	}

	function addOracle(
		address _token,
		address _chainlinkOracle,
		uint256 _tellorId
	) external override {}

	function fetchPrice(address _asset) external override returns (uint256) {
		// Fire an event just like the mainnet version would.
		// This lets the subgraph rely on events to get the latest price even when developing locally.
		emit LastGoodPriceUpdated(_asset, _price);
		return _price;
	}

	// Manual external price setter.
	function setPrice(uint256 price) external returns (bool) {
		_price = price;
		return true;
	}
}


// File contracts/B.Protocol/ChainlinkTestnet.sol


pragma solidity 0.8.10;

/*
* PriceFeed placeholder for testnet and development. The price is simply set manually and saved in a state 
* variable. The contract does not connect to a live Chainlink price feed. 
*/
contract ChainlinkTestnet {
    
    PriceFeedTestnet feed;
    uint time = 0;

    constructor(PriceFeedTestnet _feed) public {
        feed = _feed;
    }

    function decimals() external pure returns(uint) {
        return 18;
    }

    function setTimestamp(uint _time) external {
        time = _time;
    }

    function latestRoundData() external view returns
     (
        uint80 /* roundId */,
        int256 answer,
        uint256 /* startedAt */,
        uint256 timestamp,
        uint80 /* answeredInRound */
    )
    {
        answer = int(feed.getPrice());
        if(time == 0 ) timestamp = block.timestamp;
        else timestamp = time;
    }
}