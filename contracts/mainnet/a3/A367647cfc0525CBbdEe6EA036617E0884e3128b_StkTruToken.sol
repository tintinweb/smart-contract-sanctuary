/**
 *Submitted for verification at Etherscan.io on 2021-02-19
*/

/*
    .'''''''''''..     ..''''''''''''''''..       ..'''''''''''''''..
    .;;;;;;;;;;;'.   .';;;;;;;;;;;;;;;;;;,.     .,;;;;;;;;;;;;;;;;;,.
    .;;;;;;;;;;,.   .,;;;;;;;;;;;;;;;;;;;,.    .,;;;;;;;;;;;;;;;;;;,.
    .;;;;;;;;;,.   .,;;;;;;;;;;;;;;;;;;;;,.   .;;;;;;;;;;;;;;;;;;;;,.
    ';;;;;;;;'.  .';;;;;;;;;;;;;;;;;;;;;;,. .';;;;;;;;;;;;;;;;;;;;;,.
    ';;;;;,..   .';;;;;;;;;;;;;;;;;;;;;;;,..';;;;;;;;;;;;;;;;;;;;;;,.
    ......     .';;;;;;;;;;;;;,'''''''''''.,;;;;;;;;;;;;;,'''''''''..
              .,;;;;;;;;;;;;;.           .,;;;;;;;;;;;;;.
             .,;;;;;;;;;;;;,.           .,;;;;;;;;;;;;,.
            .,;;;;;;;;;;;;,.           .,;;;;;;;;;;;;,.
           .,;;;;;;;;;;;;,.           .;;;;;;;;;;;;;,.     .....
          .;;;;;;;;;;;;;'.         ..';;;;;;;;;;;;;'.    .',;;;;,'.
        .';;;;;;;;;;;;;'.         .';;;;;;;;;;;;;;'.   .';;;;;;;;;;.
       .';;;;;;;;;;;;;'.         .';;;;;;;;;;;;;;'.    .;;;;;;;;;;;,.
      .,;;;;;;;;;;;;;'...........,;;;;;;;;;;;;;;.      .;;;;;;;;;;;,.
     .,;;;;;;;;;;;;,..,;;;;;;;;;;;;;;;;;;;;;;;,.       ..;;;;;;;;;,.
    .,;;;;;;;;;;;;,. .,;;;;;;;;;;;;;;;;;;;;;;,.          .',;;;,,..
   .,;;;;;;;;;;;;,.  .,;;;;;;;;;;;;;;;;;;;;;,.              ....
    ..',;;;;;;;;,.   .,;;;;;;;;;;;;;;;;;;;;,.
       ..',;;;;'.    .,;;;;;;;;;;;;;;;;;;;'.
          ...'..     .';;;;;;;;;;;;;;,,,'.
                       ...............
*/

// https://github.com/trusttoken/smart-contracts
// Dependency file: @openzeppelin/contracts/token/ERC20/IERC20.sol

// SPDX-License-Identifier: MIT

// pragma solidity ^0.6.0;

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
     * // importANT: Beware that changing an allowance with this method brings the risk
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


// Dependency file: @openzeppelin/contracts/utils/ReentrancyGuard.sol


