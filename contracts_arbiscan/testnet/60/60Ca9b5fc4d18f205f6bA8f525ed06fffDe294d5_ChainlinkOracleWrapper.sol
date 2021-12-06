//SPDX-License-Identifier: CC-BY-NC-ND-4.0
pragma solidity 0.8.7;

import "../interfaces/IOracleWrapper.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV2V3Interface.sol";

/// @title The oracle management contract for chainlink V3 oracles
contract ChainlinkOracleWrapper is IOracleWrapper {
    // #### Globals
    /**
     * @notice The address of the feed oracle
     */
    address public override oracle;
    address public immutable override deployer;
    uint256 private constant MAX_DECIMALS = 18;
    int256 public scaler;

    // #### Functions
    constructor(address _oracle, address _deployer) {
        require(_oracle != address(0), "Oracle cannot be 0 address");
        oracle = _oracle;
        deployer = _deployer;
        // reset the scaler for consistency
        uint8 _decimals = AggregatorV2V3Interface(oracle).decimals();
        require(_decimals <= MAX_DECIMALS, "COA: too many decimals");
        // scaler is always <= 10^18 and >= 1 so this cast is safe
        unchecked {
            scaler = int256(10**(MAX_DECIMALS - _decimals));
        }
    }

    /**
     * @notice Returns the oracle price in WAD format
     */
    function getPrice() external view override returns (int256 _price) {
        (_price, ) = _latestRoundData();
    }

    /**
     * @return _price The latest round data price
     * @return _data The metadata. Implementations can choose what data to return here. This implementation returns the roundID
     */
    function getPriceAndMetadata() external view override returns (int256 _price, bytes memory _data) {
        (int256 price, uint80 roundID) = _latestRoundData();
        _data = abi.encodePacked(roundID);
        return (price, _data);
    }

    /**
     * @dev An internal function that gets the WAD value price and latest roundID
     */
    function _latestRoundData() internal view returns (int256 _price, uint80 _roundID) {
        (uint80 roundID, int256 price, , uint256 timeStamp, uint80 answeredInRound) = AggregatorV2V3Interface(oracle)
            .latestRoundData();
        require(answeredInRound >= roundID, "COA: Stale answer");
        require(timeStamp != 0, "COA: Round incomplete");
        return (toWad(price), roundID);
    }

    /**
     * @notice Converts a raw value to a WAD value based on the decimals in the feed
     * @dev This allows consistency for oracles used throughout the protocol
     *      and allows oracles to have their decimals changed without affecting
     *      the market itself
     */
    function toWad(int256 raw) internal view returns (int256) {
        return raw * scaler;
    }

    /**
     * @notice Converts from a WAD value to a raw value based on the decimals in the feed
     */
    function fromWad(int256 wad) external view override returns (int256) {
        return wad / scaler;
    }

    function poll() external view override returns (int256) {
        (int256 _price, ) = _latestRoundData();
        return _price;
    }
}

//SPDX-License-Identifier: CC-BY-NC-ND-4.0
pragma solidity 0.8.7;

/// @title The oracle wrapper contract interface
interface IOracleWrapper {
    function oracle() external view returns (address);

    function deployer() external view returns (address);

    // #### Functions

    /**
     * @notice Returns the current price for the asset in question
     * @return The latest price
     */
    function getPrice() external view returns (int256);

    /**
     * @return _price The latest round data price
     * @return _data The metadata. Implementations can choose what data to return here
     */
    function getPriceAndMetadata() external view returns (int256 _price, bytes memory _data);

    /**
     * @notice Converts from a WAD to normal value
     * @return Converted non-WAD value
     */
    function fromWad(int256 wad) external view returns (int256);

    /**
     * @notice Updates the underlying oracle state and returns the new price
     * @dev Spot oracles must implement but it will be a no-op
     */
    function poll() external returns (int256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AggregatorInterface.sol";
import "./AggregatorV3Interface.sol";

interface AggregatorV2V3Interface is AggregatorInterface, AggregatorV3Interface
{
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorInterface {
  function latestAnswer()
    external
    view
    returns (
      int256
    );
  
  function latestTimestamp()
    external
    view
    returns (
      uint256
    );

  function latestRound()
    external
    view
    returns (
      uint256
    );

  function getAnswer(
    uint256 roundId
  )
    external
    view
    returns (
      int256
    );

  function getTimestamp(
    uint256 roundId
  )
    external
    view
    returns (
      uint256
    );

  event AnswerUpdated(
    int256 indexed current,
    uint256 indexed roundId,
    uint256 updatedAt
  );

  event NewRound(
    uint256 indexed roundId,
    address indexed startedBy,
    uint256 startedAt
  );
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