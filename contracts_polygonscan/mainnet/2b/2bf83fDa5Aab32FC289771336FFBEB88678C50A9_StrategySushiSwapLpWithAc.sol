// SPDX-License-Identifier: ISC
/**
* By using this software, you understand, acknowledge and accept that Tetu
* and/or the underlying software are provided “as is” and “as available”
* basis and without warranties or representations of any kind either expressed
* or implied. Any use of this open source software released under the ISC
* Internet Systems Consortium license is done at your own risk to the fullest
* extent permissible pursuant to applicable law any and all liability as well
* as all warranties, including any fitness for a particular purpose with respect
* to Tetu and/or the underlying software and the use thereof are disclaimed.
*/
pragma solidity 0.8.4;


import "../../../base/strategies/masterchef-base/MCv2StrategyAC.sol";
import "../../../third_party/uniswap/IUniswapV2Pair.sol";

contract StrategySushiSwapLpWithAc is MCv2StrategyAC {

  address public constant _MASTER_CHEF_REWARD_POOL = address(0x0769fd68dFb93167989C6f7254cd0D766Fb2841F);
  address public constant _SUSHI_ROUTER = address(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506);
  IStrategy.Platform private constant _PLATFORM = IStrategy.Platform.SUSHI;
  // rewards
  address private constant SUSHI = address(0x0b3F868E0BE5597D5DB7fEB59E1CADBb0fdDa50a);
  address private constant WMATIC = address(0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270);
  address[] private sushiPoolRewards = [SUSHI, WMATIC];
  address[] private _assets;

  constructor(
    address _controller,
    address _vault,
    address _underlying,
    address _token0,
    address _token1,
    uint256 _poolId
  ) MCv2StrategyAC(_controller, _underlying, _vault, sushiPoolRewards, _MASTER_CHEF_REWARD_POOL, _poolId, _SUSHI_ROUTER) {
    require(_underlying != address(0), "zero underlying");
    require(_token0 != address(0), "zero token0");
    require(_token1 != address(0), "zero token1");
    require(_token0 != _token1, "same tokens");

    _assets.push(_token0);
    _assets.push(_token1);

    address token0 = IUniswapV2Pair(_underlying).token0();
    address token1 = IUniswapV2Pair(_underlying).token1();
    require(_token0 == token0 || _token0 == token1, "wrong token0");
    require(_token1 == token0 || _token1 == token1, "wrong token1");
  }


  function platform() external override pure returns (IStrategy.Platform) {
    return _PLATFORM;
  }

  // assets should reflect underlying tokens need to investing
  function assets() external override view returns (address[] memory) {
    return _assets;
  }
}

// SPDX-License-Identifier: ISC
/**
* By using this software, you understand, acknowledge and accept that Tetu
* and/or the underlying software are provided “as is” and “as available”
* basis and without warranties or representations of any kind either expressed
* or implied. Any use of this open source software released under the ISC
* Internet Systems Consortium license is done at your own risk to the fullest
* extent permissible pursuant to applicable law any and all liability as well
* as all warranties, including any fitness for a particular purpose with respect
* to Tetu and/or the underlying software and the use thereof are disclaimed.
*/

pragma solidity 0.8.4;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../StrategyBase.sol";
import "../../../third_party/sushi/IMiniChefV2.sol";
import "../../interface/IMasterChefStrategyV3.sol";

