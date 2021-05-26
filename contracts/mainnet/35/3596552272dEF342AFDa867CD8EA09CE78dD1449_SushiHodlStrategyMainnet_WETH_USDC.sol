pragma solidity 0.5.16;

import "../../base/sushi-base/MasterChefHodlStrategy.sol";

contract SushiHodlStrategyMainnet_WETH_USDC is MasterChefHodlStrategy {

  address public weth_usdc_unused; // just a differentiator for the bytecode

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0x397FF1542f962076d0BFE58eA045FfA2d347ACa0);
    address sushi = address(0x6B3595068778DD592e39A122f4f5a5cF09C90fE2);
    MasterChefHodlStrategy.initializeMasterChefHodlStrategy(
      _storage,
      underlying,
      _vault,
      address(0xc2EdaD668740f1aA35E4D8f227fB8E17dcA888Cd), // master chef contract
      sushi,
      1,  // Pool id
      address(0x274AA8B58E8C57C4e347C8768ed853Eb6D375b48), // Sushi hodlVault fsushi
      address(0x0000000000000000000000000000000000000000) // manually set it later
    );
  }
}

pragma solidity 0.5.16;

import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Detailed.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "../interface/uniswap/IUniswapV2Router02.sol";
import "../interface/IStrategy.sol";
import "../interface/IVault.sol";
import "../upgradability/BaseUpgradeableStrategy.sol";
import "./interfaces/IMasterChef.sol";
import "../interface/uniswap/IUniswapV2Pair.sol";
import "../PotPool.sol";

