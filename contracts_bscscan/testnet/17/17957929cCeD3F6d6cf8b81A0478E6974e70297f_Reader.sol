// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../libraries/token/IERC20.sol";
import "../libraries/math/SafeMath.sol";

import "../core/interfaces/IVault.sol";
import "../core/interfaces/IVaultPriceFeed.sol";
import "../tokens/interfaces/IYieldTracker.sol";
import "../tokens/interfaces/IYieldToken.sol";
import "../amm/interfaces/IPancakeFactory.sol";

contract Reader {
    using SafeMath for uint256;

    uint256 public constant BASIS_POINTS_DIVISOR = 10000;
    uint256 public constant PRICE_PRECISION = 10 ** 30;
    uint256 public constant USDF_DECIMALS = 18;

    function getMaxAmountOutBeforeDebtExceeded(IVault _vault, address _token) public view returns (uint256) {
        uint256 maxDebtBasisPoints = _vault.maxDebtBasisPoints();
        uint256 redemptionCollateralUsd = _vault.getRedemptionCollateralUsd(_token);
        uint256 usdfDebt = _vault.usdfAmounts(_token).mul(PRICE_PRECISION).div(10 ** USDF_DECIMALS);
        if (redemptionCollateralUsd.mul(maxDebtBasisPoints) < BASIS_POINTS_DIVISOR.mul(usdfDebt)) {
            return 0;
        }
        uint256 maxUsdAmount = redemptionCollateralUsd.mul(maxDebtBasisPoints).sub(BASIS_POINTS_DIVISOR.mul(usdfDebt)).div(maxDebtBasisPoints.sub(BASIS_POINTS_DIVISOR));
        uint256 price = _vault.getMaxPrice(_token);
        uint256 tokenDecimals = _vault.tokenDecimals(_token);
        return maxUsdAmount.mul(10 ** tokenDecimals).div(price);
    }

    function getMaxAmountIn(IVault _vault, address _tokenIn, address _tokenOut) public view returns (uint256) {
        uint256 priceIn = _vault.getMinPrice(_tokenIn);
        uint256 priceOut = _vault.getMaxPrice(_tokenOut);
        uint256 poolAmount = _vault.poolAmounts(_tokenOut);
        uint256 reservedAmount = _vault.reservedAmounts(_tokenOut);
        uint256 availableAmount = poolAmount.sub(reservedAmount);

        if (!_vault.stableTokens(_tokenOut)) {
            uint256 maxAmountOut = getMaxAmountOutBeforeDebtExceeded(_vault, _tokenOut);

            if (maxAmountOut < availableAmount) {
                availableAmount = maxAmountOut;
            }
        }

        uint256 amountIn = availableAmount.mul(priceOut).div(priceIn);
        return _vault.adjustForDecimals(amountIn, _tokenOut, _tokenIn);
    }

    function getAmountOut(IVault _vault, address _tokenIn, address _tokenOut, uint256 _amountIn) public view returns (uint256, uint256) {
        uint256 priceIn = _vault.getMinPrice(_tokenIn);
        uint256 priceOut = _vault.getMaxPrice(_tokenOut);
        uint256 amountOut = _amountIn.mul(priceIn).div(priceOut);
        bool isStableSwap = _vault.stableTokens(_tokenIn) && _vault.stableTokens(_tokenOut);
        uint256 feeBasisPoints = isStableSwap ? _vault.stableSwapFeeBasisPoints() : _vault.swapFeeBasisPoints();
        uint256 amountOutAfterFees = amountOut.mul(BASIS_POINTS_DIVISOR.sub(feeBasisPoints)).div(BASIS_POINTS_DIVISOR);
        uint256 feeAmount = amountOut.sub(amountOutAfterFees);

        return (amountOutAfterFees, feeAmount);
    }

    function getFees(address _vault, address[] memory _tokens) public view returns (uint256[] memory) {
        uint256[] memory amounts = new uint256[](_tokens.length);
        for (uint256 i = 0; i < _tokens.length; i++) {
            amounts[i] = IVault(_vault).feeReserves(_tokens[i]);
        }
        return amounts;
    }

    function getTotalStaked(address[] memory _yieldTokens) public view returns (uint256[] memory) {
        uint256[] memory amounts = new uint256[](_yieldTokens.length);
        for (uint256 i = 0; i < _yieldTokens.length; i++) {
            IYieldToken yieldToken = IYieldToken(_yieldTokens[i]);
            amounts[i] = yieldToken.totalStaked();
        }
        return amounts;
    }

    function getStakingInfo(address _account, address[] memory _yieldTrackers) public view returns (uint256[] memory) {
        uint256 propsLength = 2;
        uint256[] memory amounts = new uint256[](_yieldTrackers.length * propsLength);
        for (uint256 i = 0; i < _yieldTrackers.length; i++) {
            IYieldTracker yieldTracker = IYieldTracker(_yieldTrackers[i]);
            amounts[i * propsLength] = yieldTracker.claimable(_account);
            amounts[i * propsLength + 1] = yieldTracker.getTokensPerInterval();
        }
        return amounts;
    }

    function getPairInfo(address _factory, address[] memory _tokens) public view returns (uint256[] memory) {
        uint256 inputLength = 2;
        uint256 propsLength = 2;
        uint256[] memory amounts = new uint256[](_tokens.length / inputLength * propsLength);
        for (uint256 i = 0; i < _tokens.length / inputLength; i++) {
            address token0 = _tokens[i * inputLength];
            address token1 = _tokens[i * inputLength + 1];
            address pair = IPancakeFactory(_factory).getPair(token0, token1);

            amounts[i * propsLength] = IERC20(token0).balanceOf(pair);
            amounts[i * propsLength + 1] = IERC20(token1).balanceOf(pair);
        }
        return amounts;
    }

    function getFundingRates(address _vault, address _weth, address[] memory _tokens) public view returns (uint256[] memory) {
        uint256 propsLength = 2;
        uint256[] memory fundingRates = new uint256[](_tokens.length * propsLength);
        IVault vault = IVault(_vault);
        uint256 fundingRateFactor = vault.fundingRateFactor();

        for (uint256 i = 0; i < _tokens.length; i++) {
            address token = _tokens[i];
            if (token == address(0)) {
                token = _weth;
            }
            uint256 reservedAmount = vault.reservedAmounts(token);
            uint256 poolAmount = vault.poolAmounts(token);

            if (poolAmount > 0) {
                fundingRates[i * propsLength] = fundingRateFactor.mul(reservedAmount).div(poolAmount);
            }

            if (vault.cumulativeFundingRates(token) > 0) {
                uint256 nextRate = vault.getNextFundingRate(token);
                uint256 baseRate = vault.cumulativeFundingRates(token);
                fundingRates[i * propsLength + 1] = baseRate.add(nextRate);
            }
        }

        return fundingRates;
    }

    function getTokenSupply(IERC20 _token, address[] memory _excludedAccounts) public view returns (uint256) {
        uint256 supply = _token.totalSupply();
        for (uint256 i = 0; i < _excludedAccounts.length; i++) {
            address account = _excludedAccounts[i];
            uint256 balance = _token.balanceOf(account);
            supply = supply.sub(balance);
        }
        return supply;
    }

    function getTokenBalances(address _account, address[] memory _tokens) public view returns (uint256[] memory) {
        uint256[] memory balances = new uint256[](_tokens.length);
        for (uint256 i = 0; i < _tokens.length; i++) {
            address token = _tokens[i];
            if (token == address(0)) {
                balances[i] = _account.balance;
                continue;
            }
            balances[i] = IERC20(token).balanceOf(_account);
        }
        return balances;
    }

    function getTokenBalancesWithSupplies(address _account, address[] memory _tokens) public view returns (uint256[] memory) {
        uint256 propsLength = 2;
        uint256[] memory balances = new uint256[](_tokens.length * propsLength);
        for (uint256 i = 0; i < _tokens.length; i++) {
            address token = _tokens[i];
            if (token == address(0)) {
                balances[i * propsLength] = _account.balance;
                balances[i * propsLength + 1] = 0;
                continue;
            }
            balances[i * propsLength] = IERC20(token).balanceOf(_account);
            balances[i * propsLength + 1] = IERC20(token).totalSupply();
        }
        return balances;
    }

    function getVaultTokenInfo(address _vault, address _weth, uint256 _usdfAmount, address[] memory _tokens) public view returns (uint256[] memory) {
        uint256 propsLength = 9;

        IVault vault = IVault(_vault);
        IVaultPriceFeed priceFeed = IVaultPriceFeed(vault.priceFeed());

        uint256[] memory amounts = new uint256[](_tokens.length * propsLength);
        for (uint256 i = 0; i < _tokens.length; i++) {
            address token = _tokens[i];
            if (token == address(0)) {
                token = _weth;
            }
            amounts[i * propsLength] = vault.poolAmounts(token);
            amounts[i * propsLength + 1] = vault.reservedAmounts(token);
            amounts[i * propsLength + 2] = vault.usdfAmounts(token);
            amounts[i * propsLength + 3] = vault.getRedemptionAmount(token, _usdfAmount);
            amounts[i * propsLength + 4] = vault.getMinPrice(token);
            amounts[i * propsLength + 5] = vault.getMaxPrice(token);
            amounts[i * propsLength + 6] = vault.guaranteedUsd(token);
            amounts[i * propsLength + 7] = priceFeed.getPrice(token, false, false);
            amounts[i * propsLength + 8] = priceFeed.getPrice(token, true, false);
        }

        return amounts;
    }

    function getPositions(address _vault, address _account, address[] memory _collateralTokens, address[] memory _indexTokens, bool[] memory _isLong) public view returns(uint256[] memory) {
        uint256 propsLength = 8;
        uint256[] memory amounts = new uint256[](_collateralTokens.length * propsLength);

        for (uint256 i = 0; i < _collateralTokens.length; i++) {
            {
            (uint256 size,
             uint256 collateral,
             uint256 averagePrice,
             uint256 entryFundingRate,
             /* reserveAmount */,
             uint256 realisedPnl,
             bool hasRealisedProfit) = IVault(_vault).getPosition(_account, _collateralTokens[i], _indexTokens[i], _isLong[i]);

            amounts[i * propsLength] = size;
            amounts[i * propsLength + 1] = collateral;
            amounts[i * propsLength + 2] = averagePrice;
            amounts[i * propsLength + 3] = entryFundingRate;
            amounts[i * propsLength + 4] = hasRealisedProfit ? 1 : 0;
            amounts[i * propsLength + 5] = realisedPnl;
            }

            uint256 size = amounts[i * propsLength];
            uint256 averagePrice = amounts[i * propsLength + 2];
            if (averagePrice > 0) {
                (bool hasProfit, uint256 delta) = IVault(_vault).getDelta(_indexTokens[i], size, averagePrice, _isLong[i]);
                amounts[i * propsLength + 6] = hasProfit ? 1 : 0;
                amounts[i * propsLength + 7] = delta;
            }
        }

        return amounts;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

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

pragma solidity 0.6.12;

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

pragma solidity 0.6.12;

interface IVault {
    function maxDebtBasisPoints() external view returns (uint256);
    function setMaxDebtBasisPoints(uint256 _maxDebtBasisPoints) external;
    function getRedemptionCollateralUsd(address _token) external view returns (uint256);
    function setIsMintingEnabled(bool _isMintingEnabled) external;
    function setIsSwapEnabled(bool _isSwapEnabled) external;
    function adjustForDecimals(uint256 _amount, address _tokenDiv, address _tokenMul) external view returns (uint256);

    function setFees(
        uint256 _swapFeeBasisPoints,
        uint256 _stableSwapFeeBasisPoints,
        uint256 _marginFeeBasisPoints,
        uint256 _liquidationFeeUsd
    ) external;

    function setTokenConfig(
        address _token,
        uint256 _tokenDecimals,
        uint256 _redemptionBps,
        uint256 _minProfitBps,
        bool _isStable,
        bool _isShortable
    ) external;

    function setPriceFeed(address _priceFeed) external;
    function setMaxUsdf(uint256 _maxUsdfBatchSize, uint256 _maxUsdfBuffer) external;
    function setMaxGasPrice(uint256 _maxGasPrice) external;
    function withdrawFees(address _token, address _receiver) external returns (uint256);

    function directPoolDeposit(address _token) external;
    function buyUSDF(address _token, address _receiver) external returns (uint256);
    function sellUSDF(address _token, address _receiver) external returns (uint256);
    function swap(address _tokenIn, address _tokenOut, address _receiver) external returns (uint256);
    function increasePosition(address _account, address _collateralToken, address _indexToken, uint256 _sizeDelta, bool _isLong) external;
    function decreasePosition(address _account, address _collateralToken, address _indexToken, uint256 _collateralDelta, uint256 _sizeDelta, bool _isLong, address _receiver) external returns (uint256);
    function tokenToUsdMin(address _token, uint256 _tokenAmount) external view returns (uint256);

    function priceFeed() external view returns (address);
    function fundingRateFactor() external view returns (uint256);
    function cumulativeFundingRates(address _token) external view returns (uint256);
    function getNextFundingRate(address _token) external view returns (uint256);

    function swapFeeBasisPoints() external view returns (uint256);
    function stableSwapFeeBasisPoints() external view returns (uint256);

    function stableTokens(address _token) external view returns (bool);
    function shortableTokens(address _token) external view returns (bool);
    function feeReserves(address _token) external view returns (uint256);
    function tokenDecimals(address _token) external view returns (uint256);
    function redemptionBasisPoints(address _token) external view returns (uint256);
    function guaranteedUsd(address _token) external view returns (uint256);
    function poolAmounts(address _token) external view returns (uint256);
    function reservedAmounts(address _token) external view returns (uint256);
    function usdfAmounts(address _token) external view returns (uint256);
    function getRedemptionAmount(address _token, uint256 _usdfAmount) external view returns (uint256);
    function getMaxPrice(address _token) external view returns (uint256);
    function getMinPrice(address _token) external view returns (uint256);

    function getDelta(address _indexToken, uint256 _size, uint256 _averagePrice, bool _isLong) external view returns (bool, uint256);
    function getPosition(address _account, address _collateralToken, address _indexToken, bool _isLong) external view returns (uint256, uint256, uint256, uint256, uint256, uint256, bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IVaultPriceFeed {
    function setUseV2Pricing(bool _useV2Pricing) external;
    function setIsAmmEnabled(bool _isEnabled) external;
    function setIsSecondaryPriceEnabled(bool _isEnabled) external;
    function setSpreadBasisPoints(address _token, uint256 _spreadBasisPoints) external;
    function setSpreadThresholdBasisPoints(uint256 _spreadThresholdBasisPoints) external;
    function setFavorPrimaryPrice(bool _favorPrimaryPrice) external;
    function setPriceSampleSpace(uint256 _priceSampleSpace) external;
    function setMaxStrictPriceDeviation(uint256 _maxStrictPriceDeviation) external;
    function getPrice(address _token, bool _maximise, bool _includeAmmPrice) external view returns (uint256);
    function getAmmPrice(address _token) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IYieldTracker {
    function claim(address _account, address _receiver) external returns (uint256);
    function updateRewards(address _account) external;
    function getTokensPerInterval() external view returns (uint256);
    function claimable(address _account) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IYieldToken {
    function totalStaked() external view returns (uint256);
    function stakedBalance(address _account) external view returns (uint256);
    function removeAdmin(address _account) external;
}

//SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IPancakeFactory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}