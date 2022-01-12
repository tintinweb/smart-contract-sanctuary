// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./BabyDolz.sol";

// Pool settings
struct Pool {
    // Address of the token hosted by the pool
    address token;
    // Minimum time in seconds before the tokens staked can be withdrew
    uint32 lockTime;
    // Amount of tokens that give access to 1 reward every block
    uint64 amountPerReward;
    // Value of 1 reward per block
    uint40 rewardPerBlock;
    // Minimum amount of token to deposit per user
    uint72 minimumDeposit;
    // Percentage of the deposit that is collected by the pool, with one decimal
    // Eg. for 34.3 percents, depositFee will have a value of 343
    uint104 depositFee;
    // Last block where the reward will take effect
    // Not taken into account if equals 0
    uint40 lastRewardedBlock;
}

// User deposit informations
struct Deposit {
    // Cumulated amount deposited
    uint176 amount;
    // Block number from when to compute next reward
    uint40 rewardBlockStart;
    // Timestamp in seconds when the deposit is available for withdraw
    uint40 lockTimeEnd;
}

/**
 * @notice Staking contract to earn BabyDolz tokens
 */
contract DolzChef is Ownable {
    using SafeERC20 for IERC20;

    // BabyDolz token address
    address public immutable babyDolz;
    // List of all the pools created with their settings
    Pool[] public pools;

    // Associate pool id to user address to deposit informations
    mapping(uint256 => mapping(address => Deposit)) public deposits;
    // Associate pool id to the amount of fees collected
    mapping(uint256 => uint256) public collectedFees;

    event AmountPerRewardUpdated(uint256 indexed poolId, uint256 newAmountPerReward);
    event RewardPerBlockUpdated(uint256 indexed poolId, uint256 newRewardPerBlock);
    event DepositFeeUpdated(uint256 indexed poolId, uint256 newDepositFee);
    event MinimumDepositUpdated(uint256 indexed poolId, uint256 newMinimumDeposit);
    event LockTimeUpdated(uint256 indexed poolId, uint256 newLockTime);
    event PoolCreated(
        address indexed token,
        uint256 id,
        uint256 amountPerReward,
        uint256 rewardPerBlock,
        uint256 depositFee,
        uint256 minimumDeposit,
        uint256 lockTime
    );
    event PoolClosed(uint256 indexed poolId, uint256 lastRewardedBlock);
    event Deposited(uint256 indexed poolId, address indexed account, uint256 amount);
    event Withdrew(uint256 indexed poolId, address indexed account, uint256 amount);
    event WithdrewFees(uint256 indexed poolId, uint256 amount);
    event Harvested(uint256 indexed poolId, address indexed account, uint256 amount);

    /**
     @notice Check that percentage is less or equal to 1000 to not exceed 100.0%
     */
    modifier checkPercentage(uint256 percentage) {
        require(percentage <= 1000, "DolzChef: percentage should be equal to or lower than 1000");
        _;
    }

    /**
     * @param _babyDolz Address of the BabyDolz token that users will be rewarded with.
     */
    constructor(address _babyDolz) {
        babyDolz = _babyDolz;
    }

    function getPoolInfo(uint256 poolId) external view returns (Pool memory) {
        return pools[poolId];
    }

    /**
     * @notice Enable to update the amount of tokens that give access to 1 reward every block for a specific pool.
     * @dev Only accessible to owner.
     * @param poolId Id of the pool to update.
     * @param newAmountPerReward New amount of tokens that give access to 1 reward
     */
    function setAmountPerReward(uint256 poolId, uint64 newAmountPerReward) external onlyOwner {
        pools[poolId].amountPerReward = newAmountPerReward;
        emit AmountPerRewardUpdated(poolId, newAmountPerReward);
    }

    /**
     * @notice Get the number of pools created.
     * @return Number of pools.
     */
    function numberOfPools() external view returns (uint256) {
        return pools.length;
    }

    /**
     * @notice Enable to update the amount of BabyDolz received as staking reward every block for a specific pool.
     * @dev Only accessible to owner.
     * @param poolId Id of the pool to update.
     * @param newRewardPerBlock New amount of BabyDolz received as staking reward every block.
     */
    function setRewardPerBlock(uint256 poolId, uint40 newRewardPerBlock) external onlyOwner {
        pools[poolId].rewardPerBlock = newRewardPerBlock;
        emit RewardPerBlockUpdated(poolId, newRewardPerBlock);
    }

    /**
     * @notice Enable to update the deposit fee of a specific pool.
     * @dev Only accessible to owner.
     * @param poolId Id of the pool to update.
     * @param newDepositFee New percentage of the deposit that is collected by the pool, with one decimal.
     * Eg. for 34.3 percents, depositFee will have a value of 343
     */
    function setDepositFee(uint256 poolId, uint104 newDepositFee)
        external
        onlyOwner
        checkPercentage(newDepositFee)
    {
        pools[poolId].depositFee = newDepositFee;
        emit DepositFeeUpdated(poolId, newDepositFee);
    }

    /**
     * @notice Enable to update the minimum deposit amount of a specific pool.
     * @dev Only accessible to owner.
     * @param poolId Id of the pool to update.
     * @param newMinimumDeposit New minimum token amount to be deposited in the pool by each user.
     */
    function setMinimumDeposit(uint256 poolId, uint72 newMinimumDeposit) external onlyOwner {
        pools[poolId].minimumDeposit = newMinimumDeposit;
        emit MinimumDepositUpdated(poolId, newMinimumDeposit);
    }

    /**
     * @notice Enable to update the lock time of a specific pool.
     * @dev Only accessible to owner.
     * @param poolId Id of the pool to update.
     * @param newLockTime New amount of seconds that users will have to wait after a deposit to be able to withdraw.
     */
    function setLockTime(uint256 poolId, uint32 newLockTime) external onlyOwner {
        pools[poolId].lockTime = newLockTime;
        emit LockTimeUpdated(poolId, newLockTime);
    }

    /**
     * @notice Enable to create a new pool for a token.
     * @dev Only accessible to owner.
     * @param token Addres of the token that can be staked in the pool.
     * @param amountPerReward Amount of tokens that give access to 1 reward every block.
     * @param rewardPerBlock Value of 1 reward per block.
     * @param depositFee Percentage of the deposit that is collected by the pool, with one decimal.
     * Eg. for 34.3 percents, depositFee will have a value of 343
     * @param minimumDeposit Minimum amount of token to deposit per user.
     * @param lockTime Minimum time in seconds before the tokens staked can be withdrew.
     */
    function createPool(
        address token,
        uint64 amountPerReward,
        uint40 rewardPerBlock,
        uint104 depositFee,
        uint72 minimumDeposit,
        uint32 lockTime
    ) external onlyOwner checkPercentage(depositFee) {
        pools.push(
            Pool({
                token: token,
                amountPerReward: amountPerReward,
                rewardPerBlock: rewardPerBlock,
                depositFee: depositFee,
                minimumDeposit: minimumDeposit,
                lockTime: lockTime,
                lastRewardedBlock: 0
            })
        );
        emit PoolCreated(
            token,
            pools.length - 1,
            amountPerReward,
            rewardPerBlock,
            depositFee,
            minimumDeposit,
            lockTime
        );
    }

    /**
     * @notice Enable to close a new pool by determining the last block that is going to be rewarded.
     * @dev Only accessible to owner.
     * @param poolId Id of the pool to terminate.
     * @param lastRewardedBlock Last block where the reward will take effect.
     */
    function closePool(uint256 poolId, uint40 lastRewardedBlock) external onlyOwner {
        require(
            lastRewardedBlock > block.number,
            "DolzChef: last rewarded block must be greater than current"
        );
        pools[poolId].lastRewardedBlock = lastRewardedBlock;
        emit PoolClosed(poolId, lastRewardedBlock);
    }

    /**
     * @notice Enable users to stake their tokens in the pool.
     * @param poolId Id of pool where to deposit tokens.
     * @param depositAmount Amount of tokens to deposit.
     */
    function deposit(uint256 poolId, uint176 depositAmount) external {
        Pool memory pool = pools[poolId]; // gas savings

        // Check if the user deposits enough tokens
        require(
            deposits[poolId][msg.sender].amount + depositAmount >= pool.minimumDeposit,
            "DolzChef: cannot deposit less that minimum deposit value"
        );

        // Send the reward the user accumulated so far and updates deposit state
        harvest(poolId);

        // Compute the fees to collected and update the deposit state
        uint176 fees = (depositAmount * pool.depositFee) / 1000;
        collectedFees[poolId] += fees;
        deposits[poolId][msg.sender].amount += depositAmount - fees;
        deposits[poolId][msg.sender].lockTimeEnd = uint40(block.timestamp + pool.lockTime);

        emit Deposited(poolId, msg.sender, depositAmount);
        IERC20(pools[poolId].token).safeTransferFrom(msg.sender, address(this), depositAmount);
    }

    /**
     * @notice Enable users to with withdraw their stake after end of lock time with reward.
     * @param poolId Id of pool where to withdraw tokens.
     * @param withdrawAmount Amount of tokens to withdraw.
     */
    function withdraw(uint256 poolId, uint176 withdrawAmount) external {
        // Check if the stake is available to withdraw
        require(
            block.timestamp >= deposits[poolId][msg.sender].lockTimeEnd,
            "DolzChef: can't withdraw before lock time end"
        );

        // Send the reward the user accumulated so far and updates deposit state
        harvest(poolId);
        deposits[poolId][msg.sender].amount -= withdrawAmount;

        emit Withdrew(poolId, msg.sender, withdrawAmount);
        IERC20(pools[poolId].token).safeTransfer(msg.sender, withdrawAmount);
    }

    /**
     * @notice Enable users to with withdraw their stake before end of lock time without reward.
     * @param poolId Id of pool where to withdraw tokens.
     * @param withdrawAmount Amount of tokens to withdraw.
     */
    function emergencyWithdraw(uint256 poolId, uint176 withdrawAmount) external {
        deposits[poolId][msg.sender].amount -= withdrawAmount;

        emit Withdrew(poolId, msg.sender, withdrawAmount);
        IERC20(pools[poolId].token).safeTransfer(msg.sender, withdrawAmount);
    }

    /**
     * @notice Enable the admin to withdraw the fees collected on a specific pool.
     * @dev Only accessible to owner.
     * @param poolId Id of the pool where to withdraw the fees collected.
     * @param receiver Address that will receive the fees.
     * @param amount Amount of fees to withdraw, in number of tokens.
     */
    function withdrawFees(
        uint256 poolId,
        address receiver,
        uint256 amount
    ) external onlyOwner {
        // Check that the amount required in equal or lower to the amount of fees collected
        require(
            amount <= collectedFees[poolId],
            "DolzChef: cannot withdraw more than collected fees"
        );

        collectedFees[poolId] -= amount;

        emit WithdrewFees(poolId, amount);
        IERC20(pools[poolId].token).safeTransfer(receiver, amount);
    }

    /**
     * @notice Enable the users to withdraw their reward without unstaking their deposit.
     * @param poolId Id of the pool where to withdraw the reward.
     */
    function harvest(uint256 poolId) public {
        // Get the amount of tokens to reward the user with
        uint256 reward = pendingReward(poolId, msg.sender);
        // Update the deposit state
        deposits[poolId][msg.sender].rewardBlockStart = uint40(block.number);

        emit Harvested(poolId, msg.sender, reward);
        BabyDolz(babyDolz).mint(msg.sender, reward);
    }

    /**
     * @notice Computes the reward a user is entitled of.
     * @dev Avaible as an external function for frontend as well as internal for harvest function.
     * @param poolId Id of the pool where to get the reward.
     * @param account Address of the account to get the reward for.
     * @return The amount of BabyDolz token the user is entitled to as a staking reward.
     */
    function pendingReward(uint256 poolId, address account) public view returns (uint256) {
        uint256 lastRewardedBlock = pools[poolId].lastRewardedBlock; // gas savings
        // Checks if pool is close or not
        uint256 lastBlock = lastRewardedBlock != 0 && lastRewardedBlock < block.number
            ? lastRewardedBlock
            : block.number;
        Deposit memory deposited = deposits[poolId][account]; // gas savings
        // Following computation is an optimised version of this:
        // reward = amountStaked / amountPerReward * rewardPerBlock * numberOfElapsedBlocks
        return
            ((deposited.amount * pools[poolId].rewardPerBlock) *
                (lastBlock - deposited.rewardBlockStart)) / pools[poolId].amountPerReward;
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

pragma solidity 0.8.10;

import "./ERC20Bridgable.sol";

contract BabyDolz is ERC20Bridgable {
    // Addresses authorized to mint tokens are set to true
    mapping(address => bool) public minters;
    // Addresses authorized to send tokens are set to true
    mapping(address => bool) public senders;
    // Addresses authorized to receive tokens are set to true
    mapping(address => bool) public receivers;

    event MinterSet(address account, bool authorized);
    event SenderSet(address account, bool authorized);
    event ReceiverSet(address account, bool authorized);

    constructor(string memory name, string memory symbol) ERC20Bridgable(name, symbol) {}

    /**
     * @notice Change the minter state of an address.
     * @dev Only callable by owner.
     * @param account Address to configure.
     * @param authorized True to enable address to mint, false to disable.
     */
    function setMinter(address account, bool authorized) external onlyOwner {
        minters[account] = authorized;
        emit MinterSet(account, authorized);
    }

    /**
     * @notice Change the sender state of an address.
     * @dev Only callable by owner.
     * @param account Address to configure.
     * @param authorized True to enable address to send, false to disable.
     */
    function setSender(address account, bool authorized) external onlyOwner {
        senders[account] = authorized;
        emit SenderSet(account, authorized);
    }

    /**
     * @notice Change the receiver state of an address.
     * @dev Only callable by owner.
     * @param account Address to configure.
     * @param authorized True to enable address to receive, false to disable.
     */
    function setReceiver(address account, bool authorized) external onlyOwner {
        receivers[account] = authorized;
        emit ReceiverSet(account, authorized);
    }

    /**
     * @notice Mint tokens for an account.
     * @dev Only callable by an authorized minter, check is done in _beforeTokenTransfer hook.
     * @param account Address to mint for.
     * @param amount Amount to mint.
     */
    function mint(address account, uint256 amount) external {
        _mint(account, amount);
    }

    /**
     * @dev Override ERC20 hook to check transfer authorizations.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        // Calls previous actions
        super._beforeTokenTransfer(from, to, amount);
        if (from == address(0)) {
            // If transfer is minting, checks that msg.sender is an authorized minter
            require(minters[msg.sender], "BabyDolz: sender is not an authorized minter");
        } else {
            // Otherwise check that sender or receiver are authorized
            require(senders[from] || receivers[to], "BabyDolz: transfer not authorized");
        }
    }
}

// SPDX-License-Identifier: MIT

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

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./interfaces/IERC20Bridgable.sol";

/**
 * @notice Bridge update proposal informations.
 * @param newBridge The address of the bridge proposed.
 * @param endGracePeriod The timestamp in second from when the proposal can be executed.
 */
struct BridgeUpdate {
    address newBridge;
    uint256 endGracePeriod;
}

/**
 * @notice ERC20 token smart contract with a mechanism for authorizing a bridge to mint and burn.
 */
contract ERC20Bridgable is ERC20, Ownable, IERC20Bridgable {
    using Address for address;

    // Address of the contract who will be able to mint and burn tokens
    address public bridge;
    // Latest update launched, executed or not
    BridgeUpdate public bridgeUpdate;

    modifier onlyBridge() {
        require(msg.sender == bridge, "ERC20Bridgable: access denied");
        _;
    }

    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

    /**
     * @notice Create a bridge update that can be executed after 7 days.
     * The 7 days period is there to enable holders to check the new bridge contract
     * before it starts to be used.
     * @dev Only executable by the owner of the contract.
     * @param newBridge Address of the new bridge.
     */
    function launchBridgeUpdate(address newBridge) external onlyOwner {
        // Check if there already is an update waiting to be executed
        require(
            bridgeUpdate.newBridge == address(0),
            "ERC20Bridgable: current update has to be executed"
        );
        // Make sure the new address is a contract and not an EOA
        require(newBridge.isContract(), "ERC20Bridgable: address provided is not a contract");

        uint256 endGracePeriod = block.timestamp + 1 weeks;

        bridgeUpdate = BridgeUpdate(newBridge, endGracePeriod);

        emit BridgeUpdateLaunched(newBridge, endGracePeriod);
    }

    /**
     * @notice Execute the update once the grace period has passed, and change the bridge address.
     * @dev Only executable by the owner of the contract.
     */
    function executeBridgeUpdate() external onlyOwner {
        // Check that grace period has passed
        require(
            bridgeUpdate.endGracePeriod <= block.timestamp,
            "ERC20Bridgable: grace period has not finished"
        );
        // Check that update have not already been executed
        require(bridgeUpdate.newBridge != address(0), "ERC20Bridgable: update already executed");

        bridge = bridgeUpdate.newBridge;
        emit BridgeUpdateExecuted(bridgeUpdate.newBridge);

        delete bridgeUpdate;
    }

    /**
     * @dev Enable the bridge to mint tokens in case they are received from Ethereum mainnet.
     * Only executable by the bridge contract.
     * @param account Address of the user who should receive the tokens.
     * @param amount Amount of token that the user should receive.
     */
    function mintFromBridge(address account, uint256 amount) external override onlyBridge {
        _mint(account, amount);
    }

    /**
     * @dev Enable the bridge to burn tokens in case they are sent to Ethereum mainnet.
     * Only executable by the bridge contract.
     * @param account Address of the user who is bridging the tokens.
     * @param amount Amount of token that the user is bridging.
     */
    function burnFromBridge(address account, uint256 amount) external override onlyBridge {
        _burn(account, amount);
    }
}

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;

interface IERC20Bridgable {
    function mintFromBridge(address account, uint256 amount) external;

    function burnFromBridge(address account, uint256 amount) external;

    event BridgeUpdateLaunched(address indexed newBridge, uint256 endGracePeriod);
    event BridgeUpdateExecuted(address indexed newBridge);
}

// SPDX-License-Identifier: MIT

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