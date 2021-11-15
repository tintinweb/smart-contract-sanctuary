//SPDX-License-Identifier: GPL-3.0
pragma solidity 0.7.3;

import {IVolatilityOracle} from "../interfaces/IVolatilityOracle.sol";
import {IPriceOracle} from "../interfaces/IPriceOracle.sol";
import {DSMath} from "../libraries/DSMath.sol";
import {IERC20Detailed} from "../interfaces/IERC20Detailed.sol";
import {Math} from "../libraries/Math.sol";
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";

contract OptionsPremiumPricer is DSMath {
    using SafeMath for uint256;

    /**
     * Immutables
     */
    address public immutable pool;
    IVolatilityOracle public immutable volatilityOracle;
    IPriceOracle public immutable priceOracle;
    IPriceOracle public immutable stablesOracle;
    uint256 private immutable priceOracleDecimals;
    uint256 private immutable stablesOracleDecimals;

    // For reference - IKEEP3rVolatility: 0xCCdfCB72753CfD55C5afF5d98eA5f9C43be9659d

    /**
     * @notice Constructor for pricer, deploy one for every pool
     * @param _pool is the Uniswap v3 pool
     * @param _volatilityOracle is the oracle for historical volatility
     * @param _priceOracle is the Chainlink price oracle for the underlying asset
     * @param _stablesOracle is the Chainlink price oracle for the strike asset (e.g. USDC)
     */
    constructor(
        address _pool,
        address _volatilityOracle,
        address _priceOracle,
        address _stablesOracle
    ) {
        require(_pool != address(0), "!_pool");
        require(_volatilityOracle != address(0), "!_volatilityOracle");
        require(_priceOracle != address(0), "!_priceOracle");
        require(_stablesOracle != address(0), "!_stablesOracle");

        pool = _pool;
        volatilityOracle = IVolatilityOracle(_volatilityOracle);
        priceOracle = IPriceOracle(_priceOracle);
        stablesOracle = IPriceOracle(_stablesOracle);
        priceOracleDecimals = IPriceOracle(_priceOracle).decimals();
        stablesOracleDecimals = IPriceOracle(_stablesOracle).decimals();
    }

    /**
     * @notice Calculates the premium of the provided option using Black-Scholes
     * References for Black-Scholes:
       https://www.macroption.com/black-scholes-formula/
       https://www.investopedia.com/terms/b/blackscholes.asp
       https://www.erieri.com/blackscholes
       https://goodcalculators.com/black-scholes-calculator/
       https://www.calkoo.com/en/black-scholes-option-pricing-model
     * @param st is the strike price of the option
     * @param expiryTimestamp is the unix timestamp of expiry
     * @param isPut is whether the option is a put option
     * @return premium for 100 contracts with 18 decimals i.e.
     * 500*10**18 = 500 USDC for 100 contracts for puts,
     * 5*10**18 = 5 of underlying asset (ETH, WBTC, etc.) for 100 contracts for calls,
     */
    function getPremium(
        uint256 st,
        uint256 expiryTimestamp,
        bool isPut
    ) external view returns (uint256 premium) {
        require(
            expiryTimestamp > block.timestamp,
            "Expiry must be in the future!"
        );

        uint256 spotPrice = priceOracle.latestAnswer();

        (uint256 sp, uint256 v, uint256 t) =
            blackScholesParams(spotPrice, expiryTimestamp);

        (uint256 call, uint256 put) = quoteAll(t, v, sp, st);

        // Multiplier to convert oracle latestAnswer to 18 decimals
        uint256 assetOracleMultiplier =
            10 **
                (
                    uint256(18).sub(
                        isPut ? stablesOracleDecimals : priceOracleDecimals
                    )
                );
        // Make option premium denominated in the underlying
        // asset for call vaults and USDC for put vaults
        premium = isPut
            ? wdiv(put, stablesOracle.latestAnswer().mul(assetOracleMultiplier))
            : wdiv(call, spotPrice.mul(assetOracleMultiplier));

        // Convert to 18 decimals
        premium = premium.mul(assetOracleMultiplier);
    }

    /**
     * @notice Calculates the option's delta
     * Formula reference: `d_1` in https://www.investopedia.com/terms/b/blackscholes.asp
     * http://www.optiontradingpedia.com/options_delta.htm
     * https://www.macroption.com/black-scholes-formula/
     * @param st is the strike price of the option
     * @param expiryTimestamp is the unix timestamp of expiry
     * @return delta for given option. 4 decimals (ex: 8100 = 0.81 delta) as this is what strike selection
     * module recognizes
     */
    function getOptionDelta(uint256 st, uint256 expiryTimestamp)
        external
        view
        returns (uint256 delta)
    {
        require(
            expiryTimestamp > block.timestamp,
            "Expiry must be in the future!"
        );

        uint256 spotPrice = priceOracle.latestAnswer();
        (uint256 sp, uint256 v, uint256 t) =
            blackScholesParams(spotPrice, expiryTimestamp);

        uint256 d1;
        uint256 d2;

        // Divide delta by 10 ** 10 to bring it to 4 decimals for strike selection
        if (sp >= st) {
            (d1, d2) = derivatives(t, v, sp, st);
            delta = Math.ncdf((Math.FIXED_1 * d1) / 1e18).div(10**10);
        } else {
            // If underlying < strike price notice we switch st <-> sp passed into d
            (d1, d2) = derivatives(t, v, st, sp);
            delta = uint256(10)
                .mul(10**13)
                .sub(Math.ncdf((Math.FIXED_1 * d2) / 1e18))
                .div(10**10);
        }
    }

    /**
     * @notice Calculates the option's delta
     * Formula reference: `d_1` in https://www.investopedia.com/terms/b/blackscholes.asp
     * http://www.optiontradingpedia.com/options_delta.htm
     * https://www.macroption.com/black-scholes-formula/
     * @param sp is the spot price of the option
     * @param st is the strike price of the option
     * @param v is the annualized volatility of the underlying asset
     * @param expiryTimestamp is the unix timestamp of expiry
     * @return delta for given option. 4 decimals (ex: 8100 = 0.81 delta) as this is what strike selection
     * module recognizes
     */
    function getOptionDelta(
        uint256 sp,
        uint256 st,
        uint256 v,
        uint256 expiryTimestamp
    ) external view returns (uint256 delta) {
        require(
            expiryTimestamp > block.timestamp,
            "Expiry must be in the future!"
        );

        // days until expiry
        uint256 t = expiryTimestamp.sub(block.timestamp).div(1 days);

        uint256 d1;
        uint256 d2;

        // Divide delta by 10 ** 10 to bring it to 4 decimals for strike selection
        if (sp >= st) {
            (d1, d2) = derivatives(t, v, sp, st);
            delta = Math.ncdf((Math.FIXED_1 * d1) / 1e18).div(10**10);
        } else {
            // If underlying < strike price notice we switch st <-> sp passed into d
            (d1, d2) = derivatives(t, v, st, sp);
            delta = uint256(10)
                .mul(10**13)
                .sub(Math.ncdf((Math.FIXED_1 * d2) / 1e18))
                .div(10**10);
        }
    }

    /**
     * @notice Calculates black scholes for both put and call
     * @param t is the days until expiry
     * @param v is the annualized volatility
     * @param sp is the underlying price
     * @param st is the strike price
     * @return call is the premium of the call option given parameters
     * @return put is the premium of the put option given parameters
     */
    function quoteAll(
        uint256 t,
        uint256 v,
        uint256 sp,
        uint256 st
    ) private pure returns (uint256 call, uint256 put) {
        uint256 _c;
        uint256 _p;

        if (sp > st) {
            _c = blackScholes(t, v, sp, st);
            _p = max(_c.add(st), sp) == sp ? 0 : _c.add(st).sub(sp);
        } else {
            _p = blackScholes(t, v, st, sp);
            _c = max(_p.add(sp), st) == st ? 0 : _p.add(sp).sub(st);
        }

        return (_c, _p);
    }

    /**
     * @notice Calculates black scholes for the ITM option at mint given strike
     * price and underlying given the parameters (if underling >= strike price this is
     * premium of call, and put otherwise)
     * @param t is the days until expiry
     * @param v is the annualized volatility
     * @param sp is the underlying price
     * @param st is the strike price
     * @return premium is the premium of option
     */
    function blackScholes(
        uint256 t,
        uint256 v,
        uint256 sp,
        uint256 st
    ) private pure returns (uint256 premium) {
        (uint256 d1, uint256 d2) = derivatives(t, v, sp, st);

        uint256 cdfD1 = Math.ncdf((Math.FIXED_1 * d1) / 1e18);
        uint256 cdfD2 = Math.cdf((int256(Math.FIXED_1) * int256(d2)) / 1e18);

        premium = (sp * cdfD1) / 1e14 - (st * cdfD2) / 1e14;
    }

    /**
     * @notice Calculates d1 and d2 used in black scholes calculation
     * as parameters to black scholes calculations
     * @param t is the days until expiry
     * @param v is the annualized volatility
     * @param sp is the underlying price
     * @param st is the strike price
     * @return d1 and d2
     */
    function derivatives(
        uint256 t,
        uint256 v,
        uint256 sp,
        uint256 st
    ) internal pure returns (uint256 d1, uint256 d2) {
        require(sp > 0, "!sp");
        require(st > 0, "!st");

        uint256 sigma = ((v**2) / 2);
        uint256 sigmaB = 1e36;

        uint256 sig = (((1e18 * sigma) / sigmaB) * t) / 365;

        uint256 sSQRT = (v * Math.sqrt2((1e18 * t) / 365)) / 1e9;
        require(sSQRT > 0, "!sSQRT");

        d1 = (1e18 * Math.ln((Math.FIXED_1 * sp) / st)) / Math.FIXED_1;
        d1 = ((d1 + sig) * 1e18) / sSQRT;
        d2 = d1 - sSQRT;
    }

    /**
     * @notice Calculates the current underlying price, annualized volatility, and days until expiry
     * as parameters to black scholes calculations
     * @param expiryTimestamp is the unix timestamp of expiry
     * @return sp is the underlying
     * @return v is the volatility
     * @return t is the days until expiry
     */
    function blackScholesParams(uint256 spotPrice, uint256 expiryTimestamp)
        private
        view
        returns (
            uint256 sp,
            uint256 v,
            uint256 t
        )
    {
        // chainlink oracle returns crypto / usd pairs with 8 decimals, like otoken strike price
        sp = spotPrice.mul(10**8).div(10**priceOracleDecimals);
        // annualized vol * 10 ** 8 because delta expects 18 decimals
        // and annualizedVol is 8 decimals
        v = volatilityOracle.annualizedVol(pool).mul(10**10);
        t = expiryTimestamp.sub(block.timestamp).div(1 days);
    }

    /**
     * @notice Calculates the underlying assets price
     */
    function getUnderlyingPrice() external view returns (uint256 price) {
        price = priceOracle.latestAnswer();
    }
}

