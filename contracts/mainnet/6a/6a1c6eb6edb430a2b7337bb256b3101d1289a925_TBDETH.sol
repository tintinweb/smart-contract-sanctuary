// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

import './interfaces/IHegicETHOptions.sol';
import './interfaces/ICurve.sol';
import './interfaces/IUniswapV2Router02.sol';
import './interfaces/IChainlinkAggregatorV3.sol';
import './interfaces/IERC20.sol';
import './interfaces/IWETH.sol';
import './interfaces/ITBD.sol';

import '@openzeppelin/contracts/math/SafeMath.sol';

contract TBDETH is ITBD {
    using SafeMath for uint256;

    // Curve MetaPool used to convert alUSD to Dai
    ICurve alUSDMetaPool;

    // Hegic ETH Options contract
    IHegicETHOptions hegicETHOptions;

    // Uniswap router to convert Dai to Eth
    IUniswapV2Router02 uniswapV2Router02;

    // alUSD, Dai and Weth ERC20 contracts
    IERC20 alUSD;
    IERC20 Dai;
    IWETH Weth;

    // Store of created options
    mapping(address => ITBD.Option[]) public optionsByOwner;

    // Uniswap exchange paths Dai => Eth
    address[] public uniswapExchangePath;

    // Decimals for price values from aggregators
    uint256 constant PRICE_DECIMALS = 1e8;

    constructor(
        address _hegicETHOptions,
        address _alUSD,
        address _Dai,
        address _Weth,
        address _alUSDMetaPool,
        address _uniswapV2Router02
    ) {
        alUSDMetaPool = ICurve(_alUSDMetaPool);
        hegicETHOptions = IHegicETHOptions(_hegicETHOptions);
        alUSD = IERC20(_alUSD);
        Dai = IERC20(_Dai);
        Weth = IWETH(_Weth);
        uniswapV2Router02 = IUniswapV2Router02(_uniswapV2Router02);

        uniswapExchangePath = new address[](2);
        uniswapExchangePath[0] = _Dai;
        uniswapExchangePath[1] = _Weth;
    }

    /// ITBD overriden functions

    function purchaseOptionWithAlUSD(
        uint256 amount,
        uint256 strike,
        uint256 period,
        address owner,
        IHegicOptionTypes.OptionType optionType,
        uint256 minETH
    ) public override returns (uint256 optionID) {
        // Retrieve alUSD from user
        require(alUSD.transferFrom(msg.sender, address(this), amount), 'TBD/cannot-transfer-alusd');

        // Compute curve output amount in Dai
        uint256 curveDyInDai = alUSDMetaPool.get_dy_underlying(0, 1, amount);
        // Approve alUSD for curve
        alUSD.approve(address(alUSDMetaPool), amount);
        // Swap alUSD to Dai
        require(
            alUSDMetaPool.exchange_underlying(int128(0), int128(1), amount, curveDyInDai) == curveDyInDai,
            'TBD/cannot-swap-alusd-to-dai'
        );

        // Compute amount of Eth retrievable from Swap & check if above minimal Eth value provided
        // Doing it soon prevents extra gas usage in case of failure due to useless approvale and swap
        uint256[] memory uniswapAmounts = uniswapV2Router02.getAmountsOut(curveDyInDai, uniswapExchangePath);
        require(uniswapAmounts[1] > minETH, 'TBD/min-eth-not-reached');

        // Approve Dai to Uniswap Router
        Dai.approve(address(uniswapV2Router02), curveDyInDai);

        // Swap Dai for Eth
        uniswapAmounts =
            uniswapV2Router02.swapExactTokensForETH(
                curveDyInDai,
                minETH,
                uniswapExchangePath,
                address(this),
                block.timestamp
            );

        // Reverse compute option amount
        uint256 optionAmount = getAmount(period, uniswapAmounts[1], strike, optionType);

        // Create and send option to owner
        optionID = hegicETHOptions.create{value: uniswapAmounts[1]}(period, optionAmount, strike, optionType);
        hegicETHOptions.transfer(optionID, payable(owner));

        emit PurchaseOption(owner, optionID, amount, address(alUSD), uniswapAmounts[1]);

        // Store option
        optionsByOwner[msg.sender].push(ITBD.Option({id: optionID, priceInAlUSD: amount}));

        return optionID;
    }

    function getOptionsByOwner(address owner) external view override returns (ITBD.Option[] memory) {
        return optionsByOwner[owner];
    }

    function getUnderlyingFeeFromAlUSD(uint256 amount) external view override returns (uint256) {
        uint256 curveDyInDai = alUSDMetaPool.get_dy_underlying(0, 1, amount);
        uint256[] memory uniswapWethOutput = uniswapV2Router02.getAmountsOut(curveDyInDai, uniswapExchangePath);
        return uniswapWethOutput[1];
    }

    function getEthFeeFromAlUSD(uint256 amount) external view override returns (uint256) {
        uint256 curveDyInDai = alUSDMetaPool.get_dy_underlying(0, 1, amount);
        uint256[] memory uniswapWethOutput = uniswapV2Router02.getAmountsOut(curveDyInDai, uniswapExchangePath);
        return uniswapWethOutput[1];
    }

    function getOptionAmountFromAlUSD(
        uint256 period,
        uint256 amount,
        uint256 strike,
        IHegicOptionTypes.OptionType optionType
    ) external view override returns (uint256) {
        uint256 curveDyInDai = alUSDMetaPool.get_dy_underlying(0, 1, amount);
        uint256[] memory uniswapWethOutput = uniswapV2Router02.getAmountsOut(curveDyInDai, uniswapExchangePath);

        return getAmount(period, uniswapWethOutput[1], strike, optionType);
    }

    function getAmount(
        uint256 period,
        uint256 fees,
        uint256 strike,
        IHegicOptionTypes.OptionType optionType
    ) public view override returns (uint256) {
        require(
            optionType == IHegicOptionTypes.OptionType.Put || optionType == IHegicOptionTypes.OptionType.Call,
            'invalid option type'
        );
        (, int256 latestPrice, , , ) = IChainlinkAggregatorV3(hegicETHOptions.priceProvider()).latestRoundData();
        uint256 currentPrice = uint256(latestPrice);
        uint256 iv = hegicETHOptions.impliedVolRate();

        if (optionType == IHegicOptionTypes.OptionType.Put) {
            if (strike > currentPrice) {
                // ITM Put Fee
                uint256 nume = fees.mul(currentPrice).mul(PRICE_DECIMALS);
                uint256 sqrtPeriod = sqrt(period);
                uint256 denom = currentPrice.mul(PRICE_DECIMALS).div(100);
                denom = denom.add(sqrtPeriod.mul(iv).mul(strike));
                denom = denom.add(PRICE_DECIMALS.mul(strike.sub(currentPrice)));
                return nume.div(denom);
            } else {
                // OTM Put Fee
                uint256 nume = fees.mul(currentPrice).mul(PRICE_DECIMALS);
                uint256 sqrtPeriod = sqrt(period);
                uint256 denom = sqrtPeriod.mul(strike).mul(iv).add(currentPrice.mul(PRICE_DECIMALS).div(100));
                return nume.div(denom);
            }
        } else {
            if (strike < currentPrice) {
                // ITM Call Fee
                uint256 nume = fees.mul(strike).mul(PRICE_DECIMALS).mul(currentPrice);
                uint256 sqrtPeriod = sqrt(period);
                uint256 denom = strike.mul(PRICE_DECIMALS).div(100).mul(currentPrice);
                denom = denom.add(sqrtPeriod.mul(iv).mul(currentPrice).mul(currentPrice));
                denom = denom.add(strike.mul(PRICE_DECIMALS).mul(currentPrice.sub(strike)));
                return nume.div(denom);
            } else {
                // OTM Call Fee
                uint256 nume = fees.mul(strike).mul(PRICE_DECIMALS);
                uint256 sqrtPeriod = sqrt(period);
                uint256 denom = sqrtPeriod.mul(currentPrice).mul(iv).add(strike.mul(PRICE_DECIMALS).div(100));
                return nume.div(denom);
            }
        }
    }

    /// Misc

    function sqrt(uint256 x) private pure returns (uint256 result) {
        result = x;
        uint256 k = x.div(2).add(1);
        while (k < result) (result, k) = (k, x.div(k).add(k).div(2));
    }

    receive() external payable {}

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import './IHegicOptionTypes.sol';

interface IHegicETHOptions is IHegicOptionTypes {
    function priceProvider() external view returns (address);

    function impliedVolRate() external view returns (uint256);

    enum State {Inactive, Active, Exercised, Expired}

    function exercise(uint256 optionID) external;

    function options(uint256)
        external
        view
        returns (
            State state,
            address payable holder,
            uint256 strike,
            uint256 amount,
            uint256 lockedAmount,
            uint256 premium,
            uint256 expiration,
            IHegicOptionTypes.OptionType optionType
        );

    struct Option {
        State state;
        address payable holder;
        uint256 strike;
        uint256 amount;
        uint256 lockedAmount;
        uint256 premium;
        uint256 expiration;
        IHegicOptionTypes.OptionType optionType;
    }

    function fees(
        uint256 period,
        uint256 amount,
        uint256 strike,
        IHegicOptionTypes.OptionType optionType
    )
        external
        view
        returns (
            uint256 total,
            uint256 settlementFee,
            uint256 strikeFee,
            uint256 periodFee
        );

    function create(
        uint256 period,
        uint256 amount,
        uint256 strike,
        IHegicOptionTypes.OptionType optionType
    ) external payable returns (uint256 optionID);

    function transfer(uint256 optionID, address payable newHolder) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

interface ICurve {
    function get_dy_underlying(
        int128 i,
        int128 j,
        uint256 dx
    ) external view returns (uint256);

    function exchange_underlying(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy
    ) external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

interface IUniswapV2Router02 {
    function getAmountsOut(uint256 amountIn, address[] memory path) external view returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

interface IChainlinkAggregatorV3 {
    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

interface IERC20 {
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import './IERC20.sol';

interface IWETH is IERC20 {
    function withdraw(uint256 wad) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

import './IHegicOptionTypes.sol';

interface ITBD {
    event PurchaseOption(
        address indexed owner,
        uint256 optionID,
        uint256 purchasePrice,
        address purchaseToken,
        uint256 fees
    );

    struct Option {
        uint256 id;
        uint256 priceInAlUSD;
    }

    /// @notice Convert alUSD to Dai using Curve, Dai to Weth using Uniswap and purchases option on Hegic
    /// @param amount Amount of AlUSD paid
    /// @param strike Strike price (with 8 decimals)
    /// @param period Option period in seconds (min 1 day, max 28 days) 
    /// @param owner Address where option is sent 
    /// @param optionType 1 for PUT, 2 for CALL
    /// @param minETH Prevents high slippage by setting min eth after swaps
    function purchaseOptionWithAlUSD(
        uint256 amount,
        uint256 strike,
        uint256 period,
        address owner,
        IHegicOptionTypes.OptionType optionType,
        uint256 minETH
    ) external returns (uint256 optionID);

    /// @notice Retrieve created options
    /// @param owner Owner of the options to retrieve
    function getOptionsByOwner(address owner) external view returns (Option[] memory);

    /// @notice Retrieve option creation cost in the underlying token
    /// @param amount alUSD amount used
    function getUnderlyingFeeFromAlUSD(uint256 amount) external view returns (uint256);

    /// @notice Retrieve option creation cost in eth
    /// @param amount alUSD amount used
    function getEthFeeFromAlUSD(uint256 amount) external view returns (uint256);

    /// @notice Retrieve the option size depending on all parameters + alUSD paid
    /// @param amount Amount of AlUSD paid
    /// @param strike Strike price (with 8 decimals)
    /// @param period Option period in seconds (min 1 day, max 28 days) 
    /// @param optionType 1 for PUT, 2 for CALL
    function getOptionAmountFromAlUSD(
        uint256 period,
        uint256 amount,
        uint256 strike,
        IHegicOptionTypes.OptionType optionType
    ) external view returns (uint256);

    /// @notice Retrieve the option size from the raw eth fee paid to Hegic
    /// @param period Option period in seconds (min 1 day, max 28 days) 
    /// @param fees Amount of Eth paid
    /// @param strike Strike price (with 8 decimals)
    /// @param optionType 1 for PUT, 2 for CALL
    function getAmount(
        uint256 period,
        uint256 fees,
        uint256 strike,
        IHegicOptionTypes.OptionType optionType
    ) external view returns (uint256);
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
pragma solidity ^0.7.6;

interface IHegicOptionTypes {
    enum OptionType {Invalid, Put, Call}

}

