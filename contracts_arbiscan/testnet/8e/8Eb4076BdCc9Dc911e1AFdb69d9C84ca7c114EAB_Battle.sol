/**
 *Submitted for verification at arbiscan.io on 2021-10-10
*/

// Sources flattened with hardhat v2.6.5 https://hardhat.org

// File contracts/VirtualToken.sol

// SPDX-License-Identifier: MIT

// import "hardhat/console.sol";

pragma solidity ^0.8.0;

contract VirtualToken {
    mapping (uint=>uint) public spearTotal;
    mapping(uint => mapping(address=>uint)) public spearBalance;


    mapping (uint=>uint) public shieldTotal;
    mapping(uint => mapping(address=>uint)) public shieldBalance;

    // ri=>amount
    mapping(uint=>uint) public cSpear;
    mapping(uint=>uint) public cShield;
    mapping(uint=>uint) public collateral;

    // 0 => spear; 1 => shield
    event VTransfer(address indexed from, address indexed to, uint ri, uint spearOrShield, uint value);

    // view
    function spearSold(uint ri) public view returns(uint){
        return spearTotal[ri] - spearBalance[ri][address(this)];
    }

    function shieldSold(uint ri) public view returns(uint) {
        return shieldTotal[ri] - shieldBalance[ri][address(this)];
    }

    function cSurplus(uint ri) public view returns(uint amount) {
        amount = collateral[ri] - cSpear[ri] - cShield[ri];
    }

    // mut
    function addCSpear(uint ri, uint amount) internal {
        cSpear[ri] += amount;
        collateral[ri] += amount;
    }

    function addCShield(uint ri, uint amount) internal {
        cShield[ri] += amount;
        collateral[ri] += amount;
    }

    function addCSurplus(uint ri, uint amount) internal {
        collateral[ri] += amount;
    }

    function subCSpear(uint ri, uint amount) internal {
        cSpear[ri] -= amount;
        collateral[ri] -= amount;
    }

    function subCShield(uint ri, uint amount) internal {
        cShield[ri] -= amount;
        collateral[ri] -= amount;
    }

    function subCSurplus(uint ri, uint amount) internal {
        collateral[ri] -= amount;
    }

    function setCSpear(uint ri, uint amount) internal {
        cSpear[ri] = amount;
    }

    function setCShield(uint ri, uint amount) internal {
        cShield[ri] = amount;
    }

    function addCollateral(uint ri, uint amount) internal {
        collateral[ri] += amount;
    }

    function transferSpear(uint ri, address from, address to, uint amount) internal {
        require(from != address(0), "from should not be address(0)");
        require(to != address(0), "to should not be address(0)");
        spearBalance[ri][from] -= amount;
        spearBalance[ri][to] += amount;
        emit VTransfer(from, to, ri, 0, amount);
    }

    function transferShield(uint ri, address from, address to, uint amount) internal {
        require(from != address(0), "from should not be address(0)");
        require(to != address(0), "to should not be address(0)");
        shieldBalance[ri][from] -= amount;
        shieldBalance[ri][to] += amount;
        emit VTransfer(from, to, ri, 1, amount);
    }

    function burnSpear(uint ri, address acc, uint amount) internal {
        spearBalance[ri][acc] -= amount;
        spearTotal[ri] -= amount;
        emit VTransfer(acc, address(0), ri, 0,amount);
    }

    function burnShield(uint ri, address acc, uint amount) internal {
        shieldBalance[ri][acc] -= amount;
        shieldTotal[ri] -= amount;
        emit VTransfer(acc, address(0), ri, 1, amount);
    }

    function mintSpear(uint ri, address acc, uint amount) internal {
        spearBalance[ri][acc] += amount;
        spearTotal[ri] += amount;
        emit VTransfer(address(0), acc, ri, 0, amount);
    }

    function mintShield(uint ri, address acc, uint amount) internal {
        shieldBalance[ri][acc] += amount;
        shieldTotal[ri] += amount;
        emit VTransfer(address(0), acc, ri, 1, amount);
    }

}


// File @openzeppelin/contracts/utils/math/[email protected]

// SPD-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
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
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}


// File contracts/lib/SafeDecimalMath.sol

// SPD-License-Identifier: MIT
pragma solidity ^0.8.0;

// Libraries

