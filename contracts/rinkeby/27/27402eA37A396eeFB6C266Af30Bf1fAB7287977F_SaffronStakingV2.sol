// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interface/ISFIRewarder.sol";

/**
 * @dev Contract for rewarding users with SFI for the Saffron liquidity mining program.
 *
 * Code based off Sushiswap's Masterchef contract with the addition of SFIRewarder.
 * 
 * NOTE: Do not add pools with LP tokens that are deflationary or have reflection.
 */
contract SaffronStakingV2 is Ownable {
    using SafeERC20 for IERC20;

    // Structure of user deposited amounts and their pending reward debt.
    struct UserInfo {
        // Amount of tokens added by the user.
        uint256 amount;

        // Accounting mechanism. Prevents double-redeeming rewards in the same block.
        uint256 rewardDebt;
    }

    // Structure holding information about each pool's LP token and allocation information.
    struct PoolInfo {
        // LP token contract. In the case of single-asset staking this is an ERC20.
        IERC20 lpToken;

        // Allocation points to determine how many SFI will be distributed per block to this pool.
        uint256 allocPoint;

        // The last block that accumulated rewards were calculated for this pool.
        uint256 lastRewardBlock; 

        // Accumulator storing the accumulated SFI earned per share of this pool.
        // Shares are user lpToken deposit amounts. This value is scaled up by 1e18.
        uint256 accSFIPerShare; 
    }

    // The amount of SFI to be rewarded per block to all pools.
    uint256 public sfiPerBlock;

    // SFI rewards are cut off after a specified block. Can be updated by governance to extend/reduce reward time.
    uint256 public rewardCutoff; 

    // SFIRewarder contract holding the SFI tokens to be rewarded to users.
    ISFIRewarder public rewarder;

    // List of pool info structs by pool id.
    PoolInfo[] public poolInfo;

    // Mapping to store list of added LP tokens to prevent accidentally adding duplicate pools.
    mapping(address => bool) lpTokenAdded; 

    // Mapping of mapping to store user informaton indexed by pool id and the user's address.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;

    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint;

    constructor(address _rewarder, uint256 _sfiPerBlock, uint256 _rewardCutoff) {
        require(_rewarder != address(0), "invalid rewarder");
        require(_rewardCutoff >= block.number, "invalid rewardCutoff");
        rewarder = ISFIRewarder(_rewarder);
        sfiPerBlock = _sfiPerBlock;
        rewardCutoff = _rewardCutoff;
    }

    /** 
     * @dev Update the SFIRewarder. Only callable by the contract owner.
     * @param _rewarder The new SFIRewarder account.
     */
    function setRewarder(address _rewarder) external onlyOwner {
        require(_rewarder != address(0), "invalid rewarder address");
        rewarder = ISFIRewarder(_rewarder);
    }

    /** 
     * @dev Update the amount of SFI rewarded per block. Only callable by the contract owner.
     * @param _sfiPerBlock The new SFI per block amount to be distributed.
     */
    function setRewardPerBlock(uint256 _sfiPerBlock) external onlyOwner {
        massUpdatePools();
        sfiPerBlock = _sfiPerBlock;
    }

    /** 
     * @dev Update the reward end block. Only callable by the contract owner.
     * @param _rewardCutoff The new cut-off block to end SFI reward distribution.
     */
    function setRewardCutoff(uint256 _rewardCutoff) external onlyOwner {
        require(_rewardCutoff >= block.number, "invalid rewardCutoff");
        rewardCutoff = _rewardCutoff;
    }

    /** 
     * @dev Update the reward end block and sfiPerBlock atomically. Only callable by the contract owner.
     * @param _rewardCutoff The new cut-off block to end SFI reward distribution.
     * @param _sfiPerBlock The new SFI per block amount to be distributed.
     */
    function setRewardPerBlockAndRewardCutoff(uint256 _sfiPerBlock, uint256 _rewardCutoff) external onlyOwner {
        require(_rewardCutoff >= block.number, "invalid rewardCutoff");
        massUpdatePools();
        sfiPerBlock = _sfiPerBlock;
        rewardCutoff = _rewardCutoff;
    }

    /** 
     * @dev Return the number of pools in the poolInfo list.
     */
    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    /**
     * @dev Add a new pool specifying its lp token and allocation points.
     * @param _allocPoint The allocationPoints for the pool. Determines SFI per block.
     * @param _lpToken Token address for the LP token in this pool.
     */
    function add(uint256 _allocPoint, address _lpToken) public onlyOwner {
        require(_lpToken != address(0), "invalid _lpToken address");
        require(!lpTokenAdded[_lpToken], "lpToken already added");
        require(block.number < rewardCutoff, "can't add pool after cutoff");
        require(_allocPoint > 0, "can't add pool with 0 ap");
        massUpdatePools();
        totalAllocPoint = totalAllocPoint + _allocPoint;
        lpTokenAdded[_lpToken] = true;
        poolInfo.push(PoolInfo({lpToken: IERC20(_lpToken), allocPoint: _allocPoint, lastRewardBlock: block.number, accSFIPerShare: 0}));
    }

    /**
     * @dev Set the allocPoint of the specific pool with id _pid.
     * @param _pid The pool id that is to be set.
     * @param _allocPoint The new allocPoint for the pool.
     */
    function set(uint256 _pid, uint256 _allocPoint) public onlyOwner {
        require(_pid < poolInfo.length, "can't set non-existant pool");
        require(_allocPoint > 0, "can't set pool to 0 ap");
        massUpdatePools();
        totalAllocPoint = totalAllocPoint - poolInfo[_pid].allocPoint + _allocPoint;
        poolInfo[_pid].allocPoint = _allocPoint;
    }

    /**
     * @dev Return the pending SFI rewards of a user for a specific pool id.
     *
     * Helper function for front-end web3 implementations.
     *
     * @param _pid Pool id to get SFI rewards report from.
     * @param _user User account to report SFI rewards from.
     * @return Pending SFI amount for the user indexed by pool id.
     */
    function pendingSFI(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo memory pool = poolInfo[_pid];
        UserInfo memory user = userInfo[_pid][_user];
        uint256 accSFIPerShare = pool.accSFIPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));

        uint256 latestRewardBlock = block.number >= rewardCutoff ? rewardCutoff : block.number;

        if (latestRewardBlock > pool.lastRewardBlock && lpSupply != 0) {
            // Get number of blocks to multiply by
            uint256 multiplier = latestRewardBlock - pool.lastRewardBlock;
            // New SFI reward is the number of blocks multiplied by the SFI per block times multiplied by the pools share of the total
            uint256 sfiReward = multiplier * sfiPerBlock * pool.allocPoint;
            // Add delta/change in share of the new reward to the accumulated SFI per share for this pool's token
            accSFIPerShare = accSFIPerShare + (sfiReward * 1e18 / lpSupply / totalAllocPoint);
        }
        // Return the pending SFI amount for this user
        return (user.amount * accSFIPerShare / 1e18) - user.rewardDebt;
    }

    /**
     * @dev Update reward variables for all pools. Be careful of gas spending! More than 100 pools is not recommended.
     */
    function massUpdatePools() public {
        for (uint256 pid = 0; pid < poolInfo.length; ++pid) {
            updatePool(pid);
        }
    }

    /**
     * @dev Update accumulated SFI shares of the specified pool.
     * @param _pid The id of the pool to be updated.
     */
    function updatePool(uint256 _pid) public returns (PoolInfo memory) {
        // Retrieve pool info by the pool id
        PoolInfo storage pool = poolInfo[_pid];

        // Only reward SFI for blocks earlier than rewardCutoff block
        uint256 latestRewardBlock = block.number >= rewardCutoff ? rewardCutoff : block.number;

        // Don't update twice in the same block
        if (latestRewardBlock > pool.lastRewardBlock) {
            // Get the amount of this pools token owned by the SaffronStaking contract
            uint256 lpSupply = pool.lpToken.balanceOf(address(this));
            // Calculate new rewards if amount is greater than 0
            if (lpSupply > 0) {
                // Get number of blocks to multiply by
                uint256 multiplier = latestRewardBlock - pool.lastRewardBlock;
                // New SFI reward is the number of blocks multiplied by the SFI per block times multiplied by the pools share of the total
                uint256 sfiReward = multiplier * sfiPerBlock * pool.allocPoint;
                // Add delta/change in share of the new reward to the accumulated SFI per share for this pool's token
                pool.accSFIPerShare = pool.accSFIPerShare + (sfiReward * 1e18 / lpSupply / totalAllocPoint);
            } 
            // Set the last reward block to the most recent reward block
            pool.lastRewardBlock = latestRewardBlock;
        }
        // Return this pools updated info
        return poolInfo[_pid];
    }

    /**
     * @dev Deposit the user's lp token into the the specified pool.
     * @param _pid Pool id where the user's asset is being deposited.
     * @param _amount Amount to deposit into the pool.
     */
    function deposit(uint256 _pid, uint256 _amount) public {
        // Get pool identified by pid
        PoolInfo memory pool = updatePool(_pid);
        // Get user in this pool identified by msg.sender address
        UserInfo storage user = userInfo[_pid][msg.sender];
        // Calculate pending SFI earnings for this user in this pool
        uint256 pending = (user.amount * pool.accSFIPerShare / 1e18) - user.rewardDebt;

        // Effects
        // Add the new deposit amount to the pool user's amount total
        user.amount = user.amount + _amount;
        // Update the pool user's reward debt to this new amount
        user.rewardDebt = user.amount * pool.accSFIPerShare / 1e18;

        // Interactions
        // Transfer pending SFI rewards to the user
        safeSFITransfer(msg.sender, pending);
        // Transfer the users tokens to this contract (deposit them in this contract)
        pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);

        emit TokensDeposited(msg.sender, _pid, _amount);
    }

    /**
     * @dev Withdraw the user's lp token from the specified pool.
     * @param _pid Pool id from which the user's asset is being withdrawn.
     * @param _amount Amount to withdraw from the pool.
     */
    function withdraw(uint256 _pid, uint256 _amount) public {
        // Get pool identified by pid
        PoolInfo memory pool = updatePool(_pid);
        // Get user in this pool identified by msg.sender address
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "can't withdraw more than user balance");
        // Calculate pending SFI earnings for this user in this pool
        uint256 pending = (user.amount * pool.accSFIPerShare / 1e18) - user.rewardDebt;

        // Effects
        // Subtract the new withdraw amount from the pool user's amount total
        user.amount = user.amount - _amount;
        // Update the pool user's reward debt to this new amount
        user.rewardDebt = user.amount * pool.accSFIPerShare / 1e18;

        // Interactions
        // Transfer pending SFI rewards to the user
        safeSFITransfer(msg.sender, pending);
        // Transfer contract's tokens amount to this user (withdraw them from this contract)
        pool.lpToken.safeTransfer(address(msg.sender), _amount);

        emit TokensWithdrawn(msg.sender, _pid, _amount);
    }

    /**
     * @dev Emergency function to withdraw a user's asset in a specified pool.
     * @param _pid Pool id from which the user's asset is being withdrawn.
     */
    function emergencyWithdraw(uint256 _pid) public {
        PoolInfo memory pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 amount = user.amount;

        // Effects
        user.amount = 0;
        user.rewardDebt = 0;

        // Interactions
        pool.lpToken.safeTransfer(address(msg.sender), amount);

        emit TokensEmergencyWithdrawn(msg.sender, _pid, amount);
    }

    /**
     * @dev Transfer SFI from the SFIRewarder contract to the user's account.
     * @param to Account to transfer SFI to from the SFIRewarder contract.
     * @param amount Amount of SFI to transfer from the SFIRewarder to the user's account.
     */
    function safeSFITransfer(address to, uint256 amount) internal {
        if (amount > 0) rewarder.rewardUser(to, amount);
    }

    /**
     * @dev Emitted when `amount` tokens are deposited by `user` into pool id `pid`.
     */
    event TokensDeposited(address indexed user, uint256 indexed pid, uint256 amount);

    /**
     * @dev Emitted when `amount` tokens are withdrawn by `user` from pool id `pid`.
     */
    event TokensWithdrawn(address indexed user, uint256 indexed pid, uint256 amount);

    /**
     * @dev Emitted when `amount` tokens are emergency withdrawn by `user` from pool id `pid`.
     */
    event TokensEmergencyWithdrawn(address indexed user, uint256 indexed pid, uint256 amount);

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

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

/**
 * @dev Interface of the SFIRewarder contract for SaffronStakingV2 to implement and call.
 */
interface ISFIRewarder {
    /**
     * @dev Rewards an `amount` of SFI to account `to`.
     */
    function rewardUser(address to, uint256 amount) external;
    
    /**
     * @dev Emitted when `amount` SFI are rewarded to account `to`.
     *
     * Note that `amount` may be zero.
     */
    event UserRewarded(address indexed to, uint256 amount);

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
        return msg.data;
    }
}

