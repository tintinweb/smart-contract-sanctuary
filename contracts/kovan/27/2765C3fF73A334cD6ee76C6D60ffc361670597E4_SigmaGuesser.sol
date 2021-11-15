// SPDX-License-Identifier: agpl-3.0

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "../interfaces/IBlackScholes.sol";
import "../interfaces/IPodOption.sol";
import "../interfaces/ISigmaGuesser.sol";
import "../interfaces/IConfigurationManager.sol";

contract SigmaGuesser is ISigmaGuesser {
    using SafeMath for uint256;
    IBlackScholes private immutable _blackScholes;

    /**
     * @dev store globally accessed configurations
     */
    IConfigurationManager public immutable configurationManager;

    /**
     * @dev numerical method's acceptable range
     */
    uint256 public acceptableRange;

    /**
     * @dev Min numerical method's acceptable range
     */
    uint256 public constant MIN_ACCEPTABLE_RANGE = 10; //10%

    struct Boundaries {
        uint256 sigmaLower;
        uint256 priceLower;
        uint256 sigmaHigher;
        uint256 priceHigher;
    }

    constructor(IConfigurationManager _configurationManager, address blackScholes) public {
        require(blackScholes != address(0), "Sigma: Invalid blackScholes");

        configurationManager = _configurationManager;

        acceptableRange = _configurationManager.getParameter("GUESSER_ACCEPTABLE_RANGE");

        require(acceptableRange >= MIN_ACCEPTABLE_RANGE, "Sigma: Invalid acceptableRange");

        _blackScholes = IBlackScholes(blackScholes);
    }

    function blackScholes() external override view returns (address) {
        return address(_blackScholes);
    }

    function getPutSigma(
        uint256 _targetPrice,
        uint256 _sigmaInitialGuess,
        uint256 _spotPrice,
        uint256 _strikePrice,
        uint256 _timeToMaturity,
        int256 _riskFree
    ) external override view returns (uint256 calculatedSigma, uint256 calculatedPrice) {
        (calculatedSigma, calculatedPrice) = getSigma(
            _targetPrice,
            _sigmaInitialGuess,
            _spotPrice,
            _strikePrice,
            _timeToMaturity,
            _riskFree,
            IPodOption.OptionType.PUT
        );
        return (calculatedSigma, calculatedPrice);
    }

    function getCallSigma(
        uint256 _targetPrice,
        uint256 _sigmaInitialGuess,
        uint256 _spotPrice,
        uint256 _strikePrice,
        uint256 _timeToMaturity,
        int256 _riskFree
    ) external override view returns (uint256 calculatedSigma, uint256 calculatedPrice) {
        (calculatedSigma, calculatedPrice) = getSigma(
            _targetPrice,
            _sigmaInitialGuess,
            _spotPrice,
            _strikePrice,
            _timeToMaturity,
            _riskFree,
            IPodOption.OptionType.CALL
        );
        return (calculatedSigma, calculatedPrice);
    }

    function getCloserSigma(Boundaries memory boundaries, uint256 targetPrice) external pure returns (uint256) {
        return _getCloserSigma(boundaries, targetPrice);
    }

    /**
     * Get an approximation of sigma given a target price inside an error range
     *
     * @param _targetPrice The target price that we need to find the sigma for
     * @param _sigmaInitialGuess sigma guess in order to reduce gas costs
     * @param _spotPrice Current spot price of the underlying
     * @param _strikePrice Option strike price
     * @param _timeToMaturity Annualized time to maturity
     * @param _riskFree The risk-free rate
     * @param _optionType the option type (0 for PUt, 1 for Call)
     * @return calculatedSigma The new sigma found given _targetPrice and inside ACCEPTABLE_ERROR
     * @return calculatedPrice That is the real price found, in the best scenario, calculated price should
     * be equal to _targetPrice
     */
    function getSigma(
        uint256 _targetPrice,
        uint256 _sigmaInitialGuess,
        uint256 _spotPrice,
        uint256 _strikePrice,
        uint256 _timeToMaturity,
        int256 _riskFree,
        IPodOption.OptionType _optionType
    ) public view returns (uint256 calculatedSigma, uint256 calculatedPrice) {
        require(_sigmaInitialGuess > 0, "Sigma: initial guess should be greater than zero");
        uint256 calculatedInitialPrice = _getPrice(
            _spotPrice,
            _strikePrice,
            _sigmaInitialGuess,
            _timeToMaturity,
            _riskFree,
            _optionType
        );
        if (_equalEnough(_targetPrice, calculatedInitialPrice, acceptableRange)) {
            return (_sigmaInitialGuess, calculatedInitialPrice);
        } else {
            Boundaries memory boundaries = _getInitialBoundaries(
                _targetPrice,
                calculatedInitialPrice,
                _sigmaInitialGuess,
                _spotPrice,
                _strikePrice,
                _timeToMaturity,
                _riskFree,
                _optionType
            );
            calculatedSigma = _getCloserSigma(boundaries, _targetPrice);
            calculatedPrice = _getPrice(
                _spotPrice,
                _strikePrice,
                calculatedSigma,
                _timeToMaturity,
                _riskFree,
                _optionType
            );

            while (_equalEnough(_targetPrice, calculatedPrice, acceptableRange) == false) {
                if (calculatedPrice < _targetPrice) {
                    boundaries.priceLower = calculatedPrice;
                    boundaries.sigmaLower = calculatedSigma;
                } else {
                    boundaries.priceHigher = calculatedPrice;
                    boundaries.sigmaHigher = calculatedSigma;
                }
                calculatedSigma = _getCloserSigma(boundaries, _targetPrice);

                calculatedPrice = _getPrice(
                    _spotPrice,
                    _strikePrice,
                    calculatedSigma,
                    _timeToMaturity,
                    _riskFree,
                    _optionType
                );
            }
            return (calculatedSigma, calculatedPrice);
        }
    }

    /**********************************************************************************************
    // Each time you run this function, returns you a closer sigma value to the target price p0   //
    // getCloserSigma                                                                             //
    // sL = sigmaLower                                                                            //
    // sH = sigmaHigher                                 ( sH - sL )                               //
    // pL = priceLower          sN = sL + ( p0 - pL ) * -----------                               //
    // pH = priceHigher                                 ( pH - pL )                               //
    // p0 = targetPrice                                                                           //
    // sN = sigmaNext                                                                             //
    **********************************************************************************************/
    function _getCloserSigma(Boundaries memory boundaries, uint256 targetPrice) internal pure returns (uint256) {
        uint256 numerator = targetPrice.sub(boundaries.priceLower).mul(
            boundaries.sigmaHigher.sub(boundaries.sigmaLower)
        );
        uint256 denominator = boundaries.priceHigher.sub(boundaries.priceLower);

        uint256 result = numerator.div(denominator);
        uint256 nextSigma = boundaries.sigmaLower.add(result);
        return nextSigma;
    }

    function _getPrice(
        uint256 _spotPrice,
        uint256 _strikePrice,
        uint256 calculatedSigma,
        uint256 _timeToMaturity,
        int256 _riskFree,
        IPodOption.OptionType _optionType
    ) internal view returns (uint256 price) {
        if (_optionType == IPodOption.OptionType.PUT) {
            price = _blackScholes.getPutPrice(_spotPrice, _strikePrice, calculatedSigma, _timeToMaturity, _riskFree);
        } else {
            price = _blackScholes.getCallPrice(_spotPrice, _strikePrice, calculatedSigma, _timeToMaturity, _riskFree);
        }
        return price;
    }

    function _equalEnough(
        uint256 target,
        uint256 value,
        uint256 range
    ) internal pure returns (bool) {
        uint256 proportion = target / range;
        if (target > value) {
            uint256 diff = target - value;
            return diff <= proportion;
        } else {
            uint256 diff = value - target;
            return diff <= proportion;
        }
    }

    function _getInitialBoundaries(
        uint256 _targetPrice,
        uint256 initialPrice,
        uint256 initialSigma,
        uint256 _spotPrice,
        uint256 _strikePrice,
        uint256 _timeToMaturity,
        int256 _riskFree,
        IPodOption.OptionType _optionType
    ) internal view returns (Boundaries memory b) {
        b.sigmaLower = 0;
        b.priceLower = 0;
        uint256 newGuessPrice = initialPrice;
        uint256 newGuessSigma = initialSigma;

        // nextGuessSigma = nextTryPrice
        while (newGuessPrice < _targetPrice) {
            b.sigmaLower = newGuessSigma;
            b.priceLower = newGuessPrice;

            // it keep increasing the currentSigma in 150% until it finds a new higher boundary
            newGuessSigma = newGuessSigma.add(newGuessSigma.div(2));
            newGuessPrice = _getPrice(_spotPrice, _strikePrice, newGuessSigma, _timeToMaturity, _riskFree, _optionType);
        }
        b.sigmaHigher = newGuessSigma;
        b.priceHigher = newGuessPrice;
    }

    /**
     * @notice Update acceptableRange calling configuratorManager
     */
    function updateAcceptableRange() external override {
        acceptableRange = configurationManager.getParameter("GUESSER_ACCEPTABLE_RANGE");
        require(acceptableRange >= MIN_ACCEPTABLE_RANGE, "Sigma: Invalid acceptableRange");
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

// SPDX-License-Identifier: agpl-3.0

pragma solidity 0.6.12;

interface IBlackScholes {
    function getCallPrice(
        uint256 spotPrice,
        uint256 strikePrice,
        uint256 sigma,
        uint256 time,
        int256 riskFree
    ) external view returns (uint256);

    function getPutPrice(
        uint256 spotPrice,
        uint256 strikePrice,
        uint256 sigma,
        uint256 time,
        int256 riskFree
    ) external view returns (uint256);
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

interface ISigmaGuesser {
    function blackScholes() external view returns (address);

    function getPutSigma(
        uint256 _targetPrice,
        uint256 _sigmaInitialGuess,
        uint256 _spotPrice,
        uint256 _strikePrice,
        uint256 _timeToMaturity,
        int256 _riskFree
    ) external view returns (uint256, uint256);

    function getCallSigma(
        uint256 _targetPrice,
        uint256 _sigmaInitialGuess,
        uint256 _spotPrice,
        uint256 _strikePrice,
        uint256 _timeToMaturity,
        int256 _riskFree
    ) external view returns (uint256, uint256);

    function updateAcceptableRange() external;
}

// SPDX-License-Identifier: agpl-3.0

pragma solidity 0.6.12;

interface IConfigurationManager {
    function setParameter(bytes32 name, uint256 value) external;

    function setEmergencyStop(address emergencyStop) external;

    function setPricingMethod(address pricingMethod) external;

    function setSigmaGuesser(address sigmaGuesser) external;

    function setPriceProvider(address priceProvider) external;

    function setCapProvider(address capProvider) external;

    function setAMMFactory(address ammFactory) external;

    function setOptionFactory(address optionFactory) external;

    function setOptionHelper(address optionHelper) external;

    function getParameter(bytes32 name) external view returns (uint256);

    function getEmergencyStop() external view returns (address);

    function getPricingMethod() external view returns (address);

    function getSigmaGuesser() external view returns (address);

    function getPriceProvider() external view returns (address);

    function getCapProvider() external view returns (address);

    function getAMMFactory() external view returns (address);

    function getOptionFactory() external view returns (address);

    function getOptionHelper() external view returns (address);
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

