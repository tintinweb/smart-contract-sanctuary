/**
 *Submitted for verification at snowtrace.io on 2022-01-22
*/

// File: @openzeppelin/contracts/utils/Address.sol



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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol



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

// File: contracts/StakingStorage.sol


pragma solidity ^0.8.0;


contract StakingStorage {

    /**
     * @dev Struct to store user data for each pool
     * @dev `unstakeRequestTime` only with be set to different than zero during withdrawal delays (if the pool have one)
     */
    struct UserInfo {
        uint256 amount;
        uint256 depositTime;
        uint256 pendingRewards;
        uint256 rewardPerTokenPaid;
        uint256 unstakeRequestTime;
        uint256 withdrawn;
        address delegatee;
    }

    /**
     * @dev Struct to store pool params
     * @dev `lockPeriod` is a fixed timestamp that need to be achieved to user deposit amount be withdrawable
     * @dev `withdrawDelay` is a time locking period that starts after the user makes a withdraw request, after it finish a new withdraw request will fullfil the withdraw
     * @dev `vestingPeriod` is a time period that starts after the `lockPeriod` that will linear release the withdrawable amount
     */
    struct PoolInfo {
        // General data
        address stakingToken;
        uint256 depositedAmount;
        // Rewards data and params
        uint256 lastUpdateTime;
        uint256 rewardPerTokenStored;
        uint256 rewardsDuration;
        uint256 rewardRate;
        uint256 periodFinish;
        // Vesting params
        uint256 lockPeriod;
        uint256 withdrawDelay;
        uint256 vestingPeriod;
        // Gov params
        uint256 votingMultiplier;
    }

    string public constant name = "Kassandra Staking";

    address public kacyAddress;
    IERC20 public kacy;

    /// @dev Array of pool infos
    PoolInfo[] public poolInfo;

    /// @dev A map to access the user info for each account: PoolId => Address => UserInfo
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;

    /************************** Checkpoints ******************************/

    /// @dev A checkpoint for marking the voting power from a given block
    struct Checkpoint {
        uint32 fromBlock;
        uint256 votes;
    }

    /// @dev A aggregated record of the total voting power of all accounts
    uint256 public totalVotes;

    /// @dev A record of votes checkpoints for each account, by index
    mapping (address => mapping (uint32 => Checkpoint)) public checkpoints;

    /// @dev The number of checkpoints for each account
    mapping (address => uint32) public numCheckpoints;

    /// @notice The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

    /// @notice The EIP-712 typehash for the delegation struct used by the contract
    bytes32 public constant DELEGATION_TYPEHASH = keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry,uint256 pid)");

    /// @notice The EIP-712 typehash for the permit struct used by the contract
    bytes32 public constant PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    /// @notice A record of states for signing / validating signatures
    mapping (address => uint) public nonces;

}

// File: contracts/StakingGov.sol


pragma solidity ^0.8.0;


