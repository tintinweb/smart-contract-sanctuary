// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import "./FeeOwner.sol";
import "./Fee1155.sol";

/**
  @title A basic smart contract for tracking the ownership of SuperFarm Items.
  @author Tim Clancy

  This is the governing registry of all SuperFarm Item assets.
*/
contract FarmItemRecords is Ownable, ReentrancyGuard {

  /// A version number for this record contract's interface.
  uint256 public version = 1;

  /// A mapping for an array of all Fee1155s deployed by a particular address.
  mapping (address => address[]) public itemRecords;

  /// An event for tracking the creation of a new Item.
  event ItemCreated(address indexed itemAddress, address indexed creator);

  /// Specifically whitelist an OpenSea proxy registry address.
  address public proxyRegistryAddress;

  /**
    Construct a new item registry with a specific OpenSea proxy address.

    @param _proxyRegistryAddress An OpenSea proxy registry address.
  */
  constructor(address _proxyRegistryAddress) public {
    proxyRegistryAddress = _proxyRegistryAddress;
  }

  /**
    Create a Fee1155 on behalf of the owner calling this function. The Fee1155
    immediately mints a single-item collection.

    @param _uri The item group's metadata URI.
    @param _royaltyFee The creator's fee to apply to the created item.
    @param _initialSupply An array of per-item initial supplies which should be
                          minted immediately.
    @param _maximumSupply An array of per-item maximum supplies.
    @param _recipients An array of addresses which will receive the initial
                       supply minted for each corresponding item.
    @param _data Any associated data to use if items are minted this transaction.
  */
  function createItem(string calldata _uri, uint256 _royaltyFee, uint256[] calldata _initialSupply, uint256[] calldata _maximumSupply, address[] calldata _recipients, bytes calldata _data) external nonReentrant returns (Fee1155) {
    FeeOwner royaltyFeeOwner = new FeeOwner(_royaltyFee, 30000);
    Fee1155 newItemGroup = new Fee1155(_uri, royaltyFeeOwner, proxyRegistryAddress);
    newItemGroup.create(_initialSupply, _maximumSupply, _recipients, _data);

    // Transfer ownership of the new Item to the user then store a reference.
    royaltyFeeOwner.transferOwnership(msg.sender);
    newItemGroup.transferOwnership(msg.sender);
    address itemAddress = address(newItemGroup);
    itemRecords[msg.sender].push(itemAddress);
    emit ItemCreated(itemAddress, msg.sender);
    return newItemGroup;
  }

  /**
    Allow a user to add an existing Item contract to the registry.

    @param _itemAddress The address of the Item contract to add for this user.
  */
  function addItem(address _itemAddress) external {
    itemRecords[msg.sender].push(_itemAddress);
  }

  /**
    Get the number of entries in the Item records mapping for the given user.

    @return The number of Items added for a given address.
  */
  function getItemCount(address _user) external view returns (uint256) {
    return itemRecords[_user].length;
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
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

/**
  @title Represents ownership over a fee of some percentage.
  @author Tim Clancy
*/
contract FeeOwner is Ownable {
  using SafeMath for uint256;

  /// A version number for this FeeOwner contract's interface.
  uint256 public version = 1;

  /// The percent fee due to this contract's owner, represented as 1/1000th of a percent. That is, a 1% fee maps to 1000.
  uint256 public fee;

  /// The maximum configurable percent fee due to this contract's owner, represented as 1/1000th of a percent.
  uint256 public maximumFee;

  /// An event for tracking modification of the fee.
  event FeeChanged(uint256 oldFee, uint256 newFee);

  /**
    Construct a new FeeOwner by providing specifying a fee.

    @param _fee The percent fee to apply, represented as 1/1000th of a percent.
    @param _maximumFee The maximum possible fee that the owner can set.
  */
  constructor(uint256 _fee, uint256 _maximumFee) public {
    require(_fee <= _maximumFee, "The fee cannot be set above its maximum.");
    fee = _fee;
    maximumFee = _maximumFee;
  }

  /**
    Allows the owner of this fee to modify what they take, within bounds.

    @param newFee The new fee to begin using.
  */
  function changeFee(uint256 newFee) external onlyOwner {
    require(newFee <= maximumFee, "The fee cannot be set above its original maximum.");
    emit FeeChanged(fee, newFee);
    fee = newFee;
  }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

import "./FeeOwner.sol";

/**
  @title An OpenSea delegate proxy contract which we include for whitelisting.
  @author OpenSea
*/
contract OwnableDelegateProxy { }

/**
  @title An OpenSea proxy registry contract which we include for whitelisting.
  @author OpenSea
*/
contract ProxyRegistry {
  mapping(address => OwnableDelegateProxy) public proxies;
}

/**
  @title An ERC-1155 item creation contract which specifies an associated
         FeeOwner who receives royalties from sales of created items.
  @author Tim Clancy

  The fee set by the FeeOwner on this Item is honored by Shop contracts.
  In addition to the inherited OpenZeppelin dependency, this uses ideas from
  the original ERC-1155 reference implementation.
*/
contract Fee1155 is ERC1155, Ownable {
  using SafeMath for uint256;

  /// A version number for this fee-bearing 1155 item contract's interface.
  uint256 public version = 1;

  /// The ERC-1155 URI for looking up item metadata using {id} substitution.
  string public metadataUri;

  /// A user-specified FeeOwner to receive a portion of item sale earnings.
  FeeOwner public feeOwner;

  /// Specifically whitelist an OpenSea proxy registry address.
  address public proxyRegistryAddress;

  /// @dev A mask for isolating an item's group ID.
  uint256 constant GROUP_MASK = uint256(uint128(~0)) << 128;

  /// A counter to enforce unique IDs for each item group minted.
  uint256 public nextItemGroupId;

  /// This mapping tracks the number of unique items within each item group.
  mapping (uint256 => uint256) public itemGroupSizes;

  /// A mapping of item IDs to their circulating supplies.
  mapping (uint256 => uint256) public currentSupply;

  /// A mapping of item IDs to their maximum supplies; true NFTs are unique.
  mapping (uint256 => uint256) public maximumSupply;

  /// A mapping of all addresses approved to mint items on behalf of the owner.
  mapping (address => bool) public approvedMinters;

  /// An event for tracking the creation of an item group.
  event ItemGroupCreated(uint256 itemGroupId, uint256 itemGroupSize,
    address indexed creator);

  /// A custom modifier which permits only approved minters to mint items.
  modifier onlyMinters {
    require(msg.sender == owner() || approvedMinters[msg.sender],
      "You are not an approved minter for this item.");
    _;
  }

  /**
    Construct a new ERC-1155 item with an associated FeeOwner fee.

    @param _uri The metadata URI to perform token ID substitution in.
    @param _feeOwner The address of a FeeOwner who receives earnings from this
                     item.
    @param _proxyRegistryAddress An OpenSea proxy registry address.
  */
  constructor(string memory _uri, FeeOwner _feeOwner, address _proxyRegistryAddress) public ERC1155(_uri) {
    metadataUri = _uri;
    feeOwner = _feeOwner;
    proxyRegistryAddress = _proxyRegistryAddress;
    nextItemGroupId = 0;
  }

  /**
    An override to whitelist the OpenSea proxy contract to enable gas-free
    listings. This function returns true if `_operator` is approved to transfer
    items owned by `_owner`.

    @param _owner The owner of items to check for transfer ability.
    @param _operator The potential transferrer of `_owner`'s items.
  */
  function isApprovedForAll(address _owner, address _operator) public view override returns (bool isOperator) {
    ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
    if (address(proxyRegistry.proxies(_owner)) == _operator) {
      return true;
    }
    return ERC1155.isApprovedForAll(_owner, _operator);
  }

  /**
    Allow the item owner to update the metadata URI of this collection.

    @param _uri The new URI to update to.
  */
  function setURI(string calldata _uri) external onlyOwner {
    metadataUri = _uri;
  }

  /**
    Allows the owner of this contract to grant or remove approval to an external
    minter of items.

    @param _minter The external address allowed to mint items.
    @param _approval The updated `_minter` approval status.
  */
  function approveMinter(address _minter, bool _approval) external onlyOwner {
    approvedMinters[_minter] = _approval;
  }

  /**
    This function creates an "item group" which may contain one or more
    individual items. The items within a group may be any combination of
    fungible or nonfungible. The distinction between a fungible and a
    nonfungible item is made by checking the item's possible `_maximumSupply`;
    nonfungible items will naturally have a maximum supply of one because they
    are unqiue. Creating an item through this function defines its maximum
    supply. The size of the item group is inferred from the size of the input
    arrays.

    The primary purpose of an item group is to create a collection of
    nonfungible items where each item within the collection is unique but they
    all share some data as a group. The primary example of this is something
    like a series of 100 trading cards where each card is unique with its issue
    number from 1 to 100 but all otherwise reflect the same metadata. In such an
    example, the `_maximumSupply` of each item is one and the size of the group
    would be specified by passing an array with 100 elements in it to this
    function: [ 1, 1, 1, ... 1 ].

    Within an item group, items are 1-indexed with the 0-index of the item group
    supporting lookup of item group metadata. This 0-index metadata includes
    lookup via `maximumSupply` of the full count of items in the group should
    all of the items be minted, lookup via `currentSupply` of the number of
    items circulating from the group as a whole, and lookup via `groupSizes` of
    the number of unique items within the group.

    @param initialSupply An array of per-item initial supplies which should be
                         minted immediately.
    @param _maximumSupply An array of per-item maximum supplies.
    @param recipients An array of addresses which will receive the initial
                      supply minted for each corresponding item.
    @param data Any associated data to use if items are minted this transaction.
  */
  function create(uint256[] calldata initialSupply, uint256[] calldata _maximumSupply, address[] calldata recipients, bytes calldata data) external onlyOwner returns (uint256) {
    uint256 groupSize = initialSupply.length;
    require(groupSize > 0,
      "You cannot create an empty item group.");
    require(initialSupply.length == _maximumSupply.length,
      "Initial supply length cannot be mismatched with maximum supply length.");
    require(initialSupply.length == recipients.length,
      "Initial supply length cannot be mismatched with recipients length.");

    // Create an item group of requested size using the next available ID.
    uint256 shiftedGroupId = nextItemGroupId << 128;
    itemGroupSizes[shiftedGroupId] = groupSize;
    emit ItemGroupCreated(shiftedGroupId, groupSize, msg.sender);

    // Record the supply cap of each item being created in the group.
    uint256 fullCollectionSize = 0;
    for (uint256 i = 0; i < groupSize; i++) {
      uint256 itemInitialSupply = initialSupply[i];
      uint256 itemMaximumSupply = _maximumSupply[i];
      fullCollectionSize = fullCollectionSize.add(itemMaximumSupply);
      require(itemMaximumSupply > 0,
        "You cannot create an item which is never mintable.");
      require(itemInitialSupply <= itemMaximumSupply,
        "You cannot create an item which exceeds its own supply cap.");

      // The item ID is offset by one because the zero index of the group is used to store the group size.
      uint256 itemId = shiftedGroupId.add(i + 1);
      maximumSupply[itemId] = itemMaximumSupply;

      // If this item is being initialized with a supply, mint to the recipient.
      if (itemInitialSupply > 0) {
        address itemRecipient = recipients[i];
        _mint(itemRecipient, itemId, itemInitialSupply, data);
        currentSupply[itemId] = itemInitialSupply;
      }
    }

    // Also record the full size of the entire item group.
    maximumSupply[shiftedGroupId] = fullCollectionSize;

    // Increment our next item group ID and return our created item group ID.
    nextItemGroupId = nextItemGroupId.add(1);
    return shiftedGroupId;
  }

  /**
    Allow the item owner to mint a new item, so long as there is supply left to
    do so.

    @param to The address to send the newly-minted items to.
    @param id The ERC-1155 ID of the item being minted.
    @param amount The amount of the new item to mint.
    @param data Any associated data for this minting event that should be passed.
  */
  function mint(address to, uint256 id, uint256 amount, bytes calldata data) external onlyMinters {
    uint256 groupId = id & GROUP_MASK;
    require(groupId != id,
      "You cannot mint an item with an issuance index of 0.");
    currentSupply[groupId] = currentSupply[groupId].add(amount);
    uint256 newSupply = currentSupply[id].add(amount);
    currentSupply[id] = newSupply;
    require(newSupply <= maximumSupply[id],
      "You cannot mint an item beyond its permitted maximum supply.");
    _mint(to, id, amount, data);
  }

  /**
    Allow the item owner to mint a new batch of items, so long as there is
    supply left to do so for each item.

    @param to The address to send the newly-minted items to.
    @param ids The ERC-1155 IDs of the items being minted.
    @param amounts The amounts of the new items to mint.
    @param data Any associated data for this minting event that should be passed.
  */
  function mintBatch(address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external onlyMinters {
    require(ids.length > 0,
      "You cannot perform an empty mint.");
    require(ids.length == amounts.length,
      "Supplied IDs length cannot be mismatched with amounts length.");
    for (uint256 i = 0; i < ids.length; i++) {
      uint256 id = ids[i];
      uint256 amount = amounts[i];
      uint256 groupId = id & GROUP_MASK;
      require(groupId != id,
        "You cannot mint an item with an issuance index of 0.");
      currentSupply[groupId] = currentSupply[groupId].add(amount);
      uint256 newSupply = currentSupply[id].add(amount);
      currentSupply[id] = newSupply;
      require(newSupply <= maximumSupply[id],
        "You cannot mint an item beyond its permitted maximum supply.");
    }
    _mintBatch(to, ids, amounts, data);
  }
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC1155.sol";
import "./IERC1155MetadataURI.sol";
import "./IERC1155Receiver.sol";
import "../../utils/Context.sol";
import "../../introspection/ERC165.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 *
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using SafeMath for uint256;
    using Address for address;

    // Mapping from token ID to account balances
    mapping (uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping (address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /*
     *     bytes4(keccak256('balanceOf(address,uint256)')) == 0x00fdd58e
     *     bytes4(keccak256('balanceOfBatch(address[],uint256[])')) == 0x4e1273f4
     *     bytes4(keccak256('setApprovalForAll(address,bool)')) == 0xa22cb465
     *     bytes4(keccak256('isApprovedForAll(address,address)')) == 0xe985e9c5
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256,uint256,bytes)')) == 0xf242432a
     *     bytes4(keccak256('safeBatchTransferFrom(address,address,uint256[],uint256[],bytes)')) == 0x2eb2c2d6
     *
     *     => 0x00fdd58e ^ 0x4e1273f4 ^ 0xa22cb465 ^
     *        0xe985e9c5 ^ 0xf242432a ^ 0x2eb2c2d6 == 0xd9b67a26
     */
    bytes4 private constant _INTERFACE_ID_ERC1155 = 0xd9b67a26;

    /*
     *     bytes4(keccak256('uri(uint256)')) == 0x0e89341c
     */
    bytes4 private constant _INTERFACE_ID_ERC1155_METADATA_URI = 0x0e89341c;

    /**
     * @dev See {_setURI}.
     */
    constructor (string memory uri_) public {
        _setURI(uri_);

        // register the supported interfaces to conform to ERC1155 via ERC165
        _registerInterface(_INTERFACE_ID_ERC1155);

        // register the supported interfaces to conform to ERC1155MetadataURI via ERC165
        _registerInterface(_INTERFACE_ID_ERC1155_METADATA_URI);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) external view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: balance query for the zero address");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(
        address[] memory accounts,
        uint256[] memory ids
    )
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(_msgSender() != operator, "ERC1155: setting approval status for self");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    )
        public
        virtual
        override
    {
        require(to != address(0), "ERC1155: transfer to the zero address");
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][from] = _balances[id][from].sub(amount, "ERC1155: insufficient balance for transfer");
        _balances[id][to] = _balances[id][to].add(amount);

        emit TransferSingle(operator, from, to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    )
        public
        virtual
        override
    {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            _balances[id][from] = _balances[id][from].sub(
                amount,
                "ERC1155: insufficient balance for transfer"
            );
            _balances[id][to] = _balances[id][to].add(amount);
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `account`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - If `account` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(address account, uint256 id, uint256 amount, bytes memory data) internal virtual {
        require(account != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), account, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][account] = _balances[id][account].add(amount);
        emit TransferSingle(operator, address(0), account, id, amount);

        _doSafeTransferAcceptanceCheck(operator, address(0), account, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] = amounts[i].add(_balances[ids[i]][to]);
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `account`
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens of token type `id`.
     */
    function _burn(address account, uint256 id, uint256 amount) internal virtual {
        require(account != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, account, address(0), _asSingletonArray(id), _asSingletonArray(amount), "");

        _balances[id][account] = _balances[id][account].sub(
            amount,
            "ERC1155: burn amount exceeds balance"
        );

        emit TransferSingle(operator, account, address(0), id, amount);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(address account, uint256[] memory ids, uint256[] memory amounts) internal virtual {
        require(account != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, account, address(0), ids, amounts, "");

        for (uint i = 0; i < ids.length; i++) {
            _balances[ids[i]][account] = _balances[ids[i]][account].sub(
                amounts[i],
                "ERC1155: burn amount exceeds balance"
            );
        }

        emit TransferBatch(operator, account, address(0), ids, amounts);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    )
        internal
        virtual
    { }

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    )
        private
    {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver(to).onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    )
        private
    {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (bytes4 response) {
                if (response != IERC1155Receiver(to).onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "../../introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "./IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../introspection/IERC165.sol";

/**
 * _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {

    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    )
        external
        returns(bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    )
        external
        returns(bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
abstract contract ERC165 is IERC165 {
    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor () internal {
        // Derived contracts need only register support for their own interfaces,
        // we register support for ERC165 itself here
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     *
     * Time complexity O(1), guaranteed to always use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC1155/ERC1155Holder.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

import "./FeeOwner.sol";
import "./Fee1155.sol";

/**
  @title A simple Shop contract for selling ERC-1155s for Ether via direct
         minting.
  @author Tim Clancy

  This contract is a limited subset of the Shop1155 contract designed to mint
  items directly to the user upon purchase. This shop additionally requires the
  owner to directly approve purchase requests from prospective buyers.
*/
contract ShopEtherMinter1155Curated is ERC1155Holder, Ownable, ReentrancyGuard {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  /// A version number for this Shop contract's interface.
  uint256 public version = 1;

  /// @dev A mask for isolating an item's group ID.
  uint256 constant GROUP_MASK = uint256(uint128(~0)) << 128;

  /// A user-specified Fee1155 contract to support selling items from.
  Fee1155 public item;

  /// A user-specified FeeOwner to receive a portion of Shop earnings.
  FeeOwner public feeOwner;

  /// The Shop's inventory of item groups for sale.
  uint256[] public inventory;

  /// The Shop's price for each item group.
  mapping (uint256 => uint256) public prices;

  /// A mapping of each item group ID to an array of addresses with offers.
  mapping (uint256 => address[]) public bidders;

  /// A mapping for each item group ID to a mapping of address-price offers.
  mapping (uint256 => mapping (address => uint256)) public offers;

  /**
    Construct a new Shop by providing it a FeeOwner.

    @param _item The address of the Fee1155 item that will be minting sales.
    @param _feeOwner The address of the FeeOwner due a portion of Shop earnings.
  */
  constructor(Fee1155 _item, FeeOwner _feeOwner) public {
    item = _item;
    feeOwner = _feeOwner;
  }

  /**
    Returns the length of the inventory array.

    @return the length of the inventory array.
  */
  function getInventoryCount() external view returns (uint256) {
    return inventory.length;
  }

  /**
    Returns the length of the bidder array on an item group.

    @return the length of the bidder array on an item group.
  */
  function getBidderCount(uint256 groupId) external view returns (uint256) {
    return bidders[groupId].length;
  }

  /**
    Allows the Shop owner to list a new set of NFT items for sale.

    @param _groupIds The item group IDs to list for sale in this shop.
    @param _prices The corresponding purchase price to mint an item of each group.
  */
  function listItems(uint256[] calldata _groupIds, uint256[] calldata _prices) external onlyOwner {
    require(_groupIds.length > 0,
      "You must list at least one item.");
    require(_groupIds.length == _prices.length,
      "Items length cannot be mismatched with prices length.");

    // Iterate through every specified item group to list items.
    for (uint256 i = 0; i < _groupIds.length; i++) {
      uint256 groupId = _groupIds[i];
      uint256 price = _prices[i];
      inventory.push(groupId);
      prices[groupId] = price;
    }
  }

  /**
    Allows the Shop owner to remove items from sale.

    @param _groupIds The group IDs currently listed in the shop to take off sale.
  */
  function removeItems(uint256[] calldata _groupIds) external onlyOwner {
    require(_groupIds.length > 0,
      "You must remove at least one item.");

    // Iterate through every specified item group to remove items.
    for (uint256 i = 0; i < _groupIds.length; i++) {
      uint256 groupId = _groupIds[i];
      prices[groupId] = 0;
    }
  }

  /**
    Allows any user to place an offer to purchase an item group from this Shop.
    For this shop, users place an offer automatically at the price set by the
    Shop owner. This function takes a user's Ether into escrow for the offer.

    @param _itemGroupIds An array of (unique) item groups for a user to place an offer for.
  */
  function makeOffers(uint256[] calldata _itemGroupIds) public nonReentrant payable {
    require(_itemGroupIds.length > 0,
      "You must make an offer for at least one item group.");

    // Iterate through every specified item to make an offer on items.
    for (uint256 i = 0; i < _itemGroupIds.length; i++) {
      uint256 groupId = _itemGroupIds[i];
      uint256 price = prices[groupId];
      require(price > 0,
        "You cannot make an offer for an item that is not listed.");

      // Record an offer for this item.
      bidders[groupId].push(msg.sender);
      offers[groupId][msg.sender] = msg.value;
    }
  }

  /**
    Allows any user to cancel an offer for items from this Shop. This function
    returns a user's Ether if there is any in escrow for the item group.

    @param _itemGroupIds An array of (unique) item groups for a user to cancel an offer for.
  */
  function cancelOffers(uint256[] calldata _itemGroupIds) public nonReentrant {
    require(_itemGroupIds.length > 0,
      "You must cancel an offer for at least one item group.");

    // Iterate through every specified item to cancel offers on items.
    uint256 returnedOfferAmount = 0;
    for (uint256 i = 0; i < _itemGroupIds.length; i++) {
      uint256 groupId = _itemGroupIds[i];
      uint256 offeredValue = offers[groupId][msg.sender];
      returnedOfferAmount = returnedOfferAmount.add(offeredValue);
      offers[groupId][msg.sender] = 0;
    }

    // Return the user's escrowed offer Ether.
    (bool success, ) = payable(msg.sender).call{ value: returnedOfferAmount }("");
    require(success, "Returning canceled offer amount failed.");
  }

  /**
    Allows the Shop owner to accept any valid offer from a user. Once the Shop
    owner accepts the offer, the Ether is distributed according to fees and the
    item is minted to the user.

    @param _groupIds The item group IDs to process offers for.
    @param _bidders The specific bidder for each item group ID to accept.
    @param _itemIds The specific item ID within the group to mint for the bidder.
    @param _amounts The amount of specific item to mint for the bidder.
  */
  function acceptOffers(uint256[] calldata _groupIds, address[] calldata _bidders, uint256[] calldata _itemIds, uint256[] calldata _amounts) public nonReentrant onlyOwner {
    require(_groupIds.length > 0,
      "You must accept an offer for at least one item.");
    require(_groupIds.length == _bidders.length,
      "Group IDs length cannot be mismatched with bidders length.");
    require(_groupIds.length == _itemIds.length,
      "Group IDs length cannot be mismatched with item IDs length.");
    require(_groupIds.length == _amounts.length,
      "Group IDs length cannot be mismatched with item amounts length.");

    // Accept all offers and disperse fees accordingly.
    uint256 feePercent = feeOwner.fee();
    uint256 itemRoyaltyPercent = item.feeOwner().fee();
    for (uint256 i = 0; i < _groupIds.length; i++) {
      uint256 groupId = _groupIds[i];
      address bidder = _bidders[i];
      uint256 itemId = _itemIds[i];
      uint256 amount = _amounts[i];

      // Verify that the offer being accepted is still valid.
      uint256 price = prices[groupId];
      require(price > 0,
        "You cannot accept an offer for an item that is not listed.");
      uint256 offeredPrice = offers[groupId][bidder];
      require(offeredPrice >= price,
        "You cannot accept an offer for less than the current asking price.");

      // Split fees for this purchase.
      uint256 feeValue = offeredPrice.mul(feePercent).div(100000);
      uint256 royaltyValue = offeredPrice.mul(itemRoyaltyPercent).div(100000);
      (bool success, ) = payable(feeOwner.owner()).call{ value: feeValue }("");
      require(success, "Platform fee transfer failed.");
      (success, ) = payable(item.feeOwner().owner()).call{ value: royaltyValue }("");
      require(success, "Creator royalty transfer failed.");
      (success, ) = payable(owner()).call{ value: offeredPrice.sub(feeValue).sub(royaltyValue) }("");
      require(success, "Shop owner transfer failed.");

      // Mint the item.
      item.mint(bidder, itemId, amount, "");
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./ERC1155Receiver.sol";

/**
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(address, address, uint256, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address, address, uint256[] memory, uint256[] memory, bytes memory) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC1155Receiver.sol";
import "../../introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    constructor() internal {
        _registerInterface(
            ERC1155Receiver(address(0)).onERC1155Received.selector ^
            ERC1155Receiver(address(0)).onERC1155BatchReceived.selector
        );
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC1155/ERC1155Holder.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

import "./FeeOwner.sol";
import "./Fee1155NFTLockable.sol";
import "./Staker.sol";

/**
  @title A Shop contract for selling NFTs via direct minting through particular
         pools with specific participation requirements.
  @author Tim Clancy

  This launchpad contract is specifically optimized for SuperFarm direct use.
*/
contract ShopPlatformLaunchpad1155 is ERC1155Holder, Ownable, ReentrancyGuard {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  /// A version number for this Shop contract's interface.
  uint256 public version = 2;

  /// @dev A mask for isolating an item's group ID.
  uint256 constant GROUP_MASK = uint256(uint128(~0)) << 128;

  /// A user-specified Fee1155 contract to support selling items from.
  Fee1155NFTLockable public item;

  /// A user-specified FeeOwner to receive a portion of Shop earnings.
  FeeOwner public feeOwner;

  /// A user-specified Staker contract to spend user points on.
  Staker[] public stakers;

  /**
    A limit on the number of items that a particular address may purchase across
    any number of pools in the launchpad.
  */
  uint256 public globalPurchaseLimit;

  /// A mapping of addresses to the number of items each has purchased globally.
  mapping (address => uint256) public globalPurchaseCounts;

  /// The address of the orignal owner of the item contract.
  address public originalOwner;

  /// Whether ownership is locked to disable clawback.
  bool public ownershipLocked;

  /// A mapping of item group IDs to their next available issue number minus one.
  mapping (uint256 => uint256) public nextItemIssues;

  /// The next available ID to be assumed by the next whitelist added.
  uint256 public nextWhitelistId;

  /**
    A mapping of whitelist IDs to specific Whitelist elements. Whitelists may be
    shared between pools via specifying their ID in a pool requirement.
  */
  mapping (uint256 => Whitelist) public whitelists;

  /// The next available ID to be assumed by the next pool added.
  uint256 public nextPoolId;

  /// A mapping of pool IDs to pools.
  mapping (uint256 => Pool) public pools;

  /**
    This struct is a source of mapping-free input to the `addPool` function.

    @param name A name for the pool.
    @param startBlock The first block where this pool begins allowing purchases.
    @param endBlock The final block where this pool allows purchases.
    @param purchaseLimit The maximum number of items a single address may purchase from this pool.
    @param requirement A PoolRequirement requisite for users who want to participate in this pool.
  */
  struct PoolInput {
    string name;
    uint256 startBlock;
    uint256 endBlock;
    uint256 purchaseLimit;
    PoolRequirement requirement;
  }

  /**
    This struct tracks information about a single item pool in the Shop.

    @param name A name for the pool.
    @param startBlock The first block where this pool begins allowing purchases.
    @param endBlock The final block where this pool allows purchases.
    @param purchaseLimit The maximum number of items a single address may purchase from this pool.
    @param purchaseCounts A mapping of addresses to the number of items each has purchased from this pool.
    @param requirement A PoolRequirement requisite for users who want to participate in this pool.
    @param itemGroups An array of all item groups currently present in this pool.
    @param currentPoolVersion A version number hashed with item group IDs before
           being used as keys to other mappings. This supports efficient
           invalidation of stale mappings.
    @param itemCaps A mapping of item group IDs to the maximum number this pool is allowed to mint.
    @param itemMinted A mapping of item group IDs to the number this pool has currently minted.
    @param itemPricesLength A mapping of item group IDs to the number of price assets available to purchase with.
    @param itemPrices A mapping of item group IDs to a mapping of available PricePair assets available to purchase with.
  */
  struct Pool {
    string name;
    uint256 startBlock;
    uint256 endBlock;
    uint256 purchaseLimit;
    mapping (address => uint256) purchaseCounts;
    PoolRequirement requirement;
    uint256[] itemGroups;
    uint256 currentPoolVersion;
    mapping (bytes32 => uint256) itemCaps;
    mapping (bytes32 => uint256) itemMinted;
    mapping (bytes32 => uint256) itemPricesLength;
    mapping (bytes32 => mapping (uint256 => PricePair)) itemPrices;
  }

  /**
    This struct tracks information about a prerequisite for a user to
    participate in a pool.

    @param requiredType
      A sentinel value for the specific type of asset being required.
        0 = a pool which requires no specific assets to participate.
        1 = an ERC-20 token, see `requiredAsset`.
        2 = an NFT item, see `requiredAsset`.
    @param requiredAsset
      Some more specific information about the asset to require.
        If the `requiredType` is 1, we use this address to find the ERC-20
        token that we should be specifically requiring holdings of.
        If the `requiredType` is 2, we use this address to find the item
        contract that we should be specifically requiring holdings of.
    @param requiredAmount The amount of the specified `requiredAsset` required.
    @param whitelistId
      The ID of an address whitelist to restrict participants in this pool. To
      participate, a purchaser must have their address present in the
      corresponding whitelist. Other requirements from `requiredType` apply.
      An ID of 0 is a sentinel value for no whitelist: a public pool.
  */
  struct PoolRequirement {
    uint256 requiredType;
    address requiredAsset;
    uint256 requiredAmount;
    uint256 whitelistId;
  }

  /**
    This struct tracks information about a single asset with associated price
    that an item is being sold in the shop for.

    @param assetType A sentinel value for the specific type of asset being used.
                     0 = non-transferrable points from a Staker; see `asset`.
                     1 = Ether.
                     2 = an ERC-20 token, see `asset`.
    @param asset Some more specific information about the asset to charge in.
                 If the `assetType` is 0, we convert the given address to an
                 integer index for finding a specific Staker from `stakers`.
                 If the `assetType` is 1, we ignore this field.
                 If the `assetType` is 2, we use this address to find the ERC-20
                 token that we should be specifically charging with.
    @param price The amount of the specified `assetType` and `asset` to charge.
  */
  struct PricePair {
    uint256 assetType;
    address asset;
    uint256 price;
  }

  /**
    This struct is a source of mapping-free input to the `addWhitelist` function.

    @param expiryBlock A block number after which this whitelist is automatically considered inactive, no matter the value of `isActive`.
    @param isActive Whether or not this whitelist is actively restricting purchases in blocks before `expiryBlock`.
    @param addresses An array of addresses to whitelist for participation in a purchase.
  */
  struct WhitelistInput {
    uint256 expiryBlock;
    bool isActive;
    address[] addresses;
  }

  /**
    This struct tracks information about a single whitelist known to this
    launchpad. Whitelists may be shared across potentially-multiple item pools.

    @param expiryBlock A block number after which this whitelist is automatically considered inactive, no matter the value of `isActive`.
    @param isActive Whether or not this whitelist is actively restricting purchases in blocks before `expiryBlock`.
    @param currentWhitelistVersion A version number hashed with item group IDs before being used as keys to other mappings. This supports efficient invalidation of stale mappings.
    @param addresses A mapping of hashed addresses to a flag indicating whether this whitelist allows the address to participate in a purchase.
  */
  struct Whitelist {
    uint256 expiryBlock;
    bool isActive;
    uint256 currentWhitelistVersion;
    mapping (bytes32 => bool) addresses;
  }

  /**
    This struct tracks information about a single item being sold in a pool.

    @param groupId The group ID of the specific NFT in the collection being sold by a pool.
    @param cap The maximum number of items that a pool may mint of the specified `groupId`.
    @param minted The number of items that a pool has currently minted of the specified `groupId`.
    @param prices The PricePair options that may be used to purchase this item from its pool.
  */
  struct PoolItem {
    uint256 groupId;
    uint256 cap;
    uint256 minted;
    PricePair[] prices;
  }

  /**
    This struct contains the information gleaned from the `getPool` and
    `getPools` functions; it represents a single pool's data.

    @param name A name for the pool.
    @param startBlock The first block where this pool begins allowing purchases.
    @param endBlock The final block where this pool allows purchases.
    @param purchaseLimit The maximum number of items a single address may purchase from this pool.
    @param requirement A PoolRequirement requisite for users who want to participate in this pool.
    @param itemMetadataUri The metadata URI of the item collection being sold by this launchpad.
    @param items An array of PoolItems representing each item for sale in the pool.
  */
  struct PoolOutput {
    string name;
    uint256 startBlock;
    uint256 endBlock;
    uint256 purchaseLimit;
    PoolRequirement requirement;
    string itemMetadataUri;
    PoolItem[] items;
  }

  /**
    This struct contains the information gleaned from the `getPool` and
    `getPools` functions; it represents a single pool's data. It also includes
    additional information relevant to a user's address lookup.

    @param name A name for the pool.
    @param startBlock The first block where this pool begins allowing purchases.
    @param endBlock The final block where this pool allows purchases.
    @param purchaseLimit The maximum number of items a single address may purchase from this pool.
    @param requirement A PoolRequirement requisite for users who want to participate in this pool.
    @param itemMetadataUri The metadata URI of the item collection being sold by this launchpad.
    @param items An array of PoolItems representing each item for sale in the pool.
    @param purchaseCount The amount of items purchased from this pool by the specified address.
    @param whitelistStatus Whether or not the specified address is whitelisted for this pool.
  */
  struct PoolAddressOutput {
    string name;
    uint256 startBlock;
    uint256 endBlock;
    uint256 purchaseLimit;
    PoolRequirement requirement;
    string itemMetadataUri;
    PoolItem[] items;
    uint256 purchaseCount;
    bool whitelistStatus;
  }

  /// An event to track the original item contract owner clawing back ownership.
  event OwnershipClawback();

  /// An event to track the original item contract owner locking future clawbacks.
  event OwnershipLocked();

  /// An event to track the complete replacement of a pool's data.
  event PoolUpdated(uint256 poolId, PoolInput pool, uint256[] groupIds, uint256[] amounts, PricePair[][] pricePairs);

  /// An event to track the complete replacement of addresses in a whitelist.
  event WhitelistUpdated(uint256 whitelistId, address[] addresses);

  /// An event to track the addition of addresses to a whitelist.
  event WhitelistAddition(uint256 whitelistId, address[] addresses);

  /// An event to track the removal of addresses from a whitelist.
  event WhitelistRemoval(uint256 whitelistId, address[] addresses);

  // An event to track activating or deactivating a whitelist.
  event WhitelistActiveUpdate(uint256 whitelistId, bool isActive);

  // An event to track the purchase of items from a pool.
  event ItemPurchased(uint256 poolId, uint256[] itemIds, uint256 assetId, uint256[] amounts, address user);

  /// @dev a modifier which allows only `originalOwner` to call a function.
  modifier onlyOriginalOwner() {
    require(originalOwner == _msgSender(),
      "You are not the original owner of this contract.");
    _;
  }

  /**
    Construct a new Shop by providing it a FeeOwner.

    @param _item The address of the Fee1155NFTLockable item that will be minting sales.
    @param _feeOwner The address of the FeeOwner due a portion of Shop earnings.
    @param _stakers The addresses of any Stakers to permit spending points from.
    @param _globalPurchaseLimit A global limit on the number of items that a
      single address may purchase across all pools in the launchpad.
  */
  constructor(Fee1155NFTLockable _item, FeeOwner _feeOwner, Staker[] memory _stakers, uint256 _globalPurchaseLimit) public {
    item = _item;
    feeOwner = _feeOwner;
    stakers = _stakers;
    globalPurchaseLimit = _globalPurchaseLimit;

    nextWhitelistId = 1;
    originalOwner = item.owner();
    ownershipLocked = false;
  }

  /**
    A function which allows the caller to retrieve information about specific
    pools, the items for sale within, and the collection this launchpad uses.

    @param poolIds An array of pool IDs to retrieve information about.
  */
  function getPools(uint256[] calldata poolIds) external view returns (PoolOutput[] memory) {
    PoolOutput[] memory poolOutputs = new PoolOutput[](poolIds.length);
    for (uint256 i = 0; i < poolIds.length; i++) {
      uint256 poolId = poolIds[i];

      // Process output for each pool.
      PoolItem[] memory poolItems = new PoolItem[](pools[poolId].itemGroups.length);
      for (uint256 j = 0; j < pools[poolId].itemGroups.length; j++) {
        uint256 itemGroupId = pools[poolId].itemGroups[j];
        bytes32 itemKey = keccak256(abi.encodePacked(pools[poolId].currentPoolVersion, itemGroupId));

        // Parse each price the item is sold at.
        PricePair[] memory itemPrices = new PricePair[](pools[poolId].itemPricesLength[itemKey]);
        for (uint256 k = 0; k < pools[poolId].itemPricesLength[itemKey]; k++) {
          itemPrices[k] = pools[poolId].itemPrices[itemKey][k];
        }

        // Track the item.
        poolItems[j] = PoolItem({
          groupId: itemGroupId,
          cap: pools[poolId].itemCaps[itemKey],
          minted: pools[poolId].itemMinted[itemKey],
          prices: itemPrices
        });
      }

      // Track the pool.
      poolOutputs[i] = PoolOutput({
        name: pools[poolId].name,
        startBlock: pools[poolId].startBlock,
        endBlock: pools[poolId].endBlock,
        purchaseLimit: pools[poolId].purchaseLimit,
        requirement: pools[poolId].requirement,
        itemMetadataUri: item.metadataUri(),
        items: poolItems
      });
    }

    // Return the pools.
    return poolOutputs;
  }

  /**
    A function which allows the caller to retrieve the number of items specific
    addresses have purchased from specific pools.

    @param poolIds The IDs of the pools to check for addresses in `purchasers`.
    @param purchasers The addresses to check the purchase counts for.
  */
  function getPurchaseCounts(uint256[] calldata poolIds, address[] calldata purchasers) external view returns (uint256[][] memory) {
    uint256[][] memory purchaseCounts;
    for (uint256 i = 0; i < poolIds.length; i++) {
      uint256 poolId = poolIds[i];
      for (uint256 j = 0; j < purchasers.length; j++) {
        address purchaser = purchasers[j];
        purchaseCounts[j][i] = pools[poolId].purchaseCounts[purchaser];
      }
    }
    return purchaseCounts;
  }

  /**
    A function which allows the caller to retrieve information about specific
    pools, the items for sale within, and the collection this launchpad uses.
    A provided address differentiates this function from `getPools`; the added
    address enables this function to retrieve pool data as well as whitelisting
    and purchase count details for the provided address.

    @param poolIds An array of pool IDs to retrieve information about.
    @param userAddress An address which enables this function to support additional relevant data lookups.
  */
  function getPoolsWithAddress(uint256[] calldata poolIds, address userAddress) external view returns (PoolAddressOutput[] memory) {
    PoolAddressOutput[] memory poolOutputs = new PoolAddressOutput[](poolIds.length);
    for (uint256 i = 0; i < poolIds.length; i++) {
      uint256 poolId = poolIds[i];

      // Process output for each pool.
      PoolItem[] memory poolItems = new PoolItem[](pools[poolId].itemGroups.length);
      for (uint256 j = 0; j < pools[poolId].itemGroups.length; j++) {
        uint256 itemGroupId = pools[poolId].itemGroups[j];
        bytes32 itemKey = keccak256(abi.encodePacked(pools[poolId].currentPoolVersion, itemGroupId));

        // Parse each price the item is sold at.
        PricePair[] memory itemPrices = new PricePair[](pools[poolId].itemPricesLength[itemKey]);
        for (uint256 k = 0; k < pools[poolId].itemPricesLength[itemKey]; k++) {
          itemPrices[k] = pools[poolId].itemPrices[itemKey][k];
        }

        // Track the item.
        poolItems[j] = PoolItem({
          groupId: itemGroupId,
          cap: pools[poolId].itemCaps[itemKey],
          minted: pools[poolId].itemMinted[itemKey],
          prices: itemPrices
        });
      }

      // Track the pool.
      uint256 whitelistId = pools[poolId].requirement.whitelistId;
      bytes32 addressKey = keccak256(abi.encode(whitelists[whitelistId].currentWhitelistVersion, userAddress));
      poolOutputs[i] = PoolAddressOutput({
        name: pools[poolId].name,
        startBlock: pools[poolId].startBlock,
        endBlock: pools[poolId].endBlock,
        purchaseLimit: pools[poolId].purchaseLimit,
        requirement: pools[poolId].requirement,
        itemMetadataUri: item.metadataUri(),
        items: poolItems,
        purchaseCount: pools[poolId].purchaseCounts[userAddress],
        whitelistStatus: whitelists[whitelistId].addresses[addressKey]
      });
    }

    // Return the pools.
    return poolOutputs;
  }

  /**
    A function which allows the original owner of the item contract to revoke
    ownership from the launchpad.
  */
  function ownershipClawback() external onlyOriginalOwner {
    require(!ownershipLocked,
      "Ownership transfers have been locked.");
    item.transferOwnership(originalOwner);

    // Emit an event that the original owner of the item contract has clawed the contract back.
    emit OwnershipClawback();
  }

  /**
    A function which allows the original owner of this contract to lock all
    future ownership clawbacks.
  */
  function lockOwnership() external onlyOriginalOwner {
    ownershipLocked = true;

    // Emit an event that the contract's ownership transferrance is locked.
    emit OwnershipLocked();
  }

  /**
    Allow the owner of the Shop to add a new pool of items to purchase.

    @param pool The PoolInput full of data defining the pool's operation.
    @param _groupIds The specific Fee1155 item group IDs to sell in this pool, keyed to `_amounts`.
    @param _amounts The maximum amount of each particular groupId that can be sold by this pool.
    @param _pricePairs The asset address to price pairings to use for selling
                       each item.
  */
  function addPool(PoolInput calldata pool, uint256[] calldata _groupIds, uint256[] calldata _amounts, PricePair[][] memory _pricePairs) external onlyOwner {
    updatePool(nextPoolId, pool, _groupIds, _amounts, _pricePairs);

    // Increment the ID which will be used by the next pool added.
    nextPoolId = nextPoolId.add(1);
  }

  /**
    Allow the owner of the Shop to update an existing pool of items.

    @param poolId The ID of the pool to update.
    @param pool The PoolInput full of data defining the pool's operation.
    @param _groupIds The specific Fee1155 item group IDs to sell in this pool, keyed to `_amounts`.
    @param _amounts The maximum amount of each particular groupId that can be sold by this pool.
    @param _pricePairs The asset address to price pairings to use for selling
                       each item.
  */
  function updatePool(uint256 poolId, PoolInput calldata pool, uint256[] calldata _groupIds, uint256[] calldata _amounts, PricePair[][] memory _pricePairs) public onlyOwner {
    require(poolId <= nextPoolId,
      "You cannot update a non-existent pool.");
    require(pool.endBlock >= pool.startBlock,
      "You cannot create a pool which ends before it starts.");
    require(_groupIds.length > 0,
      "You must list at least one item group.");
    require(_groupIds.length == _amounts.length,
      "Item groups length cannot be mismatched with mintable amounts length.");
    require(_groupIds.length == _pricePairs.length,
      "Item groups length cannot be mismatched with price pair inputlength.");

    // Immediately store some given information about this pool.
    uint256 newPoolVersion = pools[poolId].currentPoolVersion.add(1);
    pools[poolId] = Pool({
      name: pool.name,
      startBlock: pool.startBlock,
      endBlock: pool.endBlock,
      purchaseLimit: pool.purchaseLimit,
      itemGroups: _groupIds,
      currentPoolVersion: newPoolVersion,
      requirement: pool.requirement
    });

    // Store the amount of each item group that this pool may mint.
    for (uint256 i = 0; i < _groupIds.length; i++) {
      require(_amounts[i] > 0,
        "You cannot add an item with no mintable amount.");
      bytes32 itemKey = keccak256(abi.encode(newPoolVersion, _groupIds[i]));
      pools[poolId].itemCaps[itemKey] = _amounts[i];

      // Store future purchase information for the item group.
      for (uint256 j = 0; j < _pricePairs[i].length; j++) {
        pools[poolId].itemPrices[itemKey][j] = _pricePairs[i][j];
      }
      pools[poolId].itemPricesLength[itemKey] = _pricePairs[i].length;
    }

    // Emit an event indicating that a pool has been updated.
    emit PoolUpdated(poolId, pool, _groupIds, _amounts, _pricePairs);
  }

  /**
    Allow the owner to add a new whitelist.

    @param whitelist The WhitelistInput full of data defining the new whitelist.
  */
  function addWhitelist(WhitelistInput memory whitelist) external onlyOwner {
    updateWhitelist(nextWhitelistId, whitelist);

    // Increment the ID which will be used by the next whitelist added.
    nextWhitelistId = nextWhitelistId.add(1);
  }

  /**
    Allow the owner to update a whitelist.

    @param whitelistId The whitelist ID to replace with the new whitelist.
    @param whitelist The WhitelistInput full of data defining the new whitelist.
  */
  function updateWhitelist(uint256 whitelistId, WhitelistInput memory whitelist) public onlyOwner {
    uint256 newWhitelistVersion = whitelists[whitelistId].currentWhitelistVersion.add(1);

    // Immediately store some given information about this whitelist.
    whitelists[whitelistId] = Whitelist({
      expiryBlock: whitelist.expiryBlock,
      isActive: whitelist.isActive,
      currentWhitelistVersion: newWhitelistVersion
    });

    // Invalidate the old mapping and store the new participation flags.
    for (uint256 i = 0; i < whitelist.addresses.length; i++) {
      bytes32 addressKey = keccak256(abi.encode(newWhitelistVersion, whitelist.addresses[i]));
      whitelists[whitelistId].addresses[addressKey] = true;
    }

    // Emit an event to track the new, replaced state of the whitelist.
    emit WhitelistUpdated(whitelistId, whitelist.addresses);
  }

  /**
    Allow the owner to add specified addresses to a whitelist.

    @param whitelistId The ID of the whitelist to add users to.
    @param addresses The array of addresses to add.
  */
  function addToWhitelist(uint256 whitelistId, address[] calldata addresses) public onlyOwner {
    uint256 whitelistVersion = whitelists[whitelistId].currentWhitelistVersion;
    for (uint256 i = 0; i < addresses.length; i++) {
      bytes32 addressKey = keccak256(abi.encode(whitelistVersion, addresses[i]));
      whitelists[whitelistId].addresses[addressKey] = true;
    }

    // Emit an event to track the addition of new addresses to the whitelist.
    emit WhitelistAddition(whitelistId, addresses);
  }

  /**
    Allow the owner to remove specified addresses from a whitelist.

    @param whitelistId The ID of the whitelist to remove users from.
    @param addresses The array of addresses to remove.
  */
  function removeFromWhitelist(uint256 whitelistId, address[] calldata addresses) public onlyOwner {
    uint256 whitelistVersion = whitelists[whitelistId].currentWhitelistVersion;
    for (uint256 i = 0; i < addresses.length; i++) {
      bytes32 addressKey = keccak256(abi.encode(whitelistVersion, addresses[i]));
      whitelists[whitelistId].addresses[addressKey] = false;
    }

    // Emit an event to track the removal of addresses from the whitelist.
    emit WhitelistRemoval(whitelistId, addresses);
  }

  /**
    Allow the owner to manually set the active status of a specific whitelist.

    @param whitelistId The ID of the whitelist to update the active flag for.
    @param isActive The boolean flag to enable or disable the whitelist.
  */
  function setWhitelistActive(uint256 whitelistId, bool isActive) public onlyOwner {
    whitelists[whitelistId].isActive = isActive;

    // Emit an event to track whitelist activation status changes.
    emit WhitelistActiveUpdate(whitelistId, isActive);
  }

  /**
    A function which allows the caller to retrieve whether or not addresses can
    participate in some given whitelists.

    @param whitelistIds The IDs of the whitelists to check for addresses.
    @param addresses The addresses to check whitelist eligibility for.
  */
  function getWhitelistStatus(uint256[] calldata whitelistIds, address[] calldata addresses) external view returns (bool[][] memory) {
    bool[][] memory whitelistStatus;
    for (uint256 i = 0; i < whitelistIds.length; i++) {
      uint256 whitelistId = whitelistIds[i];
      uint256 whitelistVersion = whitelists[whitelistId].currentWhitelistVersion;
      for (uint256 j = 0; j < addresses.length; j++) {
        bytes32 addressKey = keccak256(abi.encode(whitelistVersion, addresses[j]));
        whitelistStatus[j][i] = whitelists[whitelistId].addresses[addressKey];
      }
    }
    return whitelistStatus;
  }

  /**
    Allow a user to purchase an item from a pool.

    @param poolId The ID of the particular pool that the user would like to purchase from.
    @param groupId The item group ID that the user would like to purchase.
    @param assetId The type of payment asset that the user would like to purchase with.
    @param amount The amount of item that the user would like to purchase.
  */
  function mintFromPool(uint256 poolId, uint256 groupId, uint256 assetId, uint256 amount) external nonReentrant payable {
    require(amount > 0,
      "You must purchase at least one item.");
    require(poolId < nextPoolId,
      "You can only purchase items from an active pool.");

    // Verify that the asset being used in the purchase is valid.
    bytes32 itemKey = keccak256(abi.encode(pools[poolId].currentPoolVersion, groupId));
    require(assetId < pools[poolId].itemPricesLength[itemKey],
      "Your specified asset ID is not valid.");

    // Verify that the pool is still running its sale.
    require(block.number >= pools[poolId].startBlock && block.number <= pools[poolId].endBlock,
      "This pool is not currently running its sale.");

    // Verify that the pool is respecting per-address global purchase limits.
    uint256 userGlobalPurchaseAmount = amount.add(globalPurchaseCounts[msg.sender]);
    require(userGlobalPurchaseAmount <= globalPurchaseLimit,
      "You may not purchase any more items from this sale.");

    // Verify that the pool is respecting per-address pool purchase limits.
    uint256 userPoolPurchaseAmount = amount.add(pools[poolId].purchaseCounts[msg.sender]);
    require(userPoolPurchaseAmount <= pools[poolId].purchaseLimit,
      "You may not purchase any more items from this pool.");

    // Verify that the pool is either public, whitelist-expired, or an address is whitelisted.
    {
      uint256 whitelistId = pools[poolId].requirement.whitelistId;
      uint256 whitelistVersion = whitelists[whitelistId].currentWhitelistVersion;
      bytes32 addressKey = keccak256(abi.encode(whitelistVersion, msg.sender));
      bool addressWhitelisted = whitelists[whitelistId].addresses[addressKey];
      require(whitelistId == 0 || block.number > whitelists[whitelistId].expiryBlock || addressWhitelisted || !whitelists[whitelistId].isActive,
        "You are not whitelisted on this pool.");
    }

    // Verify that the pool is not depleted by the user's purchase.
    uint256 newCirculatingTotal = pools[poolId].itemMinted[itemKey].add(amount);
    require(newCirculatingTotal <= pools[poolId].itemCaps[itemKey],
      "There are not enough items available for you to purchase.");

    // Verify that the user meets any requirements gating participation in this pool.
    PoolRequirement memory poolRequirement = pools[poolId].requirement;
    if (poolRequirement.requiredType == 1) {
      IERC20 requiredToken = IERC20(poolRequirement.requiredAsset);
      require(requiredToken.balanceOf(msg.sender) >= poolRequirement.requiredAmount,
        "You do not have enough required token to participate in this pool.");
    }

    // TODO: supporting item gate requirement requires upgrading the Fee1155 contract.
    // else if (poolRequirement.requiredType == 2) {
    //   Fee1155 requiredItem = Fee1155(poolRequirement.requiredAsset);
    //   require(requiredItem.balanceOf(msg.sender) >= poolRequirement.requiredAmount,
    //     "You do not have enough required item to participate in this pool.");
    // }

    // Process payment for the user.
    // If the sentinel value for the point asset type is found, sell for points.
    // This involves converting the asset from an address to a Staker index.
    PricePair memory sellingPair = pools[poolId].itemPrices[itemKey][assetId];
    if (sellingPair.assetType == 0) {
      uint256 stakerIndex = uint256(sellingPair.asset);
      stakers[stakerIndex].spendPoints(msg.sender, sellingPair.price.mul(amount));

    // If the sentinel value for the Ether asset type is found, sell for Ether.
    } else if (sellingPair.assetType == 1) {
      uint256 etherPrice = sellingPair.price.mul(amount);
      require(msg.value >= etherPrice,
        "You did not send enough Ether to complete this purchase.");
      (bool success, ) = payable(owner()).call{ value: msg.value }("");
      require(success, "Shop owner transfer failed.");

    // Otherwise, attempt to sell for an ERC20 token.
    } else {
      IERC20 sellingAsset = IERC20(sellingPair.asset);
      uint256 tokenPrice = sellingPair.price.mul(amount);
      require(sellingAsset.balanceOf(msg.sender) >= tokenPrice,
        "You do not have enough token to complete this purchase.");
      sellingAsset.safeTransferFrom(msg.sender, owner(), tokenPrice);
    }

    // If payment is successful, mint each of the user's purchased items.
    uint256[] memory itemIds = new uint256[](amount);
    uint256[] memory amounts = new uint256[](amount);
    uint256 nextIssueNumber = nextItemIssues[groupId];
    {
      uint256 shiftedGroupId = groupId << 128;
      for (uint256 i = 1; i <= amount; i++) {
        uint256 itemId = shiftedGroupId.add(nextIssueNumber).add(i);
        itemIds[i - 1] = itemId;
        amounts[i - 1] = 1;
      }
    }

    // Mint the items.
    item.createNFT(msg.sender, itemIds, amounts, "");

    // Update the tracker for available item issue numbers.
    nextItemIssues[groupId] = nextIssueNumber.add(amount);

    // Update the count of circulating items from this pool.
    pools[poolId].itemMinted[itemKey] = newCirculatingTotal;

    // Update the pool's count of items that a user has purchased.
    pools[poolId].purchaseCounts[msg.sender] = userPoolPurchaseAmount;

    // Update the global count of items that a user has purchased.
    globalPurchaseCounts[msg.sender] = userGlobalPurchaseAmount;

    // Emit an event indicating a successful purchase.
    emit ItemPurchased(poolId, itemIds, assetId, amounts, msg.sender);
  }

  /**
    Sweep all of a particular ERC-20 token from the contract.

    @param _token The token to sweep the balance from.
  */
  function sweep(IERC20 _token) external onlyOwner {
    uint256 balance = _token.balanceOf(address(this));
    _token.safeTransferFrom(address(this), msg.sender, balance);
  }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

import "./FeeOwner.sol";

/**
  @title An OpenSea delegate proxy contract which we include for whitelisting.
  @author OpenSea
*/
contract OwnableDelegateProxy { }

/**
  @title An OpenSea proxy registry contract which we include for whitelisting.
  @author OpenSea
*/
contract ProxyRegistry {
  mapping(address => OwnableDelegateProxy) public proxies;
}

/**
  @title An ERC-1155 item creation contract which specifies an associated
         FeeOwner who receives royalties from sales of created items.
  @author Tim Clancy

  The fee set by the FeeOwner on this Item is honored by Shop contracts.
  In addition to the inherited OpenZeppelin dependency, this uses ideas from
  the original ERC-1155 reference implementation.
*/
contract Fee1155NFTLockable is ERC1155, Ownable {
  using SafeMath for uint256;

  /// A version number for this fee-bearing 1155 item contract's interface.
  uint256 public version = 1;

  /// The ERC-1155 URI for looking up item metadata using {id} substitution.
  string public metadataUri;

  /// A user-specified FeeOwner to receive a portion of item sale earnings.
  FeeOwner public feeOwner;

  /// Specifically whitelist an OpenSea proxy registry address.
  address public proxyRegistryAddress;

  /// A counter to enforce unique IDs for each item group minted.
  uint256 public nextItemGroupId;

  /// This mapping tracks the number of unique items within each item group.
  mapping (uint256 => uint256) public itemGroupSizes;

  /// Whether or not the item collection has been locked to further minting.
  bool public locked;

  /// An event for tracking the creation of an item group.
  event ItemGroupCreated(uint256 itemGroupId, uint256 itemGroupSize,
    address indexed creator);

  /**
    Construct a new ERC-1155 item with an associated FeeOwner fee.

    @param _uri The metadata URI to perform token ID substitution in.
    @param _feeOwner The address of a FeeOwner who receives earnings from this
                     item.
  */
  constructor(string memory _uri, FeeOwner _feeOwner, address _proxyRegistryAddress) public ERC1155(_uri) {
    metadataUri = _uri;
    feeOwner = _feeOwner;
    proxyRegistryAddress = _proxyRegistryAddress;
    nextItemGroupId = 0;
    locked = false;
  }

  /**
    An override to whitelist the OpenSea proxy contract to enable gas-free
    listings. This function returns true if `_operator` is approved to transfer
    items owned by `_owner`.

    @param _owner The owner of items to check for transfer ability.
    @param _operator The potential transferrer of `_owner`'s items.
  */
  function isApprovedForAll(address _owner, address _operator) public view override returns (bool isOperator) {
    ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
    if (address(proxyRegistry.proxies(_owner)) == _operator) {
      return true;
    }
    return ERC1155.isApprovedForAll(_owner, _operator);
  }

  /**
    Allow the item owner to update the metadata URI of this collection.

    @param _uri The new URI to update to.
  */
  function setURI(string calldata _uri) external onlyOwner {
    metadataUri = _uri;
  }

  /**
    Allow the item owner to forever lock this contract to further item minting.
  */
  function lock() external onlyOwner {
    locked = true;
  }

  /**
    Create a new NFT item group of a specific size. NFTs within a group share a
    group ID in the upper 128-bits of their full item ID. Within a group NFTs
    can be distinguished for the purposes of serializing issue numbers.

    @param recipient The address to receive all NFTs within the newly-created group.
    @param ids The item IDs for the new items to create.
    @param amounts The amount of each corresponding item ID to create.
    @param data Any associated data to use on items minted in this transaction.
  */
  function createNFT(address recipient, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external onlyOwner returns (uint256) {
    require(!locked,
      "You cannot create more NFTs on a locked collection.");
    require(ids.length > 0,
      "You cannot create an empty item group.");
    require(ids.length == amounts.length,
      "IDs length cannot be mismatched with amounts length.");

    // Create an item group of requested size using the next available ID.
    uint256 shiftedGroupId = nextItemGroupId << 128;
    itemGroupSizes[shiftedGroupId] = ids.length;

    // Mint the entire batch of items.
    _mintBatch(recipient, ids, amounts, data);

    // Increment our next item group ID and return our created item group ID.
    nextItemGroupId = nextItemGroupId.add(1);
    emit ItemGroupCreated(shiftedGroupId, ids.length, msg.sender);
    return shiftedGroupId;
  }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

/**
  @title An asset staking contract.
  @author Tim Clancy

  This staking contract disburses tokens from its internal reservoir according
  to a fixed emission schedule. Assets can be assigned varied staking weights.
  This code is inspired by and modified from Sushi's Master Chef contract.
  https://github.com/sushiswap/sushiswap/blob/master/contracts/MasterChef.sol
*/
contract Staker is Ownable, ReentrancyGuard {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  // A user-specified, descriptive name for this Staker.
  string public name;

  // The token to disburse.
  IERC20 public token;

  // The amount of the disbursed token deposited by users. This is used for the
  // special case where a staking pool has been created for the disbursed token.
  // This is required to prevent the Staker itself from reducing emissions.
  uint256 public totalTokenDeposited;

  // A flag signalling whether the contract owner can add or set developers.
  bool public canAlterDevelopers;

  // An array of developer addresses for finding shares in the share mapping.
  address[] public developerAddresses;

  // A mapping of developer addresses to their percent share of emissions.
  // Share percentages are represented as 1/1000th of a percent. That is, a 1%
  // share of emissions should map an address to 1000.
  mapping (address => uint256) public developerShares;

  // A flag signalling whether or not the contract owner can alter emissions.
  bool public canAlterTokenEmissionSchedule;
  bool public canAlterPointEmissionSchedule;

  // The token emission schedule of the Staker. This emission schedule maps a
  // block number to the amount of tokens or points that should be disbursed with every
  // block beginning at said block number.
  struct EmissionPoint {
    uint256 blockNumber;
    uint256 rate;
  }

  // An array of emission schedule key blocks for finding emission rate changes.
  uint256 public tokenEmissionBlockCount;
  mapping (uint256 => EmissionPoint) public tokenEmissionBlocks;
  uint256 public pointEmissionBlockCount;
  mapping (uint256 => EmissionPoint) public pointEmissionBlocks;

  // Store the very earliest possible emission block for quick reference.
  uint256 MAX_INT = 2**256 - 1;
  uint256 internal earliestTokenEmissionBlock;
  uint256 internal earliestPointEmissionBlock;

  // Information for each pool that can be staked in.
  // - token: the address of the ERC20 asset that is being staked in the pool.
  // - strength: the relative token emission strength of this pool.
  // - lastRewardBlock: the last block number where token distribution occurred.
  // - tokensPerShare: accumulated tokens per share times 1e12.
  // - pointsPerShare: accumulated points per share times 1e12.
  struct PoolInfo {
    IERC20 token;
    uint256 tokenStrength;
    uint256 tokensPerShare;
    uint256 pointStrength;
    uint256 pointsPerShare;
    uint256 lastRewardBlock;
  }

  IERC20[] public poolTokens;

  // Stored information for each available pool per its token address.
  mapping (IERC20 => PoolInfo) public poolInfo;

  // Information for each user per staking pool:
  // - amount: the amount of the pool asset being provided by the user.
  // - tokenPaid: the value of the user's total earning that has been paid out.
  // -- pending reward = (user.amount * pool.tokensPerShare) - user.rewardDebt.
  // - pointPaid: the value of the user's total point earnings that has been paid out.
  struct UserInfo {
    uint256 amount;
    uint256 tokenPaid;
    uint256 pointPaid;
  }

  // Stored information for each user staking in each pool.
  mapping (IERC20 => mapping (address => UserInfo)) public userInfo;

  // The total sum of the strength of all pools.
  uint256 public totalTokenStrength;
  uint256 public totalPointStrength;

  // The total amount of the disbursed token ever emitted by this Staker.
  uint256 public totalTokenDisbursed;

  // Users additionally accrue non-token points for participating via staking.
  mapping (address => uint256) public userPoints;
  mapping (address => uint256) public userSpentPoints;

  // A map of all external addresses that are permitted to spend user points.
  mapping (address => bool) public approvedPointSpenders;

  // Events for depositing assets into the Staker and later withdrawing them.
  event Deposit(address indexed user, IERC20 indexed token, uint256 amount);
  event Withdraw(address indexed user, IERC20 indexed token, uint256 amount);

  // An event for tracking when a user has spent points.
  event SpentPoints(address indexed source, address indexed user, uint256 amount);

  /**
    Construct a new Staker by providing it a name and the token to disburse.
    @param _name The name of the Staker contract.
    @param _token The token to reward stakers in this contract with.
  */
  constructor(string memory _name, IERC20 _token) public {
    name = _name;
    token = _token;
    token.approve(address(this), MAX_INT);
    canAlterDevelopers = true;
    canAlterTokenEmissionSchedule = true;
    earliestTokenEmissionBlock = MAX_INT;
    canAlterPointEmissionSchedule = true;
    earliestPointEmissionBlock = MAX_INT;
  }

  /**
    Add a new developer to the Staker or overwrite an existing one.
    This operation requires that developer address addition is not locked.
    @param _developerAddress The additional developer's address.
    @param _share The share in 1/1000th of a percent of each token emission sent
    to this new developer.
  */
  function addDeveloper(address _developerAddress, uint256 _share) external onlyOwner {
    require(canAlterDevelopers,
      "This Staker has locked the addition of developers; no more may be added.");
    developerAddresses.push(_developerAddress);
    developerShares[_developerAddress] = _share;
  }

  /**
    Permanently forfeits owner ability to alter the state of Staker developers.
    Once called, this function is intended to give peace of mind to the Staker's
    developers and community that the fee structure is now immutable.
  */
  function lockDevelopers() external onlyOwner {
    canAlterDevelopers = false;
  }

  /**
    A developer may at any time update their address or voluntarily reduce their
    share of emissions by calling this function from their current address.
    Note that updating a developer's share to zero effectively removes them.
    @param _newDeveloperAddress An address to update this developer's address.
    @param _newShare The new share in 1/1000th of a percent of each token
    emission sent to this developer.
  */
  function updateDeveloper(address _newDeveloperAddress, uint256 _newShare) external {
    uint256 developerShare = developerShares[msg.sender];
    require(developerShare > 0,
      "You are not a developer of this Staker.");
    require(_newShare <= developerShare,
      "You cannot increase your developer share.");
    developerShares[msg.sender] = 0;
    developerAddresses.push(_newDeveloperAddress);
    developerShares[_newDeveloperAddress] = _newShare;
  }

  /**
    Set new emission details to the Staker or overwrite existing ones.
    This operation requires that emission schedule alteration is not locked.

    @param _tokenSchedule An array of EmissionPoints defining the token schedule.
    @param _pointSchedule An array of EmissionPoints defining the point schedule.
  */
  function setEmissions(EmissionPoint[] memory _tokenSchedule, EmissionPoint[] memory _pointSchedule) external onlyOwner {
    if (_tokenSchedule.length > 0) {
      require(canAlterTokenEmissionSchedule,
        "This Staker has locked the alteration of token emissions.");
      tokenEmissionBlockCount = _tokenSchedule.length;
      for (uint256 i = 0; i < tokenEmissionBlockCount; i++) {
        tokenEmissionBlocks[i] = _tokenSchedule[i];
        if (earliestTokenEmissionBlock > _tokenSchedule[i].blockNumber) {
          earliestTokenEmissionBlock = _tokenSchedule[i].blockNumber;
        }
      }
    }
    require(tokenEmissionBlockCount > 0,
      "You must set the token emission schedule.");

    if (_pointSchedule.length > 0) {
      require(canAlterPointEmissionSchedule,
        "This Staker has locked the alteration of point emissions.");
      pointEmissionBlockCount = _pointSchedule.length;
      for (uint256 i = 0; i < pointEmissionBlockCount; i++) {
        pointEmissionBlocks[i] = _pointSchedule[i];
        if (earliestPointEmissionBlock > _pointSchedule[i].blockNumber) {
          earliestPointEmissionBlock = _pointSchedule[i].blockNumber;
        }
      }
    }
    require(tokenEmissionBlockCount > 0,
      "You must set the point emission schedule.");
  }

  /**
    Permanently forfeits owner ability to alter the emission schedule.
    Once called, this function is intended to give peace of mind to the Staker's
    developers and community that the inflation rate is now immutable.
  */
  function lockTokenEmissions() external onlyOwner {
    canAlterTokenEmissionSchedule = false;
  }

  /**
    Permanently forfeits owner ability to alter the emission schedule.
    Once called, this function is intended to give peace of mind to the Staker's
    developers and community that the inflation rate is now immutable.
  */
  function lockPointEmissions() external onlyOwner {
    canAlterPointEmissionSchedule = false;
  }

  /**
    Returns the length of the developer address array.
    @return the length of the developer address array.
  */
  function getDeveloperCount() external view returns (uint256) {
    return developerAddresses.length;
  }

  /**
    Returns the length of the staking pool array.
    @return the length of the staking pool array.
  */
  function getPoolCount() external view returns (uint256) {
    return poolTokens.length;
  }

  /**
    Returns the amount of token that has not been disbursed by the Staker yet.
    @return the amount of token that has not been disbursed by the Staker yet.
  */
  function getRemainingToken() external view returns (uint256) {
    return token.balanceOf(address(this));
  }

  /**
    Allows the contract owner to add a new asset pool to the Staker or overwrite
    an existing one.
    @param _token The address of the asset to base this staking pool off of.
    @param _tokenStrength The relative strength of the new asset for earning token.
    @param _pointStrength The relative strength of the new asset for earning points.
  */
  function addPool(IERC20 _token, uint256 _tokenStrength, uint256 _pointStrength) external onlyOwner {
    require(tokenEmissionBlockCount > 0 && pointEmissionBlockCount > 0,
      "Staking pools cannot be addded until an emission schedule has been defined.");
    uint256 lastTokenRewardBlock = block.number > earliestTokenEmissionBlock ? block.number : earliestTokenEmissionBlock;
    uint256 lastPointRewardBlock = block.number > earliestPointEmissionBlock ? block.number : earliestPointEmissionBlock;
    uint256 lastRewardBlock = lastTokenRewardBlock > lastPointRewardBlock ? lastTokenRewardBlock : lastPointRewardBlock;
    if (address(poolInfo[_token].token) == address(0)) {
      poolTokens.push(_token);
      totalTokenStrength = totalTokenStrength.add(_tokenStrength);
      totalPointStrength = totalPointStrength.add(_pointStrength);
      poolInfo[_token] = PoolInfo({
        token: _token,
        tokenStrength: _tokenStrength,
        tokensPerShare: 0,
        pointStrength: _pointStrength,
        pointsPerShare: 0,
        lastRewardBlock: lastRewardBlock
      });
    } else {
      totalTokenStrength = totalTokenStrength.sub(poolInfo[_token].tokenStrength).add(_tokenStrength);
      poolInfo[_token].tokenStrength = _tokenStrength;
      totalPointStrength = totalPointStrength.sub(poolInfo[_token].pointStrength).add(_pointStrength);
      poolInfo[_token].pointStrength = _pointStrength;
    }
  }

  /**
    Uses the emission schedule to calculate the total amount of staking reward
    token that was emitted between two specified block numbers.

    @param _fromBlock The block to begin calculating emissions from.
    @param _toBlock The block to calculate total emissions up to.
  */
  function getTotalEmittedTokens(uint256 _fromBlock, uint256 _toBlock) public view returns (uint256) {
    require(_toBlock >= _fromBlock,
      "Tokens cannot be emitted from a higher block to a lower block.");
    uint256 totalEmittedTokens = 0;
    uint256 workingRate = 0;
    uint256 workingBlock = _fromBlock;
    for (uint256 i = 0; i < tokenEmissionBlockCount; ++i) {
      uint256 emissionBlock = tokenEmissionBlocks[i].blockNumber;
      uint256 emissionRate = tokenEmissionBlocks[i].rate;
      if (_toBlock < emissionBlock) {
        totalEmittedTokens = totalEmittedTokens.add(_toBlock.sub(workingBlock).mul(workingRate));
        return totalEmittedTokens;
      } else if (workingBlock < emissionBlock) {
        totalEmittedTokens = totalEmittedTokens.add(emissionBlock.sub(workingBlock).mul(workingRate));
        workingBlock = emissionBlock;
      }
      workingRate = emissionRate;
    }
    if (workingBlock < _toBlock) {
      totalEmittedTokens = totalEmittedTokens.add(_toBlock.sub(workingBlock).mul(workingRate));
    }
    return totalEmittedTokens;
  }

  /**
    Uses the emission schedule to calculate the total amount of points
    emitted between two specified block numbers.

    @param _fromBlock The block to begin calculating emissions from.
    @param _toBlock The block to calculate total emissions up to.
  */
  function getTotalEmittedPoints(uint256 _fromBlock, uint256 _toBlock) public view returns (uint256) {
    require(_toBlock >= _fromBlock,
      "Points cannot be emitted from a higher block to a lower block.");
    uint256 totalEmittedPoints = 0;
    uint256 workingRate = 0;
    uint256 workingBlock = _fromBlock;
    for (uint256 i = 0; i < pointEmissionBlockCount; ++i) {
      uint256 emissionBlock = pointEmissionBlocks[i].blockNumber;
      uint256 emissionRate = pointEmissionBlocks[i].rate;
      if (_toBlock < emissionBlock) {
        totalEmittedPoints = totalEmittedPoints.add(_toBlock.sub(workingBlock).mul(workingRate));
        return totalEmittedPoints;
      } else if (workingBlock < emissionBlock) {
        totalEmittedPoints = totalEmittedPoints.add(emissionBlock.sub(workingBlock).mul(workingRate));
        workingBlock = emissionBlock;
      }
      workingRate = emissionRate;
    }
    if (workingBlock < _toBlock) {
      totalEmittedPoints = totalEmittedPoints.add(_toBlock.sub(workingBlock).mul(workingRate));
    }
    return totalEmittedPoints;
  }

  /**
    Update the pool corresponding to the specified token address.
    @param _token The address of the asset to update the corresponding pool for.
  */
  function updatePool(IERC20 _token) internal {
    PoolInfo storage pool = poolInfo[_token];
    if (block.number <= pool.lastRewardBlock) {
      return;
    }
    uint256 poolTokenSupply = pool.token.balanceOf(address(this));
    if (address(_token) == address(token)) {
      poolTokenSupply = totalTokenDeposited;
    }
    if (poolTokenSupply <= 0) {
      pool.lastRewardBlock = block.number;
      return;
    }

    // Calculate tokens and point rewards for this pool.
    uint256 totalEmittedTokens = getTotalEmittedTokens(pool.lastRewardBlock, block.number);
    uint256 tokensReward = totalEmittedTokens.mul(pool.tokenStrength).div(totalTokenStrength).mul(1e12);
    uint256 totalEmittedPoints = getTotalEmittedPoints(pool.lastRewardBlock, block.number);
    uint256 pointsReward = totalEmittedPoints.mul(pool.pointStrength).div(totalPointStrength).mul(1e30);

    // Directly pay developers their corresponding share of tokens and points.
    for (uint256 i = 0; i < developerAddresses.length; ++i) {
      address developer = developerAddresses[i];
      uint256 share = developerShares[developer];
      uint256 devTokens = tokensReward.mul(share).div(100000);
      tokensReward = tokensReward - devTokens;
      uint256 devPoints = pointsReward.mul(share).div(100000);
      pointsReward = pointsReward - devPoints;
      token.safeTransferFrom(address(this), developer, devTokens.div(1e12));
      userPoints[developer] = userPoints[developer].add(devPoints.div(1e30));
    }

    // Update the pool rewards per share to pay users the amount remaining.
    pool.tokensPerShare = pool.tokensPerShare.add(tokensReward.div(poolTokenSupply));
    pool.pointsPerShare = pool.pointsPerShare.add(pointsReward.div(poolTokenSupply));
    pool.lastRewardBlock = block.number;
  }

  /**
    A function to easily see the amount of token rewards pending for a user on a
    given pool. Returns the pending reward token amount.
    @param _token The address of a particular staking pool asset to check for a
    pending reward.
    @param _user The user address to check for a pending reward.
    @return the pending reward token amount.
  */
  function getPendingTokens(IERC20 _token, address _user) public view returns (uint256) {
    PoolInfo storage pool = poolInfo[_token];
    UserInfo storage user = userInfo[_token][_user];
    uint256 tokensPerShare = pool.tokensPerShare;
    uint256 poolTokenSupply = pool.token.balanceOf(address(this));
    if (address(_token) == address(token)) {
      poolTokenSupply = totalTokenDeposited;
    }

    if (block.number > pool.lastRewardBlock && poolTokenSupply > 0) {
      uint256 totalEmittedTokens = getTotalEmittedTokens(pool.lastRewardBlock, block.number);
      uint256 tokensReward = totalEmittedTokens.mul(pool.tokenStrength).div(totalTokenStrength).mul(1e12);
      tokensPerShare = tokensPerShare.add(tokensReward.div(poolTokenSupply));
    }

    return user.amount.mul(tokensPerShare).div(1e12).sub(user.tokenPaid);
  }

  /**
    A function to easily see the amount of point rewards pending for a user on a
    given pool. Returns the pending reward point amount.

    @param _token The address of a particular staking pool asset to check for a
    pending reward.
    @param _user The user address to check for a pending reward.
    @return the pending reward token amount.
  */
  function getPendingPoints(IERC20 _token, address _user) public view returns (uint256) {
    PoolInfo storage pool = poolInfo[_token];
    UserInfo storage user = userInfo[_token][_user];
    uint256 pointsPerShare = pool.pointsPerShare;
    uint256 poolTokenSupply = pool.token.balanceOf(address(this));
    if (address(_token) == address(token)) {
      poolTokenSupply = totalTokenDeposited;
    }

    if (block.number > pool.lastRewardBlock && poolTokenSupply > 0) {
      uint256 totalEmittedPoints = getTotalEmittedPoints(pool.lastRewardBlock, block.number);
      uint256 pointsReward = totalEmittedPoints.mul(pool.pointStrength).div(totalPointStrength).mul(1e30);
      pointsPerShare = pointsPerShare.add(pointsReward.div(poolTokenSupply));
    }

    return user.amount.mul(pointsPerShare).div(1e30).sub(user.pointPaid);
  }

  /**
    Return the number of points that the user has available to spend.
    @return the number of points that the user has available to spend.
  */
  function getAvailablePoints(address _user) public view returns (uint256) {
    uint256 concreteTotal = userPoints[_user];
    uint256 pendingTotal = 0;
    for (uint256 i = 0; i < poolTokens.length; ++i) {
      IERC20 poolToken = poolTokens[i];
      uint256 _pendingPoints = getPendingPoints(poolToken, _user);
      pendingTotal = pendingTotal.add(_pendingPoints);
    }
    uint256 spentTotal = userSpentPoints[_user];
    return concreteTotal.add(pendingTotal).sub(spentTotal);
  }

  /**
    Return the total number of points that the user has ever accrued.
    @return the total number of points that the user has ever accrued.
  */
  function getTotalPoints(address _user) external view returns (uint256) {
    uint256 concreteTotal = userPoints[_user];
    uint256 pendingTotal = 0;
    for (uint256 i = 0; i < poolTokens.length; ++i) {
      IERC20 poolToken = poolTokens[i];
      uint256 _pendingPoints = getPendingPoints(poolToken, _user);
      pendingTotal = pendingTotal.add(_pendingPoints);
    }
    return concreteTotal.add(pendingTotal);
  }

  /**
    Return the total number of points that the user has ever spent.
    @return the total number of points that the user has ever spent.
  */
  function getSpentPoints(address _user) external view returns (uint256) {
    return userSpentPoints[_user];
  }

  /**
    Deposit some particular assets to a particular pool on the Staker.
    @param _token The asset to stake into its corresponding pool.
    @param _amount The amount of the provided asset to stake.
  */
  function deposit(IERC20 _token, uint256 _amount) external nonReentrant {
    PoolInfo storage pool = poolInfo[_token];
    require(pool.tokenStrength > 0 || pool.pointStrength > 0,
      "You cannot deposit assets into an inactive pool.");
    UserInfo storage user = userInfo[_token][msg.sender];
    updatePool(_token);
    if (user.amount > 0) {
      uint256 pendingTokens = user.amount.mul(pool.tokensPerShare).div(1e12).sub(user.tokenPaid);
      token.safeTransferFrom(address(this), msg.sender, pendingTokens);
      totalTokenDisbursed = totalTokenDisbursed.add(pendingTokens);
      uint256 pendingPoints = user.amount.mul(pool.pointsPerShare).div(1e30).sub(user.pointPaid);
      userPoints[msg.sender] = userPoints[msg.sender].add(pendingPoints);
    }
    pool.token.safeTransferFrom(address(msg.sender), address(this), _amount);
    if (address(_token) == address(token)) {
      totalTokenDeposited = totalTokenDeposited.add(_amount);
    }
    user.amount = user.amount.add(_amount);
    user.tokenPaid = user.amount.mul(pool.tokensPerShare).div(1e12);
    user.pointPaid = user.amount.mul(pool.pointsPerShare).div(1e30);
    emit Deposit(msg.sender, _token, _amount);
  }

  /**
    Withdraw some particular assets from a particular pool on the Staker.
    @param _token The asset to withdraw from its corresponding staking pool.
    @param _amount The amount of the provided asset to withdraw.
  */
  function withdraw(IERC20 _token, uint256 _amount) external nonReentrant {
    PoolInfo storage pool = poolInfo[_token];
    UserInfo storage user = userInfo[_token][msg.sender];
    require(user.amount >= _amount,
      "You cannot withdraw that much of the specified token; you are not owed it.");
    updatePool(_token);
    uint256 pendingTokens = user.amount.mul(pool.tokensPerShare).div(1e12).sub(user.tokenPaid);
    token.safeTransferFrom(address(this), msg.sender, pendingTokens);
    totalTokenDisbursed = totalTokenDisbursed.add(pendingTokens);
    uint256 pendingPoints = user.amount.mul(pool.pointsPerShare).div(1e30).sub(user.pointPaid);
    userPoints[msg.sender] = userPoints[msg.sender].add(pendingPoints);
    if (address(_token) == address(token)) {
      totalTokenDeposited = totalTokenDeposited.sub(_amount);
    }
    user.amount = user.amount.sub(_amount);
    user.tokenPaid = user.amount.mul(pool.tokensPerShare).div(1e12);
    user.pointPaid = user.amount.mul(pool.pointsPerShare).div(1e30);
    pool.token.safeTransfer(address(msg.sender), _amount);
    emit Withdraw(msg.sender, _token, _amount);
  }

  /**
    Allows the owner of this Staker to grant or remove approval to an external
    spender of the points that users accrue from staking resources.
    @param _spender The external address allowed to spend user points.
    @param _approval The updated user approval status.
  */
  function approvePointSpender(address _spender, bool _approval) external onlyOwner {
    approvedPointSpenders[_spender] = _approval;
  }

  /**
    Allows an approved spender of points to spend points on behalf of a user.
    @param _user The user whose points are being spent.
    @param _amount The amount of the user's points being spent.
  */
  function spendPoints(address _user, uint256 _amount) external {
    require(approvedPointSpenders[msg.sender],
      "You are not permitted to spend user points.");
    uint256 _userPoints = getAvailablePoints(_user);
    require(_userPoints >= _amount,
      "The user does not have enough points to spend the requested amount.");
    userSpentPoints[_user] = userSpentPoints[_user].add(_amount);
    emit SpentPoints(msg.sender, _user, _amount);
  }

  /**
    Sweep all of a particular ERC-20 token from the contract.

    @param _token The token to sweep the balance from.
  */
  function sweep(IERC20 _token) external onlyOwner {
    uint256 balance = _token.balanceOf(address(this));
    _token.safeTransferFrom(address(this), msg.sender, balance);
  }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import "./Token.sol";
import "./Staker.sol";

/**
  @title A basic smart contract for tracking the ownership of SuperFarm Stakers.
  @author Tim Clancy

  This is the governing registry of all SuperFarm Staker assets.
*/
contract FarmStakerRecords is Ownable, ReentrancyGuard {

  /// A struct used to specify token and pool strengths for adding a pool.
  struct PoolData {
    IERC20 poolToken;
    uint256 tokenStrength;
    uint256 pointStrength;
  }

  /// A version number for this record contract's interface.
  uint256 public version = 1;

  /// A mapping for an array of all Stakers deployed by a particular address.
  mapping (address => address[]) public farmRecords;

  /// An event for tracking the creation of a new Staker.
  event FarmCreated(address indexed farmAddress, address indexed creator);

  /**
    Create a Staker on behalf of the owner calling this function. The Staker
    supports immediate specification of the emission schedule and pool strength.

    @param _name The name of the Staker to create.
    @param _token The Token to reward stakers in the Staker with.
    @param _tokenSchedule An array of EmissionPoints defining the token schedule.
    @param _pointSchedule An array of EmissionPoints defining the point schedule.
    @param _initialPools An array of pools to initially add to the new Staker.
  */
  function createFarm(string calldata _name, IERC20 _token, Staker.EmissionPoint[] memory _tokenSchedule, Staker.EmissionPoint[] memory _pointSchedule, PoolData[] calldata _initialPools) nonReentrant external returns (Staker) {
    Staker newStaker = new Staker(_name, _token);

    // Establish the emissions schedule and add the token pools.
    newStaker.setEmissions(_tokenSchedule, _pointSchedule);
    for (uint256 i = 0; i < _initialPools.length; i++) {
      newStaker.addPool(_initialPools[i].poolToken, _initialPools[i].tokenStrength, _initialPools[i].pointStrength);
    }

    // Transfer ownership of the new Staker to the user then store a reference.
    newStaker.transferOwnership(msg.sender);
    address stakerAddress = address(newStaker);
    farmRecords[msg.sender].push(stakerAddress);
    emit FarmCreated(stakerAddress, msg.sender);
    return newStaker;
  }

  /**
    Allow a user to add an existing Staker contract to the registry.

    @param _farmAddress The address of the Staker contract to add for this user.
  */
  function addFarm(address _farmAddress) external {
    farmRecords[msg.sender].push(_farmAddress);
  }

  /**
    Get the number of entries in the Staker records mapping for the given user.

    @return The number of Stakers added for a given address.
  */
  function getFarmCount(address _user) external view returns (uint256) {
    return farmRecords[_user].length;
  }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/ERC20Capped.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
  @title A basic ERC-20 token with voting functionality.
  @author Tim Clancy

  This contract is used when deploying SuperFarm ERC-20 tokens.
  This token is created with a fixed, immutable cap and includes voting rights.
  Voting functionality is copied and modified from Sushi, and in turn from YAM:
  https://github.com/yam-finance/yam-protocol/blob/master/contracts/token/YAMGovernanceStorage.sol
  https://github.com/yam-finance/yam-protocol/blob/master/contracts/token/YAMGovernance.sol
  Which is in turn copied and modified from COMPOUND:
  https://github.com/compound-finance/compound-protocol/blob/master/contracts/Governance/Comp.sol
*/
contract Token is ERC20Capped, Ownable {

  /// A version number for this Token contract's interface.
  uint256 public version = 1;

  /**
    Construct a new Token by providing it a name, ticker, and supply cap.

    @param _name The name of the new Token.
    @param _ticker The ticker symbol of the new Token.
    @param _cap The supply cap of the new Token.
  */
  constructor (string memory _name, string memory _ticker, uint256 _cap) public ERC20(_name, _ticker) ERC20Capped(_cap) { }

  /**
   * @dev Destroys `amount` tokens from the caller.
   *
   * See {ERC20-_burn}.
   */
  function burn(uint256 amount) public virtual {
      _burn(_msgSender(), amount);
  }

  /**
   * @dev Destroys `amount` tokens from `account`, deducting from the caller's
   * allowance.
   *
   * See {ERC20-_burn} and {ERC20-allowance}.
   *
   * Requirements:
   *
   * - the caller must have allowance for ``accounts``'s tokens of at least
   * `amount`.
   */
  function burnFrom(address account, uint256 amount) public virtual {
      uint256 decreasedAllowance = allowance(account, _msgSender()).sub(amount, "ERC20: burn amount exceeds allowance");

      _approve(account, _msgSender(), decreasedAllowance);
      _burn(account, amount);
  }

  /**
    Allows Token creator to mint `_amount` of this Token to the address `_to`.
    New tokens of this Token cannot be minted if it would exceed the supply cap.
    Users are delegated votes when they are minted Token.

    @param _to the address to mint Tokens to.
    @param _amount the amount of new Token to mint.
  */
  function mint(address _to, uint256 _amount) external onlyOwner {
    _mint(_to, _amount);
    _moveDelegates(address(0), _delegates[_to], _amount);
  }

  /**
    Allows users to transfer tokens to a recipient, moving delegated votes with
    the transfer.

    @param recipient The address to transfer tokens to.
    @param amount The amount of tokens to send to `recipient`.
  */
  function transfer(address recipient, uint256 amount) public override returns (bool) {
    _transfer(_msgSender(), recipient, amount);
    _moveDelegates(_delegates[msg.sender], _delegates[recipient], amount);
    return true;
  }

  /// @dev A mapping to record delegates for each address.
  mapping (address => address) internal _delegates;

  /// A checkpoint structure to mark some number of votes from a given block.
  struct Checkpoint {
    uint32 fromBlock;
    uint256 votes;
  }

  /// A mapping to record indexed Checkpoint votes for each address.
  mapping (address => mapping (uint32 => Checkpoint)) public checkpoints;

  /// A mapping to record the number of Checkpoints for each address.
  mapping (address => uint32) public numCheckpoints;

  /// The EIP-712 typehash for the contract's domain.
  bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

  /// The EIP-712 typehash for the delegation struct used by the contract.
  bytes32 public constant DELEGATION_TYPEHASH = keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

  /// A mapping to record per-address states for signing / validating signatures.
  mapping (address => uint) public nonces;

  /// An event emitted when an address changes its delegate.
  event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

  /// An event emitted when the vote balance of a delegated address changes.
  event DelegateVotesChanged(address indexed delegate, uint previousBalance, uint newBalance);

  /**
    Return the address delegated to by `delegator`.

    @return The address delegated to by `delegator`.
  */
  function delegates(address delegator) external view returns (address) {
    return _delegates[delegator];
  }

  /**
    Delegate votes from `msg.sender` to `delegatee`.

    @param delegatee The address to delegate votes to.
  */
  function delegate(address delegatee) external {
    return _delegate(msg.sender, delegatee);
  }

  /**
    Delegate votes from signatory to `delegatee`.

    @param delegatee The address to delegate votes to.
    @param nonce The contract state required for signature matching.
    @param expiry The time at which to expire the signature.
    @param v The recovery byte of the signature.
    @param r Half of the ECDSA signature pair.
    @param s Half of the ECDSA signature pair.
  */
  function delegateBySig(address delegatee, uint nonce, uint expiry, uint8 v, bytes32 r, bytes32 s) external {
    bytes32 domainSeparator = keccak256(
      abi.encode(
        DOMAIN_TYPEHASH,
        keccak256(bytes(name())),
        getChainId(),
        address(this)));

    bytes32 structHash = keccak256(
      abi.encode(
          DELEGATION_TYPEHASH,
          delegatee,
          nonce,
          expiry));

    bytes32 digest = keccak256(
      abi.encodePacked(
        "\x19\x01",
        domainSeparator,
        structHash));

    address signatory = ecrecover(digest, v, r, s);
    require(signatory != address(0), "Invalid signature.");
    require(nonce == nonces[signatory]++, "Invalid nonce.");
    require(now <= expiry, "Signature expired.");
    return _delegate(signatory, delegatee);
  }

  /**
    Get the current votes balance for the address `account`.

    @param account The address to get the votes balance of.
    @return The number of current votes for `account`.
  */
  function getCurrentVotes(address account) external view returns (uint256) {
    uint32 nCheckpoints = numCheckpoints[account];
    return nCheckpoints > 0 ? checkpoints[account][nCheckpoints - 1].votes : 0;
  }

  /**
    Determine the prior number of votes for an address as of a block number.

    @dev The block number must be a finalized block or else this function will revert to prevent misinformation.
    @param account The address to check.
    @param blockNumber The block number to get the vote balance at.
    @return The number of votes the account had as of the given block.
  */
  function getPriorVotes(address account, uint blockNumber) external view returns (uint256) {
    require(blockNumber < block.number, "The specified block is not yet finalized.");

    uint32 nCheckpoints = numCheckpoints[account];
    if (nCheckpoints == 0) {
      return 0;
    }

    // First check the most recent balance.
    if (checkpoints[account][nCheckpoints - 1].fromBlock <= blockNumber) {
      return checkpoints[account][nCheckpoints - 1].votes;
    }

    // Then check the implicit zero balance.
    if (checkpoints[account][0].fromBlock > blockNumber) {
      return 0;
    }

    uint32 lower = 0;
    uint32 upper = nCheckpoints - 1;
    while (upper > lower) {
      uint32 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
      Checkpoint memory cp = checkpoints[account][center];
      if (cp.fromBlock == blockNumber) {
        return cp.votes;
      } else if (cp.fromBlock < blockNumber) {
        lower = center;
      } else {
        upper = center - 1;
      }
    }
    return checkpoints[account][lower].votes;
  }

  /**
    An internal function to actually perform the delegation of votes.

    @param delegator The address delegating to `delegatee`.
    @param delegatee The address receiving delegated votes.
  */
  function _delegate(address delegator, address delegatee) internal {
    address currentDelegate = _delegates[delegator];
    uint256 delegatorBalance = balanceOf(delegator);
    _delegates[delegator] = delegatee;
    /* console.log('a-', currentDelegate, delegator, delegatee); */
    emit DelegateChanged(delegator, currentDelegate, delegatee);

    _moveDelegates(currentDelegate, delegatee, delegatorBalance);
  }

  /**
    An internal function to move delegated vote amounts between addresses.

    @param srcRep the previous representative who received delegated votes.
    @param dstRep the new representative to receive these delegated votes.
    @param amount the amount of delegated votes to move between representatives.
  */
  function _moveDelegates(address srcRep, address dstRep, uint256 amount) internal {
    if (srcRep != dstRep && amount > 0) {

      // Decrease the number of votes delegated to the previous representative.
      if (srcRep != address(0)) {
        uint32 srcRepNum = numCheckpoints[srcRep];
        uint256 srcRepOld = srcRepNum > 0 ? checkpoints[srcRep][srcRepNum - 1].votes : 0;
        uint256 srcRepNew = srcRepOld.sub(amount);
        _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
      }

      // Increase the number of votes delegated to the new representative.
      if (dstRep != address(0)) {
        uint32 dstRepNum = numCheckpoints[dstRep];
        uint256 dstRepOld = dstRepNum > 0 ? checkpoints[dstRep][dstRepNum - 1].votes : 0;
        uint256 dstRepNew = dstRepOld.add(amount);
        _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
      }
    }
  }

  /**
    An internal function to write a checkpoint of modified vote amounts.
    This function is guaranteed to add at most one checkpoint per block.

    @param delegatee The address whose vote count is changed.
    @param nCheckpoints The number of checkpoints by address `delegatee`.
    @param oldVotes The prior vote count of address `delegatee`.
    @param newVotes The new vote count of address `delegatee`.
  */
  function _writeCheckpoint(address delegatee, uint32 nCheckpoints, uint256 oldVotes, uint256 newVotes) internal {
    uint32 blockNumber = safe32(block.number, "Block number exceeds 32 bits.");

    if (nCheckpoints > 0 && checkpoints[delegatee][nCheckpoints - 1].fromBlock == blockNumber) {
      checkpoints[delegatee][nCheckpoints - 1].votes = newVotes;
    } else {
      checkpoints[delegatee][nCheckpoints] = Checkpoint(blockNumber, newVotes);
      numCheckpoints[delegatee] = nCheckpoints + 1;
    }

    emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
  }

  /**
    A function to safely limit a number to less than 2^32.

    @param n the number to limit.
    @param errorMessage the error message to revert with should `n` be too large.
    @return The number `n` limited to 32 bits.
  */
  function safe32(uint n, string memory errorMessage) internal pure returns (uint32) {
    require(n < 2**32, errorMessage);
    return uint32(n);
  }

  /**
    A function to return the ID of the contract's particular network or chain.

    @return The ID of the contract's network or chain.
  */
  function getChainId() internal pure returns (uint) {
    uint256 chainId;
    assembly { chainId := chainid() }
    return chainId;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./ERC20.sol";

/**
 * @dev Extension of {ERC20} that adds a cap to the supply of tokens.
 */
abstract contract ERC20Capped is ERC20 {
    using SafeMath for uint256;

    uint256 private _cap;

    /**
     * @dev Sets the value of the `cap`. This value is immutable, it can only be
     * set once during construction.
     */
    constructor (uint256 cap_) internal {
        require(cap_ > 0, "ERC20Capped: cap is 0");
        _cap = cap_;
    }

    /**
     * @dev Returns the cap on the token's total supply.
     */
    function cap() public view virtual returns (uint256) {
        return _cap;
    }

    /**
     * @dev See {ERC20-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - minted tokens must not cause the total supply to go over the cap.
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        if (from == address(0)) { // When minting tokens
            require(totalSupply().add(amount) <= cap(), "ERC20Capped: cap exceeded");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

import "./Token.sol";

/**
  @title A vault for securely holding tokens.
  @author Tim Clancy

  The purpose of this contract is to hold a single type of ERC-20 token securely
  behind a Compound Timelock governed by a Gnosis MultiSigWallet. Tokens may
  only leave the vault with multisignature permission and after passing through
  a mandatory timelock. The justification for the timelock is such that, if the
  multisignature wallet is ever compromised, the team will have two days to act
  in mitigating the potential damage from the attacker's `sentTokens` call. Such
  mitigation efforts may include calling `panic` from a separate, uncompromised
  and non-timelocked multisignature wallet, or finding some way to issue a new
  token entirely.
*/
contract TokenVault is Ownable, ReentrancyGuard {
  using SafeMath for uint256;

  /// A version number for this TokenVault contract's interface.
  uint256 public version = 1;

  /// A user-specified, descriptive name for this TokenVault.
  string public name;

  /// The token to hold safe.
  Token public token;

  /**
    The panic owner is an optional address allowed to immediately send the
    contents of the vault to the address specified in `panicDestination`. The
    intention of this system is to support a series of cascading vaults secured
    by their own multisignature wallets. If, for instance, vault one is
    compromised via its attached multisignature wallet, vault two could
    intercede to save the tokens from vault one before the malicious token send
    clears the owning timelock.
  */
  address public panicOwner;

  /// An optional address where tokens may be immediately sent by `panicOwner`.
  address public panicDestination;

  /**
    A counter to limit the number of times a vault can panic before burning the
    underlying supply of tokens. This limit is in place to protect against a
    situation where multiple vaults linked in a circle are all compromised. In
    the event of such an attack, this still gives the original multisignature
    holders the chance to burn the tokens by repeatedly calling `panic` before
    the attacker can use `sendTokens`.
  */
  uint256 public panicLimit;

  /// A counter for the number of times this vault has panicked.
  uint256 public panicCounter;

  /// A flag to determine whether or not this vault can alter its `panicOwner` and `panicDestination`.
  bool public canAlterPanicDetails;

  /// An event for tracking a change in panic details.
  event PanicDetailsChange(address indexed panicOwner, address indexed panicDestination);

  /// An event for tracking a lock on alteration of panic details.
  event PanicDetailsLocked();

  /// An event for tracking a disbursement of tokens.
  event TokenSend(uint256 tokenAmount);

  /// An event for tracking a panic transfer of tokens.
  event PanicTransfer(uint256 panicCounter, uint256 tokenAmount, address indexed destination);

  /// An event for tracking a panic burn of tokens.
  event PanicBurn(uint256 panicCounter, uint256 tokenAmount);

  /// @dev a modifier which allows only `panicOwner` to call a function.
  modifier onlyPanicOwner() {
    require(panicOwner == _msgSender(),
      "TokenVault: caller is not the panic owner");
    _;
  }

  /**
    Construct a new TokenVault by providing it a name and the token to disburse.

    @param _name The name of the TokenVault.
    @param _token The token to store and disburse.
    @param _panicOwner The address to grant emergency withdrawal powers to.
    @param _panicDestination The destination to withdraw to in emergency.
    @param _panicLimit A limit for the number of times `panic` can be called before tokens burn.
  */
  constructor(string memory _name, Token _token, address _panicOwner, address _panicDestination, uint256 _panicLimit) public {
    name = _name;
    token = _token;
    panicOwner = _panicOwner;
    panicDestination = _panicDestination;
    panicLimit = _panicLimit;
    panicCounter = 0;
    canAlterPanicDetails = true;
    uint256 MAX_INT = 2**256 - 1;
    token.approve(address(this), MAX_INT);
  }

  /**
    Allows the owner of the TokenVault to update the `panicOwner` and
    `panicDestination` details governing its panic functionality.

    @param _panicOwner The new panic owner to set.
    @param _panicDestination The new emergency destination to send tokens to.
  */
  function changePanicDetails(address _panicOwner, address _panicDestination) external nonReentrant onlyOwner {
    require(canAlterPanicDetails,
      "You cannot change panic details on a vault which is locked.");
    panicOwner = _panicOwner;
    panicDestination = _panicDestination;
    emit PanicDetailsChange(panicOwner, panicDestination);
  }

  /**
    Allows the owner of the TokenVault to lock the vault to all future panic
    detail changes.
  */
  function lock() external nonReentrant onlyOwner {
    canAlterPanicDetails = false;
    emit PanicDetailsLocked();
  }

  /**
    Allows the TokenVault owner to send tokens out of the vault.

    @param _recipients The array of addresses to receive tokens.
    @param _amounts The array of amounts sent to each address in `_recipients`.
  */
  function sendTokens(address[] calldata _recipients, uint256[] calldata _amounts) external nonReentrant onlyOwner {
    require(_recipients.length > 0,
      "You must send tokens to at least one recipient.");
    require(_recipients.length == _amounts.length,
      "Recipients length cannot be mismatched with amounts length.");

    // Iterate through every specified recipient and send tokens.
    uint256 totalAmount = 0;
    for (uint256 i = 0; i < _recipients.length; i++) {
      address recipient = _recipients[i];
      uint256 amount = _amounts[i];
      token.transfer(recipient, amount);
      totalAmount = totalAmount.add(amount);
    }
    emit TokenSend(totalAmount);
  }

  /**
    Allow the TokenVault's `panicOwner` to immediately send its contents to a
    predefined `panicDestination`. This can be used to circumvent the timelock
    in case of an emergency.
  */
  function panic() external nonReentrant onlyPanicOwner {
    uint256 totalBalance = token.balanceOf(address(this));

    // If the panic limit is reached, burn the tokens.
    if (panicCounter == panicLimit) {
      token.burn(totalBalance);
      emit PanicBurn(panicCounter, totalBalance);

    // Otherwise, drain the vault to the panic destination.
    } else {
      if (panicDestination == address(0)) {
        token.burn(totalBalance);
        emit PanicBurn(panicCounter, totalBalance);
      } else {
        token.transfer(panicDestination, totalBalance);
        emit PanicTransfer(panicCounter, totalBalance, panicDestination);
      }
      panicCounter = panicCounter.add(1);
    }
  }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

/**
  @title A token vesting contract for streaming claims.
  @author SuperFarm

  This vesting contract allows users to claim vested tokens with every block.
*/
contract VestStream is Ownable, ReentrancyGuard {
  using SafeMath for uint256;
  using SafeMath for uint64;
  using SafeERC20 for IERC20;

  /// The token to disburse in vesting.
  IERC20 public token;

  // Information for a particular token claim.
  // - totalAmount: the total size of the token claim.
  // - startTime: the timestamp in seconds when the vest begins.
  // - endTime: the timestamp in seconds when the vest completely matures.
  // - lastCLaimTime: the timestamp in seconds of the last time the claim was utilized.
  // - amountClaimed: the total amount claimed from the entire claim.
  struct Claim {
    uint256 totalAmount;
    uint64 startTime;
    uint64 endTime;
    uint64 lastClaimTime;
    uint256 amountClaimed;
  }

  // A mapping of addresses to the claim received.
  mapping(address => Claim) private claims;

  /// An event for tracking the creation of a token vest claim.
  event ClaimCreated(address creator, address beneficiary);

  /// An event for tracking a user claiming some of their vested tokens.
  event Claimed(address beneficiary, uint256 amount);

  /**
    Construct a new VestStream by providing it a token to disburse.

    @param _token The token to vest to claimants in this contract.
  */
  constructor(IERC20 _token) public {
    token = _token;
    uint256 MAX_INT = 2**256 - 1;
    token.approve(address(this), MAX_INT);
  }

  /**
    A function which allows the caller to retrieve information about a specific
    claim via its beneficiary.

    @param beneficiary the beneficiary to query claims for.
  */
  function getClaim(address beneficiary) external view returns (Claim memory) {
    require(beneficiary != address(0), "The zero address may not be a claim beneficiary.");
    return claims[beneficiary];
  }

  /**
    A function which allows the caller to retrieve information about a specific
    claim's remaining claimable amount.

    @param beneficiary the beneficiary to query claims for.
  */
  function claimableAmount(address beneficiary) public view returns (uint256) {
    Claim memory claim = claims[beneficiary];

    // Early-out if the claim has not started yet.
    if (claim.startTime == 0 || block.timestamp < claim.startTime) {
      return 0;
    }

    // Calculate the current releasable token amount.
    uint64 currentTimestamp = uint64(block.timestamp) > claim.endTime ? claim.endTime : uint64(block.timestamp);
    uint256 claimPercent = currentTimestamp.sub(claim.startTime).mul(1e18).div(claim.endTime.sub(claim.startTime));
    uint256 claimAmount = claim.totalAmount.mul(claimPercent).div(1e18);

    // Reduce the unclaimed amount by the amount already claimed.
    uint256 unclaimedAmount = claimAmount.sub(claim.amountClaimed);
    return unclaimedAmount;
  }

  /**
    Sweep all of a particular ERC-20 token from the contract.

    @param _token The token to sweep the balance from.
  */
  function sweep(IERC20 _token) external onlyOwner {
    uint256 balance = _token.balanceOf(address(this));
    _token.safeTransferFrom(address(this), msg.sender, balance);
  }

  /**
    A function which allows the caller to create toke vesting claims for some
    beneficiaries. The disbursement token will be taken from the claim creator.

    @param _beneficiaries an array of addresses to construct token claims for.
    @param _totalAmounts the total amount of tokens to be disbursed to each beneficiary.
    @param _startTime a timestamp when this claim is to begin vesting.
    @param _endTime a timestamp when this claim is to reach full maturity.
  */
  function createClaim(address[] memory _beneficiaries, uint256[] memory _totalAmounts, uint64 _startTime, uint64 _endTime) external onlyOwner {
    require(_beneficiaries.length > 0, "You must specify at least one beneficiary for a claim.");
    require(_beneficiaries.length == _totalAmounts.length, "Beneficiaries and their amounts may not be mismatched.");
    require(_endTime >= _startTime, "You may not create a claim which ends before it starts.");

    // After validating the details for this token claim, initialize a claim for
    // each specified beneficiary.
    for (uint i = 0; i < _beneficiaries.length; i++) {
      address _beneficiary = _beneficiaries[i];
      uint256 _totalAmount = _totalAmounts[i];
      require(_beneficiary != address(0), "The zero address may not be a beneficiary.");
      require(_totalAmount > 0, "You may not create a zero-token claim.");

      // Establish a claim for this particular beneficiary.
      Claim memory claim = Claim({
        totalAmount: _totalAmount,
        startTime: _startTime,
        endTime: _endTime,
        lastClaimTime: _startTime,
        amountClaimed: 0
      });
      claims[_beneficiary] = claim;
      emit ClaimCreated(msg.sender, _beneficiary);
    }
  }

  /**
    A function which allows the caller to send a claim's unclaimed amount to the
    beneficiary of the claim.

    @param beneficiary the beneficiary to claim for.
  */
  function claim(address beneficiary) external nonReentrant {
    Claim memory _claim = claims[beneficiary];

    // Verify that the claim is still active.
    require(_claim.lastClaimTime < _claim.endTime, "This claim has already been completely claimed.");

    // Calculate the current releasable token amount.
    uint64 currentTimestamp = uint64(block.timestamp) > _claim.endTime ? _claim.endTime : uint64(block.timestamp);
    uint256 claimPercent = currentTimestamp.sub(_claim.startTime).mul(1e18).div(_claim.endTime.sub(_claim.startTime));
    uint256 claimAmount = _claim.totalAmount.mul(claimPercent).div(1e18);

    // Reduce the unclaimed amount by the amount already claimed.
    uint256 unclaimedAmount = claimAmount.sub(_claim.amountClaimed);

    // Transfer the unclaimed tokens to the beneficiary.
    token.safeTransferFrom(address(this), beneficiary, unclaimedAmount);

    // Update the amount currently claimed by the user.
    _claim.amountClaimed = claimAmount;

    // Update the last time the claim was utilized.
    _claim.lastClaimTime = currentTimestamp;

    // Update the claim structure being tracked.
    claims[beneficiary] = _claim;

    // Emit an event for this token claim.
    emit Claimed(beneficiary, unclaimedAmount);
  }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

/**
  @title An OpenSea mock proxy contract which we use to test whitelisting.
  @author OpenSea
*/
contract MockProxyRegistry is Ownable {
  using SafeMath for uint256;

  /// A mapping of testing proxies.
  mapping(address => address) public proxies;

  /**
    Allow the registry owner to set a proxy on behalf of an address.

    @param _address The address that the proxy will act on behalf of.
    @param _proxyForAddress The proxy that will act on behalf of the address.
  */
  function setProxy(address _address, address _proxyForAddress) external onlyOwner {
    proxies[_address] = _proxyForAddress;
  }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC1155/ERC1155Holder.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

import "./FeeOwner.sol";
import "./Fee1155.sol";

/**
  @title A simple Shop contract for selling ERC-1155s for Ether via direct
         minting.
  @author Tim Clancy

  This contract is a limited subset of the Shop1155 contract designed to mint
  items directly to the user upon purchase.
*/
contract ShopEtherMinter1155 is ERC1155Holder, Ownable, ReentrancyGuard {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  /// A version number for this Shop contract's interface.
  uint256 public version = 1;

  /// @dev A mask for isolating an item's group ID.
  uint256 constant GROUP_MASK = uint256(uint128(~0)) << 128;

  /// A user-specified Fee1155 contract to support selling items from.
  Fee1155 public item;

  /// A user-specified FeeOwner to receive a portion of Shop earnings.
  FeeOwner public feeOwner;

  /// The Shop's inventory of item groups for sale.
  uint256[] public inventory;

  /// The Shop's price for each item group.
  mapping (uint256 => uint256) public prices;

  /**
    Construct a new Shop by providing it a FeeOwner.

    @param _item The address of the Fee1155 item that will be minting sales.
    @param _feeOwner The address of the FeeOwner due a portion of Shop earnings.
  */
  constructor(Fee1155 _item, FeeOwner _feeOwner) public {
    item = _item;
    feeOwner = _feeOwner;
  }

  /**
    Returns the length of the inventory array.

    @return the length of the inventory array.
  */
  function getInventoryCount() external view returns (uint256) {
    return inventory.length;
  }

  /**
    Allows the Shop owner to list a new set of NFT items for sale.

    @param _groupIds The item group IDs to list for sale in this shop.
    @param _prices The corresponding purchase price to mint an item of each group.
  */
  function listItems(uint256[] calldata _groupIds, uint256[] calldata _prices) external onlyOwner {
    require(_groupIds.length > 0,
      "You must list at least one item.");
    require(_groupIds.length == _prices.length,
      "Items length cannot be mismatched with prices length.");

    // Iterate through every specified item group to list items.
    for (uint256 i = 0; i < _groupIds.length; i++) {
      uint256 groupId = _groupIds[i];
      uint256 price = _prices[i];
      inventory.push(groupId);
      prices[groupId] = price;
    }
  }

  /**
    Allows the Shop owner to remove items from sale.

    @param _groupIds The group IDs currently listed in the shop to take off sale.
  */
  function removeItems(uint256[] calldata _groupIds) external onlyOwner {
    require(_groupIds.length > 0,
      "You must remove at least one item.");

    // Iterate through every specified item group to remove items.
    for (uint256 i = 0; i < _groupIds.length; i++) {
      uint256 groupId = _groupIds[i];
      prices[groupId] = 0;
    }
  }

  /**
    Allows any user to purchase items from this Shop. Users supply specfic item
    IDs within the groups listed for sale and supply the corresponding amount of
    Ether to cover the purchase prices.

    @param _itemIds The specific item IDs to purchase from this shop.
  */
  function purchaseItems(uint256[] calldata _itemIds) public nonReentrant payable {
    require(_itemIds.length > 0,
      "You must purchase at least one item.");

    // Iterate through every specified item to list items.
    uint256 feePercent = feeOwner.fee();
    uint256 itemRoyaltyPercent = item.feeOwner().fee();
    for (uint256 i = 0; i < _itemIds.length; i++) {
      uint256 itemId = _itemIds[i];
      uint256 groupId = itemId & GROUP_MASK;
      uint256 price = prices[groupId];
      require(price > 0,
        "You cannot purchase an item that is not listed.");

      // Split fees for this purchase.
      uint256 feeValue = price.mul(feePercent).div(100000);
      uint256 royaltyValue = price.mul(itemRoyaltyPercent).div(100000);
      (bool success, ) = payable(feeOwner.owner()).call{ value: feeValue }("");
      require(success, "Platform fee transfer failed.");
      (success, ) = payable(item.feeOwner().owner()).call{ value: royaltyValue }("");
      require(success, "Creator royalty transfer failed.");
      (success, ) = payable(owner()).call{ value: price.sub(feeValue).sub(royaltyValue) }("");
      require(success, "Shop owner transfer failed.");

      // Mint the item.
      item.mint(msg.sender, itemId, 1, "");
    }
  }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

// TRUFFLE
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract SuperVestCliff {
    using SafeMath for uint256;
    using Address for address;

    address public tokenAddress;

    event Claimed(
        address owner,
        address beneficiary,
        uint256 amount,
        uint256 index
    );
    event ClaimCreated(address owner, address beneficiary, uint256 index);

    struct Claim {
        address owner;
        address beneficiary;
        uint256[] timePeriods;
        uint256[] tokenAmounts;
        uint256 totalAmount;
        uint256 amountClaimed;
        uint256 periodsClaimed;
    }
    Claim[] private claims;

    mapping(address => uint256[]) private _ownerClaims;
    mapping(address => uint256[]) private _beneficiaryClaims;

    constructor(address _tokenAddress) public {
        tokenAddress = _tokenAddress;
    }

    /**
     * Get Owner Claims
     *
     * @param owner - Claim Owner Address
     */
    function ownerClaims(address owner)
        external
        view
        returns (uint256[] memory)
    {
        require(owner != address(0), "Owner address cannot be 0");
        return _ownerClaims[owner];
    }

    /**
     * Get Beneficiary Claims
     *
     * @param beneficiary - Claim Owner Address
     */
    function beneficiaryClaims(address beneficiary)
        external
        view
        returns (uint256[] memory)
    {
        require(beneficiary != address(0), "Beneficiary address cannot be 0");
        return _beneficiaryClaims[beneficiary];
    }

    /**
     * Get Amount Claimed
     *
     * @param index - Claim Index
     */
    function claimed(uint256 index) external view returns (uint256) {
        return claims[index].amountClaimed;
    }

    /**
     * Get Total Claim Amount
     *
     * @param index - Claim Index
     */
    function totalAmount(uint256 index) external view returns (uint256) {
        return claims[index].totalAmount;
    }

    /**
     * Get Time Periods of Claim
     *
     * @param index - Claim Index
     */
    function timePeriods(uint256 index)
        external
        view
        returns (uint256[] memory)
    {
        return claims[index].timePeriods;
    }

    /**
     * Get Token Amounts of Claim
     *
     * @param index - Claim Index
     */
    function tokenAmounts(uint256 index)
        external
        view
        returns (uint256[] memory)
    {
        return claims[index].tokenAmounts;
    }

    /**
     * Create a Claim - To Vest Tokens to Beneficiary
     *
     * @param _beneficiary - Tokens will be claimed by _beneficiary
     * @param _timePeriods - uint256 Array of Epochs
     * @param _tokenAmounts - uin256 Array of Amounts to transfer at each time period
     */
    function createClaim(
        address _beneficiary,
        uint256[] memory _timePeriods,
        uint256[] memory _tokenAmounts
    ) public returns (bool) {
        require(
            _timePeriods.length == _tokenAmounts.length,
            "_timePeriods & _tokenAmounts length mismatch"
        );
        require(tokenAddress.isContract(), "Invalid tokenAddress");
        require(_beneficiary != address(0), "Cannot Vest to address 0");
        // Calculate total amount
        uint256 _totalAmount = 0;
        for (uint256 i = 0; i < _tokenAmounts.length; i++) {
            _totalAmount = _totalAmount.add(_tokenAmounts[i]);
        }
        require(_totalAmount > 0, "Provide Token Amounts to Vest");
        require(
            ERC20(tokenAddress).allowance(msg.sender, address(this)) >=
                _totalAmount,
            "Provide token allowance to SuperVestCliff contract"
        );
        // Transfer Tokens to SuperStreamClaim
        ERC20(tokenAddress).transferFrom(
            msg.sender,
            address(this),
            _totalAmount
        );
        // Create Claim
        Claim memory claim =
            Claim({
                owner: msg.sender,
                beneficiary: _beneficiary,
                timePeriods: _timePeriods,
                tokenAmounts: _tokenAmounts,
                totalAmount: _totalAmount,
                amountClaimed: 0,
                periodsClaimed: 0
            });
        claims.push(claim);
        uint256 index = claims.length - 1;
        // Map Claim Index to Owner & Beneficiary
        _ownerClaims[msg.sender].push(index);
        _beneficiaryClaims[_beneficiary].push(index);
        emit ClaimCreated(msg.sender, _beneficiary, index);
        return true;
    }

    /**
     * Claim Tokens
     *
     * @param index - Index of the Claim
     */
    function claim(uint256 index) external {
        Claim storage claim = claims[index];
        // Check if msg.sender is the beneficiary
        require(
            claim.beneficiary == msg.sender,
            "Only beneficiary can claim tokens"
        );
        // Check if anything is left to release
        require(
            claim.periodsClaimed < claim.timePeriods.length,
            "Nothing to release"
        );
        // Calculate releasable amount
        uint256 amount = 0;
        for (
            uint256 i = claim.periodsClaimed;
            i < claim.timePeriods.length;
            i++
        ) {
            if (claim.timePeriods[i] <= block.timestamp) {
                amount = amount.add(claim.tokenAmounts[i]);
                claim.periodsClaimed = claim.periodsClaimed.add(1);
            } else {
                break;
            }
        }
        // If there is any amount to release
        require(amount > 0, "Nothing to release");
        // Transfer Tokens from Owner to Beneficiary
        ERC20(tokenAddress).transfer(claim.beneficiary, amount);
        claim.amountClaimed = claim.amountClaimed.add(amount);
        emit Claimed(claim.owner, claim.beneficiary, amount, index);
    }

    /**
     * Get Amount of tokens that can be claimed
     *
     * @param index - Index of the Claim
     */
    function claimableAmount(uint256 index) public view returns (uint256) {
        Claim storage claim = claims[index];
        // Calculate Claimable Amount
        uint256 amount = 0;
        for (
            uint256 i = claim.periodsClaimed;
            i < claim.timePeriods.length;
            i++
        ) {
            if (claim.timePeriods[i] <= block.timestamp) {
                amount = amount.add(claim.tokenAmounts[i]);
            } else {
                break;
            }
        }
        return amount;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

// TRUFFLE
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract SuperNFTVestStream {
    using SafeMath for uint256;
    using Address for address;

    address public tokenAddress;
    address public nftAddress;

    event Claimed(
        address owner,
        uint256 nftId,
        address beneficiary,
        uint256 amount,
        uint256 index
    );
    event ClaimCreated(
        address owner,
        uint256 nftId,
        uint256 totalAmount,
        uint256 index
    );

    struct Claim {
        address owner;
        uint256 nftId;
        uint256[] timePeriods;
        uint256[] tokenAmounts;
        uint256 totalAmount;
        uint256 amountClaimed;
        uint256 periodsClaimed;
    }
    Claim[] private claims;

    struct StreamInfo {
        uint256 startTime;
        bool notOverflow;
        uint256 startDiff;
        uint256 diff;
        uint256 amountPerBlock;
        uint256[] _timePeriods;
        uint256[] _tokenAmounts;
    }

    mapping(address => uint256[]) private _ownerClaims;
    mapping(uint256 => uint256[]) private _nftClaims;

    constructor(address _tokenAddress, address _nftAddress) public {
        require(
            _tokenAddress.isContract(),
            "_tokenAddress must be a contract address"
        );
        require(
            _nftAddress.isContract(),
            "_nftAddress must be a contract address"
        );
        tokenAddress = _tokenAddress;
        nftAddress = _nftAddress;
    }

    /**
     * Get Owner Claims
     *
     * @param owner - Claim Owner Address
     */
    function ownerClaims(address owner)
        external
        view
        returns (uint256[] memory)
    {
        require(owner != address(0), "Owner address cannot be 0");
        return _ownerClaims[owner];
    }

    /**
     * Get NFT Claims
     *
     * @param nftId - NFT ID
     */
    function nftClaims(uint256 nftId) external view returns (uint256[] memory) {
        require(nftId != 0, "nftId cannot be 0");
        return _nftClaims[nftId];
    }

    /**
     * Get Amount Claimed
     *
     * @param index - Claim Index
     */
    function claimed(uint256 index) external view returns (uint256) {
        return claims[index].amountClaimed;
    }

    /**
     * Get Total Claim Amount
     *
     * @param index - Claim Index
     */
    function totalAmount(uint256 index) external view returns (uint256) {
        return claims[index].totalAmount;
    }

    /**
     * Get Time Periods of Claim
     *
     * @param index - Claim Index
     */
    function timePeriods(uint256 index)
        external
        view
        returns (uint256[] memory)
    {
        return claims[index].timePeriods;
    }

    /**
     * Get Token Amounts of Claim
     *
     * @param index - Claim Index
     */
    function tokenAmounts(uint256 index)
        external
        view
        returns (uint256[] memory)
    {
        return claims[index].tokenAmounts;
    }

    /**
     * Create a Claim - To Vest Tokens to NFT
     *
     * @param _nftId - Tokens will be claimed by owner of _nftId
     * @param _startBlock - Block Number to start vesting from
     * @param _stopBlock - Block Number to end vesting at (Release all tokens)
     * @param _totalAmount - Total Amount to be Vested
     * @param _blockTime - Block Time (used for predicting _timePeriods)
     */
    function createClaim(
        uint256 _nftId,
        uint256 _startBlock,
        uint256 _stopBlock,
        uint256 _totalAmount,
        uint256 _blockTime
    ) external returns (bool) {
        require(_nftId != 0, "Cannot Vest to NFT 0");
        require(
            _stopBlock > _startBlock,
            "_stopBlock must be greater than _startBlock"
        );
        require(tokenAddress.isContract(), "Invalid tokenAddress");
        require(_totalAmount > 0, "Provide Token Amounts to Vest");
        require(
            ERC20(tokenAddress).allowance(msg.sender, address(this)) >=
                _totalAmount,
            "Provide token allowance to SuperNFTVestStream contract"
        );
        // Calculate estimated epoch for _startBlock
        StreamInfo memory streamInfo =
            StreamInfo(0, false, 0, 0, 0, new uint256[](0), new uint256[](0));
        (streamInfo.notOverflow, streamInfo.startDiff) = _startBlock.trySub(
            block.number
        );
        if (streamInfo.notOverflow) {
            // If Not Overflow
            streamInfo.startTime = block.timestamp.add(
                _blockTime.mul(streamInfo.startDiff)
            );
        } else {
            // If Overflow
            streamInfo.startDiff = block.number.sub(_startBlock);
            streamInfo.startTime = block.timestamp.sub(
                _blockTime.mul(streamInfo.startDiff)
            );
        }
        // Calculate _timePeriods & _tokenAmounts
        streamInfo.diff = _stopBlock.sub(_startBlock);
        streamInfo.amountPerBlock = _totalAmount.div(streamInfo.diff);
        streamInfo._timePeriods = new uint256[](streamInfo.diff);
        streamInfo._tokenAmounts = new uint256[](streamInfo.diff);

        streamInfo._timePeriods[0] = streamInfo.startTime;
        streamInfo._tokenAmounts[0] = streamInfo.amountPerBlock;
        for (uint256 i = 1; i < streamInfo.diff; i++) {
            streamInfo._timePeriods[i] = streamInfo._timePeriods[i - 1].add(
                _blockTime
            );
            streamInfo._tokenAmounts[i] = streamInfo.amountPerBlock;
        }
        // Transfer Tokens to SuperVestStream
        ERC20(tokenAddress).transferFrom(
            msg.sender,
            address(this),
            _totalAmount
        );
        // Create Claim
        Claim memory claim =
            Claim({
                owner: msg.sender,
                nftId: _nftId,
                timePeriods: streamInfo._timePeriods,
                tokenAmounts: streamInfo._tokenAmounts,
                totalAmount: _totalAmount,
                amountClaimed: 0,
                periodsClaimed: 0
            });
        claims.push(claim);
        uint256 index = claims.length - 1;
        // Map Claim Index to Owner & Beneficiary
        _ownerClaims[msg.sender].push(index);
        _nftClaims[_nftId].push(index);
        emit ClaimCreated(msg.sender, _nftId, _totalAmount, index);
        return true;
    }

    /**
     * Claim Tokens
     *
     * @param index - Index of the Claim
     */
    function claim(uint256 index) external {
        Claim storage claim = claims[index];
        // Check if msg.sender is the owner of the NFT
        require(
            msg.sender == ERC721(nftAddress).ownerOf(claim.nftId),
            "msg.sender must own the NFT"
        );
        // Check if anything is left to release
        require(
            claim.periodsClaimed < claim.timePeriods.length,
            "Nothing to release"
        );
        // Calculate releasable amount
        uint256 amount = 0;
        for (
            uint256 i = claim.periodsClaimed;
            i < claim.timePeriods.length;
            i++
        ) {
            if (claim.timePeriods[i] <= block.timestamp) {
                amount = amount.add(claim.tokenAmounts[i]);
                claim.periodsClaimed = claim.periodsClaimed.add(1);
            } else {
                break;
            }
        }
        // If there is any amount to release
        require(amount > 0, "Nothing to release");
        // Transfer Tokens from Owner to Beneficiary
        ERC20(tokenAddress).transfer(msg.sender, amount);
        claim.amountClaimed = claim.amountClaimed.add(amount);
        emit Claimed(claim.owner, claim.nftId, msg.sender, amount, index);
    }

    /**
     * Get Amount of tokens that can be claimed
     *
     * @param index - Index of the Claim
     */
    function claimableAmount(uint256 index) public view returns (uint256) {
        Claim storage claim = claims[index];
        // Calculate Claimable Amount
        uint256 amount = 0;
        for (
            uint256 i = claim.periodsClaimed;
            i < claim.timePeriods.length;
            i++
        ) {
            if (claim.timePeriods[i] <= block.timestamp) {
                amount = amount.add(claim.tokenAmounts[i]);
            } else {
                break;
            }
        }
        return amount;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/Context.sol";
import "./IERC721.sol";
import "./IERC721Metadata.sol";
import "./IERC721Enumerable.sol";
import "./IERC721Receiver.sol";
import "../../introspection/ERC165.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";
import "../../utils/EnumerableSet.sol";
import "../../utils/EnumerableMap.sol";
import "../../utils/Strings.sol";

/**
 * @title ERC721 Non-Fungible Token Standard basic implementation
 * @dev see https://eips.ethereum.org/EIPS/eip-721
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata, IERC721Enumerable {
    using SafeMath for uint256;
    using Address for address;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableMap for EnumerableMap.UintToAddressMap;
    using Strings for uint256;

    // Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    // which can be also obtained as `IERC721Receiver(0).onERC721Received.selector`
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

    // Mapping from holder address to their (enumerable) set of owned tokens
    mapping (address => EnumerableSet.UintSet) private _holderTokens;

    // Enumerable mapping from token ids to their owners
    EnumerableMap.UintToAddressMap private _tokenOwners;

    // Mapping from token ID to approved address
    mapping (uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Optional mapping for token URIs
    mapping (uint256 => string) private _tokenURIs;

    // Base URI
    string private _baseURI;

    /*
     *     bytes4(keccak256('balanceOf(address)')) == 0x70a08231
     *     bytes4(keccak256('ownerOf(uint256)')) == 0x6352211e
     *     bytes4(keccak256('approve(address,uint256)')) == 0x095ea7b3
     *     bytes4(keccak256('getApproved(uint256)')) == 0x081812fc
     *     bytes4(keccak256('setApprovalForAll(address,bool)')) == 0xa22cb465
     *     bytes4(keccak256('isApprovedForAll(address,address)')) == 0xe985e9c5
     *     bytes4(keccak256('transferFrom(address,address,uint256)')) == 0x23b872dd
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256)')) == 0x42842e0e
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256,bytes)')) == 0xb88d4fde
     *
     *     => 0x70a08231 ^ 0x6352211e ^ 0x095ea7b3 ^ 0x081812fc ^
     *        0xa22cb465 ^ 0xe985e9c5 ^ 0x23b872dd ^ 0x42842e0e ^ 0xb88d4fde == 0x80ac58cd
     */
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;

    /*
     *     bytes4(keccak256('name()')) == 0x06fdde03
     *     bytes4(keccak256('symbol()')) == 0x95d89b41
     *     bytes4(keccak256('tokenURI(uint256)')) == 0xc87b56dd
     *
     *     => 0x06fdde03 ^ 0x95d89b41 ^ 0xc87b56dd == 0x5b5e139f
     */
    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;

    /*
     *     bytes4(keccak256('totalSupply()')) == 0x18160ddd
     *     bytes4(keccak256('tokenOfOwnerByIndex(address,uint256)')) == 0x2f745c59
     *     bytes4(keccak256('tokenByIndex(uint256)')) == 0x4f6ccce7
     *
     *     => 0x18160ddd ^ 0x2f745c59 ^ 0x4f6ccce7 == 0x780e9d63
     */
    bytes4 private constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;

        // register the supported interfaces to conform to ERC721 via ERC165
        _registerInterface(_INTERFACE_ID_ERC721);
        _registerInterface(_INTERFACE_ID_ERC721_METADATA);
        _registerInterface(_INTERFACE_ID_ERC721_ENUMERABLE);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _holderTokens[owner].length();
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        return _tokenOwners.get(tokenId, "ERC721: owner query for nonexistent token");
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }
        // If there is a baseURI but no tokenURI, concatenate the tokenID to the baseURI.
        return string(abi.encodePacked(base, tokenId.toString()));
    }

    /**
    * @dev Returns the base URI set via {_setBaseURI}. This will be
    * automatically added as a prefix in {tokenURI} to each token's URI, or
    * to the token ID if no specific URI is set for that token ID.
    */
    function baseURI() public view virtual returns (string memory) {
        return _baseURI;
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        return _holderTokens[owner].at(index);
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        // _tokenOwners are indexed by tokenIds, so .length() returns the number of tokenIds
        return _tokenOwners.length();
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        (uint256 tokenId, ) = _tokenOwners.at(index);
        return tokenId;
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(_msgSender() == owner || ERC721.isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _tokenOwners.contains(tokenId);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || ERC721.isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     d*
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(address to, uint256 tokenId, bytes memory _data) internal virtual {
        _mint(to, tokenId);
        require(_checkOnERC721Received(address(0), to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _holderTokens[to].add(tokenId);

        _tokenOwners.set(tokenId, to);

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId); // internal owner

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        // Clear metadata (if any)
        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }

        _holderTokens[owner].remove(tokenId);

        _tokenOwners.remove(tokenId);

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own"); // internal owner
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _holderTokens[from].remove(tokenId);
        _holderTokens[to].add(tokenId);

        _tokenOwners.set(tokenId, to);

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev Internal function to set the base URI for all token IDs. It is
     * automatically added as a prefix to the value returned in {tokenURI},
     * or to the token ID if {tokenURI} is empty.
     */
    function _setBaseURI(string memory baseURI_) internal virtual {
        _baseURI = baseURI_;
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
        private returns (bool)
    {
        if (!to.isContract()) {
            return true;
        }
        bytes memory returndata = to.functionCall(abi.encodeWithSelector(
            IERC721Receiver(to).onERC721Received.selector,
            _msgSender(),
            from,
            tokenId,
            _data
        ), "ERC721: transfer to non ERC721Receiver implementer");
        bytes4 retval = abi.decode(returndata, (bytes4));
        return (retval == _ERC721_RECEIVED);
    }

    function _approve(address to, uint256 tokenId) private {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId); // internal owner
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual { }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "../../introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
      * @dev Safely transfers `tokenId` token from `from` to `to`.
      *
      * Requirements:
      *
      * - `from` cannot be the zero address.
      * - `to` cannot be the zero address.
      * - `tokenId` token must exist and be owned by `from`.
      * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
      * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
      *
      * Emits a {Transfer} event.
      */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "./IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {

    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "./IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Library for managing an enumerable variant of Solidity's
 * https://solidity.readthedocs.io/en/latest/types.html#mapping-types[`mapping`]
 * type.
 *
 * Maps have the following properties:
 *
 * - Entries are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Entries are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableMap for EnumerableMap.UintToAddressMap;
 *
 *     // Declare a set state variable
 *     EnumerableMap.UintToAddressMap private myMap;
 * }
 * ```
 *
 * As of v3.0.0, only maps of type `uint256 -> address` (`UintToAddressMap`) are
 * supported.
 */
library EnumerableMap {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Map type with
    // bytes32 keys and values.
    // The Map implementation uses private functions, and user-facing
    // implementations (such as Uint256ToAddressMap) are just wrappers around
    // the underlying Map.
    // This means that we can only create new EnumerableMaps for types that fit
    // in bytes32.

    struct MapEntry {
        bytes32 _key;
        bytes32 _value;
    }

    struct Map {
        // Storage of map keys and values
        MapEntry[] _entries;

        // Position of the entry defined by a key in the `entries` array, plus 1
        // because index 0 means a key is not in the map.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function _set(Map storage map, bytes32 key, bytes32 value) private returns (bool) {
        // We read and store the key's index to prevent multiple reads from the same storage slot
        uint256 keyIndex = map._indexes[key];

        if (keyIndex == 0) { // Equivalent to !contains(map, key)
            map._entries.push(MapEntry({ _key: key, _value: value }));
            // The entry is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            map._indexes[key] = map._entries.length;
            return true;
        } else {
            map._entries[keyIndex - 1]._value = value;
            return false;
        }
    }

    /**
     * @dev Removes a key-value pair from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function _remove(Map storage map, bytes32 key) private returns (bool) {
        // We read and store the key's index to prevent multiple reads from the same storage slot
        uint256 keyIndex = map._indexes[key];

        if (keyIndex != 0) { // Equivalent to contains(map, key)
            // To delete a key-value pair from the _entries array in O(1), we swap the entry to delete with the last one
            // in the array, and then remove the last entry (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = keyIndex - 1;
            uint256 lastIndex = map._entries.length - 1;

            // When the entry to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            MapEntry storage lastEntry = map._entries[lastIndex];

            // Move the last entry to the index where the entry to delete is
            map._entries[toDeleteIndex] = lastEntry;
            // Update the index for the moved entry
            map._indexes[lastEntry._key] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved entry was stored
            map._entries.pop();

            // Delete the index for the deleted slot
            delete map._indexes[key];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function _contains(Map storage map, bytes32 key) private view returns (bool) {
        return map._indexes[key] != 0;
    }

    /**
     * @dev Returns the number of key-value pairs in the map. O(1).
     */
    function _length(Map storage map) private view returns (uint256) {
        return map._entries.length;
    }

   /**
    * @dev Returns the key-value pair stored at position `index` in the map. O(1).
    *
    * Note that there are no guarantees on the ordering of entries inside the
    * array, and it may change when more entries are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Map storage map, uint256 index) private view returns (bytes32, bytes32) {
        require(map._entries.length > index, "EnumerableMap: index out of bounds");

        MapEntry storage entry = map._entries[index];
        return (entry._key, entry._value);
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     */
    function _tryGet(Map storage map, bytes32 key) private view returns (bool, bytes32) {
        uint256 keyIndex = map._indexes[key];
        if (keyIndex == 0) return (false, 0); // Equivalent to contains(map, key)
        return (true, map._entries[keyIndex - 1]._value); // All indexes are 1-based
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function _get(Map storage map, bytes32 key) private view returns (bytes32) {
        uint256 keyIndex = map._indexes[key];
        require(keyIndex != 0, "EnumerableMap: nonexistent key"); // Equivalent to contains(map, key)
        return map._entries[keyIndex - 1]._value; // All indexes are 1-based
    }

    /**
     * @dev Same as {_get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {_tryGet}.
     */
    function _get(Map storage map, bytes32 key, string memory errorMessage) private view returns (bytes32) {
        uint256 keyIndex = map._indexes[key];
        require(keyIndex != 0, errorMessage); // Equivalent to contains(map, key)
        return map._entries[keyIndex - 1]._value; // All indexes are 1-based
    }

    // UintToAddressMap

    struct UintToAddressMap {
        Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(UintToAddressMap storage map, uint256 key, address value) internal returns (bool) {
        return _set(map._inner, bytes32(key), bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(UintToAddressMap storage map, uint256 key) internal returns (bool) {
        return _remove(map._inner, bytes32(key));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(UintToAddressMap storage map, uint256 key) internal view returns (bool) {
        return _contains(map._inner, bytes32(key));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(UintToAddressMap storage map) internal view returns (uint256) {
        return _length(map._inner);
    }

   /**
    * @dev Returns the element stored at position `index` in the set. O(1).
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintToAddressMap storage map, uint256 index) internal view returns (uint256, address) {
        (bytes32 key, bytes32 value) = _at(map._inner, index);
        return (uint256(key), address(uint160(uint256(value))));
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     *
     * _Available since v3.4._
     */
    function tryGet(UintToAddressMap storage map, uint256 key) internal view returns (bool, address) {
        (bool success, bytes32 value) = _tryGet(map._inner, bytes32(key));
        return (success, address(uint160(uint256(value))));
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(UintToAddressMap storage map, uint256 key) internal view returns (address) {
        return address(uint160(uint256(_get(map._inner, bytes32(key)))));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(UintToAddressMap storage map, uint256 key, string memory errorMessage) internal view returns (address) {
        return address(uint160(uint256(_get(map._inner, bytes32(key), errorMessage))));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    /**
     * @dev Converts a `uint256` to its ASCII `string` representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        uint256 index = digits - 1;
        temp = value;
        while (temp != 0) {
            buffer[index--] = bytes1(uint8(48 + temp % 10));
            temp /= 10;
        }
        return string(buffer);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

// TRUFFLE
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract SuperNFTVestCliff {
    using SafeMath for uint256;
    using Address for address;

    address public tokenAddress;
    address public nftAddress;

    event Claimed(
        address owner,
        uint256 nftId,
        address beneficiary,
        uint256 amount,
        uint256 index
    );
    event ClaimCreated(
        address owner,
        uint256 nftId,
        uint256 totalAmount,
        uint256 index
    );

    struct Claim {
        address owner;
        uint256 nftId;
        uint256[] timePeriods;
        uint256[] tokenAmounts;
        uint256 totalAmount;
        uint256 amountClaimed;
        uint256 periodsClaimed;
    }
    Claim[] private claims;

    mapping(address => uint256[]) private _ownerClaims;
    mapping(uint256 => uint256[]) private _nftClaims;

    constructor(address _tokenAddress, address _nftAddress) public {
        require(
            _tokenAddress.isContract(),
            "_tokenAddress must be a contract address"
        );
        require(
            _nftAddress.isContract(),
            "_nftAddress must be a contract address"
        );
        tokenAddress = _tokenAddress;
        nftAddress = _nftAddress;
    }

    /**
     * Get Owner Claims
     *
     * @param owner - Claim Owner Address
     */
    function ownerClaims(address owner)
        external
        view
        returns (uint256[] memory)
    {
        require(owner != address(0), "Owner address cannot be 0");
        return _ownerClaims[owner];
    }

    /**
     * Get NFT Claims
     *
     * @param nftId - NFT ID
     */
    function nftClaims(uint256 nftId) external view returns (uint256[] memory) {
        require(nftId != 0, "nftId cannot be 0");
        return _nftClaims[nftId];
    }

    /**
     * Get Amount Claimed
     *
     * @param index - Claim Index
     */
    function claimed(uint256 index) external view returns (uint256) {
        return claims[index].amountClaimed;
    }

    /**
     * Get Total Claim Amount
     *
     * @param index - Claim Index
     */
    function totalAmount(uint256 index) external view returns (uint256) {
        return claims[index].totalAmount;
    }

    /**
     * Get Time Periods of Claim
     *
     * @param index - Claim Index
     */
    function timePeriods(uint256 index)
        external
        view
        returns (uint256[] memory)
    {
        return claims[index].timePeriods;
    }

    /**
     * Get Token Amounts of Claim
     *
     * @param index - Claim Index
     */
    function tokenAmounts(uint256 index)
        external
        view
        returns (uint256[] memory)
    {
        return claims[index].tokenAmounts;
    }

    /**
     * Create a Claim - To Vest Tokens to NFT
     *
     * @param _nftId - Tokens will be claimed by owner of _nftId
     * @param _timePeriods - uint256 Array of Epochs
     * @param _tokenAmounts - uin256 Array of Amounts to transfer at each time period
     */
    function createClaim(
        uint256 _nftId,
        uint256[] memory _timePeriods,
        uint256[] memory _tokenAmounts
    ) public returns (bool) {
        require(_nftId != 0, "Cannot Vest to NFT 0");
        require(
            _timePeriods.length == _tokenAmounts.length,
            "_timePeriods & _tokenAmounts length mismatch"
        );
        // Calculate total amount
        uint256 _totalAmount = 0;
        for (uint256 i = 0; i < _tokenAmounts.length; i++) {
            _totalAmount = _totalAmount.add(_tokenAmounts[i]);
        }
        require(_totalAmount > 0, "Provide Token Amounts to Vest");
        require(
            ERC20(tokenAddress).allowance(msg.sender, address(this)) >=
                _totalAmount,
            "Provide token allowance to SuperStreamClaim contract"
        );
        // Transfer Tokens to SuperStreamClaim
        ERC20(tokenAddress).transferFrom(
            msg.sender,
            address(this),
            _totalAmount
        );
        // Create Claim
        Claim memory claim =
            Claim({
                owner: msg.sender,
                nftId: _nftId,
                timePeriods: _timePeriods,
                tokenAmounts: _tokenAmounts,
                totalAmount: _totalAmount,
                amountClaimed: 0,
                periodsClaimed: 0
            });
        claims.push(claim);
        uint256 index = claims.length.sub(1);
        // Map Claim Index to Owner & Beneficiary
        _ownerClaims[msg.sender].push(index);
        _nftClaims[_nftId].push(index);
        emit ClaimCreated(msg.sender, _nftId, _totalAmount, index);
        return true;
    }

    /**
     * Claim Tokens
     *
     * @param index - Index of the Claim
     */
    function claim(uint256 index) external {
        Claim storage claim = claims[index];
        // Check if msg.sender is the owner of the NFT
        require(
            msg.sender == ERC721(nftAddress).ownerOf(claim.nftId),
            "msg.sender must own the NFT"
        );
        // Check if anything is left to release
        require(
            claim.periodsClaimed < claim.timePeriods.length,
            "Nothing to release"
        );
        // Calculate releasable amount
        uint256 amount = 0;
        for (
            uint256 i = claim.periodsClaimed;
            i < claim.timePeriods.length;
            i++
        ) {
            if (claim.timePeriods[i] <= block.timestamp) {
                amount = amount.add(claim.tokenAmounts[i]);
                claim.periodsClaimed = claim.periodsClaimed.add(1);
            } else {
                break;
            }
        }
        // If there is any amount to release
        require(amount > 0, "Nothing to release");
        // Transfer Tokens from Owner to Beneficiary
        ERC20(tokenAddress).transfer(msg.sender, amount);
        claim.amountClaimed = claim.amountClaimed.add(amount);
        emit Claimed(claim.owner, claim.nftId, msg.sender, amount, index);
    }

    /**
     * Get Amount of tokens that can be claimed
     *
     * @param index - Index of the Claim
     */
    function claimableAmount(uint256 index) public view returns (uint256) {
        Claim storage claim = claims[index];
        // Calculate Claimable Amount
        uint256 amount = 0;
        for (
            uint256 i = claim.periodsClaimed;
            i < claim.timePeriods.length;
            i++
        ) {
            if (claim.timePeriods[i] <= block.timestamp) {
                amount = amount.add(claim.tokenAmounts[i]);
            } else {
                break;
            }
        }
        return amount;
    }
}

pragma solidity ^0.6.2;

// REMIX
// import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v3.4/contracts/token/ERC721/ERC721.sol";
// import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v3.4/contracts/token/ERC20/ERC20.sol";
// import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v3.4/contracts/utils/Counters.sol";
// import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v3.4/contracts/utils/EnumerableSet.sol";
// import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v3.4/contracts/math/SafeMath.sol";
// import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v3.4/contracts/utils/Address.sol";

// TRUFFLE
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";

// SuperNFT SMART CONTRACT
contract SuperNFT is ERC721 {
    using EnumerableSet for EnumerableSet.UintSet;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    mapping(string => uint8) hashes;

    /**
     * Mint + Issue NFT
     *
     * @param recipient - NFT will be issued to recipient
     * @param hash - Artwork IPFS hash
     * @param data - Artwork URI/Data
     */
    function issueToken(
        address recipient,
        string memory hash,
        string memory data
    ) public returns (uint256) {
        require(hashes[hash] != 1);
        hashes[hash] = 1;
        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();
        _mint(recipient, newTokenId);
        _setTokenURI(newTokenId, data);
        return newTokenId;
    }

    constructor() public ERC721("SUPER NFT", "SNFT") {}
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../math/SafeMath.sol";

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented or decremented by one. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 * Since it is not possible to overflow a 256 bit integer with increments of one, `increment` can skip the {SafeMath}
 * overflow check, thereby saving gas. This does assume however correct usage, in that the underlying `_value` is never
 * directly accessed.
 */
library Counters {
    using SafeMath for uint256;

    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        // The {SafeMath} overflow check can be skipped here, see the comment at the top
        counter._value += 1;
    }

    function decrement(Counter storage counter) internal {
        counter._value = counter._value.sub(1);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

import "./FeeOwner.sol";

/**
  @title An OpenSea delegate proxy contract which we include for whitelisting.
  @author OpenSea
*/
contract OwnableDelegateProxy { }

/**
  @title An OpenSea proxy registry contract which we include for whitelisting.
  @author OpenSea
*/
contract ProxyRegistry {
  mapping(address => OwnableDelegateProxy) public proxies;
}

/**
  @title An ERC-1155 item creation contract which specifies an associated
         FeeOwner who receives royalties from sales of created items.
  @author Tim Clancy

  The fee set by the FeeOwner on this Item is honored by Shop contracts.
  In addition to the inherited OpenZeppelin dependency, this uses ideas from
  the original ERC-1155 reference implementation.
*/
contract Fee1155NFT is ERC1155, Ownable {
  using SafeMath for uint256;

  /// A version number for this fee-bearing 1155 item contract's interface.
  uint256 public version = 1;

  /// The ERC-1155 URI for looking up item metadata using {id} substitution.
  string public metadataUri;

  /// A user-specified FeeOwner to receive a portion of item sale earnings.
  FeeOwner public feeOwner;

  /// Specifically whitelist an OpenSea proxy registry address.
  address public proxyRegistryAddress;

  /// A counter to enforce unique IDs for each item group minted.
  uint256 public nextItemGroupId;

  /// This mapping tracks the number of unique items within each item group.
  mapping (uint256 => uint256) public itemGroupSizes;

  /// An event for tracking the creation of an item group.
  event ItemGroupCreated(uint256 itemGroupId, uint256 itemGroupSize,
    address indexed creator);

  /**
    Construct a new ERC-1155 item with an associated FeeOwner fee.

    @param _uri The metadata URI to perform token ID substitution in.
    @param _feeOwner The address of a FeeOwner who receives earnings from this
                     item.
  */
  constructor(string memory _uri, FeeOwner _feeOwner, address _proxyRegistryAddress) public ERC1155(_uri) {
    metadataUri = _uri;
    feeOwner = _feeOwner;
    proxyRegistryAddress = _proxyRegistryAddress;
    nextItemGroupId = 0;
  }

  /**
    An override to whitelist the OpenSea proxy contract to enable gas-free
    listings. This function returns true if `_operator` is approved to transfer
    items owned by `_owner`.

    @param _owner The owner of items to check for transfer ability.
    @param _operator The potential transferrer of `_owner`'s items.
  */
  function isApprovedForAll(address _owner, address _operator) public view override returns (bool isOperator) {
    ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
    if (address(proxyRegistry.proxies(_owner)) == _operator) {
      return true;
    }
    return ERC1155.isApprovedForAll(_owner, _operator);
  }

  /**
    Allow the item owner to update the metadata URI of this collection.

    @param _uri The new URI to update to.
  */
  function setURI(string calldata _uri) external onlyOwner {
    metadataUri = _uri;
  }

  /**
    Create a new NFT item group of a specific size. NFTs within a group share a
    group ID in the upper 128-bits of their full item ID. Within a group NFTs
    can be distinguished for the purposes of serializing issue numbers.

    @param recipient The address to receive all NFTs within the newly-created group.
    @param groupSize The number of individual NFTs to create within the group.
    @param data Any associated data to use on items minted in this transaction.
  */
  function createNFT(address recipient, uint256 groupSize, bytes calldata data) external onlyOwner returns (uint256) {
    require(groupSize > 0,
      "You cannot create an empty item group.");

    // Create an item group of requested size using the next available ID.
    uint256 shiftedGroupId = nextItemGroupId << 128;
    itemGroupSizes[shiftedGroupId] = groupSize;

    // Record the supply cap of each item being created in the group.
    uint256[] memory itemIds = new uint256[](groupSize);
    uint256[] memory amounts = new uint256[](groupSize);
    for (uint256 i = 1; i <= groupSize; i++) {
      itemIds[i - 1] = shiftedGroupId.add(i);
      amounts[i - 1] = 1;
    }

    // Mint the entire batch of items.
    _mintBatch(recipient, itemIds, amounts, data);

    // Increment our next item group ID and return our created item group ID.
    nextItemGroupId = nextItemGroupId.add(1);
    emit ItemGroupCreated(shiftedGroupId, groupSize, msg.sender);
    return shiftedGroupId;
  }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC1155/ERC1155Holder.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

import "./FeeOwner.sol";
import "./Fee1155.sol";
import "./Staker.sol";

/**
  @title A simple Shop contract for selling ERC-1155s for points, Ether, or
         ERC-20 tokens.
  @author Tim Clancy

  This contract allows its owner to list NFT items for sale. NFT items are
  purchased by users using points spent on a corresponding Staker contract.
  The Shop must be approved by the owner of the Staker contract.
*/
contract Shop1155 is ERC1155Holder, Ownable, ReentrancyGuard {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  /// A version number for this Shop contract's interface.
  uint256 public version = 1;

  /// A user-specified, descriptive name for this Shop.
  string public name;

  /// A user-specified FeeOwner to receive a portion of Shop earnings.
  FeeOwner public feeOwner;

  /// A user-specified Staker contract to spend user points on.
  Staker[] public stakers;

  /**
    This struct tracks information about a single asset with associated price
    that an item is being sold in the shop for.

    @param assetType A sentinel value for the specific type of asset being used.
                     0 = non-transferrable points from a Staker; see `asset`.
                     1 = Ether.
                     2 = an ERC-20 token, see `asset`.
    @param asset Some more specific information about the asset to charge in.
                 If the `assetType` is 0, we convert the given address to an
                 integer index for finding a specific Staker from `stakers`.
                 If the `assetType` is 1, we ignore this field.
                 If the `assetType` is 2, we use this address to find the ERC-20
                 token that we should be specifically charging with.
    @param price The amount of the specified `assetType` and `asset` to charge.
  */
  struct PricePair {
    uint256 assetType;
    address asset;
    uint256 price;
  }

  /**
    This struct tracks information about each item of inventory in the Shop.

    @param token The address of a Fee1155 collection contract containing the
                 item we want to sell.
    @param id The specific ID of the item within the Fee1155 from `token`.
    @param amount The amount of this specific item on sale in the Shop.
  */
  struct ShopItem {
    Fee1155 token;
    uint256 id;
    uint256 amount;
  }

  // The Shop's inventory of items for sale.
  uint256 nextItemId;
  mapping (uint256 => ShopItem) public inventory;
  mapping (uint256 => uint256) public pricePairLengths;
  mapping (uint256 => mapping (uint256 => PricePair)) public prices;

  /**
    Construct a new Shop by providing it a name, FeeOwner, optional Stakers. Any
    attached Staker contracts must also approve this Shop to spend points.

    @param _name The name of the Shop contract.
    @param _feeOwner The address of the FeeOwner due a portion of Shop earnings.
    @param _stakers The addresses of any Stakers to permit spending points from.
  */
  constructor(string memory _name, FeeOwner _feeOwner, Staker[] memory _stakers) public {
    name = _name;
    feeOwner = _feeOwner;
    stakers = _stakers;
    nextItemId = 0;
  }

  /**
    Returns the length of the Staker array.

    @return the length of the Staker array.
  */
  function getStakerCount() external view returns (uint256) {
    return stakers.length;
  }

  /**
    Returns the number of items in the Shop's inventory.

    @return the number of items in the Shop's inventory.
  */
  function getInventoryCount() external view returns (uint256) {
    return nextItemId;
  }

  /**
    Allows the Shop owner to add newly-supported Stakers for point spending.

    @param _stakers The array of new Stakers to add.
  */
  function addStakers(Staker[] memory _stakers) external onlyOwner {
    for (uint256 i = 0; i < _stakers.length; i++) {
      stakers.push(_stakers[i]);
    }
  }

  /**
    Allows the Shop owner to list a new set of NFT items for sale.

    @param _pricePairs The asset address to price pairings to use for selling
                       each item.
    @param _items The array of Fee1155 item contracts to sell from.
    @param _ids The specific Fee1155 item IDs to sell.
    @param _amounts The amount of inventory being listed for each item.
  */
  function listItems(PricePair[] memory _pricePairs, Fee1155[] calldata _items, uint256[][] calldata _ids, uint256[][] calldata _amounts) external nonReentrant onlyOwner {
    require(_items.length > 0,
      "You must list at least one item.");
    require(_items.length == _ids.length,
      "Items length cannot be mismatched with IDs length.");
    require(_items.length == _amounts.length,
      "Items length cannot be mismatched with amounts length.");

    // Iterate through every specified Fee1155 contract to list items.
    for (uint256 i = 0; i < _items.length; i++) {
      Fee1155 item = _items[i];
      uint256[] memory ids = _ids[i];
      uint256[] memory amounts = _amounts[i];
      require(ids.length > 0,
        "You must specify at least one item ID.");
      require(ids.length == amounts.length,
        "Item IDs length cannot be mismatched with amounts length.");

      // For each Fee1155 contract, add the requested item IDs to the Shop.
      for (uint256 j = 0; j < ids.length; j++) {
        uint256 id = ids[j];
        uint256 amount = amounts[j];
        require(amount > 0,
          "You cannot list an item with no starting amount.");
        inventory[nextItemId + j] = ShopItem({
          token: item,
          id: id,
          amount: amount
        });
        for (uint k = 0; k < _pricePairs.length; k++) {
          prices[nextItemId + j][k] = _pricePairs[k];
        }
        pricePairLengths[nextItemId + j] = _pricePairs.length;
      }
      nextItemId = nextItemId.add(ids.length);

      // Batch transfer the listed items to the Shop contract.
      item.safeBatchTransferFrom(msg.sender, address(this), ids, amounts, "");
    }
  }

  /**
    Allows the Shop owner to remove items.

    @param _itemId The id of the specific inventory item of this shop to remove.
    @param _amount The amount of the specified item to remove.
  */
  function removeItem(uint256 _itemId, uint256 _amount) external nonReentrant onlyOwner {
    ShopItem storage item = inventory[_itemId];
    require(item.amount >= _amount && item.amount != 0,
      "There is not enough of your desired item to remove.");
    inventory[_itemId].amount = inventory[_itemId].amount.sub(_amount);
    item.token.safeTransferFrom(address(this), msg.sender, item.id, _amount, "");
  }

  /**
    Allows the Shop owner to adjust the prices of an NFT item set.

    @param _itemId The id of the specific inventory item of this shop to adjust.
    @param _pricePairs The asset-price pairs at which to sell a single instance of the item.
  */
  function changeItemPrice(uint256 _itemId, PricePair[] memory _pricePairs) external onlyOwner {
    for (uint i = 0; i < _pricePairs.length; i++) {
      prices[_itemId][i] = _pricePairs[i];
    }
    pricePairLengths[_itemId] = _pricePairs.length;
  }

  /**
    Allows any user to purchase an item from this Shop provided they have enough
    of the asset being used to purchase with.

    @param _itemId The ID of the specific inventory item of this shop to buy.
    @param _amount The amount of the specified item to purchase.
    @param _assetId The index of the asset from the item's asset-price pairs to
                    attempt this purchase using.
  */
  function purchaseItem(uint256 _itemId, uint256 _amount, uint256 _assetId) external nonReentrant payable {
    ShopItem storage item = inventory[_itemId];
    require(item.amount >= _amount && item.amount != 0,
      "There is not enough of your desired item in stock to purchase.");
    require(_assetId < pricePairLengths[_itemId],
      "Your specified asset ID is not valid.");
    PricePair memory sellingPair = prices[_itemId][_assetId];

    // If the sentinel value for the point asset type is found, sell for points.
    // This involves converting the asset from an address to a Staker index.
    if (sellingPair.assetType == 0) {
      uint256 stakerIndex = uint256(sellingPair.asset);
      stakers[stakerIndex].spendPoints(msg.sender, sellingPair.price.mul(_amount));
      inventory[_itemId].amount = inventory[_itemId].amount.sub(_amount);
      item.token.safeTransferFrom(address(this), msg.sender, item.id, _amount, "");

    // If the sentinel value for the Ether asset type is found, sell for Ether.
    } else if (sellingPair.assetType == 1) {
      uint256 etherPrice = sellingPair.price.mul(_amount);
      require(msg.value >= etherPrice,
        "You did not send enough Ether to complete this purchase.");
      uint256 feePercent = feeOwner.fee();
      uint256 feeValue = msg.value.mul(feePercent).div(100000);
      uint256 itemRoyaltyPercent = item.token.feeOwner().fee();
      uint256 royaltyValue = msg.value.mul(itemRoyaltyPercent).div(100000);
      (bool success, ) = payable(feeOwner.owner()).call{ value: feeValue }("");
      require(success, "Platform fee transfer failed.");
      (success, ) = payable(item.token.feeOwner().owner()).call{ value: royaltyValue }("");
      require(success, "Creator royalty transfer failed.");
      (success, ) = payable(owner()).call{ value: msg.value.sub(feeValue).sub(royaltyValue) }("");
      require(success, "Shop owner transfer failed.");
      inventory[_itemId].amount = inventory[_itemId].amount.sub(_amount);
      item.token.safeTransferFrom(address(this), msg.sender, item.id, _amount, "");

    // Otherwise, attempt to sell for an ERC20 token.
    } else {
      IERC20 sellingAsset = IERC20(sellingPair.asset);
      uint256 tokenPrice = sellingPair.price.mul(_amount);
      require(sellingAsset.balanceOf(msg.sender) >= tokenPrice,
        "You do not have enough token to complete this purchase.");
      uint256 feePercent = feeOwner.fee();
      uint256 feeValue = tokenPrice.mul(feePercent).div(100000);
      uint256 itemRoyaltyPercent = item.token.feeOwner().fee();
      uint256 royaltyValue = tokenPrice.mul(itemRoyaltyPercent).div(100000);
      sellingAsset.safeTransferFrom(msg.sender, feeOwner.owner(), feeValue);
      sellingAsset.safeTransferFrom(msg.sender, item.token.feeOwner().owner(), royaltyValue);
      sellingAsset.safeTransferFrom(msg.sender, owner(), tokenPrice.sub(feeValue).sub(royaltyValue));
      inventory[_itemId].amount = inventory[_itemId].amount.sub(_amount);
      item.token.safeTransferFrom(address(this), msg.sender, item.id, _amount, "");
    }
  }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import "./FeeOwner.sol";
import "./Shop1155.sol";

/**
  @title A basic smart contract for tracking the ownership of SuperFarm Shops.
  @author Tim Clancy

  This is the governing registry of all SuperFarm Shop assets.
*/
contract FarmShopRecords is Ownable, ReentrancyGuard {

  /// A version number for this record contract's interface.
  uint256 public version = 1;

  /// The current platform fee owner to force when creating Shops.
  FeeOwner public platformFeeOwner;

  /// A mapping for an array of all Shop1155s deployed by a particular address.
  mapping (address => address[]) public shopRecords;

  /// An event for tracking the creation of a new Shop.
  event ShopCreated(address indexed shopAddress, address indexed creator);

  /**
    Construct a new registry of SuperFarm records with a specified platform fee owner.

    @param _feeOwner The address of the FeeOwner due a portion of all Shop earnings.
  */
  constructor(FeeOwner _feeOwner) public {
    platformFeeOwner = _feeOwner;
  }

  /**
    Allows the registry owner to update the platform FeeOwner to use upon Shop creation.

    @param _feeOwner The address of the FeeOwner to make the new platform fee owner.
  */
  function changePlatformFeeOwner(FeeOwner _feeOwner) external onlyOwner {
    platformFeeOwner = _feeOwner;
  }

  /**
    Create a Shop1155 on behalf of the owner calling this function. The Shop
    supports immediately registering attached Stakers if provided.

    @param _name The name of the Shop to create.
    @param _stakers An array of Stakers to attach to the new Shop.
  */
  function createShop(string calldata _name, Staker[] calldata _stakers) external nonReentrant returns (Shop1155) {
    Shop1155 newShop = new Shop1155(_name, platformFeeOwner, _stakers);

    // Transfer ownership of the new Shop to the user then store a reference.
    newShop.transferOwnership(msg.sender);
    address shopAddress = address(newShop);
    shopRecords[msg.sender].push(shopAddress);
    emit ShopCreated(shopAddress, msg.sender);
    return newShop;
  }

  /**
    Get the number of entries in the Shop records mapping for the given user.

    @return The number of Shops added for a given address.
  */
  function getShopCount(address _user) external view returns (uint256) {
    return shopRecords[_user].length;
  }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import "./Token.sol";

/**
  @title A basic smart contract for tracking the ownership of SuperFarm Tokens.
  @author Tim Clancy

  This is the governing registry of all SuperFarm Token assets.
*/
contract FarmTokenRecords is Ownable, ReentrancyGuard {

  /// A version number for this record contract's interface.
  uint256 public version = 1;

  /// A mapping for an array of all Tokens deployed by a particular address.
  mapping (address => address[]) public tokenRecords;

  /// An event for tracking the creation of a new Token.
  event TokenCreated(address indexed tokenAddress, address indexed creator);

  /**
    Create a Token on behalf of the owner calling this function. The Token
    supports immediate minting at the time of creation to particular addresses.

    @param _name The name of the Token to create.
    @param _ticker The ticker symbol of the Token to create.
    @param _cap The supply cap of the Token.
    @param _directMintAddresses An array of addresses to mint directly to.
    @param _directMintAmounts An array of Token amounts to mint to keyed addresses.
  */
  function createToken(string calldata _name, string calldata _ticker, uint256 _cap, address[] calldata _directMintAddresses, uint256[] calldata _directMintAmounts) external nonReentrant returns (Token) {
    require(_directMintAddresses.length == _directMintAmounts.length,
      "Direct mint addresses length cannot be mismatched with mint amounts length.");

    // Create the token and optionally mint any specified addresses.
    Token newToken = new Token(_name, _ticker, _cap);
    for (uint256 i = 0; i < _directMintAddresses.length; i++) {
      address directMintAddress = _directMintAddresses[i];
      uint256 directMintAmount = _directMintAmounts[i];
      newToken.mint(directMintAddress, directMintAmount);
    }

    // Transfer ownership of the new Token to the user then store a reference.
    newToken.transferOwnership(msg.sender);
    address tokenAddress = address(newToken);
    tokenRecords[msg.sender].push(tokenAddress);
    emit TokenCreated(tokenAddress, msg.sender);
    return newToken;
  }

  /**
    Allow a user to add an existing Token contract to the registry.

    @param _tokenAddress The address of the Token contract to add for this user.
  */
  function addToken(address _tokenAddress) external {
    tokenRecords[msg.sender].push(_tokenAddress);
  }

  /**
    Get the number of entries in the Token records mapping for the given user.

    @return The number of Tokens added for a given address.
  */
  function getTokenCount(address _user) external view returns (uint256) {
    return tokenRecords[_user].length;
  }
}

// SPDX-License-Identifier: BSD-3-Clause
// Modified from https://github.com/compound-finance/compound-protocol/blob/master/contracts/Timelock.sol
// Copyright 2020 Compound Labs, Inc.
// Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
// 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
// 3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";

contract Timelock {
  using SafeMath for uint;

  event NewAdmin(address indexed newAdmin);
  event NewPendingAdmin(address indexed newPendingAdmin);
  event NewDelay(uint indexed newDelay);
  event CancelTransaction(bytes32 indexed txHash, address indexed target, uint value, string signature,  bytes data, uint eta);
  event ExecuteTransaction(bytes32 indexed txHash, address indexed target, uint value, string signature,  bytes data, uint eta);
  event QueueTransaction(bytes32 indexed txHash, address indexed target, uint value, string signature, bytes data, uint eta);

  uint public constant GRACE_PERIOD = 14 days;
  uint public constant MINIMUM_DELAY = 2 days;
  uint public constant MAXIMUM_DELAY = 30 days;

  address public admin;
  address public pendingAdmin;
  uint public delay;

  mapping (bytes32 => bool) public queuedTransactions;


  constructor(address admin_, uint delay_) public {
    require(delay_ >= MINIMUM_DELAY, "Timelock::constructor: Delay must exceed minimum delay.");
    require(delay_ <= MAXIMUM_DELAY, "Timelock::setDelay: Delay must not exceed maximum delay.");

    admin = admin_;
    delay = delay_;
  }

  receive() external payable { }

  function setDelay(uint delay_) public {
    require(msg.sender == address(this), "Timelock::setDelay: Call must come from Timelock.");
    require(delay_ >= MINIMUM_DELAY, "Timelock::setDelay: Delay must exceed minimum delay.");
    require(delay_ <= MAXIMUM_DELAY, "Timelock::setDelay: Delay must not exceed maximum delay.");
    delay = delay_;

    emit NewDelay(delay);
  }

  function acceptAdmin() public {
    require(msg.sender == pendingAdmin, "Timelock::acceptAdmin: Call must come from pendingAdmin.");
    admin = msg.sender;
    pendingAdmin = address(0);

    emit NewAdmin(admin);
  }

  function setPendingAdmin(address pendingAdmin_) public {
    require(msg.sender == address(this), "Timelock::setPendingAdmin: Call must come from Timelock.");
    pendingAdmin = pendingAdmin_;

    emit NewPendingAdmin(pendingAdmin);
  }

  function queueTransaction(address target, uint value, string memory signature, bytes memory data, uint eta) public returns (bytes32) {
    require(msg.sender == admin, "Timelock::queueTransaction: Call must come from admin.");
    require(eta >= getBlockTimestamp().add(delay), "Timelock::queueTransaction: Estimated execution block must satisfy delay.");

    bytes32 txHash = keccak256(abi.encode(target, value, signature, data, eta));
    queuedTransactions[txHash] = true;

    emit QueueTransaction(txHash, target, value, signature, data, eta);
    return txHash;
  }

  function cancelTransaction(address target, uint value, string memory signature, bytes memory data, uint eta) public {
    require(msg.sender == admin, "Timelock::cancelTransaction: Call must come from admin.");

    bytes32 txHash = keccak256(abi.encode(target, value, signature, data, eta));
    queuedTransactions[txHash] = false;

    emit CancelTransaction(txHash, target, value, signature, data, eta);
  }

  function _getRevertMsg(bytes memory _returnData) internal pure returns (string memory) {
      // If the _res length is less than 68, then the transaction failed silently (without a revert message)
      if (_returnData.length < 68) return 'Transaction reverted silently';

      assembly {
          // Slice the sighash.
          _returnData := add(_returnData, 0x04)
      }
      return abi.decode(_returnData, (string)); // All that remains is the revert string
  }

  function executeTransaction(address target, uint value, string memory signature, bytes memory data, uint eta) public payable returns (bytes memory) {
    require(msg.sender == admin, "Timelock::executeTransaction: Call must come from admin.");

    bytes32 txHash = keccak256(abi.encode(target, value, signature, data, eta));
    require(queuedTransactions[txHash], "Timelock::executeTransaction: Transaction hasn't been queued.");
    require(getBlockTimestamp() >= eta, "Timelock::executeTransaction: Transaction hasn't surpassed time lock.");
    require(getBlockTimestamp() <= eta.add(GRACE_PERIOD), "Timelock::executeTransaction: Transaction is stale.");

    queuedTransactions[txHash] = false;

    bytes memory callData;

    if (bytes(signature).length == 0) {
        callData = data;
    } else {
        callData = abi.encodePacked(bytes4(keccak256(bytes(signature))), data);
    }

    // solium-disable-next-line security/no-call-value
    (bool success, bytes memory returnData) = target.call{ value: value }(callData);
    require(success, "Timelock::executeTransaction: Transaction execution reverted.");
    emit ExecuteTransaction(txHash, target, value, signature, data, eta);

    return returnData;
  }

  function getBlockTimestamp() internal view returns (uint) {
    return block.timestamp;
  }
}

