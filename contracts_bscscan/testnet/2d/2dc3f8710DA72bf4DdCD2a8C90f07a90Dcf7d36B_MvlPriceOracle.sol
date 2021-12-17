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

pragma solidity 0.8.8;

interface IMvlPriceOracle {
  function getCurrentWeightedAveragePrice() external view returns (uint256 price);

  function getCurrentPrice() external view returns (uint256 currentPrice);

  function setCurrentPrice(uint256 price) external;

  function getMaxCount() external view returns (uint256 maxCount);

  function setMaxCount(uint256 maxCount) external;

  function resetCount() external;
}

// SPDX-License-Identifier: MIT

import '@openzeppelin/contracts/access/Ownable.sol';
import '../interfaces/IMvlPriceOracle.sol';

pragma solidity 0.8.8;

contract MvlPriceOracle is IMvlPriceOracle, Ownable {
  constructor() {
    _maxCount = 1000;
  }

  uint256 public counts;

  uint256 internal _currentPrice;
  uint256 internal _weightedPrice;
  uint256 internal _maxCount;

  /// @notice Return weighted averaged mvl token price with 18 decimals
  function getCurrentWeightedAveragePrice() external view returns (uint256 weightedPrice) {
    weightedPrice = _weightedPrice;
  }

  /// @notice Return current mvl token price with 18 decimals
  function getCurrentPrice() external view returns (uint256 currentPrice) {
    currentPrice = _currentPrice;
  }

  /// @notice This function weights average of newly input values to the previously calculated values.
  /// The weighted average runs until the price input number is `_maxCount`.
  function setCurrentPrice(uint256 price) external onlyOwner {
    _weightedPrice = _weightPrice(price);
    _currentPrice = price;
  }

  /// @notice This functions maxCount which is the number of count weighting price average
  /// The initial value is 60 * 24 * 7 / 10 ~ 1000.
  function getMaxCount() external view returns (uint256 maxCount) {
    maxCount = _maxCount;
  }

  /// @notice Set maxCount. It depends on
  function setMaxCount(uint256 maxCount) external onlyOwner {
    _maxCount = maxCount;
  }

  function resetCount() external onlyOwner {
    counts = 0;
  }

  function _weightPrice(uint256 price) internal returns (uint256 weightedPrice) {
    uint256 previousPrice = _weightedPrice;

    uint256 priceMul = previousPrice * counts + price;
    uint256 denominator = counts + 1;

    if (counts < _maxCount) {
      counts++;
    }

    weightedPrice = priceMul / denominator;
  }
}