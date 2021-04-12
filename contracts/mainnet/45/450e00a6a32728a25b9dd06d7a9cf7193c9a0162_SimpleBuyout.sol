/**
 *Submitted for verification at Etherscan.io on 2021-04-11
*/

// SPDX-License-Identifier: https://github.com/lendroidproject/protocol.2.0/blob/master/LICENSE.md


// File: @openzeppelin/contracts/GSN/Context.sol

pragma solidity ^0.7.0;

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

pragma solidity ^0.7.0;

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
    constructor () {
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

// File: @openzeppelin/contracts/math/SafeMath.sol

pragma solidity ^0.7.0;

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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

pragma solidity ^0.7.0;

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

// File: @openzeppelin/contracts/utils/Address.sol

pragma solidity ^0.7.0;

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
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
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

// File: @openzeppelin/contracts/token/ERC20/SafeERC20.sol

pragma solidity ^0.7.0;




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

// File: @openzeppelin/contracts/utils/Pausable.sol

pragma solidity ^0.7.0;


/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor () {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// File: contracts/heartbeat/Pacemaker.sol

pragma solidity 0.7.5;



/** @title Pacemaker
    @author Lendroid Foundation
    @notice Smart contract based on which various events in the Protocol take place
    @dev Audit certificate : https://certificate.quantstamp.com/view/lendroid-whalestreet
*/


// solhint-disable-next-line
abstract contract Pacemaker {

    using SafeMath for uint256;
    uint256 constant public HEART_BEAT_START_TIME = 1607212800;// 2020-12-06 00:00:00 UTC (UTC +00:00)
    uint256 constant public EPOCH_PERIOD = 8 hours;

    /**
        @notice Displays the epoch which contains the given timestamp
        @return uint256 : Epoch value
    */
    function epochFromTimestamp(uint256 timestamp) public pure returns (uint256) {
        if (timestamp > HEART_BEAT_START_TIME) {
            return timestamp.sub(HEART_BEAT_START_TIME).div(EPOCH_PERIOD).add(1);
        }
        return 0;
    }

    /**
        @notice Displays timestamp when a given epoch began
        @return uint256 : Epoch start time
    */
    function epochStartTimeFromTimestamp(uint256 timestamp) public pure returns (uint256) {
        if (timestamp <= HEART_BEAT_START_TIME) {
            return HEART_BEAT_START_TIME;
        } else {
            return HEART_BEAT_START_TIME.add((epochFromTimestamp(timestamp).sub(1)).mul(EPOCH_PERIOD));
        }
    }

    /**
        @notice Displays timestamp when a given epoch will end
        @return uint256 : Epoch end time
    */
    function epochEndTimeFromTimestamp(uint256 timestamp) public pure returns (uint256) {
        if (timestamp < HEART_BEAT_START_TIME) {
            return HEART_BEAT_START_TIME;
        } else if (timestamp == HEART_BEAT_START_TIME) {
            return HEART_BEAT_START_TIME.add(EPOCH_PERIOD);
        } else {
            return epochStartTimeFromTimestamp(timestamp).add(EPOCH_PERIOD);
        }
    }

    /**
        @notice Calculates current epoch value from the block timestamp
        @dev Calculates the nth 8-hour window frame since the heartbeat's start time
        @return uint256 : Current epoch value
    */
    function currentEpoch() public view returns (uint256) {
        return epochFromTimestamp(block.timestamp);// solhint-disable-line not-rely-on-time
    }

}

// File: contracts/IToken0.sol

pragma solidity 0.7.5;



/**
 * @dev Required interface of a Token0 compliant contract.
 */
interface IToken0 is IERC20 {
    function mint(address account, uint256 amount) external;

    function burn(uint256 amount) external;

    function burnFrom(address account, uint256 amount) external;
}

// File: contracts/IVault.sol

pragma solidity 0.7.5;
pragma abicoder v2;


/**
 * @dev Required interface of a Vault compliant contract.
 */
interface IVault {
    function lockVault() external;

    function unlockVault() external;

    function safeAddAsset(address[] calldata tokenAddresses, uint256[] calldata tokenIds,
            string[] calldata categories) external;

    function safeTransferAsset(uint256[] calldata assetIds) external;

    function escapeHatchERC721(address tokenAddress, uint256 tokenId) external;

    function setDecentralandOperator(address registryAddress, address operatorAddress,
        uint256 assetId) external;

    function transferOwnership(address newOwner) external;

    function totalAssetSlots() external view returns (uint256);

    function onERC721Received(address, uint256, bytes memory) external pure returns (bytes4);

}

// File: contracts/SimpleBuyout.sol

pragma solidity 0.7.5;


/** @title SimpleBuyout
    @author Lendroid Foundation
    @notice Smart contract representing a NFT bundle buyout
    @dev Audit certificate : Pending
*/
contract SimpleBuyout is Ownable, Pacemaker, Pausable {
    using SafeERC20 for IERC20;
    using SafeERC20 for IToken0;
    using SafeMath for uint256;
    using Address for address;

    enum BuyoutStatus { ENABLED, ACTIVE, REVOKED, ENDED }

    BuyoutStatus public status;
    IToken0 public token0;
    //// admin
    IERC20 public token2;
    uint256 public startThreshold;
    uint256[4] public epochs;// [startEpoch, endEpoch, durationInEpochs, bidIntervalInEpochs]
    //// vault
    IVault public vault;
    //// governance
    uint256 public stopThresholdPercent;
    uint256 public currentBidToken0Staked;
    mapping (address => uint256) public token0Staked;
    //// end user
    address public highestBidder;
    uint256[3] public highestBidValues;// [highestBid, highestToken0Bid, highestToken2Bid]
    //// bid and veto count
    uint256 public currentBidId;
    mapping (address => uint256) public lastVetoedBidId;
    //// redeem
    uint256 public redeemToken2Amount;
    //// prevent flash loan attacks on veto/withdrawVeto logic
    mapping (address => uint256) public lastVetoedBlockNumber;

    uint256 constant public MINIMUM_BID_PERCENTAGE_INCREASE_ON_VETO = 108;
    uint256 constant public MINIMUM_BID_TOKEN0_PERCENTAGE_REQUIRED = 1;

    // Events that will be emitted on changes.
    event HighestBidIncreased(address bidder, uint256 amount);
    event BuyoutStarted(address bidder, uint256 amount);
    event BuyoutRevoked(uint256 amount);
    event BuyoutEnded(address bidder, uint256 amount);

    // solhint-disable-next-line func-visibility
    constructor(address token0Address, address token2Address, address vaultAddress, uint256[4] memory uint256Values) {
        // input validations
        require(token0Address.isContract(), "{enableBuyout} : invalid token0Address");
        require(token2Address.isContract(), "{enableBuyout} : invalid token2Address");
        require(vaultAddress.isContract(), "{enableBuyout} : invalid vaultAddress");
        require(uint256Values[0] > 0, "{enableBuyout} : startThreshold cannot be zero");
        require(uint256Values[1] > 0, "{enableBuyout} : durationInEpochs cannot be zero");
        // uint256Values[1], aka, bidIntervalInEpochs can be zero, so no checks required.
        require(uint256Values[3] > 0 && uint256Values[3] <= 100,
            "{enableBuyout} : stopThresholdPercent should be between 1 and 100");
        // set values
        token0 = IToken0(token0Address);
        token2 = IERC20(token2Address);
        vault = IVault(vaultAddress);
        startThreshold = uint256Values[0];
        epochs[2] = uint256Values[1];
        epochs[3] = uint256Values[2];
        stopThresholdPercent = uint256Values[3];
        status = BuyoutStatus.ENABLED;
    }

    function togglePause(bool pause) external onlyOwner {
        if (pause) {
            _pause();
        } else {
            _unpause();
        }
    }

    function transferVaultOwnership(address newOwner) external onlyOwner whenPaused {
        require(newOwner != address(0), "{transferVaultOwnership} : invalid newOwner");
        // transfer ownership of Vault to newOwner
        vault.transferOwnership(newOwner);
    }

    function placeBid(uint256 totalBidAmount, uint256 token2Amount) external whenNotPaused {
        // verify buyout has not ended
        require(status != BuyoutStatus.ENDED, "{placeBid} : buyout has ended");
        // verify token0 and token2 amounts are sufficient to place bid
        require(totalBidAmount > startThreshold, "{placeBid} : totalBidAmount does not meet minimum threshold");
        require(token2.balanceOf(msg.sender) >= token2Amount, "{placeBid} : insufficient token2 balance");
        require(totalBidAmount > highestBidValues[0], "{placeBid} : there already is a higher bid");
        uint256 token0Amount = requiredToken0ToBid(totalBidAmount, token2Amount);
        require(token0.balanceOf(msg.sender) >= token0Amount, "{placeBid} : insufficient token0 balance");
        require(token0Amount >= token0.totalSupply().mul(MINIMUM_BID_TOKEN0_PERCENTAGE_REQUIRED).div(100),
            "{placeBid} : token0Amount should be at least 5% of token0 totalSupply");
        // increment bid number and reset veto count
        currentBidId = currentBidId.add(1);
        currentBidToken0Staked = 0;
        // update endEpoch
        if (status == BuyoutStatus.ACTIVE) {
            // already active
            require(currentEpoch() <= epochs[1], "{placeBid} : buyout end epoch has been surpassed");
            epochs[1] = currentEpoch().add(epochs[3]);
        } else {
            // activate buyout process if applicable
            status = BuyoutStatus.ACTIVE;
            epochs[1] = currentEpoch().add(epochs[2]);
        }
        // set startEpoch
        epochs[0] = currentEpoch();
        // return highest bid to previous bidder
        if (highestBidValues[1] > 0) {
            token0.safeTransfer(highestBidder, highestBidValues[1]);
        }
        if (highestBidValues[2] > 0) {
            token2.safeTransfer(highestBidder, highestBidValues[2]);
        }
        // set sender as highestBidder and totalBidAmount as highestBidValues[0]
        highestBidder = msg.sender;
        highestBidValues[0] = totalBidAmount;
        highestBidValues[1] = token0Amount;
        highestBidValues[2] = token2Amount;
        // transfer token0 and token2 to this contract
        token0.safeTransferFrom(msg.sender, address(this), token0Amount);
        token2.safeTransferFrom(msg.sender, address(this), token2Amount);
        // send notification
        emit HighestBidIncreased(msg.sender, totalBidAmount);
    }

    function veto(uint256 token0Amount) external whenNotPaused {
        require(token0Amount > 0, "{veto} : token0Amount cannot be zero");
        token0Staked[msg.sender] = token0Staked[msg.sender].add(token0Amount);
        uint256 vetoAmount = lastVetoedBidId[msg.sender] == currentBidId ? token0Amount : token0Staked[msg.sender];
        _veto(msg.sender, vetoAmount);
        token0.safeTransferFrom(msg.sender, address(this), token0Amount);
    }

    function extendVeto() external whenNotPaused {
        uint256 token0Amount = token0Staked[msg.sender];
        require(token0Amount > 0, "{extendVeto} : no staked token0Amount");
        require(lastVetoedBidId[msg.sender] != currentBidId, "{extendVeto} : already vetoed");
        _veto(msg.sender, token0Amount);
    }

    function withdrawStakedToken0(uint256 token0Amount) external {
        require(lastVetoedBlockNumber[msg.sender] < block.number, "{withdrawStakedToken0} : Flash attack!");
        require(token0Amount > 0, "{withdrawStakedToken0} : token0Amount cannot be zero");
        require(token0Staked[msg.sender] >= token0Amount,
            "{withdrawStakedToken0} : token0Amount cannot exceed staked amount");
        // ensure Token0 cannot be unstaked if users veto on current bid has not expired
        if ((status == BuyoutStatus.ACTIVE) && (currentEpoch() <= epochs[1])) {
            // already active
            require(lastVetoedBidId[msg.sender] != currentBidId,
                "{withdrawStakedToken0} : cannot unstake until veto on current bid expires");
        }
        token0Staked[msg.sender] = token0Staked[msg.sender].sub(token0Amount);
        token0.safeTransfer(msg.sender, token0Amount);
    }

    function endBuyout() external whenNotPaused {
        // solhint-disable-next-line not-rely-on-time
        require(currentEpoch() > epochs[1], "{endBuyout} : end epoch has not yet been reached");
        require(status != BuyoutStatus.ENDED, "{endBuyout} : buyout has already ended");
        require(highestBidder != address(0), "{endBuyout} : buyout does not have highestBidder");
        // additional safety checks
        require(((highestBidValues[1] > 0) || (highestBidValues[2] > 0)),
            "{endBuyout} : highestBidder deposits cannot be 0");
        // set status
        status = BuyoutStatus.ENDED;
        redeemToken2Amount = highestBidValues[2];
        highestBidValues[2] = 0;
        // burn token0Amount
        if (highestBidValues[1] > 0) {
            token0.burn(highestBidValues[1]);
        }
        // transfer ownership of Vault to highestBidder
        vault.transferOwnership(highestBidder);

        emit BuyoutEnded(highestBidder, highestBidValues[0]);
    }

    function withdrawBid() external whenPaused {
        require(highestBidder == msg.sender, "{withdrawBid} : sender is not highestBidder");
        _resetHighestBidDetails();

    }

    function redeem(uint256 token0Amount) external {
        require(status == BuyoutStatus.ENDED, "{redeem} : redeem has not yet been enabled");
        require(token0.balanceOf(msg.sender) >= token0Amount, "{redeem} : insufficient token0 amount");
        require(token0Amount > 0, "{redeem} : token0 amount cannot be zero");
        uint256 token2Amount = token2AmountRedeemable(token0Amount);
        redeemToken2Amount = redeemToken2Amount.sub(token2Amount);
        // burn token0Amount
        token0.burnFrom(msg.sender, token0Amount);
        // send token2Amount
        token2.safeTransfer(msg.sender, token2Amount);
    }

    function token2AmountRedeemable(uint256 token0Amount) public view returns (uint256) {
        return token0Amount.mul(redeemToken2Amount).div(token0.totalSupply());
    }

    function requiredToken0ToBid(uint256 totalBidAmount, uint256 token2Amount) public view returns (uint256) {
        uint256 token0Supply = token0.totalSupply();
        require(token2Amount <= totalBidAmount, "{requiredToken0ToBid} : token2Amount cannot exceed totalBidAmount");
        // token2Amount = threshold * ( (totalToken0Supply - token0Amount) / totalToken0Supply )
        return token0Supply
            .mul(
                totalBidAmount
                .sub(token2Amount)
            ).div(totalBidAmount);
    }

    function _resetHighestBidDetails() internal {
        uint256 token0Amount = highestBidValues[1];
        uint256 token2Amount = highestBidValues[2];
        if (token0Amount > 0) {
            token0.safeTransfer(highestBidder, token0Amount);
        }
        if (token2Amount > 0) {
            token2.safeTransfer(highestBidder, token2Amount);
        }
        // reset highestBidder
        highestBidder = address(0);
        // reset highestBidValues
        highestBidValues[0] = 0;
        highestBidValues[1] = 0;
        highestBidValues[2] = 0;
    }

    function _veto(address sender, uint256 token0Amount) internal {
        // verify buyout has not ended
        require((
            (status == BuyoutStatus.ACTIVE) && (currentEpoch() >= epochs[0]) && (currentEpoch() <= epochs[1])
        ), "{_veto} : buyout is not active");
        lastVetoedBlockNumber[sender] = block.number;
        lastVetoedBidId[sender] = currentBidId;
        uint256 updatedCurrentBidToken0Staked = currentBidToken0Staked.add(token0Amount);
        if (updatedCurrentBidToken0Staked < stopThresholdPercent.mul(token0.totalSupply().div(100))) {
            currentBidToken0Staked = updatedCurrentBidToken0Staked;
        } else {
            currentBidToken0Staked = 0;
            // increase startThreshold by 8% of last bid
            startThreshold = highestBidValues[0].mul(MINIMUM_BID_PERCENTAGE_INCREASE_ON_VETO).div(100);
            // reset endEpoch
            epochs[1] = 0;
            // set status
            status = BuyoutStatus.REVOKED;
            _resetHighestBidDetails();
            emit BuyoutRevoked(updatedCurrentBidToken0Staked);
        }
    }

}