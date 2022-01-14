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
 * @dev These functions deal with verification of Merkle trees (hash trees),
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(bytes32[] memory proof, bytes32 root, bytes32 leaf) internal pure returns (bool) {
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }

        // Check if the computed hash (root) is equal to the provided root
        return computedHash == root;
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

import "./IERC721Receiver.sol";

  /**
   * @dev Implementation of the {IERC721Receiver} interface.
   *
   * Accepts all token transfers. 
   * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
   */
contract ERC721Holder is IERC721Receiver {

    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
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

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721Holder.sol";

import "./interfaces/ICurrencyManager.sol";
import "./interfaces/INFTStaking.sol";
import "./interfaces/IElpisEquipment.sol";

contract NFTStaking is
    INFTStaking,
    ERC721Holder,
    Context,
    Ownable,
    ReentrancyGuard
{
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.UintSet;

    // Info of each user.
    struct UserInfo {
        uint256 rewardDebt; // Reward debt. See explanation below.
        uint256 rewardToHarvest; //When stake or unstake, add pending reward to rewardToHarvest.
        EnumerableSet.UintSet holderTokens; // Mapping from holder address to their (enumerable) set of owned tokens
    }

    // Info of each pool.
    struct PoolInfo {
        bytes32 merkleRoot; //  The merkle root is built from hero tree.
        uint256 rewardPerNFTAndBlock; // Rewards created per NFT and block
        uint256 lastRewardBlock; // Last block number that rewards distribution occurs.
        uint256 accRewardPerNFT; // Accumulated rewards per NFT.
        uint256 totalStaked; // Total number of heroes staked in pool
    }

    bool public isEmergency = false;
    bool public isBuyable = false;
    uint256 public maxEquipmentSupply;
    uint256 public totalEquipmentSales;
    // The NFT addresss
    IERC721 public immutable EMH;
    //The reward NFT address
    IElpisEquipment public immutable EMQ;
    //The currency manager address
    ICurrencyManager public immutable currencyManager;
    //The symbol of reward currency
    bytes32 public immutable rewardCurrency;
    // The block number when NFT staking starts
    uint256 public immutable startBlock;
    // The block number when rewards harvesting starts
    uint256 public startBlockHarvestable;

    //A list of the current prices of equipments on sale
    uint256[] public equipmentPriceList;
    //Info of each pool
    PoolInfo[] public poolInfo;

    // Info of each user that stakes hero.
    mapping(uint256 => mapping(address => UserInfo)) private _userInfo;
    //a map to check a pool(merkle root) is unique
    mapping(bytes32 => bool) private _poolIndexes;

    modifier poolNotExists(bytes32 merkleRoot) {
        require(!_poolIndexes[merkleRoot], "Pool already exists");
        _;
    }

    modifier buyable() {
        require(isBuyable, "Not buyable");
        _;
    }

    constructor(
        IERC721 _EMH,
        IElpisEquipment _EMQ,
        ICurrencyManager _currencyManager,
        bytes32 _rewardCurrency,
        uint256 _startBlock
    ) {
        EMH = _EMH;
        EMQ = _EMQ;
        currencyManager = _currencyManager;
        rewardCurrency = _rewardCurrency;
        startBlock = _startBlock;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    function priceListEquipmentsLength() external view returns (uint256) {
        return equipmentPriceList.length;
    }

    function updateEmergencyState(bool _isEmergency) external onlyOwner {
        isEmergency = _isEmergency;
    }

    function updateBuyableState(bool _isBuyable) external onlyOwner {
        isBuyable = _isBuyable;
    }

    function updateMaxEquipmentSupply(uint256 _maxEquipmentSupply)
        external
        onlyOwner
    {
        maxEquipmentSupply = _maxEquipmentSupply;
    }

    // Return reward multiplier over the given from `_from` to `_to` block.
    function getMultiplier(uint256 _from, uint256 _to)
        public
        pure
        returns (uint256)
    {
        return _to.sub(_from);
    }

    //View function to see user info
    function getUserInfo(uint256 _pid, address _account)
        external
        view
        returns (
            uint256 amount,
            uint256 rewardToHarvest,
            uint256 rewardDebt
        )
    {
        UserInfo storage user = _userInfo[_pid][_account];
        amount = user.holderTokens.length();
        rewardToHarvest = user.rewardToHarvest;
        rewardDebt = user.rewardDebt;
    }

    /// @dev Returns a token ID owned by `owner` at a given `index` of their token list.
    /// Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
    function tokenOfOwnerByIndex(
        uint256 _pid,
        address _owner,
        uint256 _index
    ) external view returns (uint256) {
        UserInfo storage user = _userInfo[_pid][_owner];
        return user.holderTokens.at(_index);
    }

    function pendingReward(uint256 _pid, address _user)
        external
        view
        override
        returns (uint256)
    {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = _userInfo[_pid][_user];
        uint256 accRewardPerNFT = pool.accRewardPerNFT;
        uint256 totalStaked = pool.totalStaked;

        if (block.number > pool.lastRewardBlock && totalStaked != 0) {
            uint256 multiplier = getMultiplier(
                pool.lastRewardBlock,
                block.number
            );
            uint256 reward = multiplier.mul(pool.rewardPerNFTAndBlock);
            accRewardPerNFT = accRewardPerNFT.add(reward);
        }

        return
            user.holderTokens.length().mul(accRewardPerNFT).sub(
                user.rewardDebt
            );
    }

    function add(bytes32 _merkleRoot, uint256 _rewardPerNFTAndBlock)
        public
        override
        onlyOwner
        poolNotExists(_merkleRoot)
    {
        _poolIndexes[_merkleRoot] = true;
        uint256 lastRewardBlock = block.number > startBlock
            ? block.number
            : startBlock;
        poolInfo.push(
            PoolInfo({
                merkleRoot: _merkleRoot,
                rewardPerNFTAndBlock: _rewardPerNFTAndBlock,
                lastRewardBlock: lastRewardBlock,
                accRewardPerNFT: 0,
                totalStaked: 0
            })
        );
    }

    function updateMerkleRoot(uint256 _pid, bytes32 _merkleRoot)
        public
        override
        onlyOwner
        poolNotExists(_merkleRoot)
    {
        PoolInfo storage pool = poolInfo[_pid];
        bytes32 oldMekleRoot = pool.merkleRoot;
        require(
            oldMekleRoot != _merkleRoot,
            "The new merkle root match old value"
        );

        _poolIndexes[oldMekleRoot] = false;
        _poolIndexes[_merkleRoot] = true;
        pool.merkleRoot = _merkleRoot;

        emit MerkleRootChanged(
            _msgSender(),
            _pid,
            oldMekleRoot,
            _merkleRoot
        );
    }

    function updateRewardPerNFTAndBlock(
        uint256 _pid,
        uint256 _rewardPerNFTAndBlock
    ) public override onlyOwner {
        PoolInfo storage pool = poolInfo[_pid];

        uint256 oldRewardPerNFTAndBlock = pool.rewardPerNFTAndBlock;
        if (oldRewardPerNFTAndBlock != _rewardPerNFTAndBlock) {
            updateStakingPool(_pid);
            pool.rewardPerNFTAndBlock = _rewardPerNFTAndBlock;

            emit RewardPerNFTAndBlockChanged(
                _pid,
                oldRewardPerNFTAndBlock,
                _rewardPerNFTAndBlock
            );
        }
    }

    function addEquipmentPrice(uint256 _price) external override onlyOwner {
        require(_price > 0, "The price is the zero value");
        equipmentPriceList.push(_price);

        emit EquipmentPriceAdded(
            _msgSender(),
            equipmentPriceList.length - 1,
            _price
        );
    }

    function updateEquipmentPrice(uint256 _idx, uint256 _price)
        external
        override
        onlyOwner
    {
        require(_price > 0, "The new price is the zero value");
        emit EquipmentPriceChanged(
            _msgSender(),
            _idx,
            equipmentPriceList[_idx],
            _price
        );
        equipmentPriceList[_idx] = _price;
    }

    /// Update pool reward variables
    function updateStakingPool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 totalStaked = pool.totalStaked;
        if (totalStaked == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 reward = multiplier.mul(pool.rewardPerNFTAndBlock);
        pool.accRewardPerNFT = pool.accRewardPerNFT.add(reward);
        pool.lastRewardBlock = block.number;
    }

    function stake(
        uint256 _pid,
        uint256 _index,
        uint256 _tokenId,
        bytes32[] calldata _merkleProof
    ) external override nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = _userInfo[_pid][_msgSender()];
        require(
            _tokenIsValid(_index, _tokenId, _merkleProof, pool.merkleRoot),
            "Verify tokenId failed"
        );

        updateStakingPool(_pid);
        uint256 currentBalance = user.holderTokens.length();
        if (currentBalance > 0) {
            uint256 pending = currentBalance.mul(pool.accRewardPerNFT).sub(
                user.rewardDebt
            );
            if (pending > 0) {
                user.rewardToHarvest = user.rewardToHarvest.add(pending);
            }
        }

        EMH.safeTransferFrom(_msgSender(), address(this), _tokenId);
        user.holderTokens.add(_tokenId);
        user.rewardDebt = user.holderTokens.length().mul(pool.accRewardPerNFT);
        pool.totalStaked++;

        emit Staked(_msgSender(), _pid, _tokenId);
    }

    function batchStake(
        uint256 _pid,
        uint256[] calldata _indexes,
        uint256[] calldata _tokenIds,
        bytes32[][] calldata _merkleProofs
    ) external override nonReentrant {
        require(
            _indexes.length == _tokenIds.length &&
                _indexes.length == _merkleProofs.length,
            "indexess, tokenIds and merkleProofs length mismatch"
        );

        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = _userInfo[_pid][_msgSender()];

        updateStakingPool(_pid);
        uint256 currentBalance = user.holderTokens.length();
        if (currentBalance > 0) {
            uint256 pending = currentBalance.mul(pool.accRewardPerNFT).sub(
                user.rewardDebt
            );

            if (pending > 0) {
                user.rewardToHarvest = user.rewardToHarvest.add(pending);
            }
        }

        uint256 amount = _tokenIds.length;
        for (uint256 i = 0; i < amount; ++i) {
            require(
                _tokenIsValid(
                    _indexes[i],
                    _tokenIds[i],
                    _merkleProofs[i],
                    pool.merkleRoot
                ),
                "Verify tokenId failed"
            );

            EMH.safeTransferFrom(_msgSender(), address(this), _tokenIds[i]);
            user.holderTokens.add(_tokenIds[i]);
        }
        user.rewardDebt = user.holderTokens.length().mul(pool.accRewardPerNFT);
        pool.totalStaked += amount;

        emit BatchStaked(_msgSender(), _pid, _tokenIds);
    }

    function unstake(uint256 _pid, uint256 _tokenId)
        external
        override
        nonReentrant
    {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = _userInfo[_pid][_msgSender()];
        require(
            user.holderTokens.contains(_tokenId),
            "The tokenId has not been staked by the caller"
        );

        updateStakingPool(_pid);
        uint256 pending = user
            .holderTokens
            .length()
            .mul(pool.accRewardPerNFT)
            .sub(user.rewardDebt);
        if (pending > 0) {
            user.rewardToHarvest = user.rewardToHarvest.add(pending);
        }

        EMH.safeTransferFrom(address(this), _msgSender(), _tokenId);
        user.holderTokens.remove(_tokenId);
        user.rewardDebt = user.holderTokens.length().mul(pool.accRewardPerNFT);
        pool.totalStaked--;

        emit UnStaked(msg.sender, _pid, _tokenId);
    }

    function batchUnstake(uint256 _pid, uint256[] calldata _tokenIds)
        external
        override
        nonReentrant
    {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = _userInfo[_pid][_msgSender()];
        uint256 currentBalance = user.holderTokens.length();
        uint256 amount = _tokenIds.length;
        require(currentBalance >= amount, "Unstake exceeds balance");

        updateStakingPool(_pid);
        if (currentBalance > 0) {
            uint256 pending = currentBalance.mul(pool.accRewardPerNFT).sub(
                user.rewardDebt
            );
            if (pending > 0) {
                user.rewardToHarvest = user.rewardToHarvest.add(pending);
            }
        }

        for (uint256 i = 0; i < amount; ++i) {
            require(
                user.holderTokens.contains(_tokenIds[i]),
                "The tokenId has not been staked by caller"
            );
            EMH.safeTransferFrom(address(this), _msgSender(), _tokenIds[i]);
            user.holderTokens.remove(_tokenIds[i]);
        }
        user.rewardDebt = user.holderTokens.length().mul(pool.accRewardPerNFT);
        pool.totalStaked -= amount;

        emit BatchUnStaked(_msgSender(), _pid, _tokenIds);
    }

    // Be careful of gas spending!
    function stopReward() external onlyOwner {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updateRewardPerNFTAndBlock(pid, 0);
        }
    }

    function emergencyUnstake(uint256 _pid, uint256[] calldata _tokenIds)
        external
        override
        nonReentrant
    {
        require(isEmergency, "Not allow");

        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = _userInfo[_pid][_msgSender()];
        require(
            user.holderTokens.length() >= _tokenIds.length,
            "Unstake exceeds balance"
        );

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            EMH.safeTransferFrom(address(this), _msgSender(), _tokenIds[i]);
            user.holderTokens.remove(_tokenIds[i]);
        }
        if (user.holderTokens.length() == 0) {
            user.rewardDebt = 0;
        }
        pool.totalStaked -= _tokenIds.length;

        emit EmergencyUnstake(_msgSender(), _pid, _tokenIds);
    }

    function harvest() external override nonReentrant {
        uint256 length = poolInfo.length;
        uint256 totalEarned = 0;
        for (uint256 pid = 0; pid < length; ++pid) {
            PoolInfo storage pool = poolInfo[pid];
            UserInfo storage user = _userInfo[pid][_msgSender()];

            //we will only calculate the pending rewards of the pools that the user has stake
            uint256 currentBalance = user.holderTokens.length();
            if (currentBalance > 0) {
                updateStakingPool(pid);
                uint256 pending = currentBalance.mul(pool.accRewardPerNFT).sub(
                    user.rewardDebt
                );

                if (pending > 0) {
                    user.rewardToHarvest = user.rewardToHarvest.add(pending);
                }
                user.rewardDebt = currentBalance.mul(pool.accRewardPerNFT);
            }
            if (user.rewardToHarvest > 0) {
                totalEarned = totalEarned.add(user.rewardToHarvest);
                user.rewardToHarvest = 0;
            }
        }
        currencyManager.increase(rewardCurrency, _msgSender(), totalEarned);

        emit Harvested(_msgSender(), totalEarned);
    }

    function buyEquipments(uint256 _idx, uint256 _amount)
        external
        override
        buyable
    {
        if (maxEquipmentSupply > 0) {
            require(
                totalEquipmentSales.add(_amount) <= maxEquipmentSupply,
                "Exceeds the maximum equipment supply"
            );
        }
        uint256 cost = equipmentPriceList[_idx].mul(_amount);
        currencyManager.decrease(rewardCurrency, _msgSender(), cost);
        totalEquipmentSales = totalEquipmentSales.add(_amount);
        for (uint256 i = 0; i < _amount; ++i) {
            EMQ.mint(_msgSender());
        }

        emit EquipmentBought(_msgSender(), _idx, _amount);
    }

    function _tokenIsValid(
        uint256 _index,
        uint256 _tokenId,
        bytes32[] calldata _merkleProof,
        bytes32 _merkleRoot
    ) internal pure returns (bool) {
        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encodePacked(_index, _tokenId));
        return MerkleProof.verify(_merkleProof, _merkleRoot, node);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface ICurrencyManager {
    function balanceOf(address account, bytes32 currency) external view returns (uint256);

    function increase(
        bytes32 currency,
        address account,
        uint256 amount
    ) external;

    function decrease(
        bytes32 currency,
        address account,
        uint256 amount
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IElpisEquipment is IERC721 {
    function mint(address to) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface INFTStaking {
    /// @notice Emitted when someone stake in the pool.
    event Staked(address indexed staker, uint256 indexed pid, uint256 tokenId);

    /// @notice Emitted when someone batch stake in the pool.
    event BatchStaked(
        address indexed staker,
        uint256 indexed pid,
        uint256[] tokenIds
    );

    /// @notice Emitted when someone unstake from the pool.
    event UnStaked(
        address indexed staker,
        uint256 indexed pid,
        uint256 tokenId
    );

    /// @notice Emitted when someone batch unstake from the pool.
    event BatchUnStaked(
        address indexed staker,
        uint256 indexed pid,
        uint256[] tokenIds
    );

    /// @notice Emitted when someone harvest reward from the pool.
    event Harvested(address indexed staker, uint256 amount);

    /// @notice Emitted when someone emergency unstake from the pool.
    event EmergencyUnstake(
        address indexed staker,
        uint256 indexed pid,
        uint256[] tokenIds
    );

    /// @notice Emitted when the amount of rewards created per NFT and block is changed.
    event RewardPerNFTAndBlockChanged(
        uint256 pid,
        uint256 oldRewardPerNFTAndBlock,
        uint256 newRewardPerNFTAndBlock
    );

    event MerkleRootChanged(
        address account,
        uint256 pid,
        bytes32 oldMerkleRoot,
        bytes32 newMerkleRoot
    );

    /// @notice Emitted when someone buy equipment.
    event EquipmentBought(
        address indexed account,
        uint256 indexed idx,
        uint256 amount
    );

    /// @notice Emitted when someone add the price list equipment.
    event EquipmentPriceAdded(address account, uint256 idx, uint256 price);

    /// @notice Emitted when someone change the price list equipment.
    event EquipmentPriceChanged(
        address account,
        uint256 idx,
        uint256 oldPrice,
        uint256 newPrice
    );

    /// @notice View function to see user's pending rewards per pool.
    /// @param pid The index of pool in the pools.
    /// @param user The address of user.
    /// @return the pending reward of user.
    function pendingReward(uint256 pid, address user)
        external
        view
        returns (uint256);

    /// @notice Add the price equipment to equipment price list.
    /// @param price The price equipment.
    function addEquipmentPrice(uint256 price) external;

    /// @notice Update the price equipment.
    /// @param idx The idx of the price equipment in the equipment price list.
    /// @param newPrice The new price list equipment.
    function updateEquipmentPrice(uint256 idx, uint256 newPrice) external;

    /// @notice Add new staking pool.
    /// @param merkleRoot The merkle root is built from hero tree.
    /// @param rewardPerNFTAndBlock The amount of rewards created per NFT and block.
    function add(bytes32 merkleRoot, uint256 rewardPerNFTAndBlock) external;

    /// @notice Update pool's merkle root.
    /// @param pid The index of pool in the pools.
    /// @param newMerkleRoot The new merkle root is built from hero tree.
    function updateMerkleRoot(uint256 pid, bytes32 newMerkleRoot) external;

    /// @notice Update pool's merkle root.
    /// @param pid The index of pool in the pools.
    /// @param newRewardPerNFTAndBlock The new amount of rewards created per NFT and block.
    function updateRewardPerNFTAndBlock(
        uint256 pid,
        uint256 newRewardPerNFTAndBlock
    ) external;

    /// @notice Stake NFT token to pool for EBA allocation.
    /// @param pid The index of pool in the pools.
    /// @param index The index of tokenId in the merkle tree.
    /// @param tokenId The token id of NFT asset.
    /// @param merkleProof A proof containing: sibling hashes on the branch from the leaf to the root of the merkle tree.
    function stake(
        uint256 pid,
        uint256 index,
        uint256 tokenId,
        bytes32[] calldata merkleProof
    ) external;

    /// @notice batch stake implementation
    function batchStake(
        uint256 pid,
        uint256[] calldata indexs,
        uint256[] calldata tokenIds,
        bytes32[][] calldata merkleProofs
    ) external;

    /// @notice UnStake NFT token from pool.
    /// @param pid The index of pool in the pools.
    /// @param tokenId The token id of NFT asset.
    function unstake(uint256 pid, uint256 tokenId) external;

    /// @notice batch unstake implementation
    function batchUnstake(uint256 pid, uint256[] calldata tokenIds) external;

    /// @notice harvest user rewards.
    function harvest() external;

    /// @notice Buy `amount` equipment.
    /// @param idx The index of equipment price in the equipment price list.
    /// @param amount The amount of equipments to buy.
    function buyEquipments(uint256 idx, uint256 amount) external;

    /// @notice Unstake all without caring about rewards. EMERGENCY ONLY.
    /// @param pid The index of pool in the pools.
    /// @param tokenIds The list of `tokenId` tokens to unstake from the `pid` pool.
    function emergencyUnstake(uint256 pid, uint256[] calldata tokenIds)
        external;
}