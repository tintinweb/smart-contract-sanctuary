// SPDX-License-Identifier: agpl-3.0

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "../interfaces/IConfigurationManager.sol";
import "../interfaces/IPodOption.sol";
import "../interfaces/IOptionAMMFactory.sol";
import "../interfaces/IOptionAMMPool.sol";

/**
 * @title PodOption
 * @author Pods Finance
 * @notice Represents a Proxy that can perform a set of operations on the behalf of an user
 */
contract OptionHelper {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    /**
     * @dev store globally accessed configurations
     */
    IConfigurationManager public immutable configurationManager;

    event OptionsBought(
        address indexed buyer,
        address indexed optionAddress,
        uint256 optionsBought,
        address inputToken,
        uint256 inputSold
    );

    event OptionsSold(
        address indexed seller,
        address indexed optionAddress,
        uint256 optionsSold,
        address outputToken,
        uint256 outputReceived
    );

    event OptionsMintedAndSold(
        address indexed seller,
        address indexed optionAddress,
        uint256 optionsMintedAndSold,
        address outputToken,
        uint256 outputBought
    );

    event LiquidityAdded(
        address indexed staker,
        address indexed optionAddress,
        uint256 amountOptions,
        address token,
        uint256 tokenAmount
    );

    constructor(IConfigurationManager _configurationManager) public {
        require(
            Address.isContract(address(_configurationManager)),
            "OptionHelper: Configuration Manager is not a contract"
        );
        configurationManager = _configurationManager;
    }

    modifier withinDeadline(uint256 deadline) {
        require(deadline > block.timestamp, "OptionHelper: deadline expired");
        _;
    }

    /**
     * @notice Mint options
     * @dev Mints an amount of options and return to caller
     *
     * @param option The option contract to mint
     * @param optionAmount Amount of options to mint
     */
    function mint(IPodOption option, uint256 optionAmount) external {
        _mint(option, optionAmount);

        // Transfers back the minted options
        IERC20(address(option)).safeTransfer(msg.sender, optionAmount);
    }

    /**
     * @notice Mint and sell options
     * @dev Mints an amount of options and sell it in pool
     *
     * @param option The option contract to mint
     * @param optionAmount Amount of options to mint
     * @param minTokenAmount Minimum amount of output tokens accepted
     * @param deadline The deadline in unix-timestamp that limits the transaction from happening
     * @param initialIVGuess The initial implied volatility guess
     */
    function mintAndSellOptions(
        IPodOption option,
        uint256 optionAmount,
        uint256 minTokenAmount,
        uint256 deadline,
        uint256 initialIVGuess
    ) external withinDeadline(deadline) {
        IOptionAMMPool pool = _getPool(option);

        _mint(option, optionAmount);

        // Approve pool transfer
        IERC20(address(option)).safeApprove(address(pool), optionAmount);

        // Sells options to pool
        uint256 tokensBought = pool.tradeExactAInput(optionAmount, minTokenAmount, msg.sender, initialIVGuess);

        emit OptionsMintedAndSold(msg.sender, address(option), optionAmount, pool.tokenB(), tokensBought);
    }

    /**
     * @notice Mint and add liquidity
     * @dev Mint options and provide them as liquidity to the pool
     *
     * @param option The option contract to mint
     * @param optionAmount Amount of options to mint
     * @param tokenAmount Amount of tokens to provide as liquidity
     */
    function mintAndAddLiquidity(
        IPodOption option,
        uint256 optionAmount,
        uint256 tokenAmount
    ) external {
        IOptionAMMPool pool = _getPool(option);
        IERC20 tokenB = IERC20(pool.tokenB());

        _mint(option, optionAmount);

        if (tokenAmount > 0) {
            // Take stable token from caller
            tokenB.safeTransferFrom(msg.sender, address(this), tokenAmount);
        }

        // Approve pool transfer
        IERC20(address(option)).safeApprove(address(pool), optionAmount);
        tokenB.safeApprove(address(pool), tokenAmount);

        // Adds options and tokens to pool as liquidity
        pool.addLiquidity(optionAmount, tokenAmount, msg.sender);

        emit LiquidityAdded(msg.sender, address(option), optionAmount, pool.tokenB(), tokenAmount);
    }

    /**
     * @notice Add liquidity
     * @dev Provide options as liquidity to the pool
     *
     * @param option The option contract to mint
     * @param optionAmount Amount of options to provide
     * @param tokenAmount Amount of tokens to provide as liquidity
     */
    function addLiquidity(
        IPodOption option,
        uint256 optionAmount,
        uint256 tokenAmount
    ) external {
        IOptionAMMPool pool = _getPool(option);
        IERC20 tokenB = IERC20(pool.tokenB());

        if (optionAmount > 0) {
            // Take options from caller
            IERC20(address(option)).safeTransferFrom(msg.sender, address(this), optionAmount);
        }

        if (tokenAmount > 0) {
            // Take stable token from caller
            tokenB.safeTransferFrom(msg.sender, address(this), tokenAmount);
        }

        // Approve pool transfer
        IERC20(address(option)).safeApprove(address(pool), optionAmount);
        tokenB.safeApprove(address(pool), tokenAmount);

        // Adds options and tokens to pool as liquidity
        pool.addLiquidity(optionAmount, tokenAmount, msg.sender);

        emit LiquidityAdded(msg.sender, address(option), optionAmount, pool.tokenB(), tokenAmount);
    }

    /**
     * @notice Sell exact amount of options
     * @dev Sell an amount of options from pool
     *
     * @param option The option contract to sell
     * @param optionAmount Amount of options to sell
     * @param minTokenReceived Min amount of input tokens to receive
     * @param deadline The deadline in unix-timestamp that limits the transaction from happening
     * @param initialIVGuess The initial implied volatility guess
     */
    function sellExactOptions(
        IPodOption option,
        uint256 optionAmount,
        uint256 minTokenReceived,
        uint256 deadline,
        uint256 initialIVGuess
    ) external withinDeadline(deadline) {
        IOptionAMMPool pool = _getPool(option);
        IERC20 tokenA = IERC20(pool.tokenA());

        // Take input amount from caller
        tokenA.safeTransferFrom(msg.sender, address(this), optionAmount);

        // Approve pool transfer
        tokenA.safeApprove(address(pool), optionAmount);

        // Buys options from pool
        uint256 tokenAmountReceived = pool.tradeExactAInput(optionAmount, minTokenReceived, msg.sender, initialIVGuess);

        emit OptionsSold(msg.sender, address(option), optionAmount, pool.tokenB(), tokenAmountReceived);
    }

    /**
     * @notice Sell estimated amount of options
     * @dev Sell an estimated amount of options to the pool
     *
     * @param option The option contract to sell
     * @param maxOptionAmount max Amount of options to sell
     * @param exactTokenReceived exact amount of input tokens to receive
     * @param deadline The deadline in unix-timestamp that limits the transaction from happening
     * @param initialIVGuess The initial implied volatility guess
     */
    function sellOptionsAndReceiveExactTokens(
        IPodOption option,
        uint256 maxOptionAmount,
        uint256 exactTokenReceived,
        uint256 deadline,
        uint256 initialIVGuess
    ) external withinDeadline(deadline) {
        IOptionAMMPool pool = _getPool(option);
        IERC20 tokenA = IERC20(pool.tokenA());

        // Take input amount from caller
        tokenA.safeTransferFrom(msg.sender, address(this), maxOptionAmount);

        // Approve pool transfer
        tokenA.safeApprove(address(pool), maxOptionAmount);

        // Buys options from pool
        uint256 optionsSold = pool.tradeExactBOutput(exactTokenReceived, maxOptionAmount, msg.sender, initialIVGuess);

        uint256 unusedFunds = maxOptionAmount.sub(optionsSold);

        // Reset allowance
        tokenA.safeApprove(address(pool), 0);

        // Transfer back unused funds
        if (unusedFunds > 0) {
            tokenA.safeTransfer(msg.sender, unusedFunds);
        }

        emit OptionsSold(msg.sender, address(option), optionsSold, pool.tokenB(), exactTokenReceived);
    }

    /**
     * @notice Buy exact amount of options
     * @dev Buys an amount of options from pool
     *
     * @param option The option contract to buy
     * @param optionAmount Amount of options to buy
     * @param maxTokenAmount Max amount of input tokens sold
     * @param deadline The deadline in unix-timestamp that limits the transaction from happening
     * @param initialIVGuess The initial implied volatility guess
     */
    function buyExactOptions(
        IPodOption option,
        uint256 optionAmount,
        uint256 maxTokenAmount,
        uint256 deadline,
        uint256 initialIVGuess
    ) external withinDeadline(deadline) {
        IOptionAMMPool pool = _getPool(option);
        IERC20 tokenB = IERC20(pool.tokenB());

        // Take input amount from caller
        tokenB.safeTransferFrom(msg.sender, address(this), maxTokenAmount);

        // Approve pool transfer
        tokenB.safeApprove(address(pool), maxTokenAmount);

        // Buys options from pool
        uint256 tokensSold = pool.tradeExactAOutput(optionAmount, maxTokenAmount, msg.sender, initialIVGuess);
        uint256 unusedFunds = maxTokenAmount.sub(tokensSold);

        // Reset allowance
        tokenB.safeApprove(address(pool), 0);

        // Transfer back unused funds
        if (unusedFunds > 0) {
            tokenB.safeTransfer(msg.sender, unusedFunds);
        }

        emit OptionsBought(msg.sender, address(option), optionAmount, pool.tokenB(), tokensSold);
    }

    /**
     * @notice Buy estimated amount of options
     * @dev Buys an estimated amount of options from pool
     *
     * @param option The option contract to buy
     * @param minOptionAmount Min amount of options bought
     * @param tokenAmount The exact amount of input tokens sold
     * @param deadline The deadline in unix-timestamp that limits the transaction from happening
     * @param initialIVGuess The initial implied volatility guess
     */
    function buyOptionsWithExactTokens(
        IPodOption option,
        uint256 minOptionAmount,
        uint256 tokenAmount,
        uint256 deadline,
        uint256 initialIVGuess
    ) external withinDeadline(deadline) {
        IOptionAMMPool pool = _getPool(option);
        IERC20 tokenB = IERC20(pool.tokenB());

        // Take input amount from caller
        tokenB.safeTransferFrom(msg.sender, address(this), tokenAmount);

        // Approve pool transfer
        tokenB.safeApprove(address(pool), tokenAmount);

        // Buys options from pool
        uint256 optionsBought = pool.tradeExactBInput(tokenAmount, minOptionAmount, msg.sender, initialIVGuess);

        emit OptionsBought(msg.sender, address(option), optionsBought, pool.tokenB(), tokenAmount);
    }

    /**
     * @dev Mints an amount of tokens collecting the strike tokens from the caller
     *
     * @param option The option contract to mint
     * @param amount The amount of options to mint
     */
    function _mint(IPodOption option, uint256 amount) internal {
        if (option.optionType() == IPodOption.OptionType.PUT) {
            IERC20 strikeAsset = IERC20(option.strikeAsset());
            uint256 strikeToTransfer = option.strikeToTransfer(amount);

            // Take strike asset from caller
            strikeAsset.safeTransferFrom(msg.sender, address(this), strikeToTransfer);

            // Approving strike asset transfer to Option
            strikeAsset.safeApprove(address(option), strikeToTransfer);

            option.mint(amount, msg.sender);
        } else if (option.optionType() == IPodOption.OptionType.CALL) {
            IERC20 underlyingAsset = IERC20(option.underlyingAsset());

            // Take underlying asset from caller
            underlyingAsset.safeTransferFrom(msg.sender, address(this), amount);

            // Approving underlying asset to Option
            underlyingAsset.safeApprove(address(option), amount);

            option.mint(amount, msg.sender);
        }
    }

    /**
     * @dev Returns the AMM Pool associated with the option
     *
     * @param option The option to search for
     * @return IOptionAMMPool
     */
    function _getPool(IPodOption option) internal view returns (IOptionAMMPool) {
        IOptionAMMFactory factory = IOptionAMMFactory(configurationManager.getAMMFactory());
        address exchangeOptionAddress = factory.getPool(address(option));
        require(exchangeOptionAddress != address(0), "OptionHelper: pool not found");
        return IOptionAMMPool(exchangeOptionAddress);
    }
}

