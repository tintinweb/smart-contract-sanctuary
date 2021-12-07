/**
 *Submitted for verification at Etherscan.io on 2021-12-06
*/

// File: contracts/ITOKENLOCK.sol

/**
* @dev Inteface for the token lock features in this contract
*/
interface ITOKENLOCK {
    /**
     * @dev Emitted when the token lock is initialized  
     * `tokenHolder` is the address the lock pertains to
     *  `amountLocked` is the amount of tokens locked 
     *  `time` is the (initial) time at which tokens were locked
     *  `unlockPeriod` is the time interval at which tokens become unlockedPerPeriod
     *  `unlockedPerPeriod` is the amount of token unlocked earch unlockPeriod
     */
    event  NewTokenLock(address tokenHolder, uint256 amountLocked, uint256 time, uint256 unlockPeriod, uint256 unlockedPerPeriod);
    /**
     * @dev Emitted when the token lock is updated  to be more strict
     * `tokenHolder` is the address the lock pertains to
     *  `amountLocked` is the amount of tokens locked 
     *  `time` is the (initial) time at which tokens were locked
     *  `unlockPeriod` is the time interval at which tokens become unlockedPerPeriod
     *  `unlockedPerPeriod` is the amount of token unlocked earch unlockPeriod
     */
    event  UpdateTokenLock(address tokenHolder, uint256 amountLocked, uint256 time, uint256 unlockPeriod, uint256 unlockedPerPeriod);
    
    /**
     * @dev Lock `baseTokensLocked_` held by the caller with `unlockedPerEpoch_` tokens unlocking each `unlockEpoch_`
     *
     *
     * Emits an {NewTokenLock} event indicating the updated terms of the token lockup.
     *
     * Requires msg.sender to:
     *
     * - Must not be a prevoius lock for this address. If so, it must be first cleared with a call to {clearLock}.
     * - Must have at least a balance of `baseTokensLocked_` to lock
     * - Must provide non-zero `unlockEpoch_`
     * - Must have at least `unlockedPerEpoch_` tokens to unlock 
     *  - `unlockedPerEpoch_` must be greater than zero
     */
    
    function newTokenLock(uint256 baseTokensLocked_, uint256 unlockEpoch_, uint256 unlockedPerEpoch_) external;
    
    /**
     * @dev Reset the lock state
     *
     * Requirements:
     *
     * - msg.sender must not have any tokens locked, currently
     */
    function clearLock() external;
    
    /**
     * @dev Returns the amount of tokens that are unlocked i.e. transferrable by `who`
     *
     */
    function balanceUnlocked(address who) external view returns (uint256 amount);
    /**
     * @dev Returns the amount of tokens that are locked and not transferrable by `who`
     *
     */
    function balanceLocked(address who) external view returns (uint256 amount);

    /**
     * @dev Reduce the amount of token unlocked each period by `subtractedValue`
     * 
     * Emits an {UpdateTokenLock} event indicating the updated terms of the token lockup.
     * 
     * Requires: 
     *  - msg.sender must have tokens currently locked
     *  - `subtractedValue` is greater than 0
     *  - cannot reduce the unlockedPerEpoch to 0
     *
     *  NOTE: As a side effect resets the baseTokensLocked and lockTime for msg.sender 
     */
    function decreaseUnlockAmount(uint256 subtractedValue) external;
    /**
     * @dev Increase the duration of the period at which tokens are unlocked by `addedValue`
     * this will have the net effect of slowing the rate at which tokens are unlocked
     * 
     * Emits an {UpdateTokenLock} event indicating the updated terms of the token lockup.
     * 
     * Requires: 
     *  - msg.sender must have tokens currently locked
     *  - `addedValue` is greater than 0
     * 
     *  NOTE: As a side effect resets the baseTokensLocked and lockTime for msg.sender 
     */
    function increaseUnlockTime(uint256 addedValue) external;
    /**
     * @dev Increase the number of tokens locked by `addedValue`
     * i.e. locks up more tokens.
     * 
     *      
     * Emits an {UpdateTokenLock} event indicating the updated terms of the token lockup.
     * 
     * Requires: 
     *  - msg.sender must have tokens currently locked
     *  - `addedValue` is greater than zero
     *  - msg.sender must have sufficient unlocked tokens to lock
     * 
     *  NOTE: As a side effect resets the baseTokensLocked and lockTime for msg.sender 
     *
     */
    function increaseTokensLocked(uint256 addedValue) external;

}
// File: contracts/ISTAKINGPROXY.sol

