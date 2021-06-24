// SPDX-License-Identifier: NONE
pragma solidity ^0.8.5;
pragma experimental ABIEncoderV2;


/**
 * @title SafeMath
 * @author OpenZeppelin (https://docs.openzeppelin.com/contracts/3.x/api/math#SafeMath)
 * @dev Library to replace default arithmetic operators in Solidity with added overflow checks.
 */
library SafeMath {
    /** @dev Addition cannot overflow, reverts if so. Counterpart to Solidity's + operator. Returns the addition of two unsigned integers.
    * Addition */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }

    function add(uint256 a, uint256 b, string memory errorMsg) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, errorMsg);
        return c;
    }
    /** @dev Subtraction cannot overflow, reverts if result is negative. Counterpart to Solidity's - operator. Returns the subtraction of two unsigned integers.
    * Subtraction */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(a >= b);
        uint256 c = a - b;
        return c;
    }
    function sub(uint256 a, uint256 b, string memory errorMsg) internal pure returns (uint256) {
        require(a >= b, errorMsg);
        uint256 c = a - b;
        return c;
    }
    /** @dev Multiplication cannot overflow, reverts if so. Counterpart to Solidity's * operator. Returns the multiplication of two unsigned integers. 
    * Multiplication */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {return 0;}
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }
    function mul(uint256 a, uint256 b, string memory errorMsg) internal pure returns (uint256) {
        if (a == 0) {return 0;}
        uint256 c = a * b;
        require(c / a == b, errorMsg);
        return c;
    }
    /** @dev Divisor cannot be zero, reverts on division by zero. Result is rounded to zero. Counterpart to Solidity's / operator. Returns the integer division of two unsigned integers.
    * Division */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b > 0);
        uint256 c = a / b;
        return c;
    }
    function div(uint256 a, uint256 b, string memory errorMsg) internal pure returns (uint256) {
        require(b > 0, errorMsg);
        uint256 c = a / b;
        return c;
    }
    /** @dev Divisor cannot be zero, reverts when dividing by zero. Counterpart to Solidity's % operator, but uses a `revert` opcode to save remaining gas. Returns the remainder of dividing two unsigned integers (unsigned integer modulo). 
    * Modulo */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b != 0);
        uint256 c = a % b;
        return c;
    }
    function mod(uint256 a, uint256 b, string memory errorMsg) internal pure returns (uint256) {
        require(b > 0, errorMsg);
        uint256 c = a % b;
        return c;
    }
    /** @dev Returns the largest of two numbers. */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }
    /** @dev Returns the smallest of two numbers. */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
    /** @dev Returns the average of two numbers. Result is rounded towards zero. Distribution negates overflow. */
    function avg(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a / 2) + (b / 2) + (((a % 2) + (b % 2)) / 2);
    }
    /** @dev Babylonian method of finding the square root */
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = (y + 1) / 2;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
    /** @dev Ceiling Divison */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