/// @title Abstract contract for MasterChef strategy implementation
/// @author belbix
abstract contract MCv2StrategyAC is StrategyBase, IMasterChefStrategyV3 {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  // ************ VARIABLES **********************
  /// @notice Strategy type for statistical purposes
  string public constant override STRATEGY_NAME = "MCv2StrategyAC";
  /// @notice Version of the contract
  /// @dev Should be incremented when contract changed
  string public constant VERSION = "1.0.0";
  /// @dev 1% buyback
  uint256 private constant _BUY_BACK_RATIO = 100;
  address private constant _SUSHI = address(0x0b3F868E0BE5597D5DB7fEB59E1CADBb0fdDa50a);

  /// @notice MasterChef rewards pool
  address public override mcRewardPool;
  /// @notice MasterChef rewards pool ID
  uint256 public override poolID;
  /// @notice Uniswap router for underlying LP
  address public router;

  /// @notice Contract constructor using on strategy implementation
  /// @dev The implementation should check each parameter
  /// @param _controller Controller address
  /// @param _underlying Underlying token address
  /// @param _vault SmartVault address that will provide liquidity
  /// @param __rewardTokens Reward tokens that the strategy will farm
  /// @param _mcRewardPool MasterChef pool address
  /// @param _poolID Pool id
  constructor(
    address _controller,
    address _underlying,
    address _vault,
    address[] memory __rewardTokens,
    address _mcRewardPool,
    uint256 _poolID,
    address _router
  ) StrategyBase(_controller, _underlying, _vault, __rewardTokens, _BUY_BACK_RATIO) {
    require(_mcRewardPool != address(0), "zero address pool");
    mcRewardPool = _mcRewardPool;
    poolID = _poolID;
    router = _router;

    address _lpt = IMiniChefV2(_mcRewardPool).lpToken(_poolID);
    require(_lpt == _underlyingToken, "wrong underlying");
  }

  // ************* VIEWS *******************

  /// @notice Strategy balance in the Master Chef pool
  /// @return bal Balance amount in underlying tokens
  function rewardPoolBalance() public override view returns (uint256 bal) {
    (bal,) = IMiniChefV2(mcRewardPool).userInfo(poolID, address(this));
  }

  /// @notice Return approximately amount of reward tokens ready to claim in Master Chef pool
  /// @dev Don't use it in any internal logic, only for statistical purposes
  /// @return Array with amounts ready to claim
  function readyToClaim() external view override returns (uint256[] memory) {
    uint256[] memory toClaim = new uint256[](2);
    (uint256 bal, uint256 debt) = IMiniChefV2(mcRewardPool).userInfo(poolID, address(this));

    (uint256 accSushiPerShare, uint256 lastRewardTime, uint256 allocPoint)
    = IMiniChefV2(mcRewardPool).poolInfo(poolID);

    if (block.timestamp > lastRewardTime) {
      uint256 sushiPerSecond = IMiniChefV2(mcRewardPool).sushiPerSecond();
      uint256 totalAllocPoint = IMiniChefV2(mcRewardPool).totalAllocPoint();
      uint256 lpSupply = IERC20(IMiniChefV2(mcRewardPool).lpToken(poolID)).balanceOf(mcRewardPool);
      if (lpSupply > 0) {
        uint256 time = block.timestamp.sub(lastRewardTime);
        uint256 sushiReward = time.mul(sushiPerSecond).mul(allocPoint).div(totalAllocPoint);
        accSushiPerShare = accSushiPerShare.add(sushiReward.mul(1e12).div(lpSupply));
      }
    }

    uint256 accumulatedSushi = bal * accSushiPerShare / 1e12;
    if (accumulatedSushi < debt) {
      toClaim[0] = 0;
    } else {
      toClaim[0] = accumulatedSushi - debt;
    }

    IRewarder _rewarder = IMiniChefV2(mcRewardPool).rewarder(poolID);
    if (address(_rewarder) != address(0)) {
      // we can't calculate more accurate because totalAllocPoint is private in the rewarder contract
      toClaim[1] = _rewarder.pendingToken(poolID, address(this));
    }

    return toClaim;
  }

  /// @notice TVL of the underlying in the Master Chef pool
  /// @dev Only for statistic
  /// @return Pool TVL
  function poolTotalAmount() external view override returns (uint256) {
    return IERC20(_underlyingToken).balanceOf(mcRewardPool);
  }

  // ************ GOVERNANCE ACTIONS **************************

  /// @notice Claim rewards from external project and send them to FeeRewardForwarder
  function doHardWork() external onlyNotPausedInvesting override restricted savePpfsInfo {
    IMiniChefV2(mcRewardPool).harvest(poolID, address(this));
    liquidateReward();
  }

  // ************ INTERNAL LOGIC IMPLEMENTATION **************************

  /// @dev Deposit underlying to Master Chef pool
  /// @param amount Deposit amount
  function depositToPool(uint256 amount) internal override {
    IERC20(_underlyingToken).safeApprove(mcRewardPool, 0);
    IERC20(_underlyingToken).safeApprove(mcRewardPool, amount);
    IMiniChefV2(mcRewardPool).deposit(poolID, amount, address(this));
  }

  /// @dev Deposit underlying to Master Chef pool
  /// @param amount Deposit amount
  function withdrawAndClaimFromPool(uint256 amount) internal override {
    (uint256 bal, uint256 debt) = IMiniChefV2(mcRewardPool).userInfo(poolID, address(this));
    (uint256 accSushiPerShare, ,) = IMiniChefV2(mcRewardPool).poolInfo(poolID);
    uint256 accumulatedSushi = bal * accSushiPerShare / 1e12;

    IRewarder rewarder = IMiniChefV2(mcRewardPool).rewarder(poolID);
    (IERC20[] memory tokens,) = rewarder.pendingTokens(poolID, address(this), 0);
    uint256 rewarderBal = tokens[0].balanceOf(address(rewarder));
    uint256 sushiBal = IERC20(_SUSHI).balanceOf(mcRewardPool);

    if (
    // sushi has a bug with rounding, in some cases we can't withdrawAndHarvest
      accumulatedSushi < debt
      // if mc or rewarder doesn't have enough balance make emergency withdraw
      || rewarderBal < 10 * 1e18
      || sushiBal < 10 * 1e18
    ) {
      IMiniChefV2(mcRewardPool).emergencyWithdraw(poolID, address(this));
    } else {
      IMiniChefV2(mcRewardPool).withdrawAndHarvest(poolID, amount, address(this));
    }
  }

  /// @dev Exit from external project without caring about rewards
  ///      For emergency cases only!
  function emergencyWithdrawFromPool() internal override {
    IMiniChefV2(mcRewardPool).emergencyWithdraw(poolID, address(this));
  }

  /// @dev Do something useful with farmed rewards
  function liquidateReward() internal override {
    autocompoundLP(router);
    // if we have not enough balance for buybacks we will autocompound 100%
    liquidateRewardSilently();
  }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.4;

interface IUniswapV2Pair {
  event Approval(address indexed owner, address indexed spender, uint value);
  event Transfer(address indexed from, address indexed to, uint value);

  function name() external pure returns (string memory);

  function symbol() external pure returns (string memory);

  function decimals() external pure returns (uint8);

  function totalSupply() external view returns (uint);

  function balanceOf(address owner) external view returns (uint);

  function allowance(address owner, address spender) external view returns (uint);

  function approve(address spender, uint value) external returns (bool);

  function transfer(address to, uint value) external returns (bool);

  function transferFrom(address from, address to, uint value) external returns (bool);

  function DOMAIN_SEPARATOR() external view returns (bytes32);

  function PERMIT_TYPEHASH() external pure returns (bytes32);

  function nonces(address owner) external view returns (uint);

  function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

  event Mint(address indexed sender, uint amount0, uint amount1);
  event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
  event Swap(
    address indexed sender,
    uint amount0In,
    uint amount1In,
    uint amount0Out,
    uint amount1Out,
    address indexed to
  );
  event Sync(uint112 reserve0, uint112 reserve1);

  function MINIMUM_LIQUIDITY() external pure returns (uint);

  function factory() external view returns (address);

  function token0() external view returns (address);

  function token1() external view returns (address);

  function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

  function price0CumulativeLast() external view returns (uint);

  function price1CumulativeLast() external view returns (uint);

  function kLast() external view returns (uint);

  function mint(address to) external returns (uint liquidity);

  function burn(address to) external returns (uint amount0, uint amount1);

  function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;

  function skim(address to) external;

  function sync() external;

  function initialize(address, address) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
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

// SPDX-License-Identifier: ISC
/**
* By using this software, you understand, acknowledge and accept that Tetu
* and/or the underlying software are provided “as is” and “as available”
* basis and without warranties or representations of any kind either expressed
* or implied. Any use of this open source software released under the ISC
* Internet Systems Consortium license is done at your own risk to the fullest
* extent permissible pursuant to applicable law any and all liability as well
* as all warranties, including any fitness for a particular purpose with respect
* to Tetu and/or the underlying software and the use thereof are disclaimed.
*/
pragma solidity 0.8.4;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../interface/IStrategy.sol";
import "../governance/Controllable.sol";
import "../interface/IFeeRewardForwarder.sol";
import "../interface/IBookkeeper.sol";
import "../../third_party/uniswap/IUniswapV2Pair.sol";
import "../../third_party/uniswap/IUniswapV2Router02.sol";
import "../interface/ISmartVault.sol";

/// @title Abstract contract for base strategy functionality
/// @author belbix
abstract contract StrategyBase is IStrategy, Controllable {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  uint256 internal constant _BUY_BACK_DENOMINATOR = 10000;

  //************************ VARIABLES **************************
  address internal _underlyingToken;
  address internal _smartVault;
  mapping(address => bool) internal _unsalvageableTokens;
  /// @dev we always use 100% buybacks but keep this variable to further possible changes
  uint256 internal _buyBackRatio;
  /// @dev When this flag is true, the strategy will not be able to invest. But users should be able to withdraw.
  bool public override pausedInvesting = false;
  address[] internal _rewardTokens;


  //************************ MODIFIERS **************************

  /// @dev Only for linked Vault or Governance/Controller.
  ///      Use for functions that should have strict access.
  modifier restricted() {
    require(msg.sender == _smartVault
    || msg.sender == address(controller())
      || isGovernance(msg.sender),
      "forbidden");
    _;
  }

  /// @dev This is only used in `investAllUnderlying()`
  ///      The user can still freely withdraw from the strategy
  modifier onlyNotPausedInvesting() {
    require(!pausedInvesting, "paused");
    _;
  }

  /// @dev Write info to bookkeeper. Must be used for doHardwork!
  modifier savePpfsInfo() {
    uint256 ppfs = ISmartVault(_smartVault).getPricePerFullShare();
    _;
    uint256 newPpfs = ISmartVault(_smartVault).getPricePerFullShare();
    if (ppfs != newPpfs) {
      IBookkeeper(IController(controller()).bookkeeper()).registerPpfsChange(_smartVault, newPpfs);
    }
  }

  /// @notice Contract constructor using on Base Strategy implementation
  /// @param _controller Controller address
  /// @param _underlying Underlying token address
  /// @param _vault SmartVault address that will provide liquidity
  /// @param __rewardTokens Reward tokens that the strategy will farm
  /// @param _bbRatio Buy back ratio
  constructor(
    address _controller,
    address _underlying,
    address _vault,
    address[] memory __rewardTokens,
    uint256 _bbRatio
  ) {
    Controllable.initializeControllable(_controller);
    _underlyingToken = _underlying;
    _smartVault = _vault;
    _rewardTokens = __rewardTokens;
    _buyBackRatio = _bbRatio;

    // prohibit the movement of tokens that are used in the main logic
    for (uint256 i = 0; i < _rewardTokens.length; i++) {
      _unsalvageableTokens[_rewardTokens[i]] = true;
    }
    _unsalvageableTokens[_underlying] = true;
  }

  // *************** VIEWS ****************

  /// @notice Reward tokens of external project
  /// @return Reward tokens array
  function rewardTokens() public view override returns (address[] memory) {
    return _rewardTokens;
  }

  /// @notice Strategy underlying, the same in the Vault
  /// @return Strategy underlying token
  function underlying() external view override returns (address) {
    return _underlyingToken;
  }

  /// @notice Underlying balance of this contract
  /// @return Balance of underlying token
  function underlyingBalance() public view override returns (uint256) {
    return IERC20(_underlyingToken).balanceOf(address(this));
  }

  /// @notice SmartVault address linked to this strategy
  /// @return Vault address
  function vault() external view override returns (address) {
    return _smartVault;
  }

  /// @notice Return true for tokens that governance can't touch
  /// @return True if given token unsalvageable
  function unsalvageableTokens(address token) external override view returns (bool) {
    return _unsalvageableTokens[token];
  }

  /// @notice Strategy buy back ratio. Currently stubbed to 100%
  /// @return Buy back ratio
  function buyBackRatio() external view override returns (uint256) {
    return _buyBackRatio;
  }

  /// @notice Balance of given token on this contract
  /// @return Balance of given token
  function rewardBalance(uint256 rewardTokenIdx) public view returns (uint256) {
    return IERC20(_rewardTokens[rewardTokenIdx]).balanceOf(address(this));
  }

  /// @notice Return underlying balance + balance in the reward pool
  /// @return Sum of underlying balances
  function investedUnderlyingBalance() external override view returns (uint256) {
    // Adding the amount locked in the reward pool and the amount that is somehow in this contract
    // both are in the units of "underlying"
    // The second part is needed because there is the emergency exit mechanism
    // which would break the assumption that all the funds are always inside of the reward pool
    return rewardPoolBalance().add(underlyingBalance());
  }

  //******************** GOVERNANCE *******************


  /// @notice In case there are some issues discovered about the pool or underlying asset
  ///         Governance can exit the pool properly
  ///         The function is only used for emergency to exit the pool
  ///         Pause investing
  function emergencyExit() external override onlyControllerOrGovernance {
    emergencyExitRewardPool();
    pausedInvesting = true;
  }


  /// @notice Resumes the ability to invest into the underlying reward pools
  function continueInvesting() external override onlyControllerOrGovernance {
    pausedInvesting = false;
  }

  /// @notice Controller can claim coins that are somehow transferred into the contract
  ///         Note that they cannot come in take away coins that are used and defined in the strategy itself
  /// @param recipient Recipient address
  /// @param recipient Token address
  /// @param recipient Token amount
  function salvage(address recipient, address token, uint256 amount)
  external override onlyController {
    // To make sure that governance cannot come in and take away the coins
    require(!_unsalvageableTokens[token], "not salvageable");
    IERC20(token).safeTransfer(recipient, amount);
  }

  /// @notice Withdraws all the asset to the vault
  function withdrawAllToVault() external override restricted {
    exitRewardPool();
    IERC20(_underlyingToken).safeTransfer(_smartVault, underlyingBalance());
  }

  /// @notice Withdraws some asset to the vault
  /// @param amount Asset amount
  function withdrawToVault(uint256 amount) external override restricted {
    // Typically there wouldn't be any amount here
    // however, it is possible because of the emergencyExit
    if (amount > underlyingBalance()) {
      // While we have the check above, we still using SafeMath below
      // for the peace of mind (in case something gets changed in between)
      uint256 needToWithdraw = amount.sub(underlyingBalance());
      uint256 toWithdraw = Math.min(rewardPoolBalance(), needToWithdraw);
      withdrawAndClaimFromPool(toWithdraw);
    }

    IERC20(_underlyingToken).safeTransfer(_smartVault, Math.min(amount, underlyingBalance()));
  }

  /// @notice Stakes everything the strategy holds into the reward pool
  function investAllUnderlying() public override restricted onlyNotPausedInvesting {
    // this check is needed, because most of the SNX reward pools will revert if
    // you try to stake(0).
    if (underlyingBalance() > 0) {
      depositToPool(underlyingBalance());
    }
  }

  // ***************** INTERNAL ************************

  /// @dev Withdraw everything from external pool
  function exitRewardPool() internal virtual {
    uint256 bal = rewardPoolBalance();
    if (bal != 0) {
      withdrawAndClaimFromPool(bal);
    }
  }

  /// @dev Withdraw everything from external pool without caring about rewards
  function emergencyExitRewardPool() internal {
    uint256 bal = rewardPoolBalance();
    if (bal != 0) {
      emergencyWithdrawFromPool();
    }
  }

  /// @dev Default implementation of liquidation process
  ///      Send all profit to FeeRewardForwarder
  function liquidateRewardDefault() internal {
    _liquidateReward(true);
  }

  function liquidateRewardSilently() internal {
    _liquidateReward(false);
  }

  function _liquidateReward(bool revertOnErrors) internal {
    address forwarder = IController(controller()).feeRewardForwarder();
    for (uint256 i = 0; i < _rewardTokens.length; i++) {
      uint256 amount = rewardBalance(i);
      if (amount != 0) {
        address rt = _rewardTokens[i];
        IERC20(rt).safeApprove(forwarder, 0);
        IERC20(rt).safeApprove(forwarder, amount);
        // it will sell reward token to Target Token and distribute it to SmartVault and PS
        uint256 targetTokenEarned = 0;
        if (revertOnErrors) {
          targetTokenEarned = IFeeRewardForwarder(forwarder).distribute(amount, rt, _smartVault);
        } else {
          //slither-disable-next-line unused-return,variable-scope,uninitialized-local
          try IFeeRewardForwarder(forwarder).distribute(amount, rt, _smartVault) returns (uint r) {
            targetTokenEarned = r;
          } catch {}
        }
        if (targetTokenEarned > 0) {
          IBookkeeper(IController(controller()).bookkeeper()).registerStrategyEarned(targetTokenEarned);
        }
      }
    }
  }

  /// @dev Liquidate rewards and buy underlying asset
  function autocompound() internal {
    address forwarder = IController(controller()).feeRewardForwarder();
    for (uint256 i = 0; i < _rewardTokens.length; i++) {
      uint256 amount = rewardBalance(i);
      if (amount != 0) {
        uint toCompound = amount * (_BUY_BACK_DENOMINATOR - _buyBackRatio) / _BUY_BACK_DENOMINATOR;
        address rt = _rewardTokens[i];
        IERC20(rt).safeApprove(forwarder, 0);
        IERC20(rt).safeApprove(forwarder, toCompound);
        IFeeRewardForwarder(forwarder).liquidate(rt, _underlyingToken, toCompound);
      }
    }
  }

  /// @dev Default implementation of auto-compounding for swap pairs
  ///      Liquidate rewards, buy assets and add to liquidity pool
  function autocompoundLP(address _router) internal {
    address forwarder = IController(controller()).feeRewardForwarder();
    for (uint256 i = 0; i < _rewardTokens.length; i++) {
      uint256 amount = rewardBalance(i);
      if (amount != 0) {
        uint toCompound = amount * (_BUY_BACK_DENOMINATOR - _buyBackRatio) / _BUY_BACK_DENOMINATOR;
        address rt = _rewardTokens[i];
        IERC20(rt).safeApprove(forwarder, 0);
        IERC20(rt).safeApprove(forwarder, toCompound);

        IUniswapV2Pair pair = IUniswapV2Pair(_underlyingToken);
        if (rt != pair.token0()) {
          uint256 token0Amount = IFeeRewardForwarder(forwarder).liquidate(rt, pair.token0(), toCompound / 2);
          require(token0Amount != 0, "SB: Token0 zero amount");
        }
        if (rt != pair.token1()) {
          uint256 token1Amount = IFeeRewardForwarder(forwarder).liquidate(rt, pair.token1(), toCompound / 2);
          require(token1Amount != 0, "SB: Token1 zero amount");
        }
        addLiquidity(_underlyingToken, _router);
      }
    }
  }

  /// @dev Add all available tokens to given pair
  function addLiquidity(address _pair, address _router) internal {
    IUniswapV2Router02 router = IUniswapV2Router02(_router);
    IUniswapV2Pair pair = IUniswapV2Pair(_pair);
    address _token0 = pair.token0();
    address _token1 = pair.token1();

    uint256 amount0 = IERC20(_token0).balanceOf(address(this));
    uint256 amount1 = IERC20(_token1).balanceOf(address(this));

    IERC20(_token0).safeApprove(_router, 0);
    IERC20(_token0).safeApprove(_router, amount0);
    IERC20(_token1).safeApprove(_router, 0);
    IERC20(_token1).safeApprove(_router, amount1);
    //slither-disable-next-line unused-return
    router.addLiquidity(
      _token0,
      _token1,
      amount0,
      amount1,
      1,
      1,
      address(this),
      block.timestamp
    );
  }

  //******************** VIRTUAL *********************
  // This functions should be implemented in the strategy contract

  function rewardPoolBalance() public virtual override view returns (uint256 bal);

  //slither-disable-next-line dead-code
  function depositToPool(uint256 amount) internal virtual;

  //slither-disable-next-line dead-code
  function withdrawAndClaimFromPool(uint256 amount) internal virtual;

  //slither-disable-next-line dead-code
  function emergencyWithdrawFromPool() internal virtual;

  //slither-disable-next-line dead-code
  function liquidateReward() internal virtual;

}

// SPDX-License-Identifier: ISC
/**
* By using this software, you understand, acknowledge and accept that Tetu
* and/or the underlying software are provided “as is” and “as available”
* basis and without warranties or representations of any kind either expressed
* or implied. Any use of this open source software released under the ISC
* Internet Systems Consortium license is done at your own risk to the fullest
* extent permissible pursuant to applicable law any and all liability as well
* as all warranties, including any fitness for a particular purpose with respect
* to Tetu and/or the underlying software and the use thereof are disclaimed.
*/

pragma solidity 0.8.4;

import "./IRewarder.sol";

interface IMiniChefV2 {

  function rewarder(uint256 _pid) external view returns (IRewarder);

  function deposit(uint256 _pid, uint256 _amount, address to) external;

  function withdraw(uint256 _pid, uint256 _amount, address to) external;

  function harvest(uint256 _pid, address to) external;

  function withdrawAndHarvest(uint256 _pid, uint256 _amount, address to) external;

  function emergencyWithdraw(uint256 _pid, address to) external;

  // **************** VIEWS ***************

  function userInfo(uint256 _pid, address _user)
  external view returns (uint256 amount, uint256 rewardDebt);

  function lpToken(uint256 _pid) external view returns (address);

  function poolLength() external view returns (uint256);

  function sushiPerSecond() external view returns (uint256);

  function totalAllocPoint() external view returns (uint256);

  function poolInfo(uint256 _pid)
  external view returns (uint256 accSushiPerShare, uint256 lastRewardTime, uint256 allocPoint);
}

// SPDX-License-Identifier: ISC
/**
* By using this software, you understand, acknowledge and accept that Tetu
* and/or the underlying software are provided “as is” and “as available”
* basis and without warranties or representations of any kind either expressed
* or implied. Any use of this open source software released under the ISC
* Internet Systems Consortium license is done at your own risk to the fullest
* extent permissible pursuant to applicable law any and all liability as well
* as all warranties, including any fitness for a particular purpose with respect
* to Tetu and/or the underlying software and the use thereof are disclaimed.
*/

pragma solidity 0.8.4;

interface IMasterChefStrategyV3 {

  function mcRewardPool() external view returns (address);

  function poolID() external view returns (uint256);

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

// SPDX-License-Identifier: ISC
/**
* By using this software, you understand, acknowledge and accept that Tetu
* and/or the underlying software are provided “as is” and “as available”
* basis and without warranties or representations of any kind either expressed
* or implied. Any use of this open source software released under the ISC
* Internet Systems Consortium license is done at your own risk to the fullest
* extent permissible pursuant to applicable law any and all liability as well
* as all warranties, including any fitness for a particular purpose with respect
* to Tetu and/or the underlying software and the use thereof are disclaimed.
*/

pragma solidity 0.8.4;

interface IStrategy {

  enum Platform {
    UNKNOWN, // 0
    TETU, // 1
    QUICK, // 2
    SUSHI, // 3
    WAULT, // 4
    IRON, // 5
    COSMIC, // 6
    CURVE, // 7
    DINO, // 8
    IRON_LEND, // 9
    HERMES, // 10
    CAFE, // 11
    TETU_SWAP // 12
  }

  // *************** GOVERNANCE ACTIONS **************
  function STRATEGY_NAME() external view returns (string memory);

  function withdrawAllToVault() external;

  function withdrawToVault(uint256 amount) external;

  function salvage(address recipient, address token, uint256 amount) external;

  function doHardWork() external;

  function investAllUnderlying() external;

  function emergencyExit() external;

  function continueInvesting() external;

  // **************** VIEWS ***************
  function rewardTokens() external view returns (address[] memory);

  function underlying() external view returns (address);

  function underlyingBalance() external view returns (uint256);

  function rewardPoolBalance() external view returns (uint256);

  function buyBackRatio() external view returns (uint256);

  function unsalvageableTokens(address token) external view returns (bool);

  function vault() external view returns (address);

  function investedUnderlyingBalance() external view returns (uint256);

  function platform() external view returns (Platform);

  function assets() external view returns (address[] memory);

  function pausedInvesting() external view returns (bool);

  function readyToClaim() external view returns (uint256[] memory);

  function poolTotalAmount() external view returns (uint256);
}

// SPDX-License-Identifier: ISC
/**
* By using this software, you understand, acknowledge and accept that Tetu
* and/or the underlying software are provided “as is” and “as available”
* basis and without warranties or representations of any kind either expressed
* or implied. Any use of this open source software released under the ISC
* Internet Systems Consortium license is done at your own risk to the fullest
* extent permissible pursuant to applicable law any and all liability as well
* as all warranties, including any fitness for a particular purpose with respect
* to Tetu and/or the underlying software and the use thereof are disclaimed.
*/

pragma solidity 0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../interface/IController.sol";
import "../interface/IControllable.sol";

/// @title Implement basic functionality for any contract that require strict control
/// @dev Can be used with upgradeable pattern.
///      Require call initializeControllable() in any case.
/// @author belbix
abstract contract Controllable is Initializable, IControllable {
  bytes32 internal constant _CONTROLLER_SLOT = 0x5165972ef41194f06c5007493031d0b927c20741adcb74403b954009fd2c3617;
  bytes32 internal constant _CREATED_SLOT = 0x6f55f470bdc9cb5f04223fd822021061668e4dccb43e8727b295106dc9769c8a;

  /// @notice Controller address changed
  event UpdateController(address oldValue, address newValue);

  constructor() {
    assert(_CONTROLLER_SLOT == bytes32(uint256(keccak256("eip1967.controllable.controller")) - 1));
    assert(_CREATED_SLOT == bytes32(uint256(keccak256("eip1967.controllable.created")) - 1));
  }

  /// @notice Initialize contract after setup it as proxy implementation
  ///         Save block.timestamp in the "created" variable
  /// @dev Use it only once after first logic setup
  /// @param _controller Controller address
  function initializeControllable(address _controller) public initializer {
    setController(_controller);
    setCreated(block.timestamp);
  }

  function isController(address _adr) public override view returns (bool) {
    return _adr == controller();
  }

  /// @notice Return true is given address is setup as governance in Controller
  /// @param _adr Address for check
  /// @return true if given address is governance
  function isGovernance(address _adr) public override view returns (bool) {
    return IController(controller()).governance() == _adr;
  }

  // ************ MODIFIERS **********************

  /// @dev Allow operation only for Controller
  modifier onlyController() {
    require(controller() == msg.sender, "not controller");
    _;
  }

  /// @dev Allow operation only for Controller or Governance
  modifier onlyControllerOrGovernance() {
    require(isController(msg.sender) || isGovernance(msg.sender), "not controller or gov");
    _;
  }

  /// @dev Only smart contracts will be affected by this modifier
  ///      If it is a contract it should be whitelisted
  modifier onlyAllowedUsers() {
    require(IController(controller()).isAllowedUser(msg.sender), "not allowed");
    _;
  }

  /// @dev Only Reward Distributor allowed. Governance is Reward Distributor by default.
  modifier onlyRewardDistribution() {
    require(IController(controller()).isRewardDistributor(msg.sender), "only distr");
    _;
  }

  // ************* SETTERS/GETTERS *******************

  /// @notice Return controller address saved in the contract slot
  /// @return adr Controller address
  function controller() public view returns (address adr) {
    bytes32 slot = _CONTROLLER_SLOT;
    assembly {
      adr := sload(slot)
    }
  }

  /// @dev Set a controller address to contract slot
  /// @param _newController Controller address
  function setController(address _newController) internal {
    require(_newController != address(0), "zero address");
    emit UpdateController(controller(), _newController);
    bytes32 slot = _CONTROLLER_SLOT;
    assembly {
      sstore(slot, _newController)
    }
  }

  /// @notice Return creation timestamp
  /// @return ts Creation timestamp
  function created() external view returns (uint256 ts) {
    bytes32 slot = _CREATED_SLOT;
    assembly {
      ts := sload(slot)
    }
  }

  /// @dev Filled only once when contract initialized
  /// @param _created block.timestamp
  function setCreated(uint256 _created) private {
    bytes32 slot = _CREATED_SLOT;
    assembly {
      sstore(slot, _created)
    }
  }

}

// SPDX-License-Identifier: ISC
/**
* By using this software, you understand, acknowledge and accept that Tetu
* and/or the underlying software are provided “as is” and “as available”
* basis and without warranties or representations of any kind either expressed
* or implied. Any use of this open source software released under the ISC
* Internet Systems Consortium license is done at your own risk to the fullest
* extent permissible pursuant to applicable law any and all liability as well
* as all warranties, including any fitness for a particular purpose with respect
* to Tetu and/or the underlying software and the use thereof are disclaimed.
*/

pragma solidity 0.8.4;

interface IFeeRewardForwarder {
  function distribute(uint256 _amount, address _token, address _vault) external returns (uint256);

  function notifyPsPool(address _token, uint256 _amount) external returns (uint256);

  function notifyCustomPool(address _token, address _rewardPool, uint256 _maxBuyback) external returns (uint256);

  function liquidate(address tokenIn, address tokenOut, uint256 amount) external returns (uint256);
}

// SPDX-License-Identifier: ISC
/**
* By using this software, you understand, acknowledge and accept that Tetu
* and/or the underlying software are provided “as is” and “as available”
* basis and without warranties or representations of any kind either expressed
* or implied. Any use of this open source software released under the ISC
* Internet Systems Consortium license is done at your own risk to the fullest
* extent permissible pursuant to applicable law any and all liability as well
* as all warranties, including any fitness for a particular purpose with respect
* to Tetu and/or the underlying software and the use thereof are disclaimed.
*/

pragma solidity 0.8.4;

interface IBookkeeper {

  struct PpfsChange {
    address vault;
    uint256 block;
    uint256 time;
    uint256 value;
    uint256 oldBlock;
    uint256 oldTime;
    uint256 oldValue;
  }

  struct HardWork {
    address strategy;
    uint256 block;
    uint256 time;
    uint256 targetTokenAmount;
  }

  function addVault(address _vault) external;

  function addStrategy(address _strategy) external;

  function registerStrategyEarned(uint256 _targetTokenAmount) external;

  function registerFundKeeperEarned(address _token, uint256 _fundTokenAmount) external;

  function registerUserAction(address _user, uint256 _amount, bool _deposit) external;

  function registerVaultTransfer(address from, address to, uint256 amount) external;

  function registerUserEarned(address _user, address _vault, address _rt, uint256 _amount) external;

  function registerPpfsChange(address vault, uint256 value) external;

  function registerRewardDistribution(address vault, address token, uint256 amount) external;

  function vaults() external view returns (address[] memory);

  function vaultsLength() external view returns (uint256);

  function strategies() external view returns (address[] memory);

  function strategiesLength() external view returns (uint256);

  function lastPpfsChange(address vault) external view returns (PpfsChange memory);

  /// @notice Return total earned TETU tokens for strategy
  /// @dev Should be incremented after strategy rewards distribution
  /// @param vault Strategy address
  /// @return Earned TETU tokens
  function targetTokenEarned(address vault) external view returns (uint256);

  /// @notice Return share(xToken) balance of given user
  /// @dev Should be calculated for each xToken transfer
  /// @param vault Vault address
  /// @param user User address
  /// @return User share (xToken) balance
  function vaultUsersBalances(address vault, address user) external view returns (uint256);

  /// @notice Return earned token amount for given token and user
  /// @dev Fills when user claim rewards
  /// @param user User address
  /// @param vault Vault address
  /// @param token Token address
  /// @return User's earned tokens amount
  function userEarned(address user, address vault, address token) external view returns (uint256);

  function lastHardWork(address vault) external view returns (HardWork memory);

  /// @notice Return users quantity for given Vault
  /// @dev Calculation based in Bookkeeper user balances
  /// @param vault Vault address
  /// @return Users quantity
  function vaultUsersQuantity(address vault) external view returns (uint256);

  function fundKeeperEarned(address vault) external view returns (uint256);

  function vaultRewards(address vault, address token, uint256 idx) external view returns (uint256);

  function vaultRewardsLength(address vault, address token) external view returns (uint256);

  function strategyEarnedSnapshots(address strategy, uint256 idx) external view returns (uint256);

  function strategyEarnedSnapshotsTime(address strategy, uint256 idx) external view returns (uint256);

  function strategyEarnedSnapshotsLength(address strategy) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.4;

interface IUniswapV2Router02 {
  function factory() external view returns (address);

  function WETH() external view returns (address);

  function addLiquidity(
    address tokenA,
    address tokenB,
    uint amountADesired,
    uint amountBDesired,
    uint amountAMin,
    uint amountBMin,
    address to,
    uint deadline
  ) external returns (uint amountA, uint amountB, uint liquidity);

  function addLiquidityETH(
    address token,
    uint amountTokenDesired,
    uint amountTokenMin,
    uint amountETHMin,
    address to,
    uint deadline
  ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

  function removeLiquidity(
    address tokenA,
    address tokenB,
    uint liquidity,
    uint amountAMin,
    uint amountBMin,
    address to,
    uint deadline
  ) external returns (uint amountA, uint amountB);

  function removeLiquidityETH(
    address token,
    uint liquidity,
    uint amountTokenMin,
    uint amountETHMin,
    address to,
    uint deadline
  ) external returns (uint amountToken, uint amountETH);

  function removeLiquidityWithPermit(
    address tokenA,
    address tokenB,
    uint liquidity,
    uint amountAMin,
    uint amountBMin,
    address to,
    uint deadline,
    bool approveMax, uint8 v, bytes32 r, bytes32 s
  ) external returns (uint amountA, uint amountB);

  function removeLiquidityETHWithPermit(
    address token,
    uint liquidity,
    uint amountTokenMin,
    uint amountETHMin,
    address to,
    uint deadline,
    bool approveMax, uint8 v, bytes32 r, bytes32 s
  ) external returns (uint amountToken, uint amountETH);

  function swapExactTokensForTokens(
    uint amountIn,
    uint amountOutMin,
    address[] calldata path,
    address to,
    uint deadline
  ) external returns (uint[] memory amounts);

  function swapTokensForExactTokens(
    uint amountOut,
    uint amountInMax,
    address[] calldata path,
    address to,
    uint deadline
  ) external returns (uint[] memory amounts);

  function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
  external
  payable
  returns (uint[] memory amounts);

  function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
  external
  returns (uint[] memory amounts);

  function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
  external
  returns (uint[] memory amounts);

  function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
  external
  payable
  returns (uint[] memory amounts);

  function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);

  function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);

  function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);

  function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);

  function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);

  function removeLiquidityETHSupportingFeeOnTransferTokens(
    address token,
    uint liquidity,
    uint amountTokenMin,
    uint amountETHMin,
    address to,
    uint deadline
  ) external returns (uint amountETH);

  function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
    address token,
    uint liquidity,
    uint amountTokenMin,
    uint amountETHMin,
    address to,
    uint deadline,
    bool approveMax, uint8 v, bytes32 r, bytes32 s
  ) external returns (uint amountETH);

  function swapExactTokensForTokensSupportingFeeOnTransferTokens(
    uint amountIn,
    uint amountOutMin,
    address[] calldata path,
    address to,
    uint deadline
  ) external;

  function swapExactETHForTokensSupportingFeeOnTransferTokens(
    uint amountOutMin,
    address[] calldata path,
    address to,
    uint deadline
  ) external payable;

  function swapExactTokensForETHSupportingFeeOnTransferTokens(
    uint amountIn,
    uint amountOutMin,
    address[] calldata path,
    address to,
    uint deadline
  ) external;
}