contract StakingGov is StakingStorage {

    /* ========== VIEWS ========== */

    /**
     * @notice Gets the current sum of votes balance all accounts in all pools
     * @return The number of current total votes
     */
    function getTotalVotes() external view returns (uint256) {
        return totalVotes;
    }

    /**
     * @notice Gets the current votes balance for `account`
     * @param account The address to get votes balance
     * @return The number of current votes for `account`
     */
    function getCurrentVotes(address account) external view returns (uint256) {
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
    function getPriorVotes(address account, uint blockNumber) public view returns (uint256) {
        require(blockNumber < block.number, "ERR_VOTES_NOT_YET_DETERMINED");

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

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
     * @notice Delegate votes from `msg.sender` in `pid` to `delegatee`
     * @param pid Pool id to be staked in
     * @param delegatee The address to delegate votes to
     */
    function delegate(uint256 pid, address delegatee) public {
        return _delegate(pid, msg.sender, delegatee);
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
    function delegateBySig(uint256 pid, address delegatee, uint nonce, uint expiry, uint8 v, bytes32 r, bytes32 s) public {
        bytes32 domainSeparator = keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name)), _getChainId(), address(this)));
        bytes32 structHash = keccak256(abi.encode(DELEGATION_TYPEHASH, delegatee, nonce, expiry, pid));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), "ERR_INVALID_SIGNATURE");
        require(nonce == nonces[signatory]++, "ERR_INVALID_NONCE");
        require(block.timestamp <= expiry, "ERR_SIGNATURE_EXPIRED");
        return _delegate(pid, signatory, delegatee);
    }


    function _delegate(uint256 pid, address delegator, address delegatee) internal {
        UserInfo storage user = userInfo[pid][delegator];
        address currentDelegate = user.delegatee;
        uint256 delegatorVotes = _getPoolDelegatorVotes(pid, delegator);
        user.delegatee = delegatee;

        emit DelegateChanged(delegator, currentDelegate, delegatee);

        _moveDelegates(currentDelegate, delegatee, delegatorVotes);
    }

    function _moveDelegates(address srcRep, address dstRep, uint256 votes) internal {
        if (srcRep != dstRep && votes > 0) {
            if (srcRep != address(0)) {
                _decreaseVotingPower(srcRep, votes);
            }
            if (dstRep != address(0)) {
                _increaseVotingPower(dstRep, votes);
            }
        }
    }

    function _decreaseVotingPower(address delegatee, uint256 votes) internal {
            uint32 nCheckpoints = numCheckpoints[delegatee];
            uint256 oldVotingPower = nCheckpoints > 0 ? checkpoints[delegatee][nCheckpoints - 1].votes : 0;
            uint256 newVotingPower = oldVotingPower - votes;
            totalVotes -= votes;
            _writeCheckpoint(delegatee, nCheckpoints, oldVotingPower, newVotingPower);
    }

    function _increaseVotingPower(address delegatee, uint256 votes) internal {
            uint32 nCheckpoints = numCheckpoints[delegatee];
            uint256 oldVotingPower = nCheckpoints > 0 ? checkpoints[delegatee][nCheckpoints - 1].votes : 0;
            uint256 newVotingPower = oldVotingPower + votes;
            totalVotes += votes;
            _writeCheckpoint(delegatee, nCheckpoints, oldVotingPower, newVotingPower);
    }

    function _getPoolDelegatorVotes(uint256 pid, address delegator) internal view returns(uint256) {
        PoolInfo storage pool = poolInfo[pid];
        UserInfo storage user = userInfo[pid][delegator];

        uint256 delegatorVotes;

        if (user.unstakeRequestTime == 0) {
            delegatorVotes = user.amount * pool.votingMultiplier;
        } else {
            delegatorVotes = user.amount;
        }

        return delegatorVotes;
    }

    function _unboostVotingPower(uint256 pid, address delegator) internal {
        PoolInfo storage pool = poolInfo[pid];
        UserInfo storage user = userInfo[pid][delegator];
        address delegatee = user.delegatee;
        uint256 lostVotingPower = user.amount * (pool.votingMultiplier - 1);
        _decreaseVotingPower(delegatee, lostVotingPower);
    }

    function _boostVotingPower(uint256 pid, address delegator) internal {
        PoolInfo storage pool = poolInfo[pid];
        UserInfo storage user = userInfo[pid][delegator];
        address delegatee = user.delegatee;
        uint256 recoveredVotingPower = user.amount * (pool.votingMultiplier - 1);
        _increaseVotingPower(delegatee, recoveredVotingPower);
    }

    function _writeCheckpoint(address delegatee, uint32 nCheckpoints, uint256 oldVotes, uint256 newVotes) internal {
      uint32 blockNumber = _safe32(block.number, "StakingGov::_writeCheckpoint: block number exceeds 32 bits");

      if (nCheckpoints > 0 && checkpoints[delegatee][nCheckpoints - 1].fromBlock == blockNumber) {
          checkpoints[delegatee][nCheckpoints - 1].votes = newVotes;
      } else {
          checkpoints[delegatee][nCheckpoints] = Checkpoint(blockNumber, newVotes);
          numCheckpoints[delegatee] = nCheckpoints + 1;
      }

      emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
    }

    /* ========== PURES ========== */

    function _safe32(uint n, string memory errorMessage) internal pure returns (uint32) {
        require(n < 2**32, errorMessage);
        return uint32(n);
    }

    function _getChainId() internal view returns (uint) {
        uint256 chainId;
        assembly { chainId := chainid() }
        return chainId;
    }

    /* ========== EVENTS ========== */

    /// @notice An event thats emitted when the minter address is changed
    event MinterChanged(address minter, address newMinter);

    /// @notice An event thats emitted when an account changes its delegate
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    /// @notice An event thats emitted when a delegate account's vote balance changes
    event DelegateVotesChanged(address indexed delegate, uint previousBalance, uint newBalance);

    /// @notice The standard EIP-20 transfer event
    event Transfer(address indexed from, address indexed to, uint256 amount);

    /// @notice The standard EIP-20 approval event
    event Approval(address indexed owner, address indexed spender, uint256 amount);

}
// File: @openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol



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