pragma solidity ^0.6.0;

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

pragma solidity ^0.6.0;

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
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

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

pragma solidity ^0.6.0;

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
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

pragma solidity ^0.6.2;

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
}

// SPDX-License-Identifier: agpl-3.0

pragma solidity 0.6.12;

interface IConfigurationManager {
    function setParameter(bytes32 name, uint256 value) external;

    function setEmergencyStop(address emergencyStop) external;

    function setPricingMethod(address pricingMethod) external;

    function setIVGuesser(address ivGuesser) external;

    function setIVProvider(address ivProvider) external;

    function setPriceProvider(address priceProvider) external;

    function setCapProvider(address capProvider) external;

    function setAMMFactory(address ammFactory) external;

    function setOptionFactory(address optionFactory) external;

    function setOptionHelper(address optionHelper) external;

    function getParameter(bytes32 name) external view returns (uint256);

    function getEmergencyStop() external view returns (address);

    function getPricingMethod() external view returns (address);

    function getIVGuesser() external view returns (address);

    function getIVProvider() external view returns (address);

    function getPriceProvider() external view returns (address);

    function getCapProvider() external view returns (address);

    function getAMMFactory() external view returns (address);

    function getOptionFactory() external view returns (address);

    function getOptionHelper() external view returns (address);
}

