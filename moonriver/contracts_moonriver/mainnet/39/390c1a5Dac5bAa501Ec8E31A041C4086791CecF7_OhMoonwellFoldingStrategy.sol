// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import {Math} from "@openzeppelin/contracts/math/Math.sol";
import {IStrategy} from "@ohfinance/oh-contracts/contracts/interfaces/strategies/IStrategy.sol";
import {TransferHelper} from "@ohfinance/oh-contracts/contracts/libraries/TransferHelper.sol";
import {OhStrategy} from "@ohfinance/oh-contracts/contracts/strategies/OhStrategy.sol";
import {OhMoonwellHelper} from "./OhMoonwellHelper.sol";
import {OhMoonwellFoldingStrategyStorage} from "./OhMoonwellFoldingStrategyStorage.sol";

/// @title Oh! Finance Moonwell Folding Strategy
/// @notice Standard, single asset leveraged strategy. Invest underlying tokens into derivative MErc20 tokens
/// @dev https://docs.moonwell.fi/
contract OhMoonwellFoldingStrategy is IStrategy, OhMoonwellHelper, OhStrategy, OhMoonwellFoldingStrategyStorage {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /// @notice Initialize the Moonwell Strategy Logic
    constructor() initializer {
        assert(registry() == address(0));
        assert(bank() == address(0));
        assert(underlying() == address(0));
        assert(reward() == address(0));
    }

    /// @notice Initializes the Moonwell Folding Strategy Proxy
    /// @param registry_ the registry contract
    /// @param bank_ the bank associated with the strategy
    /// @param underlying_ the underlying token that is deposited
    /// @param derivative_ the MToken address received from Moonwell
    /// @param reward_ the address of the reward token MFAM
    /// @param secondaryReward_ the address of the reward token WMOVR
    /// @param comptroller_ the Moonwell rewards contract
    /// @dev The function should be called at time of deployment
    function initializeMoonwellFoldingStrategy(
        address registry_,
        address bank_,
        address underlying_,
        address derivative_,
        address reward_,
        address secondaryReward_,
        address comptroller_,
        uint256 folds_,
        uint256 collateralFactorNumerator_,
        uint256 collateralFactorDenominator_
    ) public initializer {
        initializeStrategy(
            registry_, 
            bank_, 
            underlying_, 
            derivative_, 
            reward_
        );
        
        initializeMoonwellFoldingStorage(
            secondaryReward_,
            comptroller_, 
            folds_,
            collateralFactorNumerator_, 
            collateralFactorDenominator_
        );

        IERC20(underlying_).safeApprove(derivative_, type(uint256).max);
        enter(comptroller_, derivative_);
    }

    /// @notice Get the balance of underlying invested by the Strategy
    /// @dev Get the exchange rate (which is scaled up by 1e18) and multiply by amount of MTokens
    /// @return The amount of underlying the strategy has invested
    function investedBalance() public view override returns (uint256) {
        return suppliedUnderlying().sub(borrowedUnderlying());
    }

    // Get the balance of extra rewards received by the Strategy
    function secondaryRewardBalance() public view returns (uint256) {
        address secondaryReward = secondaryReward();
        if (secondaryReward == address(0)) {
            return 0;
        }
    
        return IERC20(secondaryReward).balanceOf(address(this));
    }

    function invest() external override onlyBank {
        _compound();
        _deposit();
    }

    function _compound() internal {
        _claimAll();

        uint256 amount = rewardBalance();
        if (amount > 0) {
            liquidate(reward(), underlying(), amount);
        }

        uint256 secondaryAmount = secondaryRewardBalance();
        if (secondaryAmount > 0) {
            liquidate(secondaryReward(), underlying(), secondaryAmount);
        }
    }

    function _claimAll() internal {
        if (suppliedUnderlying() > 0) {
            // Claim MFAM
            claim(comptroller(), 0);
            
            // Claim and wrap MOVR
            claim(comptroller(), 1);
            wrap(secondaryReward(), address(this).balance);
        }
    }

    // deposit underlying tokens into Moonwell as collateral and borrow against it, minting MTokens
    function _deposit() internal {
        uint256 balance = underlyingBalance();

        if (balance > 0) {
            mint(derivative(), balance);

            uint256 folds = folds();
            for (uint256 i = 0; i < folds; i++) {
                uint256 borrowAmount = balance.mul(collateralFactorNumerator()).div(collateralFactorDenominator());
                borrow(derivative(), borrowAmount);
                balance = underlyingBalance();
                mint(derivative(), balance);
            }
        }

        updateSupply();
    }

    // withdraw all underlying by redeem all MTokens
    function withdrawAll() external override onlyBank {
        updateSupply();
        uint256 invested = investedBalance();
        _withdraw(msg.sender, invested);
    }

    // withdraw an amount of underlying tokens
    function withdraw(uint256 amount) external override onlyBank returns (uint256) {
        updateSupply();
        uint256 withdrawn = _withdraw(msg.sender, amount);
        return withdrawn;
    }

    // withdraw underlying tokens from the protocol after redeeming them from moonwell
    function _withdraw(address recipient, uint256 amount) internal returns (uint256) {
        if (amount == 0) {
            return 0;
        }

        uint256 invested = investedBalance();
        if (invested == 0) {
            return 0;
        }

        // calculate amount to redeem by supply ownership
        uint256 withdrawn;
        uint256 supplyShare = amount.mul(1e18).div(invested);
        uint256 redeemAmount = supplyShare.mul(invested).div(1e18);

        if (redeemAmount <= underlyingBalance()) {
            withdrawn = TransferHelper.safeTokenTransfer(recipient, underlying(), amount);
            return withdrawn;
        }

        // safely redeem from Moonwell
        if (redeemAmount > invested) {
            mustRedeemPartial(invested);
        } else {
            mustRedeemPartial(redeemAmount);
        }

        // withdraw to bank
        withdrawn = TransferHelper.safeTokenTransfer(recipient, underlying(), amount);
        
        // re-invest whatever is left over if any
        if (underlyingBalance() > 10) {
            _compound();
            _deposit();
        } else {
            updateSupply();
        }

        return withdrawn;
    }

    // Redeems `amountUnderlying` or fails.
    function mustRedeemPartial(uint256 amountUnderlying) internal {
        require(
            getCash(derivative()) >= amountUnderlying,
            "market cash cannot cover liquidity"
        );
        redeemMaximumUnderlyingWithLoan();
        require(underlyingBalance() >= amountUnderlying, "Unable to withdraw the entire amountUnderlying");
    }

    function redeemMaximumUnderlyingWithLoan() internal {
        // amount of liquidity
        uint256 available = getCash(derivative());
        // amount of underlying we supplied
        uint256 supplied = balanceOfUnderlying(derivative(), address(this));
        // amount of underlying we borrowed
        uint256 borrowed = borrowBalanceCurrent(derivative(), address(this));

        while (borrowed > 0) {
            uint256 requiredCollateral = borrowed
                .mul(collateralFactorDenominator())
                .add(collateralFactorNumerator().div(2))           
                .div(collateralFactorNumerator());

            // redeem just as much as needed to repay the loan
            uint256 wantToRedeem = supplied.sub(requiredCollateral);
            redeemUnderlying(derivative(), Math.min(wantToRedeem, available));
            // now we can repay our borrowed amount
            uint256 balance = underlyingBalance();
            repay(derivative(), Math.min(borrowed, balance));

            // update the parameters
            available = getCash(derivative());
            supplied = balanceOfUnderlying(derivative(), address(this));
            borrowed = borrowBalanceCurrent(derivative(), address(this));
        }

        // redeem the most we can redeem
        redeemUnderlying(derivative(), Math.min(available, supplied));
    }

    function updateSupply() internal {
        setSuppliedUnderlying(balanceOfUnderlying(derivative(), address(this)));
        setBorrowedUnderlying(borrowBalanceCurrent(derivative(), address(this)));
    }

    receive() external payable {}
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

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import {IStrategyBase} from "./IStrategyBase.sol";

interface IStrategy is IStrategyBase {
    function investedBalance() external view returns (uint256);

    function invest() external;

    function withdraw(uint256 amount) external returns (uint256);

    function withdrawAll() external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

library TransferHelper {
    using SafeERC20 for IERC20;

    // safely transfer tokens without underflowing
    function safeTokenTransfer(
        address recipient,
        address token,
        uint256 amount
    ) internal returns (uint256) {
        if (amount == 0) {
            return 0;
        }

        uint256 balance = IERC20(token).balanceOf(address(this));
        if (balance < amount) {
            IERC20(token).safeTransfer(recipient, balance);
            return balance;
        } else {
            IERC20(token).safeTransfer(recipient, amount);
            return amount;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import {IBank} from "../interfaces/bank/IBank.sol";
import {IStrategyBase} from "../interfaces/strategies/IStrategyBase.sol";
import {ILiquidator} from "../interfaces/ILiquidator.sol";
import {IManager} from "../interfaces/IManager.sol";
import {TransferHelper} from "../libraries/TransferHelper.sol";
import {OhSubscriberUpgradeable} from "../registry/OhSubscriberUpgradeable.sol";
import {OhStrategyStorage} from "./OhStrategyStorage.sol";

/// @title Oh! Finance Strategy
/// @notice Base Upgradeable Strategy Contract to build strategies on
contract OhStrategy is OhSubscriberUpgradeable, OhStrategyStorage, IStrategyBase {
    using SafeERC20 for IERC20;

    event Liquidate(address indexed router, address indexed token, uint256 amount);
    event Sweep(address indexed token, uint256 amount, address recipient);

    /// @notice Only the Bank can execute these functions
    modifier onlyBank() {
        require(msg.sender == bank(), "Strategy: Only Bank");
        _;
    }

    /// @notice Initialize the base Strategy
    /// @param registry_ Address of the Registry
    /// @param bank_ Address of Bank
    /// @param underlying_ Underying token that is deposited
    /// @param derivative_ Derivative token received from protocol, or address(0)
    /// @param reward_ Reward token received from protocol, or address(0)
    function initializeStrategy(
        address registry_,
        address bank_,
        address underlying_,
        address derivative_,
        address reward_
    ) internal initializer {
        initializeSubscriber(registry_);
        initializeStorage(bank_, underlying_, derivative_, reward_);
    }

    /// @dev Balance of underlying awaiting Strategy investment
    function underlyingBalance() public view override returns (uint256) {
        return IERC20(underlying()).balanceOf(address(this));
    }

    /// @dev Balance of derivative tokens received from Strategy, if applicable
    /// @return The balance of derivative tokens
    function derivativeBalance() public view override returns (uint256) {
        if (derivative() == address(0)) {
            return 0;
        }
        return IERC20(derivative()).balanceOf(address(this));
    }

    /// @dev Balance of reward tokens awaiting liquidation, if applicable
    function rewardBalance() public view override returns (uint256) {
        if (reward() == address(0)) {
            return 0;
        }
        return IERC20(reward()).balanceOf(address(this));
    }

    /// @notice Governance function to sweep any stuck / airdrop tokens to a given recipient
    /// @param token The address of the token to sweep
    /// @param amount The amount of tokens to sweep
    /// @param recipient The address to send the sweeped tokens to
    function sweep(
        address token,
        uint256 amount,
        address recipient
    ) external onlyGovernance {
        // require(!_protected[token], "Strategy: Cannot sweep");
        TransferHelper.safeTokenTransfer(recipient, token, amount);
        emit Sweep(token, amount, recipient);
    }

    /// @dev Liquidation function to swap rewards for underlying
    function liquidate(
        address from,
        address to,
        uint256 amount
    ) internal {
        // if (amount > minimumSell())

        // find the liquidator to use
        address manager = manager();
        address liquidator = IManager(manager).liquidators(from, to);

        // increase allowance and liquidate to the manager
        TransferHelper.safeTokenTransfer(liquidator, from, amount);
        uint256 received = ILiquidator(liquidator).liquidate(manager, from, to, amount, 1);

        // notify revenue and transfer proceeds back to strategy
        IManager(manager).accrueRevenue(bank(), to, received);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import {WMOVR} from "../../interfaces/WMOVR.sol";
import {MGlimmer} from "./interfaces/MGlimmer.sol";
import {MErc20} from "./interfaces/MErc20.sol";
import {Comptroller} from "./interfaces/Comptroller.sol";

/// @title Oh! Finance Moonwell Helper
/// @notice Helper functions to interact with the Moonwell Protocol
/// @dev https://docs.moonwell.fi/
abstract contract OhMoonwellHelper {
    using SafeERC20 for IERC20;

    /// @notice Get the exchange rate of mTokens => underlying
    /// @dev Originally specified here - https://compound.finance/docs/ctokens#exchange-rate
    /// @param mToken The mToken address rate to get
    /// @return The exchange rate scaled by 1e18
    function getExchangeRate(address mToken) internal view returns (uint256) {
        return MErc20(mToken).exchangeRateStored();
    }

    // Returns the cash balance of this mToken in the underlying asset
    function getCash(address mToken) internal view returns (uint256) {
        return MErc20(mToken).getCash();
    }

    // Returns the owner's mToken balance
    function balanceOfUnderlying(address mToken, address owner) internal returns (uint256) {
        return MErc20(mToken).balanceOfUnderlying(owner);
    }

    // Returns the owner's borrow balance
    function borrowBalanceCurrent(address mToken, address owner) internal returns (uint256) {
        return MErc20(mToken).borrowBalanceCurrent(owner);
    }

    /// @notice Enter the market (approve), required before calling borrow
    /// @param comptroller The Moonwell comptroller (rewards contract)
    /// @param mToken The mToken market to enter
    function enter(address comptroller, address mToken) internal {
        address[] memory mTokens = new address[](1);
        mTokens[0] = mToken;
        Comptroller(comptroller).enterMarkets(mTokens);
    }

    /// @notice Mint mTokens by providing/lending underlying as collateral
    /// @param mToken The Moonwell mToken
    /// @param amount The amount of underlying to lend
    function mint(
        address mToken,
        uint256 amount
    ) internal {
        if (amount == 0) {
            return;
        }

        uint256 result = MErc20(mToken).mint(amount);
        require(result == 0, "Moonwell: Borrow failed");
    }

    /// @notice Borrow underlying tokens from a given mToken against collateral
    /// @param mToken The mToken corresponding the underlying we want to borrow
    /// @param amount The amount of underlying to borrow
    function borrow(address mToken, uint256 amount) internal {
        if (amount == 0) {
            return;
        }

        uint256 result = MErc20(mToken).borrow(amount);
        require(result == 0, "Moonwell: Borrow failed");
    }

    /// @notice Repay loan with a given amount of underlying
    /// @param mToken The mToken for the underlying
    /// @param amount The amount of underlying to repay
    function repay(
        address mToken,
        uint256 amount
    ) internal {
        if (amount == 0) {
            return;
        }

        uint256 result = MErc20(mToken).repayBorrow(amount);
        require(result == 0, "Moonwell: Repay failed");
    }

    /// @notice Redeem mTokens for underlying
    /// @param mToken The mToken to redeem
    /// @param amount The amount of mTokens to redeem
    function redeem(address mToken, uint256 amount) internal {
        if (amount == 0) {
            return;
        }

        uint256 result = MErc20(mToken).redeem(amount);
        require(result == 0, "Moonwell: Redeem mToken");
    }

    /// @notice Redeem mTokens for underlying
    /// @param mToken The mToken to redeem
    /// @param amount The amount of underlying tokens to receive
    function redeemUnderlying(address mToken, uint256 amount) internal {
        if (amount == 0) {
            return;
        }

        uint256 result = MErc20(mToken).redeemUnderlying(amount);
        require(result == 0, "Moonwell: Redeem underlying");
    }

    /// @notice Redeem mTokens for wmovr
    /// @param wmovr WMOVR Address
    /// @param mToken The mToken to redeem
    /// @param amount The amount of underlying to receive
    /// @dev Redeem in MOVR, then convert to wmovr
    function redeemUnderlyingInWeth(
        address wmovr,
        address mToken,
        uint256 amount
    ) internal {
        if (amount == 0) {
            return;
        }

        redeemUnderlying(mToken, amount);
        WMOVR(wmovr).deposit{value: address(this).balance}();
    }

    /// @notice Claim rewards from comptroller for this address
    /// @param comptroller The Moonwell comptroller, Reward Contract
    /// @param rewardType Reward type: 0 = MFAM, 1 = MOVR
    function claim(address comptroller, uint8 rewardType) internal {
        Comptroller(comptroller).claimReward(rewardType, address(this));
    }

    /// @notice Wrap MOVR to WMOVR
    /// @param wmovr Address of WMOVR
    /// @param amount Amount of MOVR to wrap
    function wrap(address wmovr, uint256 amount) internal {
        if (amount == 0) {
            return;
        }
        WMOVR(wmovr).deposit{value: amount}();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import {IMoonwellFoldingStrategyStorage} from "../../interfaces/strategies/moonwell/IMoonwellFoldingStrategyStorage.sol";
import {OhUpgradeable} from "@ohfinance/oh-contracts/contracts/proxy/OhUpgradeable.sol";

contract OhMoonwellFoldingStrategyStorage is Initializable, OhUpgradeable, IMoonwellFoldingStrategyStorage {
    bytes32 internal constant _SECONDARY_REWARD_SLOT = 0xc86ea8dc638d4626de72aebbab154b9efc124bca476b569d921bbbba29a9c863;
    bytes32 internal constant _COMPTROLLER_SLOT = 0x7bf009139d7e3c7e684f68bc17b69a1f37ebb989c1fd3aa50a98437b35992ec1;
    bytes32 internal constant _FOLDS = 0x0819b21e3e41b5819c98075e16f1dac2ac5f9920276adcdb574d2dd78d5a44e1;
    bytes32 internal constant _COLLATERAL_FACTOR = 0xaa42134260c571dae849c85b74e4dab3ab3adde8bda78f89741f3a08fd2f6788;
    bytes32 internal constant _COLLATERAL_FACTOR_NUMERATOR = 0x1d40a6ec69cc6171b66111a0f4c8676cd444c56e796ad6dfcc11737b1f951e8e;
    bytes32 internal constant _COLLATERAL_FACTOR_DENOMINATOR = 0x21e5f33d1cc989f81ebcb97f627391afa75c84768527816278a904f0f61d85d3;
    bytes32 internal constant _SUPPLIED_UNDERLYING = 0x9804ab579e190b2a29630e835a6a7ea05320b9dc3bf4a527ffb2c6bff9e7baa4;
    bytes32 internal constant _BORROWED_UNDERLYING = 0xd4e15b8541f773ba846ddff2cebfc3735263e5c7ec80430f73a1237d0d4149b8;

    constructor() {
        assert(_SECONDARY_REWARD_SLOT == bytes32(uint256(keccak256("eip1967.moonwellFoldingStrategy.secondaryReward")) - 1));
        assert(_COMPTROLLER_SLOT == bytes32(uint256(keccak256("eip1967.moonwellFoldingStrategy.comptroller")) - 1));
        assert(_FOLDS == bytes32(uint256(keccak256("eip1967.moonwellFoldingStrategy.folds")) - 1));
        assert(_COLLATERAL_FACTOR == bytes32(uint256(keccak256("eip1967.moonwellFoldingStrategy.collateralFactor")) - 1));
        assert(_COLLATERAL_FACTOR_NUMERATOR == bytes32(uint256(keccak256("eip1967.moonwellFoldingStrategy.collateralFactorNumerator")) - 1));
        assert(_COLLATERAL_FACTOR_DENOMINATOR == bytes32(uint256(keccak256("eip1967.moonwellFoldingStrategy.collateralFactorDenominator")) - 1));
        assert(_SUPPLIED_UNDERLYING == bytes32(uint256(keccak256("eip1967.moonwellFoldingStrategy.suppliedUnderlying")) - 1));
        assert(_BORROWED_UNDERLYING == bytes32(uint256(keccak256("eip1967.moonwellFoldingStrategy.borrowedUnderlying")) - 1));
    }

    function initializeMoonwellFoldingStorage(
        address secondaryReward_,
        address comptroller_,
        uint256 folds_,
        uint256 collateralFactorNumerator_,
        uint256 collateralFactorDenominator_
    ) internal initializer {
        _setSecondaryReward(secondaryReward_);
        _setComptroller(comptroller_);
        _setFolds(folds_);
        _setCollateralFactorNumerator(collateralFactorNumerator_);
        _setCollateralFactorDenominator(collateralFactorDenominator_);
        setSuppliedUnderlying(0);
        setBorrowedUnderlying(0);
    }

    function secondaryReward() public view override returns (address) {
        return getAddress(_SECONDARY_REWARD_SLOT);
    }

    function _setSecondaryReward(address secondaryReward_) internal {
        setAddress(_SECONDARY_REWARD_SLOT, secondaryReward_);
    }

    function comptroller() public view override returns (address) {
        return getAddress(_COMPTROLLER_SLOT);
    }

    function _setComptroller(address comptroller_) internal {
        setAddress(_COMPTROLLER_SLOT, comptroller_);
    }

    function folds() public view override returns (uint256) {
        return getUInt256(_FOLDS);
    }

    function _setFolds(uint256 folds_) internal {
        setUInt256(_FOLDS, folds_);
    }

    function collateralFactorNumerator() public view override returns (uint256) {
        return getUInt256(_COLLATERAL_FACTOR_NUMERATOR);
    }

    function _setCollateralFactorNumerator(uint256 collateralFactorNumerator_) internal {
        setUInt256(_COLLATERAL_FACTOR_NUMERATOR, collateralFactorNumerator_);
    }

    function collateralFactorDenominator() public view override returns (uint256) {
        return getUInt256(_COLLATERAL_FACTOR_DENOMINATOR);
    }

    function _setCollateralFactorDenominator(uint256 collateralFactorDenominator_) internal {
        setUInt256(_COLLATERAL_FACTOR_DENOMINATOR, collateralFactorDenominator_);
    }

    function suppliedUnderlying() public view override returns (uint256) {
        return getUInt256(_SUPPLIED_UNDERLYING);
    }

    function setSuppliedUnderlying(uint256 suppliedUnderlying_) public override {
        setUInt256(_SUPPLIED_UNDERLYING, suppliedUnderlying_);
    }

    function borrowedUnderlying() public view override returns (uint256) {
        return getUInt256(_BORROWED_UNDERLYING);
    }

    function setBorrowedUnderlying(uint256 borrowedUnderlying_) public override {
        setUInt256(_BORROWED_UNDERLYING, borrowedUnderlying_);
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

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import {IStrategyStorage} from "./IStrategyStorage.sol";

interface IStrategyBase is IStrategyStorage {
    function underlyingBalance() external view returns (uint256);

    function derivativeBalance() external view returns (uint256);

    function rewardBalance() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface IStrategyStorage {
    function bank() external view returns (address);

    function underlying() external view returns (address);

    function derivative() external view returns (address);

    function reward() external view returns (address);

    // function investedBalance() external view returns (uint256);

    // function invest() external;

    // function withdraw(uint256 amount) external returns (uint256);

    // function withdrawAll() external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import {IBankStorage} from "./IBankStorage.sol";

interface IBank is IBankStorage {
    function strategies(uint256 i) external view returns (address);

    function totalStrategies() external view returns (uint256);

    function underlyingBalance() external view returns (uint256);

    function strategyBalance(uint256 i) external view returns (uint256);

    function investedBalance() external view returns (uint256);

    function virtualBalance() external view returns (uint256);

    function virtualPrice() external view returns (uint256);

    function pause() external;

    function unpause() external;

    function invest(address strategy, uint256 amount) external;

    function investAll(address strategy) external;

    function exit(address strategy, uint256 amount) external;

    function exitAll(address strategy) external;

    function deposit(uint256 amount) external;

    function depositFor(uint256 amount, address recipient) external;

    function withdraw(uint256 amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface ILiquidator {
    function liquidate(
        address recipient,
        address from,
        address to,
        uint256 amount,
        uint256 minOut
    ) external returns (uint256);

    function getSwapInfo(address from, address to) external view returns (address router, address[] memory path);

    function sushiswapRouter() external view returns (address);

    function uniswapRouter() external view returns (address);

    function weth() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface IManager {
    function token() external view returns (address);

    function buybackFee() external view returns (uint256);

    function managementFee() external view returns (uint256);

    function liquidators(address from, address to) external view returns (address);

    function whitelisted(address _contract) external view returns (bool);

    function banks(uint256 i) external view returns (address);

    function totalBanks() external view returns (uint256);

    function strategies(address bank, uint256 i) external view returns (address);

    function totalStrategies(address bank) external view returns (uint256);

    function withdrawIndex(address bank) external view returns (uint256);

    function setWithdrawIndex(uint256 i) external;

    function rebalance(address bank) external;

    function finance(address bank) external;

    function financeAll(address bank) external;

    function buyback(address from) external;

    function accrueRevenue(
        address bank,
        address underlying,
        uint256 amount
    ) external;

    function exitAll(address bank) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {ISubscriber} from "../interfaces/ISubscriber.sol";
import {IRegistry} from "../interfaces/IRegistry.sol";
import {OhUpgradeable} from "../proxy/OhUpgradeable.sol";

/// @title Oh! Finance Subscriber Upgradeable
/// @notice Base Oh! Finance upgradeable contract used to control access throughout the protocol
abstract contract OhSubscriberUpgradeable is Initializable, OhUpgradeable, ISubscriber {
    bytes32 private constant _REGISTRY_SLOT = 0x1b5717851286d5e98a28354be764b8c0a20eb2fbd059120090ee8bcfe1a9bf6c;

    /// @notice Only allow authorized addresses (governance or manager) to execute a function
    modifier onlyAuthorized {
        require(msg.sender == governance() || msg.sender == manager(), "Subscriber: Only Authorized");
        _;
    }

    /// @notice Only allow the governance address to execute a function
    modifier onlyGovernance {
        require(msg.sender == governance(), "Subscriber: Only Governance");
        _;
    }

    /// @notice Verify the registry storage slot is correct
    constructor() {
        assert(_REGISTRY_SLOT == bytes32(uint256(keccak256("eip1967.subscriber.registry")) - 1));
    }

    /// @notice Initialize the Subscriber
    /// @param registry_ The Registry contract address
    /// @dev Always call this method in the initializer function for any derived classes
    function initializeSubscriber(address registry_) internal initializer {
        require(Address.isContract(registry_), "Subscriber: Invalid Registry");
        _setRegistry(registry_);
    }

    /// @notice Set the Registry for the contract. Only callable by Governance.
    /// @param registry_ The new registry
    /// @dev Requires sender to be Governance of the new Registry to avoid bricking.
    /// @dev Ideally should not be used
    function setRegistry(address registry_) external onlyGovernance {
        _setRegistry(registry_);
        require(msg.sender == governance(), "Subscriber: Bad Governance");
    }

    /// @notice Get the Governance address
    /// @return The current Governance address
    function governance() public view override returns (address) {
        return IRegistry(registry()).governance();
    }

    /// @notice Get the Manager address
    /// @return The current Manager address
    function manager() public view override returns (address) {
        return IRegistry(registry()).manager();
    }

    /// @notice Get the Registry address
    /// @return The current Registry address
    function registry() public view override returns (address) {
        return getAddress(_REGISTRY_SLOT);
    }

    function _setRegistry(address registry_) private {
        setAddress(_REGISTRY_SLOT, registry_);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import {IStrategyStorage} from "../interfaces/strategies/IStrategyStorage.sol";
import {OhUpgradeable} from "../proxy/OhUpgradeable.sol";

contract OhStrategyStorage is Initializable, OhUpgradeable, IStrategyStorage {
    bytes32 internal constant _BANK_SLOT = 0xd2eff96e29993ca5431993c3a205e12e198965c0e1fdd87b4899b57f1e611c74;
    bytes32 internal constant _UNDERLYING_SLOT = 0x0fad97fe3ec7d6c1e9191a09a0c4ccb7a831b6605392e57d2fedb8501a4dc812;
    bytes32 internal constant _DERIVATIVE_SLOT = 0x4ff4c9b81c0bf267e01129f4817e03efc0163ee7133b87bd58118a96bbce43d3;
    bytes32 internal constant _REWARD_SLOT = 0xaeb865605058f37eedb4467ee2609ddec592b0c9a6f7f7cb0db3feabe544c71c;

    constructor() {
        assert(_BANK_SLOT == bytes32(uint256(keccak256("eip1967.strategy.bank")) - 1));
        assert(_UNDERLYING_SLOT == bytes32(uint256(keccak256("eip1967.strategy.underlying")) - 1));
        assert(_DERIVATIVE_SLOT == bytes32(uint256(keccak256("eip1967.strategy.derivative")) - 1));
        assert(_REWARD_SLOT == bytes32(uint256(keccak256("eip1967.strategy.reward")) - 1));
    }

    function initializeStorage(
        address bank_,
        address underlying_,
        address derivative_,
        address reward_
    ) internal initializer {
        _setBank(bank_);
        _setUnderlying(underlying_);
        _setDerivative(derivative_);
        _setReward(reward_);
    }

    /// @notice The Bank that the Strategy is associated with
    function bank() public view override returns (address) {
        return getAddress(_BANK_SLOT);
    }

    /// @notice The underlying token the Strategy invests in AaveV2
    function underlying() public view override returns (address) {
        return getAddress(_UNDERLYING_SLOT);
    }

    /// @notice The derivative token received from AaveV2 (aToken)
    function derivative() public view override returns (address) {
        return getAddress(_DERIVATIVE_SLOT);
    }

    /// @notice The reward token received from AaveV2 (stkAave)
    function reward() public view override returns (address) {
        return getAddress(_REWARD_SLOT);
    }

    function _setBank(address _address) internal {
        setAddress(_BANK_SLOT, _address);
    }

    function _setUnderlying(address _address) internal {
        setAddress(_UNDERLYING_SLOT, _address);
    }

    function _setDerivative(address _address) internal {
        setAddress(_DERIVATIVE_SLOT, _address);
    }

    function _setReward(address _address) internal {
        setAddress(_REWARD_SLOT, _address);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface IBankStorage {
    function paused() external view returns (bool);

    function underlying() external view returns (address);
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

pragma solidity 0.7.6;

interface ISubscriber {
    function registry() external view returns (address);

    function governance() external view returns (address);

    function manager() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface IRegistry {
    function governance() external view returns (address);

    function manager() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

/// @title Oh! Finance Base Upgradeable
/// @notice Contains internal functions to get/set primitive data types used by a proxy contract
abstract contract OhUpgradeable {
    function getAddress(bytes32 slot) internal view returns (address _address) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            _address := sload(slot)
        }
    }

    function getBoolean(bytes32 slot) internal view returns (bool _bool) {
        uint256 bool_;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            bool_ := sload(slot)
        }
        _bool = bool_ == 1;
    }

    function getBytes32(bytes32 slot) internal view returns (bytes32 _bytes32) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            _bytes32 := sload(slot)
        }
    }

    function getUInt256(bytes32 slot) internal view returns (uint256 _uint) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            _uint := sload(slot)
        }
    }

    function setAddress(bytes32 slot, address _address) internal {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, _address)
        }
    }

    function setBytes32(bytes32 slot, bytes32 _bytes32) internal {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, _bytes32)
        }
    }

    /// @dev Set a boolean storage variable in a given slot
    /// @dev Convert to a uint to take up an entire contract storage slot
    function setBoolean(bytes32 slot, bool _bool) internal {
        uint256 bool_ = _bool ? 1 : 0;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, bool_)
        }
    }

    function setUInt256(bytes32 slot, uint256 _uint) internal {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, _uint)
        }
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

pragma solidity 0.7.6;

interface WMOVR {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface MGlimmer {
    function mint() external payable;

    function borrow(uint256 borrowAmount) external returns (uint256);

    function redeem(uint256 redeemTokens) external returns (uint256);

    function redeemUnderlying(uint256 redeemAmount) external returns (uint256);

    function repayBorrow() external payable;

    function repayBorrowBehalf(address borrower) external payable;

    function borrowBalanceCurrent(address account) external returns (uint256);

    function borrowBalanceStored(address account) external view returns (uint256);

    function balanceOfUnderlying(address account) external returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function getAccountSnapshot(address account)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        );
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface MErc20 {
    function underlying() external;

    function mint(uint256 mintAmount) external returns (uint256);

    function redeem(uint256 redeemTokens) external returns (uint256);

    function redeemUnderlying(uint256 redeemAmount) external returns (uint256);

    function borrow(uint256 borrowAmount) external returns (uint256);

    function repayBorrow(uint256 repayAmount) external returns (uint256);

    function exchangeRateStored() external view returns (uint256);

    function getCash() external view returns (uint256);

    function balanceOfUnderlying(address owner) external returns (uint256);

    function borrowBalanceCurrent(address account) external returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface Comptroller {
    function getAccountLiquidity(address account)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );

    function getHypotheticalAccountLiquidity(
        address account,
        address mTokenModify,
        uint256 redeemTokens,
        uint256 borrowAmount
    )
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );

    function claimReward(uint8 rewardType, address holder) external;

    function enterMarkets(address[] calldata mTokens) external returns (uint256[] memory);

    function exitMarket(address mToken) external returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface IMoonwellFoldingStrategyStorage {
    function secondaryReward() external view returns (address);
    
    function comptroller() external view returns (address);

    function folds() external view returns (uint256);

    function collateralFactorNumerator() external view returns (uint256);

    function collateralFactorDenominator() external view returns (uint256);

    function suppliedUnderlying() external view returns (uint256);

    function setSuppliedUnderlying(uint256 suppliedUnderlying_) external;

    function borrowedUnderlying() external view returns (uint256);

    function setBorrowedUnderlying(uint256 borrowedUnderlying_) external;
}