// https://docs.synthetix.io/contracts/SafeDecimalMath
library SafeDecimalMath {
    using SafeMath for uint256;

    /* Number of decimal places in the representations. */
    uint8 public constant decimals = 18;
    uint8 public constant highPrecisionDecimals = 27;

    /* The number representing 1.0. */
    uint256 public constant UNIT = 10**uint256(decimals);

    /* The number representing 1.0 for higher fidelity numbers. */
    uint256 public constant PRECISE_UNIT = 10**uint256(highPrecisionDecimals);
    uint256 private constant UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR =
        10**uint256(highPrecisionDecimals - decimals);

    /**
     * @return Provides an interface to UNIT.
     */
    function unit() external pure returns (uint256) {
        return UNIT;
    }

    /**
     * @return Provides an interface to PRECISE_UNIT.
     */
    function preciseUnit() external pure returns (uint256) {
        return PRECISE_UNIT;
    }

    /**
     * @return The result of multiplying x and y, interpreting the operands as fixed-point
     * decimals.
     *
     * @dev A unit factor is divided out after the product of x and y is evaluated,
     * so that product must be less than 2**256. As this is an integer division,
     * the internal division always rounds down. This helps save on gas. Rounding
     * is more expensive on gas.
     */
    function multiplyDecimal(uint256 x, uint256 y)
        internal
        pure
        returns (uint256)
    {
        /* Divide by UNIT to remove the extra factor introduced by the product. */
        return x.mul(y) / UNIT;
    }

    /**
     * @return The result of safely multiplying x and y, interpreting the operands
     * as fixed-point decimals of the specified precision unit.
     *
     * @dev The operands should be in the form of a the specified unit factor which will be
     * divided out after the product of x and y is evaluated, so that product must be
     * less than 2**256.
     *
     * Unlike multiplyDecimal, this function rounds the result to the nearest increment.
     * Rounding is useful when you need to retain fidelity for small decimal numbers
     * (eg. small fractions or percentages).
     */
    function _multiplyDecimalRound(
        uint256 x,
        uint256 y,
        uint256 precisionUnit
    ) private pure returns (uint256) {
        /* Divide by UNIT to remove the extra factor introduced by the product. */
        uint256 quotientTimesTen = x.mul(y) / (precisionUnit / 10);

        if (quotientTimesTen % 10 >= 5) {
            quotientTimesTen += 10;
        }

        return quotientTimesTen / 10;
    }

    /**
     * @return The result of safely multiplying x and y, interpreting the operands
     * as fixed-point decimals of a precise unit.
     *
     * @dev The operands should be in the precise unit factor which will be
     * divided out after the product of x and y is evaluated, so that product must be
     * less than 2**256.
     *
     * Unlike multiplyDecimal, this function rounds the result to the nearest increment.
     * Rounding is useful when you need to retain fidelity for small decimal numbers
     * (eg. small fractions or percentages).
     */
    function multiplyDecimalRoundPrecise(uint256 x, uint256 y)
        internal
        pure
        returns (uint256)
    {
        return _multiplyDecimalRound(x, y, PRECISE_UNIT);
    }

    /**
     * @return The result of safely multiplying x and y, interpreting the operands
     * as fixed-point decimals of a standard unit.
     *
     * @dev The operands should be in the standard unit factor which will be
     * divided out after the product of x and y is evaluated, so that product must be
     * less than 2**256.
     *
     * Unlike multiplyDecimal, this function rounds the result to the nearest increment.
     * Rounding is useful when you need to retain fidelity for small decimal numbers
     * (eg. small fractions or percentages).
     */
    function multiplyDecimalRound(uint256 x, uint256 y)
        internal
        pure
        returns (uint256)
    {
        return _multiplyDecimalRound(x, y, UNIT);
    }

    /**
     * @return The result of safely dividing x and y. The return value is a high
     * precision decimal.
     *
     * @dev y is divided after the product of x and the standard precision unit
     * is evaluated, so the product of x and UNIT must be less than 2**256. As
     * this is an integer division, the result is always rounded down.
     * This helps save on gas. Rounding is more expensive on gas.
     */
    function divideDecimal(uint256 x, uint256 y)
        internal
        pure
        returns (uint256)
    {
        /* Reintroduce the UNIT factor that will be divided out by y. */
        return x.mul(UNIT).div(y);
    }

    /**
     * @return The result of safely dividing x and y. The return value is as a rounded
     * decimal in the precision unit specified in the parameter.
     *
     * @dev y is divided after the product of x and the specified precision unit
     * is evaluated, so the product of x and the specified precision unit must
     * be less than 2**256. The result is rounded to the nearest increment.
     */
    function _divideDecimalRound(
        uint256 x,
        uint256 y,
        uint256 precisionUnit
    ) private pure returns (uint256) {
        uint256 resultTimesTen = x.mul(precisionUnit * 10).div(y);

        if (resultTimesTen % 10 >= 5) {
            resultTimesTen += 10;
        }

        return resultTimesTen / 10;
    }

    /**
     * @return The result of safely dividing x and y. The return value is as a rounded
     * standard precision decimal.
     *
     * @dev y is divided after the product of x and the standard precision unit
     * is evaluated, so the product of x and the standard precision unit must
     * be less than 2**256. The result is rounded to the nearest increment.
     */
    function divideDecimalRound(uint256 x, uint256 y)
        internal
        pure
        returns (uint256)
    {
        return _divideDecimalRound(x, y, UNIT);
    }

    /**
     * @return The result of safely dividing x and y. The return value is as a rounded
     * high precision decimal.
     *
     * @dev y is divided after the product of x and the high precision unit
     * is evaluated, so the product of x and the high precision unit must
     * be less than 2**256. The result is rounded to the nearest increment.
     */
    function divideDecimalRoundPrecise(uint256 x, uint256 y)
        internal
        pure
        returns (uint256)
    {
        return _divideDecimalRound(x, y, PRECISE_UNIT);
    }

    /**
     * @dev Convert a standard decimal representation to a high precision one.
     */
    function decimalToPreciseDecimal(uint256 i)
        internal
        pure
        returns (uint256)
    {
        return i.mul(UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR);
    }

    /**
     * @dev Convert a high precision decimal to a standard decimal representation.
     */
    function preciseDecimalToDecimal(uint256 i)
        internal
        pure
        returns (uint256)
    {
        uint256 quotientTimesTen = i /
            (UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR / 10);

        if (quotientTimesTen % 10 >= 5) {
            quotientTimesTen += 10;
        }

        return quotientTimesTen / 10;
    }
}


// File contracts/lib/DMath.sol

// SPD-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

// a library for performing various math operations

library DMath {
    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}


// File contracts/algo/Pricing.sol

// SPD-License-Identifier: MIT

pragma solidity ^0.8.0;



library Pricing {
    using SafeMath for uint256;
    using SafeDecimalMath for uint256;

    function getVirtualOut(
        uint256 cDeltaAmount,
        uint256 cAmount,
        uint256 vAmount
    ) internal pure returns (uint256) {
        // if (cAmount.divideDecimal(vAmount) >= 0.9999 * 1e18) {
        if (cAmount.divideDecimal(vAmount) >= 0.99 * 1e18) {
            return cDeltaAmount;
        }
        // uint cLimitAmount = DMath.sqrt(cAmount*vAmount.mul(9999).div(10000));
        // uint vLimitAmount = DMath.sqrt(cAmount*vAmount.mul(10000).div(9999));
        uint256 cLimitAmount = DMath.sqrt(cAmount * vAmount.mul(99).div(100));
        uint256 vLimitAmount = DMath.sqrt(cAmount * vAmount.mul(100).div(99));
        if (cDeltaAmount + cAmount > cLimitAmount) {
            // console.log("%s %s %s ", vAmount/1e18, vLimitAmount/1e18, cDeltaAmount/1e18);
            // console.log("%s %s", cLimitAmount/1e18, cAmount/1e18);
            uint256 result = vAmount -
                vLimitAmount +
                (cDeltaAmount - (cLimitAmount - cAmount));
            return result;
        } else {
            uint256 numerator = vAmount * cDeltaAmount;
            uint256 denominator = cAmount + cDeltaAmount;
            return numerator / denominator;
        }
    }

    function getCollateralOut(
        uint256 vDeltaAmount,
        uint256 vAmount,
        uint256 cAmount
    ) internal pure returns (uint256) {
        if (cAmount.divideDecimal(vAmount) > 0.99e18) {
            uint256 maxAmountBy1 = ((cAmount - (vAmount * 99) / 100) * 100) /
                199;
            if (vDeltaAmount <= maxAmountBy1) {
                return vDeltaAmount;
            } else {
                uint256 numerator = (cAmount - maxAmountBy1) *
                    (vDeltaAmount - maxAmountBy1);
                uint256 denominator = (vAmount + maxAmountBy1) *
                    (vDeltaAmount - maxAmountBy1);
                return numerator / denominator + maxAmountBy1;
            }
        } else {
            uint256 numerator = cAmount * vDeltaAmount;
            uint256 denominator = vAmount + vDeltaAmount;
            return numerator / denominator;
        }
    }
}