// SPDX-License-Identifier: agpl-3.0

pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IPodOption is IERC20 {
    /** Enums */
    // @dev 0 for Put, 1 for Call
    enum OptionType { PUT, CALL }
    // @dev 0 for European, 1 for American
    enum ExerciseType { EUROPEAN, AMERICAN }

    /** Events */
    event Mint(address indexed minter, uint256 amount);
    event Unmint(address indexed minter, uint256 optionAmount, uint256 strikeAmount, uint256 underlyingAmount);
    event Exercise(address indexed exerciser, uint256 amount);
    event Withdraw(address indexed minter, uint256 strikeAmount, uint256 underlyingAmount);

    /** Functions */

    /**
     * @notice Locks collateral and write option tokens.
     *
     * @dev The issued amount ratio is 1:1, i.e., 1 option token for 1 underlying token.
     *
     * The collateral could be the strike or the underlying asset depending on the option type: Put or Call,
     * respectively
     *
     * It presumes the caller has already called IERC20.approve() on the
     * strike/underlying token contract to move caller funds.
     *
     * Options can only be minted while the series is NOT expired.
     *
     * It is also important to notice that options will be sent back
     * to `msg.sender` and not the `owner`. This behavior is designed to allow
     * proxy contracts to mint on others behalf. The `owner` will be able to remove
     * the deposited collateral after series expiration or by calling unmint(), even
     * if a third-party minted options on its behalf.
     *
     * @param amountOfOptions The amount option tokens to be issued
     * @param owner Which address will be the owner of the options
     */
    function mint(uint256 amountOfOptions, address owner) external;

    /**
     * @notice Allow option token holders to use them to exercise the amount of units
     * of the locked tokens for the equivalent amount of the exercisable assets.
     *
     * @dev It presumes the caller has already called IERC20.approve() exercisable asset
     * to move caller funds.
     *
     * On American options, this function can only called anytime before expiration.
     * For European options, this function can only be called during the exerciseWindow.
     * Meaning, after expiration and before the end of exercise window.
     *
     * @param amountOfOptions The amount option tokens to be exercised
     */
    function exercise(uint256 amountOfOptions) external;

    /**
     * @notice After series expiration in case of American or after exercise window for European,
     * allow minters who have locked their collateral to withdraw them proportionally
     * to their minted options.
     *
     * @dev If assets had been exercised during the option series the minter may withdraw
     * the exercised assets or a combination of exercised and collateral.
     */
    function withdraw() external;

    /**
     * @notice Unlocks collateral by burning option tokens.
     *
     * @dev In case of American options where exercise can happen before the expiration, caller
     * may receive a mix of underlying asset and strike asset.
     *
     * Options can only be burned while the series is NOT expired.
     *
     * @param amountOfOptions The amount option tokens to be burned
     */
    function unmint(uint256 amountOfOptions) external;

    function optionType() external view returns (OptionType);

    function exerciseType() external view returns (ExerciseType);

    function underlyingAsset() external view returns (address);

    function underlyingAssetDecimals() external view returns (uint8);

    function strikeAsset() external view returns (address);

    function strikeAssetDecimals() external view returns (uint8);

    function strikePrice() external view returns (uint256);

    function strikePriceDecimals() external view returns (uint8);

    function expiration() external view returns (uint256);

    function startOfExerciseWindow() external view returns (uint256);

    function hasExpired() external view returns (bool);

    function isTradeWindow() external view returns (bool);

    function isExerciseWindow() external view returns (bool);

    function isWithdrawWindow() external view returns (bool);

    function strikeToTransfer(uint256 amountOfOptions) external view returns (uint256);

    function getSellerWithdrawAmounts(address owner)
        external
        view
        returns (uint256 strikeAmount, uint256 underlyingAmount);

    function underlyingReserves() external view returns (uint256);

    function strikeReserves() external view returns (uint256);
}