// pragma solidity ^0.6.0;

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
contract ReentrancyGuard {
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


// Dependency file: @openzeppelin/contracts/math/SafeMath.sol


// pragma solidity ^0.6.0;

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


// Dependency file: @openzeppelin/contracts/GSN/Context.sol


// pragma solidity ^0.6.0;

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


// Dependency file: @openzeppelin/contracts/utils/Address.sol


// pragma solidity ^0.6.2;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [// importANT]
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
     * // importANT: because control is transferred to `recipient`, care must be
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


// Dependency file: contracts/trusttoken/common/ProxyStorage.sol

// pragma solidity 0.6.10;

/**
 * All storage must be declared here
 * New storage must be appended to the end
 * Never remove items from this list
 */
contract ProxyStorage {
    bool initalized;
    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    mapping(uint144 => uint256) attributes_Depricated;

    address owner_;
    address pendingOwner_;

    mapping(address => address) public delegates; // A record of votes checkpoints for each account, by index
    struct Checkpoint {
        // A checkpoint for marking number of votes from a given block
        uint32 fromBlock;
        uint96 votes;
    }
    mapping(address => mapping(uint32 => Checkpoint)) public checkpoints; // A record of votes checkpoints for each account, by index
    mapping(address => uint32) public numCheckpoints; // The number of checkpoints for each account
    mapping(address => uint256) public nonces;

    /* Additionally, we have several keccak-based storage locations.
     * If you add more keccak-based storage mappings, such as mappings, you must document them here.
     * If the length of the keccak input is the same as an existing mapping, it is possible there could be a preimage collision.
     * A preimage collision can be used to attack the contract by treating one storage location as another,
     * which would always be a critical issue.
     * Carefully examine future keccak-based storage to ensure there can be no preimage collisions.
     *******************************************************************************************************
     ** length     input                                                         usage
     *******************************************************************************************************
     ** 19         "trueXXX.proxy.owner"                                         Proxy Owner
     ** 27         "trueXXX.pending.proxy.owner"                                 Pending Proxy Owner
     ** 28         "trueXXX.proxy.implementation"                                Proxy Implementation
     ** 64         uint256(address),uint256(1)                                   balanceOf
     ** 64         uint256(address),keccak256(uint256(address),uint256(2))       allowance
     ** 64         uint256(address),keccak256(bytes32,uint256(3))                attributes
     **/
}


// Dependency file: contracts/trusttoken/common/ERC20.sol

/**
 * @notice This is a copy of openzeppelin ERC20 contract with removed state variables.
 * Removing state variables has been necessary due to proxy pattern usage.
 * Changes to Openzeppelin ERC20 https://github.com/OpenZeppelin/openzeppelin-contracts/blob/de99bccbfd4ecd19d7369d01b070aa72c64423c9/contracts/token/ERC20/ERC20.sol:
 * - Remove state variables _name, _symbol, _decimals
 * - Use state variables balances, allowances, totalSupply from ProxyStorage
 * - Remove constructor
 * - Solidity version changed from ^0.6.0 to 0.6.10
 * - Contract made abstract
 * - Remove inheritance from IERC20 because of ProxyStorage name conflicts
 *
 * See also: ClaimableOwnable.sol and ProxyStorage.sol
 */


// pragma solidity 0.6.10;

// import {Context} from "@openzeppelin/contracts/GSN/Context.sol";
// import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
// import {Address} from "@openzeppelin/contracts/utils/Address.sol";

// import {ProxyStorage} from "contracts/trusttoken/common/ProxyStorage.sol";

// prettier-ignore
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
abstract contract ERC20 is ProxyStorage, Context {
    using SafeMath for uint256;
    using Address for address;

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


    /**
     * @dev Returns the name of the token.
     */
    function name() public virtual pure returns (string memory);

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public virtual pure returns (string memory);

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
    function decimals() public virtual pure returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), allowance[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
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
        _approve(_msgSender(), spender, allowance[_msgSender()][spender].add(addedValue));
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
        _approve(_msgSender(), spender, allowance[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
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

        balanceOf[sender] = balanceOf[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        balanceOf[recipient] = balanceOf[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        totalSupply = totalSupply.add(amount);
        balanceOf[account] = balanceOf[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        balanceOf[account] = balanceOf[account].sub(amount, "ERC20: burn amount exceeds balance");
        totalSupply = totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
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

        allowance[owner][spender] = amount;
        emit Approval(owner, spender, amount);
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
    // solhint-disable-next-line no-empty-blocks
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}


// Dependency file: contracts/governance/interface/IVoteToken.sol

// pragma solidity ^0.6.10;

// import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IVoteToken {
    function delegate(address delegatee) external;

    function delegateBySig(
        address delegatee,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function getCurrentVotes(address account) external view returns (uint96);

    function getPriorVotes(address account, uint256 blockNumber) external view returns (uint96);
}

interface IVoteTokenWithERC20 is IVoteToken, IERC20 {}


// Dependency file: contracts/governance/VoteToken.sol

// AND COPIED FROM https://github.com/compound-finance/compound-protocol/blob/c5fcc34222693ad5f547b14ed01ce719b5f4b000/contracts/Governance/Comp.sol
// Copyright 2020 Compound Labs, Inc.
// Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
// 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
// 3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
// Ctrl+f for OLD to see all the modifications.

// pragma solidity 0.6.10;

// import {ERC20} from "contracts/trusttoken/common/ERC20.sol";
// import {IVoteToken} from "contracts/governance/interface/IVoteToken.sol";

/**
 * @title VoteToken
 * @notice Custom token which tracks voting power for governance
 * @dev This is an abstraction of a fork of the Compound governance contract
 * VoteToken is used by TRU and stkTRU to allow tracking voting power
 * Checkpoints are created every time state is changed which record voting power
 * Inherits standard ERC20 behavior
 */
abstract contract VoteToken is ERC20, IVoteToken {
    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");
    bytes32 public constant DELEGATION_TYPEHASH = keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);
    event DelegateVotesChanged(address indexed delegate, uint256 previousBalance, uint256 newBalance);

    function delegate(address delegatee) public override {
        return _delegate(msg.sender, delegatee);
    }

    /** 
     * @dev Delegate votes using signature
     */
    function delegateBySig(
        address delegatee,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public override {
        bytes32 domainSeparator = keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name())), getChainId(), address(this)));
        bytes32 structHash = keccak256(abi.encode(DELEGATION_TYPEHASH, delegatee, nonce, expiry));
        bytes32 digest = keccak256(abi.encodePacked("", domainSeparator, structHash));
        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), "TrustToken::delegateBySig: invalid signature");
        require(nonce == nonces[signatory]++, "TrustToken::delegateBySig: invalid nonce");
        require(now <= expiry, "TrustToken::delegateBySig: signature expired");
        return _delegate(signatory, delegatee);
    }

    /**
     * @dev Get current voting power for an account
     * @param account Account to get voting power for
     * @return Voting power for an account
     */
    function getCurrentVotes(address account) public virtual override view returns (uint96) {
        uint32 nCheckpoints = numCheckpoints[account];
        return nCheckpoints > 0 ? checkpoints[account][nCheckpoints - 1].votes : 0;
    }

    /**
     * @dev Get voting power at a specific block for an account
     * @param account Account to get voting power for
     * @param blockNumber Block to get voting power at
     * @return Voting power for an account at specific block
     */
    function getPriorVotes(address account, uint256 blockNumber) public virtual override view returns (uint96) {
        require(blockNumber < block.number, "TrustToken::getPriorVotes: not yet determined");

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
     * @dev Internal function to delegate voting power to an account
     * @param delegator Account to delegate votes from
     * @param delegatee Account to delegate votes to
     */
    function _delegate(address delegator, address delegatee) internal {
        address currentDelegate = delegates[delegator];
        // OLD: uint96 delegatorBalance = balanceOf(delegator);
        uint96 delegatorBalance = safe96(_balanceOf(delegator), "StkTruToken: uint96 overflow");
        delegates[delegator] = delegatee;

        emit DelegateChanged(delegator, currentDelegate, delegatee);

        _moveDelegates(currentDelegate, delegatee, delegatorBalance);
    }

    function _balanceOf(address account) internal view virtual returns (uint256) {
        return balanceOf[account];
    }

    function _transfer(
        address _from,
        address _to,
        uint256 _value
    ) internal virtual override {
        super._transfer(_from, _to, _value);
        _moveDelegates(delegates[_from], delegates[_to], safe96(_value, "StkTruToken: uint96 overflow"));
    }

    function _mint(address account, uint256 amount) internal virtual override {
        super._mint(account, amount);
        _moveDelegates(address(0), delegates[account], safe96(amount, "StkTruToken: uint96 overflow"));
    }

    function _burn(address account, uint256 amount) internal virtual override {
        super._burn(account, amount);
        _moveDelegates(delegates[account], address(0), safe96(amount, "StkTruToken: uint96 overflow"));
    }

    /**
     * @dev internal function to move delegates between accounts
     */
    function _moveDelegates(
        address srcRep,
        address dstRep,
        uint96 amount
    ) internal {
        if (srcRep != dstRep && amount > 0) {
            if (srcRep != address(0)) {
                uint32 srcRepNum = numCheckpoints[srcRep];
                uint96 srcRepOld = srcRepNum > 0 ? checkpoints[srcRep][srcRepNum - 1].votes : 0;
                uint96 srcRepNew = sub96(srcRepOld, amount, "TrustToken::_moveVotes: vote amount underflows");
                _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
            }

            if (dstRep != address(0)) {
                uint32 dstRepNum = numCheckpoints[dstRep];
                uint96 dstRepOld = dstRepNum > 0 ? checkpoints[dstRep][dstRepNum - 1].votes : 0;
                uint96 dstRepNew = add96(dstRepOld, amount, "TrustToken::_moveVotes: vote amount overflows");
                _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
            }
        }
    }

    /** 
     * @dev internal function to write a checkpoint for voting power
     */
    function _writeCheckpoint(
        address delegatee,
        uint32 nCheckpoints,
        uint96 oldVotes,
        uint96 newVotes
    ) internal {
        uint32 blockNumber = safe32(block.number, "TrustToken::_writeCheckpoint: block number exceeds 32 bits");

        if (nCheckpoints > 0 && checkpoints[delegatee][nCheckpoints - 1].fromBlock == blockNumber) {
            checkpoints[delegatee][nCheckpoints - 1].votes = newVotes;
        } else {
            checkpoints[delegatee][nCheckpoints] = Checkpoint(blockNumber, newVotes);
            numCheckpoints[delegatee] = nCheckpoints + 1;
        }

        emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
    }

    /**
     * @dev internal function to convert from uint256 to uint32
     */
    function safe32(uint256 n, string memory errorMessage) internal pure returns (uint32) {
        require(n < 2**32, errorMessage);
        return uint32(n);
    }

    /**
     * @dev internal function to convert from uint256 to uint96
     */
    function safe96(uint256 n, string memory errorMessage) internal pure returns (uint96) {
        require(n < 2**96, errorMessage);
        return uint96(n);
    }

    /**
     * @dev internal safe math function to add two uint96 numbers
     */
    function add96(
        uint96 a,
        uint96 b,
        string memory errorMessage
    ) internal pure returns (uint96) {
        uint96 c = a + b;
        require(c >= a, errorMessage);
        return c;
    }

    /**
     * @dev internal safe math function to subtract two uint96 numbers
     */
    function sub96(
        uint96 a,
        uint96 b,
        string memory errorMessage
    ) internal pure returns (uint96) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /** 
     * @dev internal function to get chain ID
     */
    function getChainId() internal pure returns (uint256) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        return chainId;
    }
}


