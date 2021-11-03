/**
 *Submitted for verification at Etherscan.io on 2020-12-01
*/

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.5;
pragma experimental ABIEncoderV2;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
  /**
   * @dev Returns the addition of two unsigned integers, reverting on
   * overflow.
   *
   * Counterpart to Solidity's `+` operator.
   *
   * Requirements:
   * - Addition cannot overflow.
   */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, 'SafeMath: addition overflow');

    return c;
  }

  /**
   * @dev Returns the subtraction of two unsigned integers, reverting on
   * overflow (when the result is negative).
   *
   * Counterpart to Solidity's `-` operator.
   *
   * Requirements:
   * - Subtraction cannot overflow.
   */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    return sub(a, b, 'SafeMath: subtraction overflow');
  }

  /**
   * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
   * overflow (when the result is negative).
   *
   * Counterpart to Solidity's `-` operator.
   *
   * Requirements:
   * - Subtraction cannot overflow.
   */
  function sub(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b <= a, errorMessage);
    uint256 c = a - b;

    return c;
  }

  /**
   * @dev Returns the multiplication of two unsigned integers, reverting on
   * overflow.
   *
   * Counterpart to Solidity's `*` operator.
   *
   * Requirements:
   * - Multiplication cannot overflow.
   */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, 'SafeMath: multiplication overflow');

    return c;
  }

  /**
   * @dev Returns the integer division of two unsigned integers. Reverts on
   * division by zero. The result is rounded towards zero.
   *
   * Counterpart to Solidity's `/` operator. Note: this function uses a
   * `revert` opcode (which leaves remaining gas untouched) while Solidity
   * uses an invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   * - The divisor cannot be zero.
   */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return div(a, b, 'SafeMath: division by zero');
  }

  /**
   * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
   * division by zero. The result is rounded towards zero.
   *
   * Counterpart to Solidity's `/` operator. Note: this function uses a
   * `revert` opcode (which leaves remaining gas untouched) while Solidity
   * uses an invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   * - The divisor cannot be zero.
   */
  function div(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    // Solidity only automatically asserts when dividing by 0
    require(b > 0, errorMessage);
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  /**
   * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
   * Reverts when dividing by zero.
   *
   * Counterpart to Solidity's `%` operator. This function uses a `revert`
   * opcode (which leaves remaining gas untouched) while Solidity uses an
   * invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   * - The divisor cannot be zero.
   */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    return mod(a, b, 'SafeMath: modulo by zero');
  }

  /**
   * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
   * Reverts with custom message when dividing by zero.
   *
   * Counterpart to Solidity's `%` operator. This function uses a `revert`
   * opcode (which leaves remaining gas untouched) while Solidity uses an
   * invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   * - The divisor cannot be zero.
   */
  function mod(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b != 0, errorMessage);
    return a % b;
  }
}

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
  function _msgSender() internal view virtual returns (address payable) {
    return msg.sender;
  }

  function _msgData() internal view virtual returns (bytes memory) {
    this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    return msg.data;
  }
}

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
contract Ownable is Context {
  address private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev Initializes the contract setting the deployer as the initial owner.
   */
  constructor() {
    address msgSender = _msgSender();
    _owner = msgSender;
    emit OwnershipTransferred(address(0), msgSender);
  }

  /**
   * @dev Returns the address of the current owner.
   */
  function owner() public view returns (address) {
    return _owner;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(_owner == _msgSender(), 'Ownable: caller is not the owner');
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
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   */
  function transferOwnership(address newOwner) public virtual onlyOwner {
    require(newOwner != address(0), 'Ownable: new owner is the zero address');
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

/**
 * @title IPriceOracleGetter interface
 * @notice Interface for the Aave price oracle.
 **/

interface IPriceOracleGetter {
  /**
   * @dev returns the asset price in ETH wei
   * @param asset the address of the asset
   **/
  function getAssetPrice(address asset) external view returns (uint256);
}

contract AaveFallbackOracle is Ownable, IPriceOracleGetter {
  using SafeMath for uint256;

  struct Price {
    uint64 blockNumber;
    uint64 blockTimestamp;
    uint128 price;
  }

  event PricesSubmitted(address sybil, address[] assets, uint128[] prices);
  event SybilAuthorized(address indexed sybil);
  event SybilUnauthorized(address indexed sybil);

  uint256 public constant PERCENTAGE_BASE = 1e4;

  mapping(address => Price) private _prices;

  mapping(address => bool) private _sybils;

  modifier onlySybil {
    _requireWhitelistedSybil(msg.sender);
    _;
  }

  function authorizeSybil(address sybil) external onlyOwner {
    _sybils[sybil] = true;

    emit SybilAuthorized(sybil);
  }

  function unauthorizeSybil(address sybil) external onlyOwner {
    _sybils[sybil] = false;

    emit SybilUnauthorized(sybil);
  }

  function submitPrices(address[] calldata assets, uint128[] calldata prices) external onlySybil {
    require(assets.length == prices.length, 'INCONSISTENT_PARAMS_LENGTH');
    for (uint256 i = 0; i < assets.length; i++) {
      _prices[assets[i]] = Price(uint64(block.number), uint64(block.timestamp), prices[i]);
    }

    emit PricesSubmitted(msg.sender, assets, prices);
  }

  function getAssetPrice(address asset) external view override returns (uint256) {
    return uint256(_prices[asset].price);
  }

  function isSybilWhitelisted(address sybil) public view returns (bool) {
    return _sybils[sybil];
  }

  function getPricesData(address[] calldata assets) external view returns (Price[] memory) {
    Price[] memory result = new Price[](assets.length);
    for (uint256 i = 0; i < assets.length; i++) {
      result[i] = _prices[assets[i]];
    }
    return result;
  }

  function filterCandidatePricesByDeviation(
    uint256 deviation,
    address[] calldata assets,
    uint256[] calldata candidatePrices
  ) external view returns (address[] memory, uint256[] memory) {
    require(assets.length == candidatePrices.length, 'INCONSISTENT_PARAMS_LENGTH');
    address[] memory filteredAssetsWith0s = new address[](assets.length);
    uint256[] memory filteredCandidatesWith0s = new uint256[](assets.length);
    uint256 end0sInLists;
    for (uint256 i = 0; i < assets.length; i++) {
      uint128 currentOraclePrice = _prices[assets[i]].price;
      if (
        uint256(currentOraclePrice) >
        candidatePrices[i].mul(PERCENTAGE_BASE.add(deviation)).div(PERCENTAGE_BASE) ||
        uint256(currentOraclePrice) <
        candidatePrices[i].mul(PERCENTAGE_BASE.sub(deviation)).div(PERCENTAGE_BASE)
      ) {
        filteredAssetsWith0s[end0sInLists] = assets[i];
        filteredCandidatesWith0s[end0sInLists] = candidatePrices[i];
        end0sInLists++;
      }
    }
    address[] memory resultAssets = new address[](end0sInLists);
    uint256[] memory resultPrices = new uint256[](end0sInLists);
    for (uint256 i = 0; i < end0sInLists; i++) {
      resultAssets[i] = filteredAssetsWith0s[i];
      resultPrices[i] = filteredCandidatesWith0s[i];
    }

    return (resultAssets, resultPrices);
  }

  function _requireWhitelistedSybil(address sybil) internal view {
    require(isSybilWhitelisted(sybil), 'INVALID_SYBIL');
  }
}