// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "./FinaFarming.sol";

contract FinaLockFarming is Initializable, OwnableUpgradeable, FinaFarming {
    using AddressUpgradeable for address;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    uint[] public depositTier; //requirements for deposit lock
    uint[] public rewardRatioByTier; //need to divide by 10000

    event Rewards(address who, uint pid, uint rewardOne, uint rewardTwo);
    event DepositTier(uint index, uint value);
    event RewardRatioByTier(uint index, uint value);

    constructor() {}

    function initialize(IERC20Upgradeable finaToken_, IERC20Upgradeable secondToken_, address devAddr_,
        uint rewardPerBlock_, uint startBlock_, uint[] calldata depositTier_, 
        uint[] calldata rewardRatioByTier_) external virtual initializer {
        __FinaFarming_init(finaToken_, secondToken_, devAddr_, rewardPerBlock_, startBlock_);
        setDepositTierAndRatio(depositTier_,rewardRatioByTier_);
    }

    function depositLP(uint _pid, uint _amount) external virtual override onlyEOA whenNotPaused {
        require(_amount>0, "deposit amount is null");
        LPPoolInfo storage lpPool = lpPoolInfo[_pid];
        UserLPInfo storage user = userLPInfo[_pid][_msgSender()];
        updateLPPool(_pid);
        if (user.amount > 0) {
            //use weight(amount) averaged time
            user.averageDepositedTime =
            (user.averageDepositedTime * user.amount + _amount * block.timestamp) / (user.amount + _amount);

        } else {
            user.firstDepositedTime = block.timestamp;
            user.averageDepositedTime = user.firstDepositedTime;
        }
        lpPool.lpToken.safeTransferFrom(address(_msgSender()), address(this), _amount);
        user.amount += _amount;
        user.rewardDebt = user.amount * lpPool.accRewardPerShare / 1e12;
        emit Deposit(_msgSender(), _pid, _amount);
    }

    function pendingLPRewardByTier(uint _pid, address _user) public view returns (uint[] memory pending) {
        LPPoolInfo storage lpPool = lpPoolInfo[_pid];
        UserLPInfo storage user = userLPInfo[_pid][_user];
        uint accRewardPerShare = lpPool.accRewardPerShare;
        uint lpSupply = lpPool.lpToken.balanceOf(address(this));
        if (block.number > lpPool.lastRewardBlock && lpSupply != 0) {
            uint multiplier = block.number - lpPool.lastRewardBlock;
            uint finaReward = multiplier * rewardPerBlock * lpPool.allocPoint / totalLPAllocPoint;
            accRewardPerShare = accRewardPerShare + (finaReward * 1e12 / lpSupply);
        }
        pending = new uint[](2);
        pending[0] = user.amount * accRewardPerShare / 1e12 - user.rewardDebt;
        pending[1] = pending[0] * secondRewardPerBlock / rewardPerBlock;
        if(pending[0] > 0){
            for(uint i = depositTier.length; i > 0; i--) {
                if(block.timestamp>= user.averageDepositedTime + depositTier[i-1]){
                    pending[0] = pending[0] * rewardRatioByTier[i] / 10000;
                    pending[1] = pending[1] * rewardRatioByTier[i] / 10000;
                }
            }
        }
    }

    function withdrawLP(uint _pid, uint _amount) external virtual override onlyEOA whenNotPaused {
        LPPoolInfo storage lpPool = lpPoolInfo[_pid];
        UserLPInfo storage user = userLPInfo[_pid][_msgSender()];
        require(user.amount >= _amount, "withdraw amount overflow");
        updateLPPool(_pid);
        uint[] memory p = pendingLPReward(_pid,_msgSender());
        uint pending = p[0];
        uint pendingExtra = p[1];

        if(pending > 0){
            for(uint i = depositTier.length; i > 0; i--) {
                if(block.timestamp>= user.averageDepositedTime + depositTier[i-1]){
                    finaToken.safeTransfer(_msgSender(), pending * rewardRatioByTier[i] / 10000);
                    secondRewardToken.safeTransfer(_msgSender(), pendingExtra * rewardRatioByTier[i] / 10000);
                    emit Rewards(_msgSender(), _pid, pending * rewardRatioByTier[i] / 10000, pendingExtra * rewardRatioByTier[i] / 10000);
                }
            }
        }

        if(_amount > 0) {
            lpPool.lpToken.safeTransfer(address(_msgSender()), _amount);
            if(_amount < user.amount) {
                //if not all withdrawn, update averageDepositedTime
                user.averageDepositedTime = (user.averageDepositedTime * user.amount - _amount * block.timestamp) / (user.amount - _amount);
            }
            user.amount = user.amount - _amount;
        } else {
            user.averageDepositedTime = block.timestamp;
        }
        user.rewardDebt = user.amount * lpPool.accRewardPerShare / 1e12;
        emit Withdraw(_msgSender(), _pid, _amount);
    }

    function withdrawEmergency(uint _pid) external virtual onlyEOA whenNotPaused {
        LPPoolInfo storage lpPool = lpPoolInfo[_pid];
        UserLPInfo storage user = userLPInfo[_pid][_msgSender()];
        require(user.amount >0, "withdraw zero amount");
        //no need to calculate rewards in emergency
        updateLPPool(_pid);
        lpPool.lpToken.safeTransfer(address(_msgSender()), user.amount);
        user.rewardDebt = user.amount * lpPool.accRewardPerShare / 1e12;
        emit Withdraw(_msgSender(), _pid, user.amount);
    }

    function setDepositTierAndRatio(uint[] calldata seconds_, uint[] calldata ratio_) onlyOwner public {
        require(seconds_.length >0, "array length is null!");
        require(seconds_.length == ratio_.length, "array length not equal!");
        for(uint i = 0; i < seconds_.length; i++){
            depositTier[i] = seconds_[i];//uint in seconds
            rewardRatioByTier[i] = ratio_[i];//divide by 10000
            emit DepositTier(i,seconds_[i] );
            emit RewardRatioByTier(i,ratio_[i]);
        }
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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

pragma solidity ^0.8.4;
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";


contract FinaFarming is Initializable, OwnableUpgradeable, PausableUpgradeable {
    using AddressUpgradeable for address;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    IERC20Upgradeable public finaToken;
    IERC20Upgradeable public secondRewardToken;

    modifier onlyEOA() {
        require(_msgSender() == tx.origin, "FinaFarming: not eoa");
        _;
    }

    struct UserLPInfo {
        uint amount;     // How many LP tokens the user has provided.
        uint rewardDebt; // pending reward = (user.amount * pool.accRewardPerShare) - user.rewardDebt
        uint firstDepositedTime; // keeps track of deposited time.
        uint averageDepositedTime; // use an average time for penalty calculation.
    }

    struct LPPoolInfo {
        IERC20Upgradeable lpToken;           // Address of LP token contract.
        uint allocPoint;       // How many allocation points assigned to this pool. 
        uint lastRewardBlock;  // Last block number that reward distribution occurs.
        uint accRewardPerShare; // Accumulated rewards per share, times 1e12.
    }

    // Info of each LP pool.
    LPPoolInfo[] public lpPoolInfo;
    // Info of each user that stakes LP tokens. pid => {user address => UserLPInfo}
    mapping (uint => mapping (address => UserLPInfo)) public userLPInfo;

    uint public totalLPAllocPoint;
    uint public startBlock;
    uint public rewardPerBlock; //for fina reward
    uint public secondRewardPerBlock; //for calculating second token as reward
    address public devAddr;

    event Deposit(address who, uint pid, uint amount);
    event Withdraw(address who, uint pid, uint amount);

    constructor() {}

    function initialize(IERC20Upgradeable finaToken_, IERC20Upgradeable secondToken_, address devAddr_,
        uint rewardPerBlock_, uint startBlock_) external virtual initializer {
        __FinaFarming_init(finaToken_, secondToken_, devAddr_, rewardPerBlock_, startBlock_);
    }

    function __FinaFarming_init(IERC20Upgradeable finaToken_, IERC20Upgradeable secondToken_, address devAddr_,
        uint rewardPerBlock_, uint startBlock_) internal initializer {
        __Ownable_init();
        __Pausable_init_unchained();
        require(address(finaToken_) != address(0),"finaToken_ address is null");
        require(address(secondToken_) != address(0),"secondToken_ address is null");
        finaToken = finaToken_;
        secondRewardToken = secondToken_;
        devAddr = devAddr_;
        rewardPerBlock = rewardPerBlock_;
        startBlock = startBlock_;
        totalLPAllocPoint = 0;
    }

    function addLPPool(IERC20Upgradeable lpToken_, uint allocPoint_, uint lastRewardBlock_) onlyOwner external {
        require(address(lpToken_) != address(0),"lpToken_ address is null");
        lpPoolInfo.push(LPPoolInfo({
            lpToken: lpToken_,
            allocPoint: allocPoint_,
            lastRewardBlock: lastRewardBlock_,
            accRewardPerShare: 0
        }));
        updateLPAllocPoint();
    }

    function resetLPPool(uint pid_, IERC20Upgradeable lpToken_, uint allocPoint_, uint lastRewardBlock_) onlyOwner external {
        lpPoolInfo[pid_].lpToken = lpToken_;
        lpPoolInfo[pid_].allocPoint = allocPoint_;
        lpPoolInfo[pid_].lastRewardBlock = lastRewardBlock_;
        updateLPAllocPoint();
    }

    function updateLPAllocPoint() internal {
        uint length = lpPoolInfo.length;
        uint points = 0;
        for (uint pid = 0; pid < length; pid++) {
            points = points + lpPoolInfo[pid].allocPoint;
        }
        if (points != 0) {
            totalLPAllocPoint = points;
        }
    }

    function depositLP(uint _pid, uint _amount) external virtual onlyEOA whenNotPaused {
        LPPoolInfo storage lpPool = lpPoolInfo[_pid];
        UserLPInfo storage user = userLPInfo[_pid][_msgSender()];
        updateLPPool(_pid);
        if (user.amount > 0) {
            uint pending = user.amount * lpPool.accRewardPerShare / 1e12 - user.rewardDebt;
            //give second token as reward
            uint pendingExtra = pending * secondRewardPerBlock / rewardPerBlock;
            if(pending > 0) {
                finaToken.safeTransferFrom(address(this),_msgSender(), pending);
                secondRewardToken.safeTransferFrom(address(this), _msgSender(), pendingExtra);
            }
        }
        if (_amount > 0) {
            lpPool.lpToken.safeTransferFrom(address(_msgSender()), address(this), _amount);
            user.amount = user.amount + _amount;
        }
        user.rewardDebt = user.amount * lpPool.accRewardPerShare / 1e12;
        emit Deposit(_msgSender(), _pid, _amount);
    }

    //update pool info
    function updateLPPool(uint _pid) public whenNotPaused {
        LPPoolInfo storage lpPool = lpPoolInfo[_pid];
        if (block.number <= lpPool.lastRewardBlock) { return;}
        uint lpSupply = lpPool.lpToken.balanceOf(address(this));
        if (lpSupply == 0) {
            lpPool.lastRewardBlock = block.number;
            return;
        }
        uint multiplier = block.number - lpPool.lastRewardBlock;
        uint finaReward = multiplier * rewardPerBlock * lpPool.allocPoint / totalLPAllocPoint;
        lpPool.accRewardPerShare += finaReward * 1e12 / lpSupply;
        lpPool.lastRewardBlock = block.number;
    }

    // View function to see pending fina rewards and second token rewards on frontend.
    function pendingLPReward(uint _pid, address _user) public view returns (uint[] memory pending) {
        LPPoolInfo storage lpPool = lpPoolInfo[_pid];
        UserLPInfo storage user = userLPInfo[_pid][_user];
        uint accRewardPerShare = lpPool.accRewardPerShare;
        uint lpSupply = lpPool.lpToken.balanceOf(address(this));
        if (block.number > lpPool.lastRewardBlock && lpSupply != 0) {
            uint multiplier = block.number - lpPool.lastRewardBlock;
            uint finaReward = multiplier * rewardPerBlock * lpPool.allocPoint / totalLPAllocPoint;
            accRewardPerShare = accRewardPerShare + (finaReward * 1e12 / lpSupply);
        }
        pending = new uint[](2);
        pending[0] = user.amount * accRewardPerShare / 1e12 - user.rewardDebt;
        pending[1] = pending[0] * secondRewardPerBlock / rewardPerBlock;
    }


    function withdrawLP(uint _pid, uint _amount) external virtual onlyEOA whenNotPaused {
        LPPoolInfo storage lpPool = lpPoolInfo[_pid];
        UserLPInfo storage user = userLPInfo[_pid][_msgSender()];
        require(user.amount >= _amount, "withdraw: not good");
        updateLPPool(_pid);
        uint pending = user.amount * lpPool.accRewardPerShare / 1e12 - user.rewardDebt;
        //give second token as reward
        uint pendingExtra = pending * secondRewardPerBlock / rewardPerBlock;
        if(pending > 0) {
            finaToken.safeTransferFrom(address(this),_msgSender(), pending);
            secondRewardToken.safeTransferFrom(address(this), _msgSender(), pendingExtra);
        }
        if(_amount > 0) {
            user.amount = user.amount - _amount;
            lpPool.lpToken.safeTransfer(address(_msgSender()), _amount);
        }
        user.rewardDebt = user.amount * lpPool.accRewardPerShare / 1e12;
        emit Withdraw(_msgSender(), _pid, _amount);
    }

    function setRewardPerBlock(uint _rewardPerBlock, uint _secondRewardPerBlock) onlyOwner external {
        require(_rewardPerBlock != 0, "The RewardPerBlock is null");
        require(_secondRewardPerBlock != 0, "The SecondRewardPerBlock is null");
        rewardPerBlock = _rewardPerBlock;
        secondRewardPerBlock = _secondRewardPerBlock;
    }

    function setFinaAddress(IERC20Upgradeable token_) onlyOwner external {
        require(address(token_) != address(0), "The address of token is null");
        finaToken = token_;
    }

    function setSecondTokenAddress(IERC20Upgradeable token_) onlyOwner external {
        require(address(token_) != address(0), "The address of token is null");
        secondRewardToken = token_;
    }

    function setDevAddress(address dev_) onlyOwner external {
        require(dev_ != address(0), "The address is null");
        devAddr = dev_;
    }

    /*
     * @dev Pull out all balance of token or BNB in this contract. When tokenAddress_ is 0x0, will transfer all BNB to the admin owner.
     */
    function pullFunds(address tokenAddress_) onlyOwner external {
        if (tokenAddress_ == address(0)) {
            payable(_msgSender()).transfer(address(this).balance);
        } else {
            IERC20Upgradeable token = IERC20Upgradeable(tokenAddress_);
            token.transfer(_msgSender(), token.balanceOf(address(this)));
        }
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
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
    function __Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}