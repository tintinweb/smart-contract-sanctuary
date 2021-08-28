/**
 *Submitted for verification at polygonscan.com on 2021-08-28
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

// File: @openzeppelin/contracts/GSN/Context.sol

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

// File: @openzeppelin/contracts/math/SafeMath.sol

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

// File: contracts/interfaces/IRelayRecipient.sol

/**
 * a contract must implement this interface in order to support relayed transaction.
 * It is better to inherit the BaseRelayRecipient as its implementation.
 */
abstract contract IRelayRecipient {

    /**
     * return if the forwarder is trusted to forward relayed transactions to us.
     * the forwarder is required to verify the sender's signature, and verify
     * the call is not a replay.
     */
    function isTrustedForwarder(address forwarder) public virtual view returns(bool);

    /**
     * return the sender of this call.
     * if the call came through our trusted forwarder, then the real sender is appended as the last 20 bytes
     * of the msg.data.
     * otherwise, return `msg.sender`
     * should be used in the contract anywhere instead of msg.sender
     */
    function _msgSender() internal virtual view returns (address payable);

    function versionRecipient() external virtual view returns (string memory);
}

// File: contracts/common/BaseRelayRecipient.sol

/**
 * A base contract to be inherited by any contract that want to receive relayed transactions
 * A subclass must use "_msgSender()" instead of "msg.sender"
 */
abstract contract BaseRelayRecipient is IRelayRecipient {

    /*
     * Forwarder we accept calls from
     */
    function _trustedForwarder() internal virtual view returns(address);

    /*
     * require a function to be called through GSN only
     */
    modifier trustedForwarderOnly() {
        require(msg.sender == _trustedForwarder(), "Function can only be called through the trusted Forwarder");
        _;
    }

    function isTrustedForwarder(address forwarder) public override view returns(bool) {
        return forwarder == _trustedForwarder();
    }

    /**
     * return the sender of this call.
     * if the call came through our trusted forwarder, return the original sender.
     * otherwise, return `msg.sender`.
     * should be used in the contract anywhere instead of msg.sender
     */
    function _msgSender() internal override virtual view returns (address payable ret) {
        if (msg.data.length >= 24 && isTrustedForwarder(msg.sender)) {
            // At this point we know that the sender is a trusted forwarder,
            // so we trust that the last bytes of msg.data are the verified sender address.
            // extract sender address from the end of msg.data
            assembly {
                ret := shr(96,calldataload(sub(calldatasize(),20)))
            }
        } else {
            return msg.sender;
        }
    }
}

// File: contracts/interfaces/IMigratable.sol

interface IMigratable {
    function approveMigration(IMigratable migrateTo_) external;
    function onMigration(address who_, uint256 amount_, bytes memory data_) external;
}

// File: contracts/common/Migratable.sol

abstract contract Migratable is IMigratable {

    IMigratable public migrateTo;

    function _migrationCaller() internal virtual view returns(address);

    function approveMigration(IMigratable migrateTo_) external override {
        require(msg.sender == _migrationCaller(), "Only _migrationCaller() can call");
        require(address(migrateTo_) != address(0) &&
                address(migrateTo_) != address(this), "Invalid migrateTo_");
        migrateTo = migrateTo_;
    }

    function onMigration(address who_, uint256 amount_, bytes memory data_) external virtual override {
    }
}

// File: contracts/common/NonReentrancy.sol

