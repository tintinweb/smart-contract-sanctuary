/**
 *Submitted for verification at Etherscan.io on 2021-02-04
*/

// File: contracts/interfaces/AggregatorV3Interface.sol

// SPDX-License-Identifier: MIT
pragma solidity >0.5.16;

interface AggregatorV3Interface {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    // getRoundData and latestRoundData should both raise "No data present"
    // if they do not have data to report, instead of returning unset values
    // which could be misinterpreted as actual reported values.
    function getRoundData(uint80 _roundId)
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );

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

// File: contracts/interfaces/UniswapPriceOracleInterface.sol

// SPDX-License-Identifier: MIT
pragma solidity >0.5.16;

interface UniswapPriceOracleInterface {
    function update() external;

    function consult(address token) external view returns (uint256 amountOut);
}

// File: contracts/interfaces/CTokenInterfaces.sol

pragma solidity >0.5.16;

interface CTokenInterface {
    function symbol() external view returns (string memory);
}

interface CErc20Interface {
    function underlying() external view returns (address);
}

interface Erc20Interface {
    function decimals() external view returns (uint256);
}

// File: @openzeppelin/contracts/math/SafeMath.sol

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

// File: contracts/SUKUPriceOracle.sol

// SPDX-License-Identifier: MIT
pragma solidity >0.5.16;





contract SUKUPriceOracle {
    using SafeMath for uint256;
    /// @notice Indicator that this is a PriceOracle contract (for inspection)
    bool public constant isPriceOracle = true;
    uint256 constant MANTISSA_DECIMALS = 18;

    AggregatorV3Interface internal priceFeedETHUSD;
    AggregatorV3Interface internal priceFeedUSDCETH;
    UniswapPriceOracleInterface internal uniswapPriceOracle;

    constructor(
        address priceFeedETHUSD_,
        address priceFeedUSDCETH_,
        address uniswapPriceOracle_
    ) public {
        priceFeedETHUSD = AggregatorV3Interface(priceFeedETHUSD_);
        priceFeedUSDCETH = AggregatorV3Interface(priceFeedUSDCETH_);
        uniswapPriceOracle = UniswapPriceOracleInterface(uniswapPriceOracle_);
    }

    /**
     * @notice Get the current price of a supported cToken underlying
     * @param cToken The address of the market (token)
     * @return USD price mantissa or failure for unsupported markets
     */
    function getUnderlyingPrice(address cToken) public view returns (uint256) {
        string memory cTokenSymbol = CTokenInterface(cToken).symbol();
        // sETH doesn't not have an underlying field
        if (compareStrings(cTokenSymbol, "sETH")) {
            return getETHUSDCPrice();
        }
        address underlyingAddress = CErc20Interface(cToken).underlying();
        uint underlyingDecimals = Erc20Interface(underlyingAddress).decimals();
        // Becuase decimals places differ among contracts it's necessary to
        //  scale the price so that the values between tokens stays as expected
        uint256 priceFactor = MANTISSA_DECIMALS.sub(underlyingDecimals);
        if (compareStrings(cTokenSymbol, "sUSDC")) {
            return
                getETHUSDCPrice()
                    .mul(getUSDCETHPrice())
                    .div(10**MANTISSA_DECIMALS)
                    .mul(10**priceFactor);
        } else if (compareStrings(cTokenSymbol, "sSUKU")) {
            uint256 SUKUETHpriceMantissa =
                uniswapPriceOracle.consult(
                    address(CErc20Interface(address(cToken)).underlying())
                );
            return
                getETHUSDCPrice()
                    .mul(SUKUETHpriceMantissa)
                    .div(10**MANTISSA_DECIMALS)
                    .mul(10**priceFactor);
        } else {
            revert("This is not a supported market address.");
        }
    }

    /**
     * @notice Get the ETHUSD price from ChainLink and convert to a mantissa value
     * @return USD price mantissa
     */
    function getETHUSDCPrice() public view returns (uint256) {
        (
            uint80 roundID,
            int256 price,
            uint256 startedAt,
            uint256 timeStamp,
            uint80 answeredInRound
        ) = priceFeedETHUSD.latestRoundData();
        // Get decimals of price feed
        uint256 decimals = priceFeedETHUSD.decimals();
        // Add decimal places to format an 18 decimal mantissa
        uint256 priceMantissa =
            uint256(price).mul(10**(MANTISSA_DECIMALS.sub(decimals)));

        return priceMantissa;
    }

    /**
     * @notice Get the USDCETH price from ChainLink and convert to a mantissa value
     * @return USD price mantissa
     */
    function getUSDCETHPrice() public view returns (uint256) {
        (
            uint80 roundID,
            int256 price,
            uint256 startedAt,
            uint256 timeStamp,
            uint80 answeredInRound
        ) = priceFeedUSDCETH.latestRoundData();
        // Get decimals of price feed
        uint256 decimals = priceFeedUSDCETH.decimals();
        // Add decimal places to format an 18 decimal mantissa
        uint256 priceMantissa =
            uint256(price).mul(10**(MANTISSA_DECIMALS.sub(decimals)));

        return priceMantissa;
    }

    function compareStrings(string memory a, string memory b)
        internal
        pure
        returns (bool)
    {
        return (keccak256(abi.encodePacked((a))) ==
            keccak256(abi.encodePacked((b))));
    }
}