// SPDX-License-Identifier: Unlicense

pragma solidity ^0.6.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./interfaces/IMillionPieces.sol";
import "./interfaces/IAuction.sol";
import "./helpers/ProxyRegistry.sol";


/**
 * @title Auction
 */
contract Auction is IAuction, Ownable {
  using SafeMath for uint256;

  uint256 public constant BATCH_PURCHASE_LIMIT = 25;
  uint256 public constant PRICE_FOR_SEGMENT = 0.1 ether;

  address payable public fund;
  address public immutable proxyRegistryAddress;
  IMillionPieces public immutable millionPieces;

  event NewPurchase(address purchaser, address receiver, uint256 tokenId, uint256 weiAmount);

  constructor(
    address _millionPieces,
    address payable _fund,
    address _proxyRegistryAddress
  ) public {
    fund = _fund;
    proxyRegistryAddress = _proxyRegistryAddress;
    millionPieces = IMillionPieces(_millionPieces);
  }

  fallback () external payable { revert(); }
  receive () external payable { revert(); }

  //  --------------------
  //  PUBLIC
  //  --------------------

  function buySingle(address receiver, uint256 tokenId) external payable override {
    require(msg.value >= PRICE_FOR_SEGMENT, "buySingle: Not enough ETH for purchase!");

    _buySingle(receiver, tokenId);
  }

  function buyMany(
    address[] calldata receivers,
    uint256[] calldata tokenIds
  ) external payable override {
    uint256 tokensCount = tokenIds.length;
    require(tokensCount > 0 && tokensCount <= BATCH_PURCHASE_LIMIT, "buyMany: Arrays should bigger 0 and less then max limit!");
    require(tokensCount == receivers.length, "buyMany: Arrays should be equal to each other!");
    require(msg.value >= tokensCount.mul(PRICE_FOR_SEGMENT), "buyMany: Not enough ETH for purchase!");

    _buyMany(receivers, tokenIds);
  }

  function mint(uint256 tokenId, address receiver) public {
    // Must be sent from the owner proxy or owner.
    ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
    require(address(proxyRegistry.proxies(owner())) == msg.sender || owner() == msg.sender, "mint: Not auth!");

    _buySingle(receiver, tokenId);
  }

  function changeFundAddress(address payable newFund) external onlyOwner {
    require(newFund != address(0), "changeFundAddress: Empty fund address!");
    fund = newFund;
  }

  //  --------------------
  //  INTERNAL
  //  -------------------

  function _buySingle(address receiver, uint256 tokenId) private {
    // Mint token to receiver
    _mintNft(receiver, tokenId);

    // Emit single segment purchase event
    emit NewPurchase(msg.sender, receiver, tokenId, msg.value);

    // Send ETH to fund address
    _transferEth(fund, msg.value);
  }

  function _buyMany(address[] memory receivers, uint256[] memory tokenIds) private {
    uint256 tokensCount = tokenIds.length;
    uint256 actualPurchasedSegments = 0;
    uint256 ethPerEachSegment = msg.value.div(tokensCount);

    for (uint256 i = 0; i < tokensCount; i++) {
      // Transfer if tokens not exist, else sent ETH back to purchaser
      if (_isPurchasable(tokenIds[i])) {
        // Mint token to receiver
        _mintNft(receivers[i], tokenIds[i]);
        actualPurchasedSegments++;

        emit NewPurchase(msg.sender, receivers[i], tokenIds[i], ethPerEachSegment);
      }
    }

    // Send ETH to fund address
    _transferEth(fund, actualPurchasedSegments.mul(ethPerEachSegment));

    // Send non-purchased funds to sender address back
    if (tokensCount != actualPurchasedSegments) {
      _transferEth(msg.sender, (tokensCount.sub(actualPurchasedSegments)).mul(ethPerEachSegment));
    }
  }

  /**
   * @notice Transfer amount of ETH to the fund address.
   */
  function _transferEth(address receiver, uint256 amount) private {
    (bool success, ) = receiver.call{value: amount}("");
    require(success, "_transferEth: Failed to transfer funds!");
  }

  /**
   * @notice Mint simple segment.
   */
  function _mintNft(address receiver, uint256 tokenId) private {
    millionPieces.mintTo(receiver, tokenId);
  }

  /**
   * @notice Is provided token exists or not.
   */
  function _isPurchasable(uint256 tokenId) private view returns (bool) {
    return !millionPieces.exists(tokenId);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.6.12;


/**
 * @title IMillionPieces
 */
interface IMillionPieces {
    function mintTo(address to, uint256 tokenId) external;
    function mintToSpecial(address to, uint256 tokenId) external;
    function createArtwork(string calldata name) external;
    function setTokenURI(uint256 tokenId, string calldata uri) external;
    function setBaseURI(string calldata baseURI) external;
    function exists(uint256 tokenId) external view returns (bool);
    function isSpecialSegment(uint256 tokenId) external pure returns (bool);
    function isValidArtworkSegment(uint256 tokenId) external view returns (bool);
    function getArtworkName(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.6.12;


/**
 * @title IAuction
 */
interface IAuction {
    function buySingle(address receiver, uint256 tokenId) external payable;
    function buyMany(address[] calldata receivers, uint256[] calldata tokenIds) external payable;
}

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.6.12;

contract OwnableDelegateProxy {}

contract ProxyRegistry {
  mapping(address => OwnableDelegateProxy) public proxies;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

{
  "optimizer": {
    "enabled": true,
    "runs": 9999
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