// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "../interfaces/BPool.sol";
import "../interfaces/IPriceOracle.sol";
import "../misc/BNum.sol";

/** @title BalancerSharedPoolPriceProvider
 * @notice Price provider for a balancer pool token
 * It calculates the price using Chainlink as an external price source and the pool's tokens balances using the weighted arithmetic mean formula.
 * If there is a price deviation, instead of the balances, it uses a weighted geometric mean with the token's weights and constant value function V.
 */

contract BalancerSharedPoolPriceProvider is BNum {
    BPool public pool;
    address[] public tokens;
    uint256[] public weights;
    bool[] public isPeggedToEth;
    uint8[] public decimals;
    IPriceOracle public priceOracle;
    uint256 public immutable maxPriceDeviation;
    uint256 internal immutable K;
    uint256 internal immutable powerPrecision;
    uint256[][] internal approximationMatrix;

    /**
     * BalancerSharedPoolPriceProvider constructor.
     * @param _pool Balancer pool address.
     * @param _isPeggedToEth For each token, true if it is pegged to ETH (token order determined by pool.getFinalTokens()).
     * @param _decimals Number of decimals for each token (token order determined by pool.getFinalTokens()).
     * @param _priceOracle Aave price oracle.
     * @param _maxPriceDeviation Threshold of spot prices deviation: 10ˆ16 represents a 1% deviation.
     * @param _K //Constant K = 1 / (w1ˆw1 * .. * wn^wn)
     * @param _powerPrecision //Precision for power math function.
     * @param _approximationMatrix //Approximation matrix for gas optimization.
     */
    constructor(
        BPool _pool,
        bool[] memory _isPeggedToEth,
        uint8[] memory _decimals,
        IPriceOracle _priceOracle,
        uint256 _maxPriceDeviation,
        uint256 _K,
        uint256 _powerPrecision,
        uint256[][] memory _approximationMatrix
    ) public {
        pool = _pool;
        //Get token list
        tokens = pool.getFinalTokens(); //This already checks for pool finalized
        uint256 length = tokens.length;
        //Validate contructor params
        require(length >= 2 && length <= 3, "ERR_INVALID_POOL_TOKENS_NUMBER");
        require(_isPeggedToEth.length == length, "ERR_INVALID_PEGGED_LENGTH");
        require(_decimals.length == length, "ERR_INVALID_DECIMALS_LENGTH");
        for (uint8 i = 0; i < length; i++) {
            require(_decimals[i] <= 18, "ERR_INVALID_DECIMALS");
        }
        require(
            _approximationMatrix.length == 0 ||
                _approximationMatrix[0].length == length + 1,
            "ERR_INVALID_APPROX_MATRIX"
        );
        require(_maxPriceDeviation < BONE, "ERR_INVALID_PRICE_DEVIATION");
        require(
            _powerPrecision >= 1 && _powerPrecision <= BONE,
            "ERR_INVALID_POWER_PRECISION"
        );
        require(
            address(_priceOracle) != address(0),
            "ERR_INVALID_PRICE_PROVIDER"
        );
        //Get token normalized weights
        for (uint8 i = 0; i < length; i++) {
            weights.push(pool.getNormalizedWeight(tokens[i]));
        }
        isPeggedToEth = _isPeggedToEth;
        decimals = _decimals;
        priceOracle = _priceOracle;
        maxPriceDeviation = _maxPriceDeviation;
        K = _K;
        powerPrecision = _powerPrecision;
        approximationMatrix = _approximationMatrix;
    }

    /**
     * Returns the token balance in ethers by multiplying its balance with its price in ethers.
     * @param index Token index.
     */
    function getEthBalanceByToken(uint256 index)
        internal
        view
        returns (uint256)
    {
        uint256 pi = isPeggedToEth[index]
            ? BONE
            : uint256(priceOracle.getAssetPrice(tokens[index]));
        require(pi > 0, "ERR_NO_ORACLE_PRICE");
        uint256 missingDecimals = 18 - decimals[index];
        uint256 bi = bmul(
            pool.getBalance(tokens[index]),
            BONE * 10**(missingDecimals)
        );
        return bmul(bi, pi);
    }

    /**
     * Using the matrix approximation, returns a near base and exponentiation result, for num ^ weights[index]
     * @param index Token index.
     * @param num Base to approximate.
     */
    function getClosestBaseAndExponetation(uint256 index, uint256 num)
        internal
        view
        returns (uint256, uint256)
    {
        uint256 length = approximationMatrix.length;
        uint256 k = index + 1;
        for (uint8 i = 0; i < length; i++) {
            if (approximationMatrix[i][0] >= num) {
                return (approximationMatrix[i][0], approximationMatrix[i][k]);
            }
        }
        return (0, 0);
    }

    /**
     * Returns true if there is a price deviation.
     * @param ethTotals Balance of each token in ethers.
     */
    function hasDeviation(uint256[] memory ethTotals)
        internal
        view
        returns (bool)
    {
        //Check for a price deviation
        uint256 length = tokens.length;
        for (uint8 i = 0; i < length; i++) {
            for (uint8 o = 0; o < length; o++) {
                if (i != o) {
                    uint256 price_deviation = bdiv(
                        bdiv(ethTotals[i], weights[i]),
                        bdiv(ethTotals[o], weights[o])
                    );
                    if (
                        price_deviation > (BONE + maxPriceDeviation) ||
                        price_deviation < (BONE - maxPriceDeviation)
                    ) {
                        return true;
                    }
                }
            }
        }
        return false;
    }

    /**
     * Calculates the price of the pool token using the formula of weighted arithmetic mean.
     * @param ethTotals Balance of each token in ethers.
     */
    function getArithmeticMean(uint256[] memory ethTotals)
        internal
        view
        returns (uint256)
    {
        uint256 totalEth = 0;
        uint256 length = tokens.length;
        for (uint8 i = 0; i < length; i++) {
            totalEth = badd(totalEth, ethTotals[i]);
        }
        return bdiv(totalEth, pool.totalSupply());
    }

    /**
     * Returns the weighted token balance in ethers by calculating the balance in ether of the token to the power of its weight.
     * @param index Token index.
     */
    function getWeightedEthBalanceByToken(uint256 index, uint256 ethTotal)
        internal
        view
        returns (uint256)
    {
        uint256 weight = weights[index];
        (uint256 base, uint256 result) = getClosestBaseAndExponetation(
            index,
            ethTotal
        );
        if (base == 0 || ethTotal < MAX_BPOW_BASE) {
            if (ethTotal < MAX_BPOW_BASE) {
                return bpowApprox(ethTotal, weight, powerPrecision);
            } else {
                return
                    bmul(
                        ethTotal,
                        bpowApprox(
                            bdiv(BONE, ethTotal),
                            (BONE - weight),
                            powerPrecision
                        )
                    );
            }
        } else {
            return
                bmul(
                    result,
                    bpowApprox(bdiv(ethTotal, base), weight, powerPrecision)
                );
        }
    }

    /**
     * Calculates the price of the pool token using the formula of weighted geometric mean.
     * @param ethTotals Balance of each token in ethers.
     */
    function getWeightedGeometricMean(uint256[] memory ethTotals)
        internal
        view
        returns (uint256)
    {
        uint256 mult = BONE;
        uint256 length = tokens.length;
        for (uint256 i = 0; i < length; i++) {
            mult = bmul(mult, getWeightedEthBalanceByToken(i, ethTotals[i]));
        }
        return bdiv(bmul(mult, K), pool.totalSupply());
    }

    /**
     * Returns the pool's token price.
     * It calculates the price using Chainlink as an external price source and the pool's tokens balances using the weighted arithmetic mean formula.
     * If there is a price deviation, instead of the balances, it uses a weighted geometric mean with the token's weights and constant value function V.
     */
    function latestAnswer() external view returns (uint256) {
        //Get token balances in ethers
        uint256[] memory ethTotals = new uint256[](tokens.length);
        uint256 length = tokens.length;
        for (uint256 i = 0; i < length; i++) {
            ethTotals[i] = getEthBalanceByToken(i);
        }

        if (hasDeviation(ethTotals)) {
            //Calculate the weighted geometric mean
            return getWeightedGeometricMean(ethTotals);
        } else {
            //Calculate the weighted arithmetic mean
            return getArithmeticMean(ethTotals);
        }
    }

    /**
     * Returns Balancer pool address.
     */
    function getPool() external view returns (BPool) {
        return pool;
    }

    /**
     * Returns all tokens.
     */
    function getTokens() external view returns (address[] memory) {
        return tokens;
    }

    /**
     * Returns all tokens's weights.
     */
    function getWeights() external view returns (uint256[] memory) {
        return weights;
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;


interface BPool {

    function getFinalTokens() external view returns (address[] memory tokens);
    function getNormalizedWeight(address token) external view returns (uint);
    function getBalance(address token) external view returns (uint);
    function totalSupply() external view returns (uint);
 
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

/************
@title IPriceOracle interface
@notice Interface for the Aave price oracle.*/
interface IPriceOracle {
    /***********
    @dev returns the asset price in ETH
     */
    function getAssetPrice(address _asset) external view returns (uint256);

}

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

// From https://github.com/balancer-labs/balancer-core/blob/master/contracts/BNum.sol

pragma solidity 0.6.12;

import "./BConst.sol";

contract BNum is BConst {

    function btoi(uint a)
        internal pure 
        returns (uint)
    {
        return a / BONE;
    }

    function bfloor(uint a)
        internal pure
        returns (uint)
    {
        return btoi(a) * BONE;
    }

    function badd(uint a, uint b)
        internal pure
        returns (uint)
    {
        uint c = a + b;
        require(c >= a, "ERR_ADD_OVERFLOW");
        return c;
    }

    function bsub(uint a, uint b)
        internal pure
        returns (uint)
    {
        (uint c, bool flag) = bsubSign(a, b);
        require(!flag, "ERR_SUB_UNDERFLOW");
        return c;
    }

    function bsubSign(uint a, uint b)
        internal pure
        returns (uint, bool)
    {
        if (a >= b) {
            return (a - b, false);
        } else {
            return (b - a, true);
        }
    }

    function bmul(uint a, uint b)
        internal pure
        returns (uint)
    {
        uint c0 = a * b;
        require(a == 0 || c0 / a == b, "ERR_MUL_OVERFLOW");
        uint c1 = c0 + (BONE / 2);
        require(c1 >= c0, "ERR_MUL_OVERFLOW");
        uint c2 = c1 / BONE;
        return c2;
    }

    function bdiv(uint a, uint b)
        internal pure
        returns (uint)
    {
        require(b != 0, "ERR_DIV_ZERO");
        uint c0 = a * BONE;
        require(a == 0 || c0 / a == BONE, "ERR_DIV_INTERNAL"); // bmul overflow
        uint c1 = c0 + (b / 2);
        require(c1 >= c0, "ERR_DIV_INTERNAL"); //  badd require
        uint c2 = c1 / b;
        return c2;
    }

    // DSMath.wpow
    function bpowi(uint a, uint n)
        internal pure
        returns (uint)
    {
        uint z = n % 2 != 0 ? a : BONE;

        for (n /= 2; n != 0; n /= 2) {
            a = bmul(a, a);

            if (n % 2 != 0) {
                z = bmul(z, a);
            }
        }
        return z;
    }

    // Compute b^(e.w) by splitting it into (b^e)*(b^0.w).
    // Use `bpowi` for `b^e` and `bpowK` for k iterations
    // of approximation of b^0.w
    function bpow(uint base, uint exp)
        internal pure
        returns (uint)
    {
        require(base >= MIN_BPOW_BASE, "ERR_BPOW_BASE_TOO_LOW");
        require(base <= MAX_BPOW_BASE, "ERR_BPOW_BASE_TOO_HIGH");

        uint whole  = bfloor(exp);   
        uint remain = bsub(exp, whole);

        uint wholePow = bpowi(base, btoi(whole));

        if (remain == 0) {
            return wholePow;
        }

        uint partialResult = bpowApprox(base, remain, BPOW_PRECISION);
        return bmul(wholePow, partialResult);
    }

    function bpowApprox(uint base, uint exp, uint precision)
        internal pure
        returns (uint)
    {
        // term 0:
        uint a     = exp;
        (uint x, bool xneg)  = bsubSign(base, BONE);
        uint term = BONE;
        uint sum   = term;
        bool negative = false;


        // term(k) = numer / denom 
        //         = (product(a - i - 1, i=1-->k) * x^k) / (k!)
        // each iteration, multiply previous term by (a-(k-1)) * x / k
        // continue until term is less than precision
        for (uint i = 1; term >= precision; i++) {
            uint bigK = i * BONE;
            (uint c, bool cneg) = bsubSign(a, bsub(bigK, BONE));
            term = bmul(term, bmul(c, x));
            term = bdiv(term, bigK);
            if (term == 0) break;

            if (xneg) negative = !negative;
            if (cneg) negative = !negative;
            if (negative) {
                sum = bsub(sum, term);
            } else {
                sum = badd(sum, term);
            }
        }

        return sum;
    }

}

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

// From // From https://github.com/balancer-labs/balancer-core/blob/master/contracts/BConst.sol

pragma solidity 0.6.12;

contract BConst {
    uint public constant BONE              = 10**18;

    uint public constant MIN_BOUND_TOKENS  = 2;
    uint public constant MAX_BOUND_TOKENS  = 8;

    uint public constant MIN_FEE           = BONE / 10**6;
    uint public constant MAX_FEE           = BONE / 10;
    uint public constant EXIT_FEE          = 0;

    uint public constant MIN_WEIGHT        = BONE;
    uint public constant MAX_WEIGHT        = BONE * 50;
    uint public constant MAX_TOTAL_WEIGHT  = BONE * 50;
    uint public constant MIN_BALANCE       = BONE / 10**12;

    uint public constant INIT_POOL_SUPPLY  = BONE * 100;

    uint public constant MIN_BPOW_BASE     = 1 wei;
    uint public constant MAX_BPOW_BASE     = (2 * BONE) - 1 wei;
    uint public constant BPOW_PRECISION    = BONE / 10**10;

    uint public constant MAX_IN_RATIO      = BONE / 2;
    uint public constant MAX_OUT_RATIO     = (BONE / 3) + 1 wei;
}