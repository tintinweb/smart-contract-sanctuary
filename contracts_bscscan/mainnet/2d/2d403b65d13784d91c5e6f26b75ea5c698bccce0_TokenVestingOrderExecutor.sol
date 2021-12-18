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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
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

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
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
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
        mapping(bytes32 => uint256) _indexes;
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

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

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
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
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

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
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

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
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

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

library NFTExchangeLibrary {
    enum OrderStatus {
        AVAILABLE,
        EXECUTED,
        CLOSED
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

import "../common/PeaMinterContract.sol";
import {MathLibrary} from "../common/MathLibrary.sol";

/**
 * Control executor fee
 */
contract NFTFeeManager is Ownable {
    uint256 _globalFeePercent;
    address _globalReceiver;

    mapping(address => uint256) _executorFeePercent;
    mapping(address => mapping(address => uint256)) _executorTokenFeePercent;

    mapping(address => address) _executorReceiver;

    constructor() {
        //_globalFeePercent = 100; // 1%
        _globalFeePercent = 0;
        _globalReceiver = _msgSender();
    }

    function setGlobalFee(uint256 feePercent) public onlyOwner {
        _globalFeePercent = feePercent;
    }

    function setExecutorFee(address executor, uint256 feePercent)
        public
        onlyOwner
    {
        _executorFeePercent[executor] = feePercent;
    }

    function setExecutorTokenFee(
        address executor,
        address token,
        uint256 feePercent
    ) public onlyOwner {
        _executorTokenFeePercent[executor][token] = feePercent;
    }

    function setGlobalReceiver(address receiver) public onlyOwner {
        _globalReceiver = receiver;
    }

    function setExecutorReceiver(address executor, address receiver)
        public
        onlyOwner
    {
        _executorReceiver[executor] = receiver;
    }

    function getGlobalFee() public view returns (uint256) {
        return _globalFeePercent;
    }

    function getExecutorFee(address executor) public view returns (uint256) {
        return _executorFeePercent[executor];
    }

    function getExecutorTokenFee(address executor, address token)
        public
        view
        returns (uint256)
    {
        return _executorTokenFeePercent[executor][token];
    }

    function getGlobalReceiver() public view returns (address) {
        return _globalReceiver;
    }

    function getExecutorReceiver(address executor)
        public
        view
        returns (address)
    {
        return _executorReceiver[executor];
    }

    function getCurrentFeePercent(address executor, address token)
        public
        view
        returns (uint256)
    {
        if (_executorTokenFeePercent[executor][token] != 0)
            return _executorTokenFeePercent[executor][token];

        if (_executorFeePercent[executor] != 0)
            return _executorFeePercent[executor];

        return _globalFeePercent;
    }

    function getCurrentReceiver(address executor)
        public
        view
        returns (address)
    {
        if (_executorReceiver[executor] != address(0))
            return _executorReceiver[executor];

        return _globalReceiver;
    }

    function calculateFee(
        address executor,
        address token,
        uint256 amount
    ) public view returns (uint256) {
        uint256 feePercent = getCurrentFeePercent(executor, token);
        if(feePercent == 0) return 0;
        return MathLibrary.calculatePercent(amount, feePercent);
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "../common/PeaMinterContract.sol";

/**
* Control & Listing Orders. Manage active orders & owner orders
*/ 
contract NFTOrderManager is PeaMinterContract {
    using Counters for Counters.Counter;
    using EnumerableSet for EnumerableSet.UintSet;

    Counters.Counter private _currentOrderId;
    EnumerableSet.UintSet private _activeOrders;
    mapping(uint256 => address) _orderExecutors;
    mapping(address => EnumerableSet.UintSet) _ownerOrders;

    event CreateOrder(uint256 orderId, address indexed executor, address indexed creator);
    event RemoveActiveOrder(uint256 orderId);    

     /**
     * Create new order id.
     * Emit event CreateOrder
     */      
    function createOrder(address creator) public onlyMinter returns (uint256) {
        address executor = _msgSender();

        _currentOrderId.increment();
        uint256 orderId = _currentOrderId.current();

        _orderExecutors[orderId] = executor;
        _activeOrders.add(orderId);
        _ownerOrders[creator].add(orderId);

        emit CreateOrder(orderId, executor, creator);

        return orderId;
    }

     /**
     * Remove order id out of active order list
     * Emit event RemoveActiveOrder
     */ 
    function removeActiveOrder(uint256 orderId) public onlyMinter {
        _activeOrders.remove(orderId);
        
        emit RemoveActiveOrder(orderId);
    }

     /**
     * Get current Order Id
     */ 
    function currentOrder() public view returns (uint256) {
        return _currentOrderId.current();
    }

     /**
     * Get order's executor by orderId
     */ 
    function getOrderExecutor(uint256 orderId) public view returns (address) {
        return _orderExecutors[orderId];
    }

     /**
     * Get active orders array length
     */ 
    function getActiveOrdersLength() public view returns (uint256) {
        return _activeOrders.length();
    }

     /**
     * Get active order id at given index of active orders array
     */
    function getActiveOrderAtIndex(uint256 index) public view returns (uint256) {
        return _activeOrders.at(index);
    }

     /**
     * Get a given owner orders array length
     */ 
    function geOwnerOrdersLength(address owner) public view returns (uint256) {
        return _ownerOrders[owner].length();
    }

     /**
     * Get order id at given index of a given owner orders array
     */
    function geOwnerOrderAtIndex(address owner, uint256 index) public view returns (uint256) {
        return _ownerOrders[owner].at(index);
    }
}

// SPDX-License-Identifier: GPL-3.0
// version 1.0.0

pragma solidity 0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./NFTOrderManager.sol";
import "./NFTFeeManager.sol";
import "../common/PeaMinterContract.sol";

import {MathLibrary} from "../common/MathLibrary.sol";
import {TransferLibrary} from "../common/TransferLibrary.sol";
import {NFTExchangeLibrary} from "./NFTExchangeLibrary.sol";
import {TokenVesting} from "../vesting/TokenVesting.sol";

struct VestingOrder {
    address tokenContract;
    address currencyContract;
    uint256 pricePerToken;
    uint256 priceBase;
    uint256 initAmount;
    uint256 currentAmount;
    address seller;
    uint256 beginDate;
    uint256 endDate;
    bool isVesting;
    NFTExchangeLibrary.OrderStatus status;
}

struct VestingDetail {
    uint256 vestingPercent;
    uint256 lockDurationByDays;
    uint256 releasePercentEachPeriod;
    uint256 daysInPeriod;
}

/**
 * Execute a token vesting order: Seller ico tokens
 */
contract TokenVestingOrderExecutor is PeaMinterContract {
    using SafeMath for uint256;

    address _orderManager;
    NFTFeeManager _feeManager;
    TokenVesting _tokenVestingManager;

    mapping(uint256 => VestingOrder) private _orders;
    mapping(uint256 => VestingDetail) private _orderVestings;
    mapping(uint256 => address) private _orderManagers;

    event BuyToken(uint256 orderId, address buyer, uint256 amount);

    constructor() {
        addMinter(_msgSender());
    }

    function setOrderManager(address contractAddress) public onlyOwner {
        _orderManager = contractAddress;
    }

    function getOrderManager() public view returns (address) {
        return _orderManager;
    }

    function setFeeManager(address contractAddress) public onlyOwner {
        _feeManager = NFTFeeManager(contractAddress);
    }

    function getFeeManager() public view returns (address) {
        return address(_feeManager);
    }

    function setTokenVestingManager(address contractAddress) public onlyOwner {
        _tokenVestingManager = TokenVesting(contractAddress);
    }

    function getTokenVestingManager() public view returns (address) {
        return address(_tokenVestingManager);
    }    

    /**
     * Open vesting token order
     * 1. Register Order with AVAILABLE status
     * 2. Transfer token to contract address
     */
    function openOrder(
        VestingOrder memory order,
        VestingDetail memory vestingDetail
    ) public onlyMinter {
        require(
            order.pricePerToken > 0,
            "TokenVestingOrderExecutor: Price must greater than zero"
        );
        require(
            order.priceBase > 0,
            "TokenVestingOrderExecutor: Price base must greater than zero"
        );
        require(
            order.initAmount > 0,
            "TokenVestingOrderExecutor: Initial Amount must greater than zero"
        );

        address seller = _msgSender();
        uint256 orderId = NFTOrderManager(_orderManager).createOrder(seller);

        _orderManagers[orderId] = address(_orderManager);

        _orders[orderId] = VestingOrder({
            tokenContract: order.tokenContract,
            currencyContract: order.currencyContract,
            pricePerToken: order.pricePerToken,
            priceBase: order.priceBase,
            initAmount: order.initAmount,
            currentAmount: order.initAmount,
            seller: seller,
            beginDate: order.beginDate,
            endDate: order.endDate,
            isVesting: order.isVesting,
            status: NFTExchangeLibrary.OrderStatus.AVAILABLE
        });

        if (order.isVesting) {
            require(
                vestingDetail.vestingPercent > 0,
                "TokenVestingOrderExecutor: Vesting percent must less than or equal 10000"
            );
            require(
                vestingDetail.releasePercentEachPeriod > 0,
                "TokenVestingOrderExecutor: Release percent vesting must less than or equal 10000"
            );

            _orderVestings[orderId] = VestingDetail({
                vestingPercent: vestingDetail.vestingPercent,
                lockDurationByDays: vestingDetail.lockDurationByDays,
                releasePercentEachPeriod: vestingDetail
                    .releasePercentEachPeriod,
                daysInPeriod: vestingDetail.daysInPeriod
            });
        }

        TransferLibrary.transferTokenFrom(
            order.tokenContract,
            order.initAmount,
            seller,
            address(this)
        );
    }

    /**
     * Execute vesting token order
     * 1. Order status will be changed to EXECUTED if currentAmount = 0
     * 2. Transfer tokens from exchange to buyer
     * 3. Calculate fee
     * 4. Transfer currency tokens to seller
     * 5. Transfer fee to exchange
     * 6. Remove order out of active order if currentAmount = 0
     */
    function executeOrder(uint256 orderId, uint256 amount) public {
        require(
            _orders[orderId].status == NFTExchangeLibrary.OrderStatus.AVAILABLE,
            "TokenVestingOrderExecutor: The order is not available"
        );

        require(
            _orders[orderId].beginDate == 0 || block.timestamp >= _orders[orderId].beginDate,
            "TokenVestingOrderExecutor: The order is not started yet"
        );

        require(
            _orders[orderId].endDate == 0 || block.timestamp <= _orders[orderId].endDate,
            "TokenVestingOrderExecutor: The order is ended"
        );        

        address buyer = _msgSender();

        uint256 buyAmount = (_orders[orderId].currentAmount > amount)
            ? amount
            : _orders[orderId].currentAmount;

        //100% = 100*100
        uint256 immediateRecievePercent = (_orders[orderId].isVesting)
            ? (10000 - _orderVestings[orderId].vestingPercent)
            : 10000;

        uint256 actualReceived = MathLibrary.calculatePercent(
            buyAmount,
            immediateRecievePercent
        );

        if (actualReceived > 0) {
            TransferLibrary.transferToken(
                _orders[orderId].tokenContract,
                actualReceived,
                buyer
            );
        }

        //vesting
        if (buyAmount > actualReceived) {
            uint256 vestingAmount = buyAmount - actualReceived;

            TransferLibrary.transferToken(
                _orders[orderId].tokenContract,
                vestingAmount,
                address(_tokenVestingManager)
            );

            _tokenVestingManager.openContractWithoutTransfer(
                buyer,
                _orders[orderId].tokenContract,
                vestingAmount,
                _orderVestings[orderId].lockDurationByDays,
                _orderVestings[orderId].releasePercentEachPeriod,
                _orderVestings[orderId].daysInPeriod
            );
        }

        uint256 totalPaid = buyAmount.mul(_orders[orderId].pricePerToken);
        totalPaid = totalPaid.div(_orders[orderId].priceBase);

        uint256 fee = _feeManager.calculateFee(
            address(this),
            _orders[orderId].currencyContract,
            totalPaid
        );

        TransferLibrary.transferTokenFrom(
            _orders[orderId].currencyContract,
            (totalPaid - fee),
            buyer,
            _orders[orderId].seller
        );

        if (fee > 0) {
            TransferLibrary.transferTokenFrom(
                _orders[orderId].currencyContract,
                fee,
                buyer,
                _feeManager.getCurrentReceiver(address(this))
            );
        }

        if (_orders[orderId].currentAmount > buyAmount) {
            _orders[orderId].currentAmount -= buyAmount;
        } else {
            _orders[orderId].currentAmount = 0;
            _orders[orderId].status = NFTExchangeLibrary.OrderStatus.EXECUTED;
            NFTOrderManager(_orderManagers[orderId]).removeActiveOrder(orderId);
        }

        emit BuyToken(orderId, buyer, buyAmount);
    }

    /**
     * Close vesting token order
     * 1. Set order status to CLOSED
     * 2. Transfer the rest of token to seller
     * 3. Remove order out of active order list
     */
    function closeOrder(uint256 orderId) public {
        require(
            _orders[orderId].status == NFTExchangeLibrary.OrderStatus.AVAILABLE,
            "TokenVestingOrderExecutor: The order is not available"
        );

        address sender = _msgSender();

        require(
            _orders[orderId].seller == sender || isMinter(sender),
            "TokenVestingOrderExecutor: Only owner has permission to close order"
        );

        TransferLibrary.transferToken(
            _orders[orderId].tokenContract,
            _orders[orderId].currentAmount,
            _orders[orderId].seller
        );

        _orders[orderId].currentAmount = 0;
        _orders[orderId].status = NFTExchangeLibrary.OrderStatus.CLOSED;

        NFTOrderManager(_orderManagers[orderId]).removeActiveOrder(orderId);
    }

    /**
     * get vesting order
     */
    function getOrder(uint256 orderId)
        public
        view
        returns (VestingOrder memory)
    {
        return _orders[orderId];
    }

    /**
     * get vesting order detail
     */
    function getVestingDetail(uint256 orderId)
        public
        view
        returns (VestingDetail memory)
    {
        return _orderVestings[orderId];
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

library MathLibrary {

    function ceil(uint256 a, uint256 m) internal pure returns (uint256) {
        uint256 c = SafeMath.add(a,m);
        uint256 d = SafeMath.sub(c,1);
        return SafeMath.mul(SafeMath.div(d,m),m);
    }   

    /**
     * Percent have to mul with 100
     * Example: 1% = 100, 0.1% = 10, 0.01% = 1
     */    
    function calculatePercent(uint256 _value, uint256 percent) internal pure returns (uint256)  {
        uint256 BASEPERCENT = 100;
        uint256 roundValue = ceil(_value, BASEPERCENT);
        uint256 mulRoundValue = SafeMath.mul(roundValue, BASEPERCENT);
        uint256 result = SafeMath.div(SafeMath.mul(mulRoundValue, percent), 1000000);
        return result;
    }    
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";

contract PeaMinterContract is Ownable {

    mapping(address => bool) private _minters;

    function addMinter(address minter) public onlyOwner {
        _minters[minter] = true;
    }
    
    function removeMinter(address minter) public onlyOwner {
        delete _minters[minter];
    }
    
    function isMinter(address minter) public view returns(bool){
        return _minters[minter];
    }
    
    /**
     * @dev Throws if called by any account other than the setup minter.
     */
    modifier onlyMinter() {
        require(_minters[_msgSender()], "PeaMinterContract: caller is not the minter");
        _;
    }    
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

library TransferLibrary {

    function transferTokenFrom(address currency, uint256 amount, address sender, address receiver) internal returns (bool) {
        require(amount > 0, "TransferLibrary: Amount is zero");
        IERC20 _contract = IERC20(currency);
        return _contract.transferFrom(sender, receiver, amount);
    }
    
    function transferToken(address currency, uint256 amount, address receiver) internal returns (bool) {
        require(amount > 0, "TransferLibrary: Amount is zero");
        IERC20 _contract = IERC20(currency);      
        return _contract.transfer(receiver, amount);
    }

    function transferNFTFrom(address contractAddress, uint256 tokenId, address sender, address receiver) internal {
        IERC721 _contract = IERC721(contractAddress);
        _contract.transferFrom(sender, receiver, tokenId);
    }     
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import {MathLibrary} from "../common/MathLibrary.sol";
import {TransferLibrary} from "../common/TransferLibrary.sol";

import "../common/PeaMinterContract.sol";

struct DistributeContract {
    address receiver;
    address tokenContract;
    uint256 initialAmount;
    uint256 currentAmount;
    uint256 beginLockDate;
    uint256 endLockDate;
    uint256 recentWithdrawDate;
    uint256 releasePercentEachPeriod;
    uint256 daysInPeriod;
}

contract TokenVesting is PeaMinterContract {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    using EnumerableSet for EnumerableSet.UintSet;    

    Counters.Counter private _currentContractId;

    mapping(uint256 => DistributeContract) private _distributeContracts;
    mapping(address => EnumerableSet.UintSet) private _userContracts;

    event OpenContract(uint256 contractId);
    event Withdraw(uint256 contractId, uint256 amount, address receiver);

    function openContract(
        address receiver,
        address tokenContract,
        uint256 initialAmount,
        uint256 lockDurationByDays,
        uint256 releasePercentEachPeriod,
        uint256 daysInPeriod
    ) public {
        address owner = _msgSender();
        TransferLibrary.transferTokenFrom(tokenContract, initialAmount, owner, address(this));

        _openContract(
            receiver,
            tokenContract,
            initialAmount,
            lockDurationByDays,
            releasePercentEachPeriod,
            daysInPeriod
        );
    }

    function openContractWithoutTransfer(
        address receiver,
        address tokenContract,
        uint256 initialAmount,
        uint256 lockDurationByDays,
        uint256 releasePercentEachPeriod,
        uint256 daysInPeriod
    ) public onlyMinter {
        _openContract(
            receiver,
            tokenContract,
            initialAmount,
            lockDurationByDays,
            releasePercentEachPeriod,
            daysInPeriod
        );
    }

    function _openContract(
        address receiver,
        address tokenContract,
        uint256 initialAmount,
        uint256 lockDurationByDays,
        uint256 releasePercentEachPeriod,
        uint256 daysInPeriod 
    ) private {
        _currentContractId.increment();
        uint256 contractId = _currentContractId.current();
        uint256 today = block.timestamp;

        require(
            releasePercentEachPeriod > 0,
            "TokenVesting: Vesting release percent must less than or equal 10000"
        );  

        _distributeContracts[contractId] = DistributeContract({
            receiver: receiver,
            tokenContract: tokenContract,
            initialAmount : initialAmount,
            currentAmount : initialAmount,
            beginLockDate : today,
            recentWithdrawDate : today,
            endLockDate : today + _parseDayToSeconds(lockDurationByDays),
            releasePercentEachPeriod : releasePercentEachPeriod,
            daysInPeriod : daysInPeriod
        });

        _userContracts[receiver].add(contractId);
        
        emit OpenContract(contractId);
    }

    function withdraw(uint256 contractId) public returns(bool) {

        DistributeContract memory distributeContract = _distributeContracts[contractId];
        require(distributeContract.currentAmount > 0, "TokenVesting: nothing to withdraw");

        uint256 today = block.timestamp;

        if(today >= distributeContract.endLockDate){
            uint256 withdrawAllAmount = distributeContract.currentAmount;
            
            TransferLibrary.transferToken(distributeContract.tokenContract, withdrawAllAmount, distributeContract.receiver);
            
            _distributeContracts[contractId].currentAmount = 0;
            _distributeContracts[contractId].recentWithdrawDate = today;
            emit Withdraw(contractId, withdrawAllAmount, distributeContract.receiver);
            return true;
        }
        
        
        uint256 periodInSeconds = _parseDayToSeconds(distributeContract.daysInPeriod);

        require(today >= periodInSeconds + distributeContract.recentWithdrawDate, "TokenVesting: too soon to withdraw");

        uint256 gapTime = today - distributeContract.recentWithdrawDate;
        uint256 numberOfPeriods = gapTime.div(periodInSeconds);

        uint256 releaseAmountEachPeriod = MathLibrary.calculatePercent(distributeContract.initialAmount, distributeContract.releasePercentEachPeriod);
        uint256 intendWithdrawAmount = numberOfPeriods.mul(releaseAmountEachPeriod);
        uint256 withdrawAmount = (distributeContract.currentAmount > intendWithdrawAmount)? intendWithdrawAmount : distributeContract.currentAmount;
        
        TransferLibrary.transferToken(distributeContract.tokenContract, withdrawAmount, distributeContract.receiver);
        
        _distributeContracts[contractId].currentAmount -= withdrawAmount;
        _distributeContracts[contractId].recentWithdrawDate += numberOfPeriods.mul(periodInSeconds);
        emit Withdraw(contractId, withdrawAmount, distributeContract.receiver);        
        return true;
        
    }

    function getContract(uint256 contractId) public view returns(DistributeContract memory){
        return  _distributeContracts[contractId];       
    }

     /**
     * Get a given owner contracts array length
     */ 
    function geOwnerContractsLength(address owner) public view returns (uint256) {
        return _userContracts[owner].length();
    }    

     /**
     * Get contract id at given index of a given owner contracts array
     */
    function geOwnerContractAtIndex(address owner, uint256 index) public view returns (uint256) {
        return _userContracts[owner].at(index);
    }    

    function _parseDayToSeconds(uint256 numOfDays) private pure returns(uint256){
        return numOfDays * 24 * 3600 ;
    }
}