// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;
pragma abicoder v2;

import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import {SharedDataTypes} from "../libraries/SharedDataTypes.sol";
import {UZV1BasePool} from "./UZV1BasePool.sol";

/**
 * @title UnizenBasicRewardPool
 * @author Unizen
 * @notice Reward pool for ERC20 tokens
 **/
contract UZV1BasicRewardPool is UZV1BasePool {
    using SafeMath for uint256;

    /* === STATE VARIABLES === */

    function initialize(address _router, address _accessToken)
        public
        override
        initializer
    {
        UZV1BasePool.initialize(_router, _accessToken);
    }

    /* === VIEW FUNCTIONS === */
    function canReceiveRewards() external pure override returns (bool) {
        return true;
    }

    function getPoolType() external pure override returns (uint8) {
        return 0;
    }

    function isPayable() public pure override returns (bool) {
        return false;
    }

    function isNative() public pure override returns (bool) {
        return false;
    }

    /* === MUTATING FUNCTIONS === */
    /// user functions
    function _safeClaim(address _user, uint256 _amount)
        internal
        override
        returns (uint256)
    {
        IERC20 _token = IERC20(_poolData.token);
        uint256 _balance = _token.balanceOf(address(this));
        uint256 _realAmount = (_amount <= _balance) ? _amount : _balance;

        if (_realAmount == 0) return 0;

        _poolStakerUser[_user].totalSavedRewards = _poolStakerUser[_user]
            .totalSavedRewards
            .add(_realAmount);

        _totalRewardsLeft = _totalRewardsLeft.sub(_realAmount);

        SafeERC20.safeTransfer(_token, _user, _realAmount);

        emit RewardClaimed(_user, _realAmount);
        return _realAmount;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

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
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

library SharedDataTypes {
    // struct for returning snapshot values
    struct StakeSnapshot {
        // initial block number snapshoted
        uint256 startBlock;
        // end block number snapshoted
        uint256 endBlock;
        // staked amount at initial block
        uint256 stakedAmount;
        // total value locked at end block
        uint256 tokenTVL;
    }

    // general staker user information
    struct StakerUser {
        // snapshotted stakes of the user per token (token => block.number => stakedAmount)
        mapping(address => mapping(uint256 => uint256)) stakedAmountSnapshots;
        // snapshotted stakes of the user per token keys (token => block.number[])
        mapping(address => uint256[]) stakedAmountKeys;
        // current stakes of the user per token
        mapping(address => uint256) stakedAmount;
        // total amount of holder tokens
        uint256 zcxhtStakedAmount;
    }

    // information for stakeable tokens
    struct StakeableToken {
        // snapshotted total value locked (TVL) (block.number => totalValueLocked)
        mapping(uint256 => uint256) totalValueLockedSnapshots;
        // snapshotted total value locked (TVL) keys (block.number[])
        uint256[] totalValueLockedKeys;
        // current total value locked (TVL)
        uint256 totalValueLocked;
        uint256 weight;
        bool active;
    }

    // POOL DATA

    // data object for a user stake on a pool
    struct PoolStakerUser {
        // saved / withdrawn rewards of user
        uint256 totalSavedRewards;
        // total purchased allocation
        uint256 totalPurchasedAllocation;
        // native address, if necessary
        string nativeAddress;
        // date/time when user has claimed the reward
        uint256 claimedTime;
    }

    // flat data type of stake for UI
    struct FlatPoolStakerUser {
        address[] tokens;
        uint256[] amounts;
        uint256 pendingRewards;
        uint256 totalPurchasedAllocation;
        uint256 totalSavedRewards;
        uint256 claimedTime;
        PoolState state;
        UserPoolState userState;
    }

    // UI information for pool
    // data will be fetched via github token repository
    // blockchain / cAddress being the most relevant values
    // for fetching the correct token data
    struct PoolInfo {
        // token name
        string name;
        // name of blockchain, as written on github
        string blockchain;
        // tokens contract address on chain
        string cAddress;
    }

    // possible states of the reward pool
    enum PoolState {
        pendingStaking,
        staking,
        pendingPayment,
        payment,
        pendingDistribution,
        distribution,
        retired
    }

    // possible states of the reward pool's user
    enum UserPoolState {
        notclaimed,
        claimed,
        rejected,
        missed
    }

    // input data for new reward pools
    struct PoolInputData {
        // total rewards to distribute
        uint256 totalRewards;
        // start block for distribution
        uint256 startBlock;
        // end block for distribution
        uint256 endBlock;
        // erc token address
        address token;
        // pool type
        uint8 poolType;
        // information about the reward token
        PoolInfo tokenInfo;
    }

    struct PoolData {
        PoolState state;
        // pool information for the ui
        PoolInfo info;
        // start block of staking rewards
        uint256 startBlock;
        // end block of staking rewards
        uint256 endBlock;
        // start block of payment period
        uint256 paymentStartBlock;
        // end block of payment period
        uint256 paymentEndBlock;
        // start block of distribution period
        uint256 distributionStartBlock;
        // end block of distribution period
        uint256 distributionEndBlock;
        // total rewards for allocation
        uint256 totalRewards;
        // rewards per block
        uint256 rewardsPerBlock;
        // price of a single payment token
        uint256 rewardTokenPrice;
        // type of the pool
        uint8 poolType;
        // address of payment token
        address paymentToken;
        // address of reward token
        address token;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;
pragma abicoder v2;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import {IUZV1RewardPool} from "../interfaces/pools/IUZV1RewardPool.sol";
import {IUZV1Router} from "../interfaces/IUZV1Router.sol";

import {SharedDataTypes} from "../libraries/SharedDataTypes.sol";
import {UZV1ProAccess} from "../membership/UZV1ProAccess.sol";

/**
 * @title UnizenBasePool
 * @author Unizen
 * @notice Base Reward pool for Unizen. Serves as base for all existing pool types,
 * to ease more pool types and reduce duplicated code.
 * The base rewards calculation approach is based on the great work of MasterChef.sol by SushiSwap.
 * https://github.com/sushiswap/sushiswap/blob/master/contracts/MasterChef.sol
 **/
abstract contract UZV1BasePool is IUZV1RewardPool, UZV1ProAccess {
    using SafeMath for uint256;
    /* === STATE VARIABLES === */
    // router address
    IUZV1Router internal _router;
    address public override factory;

    // data of user stakes and rewards
    mapping(address => SharedDataTypes.PoolStakerUser) internal _poolStakerUser;

    // pool data
    SharedDataTypes.PoolData internal _poolData;

    // total rewards left
    uint256 internal _totalRewardsLeft;

    modifier onlyFactoryOrOwner() {
        require(
            _msgSender() == factory || _msgSender() == owner(),
            "ONLY_FACTORY_OR_OWNER"
        );
        _;
    }

    function initialize(address _newRouter, address _accessToken)
        public
        virtual
        override
        initializer
    {
        UZV1ProAccess.initialize(_accessToken);
        _router = IUZV1Router(_newRouter);
        emit PoolInitiated();
    }

    function setFactory(address _factory) external override onlyOwner {
        factory = _factory;
    }

    function transferOwnership(address _newOwner)
        public
        override(IUZV1RewardPool, OwnableUpgradeable)
        onlyOwner
    {
        OwnableUpgradeable.transferOwnership(_newOwner);
    }

    /* === VIEW FUNCTIONS === */
    function getUserPoolStake(address _user)
        public
        view
        virtual
        override
        returns (SharedDataTypes.PoolStakerUser memory)
    {
        return _poolStakerUser[_user];
    }

    function getPendingRewards(address _user)
        external
        view
        virtual
        override
        returns (uint256 reward)
    {
        return _getPendingRewards(_user);
    }

    /**
     * @dev  Calculates the current pending reward amounts of a user
     * @param _user The user to check
     *
     * @return reward uint256 pending amount of user rewards
     **/
    function _getPendingRewards(address _user)
        internal
        view
        returns (uint256 reward)
    {
        uint256 _totalRewards = _getTotalRewards(_user);
        return
            _totalRewards > _poolStakerUser[_user].totalSavedRewards
                ? _totalRewards.sub(_poolStakerUser[_user].totalSavedRewards)
                : 0;
    }

    /**
     * @dev  Calculates the current total reward amounts of a user
     * @param _user The user to check
     *
     * @return reward uint256 total amount of user rewards
     **/
    function _getTotalRewards(address _user)
        internal
        view
        returns (uint256 reward)
    {
        // no need to calculate, if rewards haven't started yet
        if (block.number < _poolData.startBlock) return 0;

        // get all tokens
        (
            address[] memory _allTokens,
            ,
            uint256[] memory _weights,
            uint256 _combinedWeight
        ) = _router.getAllTokens(_getLastRewardBlock());

        // loop through all active tokens and get users currently pending reward
        for (uint8 i = 0; i < _allTokens.length; i++) {
            // read user stakes for every token
            SharedDataTypes.StakeSnapshot[] memory _snapshots = _router
                .getUserStakesSnapshots(
                    _user,
                    _allTokens[i],
                    _poolData.startBlock,
                    _getLastRewardBlock()
                );

            // calculates reward for every snapshoted block period
            for (uint256 bl = 0; bl < _snapshots.length; bl++) {
                // calculate pending rewards for token and add it to total pending reward amount
                reward = reward.add(
                    _calculateTotalRewardForToken(
                        _snapshots[bl].stakedAmount,
                        _weights[i],
                        _combinedWeight,
                        _snapshots[bl].tokenTVL,
                        _snapshots[bl].endBlock.sub(_snapshots[bl].startBlock)
                    )
                );
            }
        }
    }

    /**
     * @dev  Returns whether the pool is currently active
     *
     * @return bool active status of pool
     **/
    function isPoolActive() public view virtual override returns (bool) {
        return (block.number >= _poolData.startBlock &&
            block.number <= _poolData.endBlock);
    }

    /**
     * @dev  Returns whether the pool can be payed with a token
     *
     * @return bool status if pool is payable
     **/
    function isPayable() public view virtual override returns (bool);

    /**
     * @dev  Returns whether the pool is a base or native pool
     *
     * @return bool True, if pool distributes native rewards
     **/
    function isNative() public view virtual override returns (bool);

    /**
     * @dev  Returns all relevant information of an pool, excluding the stakes
     * of users.
     *
     * @return PoolData object
     **/
    function getPoolInfo()
        external
        view
        virtual
        override
        returns (SharedDataTypes.PoolData memory)
    {
        SharedDataTypes.PoolData memory _data = _poolData;
        _data.state = getPoolState();
        return _data;
    }

    /**
     * @dev  Returns the current state of the pool. Not all states
     * are available on every pool type. f.e. payment
     *
     * @return PoolState State of the current phase
     *  * pendingStaking
     *  * staking
     *  * retired
     **/
    function getPoolState()
        public
        view
        virtual
        override
        returns (SharedDataTypes.PoolState)
    {
        // if current block is bigger than end block, return retired state
        if (block.number > _poolData.endBlock) {
            return SharedDataTypes.PoolState.retired;
        }

        // if current block is within start and end block, return staking phase
        if (
            block.number >= _poolData.startBlock &&
            block.number <= _poolData.endBlock
        ) {
            return SharedDataTypes.PoolState.staking;
        }

        // otherwise, pool is in pendingStaking state
        return SharedDataTypes.PoolState.pendingStaking;
    }

    /**
     * @dev  Returns the current state of the pool user
     *
     * @return UserPoolState State of the user for the current phase
     *  * notclaimed
     *  * claimed
     *  * rejected
     *  * missed
     **/
    function getUserPoolState()
        public
        view
        virtual
        override
        returns (SharedDataTypes.UserPoolState)
    {
        return SharedDataTypes.UserPoolState.notclaimed;
    }

    /**
     * @dev  Returns the current type of the pool
     *
     * @return uint8 id of used pool type
     **/
    function getPoolType() external view virtual override returns (uint8);

    /**
     * @dev Returns all relevant staking data for a user.
     *
     * @param _user address of user to check
     *
     * @return FlatPoolStakerUser data object, containing all information about the staking data
     *  * total tokens staked
     *  * total saved rewards (saved/withdrawn)
     *  * array with stakes for each active token
     **/
    function getUserInfo(address _user)
        public
        view
        virtual
        override
        returns (SharedDataTypes.FlatPoolStakerUser memory)
    {
        SharedDataTypes.FlatPoolStakerUser memory _userData;

        // use data from staking contract
        uint256[] memory _userStakes = _router.getUserStakes(
            _user,
            _getLastRewardBlock()
        );

        // get all tokens
        (address[] memory _allTokens, , , ) = _router.getAllTokens();

        _userData.totalSavedRewards = _poolStakerUser[_user].totalSavedRewards;
        _userData.pendingRewards = _getPendingRewards(_user);

        _userData.amounts = new uint256[](_allTokens.length);
        _userData.tokens = new address[](_allTokens.length);

        for (uint8 i = 0; i < _allTokens.length; i++) {
            _userData.tokens[i] = _allTokens[i];
            _userData.amounts[i] = _userStakes[i];
        }
        _userData.state = getPoolState();
        _userData.userState = getUserPoolState();

        return _userData;
    }

    /**
     * @dev  Returns whether the pool pays out any rewards. Usually true for onchain and
     * false of off-chain reward pools.
     *
     * @return bool True if the user can receive rewards
     **/
    function canReceiveRewards() external view virtual override returns (bool);

    /**
     * @dev  Returns the rewards that are left on the pool. This can be different, based
     * on the type of pool. While basic reward pools will just return the reward token balance,
     * off-chain pools will just store virtual allocations for users and incubators have different
     * returns, based on their current pool state
     *
     * @return uint256 Amount of rewards left
     **/
    function getAmountOfOpenRewards()
        external
        view
        virtual
        override
        returns (uint256)
    {
        return _totalRewardsLeft;
    }

    /**
     * @dev Returns the start block for staking
     * @return uint256 Staking start block number
     **/
    function getStartBlock() public view virtual override returns (uint256) {
        return _poolData.startBlock;
    }

    /**
     * @dev Returns the end block for staking
     * @return uint256 Staking end block number
     **/
    function getEndBlock() public view virtual override returns (uint256) {
        return _poolData.endBlock;
    }

    /**
     * @dev Returns start and end blocks for
     * all existing stages of the pool
     * @return uint256[] Array with all block numbers. Each phase always has startBlock, endBlock
     */
    function getTimeWindows()
        external
        view
        virtual
        override
        returns (uint256[] memory)
    {
        uint256[] memory timeWindows = new uint256[](2);
        timeWindows[0] = getStartBlock();
        timeWindows[1] = getEndBlock();
        return timeWindows;
    }

    /* === MUTATING FUNCTIONS === */
    /// user functions
    function pay(address _user, uint256 _amount)
        external
        virtual
        override
        onlyRouterOrProAccess(_msgSender())
        returns (uint256 refund)
    {
        revert();
    }

    function claimRewards(address _user)
        external
        virtual
        override
        whenNotPaused
        onlyRouterOrProAccess(_msgSender())
    {
        _claimRewards(_user);
    }

    function _claimRewards(address _user) internal virtual {
        uint256 _pendingRewards = _getPendingRewards(_user);

        // check if there are pending rewards
        if (_pendingRewards > 0) {
            // claim rewards
            _safeClaim(_user, _pendingRewards);
        }
    }

    /**
     * @dev  Allows the user to set a custom native address as receiver of rewards
     * as these rewards will be distributed off-chain.
     *
     * @param _user address of the user, we want to update
     * @param _receiver string users native address, where rewards will be sent to
     **/
    function setNativeAddress(address _user, string calldata _receiver)
        external
        override
        onlyRouterOrProAccess(_msgSender())
    {
        require(isNative() == true, "NO_NATIVE_ADDR_REQ");
        require(_user != address(0), "ZERO_ADDRESS");
        require(bytes(_receiver).length > 0, "EMPTY_RECEIVER");
        // if sender is not router, sender and user have to
        // be identical
        if (_msgSender() != address(_router)) {
            require(_msgSender() == _user, "FORBIDDEN");
        }

        _poolStakerUser[_user].nativeAddress = _receiver;
    }

    /**
     * @dev Returns the users current address as string, or the user provided
     * native address, if the pool is a native reward pool
     *
     * @param user address of the user
     * @return receiverAddress string of the users receiving address
     */
    function getUserReceiverAddress(address user)
        external
        view
        override
        returns (string memory receiverAddress)
    {
        require(user != address(0), "ZERO_ADDRESS");
        receiverAddress = (isNative() == true)
            ? _poolStakerUser[user].nativeAddress
            : _addressToString(user);
    }

    // helpers to convert address to string
    // https://ethereum.stackexchange.com/questions/72677/convert-address-to-string-after-solidity-0-5-x
    function _addressToString(address _addr)
        internal
        pure
        returns (string memory)
    {
        bytes32 value = bytes32(uint256(_addr));
        bytes memory alphabet = "0123456789abcdef";

        bytes memory str = new bytes(51);
        str[0] = "0";
        str[1] = "x";
        for (uint256 i = 0; i < 20; i++) {
            str[2 + i * 2] = alphabet[uint8(value[i + 12] >> 4)];
            str[3 + i * 2] = alphabet[uint8(value[i + 12] & 0x0f)];
        }
        return string(str);
    }

    /**
     * @dev Calculates the last reward block
     * @return uint256 Last reward block (block.number or _poolData.endBlock)
     **/
    function _getLastRewardBlock() internal view virtual returns (uint256) {
        return
            (block.number <= _poolData.endBlock)
                ? block.number
                : _poolData.endBlock;
    }

    /**
     * @dev  Safety function that takes care of claiming amounts that
     * exceed the reward that is left, in case there is a slight offset
     * due to rounding issues.
     *
     * @param _user The user we want to send rewards to
     * @param _amount The amount of rewards that should be claimed / sent
     **/
    function _safeClaim(address _user, uint256 _amount)
        internal
        virtual
        returns (uint256)
    {
        uint256 _realAmount = (_amount <= _totalRewardsLeft)
            ? _amount
            : _totalRewardsLeft;
        require(_realAmount > 0, "ZERO_REWARD_AMOUNT");

        _poolStakerUser[_user].totalSavedRewards = _poolStakerUser[_user]
            .totalSavedRewards
            .add(_realAmount);
        _totalRewardsLeft = _totalRewardsLeft.sub(_realAmount);

        emit RewardClaimed(_user, _realAmount);
        return _realAmount;
    }

    function _rewardsForToken(
        uint256 _weight,
        uint256 _combinedWeight,
        uint256 _tvl,
        uint256 _blocks
    ) internal view returns (uint256) {
        uint256 _reward = _blocks
            .mul(_poolData.rewardsPerBlock)
            .mul(_weight)
            .div(_combinedWeight);
        if (_tvl > 0) {
            return _reward.mul(1e18).div(_tvl);
        } else {
            return 0;
        }
    }

    function _calculateTotalRewardForToken(
        uint256 _userStakes,
        uint256 _weight,
        uint256 _combinedWeight,
        uint256 _tvl,
        uint256 _blocks
    ) internal view returns (uint256 reward) {
        uint256 _rewardsPerShare;

        // we only need to calculate this, if the user holds any
        // amount of this token
        if (_userStakes > 0) {
            // check if we need to calculate the rewards for more than the current block
            if (_tvl > 0) {
                // calculate the rewards per share
                _rewardsPerShare = _rewardsForToken(
                    _weight,
                    _combinedWeight,
                    _tvl,
                    _blocks
                );
                // check if there is any reward to calculate
                if (_rewardsPerShare > 0) {
                    // get the current reward for users stakes
                    reward = _userStakes.mul(_rewardsPerShare).div(1e18);
                }
            }
        }
    }

    /// control functions
    /**
     * @dev Withdrawal function to remove payments, leftover rewards or tokens sent by accident, to the owner
     *
     * @param _tokenAddress address of token to withdraw
     * @param _amount amount of tokens to withdraw, 0 for all
     */
    function withdrawTokens(address _tokenAddress, uint256 _amount)
        external
        override
        onlyFactoryOrOwner
    {
        require(_tokenAddress != address(0), "ZERO_ADDRESS");

        IERC20 _token = IERC20(_tokenAddress);
        uint256 _balance = _token.balanceOf(address(this));
        require(_balance > 0, "NO_TOKEN_BALANCE");

        uint256 _amountToWithdraw = (_amount > 0 && _amount <= _balance)
            ? _amount
            : _balance;

        SafeERC20.safeTransfer(_token, owner(), _amountToWithdraw);
    }

    /**
     * @dev Updates the start / endblock of the staking window. Also updated the rewards
     * per block based on the new timeframe. Use with caution: this function can result
     * in unexpected issues, if used during an active staking window.
     *
     * @param _startBlock start of the staking window
     * @param _endBlock end of the staking window
     */
    function setStakingWindow(uint256 _startBlock, uint256 _endBlock)
        public
        virtual
        override
        onlyFactoryOrOwner
    {
        require(_endBlock > _startBlock, "INVALID_END_BLOCK");
        require(_startBlock > 0, "INVALID_START_BLOCK");
        require(_endBlock > 0, "INVALID_END_BLOCK");
        // start block cant be in the past
        require(_startBlock >= block.number, "INVALID_START_BLOCK");

        _poolData.startBlock = _startBlock;
        _poolData.endBlock = _endBlock;

        // calculate rewards per block
        _poolData.rewardsPerBlock = _poolData.totalRewards.div(
            _poolData.endBlock.sub(_poolData.startBlock)
        );
    }

    /**
     * @dev  Updates the whole pool meta data, based on the new pool input object
     * This function should be used with caution, as it could result in unexpected
     * issues on the calculations. Ideally only used during waiting state
     *
     * @param _inputData object containing all relevant pool information
     **/
    function setPoolData(SharedDataTypes.PoolInputData calldata _inputData)
        external
        virtual
        override
        onlyFactoryOrOwner
    {
        // set pool data
        _poolData.totalRewards = _inputData.totalRewards;
        _poolData.token = _inputData.token;
        _poolData.poolType = _inputData.poolType;
        _poolData.info = _inputData.tokenInfo;

        _totalRewardsLeft = _inputData.totalRewards;

        // set staking window and calculate rewards per block
        setStakingWindow(_inputData.startBlock, _inputData.endBlock);

        emit PoolDataSet(
            _poolData.token,
            _poolData.totalRewards,
            _poolData.startBlock,
            _poolData.endBlock
        );
    }

    /* === MODIFIERS === */
    modifier onlyRouter() {
        require(_msgSender() == address(_router), "FORBIDDEN: ROUTER");
        _;
    }

    modifier onlyRouterOrProAccess(address _user) {
        if (_user != address(_router)) {
            _checkPro(_user);
        }
        _;
    }

    /* === EVENTS === */
    event PoolInitiated();

    event PoolDataSet(
        address rewardToken,
        uint256 totalReward,
        uint256 startBlock,
        uint256 endBlock
    );

    event RewardClaimed(address indexed user, uint256 amount);

    event AllocationPaid(
        address indexed user,
        address token,
        uint256 paidAmount,
        uint256 paidAllocation
    );
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

pragma solidity >=0.6.0 <0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/Initializable.sol";
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
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;
pragma abicoder v2;

import {SharedDataTypes} from "../../libraries/SharedDataTypes.sol";

interface IUZV1RewardPool {
    /* mutating functions */
    function claimRewards(address _user) external;

    function factory() external returns (address);

    function setFactory(address) external;

    function transferOwnership(address _newOwner) external;

    function pay(address _user, uint256 _amount)
        external
        returns (uint256 refund);

    /* view functions */
    // pool specific
    function canReceiveRewards() external view returns (bool);

    function isPoolActive() external view returns (bool);

    function isPayable() external view returns (bool);

    function isNative() external view returns (bool);

    function getPoolState() external view returns (SharedDataTypes.PoolState);

    function getUserPoolStake(address _user)
        external
        view
        returns (SharedDataTypes.PoolStakerUser memory);

    function getUserPoolState()
        external
        view
        returns (SharedDataTypes.UserPoolState);

    function getPoolType() external view returns (uint8);

    function getPoolInfo()
        external
        view
        returns (SharedDataTypes.PoolData memory);

    function getAmountOfOpenRewards() external view returns (uint256);

    function getStartBlock() external view returns (uint256);

    function getEndBlock() external view returns (uint256);

    function getTimeWindows() external view returns (uint256[] memory);

    function getUserReceiverAddress(address user)
        external
        view
        returns (string memory receiverAddress);

    // user specific
    function getPendingRewards(address _user)
        external
        view
        returns (uint256 reward);

    function getUserInfo(address _user)
        external
        view
        returns (SharedDataTypes.FlatPoolStakerUser memory);

    function setNativeAddress(address _user, string calldata _receiver)
        external;

    function initialize(address _router, address _accessToken) external;

    function setPoolData(SharedDataTypes.PoolInputData calldata _inputData)
        external;

    function withdrawTokens(address _tokenAddress, uint256 _amount) external;

    function setStakingWindow(uint256 _startBlock, uint256 _endBlock) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;
pragma abicoder v2;

import {IUZV1RewardPool} from "./pools/IUZV1RewardPool.sol";
import {SharedDataTypes} from "../libraries/SharedDataTypes.sol";

interface IUZV1Router {
    /* view functions */
    function getAllUserRewards(address _user)
        external
        view
        returns (address[] memory _pools, uint256[] memory _rewards);

    function getAllPools() external view returns (address[] memory);

    function getAllTokens()
        external
        view
        returns (
            address[] memory tokenList,
            uint256[] memory tokenTVLs,
            uint256[] memory weights,
            uint256 combinedWeight
        );

    function getAllTokens(uint256 _blocknumber)
        external
        view
        returns (
            address[] memory tokenList,
            uint256[] memory tokenTVLs,
            uint256[] memory weights,
            uint256 combinedWeight
        );

    function getTVLs() external view returns (uint256[] memory _tokenTVLs);

    function getTVLs(uint256 _blocknumber)
        external
        view
        returns (uint256[] memory _tokenTVLs);

    function getUserTVLShare(address _user, uint256 _precision)
        external
        view
        returns (uint256[] memory);

    function getStakingUserData(address _user)
        external
        view
        returns (
            address[] memory,
            uint256[] memory,
            uint256
        );

    function getTokenWeights()
        external
        view
        returns (uint256[] memory weights, uint256 combinedWeight);

    function getUserStakes(address _user)
        external
        view
        returns (uint256[] memory);

    function getUserStakes(address _user, uint256 _blocknumber)
        external
        view
        returns (uint256[] memory);

    function getUserStakesSnapshots(
        address _user,
        address _token,
        uint256 _startBlock,
        uint256 _endBlock
    )
        external
        view
        returns (SharedDataTypes.StakeSnapshot[] memory startBlocks);

    /* pool view functions */

    function canReceiveRewards(address _pool) external view returns (bool);

    function isPoolNative(address _pool) external view returns (bool);

    function getPoolState(address _pool)
        external
        view
        returns (SharedDataTypes.PoolState);

    function getPoolType(address _pool) external view returns (uint8);

    function getPoolInfo(address _pool)
        external
        view
        returns (SharedDataTypes.PoolData memory);

    function getTimeWindows(address _pool)
        external
        view
        returns (uint256[] memory);

    function getPoolUserReceiverAddress(address _pool, address _user)
        external
        view
        returns (string memory receiverAddress);

    function getPoolUserInfo(address _pool, address _user)
        external
        view
        returns (SharedDataTypes.FlatPoolStakerUser memory);

    function getTotalPriceForPurchaseableTokens(address _pool, address _user)
        external
        view
        returns (uint256);

    /* mutating functions */
    function claimAllRewards() external;

    function claimReward(address _pool) external returns (bool);

    function claimRewardsFor(IUZV1RewardPool[] calldata pools) external;

    function payRewardAndSetNativeAddressForPool(
        address _pool,
        uint256 _amount,
        string calldata _receiver
    ) external;

    function payRewardPool(address _pool, uint256 _amount) external;

    function createNewPool(
        uint256 totalRewards,
        uint256 startBlock,
        uint256 endBlock,
        address token,
        uint8 poolType,
        string memory name,
        string memory blockchain,
        string memory cAddress
    ) external returns (address);

    function setNativeAddressForPool(address _pool, string calldata _receiver)
        external;

    /* control functions */
    function setFactory(address _factory) external;

    function setStaking(address _staking) external;

    function emergencyWithdrawTokenFromRouter(address _token, uint256 _amount)
        external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;
pragma abicoder v2;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";

/**
 * @title UZProAccess
 * @author Unizen
 * @notice Simple abstract class to add easy checks
 * for pro membership access token
 **/
abstract contract UZV1ProAccess is
    Initializable,
    OwnableUpgradeable,
    PausableUpgradeable
{
    // internal storage of the erc721 token
    IERC721 internal _membershipToken;

    function initialize(address _token) public virtual initializer {
        __Ownable_init();
        __Pausable_init();
        _setMembershipToken(_token);
    }

    function membershipToken() public view returns (address) {
        return address(_membershipToken);
    }

    /* === CONTROL FUNCTIONS === */
    /**
     * @dev pause smart contract
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     * @dev unpause smart contract
     */
    function unPause() public onlyOwner {
        _unpause();
    }

    /**
     * @dev  Allows the owner of the contract, to update
     * the used membership token
     * @param _newToken address of the new erc721 token
     **/
    function setMembershipToken(address _newToken) public onlyOwner {
        _setMembershipToken(_newToken);
    }

    function _setMembershipToken(address _newToken) internal {
        if (_newToken == address(0) && address(_membershipToken) == address(0))
            return;

        require(_newToken != address(_membershipToken), "SAME_ADDRESS");
        _membershipToken = IERC721(_newToken);
    }

    /**
     * @dev  Internal function that checks if the users has any
     * membership tokens. Reverts, if none is found.
     * @param _user address of user to check
     **/
    function _checkPro(address _user) internal view {
        if (address(_membershipToken) != address(0)) {
            require(
                _membershipToken.balanceOf(_user) > 0,
                "FORBIDDEN: PRO_MEMBER"
            );
        }
    }

    /* === MODIFIERS === */
    modifier onlyPro(address _user) {
        _checkPro(_user);
        _;
    }

    /* === EVENTS === */
    event MembershipTokenUpdated(address _newTokenAddress);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
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
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
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
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

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

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

pragma solidity >=0.6.2 <0.8.0;

import "../../introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
      * @dev Safely transfers `tokenId` token from `from` to `to`.
      *
      * Requirements:
      *
      * - `from` cannot be the zero address.
      * - `to` cannot be the zero address.
      * - `tokenId` token must exist and be owned by `from`.
      * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
      * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
      *
      * Emits a {Transfer} event.
      */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./ContextUpgradeable.sol";
import "../proxy/Initializable.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}