// SPDX-License-Identifier: ISC
/**
* By using this software, you understand, acknowledge and accept that Tetu
* and/or the underlying software are provided “as is” and “as available”
* basis and without warranties or representations of any kind either expressed
* or implied. Any use of this open source software released under the ISC
* Internet Systems Consortium license is done at your own risk to the fullest
* extent permissible pursuant to applicable law any and all liability as well
* as all warranties, including any fitness for a particular purpose with respect
* to Tetu and/or the underlying software and the use thereof are disclaimed.
*/

pragma solidity 0.8.4;

interface ISmartVault {

  function setStrategy(address _strategy) external;

  function changeActivityStatus(bool _active) external;

  function changePpfsDecreaseAllowed(bool _value) external;

  function setLockPeriod(uint256 _value) external;

  function setLockPenalty(uint256 _value) external;

  function setToInvest(uint256 _value) external;

  function doHardWork() external;

  function rebalance() external;

  function disableLock() external;

  function notifyTargetRewardAmount(address _rewardToken, uint256 reward) external;

  function notifyRewardWithoutPeriodChange(address _rewardToken, uint256 reward) external;

  function deposit(uint256 amount) external;

  function depositAndInvest(uint256 amount) external;

  function depositFor(uint256 amount, address holder) external;

  function withdraw(uint256 numberOfShares) external;

