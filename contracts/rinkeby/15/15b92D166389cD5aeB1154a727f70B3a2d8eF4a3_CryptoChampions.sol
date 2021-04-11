/**
 *Submitted for verification at Etherscan.io on 2021-04-10
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.12;

// Global Enums and Structs



struct MinigamePlayer {
    bool isInGame;

    // Will add more as needed
}
struct Hero {
    bool valid;
    string name;
    string affinity;
    int256 affinityPrice;
    uint256 roundMinted;
    uint256 elderId;
    uint256 raceId;
    uint256 classId;
    uint8 appearance;
    uint8 trait1;
    uint8 trait2;
    uint8 skill1;
    uint8 skill2;
    uint8 alignment;
    uint8 background;
    uint8 hometown;
    uint8 weather;
    uint8 level;
    uint8 hp;
    uint8 mana;
    uint8 stamina;
    uint8 strength;
    uint8 dexterity;
    uint8 constitution;
    uint8 intelligence;
    uint8 wisdom;
    uint8 charisma;
}
struct ElderSpirit {
    bool valid;
    uint256 raceId;
    uint256 classId;
    string affinity;
    int256 affinityPrice;
}

// Part: ICryptoChampions

interface ICryptoChampions {
    function createAffinity(string calldata tokenTicker, address feedAddress) external;

    function setElderMintPrice(uint256 price) external;

    function setTokenURI(uint256 id, string calldata uri) external;

    function mintElderSpirit(
        uint256 raceId,
        uint256 classId,
        string calldata affinity
    ) external payable returns (uint256);

    function getElderOwner(uint256 elderId) external view returns (address);

    function mintHero(uint256 elderId, string memory heroName) external payable returns (uint256);

    function getHeroOwner(uint256 heroId) external view returns (address);

    function getElderSpirit(uint256 elderId)
        external
        view
        returns (
            bool,
            uint256,
            uint256,
            string memory,
            int256
        );

    function getHeroGameData(uint256 heroId)
        external
        view
        returns (
            bool, // valid
            string memory, // affinity
            int256, // affinity price
            uint256, // round minted
            uint256 // elder id
        );

    function getHeroVisuals(uint256 heroId)
        external
        view
        returns (
            string memory, // name
            uint256, // race id
            uint256, // class id
            uint8 // appearance
        );

    function getHeroTraitsSkills(uint256 heroId)
        external
        view
        returns (
            uint8, // trait 1
            uint8, // trait 2
            uint8, // skill 1
            uint8 // skill 2
        );

    function getHeroLore(uint256 heroId)
        external
        view
        returns (
            uint8, // alignment
            uint8, // background
            uint8, // hometown
            uint8 // weather
        );

    function getHeroVitals(uint256 heroId)
        external
        view
        returns (
            uint8, // level
            uint8, // hp
            uint8, // mana
            uint8 // stamina
        );

    function getHeroStats(uint256 heroId)
        external
        view
        returns (
            uint8, // strength
            uint8, // dexterity
            uint8, // constitution
            uint8, // intelligence
            uint8, // wisdom
            uint8 // charisma
        );

    function getHeroMintPrice(uint256 round, uint256 elderId) external view returns (uint256);

    function getElderSpawnsAmount(uint256 round, uint256 elderId) external view returns (uint256);

    function getAffinityFeedAddress(string calldata affinity) external view returns (address);

    function declareRoundWinner(string calldata winningAffinity) external;

    function claimReward(uint256 heroId) external;

    function getNumEldersInGame() external view returns (uint256);

    function transferInGameTokens(address to, uint256 amount) external;

    function delegatedTransferInGameTokens(
        address from,
        address to,
        uint256 amount
    ) external;

    function refreshPhase() external;
}

// Part: IMinigameFactoryRegistry

interface IMinigameFactoryRegistry {
    function registerMinigame(string calldata minigameKey, address minigameFactoryAddress) external;

    function getFactory(string calldata minigameKey) external returns (address);
}

// Part: OpenZeppelin/[email protected]/Address

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

// Part: OpenZeppelin/[email protected]/Context

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

// Part: OpenZeppelin/[email protected]/EnumerableSet

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

// Part: OpenZeppelin/[email protected]/IERC165

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

// Part: OpenZeppelin/[email protected]/SafeMath

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

// Part: OpenZeppelin/[email protected]/SignedSafeMath

/**
 * @title SignedSafeMath
 * @dev Signed math operations with safety checks that revert on error.
 */
library SignedSafeMath {
    int256 constant private _INT256_MIN = -2**255;

    /**
     * @dev Returns the multiplication of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        require(!(a == -1 && b == _INT256_MIN), "SignedSafeMath: multiplication overflow");

        int256 c = a * b;
        require(c / a == b, "SignedSafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two signed integers. Reverts on
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
    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0, "SignedSafeMath: division by zero");
        require(!(b == -1 && a == _INT256_MIN), "SignedSafeMath: division overflow");

        int256 c = a / b;

        return c;
    }

    /**
     * @dev Returns the subtraction of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a), "SignedSafeMath: subtraction overflow");

        return c;
    }

    /**
     * @dev Returns the addition of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a), "SignedSafeMath: addition overflow");

        return c;
    }
}

// Part: smartcontractkit/[email protected]/AggregatorV3Interface

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

// Part: smartcontractkit/[email protected]/LinkTokenInterface

interface LinkTokenInterface {
  function allowance(address owner, address spender) external view returns (uint256 remaining);
  function approve(address spender, uint256 value) external returns (bool success);
  function balanceOf(address owner) external view returns (uint256 balance);
  function decimals() external view returns (uint8 decimalPlaces);
  function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);
  function increaseApproval(address spender, uint256 subtractedValue) external;
  function name() external view returns (string memory tokenName);
  function symbol() external view returns (string memory tokenSymbol);
  function totalSupply() external view returns (uint256 totalTokensIssued);
  function transfer(address to, uint256 value) external returns (bool success);
  function transferAndCall(address to, uint256 value, bytes calldata data) external returns (bool success);
  function transferFrom(address from, address to, uint256 value) external returns (bool success);
}

// Part: smartcontractkit/[email protected]/VRFRequestIDBase

contract VRFRequestIDBase {

  /**
   * @notice returns the seed which is actually input to the VRF coordinator
   *
   * @dev To prevent repetition of VRF output due to repetition of the
   * @dev user-supplied seed, that seed is combined in a hash with the
   * @dev user-specific nonce, and the address of the consuming contract. The
   * @dev risk of repetition is mostly mitigated by inclusion of a blockhash in
   * @dev the final seed, but the nonce does protect against repetition in
   * @dev requests which are included in a single block.
   *
   * @param _userSeed VRF seed input provided by user
   * @param _requester Address of the requesting contract
   * @param _nonce User-specific nonce at the time of the request
   */
  function makeVRFInputSeed(bytes32 _keyHash, uint256 _userSeed,
    address _requester, uint256 _nonce)
    internal pure returns (uint256)
  {
    return  uint256(keccak256(abi.encode(_keyHash, _userSeed, _requester, _nonce)));
  }

  /**
   * @notice Returns the id for this request
   * @param _keyHash The serviceAgreement ID to be used for this request
   * @param _vRFInputSeed The seed to be passed directly to the VRF
   * @return The id for this request
   *
   * @dev Note that _vRFInputSeed is not the seed passed by the consuming
   * @dev contract, but the one generated by makeVRFInputSeed
   */
  function makeRequestId(
    bytes32 _keyHash, uint256 _vRFInputSeed) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(_keyHash, _vRFInputSeed));
  }
}