// File contracts/BondingCurve.sol

// SPD-License-Identifier: MIT

pragma solidity ^0.8.0;



contract BondingCurve is VirtualToken {

    using SafeDecimalMath for uint;

    uint public maxPrice;
    uint public minPrice;
    uint public feeRatio;

    // VPrice => virtual token price => spear/shield price
    event VPriceUpdated(uint ri, uint256 _spearPrice, uint256 _shieldPrice);
    event CollateralUpdated(uint256 ri, uint256 cSpearAmount, uint256 cShieldAmount, uint256 cSurplusAmount);

    // =======VIEW========
    function spearPrice(uint roundId) public view returns(uint) {
        uint spPrice = cSpear[roundId].divideDecimal(spearBalance[roundId][address(this)]);
        if (spPrice >= maxPrice) {
            spPrice = maxPrice;
        }
        if (spPrice <= minPrice) {
            spPrice = minPrice;
        }
        return spPrice;
    }

    function shieldPrice(uint roundId) public view returns(uint) {
        uint shPrice = cShield[roundId].divideDecimal(shieldBalance[roundId][address(this)]);
        if (shPrice >= maxPrice) {
            shPrice = maxPrice;
        }
        if (shPrice <= minPrice) {
            shPrice = minPrice;
        }
        return shPrice;
    }

    function _tryBuy(uint ri, uint cDelta, uint spearOrShield) internal view returns(uint out, uint fee) {
        fee = cDelta.multiplyDecimal(feeRatio);
        uint cDeltaAdjust = cDelta - fee;
        if (spearOrShield == 0) {
            // buy spear
            out = Pricing.getVirtualOut(cDeltaAdjust, cSpear[ri], spearBalance[ri][address(this)]);
        } else if (spearOrShield == 1) {
            // buy shield
            out = Pricing.getVirtualOut(cDeltaAdjust, cShield[ri], shieldBalance[ri][address(this)]);
        } else {
            revert("must spear or shield");
        }
    }

    function _trySell(uint ri, uint vDelta, uint spearOrShield) internal view returns(uint outAdjust, uint fee) {
        uint out;
        if (spearOrShield == 0) {
            uint spearInContract = spearBalance[ri][address(this)];
            out = Pricing.getCollateralOut(vDelta, spearInContract, cSpear[ri]);
        } else if (spearOrShield == 1) {
            uint shieldInContract = shieldBalance[ri][address(this)];
            out = Pricing.getCollateralOut(vDelta, shieldInContract, cShield[ri]);
        } else {
            revert("must spear or shield");
        }
        fee = out.multiplyDecimal(feeRatio);
        outAdjust = out - fee;
    }

    // =====MUT=====

    function _buy(uint ri, uint cDelta, uint spearOrShield, uint outMin) internal returns(uint out, uint fee){
        (out, fee) = _tryBuy(ri, cDelta, spearOrShield);
        require(out >= outMin, "insufficient out");
        uint spearInContract = spearBalance[ri][address(this)];
        uint shieldInContract = shieldBalance[ri][address(this)];
        if (spearOrShield == 0) {
            // spear
            bool isExcceed = (cDelta + cSpear[ri]).divideDecimal(spearInContract-out) >= maxPrice;
            if (isExcceed) {
                transferSpear(ri, address(this), msg.sender, out);
                addCSpear(ri, cDelta);
                setCShield(ri, minPrice.multiplyDecimal(shieldInContract));
            } else {
                addCSpear(ri, cDelta);
                transferSpear(ri, address(this), msg.sender, out);
                setCShield(ri, (1e18 - spearPrice(ri)).multiplyDecimal(shieldInContract));
            }
        } else if (spearOrShield == 1) {
            // shield
            bool isExcceed = (cDelta + cShield[ri]).divideDecimal(shieldInContract-out) >= maxPrice;
            if (isExcceed) {
                transferShield(ri, address(this), msg.sender, out);
                addCShield(ri, cDelta);
                setCSpear(ri, minPrice.multiplyDecimal(spearInContract));
            } else {
                addCShield(ri, cDelta);
                transferShield(ri, address(this), msg.sender, out);
                setCSpear(ri, (1e18 - shieldPrice(ri)).multiplyDecimal(spearInContract));
            }
        } else {
            revert("must spear or shield");
        }
        emit CollateralUpdated(ri, cSpear[ri], cShield[ri], cSurplus(ri));
        emit VPriceUpdated(ri, spearPrice(ri), shieldPrice(ri));

    }

    function _sell(uint ri, uint vDelta, uint spearOrShield, uint outMin) internal returns(uint out, uint fee) {
        (out, fee) = _trySell(ri, vDelta, spearOrShield);
        require(out >= outMin, "insufficient out");
        if (spearOrShield == 0) {
            uint shieldInContract = shieldBalance[ri][address(this)];
            subCSpear(ri, out);
            transferSpear(ri, msg.sender, address(this), vDelta);
            setCShield(ri, (1e18 - spearPrice(ri)).multiplyDecimal(shieldInContract));
        } else if (spearOrShield == 1) {
            uint spearInContract = spearBalance[ri][address(this)];
            subCShield(ri, out);
            transferShield(ri, msg.sender, address(this), vDelta);
            setCSpear(ri, (1e18 - shieldPrice(ri)).multiplyDecimal(spearInContract));
        } else {
            revert("must spear or shield");
        }
        emit CollateralUpdated(ri, cSpear[ri], cShield[ri], cSurplus(ri));
        emit VPriceUpdated(ri, spearPrice(ri), shieldPrice(ri));
    }

    function _afterBuySpear(uint roundId, uint cDeltaAmount) internal virtual {}
    function _afterSellSpear(uint roundId, uint vDeltaAmount) internal virtual {}
    function _afterBuyShield(uint roundId, uint cDeltaAmount) internal virtual {}
    function _afterSellShield(uint roundId, uint vDeltaAmount) internal virtual {}

}


