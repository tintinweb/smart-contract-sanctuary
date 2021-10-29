//SourceUnit: FactoryManager.sol

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

pragma solidity ^0.5.9;

contract BParam {
    uint public constant MAX = 2 ** 256 - 1;
    uint public constant BONE = 10 ** 18;

    uint public constant MIN_BOUND_TOKENS = 2;
    uint public constant MAX_BOUND_TOKENS = 2;

    //Number of tokens: pools must contain at least two, and may contain up to eight tokens.
    //Swap fee: the fee must be between 0.0001% and 10%

    uint public constant MIN_FEE = BONE / 10 ** 6;
    uint public constant MAX_FEE = BONE / 10;

    uint public constant MIN_WEIGHT = BONE;
    uint public constant MAX_WEIGHT = BONE * 50;
    uint public constant MAX_TOTAL_WEIGHT = BONE * 50;
    uint public constant MIN_BALANCE = BONE / 10 ** 12;

    uint public constant INIT_POOL_SUPPLY = BONE * 100;

    uint public constant MIN_BPOW_BASE = 1;
    uint public constant MAX_BPOW_BASE = (2 * BONE) - 1;
    uint public constant BPOW_PRECISION = BONE / 10 ** 10;

    uint public constant MAX_IN_RATIO = BONE / 2;
    uint public constant MAX_OUT_RATIO = (BONE / 3) + 1;

    uint public constant CENTI_FEE = BONE / 100;
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

pragma solidity ^0.5.9;

contract BNum is BParam {

    function btoi(uint a) internal pure returns (uint){
        return a / BONE;
    }

    function bfloor(uint a) internal pure returns (uint){
        return btoi(a) * BONE;
    }

    function badd(uint a, uint b) internal pure returns (uint){
        uint c = a + b;
        require(c >= a, "ERR_ADD_OVERFLOW");
        return c;
    }

    function bsub(uint a, uint b) internal pure returns (uint){
        (uint c, bool flag) = bsubSign(a, b);
        require(!flag, "ERR_SUB_UNDERFLOW");
        return c;
    }

    function bsubSign(uint a, uint b) internal pure returns (uint, bool){
        if (a >= b) {
            return (a - b, false);
        } else {
            return (b - a, true);
        }
    }

    function bmul(uint a, uint b) internal pure returns (uint){
        uint c0 = a * b;
        require(a == 0 || c0 / a == b, "ERR_MUL_OVERFLOW");
        uint c1 = c0 + (BONE / 2);
        require(c1 >= c0, "ERR_MUL_OVERFLOW");
        uint c2 = c1 / BONE;
        return c2;
    }

    function bdiv(uint a, uint b) internal pure returns (uint){
        require(b != 0, "ERR_DIV_ZERO");
        uint c0 = a * BONE;
        require(a == 0 || c0 / a == BONE, "ERR_DIV_INTERNAL");
        // bmul overflow
        uint c1 = c0 + (b / 2);
        require(c1 >= c0, "ERR_DIV_INTERNAL");
        //  badd require
        uint c2 = c1 / b;
        return c2;
    }

    // DSMath.wpow
    function bpowi(uint a, uint n) internal pure returns (uint){
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
    function bpow(uint base, uint exp) internal pure returns (uint){
        require(base >= MIN_BPOW_BASE, "ERR_BPOW_BASE_TOO_LOW");
        require(base <= MAX_BPOW_BASE, "ERR_BPOW_BASE_TOO_HIGH");

        uint whole = bfloor(exp);
        uint remain = bsub(exp, whole);

        uint wholePow = bpowi(base, btoi(whole));

        if (remain == 0) {
            return wholePow;
        }

        uint partialResult = bpowApprox(base, remain, BPOW_PRECISION);
        return bmul(wholePow, partialResult);
    }

    function bpowApprox(uint base, uint exp, uint precision) internal pure returns (uint){
        // term 0:
        uint a = exp;
        (uint x, bool xneg) = bsubSign(base, BONE);
        uint term = BONE;
        uint sum = term;
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

pragma solidity ^0.5.9;

contract BMath is BParam, BNum {
    /**********************************************************************************************
    // calcSpotPrice                                                                             //
    // sP = spotPrice                                                                            //
    // bI = tokenBalanceIn                ( bI / wI )         1                                  //
    // bO = tokenBalanceOut         sP =  -----------  *  ----------                             //
    // wI = tokenWeightIn                 ( bO / wO )     ( 1 - sF )                             //
    // wO = tokenWeightOut                                                                       //
    // sF = swapFee                                                                              //
    **********************************************************************************************/
    function calcSpotPrice(
        uint tokenBalanceIn,
        uint tokenWeightIn,
        uint tokenBalanceOut,
        uint tokenWeightOut,
        uint swapFee
    ) public pure returns (uint spotPrice){
        uint numer = bdiv(tokenBalanceIn, tokenWeightIn);
        uint denom = bdiv(tokenBalanceOut, tokenWeightOut);
        uint ratio = bdiv(numer, denom);
        uint scale = bdiv(BONE, bsub(BONE, swapFee));
        return (spotPrice = bmul(ratio, scale));
    }

    /**********************************************************************************************
    // calcOutGivenIn                                                                            //
    // aO = tokenAmountOut                                                                       //
    // bO = tokenBalanceOut                                                                      //
    // bI = tokenBalanceIn              /      /            bI             \    (wI / wO) \      //
    // aI = tokenAmountIn    aO = bO * |  1 - | --------------------------  | ^            |     //
    // wI = tokenWeightIn               \      \ ( bI + ( aI * ( 1 - sF )) /              /      //
    // wO = tokenWeightOut                                                                       //
    // sF = swapFee                                                                              //
    **********************************************************************************************/
    function calcOutGivenIn(
        uint tokenBalanceIn,
        uint tokenWeightIn,
        uint tokenBalanceOut,
        uint tokenWeightOut,
        uint tokenAmountIn,
        uint swapFee
    ) public pure returns (uint tokenAmountOut){
        uint weightRatio = bdiv(tokenWeightIn, tokenWeightOut);
        uint adjustedIn = bsub(BONE, swapFee);
        adjustedIn = bmul(tokenAmountIn, adjustedIn);
        uint y = bdiv(tokenBalanceIn, badd(tokenBalanceIn, adjustedIn));
        uint foo = bpow(y, weightRatio);
        uint bar = bsub(BONE, foo);
        tokenAmountOut = bmul(tokenBalanceOut, bar);
        return tokenAmountOut;
    }

    /**********************************************************************************************
    // calcInGivenOut                                                                            //
    // aI = tokenAmountIn                                                                        //
    // bO = tokenBalanceOut               /  /     bO      \    (wO / wI)      \                 //
    // bI = tokenBalanceIn          bI * |  | ------------  | ^            - 1  |                //
    // aO = tokenAmountOut    aI =        \  \ ( bO - aO ) /                   /                 //
    // wI = tokenWeightIn           --------------------------------------------                 //
    // wO = tokenWeightOut                          ( 1 - sF )                                   //
    // sF = swapFee                                                                              //
    **********************************************************************************************/
    function calcInGivenOut(
        uint tokenBalanceIn,
        uint tokenWeightIn,
        uint tokenBalanceOut,
        uint tokenWeightOut,
        uint tokenAmountOut,
        uint swapFee
    ) public pure returns (uint tokenAmountIn){
        uint weightRatio = bdiv(tokenWeightOut, tokenWeightIn);
        uint diff = bsub(tokenBalanceOut, tokenAmountOut);
        uint y = bdiv(tokenBalanceOut, diff);
        uint foo = bpow(y, weightRatio);
        foo = bsub(foo, BONE);
        tokenAmountIn = bsub(BONE, swapFee);
        tokenAmountIn = bdiv(bmul(tokenBalanceIn, foo), tokenAmountIn);
        return tokenAmountIn;
    }

    /**********************************************************************************************
    // calcPoolOutGivenSingleIn                                                                  //
    // pAo = poolAmountOut         /                                              \              //
    // tAi = tokenAmountIn        ///      /     //    wI \      \\       \     wI \             //
    // wI = tokenWeightIn        //| tAi *| 1 - || 1 - --  | * sF || + tBi \    --  \            //
    // tW = totalWeight     pAo=||  \      \     \\    tW /      //         | ^ tW   | * pS - pS //
    // tBi = tokenBalanceIn      \\  ------------------------------------- /        /            //
    // pS = poolSupply            \\                    tBi               /        /             //
    // sF = swapFee                \                                              /              //
    **********************************************************************************************/
    function calcPoolOutGivenSingleIn(
        uint tokenBalanceIn,
        uint tokenWeightIn,
        uint poolSupply,
        uint totalWeight,
        uint tokenAmountIn,
        uint swapFee
    ) public pure returns (uint poolAmountOut){
        // Charge the trading fee for the proportion of tokenAi
        ///  which is implicitly traded to the other pool tokens.
        // That proportion is (1- weightTokenIn)
        // tokenAiAfterFee = tAi * (1 - (1-weightTi) * poolFee);
        uint normalizedWeight = bdiv(tokenWeightIn, totalWeight);
        uint zaz = bmul(bsub(BONE, normalizedWeight), swapFee);
        uint tokenAmountInAfterFee = bmul(tokenAmountIn, bsub(BONE, zaz));

        uint newTokenBalanceIn = badd(tokenBalanceIn, tokenAmountInAfterFee);
        uint tokenInRatio = bdiv(newTokenBalanceIn, tokenBalanceIn);

        // uint newPoolSupply = (ratioTi ^ weightTi) * poolSupply;
        uint poolRatio = bpow(tokenInRatio, normalizedWeight);
        uint newPoolSupply = bmul(poolRatio, poolSupply);
        poolAmountOut = bsub(newPoolSupply, poolSupply);
        return poolAmountOut;
    }

    /**********************************************************************************************
    // calcSingleInGivenPoolOut                                                                  //
    // tAi = tokenAmountIn              //(pS + pAo)\     /    1    \\                           //
    // pS = poolSupply                 || ---------  | ^ | --------- || * bI - bI                //
    // pAo = poolAmountOut              \\    pS    /     \(wI / tW)//                           //
    // bI = balanceIn          tAi =  --------------------------------------------               //
    // wI = weightIn                              /      wI  \                                   //
    // tW = totalWeight                          |  1 - ----  |  * sF                            //
    // sF = swapFee                               \      tW  /                                   //
    **********************************************************************************************/
    function calcSingleInGivenPoolOut(
        uint tokenBalanceIn,
        uint tokenWeightIn,
        uint poolSupply,
        uint totalWeight,
        uint poolAmountOut,
        uint swapFee
    ) public pure returns (uint tokenAmountIn){
        uint normalizedWeight = bdiv(tokenWeightIn, totalWeight);
        uint newPoolSupply = badd(poolSupply, poolAmountOut);
        uint poolRatio = bdiv(newPoolSupply, poolSupply);

        //uint newBalTi = poolRatio^(1/weightTi) * balTi;
        uint boo = bdiv(BONE, normalizedWeight);
        uint tokenInRatio = bpow(poolRatio, boo);
        uint newTokenBalanceIn = bmul(tokenInRatio, tokenBalanceIn);
        uint tokenAmountInAfterFee = bsub(newTokenBalanceIn, tokenBalanceIn);
        // Do reverse order of fees charged in joinswap_ExternAmountIn, this way
        //     ``` pAo == joinswap_ExternAmountIn(Ti, joinswap_PoolAmountOut(pAo, Ti)) ```
        //uint tAi = tAiAfterFee / (1 - (1-weightTi) * swapFee) ;
        uint zar = bmul(bsub(BONE, normalizedWeight), swapFee);
        tokenAmountIn = bdiv(tokenAmountInAfterFee, bsub(BONE, zar));
        return tokenAmountIn;
    }

    /**********************************************************************************************
    // calcSingleOutGivenPoolIn                                                                  //
    // tAo = tokenAmountOut            /      /                                             \\   //
    // bO = tokenBalanceOut           /      // pS - (pAi * (1 - eF)) \     /    1    \      \\  //
    // pAi = poolAmountIn            | bO - || ----------------------- | ^ | --------- | * b0 || //
    // ps = poolSupply                \      \\          pS           /     \(wO / tW)/      //  //
    // wI = tokenWeightIn      tAo =   \      \                                             //   //
    // tW = totalWeight                    /     /      wO \       \                             //
    // sF = swapFee                    *  | 1 - |  1 - ---- | * sF  |                            //
    // eF = exitFee                        \     \      tW /       /                             //
    **********************************************************************************************/
    function calcSingleOutGivenPoolIn(
        uint tokenBalanceOut,
        uint tokenWeightOut,
        uint poolSupply,
        uint totalWeight,
        uint poolAmountIn,
        uint swapFee,
        uint exitFee
    ) public view returns (uint tokenAmountOut){
        uint normalizedWeight = bdiv(tokenWeightOut, totalWeight);
        // charge exit fee on the pool token side
        // pAiAfterExitFee = pAi*(1-exitFee)
        uint poolAmountInAfterExitFee = bmul(poolAmountIn, bsub(BONE, exitFee));
        uint newPoolSupply = bsub(poolSupply, poolAmountInAfterExitFee);
        uint poolRatio = bdiv(newPoolSupply, poolSupply);

        // newBalTo = poolRatio^(1/weightTo) * balTo;
        uint tokenOutRatio = bpow(poolRatio, bdiv(BONE, normalizedWeight));
        uint newTokenBalanceOut = bmul(tokenOutRatio, tokenBalanceOut);

        uint tokenAmountOutBeforeSwapFee = bsub(tokenBalanceOut, newTokenBalanceOut);

        // charge swap fee on the output token side
        //uint tAo = tAoBeforeSwapFee * (1 - (1-weightTo) * swapFee)
        uint zaz = bmul(bsub(BONE, normalizedWeight), swapFee);
        tokenAmountOut = bmul(tokenAmountOutBeforeSwapFee, bsub(BONE, zaz));
        return tokenAmountOut;
    }

    /**********************************************************************************************
    // calcPoolInGivenSingleOut                                                                  //
    // pAi = poolAmountIn               // /               tAo             \\     / wO \     \   //
    // bO = tokenBalanceOut            // | bO - -------------------------- |\   | ---- |     \  //
    // tAo = tokenAmountOut      pS - ||   \     1 - ((1 - (tO / tW)) * sF)/  | ^ \ tW /  * pS | //
    // ps = poolSupply                 \\ -----------------------------------/                /  //
    // wO = tokenWeightOut  pAi =       \\               bO                 /                /   //
    // tW = totalWeight           -------------------------------------------------------------  //
    // sF = swapFee                                        ( 1 - eF )                            //
    // eF = exitFee                                                                              //
    **********************************************************************************************/
    function calcPoolInGivenSingleOut(
        uint tokenBalanceOut,
        uint tokenWeightOut,
        uint poolSupply,
        uint totalWeight,
        uint tokenAmountOut,
        uint swapFee,
        uint exitFee
    ) public view returns (uint poolAmountIn){

        // charge swap fee on the output token side
        uint normalizedWeight = bdiv(tokenWeightOut, totalWeight);
        //uint tAoBeforeSwapFee = tAo / (1 - (1-weightTo) * swapFee) ;
        uint zoo = bsub(BONE, normalizedWeight);
        uint zar = bmul(zoo, swapFee);
        uint tokenAmountOutBeforeSwapFee = bdiv(tokenAmountOut, bsub(BONE, zar));

        uint newTokenBalanceOut = bsub(tokenBalanceOut, tokenAmountOutBeforeSwapFee);
        uint tokenOutRatio = bdiv(newTokenBalanceOut, tokenBalanceOut);

        //uint newPoolSupply = (ratioTo ^ weightTo) * poolSupply;
        uint poolRatio = bpow(tokenOutRatio, normalizedWeight);
        uint newPoolSupply = bmul(poolRatio, poolSupply);
        uint poolAmountInAfterExitFee = bsub(poolSupply, newPoolSupply);

        // charge exit fee on the pool token side
        // pAi = pAiAfterExitFee/(1-exitFee)
        poolAmountIn = bdiv(poolAmountInAfterExitFee, bsub(BONE, exitFee));
        return poolAmountIn;
    }


}


pragma solidity ^0.5.9;

interface IFactoryManager {
    function exitFee() external view returns (uint);

    function swapFeeForDex() external view returns (uint);

}



pragma solidity ^0.5.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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

// File: @openzeppelin/contracts/math/SafeMath.sol

pragma solidity ^0.5.0;

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
     *
     * _Available since v2.4.0._
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
     *
     * _Available since v2.4.0._
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
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol

pragma solidity ^0.5.0;




/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20Mintable}.
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
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view returns (uint256) {
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
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
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
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
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
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
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
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See {_burn} and {_approve}.
     */
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "ERC20: burn amount exceeds allowance"));
    }
}