  function exit() external;

  function getAllRewards() external;

  function getReward(address rt) external;

  function underlying() external view returns (address);

  function strategy() external view returns (address);

  function getRewardTokenIndex(address rt) external view returns (uint256);

  function getPricePerFullShare() external view returns (uint256);

  function underlyingUnit() external view returns (uint256);

  function duration() external view returns (uint256);

  function underlyingBalanceInVault() external view returns (uint256);

  function underlyingBalanceWithInvestment() external view returns (uint256);

  function underlyingBalanceWithInvestmentForHolder(address holder) external view returns (uint256);

  function availableToInvestOut() external view returns (uint256);

  function earned(address rt, address account) external view returns (uint256);

  function earnedWithBoost(address rt, address account) external view returns (uint256);

  function rewardPerToken(address rt) external view returns (uint256);

  function lastTimeRewardApplicable(address rt) external view returns (uint256);

  function rewardTokensLength() external view returns (uint256);

  function active() external view returns (bool);

  function rewardTokens() external view returns (address[] memory);

  function periodFinishForToken(address _rt) external view returns (uint256);

  function rewardRateForToken(address _rt) external view returns (uint256);

  function lastUpdateTimeForToken(address _rt) external view returns (uint256);

  function rewardPerTokenStoredForToken(address _rt) external view returns (uint256);

