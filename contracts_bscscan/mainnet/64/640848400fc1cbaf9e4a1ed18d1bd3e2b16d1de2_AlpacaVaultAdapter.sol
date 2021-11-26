// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12;

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import {FixedPointMath} from "../libraries/FixedPointMath.sol";
import {IDetailedERC20} from "../interfaces/IDetailedERC20.sol";
import {IVaultAdapterV2} from "../interfaces/IVaultAdapterV2.sol";
import {IbBUSDToken} from "../interfaces/IbBUSDToken.sol";
import {IAlpacaPool} from "../interfaces/IAlpacaPool.sol";
import {IAlpacaVaultConfig} from "../interfaces/IAlpacaVaultConfig.sol";
import {IUniswapV2Router01, IUniswapV2Router02} from "../interfaces/IUniswapV2Router.sol";

/// @title AlpacaVaultAdapter
///
/// @dev A vault adapter implementation which wraps an alpaca vault.
contract AlpacaVaultAdapter is IVaultAdapterV2 {
  using FixedPointMath for FixedPointMath.uq192x64;
  using SafeERC20 for IDetailedERC20;
  using SafeMath for uint256;

  /// @dev The vault that the adapter is wrapping.
  IbBUSDToken public vault;

  /// @dev The stakingPool that the adapter is wrapping.
  IAlpacaPool public stakingPool;

  /// @dev uniV2Router
  IUniswapV2Router02 public uniV2Router;

  /// @dev alpacaToken
  IDetailedERC20 public alpacaToken;

  /// @dev wBNBToken
  IDetailedERC20 public wBNBToken;

  /// @dev busdToken
  IDetailedERC20 public busdToken;

  /// @dev IAlpacaVaultConfig
  IAlpacaVaultConfig public config;

  /// @dev The address which has admin control over this contract.
  address public admin;

  /// @dev The address of the account which currently has administrative capabilities over this contract.
  address public governance;

  /// @dev The address of the pending governance.
  address public pendingGovernance;

  /// @dev The decimals of the token.
  uint256 public decimals;

  /// @dev The staking pool id of the token.
  uint256 public stakingPoolId;

  /// @dev The router path to sell alpaca for BUSD
  address[] public path;

  /// @dev The minimum swap out amount used when harvest.
  uint256 public minimumSwapOutAmount;

  /// @dev A modifier which reverts if the caller is not the admin.
  modifier onlyAdmin() {
    require(admin == msg.sender, "AlpacaVaultAdapter: only admin");
    _;
  }

  /// @dev Checks that the current message sender or caller is the governance address.
  ///
  ///
  modifier onlyGov() {
      require(msg.sender == governance, "AlpacaVaultAdapter: only governance.");
      _;
  }

  event GovernanceUpdated(address governance);

  event PendingGovernanceUpdated(address pendingGovernance);

  event MinimumSwapOutAmountUpdated(uint256 minimumSwapOutAmount);

  constructor(IbBUSDToken _vault, address _admin, address _governance, IUniswapV2Router02 _uniV2Router, IAlpacaPool _stakingPool, IDetailedERC20 _alpacaToken, IDetailedERC20 _wBNBToken, IAlpacaVaultConfig _config, uint256 _stakingPoolId) public {
    require(address(_vault) != address(0), "AlpacaVaultAdapter: vault address cannot be 0x0.");
    require(_admin != address(0), "AlpacaVaultAdapter: _admin cannot be 0x0.");
    require(_governance != address(0), "AlpacaVaultAdapter: governance address cannot be 0x0.");
    require(address(_uniV2Router) != address(0), "AlpacaVaultAdapter: _uniV2Router cannot be 0x0.");
    require(address(_stakingPool) != address(0), "AlpacaVaultAdapter: _stakingPool cannot be 0x0.");
    require(address(_alpacaToken) != address(0), "AlpacaVaultAdapter: _alpacaToken cannot be 0x0.");
    require(address(_wBNBToken) != address(0), "AlpacaVaultAdapter: _wBNBToken cannot be 0x0.");
    require(address(_config) != address(0), "AlpacaVaultAdapter: _config cannot be 0x0.");

    vault = _vault;
    admin = _admin;
    governance = _governance;
    uniV2Router = _uniV2Router;
    stakingPool = _stakingPool;
    alpacaToken = _alpacaToken;
    wBNBToken = _wBNBToken;
    config = _config;
    stakingPoolId = _stakingPoolId;

    updateApproval();
    decimals = _vault.decimals();
    busdToken = IDetailedERC20(_vault.token());

    address[] memory _path = new address[](3);
    _path[0] = address(alpacaToken);
    _path[1] = address(wBNBToken);
    _path[2] = address(busdToken);
    path = _path;
  }

  /// @dev Sets the pending governance.
  ///
  /// This function reverts if the new pending governance is the zero address or the caller is not the current
  /// governance. This is to prevent the contract governance being set to the zero address which would deadlock
  /// privileged contract functionality.
  ///
  /// @param _pendingGovernance the new pending governance.
  function setPendingGovernance(address _pendingGovernance) external onlyGov {
      require(_pendingGovernance != address(0), "AlpacaVaultAdapter: governance address cannot be 0x0.");

      pendingGovernance = _pendingGovernance;

      emit PendingGovernanceUpdated(_pendingGovernance);
  }

  /// @dev Accepts the role as governance.
  ///
  /// This function reverts if the caller is not the new pending governance.
  function acceptGovernance() external {
      require(msg.sender == pendingGovernance, "sender is not pendingGovernance");

      governance = pendingGovernance;

      emit GovernanceUpdated(pendingGovernance);
  }

  /// @dev Sets the minimum swap out amount.
  ///
  /// @param _minimumSwapOutAmount the minimum swap out amount.
  function setMinimumSwapOutAmount(uint256 _minimumSwapOutAmount) external onlyGov {
      require(_minimumSwapOutAmount > 0, "AlpacaVaultAdapter: _minimumSwapOutAmount should > 0.");

      minimumSwapOutAmount = _minimumSwapOutAmount;

      emit MinimumSwapOutAmountUpdated(_minimumSwapOutAmount);
  }

  /// @dev Gets the token that the vault accepts.
  ///
  /// @return the accepted token.
  function token() external view override returns (IDetailedERC20) {
    return IDetailedERC20(vault.token());
  }

  /// @dev Gets the total value of the assets that the adapter holds in the vault.
  ///
  /// @return the total assets.
  function totalValue() external view override returns (uint256) {

    (uint256 amount,,,) = stakingPool.userInfo(stakingPoolId, address(this));
    return _sharesToTokens(amount);
  }

  /// @dev Deposits tokens into the vault.
  ///
  /// @param _amount the amount of tokens to deposit into the vault.
  function deposit(uint256 _amount) external override {

    // deposit to vault
    vault.deposit(_amount);
    // stake to pool
    stakingPool.deposit(address(this), stakingPoolId, vault.balanceOf(address(this)));

  }

  /// @dev Withdraws tokens from the vault to the recipient.
  ///
  /// This function reverts if the caller is not the admin.
  ///
  /// @param _recipient the account to withdraw the tokes to.
  /// @param _amount    the amount of tokens to withdraw.
  function withdraw(address _recipient, uint256 _amount) external override onlyAdmin {
    // unstake
    stakingPool.withdraw(address(this), stakingPoolId, _tokensToShares(_amount));

    // withdraw
    vault.withdraw(_tokensToShares(_amount));

    // transfer all the busd in adapter to yum
    require(busdToken.transfer(_recipient, busdToken.balanceOf(address(this))), "AlpacaVaultAdapter: failed to transfer tokens");
  }

  /// @dev Indirect withdraws tokens from the vault to the recipient.
  ///
  /// This function reverts if the caller is not the admin.
  ///
  /// @param _recipient the account to withdraw the tokes to.
  /// @param _amount    the amount of tokens to withdraw.
  function indirectWithdraw(address _recipient, uint256 _amount) external override onlyAdmin {
    require(minimumSwapOutAmount > 0, "AlpacaVaultAdapter: minimumSwapOutAmount should > 0.");
    // unstake
    stakingPool.withdraw(address(this), stakingPoolId, _tokensToShares(_amount));

    // withdraw accumulated ibusd from collector harvest
    if(vault.balanceOf(address(this)) > 0){
      vault.withdraw(vault.balanceOf(address(this)));
    }

    stakingPool.harvest(stakingPoolId);
    uint256[] memory amounts = uniV2Router
      .swapExactTokensForTokens(
        alpacaToken.balanceOf(address(this)),
        minimumSwapOutAmount,
        path,
        address(this),
        block.timestamp + 800
      );
    require(amounts[2] >= minimumSwapOutAmount, "AlpacaVaultAdapter: swap amount should >= minimumSwapOutAmount");

    // transfer all the busd in adapter to user
    require(busdToken.transfer(_recipient, busdToken.balanceOf(address(this))), "AlpacaVaultAdapter: failed to transfer tokens");
    // reset minumum swap out amount in case we didn't update next harvest
    minimumSwapOutAmount = 0;
  }

  /// @dev Updates the vaults approval of the token to be the maximum value.
  function updateApproval() public {
    // busd to vault
    IDetailedERC20(vault.token()).safeApprove(address(vault), uint256(-1));
    // vault to stakingPool
    IDetailedERC20(address(vault)).safeApprove(address(stakingPool), uint256(-1));
    // alpaca to uniV2Router
    alpacaToken.safeApprove(address(uniV2Router), uint256(-1));
  }

  /// @dev Computes the total token entitled to the token holders.
  ///
  /// source from alpaca vault: https://bscscan.com/address/0x7C9e73d4C71dae564d41F78d56439bB4ba87592f
  ///
  /// @return total token.
  function _totalToken() internal view returns (uint256) {
    uint256 vaultDebtVal = vault.vaultDebtVal();
    uint256 reservePool = vault.reservePool();
    uint256 lastAccrueTime = vault.lastAccrueTime();
    if (now > lastAccrueTime) {
      uint256 interest = _pendingInterest(0, lastAccrueTime, vaultDebtVal);
      uint256 toReserve = interest.mul(config.getReservePoolBps()).div(10000);
      reservePool = reservePool.add(toReserve);
      vaultDebtVal = vaultDebtVal.add(interest);
    }
    return busdToken.balanceOf(address(vault)).add(vaultDebtVal).sub(reservePool);
  }

  /// @dev Return the pending interest that will be accrued in the next call.
  ///
  /// source from alpaca vault: https://bscscan.com/address/0x7C9e73d4C71dae564d41F78d56439bB4ba87592f
  ///
  /// @param _value Balance value to subtract off address(this).balance when called from payable functions.
  /// @param _lastAccrueTime Last timestamp to accrue interest.
  /// @param _vaultDebtVal Debt value of the given vault.
  /// @return pending interest.
  function _pendingInterest(uint256 _value, uint256 _lastAccrueTime, uint256 _vaultDebtVal) internal view returns (uint256) {
    if (now > _lastAccrueTime) {
      uint256 timePass = now.sub(_lastAccrueTime);
      uint256 balance = busdToken.balanceOf(address(vault)).sub(_value);
      uint256 ratePerSec = config.getInterestRate(_vaultDebtVal, balance);
      return ratePerSec.mul(_vaultDebtVal).mul(timePass).div(1e18);
    } else {
      return 0;
    }
  }

  /// @dev Computes the number of tokens an amount of shares is worth.
  ///
  /// @param _sharesAmount the amount of shares.
  ///
  /// @return the number of tokens the shares are worth.
  function _sharesToTokens(uint256 _sharesAmount) internal view returns (uint256) {
    return _sharesAmount.mul(_totalToken()).div(vault.totalSupply());
  }

  /// @dev Computes the number of shares an amount of tokens is worth.
  ///
  /// @param _tokensAmount the amount of shares.
  ///
  /// @return the number of shares the tokens are worth.
  function _tokensToShares(uint256 _tokensAmount) internal view returns (uint256) {
    return _tokensAmount.mul(vault.totalSupply()).div(_totalToken());
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

//SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12;

library FixedPointMath {
    uint256 public constant DECIMALS = 18;
    uint256 public constant SCALAR = 10**DECIMALS;

    struct uq192x64 {
        uint256 x;
    }

    function fromU256(uint256 value) internal pure returns (uq192x64 memory) {
        uint256 x;
        require(value == 0 || (x = value * SCALAR) / SCALAR == value);
        return uq192x64(x);
    }

    function maximumValue() internal pure returns (uq192x64 memory) {
        return uq192x64(uint256(-1));
    }

    function add(uq192x64 memory self, uq192x64 memory value) internal pure returns (uq192x64 memory) {
        uint256 x;
        require((x = self.x + value.x) >= self.x);
        return uq192x64(x);
    }

    function add(uq192x64 memory self, uint256 value) internal pure returns (uq192x64 memory) {
        return add(self, fromU256(value));
    }

    function sub(uq192x64 memory self, uq192x64 memory value) internal pure returns (uq192x64 memory) {
        uint256 x;
        require((x = self.x - value.x) <= self.x);
        return uq192x64(x);
    }

    function sub(uq192x64 memory self, uint256 value) internal pure returns (uq192x64 memory) {
        return sub(self, fromU256(value));
    }

    function mul(uq192x64 memory self, uint256 value) internal pure returns (uq192x64 memory) {
        uint256 x;
        require(value == 0 || (x = self.x * value) / value == self.x);
        return uq192x64(x);
    }

    function div(uq192x64 memory self, uint256 value) internal pure returns (uq192x64 memory) {
        require(value != 0);
        return uq192x64(self.x / value);
    }

    function cmp(uq192x64 memory self, uq192x64 memory value) internal pure returns (int256) {
        if (self.x < value.x) {
            return -1;
        }

        if (self.x > value.x) {
            return 1;
        }

        return 0;
    }

    function decode(uq192x64 memory self) internal pure returns (uint256) {
        return self.x / SCALAR;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IDetailedERC20 is IERC20 {
    function name() external returns (string memory);

    function symbol() external returns (string memory);

    function decimals() external returns (uint8);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./IDetailedERC20.sol";

/// Interface for all Vault Adapter V2 implementations.
interface IVaultAdapterV2 {
    /// @dev Gets the token that the adapter accepts.
    function token() external view returns (IDetailedERC20);

    /// @dev The total value of the assets deposited into the vault.
    function totalValue() external view returns (uint256);

    /// @dev Deposits funds into the vault.
    ///
    /// @param _amount  the amount of funds to deposit.
    function deposit(uint256 _amount) external;

    /// @dev Attempts to withdraw funds from the wrapped vault.
    ///
    /// The amount withdrawn to the recipient may be less than the amount requested.
    ///
    /// @param _recipient the recipient of the funds.
    /// @param _amount    the amount of funds to withdraw.
    function withdraw(address _recipient, uint256 _amount) external;

    /// @dev Attempts to withdraw funds from the wrapped vault.
    ///
    /// The amount withdrawn to the recipient may be less than the amount requested.
    ///
    /// @param _recipient the recipient of the funds.
    /// @param _amount    the amount of funds to withdraw.
    function indirectWithdraw(address _recipient, uint256 _amount) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12;

import {IDetailedERC20} from "./IDetailedERC20.sol";

interface IbBUSDToken is IDetailedERC20 {
    function vaultDebtVal() external view returns (uint256);

    function lastAccrueTime() external view returns (uint256);

    function reservePool() external view returns (uint256);

    function deposit(uint256) external;

    function withdraw(uint256) external;

    function token() external view returns (address);

    function totalToken() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12;

interface IAlpacaPool {
    function deposit(address, uint256, uint256) external;

    function withdraw(address, uint256, uint256) external;

    function harvest(uint256) external;

    function userInfo(uint256, address) external view returns (uint256, uint256, uint256, address);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12;

interface IAlpacaVaultConfig {
  function getInterestRate(uint256 debt, uint256 floating) external view returns (uint256);

  function getReservePoolBps() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12;

interface IUniswapV2Router01 {
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
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