// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract OrbStaking is ReentrancyGuard, Ownable {
    enum PoolType {
        LockTime,
        Unlimited
    }
    struct PoolInfo {
        IERC20 rewardToken;
        IERC20 stakingToken;
        uint256 startTime;
        uint256 rewardRate;
        uint256 lastUpdateTime;
        uint256 rewardPerTokenStored;
        uint256 totalSupply;
        PoolType poolType;
        uint256 lockTime;
        uint256 minDeposit;
    }

    event Staked(
        address indexed user,
        uint256 indexed pId,
        uint256 indexed packId,
        uint256 amount
    );
    event Withdrawn(
        address indexed user,
        uint256 indexed pId,
        uint256 indexed packId,
        uint256 amount
    );
    event GetReward(
        address indexed user,
        uint256 indexed pId,
        uint256 indexed packId,
        uint256 reward
    );

    using SafeERC20 for IERC20;
    PoolInfo[] public pools;

    mapping(uint256 => mapping(address => mapping(uint256 => uint256)))
        public userRewardPerTokenPaid;
    mapping(uint256 => mapping(address => mapping(uint256 => uint256)))
        public rewards;
    mapping(uint256 => mapping(address => mapping(uint256 => uint256)))
        public balances;
    mapping(uint256 => mapping(address => mapping(uint256 => uint256)))
        public timeBeginStaking;
    mapping(uint256 => mapping(address => uint256)) public totalPack;
    mapping(uint256 => mapping(address => bool)) private isStaked;

    /* 
     modifier function
    */

    modifier checkStart(uint256 pId) {
        require(block.timestamp >= pools[pId].startTime, "ORB: Not start");
        require(pId < pools.length, "ORB: pool Id not exist");
        _;
    }

    modifier updateReward(
        uint256 pId,
        uint256 packId,
        address account
    ) {
        updateRewardFnc(pId, packId, account);
        _;
    }

    /*
        external function 
    */

    function addPool(
        address _rewardToken,
        address _stakingToken,
        uint256 _startTime,
        uint256 _rewardRate,
        uint256 _poolType,
        uint256 _lockTime,
        uint256 _minDeposit
    ) external onlyOwner {
        pools.push(
            PoolInfo(
                IERC20(_rewardToken),
                IERC20(_stakingToken),
                _startTime,
                _rewardRate,
                0,
                0,
                0,
                PoolType(_poolType),
                _lockTime,
                _minDeposit
            )
        );
    }

    function stake(uint256 pId, uint256 amount) external checkStart(pId) {
        require(amount > 0, "Cannot not stake 0");

        if (pools[pId].poolType == PoolType.Unlimited) {
            updateRewardFnc(pId, 0, msg.sender);
            pools[pId].totalSupply += amount;
            balances[pId][msg.sender][0] += amount;
            pools[pId].stakingToken.safeTransferFrom(
                msg.sender,
                address(this),
                amount
            );
            if (!isStaked[pId][msg.sender]) {
                isStaked[pId][msg.sender] = true;
            }
            emit Staked(msg.sender, pId, 0, amount);
        } else {
            require(amount >= pools[pId].minDeposit, "ORB: amount invalid");
            uint256 index = totalPack[pId][msg.sender];
            updateRewardFnc(pId, index, msg.sender);
            pools[pId].totalSupply += amount;
            balances[pId][msg.sender][index] += amount;
            pools[pId].stakingToken.safeTransferFrom(
                msg.sender,
                address(this),
                amount
            );
            timeBeginStaking[pId][msg.sender][index] = block.timestamp;
            totalPack[pId][msg.sender] = index + 1;
            if (!isStaked[pId][msg.sender]) {
                isStaked[pId][msg.sender] = true;
            }
            emit Staked(msg.sender, pId, index, amount);
        }
    }

    /*
     external view function 
    */

    function isStakingInPoolId(uint256 pId, address account)
        external
        view
        returns (bool)
    {
        return isStaked[pId][account];
    }

    function getTotalPool() external view returns (uint256) {
        return pools.length;
    }

    function getPoolInfoById(uint256 pId)
        external
        view
        returns (
            address,
            address,
            uint256,
            uint256,
            PoolType,
            uint256,
            uint256
        )
    {
        require(pId < pools.length, "ORB pool id not exist");
        return (
            address(pools[pId].rewardToken),
            address(pools[pId].stakingToken),
            pools[pId].startTime,
            pools[pId].rewardRate,
            pools[pId].poolType,
            pools[pId].lockTime,
            pools[pId].minDeposit
        );
    }

    function totalSupply(uint256 pId) external view returns (uint256) {
        require(pId < pools.length, "ORB: pool Id not exist");
        return pools[pId].totalSupply;
    }

    function balanceOf(
        uint256 pId,
        uint256 packId,
        address account
    ) external view returns (uint256) {
        require(pId < pools.length, "ORB: pool Id not exist");
        require(packId <= totalPack[pId][account], "ORB: pack not exist");
        return balances[pId][account][packId];
    }

    function rewardPerToken(uint256 pId) public view returns (uint256) {
        require(pId < pools.length, "ORB: pool Id not exist");
        if (pools[pId].totalSupply == 0) {
            return pools[pId].rewardPerTokenStored;
        }
        return
            pools[pId].rewardPerTokenStored +
            ((block.timestamp - pools[pId].lastUpdateTime) *
                pools[pId].rewardRate *
                1e18) /
            pools[pId].totalSupply;
    }

    function earned(
        uint256 pId,
        uint256 packId,
        address account
    ) public view returns (uint256) {
        require(pId < pools.length, "ORB: pool Id not exist");
        require(packId <= totalPack[pId][account], "ORB: pack not exist");
        return
            (balances[pId][account][packId] *
                (rewardPerToken(pId) -
                    userRewardPerTokenPaid[pId][account][packId])) /
            1e18 +
            rewards[pId][account][packId];
    }

    function withdraw(
        uint256 pId,
        uint256 packId,
        uint256 amount
    )
        public
        nonReentrant
        updateReward(pId, packId, msg.sender)
        checkStart(pId)
    {
        require(amount > 0, "Cannot withdraw 0");
        if (pools[pId].poolType == PoolType.Unlimited) {
            pools[pId].totalSupply -= amount;
            balances[pId][msg.sender][0] -= amount;
            pools[pId].stakingToken.safeTransfer(msg.sender, amount);
            emit Withdrawn(msg.sender, pId, 0, amount);
        } else {
            require(packId <= totalPack[pId][msg.sender], "ORB: pack not exist");
            require(
                timeBeginStaking[pId][msg.sender][packId] +
                    pools[pId].lockTime <
                    block.timestamp,
                "ORB: Cannot withdraw in lock time!"
            );
            pools[pId].totalSupply -= amount;
            balances[pId][msg.sender][packId] -= amount;
            pools[pId].stakingToken.safeTransfer(msg.sender, amount);
            emit Withdrawn(msg.sender, pId, packId, amount);
        }
    }

    function getReward(uint256 pId, uint256 packId)
        public
        nonReentrant
        updateReward(pId, packId, msg.sender)
        checkStart(pId)
    {
        require(packId <= totalPack[pId][msg.sender], "ORB: pack not exist");
        uint256 reward = rewards[pId][msg.sender][packId];
        if (reward > 0) {
            rewards[pId][msg.sender][packId] = 0;
            pools[pId].rewardToken.safeTransferFrom(
                address(this),
                msg.sender,
                reward
            );
            emit GetReward(msg.sender, pId, packId, reward);
        }
    }

    function exit(uint256 pId, uint256 packId) external {
        require(pId < pools.length, "ORB: pool Id not exist");
        require(packId <= totalPack[pId][msg.sender], "ORB: pack not exist");
        withdraw(pId, packId, balances[pId][msg.sender][packId]);
        getReward(pId, packId);
    }

    /*
    private function 

    */
    function updateRewardFnc(
        uint256 pId,
        uint256 packId,
        address account
    ) private {
        pools[pId].rewardPerTokenStored = rewardPerToken(pId);
        pools[pId].lastUpdateTime = block.timestamp;
        rewards[pId][account][packId] = earned(pId, packId, account);
        userRewardPerTokenPaid[pId][account][packId] = pools[pId]
            .rewardPerTokenStored;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/utils/SafeERC20.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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