// File: @openzeppelin/contracts/utils/Context.sol



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
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol



pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/security/Pausable.sol



pragma solidity ^0.8.0;


/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
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
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
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
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
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

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol



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

// File: contracts/Staking.sol


pragma solidity ^0.8.0;






contract Staking is StakingGov, Pausable, ReentrancyGuard, Ownable {

    using SafeERC20 for IERC20;

    /* ========== VIEWS ========== */

    /**
     * @notice Gets the total deposited amount in the pool `pid`
     * @param pid The pool id to get the deposited amount from
     * @return Deposited amount in the pool
     */
    function depositedAmount(uint256 pid) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[pid];
        return pool.depositedAmount;
    }

    /**
     * @notice Gets how much rewards will be distributed through the pool `pid` during the whole distribution period
     * @param pid The pool id to get the rewards from
     * @return The amount that the pool `pid` will distribute
     */
    function getRewardForDuration(uint256 pid) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[pid];
        return pool.rewardRate * pool.rewardsDuration;
    }

    /**
     * @notice Gets the balance of the address `account` in the pool `pid`
     * @param pid The pool id to get the balance from
     * @param account The address to get the balance
     * @return Deposited amount in the pool `pid` by `account`
     */
    function balanceOf(uint256 pid, address account) public view returns (uint256) {
        return userInfo[pid][account].amount;
    }

    /**
     * @notice Gets the last time that the pool `pid` was giving rewards
     * @dev Stops increasing when `pool.rewardsDuration` ends
     * @param pid The pool id to get the time from
     * @return The timestamp of whether the pool was last updated
     */
    function lastTimeRewardApplicable(uint pid) public view returns (uint256) {
        PoolInfo storage pool = poolInfo[pid];
        return _min(block.timestamp, pool.periodFinish);
    }

    /**
     * @notice Gets the reward rate per token deposited in the pool `pid`
     * @param pid The pool id to get the reward per token from
     * @return The reward rate per token for the pool `pid`
     */
    function rewardPerToken(uint pid) public view returns (uint256) {
        PoolInfo storage pool = poolInfo[pid];
        if (pool.depositedAmount == 0) {
            return pool.rewardPerTokenStored;
        } else if (pool.lastUpdateTime > lastTimeRewardApplicable(pid)) {
            return 0;
        }
        return
            pool.rewardPerTokenStored + (
                (lastTimeRewardApplicable(pid) - pool.lastUpdateTime) * pool.rewardRate * (1e18) / pool.depositedAmount
            );
    }

    /**
     * @notice Gets the claimable rewards for `account` in the pool `pid`
     * @dev Unstaking stops rewards
     * @param pid The pool id to get the rewards earned from
     * @param account The address to get the rewards earned from
     * @return The claimable rewards for `account` in the pool `pid`
     */
    function earned(uint256 pid, address account) public view returns (uint256) {
        UserInfo storage user = userInfo[pid][account];
        if (user.unstakeRequestTime != 0) {
            return user.pendingRewards;
        } else {
            return user.amount * (rewardPerToken(pid) - user.rewardPerTokenPaid) / 1e18  + user.pendingRewards;
        }
    }

    /**
     * @notice Gets the timestamp that the tokens will be locked until
     * @dev This doesnt take withdrawal delay into account
     * @param pid The pool id to get the timestamp from
     * @param account The address to get the timestamp from
     * @return The lock timestamp of `account` in the pool `pid`
     */
    function lockUntil(uint256 pid, address account) public view returns (uint256) {
        PoolInfo storage pool = poolInfo[pid];
        UserInfo storage user = userInfo[pid][account];
        return user.depositTime + pool.lockPeriod;
    }

    /**
     * @notice Gets wether the `account` is locked by the pool locking period
     * @dev This doesnt take withdrawal delay into account
     * @param pid The pool id to check
     * @param account The address to check
     * @return A boolean of wheter the `account` is locked or not in pool `pid`
     */
    function locked(uint256 pid, address account) public view returns (bool) {
        return (block.timestamp < lockUntil(pid, account));
    }

    /**
     * @notice Gets the timestamp that the withdrawal delay ends
     * @dev For pools with withdrawal delay the returned value keep incresing until unstake requested
     * @param pid The pool id to check
     * @param account The address to check
     * @return The staked timestamp of `account` in the pool `pid`
     */
    function stakedUntil(uint256 pid, address account) public view returns (uint256) {
        PoolInfo storage pool = poolInfo[pid];
        UserInfo storage user = userInfo[pid][account];
        uint256 delayedTime; 
        if (pool.withdrawDelay == 0) {
            // If no withdrawDelay
            delayedTime = 0;
        } else if (user.unstakeRequestTime == 0) {
            // If withdrawDelay and no withdraw request
            delayedTime = block.timestamp + pool.withdrawDelay;
        } else {
            // If withdrawDelay and already requested withdraw a previous time
            delayedTime = user.unstakeRequestTime + pool.withdrawDelay;
        }
        return delayedTime;
    }

    /**
     * @notice Gets wether the `account` needs to be unstacked to be withdrawable
     * @dev Checks if the pool has withdrawal delay and unstake hasnt been requested yet
     * @param pid The pool id to check
     * @param account The address to check
     * @return A boolean of wheter unstake needs to be called
     */
    function needUnstake(uint256 pid, address account) public view returns (bool) {
        PoolInfo storage pool = poolInfo[pid];
        UserInfo storage user = userInfo[pid][account];
        return (pool.withdrawDelay != 0 && user.unstakeRequestTime == 0);
    }

    /**
     * @notice Gets when the `account` has a running withdrawal delay
     * @dev Returns false for pools that withdrawal delay has ended
     * @param pid The pool id to check
     * @param account The address to check
     * @return A boolean of wheter the `account` is unstaking `pid`
     */
    function unstaking(uint256 pid, address account) public view returns (bool) {
        PoolInfo storage pool = poolInfo[pid];
        if (pool.withdrawDelay == 0) {
            return false;
        } else if (needUnstake(pid, account)) {
            return false;
        } else {
            return (block.timestamp < stakedUntil(pid, account));
        }
    }

    /**
     * @notice Gets whether the `account` can withdraw from pool `pid`
     * @dev If pool have withdraw delay, then ensure it has been runned and finished, else calls `lockUntil`
     * @param pid The pool id to check
     * @param account The address to check
     * @return A boolean of wheter the `account` can withdraw from pool `pid`
     */
    function withdrawable(uint256 pid, address account) public view returns (bool) {
        PoolInfo storage pool = poolInfo[pid];
        if (pool.withdrawDelay == 0 && pool.lockPeriod == 0) {
            return true;
        } else if (needUnstake(pid, account)) {
            return false;
        } else {
            return (!locked(pid, account) && !unstaking(pid, account));
        }
    }

    /**
     * @notice Gets the available withdrawable amount for `account` in the pool `pid`
     * @dev If not withdawable return 0, if lock and vesting period ended return the full amount,
     * else linear release by the vesting period
     * @param pid The pool id to get the timestamp from
     * @param account The address to get the timestamp from
     * @return The available withdrawable amount for `account` in the pool `pid`
     */
    function availableWithdraw(uint256 pid, address account) public view returns (uint256) {
        PoolInfo storage pool = poolInfo[pid];
        UserInfo storage user = userInfo[pid][account];
        if (!withdrawable(pid, account)) {
            return 0;
        } else if (block.timestamp >= user.depositTime + pool.lockPeriod + pool.vestingPeriod) {
            return user.amount;
        } else {
            return (user.amount + user.withdrawn) * (
                block.timestamp - user.depositTime - pool.lockPeriod )/(pool.vestingPeriod
            ) - user.withdrawn;
        }
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
     * @notice Stake tokens to the pool `pid`
     * @dev `StakeFor` and `delegatee` can be passed as `address(0)` and the `stake` will work in a sensible way
     * @param pid Pool id to be staked in
     * @param amount The amount of tokens to stake
     * @param stakeFor The address to stake the tokens for or 0x0 if staking for oneself
     * @param delegatee The address of the delegatee or 0x0 if there is none
     */
    function stake(
        uint256 pid,
        uint256 amount,
        address stakeFor,
        address delegatee
        ) external nonReentrant whenNotPaused updateReward(pid, msg.sender)
    {
        require(amount > 0, "ERR_CAN_NOT_STAKE_ZERO");

        // Stake for the sender if not specified otherwise.
        if (stakeFor == address(0)) {
            stakeFor = msg.sender;
        }

        // Delegate for stakeFor if not specified otherwise.
        if (delegatee == address(0)) {
            delegatee = stakeFor;
        }

        PoolInfo storage pool = poolInfo[pid];
        UserInfo storage user = userInfo[pid][stakeFor];
        IERC20 stakingToken = IERC20(pool.stakingToken);

        if (stakeFor != msg.sender) {
            // Avoid third parties to reset stake vestings
            require(user.amount == 0, "ERR_STAKE_FOR_LIVE_USER");
        }

        //  Reset withdrawDelay due to new stake
        if (pool.withdrawDelay != 0 && user.unstakeRequestTime != 0){
            user.unstakeRequestTime = 0;
            _boostVotingPower(pid, stakeFor);
        }

        // Update voting power if there is a new delegatee
        address previousDelegatee = user.delegatee;
        if (previousDelegatee != delegatee) {
            uint256 previousVotingPower = user.amount * pool.votingMultiplier;
            _decreaseVotingPower(previousDelegatee, previousVotingPower);
            _increaseVotingPower(delegatee, previousVotingPower);
            // Update delegatee.
            user.delegatee = delegatee;

        }

        // Update stake parms
        pool.depositedAmount = pool.depositedAmount + amount;
        user.amount = user.amount + amount;
        // Beware, depositing in a pool with running vesting resets it
        user.depositTime = block.timestamp;
        user.withdrawn = 0;
        stakingToken.safeTransferFrom(msg.sender, address(this), amount);

        // Increase voting power due to new stake
        uint256 newVotingPower = amount * pool.votingMultiplier;
        _increaseVotingPower(delegatee, newVotingPower);

        emit Staked(pid, stakeFor, amount);
    }

    /**
     * @notice Unstake tokens to start the withdrawal delay
     * @dev Only needed for pools with withdrawal delay
     * @param pid Pool id to be withdrawn from
     */
    function unstake(uint256 pid) external nonReentrant updateReward(pid, msg.sender) {
        require(needUnstake(pid, msg.sender), "ERR_ALREADY_UNSTAKED");
        require(!locked(pid, msg.sender), "ERR_TOKENS_LOCKED");

        UserInfo storage user = userInfo[pid][msg.sender];

        _unboostVotingPower(pid, msg.sender);
        user.unstakeRequestTime = block.timestamp;
        emit Unstaking(pid, msg.sender, stakedUntil(pid, msg.sender));
    }

    /**
     * @notice Cancel unstaking to boost voting power and get rewards
     * @param pid Pool id to cancel unstake from
     */
    function cancelUnstake(uint256 pid) external nonReentrant updateReward(pid, msg.sender) {
        require(unstaking(pid, msg.sender), "ERR_ALREADY_UNSTAKED");

        UserInfo storage user = userInfo[pid][msg.sender];

        user.unstakeRequestTime = 0;
        _boostVotingPower(pid, msg.sender);
    }

    /**
     * @notice Withdraw tokens from pool according to the delay, lock and vesting schedules
     * @param pid Pool id to be withdrawn from
     * @param amount The amount of tokens to be withdrawn
     */
    function withdraw(uint256 pid, uint256 amount) public nonReentrant updateReward(pid, msg.sender) {
        require(amount > 0, "ERR_CAN_NOT_WTIHDRAW_ZERO");
        require(amount <= availableWithdraw(pid, msg.sender), "ERR_WITHDRAW_MORE_THAN_AVAILABLE");
 
        PoolInfo storage pool = poolInfo[pid];
        UserInfo storage user = userInfo[pid][msg.sender];

        // Remove voting power
        uint256 votingPower = user.unstakeRequestTime == 0 ? amount * pool.votingMultiplier : amount;
        _decreaseVotingPower(user.delegatee, votingPower);
        IERC20 stakingToken = IERC20(pool.stakingToken);

        // Update stake parms
        pool.depositedAmount = pool.depositedAmount - amount;
        user.amount = user.amount - amount;
        user.withdrawn = user.withdrawn + amount;
        stakingToken.safeTransfer(msg.sender, amount);
        emit Withdrawn(pid, msg.sender, amount);
    }

    /**
     * @notice Claim the earned rewards for the transaction sender in the pool `pid`
     * @param pid Pool id to get the rewards from
     */
    function getReward(uint256 pid) public nonReentrant updateReward(pid, msg.sender) {
        UserInfo storage user = userInfo[pid][msg.sender];
        uint256 reward = user.pendingRewards;
        if (reward > 0) {
            user.pendingRewards = 0;
            kacy.safeTransfer(msg.sender, reward);
            emit RewardPaid(pid, msg.sender, reward);
        }
    }

    /**
     * @notice Withdraw fund and claim the earned rewards for the transaction sender in the pool `pid`
     * @param pid Pool id to get the rewards from
     */
    function exit(uint256 pid) external {
        UserInfo storage user = userInfo[pid][msg.sender];
        withdraw(pid, user.amount);
        getReward(pid);
    }

    /**
     * @notice Delegate all votes from `msg.sender` to `delegatee`
     * @dev This is a governance function, but it is defined here because it depends on `balanceOf`
     * @param delegatee The address to delegate votes to
     */
    function delegateAll(address delegatee) external {
        for (uint256 pid; pid <= poolInfo.length; pid++){
            if (balanceOf(pid, msg.sender) > 0){
                UserInfo storage user = userInfo[pid][msg.sender];
                if(user.delegatee != delegatee) {
                    _delegate(pid, msg.sender, delegatee);
                }
            }
        }
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    /// @dev Add new staking pool
    function addPool(
        address _stakingToken,
        uint256 _rewardsDuration,
        uint256 _lockPeriod,
        uint256 _withdrawDelay,
        uint256 _vestingPeriod,
        uint256 _votingMultiplier
        ) external onlyOwner
    {
        require(kacyAddress != address(0), "ERR_KACY_NOT_SET");

        // Pools that gives voting power must have kacy as staking token
        // and must have a volting multiplier higher than the base 1
        if (_votingMultiplier != 0) {
            require(_stakingToken == kacyAddress, "ERR_NOT_VOTING_STAKING_TOKEN");
            require(_votingMultiplier >= 1, "ERR_LOW_VOTING_MULTIPLIER");
        }

        poolInfo.push(
            PoolInfo({
                stakingToken: _stakingToken,
                depositedAmount: 0,
                lastUpdateTime: 0,
                rewardPerTokenStored: 0,
                rewardsDuration: _rewardsDuration,
                rewardRate: 0,
                periodFinish: 0,
                lockPeriod: _lockPeriod,
                withdrawDelay: _withdrawDelay,
                vestingPeriod: _vestingPeriod,
                votingMultiplier: _votingMultiplier
            })
        );
        emit NewPool(poolInfo.length - 1);
    }

    /// @dev Add rewards to the pool
    function addReward(uint256 pid, uint256 reward) external onlyOwner updateReward(pid, address(0)) {
        PoolInfo storage pool = poolInfo[pid];
        require(pool.rewardsDuration > 0, "ERR_REWARD_DURATION_ZERO");

        kacy.safeTransferFrom(msg.sender, address(this), reward);

        if (block.timestamp >= pool.periodFinish) {
            pool.rewardRate = reward / pool.rewardsDuration;
        } else {
            uint256 remaining = pool.periodFinish - block.timestamp;
            uint256 leftover = remaining * pool.rewardRate;
            pool.rewardRate = (reward + leftover) / pool.rewardsDuration;
        }

        pool.lastUpdateTime = block.timestamp;
        pool.periodFinish = (block.timestamp + pool.rewardsDuration);
        emit RewardAdded(pid, reward);
    }

    /// @dev End rewards emission earlier
    function updatePeriodFinish(uint256 pid, uint256 timestamp) external onlyOwner updateReward(pid, address(0)) {
        PoolInfo storage pool = poolInfo[pid];
        pool.periodFinish = timestamp;
    }

    /// @dev Recover tokens from pool
    function recoverERC20(uint256 pid, address tokenAddress, uint256 tokenAmount) external onlyOwner {
        PoolInfo storage pool = poolInfo[pid];
        require(tokenAddress != address(pool.stakingToken), "ERR_RECOVER_STAKING_TOKEN");
        address owner = owner();
        IERC20(tokenAddress).safeTransfer(owner, tokenAmount);
        emit Recovered(pid, tokenAddress, tokenAmount);
    }

    /// @dev Set new rewards distribution duration
    function setRewardsDuration(uint256 pid, uint256 _rewardsDuration) external onlyOwner {
        PoolInfo storage pool = poolInfo[pid];
        require(block.timestamp > pool.periodFinish, "ERR_RUNNING_REWARDS");
        pool.rewardsDuration = _rewardsDuration;
        emit RewardsDurationUpdated(pid, pool.rewardsDuration);
    }
    
    /// @dev Set the governance and reward token
    function setKacy(address _kacy) external onlyOwner {
        require(_kacy != address(0), "ERR_ZERO_ADDRESS");
        require(kacyAddress == address(0), "ERR_KACY_ALREADY_SET");
        bool returnValue = IERC20(_kacy).transfer(msg.sender, 0);
        require(returnValue, "ERR_NONCONFORMING_TOKEN");
        kacy = IERC20(_kacy);
        kacyAddress = _kacy;
    }

    /* ========== MODIFIERS ========== */

    /// @dev Modifier that is called to update pool and user rewards stats everytime a user interact with a pool
    modifier updateReward(uint pid, address account) {
        PoolInfo storage pool = poolInfo[pid];
        UserInfo storage user = userInfo[pid][account];
        
        if (poolInfo[pid].lastUpdateTime == 0) {
            pool.lastUpdateTime = block.timestamp;
        } else {
            pool.rewardPerTokenStored = rewardPerToken(pid);
            pool.lastUpdateTime = lastTimeRewardApplicable(pid);
        }


        if (account != address(0)) {
            user.pendingRewards = earned(pid, account);
            user.rewardPerTokenPaid = pool.rewardPerTokenStored;
        }
        _;
    }

    /* ========== PURE FUNCTIONS ========== */

    function _max(uint a, uint b) private pure returns (uint) {
        return a > b ? a : b;
    }

    function _min(uint a, uint b) private pure returns (uint) {
        return a < b ? a : b;
    }

    /* ========== EVENTS ========== */

    event NewPool(uint256 indexed pid);
    event RewardAdded(uint256 indexed pid, uint256 indexed reward);
    event Staked(uint256 indexed pid, address indexed user, uint256 amount);
    event Unstaking(uint256 indexed pid, address indexed user,uint256 availableAt);
    event Withdrawn(uint256 indexed pid, address indexed user, uint256 amount);
    event RewardPaid(uint256 indexed pid, address indexed user, uint256 reward);
    event RewardsDurationUpdated(uint256 indexed pid, uint256 duration);
    event Recovered(uint256 indexed pid, address indexed token, uint256 indexed amount);

}