// Part: Minigame

/// @title Minigame
/// @author cds95
/// @notice This is contract for a minigame
abstract contract Minigame {
    // Possible game phases
    enum MinigamePhase { OPEN, CLOSED }

    // The current game's phase
    MinigamePhase public currentPhase;

    // Map of hero ids to player struct
    mapping(uint256 => MinigamePlayer) public players;

    // List of hero IDs in the game
    uint256[] public heroIds;

    // Number of players currently in the game
    uint256 public numPlayers;

    // Name of the game
    string public gameName;

    // Reference to crypto champions contract
    ICryptoChampions public cryptoChampions;

    // Event to signal that a game has started
    event GameStarted();

    // Event to signal that a game has ended
    event GameEnded();

    // Initializes a new minigame
    /// @param nameOfGame The minigame's name
    /// @param cryptoChampionsAddress The address of the cryptoChampions contract
    constructor(string memory nameOfGame, address cryptoChampionsAddress) public {
        gameName = nameOfGame;
        currentPhase = MinigamePhase.OPEN;
        cryptoChampions = ICryptoChampions(cryptoChampionsAddress);
    }

    /// @notice Joins a game
    /// @param heroId The id of the joining player's hero
    function joinGame(uint256 heroId) public virtual {
        require(currentPhase == MinigamePhase.OPEN);
        MinigamePlayer memory player;
        player.isInGame = true;
        players[heroId] = player;
        heroIds.push(heroId);
        numPlayers++;
    }

    /// @notice Leaves a game
    /// @param heroId The id of the leaving player's hero
    function leaveGame(uint256 heroId) public virtual {
        require(currentPhase == MinigamePhase.OPEN);
        MinigamePlayer storage player = players[heroId];
        player.isInGame = false;
        numPlayers--;
    }

    /// @notice Starts a new game and closes it when it's finished
    function startGame() external {
        require(currentPhase == MinigamePhase.OPEN);
        emit GameStarted();
        play();
        setPhase(MinigamePhase.CLOSED);
        emit GameEnded();
    }

    /// @notice Sets the current game's phase
    /// @param phase The phase the game should be set to
    function setPhase(MinigamePhase phase) internal {
        currentPhase = phase;
    }

    /// @notice Gets the number of players in the game
    function getNumPlayers() public view returns (uint256) {
        return numPlayers;
    }

    /// @notice Handler function to execute game logic.  This should be implemented by the concrete class.
    function play() internal virtual;
}

