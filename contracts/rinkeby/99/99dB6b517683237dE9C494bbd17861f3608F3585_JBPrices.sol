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

// SPDX-License-Identifier: MIT

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

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
pragma solidity 0.8.6;

import '@openzeppelin/contracts/access/Ownable.sol';

import './interfaces/IJBPrices.sol';

/** 
  @notice Manages and normalizes price feeds.
*/
contract JBPrices is IJBPrices, Ownable {
  //*********************************************************************//
  // ---------------- public constant stored properties ---------------- //
  //*********************************************************************//

  /** 
    @notice 
    The normalized number of decimals each price feed has.
  */
  uint256 public constant override TARGET_DECIMALS = 18;

  //*********************************************************************//
  // --------------------- public stored properties -------------------- //
  //*********************************************************************//

  /** 
    @notice 
    The available price feeds.

    _currency he currency of the feed.
    _base he base of the feed. 
  */
  mapping(uint256 => mapping(uint256 => AggregatorV3Interface)) public override feedFor;

  //*********************************************************************//
  // ------------------------- external views -------------------------- //
  //*********************************************************************//

  /** 
      @notice 
      Gets the current price of the provided currency in terms of the provided base currency.
      
      @param _currency The currency to get a price for.
      @param _base The currency to base the price on.
      
      @return The price of the currency in terms of the base, with 18 decimals.
    */
  function priceFor(uint256 _currency, uint256 _base) external view override returns (uint256) {
    // If the currency is the base, return 1 since they are priced the same.
    if (_currency == _base) return 10**TARGET_DECIMALS;

    // Get a reference to the feed.
    AggregatorV3Interface _feed = feedFor[_currency][_base];

    // Feed must exist.
    require(_feed != AggregatorV3Interface(address(0)), '0x03: NOT_FOUND');

    // Get the latest round information. Only need the price is needed.
    (, int256 _price, , , ) = _feed.latestRoundData();

    // Get a reference to the number of decimals the feed uses.
    uint256 _decimals = _feed.decimals();

    // If decimals need adjusting, multiply or divide the price by the decimal adjuster to get the normalized result.
    if (TARGET_DECIMALS == _decimals) {
      return uint256(_price);
    } else if (TARGET_DECIMALS > _decimals) {
      return uint256(_price) * 10**(TARGET_DECIMALS - _decimals);
    } else {
      return uint256(_price) / 10**(_decimals - TARGET_DECIMALS);
    }
  }

  //*********************************************************************//
  // ---------------------------- constructor -------------------------- //
  //*********************************************************************//

  /** 
    @param _owner The address that will own the contract.
  */
  constructor(address _owner) {
    // Transfer the ownership.
    transferOwnership(_owner);
  }

  //*********************************************************************//
  // ---------------------- external transactions ---------------------- //
  //*********************************************************************//

  /** 
    @notice 
    Add a price feed for a currency in terms of the provided base currency.

    @dev
    Current feeds can't be modified.

    @param _currency The currency that the price feed is for.
    @param _base The currency that the price feed is based on.
    @param _feed The price feed being added.
  */
  function addFeedFor(
    uint256 _currency,
    uint256 _base,
    AggregatorV3Interface _feed
  ) external override onlyOwner {
    // There can't already be a feed for the specified currency.
    require(feedFor[_currency][_base] == AggregatorV3Interface(address(0)), '0x04: ALREADY_EXISTS');

    // Set the feed.
    feedFor[_currency][_base] = _feed;

    emit AddFeed(_currency, _base, _feed);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import '@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol';

interface IJBPrices {
  event AddFeed(uint256 indexed currency, uint256 indexed base, AggregatorV3Interface feed);

  function TARGET_DECIMALS() external returns (uint256);

  function feedFor(uint256 _currency, uint256 _base) external returns (AggregatorV3Interface);

  function priceFor(uint256 _currency, uint256 _base) external view returns (uint256);

  function addFeedFor(
    uint256 _currency,
    uint256 _base,
    AggregatorV3Interface _priceFeed
  ) external;
}