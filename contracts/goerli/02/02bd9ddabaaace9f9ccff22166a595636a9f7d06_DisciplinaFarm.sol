// SPDX-FileCopyrightText: 2021 Disciplina
// SPDX-License-Identifier: BSD-3-Clause

pragma solidity 0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract DisciplinaFarm is Ownable {
    using SafeERC20 for IERC20;

    struct Epoch {
        uint start;
        uint end;
        uint256 reward;
        uint256 points;
    }

    struct Investment {
        uint lastAccumulatedEpoch;
        uint256 accReward;
        uint256 totalInvested;
        uint256 pendingPoints;
    }

    IERC20 immutable private _lpToken;
    IERC20 immutable private _rewardToken;

    uint private _currentEpoch = 0;
    uint256 private _totalInvested = 0;

    mapping (uint => Epoch) private _epochs;

    mapping (address => Investment) private _investments;

    modifier withinEpoch {
        require(isActive(), "There is no active epoch");
        _;
    }

    constructor(address lpTokenAddress, address rewardTokenAddress) {
        _lpToken = IERC20(lpTokenAddress);
        _rewardToken = IERC20(rewardTokenAddress);
    }

    /// @notice Transfers the reward to self and starts a new epoch.
    /// @param reward the epoch reward in _rewardToken
    /// @param epochEnd the end of the epoch
    function startEpoch(uint256 reward, uint epochEnd) external onlyOwner {
        require(!isActive(), "Already in an active epoch");
        require(epochEnd > getBlockNumber(), "Epoch ends in the past");
        _currentEpoch += 1;

        // Fill in the epoch
        Epoch storage epoch = _epochs[_currentEpoch];
        epoch.start = getBlockNumber();
        epoch.end = epochEnd;
        epoch.points = _totalInvested * (epochEnd - getBlockNumber());
        // ^ Carry forward the investments from the previous epochs.
        //   Here we optimistically assume that the investors would
        //   hold the investment for the whole epoch. If this turns
        //   out to be wrong, we'll subtract this amount in `withdraw`

        epoch.reward = reward;

        _rewardToken.safeTransferFrom(msg.sender, address(this), reward);
    }

    /// @notice Allows the owner to withdraw the reward for a completed
    ///   epoch with no investors.
    /// @param epochId the index of the epoch
    function claimEmpty(uint epochId) external onlyOwner {
        uint epochEnd = _epochs[epochId].end;
        require(epochEnd != 0, "The epoch does not exist");
        require(epochEnd <= getBlockNumber(), "The epoch is not finished yet");
        require(_epochs[epochId].points == 0, "The points are nonzero");
        _rewardToken.safeTransfer(msg.sender, _epochs[epochId].reward);
    }

    /// @notice Adds a new investment for `msg.sender` – creates or updates
    ///   the `Investment` structure, and transfers `amount` of LP tokens
    ///   from `msg.sender` to self. Can only be called within an active
    ///   epoch (otherwise, the formulas would be wrong)!
    /// @param amount the investment amount
    function invest(uint256 amount) external withinEpoch {
        Epoch storage epoch = _epochs[_currentEpoch];
        uint256 pointsDelta = amount * (epoch.end - getBlockNumber());
        epoch.points += pointsDelta;
        // ^ Here we optimistically assume that the investors would
        //   hold the investment for the whole epoch. If this turns
        //   out to be wrong, we'll subtract this amount in `withdraw`

        Investment storage inv = _investments[msg.sender];
        _accumulateReward(inv, epoch.end - epoch.start);
        inv.pendingPoints += pointsDelta;
        inv.totalInvested += amount;
        _totalInvested += amount;

        _lpToken.safeTransferFrom(msg.sender, address(this), amount);
    }

    /// @notice Returns a record corresponding to an individual investor.
    /// @return the investment record
    function getInvestmentStatus(address beneficiary)
        external
        view
        returns (Investment memory)
    {
        return _investments[beneficiary];
    }

    /// @notice Withdraws *all* investments of msg.sender.
    function withdraw() external {
        Investment storage inv = _investments[msg.sender];
        Epoch storage epoch = _epochs[_currentEpoch];
        _accumulateReward(inv, epoch.end - epoch.start);

        // If there's an active epoch, our optimistic assumptions
        // have failed. We need to subtract the pending points
        // from the current epoch:
        if (isActive()) {
            _epochs[_currentEpoch].points -= inv.pendingPoints;
        }

        uint256 amountToWithdraw = inv.totalInvested;
        uint256 reward = inv.accReward;
        delete _investments[msg.sender];
        _totalInvested -= amountToWithdraw;
        if (amountToWithdraw != 0) {
            _lpToken.safeTransfer(msg.sender, amountToWithdraw);
        }
        if (reward != 0) {
            _rewardToken.safeTransfer(msg.sender, reward);
        }
    }

    /// @notice Returns the address of LP token
    /// @return the address of LP token
    function lpToken() external view returns (IERC20) {
        return _lpToken;
    }

    /// @notice Returns the address of the reward token
    /// @return the address of the reward token
    function rewardToken() external view returns (IERC20) {
        return _rewardToken;
    }

    /// @notice Returns the index of the current epoch
    ///   (regardless of whether it is active or not).
    /// @return the scalar value (epoch index)
    function currentEpoch() external view returns (uint) {
        return _currentEpoch;
    }

    /// @notice Returns the total amount of LP tokens that have
    ///   not been withdrawn yet.
    /// @return the scalar value (total investment amount)
    function totalInvested() external view returns (uint256) {
        return _totalInvested;
    }

    /// @notice Returns the parameters of an epoch
    /// @return the epoch structure
    function getEpoch(uint epoch) external view returns (Epoch memory) {
        return _epochs[epoch];
    }

    /// @notice Returns the total amount of invested tokens along
    ///   with the reward that the beneficiary is eligible for.
    ///   The code of this function is equivalent to the code of
    ///   withdraw() except it does not change the state.
    /// @param beneficiary the address of the investor
    /// @return lpTokens the number of invested tokens
    /// @return reward the expected reward for the investments
    function getTotalInvestmentsAndRewards(address beneficiary)
        external
        view
        returns (uint256 lpTokens, uint256 reward)
    {
        Investment storage inv = _investments[beneficiary];
        return (inv.totalInvested, _getAccumulatedReward(inv));
    }

    /// @notice Returns the current block number (useful for testing)
    /// @return the current block number
    function getBlockNumber() virtual public view returns (uint) {
        return block.number;
    }

    /// @notice Tells if the latest epoch is active (has not ended yet)
    /// @return true if the latest epoch is active, false otherwise
    function isActive() public view returns (bool) {
        return getBlockNumber() < _epochs[_currentEpoch].end;
    }

    /// @notice Returns the latest completed epoch index.
    ///   - if `startEpoch` has never been called, reverts;
    ///   - if there is an active epoch, returns (epoch - 1);
    ///   - if there is no active epoch, returns epoch.
    /// @return last epoch whose end < now
    function lastCompletedEpoch() public view returns (uint) {
        if (isActive()) {
            return _currentEpoch - 1;
        } else {
            return _currentEpoch;
        }
    }

    /// @dev Computes the investor's reward for all completed epochs.
    ///   Updates inv.accReward with the computed value. Updates
    ///   inv.pendingPoints so that its value corresponds to the
    ///   (projected) investor's points for the current epoch.
    /// @param inv The investment record.
    /// @param currentEpochLength The length of the current epoch.
    function _accumulateReward(
        Investment storage inv,
        uint currentEpochLength
    )
        private
    {
        uint256 rewardDelta = _getAccumulatedRewardDelta(inv);

        if (rewardDelta != 0) {
            // If we have accumulated something, we can be sure that
            // this epoch did not contain other investments (otherwise,
            // _accumulateReward would have been called already). Then
            // we need to update pending points to account for the
            // carried-forward investments. As usual, we optimistically
            // assume the investor would keep the investment for the
            // whole epoch.
            inv.pendingPoints = inv.totalInvested * currentEpochLength;
            inv.accReward += rewardDelta;
        }

        inv.lastAccumulatedEpoch = lastCompletedEpoch();
    }

    /// @dev Goes through the previous completed epochs and computes
    ///   the investor's reward for all these epochs. DOES NOT account
    ///   for the current epoch if it's not completed.
    /// @param inv The investment record.
    function _getAccumulatedReward(Investment storage inv)
        private
        view
        returns (uint256)
    {
        uint256 rewardDelta = _getAccumulatedRewardDelta(inv);
        return inv.accReward + rewardDelta;
    }

    /// @dev Goes through the previous completed epochs since the
    ///   last update and computes the newly-accrued reward.
    /// @param inv The investment record.
    function _getAccumulatedRewardDelta(Investment storage inv)
        private
        view
        returns (uint256)
    {
        uint256 toEpoch = lastCompletedEpoch();
        if (inv.totalInvested == 0 && inv.pendingPoints == 0) {
            // Short-circuit uninitialized investments
            return 0;
        }
        uint256 fromEpoch = inv.lastAccumulatedEpoch + 1;
        uint256 rewardDelta = 0;

        for (uint i = fromEpoch; i <= toEpoch; ++i) {
            Epoch storage epoch = _epochs[i];
            uint256 points = 0;
            if (i == fromEpoch) {
                points = inv.pendingPoints;
            } else {
                points = (epoch.end - epoch.start) * inv.totalInvested;
            }
            rewardDelta += (epoch.reward * points) / epoch.points;
        }

        return rewardDelta;
    }
}

// SPDX-License-Identifier: MIT

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
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

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
    constructor () {
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

pragma solidity ^0.8.0;

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