  function userRewardPerTokenPaidForToken(address _rt, address account) external view returns (uint256);

  function rewardsForToken(address _rt, address account) external view returns (uint256);

  function userLastWithdrawTs(address _user) external returns (uint256);

  function userLastDepositTs(address _user) external returns (uint256);

  function userBoostTs(address _user) external returns (uint256);

  function userLockTs(address _user) external returns (uint256);

  function addRewardToken(address rt) external;

  function removeRewardToken(address rt) external;

  function stop() external;

  function ppfsDecreaseAllowed() external view returns (bool);

  function lockPeriod() external view returns (uint256);

  function lockPenalty() external view returns (uint256);

  function toInvest() external view returns (uint256);

  function lockAllowed() external view returns (bool);
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

// SPDX-License-Identifier: ISC
/**
* By using this software, you understand, acknowledge and accept that Tetu
* and/or the underlying software are provided “as is” and “as available”
* basis and without warranties or representations of any kind either expressed
* or implied. Any use of this open source software released under the ISC
* Internet Systems Consortium license is done at your own risk to the fullest
* extent permissible pursuant to applicable law any and all liability as well
* as all warranties, including any fitness for a particular purpose with respect
* to Tetu and/or the underlying software and the use thereof are disclaimed.
*/

pragma solidity 0.8.4;

interface IController {