// Dependency file: contracts/trusttoken/common/ClaimableContract.sol

// pragma solidity 0.6.10;

// import {ProxyStorage} from "contracts/trusttoken/common/ProxyStorage.sol";

/**
 * @title ClaimableContract
 * @dev The ClaimableContract contract is a copy of Claimable Contract by Zeppelin.
 and provides basic authorization control functions. Inherits storage layout of
 ProxyStorage.
 */
contract ClaimableContract is ProxyStorage {
    function owner() public view returns (address) {
        return owner_;
    }

    function pendingOwner() public view returns (address) {
        return pendingOwner_;
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev sets the original `owner` of the contract to the sender
     * at construction. Must then be reinitialized
     */
    constructor() public {
        owner_ = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner_, "only owner");
        _;
    }

    /**
     * @dev Modifier throws if called by any account other than the pendingOwner.
     */
    modifier onlyPendingOwner() {
        require(msg.sender == pendingOwner_);
        _;
    }

    /**
     * @dev Allows the current owner to set the pendingOwner address.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        pendingOwner_ = newOwner;
    }

    /**
     * @dev Allows the pendingOwner address to finalize the transfer.
     */
    function claimOwnership() public onlyPendingOwner {
        address _pendingOwner = pendingOwner_;
        emit OwnershipTransferred(owner_, _pendingOwner);
        owner_ = _pendingOwner;
        pendingOwner_ = address(0);
    }
}