interface ISTAKINGPROXY{
    /**
    * @dev a callback to perform the actual transfer of tokens to the actual staking contract 
    * Precondition: the user doing the staking MUST approve this contract or we'll revert
    **/
    function proxyTransfer(address from, uint256 amount) external;
}
// File: contracts/ISTAKING.sol

/**
* @dev Public interface for the staking functions 
*/
interface ISTAKING{
    /**
    * @dev Stakes a certain amount of tokens, this will attempt to transfer the given amount from the caller.
    * It will count the actual number of tokens trasferred as being staked
    * MUST trigger Staked event.
    **/
    function stake(uint256 amount) external returns (uint256);

    /**
    * @dev Stakes a certain amount of tokens on behalf of address `user`, 
    * this will attempt to transfer the given amount from the caller.
    * caller must have approved this contract, previously. 
    * It will count the actual number of tokens trasferred as being staked
    * MUST trigger Staked event.
    * Returns the number of tokens actually staked
    **/
    function stakeFor(address voter, address staker, uint256 amount) external returns (uint256);

    /**
    * @dev Unstakes a certain amount of tokens, this SHOULD return the given amount of tokens to the caller, 
    * MUST trigger Unstaked event.
    */
    function unstake(uint256 amount) external;

    /**
    * @dev Unstakes a certain amount of tokens currently staked on behalf of address `user`, 
    * this SHOULD return the given amount of tokens to the caller
    * caller is responsible for returning tokens to `user` if applicable.
    * MUST trigger Unstaked event.
    */
    function unstakeFor(address voter, address staker, uint256 amount) external;

    /**
    * @dev Returns the current total of tokens staked for address addr.
    */
    function totalStakedFor(address addr) external view returns (uint256);

    /**
    * @dev Returns the current tokens staked by address `delegate` for address `user`.
    */
    function stakedFor(address user, address delegate) external view returns (uint256);

    /**
    * @dev Returns the number of current total tokens staked.
    */
    function totalStaked() external view returns (uint256);

    /**
    * @dev address of the token being used by the staking interface
    */
    function token() external view returns (address);

    /** Event
    * `voter` the address that will cast votes weighted by the number of tokens staked for `voter`
    * `staker` the address staking for `voter` - tokens are transferred from & returned to `staker`
    *  `proxy` is the Staking Proxy contract that is approved by `staker` to perform the token transfer
    * `amount` is the value of tokens to be staked
    **/
    event Staked(address indexed voter, address indexed staker, address proxy, uint256 amount);
    /** Event
    * `voter` the address that will cast votes weighted by the number of tokens staked for `voter`
    * `staker` the address staking for `voter` - tokens are transferred from & returned to `staker`
    *  `proxy` is the Staking Proxy contract that is approved by `staker` to perform the token transfer
    * `amount` is the value of tokens to be staked
    **/
    event Unstaked(address indexed voter, address indexed staker, address proxy, uint256 amount);
}
// File: @openzeppelin/contracts/utils/Address.sol


// OpenZeppelin Contracts v4.4.0 (utils/Address.sol)

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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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

// File: @openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol


// OpenZeppelin Contracts v4.4.0 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;



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

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts v4.4.0 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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
abstract contract ReentrancyGuard {
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

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
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

// File: contracts/VotingStaking.sol

pragma solidity ^0.8.4;







struct Stake{
    uint256 totalStake;
    mapping (address => uint256) stakedAmount;
}

/** 
* @dev Computes voting power based on staked and locked tokens.
* The deployer is responsible for supplying a token_ implementing ERC20 and ILOCKER. 
* The deployer is trusted to know & have verified the token code token code is appropriate.
* A scaling factor is specified as a uint8 array of bytes which serves to 
* reduce or increase the voting power of a class of token holder (locked tokens). 
* The scaling factor changes over time, and is looked up based on the current epoch
*/
contract VotingPower is ReentrancyGuard, ISTAKING{
    //the token used for staking. Implements ILOCKER. It is trusted & known code.
    IERC20 immutable _token;
    //store the number of tokens staked by each address
    mapping (address => Stake) public stakes;

    //keep track of the sum of staked tokens
    uint256 private _totalStaked;

    using SafeERC20 for IERC20;

    //locked tokens have their voting power scaled by this percentage.
    bytes voteScalingPercent;
    //the time at which this contract was deployed (unix time)
    uint256 creationTime;
    //the time each voting epoch lasts in seconds
    uint256 epochLength;

    /**
    * @dev initialize the contract
    * @param token_ is the token that is staked or locked to get voting power
    * @param scaling_ is an array of uint8 (bytes) percent voting power discounts for each epoch
    * @param epoch_ is the duration of one epoch in seconds
    **/
    constructor(address token_, bytes memory scaling_, uint256 epoch_){
        require(epoch_ > 0);
        _token = IERC20(token_);
        creationTime = block.timestamp;
        voteScalingPercent = scaling_;
        epochLength = epoch_;
    }

    /**
    * @dev Returns the voting power for `who`
    * @param who the address whose votingPower to compute
    * @return the voting power for `who`
    **/
    function votingPower(address who) public view returns (uint256) {
        return _votingPowerStaked(who) + _votingPowerLocked(who);
    }

    /**
    * @dev Returns the voting power for `who` due to staked tokens
    * @param who the address whose votingPower to compute
    * @return the voting power for who    
    **/
    function _votingPowerStaked(address who) internal view returns (uint256) {
        return stakes[who].totalStake;
    }
    /**
    * @dev Returns the voting power for `who` due to locked tokens
    * @param who the address whose votingPower to compute
    * @return the voting power for who    
    * Locked tokens scaled discounted voting power as defined by voteScalingPercent
    **/
    function _votingPowerLocked(address who) internal view returns (uint256) {
        uint256 epoch = _currentEpoch();
        if(epoch >= voteScalingPercent.length){
            return ITOKENLOCK(address(_token)).balanceLocked(who);
        }
        return ITOKENLOCK(address(_token)).balanceLocked(who) * (uint8)(voteScalingPercent[epoch])/100.0;
    }
    /**
    * @dev Returns the current epoch used to look up the scaling factor
    * @return the current epoch
    **/
    function _currentEpoch() internal view returns (uint256) {
        return (block.timestamp - creationTime)/epochLength;
    }

    /**
    * @dev Stakes the specified `amount` of tokens, this will attempt to transfer the given amount from the caller.
    * It will count the actual number of tokens trasferred as being staked
    * MUST trigger Staked event.
    * Returns the number of tokens actually staked
    **/
    function stake(uint256 amount) external override nonReentrant returns (uint256){
        require(amount > 0, "Cannot Stake 0");
        uint256 previousAmount = IERC20(_token).balanceOf(address(this));
        _token.safeTransferFrom( msg.sender, address(this), amount);
        uint256 transferred = IERC20(_token).balanceOf(address(this)) - previousAmount;
        require(transferred > 0);
        stakes[msg.sender].totalStake = stakes[msg.sender].totalStake + transferred;
        stakes[msg.sender].stakedAmount[msg.sender] = stakes[msg.sender].stakedAmount[msg.sender] + transferred;
        _totalStaked = _totalStaked + transferred;
        emit Staked(msg.sender, msg.sender, msg.sender, transferred);
        return transferred;
    }

    /**
    * @dev Stakes the specified `amount` of tokens from `staker` on behalf of address `voter`, 
    * this will attempt to transfer the given amount from the caller.
    * Must be called from an ISTAKINGPROXY contract that has been approved by `staker`.
    * Tokens will be staked towards the voting power of address `voter` allowing one address to delegate voting power to another. 
    * It will count the actual number of tokens trasferred as being staked
    * MUST trigger Staked event.
    * Returns the number of tokens actually staked
    **/
    function stakeFor(address voter, address staker, uint256 amount) external override nonReentrant returns (uint256){
        require(amount > 0, "Cannot Stake 0");
        uint256 previousAmount = IERC20(_token).balanceOf(address(this));
        //_token.safeTransferFrom( msg.sender, address(this), amount);
        ISTAKINGPROXY(msg.sender).proxyTransfer(staker, amount);
        //verify that amount that the proxy contract transferred the amount
        uint256 transferred = IERC20(_token).balanceOf(address(this)) - previousAmount;
        require(transferred > 0);
        stakes[voter].totalStake = stakes[voter].totalStake + transferred;
        stakes[voter].stakedAmount[msg.sender] = stakes[voter].stakedAmount[msg.sender] + transferred;
        _totalStaked = _totalStaked + transferred;
        emit Staked(voter, staker, msg.sender, transferred);
        return transferred;
    }
    /**
    * @dev Unstakes the specified `amount` of tokens, this SHOULD return the given amount of tokens to the caller, 
    * MUST trigger Unstaked event.
    */
    function unstake(uint256 amount) external override nonReentrant{
        require(amount > 0, "Cannot UnStake 0");
        require(amount <= stakes[msg.sender].stakedAmount[msg.sender], "INSUFFICENT TOKENS TO UNSTAKE");
        _token.safeTransfer( msg.sender, amount);
        stakes[msg.sender].totalStake = stakes[msg.sender].totalStake - amount;
        stakes[msg.sender].stakedAmount[msg.sender] = stakes[msg.sender].stakedAmount[msg.sender] - amount;
        _totalStaked = _totalStaked - amount;
        emit Unstaked(msg.sender,msg.sender, msg.sender, amount);
    }

    /**
    * @dev Unstakes the specified `amount` of tokens currently staked by `staker` on behalf of `voter`, 
    * this SHOULD return the given amount of tokens to the calling contract
    * calling contract is responsible for returning tokens to `staker` if applicable.
    * MUST trigger Unstaked event.
    */
    function unstakeFor(address voter, address staker, uint256 amount) external override nonReentrant{
        require(amount > 0, "Cannot UnStake 0");
        require(amount <= stakes[voter].stakedAmount[msg.sender], "INSUFFICENT TOKENS TO UNSTAKE");
        //_token.safeTransfer( msg.sender, amount);
        _token.safeTransfer(staker, amount);
        stakes[voter].totalStake = stakes[voter].totalStake - amount;
        stakes[voter].stakedAmount[msg.sender] = stakes[voter].stakedAmount[msg.sender] - amount;
        _totalStaked = _totalStaked - amount;
        emit Unstaked(voter, staker, msg.sender, amount);
    }

    /**
    * @dev Returns the current total of tokens staked for address `addr`.
    */
    function totalStakedFor(address addr) external override view returns (uint256){
        return stakes[addr].totalStake;
    }

    /**
    * @dev Returns the current tokens staked by address `staker` for address `voter`.
    */
    function stakedFor(address voter, address staker) external override view returns (uint256){
        return stakes[voter].stakedAmount[staker];
    }
    /**
    * @dev Returns the number of current total tokens staked.
    */
    function totalStaked() external override view returns (uint256){
        return _totalStaked;
    }
    /**
    * @dev address of the token being used by the staking interface
    */
    function token() external override view returns (address){
        return address(_token);
    }
   
    

}