// Part: OpenZeppelin/[email protected]/AccessControl

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context {
    using EnumerableSet for EnumerableSet.AddressSet;
    using Address for address;

    struct RoleData {
        EnumerableSet.AddressSet members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role].members.contains(account);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view returns (uint256) {
        return _roles[role].members.length();
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view returns (address) {
        return _roles[role].members.at(index);
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to grant");

        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to revoke");

        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, _roles[role].adminRole, adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (_roles[role].members.add(account)) {
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (_roles[role].members.remove(account)) {
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// Part: OpenZeppelin/[email protected]/ERC165

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

// Part: OpenZeppelin/[email protected]/IERC1155

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

// Part: OpenZeppelin/[email protected]/IERC1155Receiver

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

// Part: VRFConsumerBase

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constuctor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator, _link) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash), and have told you the minimum LINK
 * @dev price for VRF service. Make sure your contract has sufficient LINK, and
 * @dev call requestRandomness(keyHash, fee, seed), where seed is the input you
 * @dev want to generate randomness from.
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomness method.
 *
 * @dev The randomness argument to fulfillRandomness is the actual random value
 * @dev generated from your seed.
 *
 * @dev The requestId argument is generated from the keyHash and the seed by
 * @dev makeRequestId(keyHash, seed). If your contract could have concurrent
 * @dev requests open, you can use the requestId to track which seed is
 * @dev associated with which randomness. See VRFRequestIDBase.sol for more
 * @dev details. (See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.)
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ. (Which is critical to making unpredictable randomness! See the
 * @dev next section.)
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the ultimate input to the VRF is mixed with the block hash of the
 * @dev block in which the request is made, user-provided seeds have no impact
 * @dev on its economic security properties. They are only included for API
 * @dev compatability with previous versions of this contract.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request.
 */
abstract contract VRFConsumerBase is VRFRequestIDBase {
    using SafeMath for uint256;

    /**
     * @notice fulfillRandomness handles the VRF response. Your contract must
     * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
     * @notice principles to keep in mind when implementing your fulfillRandomness
     * @notice method.
     *
     * @dev VRFConsumerBase expects its subcontracts to have a method with this
     * @dev signature, and will call it once it has verified the proof
     * @dev associated with the randomness. (It is triggered via a call to
     * @dev rawFulfillRandomness, below.)
     *
     * @param requestId The Id initially returned by requestRandomness
     * @param randomness the VRF output
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal virtual;

    /**
     * @notice requestRandomness initiates a request for VRF output given _seed
     *
     * @dev The fulfillRandomness method receives the output, once it's provided
     * @dev by the Oracle, and verified by the vrfCoordinator.
     *
     * @dev The _keyHash must already be registered with the VRFCoordinator, and
     * @dev the _fee must exceed the fee specified during registration of the
     * @dev _keyHash.
     *
     * @dev The _seed parameter is vestigial, and is kept only for API
     * @dev compatibility with older versions. It can't *hurt* to mix in some of
     * @dev your own randomness, here, but it's not necessary because the VRF
     * @dev oracle will mix the hash of the block containing your request into the
     * @dev VRF seed it ultimately uses.
     *
     * @param _keyHash ID of public key against which randomness is generated
     * @param _fee The amount of LINK to send with the request
     * @param _seed seed mixed into the input of the VRF.
     *
     * @return requestId unique ID for this request
     *
     * @dev The returned requestId can be used to distinguish responses to
     * @dev concurrent requests. It is passed as the first argument to
     * @dev fulfillRandomness.
     */
    function requestRandomness(
        bytes32 _keyHash,
        uint256 _fee,
        uint256 _seed
    ) internal returns (bytes32 requestId) {
        LINK.transferAndCall(vrfCoordinator, _fee, abi.encode(_keyHash, _seed));
        // This is the seed passed to VRFCoordinator. The oracle will mix this with
        // the hash of the block containing this request to obtain the seed/input
        // which is finally passed to the VRF cryptographic machinery.
        uint256 vRFSeed = makeVRFInputSeed(_keyHash, _seed, address(this), nonces[_keyHash]);
        // nonces[_keyHash] must stay in sync with
        // VRFCoordinator.nonces[_keyHash][this], which was incremented by the above
        // successful LINK.transferAndCall (in VRFCoordinator.randomnessRequest).
        // This provides protection against the user repeating their input seed,
        // which would result in a predictable/duplicate output, if multiple such
        // requests appeared in the same block.
        nonces[_keyHash] = nonces[_keyHash].add(1);
        return makeRequestId(_keyHash, vRFSeed);
    }

    LinkTokenInterface internal LINK;
    address private vrfCoordinator;

    // Nonces for each VRF key from which randomness has been requested.
    //
    // Must stay in sync with VRFCoordinator[_keyHash][this]
    /* keyHash */
    /* nonce */
    mapping(bytes32 => uint256) private nonces;

    /**
     * @param _vrfCoordinator address of VRFCoordinator contract
     * @param _link address of LINK token contract
     *
     * @dev https://docs.chain.link/docs/link-token-contracts
     */
    constructor(address _vrfCoordinator, address _link) public {
        vrfCoordinator = _vrfCoordinator;
        LINK = LinkTokenInterface(_link);
    }

    // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
    // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
    // the origin of the call
    function rawFulfillRandomness(bytes32 requestId, uint256 randomness) external {
        require(msg.sender == vrfCoordinator, "Only VRFCoordinator can fulfill");
        fulfillRandomness(requestId, randomness);
    }
}

// Part: OpenZeppelin/[email protected]/IERC1155MetadataURI

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

// Part: PriceWars

/// @title PriceWars
/// @author cds95
/// @notice This is the contract for the price wars minigame
contract PriceWars is Minigame {
    using SignedSafeMath for int256;

    // Initializes a new price war minigame
    constructor(address cryptoChampionsContractAddress) public Minigame("price-wars", cryptoChampionsContractAddress) {}

    /// @notice Executes one round of a price war minigame by determining the affinity with the token that had the greatest gain.
    function play() internal override {
        string memory winningAffinity;
        int256 greatestPercentageChange;
        for (uint256 elderId = 1; elderId <= cryptoChampions.getNumEldersInGame(); elderId++) {
            string memory affinity;
            int256 startAffinityPrice;
            (, , , affinity, startAffinityPrice) = cryptoChampions.getElderSpirit(elderId);
            int256 percentageChange = determinePercentageChange(startAffinityPrice, affinity);
            if (percentageChange > greatestPercentageChange || greatestPercentageChange == 0) {
                greatestPercentageChange = percentageChange;
                winningAffinity = affinity;
            }
        }
        cryptoChampions.declareRoundWinner(winningAffinity);
    }

    /// @notice Determines the percentage change of a token.
    /// @return The token's percentage change.
    function determinePercentageChange(int256 startAffinityPrice, string memory affinity)
        internal
        view
        returns (int256)
    {
        address feedAddress = cryptoChampions.getAffinityFeedAddress(affinity);
        int256 currentAffinityPrice;
        (, currentAffinityPrice, , , ) = AggregatorV3Interface(feedAddress).latestRoundData();
        int256 absoluteChange = currentAffinityPrice.sub(startAffinityPrice);
        return absoluteChange.mul(100).div(startAffinityPrice);
    }
}

// Part: OpenZeppelin/[email protected]/ERC1155

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

// Part: PriceWarsFactory

/// @title PriceWarsFactory
/// @author cds95
/// @notice This is the price wars factory contract to manage creating new price war contracts
contract PriceWarsFactory {
    // List of price war contracts that have been deployed
    PriceWars[] public games;

    /// @notice Triggered when a new price war contract is created
    event PriceWarCreated();

    /// @notice Creates a new price war game contract
    /// @param cryptoChampionsContractAddress The address of the crypto champions contract
    function createPriceWar(address cryptoChampionsContractAddress) external returns (PriceWars) {
        // TODO:  Look into clone factories to save gas
        PriceWars game = new PriceWars(cryptoChampionsContractAddress);
        games.push(game);
        emit PriceWarCreated();
        return game;
    }
}

// File: CryptoChampions.sol

/// @title Crypto Champions Interface
/// @author Oozyx
/// @notice This is the crypto champions class
contract CryptoChampions is ICryptoChampions, AccessControl, ERC1155, VRFConsumerBase {
    using SafeMath for uint256;
    using SafeMath for uint8;

    // Possible phases the contract can be in.  Phase one is when users can mint elder spirits and two is when they can mint heros.
    enum Phase { SETUP, ACTION }

    // The current phase the contract is in.
    Phase public currentPhase;

    // Number of tokens minted whenever a user mints a hero
    uint256 internal constant NUM_TOKENS_MINTED = 500 * 10**18;

    // The duration of each phase in days
    uint256 internal _setupPhaseDuration;
    uint256 internal _actionPhaseDuration;

    // The current phase start time
    uint256 public currentPhaseStartTime;

    // The owner role is used to globally govern the contract
    bytes32 internal constant ROLE_OWNER = keccak256("ROLE_OWNER");

    // The admin role is used for administrator duties and reports to the owner
    bytes32 internal constant ROLE_ADMIN = keccak256("ROLE_ADMIN");

    // The role to declare round winners
    bytes32 internal constant ROLE_GAME_ADMIN = keccak256("ROLE_GAME_ADMIN");

    // Reserved id for the in game currency
    uint256 internal constant IN_GAME_CURRENCY_ID = 0;

    // Constants used to determine fee proportions in percentage
    // Usage: fee.mul(proportion).div(100)
    uint8 internal constant HERO_MINT_ROYALTY_PERCENT = 25;
    uint8 internal constant HERO_MINT_DEV_PERCENT = 25;

    // The amount of ETH contained in the rewards pool
    uint256 public rewardsPoolAmount = 0;

    // The amount of ETH contained in the dev fund
    uint256 public devFund = 0;

    // The rewards share for every hero with the winning affinity calculated at the end of every round
    uint256 internal _heroRewardsShare = 0;

    // The identifier for the price wars game
    string internal constant PRICE_WARS_ID = "PRICE_WARS";

    // The max amount of elders that can be minted
    uint256 public constant MAX_NUMBER_OF_ELDERS = 5;

    // The amount of elders minted
    // This amount cannot be greater than MAX_NUMBER_OF_ELDERS
    uint256 public eldersInGame = 0;

    // The mapping of elder id to elder owner, ids can only be in the range of [1, MAX_NUMBER OF ELDERS]
    mapping(uint256 => address) internal _elderOwners;

    // The mapping of elder id to the elder spirit
    mapping(uint256 => ElderSpirit) internal _elderSpirits;

    // The amount of heros minted
    uint256 public heroesMinted = 0;

    // The mapping of hero id to owner, ids can only be in the range of
    // [1 + MAX_NUMBER_OF_ELDERS, ]
    mapping(uint256 => address) internal _heroOwners;

    // The mapping of hero id to the hero
    mapping(uint256 => Hero) internal _heroes;

    // The mapping of the round played to the elder spawns mapping
    mapping(uint256 => mapping(uint256 => uint256)) internal _roundElderSpawns;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    // The mint price for elders and heroes
    uint256 public elderMintPrice;

    // The current round index
    uint256 public currentRound;

    // The mapping of affinities (token ticker) to price feed address
    mapping(string => address) internal _affinities;

    // List of available affinities
    string[] public affinities;

    // The key hash used for VRF
    bytes32 internal _keyHash;

    // The fee in LINK for VRF
    uint256 internal _fee;

    // Mapping of request id to hero id
    mapping(bytes32 => uint256) internal _heroRandomRequest;

    // Mapping of request id to random result
    mapping(bytes32 => uint256) internal _randomResultsVRF;

    // The list of affinities that won in a round
    mapping(uint256 => string) public winningAffinitiesByRound;

    // Mapping of hero id to a mapping of round to a bool of the rewards claim
    mapping(uint256 => mapping(uint256 => bool)) internal _heroRewardsClaimed;

    // The registry of minigame factories
    IMinigameFactoryRegistry internal _minigameFactoryRegistry;

    /// @notice Triggered when an elder spirit gets minted
    /// @param elderId The elder id belonging to the minted elder
    /// @param owner The address of the owner
    event ElderSpiritMinted(uint256 elderId, address owner);

    /// @notice Triggered when a hero gets minted
    /// @param heroId The hero id belonging to the hero that was minted
    /// @param owner The address of the owner
    event HeroMinted(uint256 heroId, address owner);

    /// @notice Triggered when the elder spirits have been burned
    event ElderSpiritsBurned();

    // Initializes a new CryptoChampions contract
    // TODO: need to provide the proper uri
    constructor(
        bytes32 keyhash,
        address vrfCoordinator,
        address linkToken,
        address minigameFactoryRegistry
    ) public ERC1155("uri") VRFConsumerBase(vrfCoordinator, linkToken) {
        // Set up administrative roles
        _setRoleAdmin(ROLE_OWNER, ROLE_OWNER);
        _setRoleAdmin(ROLE_ADMIN, ROLE_OWNER);
        _setRoleAdmin(ROLE_GAME_ADMIN, ROLE_OWNER);

        // Set up the deployer as the owner and give admin rights
        _setupRole(ROLE_OWNER, msg.sender);
        grantRole(ROLE_ADMIN, msg.sender);

        // Set initial elder mint price
        elderMintPrice = 0.271 ether;

        // Set the initial round to 0
        currentRound = 0;

        // Set initial phase to phase one and phase start time
        currentPhase = Phase.SETUP;
        currentPhaseStartTime = now;

        // Set VRF fields
        _keyHash = keyhash;
        _fee = 0.1 * 10**18; // 0.1 LINK

        // Set phase durations
        _setupPhaseDuration = 2 days;
        _actionPhaseDuration = 2 days;

        _minigameFactoryRegistry = IMinigameFactoryRegistry(minigameFactoryRegistry);
    }

    modifier isValidElderSpiritId(uint256 elderId) {
        require(elderId > IN_GAME_CURRENCY_ID && elderId <= MAX_NUMBER_OF_ELDERS); // dev: Given id is not valid.
        _;
    }

    modifier isValidHero(uint256 heroId) {
        require(heroId > MAX_NUMBER_OF_ELDERS); // dev: Given id is not valid.
        require(_heroes[heroId].valid); // dev: Hero is not valid.
        _;
    }

    // Restrict to only price war addresses
    modifier onlyGameAdmin {
        _hasRole(ROLE_GAME_ADMIN);
        _;
    }

    // Restrict to only admins
    modifier onlyAdmin {
        _hasRole(ROLE_ADMIN);
        _;
    }

    // Restrict to the specified phase
    modifier atPhase(Phase phase) {
        require(currentPhase == phase); // dev: Current phase prohibits action.
        _;
    }

    /// @notice Sets the token uri for the given id
    /// @dev Only the admin can set URIs
    /// @param id The token id (either hero or elder)
    /// @param uri The uri of the token id
    function setTokenURI(uint256 id, string calldata uri) external override onlyAdmin {
        _tokenURIs[id] = uri;
    }

    /// @notice Override of the uri getter function
    /// @param tokenId The token id for which the URI is mapped to
    /// @return The token id uri
    function uri(uint256 tokenId) external view override returns (string memory) {
        return _tokenURIs[tokenId];
    }

    /// @notice Sets the duration of the setup phase
    /// @param numDays Number of days for the setup phase duration
    function setSetupPhaseDuration(uint256 numDays) external onlyAdmin {
        _setupPhaseDuration = numDays * 1 days;
    }

    /// @notice Sets the duration of the action phase
    /// @param numDays Number of days for the action phase
    function setActionPhaseDuration(uint256 numDays) external onlyAdmin {
        _actionPhaseDuration = numDays * 1 days;
    }

    /// @notice Transitions to the next phase
    function _transitionNextPhase() internal {
        if (currentPhase == Phase.SETUP) {
            // If rewards have gone unclaimed, send to address
            // todo
            rewardsPoolAmount = 0;

            // Reset the hero rewards share
            _heroRewardsShare = 0;

            // todo mint all elders that have yet to be minted

            // Increment the round
            currentRound = currentRound.add(1);

            // Set the next phase
            currentPhase = Phase.ACTION;
        } else if (currentPhase == Phase.ACTION) {
            // Start the price game that will determine the winning affinity
            _startNewPriceGame();

            // Calculate hero rewards.
            // Start by finding which elder had the winning affinity
            uint256 i = 1;
            for (; i <= eldersInGame; ++i) {
                if (
                    keccak256(bytes(_elderSpirits[i].affinity)) ==
                    keccak256(bytes(winningAffinitiesByRound[currentRound])) &&
                    getElderSpawnsAmount(currentRound, i) > 0
                ) {
                    _heroRewardsShare = rewardsPoolAmount.div(getElderSpawnsAmount(currentRound, i));
                    break;
                }
            }

            // Burn the elders
            _burnElders();

            // Set the next phase
            currentPhase = Phase.SETUP;
        }

        currentPhaseStartTime = now;
    }

    /// @notice Sets the contract's phase
    /// @dev May delete function and keep only the refresh phase function
    /// @param phase The phase the contract should be set to
    function setPhase(Phase phase) external onlyAdmin {
        currentPhase = phase;
    }

    /// @notice Transitions to next phase if the condition is met and rewards caller for a successful phase transition
    function refreshPhase() external override {
        bool phaseChanged = false;

        if (
            currentPhase == Phase.SETUP &&
            eldersInGame == MAX_NUMBER_OF_ELDERS &&
            now >= currentPhaseStartTime + _setupPhaseDuration
        ) {
            _transitionNextPhase();
        } else if (currentPhase == Phase.ACTION && now >= currentPhaseStartTime + _actionPhaseDuration) {
            _transitionNextPhase();
        }

        if (phaseChanged) {
            // todo reward msg.sender
        }
    }

    /// @notice Makes a request for a random number
    /// @param userProvidedSeed The seed for the random request
    /// @return requestId The request id
    function _getRandomNumber(uint256 userProvidedSeed) internal returns (bytes32 requestId) {
        require(LINK.balanceOf(address(this)) >= _fee); // dev: Not enough LINK - fill contract with faucet
        return requestRandomness(_keyHash, _fee, userProvidedSeed);
    }

    /// @notice Callback function used by the VRF coordinator
    /// @param requestId The request id
    /// @param randomness The randomness
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        _randomResultsVRF[requestId] = randomness;
        _trainHero(requestId);
    }

    /// @notice Check if msg.sender has the role
    /// @param role The role to verify
    function _hasRole(bytes32 role) internal view {
        require(hasRole(role, msg.sender)); // dev: Access denied.
    }

    /// @notice Creates a new token affinity
    /// @dev This will be called by a priviledged address. It will allow to create new affinities. May need to add a
    /// remove affinity function as well.
    /// @param tokenTicker The token ticker of the affinity
    /// @param feedAddress The price feed address
    function createAffinity(string calldata tokenTicker, address feedAddress) external override onlyAdmin {
        _affinities[tokenTicker] = feedAddress;
        affinities.push(tokenTicker);
    }

    /// @notice Sets the elder mint price
    /// @dev Can only be called by an admin address
    /// @param price The new elder mint price
    function setElderMintPrice(uint256 price) external override onlyAdmin {
        elderMintPrice = price;
    }

    /// @notice Mints an elder spirit
    /// @dev For now only race, class, and token (affinity) are needed. This will change. The race and class ids will
    /// probably be public constants defined in the crypto champions contract, this is subject to change.
    /// @param raceId The race id
    /// @param classId The class id
    /// @param affinity The affinity of the minted hero
    /// @return The elder spirit id
    function mintElderSpirit(
        uint256 raceId,
        uint256 classId,
        string calldata affinity
    ) external payable override atPhase(Phase.SETUP) returns (uint256) {
        require(eldersInGame < MAX_NUMBER_OF_ELDERS); // dev: Max number of elders already minted.
        require(msg.value >= elderMintPrice); // dev: Insufficient payment.
        require(_affinities[affinity] != address(0)); // dev: Affinity does not exist.

        // Generate the elderId and make sure it doesn't already exists
        uint256 elderId = eldersInGame.add(1);
        assert(_elderOwners[elderId] == address(0)); // dev: Elder with id already has owner.
        assert(_elderSpirits[elderId].valid == false); // dev: Elder spirit with id has already been generated.

        // Get the price data of affinity
        int256 affinityPrice;
        (, affinityPrice, , , ) = AggregatorV3Interface(_affinities[affinity]).latestRoundData();

        // Create the elder spirit
        ElderSpirit memory elder;
        elder.valid = true;
        elder.raceId = raceId;
        elder.classId = classId;
        elder.affinity = affinity;
        elder.affinityPrice = affinityPrice;

        // Mint the NFT
        _mint(_msgSender(), elderId, 1, ""); // TODO: give the URI

        // Assign the elder id with the owner and its spirit
        _elderOwners[elderId] = _msgSender();
        _elderSpirits[elderId] = elder;

        // Increment elders minted
        eldersInGame = eldersInGame.add(1);

        // Refund if user sent too much
        _refundSender(elderMintPrice);

        // The entire elder minting fee goes to the dev fund
        devFund = devFund.add(elderMintPrice);

        emit ElderSpiritMinted(elderId, _msgSender());

        return elderId;
    }

    /// @notice Gets the elder owner for the given elder id
    /// @param elderId The elder id
    /// @return The owner of the elder
    function getElderOwner(uint256 elderId) public view override isValidElderSpiritId(elderId) returns (address) {
        require(_elderOwners[elderId] != address(0)); // dev: Given elder id has not been minted.

        return _elderOwners[elderId];
    }

    /// @notice Mints a hero based on an elder spirit
    /// @param elderId The id of the elder spirit this hero is based on
    /// @return The hero id
    function mintHero(uint256 elderId, string calldata heroName)
        external
        payable
        override
        isValidElderSpiritId(elderId)
        atPhase(Phase.ACTION)
        returns (uint256)
    {
        require(_elderSpirits[elderId].valid); // dev: Elder with id doesn't exists or not valid.

        require(_canMintHero(elderId)); // dev: Can't mint hero. Too mnay heroes minted for elder.

        uint256 mintPrice = getHeroMintPrice(currentRound, elderId);
        require(msg.value >= mintPrice); // dev: Insufficient payment.

        // Generate the hero id
        uint256 heroId = heroesMinted.add(1) + MAX_NUMBER_OF_ELDERS;
        assert(_heroOwners[heroId] == address(0)); // dev: Hero with id already has an owner.
        assert(_heroes[heroId].valid == false); // dev: Hero with id has already been generated.

        // Create the hero
        Hero memory hero;
        hero.valid = true;
        hero.name = heroName;
        hero.roundMinted = currentRound;
        hero.elderId = elderId;
        hero.raceId = _elderSpirits[elderId].raceId;
        hero.classId = _elderSpirits[elderId].classId;
        hero.affinity = _elderSpirits[elderId].affinity;
        _heroes[heroId] = hero;

        // Request the random number and set hero attributes
        bytes32 requestId = _getRandomNumber(heroId);
        _heroRandomRequest[requestId] = heroId;

        // Mint the NFT
        _mint(_msgSender(), heroId, 1, ""); // TODO: give the URI

        // Mint in game currency tokens
        _mint(_msgSender(), IN_GAME_CURRENCY_ID, NUM_TOKENS_MINTED, "");

        // Assign the hero id with the owner and with the hero
        _heroOwners[heroId] = _msgSender();

        // Increment the heroes minted and the elder spawns
        heroesMinted = heroesMinted.add(1);
        _roundElderSpawns[currentRound][elderId] = _roundElderSpawns[currentRound][elderId].add(1);

        // Disburse royalties
        uint256 royaltyFee = mintPrice.mul(HERO_MINT_ROYALTY_PERCENT).div(100);
        address seedOwner = _elderOwners[elderId];
        (bool success, ) = seedOwner.call{ value: royaltyFee }("");
        require(success, "Payment failed");

        // Update the rewards and dev fund pools
        uint256 devFee = mintPrice.mul(HERO_MINT_DEV_PERCENT).div(100);
        devFund = devFund.add(devFee);
        rewardsPoolAmount = rewardsPoolAmount.add(mintPrice.sub(royaltyFee).sub(devFee));

        // Refund if user sent too much
        _refundSender(mintPrice);

        emit HeroMinted(heroId, _msgSender());

        return heroId;
    }

    /// @notice Checks to see if a hero can be minted for a given elder
    /// @dev (n < 4) || (n <= 2 * m)
    ///     n is number of champions already minted for elder
    ///     m is number of champions already minted for elder with least amount of champions
    /// @param elderId The elder id
    /// @return True if hero can be minted, false otherwise
    function _canMintHero(uint256 elderId) internal view returns (bool) {
        // Verify first condition
        if (_roundElderSpawns[currentRound][elderId] < 4) {
            return true;
        }

        // Find the elder with the least amount of heroes minted
        uint256 smallestElderAmount = _roundElderSpawns[currentRound][elderId];
        for (uint256 i = 1; i <= eldersInGame; ++i) {
            if (_roundElderSpawns[currentRound][i] < smallestElderAmount) {
                smallestElderAmount = _roundElderSpawns[currentRound][i];
            }
        }

        return _roundElderSpawns[currentRound][elderId] <= smallestElderAmount.mul(2);
    }

    /// @notice Sets the hero attributes
    /// @param requestId The request id that is mapped to a hero
    function _trainHero(bytes32 requestId) internal isValidHero(_heroRandomRequest[requestId]) {
        uint256 heroId = _heroRandomRequest[requestId];
        uint256 randomNumber = _randomResultsVRF[requestId];
        uint256 newRandomNumber;

        _heroes[heroId].level = 1; // 1 by default
        (_heroes[heroId].appearance, newRandomNumber) = _rollDice(2, randomNumber); // 1 out of 2

        (_heroes[heroId].trait1, newRandomNumber) = _rollDice(4, newRandomNumber); // 1 out of 4
        (_heroes[heroId].trait2, newRandomNumber) = _rollDice(4, newRandomNumber); // 1 out of 4
        (_heroes[heroId].skill1, newRandomNumber) = _rollDice(4, newRandomNumber); // 1 out of 4
        (_heroes[heroId].skill2, newRandomNumber) = _rollDice(4, newRandomNumber); // 1 out of 4

        (_heroes[heroId].alignment, newRandomNumber) = _rollDice(9, newRandomNumber); // 1 out of 9
        (_heroes[heroId].background, newRandomNumber) = _rollDice(30, newRandomNumber); // 1 out of 30
        (_heroes[heroId].hometown, newRandomNumber) = _rollDice(24, newRandomNumber); // 1 out of 24
        (_heroes[heroId].weather, newRandomNumber) = _rollDice(7, newRandomNumber); // 1 ouf of 7

        (_heroes[heroId].hp, newRandomNumber) = _rollDice(21, newRandomNumber); // Roll 10-30
        _heroes[heroId].hp = uint8(_heroes[heroId].hp.add(9));
        (_heroes[heroId].mana, newRandomNumber) = _rollDice(21, newRandomNumber); // Roll 10-30
        _heroes[heroId].mana = uint8(_heroes[heroId].mana.add(9));
        (_heroes[heroId].stamina, newRandomNumber) = _rollDice(31, newRandomNumber); // Roll 10-40
        _heroes[heroId].stamina = uint8(_heroes[heroId].stamina.add(9));

        (_heroes[heroId].strength, newRandomNumber) = _rollDice(16, newRandomNumber); // Roll 3-18
        _heroes[heroId].strength = uint8(_heroes[heroId].strength.add(2));
        (_heroes[heroId].dexterity, newRandomNumber) = _rollDice(16, newRandomNumber); // Roll 3-18
        _heroes[heroId].dexterity = uint8(_heroes[heroId].dexterity.add(2));
        (_heroes[heroId].constitution, newRandomNumber) = _rollDice(16, newRandomNumber); // Roll 3-18
        _heroes[heroId].constitution = uint8(_heroes[heroId].constitution.add(2));
        (_heroes[heroId].intelligence, newRandomNumber) = _rollDice(16, newRandomNumber); // Roll 3-18
        _heroes[heroId].intelligence = uint8(_heroes[heroId].intelligence.add(2));
        (_heroes[heroId].wisdom, newRandomNumber) = _rollDice(16, newRandomNumber); // Roll 3-18
        _heroes[heroId].wisdom = uint8(_heroes[heroId].wisdom.add(2));
        (_heroes[heroId].charisma, newRandomNumber) = _rollDice(16, newRandomNumber); // Roll 3-18
        _heroes[heroId].charisma = uint8(_heroes[heroId].charisma.add(2));
    }

    /// @notice Simulates rolling dice
    /// @param maxNumber The max number of the dice (e.g. regular die is 6)
    /// @param randomNumber The random number
    /// @return The result of the dice roll and a new random number to use for another dice roll
    function _rollDice(uint8 maxNumber, uint256 randomNumber) internal pure returns (uint8, uint256) {
        return (uint8(randomNumber.mod(maxNumber).add(1)), randomNumber.div(10));
    }

    /// @notice Get the hero owner for the given hero id
    /// @param heroId The hero id
    /// @return The owner address
    function getHeroOwner(uint256 heroId) public view override isValidHero(heroId) returns (address) {
        require(_heroOwners[heroId] != address(0)); // dev: Given hero id has not been minted.

        return _heroOwners[heroId];
    }

    /// @notice Burns all the elder spirits in game
    function _burnElders() internal {
        for (uint256 i = 1; i <= MAX_NUMBER_OF_ELDERS; ++i) {
            if (_elderSpirits[i].valid) {
                _burnElder(i);
            }
        }

        emit ElderSpiritsBurned();
    }

    /// @notice Burns the elder spirit
    /// @dev This will only be able to be called by the contract
    /// @param elderId The elder id
    function _burnElder(uint256 elderId) internal isValidElderSpiritId(elderId) {
        require(_elderSpirits[elderId].valid); // dev: Cannot burn elder that does not exist.

        _burn(_elderOwners[elderId], elderId, 1);

        // Reset elder values for elder id
        eldersInGame = eldersInGame.sub(1);
        _elderOwners[elderId] = address(0);
        _elderSpirits[elderId].valid = false;
    }

    /// @notice Gets the minting price of a hero based on specified elder spirit
    /// @param round The round of the hero to be minted
    /// @param elderId The elder id for which the hero will be based on
    /// @return The hero mint price
    function getHeroMintPrice(uint256 round, uint256 elderId)
        public
        view
        override
        isValidElderSpiritId(elderId)
        returns (uint256)
    {
        require(round <= currentRound); // dev: Cannot get price round has not started.
        uint256 heroAmount = _roundElderSpawns[round][elderId].add(1);

        return _priceFormula(heroAmount);
    }

    /// @notice The bounding curve function that calculates price for the new supply
    /// @dev price = 0.02*(heroes minted) + 0.1
    /// @param newSupply The new supply after a burn or mint
    /// @return The calculated price
    function _priceFormula(uint256 newSupply) internal pure returns (uint256) {
        uint256 price;
        uint256 base = 1;
        price = newSupply.mul(10**18).mul(2).div(100);
        price = price.add(base.mul(10**18).div(10));

        return price;
    }

    /// @dev Hook function called before every token transfer
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            // If token is an elder spirit, update owners so can send them royalties
            if (ids[i] > IN_GAME_CURRENCY_ID && ids[i] <= MAX_NUMBER_OF_ELDERS) {
                _elderOwners[ids[i]] = payable(to);
            }
            if (ids[i] > MAX_NUMBER_OF_ELDERS) {
                _heroOwners[ids[i]] = to;
            }
        }
    }

    /// @notice Gets the amount of heroes spawn from the elder with the specified id during the specified round
    /// @param round The round the elder was created
    /// @param elderId The elder id
    /// @return The amount of heroes spawned from the elder
    function getElderSpawnsAmount(uint256 round, uint256 elderId)
        public
        view
        override
        isValidElderSpiritId(elderId)
        returns (uint256)
    {
        require(round <= currentRound); // dev: Invalid round.
        return _roundElderSpawns[round][elderId];
    }

    /// @notice Refunds the sender if they sent too much
    /// @param cost The cost
    function _refundSender(uint256 cost) internal {
        if (msg.value.sub(cost) > 0) {
            (bool success, ) = msg.sender.call{ value: msg.value.sub(cost) }("");
            require(success); // dev: Refund failed.
        }
    }

    /// @notice Fetches the data of a single elder spirit
    /// @param elderId The id of the elder being searched for
    /// @return The elder's attributes in the following order (valid, raceId, classId, affinity)
    function getElderSpirit(uint256 elderId)
        external
        view
        override
        isValidElderSpiritId(elderId)
        returns (
            bool,
            uint256,
            uint256,
            string memory,
            int256
        )
    {
        ElderSpirit memory elderSpirit = _elderSpirits[elderId];
        return (
            elderSpirit.valid,
            elderSpirit.raceId,
            elderSpirit.classId,
            elderSpirit.affinity,
            elderSpirit.affinityPrice
        );
    }

    /// @notice Hero getter function
    /// @param heroId The hero id
    /// @return valid, affinity, affinity price, round minted, elder id
    function getHeroGameData(uint256 heroId)
        external
        view
        override
        isValidHero(heroId)
        returns (
            bool, // valid
            string memory, // affinity
            int256, // affinity price
            uint256, // round minted
            uint256 // elder id
        )
    {
        return (
            _heroes[heroId].valid,
            _heroes[heroId].affinity,
            _heroes[heroId].affinityPrice,
            _heroes[heroId].roundMinted,
            _heroes[heroId].elderId
        );
    }

    /// @notice Hero getter function
    /// @param heroId The hero id
    /// @return name, race id, class id, appearance
    function getHeroVisuals(uint256 heroId)
        external
        view
        override
        isValidHero(heroId)
        returns (
            string memory, // name
            uint256, // race id
            uint256, // class id
            uint8 // appearance
        )
    {
        return (_heroes[heroId].name, _heroes[heroId].raceId, _heroes[heroId].classId, _heroes[heroId].appearance);
    }

    /// @notice Hero getter function
    /// @param heroId The hero id
    /// @return trait 1, trait 2, skill 1, skill 2
    function getHeroTraitsSkills(uint256 heroId)
        external
        view
        override
        isValidHero(heroId)
        returns (
            uint8, // trait 1
            uint8, // trait 2
            uint8, // skill 1
            uint8 // skill 2
        )
    {
        return (_heroes[heroId].trait1, _heroes[heroId].trait2, _heroes[heroId].skill1, _heroes[heroId].skill2);
    }

    /// @notice Hero getter function
    /// @param heroId The hero id
    /// @return alignment, background, hometown, weather
    function getHeroLore(uint256 heroId)
        external
        view
        override
        isValidHero(heroId)
        returns (
            uint8, // alignment
            uint8, // background
            uint8, // hometown
            uint8 // weather
        )
    {
        return (
            _heroes[heroId].alignment,
            _heroes[heroId].background,
            _heroes[heroId].hometown,
            _heroes[heroId].weather
        );
    }

    /// @notice Hero getter function
    /// @param heroId The hero id
    /// @return level, hp, mana
    function getHeroVitals(uint256 heroId)
        external
        view
        override
        isValidHero(heroId)
        returns (
            uint8, // level
            uint8, // hp
            uint8, // mana
            uint8 // stamina
        )
    {
        return (_heroes[heroId].level, _heroes[heroId].hp, _heroes[heroId].mana, _heroes[heroId].stamina);
    }

    /// @notice Hero getter function
    /// @param heroId The hero id
    /// @return stamina, strength, dexterity, constitution, intelligence, wisdom, charisma
    function getHeroStats(uint256 heroId)
        external
        view
        override
        isValidHero(heroId)
        returns (
            uint8, // strength
            uint8, // dexterity
            uint8, // constitution
            uint8, // intelligence
            uint8, // wisdom
            uint8 // charisma
        )
    {
        return (
            _heroes[heroId].strength,
            _heroes[heroId].dexterity,
            _heroes[heroId].constitution,
            _heroes[heroId].intelligence,
            _heroes[heroId].wisdom,
            _heroes[heroId].charisma
        );
    }

    /// @notice Fetches the feed address for a given affinity
    /// @param affinity The affinity being searched for
    /// @return The address of the affinity's feed address
    function getAffinityFeedAddress(string calldata affinity) external view override returns (address) {
        return _affinities[affinity];
    }

    /// @notice Fetches the number of elders currently in the game
    /// @return The current number of elders in the game
    function getNumEldersInGame() external view override returns (uint256) {
        return eldersInGame;
    }

    /// @notice Declares a winning affinity for a round
    /// @dev This can only be called by a game admin contract
    /// @param winningAffinity The affinity that won the game
    function declareRoundWinner(string calldata winningAffinity) external override atPhase(Phase.ACTION) onlyGameAdmin {
        winningAffinitiesByRound[currentRound] = winningAffinity;
    }

    /// @notice Claims the rewards for the hero if eligible
    /// @dev Can only claim once and only for the round the hero was minted
    /// @param heroId The hero id
    function claimReward(uint256 heroId) external override atPhase(Phase.SETUP) isValidHero(heroId) {
        // Check if hero is eligible and if hero hasn't already claimed
        require(_heroes[heroId].roundMinted == currentRound); // dev: Hero was not minted this round.
        require(keccak256(bytes(_heroes[heroId].affinity)) == keccak256(bytes(winningAffinitiesByRound[currentRound]))); // dev: Hero does not have the winning affinity.
        require(_heroRewardsClaimed[heroId][currentRound] == false); // dev: Reward has already been claimed.

        (bool success, ) = _heroOwners[heroId].call{ value: _heroRewardsShare }("");
        require(success, "Payment failed");
        rewardsPoolAmount = rewardsPoolAmount.sub(_heroRewardsShare);
        _heroRewardsClaimed[heroId][currentRound] = true;
    }

    /// @notice Starts a new price game
    /// @dev This can only be called by the admin of the contract
    function _startNewPriceGame() internal {
        address priceWarsFactoryAddress = _minigameFactoryRegistry.getFactory(PRICE_WARS_ID);
        PriceWarsFactory priceWarsFactory = PriceWarsFactory(priceWarsFactoryAddress);
        PriceWars priceWar = priceWarsFactory.createPriceWar(address(this));
        grantRole(ROLE_GAME_ADMIN, address(priceWar));
        priceWar.startGame();
    }

    /// @notice Transfers in game currency tokens from one address to another
    /// @param to The receiving address
    /// @param amount The amount to transfer
    function transferInGameTokens(address to, uint256 amount) external override {
        bytes memory data;
        safeTransferFrom(msg.sender, to, IN_GAME_CURRENCY_ID, amount, data);
    }

    /// @notice Transfers in game currency tokens from one address to another.
    /// @param from The sending address.  Note that the sender must be authorized to transfer funds if the sender is different from the from address.
    /// @param to The receiving address
    /// @param amount The amount to transfer
    function delegatedTransferInGameTokens(
        address from,
        address to,
        uint256 amount
    ) external override {
        bytes memory data;
        safeTransferFrom(from, to, IN_GAME_CURRENCY_ID, amount, data);
    }

    /// @notice Returns whether or not hero has reward for the round
    /// @param heroId The id of the hero being searched for
    function hasRoundReward(uint256 heroId) external view returns (bool) {
        Hero memory hero = _heroes[heroId];
        string memory roundWinningAffinity = winningAffinitiesByRound[currentRound];
        return
            !_heroRewardsClaimed[heroId][currentRound] &&
            keccak256(bytes(hero.affinity)) == keccak256(bytes(roundWinningAffinity)) &&
            hero.roundMinted == currentRound;
    }
}