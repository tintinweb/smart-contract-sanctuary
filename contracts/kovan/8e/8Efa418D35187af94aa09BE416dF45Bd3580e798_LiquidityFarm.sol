/// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ONE_HUNDRED_PERCENT, ONE_YEAR} from "../Globals.sol";
import {ITrader} from "../interfaces/ITrader.sol";

interface IMintableERC20 is IERC20 {
    function mint(address to, uint256 amount) external;
}

interface ILiquidityPool is IERC20 {
    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );
}

/// @notice A farm that rewards LP token holder with fixed interest tokens.
/// A reward in given in pool's rDAI token by minting it. Thus this contract must have mint rights.
/// An interest rate is fixed, applied to rDAI token amount based on LP token share
/// at the moment of latest update (deposit or withdrawal).
/// Each liquidity pool can only have a farm with a single interest rate.
/// At the moment a farm can only be created; it can't be removed or modified.
contract LiquidityFarm is Ownable {
    using SafeERC20 for IERC20;

    uint256 constant TRADE_AMOUNT = 1 ether;

    struct StakeInfo {
        uint256 liquidity; // amount of deposited LP tokens
        uint256 reward; // amount of reward tokens already distributed to user but not claimed yet
        uint256 tokenStake; // amount of reward tokens staked
        uint256 updatedAt; // time of latest deposit or withdrawal
    }

    struct PoolInfo {
        address depositToken; // DAI
        address rewardToken; // rDAI
        uint256 apy;
        mapping(address => StakeInfo) stakes;
    }

    ITrader public trader;
    mapping(address => PoolInfo) pools;

    /// @notice Reverts if staking pool doesn't exist.
    modifier poolExists(address _pool) {
        require(pools[_pool].apy != 0, "POOL_NOT_EXISTS");
        _;
    }

    // TODO: return depositToken
    /// @notice Returns pool's farm info if it exists.
    function getPoolInfo(address _pool)
        public
        view
        returns (address _rewardToken, uint256 _apy)
    {
        _rewardToken = pools[_pool].rewardToken;
        _apy = pools[_pool].apy;
    }

    /// @notice Returns user's stake info in a given pool.
    function getStakeInfo(address _pool, address _user)
        public
        view
        returns (
            uint256 liquidity,
            uint256 reward,
            uint256 tokenStake,
            uint256 updatedAt
        )
    {
        StakeInfo storage stake = pools[_pool].stakes[_user];
        return (
            stake.liquidity,
            stake.reward,
            stake.tokenStake,
            stake.updatedAt
        );
    }

    /// @notice Returns current user's rewards.
    function getCurrentReward(address _pool, address user)
        public
        view
        returns (uint256)
    {
        PoolInfo storage pool = pools[_pool];
        StakeInfo storage stake = pool.stakes[user];
        return stake.reward + _calculateReward(_pool, stake);
    }

    constructor(address _trader) {
        require(_trader != address(0), "ZERO_ADDRESS");
        trader = ITrader(_trader);
    }

    /// @notice Creates a farm for liquidity pool.
    /// This contract must have rights to mint pool's rewarding token.
    /// @param apy is annual percentage yield denominated according to ONE_HUNDRED_PERCENT.
    function createFarm(
        address _pool,
        address rewardToken,
        uint256 apy
    ) public onlyOwner {
        require(apy > 0, "ILLEGAL_PARAMS");
        PoolInfo storage pool = pools[_pool];
        require(pool.apy == 0, "POOL_ALREADY_EXISTS");

        ILiquidityPool liquidityPool = ILiquidityPool(_pool);
        require(
            liquidityPool.token0() == rewardToken ||
                liquidityPool.token1() == rewardToken,
            "WRONG_REWARD_TOKEN"
        );

        pool.depositToken = liquidityPool.token0() == rewardToken
            ? liquidityPool.token1()
            : liquidityPool.token0();
        pool.rewardToken = rewardToken;
        pool.apy = apy;
    }

    /// @notice Updates a farm settings for the liquidity pool.
    /// @param apy is annual percentage yield denominated according to ONE_HUNDRED_PERCENT.
    function updateFarm(
        address _pool,
        address rewardToken,
        uint256 apy
    ) public onlyOwner {
        require(apy > 0, "ILLEGAL_PARAMS");
        PoolInfo storage pool = pools[_pool];
        require(pool.apy > 0, "POOL_DO_NOT_EXISTS");

        ILiquidityPool liquidityPool = ILiquidityPool(_pool);
        require(
            liquidityPool.token0() == rewardToken ||
                liquidityPool.token1() == rewardToken,
            "WRONG_REWARD_TOKEN"
        );

        pool.depositToken = liquidityPool.token0() == rewardToken
            ? liquidityPool.token1()
            : liquidityPool.token0();
        pool.rewardToken = rewardToken;
        pool.apy = apy;
    }

    /// @notice Deposit LP tokens for rewards allocation.
    /// Recalculates user's reward and base token value based on current share in LP.
    /// @param liquidity LP token amount to deposit.
    function deposit(address _pool, uint256 liquidity)
        public
        poolExists(_pool)
    {
        _updateDeposit(_pool, liquidity);
        IERC20(_pool).safeTransferFrom(msg.sender, address(this), liquidity);
    }

    /// @notice Same as deposit, but zaps deposit tokens into liquidity pool first.
    function depositZap(address _pool, uint256 depositTokenAmount)
        public
        poolExists(_pool)
    {
        uint256 liquidity = IERC20(_pool).balanceOf(address(this));
        // 1. swaps 50% of depositToken for rewardToken
        // 2. deposits both tokens into pool's liquidity
        // 3. lp tokens sent to this contract
        trader.zap(
            _pool,
            msg.sender,
            address(this),
            pools[_pool].depositToken,
            depositTokenAmount
        );
        uint256 depositLiquidity = IERC20(_pool).balanceOf(address(this)) -
            liquidity;
        // update sender's stake in farm
        _updateDeposit(_pool, depositLiquidity);
    }

    function _updateDeposit(address _pool, uint256 liquidity)
        private
        poolExists(_pool)
    {
        PoolInfo storage pool = pools[_pool];
        StakeInfo storage stake = pool.stakes[msg.sender];

        if (stake.tokenStake != 0) {
            stake.reward += _calculateReward(_pool, stake);
        }

        stake.liquidity += liquidity;
        stake.updatedAt = block.timestamp;

        uint256 poolBalance = IERC20(pool.rewardToken).balanceOf(_pool);
        uint256 totalLiquidity = IERC20(_pool).totalSupply();
        stake.tokenStake = (stake.liquidity * poolBalance) / totalLiquidity;
    }

    /// @notice Withdraw LP tokens.
    /// Recalculates user's reward and base token value based on current share in LP.
    /// @param _liquidity LP token amount to withdraw.
    function withdraw(address _pool, uint256 _liquidity)
        public
        poolExists(_pool)
    {
        _updateWithdraw(_pool, _liquidity);
        IERC20(_pool).safeTransferFrom(address(this), msg.sender, _liquidity);
    }

    /// @notice Withdraw LP tokens, removed liquidity from pool for tokens, claims all reward.
    function withdrawZapAndUnstake(address _pool, uint256 _amount)
        public
        poolExists(_pool)
    {
        require(
            pools[_pool].stakes[msg.sender].liquidity >= _amount,
            "You do not have that many liquidity tokens staked"
        );
        // update StakeInfo
        _updateWithdraw(_pool, _amount);
        // 1. remove LP from pool
        // 2. swap all rewardToken for depositToken
        // 3. send all deposit tokens to sender
        IERC20(_pool).safeTransfer(address(trader), _amount);
        trader.zapLPtoTokens(
            _pool,
            _amount,
            pools[_pool].depositToken,
            msg.sender
        );
        // claim all rewards
        claim(_pool);
    }

    function _updateWithdraw(address _pool, uint256 _liquidity)
        private
        poolExists(_pool)
    {
        PoolInfo storage pool = pools[_pool];
        StakeInfo storage stake = pool.stakes[msg.sender];
        require(_liquidity <= stake.liquidity, "NOT_ENOUGH_STAKED");

        stake.reward += _calculateReward(_pool, stake);

        stake.liquidity -= _liquidity;
        stake.updatedAt = block.timestamp;

        uint256 poolBalance = IERC20(pool.rewardToken).balanceOf(_pool);
        uint256 totalLiquidity = IERC20(_pool).totalSupply();
        stake.tokenStake = (stake.liquidity * poolBalance) / totalLiquidity;
    }

    /// @notice Called by a staker to claim rewards.
    function claim(address _pool) public {
        PoolInfo storage pool = pools[_pool];
        StakeInfo storage stake = pool.stakes[msg.sender];

        uint256 reward = stake.reward + _calculateReward(_pool, stake);
        stake.reward = 0;
        stake.updatedAt = block.timestamp;

        IMintableERC20(pool.rewardToken).mint(msg.sender, reward);
    }

    // TODO: cover by tests
    function _calculateReward(address _pool, StakeInfo storage _stake)
        private
        view
        returns (uint256 reward)
    {
        ILiquidityPool liquidityPool = ILiquidityPool(_pool);
        uint256 share = (_stake.tokenStake * ONE_HUNDRED_PERCENT) /
            liquidityPool.totalSupply();
        (uint256 t0, uint256 t1, ) = liquidityPool.getReserves();

        address depositToken = pools[_pool].depositToken;
        address rewardToken = pools[_pool].rewardToken;

        // three steps to find amount
        // 1. get the value of the debt token in the stablecoin
        uint256 amount = trader.getAmountOut(
            rewardToken,
            depositToken,
            TRADE_AMOUNT
        ) * (liquidityPool.token0() == depositToken ? t1 : t0);

        // 2. find the user's share of that pool but divide by the trade amount to account for rounding errors
        amount = (share * amount) / (ONE_HUNDRED_PERCENT * TRADE_AMOUNT);

        // 3. add in the share of the other part of the pool. The stablecoin part
        amount += (
            liquidityPool.token0() == depositToken
                ? (share * t0) / ONE_HUNDRED_PERCENT
                : (share * t1) / ONE_HUNDRED_PERCENT
        );

        uint256 duration = block.timestamp - _stake.updatedAt;
        uint256 apy = pools[_pool].apy;
        return (amount * duration * apy) / ONE_YEAR / ONE_HUNDRED_PERCENT;
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

// SPDX-License-Identifier: None
uint constant ONE_HUNDRED_PERCENT = 100 ether;      // NOTE This CAN NOT exceed 2^256/2 -1 as type casting to int occurs
uint constant LATE_PENALTY = 200 ether;
uint constant ONE_YEAR = 31556926;

address constant DEAD = 0x000000000000000000000000000000000000dEaD;

// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

interface ITrader{
    function trade(address, address, uint) external;
    function initPair(address, address) external returns(address);
    function getAmountOut(address, address, uint) external view returns(uint);
    function zap(address _lpToken, address _from, address _to, address _token, uint _amount) external;
    function zapLPtoTokens(address _lpToken, uint _amount, address _receivingToken, address _receiver) external;
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