//SPDX-License-Identifier: CC-BY-NC-ND-4.0
pragma solidity 0.8.7;

import "../interfaces/IOracleWrapper.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV2V3Interface.sol";

/// @title The oracle management contract for chainlink V3 oracles
contract ChainlinkOracleWrapper is IOracleWrapper, Ownable {
    // #### Globals
    /**
     * @notice The address of the feed oracle
     */
    address public override oracle;
    uint256 private constant MAX_DECIMALS = 18;
    int256 public scaler;

    // #### Functions
    constructor(address _oracle) {
        setOracle(_oracle);
    }

    /**
     * @notice Sets the address of the underlying oracle and related information
     * @param _oracle New address
     */
    function setOracle(address _oracle) public override onlyOwner {
        require(_oracle != address(0), "Oracle cannot be 0 address");
        oracle = _oracle;
        // reset the scaler for consistency
        uint8 _decimals = AggregatorV2V3Interface(oracle).decimals();
        require(_decimals <= MAX_DECIMALS, "COA: too many decimals");
        // scaler is always <= 10^18 and >= 1 so this cast is safe
        scaler = int256(10**(MAX_DECIMALS - _decimals));
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
        (
            uint80 roundID,
            int256 price,
            uint256 startedAt,
            uint256 timeStamp,
            uint80 answeredInRound
        ) = AggregatorV2V3Interface(oracle).latestRoundData();
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
}

//SPDX-License-Identifier: CC-BY-NC-ND-4.0
pragma solidity 0.8.7;

/// @title The oracle wrapper contract interface
interface IOracleWrapper {
    function oracle() external view returns (address);

    // #### Functions
    /**
     * @notice Sets the oracle for a given market
     * @dev Should be secured, ideally only allowing the PoolKeeper to access
     * @param _oracle The oracle to set for the market
     */
    function setOracle(address _oracle) external;

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AggregatorInterface.sol";
import "./AggregatorV3Interface.sol";

interface AggregatorV2V3Interface is AggregatorInterface, AggregatorV3Interface
{
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
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