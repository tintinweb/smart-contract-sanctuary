// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.7.6;

// Libraries
import '@openzeppelin/contracts/math/SafeMath.sol';
import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';

// Interfaces
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

// Contracts
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/ReentrancyGuard.sol';
import './StakingRewards.sol';

contract StakingRewardsFactory is Ownable, ReentrancyGuard {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;
  // immutables
  address public rewardsTokenDPX;
  address public rewardsTokenRDPX;
  uint256 public stakingRewardsGenesis;

  // the staking tokens for which the rewards contract has been deployed
  uint256[] public stakingID;

  // info about rewards for a particular staking token
  struct StakingRewardsInfo {
    address stakingRewards;
    uint256 rewardAmountDPX;
    uint256 rewardAmountRDPX;
    uint256 id;
  }

  // rewards info by staking token
  mapping(uint256 => StakingRewardsInfo) public stakingRewardsInfoByStakingToken;

  constructor(
    address _rewardsTokenDPX,
    address _rewardsTokenRDPX,
    uint256 _stakingRewardsGenesis
  ) Ownable() {
    require(
      _stakingRewardsGenesis >= block.timestamp,
      'StakingRewardsFactory::constructor: genesis too soon'
    );
    rewardsTokenDPX = _rewardsTokenDPX;
    rewardsTokenRDPX = _rewardsTokenRDPX;
    stakingRewardsGenesis = _stakingRewardsGenesis;
  }

  // deploy a staking reward contract for the staking token, and store the reward amount
  // the reward will be distributed to the staking reward contract no sooner than the genesis
  function deploy(
    address stakingToken,
    uint256 rewardAmountDPX,
    uint256 rewardAmountRDPX,
    uint256 rewardsDuration,
    uint256 boostedTimePeriod,
    uint256 boost,
    uint256 id
  ) public onlyOwner {
    StakingRewardsInfo storage info = stakingRewardsInfoByStakingToken[id];
    require(info.id != id, 'StakingID already taken');
    info.stakingRewards = address(
      new StakingRewards(
        address(this),
        rewardsTokenDPX,
        rewardsTokenRDPX,
        stakingToken,
        rewardsDuration,
        boostedTimePeriod,
        boost,
        id
      )
    );
    info.rewardAmountDPX = rewardAmountDPX;
    info.rewardAmountRDPX = rewardAmountRDPX;
    info.id = id;
    stakingID.push(id);
  }

  // Withdraw tokens in case functions exceed gas cost
  function withdrawRewardToken(uint256 amountDPX, uint256 amountRDPX)
    public
    onlyOwner
    returns (uint256, uint256)
  {
    address OwnerAddress = owner();
    if (OwnerAddress == msg.sender) {
      IERC20(rewardsTokenDPX).transfer(OwnerAddress, amountDPX);
      IERC20(rewardsTokenRDPX).transfer(OwnerAddress, amountRDPX);
    }
    return (amountDPX, amountRDPX);
  }

  function withdrawRewardTokensFromContract(
    uint256 amountDPX,
    uint256 amountRDPX,
    uint256 id
  ) public onlyOwner {
    address OwnerAddress = owner();
    if (OwnerAddress == msg.sender) {
      StakingRewardsInfo storage info = stakingRewardsInfoByStakingToken[id];
      require(
        info.stakingRewards != address(0),
        'StakingRewardsFactory::notifyRewardAmount: not deployed'
      );
      StakingRewards(info.stakingRewards).withdrawRewardTokens(amountDPX, amountRDPX);
    }
  }

  // notify reward amount for an individual staking token.
  // this is a fallback in case the notifyRewardAmounts costs too much gas to call for all contracts
  function notifyRewardAmount(uint256 id) public {
    require(
      block.timestamp >= stakingRewardsGenesis,
      'StakingRewardsFactory::notifyRewardAmount: not ready'
    );
    StakingRewardsInfo storage info = stakingRewardsInfoByStakingToken[id];
    require(
      info.stakingRewards != address(0),
      'StakingRewardsFactory::notifyRewardAmount: not deployed'
    );
    uint256 rewardAmountDPX = 0;
    uint256 rewardAmountRDPX = 0;
    if (info.rewardAmountDPX > 0) {
      rewardAmountDPX = info.rewardAmountDPX;
      info.rewardAmountDPX = 0;
      require(
        IERC20(rewardsTokenDPX).transfer(info.stakingRewards, rewardAmountDPX),
        'StakingRewardsFactory::notifyRewardAmount: transfer failed'
      );
    }
    if (info.rewardAmountRDPX > 0) {
      rewardAmountRDPX = info.rewardAmountRDPX;
      info.rewardAmountRDPX = 0;
      require(
        IERC20(rewardsTokenRDPX).transfer(info.stakingRewards, rewardAmountRDPX),
        'StakingRewardsFactory::notifyRewardAmount: transfer failed'
      );
    }
    StakingRewards(info.stakingRewards).notifyRewardAmount(rewardAmountDPX, rewardAmountRDPX);
  }

  ///// permissionless function

  // call notifyRewardAmount for all staking tokens.
  function notifyRewardAmounts() public {
    require(
      stakingID.length > 0,
      'StakingRewardsFactory::notifyRewardAmounts: called before any deploys'
    );
    for (uint256 i = 0; i < stakingID.length; i++) {
      notifyRewardAmount(stakingID[i]);
    }
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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
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
        require(b != 0, errorMessage);
        return a % b;
    }
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

import "../GSN/Context.sol";
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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

    constructor () internal {
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.7.6;

// Libraries
import '@openzeppelin/contracts/math/Math.sol';
import '@openzeppelin/contracts/math/SafeMath.sol';
import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';

// Interfaces
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import './interfaces/IStakingRewards.sol';

// Contracts
import '@openzeppelin/contracts/utils/ReentrancyGuard.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import './RewardsDistributionRecipient.sol';

contract StakingRewards is RewardsDistributionRecipient, ReentrancyGuard, Ownable {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  /* ========== STATE VARIABLES ========== */

  IERC20 public rewardsTokenDPX;
  IERC20 public rewardsTokenRDPX;
  IERC20 public stakingToken;
  uint256 public boost = 0;
  uint256 public periodFinish = 0;
  uint256 public boostedFinish = 0;
  uint256 public rewardRateDPX = 0;
  uint256 public rewardRateRDPX = 0;
  uint256 public rewardsDuration;
  uint256 public lastUpdateTime;
  uint256 public rewardPerTokenStoredDPX;
  uint256 public rewardPerTokenStoredRDPX;
  uint256 public boostedTimePeriod;
  uint256 public id;

  mapping(address => uint256) public userDPXRewardPerTokenPaid;
  mapping(address => uint256) public userRDPXRewardPerTokenPaid;
  mapping(address => uint256) public rewardsDPX;
  mapping(address => uint256) public rewardsRDPX;

  uint256 private _totalSupply;
  mapping(address => uint256) private _balances;

  /* ========== CONSTRUCTOR ========== */

  constructor(
    address _rewardsDistribution,
    address _rewardsTokenDPX,
    address _rewardsTokenRDPX,
    address _stakingToken,
    uint256 _rewardsDuration,
    uint256 _boostedTimePeriod,
    uint256 _boost,
    uint256 _id
  ) Ownable() {
    rewardsTokenDPX = IERC20(_rewardsTokenDPX);
    rewardsTokenRDPX = IERC20(_rewardsTokenRDPX);
    stakingToken = IERC20(_stakingToken);
    rewardsDistribution = _rewardsDistribution;
    rewardsDuration = _rewardsDuration;
    boostedTimePeriod = _boostedTimePeriod;
    boost = _boost;
    id = _id;
  }

  /* ========== VIEWS ========== */

  function totalSupply() external view returns (uint256) {
    return _totalSupply;
  }

  function balanceOf(address account) external view returns (uint256) {
    return _balances[account];
  }

  function lastTimeRewardApplicable() public view returns (uint256) {
    uint256 timeApp = Math.min(block.timestamp, periodFinish);
    return timeApp;
  }

  function rewardPerToken() public view returns (uint256, uint256) {
    if (_totalSupply == 0) {
      uint256 perTokenRateDPX = rewardPerTokenStoredDPX;
      uint256 perTokenRateRDPX = rewardPerTokenStoredRDPX;
      return (perTokenRateDPX, perTokenRateRDPX);
    }
    if (block.timestamp < boostedFinish) {
      uint256 perTokenRateDPX =
        rewardPerTokenStoredDPX.add(
          lastTimeRewardApplicable()
            .sub(lastUpdateTime)
            .mul(rewardRateDPX.mul(boost))
            .mul(1e18)
            .div(_totalSupply)
        );
      uint256 perTokenRateRDPX =
        rewardPerTokenStoredRDPX.add(
          lastTimeRewardApplicable()
            .sub(lastUpdateTime)
            .mul(rewardRateRDPX.mul(boost))
            .mul(1e18)
            .div(_totalSupply)
        );
      return (perTokenRateDPX, perTokenRateRDPX);
    } else {
      if (lastUpdateTime < boostedFinish) {
        uint256 perTokenRateDPX =
          rewardPerTokenStoredDPX
            .add(
            boostedFinish.sub(lastUpdateTime).mul(rewardRateDPX.mul(boost)).mul(1e18).div(
              _totalSupply
            )
          )
            .add(
            lastTimeRewardApplicable().sub(boostedFinish).mul(rewardRateDPX).mul(1e18).div(
              _totalSupply
            )
          );
        uint256 perTokenRateRDPX =
          rewardPerTokenStoredRDPX
            .add(
            boostedFinish.sub(lastUpdateTime).mul(rewardRateRDPX.mul(boost)).mul(1e18).div(
              _totalSupply
            )
          )
            .add(
            lastTimeRewardApplicable().sub(boostedFinish).mul(rewardRateRDPX).mul(1e18).div(
              _totalSupply
            )
          );
        return (perTokenRateDPX, perTokenRateRDPX);
      } else {
        uint256 perTokenRateDPX =
          rewardPerTokenStoredDPX.add(
            lastTimeRewardApplicable().sub(lastUpdateTime).mul(rewardRateDPX).mul(1e18).div(
              _totalSupply
            )
          );
        uint256 perTokenRateRDPX =
          rewardPerTokenStoredRDPX.add(
            lastTimeRewardApplicable().sub(lastUpdateTime).mul(rewardRateRDPX).mul(1e18).div(
              _totalSupply
            )
          );
        return (perTokenRateDPX, perTokenRateRDPX);
      }
    }
  }

  function earned(address account)
    public
    view
    returns (uint256 DPXtokensEarned, uint256 RDPXtokensEarned)
  {
    uint256 perTokenRateDPX;
    uint256 perTokenRateRDPX;
    (perTokenRateDPX, perTokenRateRDPX) = rewardPerToken();
    DPXtokensEarned = _balances[account]
      .mul(perTokenRateDPX.sub(userDPXRewardPerTokenPaid[account]))
      .div(1e18)
      .add(rewardsDPX[account]);
    RDPXtokensEarned = _balances[account]
      .mul(perTokenRateRDPX.sub(userRDPXRewardPerTokenPaid[account]))
      .div(1e18)
      .add(rewardsRDPX[account]);
  }

  /* ========== MUTATIVE FUNCTIONS ========== */
  function stakeWithPermit(
    uint256 amount,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external payable nonReentrant updateReward(msg.sender) {
    require(amount > 0, 'Cannot stake 0');
    _totalSupply = _totalSupply.add(amount);
    _balances[msg.sender] = _balances[msg.sender].add(amount);
    // permit
    IUniswapV2ERC20(address(stakingToken)).permit(
      msg.sender,
      address(this),
      amount,
      deadline,
      v,
      r,
      s
    );
    stakingToken.safeTransferFrom(msg.sender, address(this), amount);
    emit Staked(msg.sender, amount);
  }

  function stake(uint256 amount) external payable nonReentrant updateReward(msg.sender) {
    require(amount > 0, 'Cannot stake 0');
    _totalSupply = _totalSupply.add(amount);
    _balances[msg.sender] = _balances[msg.sender].add(amount);
    stakingToken.safeTransferFrom(msg.sender, address(this), amount);
    emit Staked(msg.sender, amount);
  }

  function withdraw(uint256 amount) public nonReentrant updateReward(msg.sender) {
    require(amount > 0, 'Cannot withdraw 0');
    require(amount <= _balances[msg.sender], 'Insufficent balance');
    _totalSupply = _totalSupply.sub(amount);
    _balances[msg.sender] = _balances[msg.sender].sub(amount);
    stakingToken.safeTransfer(msg.sender, amount);
    emit Withdrawn(msg.sender, amount);
  }

  function withdrawRewardTokens(uint256 amountDPX, uint256 amountRDPX)
    public
    onlyOwner
    returns (uint256, uint256)
  {
    address OwnerAddress = owner();
    if (OwnerAddress == msg.sender) {
      IERC20(rewardsTokenDPX).safeTransfer(OwnerAddress, amountDPX);
      IERC20(rewardsTokenRDPX).safeTransfer(OwnerAddress, amountRDPX);
    }
    return (amountDPX, amountRDPX);
  }

  function compound() public nonReentrant updateReward(msg.sender) {
    uint256 rewardDPX = rewardsDPX[msg.sender];
    require(rewardDPX > 0, 'stake address not found');
    require(rewardsTokenDPX == stakingToken, "Can't stake the reward token.");
    rewardsDPX[msg.sender] = 0;
    _totalSupply = _totalSupply.add(rewardDPX);
    _balances[msg.sender] = _balances[msg.sender].add(rewardDPX);
    emit RewardCompounded(msg.sender, rewardDPX);
  }

  function getReward(uint256 rewardsTokenID) public nonReentrant updateReward(msg.sender) {
    if (rewardsTokenID == 0) {
      uint256 rewardDPX = rewardsDPX[msg.sender];
      require(rewardDPX > 0, 'can not withdraw 0 DPX reward');
      rewardsDPX[msg.sender] = 0;
      rewardsTokenDPX.safeTransfer(msg.sender, rewardDPX);
      emit RewardPaid(msg.sender, rewardDPX);
    } else if (rewardsTokenID == 1) {
      uint256 rewardRDPX = rewardsRDPX[msg.sender];
      require(rewardRDPX > 0, 'can not withdraw 0 RDPX reward');
      rewardsRDPX[msg.sender] = 0;
      rewardsTokenRDPX.safeTransfer(msg.sender, rewardRDPX);
      emit RewardPaid(msg.sender, rewardRDPX);
    } else {
      uint256 rewardDPX = rewardsDPX[msg.sender];
      uint256 rewardRDPX = rewardsRDPX[msg.sender];
      if (rewardDPX > 0) {
        rewardsDPX[msg.sender] = 0;
        rewardsTokenDPX.safeTransfer(msg.sender, rewardDPX);
      }
      if (rewardRDPX > 0) {
        rewardsRDPX[msg.sender] = 0;
        rewardsTokenRDPX.safeTransfer(msg.sender, rewardRDPX);
      }
      emit RewardPaid(msg.sender, rewardDPX);
      emit RewardPaid(msg.sender, rewardRDPX);
    }
  }

  function exit() external {
    getReward(2);
    withdraw(_balances[msg.sender]);
  }

  /* ========== RESTRICTED FUNCTIONS ========== */

  function notifyRewardAmount(uint256 rewardDPX, uint256 rewardRDPX)
    external
    override
    onlyRewardsDistribution
    setReward(address(0))
  {
    if (periodFinish == 0) {
      rewardRateDPX = rewardDPX.div(rewardsDuration.add(boostedTimePeriod));
      rewardRateRDPX = rewardRDPX.div(rewardsDuration.add(boostedTimePeriod));
      lastUpdateTime = block.timestamp;
      periodFinish = block.timestamp.add(rewardsDuration);
      boostedFinish = block.timestamp.add(boostedTimePeriod);
    } else {
      uint256 remaining = periodFinish.sub(block.timestamp);
      uint256 leftoverDPX = remaining.mul(rewardRateDPX);
      uint256 leftoverRDPX = remaining.mul(rewardRateRDPX);
      rewardRateDPX = rewardDPX.add(leftoverDPX).div(rewardsDuration);
      rewardRateRDPX = rewardRDPX.add(leftoverRDPX).div(rewardsDuration);
      lastUpdateTime = block.timestamp;
      periodFinish = block.timestamp.add(rewardsDuration);
    }
    emit RewardAdded(rewardDPX, rewardRDPX);
  }

  /* ========== MODIFIERS ========== */

  // Modifier Set Reward modifier
  modifier setReward(address account) {
    (rewardPerTokenStoredDPX, rewardPerTokenStoredRDPX) = rewardPerToken();
    lastUpdateTime = lastTimeRewardApplicable();
    if (account != address(0)) {
      (rewardsDPX[account], rewardsRDPX[account]) = earned(account);
      userDPXRewardPerTokenPaid[account] = rewardPerTokenStoredDPX;
      userRDPXRewardPerTokenPaid[account] = rewardPerTokenStoredRDPX;
    }
    _;
  }

  // Modifier *Update Reward modifier*
  modifier updateReward(address account) {
    (rewardPerTokenStoredDPX, rewardPerTokenStoredRDPX) = rewardPerToken();
    lastUpdateTime = lastTimeRewardApplicable();
    if (account != address(0)) {
      (rewardsDPX[account], rewardsRDPX[account]) = earned(account);
      userDPXRewardPerTokenPaid[account] = rewardPerTokenStoredDPX;
      userRDPXRewardPerTokenPaid[account] = rewardPerTokenStoredRDPX;
    }
    _;
  }

  /* ========== EVENTS ========== */

  event RewardUpdated(uint256 rewardDPX, uint256 rewardRDPX);
  event RewardAdded(uint256 rewardDPX, uint256 rewardRDPX);
  event Staked(address indexed user, uint256 amount);
  event Withdrawn(address indexed user, uint256 amount);
  event RewardPaid(address indexed user, uint256 reward);
  event RewardCompounded(address indexed user, uint256 rewardDPX);
}

interface IUniswapV2ERC20 {
  function permit(
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;
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
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.7.6;

interface IStakingRewards {
  // Views
  function lastTimeRewardApplicable() external view returns (uint256);

  function rewardPerToken() external view returns (uint256, uint256);

  function earned(address account) external view returns (uint256, uint256);

  function getRewardForDuration() external view returns (uint256, uint256);

  function totalSupply() external view returns (uint256);

  function balanceOf(address account) external view returns (uint256);

  // Mutative

  function stake(uint256 amount) external payable;

  function withdraw(uint256 amount) external;

  function getReward(uint256 rewardsTokenID) external;

  function exit() external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.7.6;

abstract contract RewardsDistributionRecipient {
  address public rewardsDistribution;

  function notifyRewardAmount(uint256 rewardDPX, uint256 rewardRDPX) external virtual;

  modifier onlyRewardsDistribution() {
    require(msg.sender == rewardsDistribution, 'Caller is not RewardsDistribution contract');
    _;
  }
}

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}