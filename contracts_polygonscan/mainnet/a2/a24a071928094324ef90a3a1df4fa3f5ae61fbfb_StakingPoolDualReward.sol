/**
 *Submitted for verification at polygonscan.com on 2021-12-13
*/

// Sources flattened with hardhat v2.6.2 https://hardhat.org

// File @openzeppelin/contracts/token/ERC20/[email protected]

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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// File @openzeppelin/contracts/utils/[email protected]

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
        require(
            address(this).balance >= amount,
            'Address: insufficient balance'
        );

        (bool success, ) = recipient.call{value: amount}('');
        require(
            success,
            'Address: unable to send value, recipient may have reverted'
        );
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
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return functionCall(target, data, 'Address: low-level call failed');
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
        return
            functionCallWithValue(
                target,
                data,
                value,
                'Address: low-level call with value failed'
            );
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
        require(
            address(this).balance >= value,
            'Address: insufficient balance for call'
        );
        require(isContract(target), 'Address: call to non-contract');

        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                'Address: low-level static call failed'
            );
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
        require(isContract(target), 'Address: static call to non-contract');

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionDelegateCall(
                target,
                data,
                'Address: low-level delegate call failed'
            );
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
        require(isContract(target), 'Address: delegate call to non-contract');

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

// File @openzeppelin/contracts/token/ERC20/utils/[email protected]

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
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
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
            'SafeERC20: approve from non-zero to non-zero allowance'
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(
                oldAllowance >= value,
                'SafeERC20: decreased allowance below zero'
            );
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(
                token,
                abi.encodeWithSelector(
                    token.approve.selector,
                    spender,
                    newAllowance
                )
            );
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

        bytes memory returndata = address(token).functionCall(
            data,
            'SafeERC20: low-level call failed'
        );
        if (returndata.length > 0) {
            // Return data is optional
            require(
                abi.decode(returndata, (bool)),
                'SafeERC20: ERC20 operation did not succeed'
            );
        }
    }
}

// File @openzeppelin/contracts/utils/[email protected]

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

// File @openzeppelin/contracts/access/[email protected]

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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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
        require(owner() == _msgSender(), 'Ownable: caller is not the owner');
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
        require(
            newOwner != address(0),
            'Ownable: new owner is the zero address'
        );
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File @openzeppelin/contracts/proxy/utils/[email protected]

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(
            _initializing || !_initialized,
            'Initializable: contract is already initialized'
        );

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// File contracts/StakingPoolDualReward.sol

pragma solidity ^0.8.4;

