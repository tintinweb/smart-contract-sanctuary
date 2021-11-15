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
library SafeMathUpgradeable {
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
library EnumerableSetUpgradeable {
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

pragma solidity 0.7.6;

contract PriceManager {
    enum PriceType {FIXED, DECILINING_BY_TIME}

    struct DecliningPrice {
        uint128 highest; //起始价格
        uint128 lowest; //最终价格
        uint32 startTime;
        uint32 duration; //持续时间
        uint32 interval; //降价周期
    }

    //saleId => DecliningPrice
    mapping(uint24 => DecliningPrice) internal decliningPrices;
    mapping(uint24 => uint128) internal fixedPrices;

    function price(PriceType priceType_, uint24 saleId_)
        internal
        view
        returns (uint128)
    {
        if (priceType_ == PriceType.FIXED) {
            return fixedPrices[saleId_];
        }

        if (priceType_ == PriceType.DECILINING_BY_TIME) {
            DecliningPrice storage price_ = decliningPrices[saleId_];
            if (block.timestamp >= price_.startTime + price_.duration) {
                return price_.lowest;
            }
            if (block.timestamp <= price_.startTime) {
                return price_.highest;
            }

            uint256 lastPrice =
                price_.highest -
                    ((block.timestamp - price_.startTime) / price_.interval) *
                    (((price_.highest - price_.lowest) / price_.duration) *
                        price_.interval);
            uint256 price256 = lastPrice < price_.lowest ? price_.lowest : lastPrice;
            require(price256 <= uint128(-1), "price: exceeds uint128 max");

            return uint128(price256);
        }

        revert("unsupported priceType");
    }

    function setFixedPrice(uint24 saleId_, uint128 price_) internal {
        fixedPrices[saleId_] = price_;
    }

    function setDecliningPrice(
        uint24 saleId_,
        uint32 startTime_,
        uint128 highest_,
        uint128 lowest_,
        uint32 duration_,
        uint32 interval_
    ) internal {
        decliningPrices[saleId_].startTime = startTime_;
        decliningPrices[saleId_].highest = highest_;
        decliningPrices[saleId_].lowest = lowest_;
        decliningPrices[saleId_].duration = duration_;
        decliningPrices[saleId_].interval = interval_;
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
library SafeMathUpgradeable128 {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint128 a, uint128 b) internal pure returns (bool, uint128) {
        uint128 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint128 a, uint128 b) internal pure returns (bool, uint128) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint128 a, uint128 b) internal pure returns (bool, uint256) {
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
    function tryDiv(uint128 a, uint128 b) internal pure returns (bool, uint128) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint128 a, uint128 b) internal pure returns (bool, uint128) {
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
    function add(uint128 a, uint128 b) internal pure returns (uint128) {
        uint128 c = a + b;
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
    function sub(uint128 a, uint128 b) internal pure returns (uint128) {
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
    function mul(uint128 a, uint128 b) internal pure returns (uint128) {
        if (a == 0) return 0;
        uint128 c = a * b;
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
    function div(uint128 a, uint128 b) internal pure returns (uint128) {
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
    function mod(uint128 a, uint128 b) internal pure returns (uint128) {
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
    function sub(uint128 a, uint128 b, string memory errorMessage) internal pure returns (uint128) {
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
    function div(uint128 a, uint128 b, string memory errorMessage) internal pure returns (uint128) {
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
    function mod(uint128 a, uint128 b, string memory errorMessage) internal pure returns (uint128) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/EnumerableSetUpgradeable.sol";
import "./interface/external/IVNFT.sol";
import "./interface/external/ISolver.sol";
import "./interface/external/IVestingPool.sol";
import "./interface/external/IICToken.sol";
import "./library/VNFTTransferHelper.sol";
import "./library/ERC20TransferHelper.sol";
import "./interface/ISolvICMarket.sol";
import "./PriceManager.sol";
import "./SafeMathUpgradeable128.sol";

contract SolvICMarket is ISolvICMarket, PriceManager {
    using SafeMathUpgradeable for uint256;
    using SafeMathUpgradeable128 for uint128;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    event NewAdmin(address oldAdmin, address newAdmin);
    event NewPendingAdmin(address oldPendingAdmin, address newPendingAdmin);
    event NewSolver(ISolver oldSolver, ISolver newSolver);

    event AddMarket(
        address indexed icToken,
        uint64 precision,
        uint8 feePayType,
        uint8 feeType,
        uint128 feeAmount,
        uint16 feeRate
    );

    event RemoveMarket(address indexed icToken);

    event SetCurrency(address indexed currency, bool enable);

    event WithdrawFee(address icToken, uint256 reduceAmount);

    struct Sale {
        uint24 saleId;
        uint24 tokenId;
        uint32 startTime;
        address seller;
        PriceManager.PriceType priceType;

        uint128 total; //sale units
        uint128 units; //current units

        uint128 min; //min units
        uint128 max; //max units

        address icToken; //sale asset

        address currency; //pay currency
        bool useAllowList;
        bool isValid;
    }

    struct Market {
        bool isValid;
        uint64 precision;
        FeeType feeType;
        FeePayType feePayType;
        uint128 feeAmount;
        uint16 feeRate;
    }

    enum FeeType {BY_AMOUNT, FIXED}

    enum FeePayType {SELLER_PAY, BUYER_PAY}


    //saleId => struct Sale
    mapping(uint24 => Sale) public sales;

    //icToken => Market
    mapping(address => Market) public markets;

    mapping(address => bool) public currencies;

    //icToken => saleId
    mapping(address => EnumerableSetUpgradeable.UintSet) internal _icTokenSales;
    mapping(address => EnumerableSetUpgradeable.AddressSet)
        internal _allowAddresses;

    ISolver public solver;
    uint24 public nextSaleId;
    address payable public pendingAdmin;
    uint24 public nextTradeId;
    address payable public admin;
    bool public initialized;
    uint16 internal constant PERCENTAGE_BASE = 10000;

    modifier onlyAdmin {
        require(msg.sender == admin, "only admin");
        _;
    }

    constructor() {}

    function initialize(ISolver solver_) public {
        require(initialized == false, "already initialized");
        admin = msg.sender;
        nextSaleId = 1;
        nextTradeId = 1;
        _setSolver(solver_);
        initialized = true;
    }

    function publishFixedPrice(
        address icToken_,
        uint24 tokenId_,
        address currency_,
        uint128 min_,
        uint128 max_,
        uint32 startTime_,
        bool useAllowList_,
        uint128 price_
    ) external virtual override returns (uint24 saleId) {
        address seller = msg.sender;

        uint256 err =
            solver.publishFixedPriceAllowed(
                icToken_,
                tokenId_,
                seller,
                currency_,
                min_,
                max_,
                startTime_,
                useAllowList_,
                price_
            );
        require(err == 0, "Solver: not allowed");

        PriceManager.PriceType priceType = PriceManager.PriceType.FIXED;
        saleId = _publish(
            seller,
            icToken_,
            tokenId_,
            currency_,
            priceType,
            min_,
            max_,
            startTime_,
            useAllowList_
        );
        PriceManager.setFixedPrice(saleId, price_);

        emit FixedPriceSet(
            icToken_,
            saleId,
            tokenId_,
            uint8(priceType),
            price_
        );
    }

    struct PublishDecliningPriceLocalVars {
        address icToken;
        uint24 tokenId;
        address currency;
        uint128 min;
        uint128 max;
        uint32 startTime;
        bool useAllowList;
        uint128 highest;
        uint128 lowest;
        uint32 duration;
        uint32 interval;
        address seller;
    }

    function publishDecliningPrice(
        address icToken_,
        uint24 tokenId_,
        address currency_,
        uint128 min_,
        uint128 max_,
        uint32 startTime_,
        bool useAllowList_,
        uint128 highest_,
        uint128 lowest_,
        uint32 duration_,
        uint32 interval_
    ) external virtual override returns (uint24 saleId) {
        PublishDecliningPriceLocalVars memory vars;
        vars.seller = msg.sender;
        vars.icToken = icToken_;
        vars.tokenId = tokenId_;
        vars.currency = currency_;
        vars.min = min_;
        vars.max = max_;
        vars.startTime = startTime_;
        vars.useAllowList = useAllowList_;
        vars.highest = highest_;
        vars.lowest = lowest_;
        vars.duration = duration_;
        vars.interval = interval_;

        require(vars.interval > 0, "interval cannot be 0");
        require(vars.lowest <= vars.highest, "lowest > highest");
        require(vars.duration > 0, "duration cannot be 0");

        uint256 err =
            solver.publishDecliningPriceAllowed(
                vars.icToken,
                vars.tokenId,
                vars.seller,
                vars.currency,
                vars.min,
                vars.max,
                vars.startTime,
                vars.useAllowList,
                vars.highest,
                vars.lowest,
                vars.duration,
                vars.interval
            );
        require(err == 0, "Solver: not allowed");

        PriceManager.PriceType priceType =
            PriceManager.PriceType.DECILINING_BY_TIME;
        saleId = _publish(
            vars.seller,
            vars.icToken,
            vars.tokenId,
            vars.currency,
            priceType,
            vars.min,
            vars.max,
            vars.startTime,
            vars.useAllowList
        );

        PriceManager.setDecliningPrice(
            saleId,
            vars.startTime,
            vars.highest,
            vars.lowest,
            vars.duration,
            vars.interval
        );

        emit DecliningPriceSet(
            vars.icToken,
            saleId,
            vars.tokenId,
            vars.highest,
            vars.lowest,
            vars.duration,
            vars.interval
        );
    }

    function _publish(
        address seller_,
        address icToken_,
        uint24 tokenId_,
        address currency_,
        PriceManager.PriceType priceType_,
        uint128 min_,
        uint128 max_,
        uint32 startTime_,
        bool useAllowList_
    ) internal returns (uint24 saleId) {
        require(markets[icToken_].isValid, "unsupported icToken");
        require(currencies[currency_], "unsupported currency");
        if (max_ > 0) {
            require(min_ <= max_, "min > max");
        }

        IVNFT vnft = IVNFT(icToken_);

        VNFTTransferHelper.doTransferIn(icToken_, seller_, tokenId_);

        saleId = _gernateNextSaleId();
        uint256 units = vnft.unitsInToken(tokenId_);
        require(units <= uint128(-1), "exceeds uint128 max");
        sales[saleId] = Sale({
            saleId: saleId,
            seller: msg.sender,
            tokenId: tokenId_,
            total: uint128(units),
            units: uint128(units),
            startTime: startTime_,
            min: min_,
            max: max_,
            icToken: icToken_,
            currency: currency_,
            priceType: priceType_,
            useAllowList: useAllowList_,
            isValid: true
        });
        Sale storage sale = sales[saleId];
        _icTokenSales[icToken_].add(saleId);
        emit Publish(
            sale.icToken,
            sale.seller,
            sale.tokenId,
            saleId,
            uint8(sale.priceType),
            sale.units,
            sale.startTime,
            sale.currency,
            sale.min,
            sale.max,
            sale.useAllowList
        );
        solver.publishVerify(
            sale.icToken,
            sale.tokenId,
            sale.seller,
            sale.currency,
            sale.saleId,
            sale.units
        );

        return saleId;
    }

    function buyByAmount(uint24 saleId_, uint256 amount_)
        external
        payable
        virtual
        override
        returns (uint128 units_)
    {
        Sale storage sale = sales[saleId_];
        address buyer = msg.sender;
        uint128 fee = _getFee(sale.icToken, amount_);
        uint128 price = PriceManager.price(sale.priceType, sale.saleId);
        uint256 units256;
        if (markets[sale.icToken].feePayType == FeePayType.BUYER_PAY) {
            units256 = amount_.sub(fee, "fee exceeds amount")
                .mul(uint256(markets[sale.icToken].precision))
                .div(uint256(price));
        } else {
            units256 = amount_.mul(uint256(markets[sale.icToken].precision)).div(uint256(price));
        }
        require(units256 <= uint128(-1), "exceeds uint128 max");
        units_ = uint128(units256);

        uint256 err =
            solver.buyAllowed(
                sale.icToken,
                sale.tokenId,
                saleId_,
                buyer,
                sale.currency,
                amount_,
                units_,
                price
            );
        require(err == 0, "Solver: not allowed");

        _buy(buyer, sale, amount_, units_, price, fee);
        return units_;
    }

    function buyByUnits(uint24 saleId_, uint128 units_)
        external
        payable
        virtual
        override
        returns (uint256 amount_, uint128 fee_)
    {
        Sale storage sale = sales[saleId_];
        address buyer = msg.sender;
        uint128 price = PriceManager.price(sale.priceType, sale.saleId);


        amount_ = uint256(units_).mul(uint256(price)).div(uint256(markets[sale.icToken].precision));

        if (sale.currency == EthAddressLib.ethAddress() 
            && sale.priceType == PriceType.DECILINING_BY_TIME
            && amount_ != msg.value) {
           amount_ = msg.value;
           uint128 fee = _getFee(sale.icToken, amount_);
           uint256 units256;
           if (markets[sale.icToken].feePayType == FeePayType.BUYER_PAY) {
                units256 = amount_.sub(fee, "fee exceeds amount")
                    .mul(uint256(markets[sale.icToken].precision))
                    .div(uint256(price));
            } else {
                units256 = amount_.mul(uint256(markets[sale.icToken].precision)).div(uint256(price));
            }
            require(units256 <= uint128(-1), "exceeds uint128 max");
            units_ = uint128(units256);
        }

        fee_ = _getFee(sale.icToken, amount_);

        uint256 err =
            solver.buyAllowed(
                sale.icToken,
                sale.tokenId,
                saleId_,
                buyer,
                sale.currency,
                amount_,
                units_,
                price
            );
        require(err == 0, "Solver: not allowed");

        _buy(buyer, sale, amount_, units_, price, fee_);
        return (amount_, fee_);
    }

    struct BuyLocalVar {
        uint256 transferInAmount;
        uint256 transferOutAmount;
        FeePayType feePayType;
    }

    function _buy(
        address buyer_,
        Sale storage sale_,
        uint256 amount_,
        uint128 units_,
        uint128 price_,
        uint128 fee_
    ) internal {
        require(sale_.isValid, "invalid saleId");
        require(block.timestamp >= sale_.startTime, "not yet on sale");
        if (sale_.units >= sale_.min) {
            require(units_ >= sale_.min, "min units not met");
        }
        if (sale_.max > 0) {
            require(units_ <= sale_.max, "max units not met");
        }

        if (sale_.useAllowList) {
            require(
                _allowAddresses[sale_.icToken].contains(buyer_),
                "not in allow list"
            );
        }

        sale_.units = sale_.units.sub(units_, "insufficient units for sale");
        BuyLocalVar memory vars;
        vars.feePayType = markets[sale_.icToken].feePayType;

        if (vars.feePayType == FeePayType.BUYER_PAY) {
            vars.transferInAmount = amount_.add(fee_);
            vars.transferOutAmount = amount_;
        } else if (vars.feePayType == FeePayType.SELLER_PAY) {
            vars.transferInAmount = amount_;
            vars.transferOutAmount = amount_.sub(fee_, "fee exceeds amount");
        } else {
            revert("unsupported feePayType");
        }

        ERC20TransferHelper.doTransferIn(
            sale_.currency,
            buyer_,
            vars.transferInAmount
        );
        if (units_ == IVNFT(sale_.icToken).unitsInToken(sale_.tokenId)) {
            VNFTTransferHelper.doTransferOut(
                sale_.icToken,
                buyer_,
                sale_.tokenId
            );
        } else {
            VNFTTransferHelper.doTransferOut(
                sale_.icToken,
                buyer_,
                sale_.tokenId,
                units_
            );
        }

        ERC20TransferHelper.doTransferOut(
            sale_.currency,
            payable(sale_.seller),
            vars.transferOutAmount
        );

        emit Traded(
            buyer_,
            sale_.saleId,
            sale_.icToken,
            sale_.tokenId,
            _gernateNextTradeId(),
            uint32(block.timestamp),
            sale_.currency,
            uint8(sale_.priceType),
            price_,
            units_,
            amount_,
            uint8(vars.feePayType),
            fee_
        );

        if (sale_.units == 0) {
            emit Remove(
                sale_.icToken,
                sale_.seller,
                sale_.saleId,
                sale_.total,
                sale_.total - sale_.units
            );
        }

        solver.buyVerify(
            sale_.icToken,
            sale_.tokenId,
            sale_.saleId,
            buyer_,
            sale_.seller,
            amount_,
            units_,
            price_,
            fee_
        );
    }

    function remove(uint24 saleId_) public virtual override {
        Sale memory sale = sales[saleId_];
        require(sale.isValid, "invalid sale");
        require(sale.seller == msg.sender, "only seller");

        uint256 err =
            solver.removeAllow(
                sale.icToken,
                sale.tokenId,
                sale.saleId,
                sale.seller
            );
        require(err == 0, "Solver: not allowed");

        VNFTTransferHelper.doTransferOut(
            sale.icToken,
            sale.seller,
            sale.tokenId
        );

        delete sales[saleId_];
        emit Remove(
            sale.icToken,
            sale.seller,
            sale.saleId,
            sale.total,
            sale.total - sale.units
        );
    }

    function _getFee(address icToken_, uint256 amount)
        internal
        view
        returns (uint128)
    {
        Market storage market = markets[icToken_];
        if (market.feeType == FeeType.FIXED) {
            return market.feeAmount;
        } else if (market.feeType == FeeType.BY_AMOUNT) {
            uint256 fee = amount.mul(uint256(market.feeRate)).div(uint256(PERCENTAGE_BASE));
            require(fee <= uint128(-1), "Fee: exceeds uint128 max");
            return uint128(fee);
        } else {
            revert("unsupported feeType");
        }
    }

    function getPrice(uint24 saleId_)
        public
        view
        virtual
        override
        returns (uint128)
    {
        return PriceManager.price(sales[saleId_].priceType, saleId_);
    }

    function totalSalesOfICToken(address icToken_)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _icTokenSales[icToken_].length();
    }

    function saleIdOfICTokenByIndex(address icToken_, uint256 index_)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _icTokenSales[icToken_].at(index_);
    }

    function _gernateNextSaleId() internal returns (uint24) {
        return nextSaleId++;
    }

    function _gernateNextTradeId() internal returns (uint24) {
        return nextTradeId++;
    }

    function _addMarket(
        address icToken_,
        uint64 precision_,
        uint8 feePayType_,
        uint8 feeType_,
        uint128 feeAmount_,
        uint16 feeRate_
    ) public onlyAdmin {
        markets[icToken_].isValid = true;
        markets[icToken_].precision = precision_;
        markets[icToken_].feePayType = FeePayType(feePayType_);
        markets[icToken_].feeType = FeeType(feeType_);
        markets[icToken_].feeAmount = feeAmount_;
        markets[icToken_].feeRate = feeRate_;

        emit AddMarket(
            icToken_,
            precision_,
            feePayType_,
            feeType_,
            feeAmount_,
            feeRate_
        );
    }

    function _removeMarket(address icToken_) public onlyAdmin {
        delete markets[icToken_];
        emit RemoveMarket(icToken_);
    }

    function _setCurrency(address currency_, bool enable_) public onlyAdmin {
        currencies[currency_] = enable_;
        emit SetCurrency(currency_, enable_);
    }

    function _withdrawFee(address icToken_, uint256 reduceAmount_)
        public
        onlyAdmin
    {
        require(
            ERC20TransferHelper.getCashPrior(icToken_) >= reduceAmount_,
            "insufficient cash"
        );
        ERC20TransferHelper.doTransferOut(icToken_, admin, reduceAmount_);
        emit WithdrawFee(icToken_, reduceAmount_);
    }

    function _addAllowAddress(address icToken_, address[] calldata addresses_)
        external
        onlyAdmin
    {
        for (uint256 i = 0; i < addresses_.length; i++) {
            _allowAddresses[icToken_].add(addresses_[i]);
        }
    }

    function _removeAllowAddress(
        address icToken_,
        address[] calldata addresses_
    ) external onlyAdmin {
        for (uint256 i = 0; i < addresses_.length; i++) {
            _allowAddresses[icToken_].remove(addresses_[i]);
        }
    }

    function _setSolver(ISolver newSolver_) public virtual onlyAdmin {
        ISolver oldSolver = solver;
        require(newSolver_.isSolver(), "invalid solver");
        solver = newSolver_;

        emit NewSolver(oldSolver, newSolver_);
    }

    function _setPendingAdmin(address payable newPendingAdmin) public {
        require(msg.sender == admin, "only admin");

        // Save current value, if any, for inclusion in log
        address oldPendingAdmin = pendingAdmin;

        // Store pendingAdmin with value newPendingAdmin
        pendingAdmin = newPendingAdmin;

        // Emit NewPendingAdmin(oldPendingAdmin, newPendingAdmin)
        emit NewPendingAdmin(oldPendingAdmin, newPendingAdmin);
    }

    function _acceptAdmin() public {
        require(
            msg.sender == pendingAdmin && msg.sender != address(0),
            "only pending admin"
        );

        // Save current values for inclusion in log
        address oldAdmin = admin;
        address oldPendingAdmin = pendingAdmin;

        // Store admin with value pendingAdmin
        admin = pendingAdmin;

        // Clear the pending value
        pendingAdmin = address(0);

        emit NewAdmin(oldAdmin, admin);
        emit NewPendingAdmin(oldPendingAdmin, pendingAdmin);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface ISolvICMarket {
    event Publish(
        address indexed icToken,
        address indexed seller,
        uint24 indexed tokenId,
        uint24 saleId,
        uint8 priceType,
        uint128 units,
        uint128 startTime,
        address currency,
        uint128 min,
        uint128 max,
        bool useAllowList
    );

    event Remove(
        address indexed icToken,
        address indexed seller,
        uint24 indexed saleId,
        uint128 total,
        uint128 saled
    );

    event FixedPriceSet(
        address indexed icToken,
        uint24 indexed saleId,
        uint24 indexed tokenId,
        uint8 priceType,
        uint128 lastPrice
    );

    event DecliningPriceSet(
        address indexed icToken,
        uint24 indexed saleId,
        uint24 indexed tokenId,
        uint128 highest,
        uint128 lowest,
        uint32 duration,
        uint32 interval
    );

    event Traded(
        address indexed buyer,
        uint24 indexed saleId,
        address indexed icToken,
        uint24 tokenId,
        uint24 tradeId,
        uint32 tradeTime,
        address currency,
        uint8 priceType,
        uint128 price,
        uint128 tradedUnits,
        uint256 tradedAmount,
        uint8 feePayType,
        uint128 fee
    );

    function publishFixedPrice(
        address icToken_,
        uint24 tokenId_,
        address currency_,
        uint128 min_,
        uint128 max_,
        uint32 startTime_,
        bool useAllowList_,
        uint128 price_
    ) external returns (uint24 saleId);

    function publishDecliningPrice(
        address icToken_,
        uint24 tokenId_,
        address currency_,
        uint128 min_,
        uint128 max_,
        uint32 startTime_,
        bool useAllowList_,
        uint128 highest_,
        uint128 lowest_,
        uint32 duration_,
        uint32 interval_
    ) external returns (uint24 saleId);

    function buyByAmount(uint24 saleId_, uint256 amount_)
        external
        payable
        returns (uint128 units_);

    function buyByUnits(uint24 saleId_, uint128 units_)
        external
        payable
        returns (uint256 amount_, uint128 fee_);

    function remove(uint24 saleId_) external;

    function totalSalesOfICToken(address icToken_)
        external
        view
        returns (uint256);

    function saleIdOfICTokenByIndex(address icToken_, uint256 index_)
        external
        view
        returns (uint256);
    function getPrice(uint24 saleId_) external view returns (uint128);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface IICToken {
    event NewAdmin(address oldAdmin, address newAdmin);
    event NewPendingAdmin(address oldPendingAdmin, address newPendingAdmin);

    function mint(uint64 term_, uint256 amount_, uint64[] calldata maturities_, uint32[] calldata percentages_,
        string memory originalInvestor_) external payable returns (uint256, uint256);

    function claim(uint256 tokenId, uint256 amount)  external ;
    function claimAll(uint256 tokenId)  external ;
    function claimableAmount(uint256 tokenId_) external view returns(uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface ISolver {
    event NewAdmin(address oldAdmin, address newAdmin);
    event NewPendingAdmin(address oldPendingAdmin, address newPendingAdmin);

    function isSolver() external returns (bool);

    function depositAllowed(
        address product,
        address depositor,
        uint64 term,
        uint256 depositAmount,
        uint64[] calldata maturities
    ) external returns (uint256);

    function depositVerify(
        address product,
        address depositor,
        uint256 depositAmount,
        uint256 tokenId,
        uint64 term,
        uint64[] calldata maturities
    ) external returns (uint256);

    function withdrawAllowed(
        address product,
        address payee,
        uint256 withdrawAmount,
        uint256 tokenId,
        uint64 term,
        uint64 maturity
    ) external returns (uint256);

    function withdrawVerify(
        address product,
        address payee,
        uint256 withdrawAmount,
        uint256 tokenId,
        uint64 term,
        uint64 maturity
    ) external returns (uint256);

    function transferFromAllowed(
        address product,
        address from,
        address to,
        uint256 tokenId,
        uint256 targetTokenId,
        uint256 amount
    ) external returns (uint256);

    function transferFromVerify(
        address product,
        address from,
        address to,
        uint256 tokenId,
        uint256 targetTokenId,
        uint256 amount
    ) external returns (uint256);

    function mergeAllowed(
        address product,
        address owner,
        uint256 tokenId,
        uint256 targetTokenId,
        uint256 amount
    ) external returns (uint256);

    function mergeVerify(
        address product,
        address owner,
        uint256 tokenId,
        uint256 targetTokenId,
        uint256 amount
    ) external returns (uint256);

    function splitAllowed(
        address product,
        address owner,
        uint256 tokenId,
        uint256 newTokenId,
        uint256 amount
    ) external returns (uint256);

    function splitVerify(
        address product,
        address owner,
        uint256 tokenId,
        uint256 newTokenId,
        uint256 amount
    ) external returns (uint256);

    function needConvertUnsafeTransfer(
        address product,
        address from,
        address to,
        uint256 tokenId,
        uint256 units
    ) external view returns (bool);

    function needRejectUnsafeTransfer(
        address product,
        address from,
        address to,
        uint256 tokenId,
        uint256 units
    ) external view returns (bool);

    function publishFixedPriceAllowed(
        address icToken,
        uint256 tokenId,
        address seller,
        address currency,
        uint256 min,
        uint256 max,
        uint256 startTime,
        bool useAllowList,
        uint256 price
    ) external returns (uint256);

    function publishDecliningPriceAllowed(
        address icToken,
        uint256 tokenId,
        address seller,
        address currency,
        uint256 min,
        uint256 max,
        uint256 startTime,
        bool useAllowList,
        uint256 highest,
        uint256 lowest,
        uint256 duration,
        uint256 interval
    ) external returns (uint256);

    function publishVerify(
        address icToken,
        uint256 tokenId,
        address seller,
        address currency,
        uint256 saleId,
        uint256 units
    ) external;

    function buyAllowed(
        address icToken,
        uint256 tokenId,
        uint256 saleId,
        address buyer,
        address currency,
        uint256 buyAmount,
        uint256 buyUnits,
        uint256 price
    ) external returns (uint256);

    function buyVerify(
        address icToken,
        uint256 tokenId,
        uint256 saleId,
        address buyer,
        address seller,
        uint256 amount,
        uint256 units,
        uint256 price,
        uint256 fee
    ) external;

    function removeAllow(
        address icToken,
        uint256 tokenId,
        uint256 saleId,
        address seller
    ) external returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface IVNFT /* is IERC721 */{
    event TransferUnits(address from, address to, uint256 tokenId, uint256 targetTokenId,
        uint256 transferUnits);
    event Split(address owner, uint256 tokenId, uint256 newTokenId, uint256 splitUnits);
    event Merge(address owner, uint256 tokenId, uint256 targetTokenId, uint256 mergeUnits);
    event ApprovalUnits(address indexed owner, address indexed approved, uint256 indexed tokenId, uint256 approvalUnits);

    function slotOf(uint256 tokenId)  external view returns(uint256 slot);

    function balanceOfSlot(uint256 slot) external view returns (uint256 balance);
    function tokenOfSlotByIndex(uint256 slot, uint256 index) external view returns (uint256 tokenId);
    function unitsInToken(uint256 tokenId) external view returns (uint256 units);

    function approve(address to, uint256 tokenId, uint256 units) external;
    function allowance(uint256 tokenId, address spender) external view returns (uint256 allowed);

    function split(uint256 tokenId, uint256[] calldata units) external returns (uint256[] memory newTokenIds);
    function merge(uint256[] calldata tokenIds, uint256 targetTokenId) external;

    function transferFrom(address from, address to, uint256 tokenId,
        uint256 units) external returns (uint256 newTokenId);

    function safeTransferFrom(address from, address to, uint256 tokenId,
        uint256 units, bytes calldata data) external returns (uint256 newTokenId);

    function transferFrom(address from, address to, uint256 tokenId, uint256 targetTokenId,
        uint256 units) external;

    function safeTransferFrom(address from, address to, uint256 tokenId, uint256 targetTokenId,
        uint256 units, bytes calldata data) external;
}

interface IVNFTReceiver {
    function onVNFTReceived(address operator, address from, uint256 tokenId,
        uint256 units, bytes calldata data) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface IVestingPool {
   event NewAdmin(address oldAdmin, address newAdmin);
    event NewPendingAdmin(address oldPendingAdmin, address newPendingAdmin);
    event MintVesting(
        uint8 indexed claimType,
        address indexed minter,
        uint256 indexed tokenId,
        uint64 term,
        uint64[] maturities,
        uint32[] percentages,
        uint256 vestingAmount,
        uint256 principal
    );
    event ClaimVesting(
        address indexed payee,
        uint256 indexed tokenId,
        uint256 claimAmount
    );
    event TransferVesting(
        address from,
        uint256 tokenId,
        address to,
        uint256 targetTokenId,
        uint256 transferVestingAmount,
        uint256 transferPrincipal
    );
    event SplitVesting(
        address owner,
        uint256 tokenId,
        uint256 newTokenId,
        uint256 splitVestingAmount,
        uint256 splitPricipal
    );
    event MergeVesting(
        address owner,
        uint256 tokenId,
        uint256 targetTokenId,
        uint256 mergeVestingAmount,
        uint256 mergePrincipal
    );

    function isVestingPool() external pure returns (bool);

    function mint(
        uint8 claimType_,
        address minter_,
        uint256 tokenId_,
        uint64 term_,
        uint256 amount_,
        uint64[] calldata maturities_,
        uint32[] calldata percentages_,
        string memory originalInvestor_
    ) external payable returns (uint256 mintUnits);

    function claim(address payable payee, uint256 tokenId,
        uint256 amount) external returns(uint256 claimUnit);

    function claimableAmount(uint256 tokenId_)
        external
        view
        returns (uint256);

    function transferVesting(
        address from_,
        uint256 tokenId_,
        address to_,
        uint256 targetTokenId_,
        uint256 transferUnits_
    ) external;

    function splitVesting(address owner_, uint256 tokenId_, uint256 newTokenId_,
        uint256 splitUnits_) external;

    function mergeVesting(address owner_, uint256 tokenId_,
        uint256 targetTokenId_) external;

    function units2amount(uint256 units_) external view returns (uint256);
    function amount2units(uint256 units_) external view returns (uint256);
    function totalAmount() external view returns(uint256);

    function getVestingSnapshot(uint256 tokenId_)
    external
    view
    returns (
        uint8 claimType_,
        uint64 term_,
        uint256 vestingAmount_,
        uint256 principal_,
        uint64[] memory maturities_,
        uint32[] memory percentages_,
        uint256 availableWithdrawAmount_,
        string memory originalInvestor_,
        bool isValid_
    );

    function underlying() external view returns (address) ;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "./EthAddressLib.sol";

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library ERC20TransferHelper {
    using SafeMathUpgradeable for uint256;

    function doTransferIn(address underlying, address from, uint amount) internal returns (uint) {
        if (underlying == EthAddressLib.ethAddress()) {
            // Sanity checks
            require(tx.origin == from || msg.sender == from, "sender mismatch");
            require(msg.value == amount, "value mismatch");

            return amount;
        } else {
            require(msg.value == 0, "don't support msg.value");
            IERC20 token = IERC20(underlying);
            uint balanceBefore = IERC20(underlying).balanceOf(address(this));
            token.transferFrom(from, address(this), amount);

            bool success;
            assembly {
                switch returndatasize()
                case 0 {                       // This is a non-standard ERC-20
                    success := not(0)          // set success to true
                }
                case 32 {                      // This is a compliant ERC-20
                    returndatacopy(0, 0, 32)
                    success := mload(0)        // Set `success = returndata` of external call
                }
                default {                      // This is an excessively non-compliant ERC-20, revert.
                    revert(0, 0)
                }
            }
            require(success, "TOKEN_TRANSFER_IN_FAILED");

            // Calculate the amount that was *actually* transferred
            uint balanceAfter = IERC20(underlying).balanceOf(address(this));
            require(balanceAfter >= balanceBefore, "TOKEN_TRANSFER_IN_OVERFLOW");
            return balanceAfter - balanceBefore;   // underflow already checked above, just subtract
        }
    }
    function doTransferOut(address underlying, address payable to, uint amount) internal {
        if (underlying == EthAddressLib.ethAddress()) {
            to.transfer(amount);
        } else {
            IERC20 token = IERC20(underlying);
            token.transfer(to, amount);

            bool success;
            assembly {
                switch returndatasize()
                case 0 {                      // This is a non-standard ERC-20
                    success := not(0)          // set success to true
                }
                case 32 {                     // This is a complaint ERC-20
                    returndatacopy(0, 0, 32)
                    success := mload(0)        // Set `success = returndata` of external call
                }
                default {                     // This is an excessively non-compliant ERC-20, revert.
                    revert(0, 0)
                }
            }
            require(success, "TOKEN_TRANSFER_OUT_FAILED");
        }
    }

    function getCashPrior(address underlying_) internal view returns (uint256) {
        if (underlying_ == EthAddressLib.ethAddress()) {
            uint startingBalance = address(this).balance.sub(msg.value);
            return startingBalance;
        } else {
            IERC20 token = IERC20(underlying_);
            return token.balanceOf(address(this));
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

library EthAddressLib {

    /**
    * @dev returns the address used within the protocol to identify ETH
    * @return the address assigned to ETH
     */
    function ethAddress() internal pure returns(address) {
        return 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "../interface/external/IVNFT.sol";

library VNFTTransferHelper {
    function doTransferIn(address underlying, address from, uint256 tokenId) internal {
        IERC721 token = IERC721(underlying);
        token.transferFrom(from, address(this), tokenId);
    }

    function doTransferOut(address underlying, address to, uint256 tokenId) internal {
        IERC721 token = IERC721(underlying);
        token.transferFrom(address(this), to, tokenId);
    }

    function doTransferIn(address underlying, address from, uint256 tokenId, uint256 units) internal {
        IVNFT token = IVNFT(underlying);
        token.safeTransferFrom(from, address(this), tokenId, units, "");
    } 

    function doTransferOut(address underlying, address to, uint256 tokenId, uint256 units) internal {
        IVNFT token = IVNFT(underlying);
        token.safeTransferFrom(address(this), to, tokenId, units, "");
    } 
}

