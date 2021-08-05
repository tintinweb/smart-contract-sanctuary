/**
 *Submitted for verification at Etherscan.io on 2021-01-15
*/

// File: @openzeppelin/contracts/math/SafeMath.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
     *
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
        require(c / a == b, "SafeMath: multiplication overflow");

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
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
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
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
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
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: @openzeppelin/contracts/GSN/Context.sol


pragma solidity ^0.6.0;

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

// File: @openzeppelin/contracts/access/Ownable.sol


pragma solidity ^0.6.0;

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
    constructor () internal {
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
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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

// File: @openzeppelin/contracts/utils/Address.sol


pragma solidity ^0.6.2;

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
        // This method relies in extcodesize, which returns 0 for contracts in
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
        return _functionCallWithValue(target, data, 0, errorMessage);
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
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
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

// File: @openzeppelin/contracts/utils/EnumerableSet.sol


pragma solidity ^0.6.0;

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
 * As of v3.0.0, only sets of type `address` (`AddressSet`) and `uint256`
 * (`UintSet`) are supported.
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
        return _add(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(value)));
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
        return address(uint256(_at(set._inner, index)));
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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


pragma solidity ^0.6.0;

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

// File: contracts/interfaces/smart-pool/ISmartPool.sol

pragma solidity ^0.6.12;

interface ISmartPool is IERC20{

    function calcTokensForAmount(uint amount,uint8 direction) external view returns (address[] memory tokens, uint256[] memory amounts);

    function joinPool(address user,uint buyAmount)external;

    function exitPool(address user,uint sellAmount)external;

    function getJoinFeeRatio() external view returns (uint);

    function getExitFeeRatio() external view returns (uint);

}

// File: contracts/interfaces/smart-pool/ISmartPoolRegister.sol

pragma solidity ^0.6.12;

interface ISmartPoolRegistry {

    function inRegistry(address pool) external view returns (bool);
}

// File: contracts/interfaces/IMarket.sol

pragma solidity ^0.6.12;

interface IMarket {

    function getAmountOut(address fromToken, address toToken,uint amountIn) external view returns (uint amountOut);

    function getAmountIn(address fromToken, address toToken,uint amountOut) external view returns (uint amountIn);

    function getAmountsOut(uint amountIn,address[] calldata path) external view returns (uint[] memory amounts);

    function getAmountsIn(uint amountOut,address[] calldata path) external view returns (uint[] memory amounts);

    function swap(address fromToken,uint amountIn,address toToken,uint amountOut,address to) external;

    function bestSwap(uint amountIn,uint amountOut,address to,address[] calldata path) external;


}

// File: contracts/interfaces/gasSaver/IFreeFromUpTo.sol

pragma solidity ^0.6.12;

interface IFreeFromUpTo {
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function freeFromUpTo(address from, uint256 value) external returns(uint256 freed);
}

// File: contracts/interfaces/gasSaver/ChiGasSaver.sol

pragma solidity ^0.6.12;


contract ChiGasSaver {

    modifier saveGas(address payable sponsor) {
        uint256 gasStart = gasleft();
        _;
        uint256 gasSpent = 21000 + gasStart - gasleft() + 16 * msg.data.length;

        IFreeFromUpTo chi = IFreeFromUpTo(0x0000000000004946c0e9F43F4Dee607b0eF1fA1c);
        if(chi.balanceOf(sponsor)>0&&chi.allowance(sponsor,address(this))>0){
            chi.freeFromUpTo(sponsor, (gasSpent + 14154) / 41947);
        }
    }
}

// File: contracts/interfaces/weth/IWETH.sol

pragma solidity ^0.6.12;


interface IWETH is IERC20 {
    function deposit() external payable;
    function withdraw(uint wad) external;
}

// File: contracts/SwapRecipe.sol

pragma solidity ^0.6.12;










pragma experimental ABIEncoderV2;

