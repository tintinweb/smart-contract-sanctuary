// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7 <0.9.0;

import './PriceOracleConstants.sol';
import './PriceOracleQueriesHandler.sol';

contract PriceOracle is PriceOracleConstants, PriceOracleQueriesHandler, IPriceOracle {
  function decimals() public pure override(PriceOracleConstants, AggregatorV3Interface) returns (uint8) {
    return super.decimals();
  }

  function description() public pure override(PriceOracleConstants, AggregatorV3Interface) returns (string memory) {
    return super.description();
  }

  function version() public pure override(PriceOracleConstants, AggregatorV3Interface) returns (uint256) {
    return super.version();
  }

  function getRoundData(uint80 _roundId)
    public
    view
    override(PriceOracleQueriesHandler, AggregatorV3Interface)
    returns (
      uint80,
      int256,
      uint256,
      uint256,
      uint80
    )
  {
    return super.getRoundData(_roundId);
  }

  function latestRoundData()
    public
    view
    override(PriceOracleQueriesHandler, AggregatorV3Interface)
    returns (
      uint80,
      int256,
      uint256,
      uint256,
      uint80
    )
  {
    return super.latestRoundData();
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7 <0.9.0;

import '@openzeppelin/contracts/utils/math/SafeCast.sol';
import './PriceOracleUpdateHandler.sol';

abstract contract PriceOracleConstants {
  function decimals() public pure virtual returns (uint8) {
    return 8;
  }

  function description() public pure virtual returns (string memory) {
    return 'RPS / USD';
  }

  function version() public pure virtual returns (uint256) {
    return 4;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7 <0.9.0;

import '@openzeppelin/contracts/utils/math/SafeCast.sol';
import './PriceOracleUpdateHandler.sol';

abstract contract PriceOracleQueriesHandler is PriceOracleUpdateHandler {
  using SafeCast for uint224;

  function getRoundData(uint80 _roundId)
    public
    view
    virtual
    returns (
      uint80,
      int256,
      uint256,
      uint256,
      uint80
    )
  {
    require(_roundId > 0 && _roundId <= _lastRound, 'No data present');
    RoundData memory _round = _rounds[_roundId];
    return (_roundId, _round.price.toInt256(), _round.updatedAt, _round.updatedAt, _roundId);
  }

  function latestRoundData()
    public
    view
    virtual
    returns (
      uint80,
      int256,
      uint256,
      uint256,
      uint80
    )
  {
    require(_lastRound > 0, 'No data present');
    return getRoundData(_lastRound);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/math/SafeCast.sol)

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7 <0.9.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import '../interfaces/IPriceOracle.sol';

contract PriceOracleUpdateHandler is Ownable, IPriceOracleUpdateHandler {
  struct RoundData {
    uint224 price;
    uint32 updatedAt;
  }

  mapping(address => bool) internal _canAddressUpdate;
  mapping(uint80 => RoundData) internal _rounds;
  uint80 internal _lastRound;

  /// @inheritdoc IPriceOracleUpdateHandler
  function canAddressUpdate(address _address) public view returns (bool) {
    return _address == owner() || _canAddressUpdate[_address];
  }

  /// @inheritdoc IPriceOracleUpdateHandler
  function setAddressPermission(address _address, bool _permission) external onlyOwner {
    if (_address == address(0)) revert ZeroAddress();
    _canAddressUpdate[_address] = _permission;
    emit UpdatePermissionChanged(_address, _permission);
  }

  /// @inheritdoc IPriceOracleUpdateHandler
  function updatePrice(uint224 _price) external {
    if (_price == 0) revert ZeroPrice();
    if (!canAddressUpdate(msg.sender)) revert CallerCannotUpdatePrice();

    _rounds[++_lastRound] = RoundData({price: _price, updatedAt: uint32(block.timestamp)});

    emit PriceUpdated(_price, msg.sender);
  }
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
pragma solidity >=0.8.7 <0.9.0;

import '@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol';
import './IShared.sol';

/// @notice Handles everything related to the price update
interface IPriceOracleUpdateHandler {
  /// @notice Emitted when permissions are modified for an address
  /// @param _address The address that will have their update permissions modified
  /// @param permission Whether the given address will be able to update the price or not
  event UpdatePermissionChanged(address _address, bool permission);

  /// @notice Emitted then the price is updated
  /// @param price The new price
  /// @param updatedBy The caller who updated the price
  event PriceUpdated(uint224 price, address updatedBy);

  /// @notice Thrown when a user tries to set `0` as price
  error ZeroPrice();

  /// @notice Thrown when a user that does not have permissions to update the price, tries to do so
  error CallerCannotUpdatePrice();

  /// @notice Returns whether a specific address can update the price
  /// @param _address The address to check
  /// @return Whether the given address can update the price
  function canAddressUpdate(address _address) external view returns (bool);

  /// @notice Sets whether the given address can update the price or not
  /// @param _address The address to modify permissions for
  /// @param permission Whether the given addres should be able to update the price or not
  function setAddressPermission(address _address, bool permission) external;

  /// @notice Updates the price
  /// @dev Will revert with:
  /// `ZeroPrice` if the given price is 0
  /// `CallerCannotUpdatePrice` is the caller cannot update the price
  /// @param price The new price
  function updatePrice(uint224 price) external;
}

interface IPriceOracle is IPriceOracleUpdateHandler, AggregatorV3Interface {}

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

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7 <0.9.0;

/// @notice Thrown when one of the parameters is a zero address
error ZeroAddress();

/// @notice Thrown when trying to set an empty string as a base for the URI
error EmptyBaseURI();

/// @notice Thrown when trying to perform an action or query with a token id that does not exist
error InexistentToken();

/// @notice Thrown when a user tries to use an unsupported NFT type
error UnsupportedNFTType();