contract NonReentrancy {

    uint256 private unlocked = 1;

    modifier lock() {
        require(unlocked == 1, 'Tidal: LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }
}

// File: contracts/common/WeekManaged.sol

abstract contract WeekManaged {

    uint256 public offset = 4 days;

    function getCurrentWeek() public view returns(uint256) {
        return (now + offset) / (7 days);
    }

    function getNow() public view returns(uint256) {
        return now;
    }

    function getUnlockWeek() public view returns(uint256) {
        return getCurrentWeek() + 2;
    }

    function getUnlockTime(uint256 time_) public view returns(uint256) {
        require(time_ + offset > (7 days), "Time not large enough");
        return ((time_ + offset) / (7 days) + 2) * (7 days) - offset;
    }
}

// File: contracts/interfaces/IAssetManager.sol

interface IAssetManager {
    function getCategoryLength() external view returns(uint8);
    function getAssetLength() external view returns(uint256);
    function getAssetToken(uint16 index_) external view returns(address);
    function getAssetCategory(uint16 index_) external view returns(uint8);
    function getIndexesByCategory(uint8 category_, uint256 categoryIndex_) external view returns(uint16);
    function getIndexesByCategoryLength(uint8 category_) external view returns(uint256);
}

// File: contracts/interfaces/IBuyer.sol

interface IBuyer is IMigratable {
    function premiumForGuarantor(uint16 assetIndex_) external view returns(uint256);
    function premiumForSeller(uint16 assetIndex_) external view returns(uint256);
    function weekToUpdate() external view returns(uint256);
    function currentSubscription(uint16 assetIndex_) external view returns(uint256);
    function futureSubscription(uint16 assetIndex_) external view returns(uint256);
    function assetUtilization(uint16 assetIndex_) external view returns(uint256);
    function isUserCovered(address who_) external view returns(bool);
}

// File: contracts/interfaces/IGuarantor.sol

interface IGuarantor is IMigratable {
    function updateBonus(uint16 assetIndex_, uint256 amount_) external;
    function update(address who_) external;
    function startPayout(uint16 assetIndex_, uint256 payoutId_) external;
    function setPayout(uint16 assetIndex_, uint256 payoutId_, address toAddress_, uint256 total_) external;
}

// File: contracts/interfaces/IPremiumCalculator.sol

interface IPremiumCalculator {
    function getPremiumRate(uint16 assetIndex_) external view returns(uint256);
}

// File: contracts/interfaces/IRegistry.sol

interface IRegistry {

    function PERCENTAGE_BASE() external pure returns(uint256);
    function UTILIZATION_BASE() external pure returns(uint256);
    function PREMIUM_BASE() external pure returns(uint256);
    function UNIT_PER_SHARE() external pure returns(uint256);

    function buyer() external view returns(address);
    function seller() external view returns(address);
    function guarantor() external view returns(address);
    function staking() external view returns(address);
    function bonus() external view returns(address);

    function tidalToken() external view returns(address);
    function baseToken() external view returns(address);
    function assetManager() external view returns(address);
    function premiumCalculator() external view returns(address);
    function platform() external view returns(address);

    function guarantorPercentage() external view returns(uint256);
    function platformPercentage() external view returns(uint256);

    function depositPaused() external view returns(bool);

    function stakingWithdrawWaitTime() external view returns(uint256);

    function governor() external view returns(address);
    function committee() external view returns(address);

    function trustedForwarder() external view returns(address);
}

// File: contracts/interfaces/ISeller.sol

interface ISeller is IMigratable {
    function assetBalance(uint16 assetIndex_) external view returns(uint256);
    function updateBonus(uint16 assetIndex_, uint256 amount_) external;
    function update(address who_) external;
    function isAssetLocked(uint16 assetIndex_) external view returns(bool);
    function startPayout(uint16 assetIndex_, uint256 payoutId_) external;
    function setPayout(uint16 assetIndex_, uint256 payoutId_, address toAddress_, uint256 total_) external;
}

// File: contracts/Buyer.sol

// This contract is owned by Timelock.
contract Buyer is IBuyer, Ownable, WeekManaged, Migratable, NonReentrancy, BaseRelayRecipient {

    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    string public override versionRecipient = "1.0.0";

    IRegistry public registry;

    struct UserInfo {
        uint256 balance;
        uint256 weekBegin;  // The week the coverage begin
        uint256 weekEnd;  // The week the coverage end
        uint256 weekUpdated;  // The week that balance was updated
    }

    mapping(address => UserInfo) public userInfoMap;

    // assetIndex => amount
    mapping(uint16 => uint256) public override currentSubscription;

    // assetIndex => amount
    mapping(uint16 => uint256) public override futureSubscription;

    // assetIndex => utilization
    mapping(uint16 => uint256) public override assetUtilization;

    // assetIndex => total
    mapping(uint16 => uint256) public override premiumForGuarantor;

    // assetIndex => total
    mapping(uint16 => uint256) public override premiumForSeller;

    // Should be claimed immediately in the next week.
    // assetIndex => total
    mapping(uint16 => uint256) public premiumToRefund;

    uint256 public override weekToUpdate;

    // who => assetIndex + 1
    mapping(address => uint16) public buyerAssetIndexPlusOne;

    event Update(address indexed who_);
    event Deposit(address indexed who_, uint256 amount_);
    event Withdraw(address indexed who_, uint256 amount_);
    event Subscribe(address indexed who_, uint16 indexed assetIndex_, uint256 amount_);
    event Unsubscribe(address indexed who_, uint16 indexed assetIndex_, uint256 amount_);

    constructor (IRegistry registry_) public {
        registry = registry_;
    }

    function _msgSender() internal override(Context, BaseRelayRecipient) view returns (address payable) {
        return BaseRelayRecipient._msgSender();
    }

    function _trustedForwarder() internal override view returns(address) {
        return registry.trustedForwarder();
    }

    function _migrationCaller() internal override view returns(address) {
        return address(registry);
    }

    function migrate() external lock {
        uint256 balance = userInfoMap[_msgSender()].balance;

        require(address(migrateTo) != address(0), "Destination not set");
        require(balance > 0, "No balance");

        userInfoMap[_msgSender()].balance = 0;

        IERC20(registry.baseToken()).safeTransfer(address(migrateTo), balance);
        migrateTo.onMigration(_msgSender(), balance, "");
    }

    // Set buyer asset index. When 0, it's cleared.
    function setBuyerAssetIndexPlusOne(address who_, uint16 assetIndexPlusOne_) external onlyOwner {
        buyerAssetIndexPlusOne[who_] = assetIndexPlusOne_;
    }

    // Get buyer asset index
    function getBuyerAssetIndex(address who_) public view returns(uint16) {
        require(buyerAssetIndexPlusOne[who_] > 0, "No asset index");
        return buyerAssetIndexPlusOne[who_] - 1;
    }

    // Has buyer asset index
    function hasBuyerAssetIndex(address who_) public view returns(bool) {
        return buyerAssetIndexPlusOne[who_] > 0;
    }

    function getPremiumRate(uint16 assetIndex_) public view returns(uint256) {
        return IPremiumCalculator(registry.premiumCalculator()).getPremiumRate(
            assetIndex_);
    }

    function isUserCovered(address who_) public override view returns(bool) {
        return userInfoMap[who_].weekEnd == getCurrentWeek();
    }

    function getBalance(address who_) external view returns(uint256) {
        return userInfoMap[who_].balance;
    }

    function _maybeRefundOverSubscribed(uint16 assetIndex_, uint256 sellerAssetBalance_) private {
        // Maybe refund to buyer if over-subscribed in the past week, with past premium rate (assetUtilization).
        if (currentSubscription[assetIndex_] > sellerAssetBalance_) {
            premiumToRefund[assetIndex_] = currentSubscription[assetIndex_].sub(sellerAssetBalance_).mul(
                getPremiumRate(assetIndex_)).div(registry.PREMIUM_BASE());

            // Reduce currentSubscription (not too late).
            currentSubscription[assetIndex_] = sellerAssetBalance_;
        } else {
            // No need to refund.
            premiumToRefund[assetIndex_] = 0;
        }
    }

    function _calculateAssetUtilization(uint16 assetIndex_, uint256 sellerAssetBalance_) private {
        // Calculate new assetUtilization from currentSubscription and sellerAssetBalance
        if (sellerAssetBalance_ == 0) {
            assetUtilization[assetIndex_] = registry.UTILIZATION_BASE();
        } else {
            assetUtilization[assetIndex_] = currentSubscription[assetIndex_] * registry.UTILIZATION_BASE() / sellerAssetBalance_;
        }

        // Premium rate also changed.
    }

    // Called every week.
    function beforeUpdate() external lock {
        uint256 currentWeek = getCurrentWeek();

        require(weekToUpdate < currentWeek, "Already called");

        if (weekToUpdate > 0) {
            uint256 totalForGuarantor = 0;
            uint256 totalForSeller = 0;
            uint256 feeForPlatform = 0;

            // To preserve last week's data before update buyers.
            for (uint16 index = 0;
                    index < IAssetManager(registry.assetManager()).getAssetLength();
                    ++index) {
                uint256 sellerAssetBalance = ISeller(registry.seller()).assetBalance(index);
                _maybeRefundOverSubscribed(index, sellerAssetBalance);
                _calculateAssetUtilization(index, sellerAssetBalance);

                uint256 premiumOfAsset = currentSubscription[index].mul(
                    getPremiumRate(index)).div(registry.PREMIUM_BASE());

                feeForPlatform = feeForPlatform.add(
                    premiumOfAsset.mul(registry.platformPercentage()).div(registry.PERCENTAGE_BASE()));

                if (IAssetManager(registry.assetManager()).getAssetToken(index) == address(0)) {
                    // When guarantor pool doesn't exist.
                    premiumForGuarantor[index] = 0;
                    premiumForSeller[index] = premiumOfAsset.mul(
                        registry.PERCENTAGE_BASE().sub(
                            registry.platformPercentage())).div(registry.PERCENTAGE_BASE());
                } else {
                    // When guarantor pool exists.
                    premiumForGuarantor[index] = premiumOfAsset.mul(
                        registry.guarantorPercentage()).div(registry.PERCENTAGE_BASE());
                    totalForGuarantor = totalForGuarantor.add(premiumForGuarantor[index]);

                    premiumForSeller[index] = premiumOfAsset.mul(
                        registry.PERCENTAGE_BASE().sub(registry.guarantorPercentage()).sub(
                            registry.platformPercentage())).div(registry.PERCENTAGE_BASE());
                }

                totalForSeller = totalForSeller.add(premiumForSeller[index]);
            }

            IERC20(registry.baseToken()).safeTransfer(registry.platform(), feeForPlatform);
            IERC20(registry.baseToken()).safeApprove(registry.guarantor(), 0);
            IERC20(registry.baseToken()).safeApprove(registry.guarantor(), totalForGuarantor);
            IERC20(registry.baseToken()).safeApprove(registry.seller(), 0);
            IERC20(registry.baseToken()).safeApprove(registry.seller(), totalForSeller);
        }

        weekToUpdate = currentWeek;
    }

    // Called for every user every week.
    function update(address who_) external {
        uint256 currentWeek = getCurrentWeek();

        require(hasBuyerAssetIndex(who_), "not whitelisted buyer");
        uint16 buyerAssetIndex = getBuyerAssetIndex(who_);

        require(currentWeek == weekToUpdate, "Not ready to update");
        require(userInfoMap[who_].weekUpdated < currentWeek, "Already updated");

        // Maybe refund to user.
        userInfoMap[who_].balance = userInfoMap[who_].balance.add(premiumToRefund[buyerAssetIndex]);

        if (ISeller(registry.seller()).isAssetLocked(buyerAssetIndex)) {
            // Stops user's current and future subscription.
            currentSubscription[buyerAssetIndex] = 0;
            futureSubscription[buyerAssetIndex] = 0;
        } else {
            // Get per user premium
            uint256 premium = futureSubscription[buyerAssetIndex].mul(
                getPremiumRate(buyerAssetIndex)).div(registry.PREMIUM_BASE());

            if (userInfoMap[who_].balance >= premium) {
                userInfoMap[who_].balance = userInfoMap[who_].balance.sub(premium);

                if (userInfoMap[who_].weekBegin == 0 ||
                        userInfoMap[who_].weekEnd < userInfoMap[who_].weekUpdated) {
                    userInfoMap[who_].weekBegin = currentWeek;
                }

                userInfoMap[who_].weekEnd = currentWeek;

                if (futureSubscription[buyerAssetIndex] > 0) {
                    currentSubscription[buyerAssetIndex] = futureSubscription[buyerAssetIndex];
                } else if (currentSubscription[buyerAssetIndex] > 0) {
                    currentSubscription[buyerAssetIndex] = 0;
                }
            } else {
                // Stops user's current and future subscription.
                currentSubscription[buyerAssetIndex] = 0;
                futureSubscription[buyerAssetIndex] = 0;
            }
        }

        userInfoMap[who_].weekUpdated = currentWeek;  // This week.

        emit Update(who_);
    }

    // Deposit
    function deposit(uint256 amount_) external lock {
        require(hasBuyerAssetIndex(_msgSender()), "not whitelisted buyer");

        IERC20(registry.baseToken()).safeTransferFrom(_msgSender(), address(this), amount_);
        userInfoMap[_msgSender()].balance = userInfoMap[_msgSender()].balance.add(amount_);

        emit Deposit(_msgSender(), amount_);
    }

    // Withdraw
    function withdraw(uint256 amount_) external lock {
        require(userInfoMap[_msgSender()].balance >= amount_, "not enough balance");
        IERC20(registry.baseToken()).safeTransfer(_msgSender(), amount_);
        userInfoMap[_msgSender()].balance = userInfoMap[_msgSender()].balance.sub(amount_);

        emit Withdraw(_msgSender(), amount_);
    }

    function subscribe(uint16 assetIndex_, uint256 amount_) external {
        require(getBuyerAssetIndex(_msgSender()) == assetIndex_, "not whitelisted buyer and assetIndex");

        futureSubscription[assetIndex_] = futureSubscription[assetIndex_].add(amount_);

        emit Subscribe(_msgSender(), assetIndex_, amount_);
    }

    function unsubscribe(uint16 assetIndex_, uint256 amount_) external {
        require(getBuyerAssetIndex(_msgSender()) == assetIndex_, "not whitelisted buyer and assetIndex");

        futureSubscription[assetIndex_] = futureSubscription[assetIndex_].sub(amount_);

        emit Unsubscribe(_msgSender(), assetIndex_, amount_);
    }
}