// SPDX-License-Identifier: agpl-3.0

pragma solidity 0.6.12;

interface IOptionAMMFactory {
    function createPool(
        address _optionAddress,
        address _stableAsset,
        uint256 _initialSigma
    ) external returns (address);

    function getPool(address _optionAddress) external view returns (address);
}

// SPDX-License-Identifier: agpl-3.0

pragma solidity 0.6.12;

import "./IAMM.sol";

interface IOptionAMMPool is IAMM {
    // @dev 0 for when tokenA enter the pool and B leaving (A -> B)
    // and 1 for the opposite direction
    enum TradeDirection { AB, BA }

    function tradeExactAInput(
        uint256 exactAmountAIn,
        uint256 minAmountBOut,
        address owner,
        uint256 sigmaInitialGuess
    ) external returns (uint256);

    function tradeExactAOutput(
        uint256 exactAmountAOut,
        uint256 maxAmountBIn,
        address owner,
        uint256 sigmaInitialGuess
    ) external returns (uint256);

    function tradeExactBInput(
        uint256 exactAmountBIn,
        uint256 minAmountAOut,
        address owner,
        uint256 sigmaInitialGuess
    ) external returns (uint256);

    function tradeExactBOutput(
        uint256 exactAmountBOut,
        uint256 maxAmountAIn,
        address owner,
        uint256 sigmaInitialGuess
    ) external returns (uint256);