contract SwapRecipe is ChiGasSaver,Ownable {
    using SafeMath for uint;
    using Address for address;
    using EnumerableSet for EnumerableSet.AddressSet;

    bool private isPaused = false;

    EnumerableSet.AddressSet private _markets;

    address public weth;

    ISmartPoolRegistry public registry;

    address payable public gasSponsor;

    constructor(
        address _defaultMarket,
        address _registry,
        address _weth,
        address payable _gasSponsor)
    public{
        require(_defaultMarket.isContract(),"SwapRecipe: The address is not contract!");
        require(_registry.isContract(),"SwapRecipe: The address is not contract!");
        require(_weth.isContract(),"SwapRecipe: The address is not contract!");
        _markets.add(_defaultMarket);
        registry=ISmartPoolRegistry(_registry);
        weth=_weth;
        gasSponsor=_gasSponsor;
    }

    modifier onlySponsor {
        require(msg.sender==gasSponsor,"SwapRecipe.onlySponsor: msg.sender not sponsor");
        _;
    }

    modifier notPaused {
        require(!isPaused,"SwapRecipe.notPaused: is Paused");
        _;
    }

    function togglePause() external onlyOwner {
        isPaused = !isPaused;
    }

    function destroy() external onlyOwner {
        address payable _to = payable(owner());
        selfdestruct(_to);
    }

    function cleanEth() external onlyOwner {
        msg.sender.transfer(address(this).balance);
    }

    function cleanToken(address _token) external onlyOwner {
        IERC20 token = IERC20(_token);
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }

    function addMarket(address market)external onlyOwner{
        require(!_markets.contains(market),"SwapRecipe.addMarket: The market already exists!");
        _markets.add(market);
    }

    function removeMarket(address market)external onlyOwner{
        require(_markets.contains(market),"SwapRecipe.removeMarket: The market not exists!");
        _markets.remove(market);
    }

    fallback() external payable {

    }
    receive() external payable {

    }

    function calcBuy(
        address pool,
        uint buyAmount,
        address payToken)
    public view returns (uint){
        (address[] memory tokens, uint[] memory amounts) = ISmartPool(pool).calcTokensForAmount(buyAmount,0);
        uint total = 0;
        for(uint i = 0; i < tokens.length; i++) {
            if(registry.inRegistry(tokens[i])) {
                total=total.add(calcBuy(tokens[i], amounts[i],payToken));
            } else {
                (,uint needIn)=calcMinAmountIn(payToken,tokens[i],amounts[i]);
                total=total.add(needIn);
            }
        }
        return total;
    }


    function calcBestBuy(
        address pool,
        uint buyAmount,
        address[][] memory paths)
    public view returns (uint){
        (address[] memory tokens, uint[] memory amounts) = ISmartPool(pool).calcTokensForAmount(buyAmount,0);
        uint total = 0;
        for(uint i = 0; i < tokens.length; i++) {
            if(registry.inRegistry(tokens[i])) {
                //todo Not supported at the moment
                //total=total.add(calcBestBuy(tokens[i], amounts[i]),paths);
            } else {
                (,uint needIn)=calcMinAmountsIn(amounts[i],paths[i]);
                total=total.add(needIn);
            }
        }
        return total;
    }

    function calcMinAmountIn(
        address fromToken,
        address toToken,
        uint amountOut)
    public view returns(address market,uint minAmountIn){
        if(fromToken==toToken){
            return (address(0),amountOut);
        }
        for(uint i = 0; i < _markets.length(); i++) {
            market=_markets.at(i);
            uint needIn=IMarket(market).getAmountIn(fromToken,toToken,amountOut);
            if(minAmountIn==0||needIn<minAmountIn){
                minAmountIn=needIn;
            }
        }
        return (market,minAmountIn);
    }

    function calcMinAmountsIn(
        uint amountOut,
        address[] memory path)
    public view returns(address market,uint minAmountIn){
        if(path[0]==path[1]){
            return (address(0),amountOut);
        }
        for(uint i = 0; i < _markets.length(); i++) {
            market=_markets.at(i);
            uint[] memory needIns=IMarket(market).getAmountsIn(amountOut,path);
            if(minAmountIn==0||needIns[0]<minAmountIn){
                minAmountIn=needIns[0];
            }
        }
        return (market,minAmountIn);
    }

    function calcSell(
        address pool,
        uint sellAmount,
        address sellToken)
    public view returns (uint){
        (address[] memory tokens, uint[] memory amounts) = ISmartPool(pool).calcTokensForAmount(sellAmount,1);
        uint total = 0;
        for(uint i = 0; i < tokens.length; i++) {
            if(registry.inRegistry(tokens[i])) {
                total=total.add(calcSell(tokens[i], amounts[i],sellToken));
            } else {
                (,uint sellOut)=calcMaxAmountOut(tokens[i],sellToken,amounts[i]);
                total=total.add(sellOut);
            }
        }
        return total;
    }

    function calcBestSell(
        address pool,
        uint sellAmount,
        address[][] memory paths)
    public view returns (uint){
        (address[] memory tokens, uint[] memory amounts) = ISmartPool(pool).calcTokensForAmount(sellAmount,1);
        uint total = 0;
        for(uint i = 0; i < tokens.length; i++) {
            if(registry.inRegistry(tokens[i])) {
                //todo Not supported at the moment
                //total=total.add(calcBestSell(tokens[i], amounts[i]),paths);
            } else {
                (,uint sellOut)=calcMaxAmountsOut(amounts[i],paths[i]);
                total=total.add(sellOut);
            }
        }
        return total;
    }

    function calcMaxAmountOut(
        address fromToken,
        address toToken,
        uint amountIn)
    public view returns(address market,uint maxAmountOut){
        if(fromToken==toToken){
            return (address(0),amountIn);
        }
        for(uint i = 0; i < _markets.length(); i++) {
            market=_markets.at(i);
            uint sellOut=IMarket(market).getAmountOut(fromToken,toToken,amountIn);
            if(maxAmountOut==0||sellOut>maxAmountOut){
                maxAmountOut=sellOut;
            }
        }
        return (market,maxAmountOut);
    }

    function calcMaxAmountsOut(
        uint amountIn,
        address[] memory path)
    public view returns(address market,uint maxAmountOut){
        if(path[0]==path[1]){
            return (address(0),amountIn);
        }
        for(uint i = 0; i < _markets.length(); i++) {
            market=_markets.at(i);
            uint[] memory sellOuts=IMarket(market).getAmountsOut(amountIn,path);
            if(maxAmountOut==0||sellOuts[sellOuts.length-1]>maxAmountOut){
                maxAmountOut=sellOuts[sellOuts.length-1];
            }
        }
        return (market,maxAmountOut);
    }


    function ethToKF(
        address pool,
        uint buyAmount)
    external payable notPaused saveGas(gasSponsor){
        require(registry.inRegistry(pool), "SwapRecipe.ethToKF: Not a Pool");
        uint totalAmount=calcBuy(pool,buyAmount,weth);
        require(msg.value >= totalAmount, "SwapRecipe.ethToKF: Buy ETH Amount too low");
        IWETH(weth).deposit{value: totalAmount}();
        _toKF(pool,msg.sender,buyAmount);
        //clear eth
        if(address(this).balance != 0) {
            msg.sender.transfer(address(this).balance);
        }
        ISmartPool(pool).transfer(msg.sender, ISmartPool(pool).balanceOf(address(this)));
    }

    function _toKF(
        address pool,
        address to,
        uint buyAmount)
    internal{
        (address[] memory tokens, uint[] memory amounts) = ISmartPool(pool).calcTokensForAmount(buyAmount,0);
        for(uint i = 0; i < tokens.length; i++) {
            if(registry.inRegistry(tokens[i])) {
                _toKF(tokens[i],to, amounts[i]);
            } else {
                if(weth==tokens[i]){
                    IWETH(weth).transfer(pool,amounts[i]);
                }else{
                    (address market,uint needWeth)=calcMinAmountIn(weth,tokens[i],amounts[i]);
                    IWETH(weth).transfer(market,needWeth);
                    IMarket(market).swap(weth,needWeth,tokens[i],amounts[i],pool);
                }
            }
        }
        ISmartPool(pool).joinPool(to,buyAmount);
    }

    function kfToEth(address pool,uint sellAmount,uint minAmount) external notPaused saveGas(gasSponsor){
        require(registry.inRegistry(pool), "SwapRecipe.kfToEth: Not a Pool");
        uint totalAmount=calcSell(pool,sellAmount,weth);
        require(minAmount <= totalAmount, "SwapRecipe.kfToEth: Sell ETH amount too low");
        ISmartPool poolProxy= ISmartPool(pool);
        (address[] memory tokens, uint[] memory amounts) = poolProxy.calcTokensForAmount(sellAmount,1);
        poolProxy.transferFrom(msg.sender, address(this), sellAmount);
        poolProxy.exitPool(msg.sender,sellAmount);
        for(uint i = 0; i < tokens.length; i++) {
            if(weth!=tokens[i]){
                (address market,uint getWeth)=calcMaxAmountOut(tokens[i],weth,amounts[i]);
                IERC20(tokens[i]).transfer(market,amounts[i]);
                IMarket(market).swap(tokens[i],amounts[i],weth,getWeth,address(this));
            }
        }
        IWETH(weth).withdraw(IWETH(weth).balanceOf(address(this)));
        msg.sender.transfer(address(this).balance);
    }


    function erc20ToKF(
        address pool,
        uint buyAmount,
        address[][] memory paths)
    external notPaused saveGas(gasSponsor){
        require(registry.inRegistry(pool), "SwapRecipe.erc20ToKF: Not a Pool");
        uint totalAmount=calcBestBuy(pool,buyAmount,paths);
        totalAmount=totalAmount.mul(105).div(100);
        address payToken=paths[0][0];
        require(IERC20(payToken).balanceOf(msg.sender)>=totalAmount,"SwapRecipe.erc20ToKF: You token insufficient balance");
        IERC20(payToken).transferFrom(msg.sender,address(this),totalAmount);

        _toBestKF(pool,msg.sender,buyAmount,paths);
        //Prevent accidental transfer in
        if(address(this).balance != 0) {
            msg.sender.transfer(address(this).balance);
        }
        //clear token
        if(IERC20(payToken).balanceOf(address(this)) != 0) {
            IERC20(payToken).transfer(msg.sender,IERC20(payToken).balanceOf(address(this)));
        }
        ISmartPool(pool).transfer(msg.sender, ISmartPool(pool).balanceOf(address(this)));
    }

    function _toBestKF(address pool,address to,uint buyAmount,address[][] memory paths) internal{
        (address[] memory tokens, uint[] memory amounts) = ISmartPool(pool).calcTokensForAmount(buyAmount,0);
        address payToken=paths[0][0];
        for(uint i = 0; i < tokens.length; i++) {
            if(registry.inRegistry(tokens[i])) {
                //todo Not supported at the moment
                //_toBestKF(tokens[i],to, amounts[i],paths);
            } else {
                if(payToken==tokens[i]){
                    IERC20(payToken).transfer(pool,amounts[i]);
                }else{
                    (address market,uint needToken)=calcMinAmountsIn(amounts[i],paths[i]);
                    IERC20(payToken).transfer(market,needToken);
                    IMarket(market).bestSwap(needToken,amounts[i],pool,paths[i]);
                }
            }
        }
        ISmartPool(pool).joinPool(to,buyAmount);
    }


    function kfToErc20(address pool,uint sellAmount,uint minAmount,address[][] memory paths) external notPaused saveGas(gasSponsor){
        require(registry.inRegistry(pool), "SwapRecipe.kfToErc20: Not a Pool");
        uint totalAmount=calcBestSell(pool,sellAmount,paths);
        require(minAmount <= totalAmount, "SwapRecipe.kfToErc20: Sell token amount too low");
        ISmartPool poolProxy= ISmartPool(pool);
        (address[] memory tokens, uint[] memory amounts) = poolProxy.calcTokensForAmount(sellAmount,1);
        poolProxy.transferFrom(msg.sender, address(this), sellAmount);
        poolProxy.exitPool(msg.sender,sellAmount);
        address sellToken=paths[0][paths[0].length-1];
        for(uint i = 0; i < tokens.length; i++) {
            if(sellToken!=tokens[i]){
                (address market,uint getToken)=calcMaxAmountsOut(amounts[i],paths[i]);
                IERC20(tokens[i]).transfer(market,amounts[i]);
                IMarket(market).bestSwap(amounts[i],getToken,address(this),paths[i]);
            }
        }
        IERC20(sellToken).transfer(msg.sender,IERC20(sellToken).balanceOf(address(this)));
    }
}