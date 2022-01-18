// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import "../TempusPool.sol";
import "../protocols/rari/IRariFundManager.sol";
import "../utils/UntrustedERC20.sol";
import "../math/Fixed256xVar.sol";

contract RariTempusPool is TempusPool {
    using SafeERC20 for IERC20;
    using UntrustedERC20 for IERC20;
    using Fixed256xVar for uint256;

    bytes32 public constant override protocolName = "Rari";
    IRariFundManager private immutable rariFundManager;

    uint256 private immutable exchangeRateToBackingPrecision;
    uint256 private immutable backingTokenRariPoolIndex;
    uint256 private lastCalculatedInterestRate;

    constructor(
        IRariFundManager fundManager,
        address backingToken,
        address controller,
        uint256 maturity,
        uint256 estYield,
        TokenData memory principalsData,
        TokenData memory yieldsData,
        FeesConfig memory maxFeeSetup
    )
        TempusPool(
            fundManager.rariFundToken(),
            backingToken,
            controller,
            maturity,
            calculateInterestRate(
                fundManager,
                fundManager.rariFundToken(),
                getTokenRariPoolIndex(fundManager, backingToken)
            ),
            /*exchangeRateOne:*/
            1e18,
            estYield,
            principalsData,
            yieldsData,
            maxFeeSetup
        )
    {
        /// As for now, Rari's Yield Bearing Tokens are always 18 decimals and throughout this contract we're using some
        /// hard-coded 18 decimal logic for simplification and optimization of some of the calculations.
        /// Therefore, non 18 decimal YBT are not with this current version.
        require(
            IERC20Metadata(yieldBearingToken).decimals() == 18,
            "only 18 decimal Rari Yield Bearing Tokens are supported"
        );

        uint256 backingTokenIndex = getTokenRariPoolIndex(fundManager, backingToken);

        uint8 underlyingDecimals = IERC20Metadata(backingToken).decimals();
        require(underlyingDecimals <= 18, "underlying decimals must be <= 18");

        exchangeRateToBackingPrecision = 10**(18 - underlyingDecimals);
        backingTokenRariPoolIndex = backingTokenIndex;
        rariFundManager = fundManager;

        updateInterestRate();
    }

    function depositToUnderlying(uint256 amount) internal override returns (uint256) {
        // ETH deposits are not accepted, because it is rejected in the controller
        assert(msg.value == 0);

        // Deposit to Rari Pool
        IERC20(backingToken).safeIncreaseAllowance(address(rariFundManager), amount);

        uint256 preDepositBalance = IERC20(yieldBearingToken).balanceOf(address(this));
        rariFundManager.deposit(IERC20Metadata(backingToken).symbol(), amount);
        uint256 postDepositBalance = IERC20(yieldBearingToken).balanceOf(address(this));

        return (postDepositBalance - preDepositBalance);
    }

    function withdrawFromUnderlyingProtocol(uint256 yieldBearingTokensAmount, address recipient)
        internal
        override
        returns (uint256 backingTokenAmount)
    {
        uint256 rftTotalSupply = IERC20(yieldBearingToken).totalSupply();
        uint256 withdrawalAmountUsd = (yieldBearingTokensAmount * rariFundManager.getFundBalance()) / rftTotalSupply;

        uint256 backingTokenToUsdRate = rariFundManager.rariFundPriceConsumer().getCurrencyPricesInUsd()[
            backingTokenRariPoolIndex
        ];

        uint256 withdrawalAmountInBackingToken = withdrawalAmountUsd.mulfV(backingTokenONE, backingTokenToUsdRate);
        /// Checks if there were any rounding errors; If so - subtracts 1 (this essentially ensures we never round up)
        if (withdrawalAmountInBackingToken.mulfV(backingTokenToUsdRate, backingTokenONE) > withdrawalAmountUsd) {
            withdrawalAmountInBackingToken -= 1;
        }

        uint256 preDepositBalance = IERC20(backingToken).balanceOf(address(this));
        rariFundManager.withdraw(IERC20Metadata(backingToken).symbol(), withdrawalAmountInBackingToken);
        uint256 amountWithdrawn = IERC20(backingToken).balanceOf(address(this)) - preDepositBalance;

        return IERC20(backingToken).untrustedTransfer(recipient, amountWithdrawn);
    }

    /// @return Updated current Interest Rate with the same precision as the BackingToken
    function updateInterestRate() internal override returns (uint256) {
        lastCalculatedInterestRate = calculateInterestRate(
            rariFundManager,
            yieldBearingToken,
            backingTokenRariPoolIndex
        );

        require(lastCalculatedInterestRate > 0, "Calculated rate is too small");

        return lastCalculatedInterestRate;
    }

    /// @return Stored Interest Rate with the same precision as the BackingToken
    function currentInterestRate() public view override returns (uint256) {
        return lastCalculatedInterestRate;
    }

    function numAssetsPerYieldToken(uint yieldTokens, uint rate) public view override returns (uint) {
        return yieldTokens.mulfV(rate, exchangeRateONE) / exchangeRateToBackingPrecision;
    }

    function numYieldTokensPerAsset(uint backingTokens, uint rate) public view override returns (uint) {
        return backingTokens.divfV(rate, exchangeRateONE) * exchangeRateToBackingPrecision;
    }

    /// @dev The rate precision is always 18
    function interestRateToSharePrice(uint interestRate) internal view override returns (uint) {
        return interestRate / exchangeRateToBackingPrecision;
    }

    /// We need to duplicate this, because the Rari protocol does not expose it.
    ///
    /// Based on https://github.com/Rari-Capital/rari-stable-pool-contracts/blob/386aa8811e7f12c2908066ae17af923758503739/contracts/RariFundManager.sol#L580
    function calculateInterestRate(
        IRariFundManager fundManager,
        address ybToken,
        uint256 currencyIndex
    ) private returns (uint256) {
        uint256 backingTokenToUsdRate = fundManager.rariFundPriceConsumer().getCurrencyPricesInUsd()[currencyIndex];
        uint256 rftTotalSupply = IERC20(ybToken).totalSupply();
        uint256 fundBalanceUsd = rftTotalSupply > 0 ? fundManager.getFundBalance() : 0; // Only set if used

        uint256 preFeeRate;
        if (rftTotalSupply > 0 && fundBalanceUsd > 0) {
            preFeeRate = backingTokenToUsdRate.mulfV(fundBalanceUsd, rftTotalSupply);
        } else {
            preFeeRate = backingTokenToUsdRate;
        }

        /// Apply fee
        uint256 postFeeRate = preFeeRate.mulfV(1e18 - fundManager.getWithdrawalFeeRate(), 1e18);

        return postFeeRate;
    }

    function getTokenRariPoolIndex(IRariFundManager fundManager, address bToken) private view returns (uint256) {
        string[] memory acceptedSymbols = fundManager.getAcceptedCurrencies();
        string memory backingTokenSymbol = IERC20Metadata(bToken).symbol();

        for (uint256 i = 0; i < acceptedSymbols.length; i++) {
            if (keccak256(bytes(backingTokenSymbol)) == keccak256(bytes(acceptedSymbols[i]))) {
                return i;
            }
        }

        revert("backing token is not accepted by the rari pool");
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./ITempusPool.sol";
import "./token/PrincipalShare.sol";
import "./token/YieldShare.sol";
import "./math/Fixed256xVar.sol";
import "./utils/Ownable.sol";
import "./utils/UntrustedERC20.sol";
import "./utils/Versioned.sol";

/// @dev helper struct to store name and symbol for the token
struct TokenData {
    string name;
    string symbol;
}

/// @author The tempus.finance team
/// @title Implementation of Tempus Pool
abstract contract TempusPool is ITempusPool, ReentrancyGuard, Ownable, Versioned {
    using SafeERC20 for IERC20;
    using UntrustedERC20 for IERC20;
    using Fixed256xVar for uint256;

    uint256 public constant override maximumNegativeYieldDuration = 7 days;

    address public immutable override yieldBearingToken;
    address public immutable override backingToken;

    uint256 public immutable override startTime;
    uint256 public immutable override maturityTime;
    uint256 public override exceptionalHaltTime = type(uint256).max;

    uint256 public immutable override initialInterestRate;
    uint256 public override maturityInterestRate;

    uint256 public immutable exchangeRateONE;
    uint256 public immutable yieldBearingONE;
    uint256 public immutable override backingTokenONE;

    IPoolShare public immutable override principalShare;
    IPoolShare public immutable override yieldShare;

    address public immutable override controller;

    uint256 private immutable initialEstimatedYield;

    FeesConfig private feesConfig;
    uint256 public immutable override maxDepositFee;
    uint256 public immutable override maxEarlyRedeemFee;
    uint256 public immutable override maxMatureRedeemFee;
    uint256 public override totalFees;

    /// Timestamp when the negative yield period was entered.
    uint256 private negativeYieldStartTime;

    /// Constructs Pool with underlying token, start and maturity date
    /// @param _yieldBearingToken Yield Bearing Token, such as cDAI or aUSDC
    /// @param _backingToken backing token (or zero address if ETH)
    /// @param ctrl The authorized TempusController of the pool
    /// @param maturity maturity time of this pool
    /// @param initInterestRate initial interest rate of the pool
    /// @param exchangeRateOne 1.0 expressed in exchange rate decimal precision
    /// @param estimatedFinalYield estimated yield for the whole lifetime of the pool
    /// @param principalsData Tempus Principals name and symbol
    /// @param yieldsData Tempus Yields name and symbol
    /// @param maxFeeSetup Maximum fee percentages that this pool can have,
    ///                    values in Yield Bearing Token precision
    constructor(
        address _yieldBearingToken,
        address _backingToken,
        address ctrl,
        uint256 maturity,
        uint256 initInterestRate,
        uint256 exchangeRateOne,
        uint256 estimatedFinalYield,
        TokenData memory principalsData,
        TokenData memory yieldsData,
        FeesConfig memory maxFeeSetup
    ) Versioned(1, 0, 0) {
        require(maturity > block.timestamp, "maturityTime is after startTime");
        require(ctrl != address(0), "controller can not be zero");
        require(initInterestRate > 0, "initInterestRate can not be zero");
        require(estimatedFinalYield > 0, "estimatedFinalYield can not be zero");
        require(_yieldBearingToken != address(0), "YBT can not be zero");

        yieldBearingToken = _yieldBearingToken;
        backingToken = _backingToken;
        controller = ctrl;
        startTime = block.timestamp;
        maturityTime = maturity;
        initialInterestRate = initInterestRate;
        exchangeRateONE = exchangeRateOne;
        yieldBearingONE = 10**ERC20(_yieldBearingToken).decimals();
        initialEstimatedYield = estimatedFinalYield;

        maxDepositFee = maxFeeSetup.depositPercent;
        maxEarlyRedeemFee = maxFeeSetup.earlyRedeemPercent;
        maxMatureRedeemFee = maxFeeSetup.matureRedeemPercent;

        uint8 backingDecimals = _backingToken != address(0) ? IERC20Metadata(_backingToken).decimals() : 18;
        backingTokenONE = 10**backingDecimals;
        principalShare = new PrincipalShare(this, principalsData.name, principalsData.symbol, backingDecimals);
        yieldShare = new YieldShare(this, yieldsData.name, yieldsData.symbol, backingDecimals);
    }

    modifier onlyController() {
        require(msg.sender == controller, "Only callable by TempusController");
        _;
    }

    function depositToUnderlying(uint256 backingAmount) internal virtual returns (uint256 mintedYieldTokenAmount);

    function withdrawFromUnderlyingProtocol(uint256 amount, address recipient)
        internal
        virtual
        returns (uint256 backingTokenAmount);

    function matured() public view override returns (bool) {
        return (block.timestamp >= maturityTime) || (block.timestamp >= exceptionalHaltTime);
    }

    function getFeesConfig() external view override returns (FeesConfig memory) {
        return feesConfig;
    }

    function setFeesConfig(FeesConfig calldata newFeesConfig) external override onlyOwner {
        require(newFeesConfig.depositPercent <= maxDepositFee, "Deposit fee percent > max");
        require(newFeesConfig.earlyRedeemPercent <= maxEarlyRedeemFee, "Early redeem fee percent > max");
        require(newFeesConfig.matureRedeemPercent <= maxMatureRedeemFee, "Mature redeem fee percent > max");
        feesConfig = newFeesConfig;
    }

    function transferFees(address recipient) external override nonReentrant onlyOwner {
        uint256 amount = totalFees;
        totalFees = 0;

        IERC20 token = IERC20(yieldBearingToken);
        token.safeTransfer(recipient, amount);
    }

    function onDepositBacking(uint256 backingTokenAmount, address recipient)
        external
        payable
        override
        onlyController
        returns (
            uint256 mintedShares,
            uint256 depositedYBT,
            uint256 fee,
            uint256 rate
        )
    {
        // Enforced by the controller.
        assert(backingTokenAmount > 0);

        depositedYBT = depositToUnderlying(backingTokenAmount);
        assert(depositedYBT > 0);

        (mintedShares, , fee, rate) = mintShares(depositedYBT, recipient);
    }

    function onDepositYieldBearing(uint256 yieldTokenAmount, address recipient)
        external
        override
        onlyController
        returns (
            uint256 mintedShares,
            uint256 depositedBT,
            uint256 fee,
            uint256 rate
        )
    {
        // Enforced by the controller.
        assert(yieldTokenAmount > 0);

        (mintedShares, depositedBT, fee, rate) = mintShares(yieldTokenAmount, recipient);
    }

    /// @param yieldTokenAmount YBT amount in YBT decimal precision
    /// @param recipient address to which shares will be minted
    function mintShares(uint256 yieldTokenAmount, address recipient)
        private
        returns (
            uint256 mintedShares,
            uint256 depositedBT,
            uint256 fee,
            uint256 rate
        )
    {
        rate = updateInterestRate();
        (bool hasMatured, bool hasNegativeYield) = validateInterestRate(rate);

        require(!hasMatured, "Maturity reached.");
        require(!hasNegativeYield, "Negative yield!");

        // Collect fees if they are set, reducing the number of tokens for the sender
        // thus leaving more YBT in the TempusPool than there are minted TPS/TYS
        uint256 tokenAmount = yieldTokenAmount;
        uint256 depositFees = feesConfig.depositPercent;
        if (depositFees != 0) {
            fee = tokenAmount.mulfV(depositFees, yieldBearingONE);
            tokenAmount -= fee;
            totalFees += fee;
        }

        // Issue appropriate shares
        depositedBT = numAssetsPerYieldToken(tokenAmount, rate);
        mintedShares = numSharesToMint(depositedBT, rate);

        PrincipalShare(address(principalShare)).mint(recipient, mintedShares);
        YieldShare(address(yieldShare)).mint(recipient, mintedShares);
    }

    function redeemToBacking(
        address from,
        uint256 principalAmount,
        uint256 yieldAmount,
        address recipient
    )
        external
        payable
        override
        onlyController
        returns (
            uint256 redeemedYieldTokens,
            uint256 redeemedBackingTokens,
            uint256 fee,
            uint256 rate
        )
    {
        (redeemedYieldTokens, fee, rate) = burnShares(from, principalAmount, yieldAmount);

        redeemedBackingTokens = withdrawFromUnderlyingProtocol(redeemedYieldTokens, recipient);
    }

    function redeem(
        address from,
        uint256 principalAmount,
        uint256 yieldAmount,
        address recipient
    )
        external
        override
        onlyController
        returns (
            uint256 redeemedYieldTokens,
            uint256 fee,
            uint256 rate
        )
    {
        (redeemedYieldTokens, fee, rate) = burnShares(from, principalAmount, yieldAmount);

        redeemedYieldTokens = IERC20(yieldBearingToken).untrustedTransfer(recipient, redeemedYieldTokens);
    }

    function finalize() public override {
        if (matured() && maturityInterestRate == 0) {
            maturityInterestRate = updateInterestRate();
        }
    }

    function burnShares(
        address from,
        uint256 principalAmount,
        uint256 yieldAmount
    )
        private
        returns (
            uint256 redeemedYieldTokens,
            uint256 fee,
            uint256 interestRate
        )
    {
        require(IERC20(address(principalShare)).balanceOf(from) >= principalAmount, "Insufficient principals.");
        require(IERC20(address(yieldShare)).balanceOf(from) >= yieldAmount, "Insufficient yields.");

        uint256 currentRate = updateInterestRate();
        (bool hasMatured, ) = validateInterestRate(currentRate);

        if (hasMatured) {
            finalize();
        } else {
            // Redeeming prior to maturity is only allowed in equal amounts.
            require(principalAmount == yieldAmount, "Inequal redemption not allowed before maturity.");
        }
        // Burn the appropriate shares
        PrincipalShare(address(principalShare)).burnFrom(from, principalAmount);
        YieldShare(address(yieldShare)).burnFrom(from, yieldAmount);

        (redeemedYieldTokens, , fee, interestRate) = getRedemptionAmounts(principalAmount, yieldAmount, currentRate);
        totalFees += fee;
    }

    function getRedemptionAmounts(
        uint256 principalAmount,
        uint256 yieldAmount,
        uint256 currentRate
    )
        private
        view
        returns (
            uint256 redeemableYieldTokens,
            uint256 redeemableBackingTokens,
            uint256 redeemFeeAmount,
            uint256 interestRate
        )
    {
        interestRate = effectiveRate(currentRate);

        if (interestRate < initialInterestRate) {
            redeemableBackingTokens = (principalAmount * interestRate) / initialInterestRate;
        } else {
            uint256 rateDiff = interestRate - initialInterestRate;
            // this is expressed in percent with exchangeRate precision
            uint256 yieldPercent = rateDiff.divfV(initialInterestRate, exchangeRateONE);
            uint256 redeemAmountFromYieldShares = yieldAmount.mulfV(yieldPercent, exchangeRateONE);

            redeemableBackingTokens = principalAmount + redeemAmountFromYieldShares;

            // after maturity, all additional yield is being collected as fee
            if (matured() && currentRate > interestRate) {
                uint256 additionalYieldRate = currentRate - interestRate;
                uint256 feeBackingAmount = yieldAmount.mulfV(
                    additionalYieldRate.mulfV(initialInterestRate, exchangeRateONE),
                    exchangeRateONE
                );
                redeemFeeAmount = numYieldTokensPerAsset(feeBackingAmount, currentRate);
            }
        }

        redeemableYieldTokens = numYieldTokensPerAsset(redeemableBackingTokens, currentRate);

        uint256 redeemFeePercent = matured() ? feesConfig.matureRedeemPercent : feesConfig.earlyRedeemPercent;
        if (redeemFeePercent != 0) {
            uint256 regularRedeemFee = redeemableYieldTokens.mulfV(redeemFeePercent, yieldBearingONE);
            redeemableYieldTokens -= regularRedeemFee;
            redeemFeeAmount += regularRedeemFee;

            redeemableBackingTokens = numAssetsPerYieldToken(redeemableYieldTokens, currentRate);
        }
    }

    function effectiveRate(uint256 currentRate) private view returns (uint256) {
        if (matured() && maturityInterestRate != 0) {
            return (currentRate < maturityInterestRate) ? currentRate : maturityInterestRate;
        } else {
            return currentRate;
        }
    }

    /// @dev Calculates current yield - since beginning of the pool
    /// @notice Includes principal, so in case of 5% yield it returns 1.05
    /// @param interestRate Current interest rate of the underlying protocol
    /// @return Current yield relative to 1, such as 1.05 (+5%) or 0.97 (-3%)
    function currentYield(uint256 interestRate) private view returns (uint256) {
        return effectiveRate(interestRate).divfV(initialInterestRate, exchangeRateONE);
    }

    function currentYield() private returns (uint256) {
        return currentYield(updateInterestRate());
    }

    function currentYieldStored() private view returns (uint256) {
        return currentYield(currentInterestRate());
    }

    function estimatedYieldStored() private view returns (uint256) {
        return estimatedYield(currentYieldStored());
    }

    /// @dev Calculates estimated yield at maturity
    /// @notice Includes principal, so in case of 5% yield it returns 1.05
    /// @param yieldCurrent Current yield - since beginning of the pool
    /// @return Estimated yield at maturity relative to 1, such as 1.05 (+5%) or 0.97 (-3%)
    function estimatedYield(uint256 yieldCurrent) private view returns (uint256) {
        if (matured()) {
            return yieldCurrent;
        }
        uint256 currentTime = block.timestamp;
        uint256 timeToMaturity;
        uint256 poolDuration;
        unchecked {
            timeToMaturity = (maturityTime > currentTime) ? (maturityTime - currentTime) : 0;
            poolDuration = maturityTime - startTime;
        }
        uint256 timeLeft = timeToMaturity.divfV(poolDuration, exchangeRateONE);

        return yieldCurrent + timeLeft.mulfV(initialEstimatedYield, exchangeRateONE);
    }

    /// pricePerYield = currentYield * (estimatedYield - 1) / (estimatedYield)
    /// Return value decimal precision in backing token precision
    function pricePerYieldShare(uint256 currYield, uint256 estYield) private view returns (uint256) {
        uint one = exchangeRateONE;
        // in case we have estimate for negative yield
        if (estYield < one) {
            return uint256(0);
        }
        uint256 yieldPrice = (estYield - one).mulfV(currYield, one).divfV(estYield, one);
        return interestRateToSharePrice(yieldPrice);
    }

    /// pricePerPrincipal = currentYield / estimatedYield
    /// Return value decimal precision in backing token precision
    function pricePerPrincipalShare(uint256 currYield, uint256 estYield) private view returns (uint256) {
        // in case we have estimate for negative yield
        if (estYield < exchangeRateONE) {
            return interestRateToSharePrice(currYield);
        }
        uint256 principalPrice = currYield.divfV(estYield, exchangeRateONE);
        return interestRateToSharePrice(principalPrice);
    }

    function pricePerYieldShare() external override returns (uint256) {
        uint256 yield = currentYield();
        return pricePerYieldShare(yield, estimatedYield(yield));
    }

    function pricePerYieldShareStored() external view override returns (uint256) {
        uint256 yield = currentYieldStored();
        return pricePerYieldShare(yield, estimatedYield(yield));
    }

    function pricePerPrincipalShare() external override returns (uint256) {
        uint256 yield = currentYield();
        return pricePerPrincipalShare(yield, estimatedYield(yield));
    }

    function pricePerPrincipalShareStored() external view override returns (uint256) {
        uint256 yield = currentYieldStored();
        return pricePerPrincipalShare(yield, estimatedYield(yield));
    }

    function numSharesToMint(uint256 depositedBT, uint256 currentRate) private view returns (uint256) {
        return (depositedBT * initialInterestRate) / currentRate;
    }

    function estimatedMintedShares(uint256 amount, bool isBackingToken) external view override returns (uint256) {
        uint256 currentRate = currentInterestRate();
        uint256 depositedBT = isBackingToken ? amount : numAssetsPerYieldToken(amount, currentRate);
        return numSharesToMint(depositedBT, currentRate);
    }

    function estimatedRedeem(
        uint256 principals,
        uint256 yields,
        bool toBackingToken
    ) external view override returns (uint256) {
        uint256 currentRate = currentInterestRate();
        (uint256 yieldTokens, uint256 backingTokens, , ) = getRedemptionAmounts(principals, yields, currentRate);
        return toBackingToken ? backingTokens : yieldTokens;
    }

    /// @dev This updates the internal tracking of negative yield periods,
    ///      and returns the current status of maturity and interest rates.
    function validateInterestRate(uint256 rate) private returns (bool hasMatured, bool hasNegativeYield) {
        // Short circuit. No need for the below after maturity.
        if (matured()) {
            return (true, rate < initialInterestRate);
        }

        if (rate >= initialInterestRate) {
            // Reset period.
            negativeYieldStartTime = 0;
            return (false, false);
        }

        if (negativeYieldStartTime == 0) {
            // Entering a negative yield period.
            negativeYieldStartTime = block.timestamp;
            return (false, true);
        }

        if ((negativeYieldStartTime + maximumNegativeYieldDuration) <= block.timestamp) {
            // Already in a negative yield period, exceeding the duration.
            exceptionalHaltTime = block.timestamp;
            // It is considered matured now because exceptionalHaltTime is set.
            assert(matured());
            return (true, true);
        }

        // Already in negative yield period, but not for long enough.
        return (false, true);
    }

    /// @dev This updates the underlying pool's interest rate
    ///      It should be done first thing before deposit/redeem to avoid arbitrage
    /// @return Updated current Interest Rate, decimal precision depends on specific TempusPool implementation
    function updateInterestRate() internal virtual returns (uint256);

    /// @dev This returns the stored Interest Rate of the YBT (Yield Bearing Token) pool
    ///      it is safe to call this after updateInterestRate() was called
    /// @return Stored Interest Rate, decimal precision depends on specific TempusPool implementation
    function currentInterestRate() public view virtual override returns (uint256);

    function numYieldTokensPerAsset(uint backingTokens, uint interestRate) public view virtual override returns (uint);

    function numAssetsPerYieldToken(uint yieldTokens, uint interestRate) public view virtual override returns (uint);

    /// @return Converts an interest rate decimal into a Principal/Yield Share decimal
    function interestRateToSharePrice(uint interestRate) internal view virtual returns (uint);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.10;

import "./IRariFundPriceConsumer.sol";

/// @notice based on https://github.com/Rari-Capital/rari-stable-pool-contracts/blob/386aa8811e7f12c2908066ae17af923758503739/contracts/RariFundManager.sol
interface IRariFundManager {
    /// @dev Deposits an `amount` of Backing Tokens into pool
    /// @param currencyCode The symbol of the token to be deposited
    /// @param amount The amount of Backing Tokens to be deposited
    function deposit(string calldata currencyCode, uint256 amount) external;

    /// @dev Withdraws an `amount` of Backing Tokens from the pool
    /// @param currencyCode The symbol of the token to withdraw
    /// @param amount The amount of Backing Tokens to withdraw
    /// @return The amount of Backing Tokens that were withdrawn afeter fee deductions (if fees are enabled)
    function withdraw(string calldata currencyCode, uint256 amount) external returns (uint256);

    /// @return Total amount of Backing Tokens in control of the pool
    function getFundBalance() external returns (uint256);

    /// @return The Rari Fund Price Consumer address that is used by the pool
    function rariFundPriceConsumer() external view returns (IRariFundPriceConsumer);

    /// @return The pool's Yield Bearing Token (Fund Token)
    function rariFundToken() external view returns (address);

    /// @return An array of the symbols of the currencies supported by the pool
    function getAcceptedCurrencies() external view returns (string[] memory);

    /// @return Withdrawal Fee Rate (in 18 decimal precision)
    function getWithdrawalFeeRate() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @title UntrustedERC20
/// @dev Wrappers around ERC20 transfer operators that return the actual amount
/// transferred. This means they are usable with tokens, which charge a fee or royalty on transfer.
library UntrustedERC20 {
    using SafeERC20 for IERC20;

    /// Transfer tokens to a recipient.
    /// @param token The ERC20 token.
    /// @param to The recipient.
    /// @param value The requested amount.
    /// @return The actual amount of tokens transferred.
    function untrustedTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal returns (uint256) {
        uint256 startBalance = token.balanceOf(to);
        token.safeTransfer(to, value);
        return token.balanceOf(to) - startBalance;
    }

    /// Transfer tokens to a recipient.
    /// @param token The ERC20 token.
    /// @param from The sender.
    /// @param to The recipient.
    /// @param value The requested amount.
    /// @return The actual amount of tokens transferred.
    function untrustedTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal returns (uint256) {
        uint256 startBalance = token.balanceOf(to);
        token.safeTransferFrom(from, to, value);
        return token.balanceOf(to) - startBalance;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

/// @dev Fixed Point decimal math utils for variable decimal point precision
///      on 256-bit wide numbers
library Fixed256xVar {
    /// @dev Multiplies two variable precision fixed point decimal numbers
    /// @param one 1.0 expressed in the base precision of `a` and `b`
    /// @return result = a * b
    function mulfV(
        uint256 a,
        uint256 b,
        uint256 one
    ) internal pure returns (uint256) {
        // result is always truncated
        return (a * b) / one;
    }

    /// @dev Divides two variable precision fixed point decimal numbers
    /// @param one 1.0 expressed in the base precision of `a` and `b`
    /// @return result = a / b
    function divfV(
        uint256 a,
        uint256 b,
        uint256 one
    ) internal pure returns (uint256) {
        // result is always truncated
        return (a * one) / b;
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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

    constructor() {
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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.7.6 <0.9.0;
pragma abicoder v2;

import "./token/IPoolShare.sol";
import "./utils/IOwnable.sol";
import "./utils/IVersioned.sol";

/// Setting and transferring of fees are restricted to the owner.
interface ITempusFees is IOwnable {
    /// The fees are in terms of yield bearing token (YBT).
    struct FeesConfig {
        uint256 depositPercent;
        uint256 earlyRedeemPercent;
        uint256 matureRedeemPercent;
    }

    /// Returns the current fee configuration.
    function getFeesConfig() external view returns (FeesConfig memory);

    /// Replace the current fee configuration with a new one.
    /// By default all the fees are expected to be set to zero.
    /// @notice This function can only be called by the owner.
    function setFeesConfig(FeesConfig calldata newFeesConfig) external;

    /// @return Maximum possible fee percentage that can be set for deposit
    function maxDepositFee() external view returns (uint256);

    /// @return Maximum possible fee percentage that can be set for early redeem
    function maxEarlyRedeemFee() external view returns (uint256);

    /// @return Maximum possible fee percentage that can be set for mature redeem
    function maxMatureRedeemFee() external view returns (uint256);

    /// Accumulated fees available for withdrawal.
    function totalFees() external view returns (uint256);

    /// Transfers accumulated Yield Bearing Token (YBT) fees
    /// from this pool contract to `recipient`.
    /// @param recipient Address which will receive the specified amount of YBT
    /// @notice This function can only be called by the owner.
    function transferFees(address recipient) external;
}

/// All state changing operations are restricted to the controller.
interface ITempusPool is ITempusFees, IVersioned {
    /// @return The name of underlying protocol, for example "Aave" for Aave protocol
    function protocolName() external view returns (bytes32);

    /// This token will be used as a token that user can deposit to mint same amounts
    /// of principal and interest shares.
    /// @return The underlying yield bearing token.
    function yieldBearingToken() external view returns (address);

    /// This is the address of the actual backing asset token
    /// in the case of ETH, this address will be 0
    /// @return Address of the Backing Token
    function backingToken() external view returns (address);

    /// @return uint256 value of one backing token, in case of 18 decimals 1e18
    function backingTokenONE() external view returns (uint256);

    /// @return This TempusPool's Tempus Principal Share (TPS)
    function principalShare() external view returns (IPoolShare);

    /// @return This TempusPool's Tempus Yield Share (TYS)
    function yieldShare() external view returns (IPoolShare);

    /// @return The TempusController address that is authorized to perform restricted actions
    function controller() external view returns (address);

    /// @return Start time of the pool.
    function startTime() external view returns (uint256);

    /// @return Maturity time of the pool.
    function maturityTime() external view returns (uint256);

    /// @return Time of exceptional halting of the pool.
    /// In case the pool is still in operation, this must return type(uint256).max.
    function exceptionalHaltTime() external view returns (uint256);

    /// @return The maximum allowed time (in seconds) to pass with negative yield.
    function maximumNegativeYieldDuration() external view returns (uint256);

    /// @return True if maturity has been reached and the pool was finalized.
    ///         This also includes the case when maturity was triggered due to
    ///         exceptional conditions (negative yield periods).
    function matured() external view returns (bool);

    /// Finalizes the pool. This can only happen on or after `maturityTime`.
    /// Once finalized depositing is not possible anymore, and the behaviour
    /// redemption will change.
    ///
    /// Can be called by anyone and can be called multiple times.
    function finalize() external;

    /// Yield bearing tokens deposit hook.
    /// @notice Deposit will fail if maturity has been reached.
    /// @notice This function can only be called by TempusController
    /// @notice This function assumes funds were already transferred to the TempusPool from the TempusController
    /// @param yieldTokenAmount Amount of yield bearing tokens to deposit in YieldToken decimal precision
    /// @param recipient Address which will receive Tempus Principal Shares (TPS) and Tempus Yield Shares (TYS)
    /// @return mintedShares Amount of TPS and TYS minted to `recipient`
    /// @return depositedBT The YBT value deposited, denominated as Backing Tokens
    /// @return fee The fee which was deducted (in terms of YBT)
    /// @return rate The interest rate at the time of the deposit
    function onDepositYieldBearing(uint256 yieldTokenAmount, address recipient)
        external
        returns (
            uint256 mintedShares,
            uint256 depositedBT,
            uint256 fee,
            uint256 rate
        );

    /// Backing tokens deposit hook.
    /// @notice Deposit will fail if maturity has been reached.
    /// @notice This function can only be called by TempusController
    /// @notice This function assumes funds were already transferred to the TempusPool from the TempusController
    /// @param backingTokenAmount amount of Backing Tokens to be deposited to underlying protocol in BackingToken decimal precision
    /// @param recipient Address which will receive Tempus Principal Shares (TPS) and Tempus Yield Shares (TYS)
    /// @return mintedShares Amount of TPS and TYS minted to `recipient`
    /// @return depositedYBT The BT value deposited, denominated as Yield Bearing Tokens
    /// @return fee The fee which was deducted (in terms of YBT)
    /// @return rate The interest rate at the time of the deposit
    function onDepositBacking(uint256 backingTokenAmount, address recipient)
        external
        payable
        returns (
            uint256 mintedShares,
            uint256 depositedYBT,
            uint256 fee,
            uint256 rate
        );

    /// Redeems yield bearing tokens from this TempusPool
    ///      msg.sender will receive the YBT
    ///      NOTE #1 Before maturity, principalAmount must equal to yieldAmount.
    ///      NOTE #2 This function can only be called by TempusController
    /// @param from Address to redeem its Tempus Shares
    /// @param principalAmount Amount of Tempus Principal Shares (TPS) to redeem for YBT in PrincipalShare decimal precision
    /// @param yieldAmount Amount of Tempus Yield Shares (TYS) to redeem for YBT in YieldShare decimal precision
    /// @param recipient Address to which redeemed YBT will be sent
    /// @return redeemableYieldTokens Amount of Yield Bearing Tokens redeemed to `recipient`
    /// @return fee The fee which was deducted (in terms of YBT)
    /// @return rate The interest rate at the time of the redemption
    function redeem(
        address from,
        uint256 principalAmount,
        uint256 yieldAmount,
        address recipient
    )
        external
        returns (
            uint256 redeemableYieldTokens,
            uint256 fee,
            uint256 rate
        );

    /// Redeems TPS+TYS held by msg.sender into backing tokens
    ///      `msg.sender` must approve TPS and TYS amounts to this TempusPool.
    ///      `msg.sender` will receive the backing tokens
    ///      NOTE #1 Before maturity, principalAmount must equal to yieldAmount.
    ///      NOTE #2 This function can only be called by TempusController
    /// @param from Address to redeem its Tempus Shares
    /// @param principalAmount Amount of Tempus Principal Shares (TPS) to redeem in PrincipalShare decimal precision
    /// @param yieldAmount Amount of Tempus Yield Shares (TYS) to redeem in YieldShare decimal precision
    /// @param recipient Address to which redeemed BT will be sent
    /// @return redeemableYieldTokens Amount of Backing Tokens redeemed to `recipient`, denominated in YBT
    /// @return redeemableBackingTokens Amount of Backing Tokens redeemed to `recipient`
    /// @return fee The fee which was deducted (in terms of YBT)
    /// @return rate The interest rate at the time of the redemption
    function redeemToBacking(
        address from,
        uint256 principalAmount,
        uint256 yieldAmount,
        address recipient
    )
        external
        payable
        returns (
            uint256 redeemableYieldTokens,
            uint256 redeemableBackingTokens,
            uint256 fee,
            uint256 rate
        );

    /// Gets the estimated amount of Principals and Yields after a successful deposit
    /// @param amount Amount of BackingTokens or YieldBearingTokens that would be deposited
    /// @param isBackingToken If true, @param amount is in BackingTokens, otherwise YieldBearingTokens
    /// @return Amount of Principals (TPS) and Yields (TYS) in Principal/YieldShare decimal precision
    ///         TPS and TYS are minted in 1:1 ratio, hence a single return value.
    function estimatedMintedShares(uint256 amount, bool isBackingToken) external view returns (uint256);

    /// Gets the estimated amount of YieldBearingTokens or BackingTokens received when calling `redeemXXX()` functions
    /// @param principals Amount of Principals (TPS) in PrincipalShare decimal precision
    /// @param yields Amount of Yields (TYS) in YieldShare decimal precision
    /// @param toBackingToken If true, redeem amount is estimated in BackingTokens instead of YieldBearingTokens
    /// @return Amount of YieldBearingTokens or BackingTokens in YBT/BT decimal precision
    function estimatedRedeem(
        uint256 principals,
        uint256 yields,
        bool toBackingToken
    ) external view returns (uint256);

    /// @dev This returns the stored Interest Rate of the YBT (Yield Bearing Token) pool
    ///      it is safe to call this after updateInterestRate() was called
    /// @return Stored Interest Rate, decimal precision depends on specific TempusPool implementation
    function currentInterestRate() external view returns (uint256);

    /// @return Initial interest rate of the underlying pool,
    ///         decimal precision depends on specific TempusPool implementation
    function initialInterestRate() external view returns (uint256);

    /// @return Interest rate at maturity of the underlying pool (or 0 if maturity not reached yet)
    ///         decimal precision depends on specific TempusPool implementation
    function maturityInterestRate() external view returns (uint256);

    /// @return Rate of one Tempus Yield Share expressed in Asset Tokens
    function pricePerYieldShare() external returns (uint256);

    /// @return Rate of one Tempus Principal Share expressed in Asset Tokens
    function pricePerPrincipalShare() external returns (uint256);

    /// Calculated with stored interest rates
    /// @return Rate of one Tempus Yield Share expressed in Asset Tokens,
    function pricePerYieldShareStored() external view returns (uint256);

    /// Calculated with stored interest rates
    /// @return Rate of one Tempus Principal Share expressed in Asset Tokens
    function pricePerPrincipalShareStored() external view returns (uint256);

    /// @dev This returns actual Backing Token amount for amount of YBT (Yield Bearing Tokens)
    ///      For example, in case of Aave and Lido the result is 1:1,
    ///      and for compound is `yieldTokens * currentInterestRate`
    /// @param yieldTokens Amount of YBT in YBT decimal precision
    /// @param interestRate The current interest rate
    /// @return Amount of Backing Tokens for specified @param yieldTokens
    function numAssetsPerYieldToken(uint yieldTokens, uint interestRate) external view returns (uint);

    /// @dev This returns amount of YBT (Yield Bearing Tokens) that can be converted
    ///      from @param backingTokens Backing Tokens
    /// @param backingTokens Amount of Backing Tokens in BT decimal precision
    /// @param interestRate The current interest rate
    /// @return Amount of YBT for specified @param backingTokens
    function numYieldTokensPerAsset(uint backingTokens, uint interestRate) external view returns (uint);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "./PoolShare.sol";

/// @dev Token representing the principal shares of a pool.
contract PrincipalShare is PoolShare {
    constructor(
        ITempusPool _pool,
        string memory name,
        string memory symbol,
        uint8 decimals
    ) PoolShare(ShareKind.Principal, _pool, name, symbol, decimals) {}

    // solhint-disable-previous-line no-empty-blocks

    function getPricePerFullShare() external override returns (uint256) {
        return pool.pricePerPrincipalShare();
    }

    function getPricePerFullShareStored() external view override returns (uint256) {
        return pool.pricePerPrincipalShareStored();
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "./PoolShare.sol";

/// @dev Token representing the yield shares of a pool.
contract YieldShare is PoolShare {
    constructor(
        ITempusPool _pool,
        string memory name,
        string memory symbol,
        uint8 decimals
    ) PoolShare(ShareKind.Yield, _pool, name, symbol, decimals) {}

    // solhint-disable-previous-line no-empty-blocks

    function getPricePerFullShare() external override returns (uint256) {
        return pool.pricePerYieldShare();
    }

    function getPricePerFullShareStored() external view override returns (uint256) {
        return pool.pricePerYieldShareStored();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./IOwnable.sol";

/// Implements Ownable with a two step transfer of ownership
abstract contract Ownable is IOwnable {
    address private _owner;
    address private _proposedOwner;

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(msg.sender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual override returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Proposes a transfer of ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual override onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _proposedOwner = newOwner;
        emit OwnershipProposed(_owner, _proposedOwner);
    }

    /**
     * @dev Accepts ownership of the contract by a proposed account.
     * Can only be called by the proposed owner.
     */
    function acceptOwnership() public virtual override {
        require(msg.sender == _proposedOwner, "Ownable: Only proposed owner can accept ownership");
        _setOwner(_proposedOwner);
        _proposedOwner = address(0);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.6 <0.9.0;

import "./IVersioned.sol";

/// Implements versioning
abstract contract Versioned is IVersioned {
    uint16 private immutable _major;
    uint16 private immutable _minor;
    uint16 private immutable _patch;

    constructor(
        uint16 major,
        uint16 minor,
        uint16 patch
    ) {
        _major = major;
        _minor = minor;
        _patch = patch;
    }

    function version() external view returns (Version memory) {
        return Version(_major, _minor, _patch);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.7.6 <0.9.0;

import "../ITempusPool.sol";

/// Interface of Tokens representing the principal or yield shares of a pool.
interface IPoolShare {
    enum ShareKind {
        Principal,
        Yield
    }

    /// @return The kind of the share.
    function kind() external view returns (ShareKind);

    /// @return The pool this share is part of.
    function pool() external view returns (ITempusPool);

    /// @dev Price per single share expressed in Backing Tokens of the underlying pool.
    ///      This is for the purpose of TempusAMM api support.
    ///      Example: exchanging Tempus Yield Share to DAI
    /// @return 1e18 decimal conversion rate per share
    function getPricePerFullShare() external returns (uint256);

    /// @return 1e18 decimal stored conversion rate per share
    function getPricePerFullShareStored() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.6 <0.9.0;

/// Implements Ownable with a two step transfer of ownership
interface IOwnable {
    /**
     * @dev Change of ownership proposed.
     * @param currentOwner The current owner.
     * @param proposedOwner The proposed owner.
     */
    event OwnershipProposed(address indexed currentOwner, address indexed proposedOwner);

    /**
     * @dev Ownership transferred.
     * @param previousOwner The previous owner.
     * @param newOwner The new owner.
     */
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() external view returns (address);

    /**
     * @dev Proposes a transfer of ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) external;

    /**
     * @dev Accepts ownership of the contract by a proposed account.
     * Can only be called by the proposed owner.
     */
    function acceptOwnership() external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.6 <0.9.0;
pragma abicoder v2;

/// Implements versioning
interface IVersioned {
    struct Version {
        uint16 major;
        uint16 minor;
        uint16 patch;
    }

    /// @return The version of the contract.
    function version() external view returns (Version memory);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "./ERC20OwnerMintableToken.sol";
import "../ITempusPool.sol";

/// Token representing the principal or yield shares of a pool.
abstract contract PoolShare is IPoolShare, ERC20OwnerMintableToken {
    /// The kind of the share.
    ShareKind public immutable override kind;

    /// The pool this share is part of.
    ITempusPool public immutable override pool;

    uint8 internal immutable tokenDecimals;

    constructor(
        ShareKind _kind,
        ITempusPool _pool,
        string memory name,
        string memory symbol,
        uint8 _decimals
    ) ERC20OwnerMintableToken(name, symbol) {
        kind = _kind;
        pool = _pool;
        tokenDecimals = _decimals;
    }

    function decimals() public view virtual override returns (uint8) {
        return tokenDecimals;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// This is a simplified implementation, but compatible with
/// OpenZeppelin's ERC20Mintable and ERC20Burnable extensions.
contract ERC20OwnerMintableToken is ERC20 {
    /// The manager who is allowed to mint and burn.
    address public immutable manager;

    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        manager = msg.sender;
    }

    /// Creates `amount` new tokens for `to`.
    /// @param account Recipient address to mint tokens to
    /// @param amount Number of tokens to mint
    function mint(address account, uint256 amount) external {
        require(msg.sender == manager, "mint: only manager can mint");
        _mint(account, amount);
    }

    /// Destroys `amount` tokens from the caller.
    /// @param amount Number of tokens to burn.
    function burn(uint256 amount) external {
        require(msg.sender == manager, "burn: only manager can burn");
        _burn(manager, amount);
    }

    /// Destroys `amount` tokens from `account`.
    /// @param account Source address to burn tokens from
    /// @param amount Number of tokens to burn
    function burnFrom(address account, uint256 amount) external {
        require(msg.sender == manager, "burn: only manager can burn");
        _burn(account, amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
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
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
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
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

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
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
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
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.10;

/// @notice based on https://github.com/Rari-Capital/rari-stable-pool-contracts/blob/386aa8811e7f12c2908066ae17af923758503739/contracts/RariFundPriceConsumer.sol
interface IRariFundPriceConsumer {
    /// @dev The ordering of the returned currencies is hardcoded here - https://github.com/Rari-Capital/rari-stable-pool-contracts/blob/386aa8811e7f12c2908066ae17af923758503739/contracts/RariFundPriceConsumer.sol#L111
    /// @return the price of each supported currency in USD (scaled by 1e18).
    /// `IRariFundManager.getAcceptedCurrencies()` returns the supported currency symbols.
    /// Each `IRariFundManager` has an associated `IRariFundPriceConsumer`, and the prices
    /// returned here correspond to those currencies, in the same order.
    function getCurrencyPricesInUsd() external view returns (uint256[] memory);
}