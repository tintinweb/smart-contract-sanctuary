// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";

uint256 constant UNLOCKED_TRANSACTIONS_RING_SIZE = 100;

contract AFarmBridge is Ownable {
    using SafeERC20 for IERC20;

    string public networkName;
    address public immutable aFarmToken;
    address public custodian;

    bool public paused = false;

    bytes32[] public unlockedTransactions;
    uint8 private unlockedTransactionsPos;

    event BridgeLock(uint256 amount);

    constructor(string memory _networkName, address _aFarmTokenAddress) {
        networkName = _networkName;
        aFarmToken = _aFarmTokenAddress;
        custodian = msg.sender;

        unlockedTransactionsPos = 0;
        unlockedTransactions = new bytes32[](UNLOCKED_TRANSACTIONS_RING_SIZE);
    }

    function lockedAmount() public view returns (uint256) {
        return IERC20(aFarmToken).balanceOf(address(this));
    }

    function lock(uint256 aFarmTokenAmount) public {
        require(!paused, "paused");
        require(msg.sender == custodian, "only custodian");

        IERC20(aFarmToken).safeTransferFrom(custodian, address(this), aFarmTokenAmount);
        emit BridgeLock(aFarmTokenAmount);
    }

    function unlock(uint256 aFarmTokenAmount, bytes32 extranetTx) public onlyOwner uniqueTx(extranetTx) {
        IERC20(aFarmToken).safeTransfer(custodian, aFarmTokenAmount);
    }

    function setCustodian(address _custodian) public onlyOwner {
        custodian = _custodian;
    }

    function pause() public onlyOwner {
        paused = true;
    }

    function unpause() public onlyOwner {
        paused = false;
    }

    modifier uniqueTx(bytes32 _tx) {
        for (uint8 i=0; i<UNLOCKED_TRANSACTIONS_RING_SIZE; i++) {
            if (unlockedTransactions[i] == _tx) {
                revert("tx already minted");
            }
        }

        unlockedTransactions[unlockedTransactionsPos] = _tx;

        unlockedTransactionsPos++;

        if (unlockedTransactionsPos == UNLOCKED_TRANSACTIONS_RING_SIZE) {
            unlockedTransactionsPos = 0;
        }

        _;
    }

    function shutdown() public onlyOwner {
        uint256 aFarmTokenLockedAmount = lockedAmount();
        if (aFarmTokenLockedAmount > 0) {
            IERC20(aFarmToken).safeTransferFrom(address(this), custodian, aFarmTokenLockedAmount);
        }

        selfdestruct(payable(custodian));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

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
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
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
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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
        return verifyCallResult(success, returndata, errorMessage);
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
        return verifyCallResult(success, returndata, errorMessage);
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
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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

import "@openzeppelin/contracts/interfaces/IERC20.sol";

interface IRewarder {
    function onIncentReward(uint256 pid, address user, address recipient, uint256 incentAmount, uint256 newLpAmount) external;
    function pendingTokens(uint256 pid, address user, uint256 incentAmount) external view returns (IERC20[] memory, uint256[] memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../libraries/IRewarder.sol";


contract RewarderMock is IRewarder {
    using SafeERC20 for IERC20;

    uint256 private immutable rewardMultiplier;
    IERC20 private immutable rewardToken;
    uint256 private constant REWARD_TOKEN_DIVISOR = 1e18;
    address private immutable MASTERCHEF_V2;

    constructor (uint256 _rewardMultiplier, IERC20 _rewardToken, address _MASTERCHEF_V2) {
        rewardMultiplier = _rewardMultiplier;
        rewardToken = _rewardToken;
        MASTERCHEF_V2 = _MASTERCHEF_V2;
    }

    function onIncentReward (uint256, address user, address to, uint256 incentAmount, uint256) onlyMCV2 override external {
        uint256 pendingReward = incentAmount * rewardMultiplier / REWARD_TOKEN_DIVISOR;
        uint256 rewardBal = rewardToken.balanceOf(address(this));
        if (pendingReward > rewardBal) {
            rewardToken.safeTransfer(to, rewardBal);
        } else {
            rewardToken.safeTransfer(to, pendingReward);
        }
    }

    function pendingTokens(uint256 pid, address user, uint256 incentAmount) override external view returns (IERC20[] memory rewardTokens, uint256[] memory rewardAmounts) {
        IERC20[] memory _rewardTokens = new IERC20[](1);
        _rewardTokens[0] = (rewardToken);
        uint256[] memory _rewardAmounts = new uint256[](1);
        _rewardAmounts[0] = incentAmount * rewardMultiplier / REWARD_TOKEN_DIVISOR;
        return (_rewardTokens, _rewardAmounts);
    }

    modifier onlyMCV2 {
        require(
            msg.sender == MASTERCHEF_V2,
            "Only MCV2 can call this function."
        );
        _;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (finance/VestingWallet.sol)
pragma solidity ^0.8.0;

import "../token/ERC20/utils/SafeERC20.sol";
import "../utils/Address.sol";
import "../utils/Context.sol";
import "../utils/math/Math.sol";

/**
 * @title VestingWallet
 * @dev This contract handles the vesting of Eth and ERC20 tokens for a given beneficiary. Custody of multiple tokens
 * can be given to this contract, which will release the token to the beneficiary following a given vesting schedule.
 * The vesting schedule is customizable through the {vestedAmount} function.
 *
 * Any token transferred to this contract will follow the vesting schedule as if they were locked from the beginning.
 * Consequently, if the vesting has already started, any amount of tokens sent to this contract will (at least partly)
 * be immediately releasable.
 */
contract VestingWallet is Context {
    event EtherReleased(uint256 amount);
    event ERC20Released(address indexed token, uint256 amount);

    uint256 private _released;
    mapping(address => uint256) private _erc20Released;
    address private immutable _beneficiary;
    uint64 private immutable _start;
    uint64 private immutable _duration;

    /**
     * @dev Set the beneficiary, start timestamp and vesting duration of the vesting wallet.
     */
    constructor(
        address beneficiaryAddress,
        uint64 startTimestamp,
        uint64 durationSeconds
    ) {
        require(beneficiaryAddress != address(0), "VestingWallet: beneficiary is zero address");
        _beneficiary = beneficiaryAddress;
        _start = startTimestamp;
        _duration = durationSeconds;
    }

    /**
     * @dev The contract should be able to receive Eth.
     */
    receive() external payable virtual {}

    /**
     * @dev Getter for the beneficiary address.
     */
    function beneficiary() public view virtual returns (address) {
        return _beneficiary;
    }

    /**
     * @dev Getter for the start timestamp.
     */
    function start() public view virtual returns (uint256) {
        return _start;
    }

    /**
     * @dev Getter for the vesting duration.
     */
    function duration() public view virtual returns (uint256) {
        return _duration;
    }

    /**
     * @dev Amount of eth already released
     */
    function released() public view virtual returns (uint256) {
        return _released;
    }

    /**
     * @dev Amount of token already released
     */
    function released(address token) public view virtual returns (uint256) {
        return _erc20Released[token];
    }

    /**
     * @dev Release the native token (ether) that have already vested.
     *
     * Emits a {TokensReleased} event.
     */
    function release() public virtual {
        uint256 releasable = vestedAmount(uint64(block.timestamp)) - released();
        _released += releasable;
        emit EtherReleased(releasable);
        Address.sendValue(payable(beneficiary()), releasable);
    }

    /**
     * @dev Release the tokens that have already vested.
     *
     * Emits a {TokensReleased} event.
     */
    function release(address token) public virtual {
        uint256 releasable = vestedAmount(token, uint64(block.timestamp)) - released(token);
        _erc20Released[token] += releasable;
        emit ERC20Released(token, releasable);
        SafeERC20.safeTransfer(IERC20(token), beneficiary(), releasable);
    }

    /**
     * @dev Calculates the amount of ether that has already vested. Default implementation is a linear vesting curve.
     */
    function vestedAmount(uint64 timestamp) public view virtual returns (uint256) {
        return _vestingSchedule(address(this).balance + released(), timestamp);
    }

    /**
     * @dev Calculates the amount of tokens that has already vested. Default implementation is a linear vesting curve.
     */
    function vestedAmount(address token, uint64 timestamp) public view virtual returns (uint256) {
        return _vestingSchedule(IERC20(token).balanceOf(address(this)) + released(token), timestamp);
    }

    /**
     * @dev Virtual implementation of the vesting formula. This returns the amout vested, as a function of time, for
     * an asset given its total historical allocation.
     */
    function _vestingSchedule(uint256 totalAllocation, uint64 timestamp) internal view virtual returns (uint256) {
        if (timestamp < start()) {
            return 0;
        } else if (timestamp > start() + duration()) {
            return totalAllocation;
        } else {
            return (totalAllocation * (timestamp - start())) / duration();
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

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
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
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
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
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
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
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

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
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
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TestToken is ERC20 {
    uint8 private immutable _decimals;

    constructor(string memory symbol, uint8 __decimals) ERC20("Test token", symbol) {
        _decimals = __decimals;
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    function mint(uint256 amount) public {
        _mint(msg.sender, amount);
    }

    function mintTo(address account, uint256 amount) public {
        _mint(account, amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ERC20Mock is ERC20 {
    constructor(
        string memory name,
        string memory symbol,
        uint256 supply
    ) public ERC20(name, symbol) {
        _mint(msg.sender, supply);
    }

    function mint(address recipient, uint256 amount) public {
        _mint(recipient, amount);
    }
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./SignatureValidator.sol";

uint256 constant MINTED_TRANSACTIONS_RING_SIZE = 100;

contract ExtranetToken is ERC20, Ownable, SignatureValidator {
    using SafeERC20 for IERC20;

    address public immutable quoteToken;
    address public aFarmBridge;
    address public custodian;
    address public feeTo;
    address public tradeSigner;

    bool public isPaused = false;

    bytes32[] public mintedTransactions;
    uint8 private mintedTransactionsPos;

    uint8 public constant withdrawalFeePercentDecimals = 6;
    uint256 public withdrawalFeePercent = 0;

    uint8 private immutable _decimals;

    event BridgeBurn(uint256 amount);
    event Invest(uint256 aFarmTokenAmount, uint256 quoteTokenAmount);
    event Withdraw(uint256 aFarmTokenAmount, uint256 quoteTokenAmount);

    constructor(string memory name, string memory symbol, uint8 aFarmDecimals, address quoteTokenAddress, address aFarmBridgeAddress) ERC20(name, symbol) {
        quoteToken = quoteTokenAddress;
        aFarmBridge = aFarmBridgeAddress;

        _decimals = aFarmDecimals;

        mintedTransactionsPos = 0;
        mintedTransactions = new bytes32[](MINTED_TRANSACTIONS_RING_SIZE);

        custodian = msg.sender;
        feeTo = msg.sender;
        tradeSigner = msg.sender;
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    modifier uniqueTx(bytes32 _tx) {
        for (uint8 i=0; i<MINTED_TRANSACTIONS_RING_SIZE; i++) {
            if (mintedTransactions[i] == _tx) {
                revert("tx already minted");
            }
        }

        mintedTransactions[mintedTransactionsPos] = _tx;

        mintedTransactionsPos++;

        if (mintedTransactionsPos == MINTED_TRANSACTIONS_RING_SIZE) {
            mintedTransactionsPos = 0;
        }

        _;
    }

    modifier notPaused() {
        require(!isPaused, "paused");
        _;
    }

    function mint(uint256 aFarmTokenAmount, bytes32 homenetTx) public onlyOwner uniqueTx(homenetTx) {
        _mint(custodian, aFarmTokenAmount);
    }

    function burn(uint256 aFarmTokenAmount) public {
        require(msg.sender == custodian, "only custodian");
        require(balanceOf(custodian) >= aFarmTokenAmount, "not enough tokens");

        _burn(custodian, aFarmTokenAmount);
        emit BridgeBurn(aFarmTokenAmount);
    }

    // We have to verify deadline as well because someone can sign a price
    // with the oracle then come back in two months with valid signature
    // and purchase our tokens for much lower price.
    function invest(uint256 aFarmTokenAmount, uint256 quoteTokenAmount, uint32 deadline, bytes calldata signature)
        public
        notPaused
        validSignature(tradeSigner, signature, abi.encodePacked(true, aFarmTokenAmount, quoteTokenAmount, deadline, address(this), msg.sender))
    {
        require(block.timestamp < deadline, "expired");
        require(aFarmTokenAmount <= balanceOf(custodian) / 2 - 1, "more than half");
        require(IERC20(quoteToken).balanceOf(msg.sender) >= quoteTokenAmount, "not enough liquidity");

        IERC20(quoteToken).safeTransferFrom(msg.sender, custodian, quoteTokenAmount);
        _transfer(custodian, msg.sender, aFarmTokenAmount);

        emit Invest(aFarmTokenAmount, quoteTokenAmount);
    }

    function withdraw(uint256 aFarmTokenAmount, uint256 quoteTokenAmount, uint32 deadline, bytes calldata signature)
        public
        validSignature(tradeSigner, signature, abi.encodePacked(false, aFarmTokenAmount, quoteTokenAmount, deadline, address(this), msg.sender))
    {
        require(block.timestamp < deadline, "expired");
        require(balanceOf(msg.sender) >= aFarmTokenAmount, "not enough tokens");
        require(IERC20(quoteToken).balanceOf(custodian) >= quoteTokenAmount, "not enough liquidity");

        _transfer(msg.sender, custodian, aFarmTokenAmount);

        uint256 withdrawalFeeAmount = quoteTokenAmount * withdrawalFeePercent / 100 / (10 ** withdrawalFeePercentDecimals);
        uint256 quoteTokenAmountLessFee = quoteTokenAmount - withdrawalFeeAmount;

        IERC20(quoteToken).safeTransferFrom(custodian, msg.sender, quoteTokenAmountLessFee);
        if (withdrawalFeeAmount > 0) {
            IERC20(quoteToken).safeTransferFrom(custodian, feeTo, withdrawalFeeAmount);
        }

        emit Withdraw(aFarmTokenAmount, quoteTokenAmount);
    }

    function withdrawForAccount(address account, uint256 aFarmTokenAmount, uint256 quoteTokenAmount) public onlyOwner {
        require(balanceOf(account) >= aFarmTokenAmount, "not enough tokens");
        require(IERC20(quoteToken).balanceOf(custodian) >= quoteTokenAmount, "not enough liquidity");

        _transfer(account, custodian, aFarmTokenAmount);
        IERC20(quoteToken).safeTransferFrom(custodian, account, quoteTokenAmount);
    }

    function setCustodian(address _custodian) public onlyOwner {
        custodian = _custodian;
    }

    function setFeeTo(address _feeTo) public onlyOwner {
        feeTo = _feeTo;
    }

    function setTradeSigner(address _tradeSigner) public onlyOwner {
        tradeSigner = _tradeSigner;
    }

    function setAFarmBridge(address _aFarmBridge) public onlyOwner {
        aFarmBridge = _aFarmBridge;
    }

    function pause() public onlyOwner {
        isPaused = true;
    }

    function unpause() public onlyOwner {
        isPaused = false;
    }

    function setWithdrawalFeePercent(uint256 _withdrawalFeePercent) public onlyOwner {
        withdrawalFeePercent = _withdrawalFeePercent;
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);
        require(from == custodian || to == custodian, "Transfers are not allowed yet");
    }

    function shutdown() public onlyOwner {
        selfdestruct(payable(custodian));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/extensions/IERC20Metadata.sol";

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// use abi.encodePacked(param1, param2, ...) to create packed

abstract contract SignatureValidator {
    modifier validSignature(address signer, bytes calldata signature, bytes memory packed) {
        bytes32 hash = keccak256(packed);
        address recovered = recoverFromStringSignature(toEthSignedMessageHash(hash), signature);

        require(recovered == signer, "signature");

        _;
    }

    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    function recoverFromStringSignature(bytes32 hash, bytes memory signature) internal pure returns (address) {
        bytes32 r;
        bytes32 s;
        uint8 v;

        // Check the signature length
        if (signature.length != 65) {
            return (address(0));
        }

        // Divide the signature in r, s and v variables with inline assembly.
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        return recoverFromSplitSignature(hash, v, r, s);
    }

    function recoverFromSplitSignature(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
        if (v < 27) {
            v += 27;
        }

        // If the version is correct return the signer address
        if (v != 27 && v != 28) {
            return (address(0));
        } else {
            // solium-disable-next-line arg-overflow
            return ecrecover(hash, v, r, s);
        }
    }
}

// SPDX-License-Identifier: MIT

// NOTE: cloned from sushiswap canary #45da9720
// Replaced solidity version and imports

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./libraries/IRewarder.sol";

/// @notice The (older) MasterChef contract gives out a constant number of INCENT tokens per block.
/// It is the only address with minting rights for INCENT.
/// The idea for this MasterChef V2 (MCV2) contract is therefore to be the owner of a dummy token
/// that is deposited into the MasterChef V1 (MCV1) contract.
/// The allocation point for this pool on MCV1 is the total allocation point for all pools that receive double incentives.
contract IncentChef is Ownable {
    using SafeERC20 for IERC20;

    /// @notice Info of each MCV2 user.
    /// `amount` LP token amount the user has provided.
    /// `rewardDebt` The amount of INCENT entitled to the user.
    struct UserInfo {
        uint256 amount;
        int256 rewardDebt;
    }

    /// @notice Info of each MCV2 pool.
    /// `allocPoint` The amount of allocation points assigned to the pool.
    /// Also known as the amount of INCENT to distribute per block.
    struct PoolInfo {
        uint128 accIncentPerShare;
        uint64 lastRewardTime;
        uint64 allocPoint;
    }

    /// @notice Address of INCENT contract.
    IERC20 public INCENT;

    /// @notice Info of each MCV2 pool.
    PoolInfo[] public poolInfo;
    /// @notice Address of the LP token for each MCV2 pool.
    IERC20[] public lpToken;
    /// @notice Address of each `IRewarder` contract in MCV2.
    IRewarder[] public rewarder;

    /// @notice Info of each user that stakes LP tokens.
    mapping (uint256 => mapping (address => UserInfo)) public userInfo;

    /// @dev Tokens added
    mapping (address => bool) public addedTokens;

    /// @dev Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint;

    uint256 public incentPerSecond;
    uint256 private constant ACC_INCENT_PRECISION = 1e12;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount, address indexed to);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount, address indexed to);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount, address indexed to);
    event Harvest(address indexed user, uint256 indexed pid, uint256 amount);
    event LogPoolAddition(uint256 indexed pid, uint256 allocPoint, IERC20 indexed lpToken, IRewarder indexed rewarder);
    event LogSetPool(uint256 indexed pid, uint256 allocPoint, IRewarder indexed rewarder, bool overwrite);
    event LogUpdatePool(uint256 indexed pid, uint64 lastRewardTime, uint256 lpSupply, uint256 accIncentPerShare);
    event LogIncentPerSecond(uint256 incentPerSecond);

    /// @param incent The INCENT token contract address.
    constructor(IERC20 incent) {
        INCENT = incent;
    }

    function setINCENT(IERC20 incent) public onlyOwner {
        INCENT = incent;
    }

    /// @notice Returns the number of MCV2 pools.
    function poolLength() public view returns (uint256 pools) {
        pools = poolInfo.length;
    }

    /// @notice Add a new LP to the pool. Can only be called by the owner.
    /// DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    /// @param allocPoint AP of the new pool.
    /// @param _lpToken Address of the LP ERC-20 token.
    /// @param _rewarder Address of the rewarder delegate.
    function add(uint256 allocPoint, IERC20 _lpToken, IRewarder _rewarder) public onlyOwner {
        require(addedTokens[address(_lpToken)] == false, "Token already added");
        totalAllocPoint = totalAllocPoint + allocPoint;
        lpToken.push(_lpToken);
        rewarder.push(_rewarder);

        poolInfo.push(PoolInfo({
            allocPoint: uint64(allocPoint),
            lastRewardTime: uint64(block.timestamp),
            accIncentPerShare: 0
        }));
        addedTokens[address(_lpToken)] = true;
        emit LogPoolAddition(lpToken.length - 1, allocPoint, _lpToken, _rewarder);
    }

    /// @notice Update the given pool's INCENT allocation point and `IRewarder` contract. Can only be called by the owner.
    /// @param _pid The index of the pool. See `poolInfo`.
    /// @param _allocPoint New AP of the pool.
    /// @param _rewarder Address of the rewarder delegate.
    /// @param overwrite True if _rewarder should be `set`. Otherwise `_rewarder` is ignored.
    function set(uint256 _pid, uint256 _allocPoint, IRewarder _rewarder, bool overwrite) public onlyOwner {
        totalAllocPoint = totalAllocPoint - poolInfo[_pid].allocPoint + _allocPoint;
        poolInfo[_pid].allocPoint = uint64(_allocPoint);
        if (overwrite) { rewarder[_pid] = _rewarder; }
        emit LogSetPool(_pid, _allocPoint, overwrite ? _rewarder : rewarder[_pid], overwrite);
    }

    /// @notice Sets the incent per second to be distributed. Can only be called by the owner.
    /// @param _incentPerSecond The amount of Incent to be distributed per second.
    function setIncentPerSecond(uint256 _incentPerSecond) public onlyOwner {
        incentPerSecond = _incentPerSecond;
        emit LogIncentPerSecond(_incentPerSecond);
    }

    /// @notice View function to see pending INCENT on frontend.
    /// @param _pid The index of the pool. See `poolInfo`.
    /// @param _user Address of user.
    /// @return pending INCENT reward for a given user.
    function pendingIncent(uint256 _pid, address _user) external view returns (uint256 pending) {
        PoolInfo memory pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accIncentPerShare = pool.accIncentPerShare;
        uint256 lpSupply = lpToken[_pid].balanceOf(address(this));
        if (block.timestamp > pool.lastRewardTime && lpSupply != 0) {
            uint256 time = block.timestamp - pool.lastRewardTime;
            uint256 incentReward = time * incentPerSecond * pool.allocPoint / totalAllocPoint;
            accIncentPerShare = (accIncentPerShare + incentReward) * ACC_INCENT_PRECISION / lpSupply;
        }
        pending = uint256( int256(user.amount * accIncentPerShare / ACC_INCENT_PRECISION) - user.rewardDebt );
    }

    /// @notice Update reward variables for all pools. Be careful of gas spending!
    /// @param pids Pool IDs of all to be updated. Make sure to update all active pools.
    function massUpdatePools(uint256[] calldata pids) external {
        uint256 len = pids.length;
        for (uint256 i = 0; i < len; ++i) {
            updatePool(pids[i]);
        }
    }

    /// @notice Update reward variables of the given pool.
    /// @param pid The index of the pool. See `poolInfo`.
    /// @return pool Returns the pool that was updated.
    function updatePool(uint256 pid) public returns (PoolInfo memory pool) {
        pool = poolInfo[pid];
        if (block.timestamp > pool.lastRewardTime) {
            uint256 lpSupply = lpToken[pid].balanceOf(address(this));
            if (lpSupply > 0) {
                uint256 time = block.timestamp - pool.lastRewardTime;
                uint256 incentReward = time * incentPerSecond * pool.allocPoint / totalAllocPoint;
                pool.accIncentPerShare = pool.accIncentPerShare + uint128(incentReward * ACC_INCENT_PRECISION / lpSupply);
            }
            pool.lastRewardTime = uint64(block.timestamp);
            poolInfo[pid] = pool;
            emit LogUpdatePool(pid, pool.lastRewardTime, lpSupply, pool.accIncentPerShare);
        }
    }

    /// @notice Deposit LP tokens to MCV2 for INCENT allocation.
    /// @param pid The index of the pool. See `poolInfo`.
    /// @param amount LP token amount to deposit.
    /// @param to The receiver of `amount` deposit benefit.
    function deposit(uint256 pid, uint256 amount, address to) public {
        PoolInfo memory pool = updatePool(pid);
        UserInfo storage user = userInfo[pid][to];

        // Effects
        user.amount += amount;
        user.rewardDebt += int256(amount * pool.accIncentPerShare / ACC_INCENT_PRECISION);

        // Interactions
        IRewarder _rewarder = rewarder[pid];
        if (address(_rewarder) != address(0)) {
            _rewarder.onIncentReward(pid, to, to, 0, user.amount);
        }

        lpToken[pid].safeTransferFrom(msg.sender, address(this), amount);

        emit Deposit(msg.sender, pid, amount, to);
    }

    /// @notice Withdraw LP tokens from MCV2.
    /// @param pid The index of the pool. See `poolInfo`.
    /// @param amount LP token amount to withdraw.
    /// @param to Receiver of the LP tokens.
    function withdraw(uint256 pid, uint256 amount, address to) public {
        PoolInfo memory pool = updatePool(pid);
        UserInfo storage user = userInfo[pid][msg.sender];

        // Effects
        user.rewardDebt -= int256(amount * pool.accIncentPerShare / ACC_INCENT_PRECISION);
        user.amount -= amount;

        // Interactions
        IRewarder _rewarder = rewarder[pid];
        if (address(_rewarder) != address(0)) {
            _rewarder.onIncentReward(pid, msg.sender, to, 0, user.amount);
        }

        lpToken[pid].safeTransfer(to, amount);

        emit Withdraw(msg.sender, pid, amount, to);
    }

    /// @notice Harvest proceeds for transaction sender to `to`.
    /// @param pid The index of the pool. See `poolInfo`.
    /// @param to Receiver of INCENT rewards.
    function harvest(uint256 pid, address to) public {
        PoolInfo memory pool = updatePool(pid);
        UserInfo storage user = userInfo[pid][msg.sender];
        int256 accumulatedIncent = int256(user.amount * pool.accIncentPerShare / ACC_INCENT_PRECISION);
        uint256 _pendingIncent = uint256(accumulatedIncent - user.rewardDebt);

        // Effects
        user.rewardDebt = accumulatedIncent;

        // Interactions
        if (_pendingIncent != 0) {
            INCENT.safeTransfer(to, _pendingIncent);
        }

        IRewarder _rewarder = rewarder[pid];
        if (address(_rewarder) != address(0)) {
            _rewarder.onIncentReward( pid, msg.sender, to, _pendingIncent, user.amount);
        }

        emit Harvest(msg.sender, pid, _pendingIncent);
    }

    /// @notice Withdraw LP tokens from MCV2 and harvest proceeds for transaction sender to `to`.
    /// @param pid The index of the pool. See `poolInfo`.
    /// @param amount LP token amount to withdraw.
    /// @param to Receiver of the LP tokens and INCENT rewards.
    function withdrawAndHarvest(uint256 pid, uint256 amount, address to) public {
        PoolInfo memory pool = updatePool(pid);
        UserInfo storage user = userInfo[pid][msg.sender];
        int256 accumulatedIncent = int256(user.amount * pool.accIncentPerShare / ACC_INCENT_PRECISION);
        uint256 _pendingIncent = uint256(accumulatedIncent - user.rewardDebt);

        // Effects
        user.rewardDebt = accumulatedIncent - int256(amount * pool.accIncentPerShare / ACC_INCENT_PRECISION);
        user.amount -= amount;

        // Interactions
        INCENT.safeTransfer(to, _pendingIncent);

        IRewarder _rewarder = rewarder[pid];
        if (address(_rewarder) != address(0)) {
            _rewarder.onIncentReward(pid, msg.sender, to, _pendingIncent, user.amount);
        }

        lpToken[pid].safeTransfer(to, amount);

        emit Withdraw(msg.sender, pid, amount, to);
        emit Harvest(msg.sender, pid, _pendingIncent);
    }

    /// @notice Withdraw without caring about rewards. EMERGENCY ONLY.
    /// @param pid The index of the pool. See `poolInfo`.
    /// @param to Receiver of the LP tokens.
    function emergencyWithdraw(uint256 pid, address to) public {
        UserInfo storage user = userInfo[pid][msg.sender];
        uint256 amount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;

        IRewarder _rewarder = rewarder[pid];
        if (address(_rewarder) != address(0)) {
            _rewarder.onIncentReward(pid, msg.sender, to, 0, 0);
        }

        // Note: transfer can fail or succeed if `amount` is zero.
        lpToken[pid].safeTransfer(to, amount);
        emit EmergencyWithdraw(msg.sender, pid, amount, to);
    }
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";

import "./UniswapV2LibraryModified.sol";

// import "hardhat/console.sol";

uint256 constant DIVISION_PRECISION = 10**18;

/**
 * @title Main class for Uniswap-like farms. It is an ERC20 token itself.
 */
abstract contract AFarmUniswapBase is ERC20, Ownable {
    using SafeERC20 for IERC20;

    address public immutable token0;
    address public immutable token1;

    address public immutable mainToken;
    address public immutable secondaryToken;

    address public immutable quoteToken;

    // true means that quote token ("USDT") is also the main token for a pair ("WETH/USDT").
    // in this case we don't need to swap quoteToken to mainToken
    bool internal isQuoteTokenMain;

    /// @dev uniswap pair
    address public pair; // could be immutable once hardhat supports 0.8.9+

    address public immutable router;

    /// @dev address collecting protocol fees and dust after each runInvestmentQueue/runWithdrawalQueue
    address public feeTo;

    /// @dev hash with enumeration, basically
    mapping (address => uint256) public pendingInvestmentAmountByAddress;
    address[] public pendingInvestmentAddressList;
    uint256 public pendingInvestmentTotalAmount;

    mapping (address => uint256) public pendingWithdrawalAmountByAddress;
    address[] public pendingWithdrawalAddressList;
    uint256 public pendingWithdrawalTotalAmount;

    /// @dev protocol limits
    uint256 public minSingleInvestmentQuoteTokenAmount = 0;
    uint256 public maxSingleInvestmentQuoteTokenAmount = 0;
    uint256 public minSingleWithdrawalAFarmTokenAmount = 0;

    uint32 public swapDeadlineSeconds = 180 seconds;

    uint8 public constant withdrawalFeePercentDecimals = 6;
    uint256 public withdrawalFeePercent = 0;

    // FIXME verify!! https://hackernoon.com/how-much-can-i-do-in-a-block-163q3xp2
    uint16 public maxQueueSize = 100;

    bool public isPaused = false;

    // this is for UniswapV2LibraryModified so that we can work with various swaps
    bytes32 internal pairCodeHash;

    // we have the same decimals() that the underlying uniswap pair
    uint8 internal immutable _decimals;

    // "queue is dirty" event for the backend queue runner
    event PendingInvestment();
    event PendingWithdrawal();

    /**
     * @dev Create `mainTokenAddress`/`secondaryTokenAddress` farm for Uniswap, available for purchase for `quoteTokenAddress`.
     *
     * @param routerAddress must be swap's UniswapRouter02 address
     * @param quoteTokenAddress what token do we sell for, like USDT
     * @param mainTokenAddress main token address in pair we're creating
     * @param secondaryTokenAddress the other token address in pair we're creating
     * @param name farm's ERC20 name
     * @param symbol farm's ERC20 symbol
     */
    constructor(
        address routerAddress,
        address quoteTokenAddress,
        address mainTokenAddress,
        address secondaryTokenAddress,
        string memory name,
        string memory symbol
    ) ERC20(
        name,
        symbol
    ) {
        mainToken = mainTokenAddress;
        secondaryToken = secondaryTokenAddress;
        quoteToken = quoteTokenAddress;
        feeTo = msg.sender;

        require(quoteTokenAddress != secondaryTokenAddress, "quote == secondary");

        router = routerAddress;
        if (routerAddress == address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D)) { // uniswap
            pairCodeHash = hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f';

        // Sushiswap router02 on Ethereum
        } else if (routerAddress == address(0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F)) {
            pairCodeHash = hex'e18a34eb0e04b04f7a0ac29a6e80748dca96319b42c54d679cb821dca90c6303';

        // Sushiswap router02
        // Main Networks: Fantom, Matic, xDai & Binance Smart Chain
        // Test Networks: Ropsten, Rinkeby, Goerli, Kovan, Matic & Binance Smart Chain.
        } else if (routerAddress == address(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506)) {
            pairCodeHash = hex'e18a34eb0e04b04f7a0ac29a6e80748dca96319b42c54d679cb821dca90c6303';

        } else {
            revert("Unknown router, add pairCodeHash into code");
        }

        address pairAddress = IUniswapV2Factory(IUniswapV2Router02(routerAddress).factory()).getPair(mainTokenAddress, secondaryTokenAddress);
        pair = pairAddress;

        _decimals = IERC20Metadata(pairAddress).decimals();

        token1 = IUniswapV2Pair(pairAddress).token1();
        token0 = IUniswapV2Pair(pairAddress).token0();

        isQuoteTokenMain = quoteTokenAddress == mainTokenAddress;

        IERC20(quoteTokenAddress).safeApprove(routerAddress, 2**256-1);

        if (!isQuoteTokenMain) {
            IERC20(mainTokenAddress).safeApprove(routerAddress, 2**256-1);
        }

        IERC20(secondaryTokenAddress).safeApprove(routerAddress, 2**256-1);

        IERC20(pairAddress).approve(routerAddress, 2**256-1);
    }

    receive() external payable { }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    /******************** Investment Queue Methods ********************/

    function invest(uint256 quoteTokenAmount) public {
        require(!isPaused, "paused");

        require(pendingInvestmentAddressList.length < maxQueueSize, "full");
        require(quoteTokenAmount > 0, "quoteTokenAmount <= 0");
        require(minSingleInvestmentQuoteTokenAmount == 0 || quoteTokenAmount >= minSingleInvestmentQuoteTokenAmount, "too low");
        require(maxSingleInvestmentQuoteTokenAmount == 0 || quoteTokenAmount <= maxSingleInvestmentQuoteTokenAmount, "too high");

        IERC20(quoteToken).safeTransferFrom(msg.sender, address(this), quoteTokenAmount);

        if (pendingInvestmentAmountByAddress[msg.sender] == 0) {
            pendingInvestmentAddressList.push(msg.sender);
        }

        pendingInvestmentAmountByAddress[msg.sender] += quoteTokenAmount;
        pendingInvestmentTotalAmount += quoteTokenAmount;

        emit PendingInvestment();
    }

    function getPendingInvestmentAddressList() public view returns (address[] memory) {
        return pendingInvestmentAddressList;
    }

    function cancelInvestment(uint256 atIndex) public {
        require(pendingInvestmentAddressList[atIndex] == msg.sender, "address != sender");

        uint256 quoteTokenRefundAmount = pendingInvestmentAmountByAddress[msg.sender];

        delete pendingInvestmentAmountByAddress[msg.sender];

        if (pendingInvestmentAddressList.length == 1) {
            delete pendingInvestmentAddressList;

        } else {
            pendingInvestmentAddressList[atIndex] = pendingInvestmentAddressList[pendingInvestmentAddressList.length-1];
            pendingInvestmentAddressList.pop();

            // FIXME make sure that the above deleting code is correct and delete the snippet below
            // for (uint i = atIndex; i<pendingInvestmentAddressList.length-1; i++) {
            //     pendingInvestmentAddressList[i] = pendingInvestmentAddressList[i+1];
            // }
            // pendingInvestmentAddressList.pop();
        }

        if (quoteTokenRefundAmount > 0) {
            IERC20(quoteToken).safeTransfer(address(msg.sender), quoteTokenRefundAmount);
            pendingInvestmentTotalAmount -= quoteTokenRefundAmount;
        }
    }

    function cancelAllInvestments() public onlyOwner {
        require(isPaused, "not paused");
        require(pendingInvestmentAddressList.length > 0, "empty");

        for (uint i=0; i<pendingInvestmentAddressList.length; i++) {
            address account = pendingInvestmentAddressList[i];

            uint256 refundQuoteTokenAmount = pendingInvestmentAmountByAddress[account];
            delete pendingInvestmentAmountByAddress[account];

            if (refundQuoteTokenAmount > 0) {
                IERC20(quoteToken).safeTransfer(account, refundQuoteTokenAmount);
            }
        }

        delete pendingInvestmentAddressList;

        pendingInvestmentTotalAmount = 0;
    }

    function cancelTopInvestments(uint256 count) public onlyOwner {
        require(pendingInvestmentAddressList.length > count, "count");

        uint256 _count = pendingInvestmentAddressList.length < count ? pendingInvestmentAddressList.length : count;

        for (uint i=0; i<_count; i++) {
            address account = pendingInvestmentAddressList[pendingInvestmentAddressList.length-1];
            pendingInvestmentAddressList.pop();

            uint256 refundQuoteTokenAmount = pendingInvestmentAmountByAddress[account];
            delete pendingInvestmentAmountByAddress[account];

            if (refundQuoteTokenAmount > 0) {
                IERC20(quoteToken).safeTransfer(account, refundQuoteTokenAmount);
                pendingInvestmentTotalAmount -= refundQuoteTokenAmount;
            }
        }
    }

    /******************** Investment Implementation Methods ********************/

    function swapQuoteTokensToMainTokens(uint256 quoteTokenAmount, address[] memory swapPathQuoteToMain) internal {
        uint mainTokenAmountOut = getAmountOut(quoteTokenAmount, swapPathQuoteToMain);

        IUniswapV2Router02(router).swapExactTokensForTokens(
            quoteTokenAmount,
            mainTokenAmountOut,
            swapPathQuoteToMain,
            address(this),
            block.timestamp + swapDeadlineSeconds
        );
    }

    function swapHalfMainTokensToSecondaryTokens() internal {
        address[] memory path = new address[](2);
        path[0] = mainToken;
        path[1] = secondaryToken;

        uint256 mainTokenAmountToSwap = IERC20(mainToken).balanceOf(address(this)) / 2;

        swapMainAndSecondaryTokens(path, mainTokenAmountToSwap);
    }

    function addLiquidity() internal returns (uint256) {
        (, , uint _liquidity) = IUniswapV2Router02(router).addLiquidity(
            token0,
            token1,

            IERC20(token0).balanceOf(address(this)),
            IERC20(token1).balanceOf(address(this)),
            0,
            0,

            address(this),
            block.timestamp + swapDeadlineSeconds
        );

        return _liquidity;
    }

    function mintInvestmentQueueTokens(uint256 quoteTokenBalance, uint256 liquidity) internal {
        uint256 multiplierP = liquidity * DIVISION_PRECISION / quoteTokenBalance;

        for (uint256 i=0; i<pendingInvestmentAddressList.length; i++) {
            address account = pendingInvestmentAddressList[i];

            uint256 aFarmTokenAmountToMint = pendingInvestmentAmountByAddress[account] * multiplierP / DIVISION_PRECISION;

            if (aFarmTokenAmountToMint > 0) { // is this possible for this to be zero?
                _mint(account, aFarmTokenAmountToMint);
            }

            delete pendingInvestmentAmountByAddress[account];
        }

        delete pendingInvestmentAddressList;
    }

    function stakeAllTokens() internal virtual { }

    // This should transfer all LP tokens from this to feeTo. This is needed to clear LP tokens dust
    // after unstaking in stake farms like Sushi.
    function possiblyCollectLPTokenDust() internal virtual {
        // This is what should be in inherited classes:
        // _collectDustFromToken(pair);
    }

    function runInvestmentQueue(address[] memory swapPathQuoteToMain) public onlyOwner {
        require(pendingInvestmentAddressList.length > 0, "zero addresses");
        require(pendingInvestmentTotalAmount > 0, "zero amount");

        require(
            isQuoteTokenMain ||
            (swapPathQuoteToMain.length >= 2 && swapPathQuoteToMain[0] == quoteToken && swapPathQuoteToMain[swapPathQuoteToMain.length-1] == mainToken),
            "PATH"
        );

        uint256 quoteTokenBalance = IERC20(quoteToken).balanceOf(address(this));
        require(quoteTokenBalance >= pendingInvestmentTotalAmount, "balance < pending");

        uint256 quoteTokenDiffAmount = quoteTokenBalance - pendingInvestmentTotalAmount;
        if (quoteTokenDiffAmount > 0) {
            // unaccounted funds that should not be present
            IERC20(quoteToken).safeTransfer(feeTo, quoteTokenDiffAmount);
        }

        // unaccounted funds that should not be present
        _collectDustFromToken(secondaryToken);

        if (!isQuoteTokenMain) {
            // unaccounted funds that should not be present
            _collectDustFromToken(mainToken);

            swapQuoteTokensToMainTokens(pendingInvestmentTotalAmount, swapPathQuoteToMain);

            // dust left after swap
            _collectDustFromToken(quoteToken);
        }

        // collect unaccounted funds from intermediate tokens
        if (swapPathQuoteToMain.length > 2) {
            for (uint i=1; i<swapPathQuoteToMain.length - 1; i++) {
                _collectDustFromToken(swapPathQuoteToMain[i]);
            }
        }

        swapHalfMainTokensToSecondaryTokens();

        // we collect LP tokens in case someone directly transferred them to contract
        _collectDustFromToken(pair);

        uint256 liquidity = addLiquidity();

        assert(IERC20(mainToken).balanceOf(address(this)) == 0 || IERC20(secondaryToken).balanceOf(address(this)) == 0);

        _collectDustFromToken(mainToken);
        _collectDustFromToken(secondaryToken);
        _collectDustFromToken(quoteToken);

        mintInvestmentQueueTokens(pendingInvestmentTotalAmount, liquidity);

        stakeAllTokens();

        pendingInvestmentTotalAmount = 0;
    }

    /******************** Withdrawal Queue Methods ********************/

    function withdraw(uint256 aFarmTokenAmount) public {
        require(pendingWithdrawalAddressList.length < maxQueueSize, "full");
        require(aFarmTokenAmount > 0, "aFarmTokenAmount <= 0");
        require(minSingleWithdrawalAFarmTokenAmount == 0 || aFarmTokenAmount >= minSingleWithdrawalAFarmTokenAmount, "too low");

        _transfer(msg.sender, address(this), aFarmTokenAmount);

        if (pendingWithdrawalAmountByAddress[msg.sender] == 0) {
            pendingWithdrawalAddressList.push(msg.sender);
        }

        pendingWithdrawalAmountByAddress[msg.sender] += aFarmTokenAmount;
        pendingWithdrawalTotalAmount += aFarmTokenAmount;

        emit PendingWithdrawal();
    }

    function withdrawForAddress(address account) public onlyOwner {
        require(pendingWithdrawalAddressList.length < maxQueueSize, "full");

        uint256 aFarmTokenAmount = balanceOf(account);
        require(aFarmTokenAmount > 0, "aFarmTokenAmount <= 0");

        _transfer(account, address(this), aFarmTokenAmount);

        if (pendingWithdrawalAmountByAddress[account] == 0) {
            pendingWithdrawalAddressList.push(account);
        }

        pendingWithdrawalAmountByAddress[account] += aFarmTokenAmount;
        pendingWithdrawalTotalAmount += aFarmTokenAmount;
    }

    function getPendingWithdrawAddressList() public view returns (address[] memory) {
        return pendingWithdrawalAddressList;
    }

    function cancelWithdrawal(uint256 atIndex) public {
        require(pendingWithdrawalAddressList[atIndex] == msg.sender, "address != sender");

        uint256 aFarmTokenRefundAmount = pendingWithdrawalAmountByAddress[msg.sender];

        delete pendingWithdrawalAmountByAddress[msg.sender];

        if (pendingWithdrawalAddressList.length == 1) {
            delete pendingWithdrawalAddressList;

        } else {
            pendingWithdrawalAddressList[atIndex] = pendingWithdrawalAddressList[pendingWithdrawalAddressList.length-1];
            pendingWithdrawalAddressList.pop();
        }

        if (aFarmTokenRefundAmount > 0) {
            _transfer(address(this), msg.sender, aFarmTokenRefundAmount);
            pendingWithdrawalTotalAmount -= aFarmTokenRefundAmount;
        }
    }

    function cancelTopWithdrawals(uint256 count) public onlyOwner {
        require(pendingWithdrawalAddressList.length > count, "count");

        uint256 _count = pendingWithdrawalAddressList.length < count ? pendingWithdrawalAddressList.length : count;

        for (uint i=0; i<_count; i++) {
            address account = pendingWithdrawalAddressList[pendingWithdrawalAddressList.length-1];
            pendingWithdrawalAddressList.pop();

            uint256 aFarmTokenRefundAmount = pendingWithdrawalAmountByAddress[account];
            delete pendingWithdrawalAmountByAddress[account];

            if (aFarmTokenRefundAmount > 0) {
                _transfer(address(this), account, aFarmTokenRefundAmount);
                pendingWithdrawalTotalAmount -= aFarmTokenRefundAmount;
            }
        }
    }

    /******************** Withdrawal Implementation Methods ********************/

    function removeLiquidity(uint256 liquidity) internal {
        IUniswapV2Router02(router).removeLiquidity(
            token0,
            token1,
            liquidity,
            0, // FIXME oracle needed here?
            0,
            address(this),
            block.timestamp + swapDeadlineSeconds
        );
    }

    function swapMainTokensToQuoteTokens(address[] memory swapPathMainToQuote) internal {
        uint256 mainTokenBalance = IERC20(mainToken).balanceOf(address(this));
        uint quoteTokenAmountOut = getAmountOut(mainTokenBalance, swapPathMainToQuote);

        IUniswapV2Router02(router).swapExactTokensForTokens(
            mainTokenBalance,
            quoteTokenAmountOut,
            swapPathMainToQuote,
            address(this),
            block.timestamp + swapDeadlineSeconds
        );
    }

    function swapSecondaryTokensToMainTokens() internal {
        address[] memory path = new address[](2);
        path[0] = secondaryToken;
        path[1] = mainToken;

        uint256 secondaryTokenAmountToSwap = IERC20(secondaryToken).balanceOf(address(this));

        swapMainAndSecondaryTokens(path, secondaryTokenAmountToSwap);
    }

    function transferQuoteTokensToWithdrawingAccounts(uint256 aFarmTokenPendingWithdrawalTotalAmount) internal {
        uint256 quoteTokenAmountTotal = IERC20(quoteToken).balanceOf(address(this));

        for (uint256 i=0; i<pendingWithdrawalAddressList.length; i++) {
            address account = pendingWithdrawalAddressList[i];

            uint256 multiplierP = pendingWithdrawalAmountByAddress[account] * DIVISION_PRECISION / aFarmTokenPendingWithdrawalTotalAmount;
            uint256 quoteTokenAmountToTransfer = quoteTokenAmountTotal * multiplierP / DIVISION_PRECISION;

            if (quoteTokenAmountToTransfer > 0) { // hardly possible; check anyway
                IERC20(quoteToken).safeTransfer(account, quoteTokenAmountToTransfer);
            }

            delete pendingWithdrawalAmountByAddress[account];
        }

        delete pendingWithdrawalAddressList;
    }

    function collectWithdrawalFee() internal {
        uint256 quoteTokenAmountTotal = IERC20(quoteToken).balanceOf(address(this));
        uint256 withdrawalFeeAmount = quoteTokenAmountTotal * withdrawalFeePercent / 100 / (10 ** withdrawalFeePercentDecimals);
        if (withdrawalFeeAmount > 0) {
            IERC20(quoteToken).safeTransfer(feeTo, withdrawalFeeAmount);
        }
    }

    function unstakeTokens(uint256 aFarmTokenAmount) internal virtual { }

    function lpTokenBalance() public virtual view returns (uint256) {
        return IERC20(pair).balanceOf(address(this));
    }

    function runWithdrawalQueue(address[] memory swapPathMainToQuote) public onlyOwner {
        require(pendingInvestmentAddressList.length == 0, "investment pending");
        require(pendingWithdrawalAddressList.length > 0, "zero addresses");
        require(pendingWithdrawalTotalAmount > 0, "zero amount");

        require(
            isQuoteTokenMain ||
            (swapPathMainToQuote.length >= 2 && swapPathMainToQuote[0] == mainToken && swapPathMainToQuote[swapPathMainToQuote.length-1] == quoteToken),
            "PATH"
        );

        _collectDustFromToken(secondaryToken);
        _collectDustFromToken(quoteToken);

        if (!isQuoteTokenMain) {
            _collectDustFromToken(mainToken);
        }

        uint256 aFarmTokenBalance = balanceOf(address(this));
        require(aFarmTokenBalance >= pendingWithdrawalTotalAmount, "balance < withdrawal");

        uint256 aFarmTokenDiffAmount = aFarmTokenBalance - pendingWithdrawalTotalAmount;
        if (aFarmTokenDiffAmount > 0) {
            transfer(feeTo, aFarmTokenDiffAmount);
        }

        require(balanceOf(address(this)) == pendingWithdrawalTotalAmount, "diff");

        uint256 multiplierP = pendingWithdrawalTotalAmount * DIVISION_PRECISION / totalSupply();
        uint256 lpTokensToWithdraw = lpTokenBalance() * multiplierP / DIVISION_PRECISION;
        require(lpTokensToWithdraw > 0, "lp == 0");

        unstakeTokens(lpTokensToWithdraw);

        removeLiquidity(lpTokensToWithdraw);

        swapSecondaryTokensToMainTokens();

        if (!isQuoteTokenMain) {
            swapMainTokensToQuoteTokens(swapPathMainToQuote);
        }

        collectWithdrawalFee();

        transferQuoteTokensToWithdrawingAccounts(pendingWithdrawalTotalAmount);

        _burn(address(this), pendingWithdrawalTotalAmount);
        pendingWithdrawalTotalAmount = 0;

        possiblyCollectLPTokenDust();

        // There cannot be any dust left, because we swap full amounts on withdrawal on each step.
        // This is why I have left this code explicitly commented out:

        // _collectDustFromToken(secondaryToken);
        // _collectDustFromToken(mainToken);
        // _collectDustFromToken(quoteToken);
    }

    /******************** Collect Dust Methods ********************/

    function collectDustEth() public {
        uint256 balanceETH = address(this).balance;
        if (balanceETH > 0) {
            payable(feeTo).transfer(balanceETH);
        }
    }

    function collectDustFromToken(address tokenAddress) public {
        require(pendingWithdrawalAddressList.length == 0, "withdrawal");
        require(pendingInvestmentAddressList.length == 0, "investment");

        _collectDustFromToken(tokenAddress);
    }

    function _collectDustFromToken(address tokenAddress) internal {
        uint256 balance = IERC20(tokenAddress).balanceOf(address(this));
        if (balance > 0) {
            IERC20(tokenAddress).safeTransfer(feeTo, balance);
        }
    }

    /******************** Utility Methods ********************/

    function runInvestmentThenWithdrawalQueue(address[] memory swapPathMainToQuote, address[] memory swapPathQuoteToMain) public onlyOwner {
        runInvestmentQueue(swapPathQuoteToMain);
        runWithdrawalQueue(swapPathMainToQuote);
    }

    function queueInfo() public view returns (
        uint256 pendingWithdrawalAddressListLength,
        uint256 aFarmTokenPendingWithdrawalTotalAmount, // FIXME sync names and do we even need this method?

        uint256 pendingInvestmentAddressListLength,
        uint256 quoteTokenPendingInvestmentTotalAmount
    ) {
        pendingWithdrawalAddressListLength = pendingWithdrawalAddressList.length;
        aFarmTokenPendingWithdrawalTotalAmount = pendingWithdrawalTotalAmount;

        pendingInvestmentAddressListLength = pendingInvestmentAddressList.length;
        quoteTokenPendingInvestmentTotalAmount = pendingInvestmentTotalAmount;
    }

    function getAmountOut(uint256 amountIn, address[] memory path) internal view returns (uint256) {
        uint[] memory amountsOut = UniswapV2LibraryModified.getAmountsOut(pairCodeHash, IUniswapV2Router02(router).factory(), amountIn, path);
        return amountsOut[amountsOut.length - 1];
    }

    function swapMainAndSecondaryTokens(address[] memory path, uint256 amountToSwap) internal {
        uint amountOut = getAmountOut(amountToSwap, path);

        IUniswapV2Router02(router).swapExactTokensForTokens(
            amountToSwap,
            amountOut,
            path,
            address(this),
            block.timestamp + swapDeadlineSeconds
        );
    }

    /******************** Logging Methods ********************/

    // function myBalanceOf(address token) view internal returns (uint256) {
    //     return IERC20(token).balanceOf(address(this));
    // }

    // function logAllBalances(string memory reason) public view {
    //     console.log("[%s] quote   %d", reason, myBalanceOf(quoteToken), IERC20Metadata(quoteToken).symbol());
    //     console.log("[%s] token0  %d", reason, myBalanceOf(token0), IERC20Metadata(token0).symbol());
    //     console.log("[%s] token1  %d", reason, myBalanceOf(token1), IERC20Metadata(token1).symbol());

    //     console.log("[%s] pair    %d", reason, myBalanceOf(pair), IERC20Metadata(pair).symbol());
    //     console.log("[%s] my own  %d", reason, myBalanceOf(address(this)), symbol());
    // }

    /******************** Admin Methods ********************/

    function setLimits(
        uint256 _minSingleInvestmentQuoteAmount,
        uint256 _maxSingleInvestmentQuoteAmount,
        uint256 _minSingleWithdrawalAFarmTokenAmount
    ) public onlyOwner {
        // QUESTION do we need min/max for a single operation? If someone wants to invest $0.01 - let them.
        // They pay for gas. OTOH we pay for gas when we run queue.
        minSingleInvestmentQuoteTokenAmount = _minSingleInvestmentQuoteAmount;
        maxSingleInvestmentQuoteTokenAmount = _maxSingleInvestmentQuoteAmount;
        minSingleWithdrawalAFarmTokenAmount = _minSingleWithdrawalAFarmTokenAmount;
    }

    function setSwapDeadlineSeconds(uint32 _swapDeadlineSeconds) public onlyOwner {
        swapDeadlineSeconds = _swapDeadlineSeconds;
    }

    function setMaxQueueSize(uint16 _maxQueueSize) public onlyOwner {
        maxQueueSize = _maxQueueSize;
    }

    function setFeeTo(address _feeTo) public onlyOwner {
        feeTo = _feeTo;
    }

    function setWithdrawalFeePercent(uint256 _withdrawalFeePercent) public onlyOwner {
        withdrawalFeePercent = _withdrawalFeePercent;
    }

    function pause() public onlyOwner {
        isPaused = true;
    }

    function unpause() public onlyOwner {
        isPaused = false;
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        require(
            from == address(this) || to == address(this) ||
            from == address(0) || to == address(0) ||
            from == feeTo || to == feeTo,
            "Transfers are not allowed yet"
        );
    }

    function shutdown() public onlyOwner {
        require(isPaused, "must be paused");
        require(pendingInvestmentAddressList.length == 0, "investment");
        require(pendingWithdrawalAddressList.length == 0, "withdrawal");

        uint256 lpTokensToWithdraw = lpTokenBalance();
        if (lpTokensToWithdraw > 0) {
            unstakeTokens(lpTokensToWithdraw);
            removeLiquidity(IERC20(pair).balanceOf(address(this)));
        }

        _collectDustFromToken(quoteToken);
        _collectDustFromToken(mainToken);
        _collectDustFromToken(secondaryToken);
        _collectDustFromToken(pair);

        selfdestruct(payable(feeTo));
    }
}

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

// This is UniswapV2Library modified for Solidity 0.8.0+
// Removed lines are marked with "EE" comments

// EE
// SPDX-License-Identifier: Unlicensed

// EE
// Added pairCodeHash to all methods

pragma solidity >=0.5.0;

import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';

// EE
// import "./SafeMath.sol";

library UniswapV2LibraryModified {
    // EE
    // using SafeMath for uint;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'UniswapV2Library: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2Library: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(bytes32 pairCodeHash, address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        // EE
        // pair = address(uint(keccak256(abi.encodePacked(
        pair = address(uint160(uint256(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                pairCodeHash
            )))));
    }

    // fetches and sorts the reserves for a pair
    function getReserves(bytes32 pairCodeHash, address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IUniswapV2Pair(pairFor(pairCodeHash, factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'UniswapV2Library: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        // EE
        // amountB = amountA.mul(reserveB) / reserveA;
        amountB = amountA * reserveB / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');

        // EE
        // uint amountInWithFee = amountIn.mul(997);
        // uint numerator = amountInWithFee.mul(reserveOut);
        // uint denominator = reserveIn.mul(1000).add(amountInWithFee);

        uint amountInWithFee = amountIn * 997;
        uint numerator = amountInWithFee * reserveOut;
        uint denominator = reserveIn * 1000 + amountInWithFee;
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');

        // EE
        // uint numerator = reserveIn.mul(amountOut).mul(1000);
        // uint denominator = reserveOut.sub(amountOut).mul(997);
        // amountIn = (numerator / denominator).add(1);

        uint numerator = reserveIn * amountOut * 1000;
        uint denominator = (reserveOut - amountOut) * 997;
        amountIn = (numerator / denominator) + 1;
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(bytes32 pairCodeHash, address factory, uint amountIn, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = getReserves(pairCodeHash, factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(bytes32 pairCodeHash, address factory, uint amountOut, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut) = getReserves(pairCodeHash, factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }

    // EE added
    function quotePath(bytes32 pairCodeHash, address factory, uint amountIn, address[] memory path) internal view returns (uint256 amountOut) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');

        uint256 amount = amountIn;
        // amounts = new uint[](path.length);
        // amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = getReserves(pairCodeHash, factory, path[i], path[i + 1]);
            uint256 newAmount = quote(amount, reserveIn, reserveOut);
            amount = newAmount;
        }
        return amount;
    }
}

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;
import "./AFarmUniswapBase.sol";

contract AFarmUniswap is AFarmUniswapBase {
    constructor(
        address routerAddress,
        address quoteTokenAddress,
        address mainTokenAddress,
        address secondaryTokenAddress,
        string memory name,
        string memory symbol
    ) AFarmUniswapBase(
        routerAddress,
        quoteTokenAddress,
        mainTokenAddress,
        secondaryTokenAddress,
        name,
        symbol
    ) {
    }
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./AFarmUniswapBase.sol";
import "./interfaces/ISushiswapMasterChefV2.sol";

// import "hardhat/console.sol";

contract AFarmSushiswapV2 is AFarmUniswapBase {
    using SafeERC20 for IERC20;

    address public immutable masterChefV2;

    address public immutable sushiToken;
    address public immutable secondaryRewardToken;

    uint256 public poolId = 0;

    constructor(
        address routerAddress,
        address quoteTokenAddress,
        address mainTokenAddress,
        address secondaryTokenAddress,
        string memory name,
        string memory symbol,

        // sushiswap-only parameters:
        address masterChefV2Address,
        uint256 _poolId,
        address secondaryRewardTokenAddress
    ) AFarmUniswapBase(
        routerAddress,
        quoteTokenAddress,
        mainTokenAddress,
        secondaryTokenAddress,
        name,
        symbol
    ) {
        masterChefV2 = masterChefV2Address;
        poolId = _poolId;

        address _sushiToken = ISushiswapMasterChefV2(masterChefV2Address).SUSHI();
        sushiToken = _sushiToken;

        IERC20(_sushiToken).safeApprove(routerAddress, 2**256-1);
        IUniswapV2Pair(pair).approve(masterChefV2Address, 2**256-1);

        secondaryRewardToken = secondaryRewardTokenAddress;

        if (secondaryRewardTokenAddress != address(0)) {
            if (secondaryRewardTokenAddress != secondaryTokenAddress && secondaryRewardTokenAddress != mainTokenAddress && secondaryRewardTokenAddress != quoteTokenAddress) {
                IERC20(secondaryRewardTokenAddress).safeApprove(routerAddress, 2**256-1);
            }
        }
    }

    function masterChef() public view returns (address) {
        return masterChefV2;
    }

    function stakeAllTokens() internal override {
        uint256 lpTokens = IERC20(pair).balanceOf(address(this));
        if (lpTokens == 0) {
            return;
        }

        ISushiswapMasterChefV2(masterChefV2).deposit(poolId, lpTokens, address(this));

        // we collect leftover LP tokens after staking in case any left
        _collectDustFromToken(pair);
    }

    function unstakeTokens(uint256 lpTokensToWithdraw) internal override {
        ISushiswapMasterChefV2(masterChefV2).withdraw(poolId, lpTokensToWithdraw, address(this));
    }

    function possiblyCollectLPTokenDust() internal override {
        _collectDustFromToken(pair);
    }

    function lpTokenBalance() public view override returns (uint256) {
        (uint256 amount, ) = ISushiswapMasterChefV2(masterChefV2).userInfo(poolId, address(this));
        return amount;
    }

    function pendingSushi() public view returns (uint256) {
        return ISushiswapMasterChefV2(masterChefV2).pendingSushi(poolId, address(this));
    }

    function harvest() public onlyOwner {
        ISushiswapMasterChefV2(masterChefV2).harvest(poolId, address(this));
    }

    function compound(address[] memory swapPathSushiToMain, address[] memory swapPathSecondaryRewardToMain) public onlyOwner {
        require(
            swapPathSushiToMain.length >= 2 &&
            swapPathSushiToMain[0] == sushiToken &&
            swapPathSushiToMain[swapPathSushiToMain.length-1] == mainToken,
            "PATH1"
        );

        require(
            secondaryRewardToken == address(0) ||
            swapPathSecondaryRewardToMain.length >= 2 &&
            swapPathSecondaryRewardToMain[0] == secondaryRewardToken &&
            swapPathSecondaryRewardToMain[swapPathSecondaryRewardToMain.length-1] == mainToken,
            "PATH2"
        );

        uint256 sushiTokenAmount = IERC20(sushiToken).balanceOf(address(this));
        uint256 secondaryRewardTokenAmount = 0;

        if (secondaryRewardToken != address(0)) {
            secondaryRewardTokenAmount = IERC20(secondaryRewardToken).balanceOf(address(this));
        }

        require(sushiTokenAmount > 0 || secondaryRewardTokenAmount > 0, "nothing");

        if (sushiTokenAmount > 0) {
            uint mainTokenAmountOut = getAmountOut(sushiTokenAmount, swapPathSushiToMain);

            IUniswapV2Router02(router).swapExactTokensForTokens(
                sushiTokenAmount,
                mainTokenAmountOut,
                swapPathSushiToMain,
                address(this),
                block.timestamp + swapDeadlineSeconds
            );
        }

        if (secondaryRewardTokenAmount > 0) {
            uint mainTokenAmountOut = getAmountOut(secondaryRewardTokenAmount, swapPathSecondaryRewardToMain);

            IUniswapV2Router02(router).swapExactTokensForTokens(
                secondaryRewardTokenAmount,
                mainTokenAmountOut,
                swapPathSecondaryRewardToMain,
                address(this),
                block.timestamp + swapDeadlineSeconds
            );
        }

        swapHalfMainTokensToSecondaryTokens();

        addLiquidity();

        stakeAllTokens();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISushiswapMasterChefV2 {
    struct UserInfo {
        uint256 amount;
        int256 rewardDebt;
    }

    struct PoolInfo {
        uint128 accSushiPerShare;
        uint64 lastRewardBlock;
        uint64 allocPoint;
    }

    function MASTER_CHEF() external view returns (address);
    function SUSHI() external view returns (address);
    function MASTER_PID() external view returns (uint256);

    function poolInfo(uint256 pid) external view returns (ISushiswapMasterChefV2.PoolInfo memory);
    function lpToken(uint256 i) external view returns (address);
    function rewarder(uint256 i) external view returns (address);

    function userInfo(uint256 pid, address account) external view returns (uint256 amount, uint256 rewardDebt);

    function totalAllocPoint() external view returns (uint256);
    function poolLength() external view returns (uint256 pools);
    function pendingSushi(uint256 _pid, address _user) external view returns (uint256 pending);
    function sushiPerBlock() external view returns (uint256 amount);
    function deposit(uint256 pid, uint256 amount, address to) external;
    function withdraw(uint256 pid, uint256 amount, address to) external;
    function harvest(uint256 pid, address to) external;
    function withdrawAndHarvest(uint256 pid, uint256 amount, address to) external;
    function updatePool(uint256 pid) external;
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

uint256 constant DIVISION_PRECISION = 10**18;

interface AFarmUniswapLookupInterface {
    function token0() external view returns (address);
    function pair() external view returns (address);
    function router() external view returns (address);
    function mainToken() external view returns (address);
    function pendingInvestmentAmountByAddress(address account) external view returns (uint256);
    function pendingWithdrawalAmountByAddress(address account) external view returns (uint256);
    function lpTokenBalance() external view returns (uint256);
}

interface AFarmUniswapLimitsInterface {
    function minSingleInvestmentQuoteTokenAmount() external view returns (uint256);
    function maxSingleInvestmentQuoteTokenAmount() external view returns (uint256);
    function minSingleWithdrawalAFarmTokenAmount() external view returns (uint256);
    function maxQueueSize() external view returns (uint16);
    function isPaused() external view returns (bool);

    function queueInfo() external view returns (
        uint256 pendingWithdrawalAddressListLength,
        uint256 aFarmTokenPendingWithdrawalTotalAmount,

        uint256 pendingInvestmentAddressListLength,
        uint256 quoteTokenPendingInvestmentTotalAmount
    );
}

interface ExtranetTokenLookupInterface {
    function availableSupply() external view returns (uint256);
    function custodian() external view returns (address);
    function quoteToken() external view returns (address);
    function isPaused() external view returns (bool);
}

contract AFarmLookup is Ownable {
    struct lookupFarmResult {
        uint256 lpTotalSupply;
        uint256 lpTokenBalance;
        uint256 reserve0;
        uint256 reserve1;
        uint256 totalSupply;
        uint256 totalValueInQuoteToken;
        uint256 lpTotalValueInQuoteToken;
    }

    function lookupFarm(address aFarmAddress, address[] memory swapPathMainToQuote) public view returns (lookupFarmResult memory result) {
        address pairAddress = AFarmUniswapLookupInterface(aFarmAddress).pair();
        result.lpTotalSupply = IUniswapV2Pair(pairAddress).totalSupply();
        result.lpTokenBalance = AFarmUniswapLookupInterface(aFarmAddress).lpTokenBalance();

        (result.reserve0, result.reserve1, ) = IUniswapV2Pair(pairAddress).getReserves();

        result.totalSupply = IERC20(aFarmAddress).totalSupply();

        uint256 reserveMain = AFarmUniswapLookupInterface(aFarmAddress).mainToken() == AFarmUniswapLookupInterface(aFarmAddress).token0() ? result.reserve0 : result.reserve1;

        address factory = IUniswapV2Router02(AFarmUniswapLookupInterface(aFarmAddress).router()).factory();

        uint256 aFarmReserveMain = (result.lpTokenBalance * DIVISION_PRECISION / IERC20(pairAddress).totalSupply()) * reserveMain / DIVISION_PRECISION;

        if (swapPathMainToQuote.length >= 2) {
            result.totalValueInQuoteToken = quotePath(factory, aFarmReserveMain * 2, swapPathMainToQuote);
            result.lpTotalValueInQuoteToken = quotePath(factory, reserveMain * 2, swapPathMainToQuote);
        } else {
            result.totalValueInQuoteToken = aFarmReserveMain * 2;
            result.lpTotalValueInQuoteToken = reserveMain * 2;
        }
    }

    function quotePath(address factory, uint amountIn, address[] memory path) public view returns (uint256 amountOut) {
        require(path.length >= 2, 'INVALID_PATH');

        uint256 amount = amountIn;

        for (uint i; i < path.length - 1; i++) {
            address pair = IUniswapV2Factory(factory).getPair(path[i], path[i + 1]);

            (uint reserve0, uint reserve1, ) = IUniswapV2Pair(pair).getReserves();
            (uint reserveIn, uint reserveOut) = IUniswapV2Pair(pair).token0() == path[i] ? (reserve0, reserve1) : (reserve1, reserve0);

            uint256 newAmount = amount * reserveOut / reserveIn;
            amount = newAmount;
        }

        return amount;
    }

    struct lookupLimitsResult {
        uint256 minSingleInvestmentQuoteTokenAmount;
        uint256 maxSingleInvestmentQuoteTokenAmount;
        uint256 minSingleWithdrawalAFarmTokenAmount;

        uint16 maxQueueSize;
        uint256 pendingInvestmentAddressListLength;
        uint256 pendingWithdrawalAddressListLength;

        bool isPaused;
    }

    function lookupLimits(address target) public view returns (lookupLimitsResult memory result) {
        result.minSingleInvestmentQuoteTokenAmount = AFarmUniswapLimitsInterface(target).minSingleInvestmentQuoteTokenAmount();
        result.maxSingleInvestmentQuoteTokenAmount = AFarmUniswapLimitsInterface(target).maxSingleInvestmentQuoteTokenAmount();
        result.minSingleWithdrawalAFarmTokenAmount = AFarmUniswapLimitsInterface(target).minSingleWithdrawalAFarmTokenAmount();

        result.maxQueueSize = AFarmUniswapLimitsInterface(target).maxQueueSize();

        (result.pendingWithdrawalAddressListLength, , result.pendingInvestmentAddressListLength, ) = AFarmUniswapLimitsInterface(target).queueInfo();

        result.isPaused = AFarmUniswapLimitsInterface(target).isPaused();
    }

    struct lookupAccountResult {
        uint256 aFarmContractBalance;
        uint256 pendingInvestmentAmount;
        uint256 pendingWithdrawalAmount;
    }

    function lookupAccount(address aFarmAddress, address account) public view returns (lookupAccountResult memory result) {
        result.aFarmContractBalance = IERC20(aFarmAddress).balanceOf(account);
        result.pendingInvestmentAmount = AFarmUniswapLookupInterface(aFarmAddress).pendingInvestmentAmountByAddress(account);
        result.pendingWithdrawalAmount = AFarmUniswapLookupInterface(aFarmAddress).pendingWithdrawalAmountByAddress(account);
    }

    struct lookupExtranetResult {
        uint256 totalSupply;
        uint256 availableSupply;
        uint256 availableLiquidityQuoteToken;
        bool isPaused;
    }

    function lookupExtranet(address extranetToken) public view returns (lookupExtranetResult memory result) {
        address extranetTokenCustodian = ExtranetTokenLookupInterface(extranetToken).custodian();
        address quoteToken = ExtranetTokenLookupInterface(extranetToken).quoteToken();

        result.totalSupply = IERC20(extranetToken).totalSupply();
        result.availableSupply = IERC20(extranetToken).balanceOf(extranetTokenCustodian);
        result.availableLiquidityQuoteToken = IERC20(quoteToken).balanceOf(extranetTokenCustodian);

        result.isPaused = ExtranetTokenLookupInterface(extranetToken).isPaused();
    }

    function shutdown() public onlyOwner {
        selfdestruct(payable(owner()));
    }
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./AFarmUniswapBase.sol";
import "./interfaces/ISushiswapMasterChef.sol";

// import "hardhat/console.sol";

contract AFarmSushiswap is AFarmUniswapBase {
    using SafeERC20 for IERC20;

    address public immutable sushiToken;
    address public immutable masterChef;

    uint256 public poolId = 0;

    constructor(
        address routerAddress,
        address quoteTokenAddress,
        address mainTokenAddress,
        address secondaryTokenAddress,
        string memory name,
        string memory symbol,

        // sushiswap-only parameters:
        address masterChefAddress,
        uint256 _poolId
    ) AFarmUniswapBase(
        routerAddress,
        quoteTokenAddress,
        mainTokenAddress,
        secondaryTokenAddress,
        name,
        symbol
    ) {
        masterChef = masterChefAddress;
        poolId = _poolId;

        address _sushiToken = ISushiswapMasterChef(masterChefAddress).sushi();
        sushiToken = _sushiToken;

        IERC20(_sushiToken).safeApprove(routerAddress, 2**256-1);
        IUniswapV2Pair(pair).approve(masterChefAddress, 2**256-1);
    }

    function stakeAllTokens() internal override {
        uint256 lpTokens = IERC20(pair).balanceOf(address(this));
        if (lpTokens == 0) {
            return;
        }

        ISushiswapMasterChef(masterChef).deposit(poolId, lpTokens);

        // we collect leftover LP tokens after staking in case any left
        _collectDustFromToken(pair);
    }

    function unstakeTokens(uint256 lpTokensToWithdraw) internal override {
        ISushiswapMasterChef(masterChef).withdraw(poolId, lpTokensToWithdraw);
    }

    function possiblyCollectLPTokenDust() internal override {
        _collectDustFromToken(pair);
    }

    function lpTokenBalance() public view override returns (uint256) {
        (uint256 amount, ) = ISushiswapMasterChef(masterChef).userInfo(poolId, address(this));
        return amount;
    }

    function pendingSushi() public view returns (uint256) {
        return ISushiswapMasterChef(masterChef).pendingSushi(poolId, address(this));
    }

    function harvest() public onlyOwner {
        ISushiswapMasterChef(masterChef).deposit(poolId, 0);
    }

    function compound(address[] memory swapPathSushiToMain) public onlyOwner {
        uint256 sushiTokenAmount = IERC20(sushiToken).balanceOf(address(this));
        require(sushiTokenAmount > 0, "SUSHI == 0");

        require(
            swapPathSushiToMain.length >= 2 && swapPathSushiToMain[0] == sushiToken && swapPathSushiToMain[swapPathSushiToMain.length-1] == mainToken,
            "PATH"
        );

        uint mainTokenAmountOut = getAmountOut(sushiTokenAmount, swapPathSushiToMain);

        IUniswapV2Router02(router).swapExactTokensForTokens(
            sushiTokenAmount,
            mainTokenAmountOut,
            swapPathSushiToMain,
            address(this),
            block.timestamp + swapDeadlineSeconds
        );

        swapHalfMainTokensToSecondaryTokens();

        addLiquidity();

        stakeAllTokens();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISushiswapMasterChef {
    struct UserInfo {
        uint256 amount;     // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
    }

    struct PoolInfo {
        address lpToken;          // Address of LP token contract.
        uint256 allocPoint;       // How many allocation points assigned to this pool. SUSHI to distribute per block.
        uint256 lastRewardBlock;  // Last block number that SUSHI distribution occurs.
        uint256 accSushiPerShare; // Accumulated SUSHI per share, times 1e12. See below.
    }

    function sushi() external view returns (address);
    function poolInfo(uint256 pid) external view returns (ISushiswapMasterChef.PoolInfo memory);
    function userInfo(uint256 pid, address account) external view returns (uint256 amount, uint256 rewardDebt);
    function totalAllocPoint() external view returns (uint256);
    function deposit(uint256 _pid, uint256 _amount) external;
    function harvest(uint256 pid, address to) external;
    function withdraw(uint256 _pid, uint256 _amount) external;
    function pendingSushi(uint256 _pid, address _user) external view returns (uint256 amount);
    function sushiPerBlock() external view returns (uint256 value);
    function poolLength() external view returns (uint256);
    function updatePool(uint256 pid) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/finance/VestingWallet.sol";

contract VestingOne is VestingWallet {
    constructor(
        address beneficiaryAddress,
        uint64 startTimestamp,
        uint64 durationSeconds
    ) VestingWallet(
        beneficiaryAddress,
        startTimestamp,
        durationSeconds
    ) {
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../libraries/IRewarder.sol";

contract RewarderBrokenMock is IRewarder {
    function onIncentReward (uint256, address, address, uint256, uint256) override external {
        revert();
    }

    function pendingTokens(uint256 pid, address user, uint256 incentAmount) override external view returns (IERC20[] memory rewardTokens, uint256[] memory rewardAmounts){
        revert();
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity <0.9.0;

import "hardhat/console.sol";

contract Greeter {
  string greeting;

  constructor(string memory _greeting) {
    console.log("Deploying a Greeter with greeting:", _greeting);
    greeting = _greeting;
  }

  function greet() public view returns (string memory) {
    return greeting;
  }

  function setGreeting(string memory _greeting) public {
    console.log("Changing greeting from '%s' to '%s'", greeting, _greeting);
    greeting = _greeting;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.4.22 <0.9.0;

library console {
	address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function _sendLogPayload(bytes memory payload) private view {
		uint256 payloadLength = payload.length;
		address consoleAddress = CONSOLE_ADDRESS;
		assembly {
			let payloadStart := add(payload, 32)
			let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
		}
	}

	function log() internal view {
		_sendLogPayload(abi.encodeWithSignature("log()"));
	}

	function logInt(int p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(int)", p0));
	}

	function logUint(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function logString(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function logBool(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function logAddress(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function logBytes(bytes memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
	}

	function logBytes1(bytes1 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
	}

	function logBytes2(bytes2 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
	}

	function logBytes3(bytes3 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
	}

	function logBytes4(bytes4 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
	}

	function logBytes5(bytes5 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
	}

	function logBytes6(bytes6 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
	}

	function logBytes7(bytes7 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
	}

	function logBytes8(bytes8 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
	}

	function logBytes9(bytes9 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
	}

	function logBytes10(bytes10 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
	}

	function logBytes11(bytes11 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
	}

	function logBytes12(bytes12 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
	}

	function logBytes13(bytes13 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
	}

	function logBytes14(bytes14 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
	}

	function logBytes15(bytes15 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
	}

	function logBytes16(bytes16 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
	}

	function logBytes17(bytes17 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
	}

	function logBytes18(bytes18 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
	}

	function logBytes19(bytes19 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
	}

	function logBytes20(bytes20 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
	}

	function logBytes21(bytes21 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
	}

	function logBytes22(bytes22 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
	}

	function logBytes23(bytes23 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
	}

	function logBytes24(bytes24 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
	}

	function logBytes25(bytes25 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
	}

	function logBytes26(bytes26 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
	}

	function logBytes27(bytes27 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
	}

	function logBytes28(bytes28 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
	}

	function logBytes29(bytes29 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
	}

	function logBytes30(bytes30 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
	}

	function logBytes31(bytes31 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
	}

	function logBytes32(bytes32 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
	}

	function log(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function log(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function log(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function log(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function log(uint p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint)", p0, p1));
	}

	function log(uint p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string)", p0, p1));
	}

	function log(uint p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool)", p0, p1));
	}

	function log(uint p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address)", p0, p1));
	}

	function log(string memory p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint)", p0, p1));
	}

	function log(string memory p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
	}

	function log(string memory p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
	}

	function log(string memory p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
	}

	function log(bool p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint)", p0, p1));
	}

	function log(bool p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
	}

	function log(bool p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
	}

	function log(bool p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
	}

	function log(address p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint)", p0, p1));
	}

	function log(address p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
	}

	function log(address p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
	}

	function log(address p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
	}

	function log(uint p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint)", p0, p1, p2));
	}

	function log(uint p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string)", p0, p1, p2));
	}

	function log(uint p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool)", p0, p1, p2));
	}

	function log(uint p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address)", p0, p1, p2));
	}

	function log(uint p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint)", p0, p1, p2));
	}

	function log(uint p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string)", p0, p1, p2));
	}

	function log(uint p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool)", p0, p1, p2));
	}

	function log(uint p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address)", p0, p1, p2));
	}

	function log(uint p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint)", p0, p1, p2));
	}

	function log(uint p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string)", p0, p1, p2));
	}

	function log(uint p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool)", p0, p1, p2));
	}

	function log(uint p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
	}

	function log(string memory p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint)", p0, p1, p2));
	}

	function log(string memory p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
	}

	function log(string memory p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
	}

	function log(string memory p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
	}

	function log(bool p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint)", p0, p1, p2));
	}

	function log(bool p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string)", p0, p1, p2));
	}

	function log(bool p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool)", p0, p1, p2));
	}

	function log(bool p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
	}

	function log(bool p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint)", p0, p1, p2));
	}

	function log(bool p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
	}

	function log(bool p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
	}

	function log(bool p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
	}

	function log(bool p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint)", p0, p1, p2));
	}

	function log(bool p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
	}

	function log(bool p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
	}

	function log(bool p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
	}

	function log(address p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint)", p0, p1, p2));
	}

	function log(address p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string)", p0, p1, p2));
	}

	function log(address p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool)", p0, p1, p2));
	}

	function log(address p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address)", p0, p1, p2));
	}

	function log(address p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint)", p0, p1, p2));
	}

	function log(address p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
	}

	function log(address p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
	}

	function log(address p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
	}

	function log(address p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint)", p0, p1, p2));
	}

	function log(address p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
	}

	function log(address p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
	}

	function log(address p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
	}

	function log(address p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint)", p0, p1, p2));
	}

	function log(address p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
	}

	function log(address p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
	}

	function log(address p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
	}

	function log(uint p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
	}

}