  function addVaultAndStrategy(address _vault, address _strategy) external;

  function addStrategy(address _strategy) external;

  function governance() external view returns (address);

  function dao() external view returns (address);

  function bookkeeper() external view returns (address);

  function feeRewardForwarder() external view returns (address);

  function mintHelper() external view returns (address);

  function rewardToken() external view returns (address);

  function fundToken() external view returns (address);

  function psVault() external view returns (address);

  function fund() external view returns (address);

  function announcer() external view returns (address);

  function vaultController() external view returns (address);

  function whiteList(address _target) external view returns (bool);

  function vaults(address _target) external view returns (bool);

  function strategies(address _target) external view returns (bool);

  function psNumerator() external view returns (uint256);

  function psDenominator() external view returns (uint256);

  function fundNumerator() external view returns (uint256);

  function fundDenominator() external view returns (uint256);

  function isAllowedUser(address _adr) external view returns (bool);

  function isDao(address _adr) external view returns (bool);

  function isHardWorker(address _adr) external view returns (bool);

  function isRewardDistributor(address _adr) external view returns (bool);

  function isPoorRewardConsumer(address _adr) external view returns (bool);

  function isValidVault(address _vault) external view returns (bool);

  function isValidStrategy(address _strategy) external view returns (bool);

  // ************ DAO ACTIONS *************
  function setPSNumeratorDenominator(uint256 numerator, uint256 denominator) external;