// Dependency file: contracts/truefi/interface/ITrueDistributor.sol

// pragma solidity 0.6.10;

// import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ITrueDistributor {
    function trustToken() external view returns (IERC20);

    function farm() external view returns (address);

    function distribute() external;

    function nextDistribution() external view returns (uint256);

    function empty() external;
}


// Root file: contracts/governance/StkTruToken.sol

pragma solidity 0.6.10;

// import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
// import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";

// import {VoteToken} from "contracts/governance/VoteToken.sol";
// import {ClaimableContract} from "contracts/trusttoken/common/ClaimableContract.sol";
// import {ITrueDistributor} from "contracts/truefi/interface/ITrueDistributor.sol";

/**
 * @title stkTRU
 * @dev Staking contract for TrueFi
 * TRU is staked and stored in the contract
 * stkTRU is minted when staking
 * Holders of stkTRU accrue rewards over time
 * Rewards are paid in TRU and tfUSD
 * stkTRU can be used to vote in governance
 * stkTRU can be used to rate and approve loans
 */
contract StkTruToken is VoteToken, ClaimableContract, ReentrancyGuard {
    using SafeMath for uint256;
    uint256 constant PRECISION = 1e30;
    uint256 constant MIN_DISTRIBUTED_AMOUNT = 100e8;

    struct FarmRewards {
        // track overall cumulative rewards
        uint256 cumulativeRewardPerToken;
        // track previous cumulate rewards for accounts
        mapping(address => uint256) previousCumulatedRewardPerToken;
        // track claimable rewards for accounts
        mapping(address => uint256) claimableReward;
        // track total rewards
        uint256 totalClaimedRewards;
        uint256 totalFarmRewards;
    }

    struct ScheduledTfUsdRewards {
        uint64 timestamp;
        uint96 amount;
    }

    // ================ WARNING ==================
    // ===== THIS CONTRACT IS INITIALIZABLE ======
    // === STORAGE VARIABLES ARE DECLARED BELOW ==
    // REMOVAL OR REORDER OF VARIABLES WILL RESULT
    // ========= IN STORAGE CORRUPTION ===========

    IERC20 public tru;
    IERC20 public tfusd;
    ITrueDistributor public distributor;
    address public liquidator;

    uint256 public stakeSupply;

    mapping(address => uint256) cooldowns;
    uint256 public cooldownTime;
    uint256 public unstakePeriodDuration;

    mapping(IERC20 => FarmRewards) public farmRewards;

    uint32[] public sortedScheduledRewardIndices;
    ScheduledTfUsdRewards[] public scheduledRewards;
    uint256 public undistributedTfusdRewards;
    uint32 public nextDistributionIndex;

    mapping(address => bool) public whitelistedFeePayers;

    // ======= STORAGE DECLARATION END ============

    event Stake(address indexed staker, uint256 amount);
    event Unstake(address indexed staker, uint256 burntAmount);
    event Claim(address indexed who, IERC20 indexed token, uint256 amountClaimed);
    event Withdraw(uint256 amount);
    event Cooldown(address indexed who, uint256 endTime);
    event CooldownTimeChanged(uint256 newUnstakePeriodDuration);
    event UnstakePeriodDurationChanged(uint256 newUnstakePeriodDuration);
    event FeePayerWhitelistingStatusChanged(address payer, bool status);

    /**
     * @dev Only Liquidator contract can perform TRU liquidations
     */
    modifier onlyLiquidator() {
        require(msg.sender == liquidator, "StkTruToken: Can be called only by the liquidator");
        _;
    }

    /**
     * @dev Only whitelisted payers can pay fees
     */
    modifier onlyWhitelistedPayers() {
        require(whitelistedFeePayers[msg.sender], "StkTruToken: Can be called only by whitelisted payers");
        _;
    }

    /**
     * Get TRU from distributor
     */
    modifier distribute() {
        // pull TRU from distributor
        // do not pull small amounts to save some gas
        // only pull if there is distribution and distributor farm is set to this farm
        if (distributor.nextDistribution() > MIN_DISTRIBUTED_AMOUNT && distributor.farm() == address(this)) {
            distributor.distribute();
        }
        _;
    }

    /**
     * Update all rewards when an account changes state
     * @param account Account to update rewards for
     */
    modifier update(address account) {
        updateTotalRewards(tru);
        updateClaimableRewards(tru, account);
        updateTotalRewards(tfusd);
        updateClaimableRewards(tfusd, account);
        _;
    }

    /**
     * Update rewards for a specific token when an account changes state
     * @param account Account to update rewards for
     * @param token Token to update rewards for
     */
    modifier updateRewards(address account, IERC20 token) {
        if (token == tru) {
            updateTotalRewards(tru);
            updateClaimableRewards(tru, account);
        } else if (token == tfusd) {
            updateTotalRewards(tfusd);
            updateClaimableRewards(tfusd, account);
        }
        _;
    }

    /**
     * @dev Initialize contract and set default values
     * @param _tru TRU token
     * @param _tfusd tfUSD token
     * @param _distributor Distributor for this contract
     * @param _liquidator Liquidator for staked TRU
     */
    function initialize(
        IERC20 _tru,
        IERC20 _tfusd,
        ITrueDistributor _distributor,
        address _liquidator
    ) public {
        require(!initalized, "StkTruToken: Already initialized");
        tru = _tru;
        tfusd = _tfusd;
        distributor = _distributor;
        liquidator = _liquidator;

        cooldownTime = 14 days;
        unstakePeriodDuration = 2 days;

        owner_ = msg.sender;
        initalized = true;
    }

    /**
     * @dev Owner can use this function to add new addresses to payers whitelist
     * Only whitelisted payers can call payFee method
     * @param payer Address that is being added to or removed from whitelist
     * @param status New whitelisting status
     */
    function setPayerWhitelistingStatus(address payer, bool status) external onlyOwner {
        whitelistedFeePayers[payer] = status;
        emit FeePayerWhitelistingStatusChanged(payer, status);
    }

    /**
     * @dev Owner can use this function to set cooldown time
     * Cooldown time defines how long a staker waits to unstake TRU
     * @param newCooldownTime New cooldown time for stakers
     */
    function setCooldownTime(uint256 newCooldownTime) external onlyOwner {
        // Avoid overflow
        require(newCooldownTime <= 100 * 365 days, "StkTruToken: Cooldown too large");

        cooldownTime = newCooldownTime;
        emit CooldownTimeChanged(newCooldownTime);
    }

    /**
     * @dev Owner can set unstake period duration
     * Unstake period defines how long after cooldown a user has to withdraw stake
     * @param newUnstakePeriodDuration New unstake period
     */
    function setUnstakePeriodDuration(uint256 newUnstakePeriodDuration) external onlyOwner {
        require(newUnstakePeriodDuration > 0, "StkTruToken: Unstake period cannot be 0");
        // Avoid overflow
        require(newUnstakePeriodDuration <= 100 * 365 days, "StkTruToken: Unstake period too large");

        unstakePeriodDuration = newUnstakePeriodDuration;
        emit UnstakePeriodDurationChanged(newUnstakePeriodDuration);
    }

    /**
     * @dev Stake TRU for stkTRU
     * Updates rewards when staking
     * @param amount Amount of TRU to stake for stkTRU
     */
    function stake(uint256 amount) external distribute update(msg.sender) {
        require(amount > 0, "StkTruToken: Cannot stake 0");

        if (cooldowns[msg.sender] != 0 && cooldowns[msg.sender].add(cooldownTime).add(unstakePeriodDuration) > block.timestamp) {
            cooldowns[msg.sender] = block.timestamp;

            emit Cooldown(msg.sender, block.timestamp.add(cooldownTime));
        }

        if (delegates[msg.sender] == address(0)) {
            delegates[msg.sender] = msg.sender;
        }

        uint256 amountToMint = stakeSupply == 0 ? amount : amount.mul(totalSupply).div(stakeSupply);
        _mint(msg.sender, amountToMint);
        stakeSupply = stakeSupply.add(amount);

        require(tru.transferFrom(msg.sender, address(this), amount));

        emit Stake(msg.sender, amount);
    }

    /**
     * @dev Unstake stkTRU for TRU
     * Can only unstake when cooldown complete and within unstake period
     * Claims rewards when unstaking
     * @param amount Amount of stkTRU to unstake for TRU
     */
    function unstake(uint256 amount) external distribute update(msg.sender) nonReentrant {
        require(amount > 0, "StkTruToken: Cannot unstake 0");

        require(balanceOf[msg.sender] >= amount, "StkTruToken: Insufficient balance");
        require(unlockTime(msg.sender) <= block.timestamp, "StkTruToken: Stake on cooldown");

        _claim(tru);
        _claim(tfusd);

        uint256 amountToTransfer = amount.mul(stakeSupply).div(totalSupply);

        _burn(msg.sender, amount);
        stakeSupply = stakeSupply.sub(amountToTransfer);

        tru.transfer(msg.sender, amountToTransfer);

        emit Unstake(msg.sender, amount);
    }

    /**
     * @dev Initiate cooldown period
     */
    function cooldown() external {
        if (unlockTime(msg.sender) == type(uint256).max) {
            cooldowns[msg.sender] = block.timestamp;

            emit Cooldown(msg.sender, block.timestamp.add(cooldownTime));
        }
    }

    /**
     * @dev Withdraw TRU from the contract for liquidation
     * @param amount Amount to withdraw for liquidation
     */
    function withdraw(uint256 amount) external onlyLiquidator {
        stakeSupply = stakeSupply.sub(amount);
        tru.transfer(liquidator, amount);

        emit Withdraw(amount);
    }

    /**
     * @dev View function to get unlock time for an account
     * @param account Account to get unlock time for
     * @return Unlock time for account
     */
    function unlockTime(address account) public view returns (uint256) {
        if (cooldowns[account] == 0 || cooldowns[account].add(cooldownTime).add(unstakePeriodDuration) < block.timestamp) {
            return type(uint256).max;
        }
        return cooldowns[account].add(cooldownTime);
    }

    /**
     * @dev Give tfUSD as origination fee to stake.this
     * 50% are given immediately and 50% after `endTime` passes
     */
    function payFee(uint256 amount, uint256 endTime) external onlyWhitelistedPayers {
        require(endTime < type(uint64).max, "StkTruToken: time overflow");
        require(amount < type(uint96).max, "StkTruToken: amount overflow");

        require(tfusd.transferFrom(msg.sender, address(this), amount));
        undistributedTfusdRewards = undistributedTfusdRewards.add(amount.div(2));
        scheduledRewards.push(ScheduledTfUsdRewards({amount: uint96(amount.div(2)), timestamp: uint64(endTime)}));

        uint32 newIndex = findPositionForTimestamp(endTime);
        insertAt(newIndex, uint32(scheduledRewards.length) - 1);
    }

    /**
     * @dev Claim all rewards
     */
    function claim() external distribute update(msg.sender) {
        _claim(tru);
        _claim(tfusd);
    }

    /**
     * @dev Claim rewards for specific token
     * Allows account to claim specific token to save gas
     * @param token Token to claim rewards for
     */
    function claimRewards(IERC20 token) external distribute updateRewards(msg.sender, token) {
        require(token == tfusd || token == tru, "Token not supported for rewards");
        _claim(token);
    }

    /**
     * @dev View to estimate the claimable reward for an account
     * @param account Account to get claimable reward for
     * @param token Token to get rewards for
     * @return claimable rewards for account
     */
    function claimable(address account, IERC20 token) external view returns (uint256) {
        // estimate pending reward from distributor
        uint256 pending = token == tru ? distributor.nextDistribution() : 0;
        // calculate total rewards (including pending)
        uint256 newTotalFarmRewards = rewardBalance(token)
            .add(pending > MIN_DISTRIBUTED_AMOUNT ? pending : 0)
            .add(farmRewards[token].totalClaimedRewards)
            .mul(PRECISION);
        // calculate block reward
        uint256 totalBlockReward = newTotalFarmRewards.sub(farmRewards[token].totalFarmRewards);
        // calculate next cumulative reward per token
        uint256 nextCumulativeRewardPerToken = farmRewards[token].cumulativeRewardPerToken.add(totalBlockReward.div(totalSupply));
        // return claimable reward for this account
        return
            farmRewards[token].claimableReward[account].add(
                balanceOf[account]
                    .mul(nextCumulativeRewardPerToken.sub(farmRewards[token].previousCumulatedRewardPerToken[account]))
                    .div(PRECISION)
            );
    }

    /**
     * @dev Prior votes votes are calculated as priorVotes * stakedSupply / totalSupply
     * This dilutes voting power when TRU is liquidated
     * @param account Account to get current voting power for
     * @param blockNumber Block to get prior votes at
     * @return prior voting power for account and block
     */
    function getPriorVotes(address account, uint256 blockNumber) public override view returns (uint96) {
        uint96 votes = super.getPriorVotes(account, blockNumber);
        return safe96(stakeSupply.mul(votes).div(totalSupply), "StkTruToken: uint96 overflow");
    }

    /**
     * @dev Current votes are calculated as votes * stakedSupply / totalSupply
     * This dilutes voting power when TRU is liquidated
     * @param account Account to get current voting power for
     * @return voting power for account
     */
    function getCurrentVotes(address account) public override view returns (uint96) {
        uint96 votes = super.getCurrentVotes(account);
        return safe96(stakeSupply.mul(votes).div(totalSupply), "StkTruToken: uint96 overflow");
    }

    function decimals() public override pure returns (uint8) {
        return 8;
    }

    function rounding() public pure returns (uint8) {
        return 8;
    }

    function name() public override pure returns (string memory) {
        return "Staked TrueFi";
    }

    function symbol() public override pure returns (string memory) {
        return "stkTRU";
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override distribute update(sender) {
        updateClaimableRewards(tru, recipient);
        updateClaimableRewards(tfusd, recipient);
        super._transfer(sender, recipient, amount);
    }

    /**
     * @dev Internal claim function
     * Claim rewards for a specific ERC20 token
     * @param token Token to claim rewards for
     */
    function _claim(IERC20 token) internal {
        farmRewards[token].totalClaimedRewards = farmRewards[token].totalClaimedRewards.add(
            farmRewards[token].claimableReward[msg.sender]
        );
        uint256 rewardToClaim = farmRewards[token].claimableReward[msg.sender];
        farmRewards[token].claimableReward[msg.sender] = 0;
        require(token.transfer(msg.sender, rewardToClaim));
        emit Claim(msg.sender, token, rewardToClaim);
    }

    /**
     * @dev Get reward balance of this contract for a token
     * @param token Token to get reward balance for
     * @return Reward balance for token
     */
    function rewardBalance(IERC20 token) internal view returns (uint256) {
        if (token == tru) {
            return token.balanceOf(address(this)).sub(stakeSupply);
        }
        if (token == tfusd) {
            return token.balanceOf(address(this)).sub(undistributedTfusdRewards);
        }
        return 0;
    }

    /**
     * @dev Check if any scheduled rewards should be distributed
     */
    function distributeScheduledRewards() internal {
        uint32 index = nextDistributionIndex;
        while (index < scheduledRewards.length && scheduledRewards[sortedScheduledRewardIndices[index]].timestamp < block.timestamp) {
            undistributedTfusdRewards = undistributedTfusdRewards.sub(scheduledRewards[sortedScheduledRewardIndices[index]].amount);
            index++;
        }
        if (nextDistributionIndex != index) {
            nextDistributionIndex = index;
        }
    }

    /**
     * @dev Update rewards state for `token`
     */
    function updateTotalRewards(IERC20 token) internal {
        if (token == tfusd) {
            distributeScheduledRewards();
        }
        // calculate total rewards
        uint256 newTotalFarmRewards = rewardBalance(token).add(farmRewards[token].totalClaimedRewards).mul(PRECISION);
        if (newTotalFarmRewards == farmRewards[token].totalFarmRewards) {
            return;
        }
        // calculate block reward
        uint256 totalBlockReward = newTotalFarmRewards.sub(farmRewards[token].totalFarmRewards);
        // update farm rewards
        farmRewards[token].totalFarmRewards = newTotalFarmRewards;
        // if there are stakers
        if (totalSupply > 0) {
            farmRewards[token].cumulativeRewardPerToken = farmRewards[token].cumulativeRewardPerToken.add(
                totalBlockReward.div(totalSupply)
            );
        }
    }

    /**
     * @dev Update claimable rewards for a token and account
     * @param token Token to update claimable rewards for
     * @param user Account to update claimable rewards for
     */
    function updateClaimableRewards(IERC20 token, address user) internal {
        // update claimable reward for sender
        if (balanceOf[user] > 0) {
            farmRewards[token].claimableReward[user] = farmRewards[token].claimableReward[user].add(
                balanceOf[user]
                    .mul(farmRewards[token].cumulativeRewardPerToken.sub(farmRewards[token].previousCumulatedRewardPerToken[user]))
                    .div(PRECISION)
            );
        }
        // update previous cumulative for sender
        farmRewards[token].previousCumulatedRewardPerToken[user] = farmRewards[token].cumulativeRewardPerToken;
    }

    /**
     * @dev Find next distribution index given a timestamp
     * @param timestamp Timestamp to find next distribution index for
     */
    function findPositionForTimestamp(uint256 timestamp) internal view returns (uint32 i) {
        for (i = nextDistributionIndex; i < sortedScheduledRewardIndices.length; i++) {
            if (scheduledRewards[sortedScheduledRewardIndices[i]].timestamp > timestamp) {
                break;
            }
        }
    }

    /**
     * @dev internal function to insert distribution index in a sorted list
     * @param index Index to insert at
     * @param value Value at index
     */
    function insertAt(uint32 index, uint32 value) internal {
        sortedScheduledRewardIndices.push(0);
        for (uint32 j = uint32(sortedScheduledRewardIndices.length) - 1; j > index; j--) {
            sortedScheduledRewardIndices[j] = sortedScheduledRewardIndices[j - 1];
        }
        sortedScheduledRewardIndices[index] = value;
    }
}