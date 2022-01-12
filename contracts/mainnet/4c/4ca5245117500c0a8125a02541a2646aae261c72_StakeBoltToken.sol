/**
 *Submitted for verification at Etherscan.io on 2022-01-12
*/

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



// MIT License
// Copyright (c) 2021 Bolt Global Media UK LTD

/// @title BOLT Token 2021 Staking Contract
/// @author Bolt Global Media UK LTD
/// @notice Implementation of BOLT 2021 Fixed + Dynamic Staking










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


contract StakeBoltToken is Ownable {
    using SafeERC20 for IERC20;

    // Per Account staking data structure
    struct stakingInfo {
        uint128 amount; // Amount of tokens staked by the account
        uint128 unclaimedDynReward; // Allocated but Unclaimed dynamic reward
        uint128 maxObligation; // The fixed reward obligation, assuming user holds until contract expiry.
        uint32 lastClaimTime; // used for delta time for claims
    }

    mapping(address => stakingInfo) userStakes;

    // **** Constants set in Constructor ****
    // ERC-20 Token we are staking
    IERC20 immutable token;

    // Timestamp of when staking rewards start, contract expires "rewardLifetime" after this.
    uint32 rewardStartTime;

    // Reward period of the contract
    uint32 immutable rewardLifetime;

    // Fixed APR, expressed in Basis Points (BPS - 0.01%)
    uint32 immutable fixedAPR;

    // max allowable number of tokens that can be Staked to the contract by all users
    // if exceeded - abort the txn
    uint128 immutable maxTokensStakable;

    //total number of tokens that has been staked by all the users.
    uint128 totalTokensStaked;

    //tokens remaining to be distributed among stake holders - initially deposited by the contract owner
    uint128 public fixedRewardsAvailable;

    // Total dynamic tokens deposited, but not yet allocated
    uint128 public dynamicTokensToAllocate;

    // Total of the fixed staking obligation (unclaimed tokens) to stakers, assuming they stake until the contract expires.
    // This amount is adjusted with each stake/unstake.
    uint128 fixedObligation;

    // Total Dynamic Tokens across all wallets
    uint128 public dynamicTokensAllocated;

    /// @notice Persist initial state on construction
    /// @param _tokenAddr contract address of the token being staked
    /// @param _maxStakable Maximum number of tokens stakable by the contract in basic units
    constructor(address _tokenAddr, uint128 _maxStakable) {
        token = IERC20(_tokenAddr);
        maxTokensStakable = _maxStakable;
        rewardLifetime = 365 days;
        fixedAPR = 500; // 5% in Basis Points
        rewardStartTime = 0; // Rewards are not started immediately
    }

    /// @notice Initiates the reward generation period
    /// @dev contract & rewards finish "rewardLifetime" after this.
    /// @return Starting Timestamp
    function setRewardStartTime() external onlyOwner returns (uint256) {
        require(rewardStartTime == 0, "Rewards already started");

        rewardStartTime = uint32(block.timestamp);
        return rewardStartTime;
    }

    /// @notice User function for staking tokens
    /// @param _amount Number of tokens to stake in basic units (n * 10**decimals)
    function stake(uint128 _amount) external {
        require(
            (rewardStartTime == 0) ||
                (block.timestamp <= rewardStartTime + rewardLifetime),
            "Staking period is over"
        );

        require(
            totalTokensStaked + _amount <= maxTokensStakable,
            "Max staking limit exceeded"
        );

        // Use .lastClaimTime == 0 as test for Account existence - initialise if a new address
        if (userStakes[msg.sender].lastClaimTime == 0) {
            userStakes[msg.sender].lastClaimTime = uint32(block.timestamp);
        }

        _claim(); //must claim before updating amount
        userStakes[msg.sender].amount += _amount;
        totalTokensStaked += _amount;

        _updateFixedObligation(msg.sender);

        token.safeTransferFrom(msg.sender, address(this), _amount);
        emit StakeTokens(msg.sender, _amount);
    }

    /// @notice Unstake tokens from the contract. Unstaking will also trigger a claim of all allocated rewards.
    /// @dev remaining tokens after unstake will accrue rewards based on the new balance.
    /// @param _amount Number of tokens to stake in basic units (n * 10**decimals)
    function unstake(uint128 _amount) external {
        require(userStakes[msg.sender].amount > 0, "Nothing to unstake");
        require(
            _amount <= userStakes[msg.sender].amount,
            "Unstake Amount greater than Stake"
        );
        _claim();
        userStakes[msg.sender].amount -= _amount;
        totalTokensStaked -= _amount;
        _updateFixedObligation(msg.sender);

        token.safeTransfer(msg.sender, _amount);
        emit UnstakeTokens(msg.sender, _amount);
    }

    /// @notice Claim all outstanding rewards from the contract
    function claim() external {
        require(
            rewardStartTime != 0,
            "Nothing to claim, Rewards have not yet started"
        );
        _claim();
        _updateFixedObligation(msg.sender);
    }

    /// @notice Update the end of contract obligation (user and Total)
    /// @dev This obligation determines the number of tokens claimable by owner at end of contract
    /// @param _address The address to update
    function _updateFixedObligation(address _address) private {
        // Use the entire rewardlifetime if rewards have not yet started
        uint128 newMaxObligation;
        uint128 effectiveTime;

        if (rewardStartTime == 0) {
            effectiveTime = 0;
        } else if (
            uint128(block.timestamp) > rewardStartTime + rewardLifetime
        ) {
            effectiveTime = rewardStartTime + rewardLifetime;
        } else {
            effectiveTime = uint128(block.timestamp);
        }

        newMaxObligation =
            (((userStakes[_address].amount * fixedAPR) / 10000) *
                (rewardStartTime + rewardLifetime - effectiveTime)) /
            rewardLifetime;

        // Adjust the total obligation
        fixedObligation =
            fixedObligation -
            userStakes[_address].maxObligation +
            newMaxObligation;
        userStakes[_address].maxObligation = newMaxObligation;
    }

    /// @notice private claim all accumulated outstanding tokens back to the callers wallet
    function _claim() private {
        // Return with no action if the staking period has not commenced yet.
        if (rewardStartTime == 0) {
            return;
        }

        uint32 lastClaimTime = userStakes[msg.sender].lastClaimTime;

        // If the user staked before the start time was set, update the stake time to be the now known start Time
        if (lastClaimTime < rewardStartTime) {
            lastClaimTime = rewardStartTime;
        }

        // Calculation includes Fixed 5% APR + Dynamic

        // Adjust claim time to never exceed the reward end date
        uint32 claimTime = (block.timestamp < rewardStartTime + rewardLifetime)
            ? uint32(block.timestamp)
            : rewardStartTime + rewardLifetime;

        uint128 fixedClaimAmount = (((userStakes[msg.sender].amount *
            fixedAPR) / 10000) * (claimTime - lastClaimTime)) / rewardLifetime;

        uint128 dynamicClaimAmount = userStakes[msg.sender].unclaimedDynReward;
        dynamicTokensAllocated -= dynamicClaimAmount;

        uint128 totalClaim = fixedClaimAmount + dynamicClaimAmount;

        require(
            fixedRewardsAvailable >= fixedClaimAmount,
            "Insufficient Fixed Rewards available"
        );

        if (totalClaim > 0) {
            token.safeTransfer(msg.sender, totalClaim);
        }

        if (fixedClaimAmount > 0) {
            fixedRewardsAvailable -= uint128(fixedClaimAmount); // decrease the tokens remaining to reward
        }
        userStakes[msg.sender].lastClaimTime = uint32(claimTime);

        if (dynamicClaimAmount > 0) {
            userStakes[msg.sender].unclaimedDynReward = 0;
        }
        // _updateFixedObligation(msg.sender); - refactored into stake, claim, unstake

        emit ClaimReward(msg.sender, fixedClaimAmount, dynamicClaimAmount);
    }

    /// Deposit tokens for the current epoch's dynamic reward, then Allocate at end of epoch
    /// Step 1 depositDynamicReward
    /// Step 2 allocatDynamicReward

    /// @notice owner Deposit deposit of dynamic reward for later Allocation
    /// @param _amount Number of tokens to deposit in basic units (n * 10**decimals)
    function depositDynamicReward(uint128 _amount) external onlyOwner {
        token.safeTransferFrom(msg.sender, address(this), _amount);

        dynamicTokensToAllocate += _amount;

        emit DepositDynamicReward(msg.sender, _amount);
    }

    /// Step 2 - each week, an off-chain process will call this function to allocate the rewards to the staked wallets
    /// A robust mechanism is required to be sure all addresses are allocated funds and that the allocation matches the tokens
    ///  previously deposited (in step 1)
    /// Multiple calls may be made per round if necessary (e.g. if the arrays grow too big)
    /// @param _addresses[] Array of addresses to receive
    /// @param _amounts[] Number of tokens to deposit in basic units (n * 10**decimals)
    /// @param _totalAmount total number of tokens to Allocate in this call
    function allocateDynamicReward(
        address[] memory _addresses,
        uint128[] memory _amounts,
        uint128 _totalAmount
    ) external onlyOwner {
        uint256 _calcdTotal = 0;

        require(
            _addresses.length == _amounts.length,
            "_addresses[] and _amounts[] must be the same length"
        );
        require(
            dynamicTokensToAllocate >= _totalAmount,
            "Not enough tokens available to allocate"
        );

        for (uint256 i = 0; i < _addresses.length; i++) {
            userStakes[_addresses[i]].unclaimedDynReward += _amounts[i];
            _calcdTotal += _amounts[i];
        }
        require(
            _calcdTotal == _totalAmount,
            "Sum of amounts does not equal total"
        );

        dynamicTokensToAllocate -= _totalAmount; // adjust remaining balance to allocate

        // ToDo - Remove after testing
        dynamicTokensAllocated += _totalAmount;
    }

    /// @notice Team deposit of the Fixed staking reward for later distribution
    /// @notice This transfer is intended be done once, in full, before the commencement of the staking period
    /// @param _amount Number of tokens to deposit in basic units (n * 10**decimals)
    function depositFixedReward(uint128 _amount)
        external
        onlyOwner
        returns (uint128)
    {
        fixedRewardsAvailable += _amount;

        token.safeTransferFrom(msg.sender, address(this), _amount);

        emit DepositFixedReward(msg.sender, _amount);

        return fixedRewardsAvailable;
    }

    /// @notice Withdraw unused Fixed reward tokens, deposited at the beginning of the contract period.
    /// @notice Withdrawal is allowed only after the contract period has elapsed and then only allow withdrawal of unallocated tokens.
    function withdrawFixedReward() external onlyOwner returns (uint256) {
        require(
            block.timestamp > rewardStartTime + rewardLifetime,
            "Staking period is not yet over"
        );
        require(
            fixedRewardsAvailable >= fixedObligation,
            "Insufficient Fixed Rewards available"
        );
        uint128 tokensToWithdraw = fixedRewardsAvailable - fixedObligation;

        fixedRewardsAvailable -= tokensToWithdraw;

        token.safeTransfer(msg.sender, tokensToWithdraw);

        emit WithdrawFixedReward(msg.sender, tokensToWithdraw);

        return tokensToWithdraw;
    }

    //Inspection methods

    // Contract Inspection methods
    function getRewardStartTime() external view returns (uint256) {
        return rewardStartTime;
    }

    function getMaxStakingLimit() public view returns (uint256) {
        return maxTokensStakable;
    }

    function getRewardLifetime() public view returns (uint256) {
        return rewardLifetime;
    }

    function getTotalStaked() external view  returns (uint256) {
        return totalTokensStaked;
    }

    function getFixedObligation() public view returns (uint256) {
        return fixedObligation;
    }

    // Account Inspection Methods
    function getTokensStaked(address _addr) public view returns (uint256) {
        return userStakes[_addr].amount;
    }

    function getStakedPercentage(address _addr)
        public
        view
        returns (uint256, uint256)
    {
        return (totalTokensStaked, userStakes[_addr].amount);
    }

    function getStakeInfo(address _addr)
        public
        view
        returns (
            uint128 amount, // Amount of tokens staked by the account
            uint128 unclaimedFixedReward, // Allocated but Unclaimed fixed reward
            uint128 unclaimedDynReward, // Allocated but Unclaimed dynamic reward
            uint128 maxObligation, // The fixed reward obligation, assuming user holds until contract expiry.
            uint32 lastClaimTime, // used for delta time for claims
            uint32 claimtime // show the effective claim time
        )
    {
        //added to view the dynamic obligation asso. with addr.
        uint128 fixedClaimAmount;
        uint32 claimTime;
        stakingInfo memory s = userStakes[_addr];
        if (rewardStartTime > 0) {
            claimTime = (block.timestamp < rewardStartTime + rewardLifetime)
                ? uint32(block.timestamp)
                : rewardStartTime + rewardLifetime;

            fixedClaimAmount =
                (((s.amount * fixedAPR) / 10000) *
                    (claimTime - s.lastClaimTime)) /
                rewardLifetime;
        } else {
            // rewards have not started
            fixedClaimAmount = 0;
        }

        return (
            s.amount,
            fixedClaimAmount,
            s.unclaimedDynReward,
            s.maxObligation,
            s.lastClaimTime,
            claimTime
        );
    }

    function getStakeTokenAddress() public view returns (IERC20) {
        return token;
    }

    // Events
    event DepositFixedReward(address indexed from, uint256 amount);
    event DepositDynamicReward(address indexed from, uint256 amount);
    event WithdrawFixedReward(address indexed to, uint256 amount);

    event StakeTokens(address indexed from, uint256 amount);
    event UnstakeTokens(address indexed to, uint256 amount);
    event ClaimReward(
        address indexed to,
        uint256 fixedAmount,
        uint256 dynamicAmount
    );
}