// SPDX-License-Identifier: MIT
pragma solidity >=0.7.2;
pragma experimental ABIEncoderV2;

import { SafeMath } from '@openzeppelin/contracts/math/SafeMath.sol';
import { IERC20 } from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import { SafeERC20 } from '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';

import { IAction } from '../interfaces/IAction.sol';
import { IController } from '../interfaces/IController.sol';
import { IOracle } from '../interfaces/IOracle.sol';
import { IOToken } from '../interfaces/IOToken.sol';
import { IWETH } from '../interfaces/IWETH.sol'; 
import { SwapTypes } from '../libraries/SwapTypes.sol';
import { AirswapBase } from '../utils/AirswapBase.sol';
import { RollOverBase } from '../utils/RollOverBase.sol';
/**
 * Error Codes
 * S1: msg.sender must be the vault
 * S2: cannot currently close the vault position
 * S3: seller for the order (_order.sender.wallet) must be this contract
 * S4: token to sell (_order.sender.token) must be the currently activated oToken
 * S5: token to sell for (_order.signer.token) must be the underlying
 * S6: tokens being sold (_order.sender.amount) and tokens being minted (_otokenAmount) must be the same
 * S7: amount of underlying being sold for (_order.signer.amount) does not meet the minimum option premium
 * S8: strike price for the next oToken is too low
 * S9: expiry timestamp for the next oToken is invalid
 */

/**
 * @title ShortOTokenActionWithSwap
 * @author Opyn Team
 */

