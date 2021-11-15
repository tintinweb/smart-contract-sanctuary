// SPDX-License-Identifier: GPL-3.0
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

pragma solidity 0.6.12;

contract BConst {
    uint public constant BONE              = 10**18;

    uint public constant MIN_BOUND_TOKENS  = 2;
    uint public constant MAX_BOUND_TOKENS  = 9;

    uint public constant MIN_FEE           = BONE / 10**6;
    uint public constant MAX_FEE           = BONE / 10;

    uint public constant MIN_WEIGHT        = 1000000000;
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

// SPDX-License-Identifier: GPL-3.0
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

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
      require(b > 0, "ERR_DIV_ZERO");
      return a / b;
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

// SPDX-License-Identifier: GPL-3.0
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

pragma solidity 0.6.12;

import "./BNum.sol";
import "../interfaces/BMathInterface.sol";

contract BMath is BConst, BNum, BMathInterface {
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
    )
        public pure
        returns (uint spotPrice)
    {
        uint numer = bdiv(tokenBalanceIn, tokenWeightIn);
        uint denom = bdiv(tokenBalanceOut, tokenWeightOut);
        uint ratio = bdiv(numer, denom);
        uint scale = bdiv(BONE, bsub(BONE, swapFee));
        return  (spotPrice = bmul(ratio, scale));
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
    )
        public pure
        returns (uint tokenAmountOut)
    {
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
    )
        public pure override
        returns (uint tokenAmountIn)
    {
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
    )
        public pure
        returns (uint poolAmountOut)
    {
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
    )
        public pure
        returns (uint tokenAmountIn)
    {
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
    // bO = tokenBalanceOut           /      //       pS - pAi        \     /    1    \      \\  //
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
        uint swapFee
    )
        public pure
        returns (uint tokenAmountOut)
    {
        uint normalizedWeight = bdiv(tokenWeightOut, totalWeight);
        uint newPoolSupply = bsub(poolSupply, poolAmountIn);
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
    // tW = totalWeight                                                                          //
    // sF = swapFee                                                                              //
    **********************************************************************************************/
    function calcPoolInGivenSingleOut(
        uint tokenBalanceOut,
        uint tokenWeightOut,
        uint poolSupply,
        uint totalWeight,
        uint tokenAmountOut,
        uint swapFee
    )
        public pure
        returns (uint poolAmountIn)
    {

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
        uint poolAmountIn = bsub(poolSupply, newPoolSupply);
        return poolAmountIn;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface BMathInterface {
  function calcInGivenOut(
    uint256 tokenBalanceIn,
    uint256 tokenWeightIn,
    uint256 tokenBalanceOut,
    uint256 tokenWeightOut,
    uint256 tokenAmountOut,
    uint256 swapFee
  ) external pure returns (uint256 tokenAmountIn);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./BMathInterface.sol";

interface BPoolInterface is IERC20, BMathInterface {
  function joinPool(uint256 poolAmountOut, uint256[] calldata maxAmountsIn) external;

  function exitPool(uint256 poolAmountIn, uint256[] calldata minAmountsOut) external;

  function swapExactAmountIn(
    address,
    uint256,
    address,
    uint256,
    uint256
  ) external returns (uint256, uint256);

  function swapExactAmountOut(
    address,
    uint256,
    address,
    uint256,
    uint256
  ) external returns (uint256, uint256);

  function joinswapExternAmountIn(
    address,
    uint256,
    uint256
  ) external returns (uint256);

  function joinswapPoolAmountOut(
    address,
    uint256,
    uint256
  ) external returns (uint256);

  function exitswapPoolAmountIn(
    address,
    uint256,
    uint256
  ) external returns (uint256);

  function exitswapExternAmountOut(
    address,
    uint256,
    uint256
  ) external returns (uint256);

  function getDenormalizedWeight(address) external view returns (uint256);

  function getBalance(address) external view returns (uint256);

  function getSwapFee() external view returns (uint256);

  function getTotalDenormalizedWeight() external view returns (uint256);

  function getCommunityFee()
    external
    view
    returns (
      uint256,
      uint256,
      uint256,
      address
    );

  function calcAmountWithCommunityFee(
    uint256,
    uint256,
    address
  ) external view returns (uint256, uint256);

  function getRestrictions() external view returns (address);

  function isPublicSwap() external view returns (bool);

  function isFinalized() external view returns (bool);

  function isBound(address t) external view returns (bool);

  function getCurrentTokens() external view returns (address[] memory tokens);

  function getFinalTokens() external view returns (address[] memory tokens);

  function setSwapFee(uint256) external;

  function setCommunityFeeAndReceiver(
    uint256,
    uint256,
    uint256,
    address
  ) external;

  function setController(address) external;

  function setPublicSwap(bool) external;

  function finalize() external;

  function bind(
    address,
    uint256,
    uint256
  ) external;

  function rebind(
    address,
    uint256,
    uint256
  ) external;

  function unbind(address) external;

  function callVoting(
    address voting,
    bytes4 signature,
    bytes calldata args,
    uint256 value
  ) external;

  function getMinWeight() external view returns (uint256);

  function getMaxBoundTokens() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./BPoolInterface.sol";

interface PowerIndexPoolInterface is BPoolInterface {
  function bind(
    address,
    uint256,
    uint256,
    uint256,
    uint256
  ) external;

  function setDynamicWeight(
    address token,
    uint256 targetDenorm,
    uint256 fromTimestamp,
    uint256 targetTimestamp
  ) external;

  function getDynamicWeightSettings(address token)
    external
    view
    returns (
      uint256 fromTimestamp,
      uint256 targetTimestamp,
      uint256 fromDenorm,
      uint256 targetDenorm
    );

  function getMinWeight() external view override returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0
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

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/PowerIndexPoolInterface.sol";
import "./interfaces/PowerIndexPoolFactoryInterface.sol";

contract PowerIndexPoolActions {
  struct Args {
    uint256 minWeightPerSecond;
    uint256 maxWeightPerSecond;
    uint256 swapFee;
    uint256 communitySwapFee;
    uint256 communityJoinFee;
    uint256 communityExitFee;
    address communityFeeReceiver;
    bool finalize;
  }

  struct TokenConfig {
    address token;
    uint256 balance;
    uint256 targetDenorm;
    uint256 fromTimestamp;
    uint256 targetTimestamp;
  }

  function create(
    PowerIndexPoolFactoryInterface factory,
    string calldata name,
    string calldata symbol,
    Args calldata args,
    TokenConfig[] calldata tokens
  ) external returns (PowerIndexPoolInterface pool) {
    pool = factory.newPool(name, symbol, args.minWeightPerSecond, args.maxWeightPerSecond);
    pool.setSwapFee(args.swapFee);
    pool.setCommunityFeeAndReceiver(
      args.communitySwapFee,
      args.communityJoinFee,
      args.communityExitFee,
      args.communityFeeReceiver
    );

    for (uint256 i = 0; i < tokens.length; i++) {
      TokenConfig memory tokenConfig = tokens[i];
      IERC20 token = IERC20(tokenConfig.token);
      require(token.transferFrom(msg.sender, address(this), tokenConfig.balance), "ERR_TRANSFER_FAILED");
      if (token.allowance(address(this), address(pool)) > 0) {
        token.approve(address(pool), 0);
      }
      token.approve(address(pool), tokenConfig.balance);
      pool.bind(
        tokenConfig.token,
        tokenConfig.balance,
        tokenConfig.targetDenorm,
        tokenConfig.fromTimestamp,
        tokenConfig.targetTimestamp
      );
    }

    if (args.finalize) {
      pool.finalize();
      require(pool.transfer(msg.sender, pool.balanceOf(address(this))), "ERR_TRANSFER_FAILED");
    } else {
      pool.setPublicSwap(true);
    }

    pool.setController(msg.sender);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./PowerIndexPoolInterface.sol";

interface PowerIndexPoolFactoryInterface {
  function newPool(
    string calldata name,
    string calldata symbol,
    uint256 minWeightPerSecond,
    uint256 maxWeightPerSecond
  ) external returns (PowerIndexPoolInterface);
}

// SPDX-License-Identifier: GPL-3.0
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

pragma solidity 0.6.12;

// Builds new Power Index Pools, logging their addresses and providing `isPowerIndexPool(address) -> (bool)`

import "./PowerIndexPool.sol";
import "./interfaces/PowerIndexPoolFactoryInterface.sol";

contract PowerIndexPoolFactory is PowerIndexPoolFactoryInterface {
  event LOG_NEW_POOL(address indexed caller, address indexed pool);

  mapping(address => bool) public isPowerIndexPool;

  constructor() public {}

  function newPool(
    string calldata name,
    string calldata symbol,
    uint256 minWeightPerSecond,
    uint256 maxWeightPerSecond
  ) external override returns (PowerIndexPoolInterface) {
    PowerIndexPool pool = new PowerIndexPool(name, symbol, minWeightPerSecond, maxWeightPerSecond);
    isPowerIndexPool[address(pool)] = true;
    emit LOG_NEW_POOL(msg.sender, address(pool));
    pool.setController(msg.sender);
    return PowerIndexPoolInterface(address(pool));
  }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.6.12;

import "./balancer-core/BPool.sol";
import "./interfaces/PowerIndexPoolInterface.sol";

contract PowerIndexPool is BPool {
  /// @notice The event emitted when a dynamic weight set to token
  event SetDynamicWeight(
    address indexed token,
    uint256 fromDenorm,
    uint256 targetDenorm,
    uint256 fromTimestamp,
    uint256 targetTimestamp
  );

  /// @notice The event emitted when weight per second bounds set
  event SetWeightPerSecondBounds(uint256 minWeightPerSecond, uint256 maxWeightPerSecond);

  struct DynamicWeight {
    uint256 fromTimestamp;
    uint256 targetTimestamp;
    uint256 targetDenorm;
  }

  /// @dev Mapping for storing dynamic weights settings. fromDenorm stored in _records mapping as denorm variable
  mapping(address => DynamicWeight) private _dynamicWeights;

  /// @dev Min weight per second limit
  uint256 private _minWeightPerSecond;
  /// @dev Max weight per second limit
  uint256 private _maxWeightPerSecond;

  constructor(
    string memory name,
    string memory symbol,
    uint256 minWeightPerSecond,
    uint256 maxWeightPerSecond
  ) public BPool(name, symbol) {
    _minWeightPerSecond = minWeightPerSecond;
    _maxWeightPerSecond = maxWeightPerSecond;
  }

  /*** Controller Interface ***/

  /**
   * @notice Set weight per second bounds by controller
   * @param minWeightPerSecond Min weight per second
   * @param maxWeightPerSecond Max weight per second
   */
  function setWeightPerSecondBounds(uint256 minWeightPerSecond, uint256 maxWeightPerSecond) public _logs_ _lock_ {
    _onlyController();
    _minWeightPerSecond = minWeightPerSecond;
    _maxWeightPerSecond = maxWeightPerSecond;

    emit SetWeightPerSecondBounds(minWeightPerSecond, maxWeightPerSecond);
  }

  /**
   * @notice Set dynamic weight for token by controller
   * @param token Token for change settings
   * @param targetDenorm Target weight. fromDenorm will be fetch by current value of _getDenormWeight
   * @param fromTimestamp From timestamp of dynamic weight
   * @param targetTimestamp Target timestamp of dynamic weight
   */
  function setDynamicWeight(
    address token,
    uint256 targetDenorm,
    uint256 fromTimestamp,
    uint256 targetTimestamp
  ) public _logs_ _lock_ {
    _onlyController();
    _requireTokenIsBound(token);

    require(fromTimestamp > block.timestamp, "CANT_SET_PAST_TIMESTAMP");
    require(targetTimestamp > fromTimestamp, "TIMESTAMP_INCORRECT_DELTA");
    require(targetDenorm >= MIN_WEIGHT && targetDenorm <= MAX_WEIGHT, "TARGET_WEIGHT_BOUNDS");

    uint256 fromDenorm = _getDenormWeight(token);
    uint256 weightPerSecond = _getWeightPerSecond(fromDenorm, targetDenorm, fromTimestamp, targetTimestamp);
    require(weightPerSecond <= _maxWeightPerSecond, "MAX_WEIGHT_PER_SECOND");
    require(weightPerSecond >= _minWeightPerSecond, "MIN_WEIGHT_PER_SECOND");

    _records[token].denorm = fromDenorm;

    _dynamicWeights[token] = DynamicWeight({
      fromTimestamp: fromTimestamp,
      targetTimestamp: targetTimestamp,
      targetDenorm: targetDenorm
    });

    uint256 denormSum = 0;
    uint256 len = _tokens.length;
    for (uint256 i = 0; i < len; i++) {
      denormSum = badd(denormSum, _dynamicWeights[_tokens[i]].targetDenorm);
    }

    require(denormSum <= MAX_TOTAL_WEIGHT, "MAX_TARGET_TOTAL_WEIGHT");

    emit SetDynamicWeight(token, fromDenorm, targetDenorm, fromTimestamp, targetTimestamp);
  }

  /**
   * @notice Bind and setDynamicWeight at the same time
   * @param token Token for bind
   * @param balance Initial balance
   * @param targetDenorm Target weight
   * @param fromTimestamp From timestamp of dynamic weight
   * @param targetTimestamp Target timestamp of dynamic weight
   */
  function bind(
    address token,
    uint256 balance,
    uint256 targetDenorm,
    uint256 fromTimestamp,
    uint256 targetTimestamp
  )
    external
    _logs_ // _lock_  Bind does not lock because it jumps to `rebind` and `setDynamicWeight`, which does
  {
    super.bind(token, balance, MIN_WEIGHT);

    setDynamicWeight(token, targetDenorm, fromTimestamp, targetTimestamp);
  }

  /**
   * @notice Override parent unbind function
   * @param token Token for unbind
   */
  function unbind(address token) public override {
    super.unbind(token);

    _dynamicWeights[token] = DynamicWeight(0, 0, 0);
  }

  /**
   * @notice Override parent bind function and disable.
   */
  function bind(
    address,
    uint256,
    uint256
  ) public override {
    revert("DISABLED"); // Only new bind function is allowed
  }

  /**
   * @notice Override parent rebind function. Allowed only for calling from bind function
   * @param token Token for rebind
   * @param balance Balance for rebind
   * @param denorm Weight for rebind
   */
  function rebind(
    address token,
    uint256 balance,
    uint256 denorm
  ) public override {
    require(denorm == MIN_WEIGHT && _dynamicWeights[token].fromTimestamp == 0, "ONLY_NEW_TOKENS_ALLOWED");
    super.rebind(token, balance, denorm);
  }

  /*** View Functions ***/

  function getDynamicWeightSettings(address token)
    external
    view
    returns (
      uint256 fromTimestamp,
      uint256 targetTimestamp,
      uint256 fromDenorm,
      uint256 targetDenorm
    )
  {
    DynamicWeight storage dw = _dynamicWeights[token];
    return (dw.fromTimestamp, dw.targetTimestamp, _records[token].denorm, dw.targetDenorm);
  }

  function getWeightPerSecondBounds() external view returns (uint256 minWeightPerSecond, uint256 maxWeightPerSecond) {
    return (_minWeightPerSecond, _maxWeightPerSecond);
  }

  /*** Internal Functions ***/

  function _getDenormWeight(address token) internal view override returns (uint256) {
    DynamicWeight memory dw = _dynamicWeights[token];
    uint256 fromDenorm = _records[token].denorm;

    if (dw.fromTimestamp == 0 || dw.targetDenorm == fromDenorm || block.timestamp <= dw.fromTimestamp) {
      return fromDenorm;
    }
    if (block.timestamp >= dw.targetTimestamp) {
      return dw.targetDenorm;
    }

    uint256 weightPerSecond = _getWeightPerSecond(fromDenorm, dw.targetDenorm, dw.fromTimestamp, dw.targetTimestamp);
    uint256 deltaCurrentTime = bsub(block.timestamp, dw.fromTimestamp);
    if (dw.targetDenorm > fromDenorm) {
      return badd(fromDenorm, deltaCurrentTime * weightPerSecond);
    } else {
      return bsub(fromDenorm, deltaCurrentTime * weightPerSecond);
    }
  }

  function _getWeightPerSecond(
    uint256 fromDenorm,
    uint256 targetDenorm,
    uint256 fromTimestamp,
    uint256 targetTimestamp
  ) internal pure returns (uint256) {
    uint256 delta = targetDenorm > fromDenorm ? bsub(targetDenorm, fromDenorm) : bsub(fromDenorm, targetDenorm);
    return div(delta, bsub(targetTimestamp, fromTimestamp));
  }

  function _getTotalWeight() internal view override returns (uint256) {
    uint256 sum = 0;
    uint256 len = _tokens.length;
    for (uint256 i = 0; i < len; i++) {
      sum = badd(sum, _getDenormWeight(_tokens[i]));
    }
    return sum;
  }

  function _addTotalWeight(uint256 _amount) internal virtual override {
    // storage total weight don't change, it's calculated only by _getTotalWeight()
  }

  function _subTotalWeight(uint256 _amount) internal virtual override {
    // storage total weight don't change, it's calculated only by _getTotalWeight()
  }
}

// SPDX-License-Identifier: GPL-3.0
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

pragma solidity 0.6.12;

import "./BToken.sol";
import "./BMath.sol";
import "../interfaces/IPoolRestrictions.sol";
import "../interfaces/BPoolInterface.sol";

contract BPool is BToken, BMath, BPoolInterface {

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
        uint256         tokenAmountIn,
        uint256         tokenAmountOut
    );

    event LOG_JOIN(
        address indexed caller,
        address indexed tokenIn,
        uint256         tokenAmountIn
    );

    event LOG_EXIT(
        address indexed caller,
        address indexed tokenOut,
        uint256         tokenAmountOut
    );

    event LOG_CALL(
        bytes4  indexed sig,
        address indexed caller,
        bytes           data
    ) anonymous;

    event LOG_CALL_VOTING(
        address indexed voting,
        bool    indexed success,
        bytes4  indexed inputSig,
        bytes           inputData,
        bytes           outputData
    );

    event LOG_COMMUNITY_FEE(
        address indexed caller,
        address indexed receiver,
        address indexed token,
        uint256         tokenAmount
    );

    modifier _logs_() {
        emit LOG_CALL(msg.sig, msg.sender, msg.data);
        _;
    }

    modifier _lock_() {
        _preventReentrancy();
        _mutex = true;
        _;
        _mutex = false;
    }

    modifier _viewlock_() {
        _preventReentrancy();
        _;
    }

    bool private _mutex;

    address private _controller; // has CONTROL role
    bool private _publicSwap; // true if PUBLIC can call SWAP functions

    address private _wrapper; // can join, exit and swaps when _wrapperMode is true
    bool private _wrapperMode;

    IPoolRestrictions private _restrictions;

    // `setSwapFee` and `finalize` require CONTROL
    // `finalize` sets `PUBLIC can SWAP`, `PUBLIC can JOIN`
    uint private _swapFee;
    uint private _communitySwapFee;
    uint private _communityJoinFee;
    uint private _communityExitFee;
    address private _communityFeeReceiver;
    bool private _finalized;

    address[] internal _tokens;
    mapping(address => Record) internal _records;
    uint internal _totalWeight;

    mapping(address => uint256) internal _lastSwapBlock;

    constructor(string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;
        _controller = msg.sender;
        _swapFee = MIN_FEE;
        _communitySwapFee = 0;
        _communityJoinFee = 0;
        _communityExitFee = 0;
        _publicSwap = false;
        _finalized = false;
    }

    function isPublicSwap()
        external view override
        returns (bool)
    {
        return _publicSwap;
    }

    function isFinalized()
        external view override
        returns (bool)
    {
        return _finalized;
    }

    function isBound(address t)
        external view override
        returns (bool)
    {
        return _records[t].bound;
    }

    function getNumTokens()
        external view
        returns (uint)
    {
        return _tokens.length;
    }

    function getCurrentTokens()
        external view override
        _viewlock_
        returns (address[] memory tokens)
    {
        return _tokens;
    }

    function getFinalTokens()
        external view override
        _viewlock_
        returns (address[] memory tokens)
    {
        _requireContractIsFinalized();
        return _tokens;
    }

    function getDenormalizedWeight(address token)
        external view override
        _viewlock_
        returns (uint)
    {

        _requireTokenIsBound(token);
        return _getDenormWeight(token);
    }

    function getTotalDenormalizedWeight()
        external view override
        _viewlock_
        returns (uint)
    {
        return _getTotalWeight();
    }

    function getNormalizedWeight(address token)
        external view
        _viewlock_
        returns (uint)
    {

        _requireTokenIsBound(token);
        return bdiv(_getDenormWeight(token), _getTotalWeight());
    }

    function getBalance(address token)
        external view override
        _viewlock_
        returns (uint)
    {

        _requireTokenIsBound(token);
        return _records[token].balance;
    }

    function getSwapFee()
        external view override
        _viewlock_
        returns (uint)
    {
        return _swapFee;
    }

    function getCommunityFee()
        external view override
        _viewlock_
        returns (uint communitySwapFee, uint communityJoinFee, uint communityExitFee, address communityFeeReceiver)
    {
        return (_communitySwapFee, _communityJoinFee, _communityExitFee, _communityFeeReceiver);
    }

    function getController()
        external view
        _viewlock_
        returns (address)
    {
        return _controller;
    }

    function getWrapper()
        external view
        _viewlock_
        returns (address)
    {
        return _wrapper;
    }

    function getWrapperMode()
        external view
        _viewlock_
        returns (bool)
    {
        return _wrapperMode;
    }

    function getRestrictions()
        external view override
        _viewlock_
        returns (address)
    {
        return address(_restrictions);
    }

    function setSwapFee(uint swapFee)
        external override
        _logs_
        _lock_
    {
        _onlyController();
        _requireFeeInBounds(swapFee);
        _swapFee = swapFee;
    }

    function setCommunityFeeAndReceiver(
        uint communitySwapFee,
        uint communityJoinFee,
        uint communityExitFee,
        address communityFeeReceiver
    )
        external override
        _logs_
        _lock_
    {
        _onlyController();
        _requireFeeInBounds(communitySwapFee);
        _requireFeeInBounds(communityJoinFee);
        _requireFeeInBounds(communityExitFee);
        _communitySwapFee = communitySwapFee;
        _communityJoinFee = communityJoinFee;
        _communityExitFee = communityExitFee;
        _communityFeeReceiver = communityFeeReceiver;
    }

    function setRestrictions(IPoolRestrictions restrictions)
        external
        _logs_
        _lock_
    {
        _onlyController();
        _restrictions = restrictions;
    }

    function setController(address manager)
        external override
        _logs_
        _lock_
    {
        _onlyController();
        _controller = manager;
    }

    function setPublicSwap(bool public_)
        external override
        _logs_
        _lock_
    {
        _requireContractIsNotFinalized();
        _onlyController();
        _publicSwap = public_;
    }

    function setWrapper(address wrapper, bool wrapperMode)
        external
        _logs_
        _lock_
    {
        _onlyController();
        _wrapper = wrapper;
        _wrapperMode = wrapperMode;
    }

    function finalize()
        external override
        _logs_
        _lock_
    {
        _onlyController();
        _requireContractIsNotFinalized();
        require(_tokens.length >= MIN_BOUND_TOKENS, "MIN_TOKENS");

        _finalized = true;
        _publicSwap = true;

        _mintPoolShare(INIT_POOL_SUPPLY);
        _pushPoolShare(msg.sender, INIT_POOL_SUPPLY);
    }

    function callVoting(address voting, bytes4 signature, bytes calldata args, uint256 value)
        external override
        _logs_
        _lock_
    {
        require(_restrictions.isVotingSignatureAllowed(voting, signature), "NOT_ALLOWED_SIG");
        _onlyController();

        (bool success, bytes memory data) = voting.call{ value: value }(abi.encodePacked(signature, args));
        require(success, "NOT_SUCCESS");
        emit LOG_CALL_VOTING(voting, success, signature, args, data);
    }

    function bind(address token, uint balance, uint denorm)
        public override
        virtual
        _logs_
        // _lock_  Bind does not lock because it jumps to `rebind`, which does
    {
        _onlyController();
        require(!_records[token].bound, "IS_BOUND");

        require(_tokens.length < MAX_BOUND_TOKENS, "MAX_TOKENS");

        _records[token] = Record({
            bound: true,
            index: _tokens.length,
            denorm: 0,    // balance and denorm will be validated
            balance: 0   // and set by `rebind`
        });
        _tokens.push(token);
        rebind(token, balance, denorm);
    }

    function rebind(address token, uint balance, uint denorm)
        public override
        virtual
        _logs_
        _lock_
    {
        _onlyController();
        _requireTokenIsBound(token);

        require(denorm >= MIN_WEIGHT && denorm <= MAX_WEIGHT, "WEIGHT_BOUNDS");
        require(balance >= MIN_BALANCE, "MIN_BALANCE");

        // Adjust the denorm and totalWeight
        uint oldWeight = _records[token].denorm;
        if (denorm > oldWeight) {
            _addTotalWeight(bsub(denorm, oldWeight));
        } else if (denorm < oldWeight) {
            _subTotalWeight(bsub(oldWeight, denorm));
        }
        _records[token].denorm = denorm;

        // Adjust the balance record and actual token balance
        uint oldBalance = _records[token].balance;
        _records[token].balance = balance;
        if (balance > oldBalance) {
            _pullUnderlying(token, msg.sender, bsub(balance, oldBalance));
        } else if (balance < oldBalance) {
            uint tokenBalanceWithdrawn = bsub(oldBalance, balance);
            _pushUnderlying(token, msg.sender, tokenBalanceWithdrawn);
        }
    }

    function unbind(address token)
        public override
        virtual
        _logs_
        _lock_
    {
        _onlyController();
        _requireTokenIsBound(token);

        uint tokenBalance = _records[token].balance;

        _subTotalWeight(_records[token].denorm);

        // Swap the token-to-unbind with the last token,
        // then delete the last token
        uint index = _records[token].index;
        uint last = _tokens.length - 1;
        _tokens[index] = _tokens[last];
        _records[_tokens[index]].index = index;
        _tokens.pop();
        _records[token] = Record({
            bound: false,
            index: 0,
            denorm: 0,
            balance: 0
        });

        _pushUnderlying(token, msg.sender, tokenBalance);
    }

    // Absorb any tokens that have been sent to this contract into the pool
    function gulp(address token)
        external
        _logs_
        _lock_
    {
        _requireTokenIsBound(token);
        _records[token].balance = IERC20(token).balanceOf(address(this));
    }

    function getSpotPrice(address tokenIn, address tokenOut)
        external view
        _viewlock_
        returns (uint spotPrice)
    {
        require(_records[tokenIn].bound && _records[tokenOut].bound, "NOT_BOUND");
        Record storage inRecord = _records[tokenIn];
        Record storage outRecord = _records[tokenOut];
        return calcSpotPrice(inRecord.balance, _getDenormWeight(tokenIn), outRecord.balance, _getDenormWeight(tokenOut), _swapFee);
    }

    function getSpotPriceSansFee(address tokenIn, address tokenOut)
        external view
        _viewlock_
        returns (uint spotPrice)
    {
        _requireTokenIsBound(tokenIn);
        _requireTokenIsBound(tokenOut);
        Record storage inRecord = _records[tokenIn];
        Record storage outRecord = _records[tokenOut];
        return calcSpotPrice(inRecord.balance, _getDenormWeight(tokenIn), outRecord.balance, _getDenormWeight(tokenOut), 0);
    }

    function joinPool(uint poolAmountOut, uint[] calldata maxAmountsIn)
        external override
        _logs_
        _lock_
    {
        _preventSameTxOrigin();
        _onlyWrapperOrNotWrapperMode();
        _requireContractIsFinalized();

        uint poolTotal = totalSupply();
        uint ratio = bdiv(poolAmountOut, poolTotal);
        _requireMathApprox(ratio);

        for (uint i = 0; i < _tokens.length; i++) {
            address t = _tokens[i];
            uint bal = _records[t].balance;
            uint tokenAmountIn = bmul(ratio, bal);
            _requireMathApprox(tokenAmountIn);
            require(tokenAmountIn <= maxAmountsIn[i], "LIMIT_IN");
            _records[t].balance = badd(_records[t].balance, tokenAmountIn);
            emit LOG_JOIN(msg.sender, t, tokenAmountIn);
            _pullUnderlying(t, msg.sender, tokenAmountIn);
        }

        (uint poolAmountOutAfterFee, uint poolAmountOutFee) = calcAmountWithCommunityFee(
            poolAmountOut,
            _communityJoinFee,
            msg.sender
        );

        _mintPoolShare(poolAmountOut);
        _pushPoolShare(msg.sender, poolAmountOutAfterFee);
        _pushPoolShare(_communityFeeReceiver, poolAmountOutFee);

        emit LOG_COMMUNITY_FEE(msg.sender, _communityFeeReceiver, address(this), poolAmountOutFee);
    }

    function exitPool(uint poolAmountIn, uint[] calldata minAmountsOut)
        external override
        _logs_
        _lock_
    {
        _preventSameTxOrigin();
        _onlyWrapperOrNotWrapperMode();
        _requireContractIsFinalized();

        (uint poolAmountInAfterFee, uint poolAmountInFee) = calcAmountWithCommunityFee(
            poolAmountIn,
            _communityExitFee,
            msg.sender
        );

        uint poolTotal = totalSupply();
        uint ratio = bdiv(poolAmountInAfterFee, poolTotal);
        _requireMathApprox(ratio);

        _pullPoolShare(msg.sender, poolAmountIn);
        _pushPoolShare(_communityFeeReceiver, poolAmountInFee);
        _burnPoolShare(poolAmountInAfterFee);

        for (uint i = 0; i < _tokens.length; i++) {
            address t = _tokens[i];
            uint bal = _records[t].balance;
            uint tokenAmountOut = bmul(ratio, bal);
            _requireMathApprox(tokenAmountOut);
            require(tokenAmountOut >= minAmountsOut[i], "LIMIT_OUT");
            _records[t].balance = bsub(_records[t].balance, tokenAmountOut);
            emit LOG_EXIT(msg.sender, t, tokenAmountOut);
            _pushUnderlying(t, msg.sender, tokenAmountOut);
        }

        emit LOG_COMMUNITY_FEE(msg.sender, _communityFeeReceiver, address(this), poolAmountInFee);
    }


    function swapExactAmountIn(
        address tokenIn,
        uint tokenAmountIn,
        address tokenOut,
        uint minAmountOut,
        uint maxPrice
    )
        external override
        _logs_
        _lock_
        returns (uint tokenAmountOut, uint spotPriceAfter)
    {
        _preventSameTxOrigin();
        _onlyWrapperOrNotWrapperMode();
        _requireTokenIsBound(tokenIn);
        _requireTokenIsBound(tokenOut);
        require(_publicSwap, "NOT_PUBLIC");

        Record storage inRecord = _records[address(tokenIn)];
        Record storage outRecord = _records[address(tokenOut)];

        uint spotPriceBefore = calcSpotPrice(
                                    inRecord.balance,
                                    _getDenormWeight(tokenIn),
                                    outRecord.balance,
                                    _getDenormWeight(tokenOut),
                                    _swapFee
                                );
        require(spotPriceBefore <= maxPrice, "LIMIT_PRICE");

        (uint tokenAmountInAfterFee, uint tokenAmountInFee) = calcAmountWithCommunityFee(
                                                                tokenAmountIn,
                                                                _communitySwapFee,
                                                                msg.sender
                                                            );

        require(tokenAmountInAfterFee <= bmul(inRecord.balance, MAX_IN_RATIO), "MAX_IN_RATIO");

        tokenAmountOut = calcOutGivenIn(
                            inRecord.balance,
                            _getDenormWeight(tokenIn),
                            outRecord.balance,
                            _getDenormWeight(tokenOut),
                            tokenAmountInAfterFee,
                            _swapFee
                        );
        require(tokenAmountOut >= minAmountOut, "LIMIT_OUT");

        inRecord.balance = badd(inRecord.balance, tokenAmountInAfterFee);
        outRecord.balance = bsub(outRecord.balance, tokenAmountOut);

        spotPriceAfter = calcSpotPrice(
                                inRecord.balance,
                                _getDenormWeight(tokenIn),
                                outRecord.balance,
                                _getDenormWeight(tokenOut),
                                _swapFee
                            );
        require(
            spotPriceAfter >= spotPriceBefore &&
            spotPriceBefore <= bdiv(tokenAmountInAfterFee, tokenAmountOut),
            "MATH_APPROX"
        );
        require(spotPriceAfter <= maxPrice, "LIMIT_PRICE");

        emit LOG_SWAP(msg.sender, tokenIn, tokenOut, tokenAmountInAfterFee, tokenAmountOut);

        _pullCommunityFeeUnderlying(tokenIn, msg.sender, tokenAmountInFee);
        _pullUnderlying(tokenIn, msg.sender, tokenAmountInAfterFee);
        _pushUnderlying(tokenOut, msg.sender, tokenAmountOut);

        emit LOG_COMMUNITY_FEE(msg.sender, _communityFeeReceiver, tokenIn, tokenAmountInFee);

        return (tokenAmountOut, spotPriceAfter);
    }

    function swapExactAmountOut(
        address tokenIn,
        uint maxAmountIn,
        address tokenOut,
        uint tokenAmountOut,
        uint maxPrice
    )
        external override
        _logs_
        _lock_
        returns (uint tokenAmountIn, uint spotPriceAfter)
    {
        _preventSameTxOrigin();
        _onlyWrapperOrNotWrapperMode();
        _requireTokenIsBound(tokenIn);
        _requireTokenIsBound(tokenOut);
        require(_publicSwap, "NOT_PUBLIC");

        Record storage inRecord = _records[address(tokenIn)];
        Record storage outRecord = _records[address(tokenOut)];

        require(tokenAmountOut <= bmul(outRecord.balance, MAX_OUT_RATIO), "OUT_RATIO");

        uint spotPriceBefore = calcSpotPrice(
                                    inRecord.balance,
                                    _getDenormWeight(tokenIn),
                                    outRecord.balance,
                                    _getDenormWeight(tokenOut),
                                    _swapFee
                                );
        require(spotPriceBefore <= maxPrice, "LIMIT_PRICE");

        (uint tokenAmountOutAfterFee, uint tokenAmountOutFee) = calcAmountWithCommunityFee(
            tokenAmountOut,
            _communitySwapFee,
            msg.sender
        );

        tokenAmountIn = calcInGivenOut(
                            inRecord.balance,
                            _getDenormWeight(tokenIn),
                            outRecord.balance,
                            _getDenormWeight(tokenOut),
                            tokenAmountOut,
                            _swapFee
                        );
        require(tokenAmountIn <= maxAmountIn, "LIMIT_IN");

        inRecord.balance = badd(inRecord.balance, tokenAmountIn);
        outRecord.balance = bsub(outRecord.balance, tokenAmountOut);

        spotPriceAfter = calcSpotPrice(
                                inRecord.balance,
                                _getDenormWeight(tokenIn),
                                outRecord.balance,
                                _getDenormWeight(tokenOut),
                                _swapFee
                            );
        require(
            spotPriceAfter >= spotPriceBefore &&
            spotPriceBefore <= bdiv(tokenAmountIn, tokenAmountOutAfterFee),
            "MATH_APPROX"
        );
        require(spotPriceAfter <= maxPrice, "LIMIT_PRICE");

        emit LOG_SWAP(msg.sender, tokenIn, tokenOut, tokenAmountIn, tokenAmountOutAfterFee);

        _pullUnderlying(tokenIn, msg.sender, tokenAmountIn);
        _pushUnderlying(tokenOut, msg.sender, tokenAmountOutAfterFee);
        _pushUnderlying(tokenOut, _communityFeeReceiver, tokenAmountOutFee);

        emit LOG_COMMUNITY_FEE(msg.sender, _communityFeeReceiver, tokenOut, tokenAmountOutFee);

        return (tokenAmountIn, spotPriceAfter);
    }


    function joinswapExternAmountIn(address tokenIn, uint tokenAmountIn, uint minPoolAmountOut)
        external override
        _logs_
        _lock_
        returns (uint poolAmountOut)

    {
        _preventSameTxOrigin();
        _requireContractIsFinalized();
        _onlyWrapperOrNotWrapperMode();
        _requireTokenIsBound(tokenIn);
        require(tokenAmountIn <= bmul(_records[tokenIn].balance, MAX_IN_RATIO), "MAX_IN_RATIO");

        (uint tokenAmountInAfterFee, uint tokenAmountInFee) = calcAmountWithCommunityFee(
            tokenAmountIn,
            _communityJoinFee,
            msg.sender
        );

        Record storage inRecord = _records[tokenIn];

        poolAmountOut = calcPoolOutGivenSingleIn(
                            inRecord.balance,
                            _getDenormWeight(tokenIn),
                            _totalSupply,
                            _getTotalWeight(),
                            tokenAmountInAfterFee,
                            _swapFee
                        );

        require(poolAmountOut >= minPoolAmountOut, "LIMIT_OUT");

        inRecord.balance = badd(inRecord.balance, tokenAmountInAfterFee);

        emit LOG_JOIN(msg.sender, tokenIn, tokenAmountInAfterFee);

        _mintPoolShare(poolAmountOut);
        _pushPoolShare(msg.sender, poolAmountOut);
        _pullCommunityFeeUnderlying(tokenIn, msg.sender, tokenAmountInFee);
        _pullUnderlying(tokenIn, msg.sender, tokenAmountInAfterFee);

        emit LOG_COMMUNITY_FEE(msg.sender, _communityFeeReceiver, tokenIn, tokenAmountInFee);

        return poolAmountOut;
    }

    function joinswapPoolAmountOut(address tokenIn, uint poolAmountOut, uint maxAmountIn)
        external override
        _logs_
        _lock_
        returns (uint tokenAmountIn)
    {
        _preventSameTxOrigin();
        _requireContractIsFinalized();
        _onlyWrapperOrNotWrapperMode();
        _requireTokenIsBound(tokenIn);

        Record storage inRecord = _records[tokenIn];

        (uint poolAmountOutAfterFee, uint poolAmountOutFee) = calcAmountWithCommunityFee(
            poolAmountOut,
            _communityJoinFee,
            msg.sender
        );

        tokenAmountIn = calcSingleInGivenPoolOut(
                            inRecord.balance,
                            _getDenormWeight(tokenIn),
                            _totalSupply,
                            _getTotalWeight(),
                            poolAmountOut,
                            _swapFee
                        );

        _requireMathApprox(tokenAmountIn);
        require(tokenAmountIn <= maxAmountIn, "LIMIT_IN");

        require(tokenAmountIn <= bmul(_records[tokenIn].balance, MAX_IN_RATIO), "MAX_IN_RATIO");

        inRecord.balance = badd(inRecord.balance, tokenAmountIn);

        emit LOG_JOIN(msg.sender, tokenIn, tokenAmountIn);

        _mintPoolShare(poolAmountOut);
        _pushPoolShare(msg.sender, poolAmountOutAfterFee);
        _pushPoolShare(_communityFeeReceiver, poolAmountOutFee);
        _pullUnderlying(tokenIn, msg.sender, tokenAmountIn);

        emit LOG_COMMUNITY_FEE(msg.sender, _communityFeeReceiver, address(this), poolAmountOutFee);

        return tokenAmountIn;
    }

    function exitswapPoolAmountIn(address tokenOut, uint poolAmountIn, uint minAmountOut)
        external override
        _logs_
        _lock_
        returns (uint tokenAmountOut)
    {
        _preventSameTxOrigin();
        _requireContractIsFinalized();
        _onlyWrapperOrNotWrapperMode();
        _requireTokenIsBound(tokenOut);

        Record storage outRecord = _records[tokenOut];

        tokenAmountOut = calcSingleOutGivenPoolIn(
                            outRecord.balance,
                            _getDenormWeight(tokenOut),
                            _totalSupply,
                            _getTotalWeight(),
                            poolAmountIn,
                            _swapFee
                        );

        require(tokenAmountOut >= minAmountOut, "LIMIT_OUT");

        require(tokenAmountOut <= bmul(_records[tokenOut].balance, MAX_OUT_RATIO), "OUT_RATIO");

        outRecord.balance = bsub(outRecord.balance, tokenAmountOut);

        (uint tokenAmountOutAfterFee, uint tokenAmountOutFee) = calcAmountWithCommunityFee(
            tokenAmountOut,
            _communityExitFee,
            msg.sender
        );

        emit LOG_EXIT(msg.sender, tokenOut, tokenAmountOutAfterFee);

        _pullPoolShare(msg.sender, poolAmountIn);
        _burnPoolShare(poolAmountIn);
        _pushUnderlying(tokenOut, msg.sender, tokenAmountOutAfterFee);
        _pushUnderlying(tokenOut, _communityFeeReceiver, tokenAmountOutFee);

        emit LOG_COMMUNITY_FEE(msg.sender, _communityFeeReceiver, tokenOut, tokenAmountOutFee);

        return tokenAmountOutAfterFee;
    }

    function exitswapExternAmountOut(address tokenOut, uint tokenAmountOut, uint maxPoolAmountIn)
        external override
        _logs_
        _lock_
        returns (uint poolAmountIn)
    {
        _preventSameTxOrigin();
        _requireContractIsFinalized();
        _onlyWrapperOrNotWrapperMode();
        _requireTokenIsBound(tokenOut);
        require(tokenAmountOut <= bmul(_records[tokenOut].balance, MAX_OUT_RATIO), "OUT_RATIO");

        Record storage outRecord = _records[tokenOut];

        (uint tokenAmountOutAfterFee, uint tokenAmountOutFee) = calcAmountWithCommunityFee(
            tokenAmountOut,
            _communityExitFee,
            msg.sender
        );

        poolAmountIn = calcPoolInGivenSingleOut(
                            outRecord.balance,
                            _getDenormWeight(tokenOut),
                            _totalSupply,
                            _getTotalWeight(),
                            tokenAmountOut,
                            _swapFee
                        );

        _requireMathApprox(poolAmountIn);
        require(poolAmountIn <= maxPoolAmountIn, "LIMIT_IN");

        outRecord.balance = bsub(outRecord.balance, tokenAmountOut);

        emit LOG_EXIT(msg.sender, tokenOut, tokenAmountOutAfterFee);

        _pullPoolShare(msg.sender, poolAmountIn);
        _burnPoolShare(poolAmountIn);
        _pushUnderlying(tokenOut, msg.sender, tokenAmountOutAfterFee);
        _pushUnderlying(tokenOut, _communityFeeReceiver, tokenAmountOutFee);

        emit LOG_COMMUNITY_FEE(msg.sender, _communityFeeReceiver, tokenOut, tokenAmountOutFee);

        return poolAmountIn;
    }


    // ==
    // 'Underlying' token-manipulation functions make external calls but are NOT locked
    // You must `_lock_` or otherwise ensure reentry-safety

    function _pullUnderlying(address erc20, address from, uint amount)
        internal
    {
        bool xfer = IERC20(erc20).transferFrom(from, address(this), amount);
        require(xfer, "ERC20_FALSE");
    }

    function _pushUnderlying(address erc20, address to, uint amount)
        internal
    {
        bool xfer = IERC20(erc20).transfer(to, amount);
        require(xfer, "ERC20_FALSE");
    }

    function _pullCommunityFeeUnderlying(address erc20, address from, uint amount)
        internal
    {
        bool xfer = IERC20(erc20).transferFrom(from, _communityFeeReceiver, amount);
        require(xfer, "ERC20_FALSE");
    }

    function _pullPoolShare(address from, uint amount)
        internal
    {
        _pull(from, amount);
    }

    function _pushPoolShare(address to, uint amount)
        internal
    {
        _push(to, amount);
    }

    function _mintPoolShare(uint amount)
        internal
    {
        if(address(_restrictions) != address(0)) {
            uint maxTotalSupply = _restrictions.getMaxTotalSupply(address(this));
            require(badd(_totalSupply, amount) <= maxTotalSupply, "MAX_SUPPLY");
        }
        _mint(amount);
    }

    function _burnPoolShare(uint amount)
        internal
    {
        _burn(amount);
    }

    function _requireTokenIsBound(address token)
        internal view
    {
        require(_records[token].bound, "NOT_BOUND");
    }

    function _onlyController()
        internal view
    {
        require(msg.sender == _controller, "NOT_CONTROLLER");
    }

    function _requireContractIsNotFinalized()
        internal view
    {
        require(!_finalized, "IS_FINALIZED");
    }

    function _requireContractIsFinalized()
        internal view
    {
        require(_finalized, "NOT_FINALIZED");
    }

    function _requireFeeInBounds(uint256 _fee)
        internal pure
    {
        require(_fee >= MIN_FEE && _fee <= MAX_FEE, "FEE_BOUNDS");
    }

    function _requireMathApprox(uint256 _value)
        internal pure
    {
        require(_value != 0, "MATH_APPROX");
    }

    function _preventReentrancy()
        internal view
    {
        require(!_mutex, "REENTRY");
    }

    function _onlyWrapperOrNotWrapperMode()
        internal view
    {
        require(!_wrapperMode || msg.sender == _wrapper, "ONLY_WRAPPER");
    }

    function _preventSameTxOrigin()
      internal
    {
      require(block.number > _lastSwapBlock[tx.origin], "SAME_TX_ORIGIN");
      _lastSwapBlock[tx.origin] = block.number;
    }

    function _getDenormWeight(address token)
        internal view virtual
        returns (uint)
    {
        return _records[token].denorm;
    }

    function _getTotalWeight()
        internal view virtual
        returns (uint)
    {
        return _totalWeight;
    }

    function _addTotalWeight(uint _amount) internal virtual {
        _totalWeight = badd(_totalWeight, _amount);
        require(_totalWeight <= MAX_TOTAL_WEIGHT, "MAX_TOTAL_WEIGHT");
    }

    function _subTotalWeight(uint _amount) internal virtual {
        _totalWeight = bsub(_totalWeight, _amount);
    }

    function calcAmountWithCommunityFee(
        uint tokenAmountIn,
        uint communityFee,
        address operator
    )
        public view override
        returns (uint tokenAmountInAfterFee, uint tokenAmountFee)
    {
        if (address(_restrictions) != address(0) && _restrictions.isWithoutFee(operator)) {
            return (tokenAmountIn, 0);
        }
        uint adjustedIn = bsub(BONE, communityFee);
        tokenAmountInAfterFee = bmul(tokenAmountIn, adjustedIn);
        tokenAmountFee = bsub(tokenAmountIn, tokenAmountInAfterFee);
        return (tokenAmountInAfterFee, tokenAmountFee);
    }

    function getMinWeight()
        external view override
        returns (uint)
    {
        return MIN_WEIGHT;
    }

    function getMaxBoundTokens()
        external view override
        returns (uint)
    {
      return MAX_BOUND_TOKENS;
    }
}

// SPDX-License-Identifier: GPL-3.0
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

pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./BNum.sol";

contract BTokenBase is BNum {

    mapping(address => uint)                   internal _balance;
    mapping(address => mapping(address=>uint)) internal _allowance;
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
        _validateAddress(src);
        _validateAddress(dst);
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

    function _validateAddress(address addr) internal {
        require(addr != address(0), "ERR_NULL_ADDRESS");
    }
}

contract BToken is BTokenBase, IERC20 {

    string  internal _name;
    string  internal _symbol;
    uint8   private _decimals = 18;

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns(uint8) {
        return _decimals;
    }

    function allowance(address src, address dst) external override view returns (uint) {
        return _allowance[src][dst];
    }

    function balanceOf(address whom) external override view returns (uint) {
        return _balance[whom];
    }

    function totalSupply() public override view returns (uint) {
        return _totalSupply;
    }

    function approve(address dst, uint amt) external override returns (bool) {
        _validateAddress(dst);
        _allowance[msg.sender][dst] = amt;
        emit Approval(msg.sender, dst, amt);
        return true;
    }

    function increaseApproval(address dst, uint amt) external returns (bool) {
        _validateAddress(dst);
        _allowance[msg.sender][dst] = badd(_allowance[msg.sender][dst], amt);
        emit Approval(msg.sender, dst, _allowance[msg.sender][dst]);
        return true;
    }

    function decreaseApproval(address dst, uint amt) external returns (bool) {
        _validateAddress(dst);
        uint oldValue = _allowance[msg.sender][dst];
        if (amt > oldValue) {
            _allowance[msg.sender][dst] = 0;
        } else {
            _allowance[msg.sender][dst] = bsub(oldValue, amt);
        }
        emit Approval(msg.sender, dst, _allowance[msg.sender][dst]);
        return true;
    }

    function transfer(address dst, uint amt) external override returns (bool) {
        _move(msg.sender, dst, amt);
        return true;
    }

    function transferFrom(address src, address dst, uint amt) external override returns (bool) {
        require(msg.sender == src || amt <= _allowance[src][msg.sender], "ERR_BTOKEN_BAD_CALLER");
        _move(src, dst, amt);
        if (msg.sender != src && _allowance[src][msg.sender] != uint256(-1)) {
            _allowance[src][msg.sender] = bsub(_allowance[src][msg.sender], amt);
            emit Approval(src, msg.sender, _allowance[src][msg.sender]);
        }
        return true;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IPoolRestrictions {
  function getMaxTotalSupply(address _pool) external view returns (uint256);

  function isVotingSignatureAllowed(address _votingAddress, bytes4 _signature) external view returns (bool);

  function isVotingSenderAllowed(address _votingAddress, address _sender) external view returns (bool);

  function isWithoutFee(address _addr) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Reservoir is Ownable {
  constructor() public Ownable() {}

  function setApprove(
    address _token,
    address _to,
    uint256 _amount
  ) external onlyOwner {
    IERC20(_token).approve(_to, _amount);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "../GSN/Context.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
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
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface WrappedPiErc20Interface is IERC20 {
  function deposit(uint256 _amount) external;

  function withdraw(uint256 _amount) external;

  function changeRouter(address _newRouter) external;

  function approveToken(address _to, uint256 _amount) external;

  function callVoting(
    address voting,
    bytes4 signature,
    bytes calldata args,
    uint256 value
  ) external;

  function getWrappedBalance() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface TokenInterface is IERC20 {
  function deposit() external payable;

  function withdraw(uint256) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IMigrator {
  // Perform LP token migration from legacy UniswapV2 to PowerSwap.
  // Take the current LP token address and return the new LP token address.
  // Migrator should have full access to the caller's LP token.
  // Return the new LP token address.
  //
  // XXX Migrator must have allowance access to UniswapV2 LP tokens.
  // PowerSwap must mint EXACTLY the same amount of PowerSwap LP tokens or
  // else something bad will happen. Traditional UniswapV2 does not
  // do that so be careful!
  function migrate(IERC20 token, uint8 poolType) external returns (IERC20);
}

// SPDX-License-Identifier: GPL-3.0
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

pragma solidity 0.6.12;

// Builds new BPools, logging their addresses and providing `isBPool(address) -> (bool)`

import "./BPool.sol";

contract BFactory {
    event LOG_NEW_POOL(
        address indexed caller,
        address indexed pool
    );

    mapping(address => bool) public isBPool;

    constructor() public { }

    function newBPool(string calldata name, string calldata symbol)
        external
        returns (BPool)
    {
        BPool bpool = new BPool(name, symbol);
        isBPool[address(bpool)] = true;
        emit LOG_NEW_POOL(msg.sender, address(bpool));
        bpool.setController(msg.sender);
        return bpool;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./BPoolInterface.sol";

interface BFactoryInterface {
  function newBPool(string calldata name, string calldata symbol) external returns (BPoolInterface);
}