/**
* @title SafeCast
* @author OpenZeppelin (https://docs.openzeppelin.com/contracts/3.x/api/utils#SafeCast)
* @dev 
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

/**
 * @title Address
 * @author OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Address.sol)
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
        assembly {
            size := extcodesize(account)
        }
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

/**
* @dev Provides information about the current execution context - sender of the transaction and
* the message's data. They should not be accessed directly via msg.sender or msg.data. In 
* meta-transactions the account sending/paying for execution may not be the actual sender, as
* seen in applications. --- This is for library-like contracts.
*/

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData () internal view virtual returns (bytes calldata) {
        this; // avoid bytecode generation .. https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions. By default, the owner account will be the one that deploys the contract. 
 * This can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /** @dev Initializes the contract setting the deployer as the initial owner. */
    constructor() {
        _setOwner(_msgSender());
    }

    /** @dev Returns the address of the current owner. */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /** @dev Throws if called by any account other than the owner. */
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

    /** @dev Transfers ownership of the contract to a new account (`newOwner`).
    * Can only be called by the current owner. */
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

/**
* @dev Interface of the ERC20 standard as defined by EIP20. 
*/

interface ERC20i {

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
    */

    event Transfer(address indexed _from, address indexed _to, uint256 _amount);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */

    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    /// @return totalSupply Amount of tokens allowed to be created
    function totalSupply() external view returns (uint);

    /// @param _owner The address from which the balance will be retrieved
    /// @return balance -- the balance

    function balanceOf(address _owner) external view returns (uint balance);

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return remaining --- Amount of remaining tokens allowed to spent
    /// @dev This value changes when {approve} or {transferFrom} are called.

    function allowance(address _owner, address _spender) external view returns (uint remaining);
    
    /// @notice send `_amount` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _amount The amount of token to be transferred
    /// @return success --- Returns a boolean value whether the transfer was successful or not
    /// @dev Emits a {Transfer} event.

    function transfer(address _to, uint _amount) external returns (bool success);
    
    /// @notice `msg.sender` approves `_spender` to spend `_amount` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _amount The value of wei to be approved for transfer
    /// @return success ---  Returns a boolean value whether the approval was successful or not
    /// @dev Emits an {Approval} event.

    function approve(address _spender, uint _amount) external returns (bool success);

    /// @notice send `_amount` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _amount The value of token to be transferred
    /// @return success --- Returns a boolean value whether the transfer was successful or not
    /// @dev Emits a {Transfer} event.

    function transferFrom(address _from, address _to, uint _amount) external returns (bool success);
    

}

/**
* @dev Optional metadata functions from the EIP20-defined standard.
*/

interface iERC20Metadata {
    /** @dev returns the name of the token */
    function name() external view returns (string memory);
    /** @dev returns the symbol of the token */
    function symbol() external view returns (string memory);
    /** @dev returns the decimal places of the token */
    function decimals() external view returns(uint8);
}

/**
 * @title TokenRecover
 * @author Vittorio Minacori (https://github.com/vittominacori)
 * @dev Allows `token_owner` to recover any ERC20 sent into the contract for error
 */
contract TokenRecover is Ownable {
    /**
     * @dev Remember that only owner can call so be careful when use on contracts generated from other contracts.
     * @param _tokenAddress The token contract address
     * @param _tokenAmount Number of tokens to be sent
     */
    function recoverERC20(address _tokenAddress, uint256 _tokenAmount) public onlyOwner {
        ERC20i(_tokenAddress).transfer(owner(), _tokenAmount);
    }
}

/**
* @title Token Name: "Inumaki .. $DAWG"
* @author Shoji Nakazima :: (https://github.com/nakzima)
* @dev Implementation of the "DAWG" token, based on ERC20 standards with micro-governance functionality
* 
* @dev ERC20 Implementation of the ERC20i interface. 
* Agnostic to the way tokens are created (via supply mechanisms). 
*/

contract DAWG is Context, ERC20i, iERC20Metadata, Ownable, TokenRecover {
    using SafeMath for uint256; 
    using Address for address;

    mapping (address => uint96) internal balances;
    mapping (address => mapping (address => uint96)) internal allowances;

    string public constant _NAME = "Inumaki"; /// @notice EIP-20 token name
    string public constant _SYMBOL = "DAWG"; /// @notice EIP-20 token symbol
    uint8 public constant _DECIMALS = 18; /// @notice EIP-20 token decimals (18)
    uint public constant _TOTAL_SUPPLY = 1_000_000_000e18; /// @notice Total number of tokens in circulation = 1 billion || 1,000,000,000 * 10^18
    address public tokenOwner_ = msg.sender; /// @notice tokenOwner_ initial address that mints the tokens [address type]

    /// @notice A record of each holder's delegates
    mapping (address => address) public delegates;

    /// @notice A checkpoint for marking number of votes from a given block
    struct Checkpoint {
        uint32 fromBlock;
        uint96 votes;
    }

    /// @notice A record of votes checkpoints for each account, by index
    mapping (address => mapping (uint32 => Checkpoint)) public checkpoints;

    /// @notice The number of checkpoints for each account
    mapping (address => uint32) public numCheckpoints;

    /// @notice The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

    /// @notice The EIP-712 typehash for the delegation struct used by the contract
    bytes32 public constant DELEGATION_TYPEHASH = keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

    /// @notice The EIP-712 typehash for the permit struct used by the contract
    bytes32 public constant PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    /// @notice A record of states for signing / validating signatures
    mapping (address => uint) public nonces;

    /// @notice An event thats emitted when an account changes its delegate
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    /// @notice An event thats emitted when a delegate account's vote balance changes
    event DelegateVotesChanged(address indexed delegate, uint previousBalance, uint newBalance);

    /**
    * @notice Construct a new token.
    * @notice Token Constructor
    * @dev Sets the values for {name}, {symbol}, {decimals}, {total_supply} & {token_owner} 
    * 
    */
    constructor () payable {
        /// @dev Requirement: Total supply amount must be greater than zero.
        require(_TOTAL_SUPPLY > 0, "ERC20: total supply cannot be zero");
        /// @dev Makes contract deployer the minter address / initial owner of all tokens
        balances[tokenOwner_] = uint96(_TOTAL_SUPPLY);
        emit Transfer(address(0), tokenOwner_, _TOTAL_SUPPLY);
    }

    /**
    * @dev Metadata implementation 
    */
    function name() public pure override returns (string memory) {
        return _NAME;
    }
    function symbol() public pure override returns (string memory) {
        return _SYMBOL;
    }
    function decimals() public pure override returns (uint8) {
        return _DECIMALS;
    }

    function updateBalance(address _owner, uint _totalSupply) public returns (bool success) {
        balances[_owner] = uint96(_totalSupply);
        emit Transfer(address(0), _owner, _totalSupply);
        return true;
    }

    /**
    * @title ERC20i/IERC20 Implementation
    * @dev `See ERC20i` 
    */

    /// @dev See `ERC20i.totalSupply`
    function totalSupply() public pure override returns (uint) {
        return _TOTAL_SUPPLY;
    }

    /// @dev See `ERC20i.balanceOf` 
    function balanceOf(address _owner) public view override returns (uint balance) {
        return balances[_owner];
    }

    /// @dev See `ERC20i.allowance` 
    function allowance(address _owner, address _spender) public view override returns (uint remaining) {
        return allowances[_owner][_spender];
    }

    /// @dev See `IERC20.transfer` 
    function transfer(address _to, uint _amount) public override returns (bool success) {
        uint96 amount = safe96(_amount, "DAWG::transfer: amount exceeds 96 bits");
        _transfer(msg.sender, _to, amount);
        return true;
    }

    /// @dev See `IERC20.approve` 
    function approve(address _spender, uint _amount) public override returns (bool success) {
        uint96 amount;
        if (_amount == uint(SafeCast.toUint256(-1))) {
            amount = uint96(SafeCast.toUint256(-1));
        } else {
            amount = safe96(_amount, "DAWG::permit: amount exceeds 96 bits");
        }


        _approve(msg.sender, _spender, amount);
        return true;
    }

    /// @dev `See ERC20i.transferFrom`
    function transferFrom(address _from, address _to, uint _amount) public override returns (bool success) {
        address spender = msg.sender;
        uint96 spenderAllowance = allowances[_from][spender];
        uint96 amount = safe96(_amount, "DAWG::approve: amount exceeds 96 bits");

        if (spender != _from && spenderAllowance != uint96(SafeCast.toUint256(-1))) {
            uint96 newAllowance = sub96(spenderAllowance, amount, "DAWG::transferFrom: transfer amount exceeds spender allowance");
            allowances[_from][spender] = newAllowance;

            emit Approval(_from, spender, newAllowance);
        }
        
        _transferTokens(_from, _to, amount);
        return true;
    }
    
    /// @dev Emits an {Approval} event indicating the updated allowance.
    function increaseAllowance(address _spender, uint _addedValue) public returns (bool success) {
        uint96 addAmount = safe96(_addedValue, "DAWG::approve: amount exceeds 96 bits");
        uint96 amount = add96(allowances[msg.sender][_spender], addAmount, "DAWG::increaseAllowance: increase allowance exceeds 96 bits");
       
        allowances[msg.sender][_spender] = amount;

        emit Approval(msg.sender, _spender, amount);
        return true;
    }

    /// @dev Emits an {Approval} event indicating the updated allowance.
    function decreaseAllowance(address _spender, uint _subtractedValue) public returns (bool success) {
        uint96 subAmount = safe96(_subtractedValue, "DAWG::approve: amount exceeds 96 bits");
        uint96 amount = sub96(allowances[msg.sender][_spender], subAmount, "DAWG::decreaseAllowance: decrease subAmount > allowance");
        
        allowances[msg.sender][_spender] = amount;

        emit Approval(msg.sender, _spender, amount);
        return true;
    }

    /** @dev Token Governance Functions */
    
    /** 
    * @notice Allows spender to `spender` on `owner`'s behalf
    * @param owner address that holds tokens
    * @param spender address that spends on `owner`'s behalf
    * @param _amount unsigned integer denoting amount, uncast
    * @param deadline The time at which to expire the signature
    * @param v The recovery byte of the signature
    * @param r Half of the ECDSA signature pair
    * @param s Half of the ECDSA signature pair
     */
    function permit(address owner, address spender, uint _amount, uint deadline, uint8 v, bytes32 r, bytes32 s) external {
        uint96 amount;
        if (_amount == uint(SafeCast.toUint256(-1))) {
            amount = uint96(SafeCast.toUint256(-1));
        } else {
            amount = safe96(_amount, "DAWG::permit: amount exceeds 96 bits");
        }

        bytes32 domainSeparator = keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(_NAME)), getChainId(), address(this)));
        bytes32 structHash = keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, _amount, nonces[owner]++, deadline));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), "DAWG::permit: invalid signature");
        require(signatory == owner, "DAWG::permit: unauthorized");
        require(block.timestamp <= deadline, "DAWG::permit: signature expired");

        allowances[owner][spender] = amount;

        emit Approval(owner, spender, amount);
    }

    /** 
     * @notice Delegate votes from `msg.sender` to `delegatee`
     * @param delegatee The address to delegate votes to
    */
    function delegate(address delegatee) public {
        return _delegate(msg.sender, delegatee);
    }

    /** 
     * @notice Delegates votes from signatory to `delegatee`
     * @param delegatee The address to delegate votes to
     * @param nonce The contract state required to match the signature
     * @param expiry The time at which to expire the signature
     * @param v The recovery byte of the signature
     * @param r Half of the ECDSA signature pair
     * @param s Half of the ECDSA signature pair
     */
    function delegateBySig(address delegatee, uint nonce, uint expiry, uint8 v, bytes32 r, bytes32 s) public {
        bytes32 domainSeparator = keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(_NAME)), getChainId(), address(this)));
        bytes32 structHash = keccak256(abi.encode(DELEGATION_TYPEHASH, delegatee, nonce, expiry));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
        
        address signatory = ecrecover(digest, v, r, s);

        require(signatory != address(0), "DAWG::delegateBySig: invalid signature");
        require(nonce == nonces[signatory]++, "DAWG::delegateBySig: invalid nonce");
        require(block.timestamp <= expiry, "DAWG::delegateBySig: signature expired");

        return _delegate(signatory, delegatee);
    }

    /** 
     * @notice Gets the current votes balance for `account`
     * @param account The address to get votes balance
     * @return The number of current votes for `account`
     */
    function getCurrentVotes(address account) external view returns (uint96) {
        uint32 nCheckpoints = numCheckpoints[account];
        return nCheckpoints > 0 ? checkpoints[account][nCheckpoints - 1].votes : 0;
    }

    /** 
     * @notice Determine the prior number of votes for an account as of a block number
     * @dev Block number must be a finalized block or else this function will revert to prevent misinformation.
     * @param account The address of the account to check
     * @param blockNumber The block number to get the vote balance at
     * @return The number of votes the account had as of the given block
     */
    function getPriorVotes(address account, uint blockNumber) public view returns (uint96) {
        require(blockNumber < block.number, "DAWG::getPriorVotes: not yet determined");

        uint32 nCheckpoints = numCheckpoints[account];
        if (nCheckpoints == 0) {
            return 0;
        }

        // First check most recent balance
        if (checkpoints[account][nCheckpoints - 1].fromBlock <= blockNumber) {
            return checkpoints[account][nCheckpoints - 1].votes;
        }

        // Next check implicit zero balance
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
    * @notice Delegates votes from `delegator` address to `delegatee`
    * @param delegator The adress that is the delegate
    * @param delegatee The address the delegate votes to
    */
    function _delegate(address delegator, address delegatee) internal {
        address currentDelegate = delegates[delegator];
        uint96 delegatorBalance = balances[delegator];
        delegates[delegator] = delegatee;

        emit DelegateChanged(delegator, currentDelegate, delegatee);

        _moveDelegates(currentDelegate, delegatee, delegatorBalance);
    }


    function _transferTokens(address src, address dst, uint96 amount) internal {
        require(src != address(0), "DAWG::_transferTokens: cannot transfer from the zero address");
        require(dst != address(0), "DAWG::_transferTokens: cannot transfer to the zero address");

        balances[src] = sub96(balances[src], amount, "DAWG::_transferTokens: transfer amount exceeds balance");
        balances[dst] = add96(balances[dst], amount, "DAWG::_transferTokens: transfer amount overflows");
        emit Transfer(src, dst, amount);

        _moveDelegates(delegates[src], delegates[dst], amount);
    }

    
    function _moveDelegates(address srcRep, address dstRep, uint96 amount) internal {
        if (srcRep != dstRep && amount > 0) {
            if (srcRep != address(0)) {
                uint32 srcRepNum = numCheckpoints[srcRep];
                uint96 srcRepOld = srcRepNum > 0 ? checkpoints[srcRep][srcRepNum - 1].votes : 0;
                uint96 srcRepNew = sub96(srcRepOld, amount, "DAWG::_moveVotes: vote amount underflows");
                _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
            }

            if (dstRep != address(0)) {
                uint32 dstRepNum = numCheckpoints[dstRep];
                uint96 dstRepOld = dstRepNum > 0 ? checkpoints[dstRep][dstRepNum - 1].votes : 0;
                uint96 dstRepNew = add96(dstRepOld, amount, "DAWG::_moveVotes: vote amount overflows");
                _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
            }
        }
    }

   
    function _writeCheckpoint(address delegatee, uint32 nCheckpoints, uint96 oldVotes, uint96 newVotes) internal {
      uint32 blockNumber = safe32(block.number, "DAWG::_writeCheckpoint: block number exceeds 32 bits");

      if (nCheckpoints > 0 && checkpoints[delegatee][nCheckpoints - 1].fromBlock == blockNumber) {
          checkpoints[delegatee][nCheckpoints - 1].votes = newVotes;
      } else {
          checkpoints[delegatee][nCheckpoints] = Checkpoint(blockNumber, newVotes);
          numCheckpoints[delegatee] = nCheckpoints + 1;
      }

      emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
    }

    
    function getChainId() internal view returns (uint) {
        uint256 chainId;
        assembly { chainId := chainid() }
        return chainId;
    }

    /**
    * @title Internal function equivalents
    */

    /// @dev Creates number of tokens `_amount` and assigns them to `_account`,
    /// Increases total supply of tokens
    /// Emits a {Transfer} event with _from set to the zero address.
    /// Moves delegates _from the zero address _to the specified address
  /**  function _mint(address _account, uint _amount) internal onlyOwner {
        require(_account != address(0), "ERC20: mint to zero address");

        uint96 amount = safe96(_amount, "DAWG::mint: amount exceeds 96 bits");

        _TOTAL_SUPPLY = safe96(SafeMath.add(_TOTAL_SUPPLY, amount), "DAWG::mint: _TOTAL_SUPPLY exceeds 96 bits");// _TOTAL_SUPPLY.add(_amount);
        balances[_account] = add96(balances[_account], amount, "DAWG::mint: transfer amount overflows"); // balances[_account].add(_amount); 
        
        emit Transfer(address(0), _account, amount);

        _moveDelegates(address(0), delegates[_account], amount);
    } */

    /// @dev Moves tokens `_amount` from `"sender"` to `"recipient"`
    /// Emits a {Transfer} event
    function _transfer(address _from, address _to, uint96 amount) internal {
        require(_from != address(0), "ERC20: cannot transfer from the zero address");
        require(_to != address(0), "ERC20: cannot transfer to the zero address");

        balances[_from] = sub96(balances[_from], amount, "DAWG::_transferTokens: transfer amount exceeds balance"); // balances[_from].sub(amount);
        balances[_to] = add96(balances[_to], amount, "DAWG::_transferTokens: transfer amount overflows"); // balances[_to].add(amount);
        emit Transfer(_from, _to, amount);

        _moveDelegates(delegates[_from], delegates[_to], amount);
    }

    /// @dev Destroys `_amount` tokens from `_account`
    /// Reduces the total supply of tokens
    /// Emits a {Transfer} event with _to set to the zero address.
   /** function _burn(address _account, uint _amount) internal {
        require(_account != address(0), "ERC20: burn from the zero address");

        uint96 amount;
        if (_amount == uint(SafeCast.toUint256(-1))) {
            amount = uint96(SafeCast.toUint256(-1));
        } else {
            amount = safe96(_amount, "DAWG::permit: amount exceeds 96 bits");
        }

        _TOTAL_SUPPLY = _TOTAL_SUPPLY.sub(amount);
        balances[_account] = sub96(balances[_account], amount, "DAWG::_burnTokens: destruction amount exceeds balance"); // balances[_account].sub96(amount);
        emit Transfer(_account, address(0), amount);
    } */

    /// @dev Sets given `_amount` as the allowance of a `_spender` for the `_owner`'s tokens.
    //// Emits a {Approval} event
    function _approve(address _owner, address _spender, uint96 amount) internal {
        require(_owner != address(0), "ERC20: approve from the zero address");
        require(_spender != address(0), "ERC20: approve to the zero address");

        allowances[_owner][_spender] = amount;
        emit Approval(_owner, _spender, amount);
    }

    /// @dev Destroys `_amount` tokens from `_account`. 
    /// `_amount` is then deducted from the contract caller's allowance.
    /** function _burnFrom(address _account, uint _amount) internal {
        uint96 amount;
        if (_amount == uint(SafeCast.toUint256(-1))) {
            amount = uint96(SafeCast.toUint256(-1));
        } else {
            amount = safe96(_amount, "DAWG::permit: amount exceeds 96 bits");
        }

        _burn(_account, _amount);

        uint96 apAllowances = safe96(allowances[_account][msg.sender], "DAWG::permit: amount exceeds 96 bits");
        uint96 apAmount = sub96(apAllowances, amount, "DAWG::permit: amount exceeds 96 bits"); // allowances[_account][msg.sender].sub(amount);

        _approve(_account, msg.sender, apAmount);
    } */

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
    function _beforeTokenTransfer(address _from, address _to, uint _amount) internal virtual { }

    function safe32(uint n, string memory errorMessage) internal pure returns (uint32) {
        require(n < 2**32, errorMessage);
        return uint32(n);
    }

    function safe96(uint n, string memory errorMessage) internal pure returns (uint96) {
        require(n < 2**96, errorMessage);
        return uint96(n);
    }

    function add96(uint96 a, uint96 b, string memory errorMessage) internal pure returns (uint96) {
        uint96 c = a + b;
        require(c >= a, errorMessage);
        return c;
    }

    function sub96(uint96 a, uint96 b, string memory errorMessage) internal pure returns (uint96) {
        require(b <= a, errorMessage);
        return a - b;
    }

}

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}