contract ShortOTokenActionWithSwap is IAction, AirswapBase, RollOverBase {
  using SafeERC20 for IERC20;
  using SafeMath for uint256;

  address public immutable vault;

   /// @dev 100%
  uint256 constant public BASE = 10000;
  /// @dev the minimum strike price of the option chosen needs to be at least 105% of spot. 
  /// This is set expecting the contract to be a strategy selling calls. For puts should change this. 
  uint256 constant public MIN_STRIKE = 10500;
  uint256 public MIN_PROFITS; // 100 being 1%
  uint256 public lockedAsset;
  uint256 public rolloverTime;

  IController public controller;
  IOracle public oracle;
  IERC20 underlying;

  event MintAndSellOToken(uint256 collateralAmount, uint256 otokenAmount, uint256 premium);

  constructor(
    address _vault,
    address _swap,
    address _opynWhitelist,
    address _controller,
    uint256 _vaultType,
    address _underlying,
    uint256 _min_profits
  ) {
    MIN_PROFITS = _min_profits;
    vault = _vault;
    underlying = IERC20(_underlying);

    controller = IController(_controller);

    oracle = IOracle(controller.oracle());

    // enable vault to take all the underlying back and re-distribute.
    underlying.safeApprove(_vault, uint256(-1));

    // enable pool contract to pull underlying from this contract to mint options.
    underlying.safeApprove(controller.pool(), uint256(-1));

    _initSwapContract(_swap);
    _initRollOverBase(_opynWhitelist);

    _openVault(_vaultType);
  }

  function onlyVault() private view {
    require(msg.sender == vault, "S1");
  }

  /**
   * @dev return the net worth of this strategy, in terms of underlying.
   * if the action has an opened gamma vault, see if there's any short position
   */
  function currentValue() external view override returns (uint256) {
    return underlying.balanceOf(address(this)).add(lockedAsset);
    
    // todo: caclulate cash value to avoid not early withdraw to avoid loss.
  }

  /**
   * @dev return the amount of locked asset in the action.
   */
  function currentLockedAsset() external view override returns (uint256) {
    return lockedAsset;
  }

  /**
   * @dev the function that the vault will call when the round is over
   */
  function closePosition() external override {
    onlyVault();
    require(canClosePosition(), 'S2');
    
    if(_canSettleVault()) {
      _settleVault();
    }

    // this function can only be called when it's `Activated`
    // go to the next step, which will enable owner to commit next oToken
    _setActionIdle();

    lockedAsset = 0;
  }

  /**
   * @dev the function that the vault will call when the new round is starting
   */
  function rolloverPosition() external override {
    onlyVault();
    
    // this function can only be called when it's `Committed`
    _rollOverNextOTokenAndActivate();
    rolloverTime = block.timestamp;
  }

  /**
   * @dev owner only function to mint options with underlying and sell otokens in this contract 
   * by filling an order on AirSwap.
   * this can only be done in "activated" state. which is achievable by calling `rolloverPosition`
   */
  function mintAndSellOToken(uint256 _collateralAmount, uint256 _otokenAmount, SwapTypes.Order memory _order) external onlyOwner {
    onlyActivated();
    require(_order.sender.wallet == address(this), 'S3');
    require(_order.sender.token == otoken, 'S4');
    require(_order.signer.token == address(underlying), 'S5');
    require(_order.sender.amount == _otokenAmount, 'S6');

    // mint options & lock asset
    _mintOTokens(_collateralAmount, _otokenAmount);
    lockedAsset = lockedAsset.add(_collateralAmount);

    // underlying before minting
    uint256 underlyingBalanceBefore = underlying.balanceOf(address(this));

    // sell options on airswap for underlying
    IERC20(otoken).safeIncreaseAllowance(address(airswap), _order.sender.amount);
    _fillAirswapOrder(_order);

    // check that minimum premium is received & that it is higher than min threshold
    uint256 underlyingBalanceAfter = underlying.balanceOf(address(this));
    uint256 underlyingTokenEarned = underlyingBalanceAfter.sub(underlyingBalanceBefore);
    require(_collateralAmount.mul(MIN_PROFITS).div(BASE) <= underlyingTokenEarned, 'S7');

    emit MintAndSellOToken(_collateralAmount, _otokenAmount, underlyingTokenEarned);
  }

  /**
   * @notice the function will return when someone can close a position. 1 day after rollover, 
   * if the option wasn't sold, anyone can close the position. 
   */
  function canClosePosition() public view returns(bool) {
    if (otoken != address(0) && lockedAsset != 0) { 
      return _canSettleVault();
    }

    return block.timestamp > rolloverTime + 1 days; 
  }

  /**
   * @dev open vault with vaultId 1. this should only be performed once when contract is initiated
   */
  function _openVault(uint256 _vaultType) internal {
    bytes memory data;

    if (_vaultType != 0) {
      data = abi.encode(_vaultType);
    }

    // this action will always use vault id 0
    IController.ActionArgs[] memory actions = new IController.ActionArgs[](1);

    actions[0] = IController.ActionArgs(
        IController.ActionType.OpenVault,
        address(this), // owner
        address(0), // doesn't matter 
        address(0), // doesn't matter
        1, // vaultId
        0, // amount
        0, // index
        data // data
    );

    controller.operate(actions);
  }

  /**
   * @dev mint otoken in vault 1
   */
  function _mintOTokens(uint256 _collateralAmount, uint256 _otokenAmount) internal {
    // this action will always use vault id 1
    IController.ActionArgs[] memory actions = new IController.ActionArgs[](2);
    
    actions[0] = IController.ActionArgs(
        IController.ActionType.DepositCollateral,
        address(this), // vault owner is this address
        address(this), // deposit from this address
        address(underlying), // collateral is the underlying
        1, // vaultId is 1
        _collateralAmount, // amount of underlying to deposit
        0, // index
        "" // data
    );

    actions[1] = IController.ActionArgs(
        IController.ActionType.MintShortOption,
        address(this), // vault owner is this address
        address(this), // mint to this address
        otoken, // otoken to mint
        1, // vaultId is 1
        _otokenAmount, // amount of otokens to mint
        0, // index
        "" // data
    );
    
    controller.operate(actions);
  }

  /**
   * @dev settle vault 1 and withdraw all locked collateral
   */
  function _settleVault() internal {
    IController.ActionArgs[] memory actions = new IController.ActionArgs[](1);
    // this action will always use vault id 1
    actions[0] = IController.ActionArgs(
        IController.ActionType.SettleVault,
        address(this), // owner is this address
        address(this), // recipient is this address
        address(0), // doesn't mtter
        1, // vaultId is 1 
        0, // amount doesn't matter
        0, // index
        "" // data
    );

    controller.operate(actions);
  }

  /**
   * @dev checks if the current vault can be settled
   */
  function _canSettleVault() internal view returns (bool) {
    if (lockedAsset != 0 && otoken != address(0)) {
      return controller.isSettlementAllowed(otoken);
    }

    return false; 
  }
  
  /**
   * @dev funtion to add some custom logic to check the next otoken is valid to this strategy
   * this hook is triggered while action owner calls "commitNextOption"
   * so accessing otoken will give u the current otoken. 
   */
  function _customOTokenCheck(address _nextOToken) internal override view {
    // Can override or replace this.
     require(_isValidStrike(IOToken(_nextOToken).strikePrice()), 'S8');
     require (_isValidExpiry(IOToken(_nextOToken).expiryTimestamp()), 'S9');
    /**
     * e.g.
     * check otoken strike price is lower than current spot price for put.
     * check it's no more than x day til the current otoken expires. (can't commit too early)
     * check there's no previously committed otoken.
     * check otoken expiry is expected
     */
  }

  /**
   * @dev funtion to check that the otoken being sold meets a minimum valid strike price
   * this hook is triggered in the _customOtokenCheck function. 
   */
  function _isValidStrike(uint256 strikePrice) internal view returns (bool) { 
    uint256 spotPrice = oracle.getPrice(address(underlying));
    // checks that the strike price set is > than 105% of current price
    return strikePrice >= spotPrice.mul(MIN_STRIKE).div(BASE);
  }

  /**
   * @dev funtion to check that the otoken being sold meets certain expiry conditions
   * this hook is triggered in the _customOtokenCheck function. 
   */
  function _isValidExpiry(uint256 expiry) internal view returns (bool) {
    // TODO: override with your filler code. 
    // Checks that the token committed to expires within 15 days of commitment. 
    return (block.timestamp).add(15 days) >= expiry;
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
pragma solidity >=0.7.2;

interface IAction {

  /**
   * The function used to determin how much asset the current action is controlling.
   * this will impact the withdraw and deposit amount calculated from the vault.
   */
  function currentValue() external view returns (uint256);

  /**
   * The function for the vault to call at the end of each vault's round.
   * after calling this function, the vault will try to pull assets back from the action and enable withdraw.
   */
  function closePosition() external;

  /**
   * The function for the vault to call when the vault is ready to start the next round.
   * the vault will push assets to action before calling this function, but the amount can change compare to 
   * the last round. So each action should check their asset balance instead of using any cached balance.
   *
   * Each action can also add additional checks and revert the `rolloverPosition` call if the action 
   * is not ready to go into the next round.
   */
  function rolloverPosition() external;

  /**
   * The function used to determine how much asset is locked in the current action.
   * this will impact the closeposition  amount calculated from the vault.
   */
  function currentLockedAsset() external view returns (uint256);

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.2;
pragma experimental ABIEncoderV2;

interface IController {
  enum ActionType {
    OpenVault,
    MintShortOption,
    BurnShortOption,
    DepositLongOption,
    WithdrawLongOption,
    DepositCollateral,
    WithdrawCollateral,
    SettleVault,
    Redeem,
    Call
  }

  struct ActionArgs {
    ActionType actionType;
    address owner;
    address secondAddress;
    address asset;
    uint256 vaultId;
    uint256 amount;
    uint256 index;
    bytes data;
  }

  struct Vault {
    address[] shortOtokens;
    address[] longOtokens;
    address[] collateralAssets;
    uint256[] shortAmounts;
    uint256[] longAmounts;
    uint256[] collateralAmounts;
  }

  function pool() external view returns (address);

  function getPayout(address _otoken, uint256 _amount) external view returns (uint256);

  function operate(ActionArgs[] calldata _actions) external;

  function getAccountVaultCounter(address owner) external view returns (uint256);

  function oracle() external view returns (address);

  function getVault(address _owner, uint256 _vaultId) external view returns (Vault memory);

  function getProceed(address _owner, uint256 _vaultId) external view returns (uint256);

  function isSettlementAllowed(
    address otoken
  ) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.2;

interface IOracle {
    function isDisputePeriodOver(address _asset, uint256 _expiryTimestamp) external view returns (bool);
    function getExpiryPrice(address _asset, uint256 _expiryTimestamp) external view returns (uint256, bool);
    function setAssetPricer(address _asset, address _pricer) external;
    function setExpiryPrice(
        address _asset,
        uint256 _expiryTimestamp,
        uint256 _price
    ) external;
    function getPrice(address _asset) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.2;

interface IOToken {
    function underlyingAsset() external view returns (address);

    function strikeAsset() external view returns (address);

    function collateralAsset() external view returns (address);

    function strikePrice() external view returns (uint256);

    function expiryTimestamp() external view returns (uint256);

    function isPut() external view returns (bool);
    
    function balanceOf(address account) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.2;

interface IWETH {
    function deposit() external payable;

    function withdraw(uint256) external;

    function balanceOf(address account) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transfer(address recipient, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: Apache
/*
  Copyright 2020 Swap Holdings Ltd.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.7.2;
pragma experimental ABIEncoderV2;

/**
 * @title Types: Library of Swap Protocol Types and Hashes
 */
library SwapTypes {
    struct Order {
        uint256 nonce; // Unique per order and should be sequential
        uint256 expiry; // Expiry in seconds since 1 January 1970
        Party signer; // Party to the trade that sets terms
        Party sender; // Party to the trade that accepts terms
        Party affiliate; // Party compensated for facilitating (optional)
        Signature signature; // Signature of the order
    }

    struct Party {
        bytes4 kind; // Interface ID of the token
        address wallet; // Wallet address of the party
        address token; // Contract address of the token
        uint256 amount; // Amount for ERC-20 or ERC-1155
        uint256 id; // ID for ERC-721 or ERC-1155
    }

    struct Signature {
        address signatory; // Address of the wallet used to sign
        address validator; // Address of the intended swap contract
        bytes1 version; // EIP-191 signature version
        uint8 v; // `v` value of an ECDSA signature
        bytes32 r; // `r` value of an ECDSA signature
        bytes32 s; // `s` value of an ECDSA signature
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.2;
pragma experimental ABIEncoderV2;

import { ISwap } from "../interfaces/ISwap.sol";
import { SwapTypes } from "../libraries/SwapTypes.sol";

/**
 * Error Codes
 * A1: invalid airswap address, must not be a 0x address
 */

/**
 * @title AirswapBase
 */

contract AirswapBase {
    
  ISwap public airswap;

  function _initSwapContract(address _airswap) internal {
    require(_airswap != address(0), "A1");
    airswap = ISwap(_airswap);
  }

  function _fillAirswapOrder(SwapTypes.Order memory _order) internal {
    airswap.swap(_order);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.2;
pragma experimental ABIEncoderV2;

import '@openzeppelin/contracts/access/Ownable.sol';
import { IERC20 } from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import { SafeERC20 } from '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';

import { AirswapBase } from './AirswapBase.sol';
import { IWhitelist } from '../interfaces/IWhitelist.sol';
import { SwapTypes } from '../libraries/SwapTypes.sol';

/**
 * Error Codes
 * R1: next oToken has not been committed to yet
 * R2: vault is not activated, cannot mint and sell oTokens or close an open position
 * R3: vault is currently activated, cannot commit next oToken or recommit an oToken
 * R4: cannot rollover next oToken and activate vault, commit phase period not over (MIN_COMMIT_PERIOD)
 * R5: token is not a whitelisted oToken
 */

/**
 * @title RolloverBase
 * @author Opyn Team
 */

contract RollOverBase is Ownable {
  address public otoken;
  address public nextOToken;

  uint256 constant public MIN_COMMIT_PERIOD = 0 hours; // was 4 but after request reduced it to 0
  uint256 public commitStateStart;

/**
 * Idle: action will go "idle" after the vault closes this position & before the next oToken is committed.
 *
 * Committed: owner has already set the next oToken this vault is trading. During this phase, all funds are
 * already back in the vault and waiting for redistribution. Users who don't agree with the setting of the next
 * round can withdraw.
 *
 * Activated: after vault calls "rollover", the owner can start minting / buying / selling according to each action.
 */
  enum ActionState {
    Activated,
    Committed,
    Idle
  }

  ActionState public state;
  IWhitelist public opynWhitelist;

  function onlyCommitted() private view {
    require(state == ActionState.Committed, "R1");
  }

  function onlyActivated() internal view {
    require(state == ActionState.Activated, "R2");
  }


  function _initRollOverBase(address _opynWhitelist) internal {
    state = ActionState.Idle;
    opynWhitelist = IWhitelist(_opynWhitelist);
  }

  /**
   * owner can commit the next otoken, if it's in idle state.
   * or re-commit it if needed during the commit phase.
   */
  function commitOToken(address _nextOToken) external onlyOwner {
    require(state != ActionState.Activated, "R3");
    _checkOToken(_nextOToken);
    nextOToken = _nextOToken;

    state = ActionState.Committed;
    
    commitStateStart = block.timestamp;
  }

  function _setActionIdle() internal {
    onlyActivated();
    // wait for the owner to set the next option
    state = ActionState.Idle;
  }

  function _rollOverNextOTokenAndActivate() internal {
    onlyCommitted();
    require(block.timestamp - commitStateStart > MIN_COMMIT_PERIOD, "R4");

    otoken = nextOToken;
    nextOToken = address(0);

    state = ActionState.Activated;
  }

  function _checkOToken(address _nextOToken) private view {
    require(opynWhitelist.isWhitelistedOtoken(_nextOToken), 'R5');
    _customOTokenCheck(_nextOToken);
  }

  /**
   * @dev funtion to add some custom logic to check the next otoken is valid to this strategy
   * this hook is triggered while action owner calls "commitNextOption"
   * so accessing otoken will give u the current otoken. 
   */
  function _customOTokenCheck(address _nextOToken) internal virtual view {
  }
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

// SPDX-License-Identifier: Apache
/*
  Copyright 2020 Swap Holdings Ltd.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.7.2;
pragma experimental ABIEncoderV2;

import {SwapTypes} from "../libraries/SwapTypes.sol";

interface ISwap {
    /**
     * @notice Atomic Token Swap
     * @param order Types.Order
     */
    function swap(SwapTypes.Order calldata order) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
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
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.2;

interface IWhitelist {
  function isWhitelistedOtoken(address _otoken) external view returns (bool);
  function whitelistCollateral(address _collateral) external;
  function whitelistProduct(
    address _underlying,
    address _strike,
    address _collateral,
    bool _isPut
  ) external;

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