//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.3;

interface IVolatilityOracle {
    function commit(address pool) external;

    function twap(address pool) external returns (uint256 price);

    function vol(address pool)
        external
        view
        returns (uint256 standardDeviation);

    function annualizedVol(address pool)
        external
        view
        returns (uint256 annualStdev);
}

//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.3;

interface IPriceOracle {
    function decimals() external view returns (uint256 _decimals);

    function latestAnswer() external view returns (uint256 price);
}

// SPDX-License-Identifier: MIT

/// math.sol -- mixin for inline numerical wizardry

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >0.4.13;

contract DSMath {
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, "ds-math-add-overflow");
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, "ds-math-sub-underflow");
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        return x <= y ? x : y;
    }

    function max(uint256 x, uint256 y) internal pure returns (uint256 z) {
        return x >= y ? x : y;
    }

    function imin(int256 x, int256 y) internal pure returns (int256 z) {
        return x <= y ? x : y;
    }

    function imax(int256 x, int256 y) internal pure returns (int256 z) {
        return x >= y ? x : y;
    }

    uint256 constant WAD = 10**18;
    uint256 constant RAY = 10**27;

    //rounds to zero if x*WAD < y/2
    function wmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }

    //rounds to zero if x*RAY < y/2
    function rmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, y), RAY / 2) / RAY;
    }

    //rounds to zero if x*y < WAD / 2
    function wdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, WAD), y / 2) / y;
    }

    //rounds to zero if x*y < RAY / 2
    function rdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, RAY), y / 2) / y;
    }

    // This famous algorithm is called "exponentiation by squaring"
    // and calculates x^n with x as fixed-point and n as regular unsigned.
    //
    // It's O(log n), instead of O(n) for naive repeated multiplication.
    //
    // These facts are why it works:
    //
    //  If n is even, then x^n = (x^2)^(n/2).
    //  If n is odd,  then x^n = x * x^(n-1),
    //   and applying the equation for even x gives
    //    x^n = x * (x^2)^((n-1) / 2).
    //
    //  Also, EVM division is flooring and
    //    floor[(n-1) / 2] = floor[n / 2].
    //
    function rpow(uint256 x, uint256 n) internal pure returns (uint256 z) {
        z = n % 2 != 0 ? x : RAY;

        for (n /= 2; n != 0; n /= 2) {
            x = rmul(x, x);

            if (n % 2 != 0) {
                z = rmul(z, x);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.3;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC20Detailed is IERC20 {
    function decimals() external view returns (uint8);

    function symbol() external view returns (string calldata);
}

//SPDX-License-Identifier: GPL-3.0
pragma solidity 0.7.3;

library Math {
    uint256 constant FIXED_1 = 0x080000000000000000000000000000000;
    uint256 constant FIXED_2 = 0x100000000000000000000000000000000;
    uint256 constant SQRT_1 = 13043817825332782212;
    uint256 constant LNX = 3988425491;
    uint256 constant LOG_10_2 = 3010299957;
    uint256 constant LOG_E_2 = 6931471806;
    uint256 constant BASE = 1e10;

    // solhint-disable-next-line
    // Credit to Ryan Hendricks, https://github.com/RyanHendricks/Black-Scholes-Solidity/blob/master/contracts/BlackScholesEstimate.sol
    /**
     * @dev stddev calculates the standard deviation for an array of integers
     * @dev precision is the same as sqrt above meaning for higher precision
     * @dev the decimal place must be moved prior to passing the params
     * @param numbers uint[] array of numbers to be used in calculation
     */
    function stddev(uint256[] memory numbers)
        internal
        pure
        returns (uint256 sd)
    {
        uint256 sum = 0;
        for (uint256 i = 0; i < numbers.length; i++) {
            sum += numbers[i];
        }
        uint256 mean = sum / numbers.length; // Integral value; float not supported in Solidity
        sum = 0;
        uint256 i;
        for (i = 0; i < numbers.length; i++) {
            sum += (numbers[i] - mean)**2;
        }
        sd = sqrt(sum / (numbers.length - 1)); //Integral value; float not supported in Solidity
        return sd;
    }

    function sqrt2(uint256 x) internal pure returns (uint256 y) {
        uint256 z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }

    // solhint-disable-next-line
    // Credit to Paul Razvan Berg https://github.com/hifi-finance/prb-math/blob/main/contracts/PRBMath.sol
    function sqrt(uint256 x) internal pure returns (uint256 result) {
        if (x == 0) {
            return 0;
        }

        // Set the initial guess to the closest power of two that is higher than x.
        uint256 xAux = uint256(x);
        result = 1;
        if (xAux >= 0x100000000000000000000000000000000) {
            xAux >>= 128;
            result <<= 64;
        }
        if (xAux >= 0x10000000000000000) {
            xAux >>= 64;
            result <<= 32;
        }
        if (xAux >= 0x100000000) {
            xAux >>= 32;
            result <<= 16;
        }
        if (xAux >= 0x10000) {
            xAux >>= 16;
            result <<= 8;
        }
        if (xAux >= 0x100) {
            xAux >>= 8;
            result <<= 4;
        }
        if (xAux >= 0x10) {
            xAux >>= 4;
            result <<= 2;
        }
        if (xAux >= 0x8) {
            result <<= 1;
        }

        // The operations can never overflow because the result is max 2^127 when it enters this block.
        result = (result + x / result) >> 1;
        result = (result + x / result) >> 1;
        result = (result + x / result) >> 1;
        result = (result + x / result) >> 1;
        result = (result + x / result) >> 1;
        result = (result + x / result) >> 1;
        result = (result + x / result) >> 1; // Seven iterations should be enough
        uint256 roundedDownResult = x / result;
        return result >= roundedDownResult ? roundedDownResult : result;
    }

    /**
     * @dev computes e ^ (x / FIXED_1) * FIXED_1
     * input range: 0 <= x <= OPT_EXP_MAX_VAL - 1
     * auto-generated via 'PrintFunctionOptimalExp.py'
     * Detailed description:
     * - Rewrite the input as a sum of binary exponents and a single residual r, as small as possible
     * - The exponentiation of each binary exponent is given (pre-calculated)
     * - The exponentiation of r is calculated via Taylor series for e^x, where x = r
     * - The exponentiation of the input is calculated by multiplying the intermediate results above
     * - For example: e^5.521692859 = e^(4 + 1 + 0.5 + 0.021692859) = e^4 * e^1 * e^0.5 * e^0.021692859
     */
    function optimalExp(uint256 x) internal pure returns (uint256) {
        uint256 res = 0;

        uint256 y;
        uint256 z;

        z = y = x % 0x10000000000000000000000000000000; // get the input modulo 2^(-3)
        z = (z * y) / FIXED_1;
        res += z * 0x10e1b3be415a0000; // add y^02 * (20! / 02!)
        z = (z * y) / FIXED_1;
        res += z * 0x05a0913f6b1e0000; // add y^03 * (20! / 03!)
        z = (z * y) / FIXED_1;
        res += z * 0x0168244fdac78000; // add y^04 * (20! / 04!)
        z = (z * y) / FIXED_1;
        res += z * 0x004807432bc18000; // add y^05 * (20! / 05!)
        z = (z * y) / FIXED_1;
        res += z * 0x000c0135dca04000; // add y^06 * (20! / 06!)
        z = (z * y) / FIXED_1;
        res += z * 0x0001b707b1cdc000; // add y^07 * (20! / 07!)
        z = (z * y) / FIXED_1;
        res += z * 0x000036e0f639b800; // add y^08 * (20! / 08!)
        z = (z * y) / FIXED_1;
        res += z * 0x00000618fee9f800; // add y^09 * (20! / 09!)
        z = (z * y) / FIXED_1;
        res += z * 0x0000009c197dcc00; // add y^10 * (20! / 10!)
        z = (z * y) / FIXED_1;
        res += z * 0x0000000e30dce400; // add y^11 * (20! / 11!)
        z = (z * y) / FIXED_1;
        res += z * 0x000000012ebd1300; // add y^12 * (20! / 12!)
        z = (z * y) / FIXED_1;
        res += z * 0x0000000017499f00; // add y^13 * (20! / 13!)
        z = (z * y) / FIXED_1;
        res += z * 0x0000000001a9d480; // add y^14 * (20! / 14!)
        z = (z * y) / FIXED_1;
        res += z * 0x00000000001c6380; // add y^15 * (20! / 15!)
        z = (z * y) / FIXED_1;
        res += z * 0x000000000001c638; // add y^16 * (20! / 16!)
        z = (z * y) / FIXED_1;
        res += z * 0x0000000000001ab8; // add y^17 * (20! / 17!)
        z = (z * y) / FIXED_1;
        res += z * 0x000000000000017c; // add y^18 * (20! / 18!)
        z = (z * y) / FIXED_1;
        res += z * 0x0000000000000014; // add y^19 * (20! / 19!)
        z = (z * y) / FIXED_1;
        res += z * 0x0000000000000001; // add y^20 * (20! / 20!)
        res = res / 0x21c3677c82b40000 + y + FIXED_1; // divide by 20! and then add y^1 / 1! + y^0 / 0!

        if ((x & 0x010000000000000000000000000000000) != 0)
            res =
                (res * 0x1c3d6a24ed82218787d624d3e5eba95f9) /
                0x18ebef9eac820ae8682b9793ac6d1e776; // multiply by e^2^(-3)
        if ((x & 0x020000000000000000000000000000000) != 0)
            res =
                (res * 0x18ebef9eac820ae8682b9793ac6d1e778) /
                0x1368b2fc6f9609fe7aceb46aa619baed4; // multiply by e^2^(-2)
        if ((x & 0x040000000000000000000000000000000) != 0)
            res =
                (res * 0x1368b2fc6f9609fe7aceb46aa619baed5) /
                0x0bc5ab1b16779be3575bd8f0520a9f21f; // multiply by e^2^(-1)
        if ((x & 0x080000000000000000000000000000000) != 0)
            res =
                (res * 0x0bc5ab1b16779be3575bd8f0520a9f21e) /
                0x0454aaa8efe072e7f6ddbab84b40a55c9; // multiply by e^2^(+0)
        if ((x & 0x100000000000000000000000000000000) != 0)
            res =
                (res * 0x0454aaa8efe072e7f6ddbab84b40a55c5) /
                0x00960aadc109e7a3bf4578099615711ea; // multiply by e^2^(+1)
        if ((x & 0x200000000000000000000000000000000) != 0)
            res =
                (res * 0x00960aadc109e7a3bf4578099615711d7) /
                0x0002bf84208204f5977f9a8cf01fdce3d; // multiply by e^2^(+2)
        if ((x & 0x400000000000000000000000000000000) != 0)
            res =
                (res * 0x0002bf84208204f5977f9a8cf01fdc307) /
                0x0000003c6ab775dd0b95b4cbee7e65d11; // multiply by e^2^(+3)

        return res;
    }

    function floorLog2(uint256 _n) internal pure returns (uint8) {
        uint8 res = 0;

        if (_n < 256) {
            // At most 8 iterations
            while (_n > 1) {
                _n >>= 1;
                res += 1;
            }
        } else {
            // Exactly 8 iterations
            for (uint8 s = 128; s > 0; s >>= 1) {
                if (_n >= (uint256(1) << s)) {
                    _n >>= s;
                    res |= s;
                }
            }
        }

        return res;
    }

    function ln(uint256 x) internal pure returns (uint256) {
        uint256 res = 0;

        // If x >= 2, then we compute the integer part of log2(x), which is larger than 0.
        if (x >= FIXED_2) {
            uint8 count = floorLog2(x / FIXED_1);
            x >>= count; // now x < 2
            res = count * FIXED_1;
        }

        // If x > 1, then we compute the fraction part of log2(x), which is larger than 0.
        if (x > FIXED_1) {
            for (uint8 i = 127; i > 0; --i) {
                x = (x * x) / FIXED_1; // now 1 < x < 4
                if (x >= FIXED_2) {
                    x >>= 1; // now 1 < x < 2
                    res += uint256(1) << (i - 1);
                }
            }
        }

        return (res * LOG_E_2) / BASE;
    }

    /**
     * @notice Takes the absolute value of a given number
     * @dev Helper function
     * @param _number The specified number
     * @return The absolute value of the number
     */
    function abs(int256 _number) public pure returns (uint256) {
        return _number < 0 ? uint256(_number * (-1)) : uint256(_number);
    }

    function ncdf(uint256 x) internal pure returns (uint256) {
        int256 t1 = int256(1e7 + ((2316419 * x) / FIXED_1));
        uint256 exp = ((x / 2) * x) / FIXED_1;
        int256 d = int256((3989423 * FIXED_1) / optimalExp(uint256(exp)));
        uint256 prob =
            uint256(
                (d *
                    (3193815 +
                        ((-3565638 +
                            ((17814780 +
                                ((-18212560 + (13302740 * 1e7) / t1) * 1e7) /
                                t1) * 1e7) /
                            t1) * 1e7) /
                        t1) *
                    1e7) / t1
            );
        if (x > 0) prob = 1e14 - prob;
        return prob;
    }

    function cdf(int256 x) internal pure returns (uint256) {
        int256 t1 = int256(1e7 + int256((2316419 * abs(x)) / FIXED_1));
        uint256 exp = uint256((x / 2) * x) / FIXED_1;
        int256 d = int256((3989423 * FIXED_1) / optimalExp(uint256(exp)));
        uint256 prob =
            uint256(
                (d *
                    (3193815 +
                        ((-3565638 +
                            ((17814780 +
                                ((-18212560 + (13302740 * 1e7) / t1) * 1e7) /
                                t1) * 1e7) /
                            t1) * 1e7) /
                        t1) *
                    1e7) / t1
            );
        if (x > 0) prob = 1e14 - prob;
        return prob;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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

pragma solidity ^0.7.0;

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