contract StakingPoolDualReward is Ownable, Initializable {
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 reward0Debt; // Reward token 0 debt. See explanation below.
        uint256 reward1Debt; // Reward token 1 debt. See explanation below.
    }

    receive() external payable {
        WithdrawEther;
    }

    // The stake token
    IERC20 public STAKE_TOKEN;
    // The reward token
    IERC20 public REWARD_TOKEN0;
    // The reward token
    IERC20 public REWARD_TOKEN1;

    // Reward tokens created per block.
    uint256 public reward0PerBlock;
    // Reward tokens created per block.
    uint256 public reward1PerBlock;
    // Rewards per share accumulated
    uint256 public accRewardToken0PerShare = 0;
    // Rewards per share accumulated
    uint256 public accRewardToken1PerShare = 0;
    // Keep track of number of tokens staked in case the contract earns reflect fees
    uint256 public totalStaked = 0;
    // Last block number that Rewards distribution occurs.
    uint256 public lastRewardBlock;

    // Info of each user that stakes LP tokens.
    mapping(address => UserInfo) public userInfo;
    // The block number when Reward mining starts.
    uint256 public startBlock;
    // The block number when mining ends.
    uint256 public endBlock;
    // Deposit Fee Points
    uint256 public depositFee;
    // Deposit Fee Address
    address public feeAddress;
    // Deposit Burn Fee Points
    uint256 public depositBurnFee;
    // Deposit Burn Address
    address public burnAddress;

    event Deposit(address indexed user, uint256 amount);
    event DepositRewards(uint256 amount0, uint256 amount1);
    event Withdraw(address indexed user, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 amount);
    event SkimStakeTokenFees(address indexed user, uint256 amount);
    event LogUpdatePool(
        uint256 endBlock,
        uint256 reward0PerBlock,
        uint256 reward1PerBlock
    );
    event EmergencyRewardWithdraw(
        address indexed user,
        uint256 amount0,
        uint256 amount1
    );
    event EmergencySweepWithdraw(
        address indexed user,
        IERC20 indexed token,
        uint256 amount
    );
    event WithdrawEther(address indexed user, uint256 amount);
    event SetFeeAddress(address indexed user, address indexed newFeeAddress);
    event SetBurnAddress(address indexed user, address indexed newBurnAddress);

    function initialize(
        IERC20 _stakeToken,
        IERC20 _rewardToken0,
        IERC20 _rewardToken1,
        uint256 _reward0PerBlock,
        uint256 _reward1PerBlock,
        uint256 _startBlock,
        uint256 _endBlock,
        uint256 _depositFee,
        address _feeAddress,
        uint256 _depositBurnFee,
        address _burnAddress
    ) external initializer {
        STAKE_TOKEN = _stakeToken;
        REWARD_TOKEN0 = _rewardToken0;
        REWARD_TOKEN1 = _rewardToken1;
        reward0PerBlock = _reward0PerBlock;
        reward1PerBlock = _reward1PerBlock;
        startBlock = _startBlock;
        lastRewardBlock = _startBlock;
        endBlock = _endBlock;
        depositFee = _depositFee;
        feeAddress = _feeAddress;
        depositBurnFee = _depositBurnFee;
        burnAddress = _burnAddress;
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to)
        public
        view
        returns (uint256)
    {
        if (_to <= endBlock) {
            return _to - _from;
        } else if (_from >= endBlock) {
            return 0;
        } else {
            return endBlock - _from;
        }
    }

    /// @param  _endBlock The block when rewards will end
    function setEndBlock(uint256 _endBlock) external onlyOwner {
        require(
            _endBlock > endBlock,
            'new bonus end block must be greater than current'
        );
        endBlock = _endBlock;
        emit LogUpdatePool(endBlock, reward0PerBlock, reward1PerBlock);
    }

    // View function to see pending Reward on frontend.
    function pendingReward(address _user)
        external
        view
        returns (uint256, uint256)
    {
        UserInfo storage user = userInfo[_user];

        uint256 _accRewardToken0PerShare = accRewardToken0PerShare;
        uint256 _accRewardToken1PerShare = accRewardToken1PerShare;

        if (block.number > lastRewardBlock && totalStaked != 0) {
            uint256 multiplier = getMultiplier(lastRewardBlock, block.number);

            uint256 tokenReward0 = multiplier * reward0PerBlock;
            _accRewardToken0PerShare =
                accRewardToken0PerShare +
                ((tokenReward0 * 1e30) / totalStaked);

            uint256 tokenReward1 = multiplier * reward1PerBlock;
            _accRewardToken1PerShare =
                accRewardToken1PerShare +
                ((tokenReward1 * 1e30) / totalStaked);
        }
        return (
            (user.amount * _accRewardToken0PerShare) / 1e30 - user.reward0Debt,
            (user.amount * _accRewardToken1PerShare) / 1e30 - user.reward1Debt
        );
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool() public {
        if (block.number <= lastRewardBlock) {
            return;
        }

        if (totalStaked == 0) {
            lastRewardBlock = block.number;
            return;
        }

        uint256 multiplier = getMultiplier(lastRewardBlock, block.number);

        uint256 tokenReward0 = multiplier * reward0PerBlock;
        accRewardToken0PerShare =
            accRewardToken0PerShare +
            ((tokenReward0 * 1e30) / totalStaked);

        uint256 tokenReward1 = multiplier * reward1PerBlock;
        accRewardToken1PerShare =
            accRewardToken1PerShare +
            ((tokenReward1 * 1e30) / totalStaked);

        lastRewardBlock = block.number;
    }

    /// Deposit staking token into the contract to earn rewards.
    /// @dev Since this contract needs to be supplied with rewards we are
    ///  sending the balance of the contract if the pending rewards are higher
    /// @param _amount The amount of staking tokens to deposit
    function deposit(uint256 _amount) public {
        UserInfo storage user = userInfo[msg.sender];

        uint256 finalDepositAmount = 0;

        updatePool();

        if (user.amount > 0) {
            uint256 pending0 = (user.amount * accRewardToken0PerShare) /
                1e30 -
                user.reward0Debt;

            uint256 pending1 = (user.amount * accRewardToken1PerShare) /
                1e30 -
                user.reward1Debt;

            (
                uint256 currentReward0Balance,
                uint256 currentReward1Balance
            ) = rewardBalance();

            if (pending0 > 0 && pending0 > currentReward0Balance) {
                pending0 = currentReward0Balance;
            }

            if (pending1 > 0 && pending1 > currentReward1Balance) {
                pending1 = currentReward1Balance;
            }

            if (pending0 > 0 || pending1 > 1) {
                safeTransferRewards(address(msg.sender), pending0, pending1);
            }
        }

        if (_amount > 0) {
            uint256 preStakeBalance = STAKE_TOKEN.balanceOf(address(this));

            STAKE_TOKEN.safeTransferFrom(
                address(msg.sender),
                address(this),
                _amount
            );

            finalDepositAmount =
                STAKE_TOKEN.balanceOf(address(this)) -
                preStakeBalance;

            if (depositFee > 0 || depositBurnFee > 0) {
                uint256 depositFeeAmount = (finalDepositAmount * depositFee) /
                    10000;

                if (depositFeeAmount > 0) {
                    STAKE_TOKEN.safeTransfer(feeAddress, depositFeeAmount);
                }

                uint256 depositBurnFeeAmount = (finalDepositAmount *
                    depositBurnFee) / 10000;

                if (depositBurnFeeAmount > 0) {
                    STAKE_TOKEN.safeTransfer(burnAddress, depositBurnFeeAmount);
                }

                finalDepositAmount =
                    finalDepositAmount -
                    depositFeeAmount -
                    depositBurnFeeAmount;
            }

            user.amount = user.amount + finalDepositAmount;
            totalStaked = totalStaked + finalDepositAmount;
        }

        user.reward0Debt = (user.amount * accRewardToken0PerShare) / 1e30;
        user.reward1Debt = (user.amount * accRewardToken1PerShare) / 1e30;

        emit Deposit(msg.sender, finalDepositAmount);
    }

    /// Withdraw rewards and/or staked tokens. Pass a 0 amount to withdraw only rewards
    /// @param _amount The amount of staking tokens to withdraw
    function withdraw(uint256 _amount) public {
        UserInfo storage user = userInfo[msg.sender];
        require(user.amount >= _amount, 'withdraw: not good');
        updatePool();

        uint256 pending0 = (user.amount * accRewardToken0PerShare) /
            1e30 -
            user.reward0Debt;

        uint256 pending1 = (user.amount * accRewardToken1PerShare) /
            1e30 -
            user.reward1Debt;

        (
            uint256 currentReward0Balance,
            uint256 currentReward1Balance
        ) = rewardBalance();

        if (pending0 > 0 && pending0 > currentReward0Balance) {
            pending0 = currentReward0Balance;
        }

        if (pending1 > 0 && pending1 > currentReward1Balance) {
            pending1 = currentReward1Balance;
        }

        if (pending0 > 0 || pending1 > 1) {
            safeTransferRewards(address(msg.sender), pending0, pending1);
        }

        if (_amount > 0) {
            user.amount = user.amount - _amount;
            STAKE_TOKEN.safeTransfer(address(msg.sender), _amount);
            totalStaked = totalStaked - _amount;
        }

        user.reward0Debt = (user.amount * accRewardToken0PerShare) / 1e30;
        user.reward1Debt = (user.amount * accRewardToken1PerShare) / 1e30;

        emit Withdraw(msg.sender, _amount);
    }

    /// Obtain the reward balance of this contract
    /// @return wei balace of conract
    function rewardBalance() public view returns (uint256, uint256) {
        uint256 balance0 = REWARD_TOKEN0.balanceOf(address(this));
        uint256 balance1 = REWARD_TOKEN1.balanceOf(address(this));

        if (STAKE_TOKEN == REWARD_TOKEN0)
            return (balance0 - totalStaked, balance1);
        if (STAKE_TOKEN == REWARD_TOKEN1)
            return (balance0, balance1 - totalStaked);

        return (balance0, balance1);
    }

    // Deposit Rewards into contract
    function depositRewards(uint256 _amount0, uint256 _amount1) external {
        require(
            _amount0 > 0 || _amount1 > 0,
            'Deposit value must be greater than 0.'
        );

        if (_amount0 > 0) {
            REWARD_TOKEN0.safeTransferFrom(
                address(msg.sender),
                address(this),
                _amount0
            );
        }

        if (_amount1 > 0) {
            REWARD_TOKEN1.safeTransferFrom(
                address(msg.sender),
                address(this),
                _amount1
            );
        }

        emit DepositRewards(_amount0, _amount1);
    }

    /// @param _to address to send reward token to
    /// @param _amount0 value of reward token 0 to transfer
    /// @param _amount1 value of reward token 1 to transfer
    function safeTransferRewards(
        address _to,
        uint256 _amount0,
        uint256 _amount1
    ) internal {
        if (_amount0 > 0) {
            REWARD_TOKEN0.safeTransfer(_to, _amount0);
        }

        if (_amount1 > 0) {
            REWARD_TOKEN1.safeTransfer(_to, _amount1);
        }
    }

    /// @dev Obtain the stake token fees (if any) earned by reflect token
    function getStakeTokenFeeBalance() public view returns (uint256) {
        return STAKE_TOKEN.balanceOf(address(this)) - totalStaked;
    }

    /* Admin Functions */

    /// @param _feeAddress The new fee address
    function setFeeAddress(address _feeAddress) external onlyOwner {
        feeAddress = _feeAddress;
        emit SetFeeAddress(msg.sender, _feeAddress);
    }

    /// @param _burnAddress The new burn address
    function setBurnAddress(address _burnAddress) external onlyOwner {
        burnAddress = _burnAddress;
        emit SetBurnAddress(msg.sender, _burnAddress);
    }

    /// @param _reward0PerBlock The amount of reward 0 tokens to be given per block
    /// @param _reward1PerBlock The amount of reward 1 tokens to be given per block
    function setRewardPerBlock(
        uint256 _reward0PerBlock,
        uint256 _reward1PerBlock
    ) external onlyOwner {
        reward0PerBlock = _reward0PerBlock;
        reward1PerBlock = _reward1PerBlock;
        emit LogUpdatePool(endBlock, _reward0PerBlock, _reward1PerBlock);
    }

    /// @dev Remove excess stake tokens earned by reflect fees
    function skimStakeTokenFees() external onlyOwner {
        uint256 stakeTokenFeeBalance = getStakeTokenFeeBalance();

        STAKE_TOKEN.safeTransfer(msg.sender, stakeTokenFeeBalance);

        emit SkimStakeTokenFees(msg.sender, stakeTokenFeeBalance);
    }

    /// @dev Remove ether earned by reflect fees
    function withdrawEther() external onlyOwner {
        uint256 balance = address(this).balance;

        payable(msg.sender).transfer(balance);
    }

    /* Emergency Functions */

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw() external {
        UserInfo storage user = userInfo[msg.sender];

        uint256 amount = user.amount;

        STAKE_TOKEN.safeTransfer(address(msg.sender), amount);

        totalStaked = totalStaked - amount;

        user.amount = 0;
        user.reward0Debt = 0;
        user.reward1Debt = 0;

        emit EmergencyWithdraw(msg.sender, amount);
    }

    // Withdraw reward. EMERGENCY ONLY.
    function emergencyRewardWithdraw(uint256 _amount0, uint256 _amount1)
        external
        onlyOwner
    {
        (uint256 reward0Balance, uint256 reward1Balance) = rewardBalance();

        require(_amount0 <= reward0Balance, 'not enough rewards');
        require(_amount1 <= reward1Balance, 'not enough rewards');

        // Withdraw rewards
        safeTransferRewards(address(msg.sender), _amount0, _amount1);

        emit EmergencyRewardWithdraw(msg.sender, _amount0, _amount1);
    }

    /// @notice A public function to sweep accidental BEP20 transfers to this contract.
    ///   Tokens are sent to owner
    /// @param token The address of the BEP20 token to sweep
    function sweepToken(IERC20 token) external onlyOwner {
        require(
            address(token) != address(STAKE_TOKEN),
            'can not sweep stake token'
        );

        uint256 balance = token.balanceOf(address(this));

        token.transfer(msg.sender, balance);

        emit EmergencySweepWithdraw(msg.sender, token, balance);
    }
}