// File @openzeppelin/contracts-upgradeable/token/ERC20/[email protected]

// SPD-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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


// File @openzeppelin/contracts-upgradeable/token/ERC20/extensions/[email protected]

// SPD-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
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


// File @openzeppelin/contracts-upgradeable/proxy/utils/[email protected]

// SPD-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
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
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

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
}


// File @openzeppelin/contracts-upgradeable/utils/[email protected]

// SPD-License-Identifier: MIT

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}


// File @openzeppelin/contracts-upgradeable/token/ERC20/[email protected]

// SPD-License-Identifier: MIT

pragma solidity ^0.8.0;




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
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The defaut value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(string memory name_, string memory symbol_) internal initializer {
        __Context_init_unchained();
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal initializer {
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
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

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
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
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
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
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
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
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
    function _approve(address owner, address spender, uint256 amount) internal virtual {
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
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
    uint256[45] private __gap;
}


// File contracts/structs/RoundResult.sol

// SPD-License-Identifier: MIT

pragma solidity ^0.8.0;

enum RoundResult {
    Non, // 0
    SpearWin, // 1
    ShieldWin //2
}


// File contracts/BattleLP.sol

// SPD-License-Identifier: MIT

pragma solidity ^0.8.0;




contract BattleLP is BondingCurve, ERC20Upgradeable {

    using SafeDecimalMath for uint;

    mapping(uint=>uint) public startPrice;
    mapping(uint=>uint) public endPrice;

    mapping(uint=>uint) public startTS;
    mapping(uint=>uint) public endTS;

    mapping(uint=>uint) public strikePrice;
    mapping(uint=>uint) public strikePriceOver;
    mapping(uint=>uint) public strikePriceUnder;

    mapping(uint=>RoundResult) public roundResult;

    mapping(address=>uint) public lockTS;

    function _tryAddLiquidity(uint ri, uint cDeltaAmount) internal view returns(uint cDeltaSpear, uint cDeltaShield, uint deltaSpear, uint deltaShield, uint lpDelta) {
        uint cVirtual = cSpear[ri] + cShield[ri];
        cDeltaSpear = cSpear[ri].multiplyDecimal(cDeltaAmount).divideDecimal(cVirtual);
        cDeltaShield = cShield[ri].multiplyDecimal(cDeltaAmount).divideDecimal(cVirtual);
        deltaSpear = spearBalance[ri][address(this)].multiplyDecimal(cDeltaAmount).divideDecimal(cVirtual);
        deltaShield = shieldBalance[ri][address(this)].multiplyDecimal(cDeltaAmount).divideDecimal(cVirtual);
        if(totalSupply() == 0) {
            lpDelta = cDeltaAmount;
        } else {
            lpDelta = cDeltaAmount.multiplyDecimal(totalSupply()).divideDecimal(collateral[ri]);
        }
    }

    function _addLiquidity(uint ri, uint cDeltaAmount) internal returns (uint lpDelta) {
        (uint cDeltaSpear, uint cDeltaShield, uint deltaSpear, uint deltaShield, uint _lpDelta) = _tryAddLiquidity(ri, cDeltaAmount);
        addCSpear(ri, cDeltaSpear);
        addCShield(ri, cDeltaShield);
        mintSpear(ri, address(this), deltaSpear);
        mintShield(ri, address(this), deltaShield);
        // mint lp
        lpDelta = _lpDelta;
        _mint(msg.sender, lpDelta);
        
        emit CollateralUpdated(ri, cSpear[ri], cShield[ri], cSurplus(ri));
    }

    function _getCDelta(uint ri, uint lpDeltaAmount) internal view returns(uint cDelta) {
        uint spSold = spearSold(ri);
        uint shSold = shieldSold(ri);

        uint maxSold = spSold > shSold ? spSold:shSold;
        cDelta = (collateral[ri] - maxSold).multiplyDecimal(lpDeltaAmount).divideDecimal(totalSupply());
    }

    function _tryRemoveLiquidity(uint ri, uint lpDeltaAmount) internal view returns(uint cDelta, uint deltaSpear, uint deltaShield, uint earlyWithdrawFee){
        uint cDelta0 = _getCDelta(ri, lpDeltaAmount);

        cDelta = cDelta0.multiplyDecimal(1e18-pRatio(ri));
        earlyWithdrawFee = cDelta0 - cDelta;
        deltaSpear = spearBalance[ri][address(this)].multiplyDecimal(lpDeltaAmount).divideDecimal(totalSupply());
        deltaShield = shieldBalance[ri][address(this)].multiplyDecimal(lpDeltaAmount).divideDecimal(totalSupply());
    }

    function _removeLiquidity(uint ri, uint lpDeltaAmount) internal returns(uint, uint) {
        (uint cDelta, uint deltaSpear, uint deltaShield, ) = _tryRemoveLiquidity(ri, lpDeltaAmount);
        uint cDeltaSpear = cSpear[ri].multiplyDecimal(lpDeltaAmount).divideDecimal(totalSupply());
        uint cDeltaShield = cShield[ri].multiplyDecimal(lpDeltaAmount).divideDecimal(totalSupply());
        subCSpear(ri, cDeltaSpear);
        subCShield(ri, cDeltaShield);
        if (cDeltaSpear + cDeltaShield >= cDelta) {
            addCSurplus(ri, cDeltaSpear+cDeltaShield-cDelta);
        } else {
            subCSurplus(ri, cDelta - cDeltaSpear - cDeltaShield);
        }
        burnSpear(ri, address(this), deltaSpear);
        burnShield(ri, address(this), deltaShield);
        _burn(msg.sender, lpDeltaAmount);

        emit CollateralUpdated(ri, cSpear[ri], cShield[ri], cSurplus(ri));

        return (cDelta, lpDeltaAmount);
    }

    // penalty ratio
    function pRatio(uint ri) public view returns (uint ratio){
        if (spearSold(ri) == 0 && shieldSold(ri) == 0) {
            return 0;
        }
        uint s = 1e18 - (endTS[ri]-block.timestamp).divideDecimal(endTS[ri]-startTS[ri]);
        ratio = (DMath.sqrt(s) * 1e9).multiplyDecimal(1e16);
    }

    function _beforeTokenTransfer(address from, address to, uint amount) internal override {
        require(block.timestamp >= lockTS[from], "Locking");
        require(block.timestamp >= lockTS[to], "Locking");
        super._beforeTokenTransfer(from, to, amount);
    }

    function _afterAddLiquidity(uint ri, uint cDeltaAmount) internal virtual {}
    function _afterRemoveLiquidity(uint ri, uint lpDeltaAmount) internal virtual {}

}


// File contracts/structs/PeroidType.sol

// SPD-License-Identifier: MIT

pragma solidity ^0.8.0;

enum PeroidType {
    Day, // 0
    Week, // 1
    Month // 2
}


// File contracts/structs/SettleType.sol

// SPD-License-Identifier: MIT

pragma solidity ^0.8.0;

enum SettleType {
    TwoWay, // 0
    Positive, // 1
    Negative, // 2
    Specific // 3
}


// File contracts/structs/InitParams.sol

// SPD-License-Identifier: MIT

pragma solidity ^0.8.0;


struct InitParams {
    address _collateral;
    string _underlying;
    uint256 _cAmount;
    uint256 _spearPrice;
    uint256 _shieldPrice;
    PeroidType _peroidType;
    SettleType _settleType;
    uint256 _settleValue;
    address battleCreater;
    address _oracle;
    address _feeTo;
}


// File contracts/interfaces/IOracle.sol

// SPD-License-Identifier: MIT

pragma solidity ^0.8.0;


interface IOracle {
    function price(string memory symbol) external view returns (uint256);

    function historyPrice(string memory symbol, uint256 ts)
        external
        view
        returns (uint256);

    function getStrikePrice(
        string memory symbol,
        PeroidType _pt,
        SettleType _st,
        uint256 _settleValue
    )
        external
        view
        returns (
            uint256 startPrice,
            uint256 strikePrice,
            uint256 strikePriceOver,
            uint256 strikePriceUnder
        );

    function getRoundTS(PeroidType _pt)
        external
        view
        returns (uint256 start, uint256 end);

    function getNextRoundTS(PeroidType _pt)
        external
        view
        returns (uint256 start, uint256 end);

    function updatePriceByExternal(string memory symbol, uint256 ts)
        external
        returns (uint256 price_);
}


// File @openzeppelin/contracts/token/ERC20/[email protected]

// SPD-License-Identifier: MIT

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


// File @openzeppelin/contracts/token/ERC20/extensions/[email protected]

// SPD-License-Identifier: MIT

pragma solidity ^0.8.0;

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


// File @openzeppelin/contracts/utils/[email protected]

// SPD-License-Identifier: MIT

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


// File @openzeppelin/contracts/token/ERC20/utils/[email protected]

// SPD-License-Identifier: MIT

pragma solidity ^0.8.0;


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
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}


// File @openzeppelin/contracts/utils/structs/[email protected]

// SPD-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}


// File contracts/Battle.sol

// SPD-License-Identifier: MIT

pragma solidity ^0.8.0;

// import "./structs/SettleType.sol";
// import "./structs/PeroidType.sol";







contract Battle is BattleLP {
    using SafeDecimalMath for uint256;
    using SafeERC20 for IERC20Metadata;
    using EnumerableSet for EnumerableSet.UintSet;

    uint256 public constant PRICE_SETTING_PERIOD = 600;
    uint256 public constant LP_LOCK_PERIOD = 1800;
    uint256 public constant HAT_PEROID = 1800;

    address public arena;
    IERC20Metadata public collateralToken;
    string public underlying;
    PeroidType public peroidType;
    SettleType public settleType;
    uint256 public settleValue;

    uint256 public spearStartPrice;
    uint256 public shieldStartPrice;

    uint256[] public roundIds;

    address public feeTo;
    uint256 public stakeFeeRatio;

    IOracle public oracle;

    // round which user buyed spear or shield
    mapping(address => uint256) public claimRI;

    mapping(uint256 => mapping(address => uint256)) public userFutureLP;
    mapping(uint256 => uint256) public roundFutureLP;
    mapping(uint256 => uint256) public roundFutureCol; // appointmentCollateral
    mapping(address => EnumerableSet.UintSet) internal userFutureRI;

    uint256 public lpForAdjustPrice;

    uint256 public settleReward;
    uint256 public cDecimalDiff;

    // ==============view================

    function cri() public view returns (uint256) {
        return roundIds[roundIds.length - 1];
    }

    // ris: roundIds
    function expiryExitRis(address account) external view returns (uint256[] memory) {
        uint256 len = userFutureRI[account].length();
        uint256[] memory ris = new uint256[](len);
        for (uint256 i; i < len; i++) {
            ris[i] = userFutureRI[account].at(i);
        }
        return ris;
    }

    function init(
        InitParams memory p
    ) external {
        __ERC20_init("Divergence Battle LP", "DBLP");
        collateralToken = IERC20Metadata(p._collateral);

        // setting
        arena = msg.sender;
        underlying = p._underlying;
        peroidType = p._peroidType;
        settleType = p._settleType;
        settleValue = p._settleValue;
        maxPrice = 0.99e18;
        minPrice = 1e18 - maxPrice;
        cDecimalDiff = 10**(18 - uint256(collateralToken.decimals()));
        feeRatio = 3e15;
        stakeFeeRatio = 25e16;

        oracle = IOracle(p._oracle);

        spearStartPrice = p._spearPrice;
        shieldStartPrice = p._shieldPrice;
        _mint(address(1), 10**3);
        uint userLPAmount = p._cAmount * cDecimalDiff - 10**3;
        _mint(p.battleCreater, userLPAmount);
        initNewRound(p._cAmount * cDecimalDiff);

        feeTo = p._feeTo;

        uint256 ri = cri();

        emit AddLiquidity(ri, p.battleCreater, p._cAmount, userLPAmount);
    }

    function roundIdsLen() external view returns (uint256 l) {
        l = roundIds.length;
    }

    function setFeeTo(address _feeTo) external onlyArena {
        feeTo = _feeTo;
    }

    function setFeeRatio(uint256 _feeRatio) external onlyArena {
        uint oldFeeRatio = feeRatio;
        feeRatio = _feeRatio;
        emit FeeRatioChanged(oldFeeRatio, feeRatio);
    }

    function setSettleReward(uint256 amount) external onlyArena {
        settleReward = amount;
    }

    function setNextRoundSpearPrice(uint256 price) public handleClaim {
        require(block.timestamp > lockTS[msg.sender], "had seted");
        require(block.timestamp <= endTS[cri()] - PRICE_SETTING_PERIOD, "too late");
        uint256 amount = balanceOf(msg.sender);
        require(price < 1e18, "price error");
        lockTS[msg.sender] = endTS[cri()] + LP_LOCK_PERIOD;
        uint256 adjustedOldPrice = spearStartPrice.multiplyDecimal(lpForAdjustPrice).divideDecimal(lpForAdjustPrice + amount);
        uint256 adjustedNewPrice = price.multiplyDecimal(amount).divideDecimal(lpForAdjustPrice + amount);
        spearStartPrice = adjustedNewPrice + adjustedOldPrice;
        shieldStartPrice = 1e18 - spearStartPrice;
        lpForAdjustPrice += amount;

        // todo need record this ?
        // emit SetVPrice(cri(), msg.sender, spearStartPrice, shieldStartPrice);
        // emit CollateralRoundPriceUpdated(endTS[cri()], spearStartPrice, shieldStartPrice);
    }

    function _handleFee(uint256 fee) internal {
        uint256 stakingFee = fee.multiplyDecimal(stakeFeeRatio);
        collateralToken.safeTransfer(feeTo, stakingFee / cDecimalDiff);
    }

    function tryBuySpear(uint256 cDeltaAmount) public view returns (uint256) {
        (uint256 out, ) = _tryBuy(cri(), cDeltaAmount * cDecimalDiff, 0);
        require(out <= spearBalance[cri()][address(this)], "Liquidity Not Enough");
        return out;
    }

    function trySellSpear(uint256 vDeltaAmount) public view returns (uint256) {
        (uint256 out, ) = _trySell(cri(), vDeltaAmount, 0);
        return out / cDecimalDiff;
    }

    function tryBuyShield(uint256 cDeltaAmount) public view returns (uint256) {
        (uint256 out, ) = _tryBuy(cri(), cDeltaAmount * cDecimalDiff, 1);
        require(out <= shieldBalance[cri()][address(this)], "Liquidity Not Enough");
        return out;
    }

    function trySellShield(uint256 vDeltaAmount) public view returns (uint256) {
        (uint256 out, ) = _trySell(cri(), vDeltaAmount, 1);
        return out / cDecimalDiff;
    }

    function buySpear(
        uint256 cDeltaAmount,
        uint256 outMin,
        uint256 deadline
    ) public ensure(deadline) hat needSettle handleClaim {
        // fee is total 0.3%
        collateralToken.safeTransferFrom(msg.sender, address(this), cDeltaAmount);
        (uint out, uint256 fee) = _buy(cri(), cDeltaAmount * cDecimalDiff, 0, outMin);
        _handleFee(fee);
        // todo handle actual out
        claimRI[msg.sender] = cri();
        emit BuySpear(cri(), msg.sender, cDeltaAmount, out);
    }

    function sellSpear(
        uint256 vDeltaAmount,
        uint256 outMin,
        uint256 deadline
    ) public ensure(deadline) hat needSettle handleClaim {
        (uint256 out, uint256 fee) = _sell(cri(), vDeltaAmount, 0, outMin * cDecimalDiff);
        collateralToken.safeTransfer(msg.sender, out / cDecimalDiff);
        _handleFee(fee);
        emit SellSpear(cri(), msg.sender, vDeltaAmount, out / cDecimalDiff);
    }

    function buyShield(
        uint256 cDeltaAmount,
        uint256 outMin,
        uint256 deadline
    ) public ensure(deadline) hat needSettle handleClaim {
        collateralToken.safeTransferFrom(msg.sender, address(this), cDeltaAmount);
        (uint out, uint256 fee) = _buy(cri(), cDeltaAmount * cDecimalDiff, 1, outMin);
        _handleFee(fee);
        claimRI[msg.sender] = cri();
        emit BuyShield(cri(), msg.sender, cDeltaAmount, out);
    }

    function sellShield(
        uint256 vDeltaAmount,
        uint256 outMin,
        uint256 deadline
    ) public ensure(deadline) hat needSettle handleClaim {
        (uint256 out, uint256 fee) = _sell(cri(), vDeltaAmount, 1, outMin * cDecimalDiff);
        collateralToken.safeTransfer(msg.sender, out / cDecimalDiff);
        _handleFee(fee);
        emit SellShield(cri(), msg.sender, vDeltaAmount, out);
    }

    function tryAddLiquidity(uint256 cDeltaAmount)
        public
        view
        returns (
            uint256 cDeltaSpear,
            uint256 cDeltaShield,
            uint256 deltaSpear,
            uint256 deltaShield,
            uint256 lpDelta
        )
    {
        return _tryAddLiquidity(cri(), cDeltaAmount * cDecimalDiff);
    }

    function addLiquidity(uint256 cDeltaAmount, uint256 deadline) public ensure(deadline) needSettle handleClaim {
        uint256 lpDelta = _addLiquidity(cri(), cDeltaAmount * cDecimalDiff);
        collateralToken.safeTransferFrom(msg.sender, address(this), cDeltaAmount);
        emit AddLiquidity(cri(), msg.sender, cDeltaAmount, lpDelta);
    }

    function tryRemoveLiquidity(uint256 lpDeltaAmount)
        public
        view
        returns (
            uint256 cDelta,
            uint256 deltaSpear,
            uint256 deltaShield,
            uint256 earlyWithdrawFee
        )
    {
        (cDelta, deltaSpear, deltaShield, earlyWithdrawFee) = _tryRemoveLiquidity(cri(), lpDeltaAmount);
        cDelta /= cDecimalDiff;
        earlyWithdrawFee /= cDecimalDiff;
    }

    function removeLiquidity(uint256 lpDeltaAmount, uint256 deadline) public ensure(deadline) needSettle handleClaim {
        (uint256 cDelta, uint256 lpDelta) = _removeLiquidity(cri(), lpDeltaAmount);
        collateralToken.safeTransfer(msg.sender, cDelta / cDecimalDiff);
        emit RemoveLiquidity(cri(), msg.sender, cDelta / cDecimalDiff, lpDelta);
    }

    function tryRemoveLiquidityFuture(uint256 lpDeltaAmount) external view returns (uint256) {
        return _getCDelta(cri(), lpDeltaAmount) / cDecimalDiff;
    }

    function removeLiquidityFuture(uint256 lpDeltaAmount) external needSettle handleClaim {
        uint256 bal = balanceOf(msg.sender);
        require(bal >= lpDeltaAmount, "Not Enough LP");
        userFutureLP[cri()][msg.sender] += lpDeltaAmount;
        roundFutureLP[cri()] += lpDeltaAmount;
        if (!userFutureRI[msg.sender].contains(cri())) {
            userFutureRI[msg.sender].add(cri());
        }
        transfer(address(this), lpDeltaAmount);
        emit RemoveLiquidityFuture(cri(), msg.sender, lpDeltaAmount);
    }

    function tryWithdrawLiquidityHistory(address account) public view returns (uint256, uint256) {
        uint256 totalC;
        uint256 totalLP;
        uint256 len = userFutureRI[account].length();
        for (uint256 i; i < len; i++) {
            uint256 ri = userFutureRI[account].at(i);
            if (ri < cri()) {
                totalC += roundFutureCol[ri].multiplyDecimal(userFutureLP[ri][account]).divideDecimal(roundFutureLP[ri]);
                totalLP += userFutureLP[ri][account];
            }
        }
        return (totalC / cDecimalDiff, totalLP);
    }

    function withdrawLiquidityHistory() public handleClaim {
        // (uint256 totalC, uint256 totalLP) = tryWithdrawLiquidityHistory(
        //     msg.sender
        // );
        uint256 totalC;
        uint256 totalLP;
        uint256 len = userFutureRI[msg.sender].length();
        for (uint256 i; i < len; i++) {
            uint256 ri = userFutureRI[msg.sender].at(i);
            if (ri < cri()) {
                uint256 col = roundFutureCol[ri].multiplyDecimal(userFutureLP[ri][msg.sender]).divideDecimal(roundFutureLP[ri]);
                totalC += col;
                uint256 lp = userFutureLP[ri][msg.sender];
                totalLP += lp;
                emit WithdrawFutureLiquidity(ri, col, lp);
            }
        }

        require(totalC != 0, "his liqui 0");
        // uint256 len = userFutureRI[msg.sender].length();
        for (uint256 i; i < len; i++) {
            uint256 ri = userFutureRI[msg.sender].at(i);
            if (ri < cri()) {
                userFutureRI[msg.sender].remove(ri);
                roundFutureLP[ri] -= userFutureLP[ri][msg.sender];
                delete userFutureLP[ri][msg.sender];
            }
        }
        collateralToken.safeTransfer(msg.sender, totalC);
        // _burn(address(this), totalLP);
        emit RemoveLiquidity(cri(), msg.sender, totalC, totalLP);
    }

    function transferSettleReward() internal {
        if (collateral[cri()] / 100 > settleReward && settleReward > 0) {
            // transfer reward
            collateralToken.safeTransfer(msg.sender, settleReward);
            uint256 deltaCSpear = settleReward * cDecimalDiff.multiplyDecimal(cSpear[cri()]).divideDecimal(collateral[cri()]);
            uint256 deltaCShield = settleReward * cDecimalDiff.multiplyDecimal(cShield[cri()]).divideDecimal(collateral[cri()]);
            uint256 deltaCSurplus = settleReward * cDecimalDiff.multiplyDecimal(cSurplus(cri())).divideDecimal(collateral[cri()]);
            subCSpear(cri(), deltaCSpear);
            subCShield(cri(), deltaCShield);
            subCSurplus(cri(), deltaCSurplus);
        }
    }

    function settle() public {
        require(block.timestamp >= endTS[cri()], "too early");
        require(roundResult[cri()] == RoundResult.Non, "settled");
        uint256 price = oracle.updatePriceByExternal(underlying, endTS[cri()]);
        require(price != 0, "price error");
        uint256 oldRI = cri();
        lpForAdjustPrice = 0;
        endPrice[cri()] = price;
        transferSettleReward();
        uint256 result = updateRoundResult();
        // handle collateral
        (uint256 cRemain, uint256 futureCol) = getCRemain();
        if (roundFutureCol[cri()] > 0) {
            _burn(address(this), roundFutureLP[cri()]);
        }
        roundFutureCol[cri()] = futureCol;
        initNewRound(cRemain);
        emit Settled(oldRI, price, result);
    }

    // uri => userRoundId
    // rr => roundResult
    function tryClaim(address user)
        public
        view
        returns (
            uint256 uri,
            RoundResult rr,
            uint256 amount
        )
    {
        uri = claimRI[user];
        if (uri != 0) {
            rr = roundResult[uri];
            if (uri != 0 && uri < cri()) {
                if (rr == RoundResult.SpearWin) {
                    amount = spearBalance[uri][user];
                } else if (rr == RoundResult.ShieldWin) {
                    amount = shieldBalance[uri][user];
                }
            }
            amount /= cDecimalDiff;
        }
    }

    function claim() public {
        (uint256 uri, RoundResult rr, uint256 amount) = tryClaim(msg.sender);
        if (amount != 0) {
            if (rr == RoundResult.SpearWin) {
                burnSpear(uri, msg.sender, amount * cDecimalDiff);
                emit Claimed(uri, 0, msg.sender, amount * cDecimalDiff);
            } else if (rr == RoundResult.ShieldWin) {
                burnShield(uri, msg.sender, amount * cDecimalDiff);
                emit Claimed(uri, 1, msg.sender, amount * cDecimalDiff);
            } else {
                revert("error");
            }
            delete claimRI[msg.sender];
            collateralToken.safeTransfer(msg.sender, amount);
        }
    }

    function updateRoundResult() internal returns (uint256 result) {
        if (settleType == SettleType.TwoWay) {
            if (endPrice[cri()] >= strikePriceOver[cri()] || endPrice[cri()] <= strikePriceUnder[cri()]) {
                roundResult[cri()] = RoundResult.SpearWin;
            } else {
                roundResult[cri()] = RoundResult.ShieldWin;
            }
        } else if (settleType == SettleType.Positive) {
            if (endPrice[cri()] >= strikePriceOver[cri()]) {
                roundResult[cri()] = RoundResult.SpearWin;
            } else {
                roundResult[cri()] = RoundResult.ShieldWin;
            }
        } else if (settleType == SettleType.Negative) {
            if (endPrice[cri()] >= strikePriceUnder[cri()]) {
                roundResult[cri()] = RoundResult.SpearWin;
            } else {
                roundResult[cri()] = RoundResult.ShieldWin;
            }
        } else if (settleType == SettleType.Specific) {
            if (endPrice[cri()] >= strikePrice[cri()]) {
                roundResult[cri()] = RoundResult.SpearWin;
            } else {
                roundResult[cri()] = RoundResult.ShieldWin;
            }
        } else {
            revert("unknown settle type");
        }
        result = uint256(roundResult[cri()]);
    }

    function getCRemain() internal view returns (uint256 cRemain, uint256 futureCol) {
        // (uint start, ) = oracle.getNextRoundTS(uint(peroidType));
        if (roundResult[cri()] == RoundResult.SpearWin) {
            cRemain = collateral[cri()] - spearSold(cri());
        } else if (roundResult[cri()] == RoundResult.ShieldWin) {
            cRemain = collateral[cri()] - shieldSold(cri());
        } else {
            revert("not correct round result");
        }
        futureCol = cRemain.multiplyDecimal(roundFutureLP[cri()]).divideDecimal(totalSupply());
        cRemain -= futureCol;
    }

    function initNewRound(uint256 cAmount) internal {
        (uint256 _startTS, uint256 _endTS) = oracle.getRoundTS(peroidType);
        oracle.updatePriceByExternal(underlying, _startTS);
        roundIds.push(_startTS);
        (uint256 _startPrice, uint256 _strikePrice, uint256 _strikePriceOver, uint256 _strikePriceUnder) = oracle.getStrikePrice(underlying, peroidType, settleType, settleValue);
        mintSpear(cri(), address(this), cAmount);
        mintShield(cri(), address(this), cAmount);
        addCSpear(cri(), spearStartPrice.multiplyDecimal(cAmount));
        addCShield(cri(), shieldStartPrice.multiplyDecimal(cAmount));
        // startPrice endPrice
        startPrice[cri()] = _startPrice;
        startTS[cri()] = _startTS;
        endTS[cri()] = _endTS;
        strikePrice[cri()] = _strikePrice;
        strikePriceOver[cri()] = _strikePriceOver;
        strikePriceUnder[cri()] = _strikePriceUnder;
        roundResult[cri()] = RoundResult.Non;

        emit NewRound(cri(), _endTS, spearStartPrice, shieldStartPrice, _strikePrice, _strikePriceOver, _strikePriceUnder, cAmount, totalSupply());
    }

    modifier handleClaim() {
        if (claimRI[msg.sender] != 0) {
            claim();
        }
        _;
    }

    modifier onlyArena() {
        require(msg.sender == arena, "Should arena");
        _;
    }

    modifier trySettle() {
        if (block.timestamp >= endTS[cri()] && roundResult[cri()] == RoundResult.Non) {
            settle();
        }
        _;
    }

    modifier needSettle() {
        require(block.timestamp < endTS[cri()] && roundResult[cri()] == RoundResult.Non);
        _;
    }

    modifier ensure(uint256 deadline) {
        require(deadline >= block.timestamp, "EXPIRED");
        _;
    }

    modifier hat() {
        // if now is less than 30min of end, cant execute
        require(block.timestamp < endTS[cri()] - HAT_PEROID || block.timestamp >= endTS[cri()], "trade hat");
        _;
    }

    // event CollateralRoundPriceUpdated(uint256 ri, uint256 spearPrice, uint256 shieldPrice);
    event NewRound(uint256 ri, uint256 endTS, uint256 spearPrice, uint256 shieldPrice, uint256 strikePrice, uint256 strikePriceOver, uint256 strikePriceUnder, uint256 cAmount, uint256 lpAmount);
    event BuySpear(uint256 ri, address sender, uint256 amountIn, uint256 amountOut);
    event SellSpear(uint256 ri, address sender, uint256 amountIn, uint256 amountOut);
    event BuyShield(uint256 ri, address sender, uint256 amountIn, uint256 amountOut);
    event SellShield(uint256 ri, address sender, uint256 amountIn, uint256 amountOut);
    event AddLiquidity(uint256 ri, address sender, uint256 cAmount, uint256 lpAmount);
    event RemoveLiquidity(uint256 ri, address sender, uint256 cAmount, uint256 lpAmount);
    event Settled(uint256 ri, uint256 settlePrice, uint256 result);
    event Claimed(uint256 ri, uint256 spearOrShield, address account, uint256 amount);
    event RemoveLiquidityFuture(uint256 ri, address account, uint256 lpAmount);
    event WithdrawFutureLiquidity(uint256 ri, uint256 collateral, uint256 lp);
    event FeeRatioChanged(uint256 oldFeeRatio, uint newFeeRatio);
}