// File: @openzeppelin/contracts/token/ERC20/ERC20Detailed.sol

pragma solidity ^0.5.0;


/**
 * @dev Optional functions from the ERC20 standard.
 */
contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for `name`, `symbol`, and `decimals`. All three of
     * these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }
}

// File: @openzeppelin/contracts/ownership/Ownable.sol

pragma solidity ^0.5.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: @openzeppelin/contracts/token/ERC20/ERC20Burnable.sol

pragma solidity ^0.5.0;



/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev See {ERC20-_burnFrom}.
     */
    function burnFrom(address account, uint256 amount) public {
        _burnFrom(account, amount);
    }
}

// File: contracts/token/RewardToken.sol

pragma solidity ^0.5.9;






contract RewardToken is ERC20, ERC20Detailed, ERC20Burnable, Ownable {
      uint256 public MAX = 31 * 1e6 * 1e18;
      constructor () public ERC20Detailed("ops", "ops", 18) {
      }

      function mint(address _to) public onlyOwner {
          require(totalSupply() == 0, "mint once");
          _mint(_to, MAX);
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

pragma solidity ^0.5.9;

contract TokenBase is BNum {

    mapping(address => uint)                   internal _balance;
    mapping(address => mapping(address => uint)) internal _allowance;
    uint internal _totalSupply;

    event Approval(address indexed src, address indexed dst, uint amt);
    event Transfer(address indexed src, address indexed dst, uint amt);

    function _mint(uint amt) internal {
        _balance[address(this)] = badd(_balance[address(this)], amt);
        _totalSupply = badd(_totalSupply, amt);
        emit Transfer(address(0), address(this), amt);
    }

    function _burn(uint amt) internal {
        require(_balance[address(this)] >= amt, "ERR_INSUFFICIENT_BAL");
        _balance[address(this)] = bsub(_balance[address(this)], amt);
        _totalSupply = bsub(_totalSupply, amt);
        emit Transfer(address(this), address(0), amt);
    }

    function _move(address src, address dst, uint amt) internal {
        require(_balance[src] >= amt, "ERR_INSUFFICIENT_BAL");
        _balance[src] = bsub(_balance[src], amt);
        _balance[dst] = badd(_balance[dst], amt);
        emit Transfer(src, dst, amt);
    }

    function _push(address to, uint amt) internal {
        _move(address(this), to, amt);
    }

    function _pull(address from, uint amt) internal {
        _move(from, address(this), amt);
    }
}

contract BToken is TokenBase, IERC20 {

    string  private _name = "abelo dex pair token";
    string  private _symbol = "ADPT";
    uint8   private _decimals = 18;

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function allowance(address src, address dst) external view returns (uint) {
        return _allowance[src][dst];
    }

    function balanceOf(address whom) external view returns (uint) {
        return _balance[whom];
    }

    function totalSupply() public view returns (uint) {
        return _totalSupply;
    }

    function approve(address dst, uint amt) external returns (bool) {
        _allowance[msg.sender][dst] = amt;
        emit Approval(msg.sender, dst, amt);
        return true;
    }

    function increaseApproval(address dst, uint amt) external returns (bool) {
        _allowance[msg.sender][dst] = badd(_allowance[msg.sender][dst], amt);
        emit Approval(msg.sender, dst, _allowance[msg.sender][dst]);
        return true;
    }

    function decreaseApproval(address dst, uint amt) external returns (bool) {
        uint oldValue = _allowance[msg.sender][dst];
        if (amt > oldValue) {
            _allowance[msg.sender][dst] = 0;
        } else {
            _allowance[msg.sender][dst] = bsub(oldValue, amt);
        }
        emit Approval(msg.sender, dst, _allowance[msg.sender][dst]);
        return true;
    }

    function transfer(address dst, uint amt) external returns (bool) {
        _move(msg.sender, dst, amt);
        return true;
    }

    function transferFrom(address src, address dst, uint amt) external returns (bool) {
        require(msg.sender == src || amt <= _allowance[src][msg.sender], "ERR_BTOKEN_BAD_CALLER");
        _move(src, dst, amt);
        if (msg.sender != src && _allowance[src][msg.sender] != uint256(- 1)) {
            _allowance[src][msg.sender] = bsub(_allowance[src][msg.sender], amt);
            emit Approval(msg.sender, dst, _allowance[src][msg.sender]);
        }
        return true;
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

pragma solidity ^0.5.9;

contract BPool is BToken, BMath {

  struct Record {
      bool bound;   // is token bound to pool
      uint index;   // private
      uint denorm;  // denormalized weight
      uint balance;
  }

  event LOG_SWAP(
      address indexed caller,
      address indexed tokenIn,
      address indexed tokenOut,
      uint256 tokenAmountIn,
      uint256 tokenAmountOut
  );

  event LOG_JOIN(
      address indexed caller,
      address indexed tokenIn,
      uint256 tokenAmountIn
  );

  event LOG_EXIT(
      address indexed caller,
      address indexed tokenOut,
      uint256 tokenAmountOut
  );

  event LOG_CALL(
      bytes4  indexed sig,
      address indexed caller,
      bytes data
  ) anonymous;

  modifier _lock_() {
      require(!_mutex, "ERR_REENTRY");
      _mutex = true;
      _;
      _mutex = false;
  }

  modifier _viewlock_() {
      require(!_mutex, "ERR_REENTRY");
      _;
  }

  bool private _mutex;

  address private _factory;    // BFactory address to push token exitFee to
  address public factoryManager;
  address public feeAddress;
  address public tusdAddress;
  address private _controller; // has CONTROL role
  bool private _publicSwap; // true if PUBLIC can call SWAP functions

  // `setSwapFee` and `finalize` require CONTROL
  // `finalize` sets `PUBLIC can SWAP`, `PUBLIC can JOIN`

  mapping(address => uint) private tokenFundForTeam;
  mapping(address => uint) private tokenFundForBuilder;

  uint private _swapFeeForBuilder;

  uint private _swapFeeForLp;

  bool private _finalized;

  address[] private _tokens;
  mapping(address => Record) private  _records;
  uint private _totalWeight;



  constructor(address _factoryManager,address _feeAddress,address _tusdAddress) public {
      _controller = msg.sender;
      _factory = msg.sender;
      factoryManager = _factoryManager;
      feeAddress = _feeAddress;
      tusdAddress = _tusdAddress;
      _swapFeeForLp = MIN_FEE;
      _swapFeeForBuilder = 0;
      _publicSwap = false;
      _finalized = false;
  }

  function isPublicSwap() external view returns (bool){
      return _publicSwap;
  }

  function isFinalized() external view returns (bool){
      return _finalized;
  }

  function isBound(address t) external view returns (bool){
      return _records[t].bound;
  }

  function getNumTokens() external view returns (uint){
      return _tokens.length;
  }

  function getCurrentTokens() external view _viewlock_ returns (address[] memory tokens){
      return _tokens;
  }

  function getFinalTokens() external view _viewlock_ returns (address[] memory tokens){
      require(_finalized, "ERR_NOT_FINALIZED");
      return _tokens;
  }

  function getDenormalizedWeight(address token) external view _viewlock_ returns (uint){

      require(_records[token].bound, "ERR_NOT_BOUND");
      return _records[token].denorm;
  }

  function getTotalDenormalizedWeight() external view _viewlock_ returns (uint){
      return _totalWeight;
  }

  function getNormalizedWeight(address token) external view _viewlock_ returns (uint){
      require(_records[token].bound, "ERR_NOT_BOUND");
      uint denorm = _records[token].denorm;
      return bdiv(denorm, _totalWeight);
  }

  function getDenorm(address token) external view _viewlock_ returns (uint){
      require(_records[token].bound, "ERR_NOT_BOUND");
      return _records[token].denorm;
  }

  function getBalance(address token) external view _viewlock_ returns (uint){
      require(_records[token].bound, "ERR_NOT_BOUND");
      return _records[token].balance;
  }

  function getSwapFee() external view _viewlock_ returns (uint){
      return _getSwapFee();
  }

  function getController() external view _viewlock_ returns (address){
      return _controller;
  }


  function setSwapLpFee(uint _swapFee) external _lock_ {
      require(!_finalized, "ERR_IS_FINALIZED");
      require(msg.sender == _controller, "ERR_NOT_CONTROLLER");
      require(_swapFee >= MIN_FEE, "ERR_MIN_FEE");
      require(_swapFee <= CENTI_FEE, "ERR_MAX_FEE");
      _swapFeeForLp = _swapFee;
  }


  function setSwapBuilderFee(uint _swapFee) external _lock_ {
      require(!_finalized, "ERR_IS_FINALIZED");
      require(msg.sender == _controller, "ERR_NOT_CONTROLLER");
      require(_swapFee >= MIN_FEE, "ERR_MIN_FEE");
      require(_swapFee <= CENTI_FEE, "ERR_MAX_FEE");
      _swapFeeForBuilder = _swapFee;
  }

  function setController(address manager) external _lock_ {
      require(msg.sender == _controller, "ERR_NOT_CONTROLLER");
      _controller = manager;
  }

  function setPublicSwap(bool public_) external _lock_ {
      require(!_finalized, "ERR_IS_FINALIZED");
      require(msg.sender == _controller, "ERR_NOT_CONTROLLER");
      _publicSwap = public_;
  }

  function addToken(
      address tokenIn,
      uint balanceIn,
      uint denormIn,
      address tokenOut,
      uint balanceOut,
      uint denormOut
  )external{
      require(msg.sender == _controller, "ERR_NOT_CONTROLLER");
      bind(tokenIn, balanceIn, denormIn);
      bind(tokenOut, balanceOut, denormOut);
      finalize();

  }

  function finalize() public _lock_ {
      require(msg.sender == _controller, "ERR_NOT_CONTROLLER");
      require(!_finalized, "ERR_IS_FINALIZED");
      require(_tokens.length >= MIN_BOUND_TOKENS, "ERR_MIN_TOKENS");

      _finalized = true;
      _publicSwap = true;

      _mintPoolShare(INIT_POOL_SUPPLY);
      _pushPoolShare(msg.sender, INIT_POOL_SUPPLY);
  }


  function bind(address token, uint balance, uint denorm) public {
      // _lock_  Bind does not lock because it jumps to `rebind`, which does
      require(msg.sender == _controller, "ERR_NOT_CONTROLLER");
      require(!_records[token].bound, "ERR_IS_BOUND");
      require(!_finalized, "ERR_IS_FINALIZED");

      require(_tokens.length < MAX_BOUND_TOKENS, "ERR_MAX_TOKENS");

      _records[token] = Record({
      bound : true,
      index : _tokens.length,
      denorm : 0, // balance and denorm will be validated
      balance : 0   // and set by `rebind`
      });
      _tokens.push(token);
      rebind(token, balance, denorm);
  }

  function rebind(address token, uint balance, uint denorm) public _lock_ {

      require(msg.sender == _controller, "ERR_NOT_CONTROLLER");
      require(_records[token].bound, "ERR_NOT_BOUND");
      require(!_finalized, "ERR_IS_FINALIZED");

      require(denorm >= MIN_WEIGHT, "ERR_MIN_WEIGHT");
      require(denorm <= MAX_WEIGHT, "ERR_MAX_WEIGHT");
      require(balance >= MIN_BALANCE, "ERR_MIN_BALANCE");

      // Adjust the denorm and totalWeight
      uint oldWeight = _records[token].denorm;
      if (denorm > oldWeight) {
          _totalWeight = badd(_totalWeight, bsub(denorm, oldWeight));
          require(_totalWeight <= MAX_TOTAL_WEIGHT, "ERR_MAX_TOTAL_WEIGHT");
      } else if (denorm < oldWeight) {
          _totalWeight = bsub(_totalWeight, bsub(oldWeight, denorm));
      }
      _records[token].denorm = denorm;

      // Adjust the balance record and actual token balance
      uint oldBalance = _records[token].balance;
      _records[token].balance = balance;
      if (balance > oldBalance) {
          _pullUnderlying(token, msg.sender, bsub(balance, oldBalance));
      } else if (balance < oldBalance) {
          // In this case liquidity is being withdrawn, so charge EXIT_FEE
          uint tokenBalanceWithdrawn = bsub(oldBalance, balance);
          uint _exitFee = IFactoryManager(factoryManager).exitFee();
          uint _tokenExitAmount = bmul(tokenBalanceWithdrawn, _exitFee);
          _pushUnderlying(token, msg.sender, bsub(tokenBalanceWithdrawn, _tokenExitAmount));
          _pushUnderlying(token, factoryManager, _tokenExitAmount);
      }
  }

  function unbind(address token) external _lock_ {

      require(msg.sender == _controller, "ERR_NOT_CONTROLLER");
      require(_records[token].bound, "ERR_NOT_BOUND");
      require(!_finalized, "ERR_IS_FINALIZED");

      uint tokenBalance = _records[token].balance;
      uint _exitFee = IFactoryManager(factoryManager).exitFee();
      uint _tokenExitAmount = bmul(tokenBalance, _exitFee);

      _totalWeight = bsub(_totalWeight, _records[token].denorm);

      // Swap the token-to-unbind with the last token,
      // then delete the last token
      uint index = _records[token].index;
      uint last = _tokens.length - 1;
      _tokens[index] = _tokens[last];
      _records[_tokens[index]].index = index;
      _tokens.pop();
      _records[token] = Record({
      bound : false,
      index : 0,
      denorm : 0,
      balance : 0
      });

      _pushUnderlying(token, msg.sender, bsub(tokenBalance, _tokenExitAmount));
      _pushUnderlying(token, factoryManager, _tokenExitAmount);
  }

  // Absorb any tokens that have been sent to this contract into the pool
  function gulp(address token) external _lock_ {
      require(_records[token].bound, "ERR_NOT_BOUND");
      _records[token].balance = IERC20(token).balanceOf(address(this));
  }

  function getSpotPrice(address tokenIn, address tokenOut) external view _viewlock_ returns (uint spotPrice){
      require(_records[tokenIn].bound, "ERR_NOT_BOUND");
      require(_records[tokenOut].bound, "ERR_NOT_BOUND");
      Record storage inRecord = _records[tokenIn];
      Record storage outRecord = _records[tokenOut];
      uint _swapFee = _getSwapFee();
      return calcSpotPrice(inRecord.balance, inRecord.denorm, outRecord.balance, outRecord.denorm, _swapFee);
  }


  function getSpotPriceSansFee(address tokenIn, address tokenOut) external view _viewlock_ returns (uint spotPrice){
      require(_records[tokenIn].bound, "ERR_NOT_BOUND");
      require(_records[tokenOut].bound, "ERR_NOT_BOUND");
      Record storage inRecord = _records[tokenIn];
      Record storage outRecord = _records[tokenOut];
      return calcSpotPrice(inRecord.balance, inRecord.denorm, outRecord.balance, outRecord.denorm, 0);
  }


  function joinPool(uint poolAmountOut, uint[] calldata maxAmountsIn) external _lock_ {
      require(_finalized, "ERR_NOT_FINALIZED");

      uint poolTotal = totalSupply();
      uint ratio = bdiv(poolAmountOut, poolTotal);
      require(ratio != 0, "ERR_MATH_APPROX");

      for (uint i = 0; i < _tokens.length; i++) {
          address t = _tokens[i];
          uint bal = _records[t].balance;
          uint tokenAmountIn = bmul(ratio, bal);
          require(tokenAmountIn != 0, "ERR_MATH_APPROX");
          require(tokenAmountIn <= maxAmountsIn[i], "ERR_LIMIT_IN");
          _records[t].balance = badd(_records[t].balance, tokenAmountIn);
          emit LOG_JOIN(msg.sender, t, tokenAmountIn);
          _pullUnderlying(t, msg.sender, tokenAmountIn);
      }
      _mintPoolShare(poolAmountOut);
      _pushPoolShare(msg.sender, poolAmountOut);
  }

  function exitPool(uint poolAmountIn, uint[] calldata minAmountsOut) external _lock_ {
      require(_finalized, "ERR_NOT_FINALIZED");

      uint poolTotal = totalSupply();
      uint _exitFee = IFactoryManager(factoryManager).exitFee();
      uint _exitAmount = bmul(poolAmountIn, _exitFee);
      uint pAiAfterExitFee = bsub(poolAmountIn, _exitAmount);
      uint ratio = bdiv(pAiAfterExitFee, poolTotal);
      require(ratio != 0, "ERR_MATH_APPROX");

      _pullPoolShare(msg.sender, poolAmountIn);
      _pushPoolShare(factoryManager, _exitAmount);
      _burnPoolShare(pAiAfterExitFee);

      for (uint i = 0; i < _tokens.length; i++) {
          address t = _tokens[i];
          uint bal = _records[t].balance;
          uint tokenAmountOut = bmul(ratio, bal);
          require(tokenAmountOut != 0, "ERR_MATH_APPROX");
          require(tokenAmountOut >= minAmountsOut[i], "ERR_LIMIT_OUT");
          _records[t].balance = bsub(_records[t].balance, tokenAmountOut);
          emit LOG_EXIT(msg.sender, t, tokenAmountOut);
          _pushUnderlying(t, msg.sender, tokenAmountOut);
      }

  }


  function swapExactAmountIn(
      address tokenIn,
      uint tokenAmountIn,
      address tokenOut,
      uint minAmountOut,
      uint maxPrice
  ) external _lock_ returns (uint tokenAmountOut, uint spotPriceAfter){

      require(_records[tokenIn].bound, "ERR_NOT_BOUND");
      require(_records[tokenOut].bound, "ERR_NOT_BOUND");
      require(_publicSwap, "ERR_SWAP_NOT_PUBLIC");

      Record storage inRecord = _records[address(tokenIn)];
      Record storage outRecord = _records[address(tokenOut)];
      uint _swapFee = _getSwapFee();
      require(tokenAmountIn <= bmul(inRecord.balance, MAX_IN_RATIO), "ERR_MAX_IN_RATIO");

      uint spotPriceBefore = calcSpotPrice(
          inRecord.balance,
          inRecord.denorm,
          outRecord.balance,
          outRecord.denorm,
          _swapFee
      );
      require(spotPriceBefore <= maxPrice, "ERR_BAD_LIMIT_PRICE");

      tokenAmountOut = calcOutGivenIn(
          inRecord.balance,
          inRecord.denorm,
          outRecord.balance,
          outRecord.denorm,
          tokenAmountIn,
          _swapFee
      );
      require(tokenAmountOut >= minAmountOut, "ERR_LIMIT_OUT");

      // swap fee = tusd
      if(tusdAddress==tokenIn){
          _chargeFee(tokenIn, tokenAmountIn);
      }else{
          _chargeFee(tokenOut, tokenAmountOut);
      }

      inRecord.balance = badd(inRecord.balance, tokenAmountIn);
      outRecord.balance = bsub(outRecord.balance, tokenAmountOut);

      spotPriceAfter = calcSpotPrice(
          inRecord.balance,
          inRecord.denorm,
          outRecord.balance,
          outRecord.denorm,
          _swapFee
      );
      require(spotPriceAfter >= spotPriceBefore, "ERR_MATH_APPROX");
      require(spotPriceAfter <= maxPrice, "ERR_LIMIT_PRICE");
      require(spotPriceBefore <= bdiv(tokenAmountIn, tokenAmountOut), "ERR_MATH_APPROX");

      emit LOG_SWAP(msg.sender, tokenIn, tokenOut, tokenAmountIn, tokenAmountOut);

      _pullUnderlying(tokenIn, msg.sender, tokenAmountIn);
      _pushUnderlying(tokenOut, msg.sender, tokenAmountOut);

      return (tokenAmountOut, spotPriceAfter);
  }

  function swapExactAmountOut(
      address tokenIn,
      uint maxAmountIn,
      address tokenOut,
      uint tokenAmountOut,
      uint maxPrice
  ) external _lock_ returns (uint tokenAmountIn, uint spotPriceAfter){
      require(_records[tokenIn].bound, "ERR_NOT_BOUND");
      require(_records[tokenOut].bound, "ERR_NOT_BOUND");
      require(_publicSwap, "ERR_SWAP_NOT_PUBLIC");

      uint _swapFee = _getSwapFee();
      Record storage inRecord = _records[address(tokenIn)];
      Record storage outRecord = _records[address(tokenOut)];

      require(tokenAmountOut <= bmul(outRecord.balance, MAX_OUT_RATIO), "ERR_MAX_OUT_RATIO");

      uint spotPriceBefore = calcSpotPrice(
          inRecord.balance,
          inRecord.denorm,
          outRecord.balance,
          outRecord.denorm,
          _swapFee
      );
      require(spotPriceBefore <= maxPrice, "ERR_BAD_LIMIT_PRICE");

      tokenAmountIn = calcInGivenOut(
          inRecord.balance,
          inRecord.denorm,
          outRecord.balance,
          outRecord.denorm,
          tokenAmountOut,
          _swapFee
      );
      require(tokenAmountIn <= maxAmountIn, "ERR_LIMIT_IN");

      // swap fee = tusd
      if(tusdAddress==tokenIn){
          _chargeFee(tokenIn, tokenAmountIn);
      }else{
          _chargeFee(tokenOut, tokenAmountOut);
      }

      inRecord.balance = badd(inRecord.balance, tokenAmountIn);
      outRecord.balance = bsub(outRecord.balance, tokenAmountOut);

      spotPriceAfter = calcSpotPrice(
          inRecord.balance,
          inRecord.denorm,
          outRecord.balance,
          outRecord.denorm,
          _swapFee
      );
      require(spotPriceAfter >= spotPriceBefore, "ERR_MATH_APPROX");
      require(spotPriceAfter <= maxPrice, "ERR_LIMIT_PRICE");
      require(spotPriceBefore <= bdiv(tokenAmountIn, tokenAmountOut), "ERR_MATH_APPROX");

      emit LOG_SWAP(msg.sender, tokenIn, tokenOut, tokenAmountIn, tokenAmountOut);

      _pullUnderlying(tokenIn, msg.sender, tokenAmountIn);
      _pushUnderlying(tokenOut, msg.sender, tokenAmountOut);

      return (tokenAmountIn, spotPriceAfter);
  }


  function joinswapExternAmountIn(
      address tokenIn, uint tokenAmountIn, uint minPoolAmountOut
  ) external _lock_ returns (uint poolAmountOut){
      require(_finalized, "ERR_NOT_FINALIZED");
      require(_records[tokenIn].bound, "ERR_NOT_BOUND");
      require(tokenAmountIn <= bmul(_records[tokenIn].balance, MAX_IN_RATIO), "ERR_MAX_IN_RATIO");
      uint _swapFee = _getSwapFee();
      Record storage inRecord = _records[tokenIn];

      poolAmountOut = calcPoolOutGivenSingleIn(
          inRecord.balance,
          inRecord.denorm,
          _totalSupply,
          _totalWeight,
          tokenAmountIn,
          _swapFee
      );

      require(poolAmountOut >= minPoolAmountOut, "ERR_LIMIT_OUT");

      // join fee = tusd
      if(tusdAddress==tokenIn){
          _chargeFee(tokenIn, tokenAmountIn);
      }
      inRecord.balance = badd(inRecord.balance, tokenAmountIn);

      emit LOG_JOIN(msg.sender, tokenIn, tokenAmountIn);

      _mintPoolShare(poolAmountOut);
      _pushPoolShare(msg.sender, poolAmountOut);
      _pullUnderlying(tokenIn, msg.sender, tokenAmountIn);

      return poolAmountOut;
  }

  function joinswapPoolAmountOut(
      address tokenIn, uint poolAmountOut, uint maxAmountIn
  ) external _lock_ returns (uint tokenAmountIn){
      require(_finalized, "ERR_NOT_FINALIZED");
      require(_records[tokenIn].bound, "ERR_NOT_BOUND");

      Record storage inRecord = _records[tokenIn];
      uint _swapFee = _getSwapFee();
      tokenAmountIn = calcSingleInGivenPoolOut(
          inRecord.balance,
          inRecord.denorm,
          _totalSupply,
          _totalWeight,
          poolAmountOut,
          _swapFee
      );

      require(tokenAmountIn != 0, "ERR_MATH_APPROX");
      require(tokenAmountIn <= maxAmountIn, "ERR_LIMIT_IN");

      require(tokenAmountIn <= bmul(_records[tokenIn].balance, MAX_IN_RATIO), "ERR_MAX_IN_RATIO");

      // join fee = tusd
      if(tusdAddress==tokenIn){
          _chargeFee(tokenIn, tokenAmountIn);
      }

      inRecord.balance = badd(inRecord.balance, tokenAmountIn);

      emit LOG_JOIN(msg.sender, tokenIn, tokenAmountIn);

      _mintPoolShare(poolAmountOut);
      _pushPoolShare(msg.sender, poolAmountOut);
      _pullUnderlying(tokenIn, msg.sender, tokenAmountIn);

      return tokenAmountIn;
  }

  function exitswapPoolAmountIn(
      address tokenOut, uint poolAmountIn, uint minAmountOut
  ) external _lock_ returns (uint tokenAmountOut){
      require(_finalized, "ERR_NOT_FINALIZED");
      require(_records[tokenOut].bound, "ERR_NOT_BOUND");

      uint _swapFee = _getSwapFee();
      Record storage outRecord = _records[tokenOut];
      uint _exitFee = IFactoryManager(factoryManager).exitFee();
      tokenAmountOut = calcSingleOutGivenPoolIn(
          outRecord.balance,
          outRecord.denorm,
          _totalSupply,
          _totalWeight,
          poolAmountIn,
          _swapFee,
          _exitFee
      );

      require(tokenAmountOut >= minAmountOut, "ERR_LIMIT_OUT");

      require(tokenAmountOut <= bmul(_records[tokenOut].balance, MAX_OUT_RATIO), "ERR_MAX_OUT_RATIO");

      // exit fee = tusd
      if(tusdAddress==tokenOut){
          _chargeFee(tokenOut, tokenAmountOut);
      }

      outRecord.balance = bsub(outRecord.balance, tokenAmountOut);
      uint _exitAmount = bmul(poolAmountIn, _exitFee);

      emit LOG_EXIT(msg.sender, tokenOut, tokenAmountOut);

      _pullPoolShare(msg.sender, poolAmountIn);
      _burnPoolShare(bsub(poolAmountIn, _exitAmount));
      _pushPoolShare(factoryManager, _exitAmount);
      _pushUnderlying(tokenOut, msg.sender, tokenAmountOut);

      return tokenAmountOut;
  }

  function exitswapExternAmountOut(
      address tokenOut, uint tokenAmountOut, uint maxPoolAmountIn
  ) external _lock_ returns (uint poolAmountIn){
      require(_finalized, "ERR_NOT_FINALIZED");
      require(_records[tokenOut].bound, "ERR_NOT_BOUND");
      require(tokenAmountOut <= bmul(_records[tokenOut].balance, MAX_OUT_RATIO), "ERR_MAX_OUT_RATIO");

      uint _swapFee = _getSwapFee();
      Record storage outRecord = _records[tokenOut];
      uint _exitFee = IFactoryManager(factoryManager).exitFee();
      poolAmountIn = calcPoolInGivenSingleOut(
          outRecord.balance,
          outRecord.denorm,
          _totalSupply,
          _totalWeight,
          tokenAmountOut,
          _swapFee,
          _exitFee
      );

      require(poolAmountIn != 0, "ERR_MATH_APPROX");
      require(poolAmountIn <= maxPoolAmountIn, "ERR_LIMIT_IN");
      // exit fee = tusd
      if(tusdAddress==tokenOut){
          _chargeFee(tokenOut, tokenAmountOut);
      }
      outRecord.balance = bsub(outRecord.balance, tokenAmountOut);


      uint _exitAmount = bmul(poolAmountIn, _exitFee);

      emit LOG_EXIT(msg.sender, tokenOut, tokenAmountOut);

      _pullPoolShare(msg.sender, poolAmountIn);
      _burnPoolShare(bsub(poolAmountIn, _exitAmount));
      _pushPoolShare(factoryManager, _exitAmount);
      _pushUnderlying(tokenOut, msg.sender, tokenAmountOut);

      return poolAmountIn;
  }


  // ==
  // 'Underlying' token-manipulation functions make external calls but are NOT locked
  // You must `_lock_` or otherwise ensure reentry-safety

  function _pullUnderlying(address erc20, address from, uint amount) internal {
      IERC20(erc20).transferFrom(from, address(this), amount);
  }

  function _pushUnderlying(address erc20, address to, uint amount) internal {
      IERC20(erc20).transfer(to, amount);
  }

  function _pullPoolShare(address from, uint amount) internal {
      _pull(from, amount);
  }

  function _pushPoolShare(address to, uint amount) internal {
      _push(to, amount);
  }

  function _mintPoolShare(uint amount) internal {
      _mint(amount);
  }

  function _burnPoolShare(uint amount) internal {
      _burn(amount);
  }

  function _chargeFee(address _token, uint _amount) internal {
      uint rewardFund = bmul(_amount, IFactoryManager(factoryManager).swapFeeForDex());
      tokenFundForTeam[_token] = badd(tokenFundForTeam[_token], rewardFund);
      uint buildFund = bmul(_amount, _swapFeeForBuilder);
      tokenFundForBuilder[_token] = badd(tokenFundForBuilder[_token], buildFund);
  }

  function swapFee() external view returns (uint){
      return _getSwapFee();
  }

  function getExitFee() external view returns (uint){
      return IFactoryManager(factoryManager).exitFee();
  }

  function _getSwapFee() internal view returns (uint){
      uint _fee = badd(_swapFeeForLp, _swapFeeForBuilder);
      uint _feeForDex = IFactoryManager(factoryManager).swapFeeForDex();
      return badd(_fee, _feeForDex);
  }

  function claimFactoryFund() public {
//        require(msg.sender == factoryManager, "!factory manager");
      for (uint i = 0; i < _tokens.length; i++) {
          address token = _tokens[i];
          uint amount = tokenFundForTeam[token];
          if (amount > 0) {
              IERC20(token).transfer(feeAddress, amount);// send feeAddress
              tokenFundForTeam[token] = 0;
          }
      }

  }

  function withdrawToken(address token) external {
      require(msg.sender == factoryManager, "!factory manager");
      require(!_records[token].bound, "token is bound");
      uint _amount = IERC20(token).balanceOf(address(this));
      IERC20(token).transfer(factoryManager, _amount);
  }

  function claimBuildFund() public {
      require(msg.sender == _controller, "!controller");
      for (uint i = 0; i < _tokens.length; i++) {
          address token = _tokens[i];
          uint amount = tokenFundForBuilder[token];
          if (amount > 0) {
              IERC20(token).transfer(_controller, amount);
              tokenFundForBuilder[token] = 0;
          }
      }
  }


}

pragma solidity ^0.5.9;


contract PoolView is BMath {

    BPool public pool;

    constructor(address _poolAddress) public {
        pool = BPool(_poolAddress);
    }

    function getInGivenOut(
        address tokenIn, address tokenOut, uint256 tokenInAmount
    ) external view returns (uint tokenOutAmount){
        require(pool.isBound(tokenIn), "ERR_NOT_BOUND");
        require(pool.isBound(tokenOut), "ERR_NOT_BOUND");

        uint inRecordBalance = pool.getBalance(tokenIn);
        uint inRecordDenorm = pool.getDenormalizedWeight(tokenIn);
        uint outRecordBalance = pool.getBalance(tokenOut);
        uint outRecordDenorm = pool.getDenormalizedWeight(tokenOut);

        uint _swapFee = pool.swapFee();

        tokenOutAmount = calcOutGivenIn(
            inRecordBalance,
            inRecordDenorm,
            outRecordBalance,
            outRecordDenorm,
            tokenInAmount,
            _swapFee
        );
        return tokenOutAmount;
    }

    function getTokenInGivenPoolOut(
        address[]  calldata tokens, uint[] calldata amounts
    ) external view returns (uint poolAmountOut){
        require(pool.isFinalized(), "ERR_NOT_FINALIZED");
        require(tokens.length == amounts.length, "!length");
        uint poolTotal = pool.totalSupply();
        uint minRatio = MAX;
        for (uint i = 0; i < tokens.length; i++) {
            address t = tokens[i];
            uint bal = pool.getBalance(t);
            uint ratio = bdiv(amounts[i], poolTotal);
            if (ratio <= minRatio) {
                minRatio = ratio;
            }
        }
        poolAmountOut = bmul(minRatio, poolTotal);
        return poolAmountOut;
    }

    function getSingleTokenInGivenPoolOut(
        address tokenIn, uint256 tokenAmountIn
    ) external view returns (uint poolAmountOut){
        require(pool.isFinalized(), "ERR_NOT_FINALIZED");
        require(pool.isBound(tokenIn), "ERR_NOT_BOUND");
        require(tokenAmountIn <= bmul(pool.getBalance(tokenIn), MAX_IN_RATIO), "ERR_MAX_IN_RATIO");

        uint _swapFee = pool.swapFee();
        uint inRecordBalance = pool.getBalance(tokenIn);
        uint inRecordDenorm = pool.getDenormalizedWeight(tokenIn);
        uint _totalSupply = pool.totalSupply();
        uint _totalWeight = pool.getTotalDenormalizedWeight();
        poolAmountOut = calcPoolOutGivenSingleIn(
            inRecordBalance,
            inRecordDenorm,
            _totalSupply,
            _totalWeight,
            tokenAmountIn,
            _swapFee
        );
        return poolAmountOut;
    }


    function getPoolInGivenTokenOut(
        address tokenOut, uint poolAmountIn, uint minAmountOut
    ) external view returns (uint tokenAmountOut){
        require(pool.isFinalized(), "ERR_NOT_FINALIZED");
        require(pool.isBound(tokenOut), "ERR_NOT_BOUND");

        uint _swapFee = pool.swapFee();
        uint outRecordBalance = pool.getBalance(tokenOut);
        uint outRecordDenorm = pool.getDenormalizedWeight(tokenOut);
        uint _totalSupply = pool.totalSupply();
        uint _totalWeight = pool.getTotalDenormalizedWeight();
        uint _exitFee = pool.getExitFee();
        tokenAmountOut = calcSingleOutGivenPoolIn(
            outRecordBalance,
            outRecordDenorm,
            _totalSupply,
            _totalWeight,
            poolAmountIn,
            _swapFee,
            _exitFee
        );
        return tokenAmountOut;
    }

    function decimals() public view returns (uint8) {
        return pool.decimals();
    }

    function isBound(address _token) public view returns (bool){
        return pool.isBound(_token);
    }

    function totalSupply() public view returns (uint256) {
        return pool.totalSupply();
    }
}

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is disstributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.5.9;

// Builds new BPools, logging their addresses and providing `isBPool(address) -> (bool)`

contract BFactory {

  event LOG_NEW_POOL(
      address indexed caller,
      address indexed pool
  );

  BPool[] public allPools;
  mapping(address => bool) private _isBPool;
  address public controller;
  address public factoryManager;
  address public feeAddress;
  address public tusdAddress;

  constructor(address _factoryManager,address _feeAddress,address _tusdAddress) public {
      controller = msg.sender;
      factoryManager = _factoryManager;
      feeAddress = _feeAddress;
      tusdAddress = _tusdAddress;
  }

  function isBPool(address b) external view returns (bool){
      return _isBPool[b];
  }

  function newBPool() external returns (BPool){
      BPool bpool = new BPool(factoryManager,feeAddress,tusdAddress);
      _isBPool[address(bpool)] = true;
      emit LOG_NEW_POOL(msg.sender, address(bpool));
      bpool.setController(msg.sender);
      allPools.push(bpool);
      return bpool;
  }


  function setController(address _controller) external {
      require(msg.sender == controller, "!controller");
      controller = _controller;
  }

  function poolLength() external view returns (uint){
      return allPools.length;
  }

  function setFeeAddress(address _feeAddress) external {
      require(msg.sender == controller, "!controller");
      feeAddress = _feeAddress;
  }

  function setTusdAddress(address _tusdAddress) external {
      require(msg.sender == controller, "!controller");
      tusdAddress = _tusdAddress;
  }


}


pragma solidity ^0.5.9;

contract FactoryManager is BParam, BMath, Ownable {

    uint256 public goverFundDivRate = 3 * CENTI_FEE;
    address public governaddr;

    uint256 public burnRate = 15 * CENTI_FEE;

    uint public  exitFee = 0;
    uint public swapFeeForDex = 0;
    uint public dexTokenAmount = 10000 * 1e18;
    address public controller;
    mapping(address => address) swapPools;

    address public dexToken;
    address public baseToken;
    address public basePool;

    address public factory;

    uint256 private setFactoryManagerCount = 0;
    uint256 private setBasePoolCount = 0;

    constructor() public {
        controller = msg.sender;
    }

    function setController(address _controller) onlyOwner external {
        controller = _controller;
    }

    function setFactory(address _factory) external {
        require(msg.sender == controller, "!controller");
        require(setFactoryManagerCount < 2, "limit factory address");
        factory = _factory;
        setFactoryManagerCount = badd(setFactoryManagerCount, 1);
    }

    function setDexTokenAmount(uint _amount) external {
        require(msg.sender == controller, "!controller");
        dexTokenAmount = _amount;
    }

    function getSwapPool(address token) public view returns (address){
        return swapPools[token];
    }


    function addSwapPools(address token, address pool) public {
        require(msg.sender == controller, "!controller");
        require(factory != address(0), "factory=0");
        require(BFactory(factory).isBPool(pool), "!pool");
        swapPools[token] = pool;

    }

    function removeSwapPools(address token) public {
        require(msg.sender == controller, "!controller");
        swapPools[token] = address(0);

    }

    function setExitFee(uint _exitFee) public {
        require(msg.sender == controller, "!controller");
        require(_exitFee <= CENTI_FEE, "ERR_MAX_EXIT_FEE");
        exitFee = _exitFee;
    }

    function setSwapFeeForDex(uint _fee) public {
        require(msg.sender == controller, "!controller");
        require(_fee <= CENTI_FEE, "ERR_MAX_EXIT_FEE");
        swapFeeForDex = _fee;
    }

    function claimToken(address token) public {
        require(msg.sender == controller, "!controller");
        address _pool = swapPools[token];
        require(_pool != address(0), "not set pool");
        require(baseToken != address(0), "not set base token");
        swapToken(_pool, token, baseToken);
    }


    function swapToken(
        address poolAddress, address tokenIn, address tokenOut
    ) public returns (uint){
        require(msg.sender == controller, "!controller");
        require(factory != address(0), "factory=0");
        require(BFactory(factory).isBPool(poolAddress), "!pool");
        BPool pool = BPool(poolAddress);
        uint _tokenInAmount = IERC20(tokenIn).balanceOf(address(this));
        IERC20(tokenIn).approve(poolAddress, _tokenInAmount);
        (uint tokenAmountOut,) = pool.swapExactAmountIn(tokenIn, _tokenInAmount, tokenOut, 0, MAX);
        return tokenAmountOut;
    }

    function addRewardPoolLiquidity() external {
        require(IERC20(dexToken).balanceOf(msg.sender) >= dexTokenAmount, "not enough token");
        uint _amount = IERC20(baseToken).balanceOf(address(this));
        uint256 _goverFund = bmul(_amount, goverFundDivRate);
        IERC20(baseToken).transfer(governaddr, _goverFund);

        uint _tokenInAmount = bmul(_amount, burnRate);

        IERC20(baseToken).approve(basePool, _tokenInAmount);
        BPool(basePool).swapExactAmountIn(baseToken, _tokenInAmount, dexToken, 0, MAX);

        _amount = bsub(_amount, _goverFund);
        _amount = bsub(_amount, _tokenInAmount);

        IERC20(baseToken).approve(basePool, _amount);
        BPool(basePool).joinswapExternAmountIn(baseToken, _amount, 0);
    }

    function collect(address poolAddress) public {
        require(factory != address(0), "factory is 0");
        require(BFactory(factory).isBPool(poolAddress), "!pool");
        BPool(poolAddress).claimFactoryFund();
        if (basePool != poolAddress) {
            removeLiquidity(poolAddress);
        }
    }

    function removeLiquidity(address poolAddress) private {
        uint _amount = IERC20(poolAddress).balanceOf(address(this));
        if (_amount > 0) {
            uint[] memory amountOuts = new uint[](BPool(poolAddress).getNumTokens());
            BPool(poolAddress).exitPool(_amount, amountOuts);
        }
    }

    function burnToken() public {
        uint _amount = IERC20(dexToken).balanceOf(address(this));
        if (_amount > 0) {
            RewardToken(dexToken).burn(_amount);
        }
    }


    function setBasePoolToken(address _pool, address _dexToken, address _baseToken) public {
        require(msg.sender == controller, "!controller");
        require(factory != address(0), "factory is 0");
        require(BFactory(factory).isBPool(_pool), "!pool");
        require(BPool(_pool).isBound(_dexToken), "not bound");
        require(BPool(_pool).isBound(_baseToken), "not bound");
        require(setBasePoolCount < 2, "limit set base pool");
        setBasePoolCount = badd(setBasePoolCount, 1);
        basePool = _pool;
        dexToken = _dexToken;
        baseToken = _baseToken;

    }

    function gover(address _goveraddr) public {
        require(msg.sender == controller, "!controller");
        governaddr = _goveraddr;
    }

    function setBurnRate(uint _rate) public {
        require(msg.sender == controller, "!controller");
        require(_rate < 50 * CENTI_FEE, "< MAX_FEE");
        burnRate = _rate;
    }

    function setGoverFundDivRate(uint256 _goverFundDivRate) public {
        require(msg.sender == controller, "!controller");
        require(_goverFundDivRate < MAX_FEE, "< MAX_FEE");
        goverFundDivRate = _goverFundDivRate;
    }

    function claimOtherToken(address _pool, address _token) external {
        require(msg.sender == controller, "!controller");
        BPool(_pool).withdrawToken(_token);

    }

}