  function setFundNumeratorDenominator(uint256 numerator, uint256 denominator) external;

  function addToWhiteListMulti(address[] calldata _targets) external;

  function addToWhiteList(address _target) external;

  function removeFromWhiteListMulti(address[] calldata _targets) external;

  function removeFromWhiteList(address _target) external;
}

// SPDX-License-Identifier: ISC
/**
* By using this software, you understand, acknowledge and accept that Tetu
* and/or the underlying software are provided “as is” and “as available”
* basis and without warranties or representations of any kind either expressed
* or implied. Any use of this open source software released under the ISC
* Internet Systems Consortium license is done at your own risk to the fullest
* extent permissible pursuant to applicable law any and all liability as well
* as all warranties, including any fitness for a particular purpose with respect
* to Tetu and/or the underlying software and the use thereof are disclaimed.
*/

pragma solidity 0.8.4;

interface IControllable {

  function isController(address _contract) external view returns (bool);

  function isGovernance(address _contract) external view returns (bool);
}

// SPDX-License-Identifier: ISC
/**
* By using this software, you understand, acknowledge and accept that Tetu
* and/or the underlying software are provided “as is” and “as available”
* basis and without warranties or representations of any kind either expressed
* or implied. Any use of this open source software released under the ISC
* Internet Systems Consortium license is done at your own risk to the fullest
* extent permissible pursuant to applicable law any and all liability as well
* as all warranties, including any fitness for a particular purpose with respect
* to Tetu and/or the underlying software and the use thereof are disclaimed.
*/

pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IRewarder {
  function onSushiReward(uint256 pid, address user, address recipient, uint256 sushiAmount, uint256 newLpAmount) external;

  function pendingTokens(uint256 pid, address user, uint256 sushiAmount) external view returns (IERC20[] memory, uint256[] memory);

  function pendingToken(uint256 _pid, address _user) external view returns (uint256 pending);

  function rewardPerSecond() external view returns (uint256);

  function userInfo(uint256 _pid, address _user)
  external view returns (uint256 amount, uint256 rewardDebt);

  function poolInfo(uint256 _pid)
  external view returns (uint256 accSushiPerShare, uint256 lastRewardBlock, uint256 allocPoint);
}