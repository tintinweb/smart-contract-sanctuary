//"SPDX-License-Identifier: MIT"
pragma solidity 0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract LiquidityMining is Ownable {
    using SafeERC20 for IERC20;

    uint256 constant DECIMALS = 18;
    uint256 constant UNITS = 10**DECIMALS;

    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        uint256 rewardDebtAtBlock; // the last block user stake
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 token; // Address of LP token contract.
        uint256 tokenPerBlock; // tokens to distribute per block. There are aprox. 6500 blocks per day. 6500 * 1825 (5 years) = 11862500 total blocks. 600000000 token to be distributed in 11862500  = 50,579557428872497 token per block.
        uint256 lastRewardBlock; // Last block number that token distribution occurs.
        uint256 acctokenPerShare; // Accumulated tokens per share, times 1e18 (UNITS).
        uint256 waitForWithdraw; // Spent tokens until now, even if they are not withdrawn.
    }

    IERC20 public tokenToken;
    address public tokenLiquidityMiningWallet;

    // The block number when token mining starts.
    uint256 public START_BLOCK;

    // Info of each pool.
    PoolInfo[] public poolInfo;

    // tokenToPoolId
    mapping(address => uint256) public tokenToPoolId;

    // Info of each user that stakes LP tokens. pid => user address => info
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;

    event Deposit(address indexed user, uint256 indexed poolId, uint256 amount);

    event Withdraw(
        address indexed user,
        uint256 indexed poolId,
        uint256 amount
    );

    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed poolId,
        uint256 amount
    );

    event SendTokenReward(
        address indexed user,
        uint256 indexed poolId,
        uint256 amount
    );

    event TokenPerBlockSet(uint256 amount);

    constructor(
        address _tokenAddress,
        address _tokenLiquidityMiningWallet,
        uint256 _startBlock
    ) public  {
        require(_tokenAddress != address(0), "Token address should not be 0");
        require(_tokenLiquidityMiningWallet != address(0), "TokenLiquidityMiningWallet address should not be 0");
        tokenToken = IERC20(_tokenAddress);
        tokenLiquidityMiningWallet = _tokenLiquidityMiningWallet;
        START_BLOCK = _startBlock;
    }

    /********************** PUBLIC ********************************/

    // Add a new erc20 token to the pool. Can only be called by the owner.
    function add(
        uint256 _tokenPerBlock,
        IERC20 _token,
        bool _withUpdate
    ) external onlyOwner {
        require(
            tokenToPoolId[address(_token)] == 0,
            "Token is already in pool"
        );

        if (_withUpdate) {
            massUpdatePools();
        }

        uint256 lastRewardBlock = block.number > START_BLOCK
            ? block.number
            : START_BLOCK;

        tokenToPoolId[address(_token)] = poolInfo.length + 1;

        poolInfo.push(
            PoolInfo({
                token: _token,
                tokenPerBlock: _tokenPerBlock,
                lastRewardBlock: lastRewardBlock,
                acctokenPerShare: 0,
                waitForWithdraw: 0
            })
        );
    }

    // Update the given pool's token allocation point. Can only be called by the owner.
    function set(
        uint256 _poolId,
        uint256 _tokenPerBlock,
        bool _withUpdate
    ) external onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }

        poolInfo[_poolId].tokenPerBlock = _tokenPerBlock;
        emit TokenPerBlockSet(_tokenPerBlock);
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;

        for (uint256 poolId = 0; poolId < length; ++poolId) {
            updatePool(poolId);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _poolId) public {
        PoolInfo storage pool = poolInfo[_poolId];

        // Return if it's too early (if START_BLOCK is in the future probably)
        if (block.number <= pool.lastRewardBlock) return;

        // Retrieve amount of tokens held in contract
        uint256 poolBalance = pool.token.balanceOf(address(this));

        // If the contract holds no tokens at all, don't proceed.
        if (poolBalance == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }

        // Calculate the amount of token to send to the contract to pay out for this pool
        uint256 rewards = getPoolReward(
            pool.lastRewardBlock,
            block.number,
            pool.tokenPerBlock,
            pool.waitForWithdraw
        );
        pool.waitForWithdraw += rewards;

        // Update the accumulated tokenPerShare
        pool.acctokenPerShare = pool.acctokenPerShare + (rewards * UNITS/poolBalance);

        // Update the last block
        pool.lastRewardBlock = block.number;
    }

    // Get rewards for a specific amount of tokenPerBlocks
    function getPoolReward(
        uint256 _from,
        uint256 _to,
        uint256 _tokenPerBlock,
        uint256 _waitForWithdraw
    ) public view returns (uint256 rewards) {
        // Calculate number of blocks covered.
        uint256 blockCount = _to - _from;

        // Get the amount of token for this pool
        uint256 amount = blockCount*(_tokenPerBlock);

        // Retrieve allowance and balance
        uint256 allowedToken = tokenToken.allowance(
            tokenLiquidityMiningWallet,
            address(this)
        );
        uint256 farmingBalance = tokenToken.balanceOf(tokenLiquidityMiningWallet);

        // If the actual balance is less than the allowance, use the balance.
        allowedToken = farmingBalance < allowedToken
            ? farmingBalance
            : allowedToken;

        //no more token to pay as reward
        if(allowedToken <= _waitForWithdraw){
            return 0;
        }

        allowedToken = allowedToken - _waitForWithdraw;

        // If we reached the total amount allowed already, return the allowedToken
        if (allowedToken < amount) {
            rewards = allowedToken;
        } else {
            rewards = amount;
        }
    }

    function claimReward(uint256 _poolId) external {
        updatePool(_poolId);
        _harvest(_poolId);
    }

    // Deposit LP tokens to tokenStaking for token allocation.
    function deposit(uint256 _poolId, uint256 _amount) external {
        require(_amount > 0, "Amount cannot be 0");

        PoolInfo storage pool = poolInfo[_poolId];
        UserInfo storage user = userInfo[_poolId][msg.sender];

        updatePool(_poolId);

        _harvest(_poolId);

        // This is the very first deposit
        if (user.amount == 0) {
            user.rewardDebtAtBlock = block.number;
        }

        user.amount = user.amount+(_amount);
        user.rewardDebt = user.amount*(pool.acctokenPerShare)/(UNITS);
        emit Deposit(msg.sender, _poolId, _amount);

        pool.token.safeTransferFrom(
            address(msg.sender),
            address(this),
            _amount
        );
    }

    // Withdraw LP tokens from tokenStaking.
    function withdraw(uint256 _poolId, uint256 _amount) external {
        PoolInfo storage pool = poolInfo[_poolId];
        UserInfo storage user = userInfo[_poolId][msg.sender];

        require(_amount > 0, "Amount cannot be 0");

        updatePool(_poolId);
        _harvest(_poolId);

        user.amount = user.amount-(_amount);

        user.rewardDebt = user.amount*(pool.acctokenPerShare)/(UNITS);

        emit Withdraw(msg.sender, _poolId, _amount);

        pool.token.safeTransfer(address(msg.sender), _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _poolId) external {
        PoolInfo storage pool = poolInfo[_poolId];
        UserInfo storage user = userInfo[_poolId][msg.sender];

        uint256 amountToSend = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
        user.rewardDebtAtBlock = 0;

        emit EmergencyWithdraw(msg.sender, _poolId, amountToSend);

        pool.token.safeTransfer(address(msg.sender), amountToSend);
    }

    /********************** EXTERNAL ********************************/

    // Return the number of added pools
    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // View function to see pending tokens on frontend.
    function pendingReward(uint256 _poolId, address _user)
        external
        view
        returns (uint256)
    {
        PoolInfo storage pool = poolInfo[_poolId];
        UserInfo storage user = userInfo[_poolId][_user];

        uint256 acctokenPerShare = pool.acctokenPerShare;
        uint256 poolBalance = pool.token.balanceOf(address(this));

        if (block.number > pool.lastRewardBlock && poolBalance > 0) {
            uint256 rewards = getPoolReward(
                pool.lastRewardBlock,
                block.number,
                pool.tokenPerBlock,
                pool.waitForWithdraw
            );
            acctokenPerShare = acctokenPerShare+(
                rewards*(UNITS)/(poolBalance)
            );
        }

        uint256 pending = user.amount*(acctokenPerShare)/(UNITS)-(
            user.rewardDebt
        );

        return pending;
    }

    /********************** INTERNAL ********************************/

    function _harvest(uint256 _poolId) internal {
        PoolInfo storage pool = poolInfo[_poolId];
        UserInfo storage user = userInfo[_poolId][msg.sender];

        if (user.amount == 0) return;

        uint256 pending = user.amount*(pool.acctokenPerShare)/(UNITS)-(user.rewardDebt);

        uint256 tokenAvailable = tokenToken.balanceOf(tokenLiquidityMiningWallet);

        if (pending > tokenAvailable) {
            pending = tokenAvailable;
        }

        if (pending > 0) {
            user.rewardDebtAtBlock = block.number;

            user.rewardDebt = user.amount*(pool.acctokenPerShare)/(UNITS);

            pool.waitForWithdraw -= pending;

            emit SendTokenReward(msg.sender, _poolId, pending);

            // Pay out the pending rewards
            tokenToken.safeTransferFrom(
                tokenLiquidityMiningWallet,
                msg.sender,
                pending
            );
            return;
        }

        user.rewardDebt = user.amount*(pool.acctokenPerShare)/(UNITS);
    }
    function changeRewardsWallet(address _address) external onlyOwner {
        require(_address != address(0),"Address should not be 0");
        tokenLiquidityMiningWallet = _address;
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