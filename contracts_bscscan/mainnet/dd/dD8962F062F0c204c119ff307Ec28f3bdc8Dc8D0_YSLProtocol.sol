/**
 *Submitted for verification at BscScan.com on 2021-09-13
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

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
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

interface IsYSL is IERC20 {
    function YSLSupply() external returns (uint256);

    function isMinted() external returns (bool);

    function mintPurchased(
        address account,
        uint256 amount,
        uint256 lockTime
    ) external;

    function mintAirdropped(
        address account,
        uint256 amount,
        uint256 locktime
    ) external;

    function mintFor(address account, uint256 amount) external;

    function burnFrom(address account, uint256 amount) external;

    function mint(uint256 amount) external;
}

interface IStrategy {
    function deposit(address from, uint256 amount) external;

    function withdraw(uint256 amount, address user) external;

    function getUserDepositedUSD(address user) external view returns (uint256);

    function transferOut(address _user, uint256 _amount) external returns (uint256);

    function transferIn(address _user, uint256 _amount) external returns (uint256);

    function earn(address user, bool isAmplified) external;

    function lpToken() external view returns (IERC20);
}

interface IReferral {
    function hasReferral(address _account) external view returns (bool);

    function referrals(address _account) external view returns (address);

    function proccessReferral(
        address _sender,
        address _segCreator,
        bytes memory _sig
    ) external;

    function proccessReferral(address _sender, address _segCreator) external;
}

interface ILock {
    function setLock(
        uint256 _time,
        address _beneficiary,
        uint256 _amount
    ) external;

    function releaseClient(address _beneficiary, uint256 _amount) external;

    function lock(
        uint256 _amount,
        uint256 _time,
        address _user
    ) external;
}

contract YSLProtocol is OwnableUpgradeable {
    using SafeERC20 for IERC20;

    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
    }

    struct PoolInfo {
        IERC20 lpToken;
        uint256 allocPoint;
        uint256 lastRewardBlock;
        uint256 accsYSLPerShare;
        IStrategy strat;
        bool isActive;
    }

    uint256 public constant DECIMALS = 1e18;

    address public aYSL;
    // sYSL Token
    address public sYSL;

    address public referral;
    address public lockContract;
    address public treasury;

    uint256 public sYSLPerBlock;
    uint256 public totalAllocPoint;
    uint256 public lastTeamUpdate;
    uint256 public teamRate;

    PoolInfo[] public poolInfo;
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event SetTreasury(address indexed user, address indexed newTreasury);
    event UpdateEmissionRate(address indexed user, uint256 sYSLPerBlock);
    event Harvest(address indexed user, uint256 amount, uint256 poolId);

    modifier isActive(uint256 _pid) {
        require(poolInfo[_pid].isActive, "Pool is diactivated");
        _;
    }

    /**********
     * ADMIN INTERFACE
     **********/

    function initialize(
        address _aYSL,
        address _sYSL,
        address _treasury,
        address _referral,
        address _lockContract
    ) external initializer {
        aYSL = _aYSL;
        sYSL = _sYSL;
        treasury = _treasury;
        referral = _referral;
        __Ownable_init();

        teamRate = 200 * 10**18;
        lockContract = _lockContract;
    }

    /// @notice Add staking pool to the chief contract
    /// @param _allocPoint Rewards allocation
    /// @param _lpToken Addresses of the staked token
    /// @param _strat Attached strategy
    function add(
        uint256 _allocPoint,
        IERC20 _lpToken,
        address _strat
    ) external onlyOwner {
        require(_strat != address(0), "Zero address strategy");
        require(address(_lpToken) == address(IStrategy(_strat).lpToken()), "Incorrect underlying");

        uint256 lastRewardBlock = block.number;
        totalAllocPoint += _allocPoint;
        poolInfo.push(
            PoolInfo({
                lpToken: _lpToken,
                allocPoint: _allocPoint,
                lastRewardBlock: lastRewardBlock,
                accsYSLPerShare: 0,
                strat: IStrategy(_strat),
                isActive: true
            })
        );
        updatePool(poolInfo.length - 1);
        if (_allocPoint > 0) {
            IsYSL(sYSL).mintFor(address(this), _allocPoint);
        }
    }

    function setAlloc(uint256 _pid, uint256 _allocPoint) external onlyOwner {
        totalAllocPoint = totalAllocPoint - poolInfo[_pid].allocPoint + _allocPoint;
        poolInfo[_pid].allocPoint = _allocPoint;

        if (_allocPoint > 0) {
            IsYSL(sYSL).mintFor(address(this), _allocPoint);
        }
    }

    function setStrat(uint256 _pid, address _strat) external onlyOwner {
        require(address(poolInfo[_pid].lpToken) == address(IStrategy(_strat).lpToken()), "Incorrect underlying");
        poolInfo[_pid].strat = IStrategy(_strat);
    }

    function setTreasury(address _treasury) external onlyOwner {
        treasury = _treasury;
        emit SetTreasury(_msgSender(), _treasury);
    }

    function setTeamRate(uint256 _teamRate) external onlyOwner {
        teamRate = _teamRate;
    }

    function setReferral(address _referral) external onlyOwner {
        referral = _referral;
    }

    function updateEmissionRate(uint256 _sYSLPerBlock) external onlyOwner {
        massUpdatePools();
        sYSLPerBlock = _sYSLPerBlock;
        emit UpdateEmissionRate(_msgSender(), _sYSLPerBlock);
    }

    function activatePool(uint256 _pid) external onlyOwner {
        PoolInfo storage pool = poolInfo[_pid];
        require(!pool.isActive, "The pool is already activated");
        pool.isActive = false;
    }

    function deactivatePool(uint256 _pid) external onlyOwner {
        PoolInfo storage pool = poolInfo[_pid];
        require(pool.isActive, "The pool is already deactivated");
        pool.isActive = false;
    }

    /**********
     * MANAGEMENT INTERFACE
     **********/

    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    /// @notice Update reward variables of the given asset to be up-to-date.
    /// @param _pid Pool's id
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.lpToken.balanceOf(address(pool.strat));
        if (lpSupply == 0 || pool.allocPoint == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 sYSLReward = (multiplier * sYSLPerBlock * pool.allocPoint) / totalAllocPoint;

        pool.accsYSLPerShare = pool.accsYSLPerShare + ((sYSLReward * DECIMALS) / lpSupply);
        pool.lastRewardBlock = block.number;

        if (block.timestamp - lastTeamUpdate >= 1 days && teamRate > 0) {
            lastTeamUpdate = block.timestamp;
            IsYSL(sYSL).mintFor(treasury, teamRate);
        }
    }

    /**********
     * USER INTERFACE
     **********/

    /// @notice Deposit (stake) ASSET tokens
    /// @param _pid Pool's id
    /// @param _amount Amount to stake
    /// @param _referrer Referral linked user (if exist)
    function deposit(
        uint256 _pid,
        uint256 _amount,
        address _referrer
    ) public isActive(_pid) {
        require(_amount > 0, "Incorrect amount");
        updatePool(_pid);

        if (referral != address(0) && _referrer != address(0)) {
            IReferral(referral).proccessReferral(_msgSender(), _referrer);
        }

        PoolInfo memory pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_msgSender()];

        if (user.amount > 0) {
            uint256 pending = (user.amount * pool.accsYSLPerShare) / DECIMALS - user.rewardDebt;
            if (pending > 0) {
                user.rewardDebt = (user.amount * pool.accsYSLPerShare) / DECIMALS;
                safeSYSLtransfer(_msgSender(), pending);
            }
        }

        user.amount += _amount;
        // Get underlyings
        pool.lpToken.safeTransferFrom(address(_msgSender()), address(this), _amount);
        // Approve it for strategy
        pool.lpToken.approve(address(pool.strat), _amount);
        // Deposit to the strategy
        pool.strat.deposit(_msgSender(), _amount);
        emit Deposit(_msgSender(), _pid, _amount);
    }

    /// @notice Migrate from pool to pool
    /// @param _pid0 Incoming pool id
    /// @param _pid1 Outcoming pool id
    /// @param _amount Amount to migrate
    function depositFrom(
        uint256 _pid0,
        uint256 _pid1,
        uint256 _amount
    ) public isActive(_pid0) isActive(_pid1) {
        require(_amount > 0, "Insufficiant amount");
        updatePool(_pid0);
        updatePool(_pid1);

        PoolInfo memory pool0 = poolInfo[_pid0];
        PoolInfo memory pool1 = poolInfo[_pid1];
        UserInfo storage user0 = userInfo[_pid0][_msgSender()];
        UserInfo storage user1 = userInfo[_pid1][_msgSender()];

        require(user0.amount >= _amount, "Incorrect amount ot migrate");

        if (user0.amount > 0) {
            uint256 pending = (user0.amount * pool0.accsYSLPerShare) / DECIMALS - user0.rewardDebt;
            if (pending > 0) {
                user0.rewardDebt = (user0.amount * pool0.accsYSLPerShare) / DECIMALS;
                safeSYSLtransfer(_msgSender(), pending);
            }
        }
        user0.amount -= _amount;
        uint256 output = pool0.strat.transferOut(_msgSender(), _amount);

        if (user1.amount > 0) {
            uint256 pending = (user1.amount * pool1.accsYSLPerShare) / DECIMALS - user1.rewardDebt;
            if (pending > 0) {
                user1.rewardDebt = (user1.amount * pool1.accsYSLPerShare) / DECIMALS;
                safeSYSLtransfer(_msgSender(), pending);
            }
        }
        uint256 deposited = pool1.strat.transferIn(_msgSender(), output);
        user1.amount += deposited;

        emit Withdraw(_msgSender(), _pid0, _amount);
        emit Deposit(_msgSender(), _pid1, deposited);
    }

    /// @notice Withdraw (stake) ASSET tokens
    /// @param _pid Pool's id
    /// @param _amount Amount to withdraw
    function withdraw(uint256 _pid, uint256 _amount) public {
        require(_amount > 0, "Insufficiant amount");
        updatePool(_pid);

        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_msgSender()];
        require(user.amount >= _amount, "Incorrect amount to withdraw");

        // Get rewards - already done within harvest
        // Harvest first
        _harvest(_pid, _msgSender());

        // Withdraw lp
        user.amount -= _amount;
        pool.strat.withdraw(_amount, _msgSender());

        pool.lpToken.safeTransferFrom(address(pool.strat), _msgSender(), _amount);

        emit Withdraw(_msgSender(), _pid, _amount);
    }

    function harvestAll() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            harvest(pid);
        }
    }

    function harvest(uint256 _pid) public {
        updatePool(_pid);
        _harvest(_pid, _msgSender());
    }

    function _harvest(uint256 _pid, address _user) internal {
        PoolInfo memory pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];

        pool.strat.earn(_user, isAmplified(_user));

        uint256 pending = (user.amount * pool.accsYSLPerShare) / DECIMALS - user.rewardDebt;
        if (pending > 0) {
            user.rewardDebt = (user.amount * pool.accsYSLPerShare) / DECIMALS;
            safeSYSLtransfer(_user, pending);
        }
        emit Harvest(_user, pending, _pid);
    }

    /**********
     * VIEW USER'S INTERFACE
     **********/

    function pendingsYSL(uint256 _pid, address _user) public view returns (uint256) {
        PoolInfo memory pool = poolInfo[_pid];
        UserInfo memory user = userInfo[_pid][_user];

        uint256 accsYSLPerShare = pool.accsYSLPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(pool.strat));

        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 sYSLReward = (multiplier * sYSLPerBlock * pool.allocPoint) / totalAllocPoint;
            accsYSLPerShare += ((sYSLReward * DECIMALS) / lpSupply);
        }
        return (user.amount * accsYSLPerShare) / DECIMALS - user.rewardDebt;
    }

    function isAmplified(address _user) public view returns (bool) {
        uint256 aYSLamount = IERC20(aYSL).balanceOf(_user);
        if (aYSLamount == 0) return false;

        uint256 summ;
        for (uint256 i = 0; i < poolLength(); i++) {
            summ += poolInfo[i].strat.getUserDepositedUSD(_user);
        }
        return aYSLamount >= (summ / 10);
    }

    /**********
     * VIEW HELPERS
     **********/

    function poolLength() public view returns (uint256) {
        return poolInfo.length;
    }

    function getMultiplier(uint256 _from, uint256 _to) public pure returns (uint256) {
        return _to - _from;
    }

    function getTotalRewardInPools(address _user) public view returns (uint256 reward) {
        for (uint256 pid = 0; pid < poolInfo.length; ++pid) {
            reward += pendingsYSL(pid, _user);
        }
    }

    function safeSYSLtransfer(address _user, uint256 _amount) internal {
        IsYSL(sYSL).approve(lockContract, _amount);
        ILock(lockContract).lock(_amount, 90 days, _user);
    }
}