    function getOptionTradeDetailsExactAInput(uint256 exactAmountAIn)
        external
        view
        returns (
            uint256 amountBOutput,
            uint256 newSigma,
            uint256 feesTokenA,
            uint256 feesTokenB
        );

    function getOptionTradeDetailsExactAOutput(uint256 exactAmountAOut)
        external
        view
        returns (
            uint256 amountBInput,
            uint256 newSigma,
            uint256 feesTokenA,
            uint256 feesTokenB
        );

    function getOptionTradeDetailsExactBInput(uint256 exactAmountBIn)
        external
        view
        returns (
            uint256 amountAOutput,
            uint256 newSigma,
            uint256 feesTokenA,
            uint256 feesTokenB
        );

    function getOptionTradeDetailsExactBOutput(uint256 exactAmountBOut)
        external
        view
        returns (
            uint256 amountAInput,
            uint256 newSigma,
            uint256 feesTokenA,
            uint256 feesTokenB
        );

    function getRemoveLiquidityAmounts(
        uint256 percentA,
        uint256 percentB,
        address user
    ) external view returns (uint256 withdrawAmountA, uint256 withdrawAmountB);

    function getABPrice() external view returns (uint256);

    function getAdjustedIV() external view returns (uint256);
}

// SPDX-License-Identifier: agpl-3.0

pragma solidity 0.6.12;

interface IAMM {
    function addLiquidity(
        uint256 amountOfA,
        uint256 amountOfB,
        address owner
    ) external;

    function removeLiquidity(uint256 amountOfA, uint256 amountOfB) external;

    function tokenA() external view returns (address);

    function tokenB() external view returns (address);

    function tokenADecimals() external view returns (uint8);

    function tokenBDecimals() external view returns (uint8);
}