contract MasterChefHodlStrategy is IStrategy, BaseUpgradeableStrategy {

  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  address public constant uniswapRouterV2 = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
  address public constant sushiswapRouterV2 = address(0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F);

  // additional storage slots (on top of BaseUpgradeableStrategy ones) are defined here
  bytes32 internal constant _POOLID_SLOT = 0x3fd729bfa2e28b7806b03a6e014729f59477b530f995be4d51defc9dad94810b;
  bytes32 internal constant _HODLVAULT_SLOT = 0xc26d330f887c749cb38ae7c37873ff08ac4bba7aec9113c82d48a0cf6cc145f2;
  bytes32 internal constant _POTPOOL_SLOT = 0x7f4b50847e7d7a4da6a6ea36bfb188c77e9f093697337eb9a876744f926dd014;
  bytes32 internal constant _FEERATIO_SLOT = 0xdd068d8a32502e81a10cdf5394059be07ccd47fe6df7741b57a2f9937efedeaf;
  bytes32 internal constant _FEEHOLDER_SLOT = 0x00679b6f1cace16785324a171df0e550ee9f20b64671a53b5c491a3065b30f2b;

  uint256 public constant feeBase = 10000;

  constructor() public BaseUpgradeableStrategy() {
    assert(_POOLID_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.poolId")) - 1));
    assert(_HODLVAULT_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.hodlVault")) - 1));
    assert(_POTPOOL_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.potPool")) - 1));
    assert(_FEERATIO_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.feeRatio")) - 1));
    assert(_FEEHOLDER_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.feeHolder")) - 1));
  }


  function initializeMasterChefHodlStrategy(
    address _storage,
    address _underlying,
    address _vault,
    address _rewardPool,
    address _rewardToken,
    uint256 _poolId,
    address _hodlVault,
    address _potPool
  ) public initializer {
    require(_rewardPool != address(0), "reward pool is empty");

    BaseUpgradeableStrategy.initialize(
      _storage,
      _underlying,
      _vault,
      _rewardPool,
      _rewardToken,
      300, // profit sharing numerator
      1000, // profit sharing denominator
      true, // sell
      1e18, // sell floor
      12 hours // implementation change delay
    );

    address _lpt;
    (_lpt,,,) = IMasterChef(rewardPool()).poolInfo(_poolId);
    require(_lpt == underlying(), "Pool Info does not match underlying");
    _setPoolId(_poolId);
    setAddress(_HODLVAULT_SLOT, _hodlVault);
    setAddress(_POTPOOL_SLOT, _potPool);
  }

  function depositArbCheck() public view returns(bool) {
    return true;
  }

  function rewardPoolBalance() internal view returns (uint256 bal) {
      (bal,) = IMasterChef(rewardPool()).userInfo(poolId(), address(this));
  }

  function exitRewardPool() internal {
      uint256 bal = rewardPoolBalance();
      if (bal != 0) {
          IMasterChef(rewardPool()).withdraw(poolId(), bal);
      }
  }

  function emergencyExitRewardPool() internal {
      uint256 bal = rewardPoolBalance();
      if (bal != 0) {
          IMasterChef(rewardPool()).emergencyWithdraw(poolId());
      }
  }

  function unsalvagableTokens(address token) public view returns (bool) {
    return (token == rewardToken() || token == underlying());
  }

  function enterRewardPool() internal {
    uint256 entireBalance = IERC20(underlying()).balanceOf(address(this));
    IERC20(underlying()).safeApprove(rewardPool(), 0);
    IERC20(underlying()).safeApprove(rewardPool(), entireBalance);
    IMasterChef(rewardPool()).deposit(poolId(), entireBalance);
  }

  /*
  *   In case there are some issues discovered about the pool or underlying asset
  *   Governance can exit the pool properly
  *   The function is only used for emergency to exit the pool
  */
  function emergencyExit() public onlyGovernance {
    emergencyExitRewardPool();
    _setPausedInvesting(true);
  }

  /*
  *   Resumes the ability to invest into the underlying reward pools
  */

  function continueInvesting() public onlyGovernance {
    _setPausedInvesting(false);
  }

  // We Hodl all the rewards
  function _hodlAndNotify() internal {
    uint256 rewardBalance = IERC20(rewardToken()).balanceOf(address(this));
    if(rewardBalance > 0) {
      uint256 fee = 0;
      uint256 remainingReward = rewardBalance;
      if(feeHolder() != address(0)){
        fee = rewardBalance.mul(feeRatio()).div(feeBase);
        remainingReward = rewardBalance.sub(fee);
        if(fee > 0){
          IERC20(rewardToken()).safeTransfer(feeHolder(), fee);
        }
      }

      IERC20(rewardToken()).safeApprove(hodlVault(), 0);
      IERC20(rewardToken()).safeApprove(hodlVault(), remainingReward);
      IVault(hodlVault()).deposit(remainingReward);
      uint256 fRewardBalance = IERC20(hodlVault()).balanceOf(address(this));
      IERC20(hodlVault()).safeTransfer(potPool(), fRewardBalance);
      PotPool(potPool()).notifyTargetRewardAmount(hodlVault(), fRewardBalance);
    }
  }

  /*
  *   Stakes everything the strategy holds into the reward pool
  */
  function investAllUnderlying() internal onlyNotPausedInvesting {
    // this check is needed, because most of the SNX reward pools will revert if
    // you try to stake(0).
    if(IERC20(underlying()).balanceOf(address(this)) > 0) {
      enterRewardPool();
    }
  }

  /*
  *   Withdraws all the asset to the vault
  */
  function withdrawAllToVault() public restricted {
    exitRewardPool();
    _hodlAndNotify();
    IERC20(underlying()).safeTransfer(vault(), IERC20(underlying()).balanceOf(address(this)));
  }

  /*
  *   Withdraws all the asset to the vault
  */
  function withdrawToVault(uint256 amount) public restricted {
    // Typically there wouldn't be any amount here
    // however, it is possible because of the emergencyExit
    uint256 entireBalance = IERC20(underlying()).balanceOf(address(this));

    if(amount > entireBalance){
      // While we have the check above, we still using SafeMath below
      // for the peace of mind (in case something gets changed in between)
      uint256 needToWithdraw = amount.sub(entireBalance);
      uint256 toWithdraw = Math.min(rewardPoolBalance(), needToWithdraw);
      IMasterChef(rewardPool()).withdraw(poolId(), toWithdraw);
    }

    IERC20(underlying()).safeTransfer(vault(), amount);
  }

  /*
  *   Note that we currently do not have a mechanism here to include the
  *   amount of reward that is accrued.
  */
  function investedUnderlyingBalance() external view returns (uint256) {
    if (rewardPool() == address(0)) {
      return IERC20(underlying()).balanceOf(address(this));
    }
    // Adding the amount locked in the reward pool and the amount that is somehow in this contract
    // both are in the units of "underlying"
    // The second part is needed because there is the emergency exit mechanism
    // which would break the assumption that all the funds are always inside of the reward pool
    return rewardPoolBalance().add(IERC20(underlying()).balanceOf(address(this)));
  }

  /*
  *   Governance or Controller can claim coins that are somehow transferred into the contract
  *   Note that they cannot come in take away coins that are used and defined in the strategy itself
  */
  function salvage(address recipient, address token, uint256 amount) external onlyControllerOrGovernance {
     // To make sure that governance cannot come in and take away the coins
    require(!unsalvagableTokens(token), "token is defined as not salvagable");
    IERC20(token).safeTransfer(recipient, amount);
  }

  /*
  *   Get the reward, sell it in exchange for underlying, invest what you got.
  *   It's not much, but it's honest work.
  *
  *   Note that although `onlyNotPausedInvesting` is not added here,
  *   calling `investAllUnderlying()` affectively blocks the usage of `doHardWork`
  *   when the investing is being paused by governance.
  */
  function doHardWork() external onlyNotPausedInvesting restricted {
    exitRewardPool();
    _hodlAndNotify();
    investAllUnderlying();
  }

  function setHodlVault(address _value) public onlyGovernance {
    require(hodlVault() == address(0), "Hodl vault already set");
    setAddress(_HODLVAULT_SLOT, _value);
  }

  function hodlVault() public view returns (address) {
    return getAddress(_HODLVAULT_SLOT);
  }

  function setPotPool(address _value) public onlyGovernance {
    require(potPool() == address(0), "PotPool already set");
    setAddress(_POTPOOL_SLOT, _value);
  }

  function setFeeRatio(uint256 _value) public onlyGovernance {
    require(_value <= feeBase.mul(3).div(10), "Cannot be more then 30%");
    setUint256(_FEERATIO_SLOT, _value);
  }

  function setFeeHolder(address _value) public onlyGovernance {
    setAddress(_FEEHOLDER_SLOT, _value);
  }

  function potPool() public view returns (address) {
    return getAddress(_POTPOOL_SLOT);
  }

  function feeRatio() public view returns (uint256) {
    return getUint256(_FEERATIO_SLOT);
  }

  function feeHolder() public view returns (address) {
    return getAddress(_FEEHOLDER_SLOT);
  }

  function finalizeUpgrade() external onlyGovernance {
    setFeeRatio(1500);
    _finalizeUpgrade();
  }

  // masterchef rewards pool ID
  function _setPoolId(uint256 _value) internal {
    setUint256(_POOLID_SLOT, _value);
  }

  function poolId() public view returns (uint256) {
    return getUint256(_POOLID_SLOT);
  }
}

pragma solidity ^0.5.0;

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

pragma solidity ^0.5.0;

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
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

pragma solidity ^0.5.0;

import "./IERC20.sol";

/**
 * @dev Optional functions from the ERC20 standard.
 */
contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for `name`, `symbol`, and `decimals`. All three of
     * these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }
}

pragma solidity ^0.5.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

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

pragma solidity 0.5.16;

interface IStrategy {
    
    function unsalvagableTokens(address tokens) external view returns (bool);
    
    function governance() external view returns (address);
    function controller() external view returns (address);
    function underlying() external view returns (address);
    function vault() external view returns (address);

    function withdrawAllToVault() external;
    function withdrawToVault(uint256 amount) external;

    function investedUnderlyingBalance() external view returns (uint256); // itsNotMuch()

    // should only be called by controller
    function salvage(address recipient, address token, uint256 amount) external;

    function doHardWork() external;
    function depositArbCheck() external view returns(bool);
}

pragma solidity 0.5.16;

interface IVault {

    function initializeVault(
      address _storage,
      address _underlying,
      uint256 _toInvestNumerator,
      uint256 _toInvestDenominator
    ) external ;

    function balanceOf(address) external view returns (uint256);

    function underlyingBalanceInVault() external view returns (uint256);
    function underlyingBalanceWithInvestment() external view returns (uint256);

    // function store() external view returns (address);
    function governance() external view returns (address);
    function controller() external view returns (address);
    function underlying() external view returns (address);
    function strategy() external view returns (address);

    function setStrategy(address _strategy) external;
    function announceStrategyUpdate(address _strategy) external;
    function setVaultFractionToInvest(uint256 numerator, uint256 denominator) external;

    function deposit(uint256 amountWei) external;
    function depositFor(uint256 amountWei, address holder) external;

    function withdrawAll() external;
    function withdraw(uint256 numberOfShares) external;
    function getPricePerFullShare() external view returns (uint256);

    function underlyingBalanceWithInvestmentForHolder(address holder) view external returns (uint256);

    // hard work should be callable only by the controller (by the hard worker) or by governance
    function doHardWork() external;
}

pragma solidity 0.5.16;

import "@openzeppelin/upgrades/contracts/Initializable.sol";
import "./BaseUpgradeableStrategyStorage.sol";
import "../inheritance/ControllableInit.sol";
import "../interface/IController.sol";
import "../interface/IFeeRewardForwarderV6.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

contract BaseUpgradeableStrategy is Initializable, ControllableInit, BaseUpgradeableStrategyStorage {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  event ProfitsNotCollected(bool sell, bool floor);
  event ProfitLogInReward(uint256 profitAmount, uint256 feeAmount, uint256 timestamp);
  event ProfitAndBuybackLog(uint256 profitAmount, uint256 feeAmount, uint256 timestamp);

  modifier restricted() {
    require(msg.sender == vault() || msg.sender == controller()
      || msg.sender == governance(),
      "The sender has to be the controller, governance, or vault");
    _;
  }

  // This is only used in `investAllUnderlying()`
  // The user can still freely withdraw from the strategy
  modifier onlyNotPausedInvesting() {
    require(!pausedInvesting(), "Action blocked as the strategy is in emergency state");
    _;
  }

  constructor() public BaseUpgradeableStrategyStorage() {
  }

  function initialize(
    address _storage,
    address _underlying,
    address _vault,
    address _rewardPool,
    address _rewardToken,
    uint256 _profitSharingNumerator,
    uint256 _profitSharingDenominator,
    bool _sell,
    uint256 _sellFloor,
    uint256 _implementationChangeDelay
  ) public initializer {
    ControllableInit.initialize(
      _storage
    );
    _setUnderlying(_underlying);
    _setVault(_vault);
    _setRewardPool(_rewardPool);
    _setRewardToken(_rewardToken);
    _setProfitSharingNumerator(_profitSharingNumerator);
    _setProfitSharingDenominator(_profitSharingDenominator);

    _setSell(_sell);
    _setSellFloor(_sellFloor);
    _setNextImplementationDelay(_implementationChangeDelay);
    _setPausedInvesting(false);
  }

  /**
  * Schedules an upgrade for this vault's proxy.
  */
  function scheduleUpgrade(address impl) public onlyGovernance {
    _setNextImplementation(impl);
    _setNextImplementationTimestamp(block.timestamp.add(nextImplementationDelay()));
  }

  function _finalizeUpgrade() internal {
    _setNextImplementation(address(0));
    _setNextImplementationTimestamp(0);
  }

  function shouldUpgrade() external view returns (bool, address) {
    return (
      nextImplementationTimestamp() != 0
        && block.timestamp > nextImplementationTimestamp()
        && nextImplementation() != address(0),
      nextImplementation()
    );
  }

  // reward notification

  function notifyProfitInRewardToken(uint256 _rewardBalance) internal {
    if( _rewardBalance > 0 ){
      uint256 feeAmount = _rewardBalance.mul(profitSharingNumerator()).div(profitSharingDenominator());
      emit ProfitLogInReward(_rewardBalance, feeAmount, block.timestamp);
      IERC20(rewardToken()).safeApprove(controller(), 0);
      IERC20(rewardToken()).safeApprove(controller(), feeAmount);

      IController(controller()).notifyFee(
        rewardToken(),
        feeAmount
      );
    } else {
      emit ProfitLogInReward(0, 0, block.timestamp);
    }
  }

  function notifyProfitAndBuybackInRewardToken(uint256 _rewardBalance, address pool, uint256 _buybackRatio) internal {
    if( _rewardBalance > 0 ){
      uint256 feeAmount = _rewardBalance.mul(profitSharingNumerator()).div(profitSharingDenominator());
      uint256 buybackAmount = _rewardBalance.sub(feeAmount).mul(_buybackRatio).div(10000);

      address forwarder = IController(controller()).feeRewardForwarder();
      emit ProfitAndBuybackLog(_rewardBalance, feeAmount, block.timestamp);

      IERC20(rewardToken()).safeApprove(forwarder, 0);
      IERC20(rewardToken()).safeApprove(forwarder, _rewardBalance);

      IFeeRewardForwarderV6(forwarder).notifyFeeAndBuybackAmounts(
        rewardToken(),
        feeAmount,
        pool,
        buybackAmount
      );
    } else {
      emit ProfitAndBuybackLog(0, 0, block.timestamp);
    }
  }
}

pragma solidity 0.5.16;

interface IMasterChef {
    function deposit(uint256 _pid, uint256 _amount) external;
    function withdraw(uint256 _pid, uint256 _amount) external;
    function emergencyWithdraw(uint256 _pid) external;
    function userInfo(uint256 _pid, address _user) external view returns (uint256 amount, uint256 rewardDebt);
    function poolInfo(uint256 _pid) external view returns (address lpToken, uint256, uint256, uint256);
    function massUpdatePools() external;
}

// SPDX-License-Identifier: MIT
/**
 *Submitted for verification at Etherscan.io on 2020-05-05
*/

// File: contracts/interfaces/IUniswapV2Pair.sol

pragma solidity >=0.5.0;

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
pragma solidity 0.5.16;

import "./inheritance/Controllable.sol";
import "./interface/IController.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Detailed.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/GSN/Context.sol";
import "@openzeppelin/contracts/ownership/Ownable.sol";

contract IRewardDistributionRecipient is Ownable {

    mapping (address => bool) public rewardDistribution;

    constructor(address[] memory _rewardDistributions) public {
        // NotifyHelper
        rewardDistribution[0xE20c31e3d08027F5AfACe84A3A46B7b3B165053c] = true;

        // FeeRewardForwarderV5
        rewardDistribution[0x153C544f72329c1ba521DDf5086cf2fA98C86676] = true;

        for(uint256 i = 0; i < _rewardDistributions.length; i++) {
          rewardDistribution[_rewardDistributions[i]] = true;
        }
    }

    function notifyTargetRewardAmount(address rewardToken, uint256 reward) external;
    function notifyRewardAmount(uint256 reward) external;

    modifier onlyRewardDistribution() {
        require(rewardDistribution[_msgSender()], "Caller is not reward distribution");
        _;
    }

    function setRewardDistribution(address[] calldata _newRewardDistribution, bool _flag)
        external
        onlyOwner
    {
        for(uint256 i = 0; i < _newRewardDistribution.length; i++){
          rewardDistribution[_newRewardDistribution[i]] = _flag;
        }
    }
}

contract PotPool is IRewardDistributionRecipient, Controllable, ERC20, ERC20Detailed {

    using Address for address;
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    address public lpToken;
    uint256 public duration; // making it not a constant is less gas efficient, but portable

    mapping(address => uint256) public stakedBalanceOf;

    mapping (address => bool) smartContractStakers;
    address[] public rewardTokens;
    mapping(address => uint256) public periodFinishForToken;
    mapping(address => uint256) public rewardRateForToken;
    mapping(address => uint256) public lastUpdateTimeForToken;
    mapping(address => uint256) public rewardPerTokenStoredForToken;
    mapping(address => mapping(address => uint256)) public userRewardPerTokenPaidForToken;
    mapping(address => mapping(address => uint256)) public rewardsForToken;

    event RewardAdded(address rewardToken, uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, address rewardToken, uint256 reward);
    event RewardDenied(address indexed user, address rewardToken, uint256 reward);
    event SmartContractRecorded(address indexed smartContractAddress, address indexed smartContractInitiator);

    modifier updateRewards(address account) {
      for(uint256 i = 0; i < rewardTokens.length; i++ ){
        address rt = rewardTokens[i];
        rewardPerTokenStoredForToken[rt] = rewardPerToken(rt);
        lastUpdateTimeForToken[rt] = lastTimeRewardApplicable(rt);
        if (account != address(0)) {
            rewardsForToken[rt][account] = earned(rt, account);
            userRewardPerTokenPaidForToken[rt][account] = rewardPerTokenStoredForToken[rt];
        }
      }
      _;
    }

    modifier updateReward(address account, address rt){
      rewardPerTokenStoredForToken[rt] = rewardPerToken(rt);
      lastUpdateTimeForToken[rt] = lastTimeRewardApplicable(rt);
      if (account != address(0)) {
          rewardsForToken[rt][account] = earned(rt, account);
          userRewardPerTokenPaidForToken[rt][account] = rewardPerTokenStoredForToken[rt];
      }
      _;
    }

    /** View functions to respect old interface */
    function rewardToken() public view returns(address) {
      return rewardTokens[0];
    }

    function rewardPerToken() public view returns(uint256) {
      return rewardPerToken(rewardTokens[0]);
    }

    function periodFinish() public view returns(uint256) {
      return periodFinishForToken[rewardTokens[0]];
    }

    function rewardRate() public view returns(uint256) {
      return rewardRateForToken[rewardTokens[0]];
    }

    function lastUpdateTime() public view returns(uint256) {
      return lastUpdateTimeForToken[rewardTokens[0]];
    }

    function rewardPerTokenStored() public view returns(uint256) {
      return rewardPerTokenStoredForToken[rewardTokens[0]];
    }

    function userRewardPerTokenPaid(address user) public view returns(uint256) {
      return userRewardPerTokenPaidForToken[rewardTokens[0]][user];
    }

    function rewards(address user) public view returns(uint256) {
      return rewardsForToken[rewardTokens[0]][user];
    }

    // [Hardwork] setting the reward, lpToken, duration, and rewardDistribution for each pool
    constructor(
        address[] memory _rewardTokens,
        address _lpToken,
        uint256 _duration,
        address[] memory _rewardDistribution,
        address _storage,
        string memory _name,
        string memory _symbol,
        uint8 _decimals
      ) public
      ERC20Detailed(_name, _symbol, _decimals)
      IRewardDistributionRecipient(_rewardDistribution)
      Controllable(_storage) // only used for referencing the grey list
    {
        require(_decimals == ERC20Detailed(_lpToken).decimals(), "decimals has to be aligned with the lpToken");
        require(_rewardTokens.length != 0, "should initialize with at least 1 rewardToken");
        rewardTokens = _rewardTokens;
        lpToken = _lpToken;
        duration = _duration;
    }

    function lastTimeRewardApplicable(uint256 i) public view returns (uint256) {
        return lastTimeRewardApplicable(rewardTokens[i]);
    }

    function lastTimeRewardApplicable(address rt) public view returns (uint256) {
        return Math.min(block.timestamp, periodFinishForToken[rt]);
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return lastTimeRewardApplicable(rewardTokens[0]);
    }

    function rewardPerToken(uint256 i) public view returns (uint256) {
        return rewardPerToken(rewardTokens[i]);
    }

    function rewardPerToken(address rt) public view returns (uint256) {
        if (totalSupply() == 0) {
            return rewardPerTokenStoredForToken[rt];
        }
        return
            rewardPerTokenStoredForToken[rt].add(
                lastTimeRewardApplicable(rt)
                    .sub(lastUpdateTimeForToken[rt])
                    .mul(rewardRateForToken[rt])
                    .mul(1e18)
                    .div(totalSupply())
            );
    }

    function earned(uint256 i, address account) public view returns (uint256) {
        return earned(rewardTokens[i], account);
    }

    function earned(address account) public view returns (uint256) {
        return earned(rewardTokens[0], account);
    }

    function earned(address rt, address account) public view returns (uint256) {
        return
            stakedBalanceOf[account]
                .mul(rewardPerToken(rt).sub(userRewardPerTokenPaidForToken[rt][account]))
                .div(1e18)
                .add(rewardsForToken[rt][account]);
    }

    function stake(uint256 amount) public updateRewards(msg.sender) {
        require(amount > 0, "Cannot stake 0");
        recordSmartContract();
        super._mint(msg.sender, amount); // ERC20 is used as a staking receipt
        stakedBalanceOf[msg.sender] = stakedBalanceOf[msg.sender].add(amount);
        IERC20(lpToken).safeTransferFrom(msg.sender, address(this), amount);
        emit Staked(msg.sender, amount);
    }

    function withdraw(uint256 amount) public updateRewards(msg.sender) {
        require(amount > 0, "Cannot withdraw 0");
        super._burn(msg.sender, amount);
        stakedBalanceOf[msg.sender] = stakedBalanceOf[msg.sender].sub(amount);
        IERC20(lpToken).safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount);
    }

    function exit() external {
        withdraw(Math.min(stakedBalanceOf[msg.sender], balanceOf(msg.sender)));
        getAllRewards();
    }

    /// A push mechanism for accounts that have not claimed their rewards for a long time.
    /// The implementation is semantically analogous to getReward(), but uses a push pattern
    /// instead of pull pattern.
    function pushAllRewards(address recipient) public updateRewards(recipient) onlyGovernance {
      bool rewardPayout = (!smartContractStakers[recipient] || !IController(controller()).greyList(recipient));
      for(uint256 i = 0 ; i < rewardTokens.length; i++ ){
        uint256 reward = earned(rewardTokens[i], recipient);
        if (reward > 0) {
            rewardsForToken[rewardTokens[i]][recipient] = 0;
            // If it is a normal user and not smart contract,
            // then the requirement will pass
            // If it is a smart contract, then
            // make sure that it is not on our greyList.
            if (rewardPayout) {
                IERC20(rewardTokens[i]).safeTransfer(recipient, reward);
                emit RewardPaid(recipient, rewardTokens[i], reward);
            } else {
                emit RewardDenied(recipient, rewardTokens[i], reward);
            }
        }
      }
    }

    function getAllRewards() public updateRewards(msg.sender) {
      recordSmartContract();
      bool rewardPayout = (!smartContractStakers[msg.sender] || !IController(controller()).greyList(msg.sender));
      for(uint256 i = 0 ; i < rewardTokens.length; i++ ){
        _getRewardAction(rewardTokens[i], rewardPayout);
      }
    }

    function getReward(address rt) public updateReward(msg.sender, rt) {
      recordSmartContract();
      _getRewardAction(
        rt,
        // don't payout if it is a grey listed smart contract
        (!smartContractStakers[msg.sender] || !IController(controller()).greyList(msg.sender))
      );
    }

    function getReward() public {
      getReward(rewardTokens[0]);
    }

    function _getRewardAction(address rt, bool rewardPayout) internal {
      uint256 reward = earned(rt, msg.sender);
      if (reward > 0 && IERC20(rt).balanceOf(address(this)) >= reward ) {
          rewardsForToken[rt][msg.sender] = 0;
          // If it is a normal user and not smart contract,
          // then the requirement will pass
          // If it is a smart contract, then
          // make sure that it is not on our greyList.
          if (rewardPayout) {
              IERC20(rt).safeTransfer(msg.sender, reward);
              emit RewardPaid(msg.sender, rt, reward);
          } else {
              emit RewardDenied(msg.sender, rt, reward);
          }
      }
    }

    function addRewardToken(address rt) public onlyGovernance {
      require(getRewardTokenIndex(rt) == uint256(-1), "Reward token already exists");
      rewardTokens.push(rt);
    }

    function removeRewardToken(address rt) public onlyGovernance {
      uint256 i = getRewardTokenIndex(rt);
      require(i != uint256(-1), "Reward token does not exists");
      require(periodFinishForToken[rewardTokens[i]] < block.timestamp, "Can only remove when the reward period has passed");
      require(rewardTokens.length > 1, "Cannot remove the last reward token");
      uint256 lastIndex = rewardTokens.length - 1;

      // swap
      rewardTokens[i] = rewardTokens[lastIndex];

      // delete last element
      rewardTokens.length--;
    }

    // If the return value is MAX_UINT256, it means that
    // the specified reward token is not in the list
    function getRewardTokenIndex(address rt) public view returns(uint256) {
      for(uint i = 0 ; i < rewardTokens.length ; i++){
        if(rewardTokens[i] == rt)
          return i;
      }
      return uint256(-1);
    }

    function notifyTargetRewardAmount(address _rewardToken, uint256 reward)
        public
        onlyRewardDistribution
        updateRewards(address(0))
    {
        // overflow fix according to https://sips.synthetix.io/sips/sip-77
        require(reward < uint(-1) / 1e18, "the notified reward cannot invoke multiplication overflow");

        uint256 i = getRewardTokenIndex(_rewardToken);
        require(i != uint256(-1), "rewardTokenIndex not found");

        if (block.timestamp >= periodFinishForToken[_rewardToken]) {
            rewardRateForToken[_rewardToken] = reward.div(duration);
        } else {
            uint256 remaining = periodFinishForToken[_rewardToken].sub(block.timestamp);
            uint256 leftover = remaining.mul(rewardRateForToken[_rewardToken]);
            rewardRateForToken[_rewardToken] = reward.add(leftover).div(duration);
        }
        lastUpdateTimeForToken[_rewardToken] = block.timestamp;
        periodFinishForToken[_rewardToken] = block.timestamp.add(duration);
        emit RewardAdded(_rewardToken, reward);
    }

    function notifyRewardAmount(uint256 reward)
        external
        onlyRewardDistribution
        updateRewards(address(0))
    {
      notifyTargetRewardAmount(rewardTokens[0], reward);
    }

    function rewardTokensLength() public view returns(uint256){
      return rewardTokens.length;
    }

    // Harvest Smart Contract recording
    function recordSmartContract() internal {
      if( tx.origin != msg.sender ) {
        smartContractStakers[msg.sender] = true;
        emit SmartContractRecorded(msg.sender, tx.origin);
      }
    }

}

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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

pragma solidity ^0.5.5;

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
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * _Available since v2.4.0._
     */
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
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
     *
     * _Available since v2.4.0._
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

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
}

pragma solidity >=0.4.24 <0.7.0;


/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {

  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private initializing;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

  /// @dev Returns true if and only if the function is running in the constructor
  function isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    address self = address(this);
    uint256 cs;
    assembly { cs := extcodesize(self) }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}

pragma solidity 0.5.16;

import "@openzeppelin/upgrades/contracts/Initializable.sol";

contract BaseUpgradeableStrategyStorage {

  bytes32 internal constant _UNDERLYING_SLOT = 0xa1709211eeccf8f4ad5b6700d52a1a9525b5f5ae1e9e5f9e5a0c2fc23c86e530;
  bytes32 internal constant _VAULT_SLOT = 0xefd7c7d9ef1040fc87e7ad11fe15f86e1d11e1df03c6d7c87f7e1f4041f08d41;

  bytes32 internal constant _REWARD_TOKEN_SLOT = 0xdae0aafd977983cb1e78d8f638900ff361dc3c48c43118ca1dd77d1af3f47bbf;
  bytes32 internal constant _REWARD_POOL_SLOT = 0x3d9bb16e77837e25cada0cf894835418b38e8e18fbec6cfd192eb344bebfa6b8;
  bytes32 internal constant _SELL_FLOOR_SLOT = 0xc403216a7704d160f6a3b5c3b149a1226a6080f0a5dd27b27d9ba9c022fa0afc;
  bytes32 internal constant _SELL_SLOT = 0x656de32df98753b07482576beb0d00a6b949ebf84c066c765f54f26725221bb6;
  bytes32 internal constant _PAUSED_INVESTING_SLOT = 0xa07a20a2d463a602c2b891eb35f244624d9068572811f63d0e094072fb54591a;

  bytes32 internal constant _PROFIT_SHARING_NUMERATOR_SLOT = 0xe3ee74fb7893020b457d8071ed1ef76ace2bf4903abd7b24d3ce312e9c72c029;
  bytes32 internal constant _PROFIT_SHARING_DENOMINATOR_SLOT = 0x0286fd414602b432a8c80a0125e9a25de9bba96da9d5068c832ff73f09208a3b;

  bytes32 internal constant _NEXT_IMPLEMENTATION_SLOT = 0x29f7fcd4fe2517c1963807a1ec27b0e45e67c60a874d5eeac7a0b1ab1bb84447;
  bytes32 internal constant _NEXT_IMPLEMENTATION_TIMESTAMP_SLOT = 0x414c5263b05428f1be1bfa98e25407cc78dd031d0d3cd2a2e3d63b488804f22e;
  bytes32 internal constant _NEXT_IMPLEMENTATION_DELAY_SLOT = 0x82b330ca72bcd6db11a26f10ce47ebcfe574a9c646bccbc6f1cd4478eae16b31;

  bytes32 internal constant _REWARD_CLAIMABLE_SLOT = 0xbc7c0d42a71b75c3129b337a259c346200f901408f273707402da4b51db3b8e7;
  bytes32 internal constant _MULTISIG_SLOT = 0x3e9de78b54c338efbc04e3a091b87dc7efb5d7024738302c548fc59fba1c34e6;

  constructor() public {
    assert(_UNDERLYING_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.underlying")) - 1));
    assert(_VAULT_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.vault")) - 1));
    assert(_REWARD_TOKEN_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.rewardToken")) - 1));
    assert(_REWARD_POOL_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.rewardPool")) - 1));
    assert(_SELL_FLOOR_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.sellFloor")) - 1));
    assert(_SELL_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.sell")) - 1));
    assert(_PAUSED_INVESTING_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.pausedInvesting")) - 1));

    assert(_PROFIT_SHARING_NUMERATOR_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.profitSharingNumerator")) - 1));
    assert(_PROFIT_SHARING_DENOMINATOR_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.profitSharingDenominator")) - 1));

    assert(_NEXT_IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.nextImplementation")) - 1));
    assert(_NEXT_IMPLEMENTATION_TIMESTAMP_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.nextImplementationTimestamp")) - 1));
    assert(_NEXT_IMPLEMENTATION_DELAY_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.nextImplementationDelay")) - 1));

    assert(_REWARD_CLAIMABLE_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.rewardClaimable")) - 1));
    assert(_MULTISIG_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.multiSig")) - 1));
  }

  function _setUnderlying(address _address) internal {
    setAddress(_UNDERLYING_SLOT, _address);
  }

  function underlying() public view returns (address) {
    return getAddress(_UNDERLYING_SLOT);
  }

  function _setRewardPool(address _address) internal {
    setAddress(_REWARD_POOL_SLOT, _address);
  }

  function rewardPool() public view returns (address) {
    return getAddress(_REWARD_POOL_SLOT);
  }

  function _setRewardToken(address _address) internal {
    setAddress(_REWARD_TOKEN_SLOT, _address);
  }

  function rewardToken() public view returns (address) {
    return getAddress(_REWARD_TOKEN_SLOT);
  }

  function _setVault(address _address) internal {
    setAddress(_VAULT_SLOT, _address);
  }

  function vault() public view returns (address) {
    return getAddress(_VAULT_SLOT);
  }

  // a flag for disabling selling for simplified emergency exit
  function _setSell(bool _value) internal {
    setBoolean(_SELL_SLOT, _value);
  }

  function sell() public view returns (bool) {
    return getBoolean(_SELL_SLOT);
  }

  function _setPausedInvesting(bool _value) internal {
    setBoolean(_PAUSED_INVESTING_SLOT, _value);
  }

  function pausedInvesting() public view returns (bool) {
    return getBoolean(_PAUSED_INVESTING_SLOT);
  }

  function _setSellFloor(uint256 _value) internal {
    setUint256(_SELL_FLOOR_SLOT, _value);
  }

  function sellFloor() public view returns (uint256) {
    return getUint256(_SELL_FLOOR_SLOT);
  }

  function _setProfitSharingNumerator(uint256 _value) internal {
    setUint256(_PROFIT_SHARING_NUMERATOR_SLOT, _value);
  }

  function profitSharingNumerator() public view returns (uint256) {
    return getUint256(_PROFIT_SHARING_NUMERATOR_SLOT);
  }

  function _setProfitSharingDenominator(uint256 _value) internal {
    setUint256(_PROFIT_SHARING_DENOMINATOR_SLOT, _value);
  }

  function profitSharingDenominator() public view returns (uint256) {
    return getUint256(_PROFIT_SHARING_DENOMINATOR_SLOT);
  }

  function allowedRewardClaimable() public view returns (bool) {
    return getBoolean(_REWARD_CLAIMABLE_SLOT);
  }

  function _setRewardClaimable(bool _value) internal {
    setBoolean(_REWARD_CLAIMABLE_SLOT, _value);
  }

  function multiSig() public view returns(address) {
    return getAddress(_MULTISIG_SLOT);
  }

  function _setMultiSig(address _address) internal {
    setAddress(_MULTISIG_SLOT, _address);
  }

  // upgradeability

  function _setNextImplementation(address _address) internal {
    setAddress(_NEXT_IMPLEMENTATION_SLOT, _address);
  }

  function nextImplementation() public view returns (address) {
    return getAddress(_NEXT_IMPLEMENTATION_SLOT);
  }

  function _setNextImplementationTimestamp(uint256 _value) internal {
    setUint256(_NEXT_IMPLEMENTATION_TIMESTAMP_SLOT, _value);
  }

  function nextImplementationTimestamp() public view returns (uint256) {
    return getUint256(_NEXT_IMPLEMENTATION_TIMESTAMP_SLOT);
  }

  function _setNextImplementationDelay(uint256 _value) internal {
    setUint256(_NEXT_IMPLEMENTATION_DELAY_SLOT, _value);
  }

  function nextImplementationDelay() public view returns (uint256) {
    return getUint256(_NEXT_IMPLEMENTATION_DELAY_SLOT);
  }

  function setBoolean(bytes32 slot, bool _value) internal {
    setUint256(slot, _value ? 1 : 0);
  }

  function getBoolean(bytes32 slot) internal view returns (bool) {
    return (getUint256(slot) == 1);
  }

  function setAddress(bytes32 slot, address _address) internal {
    // solhint-disable-next-line no-inline-assembly
    assembly {
      sstore(slot, _address)
    }
  }

  function setUint256(bytes32 slot, uint256 _value) internal {
    // solhint-disable-next-line no-inline-assembly
    assembly {
      sstore(slot, _value)
    }
  }

  function getAddress(bytes32 slot) internal view returns (address str) {
    // solhint-disable-next-line no-inline-assembly
    assembly {
      str := sload(slot)
    }
  }

  function getUint256(bytes32 slot) internal view returns (uint256 str) {
    // solhint-disable-next-line no-inline-assembly
    assembly {
      str := sload(slot)
    }
  }
}

pragma solidity 0.5.16;

import "./GovernableInit.sol";

// A clone of Governable supporting the Initializable interface and pattern
contract ControllableInit is GovernableInit {

  constructor() public {
  }

  function initialize(address _storage) public initializer {
    GovernableInit.initialize(_storage);
  }

  modifier onlyController() {
    require(Storage(_storage()).isController(msg.sender), "Not a controller");
    _;
  }

  modifier onlyControllerOrGovernance(){
    require((Storage(_storage()).isController(msg.sender) || Storage(_storage()).isGovernance(msg.sender)),
      "The caller must be controller or governance");
    _;
  }

  function controller() public view returns (address) {
    return Storage(_storage()).controller();
  }
}

pragma solidity 0.5.16;

interface IController {

    event SharePriceChangeLog(
      address indexed vault,
      address indexed strategy,
      uint256 oldSharePrice,
      uint256 newSharePrice,
      uint256 timestamp
    );

    // [Grey list]
    // An EOA can safely interact with the system no matter what.
    // If you're using Metamask, you're using an EOA.
    // Only smart contracts may be affected by this grey list.
    //
    // This contract will not be able to ban any EOA from the system
    // even if an EOA is being added to the greyList, he/she will still be able
    // to interact with the whole system as if nothing happened.
    // Only smart contracts will be affected by being added to the greyList.
    // This grey list is only used in Vault.sol, see the code there for reference
    function greyList(address _target) external view returns(bool);

    function addVaultAndStrategy(address _vault, address _strategy) external;
    function doHardWork(address _vault) external;
    function hasVault(address _vault) external returns(bool);

    function salvage(address _token, uint256 amount) external;
    function salvageStrategy(address _strategy, address _token, uint256 amount) external;

    function notifyFee(address _underlying, uint256 fee) external;
    function profitSharingNumerator() external view returns (uint256);
    function profitSharingDenominator() external view returns (uint256);

    function feeRewardForwarder() external view returns(address);
    function setFeeRewardForwarder(address _value) external;

    function addHardWorker(address _worker) external;
}

pragma solidity 0.5.16;

interface IFeeRewardForwarderV6 {
    function poolNotifyFixedTarget(address _token, uint256 _amount) external;

    function notifyFeeAndBuybackAmounts(uint256 _feeAmount, address _pool, uint256 _buybackAmount) external;
    function notifyFeeAndBuybackAmounts(address _token, uint256 _feeAmount, address _pool, uint256 _buybackAmount) external;
    function profitSharingPool() external view returns (address);
    function configureLiquidation(address[] calldata _path, bytes32[] calldata _dexes) external;
}

pragma solidity 0.5.16;

import "@openzeppelin/upgrades/contracts/Initializable.sol";
import "./Storage.sol";

// A clone of Governable supporting the Initializable interface and pattern
contract GovernableInit is Initializable {

  bytes32 internal constant _STORAGE_SLOT = 0xa7ec62784904ff31cbcc32d09932a58e7f1e4476e1d041995b37c917990b16dc;

  modifier onlyGovernance() {
    require(Storage(_storage()).isGovernance(msg.sender), "Not governance");
    _;
  }

  constructor() public {
    assert(_STORAGE_SLOT == bytes32(uint256(keccak256("eip1967.governableInit.storage")) - 1));
  }

  function initialize(address _store) public initializer {
    _setStorage(_store);
  }

  function _setStorage(address newStorage) private {
    bytes32 slot = _STORAGE_SLOT;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      sstore(slot, newStorage)
    }
  }

  function setStorage(address _store) public onlyGovernance {
    require(_store != address(0), "new storage shouldn't be empty");
    _setStorage(_store);
  }

  function _storage() internal view returns (address str) {
    bytes32 slot = _STORAGE_SLOT;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      str := sload(slot)
    }
  }

  function governance() public view returns (address) {
    return Storage(_storage()).governance();
  }
}

pragma solidity 0.5.16;

contract Storage {

  address public governance;
  address public controller;

  constructor() public {
    governance = msg.sender;
  }

  modifier onlyGovernance() {
    require(isGovernance(msg.sender), "Not governance");
    _;
  }

  function setGovernance(address _governance) public onlyGovernance {
    require(_governance != address(0), "new governance shouldn't be empty");
    governance = _governance;
  }

  function setController(address _controller) public onlyGovernance {
    require(_controller != address(0), "new controller shouldn't be empty");
    controller = _controller;
  }

  function isGovernance(address account) public view returns (bool) {
    return account == governance;
  }

  function isController(address account) public view returns (bool) {
    return account == controller;
  }
}

pragma solidity 0.5.16;

import "./Governable.sol";

contract Controllable is Governable {

  constructor(address _storage) Governable(_storage) public {
  }

  modifier onlyController() {
    require(store.isController(msg.sender), "Not a controller");
    _;
  }

  modifier onlyControllerOrGovernance(){
    require((store.isController(msg.sender) || store.isGovernance(msg.sender)),
      "The caller must be controller or governance");
    _;
  }

  function controller() public view returns (address) {
    return store.controller();
  }
}

pragma solidity ^0.5.0;

import "../../GSN/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20Mintable}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
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
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view returns (uint256) {
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
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
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
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
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
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
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
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See {_burn} and {_approve}.
     */
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "ERC20: burn amount exceeds allowance"));
    }
}

pragma solidity ^0.5.0;

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
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

pragma solidity ^0.5.0;

import "../GSN/Context.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
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
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

pragma solidity 0.5.16;

import "./Storage.sol";

contract Governable {

  Storage public store;

  constructor(address _store) public {
    require(_store != address(0), "new storage shouldn't be empty");
    store = Storage(_store);
  }

  modifier onlyGovernance() {
    require(store.isGovernance(msg.sender), "Not governance");
    _;
  }

  function setStorage(address _store) public onlyGovernance {
    require(_store != address(0), "new storage shouldn't be empty");
    store = Storage(_store);
  }

  function governance() public view returns (address) {
    return store.governance();
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
  "metadata": {
    "useLiteralContent": true
  },
  "libraries": {}
}