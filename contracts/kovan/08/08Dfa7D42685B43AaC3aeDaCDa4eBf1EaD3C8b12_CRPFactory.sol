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

pragma solidity 0.6.12;

import "../core/BMath.sol";
import "../core/BNum.sol";

// Contract to wrap internal functions for testing

contract TMath is BMath {

    function calc_btoi(uint a) external pure returns (uint) {
        return btoi(a);
    }

    function calc_bfloor(uint a) external pure returns (uint) {
        return bfloor(a);
    }

    function calc_badd(uint a, uint b) external pure returns (uint) {
        return badd(a, b);
    }

    function calc_bsub(uint a, uint b) external pure returns (uint) {
        return bsub(a, b);
    }

    function calc_bsubSign(uint a, uint b) external pure returns (uint, bool) {
        return bsubSign(a, b);
    }

    function calc_bmul(uint a, uint b) external pure returns (uint) {
        return bmul(a, b);
    }

    function calc_bdiv(uint a, uint b) external pure returns (uint) {
        return bdiv(a, b);
    }

    function calc_bpowi(uint a, uint n) external pure returns (uint) {
        return bpowi(a, n);
    }

    function calc_bpow(uint base, uint exp) external pure returns (uint) {
        return bpow(base, exp);
    }

    function calc_bpowApprox(uint base, uint exp, uint precision) external pure returns (uint) {
        return bpowApprox(base, exp, precision);
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

pragma solidity 0.6.12;

import "./BNum.sol";

contract BMath is BConst, BNum {
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
        public pure
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
        uint swapFee
    )
        public pure
        returns (uint tokenAmountOut)
    {
        uint normalizedWeight = bdiv(tokenWeightOut, totalWeight);
        // charge exit fee on the pool token side
        // pAiAfterExitFee = pAi*(1-exitFee)
        uint poolAmountInAfterExitFee = bmul(poolAmountIn, bsub(BONE, EXIT_FEE));
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
        uint poolAmountInAfterExitFee = bsub(poolSupply, newPoolSupply);

        // charge exit fee on the pool token side
        // pAi = pAiAfterExitFee/(1-exitFee)
        poolAmountIn = bdiv(poolAmountInAfterExitFee, bsub(BONE, EXIT_FEE));
        return poolAmountIn;
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

pragma solidity 0.6.12;

import "./BToken.sol";
import "./BMath.sol";

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

    modifier _logs_() {
        emit LOG_CALL(msg.sig, msg.sender, msg.data);
        _;
    }

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
    address private _controller; // has CONTROL role
    bool private _publicSwap; // true if PUBLIC can call SWAP functions

    // `setSwapFee` and `finalize` require CONTROL
    // `finalize` sets `PUBLIC can SWAP`, `PUBLIC can JOIN`
    uint private _swapFee;
    bool private _finalized;

    address[] private _tokens;
    mapping(address=>Record) private  _records;
    uint private _totalWeight;

    constructor() public {
        _controller = msg.sender;
        _factory = msg.sender;
        _swapFee = MIN_FEE;
        _publicSwap = false;
        _finalized = false;
    }

    function isPublicSwap()
        external view
        returns (bool)
    {
        return _publicSwap;
    }

    function isFinalized()
        external view
        returns (bool)
    {
        return _finalized;
    }

    function isBound(address t)
        external view
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
        external view _viewlock_
        returns (address[] memory tokens)
    {
        return _tokens;
    }

    function getFinalTokens()
        external view
        _viewlock_
        returns (address[] memory tokens)
    {
        require(_finalized, "ERR_NOT_FINALIZED");
        return _tokens;
    }

    function getDenormalizedWeight(address token)
        external view
        _viewlock_
        returns (uint)
    {

        require(_records[token].bound, "ERR_NOT_BOUND");
        return _records[token].denorm;
    }

    function getTotalDenormalizedWeight()
        external view
        _viewlock_
        returns (uint)
    {
        return _totalWeight;
    }

    function getNormalizedWeight(address token)
        external view
        _viewlock_
        returns (uint)
    {

        require(_records[token].bound, "ERR_NOT_BOUND");
        uint denorm = _records[token].denorm;
        return bdiv(denorm, _totalWeight);
    }

    function getBalance(address token)
        external view
        _viewlock_
        returns (uint)
    {

        require(_records[token].bound, "ERR_NOT_BOUND");
        return _records[token].balance;
    }

    function getSwapFee()
        external view
        _viewlock_
        returns (uint)
    {
        return _swapFee;
    }

    function getController()
        external view
        _viewlock_
        returns (address)
    {
        return _controller;
    }

    function setSwapFee(uint swapFee)
        external
        _logs_
        _lock_
    { 
        require(!_finalized, "ERR_IS_FINALIZED");
        require(msg.sender == _controller, "ERR_NOT_CONTROLLER");
        require(swapFee >= MIN_FEE, "ERR_MIN_FEE");
        require(swapFee <= MAX_FEE, "ERR_MAX_FEE");
        _swapFee = swapFee;
    }

    function setController(address manager)
        external
        _logs_
        _lock_
    {
        require(msg.sender == _controller, "ERR_NOT_CONTROLLER");
        _controller = manager;
    }

    function setPublicSwap(bool public_)
        external
        _logs_
        _lock_
    {
        require(!_finalized, "ERR_IS_FINALIZED");
        require(msg.sender == _controller, "ERR_NOT_CONTROLLER");
        _publicSwap = public_;
    }

    function finalize()
        external
        _logs_
        _lock_
    {
        require(msg.sender == _controller, "ERR_NOT_CONTROLLER");
        require(!_finalized, "ERR_IS_FINALIZED");
        require(_tokens.length >= MIN_BOUND_TOKENS, "ERR_MIN_TOKENS");

        _finalized = true;
        _publicSwap = true;

        _mintPoolShare(INIT_POOL_SUPPLY);
        _pushPoolShare(msg.sender, INIT_POOL_SUPPLY);
    }


    function bind(address token, uint balance, uint denorm)
        external
        _logs_
        // _lock_  Bind does not lock because it jumps to `rebind`, which does
    {
        require(msg.sender == _controller, "ERR_NOT_CONTROLLER");
        require(!_records[token].bound, "ERR_IS_BOUND");
        require(!_finalized, "ERR_IS_FINALIZED");

        require(_tokens.length < MAX_BOUND_TOKENS, "ERR_MAX_TOKENS");

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
        public
        _logs_
        _lock_
    {

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
            uint tokenExitFee = bmul(tokenBalanceWithdrawn, EXIT_FEE);
            _pushUnderlying(token, msg.sender, bsub(tokenBalanceWithdrawn, tokenExitFee));
            _pushUnderlying(token, _factory, tokenExitFee);
        }
    }

    function unbind(address token)
        external
        _logs_
        _lock_
    {

        require(msg.sender == _controller, "ERR_NOT_CONTROLLER");
        require(_records[token].bound, "ERR_NOT_BOUND");
        require(!_finalized, "ERR_IS_FINALIZED");

        uint tokenBalance = _records[token].balance;
        uint tokenExitFee = bmul(tokenBalance, EXIT_FEE);

        _totalWeight = bsub(_totalWeight, _records[token].denorm);

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

        _pushUnderlying(token, msg.sender, bsub(tokenBalance, tokenExitFee));
        _pushUnderlying(token, _factory, tokenExitFee);
    }

    // Absorb any tokens that have been sent to this contract into the pool
    function gulp(address token)
        external
        _logs_
        _lock_
    {
        require(_records[token].bound, "ERR_NOT_BOUND");
        _records[token].balance = IERC20(token).balanceOf(address(this));
    }

    function getSpotPrice(address tokenIn, address tokenOut)
        external view
        _viewlock_
        returns (uint spotPrice)
    {
        require(_records[tokenIn].bound, "ERR_NOT_BOUND");
        require(_records[tokenOut].bound, "ERR_NOT_BOUND");
        Record storage inRecord = _records[tokenIn];
        Record storage outRecord = _records[tokenOut];
        return calcSpotPrice(inRecord.balance, inRecord.denorm, outRecord.balance, outRecord.denorm, _swapFee);
    }

    function getSpotPriceSansFee(address tokenIn, address tokenOut)
        external view
        _viewlock_
        returns (uint spotPrice)
    {
        require(_records[tokenIn].bound, "ERR_NOT_BOUND");
        require(_records[tokenOut].bound, "ERR_NOT_BOUND");
        Record storage inRecord = _records[tokenIn];
        Record storage outRecord = _records[tokenOut];
        return calcSpotPrice(inRecord.balance, inRecord.denorm, outRecord.balance, outRecord.denorm, 0);
    }

    function joinPool(uint poolAmountOut, uint[] calldata maxAmountsIn)
        external
        _logs_
        _lock_
    {
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

    function exitPool(uint poolAmountIn, uint[] calldata minAmountsOut)
        external
        _logs_
        _lock_
    {
        require(_finalized, "ERR_NOT_FINALIZED");

        uint poolTotal = totalSupply();
        uint exitFee = bmul(poolAmountIn, EXIT_FEE);
        uint pAiAfterExitFee = bsub(poolAmountIn, exitFee);
        uint ratio = bdiv(pAiAfterExitFee, poolTotal);
        require(ratio != 0, "ERR_MATH_APPROX");

        _pullPoolShare(msg.sender, poolAmountIn);
        _pushPoolShare(_factory, exitFee);
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
    )
        external
        _logs_
        _lock_
        returns (uint tokenAmountOut, uint spotPriceAfter)
    {

        require(_records[tokenIn].bound, "ERR_NOT_BOUND");
        require(_records[tokenOut].bound, "ERR_NOT_BOUND");
        require(_publicSwap, "ERR_SWAP_NOT_PUBLIC");

        Record storage inRecord = _records[address(tokenIn)];
        Record storage outRecord = _records[address(tokenOut)];

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
    )
        external
        _logs_
        _lock_ 
        returns (uint tokenAmountIn, uint spotPriceAfter)
    {
        require(_records[tokenIn].bound, "ERR_NOT_BOUND");
        require(_records[tokenOut].bound, "ERR_NOT_BOUND");
        require(_publicSwap, "ERR_SWAP_NOT_PUBLIC");

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


    function joinswapExternAmountIn(address tokenIn, uint tokenAmountIn, uint minPoolAmountOut)
        external
        _logs_
        _lock_
        returns (uint poolAmountOut)

    {        
        require(_finalized, "ERR_NOT_FINALIZED");
        require(_records[tokenIn].bound, "ERR_NOT_BOUND");
        require(tokenAmountIn <= bmul(_records[tokenIn].balance, MAX_IN_RATIO), "ERR_MAX_IN_RATIO");

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

        inRecord.balance = badd(inRecord.balance, tokenAmountIn);

        emit LOG_JOIN(msg.sender, tokenIn, tokenAmountIn);

        _mintPoolShare(poolAmountOut);
        _pushPoolShare(msg.sender, poolAmountOut);
        _pullUnderlying(tokenIn, msg.sender, tokenAmountIn);

        return poolAmountOut;
    }

    function joinswapPoolAmountOut(address tokenIn, uint poolAmountOut, uint maxAmountIn)
        external
        _logs_
        _lock_
        returns (uint tokenAmountIn)
    {
        require(_finalized, "ERR_NOT_FINALIZED");
        require(_records[tokenIn].bound, "ERR_NOT_BOUND");

        Record storage inRecord = _records[tokenIn];

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

        inRecord.balance = badd(inRecord.balance, tokenAmountIn);

        emit LOG_JOIN(msg.sender, tokenIn, tokenAmountIn);

        _mintPoolShare(poolAmountOut);
        _pushPoolShare(msg.sender, poolAmountOut);
        _pullUnderlying(tokenIn, msg.sender, tokenAmountIn);

        return tokenAmountIn;
    }

    function exitswapPoolAmountIn(address tokenOut, uint poolAmountIn, uint minAmountOut)
        external
        _logs_
        _lock_
        returns (uint tokenAmountOut)
    {
        require(_finalized, "ERR_NOT_FINALIZED");
        require(_records[tokenOut].bound, "ERR_NOT_BOUND");

        Record storage outRecord = _records[tokenOut];

        tokenAmountOut = calcSingleOutGivenPoolIn(
                            outRecord.balance,
                            outRecord.denorm,
                            _totalSupply,
                            _totalWeight,
                            poolAmountIn,
                            _swapFee
                        );

        require(tokenAmountOut >= minAmountOut, "ERR_LIMIT_OUT");
        
        require(tokenAmountOut <= bmul(_records[tokenOut].balance, MAX_OUT_RATIO), "ERR_MAX_OUT_RATIO");

        outRecord.balance = bsub(outRecord.balance, tokenAmountOut);

        uint exitFee = bmul(poolAmountIn, EXIT_FEE);

        emit LOG_EXIT(msg.sender, tokenOut, tokenAmountOut);

        _pullPoolShare(msg.sender, poolAmountIn);
        _burnPoolShare(bsub(poolAmountIn, exitFee));
        _pushPoolShare(_factory, exitFee);
        _pushUnderlying(tokenOut, msg.sender, tokenAmountOut);

        return tokenAmountOut;
    }

    function exitswapExternAmountOut(address tokenOut, uint tokenAmountOut, uint maxPoolAmountIn)
        external
        _logs_
        _lock_
        returns (uint poolAmountIn)
    {
        require(_finalized, "ERR_NOT_FINALIZED");
        require(_records[tokenOut].bound, "ERR_NOT_BOUND");
        require(tokenAmountOut <= bmul(_records[tokenOut].balance, MAX_OUT_RATIO), "ERR_MAX_OUT_RATIO");

        Record storage outRecord = _records[tokenOut];

        poolAmountIn = calcPoolInGivenSingleOut(
                            outRecord.balance,
                            outRecord.denorm,
                            _totalSupply,
                            _totalWeight,
                            tokenAmountOut,
                            _swapFee
                        );

        require(poolAmountIn != 0, "ERR_MATH_APPROX");
        require(poolAmountIn <= maxPoolAmountIn, "ERR_LIMIT_IN");

        outRecord.balance = bsub(outRecord.balance, tokenAmountOut);

        uint exitFee = bmul(poolAmountIn, EXIT_FEE);

        emit LOG_EXIT(msg.sender, tokenOut, tokenAmountOut);

        _pullPoolShare(msg.sender, poolAmountIn);
        _burnPoolShare(bsub(poolAmountIn, exitFee));
        _pushPoolShare(_factory, exitFee);
        _pushUnderlying(tokenOut, msg.sender, tokenAmountOut);        

        return poolAmountIn;
    }


    // ==
    // 'Underlying' token-manipulation functions make external calls but are NOT locked
    // You must `_lock_` or otherwise ensure reentry-safety

    function _pullUnderlying(address erc20, address from, uint amount)
        internal
    {
        bool xfer = IERC20(erc20).transferFrom(from, address(this), amount);
        require(xfer, "ERR_ERC20_FALSE");
    }

    function _pushUnderlying(address erc20, address to, uint amount)
        internal
    {
        bool xfer = IERC20(erc20).transfer(to, amount);
        require(xfer, "ERR_ERC20_FALSE");
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
        _mint(amount);
    }

    function _burnPoolShare(uint amount)
        internal
    {
        _burn(amount);
    }

}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.6.12;

import "./BNum.sol";
import "../utils/PCToken.sol";

// Highly opinionated token implementation

contract BTokenKase is BNum {

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
        require(_balance[address(this)] >= amt, "ERR_INSUFFICIENT_KAL");
        _balance[address(this)] = bsub(_balance[address(this)], amt);
        _totalSupply = bsub(_totalSupply, amt);
        emit Transfer(address(this), address(0), amt);
    }

    function _move(address src, address dst, uint amt) internal {
        require(_balance[src] >= amt, "ERR_INSUFFICIENT_KAL");
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

contract BToken is BTokenKase, IERC20 {

    string  private _name     = "Buni Pool Token";
    string  private _symbol   = "BPT";
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

    function allowance(address src, address dst) external view override returns (uint) {
        return _allowance[src][dst];
    }

    function balanceOf(address whom) external view override returns (uint) {
        return _balance[whom];
    }

    function totalSupply() public view override returns (uint) {
        return _totalSupply;
    }

    function approve(address dst, uint amt) external override returns (bool) {
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

    function transfer(address dst, uint amt) external override returns (bool) {
        _move(msg.sender, dst, amt);
        return true;
    }

    function transferFrom(address src, address dst, uint amt) external override returns (bool) {
        require(msg.sender == src || amt <= _allowance[src][msg.sender], "ERR_KTOKEN_BAD_CALLER");
        _move(src, dst, amt);
        if (msg.sender != src && _allowance[src][msg.sender] != uint256(-1)) {
            _allowance[src][msg.sender] = bsub(_allowance[src][msg.sender], amt);
            emit Approval(msg.sender, dst, _allowance[src][msg.sender]);
        }
        return true;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.6.12;

// Imports

import "./BuniSafeMath.sol";
import "./BuniConstants.sol";
import "../interfaces/IERC20.sol";

// Contracts

/* solhint-disable func-order */

/**
 * @author Buni Labs
 * @title Highly opinionated token implementation
*/
contract PCToken is IERC20 {
    using BuniSafeMath for uint;

    // State variables
    string public constant NAME = "Buni Smart Pool";
    uint8 public constant DECIMALS = 18;

    // No leading underscore per naming convention (non-private)
    // Cannot call totalSupply (name conflict)
    // solhint-disable-next-line private-vars-leading-underscore
    uint internal varTotalSupply;

    mapping(address => uint) private _balance;
    mapping(address => mapping(address => uint)) private _allowance;

    string private _symbol;
    string private _name;

    // Event declarations

    // See definitions above; must be redeclared to be emitted from this contract
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    // Function declarations

    /**
     * @notice Base token constructor
     * @param tokenSymbol - the token symbol
     */
    constructor (string memory tokenSymbol, string memory tokenName) public {
        _symbol = tokenSymbol;
        _name = tokenName;
    }

    // External functions

    /**
     * @notice Getter for allowance: amount spender will be allowed to spend on behalf of owner
     * @param owner - owner of the tokens
     * @param spender - entity allowed to spend the tokens
     * @return uint - remaining amount spender is allowed to transfer
     */
    function allowance(address owner, address spender) external view override returns (uint) {
        return _allowance[owner][spender];
    }

    /**
     * @notice Getter for current account balance
     * @param account - address we're checking the balance of
     * @return uint - token balance in the account
     */
    function balanceOf(address account) external view override returns (uint) {
        return _balance[account];
    }

    /**
     * @notice Approve owner (sender) to spend a certain amount
     * @dev emits an Approval event
     * @param spender - entity the owner (sender) is approving to spend his tokens
     * @param amount - number of tokens being approved
     * @return bool - result of the approval (will always be true if it doesn't revert)
     */
    function approve(address spender, uint amount) external override returns (bool) {
        /* In addition to the increase/decreaseApproval functions, could
           avoid the "approval race condition" by only allowing calls to approve
           when the current approval amount is 0
        
           require(_allowance[msg.sender][spender] == 0, "ERR_RACE_CONDITION");
           Some token contracts (e.g., KNC), already revert if you call approve 
           on a non-zero allocation. To deal with these, we use the SafeApprove library
           and safeApprove function when adding tokens to the pool.
        */

        _allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    /**
     * @notice Increase the amount the spender is allowed to spend on behalf of the owner (sender)
     * @dev emits an Approval event
     * @param spender - entity the owner (sender) is approving to spend his tokens
     * @param amount - number of tokens being approved
     * @return bool - result of the approval (will always be true if it doesn't revert)
     */
    function increaseApproval(address spender, uint amount) external returns (bool) {
        _allowance[msg.sender][spender] = BuniSafeMath.badd(_allowance[msg.sender][spender], amount);

        emit Approval(msg.sender, spender, _allowance[msg.sender][spender]);

        return true;
    }

    /**
     * @notice Decrease the amount the spender is allowed to spend on behalf of the owner (sender)
     * @dev emits an Approval event
     * @dev If you try to decrease it below the current limit, it's just set to zero (not an error)
     * @param spender - entity the owner (sender) is approving to spend his tokens
     * @param amount - number of tokens being approved
     * @return bool - result of the approval (will always be true if it doesn't revert)
     */
    function decreaseApproval(address spender, uint amount) external returns (bool) {
        uint oldValue = _allowance[msg.sender][spender];
        // Gas optimization - if amount == oldValue (or is larger), set to zero immediately
        if (amount >= oldValue) {
            _allowance[msg.sender][spender] = 0;
        } else {
            _allowance[msg.sender][spender] = BuniSafeMath.bsub(oldValue, amount);
        }

        emit Approval(msg.sender, spender, _allowance[msg.sender][spender]);

        return true;
    }

    /**
     * @notice Transfer the given amount from sender (caller) to recipient
     * @dev _move emits a Transfer event if successful
     * @param recipient - entity receiving the tokens
     * @param amount - number of tokens being transferred
     * @return bool - result of the transfer (will always be true if it doesn't revert)
     */
    function transfer(address recipient, uint amount) external override returns (bool) {
        require(recipient != address(0), "ERR_ZERO_ADDRESS");

        _move(msg.sender, recipient, amount);

        return true;
    }

    /**
     * @notice Transfer the given amount from sender to recipient
     * @dev _move emits a Transfer event if successful; may also emit an Approval event
     * @param sender - entity sending the tokens (must be caller or allowed to spend on behalf of caller)
     * @param recipient - recipient of the tokens
     * @param amount - number of tokens being transferred
     * @return bool - result of the transfer (will always be true if it doesn't revert)
     */
    function transferFrom(address sender, address recipient, uint amount) external override returns (bool) {
        require(recipient != address(0), "ERR_ZERO_ADDRESS");
        require(msg.sender == sender || amount <= _allowance[sender][msg.sender], "ERR_PCTOKEN_BAD_CALLER");

        _move(sender, recipient, amount);

        // memoize for gas optimization
        uint oldAllowance = _allowance[sender][msg.sender];

        // If the sender is not the caller, adjust the allowance by the amount transferred
        if (msg.sender != sender && oldAllowance != uint(-1)) {
            _allowance[sender][msg.sender] = BuniSafeMath.bsub(oldAllowance, amount);

            emit Approval(msg.sender, recipient, _allowance[sender][msg.sender]);
        }

        return true;
    }

    // public functions

    /**
     * @notice Getter for the total supply
     * @dev declared external for gas optimization
     * @return uint - total number of tokens in existence
     */
    function totalSupply() external view override returns (uint) {
        return varTotalSupply;
    }

    // Public functions

    /**
     * @dev Returns the name of the token.
     *      We allow the user to set this name (as well as the symbol).
     *      Alternatives are 1) A fixed string (original design)
     *                       2) A fixed string plus the user-defined symbol
     *                          return string(abi.encodePacked(NAME, "-", _symbol));
     */
    function name() external view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() external view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() external pure returns (uint8) {
        return DECIMALS;
    }

    // internal functions

    // Mint an amount of new tokens, and add them to the balance (and total supply)
    // Emit a transfer amount from the null address to this contract
    function _mint(uint amount) internal virtual {
        _balance[address(this)] = BuniSafeMath.badd(_balance[address(this)], amount);
        varTotalSupply = BuniSafeMath.badd(varTotalSupply, amount);

        emit Transfer(address(0), address(this), amount);
    }

    // Burn an amount of new tokens, and subtract them from the balance (and total supply)
    // Emit a transfer amount from this contract to the null address
    function _burn(uint amount) internal virtual {
        // Can't burn more than we have
        // Remove require for gas optimization - bsub will revert on underflow
        // require(_balance[address(this)] >= amount, "ERR_INSUFFICIENT_BAL");

        _balance[address(this)] = BuniSafeMath.bsub(_balance[address(this)], amount);
        varTotalSupply = BuniSafeMath.bsub(varTotalSupply, amount);

        emit Transfer(address(this), address(0), amount);
    }

    // Transfer tokens from sender to recipient
    // Adjust balances, and emit a Transfer event
    function _move(address sender, address recipient, uint amount) internal virtual {
        // Can't send more than sender has
        // Remove require for gas optimization - bsub will revert on underflow
        // require(_balance[sender] >= amount, "ERR_INSUFFICIENT_BAL");

        _balance[sender] = BuniSafeMath.bsub(_balance[sender], amount);
        _balance[recipient] = BuniSafeMath.badd(_balance[recipient], amount);

        emit Transfer(sender, recipient, amount);
    }

    // Transfer from this contract to recipient
    // Emits a transfer event if successful
    function _push(address recipient, uint amount) internal {
        _move(address(this), recipient, amount);
    }

    // Transfer from recipient to this contract
    // Emits a transfer event if successful
    function _pull(address sender, uint amount) internal {
        _move(sender, address(this), amount);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.6.12;


// Imports

import "./BuniConstants.sol";

/**
 * @author Buni Labs
 * @title SafeMath - wrap Solidity operators to prevent underflow/overflow
 * @dev badd and bsub are basically identical to OpenZeppelin SafeMath; mul/div have extra checks
 */
library BuniSafeMath {
    /**
     * @notice Safe addition
     * @param a - first operand
     * @param b - second operand
     * @dev if we are adding b to a, the resulting sum must be greater than a
     * @return - sum of operands; throws if overflow
     */
    function badd(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, "ERR_ADD_OVERFLOW");
        return c;
    }

    /**
     * @notice Safe unsigned subtraction
     * @param a - first operand
     * @param b - second operand
     * @dev Do a signed subtraction, and check that it produces a positive value
     *      (i.e., a - b is valid if b <= a)
     * @return - a - b; throws if underflow
     */
    function bsub(uint a, uint b) internal pure returns (uint) {
        (uint c, bool negativeResult) = bsubSign(a, b);
        require(!negativeResult, "ERR_SUB_UNDERFLOW");
        return c;
    }

    /**
     * @notice Safe signed subtraction
     * @param a - first operand
     * @param b - second operand
     * @dev Do a signed subtraction
     * @return - difference between a and b, and a flag indicating a negative result
     *           (i.e., a - b if a is greater than or equal to b; otherwise b - a)
     */
    function bsubSign(uint a, uint b) internal pure returns (uint, bool) {
        if (b <= a) {
            return (a - b, false);
        } else {
            return (b - a, true);
        }
    }

    /**
     * @notice Safe multiplication
     * @param a - first operand
     * @param b - second operand
     * @dev Multiply safely (and efficiently), rounding down
     * @return - product of operands; throws if overflow or rounding error
     */
    function bmul(uint a, uint b) internal pure returns (uint) {
        // Gas optimization (see github.com/OpenZeppelin/openzeppelin-contracts/pull/522)
        if (a == 0) {
            return 0;
        }

        // Standard overflow check: a/a*b=b
        uint c0 = a * b;
        require(c0 / a == b, "ERR_MUL_OVERFLOW");

        // Round to 0 if x*y < BONE/2?
        uint c1 = c0 + (BuniConstants.BONE / 2);
        require(c1 >= c0, "ERR_MUL_OVERFLOW");
        uint c2 = c1 / BuniConstants.BONE;
        return c2;
    }

    /**
     * @notice Safe division
     * @param dividend - first operand
     * @param divisor - second operand
     * @dev Divide safely (and efficiently), rounding down
     * @return - quotient; throws if overflow or rounding error
     */
    function bdiv(uint dividend, uint divisor) internal pure returns (uint) {
        require(divisor != 0, "ERR_DIV_ZERO");

        // Gas optimization
        if (dividend == 0){
            return 0;
        }

        uint c0 = dividend * BuniConstants.BONE;
        require(c0 / dividend == BuniConstants.BONE, "ERR_DIV_INTERNAL"); // bmul overflow

        uint c1 = c0 + (divisor / 2);
        require(c1 >= c0, "ERR_DIV_INTERNAL"); //  badd require

        uint c2 = c1 / divisor;
        return c2;
    }

    /**
     * @notice Safe unsigned integer modulo
     * @dev Returns the remainder of dividing two unsigned integers.
     *      Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * @param dividend - first operand
     * @param divisor - second operand -- cannot be zero
     * @return - quotient; throws if overflow or rounding error
     */
    function bmod(uint dividend, uint divisor) internal pure returns (uint) {
        require(divisor != 0, "ERR_MODULO_BY_ZERO");

        return dividend % divisor;
    }

    /**
     * @notice Safe unsigned integer max
     * @dev Returns the greater of the two input values
     *
     * @param a - first operand
     * @param b - second operand
     * @return - the maximum of a and b
     */
    function bmax(uint a, uint b) internal pure returns (uint) {
        return a >= b ? a : b;
    }

    /**
     * @notice Safe unsigned integer min
     * @dev returns b, if b < a; otherwise returns a
     *
     * @param a - first operand
     * @param b - second operand
     * @return - the lesser of the two input values
     */
    function bmin(uint a, uint b) internal pure returns (uint) {
        return a < b ? a : b;
    }

    /**
     * @notice Safe unsigned integer average
     * @dev Guard against (a+b) overflow by dividing each operand separately
     *
     * @param a - first operand
     * @param b - second operand
     * @return - the average of the two values
     */
    function baverage(uint a, uint b) internal pure returns (uint) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }

    /**
     * @notice Babylonian square root implementation
     * @dev (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
     * @param y - operand
     * @return z - the square root result
     */
    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        }
        else if (y != 0) {
            z = 1;
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.6.12;

/**
 * @author Buni Labs
 * @title Put all the constants in one place
 */

library BuniConstants {
    // State variables (must be constant in a library)

    // B "ONE" - all math is in the "realm" of 10 ** 18;
    // where numeric 1 = 10 ** 18
    uint public constant BONE = 10**18;
    uint public constant MIN_WEIGHT = BONE;
    uint public constant MAX_WEIGHT = BONE * 50;
    uint public constant MAX_TOTAL_WEIGHT = BONE * 50;
    uint public constant MIN_BALANCE = BONE / 10**6;
    uint public constant MAX_BALANCE = BONE * 10**12;
    uint public constant MIN_POOL_SUPPLY = BONE * 100;
    uint public constant MAX_POOL_SUPPLY = BONE * 10**9;
    uint public constant MIN_FEE = BONE / 10**6;
    uint public constant MAX_FEE = BONE / 10;
    // EXIT_FEE must always be zero, or ConfigurableRightsPool._pushUnderlying will fail
    uint public constant EXIT_FEE = 0;
    uint public constant MAX_IN_RATIO = BONE / 2;
    uint public constant MAX_OUT_RATIO = (BONE / 3) + 1 wei;
    // Must match BConst.MIN_BOUND_TOKENS and BConst.MAX_BOUND_TOKENS
    uint public constant MIN_ASSET_LIMIT = 2;
    uint public constant MAX_ASSET_LIMIT = 8;
    uint public constant MAX_UINT = uint(-1);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.6.12;

// Interface declarations

/* solhint-disable func-order */

interface IERC20 {
    // Emitted when the allowance of a spender for an owner is set by a call to approve.
    // Value is the new allowance
    event Approval(address indexed owner, address indexed spender, uint value);

    // Emitted when value tokens are moved from one account (from) to another (to).
    // Note that value may be zero
    event Transfer(address indexed from, address indexed to, uint value);

    // Returns the amount of tokens in existence
    function totalSupply() external view returns (uint);

    // Returns the amount of tokens owned by account
    function balanceOf(address account) external view returns (uint);

    // Returns the remaining number of tokens that spender will be allowed to spend on behalf of owner
    // through transferFrom. This is zero by default
    // This value changes when approve or transferFrom are called
    function allowance(address owner, address spender) external view returns (uint);

    // Sets amount as the allowance of spender over the caller’s tokens
    // Returns a boolean value indicating whether the operation succeeded
    // Emits an Approval event.
    function approve(address spender, uint amount) external returns (bool);

    // Moves amount tokens from the caller’s account to recipient
    // Returns a boolean value indicating whether the operation succeeded
    // Emits a Transfer event.
    function transfer(address recipient, uint amount) external returns (bool);

    // Moves amount tokens from sender to recipient using the allowance mechanism
    // Amount is then deducted from the caller’s allowance
    // Returns a boolean value indicating whether the operation succeeded
    // Emits a Transfer event
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.6.12;

// Needed to handle structures externally
pragma experimental ABIEncoderV2;

// Imports

import "../interfaces/IBFactory.sol";
import "../utils/PCToken.sol";
import "../utils/BuniReentrancyGuard.sol";
import "../utils/BuniOwnable.sol";
import "../crp/ConfigurableRightsPool.sol";

// Interfaces

// Libraries
import { RightsManager } from "../utils/RightsManager.sol";

// Contracts

/**
 * @author Ampleforth engineering team & Buni Labs
 *
 * @title Ampl Elastic Configurable Rights Pool.
 *
 * @dev   Extension of Buni labs' configurable rights pool (smart-pool).
 *        Amples are a dynamic supply tokens, supply and individual balances change daily by a Rebase operation.
 *        In constant-function markets, Ampleforth's supply adjustments result in Impermanent Loss (IL)
 *        to liquidity providers. The AmplElasticCRP is an extension of Buni Lab's
 *        ConfigurableRightsPool which mitigates IL induced by supply adjustments.
 *
 *        It accomplishes this by doing the following mechanism:
 *        The `resyncWeight` method will be invoked atomically after rebase through Ampleforth's orchestrator.
 *
 *        When rebase changes supply, ampl weight is updated to the geometric mean of
 *        the current ampl weight and the target. Every other token's weight is updated
 *        proportionally such that relative ratios are same.
 *
 *        Weights: {w_ampl, w_t1 ... w_tn}
 *
 *        Rebase_change: x% (Ample's supply changes by x%, can be positive or negative)
 *
 *        Ample target weight: w_ampl_target = (100+x)/100 * w_ampl
 *
 *        w_ampl_new = sqrt(w_ampl * w_ampl_target)  // geometric mean
 *        for i in tn:
 *           w_ti_new = (w_ampl_new * w_ti) / w_ampl_target
 *
 */
contract ElasticSupplyPool is ConfigurableRightsPool {
    using BuniSafeMath for uint;

    // Event declarations

    // Have to redeclare in the subclass, to be emitted from this contract

    event LogCall(
        bytes4  indexed sig,
        address indexed caller,
        bytes data
    ) anonymous;

    event LogJoin(
        address indexed caller,
        address indexed tokenIn,
        uint tokenAmountIn
    );

    event LogExit(
        address indexed caller,
        address indexed tokenOut,
        uint tokenAmountOut
    );

    // Modifiers

    // Function declarations

    /**
     * @notice Construct a new Configurable Rights Pool (wrapper around BPool)
     * @param factoryAddress - the KPoolFactory used to create the underlying pool
     * @param poolParams - CRP pool parameters
     * @param rightsParams - Set of permissions we are assigning to this smart pool
     */
    constructor(
        address factoryAddress,
        ConfigurableRightsPool.PoolParams memory poolParams,
        RightsManager.Rights memory rightsParams
    )
        // solhint-disable-next-line visibility-modifier-order
        public
        ConfigurableRightsPool(factoryAddress, poolParams, rightsParams)
    {
        require(rightsParams.canChangeWeights, "ERR_NOT_CONFIGURABLE_WEIGHTS");
    }

    // External functions

    /**
     * @notice ElasticSupply pools don't have updateWeightsGradually, so cannot call this
     * param initialSupply starting token balance
     * param minimumWeightChangeBlockPeriod - Enforce a minimum time between the start and end blocks
     * param addTokenTimeLockInBlocks - Enforce a mandatory wait time between updates
     *                                   This is also the wait time between committing and applying a new token
     */
    function createPool(
        uint, // initialSupply
        uint, // minimumWeightChangeBlockPeriod
        uint // addTokenTimeLockInBlocks
    )
        external
        override
    {
        revert("ERR_UNSUPPORTED_OPERATION");
    }

    /**
     * @notice Update the weight of an existing token - cannot do this in ElasticSupplyPools
     * param token - token to be reweighted
     * param newWeight - new weight of the token
    */
    function updateWeight(
        address, // token
        uint // newWeight
    )
        external
        logs
        onlyOwner
        needsBPool
        override
    {
        revert("ERR_UNSUPPORTED_OPERATION");
    }

    /**
     * @notice Update weights in a predetermined way, between startBlock and endBlock,
     *         through external calls to pokeWeights -- cannot do this in ElasticSupplyPools
     * @dev Makes sure we aren't already in a weight update scheme
     *      Must call pokeWeights at least once past the end for it to do the final update
     *      and enable calling this again. (Could make this check for that case, but unwarranted complexity.)
     * param newWeights - final weights we want to get to
     * param startBlock - when weights should start to change
     * param endBlock - when weights will be at their final values
    */
    function updateWeightsGradually(
        uint[] calldata, // newWeights
        uint, // startBlock
        uint // endBlock
    )
        external
        logs
        onlyOwner
        needsBPool
        override
    {
       revert("ERR_UNSUPPORTED_OPERATION");
    }

    /**
     * @notice External function called to make the contract update weights according to plan
     *         Unsupported in ElasticSupplyPools
    */
    function pokeWeights()
        external
        logs
        needsBPool
        override
    {
       revert("ERR_UNSUPPORTED_OPERATION");
    }

    /** 
     * @notice Update the weight of a token without changing the price (or transferring tokens)
     * @param token The address of the token in the underlying BPool to be weight adjusted.
     * @dev Checks if the token's current pool balance has deviated from cached balance,
     *      if so it adjusts the token's weights proportional to the deviation.
     *      The underlying BPool enforces bounds on MIN_WEIGHTS=1e18, MAX_WEIGHT=50e18 and TOTAL_WEIGHT=50e18.
     *      NOTE: The BPool.rebind function CAN REVERT if the updated weights go beyond the enforced bounds.
     */
    function resyncWeight(address token)
        external
        logs
        lock
        needsBPool
        virtual
    {
        require(gradualUpdate.startBlock == 0, "ERR_NO_UPDATE_DURING_GRADUAL");
        require(IBPool(address(bPool)).isBound(token), "ERR_NOT_BOUND");

        // get cached balance
        uint tokenBalanceBefore = IBPool(address(bPool)).getBalance(token);

        // sync balance
        IBPool(address(bPool)).gulp(token);

        // get new balance
        uint tokenBalanceAfter = IBPool(address(bPool)).getBalance(token);

        // No-Op
        if(tokenBalanceBefore == tokenBalanceAfter) {
            return;
        }

        // current token weight
        uint tokenWeightBefore = IBPool(address(bPool)).getDenormalizedWeight(token);

        // target token weight = RebaseRatio * previous token weight
        uint tokenWeightTarget = BuniSafeMath.bdiv(
            BuniSafeMath.bmul(tokenWeightBefore, tokenBalanceAfter),
            tokenBalanceBefore
        );

        // new token weight = sqrt(current token weight * target token weight)
        uint tokenWeightAfter = BuniSafeMath.sqrt(
            BuniSafeMath.bdiv(
                BuniSafeMath.bmul(tokenWeightBefore, tokenWeightTarget), 1
            )
        );

        address[] memory tokens = IBPool(address(bPool)).getCurrentTokens();
        for(uint i=0; i<tokens.length; i++){
            if(tokens[i] == token) {
                // adjust weight
                IBPool(address(bPool)).rebind(token, tokenBalanceAfter, tokenWeightAfter);

            }
            else {
                uint otherWeightBefore = IBPool(address(bPool)).getDenormalizedWeight(tokens[i]);
                uint otherBalance = bPool.getBalance(tokens[i]);

                // other token weight = (new token weight * other token weight before) / target token weight
                uint otherWeightAfter = BuniSafeMath.bdiv(
                    BuniSafeMath.bmul(tokenWeightAfter, otherWeightBefore), tokenWeightTarget
                );

                // adjust weight
                IBPool(address(bPool)).rebind(tokens[i], otherBalance, otherWeightAfter);
            }
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.6.12;

interface IBPool {
    function rebind(address token, uint balance, uint denorm) external;
    function setSwapFee(uint swapFee) external;
    function setPublicSwap(bool publicSwap) external;
    function bind(address token, uint balance, uint denorm) external;
    function unbind(address token) external;
    function gulp(address token) external;
    function isBound(address token) external view returns(bool);
    function getBalance(address token) external view returns (uint);
    function totalSupply() external view returns (uint);
    function getSwapFee() external view returns (uint);
    function isPublicSwap() external view returns (bool);
    function getDenormalizedWeight(address token) external view returns (uint);
    function getTotalDenormalizedWeight() external view returns (uint);
    // solhint-disable-next-line func-name-mixedcase
    function EXIT_FEE() external view returns (uint);
 
    function calcPoolOutGivenSingleIn(
        uint tokenBalanceIn,
        uint tokenWeightIn,
        uint poolSupply,
        uint totalWeight,
        uint tokenAmountIn,
        uint swapFee
    )
        external pure
        returns (uint poolAmountOut);

    function calcSingleInGivenPoolOut(
        uint tokenBalanceIn,
        uint tokenWeightIn,
        uint poolSupply,
        uint totalWeight,
        uint poolAmountOut,
        uint swapFee
    )
        external pure
        returns (uint tokenAmountIn);

    function calcSingleOutGivenPoolIn(
        uint tokenBalanceOut,
        uint tokenWeightOut,
        uint poolSupply,
        uint totalWeight,
        uint poolAmountIn,
        uint swapFee
    )
        external pure
        returns (uint tokenAmountOut);

    function calcPoolInGivenSingleOut(
        uint tokenBalanceOut,
        uint tokenWeightOut,
        uint poolSupply,
        uint totalWeight,
        uint tokenAmountOut,
        uint swapFee
    )
        external pure
        returns (uint poolAmountIn);

    function getCurrentTokens()
        external view
        returns (address[] memory tokens);
}

interface IBFactory {
    function newBPool() external returns (IBPool);
    function setBLabs(address b) external;
    function collect(IBPool pool) external;
    function isBPool(address b) external view returns (bool);
    function getKLabs() external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.6.12;

/**
 * @author Buni Labs (and OpenZeppelin)
 * @title Protect against reentrant calls (and also selectively protect view functions)
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {_lock_} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `_lock_` guard, functions marked as
 * `_lock_` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `_lock_` entry
 * points to them.
 *
 * Also adds a _lockview_ modifier, which doesn't create a lock, but fails
 *   if another _lock_ call is in progress
 */
contract BuniReentrancyGuard {
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
    uint private constant _NOT_ENTERED = 1;
    uint private constant _ENTERED = 2;

    uint private _status;

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `_lock_` function from another `_lock_`
     * function is not supported. It is possible to prevent this from happening
     * by making the `_lock_` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier lock() {
        // On the first call to _lock_, _notEntered will be true
        require(_status != _ENTERED, "ERR_REENTRY");

        // Any calls to _lock_ after this point will fail
        _status = _ENTERED;
        _;
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Also add a modifier that doesn't create a lock, but protects functions that
     *      should not be called while a _lock_ function is running
     */
     modifier viewlock() {
        require(_status != _ENTERED, "ERR_REENTRY_VIEW");
        _;
     }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.6.12;

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
contract BuniOwnable {
    // State variables

    address private _owner;

    // Event declarations

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    // Modifiers

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == msg.sender, "ERR_NOT_CONTROLLER");
        _;
    }

    // Function declarations

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        _owner = msg.sender;
    }

    /**
     * @notice Transfers ownership of the contract to a new account (`newOwner`).
     *         Can only be called by the current owner
     * @dev external for gas optimization
     * @param newOwner - address of new owner
     */
    function setController(address newOwner) external onlyOwner {
        require(newOwner != address(0), "ERR_ZERO_ADDRESS");

        emit OwnershipTransferred(_owner, newOwner);

        _owner = newOwner;
    }

    /**
     * @notice Returns the address of the current owner
     * @dev external for gas optimization
     * @return address - of the owner (AKA controller)
     */
    function getController() external view returns (address) {
        return _owner;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.6.12;

// Needed to handle structures externally
pragma experimental ABIEncoderV2;

// Imports

import "../interfaces/IBFactory.sol";
import "../utils/PCToken.sol";
import "../utils/BuniReentrancyGuard.sol";
import "../utils/BuniOwnable.sol";

// Interfaces

// Libraries
import { RightsManager } from "../utils/RightsManager.sol";
import "../utils/SmartPoolManager.sol";
import "../utils/SafeApprove.sol";

// Contracts

/**
 * @author Buni Labs
 * @title Smart Pool with customizable features
 * @notice PCToken is the "Buni Smart Pool" token (transferred upon finalization)
 * @dev Rights are defined as follows (index values into the array)
 *      0: canPauseSwapping - can setPublicSwap back to false after turning it on
 *                            by default, it is off on initialization and can only be turned on
 *      1: canChangeSwapFee - can setSwapFee after initialization (by default, it is fixed at create time)
 *      2: canChangeWeights - can bind new token weights (allowed by default in base pool)
 *      3: canAddRemoveTokens - can bind/unbind tokens (allowed by default in base pool)
 *      4: canWhitelistLPs - can restrict LPs to a whitelist
 *      5: canChangeCap - can change the BSP cap (max # of pool tokens)
 *
 * Note that functions called on bPool and bFactory may look like internal calls,
 *   but since they are contracts accessed through an interface, they are really external.
 * To make this explicit, we could write "IBPool(address(bPool)).function()" everywhere,
 *   instead of "bPool.function()".
 */
contract ConfigurableRightsPool is PCToken, BuniOwnable, BuniReentrancyGuard {
    using BuniSafeMath for uint;
    using SafeApprove for IERC20;

    // Type declarations

    struct PoolParams {
        // Buni Pool Token (representing shares of the pool)
        string poolTokenSymbol;
        string poolTokenName;
        // Tokens inside the Pool
        address[] constituentTokens;
        uint[] tokenBalances;
        uint[] tokenWeights;
        uint swapFee;
    }

    // State variables

    IBFactory public bFactory;
    IBPool public bPool;

    // Struct holding the rights configuration
    RightsManager.Rights public rights;

    // Hold the parameters used in updateWeightsGradually
    SmartPoolManager.GradualUpdateParams public gradualUpdate;

    // This is for adding a new (currently unbound) token to the pool
    // It's a two-step process: commitAddToken(), then applyAddToken()
    SmartPoolManager.NewTokenParams public newToken;

    // Fee is initialized on creation, and can be changed if permission is set
    // Only needed for temporary storage between construction and createPool
    // Thereafter, the swap fee should always be read from the underlying pool
    uint private _initialSwapFee;

    // Store the list of tokens in the pool, and balances
    // NOTE that the token list is *only* used to store the pool tokens between
    //   construction and createPool - thereafter, use the underlying BPool's list
    //   (avoids synchronization issues)
    address[] private _initialTokens;
    uint[] private _initialBalances;

    // Enforce a minimum time between the start and end blocks
    uint public minimumWeightChangeBlockPeriod;
    // Enforce a mandatory wait time between updates
    // This is also the wait time between committing and applying a new token
    uint public addTokenTimeLockInBlocks;

    // Whitelist of LPs (if configured)
    mapping(address => bool) private _liquidityProviderWhitelist;

    // Cap on the pool size (i.e., # of tokens minted when joining)
    // Limits the risk of experimental pools; failsafe/backup for fixed-size pools
    uint public bspCap;

    // Event declarations

    // Anonymous logger event - can only be filtered by contract address

    event LogCall(
        bytes4  indexed sig,
        address indexed caller,
        bytes data
    ) anonymous;

    event LogJoin(
        address indexed caller,
        address indexed tokenIn,
        uint tokenAmountIn
    );

    event LogExit(
        address indexed caller,
        address indexed tokenOut,
        uint tokenAmountOut
    );

    event CapChanged(
        address indexed caller,
        uint oldCap,
        uint newCap
    );
    
    event NewTokenCommitted(
        address indexed token,
        address indexed pool,
        address indexed caller
    );

    // Modifiers

    modifier logs() {
        emit LogCall(msg.sig, msg.sender, msg.data);
        _;
    }

    // Mark functions that require delegation to the underlying Pool
    modifier needsBPool() {
        require(address(bPool) != address(0), "ERR_NOT_CREATED");
        _;
    }

    modifier lockUnderlyingPool() {
        // Turn off swapping on the underlying pool during joins
        // Otherwise tokens with callbacks would enable attacks involving simultaneous swaps and joins
        bool origSwapState = bPool.isPublicSwap();
        bPool.setPublicSwap(false);
        _;
        bPool.setPublicSwap(origSwapState);
    }

    // Default values for these variables (used only in updateWeightsGradually), set in the constructor
    // Pools without permission to update weights cannot use them anyway, and should call
    //   the default createPool() function.
    // To override these defaults, pass them into the overloaded createPool()
    // Period is in blocks; 500 blocks ~ 2 hours; 90,000 blocks ~ 2 weeks
    uint public constant DEFAULT_MIN_WEIGHT_CHANGE_BLOCK_PERIOD = 90000;
    uint public constant DEFAULT_ADD_TOKEN_TIME_LOCK_IN_BLOCKS = 500;

    // Function declarations

    /**
     * @notice Construct a new Configurable Rights Pool (wrapper around BPool)
     * @dev _initialTokens and _swapFee are only used for temporary storage between construction
     *      and create pool, and should not be used thereafter! _initialTokens is destroyed in
     *      createPool to prevent this, and _swapFee is kept in sync (defensively), but
     *      should never be used except in this constructor and createPool()
     * @param factoryAddress - the KPoolFactory used to create the underlying pool
     * @param poolParams - struct containing pool parameters
     * @param rightsStruct - Set of permissions we are assigning to this smart pool
     */
    constructor(
        address factoryAddress,
        PoolParams memory poolParams,
        RightsManager.Rights memory rightsStruct
    )
        public
        PCToken(poolParams.poolTokenSymbol, poolParams.poolTokenName)
    {
        // We don't have a pool yet; check now or it will fail later (in order of likelihood to fail)
        // (and be unrecoverable if they don't have permission set to change it)
        // Most likely to fail, so check first
        require(poolParams.swapFee >= BuniConstants.MIN_FEE, "ERR_INVALID_SWAP_FEE");
        require(poolParams.swapFee <= BuniConstants.MAX_FEE, "ERR_INVALID_SWAP_FEE");

        // Arrays must be parallel
        require(poolParams.tokenBalances.length == poolParams.constituentTokens.length, "ERR_START_BALANCES_MISMATCH");
        require(poolParams.tokenWeights.length == poolParams.constituentTokens.length, "ERR_START_WEIGHTS_MISMATCH");
        // Cannot have too many or too few - technically redundant, since BPool.bind() would fail later
        // But if we don't check now, we could have a useless contract with no way to create a pool

        require(poolParams.constituentTokens.length >= BuniConstants.MIN_ASSET_LIMIT, "ERR_TOO_FEW_TOKENS");
        require(poolParams.constituentTokens.length <= BuniConstants.MAX_ASSET_LIMIT, "ERR_TOO_MANY_TOKENS");
        // There are further possible checks (e.g., if they use the same token twice), but
        // we can let bind() catch things like that (i.e., not things that might reasonably work)

        SmartPoolManager.verifyTokenCompliance(poolParams.constituentTokens);

        bFactory = IBFactory(factoryAddress);
        rights = rightsStruct;
        _initialTokens = poolParams.constituentTokens;
        _initialBalances = poolParams.tokenBalances;
        _initialSwapFee = poolParams.swapFee;

        // These default block time parameters can be overridden in createPool
        minimumWeightChangeBlockPeriod = DEFAULT_MIN_WEIGHT_CHANGE_BLOCK_PERIOD;
        addTokenTimeLockInBlocks = DEFAULT_ADD_TOKEN_TIME_LOCK_IN_BLOCKS;
        
        gradualUpdate.startWeights = poolParams.tokenWeights;
        // Initializing (unnecessarily) for documentation - 0 means no gradual weight change has been initiated
        gradualUpdate.startBlock = 0;
        // By default, there is no cap (unlimited pool token minting)
        bspCap = BuniConstants.MAX_UINT;
    }

    // External functions

    /**
     * @notice Set the swap fee on the underlying pool
     * @dev Keep the local version and core in sync (see below)
     *      bPool is a contract interface; function calls on it are external
     * @param swapFee in Wei
     */
    function setSwapFee(uint swapFee)
        external
        logs
        lock
        onlyOwner
        needsBPool
        virtual
    {
        require(rights.canChangeSwapFee, "ERR_NOT_CONFIGURABLE_SWAP_FEE");

        // Underlying pool will check against min/max fee
        bPool.setSwapFee(swapFee);
    }

    /**
     * @notice Getter for the publicSwap field on the underlying pool
     * @dev viewLock, because setPublicSwap is lock
     *      bPool is a contract interface; function calls on it are external
     * @return Current value of isPublicSwap
     */
    function isPublicSwap()
        external
        view
        viewlock
        needsBPool
        virtual
        returns (bool)
    {
        return bPool.isPublicSwap();
    }

    /**
     * @notice Set the cap (max # of pool tokens)
     * @dev _bspCap defaults in the constructor to unlimited
     *      Can set to 0 (or anywhere below the current supply), to halt new investment
     *      Prevent setting it before creating a pool, since createPool sets to intialSupply
     *      (it does this to avoid an unlimited cap window between construction and createPool)
     *      Therefore setting it before then has no effect, so should not be allowed
     * @param newCap - new value of the cap
     */
    function setCap(uint newCap)
        external
        logs
        lock
        needsBPool
        onlyOwner
    {
        require(rights.canChangeCap, "ERR_CANNOT_CHANGE_CAP");

        emit CapChanged(msg.sender, bspCap, newCap);

        bspCap = newCap;
    }

    /**
     * @notice Set the public swap flag on the underlying pool
     * @dev If this smart pool has canPauseSwapping enabled, we can turn publicSwap off if it's already on
     *      Note that if they turn swapping off - but then finalize the pool - finalizing will turn the
     *      swapping back on. They're not supposed to finalize the underlying pool... would defeat the
     *      smart pool functions. (Only the owner can finalize the pool - which is this contract -
     *      so there is no risk from outside.)
     *
     *      bPool is a contract interface; function calls on it are external
     * @param publicSwap new value of the swap
     */
    function setPublicSwap(bool publicSwap)
        external
        logs
        lock
        onlyOwner
        needsBPool
        virtual
    {
        require(rights.canPauseSwapping, "ERR_NOT_PAUSABLE_SWAP");

        bPool.setPublicSwap(publicSwap);
    }

    /**
     * @notice Create a new Smart Pool - and set the block period time parameters
     * @dev Initialize the swap fee to the value provided in the CRP constructor
     *      Can be changed if the canChangeSwapFee permission is enabled
     *      Time parameters will be fixed at these values
     *
     *      If this contract doesn't have canChangeWeights permission - or you want to use the default
     *      values, the block time arguments are not needed, and you can just call the single-argument
     *      createPool()
     * @param initialSupply - Starting token balance
     * @param minimumWeightChangeBlockPeriodParam - Enforce a minimum time between the start and end blocks
     * @param addTokenTimeLockInBlocksParam - Enforce a mandatory wait time between updates
     *                                   This is also the wait time between committing and applying a new token
     */
    function createPool(
        uint initialSupply,
        uint minimumWeightChangeBlockPeriodParam,
        uint addTokenTimeLockInBlocksParam
    )
        external
        onlyOwner
        logs
        lock
        virtual
    {
        require (minimumWeightChangeBlockPeriodParam >= addTokenTimeLockInBlocksParam,
                "ERR_INCONSISTENT_TOKEN_TIME_LOCK");
 
        minimumWeightChangeBlockPeriod = minimumWeightChangeBlockPeriodParam;
        addTokenTimeLockInBlocks = addTokenTimeLockInBlocksParam;

        createPoolInternal(initialSupply);
    }

    /**
     * @notice Create a new Smart Pool
     * @dev Delegates to internal function
     * @param initialSupply starting token balance
     */
    function createPool(uint initialSupply)
        external
        onlyOwner
        logs
        lock
        virtual
    {
        createPoolInternal(initialSupply);
    }

    /**
     * @notice Update the weight of an existing token
     * @dev Notice Balance is not an input (like with rebind on BPool) since we will require prices not to change
     *      This is achieved by forcing balances to change proportionally to weights, so that prices don't change
     *      If prices could be changed, this would allow the controller to drain the pool by arbing price changes
     * @param token - token to be reweighted
     * @param newWeight - new weight of the token
    */
    function updateWeight(address token, uint newWeight)
        external
        logs
        lock
        onlyOwner
        needsBPool
        virtual
    {
        require(rights.canChangeWeights, "ERR_NOT_CONFIGURABLE_WEIGHTS");

        // We don't want people to set weights manually if there's a block-based update in progress
        require(gradualUpdate.startBlock == 0, "ERR_NO_UPDATE_DURING_GRADUAL");

        // Delegate to library to save space
        SmartPoolManager.updateWeight(IConfigurableRightsPool(address(this)), bPool, token, newWeight);
    }

    /**
     * @notice Update weights in a predetermined way, between startBlock and endBlock,
     *         through external calls to pokeWeights
     * @dev Must call pokeWeights at least once past the end for it to do the final update
     *      and enable calling this again.
     *      It is possible to call updateWeightsGradually during an update in some use cases
     *      For instance, setting newWeights to currentWeights to stop the update where it is
     * @param newWeights - final weights we want to get to. Note that the ORDER (and number) of
     *                     tokens can change if you have added or removed tokens from the pool
     *                     It ensures the counts are correct, but can't help you with the order!
     *                     You can get the underlying BPool (it's public), and call 
     *                     getCurrentTokens() to see the current ordering, if you're not sure
     * @param startBlock - when weights should start to change
     * @param endBlock - when weights will be at their final values
    */
    function updateWeightsGradually(
        uint[] calldata newWeights,
        uint startBlock,
        uint endBlock
    )
        external
        logs
        lock
        onlyOwner
        needsBPool
        virtual
    {
        require(rights.canChangeWeights, "ERR_NOT_CONFIGURABLE_WEIGHTS");
         // Don't start this when we're in the middle of adding a new token
        require(!newToken.isCommitted, "ERR_PENDING_TOKEN_ADD");
        
        // Library computes the startBlock, computes startWeights as the current
        // denormalized weights of the core pool tokens.
        SmartPoolManager.updateWeightsGradually(
            bPool,
            gradualUpdate,
            newWeights,
            startBlock,
            endBlock,
            minimumWeightChangeBlockPeriod
        );
    }

    /**
     * @notice External function called to make the contract update weights according to plan
     * @dev Still works if we poke after the end of the period; also works if the weights don't change
     *      Resets if we are poking beyond the end, so that we can do it again
    */
    function pokeWeights()
        external
        logs
        lock
        needsBPool
        virtual
    {
        require(rights.canChangeWeights, "ERR_NOT_CONFIGURABLE_WEIGHTS");

        // Delegate to library to save space
        SmartPoolManager.pokeWeights(bPool, gradualUpdate);
    }

    /**
     * @notice Schedule (commit) a token to be added; must call applyAddToken after a fixed
     *         number of blocks to actually add the token
     *
     * @dev The purpose of this two-stage commit is to give warning of a potentially dangerous
     *      operation. A malicious pool operator could add a large amount of a low-value token,
     *      then drain the pool through price manipulation. Of course, there are many
     *      legitimate purposes, such as adding additional collateral tokens.
     *
     * @param token - the token to be added
     * @param balance - how much to be added
     * @param denormalizedWeight - the desired token weight
     */
    function commitAddToken(
        address token,
        uint balance,
        uint denormalizedWeight
    )
        external
        logs
        lock
        onlyOwner
        needsBPool
        virtual
    {
        require(rights.canAddRemoveTokens, "ERR_CANNOT_ADD_REMOVE_TOKENS");

        // Can't do this while a progressive update is happening
        require(gradualUpdate.startBlock == 0, "ERR_NO_UPDATE_DURING_GRADUAL");

        SmartPoolManager.verifyTokenCompliance(token);

        emit NewTokenCommitted(token, address(this), msg.sender);

        // Delegate to library to save space
        SmartPoolManager.commitAddToken(
            bPool,
            token,
            balance,
            denormalizedWeight,
            newToken
        );
    }

    /**
     * @notice Add the token previously committed (in commitAddToken) to the pool
     */
    function applyAddToken()
        external
        logs
        lock
        onlyOwner
        needsBPool
        virtual
    {
        require(rights.canAddRemoveTokens, "ERR_CANNOT_ADD_REMOVE_TOKENS");

        // Delegate to library to save space
        SmartPoolManager.applyAddToken(
            IConfigurableRightsPool(address(this)),
            bPool,
            addTokenTimeLockInBlocks,
            newToken
        );
    }

     /**
     * @notice Remove a token from the pool
     * @dev bPool is a contract interface; function calls on it are external
     * @param token - token to remove
     */
    function removeToken(address token)
        external
        logs
        lock
        onlyOwner
        needsBPool
    {
        // It's possible to have remove rights without having add rights
        require(rights.canAddRemoveTokens,"ERR_CANNOT_ADD_REMOVE_TOKENS");
        // After createPool, token list is maintained in the underlying BPool
        require(!newToken.isCommitted, "ERR_REMOVE_WITH_ADD_PENDING");
        // Prevent removing during an update (or token lists can get out of sync)
        require(gradualUpdate.startBlock == 0, "ERR_NO_UPDATE_DURING_GRADUAL");

        // Delegate to library to save space
        SmartPoolManager.removeToken(IConfigurableRightsPool(address(this)), bPool, token);
    } 

    /**
     * @notice Join a pool
     * @dev Emits a LogJoin event (for each token)
     *      bPool is a contract interface; function calls on it are external
     * @param poolAmountOut - number of pool tokens to receive
     * @param maxAmountsIn - Max amount of asset tokens to spend
     */
    function joinPool(uint poolAmountOut, uint[] calldata maxAmountsIn)
        external
        logs
        lock
        needsBPool
        lockUnderlyingPool
    {
        require(!rights.canWhitelistLPs || _liquidityProviderWhitelist[msg.sender],
                "ERR_NOT_ON_WHITELIST");

        // Delegate to library to save space

        // Library computes actualAmountsIn, and does many validations
        // Cannot call the push/pull/min from an external library for
        // any of these pool functions. Since msg.sender can be anybody,
        // they must be internal
        uint[] memory actualAmountsIn = SmartPoolManager.joinPool(
                                            IConfigurableRightsPool(address(this)),
                                            bPool,
                                            poolAmountOut,
                                            maxAmountsIn
                                        );

        // After createPool, token list is maintained in the underlying BPool
        address[] memory poolTokens = bPool.getCurrentTokens();

        for (uint i = 0; i < poolTokens.length; i++) {
            address t = poolTokens[i];
            uint tokenAmountIn = actualAmountsIn[i];

            emit LogJoin(msg.sender, t, tokenAmountIn);

            _pullUnderlying(t, msg.sender, tokenAmountIn);
        }

        _mintPoolShare(poolAmountOut);
        _pushPoolShare(msg.sender, poolAmountOut);
    }

    /**
     * @notice Exit a pool - redeem pool tokens for underlying assets
     * @dev Emits a LogExit event for each token
     *      bPool is a contract interface; function calls on it are external
     * @param poolAmountIn - amount of pool tokens to redeem
     * @param minAmountsOut - minimum amount of asset tokens to receive
     */
    function exitPool(uint poolAmountIn, uint[] calldata minAmountsOut)
        external
        logs
        lock
        needsBPool
        lockUnderlyingPool
    {
        // Delegate to library to save space

        // Library computes actualAmountsOut, and does many validations
        // Also computes the exitFee and pAiAfterExitFee
        (uint exitFee,
         uint pAiAfterExitFee,
         uint[] memory actualAmountsOut) = SmartPoolManager.exitPool(
                                               IConfigurableRightsPool(address(this)),
                                               bPool,
                                               poolAmountIn,
                                               minAmountsOut
                                           );

        _pullPoolShare(msg.sender, poolAmountIn);
        _pushPoolShare(address(bFactory), exitFee);
        _burnPoolShare(pAiAfterExitFee);

        // After createPool, token list is maintained in the underlying BPool
        address[] memory poolTokens = bPool.getCurrentTokens();

        for (uint i = 0; i < poolTokens.length; i++) {
            address t = poolTokens[i];
            uint tokenAmountOut = actualAmountsOut[i];

            emit LogExit(msg.sender, t, tokenAmountOut);

            _pushUnderlying(t, msg.sender, tokenAmountOut);
        }
    }

    /**
     * @notice Join by swapping a fixed amount of an external token in (must be present in the pool)
     *         System calculates the pool token amount
     * @dev emits a LogJoin event
     * @param tokenIn - which token we're transferring in
     * @param tokenAmountIn - amount of deposit
     * @param minPoolAmountOut - minimum of pool tokens to receive
     * @return poolAmountOut - amount of pool tokens minted and transferred
     */
    function joinswapExternAmountIn(
        address tokenIn,
        uint tokenAmountIn,
        uint minPoolAmountOut
    )
        external
        logs
        lock
        needsBPool
        returns (uint poolAmountOut)
    {
        require(!rights.canWhitelistLPs || _liquidityProviderWhitelist[msg.sender],
                "ERR_NOT_ON_WHITELIST");

        // Delegate to library to save space
        poolAmountOut = SmartPoolManager.joinswapExternAmountIn(
                            IConfigurableRightsPool(address(this)),
                            bPool,
                            tokenIn,
                            tokenAmountIn,
                            minPoolAmountOut
                        );

        emit LogJoin(msg.sender, tokenIn, tokenAmountIn);

        _mintPoolShare(poolAmountOut);
        _pushPoolShare(msg.sender, poolAmountOut);
        _pullUnderlying(tokenIn, msg.sender, tokenAmountIn);

        return poolAmountOut;
    }

    /**
     * @notice Join by swapping an external token in (must be present in the pool)
     *         To receive an exact amount of pool tokens out. System calculates the deposit amount
     * @dev emits a LogJoin event
     * @param tokenIn - which token we're transferring in (system calculates amount required)
     * @param poolAmountOut - amount of pool tokens to be received
     * @param maxAmountIn - Maximum asset tokens that can be pulled to pay for the pool tokens
     * @return tokenAmountIn - amount of asset tokens transferred in to purchase the pool tokens
     */
    function joinswapPoolAmountOut(
        address tokenIn,
        uint poolAmountOut,
        uint maxAmountIn
    )
        external
        logs
        lock
        needsBPool
        returns (uint tokenAmountIn)
    {
        require(!rights.canWhitelistLPs || _liquidityProviderWhitelist[msg.sender],
                "ERR_NOT_ON_WHITELIST");

        // Delegate to library to save space
        tokenAmountIn = SmartPoolManager.joinswapPoolAmountOut(
                            IConfigurableRightsPool(address(this)),
                            bPool,
                            tokenIn,
                            poolAmountOut,
                            maxAmountIn
                        );

        emit LogJoin(msg.sender, tokenIn, tokenAmountIn);

        _mintPoolShare(poolAmountOut);
        _pushPoolShare(msg.sender, poolAmountOut);
        _pullUnderlying(tokenIn, msg.sender, tokenAmountIn);

        return tokenAmountIn;
    }

    /**
     * @notice Exit a pool - redeem a specific number of pool tokens for an underlying asset
     *         Asset must be present in the pool, and will incur an EXIT_FEE (if set to non-zero)
     * @dev Emits a LogExit event for the token
     * @param tokenOut - which token the caller wants to receive
     * @param poolAmountIn - amount of pool tokens to redeem
     * @param minAmountOut - minimum asset tokens to receive
     * @return tokenAmountOut - amount of asset tokens returned
     */
    function exitswapPoolAmountIn(
        address tokenOut,
        uint poolAmountIn,
        uint minAmountOut
    )
        external
        logs
        lock
        needsBPool
        returns (uint tokenAmountOut)
    {
        // Delegate to library to save space

        // Calculates final amountOut, and the fee and final amount in
        (uint exitFee,
         uint amountOut) = SmartPoolManager.exitswapPoolAmountIn(
                               IConfigurableRightsPool(address(this)),
                               bPool,
                               tokenOut,
                               poolAmountIn,
                               minAmountOut
                           );

        tokenAmountOut = amountOut;
        uint pAiAfterExitFee = BuniSafeMath.bsub(poolAmountIn, exitFee);

        emit LogExit(msg.sender, tokenOut, tokenAmountOut);

        _pullPoolShare(msg.sender, poolAmountIn);
        _burnPoolShare(pAiAfterExitFee);
        _pushPoolShare(address(bFactory), exitFee);
        _pushUnderlying(tokenOut, msg.sender, tokenAmountOut);

        return tokenAmountOut;
    }

    /**
     * @notice Exit a pool - redeem pool tokens for a specific amount of underlying assets
     *         Asset must be present in the pool
     * @dev Emits a LogExit event for the token
     * @param tokenOut - which token the caller wants to receive
     * @param tokenAmountOut - amount of underlying asset tokens to receive
     * @param maxPoolAmountIn - maximum pool tokens to be redeemed
     * @return poolAmountIn - amount of pool tokens redeemed
     */
    function exitswapExternAmountOut(
        address tokenOut,
        uint tokenAmountOut,
        uint maxPoolAmountIn
    )
        external
        logs
        lock
        needsBPool
        returns (uint poolAmountIn)
    {
        // Delegate to library to save space

        // Calculates final amounts in, accounting for the exit fee
        (uint exitFee,
         uint amountIn) = SmartPoolManager.exitswapExternAmountOut(
                              IConfigurableRightsPool(address(this)),
                              bPool,
                              tokenOut,
                              tokenAmountOut,
                              maxPoolAmountIn
                          );

        poolAmountIn = amountIn;
        uint pAiAfterExitFee = BuniSafeMath.bsub(poolAmountIn, exitFee);

        emit LogExit(msg.sender, tokenOut, tokenAmountOut);

        _pullPoolShare(msg.sender, poolAmountIn);
        _burnPoolShare(pAiAfterExitFee);
        _pushPoolShare(address(bFactory), exitFee);
        _pushUnderlying(tokenOut, msg.sender, tokenAmountOut);
        
        return poolAmountIn;
    }

    /**
     * @notice Add to the whitelist of liquidity providers (if enabled)
     * @param provider - address of the liquidity provider
     */
    function whitelistLiquidityProvider(address provider)
        external
        onlyOwner
        lock
        logs
    {
        require(rights.canWhitelistLPs, "ERR_CANNOT_WHITELIST_LPS");
        require(provider != address(0), "ERR_INVALID_ADDRESS");

        _liquidityProviderWhitelist[provider] = true;
    }

    /**
     * @notice Remove from the whitelist of liquidity providers (if enabled)
     * @param provider - address of the liquidity provider
     */
    function removeWhitelistedLiquidityProvider(address provider)
        external
        onlyOwner
        lock
        logs
    {
        require(rights.canWhitelistLPs, "ERR_CANNOT_WHITELIST_LPS");
        require(_liquidityProviderWhitelist[provider], "ERR_LP_NOT_WHITELISTED");
        require(provider != address(0), "ERR_INVALID_ADDRESS");

        _liquidityProviderWhitelist[provider] = false;
    }

    /**
     * @notice Check if an address is a liquidity provider
     * @dev If the whitelist feature is not enabled, anyone can provide liquidity (assuming finalized)
     * @return boolean value indicating whether the address can join a pool
     */
    function canProvideLiquidity(address provider)
        external
        view
        returns(bool)
    {
        if (rights.canWhitelistLPs) {
            return _liquidityProviderWhitelist[provider];
        }
        else {
            // Probably don't strictly need this (could just return true)
            // But the null address can't provide funds
            return provider != address(0);
        }
    }

    /**
     * @notice Getter for specific permissions
     * @dev value of the enum is just the 0-based index in the enumeration
     *      For instance canPauseSwapping is 0; canChangeWeights is 2
     * @return token boolean true if we have the given permission
    */
    function hasPermission(RightsManager.Permissions permission)
        external
        view
        virtual
        returns(bool)
    {
        return RightsManager.hasPermission(rights, permission);
    }

    /**
     * @notice Get the denormalized weight of a token
     * @dev viewlock to prevent calling if it's being updated
     * @return token weight
     */
    function getDenormalizedWeight(address token)
        external
        view
        viewlock
        needsBPool
        returns (uint)
    {
        return bPool.getDenormalizedWeight(token);
    }

    /**
     * @notice Getter for the RightsManager contract
     * @dev Convenience function to get the address of the RightsManager library (so clients can check version)
     * @return address of the RightsManager library
    */
    function getRightsManagerVersion() external pure returns (address) {
        return address(RightsManager);
    }

    /**
     * @notice Getter for the BuniSafeMath contract
     * @dev Convenience function to get the address of the BuniSafeMath library (so clients can check version)
     * @return address of the BuniSafeMath library
    */
    function getBuniSafeMathVersion() external pure returns (address) {
        return address(BuniSafeMath);
    }

    /**
     * @notice Getter for the SmartPoolManager contract
     * @dev Convenience function to get the address of the SmartPoolManager library (so clients can check version)
     * @return address of the SmartPoolManager library
    */
    function getSmartPoolManagerVersion() external pure returns (address) {
        return address(SmartPoolManager);
    }

    // Public functions

    // "Public" versions that can safely be called from SmartPoolManager
    // Allows only the contract itself to call them (not the controller or any external account)

    function mintPoolShareFromLib(uint amount) public {
        require (msg.sender == address(this), "ERR_NOT_CONTROLLER");

        _mint(amount);
    }

    function pushPoolShareFromLib(address to, uint amount) public {
        require (msg.sender == address(this), "ERR_NOT_CONTROLLER");

        _push(to, amount);
    }

    function pullPoolShareFromLib(address from, uint amount) public  {
        require (msg.sender == address(this), "ERR_NOT_CONTROLLER");

        _pull(from, amount);
    }

    function burnPoolShareFromLib(uint amount) public  {
        require (msg.sender == address(this), "ERR_NOT_CONTROLLER");

        _burn(amount);
    }

    // Internal functions

    // Lint wants the function to have a leading underscore too
    /* solhint-disable private-vars-leading-underscore */

    /**
     * @notice Create a new Smart Pool
     * @dev Initialize the swap fee to the value provided in the CRP constructor
     *      Can be changed if the canChangeSwapFee permission is enabled
     * @param initialSupply starting token balance
     */
    function createPoolInternal(uint initialSupply) internal {
        require(address(bPool) == address(0), "ERR_IS_CREATED");
        require(initialSupply >= BuniConstants.MIN_POOL_SUPPLY, "ERR_INIT_SUPPLY_MIN");
        require(initialSupply <= BuniConstants.MAX_POOL_SUPPLY, "ERR_INIT_SUPPLY_MAX");

        // If the controller can change the cap, initialize it to the initial supply
        // Defensive programming, so that there is no gap between creating the pool
        // (initialized to unlimited in the constructor), and setting the cap,
        // which they will presumably do if they have this right.
        if (rights.canChangeCap) {
            bspCap = initialSupply;
        }

        // There is technically reentrancy here, since we're making external calls and
        // then transferring tokens. However, the external calls are all to the underlying BPool

        // To the extent possible, modify state variables before calling functions
        _mintPoolShare(initialSupply);
        _pushPoolShare(msg.sender, initialSupply);

        // Deploy new BPool (bFactory and bPool are interfaces; all calls are external)
        bPool = bFactory.newBPool();

        // EXIT_FEE must always be zero, or ConfigurableRightsPool._pushUnderlying will fail
        require(bPool.EXIT_FEE() == 0, "ERR_NONZERO_EXIT_FEE");
        require(BuniConstants.EXIT_FEE == 0, "ERR_NONZERO_EXIT_FEE");

        for (uint i = 0; i < _initialTokens.length; i++) {
            address t = _initialTokens[i];
            uint bal = _initialBalances[i];
            uint denorm = gradualUpdate.startWeights[i];

            bool returnValue = IERC20(t).transferFrom(msg.sender, address(this), bal);
            require(returnValue, "ERR_ERC20_FALSE");

            returnValue = IERC20(t).safeApprove(address(bPool), BuniConstants.MAX_UINT);
            require(returnValue, "ERR_ERC20_FALSE");

            bPool.bind(t, bal, denorm);
        }

        while (_initialTokens.length > 0) {
            // Modifying state variable after external calls here,
            // but not essential, so not dangerous
            _initialTokens.pop();
        }

        // Set fee to the initial value set in the constructor
        // Hereafter, read the swapFee from the underlying pool, not the local state variable
        bPool.setSwapFee(_initialSwapFee);
        bPool.setPublicSwap(true);

        // "destroy" the temporary swap fee (like _initialTokens above) in case a subclass tries to use it
        _initialSwapFee = 0;
    }

    /* solhint-enable private-vars-leading-underscore */

    // Rebind BPool and pull tokens from address
    // bPool is a contract interface; function calls on it are external
    function _pullUnderlying(address erc20, address from, uint amount) internal needsBPool {
        // Gets current Balance of token i, Bi, and weight of token i, Wi, from BPool.
        uint tokenBalance = bPool.getBalance(erc20);
        uint tokenWeight = bPool.getDenormalizedWeight(erc20);

        bool xfer = IERC20(erc20).transferFrom(from, address(this), amount);
        require(xfer, "ERR_ERC20_FALSE");
        bPool.rebind(erc20, BuniSafeMath.badd(tokenBalance, amount), tokenWeight);
    }

    // Rebind BPool and push tokens to address
    // bPool is a contract interface; function calls on it are external
    function _pushUnderlying(address erc20, address to, uint amount) internal needsBPool {
        // Gets current Balance of token i, Bi, and weight of token i, Wi, from BPool.
        uint tokenBalance = bPool.getBalance(erc20);
        uint tokenWeight = bPool.getDenormalizedWeight(erc20);
        bPool.rebind(erc20, BuniSafeMath.bsub(tokenBalance, amount), tokenWeight);

        bool xfer = IERC20(erc20).transfer(to, amount);
        require(xfer, "ERR_ERC20_FALSE");
    }

    // Wrappers around corresponding core functions

    // 
    function _mint(uint amount) internal override {
        super._mint(amount);
        require(varTotalSupply <= bspCap, "ERR_CAP_LIMIT_REACHED");
    }

    function _mintPoolShare(uint amount) internal {
        _mint(amount);
    }

    function _pushPoolShare(address to, uint amount) internal {
        _push(to, amount);
    }

    function _pullPoolShare(address from, uint amount) internal  {
        _pull(from, amount);
    }

    function _burnPoolShare(uint amount) internal  {
        _burn(amount);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.6.12;

// Needed to handle structures externally
pragma experimental ABIEncoderV2;

/**
 * @author Buni Labs
 * @title Manage Configurable Rights for the smart pool
 *      canPauseSwapping - can setPublicSwap back to false after turning it on
 *                         by default, it is off on initialization and can only be turned on
 *      canChangeSwapFee - can setSwapFee after initialization (by default, it is fixed at create time)
 *      canChangeWeights - can bind new token weights (allowed by default in base pool)
 *      canAddRemoveTokens - can bind/unbind tokens (allowed by default in base pool)
 *      canWhitelistLPs - can limit liquidity providers to a given set of addresses
 *      canChangeCap - can change the BSP cap (max # of pool tokens)
 */
library RightsManager {

    // Type declarations

    enum Permissions { PAUSE_SWAPPING,
                       CHANGE_SWAP_FEE,
                       CHANGE_WEIGHTS,
                       ADD_REMOVE_TOKENS,
                       WHITELIST_LPS,
                       CHANGE_CAP }

    struct Rights {
        bool canPauseSwapping;
        bool canChangeSwapFee;
        bool canChangeWeights;
        bool canAddRemoveTokens;
        bool canWhitelistLPs;
        bool canChangeCap;
    }

    // State variables (can only be constants in a library)
    bool public constant DEFAULT_CAN_PAUSE_SWAPPING = false;
    bool public constant DEFAULT_CAN_CHANGE_SWAP_FEE = true;
    bool public constant DEFAULT_CAN_CHANGE_WEIGHTS = true;
    bool public constant DEFAULT_CAN_ADD_REMOVE_TOKENS = false;
    bool public constant DEFAULT_CAN_WHITELIST_LPS = false;
    bool public constant DEFAULT_CAN_CHANGE_CAP = false;

    // Functions

    /**
     * @notice create a struct from an array (or return defaults)
     * @dev If you pass an empty array, it will construct it using the defaults
     * @param a - array input
     * @return Rights struct
     */ 
    function constructRights(bool[] calldata a) external pure returns (Rights memory) {
        if (a.length == 0) {
            return Rights(DEFAULT_CAN_PAUSE_SWAPPING,
                          DEFAULT_CAN_CHANGE_SWAP_FEE,
                          DEFAULT_CAN_CHANGE_WEIGHTS,
                          DEFAULT_CAN_ADD_REMOVE_TOKENS,
                          DEFAULT_CAN_WHITELIST_LPS,
                          DEFAULT_CAN_CHANGE_CAP);
        }
        else {
            return Rights(a[0], a[1], a[2], a[3], a[4], a[5]);
        }
    }

    /**
     * @notice Convert rights struct to an array (e.g., for events, GUI)
     * @dev avoids multiple calls to hasPermission
     * @param rights - the rights struct to convert
     * @return boolean array containing the rights settings
     */
    function convertRights(Rights calldata rights) external pure returns (bool[] memory) {
        bool[] memory result = new bool[](6);

        result[0] = rights.canPauseSwapping;
        result[1] = rights.canChangeSwapFee;
        result[2] = rights.canChangeWeights;
        result[3] = rights.canAddRemoveTokens;
        result[4] = rights.canWhitelistLPs;
        result[5] = rights.canChangeCap;

        return result;
    }

    // Though it is actually simple, the number of branches triggers code-complexity
    /* solhint-disable code-complexity */

    /**
     * @notice Externally check permissions using the Enum
     * @param self - Rights struct containing the permissions
     * @param permission - The permission to check
     * @return Boolean true if it has the permission
     */
    function hasPermission(Rights calldata self, Permissions permission) external pure returns (bool) {
        if (Permissions.PAUSE_SWAPPING == permission) {
            return self.canPauseSwapping;
        }
        else if (Permissions.CHANGE_SWAP_FEE == permission) {
            return self.canChangeSwapFee;
        }
        else if (Permissions.CHANGE_WEIGHTS == permission) {
            return self.canChangeWeights;
        }
        else if (Permissions.ADD_REMOVE_TOKENS == permission) {
            return self.canAddRemoveTokens;
        }
        else if (Permissions.WHITELIST_LPS == permission) {
            return self.canWhitelistLPs;
        }
        else if (Permissions.CHANGE_CAP == permission) {
            return self.canChangeCap;
        }
    }

    /* solhint-enable code-complexity */
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.6.12;

// Needed to pass in structs
pragma experimental ABIEncoderV2;

// Imports

import "../interfaces/IERC20.sol";
import "../interfaces/IConfigurableRightsPool.sol";
import "../interfaces/IBFactory.sol";
import "../utils/BuniSafeMath.sol";
import "../utils/SafeApprove.sol";


/**
 * @author Buni Labs
 * @title Factor out the weight updates
 */
library SmartPoolManager {
    // Type declarations

    struct NewTokenParams {
        address addr;
        bool isCommitted;
        uint commitBlock;
        uint denorm;
        uint balance;
    }

    // For blockwise, automated weight updates
    // Move weights linearly from startWeights to endWeights,
    // between startBlock and endBlock
    struct GradualUpdateParams {
        uint startBlock;
        uint endBlock;
        uint[] startWeights;
        uint[] endWeights;
    }

    // updateWeight and pokeWeights are unavoidably long
    /* solhint-disable function-max-lines */

    /**
     * @notice Update the weight of an existing token
     * @dev Refactored to library to make CRPFactory deployable
     * @param self - ConfigurableRightsPool instance calling the library
     * @param bPool - Core BPool the CRP is wrapping
     * @param token - token to be reweighted
     * @param newWeight - new weight of the token
    */
    function updateWeight(
        IConfigurableRightsPool self,
        IBPool bPool,
        address token,
        uint newWeight
    )
        external
    {
        require(newWeight >= BuniConstants.MIN_WEIGHT, "ERR_MIN_WEIGHT");
        require(newWeight <= BuniConstants.MAX_WEIGHT, "ERR_MAX_WEIGHT");

        uint currentWeight = bPool.getDenormalizedWeight(token);
        // Save gas; return immediately on NOOP
        if (currentWeight == newWeight) {
             return;
        }

        uint currentBalance = bPool.getBalance(token);
        uint totalSupply = self.totalSupply();
        uint totalWeight = bPool.getTotalDenormalizedWeight();
        uint poolShares;
        uint deltaBalance;
        uint deltaWeight;
        uint newBalance;

        if (newWeight < currentWeight) {
            // This means the controller will withdraw tokens to keep price
            // So they need to redeem PCTokens
            deltaWeight = BuniSafeMath.bsub(currentWeight, newWeight);

            // poolShares = totalSupply * (deltaWeight / totalWeight)
            poolShares = BuniSafeMath.bmul(totalSupply,
                                               BuniSafeMath.bdiv(deltaWeight, totalWeight));

            // deltaBalance = currentBalance * (deltaWeight / currentWeight)
            deltaBalance = BuniSafeMath.bmul(currentBalance,
                                                 BuniSafeMath.bdiv(deltaWeight, currentWeight));

            // New balance cannot be lower than MIN_BALANCE
            newBalance = BuniSafeMath.bsub(currentBalance, deltaBalance);

            require(newBalance >= BuniConstants.MIN_BALANCE, "ERR_MIN_BALANCE");

            // First get the tokens from this contract (Pool Controller) to msg.sender
            bPool.rebind(token, newBalance, newWeight);

            // Now with the tokens this contract can send them to msg.sender
            bool xfer = IERC20(token).transfer(msg.sender, deltaBalance);
            require(xfer, "ERR_ERC20_FALSE");

            self.pullPoolShareFromLib(msg.sender, poolShares);
            self.burnPoolShareFromLib(poolShares);
        }
        else {
            // This means the controller will deposit tokens to keep the price.
            // They will be minted and given PCTokens
            deltaWeight = BuniSafeMath.bsub(newWeight, currentWeight);

            require(BuniSafeMath.badd(totalWeight, deltaWeight) <= BuniConstants.MAX_TOTAL_WEIGHT,
                    "ERR_MAX_TOTAL_WEIGHT");

            // poolShares = totalSupply * (deltaWeight / totalWeight)
            poolShares = BuniSafeMath.bmul(totalSupply,
                                               BuniSafeMath.bdiv(deltaWeight, totalWeight));
            // deltaBalance = currentBalance * (deltaWeight / currentWeight)
            deltaBalance = BuniSafeMath.bmul(currentBalance,
                                                 BuniSafeMath.bdiv(deltaWeight, currentWeight));

            // First gets the tokens from msg.sender to this contract (Pool Controller)
            bool xfer = IERC20(token).transferFrom(msg.sender, address(this), deltaBalance);
            require(xfer, "ERR_ERC20_FALSE");

            // Now with the tokens this contract can bind them to the pool it controls
            bPool.rebind(token, BuniSafeMath.badd(currentBalance, deltaBalance), newWeight);

            self.mintPoolShareFromLib(poolShares);
            self.pushPoolShareFromLib(msg.sender, poolShares);
        }
    }

    /**
     * @notice External function called to make the contract update weights according to plan
     * @param bPool - Core BPool the CRP is wrapping
     * @param gradualUpdate - gradual update parameters from the CRP
    */
    function pokeWeights(
        IBPool bPool,
        GradualUpdateParams storage gradualUpdate
    )
        external
    {
        // Do nothing if we call this when there is no update plan
        if (gradualUpdate.startBlock == 0) {
            return;
        }

        // Error to call it before the start of the plan
        require(block.number >= gradualUpdate.startBlock, "ERR_CANT_POKE_YET");
        // Proposed error message improvement
        // require(block.number >= startBlock, "ERR_NO_HOKEY_POKEY");

        // This allows for pokes after endBlock that get weights to endWeights
        // Get the current block (or the endBlock, if we're already past the end)
        uint currentBlock;
        if (block.number > gradualUpdate.endBlock) {
            currentBlock = gradualUpdate.endBlock;
        }
        else {
            currentBlock = block.number;
        }

        uint blockPeriod = BuniSafeMath.bsub(gradualUpdate.endBlock, gradualUpdate.startBlock);
        uint blocksElapsed = BuniSafeMath.bsub(currentBlock, gradualUpdate.startBlock);
        uint weightDelta;
        uint deltaPerBlock;
        uint newWeight;

        address[] memory tokens = bPool.getCurrentTokens();

        // This loop contains external calls
        // External calls are to math libraries or the underlying pool, so low risk
        for (uint i = 0; i < tokens.length; i++) {
            // Make sure it does nothing if the new and old weights are the same (saves gas)
            // It's a degenerate case if they're *all* the same, but you certainly could have
            // a plan where you only change some of the weights in the set
            if (gradualUpdate.startWeights[i] != gradualUpdate.endWeights[i]) {
                if (gradualUpdate.endWeights[i] < gradualUpdate.startWeights[i]) {
                    // We are decreasing the weight

                    // First get the total weight delta
                    weightDelta = BuniSafeMath.bsub(gradualUpdate.startWeights[i],
                                                        gradualUpdate.endWeights[i]);
                    // And the amount it should change per block = total change/number of blocks in the period
                    deltaPerBlock = BuniSafeMath.bdiv(weightDelta, blockPeriod);
                    //deltaPerBlock = bdivx(weightDelta, blockPeriod);

                     // newWeight = startWeight - (blocksElapsed * deltaPerBlock)
                    newWeight = BuniSafeMath.bsub(gradualUpdate.startWeights[i],
                                                      BuniSafeMath.bmul(blocksElapsed, deltaPerBlock));
                }
                else {
                    // We are increasing the weight

                    // First get the total weight delta
                    weightDelta = BuniSafeMath.bsub(gradualUpdate.endWeights[i],
                                                        gradualUpdate.startWeights[i]);
                    // And the amount it should change per block = total change/number of blocks in the period
                    deltaPerBlock = BuniSafeMath.bdiv(weightDelta, blockPeriod);
                    //deltaPerBlock = bdivx(weightDelta, blockPeriod);

                     // newWeight = startWeight + (blocksElapsed * deltaPerBlock)
                    newWeight = BuniSafeMath.badd(gradualUpdate.startWeights[i],
                                                      BuniSafeMath.bmul(blocksElapsed, deltaPerBlock));
                }

                uint bal = bPool.getBalance(tokens[i]);

                bPool.rebind(tokens[i], bal, newWeight);
            }
        }

        // Reset to allow add/remove tokens, or manual weight updates
        if (block.number >= gradualUpdate.endBlock) {
            gradualUpdate.startBlock = 0;
        }
    }

    /* solhint-enable function-max-lines */

    /**
     * @notice Schedule (commit) a token to be added; must call applyAddToken after a fixed
     *         number of blocks to actually add the token
     * @param bPool - Core BPool the CRP is wrapping
     * @param token - the token to be added
     * @param balance - how much to be added
     * @param denormalizedWeight - the desired token weight
     * @param newToken - NewTokenParams struct used to hold the token data (in CRP storage)
     */
    function commitAddToken(
        IBPool bPool,
        address token,
        uint balance,
        uint denormalizedWeight,
        NewTokenParams storage newToken
    )
        external
    {
        require(!bPool.isBound(token), "ERR_IS_BOUND");

        require(denormalizedWeight <= BuniConstants.MAX_WEIGHT, "ERR_WEIGHT_ABOVE_MAX");
        require(denormalizedWeight >= BuniConstants.MIN_WEIGHT, "ERR_WEIGHT_BELOW_MIN");
        require(BuniSafeMath.badd(bPool.getTotalDenormalizedWeight(),
                                      denormalizedWeight) <= BuniConstants.MAX_TOTAL_WEIGHT,
                "ERR_MAX_TOTAL_WEIGHT");
        require(balance >= BuniConstants.MIN_BALANCE, "ERR_BALANCE_BELOW_MIN");

        newToken.addr = token;
        newToken.balance = balance;
        newToken.denorm = denormalizedWeight;
        newToken.commitBlock = block.number;
        newToken.isCommitted = true;
    }

    /**
     * @notice Add the token previously committed (in commitAddToken) to the pool
     * @param self - ConfigurableRightsPool instance calling the library
     * @param bPool - Core BPool the CRP is wrapping
     * @param addTokenTimeLockInBlocks -  Wait time between committing and applying a new token
     * @param newToken - NewTokenParams struct used to hold the token data (in CRP storage)
     */
    function applyAddToken(
        IConfigurableRightsPool self,
        IBPool bPool,
        uint addTokenTimeLockInBlocks,
        NewTokenParams storage newToken
    )
        external
    {
        require(newToken.isCommitted, "ERR_NO_TOKEN_COMMIT");
        require(BuniSafeMath.bsub(block.number, newToken.commitBlock) >= addTokenTimeLockInBlocks,
                                      "ERR_TIMELOCK_STILL_COUNTING");

        uint totalSupply = self.totalSupply();

        // poolShares = totalSupply * newTokenWeight / totalWeight
        uint poolShares = BuniSafeMath.bdiv(BuniSafeMath.bmul(totalSupply, newToken.denorm),
                                                bPool.getTotalDenormalizedWeight());

        // Clear this to allow adding more tokens
        newToken.isCommitted = false;

        // First gets the tokens from msg.sender to this contract (Pool Controller)
        bool returnValue = IERC20(newToken.addr).transferFrom(self.getController(), address(self), newToken.balance);
        require(returnValue, "ERR_ERC20_FALSE");

        // Now with the tokens this contract can bind them to the pool it controls
        // Approves bPool to pull from this controller
        // Approve unlimited, same as when creating the pool, so they can join pools later
        returnValue = SafeApprove.safeApprove(IERC20(newToken.addr), address(bPool), BuniConstants.MAX_UINT);
        require(returnValue, "ERR_ERC20_FALSE");

        bPool.bind(newToken.addr, newToken.balance, newToken.denorm);

        self.mintPoolShareFromLib(poolShares);
        self.pushPoolShareFromLib(msg.sender, poolShares);
    }

     /**
     * @notice Remove a token from the pool
     * @dev Logic in the CRP controls when ths can be called. There are two related permissions:
     *      AddRemoveTokens - which allows removing down to the underlying BPool limit of two
     *      RemoveAllTokens - which allows completely draining the pool by removing all tokens
     *                        This can result in a non-viable pool with 0 or 1 tokens (by design),
     *                        meaning all swapping or binding operations would fail in this state
     * @param self - ConfigurableRightsPool instance calling the library
     * @param bPool - Core BPool the CRP is wrapping
     * @param token - token to remove
     */
    function removeToken(
        IConfigurableRightsPool self,
        IBPool bPool,
        address token
    )
        external
    {
        uint totalSupply = self.totalSupply();

        // poolShares = totalSupply * tokenWeight / totalWeight
        uint poolShares = BuniSafeMath.bdiv(BuniSafeMath.bmul(totalSupply,
                                                                      bPool.getDenormalizedWeight(token)),
                                                bPool.getTotalDenormalizedWeight());

        // this is what will be unbound from the pool
        // Have to get it before unbinding
        uint balance = bPool.getBalance(token);

        // Unbind and get the tokens out of Buni pool
        bPool.unbind(token);

        // Now with the tokens this contract can send them to msg.sender
        bool xfer = IERC20(token).transfer(self.getController(), balance);
        require(xfer, "ERR_ERC20_FALSE");

        self.pullPoolShareFromLib(self.getController(), poolShares);
        self.burnPoolShareFromLib(poolShares);
    }

    /**
     * @notice Non ERC20-conforming tokens are problematic; don't allow them in pools
     * @dev Will revert if invalid
     * @param token - The prospective token to verify
     */
    function verifyTokenCompliance(address token) external {
        verifyTokenComplianceInternal(token);
    }

    /**
     * @notice Non ERC20-conforming tokens are problematic; don't allow them in pools
     * @dev Will revert if invalid - overloaded to save space in the main contract
     * @param tokens - The prospective tokens to verify
     */
    function verifyTokenCompliance(address[] calldata tokens) external {
        for (uint i = 0; i < tokens.length; i++) {
            verifyTokenComplianceInternal(tokens[i]);
         }
    }

    /**
     * @notice Update weights in a predetermined way, between startBlock and endBlock,
     *         through external cals to pokeWeights
     * @param bPool - Core BPool the CRP is wrapping
     * @param newWeights - final weights we want to get to
     * @param startBlock - when weights should start to change
     * @param endBlock - when weights will be at their final values
     * @param minimumWeightChangeBlockPeriod - needed to validate the block period
    */
    function updateWeightsGradually(
        IBPool bPool,
        GradualUpdateParams storage gradualUpdate,
        uint[] calldata newWeights,
        uint startBlock,
        uint endBlock,
        uint minimumWeightChangeBlockPeriod
    )
        external
    {
        require(block.number < endBlock, "ERR_GRADUAL_UPDATE_TIME_TRAVEL");
        
        if (block.number > startBlock) {
            // This means the weight update should start ASAP
            // Moving the start block up prevents a big jump/discontinuity in the weights
            gradualUpdate.startBlock = block.number;
        }
        else{
            gradualUpdate.startBlock = startBlock;
        }

        // Enforce a minimum time over which to make the changes
        // The also prevents endBlock <= startBlock
        require(BuniSafeMath.bsub(endBlock, gradualUpdate.startBlock) >= minimumWeightChangeBlockPeriod,
                "ERR_WEIGHT_CHANGE_TIME_BELOW_MIN");

        address[] memory tokens = bPool.getCurrentTokens();

        // Must specify weights for all tokens
        require(newWeights.length == tokens.length, "ERR_START_WEIGHTS_MISMATCH");

        uint weightsSum = 0;
        gradualUpdate.startWeights = new uint[](tokens.length);

        // Check that endWeights are valid now to avoid reverting in a future pokeWeights call
        //
        // This loop contains external calls
        // External calls are to math libraries or the underlying pool, so low risk
        for (uint i = 0; i < tokens.length; i++) {
            require(newWeights[i] <= BuniConstants.MAX_WEIGHT, "ERR_WEIGHT_ABOVE_MAX");
            require(newWeights[i] >= BuniConstants.MIN_WEIGHT, "ERR_WEIGHT_BELOW_MIN");

            weightsSum = BuniSafeMath.badd(weightsSum, newWeights[i]);
            gradualUpdate.startWeights[i] = bPool.getDenormalizedWeight(tokens[i]);
        }
        require(weightsSum <= BuniConstants.MAX_TOTAL_WEIGHT, "ERR_MAX_TOTAL_WEIGHT");

        gradualUpdate.endBlock = endBlock;
        gradualUpdate.endWeights = newWeights;
    }

    /**
     * @notice Join a pool
     * @param self - ConfigurableRightsPool instance calling the library
     * @param bPool - Core BPool the CRP is wrapping
     * @param poolAmountOut - number of pool tokens to receive
     * @param maxAmountsIn - Max amount of asset tokens to spend
     * @return actualAmountsIn - calculated values of the tokens to pull in
     */
    function joinPool(
        IConfigurableRightsPool self,
        IBPool bPool,
        uint poolAmountOut,
        uint[] calldata maxAmountsIn
    )
         external
         view
         returns (uint[] memory actualAmountsIn)
    {
        address[] memory tokens = bPool.getCurrentTokens();

        require(maxAmountsIn.length == tokens.length, "ERR_AMOUNTS_MISMATCH");

        uint poolTotal = self.totalSupply();
        // Subtract  1 to ensure any rounding errors favor the pool
        uint ratio = BuniSafeMath.bdiv(poolAmountOut,
                                           BuniSafeMath.bsub(poolTotal, 1));

        require(ratio != 0, "ERR_MATH_APPROX");

        // We know the length of the array; initialize it, and fill it below
        // Cannot do "push" in memory
        actualAmountsIn = new uint[](tokens.length);

        // This loop contains external calls
        // External calls are to math libraries or the underlying pool, so low risk
        for (uint i = 0; i < tokens.length; i++) {
            address t = tokens[i];
            uint bal = bPool.getBalance(t);
            // Add 1 to ensure any rounding errors favor the pool
            uint tokenAmountIn = BuniSafeMath.bmul(ratio,
                                                       BuniSafeMath.badd(bal, 1));

            require(tokenAmountIn != 0, "ERR_MATH_APPROX");
            require(tokenAmountIn <= maxAmountsIn[i], "ERR_LIMIT_IN");

            actualAmountsIn[i] = tokenAmountIn;
        }
    }

    /**
     * @notice Exit a pool - redeem pool tokens for underlying assets
     * @param self - ConfigurableRightsPool instance calling the library
     * @param bPool - Core BPool the CRP is wrapping
     * @param poolAmountIn - amount of pool tokens to redeem
     * @param minAmountsOut - minimum amount of asset tokens to receive
     * @return exitFee - calculated exit fee
     * @return pAiAfterExitFee - final amount in (after accounting for exit fee)
     * @return actualAmountsOut - calculated amounts of each token to pull
     */
    function exitPool(
        IConfigurableRightsPool self,
        IBPool bPool,
        uint poolAmountIn,
        uint[] calldata minAmountsOut
    )
        external
        view
        returns (uint exitFee, uint pAiAfterExitFee, uint[] memory actualAmountsOut)
    {
        address[] memory tokens = bPool.getCurrentTokens();

        require(minAmountsOut.length == tokens.length, "ERR_AMOUNTS_MISMATCH");

        uint poolTotal = self.totalSupply();

        // Calculate exit fee and the final amount in
        exitFee = BuniSafeMath.bmul(poolAmountIn, BuniConstants.EXIT_FEE);
        pAiAfterExitFee = BuniSafeMath.bsub(poolAmountIn, exitFee);

        uint ratio = BuniSafeMath.bdiv(pAiAfterExitFee,
                                           BuniSafeMath.badd(poolTotal, 1));

        require(ratio != 0, "ERR_MATH_APPROX");

        actualAmountsOut = new uint[](tokens.length);

        // This loop contains external calls
        // External calls are to math libraries or the underlying pool, so low risk
        for (uint i = 0; i < tokens.length; i++) {
            address t = tokens[i];
            uint bal = bPool.getBalance(t);
            // Subtract 1 to ensure any rounding errors favor the pool
            uint tokenAmountOut = BuniSafeMath.bmul(ratio,
                                                        BuniSafeMath.bsub(bal, 1));

            require(tokenAmountOut != 0, "ERR_MATH_APPROX");
            require(tokenAmountOut >= minAmountsOut[i], "ERR_LIMIT_OUT");

            actualAmountsOut[i] = tokenAmountOut;
        }
    }

    /**
     * @notice Join by swapping a fixed amount of an external token in (must be present in the pool)
     *         System calculates the pool token amount
     * @param self - ConfigurableRightsPool instance calling the library
     * @param bPool - Core BPool the CRP is wrapping
     * @param tokenIn - which token we're transferring in
     * @param tokenAmountIn - amount of deposit
     * @param minPoolAmountOut - minimum of pool tokens to receive
     * @return poolAmountOut - amount of pool tokens minted and transferred
     */
    function joinswapExternAmountIn(
        IConfigurableRightsPool self,
        IBPool bPool,
        address tokenIn,
        uint tokenAmountIn,
        uint minPoolAmountOut
    )
        external
        view
        returns (uint poolAmountOut)
    {
        require(bPool.isBound(tokenIn), "ERR_NOT_BOUND");
        require(tokenAmountIn <= BuniSafeMath.bmul(bPool.getBalance(tokenIn),
                                                       BuniConstants.MAX_IN_RATIO),
                                                       "ERR_MAX_IN_RATIO");

        poolAmountOut = bPool.calcPoolOutGivenSingleIn(
                            bPool.getBalance(tokenIn),
                            bPool.getDenormalizedWeight(tokenIn),
                            self.totalSupply(),
                            bPool.getTotalDenormalizedWeight(),
                            tokenAmountIn,
                            bPool.getSwapFee()
                        );

        require(poolAmountOut >= minPoolAmountOut, "ERR_LIMIT_OUT");
    }

    /**
     * @notice Join by swapping an external token in (must be present in the pool)
     *         To receive an exact amount of pool tokens out. System calculates the deposit amount
     * @param self - ConfigurableRightsPool instance calling the library
     * @param bPool - Core BPool the CRP is wrapping
     * @param tokenIn - which token we're transferring in (system calculates amount required)
     * @param poolAmountOut - amount of pool tokens to be received
     * @param maxAmountIn - Maximum asset tokens that can be pulled to pay for the pool tokens
     * @return tokenAmountIn - amount of asset tokens transferred in to purchase the pool tokens
     */
    function joinswapPoolAmountOut(
        IConfigurableRightsPool self,
        IBPool bPool,
        address tokenIn,
        uint poolAmountOut,
        uint maxAmountIn
    )
        external
        view
        returns (uint tokenAmountIn)
    {
        require(bPool.isBound(tokenIn), "ERR_NOT_BOUND");

        tokenAmountIn = bPool.calcSingleInGivenPoolOut(
                            bPool.getBalance(tokenIn),
                            bPool.getDenormalizedWeight(tokenIn),
                            self.totalSupply(),
                            bPool.getTotalDenormalizedWeight(),
                            poolAmountOut,
                            bPool.getSwapFee()
                        );

        require(tokenAmountIn != 0, "ERR_MATH_APPROX");
        require(tokenAmountIn <= maxAmountIn, "ERR_LIMIT_IN");

        require(tokenAmountIn <= BuniSafeMath.bmul(bPool.getBalance(tokenIn),
                                                       BuniConstants.MAX_IN_RATIO),
                                                       "ERR_MAX_IN_RATIO");
    }

    /**
     * @notice Exit a pool - redeem a specific number of pool tokens for an underlying asset
     *         Asset must be present in the pool, and will incur an EXIT_FEE (if set to non-zero)
     * @param self - ConfigurableRightsPool instance calling the library
     * @param bPool - Core BPool the CRP is wrapping
     * @param tokenOut - which token the caller wants to receive
     * @param poolAmountIn - amount of pool tokens to redeem
     * @param minAmountOut - minimum asset tokens to receive
     * @return exitFee - calculated exit fee
     * @return tokenAmountOut - amount of asset tokens returned
     */
    function exitswapPoolAmountIn(
        IConfigurableRightsPool self,
        IBPool bPool,
        address tokenOut,
        uint poolAmountIn,
        uint minAmountOut
    )
        external
        view
        returns (uint exitFee, uint tokenAmountOut)
    {
        require(bPool.isBound(tokenOut), "ERR_NOT_BOUND");

        tokenAmountOut = bPool.calcSingleOutGivenPoolIn(
                            bPool.getBalance(tokenOut),
                            bPool.getDenormalizedWeight(tokenOut),
                            self.totalSupply(),
                            bPool.getTotalDenormalizedWeight(),
                            poolAmountIn,
                            bPool.getSwapFee()
                        );

        require(tokenAmountOut >= minAmountOut, "ERR_LIMIT_OUT");
        require(tokenAmountOut <= BuniSafeMath.bmul(bPool.getBalance(tokenOut),
                                                        BuniConstants.MAX_OUT_RATIO),
                                                        "ERR_MAX_OUT_RATIO");

        exitFee = BuniSafeMath.bmul(poolAmountIn, BuniConstants.EXIT_FEE);
    }

    /**
     * @notice Exit a pool - redeem pool tokens for a specific amount of underlying assets
     *         Asset must be present in the pool
     * @param self - ConfigurableRightsPool instance calling the library
     * @param bPool - Core BPool the CRP is wrapping
     * @param tokenOut - which token the caller wants to receive
     * @param tokenAmountOut - amount of underlying asset tokens to receive
     * @param maxPoolAmountIn - maximum pool tokens to be redeemed
     * @return exitFee - calculated exit fee
     * @return poolAmountIn - amount of pool tokens redeemed
     */
    function exitswapExternAmountOut(
        IConfigurableRightsPool self,
        IBPool bPool,
        address tokenOut,
        uint tokenAmountOut,
        uint maxPoolAmountIn
    )
        external
        view
        returns (uint exitFee, uint poolAmountIn)
    {
        require(bPool.isBound(tokenOut), "ERR_NOT_BOUND");
        require(tokenAmountOut <= BuniSafeMath.bmul(bPool.getBalance(tokenOut),
                                                        BuniConstants.MAX_OUT_RATIO),
                                                        "ERR_MAX_OUT_RATIO");
        poolAmountIn = bPool.calcPoolInGivenSingleOut(
                            bPool.getBalance(tokenOut),
                            bPool.getDenormalizedWeight(tokenOut),
                            self.totalSupply(),
                            bPool.getTotalDenormalizedWeight(),
                            tokenAmountOut,
                            bPool.getSwapFee()
                        );

        require(poolAmountIn != 0, "ERR_MATH_APPROX");
        require(poolAmountIn <= maxPoolAmountIn, "ERR_LIMIT_IN");

        exitFee = BuniSafeMath.bmul(poolAmountIn, BuniConstants.EXIT_FEE);
    }

    // Internal functions

    // Check for zero transfer, and make sure it returns true to returnValue
    function verifyTokenComplianceInternal(address token) internal {
        bool returnValue = IERC20(token).transfer(msg.sender, 0);
        require(returnValue, "ERR_NONCONFORMING_TOKEN");
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.6.12;

// Imports

import "../interfaces/IERC20.sol";

// Libraries

/**
 * @author PieDAO (ported to Buni Labs)
 * @title SafeApprove - set approval for tokens that require 0 prior approval
 * @dev Perhaps to address the known ERC20 race condition issue
 *      See https://github.com/crytic/not-so-smart-contracts/tree/master/race_condition
 *      Some tokens - notably KNC - only allow approvals to be increased from 0
 */
library SafeApprove {
    /**
     * @notice handle approvals of tokens that require approving from a base of 0
     * @param token - the token we're approving
     * @param spender - entity the owner (sender) is approving to spend his tokens
     * @param amount - number of tokens being approved
     */
    function safeApprove(IERC20 token, address spender, uint amount) internal returns (bool) {
        uint currentAllowance = token.allowance(address(this), spender);

        // Do nothing if allowance is already set to this value
        if(currentAllowance == amount) {
            return true;
        }

        // If approval is not zero reset it to zero first
        if(currentAllowance != 0) {
            return token.approve(spender, 0);
        }

        // do the actual approval
        return token.approve(spender, amount);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.6.12;

// Interface declarations

// Introduce to avoid circularity (otherwise, the CRP and SmartPoolManager include each other)
// Removing circularity allows flattener tools to work, which enables Etherscan verification
interface IConfigurableRightsPool {
    function mintPoolShareFromLib(uint amount) external;
    function pushPoolShareFromLib(address to, uint amount) external;
    function pullPoolShareFromLib(address from, uint amount) external;
    function burnPoolShareFromLib(uint amount) external;
    function totalSupply() external view returns (uint);
    function getController() external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.6.12;

// Needed to handle structures externally
pragma experimental ABIEncoderV2;

// Imports

import "./ElasticSupplyPool.sol";

// Contracts

/**
 * @author Buni Labs
 * @title Configurable Rights Pool Factory - create parameterized smart pools
 * @dev Rights are held in a corresponding struct in ConfigurableRightsPool
 *      Index values are as follows:
 *      0: canPauseSwapping - can setPublicSwap back to false after turning it on
 *                            by default, it is off on initialization and can only be turned on
 *      1: canChangeSwapFee - can setSwapFee after initialization (by default, it is fixed at create time)
 *      2: canChangeWeights - can bind new token weights (allowed by default in base pool)
 *      3: canAddRemoveTokens - can bind/unbind tokens (allowed by default in base pool)
 *      4: canWhitelistLPs - if set, only whitelisted addresses can join pools
 *                           (enables private pools with more than one LP)
 */
contract ESPFactory {
    // State variables

    // Keep a list of all Elastic Supply Pools
    mapping(address => bool) private _isEsp;

    // Event declarations

    // Log the address of each new smart pool, and its creator
    event LogNewEsp(
        address indexed caller,
        address indexed pool
    );

    // Function declarations

    /**
     * @notice Create a new ESP
     * @dev emits a LogNewESP event
     * @param factoryAddress - the BFactory instance used to create the underlying pool
     * @param poolParams - CRP pool parameters
     * @param rights - struct of permissions, configuring this CRP instance (see above for definitions)
     */
    function newEsp(
        address factoryAddress,
        ConfigurableRightsPool.PoolParams calldata poolParams,
        RightsManager.Rights calldata rights
    )
        external
        returns (ElasticSupplyPool)
    {
        require(poolParams.constituentTokens.length >= BuniConstants.MIN_ASSET_LIMIT, "ERR_TOO_FEW_TOKENS");

        // Arrays must be parallel
        require(poolParams.tokenBalances.length == poolParams.constituentTokens.length, "ERR_START_BALANCES_MISMATCH");
        require(poolParams.tokenWeights.length == poolParams.constituentTokens.length, "ERR_START_WEIGHTS_MISMATCH");

        ElasticSupplyPool esp = new ElasticSupplyPool(
            factoryAddress,
            poolParams,
            rights
        );

        emit LogNewEsp(msg.sender, address(esp));

        _isEsp[address(esp)] = true;
        esp.setController(msg.sender);

        return esp;
    }

    /**
     * @notice Check to see if a given address is an ESP
     * @param addr - address to check
     * @return boolean indicating whether it is an ESP
     */
    function isEsp(address addr) external view returns (bool) {
        return _isEsp[addr];
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.6.12;

// Needed to handle structures externally
pragma experimental ABIEncoderV2;

// Imports

import "./ConfigurableRightsPool.sol";

// Contracts

/**
 * @author Buni Labs
 * @title Configurable Rights Pool Factory - create parameterized smart pools
 * @dev Rights are held in a corresponding struct in ConfigurableRightsPool
 *      Index values are as follows:
 *      0: canPauseSwapping - can setPublicSwap back to false after turning it on
 *                            by default, it is off on initialization and can only be turned on
 *      1: canChangeSwapFee - can setSwapFee after initialization (by default, it is fixed at create time)
 *      2: canChangeWeights - can bind new token weights (allowed by default in base pool)
 *      3: canAddRemoveTokens - can bind/unbind tokens (allowed by default in base pool)
 *      4: canWhitelistLPs - if set, only whitelisted addresses can join pools
 *                           (enables private pools with more than one LP)
 *      5: canChangeCap - can change the BSP cap (max # of pool tokens)
 */
contract CRPFactory {
    // State variables

    // Keep a list of all Configurable Rights Pools
    mapping(address=>bool) private _isCrp;

    // Event declarations

    // Log the address of each new smart pool, and its creator
    event LogNewCrp(
        address indexed caller,
        address indexed pool
    );

    // Function declarations

    /**
     * @notice Create a new CRP
     * @dev emits a LogNewCRP event
     * @param factoryAddress - the BFactory instance used to create the underlying pool
     * @param poolParams - struct containing the names, tokens, weights, balances, and swap fee
     * @param rights - struct of permissions, configuring this CRP instance (see above for definitions)
     */
    function newCrp(
        address factoryAddress,
        ConfigurableRightsPool.PoolParams calldata poolParams,
        RightsManager.Rights calldata rights
    )
        external
        returns (ConfigurableRightsPool)
    {
        require(poolParams.constituentTokens.length >= BuniConstants.MIN_ASSET_LIMIT, "ERR_TOO_FEW_TOKENS");

        // Arrays must be parallel
        require(poolParams.tokenBalances.length == poolParams.constituentTokens.length, "ERR_START_BALANCES_MISMATCH");
        require(poolParams.tokenWeights.length == poolParams.constituentTokens.length, "ERR_START_WEIGHTS_MISMATCH");

        ConfigurableRightsPool crp = new ConfigurableRightsPool(
            factoryAddress,
            poolParams,
            rights
        );

        emit LogNewCrp(msg.sender, address(crp));

        _isCrp[address(crp)] = true;
        // The caller is the controller of the CRP
        // The CRP will be the controller of the underlying Core BPool
        crp.setController(msg.sender);

        return crp;
    }

    /**
     * @notice Check to see if a given address is a CRP
     * @param addr - address to check
     * @return boolean indicating whether it is a CRP
     */
    function isCrp(address addr) external view returns (bool) {
        return _isCrp[addr];
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

pragma solidity 0.6.12;

// Builds new KPools, logging their addresses and providing `isBPool(address) -> (bool)`

import "./BPool.sol";

contract BFactory {
    event LOG_NEW_POOL(
        address indexed caller,
        address indexed pool
    );

    event LOG_BLABS(
        address indexed caller,
        address indexed klabs
    );

    mapping(address=>bool) private _isBPool;

    function isBPool(address b)
        external view returns (bool)
    {
        return _isBPool[b];
    }

    function newBPool()
        external
        returns (BPool)
    {
        BPool kpool = new BPool();
        _isBPool[address(kpool)] = true;
        emit LOG_NEW_POOL(msg.sender, address(kpool));
        kpool.setController(msg.sender);
        return kpool;
    }

    address private _blabs;

    constructor() public {
        _blabs = msg.sender;
    }

    function getBLabs()
        external view
        returns (address)
    {
        return _blabs;
    }

    function setBLabs(address b)
        external
    {
        require(msg.sender == _blabs, "ERR_NOT_blabs");
        emit LOG_BLABS(msg.sender, b);
        _blabs = b;
    }

    function collect(BPool pool)
        external 
    {
        require(msg.sender == _blabs, "ERR_NOT_blabs");
        uint collected = IERC20(pool).balanceOf(address(this));
        bool xfer = pool.transfer(_blabs, collected);
        require(xfer, "ERR_ERC20_FAILED");
    }
}

import "../../core/BNum.sol";

pragma solidity 0.6.12;

contract TKPoolJoinPool is BNum {

    bool public echidna_no_bug_found = true;

    // joinPool models the BPool.joinPool behavior for one token
    // A bug is found if poolAmountOut is greater than 0
    // And tokenAmountIn is 0
    function joinPool(uint poolAmountOut, uint poolTotal, uint _records_t_balance)
        public returns(uint)
    {
        // We constraint poolTotal and _records_t_balance
        // To have "realistic" values
        require(poolTotal <= 100 ether);
        require(poolTotal >= 1 ether);
        require(_records_t_balance <= 10 ether);
        require(_records_t_balance >= 10**6);

        uint ratio = bdiv(poolAmountOut, poolTotal);
        require(ratio != 0, "ERR_MATH_APPROX");

        uint bal = _records_t_balance;
        uint tokenAmountIn = bmul(ratio, bal);

        require(poolAmountOut > 0);
        require(tokenAmountIn == 0);

        echidna_no_bug_found = false;
    }

}

import "../../core/BNum.sol";

pragma solidity 0.6.12;

//  This test is similar to TKPoolJoinExit but with no exit fee
contract TKPoolJoinExitNoFee is BNum {

    bool public echidna_no_bug_found = true;

    // joinPool models the BPool.joinPool behavior for one token
    function joinPool(uint poolAmountOut, uint poolTotal, uint _records_t_balance)
        internal pure returns(uint)
    {
        uint ratio = bdiv(poolAmountOut, poolTotal);
        require(ratio != 0, "ERR_MATH_APPROX");

        uint bal = _records_t_balance;
        uint tokenAmountIn = bmul(ratio, bal);

        return tokenAmountIn;
    }

    // exitPool models the BPool.exitPool behavior for one token where no fee is applied
    function exitPoolNoFee(uint poolAmountIn, uint poolTotal, uint _records_t_balance)
        internal pure returns(uint)
    {
        uint ratio = bdiv(poolAmountIn, poolTotal);
        require(ratio != 0, "ERR_MATH_APPROX");

        uint bal = _records_t_balance;
        uint tokenAmountOut = bmul(ratio, bal);

        return tokenAmountOut;
    }

    // This function model an attacker calling joinPool - exitPool and taking advantage of potential rounding
    // issues to generate free pool token
    function joinAndExitNoFeePool(uint poolAmountOut, uint poolAmountIn, uint poolTotal, uint _records_t_balance)
        public 
    {
        uint tokenAmountIn = joinPool(poolAmountOut, poolTotal, _records_t_balance);

        // We constraint poolTotal and _records_t_balance
        // To have "realistic" values
        require(poolTotal <= 100 ether);
        require(poolTotal >= 1 ether);
        require(_records_t_balance <= 10 ether);
        require(_records_t_balance >= 10**6);

        poolTotal = badd(poolTotal, poolAmountOut);
        _records_t_balance = badd(_records_t_balance, tokenAmountIn);

        require(tokenAmountIn > 0); // prevent triggering the free token generation from joinPool 

        require(poolTotal >= poolAmountIn);
        uint tokenAmountOut = exitPoolNoFee(poolAmountIn, poolTotal, _records_t_balance);
        require(_records_t_balance >= tokenAmountOut);

        // We try to generate free pool share 
        require(poolAmountOut > poolAmountIn); 
        require(tokenAmountOut == tokenAmountIn); 
        echidna_no_bug_found = false;
    }


}

import "../../core/BNum.sol";

pragma solidity 0.6.12;

//  This test is similar to TKPoolJoin but with an exit fee
contract TKPoolJoinExit is BNum {

    bool public echidna_no_bug_found = true;

    // joinPool models the BPool.joinPool behavior for one token
    function joinPool(uint poolAmountOut, uint poolTotal, uint _records_t_balance)
        internal pure returns(uint)
    {
        uint ratio = bdiv(poolAmountOut, poolTotal);
        require(ratio != 0, "ERR_MATH_APPROX");

        uint bal = _records_t_balance;
        uint tokenAmountIn = bmul(ratio, bal);

        return tokenAmountIn;
    }

    // exitPool models the BPool.exitPool behavior for one token
    function exitPool(uint poolAmountIn, uint poolTotal, uint _records_t_balance)
        internal pure returns(uint)
    {
        uint exitFee = bmul(poolAmountIn, EXIT_FEE);
        uint pAiAfterExitFee = bsub(poolAmountIn, exitFee);
        uint ratio = bdiv(pAiAfterExitFee, poolTotal);
        require(ratio != 0, "ERR_MATH_APPROX");

        uint bal = _records_t_balance;
        uint tokenAmountOut = bmul(ratio, bal);

        return tokenAmountOut;
    }


    // This function model an attacker calling joinPool - exitPool and taking advantage of potential rounding
    // issues to generate free pool token
    function joinAndExitPool(uint poolAmountOut, uint poolAmountIn, uint poolTotal, uint _records_t_balance) public {
        uint tokenAmountIn = joinPool(poolAmountOut, poolTotal, _records_t_balance);

        // We constraint poolTotal and _records_t_balance
        // To have "realistic" values
        require(poolTotal <= 100 ether);
        require(poolTotal >= 1 ether);
        require(_records_t_balance <= 10 ether);
        require(_records_t_balance >= 10**6);

        poolTotal = badd(poolTotal, poolAmountOut);
        _records_t_balance = badd(_records_t_balance, tokenAmountIn);

        require(tokenAmountIn > 0); // prevent triggering the free token generation from joinPool 

        require(poolTotal >= poolAmountIn);
        uint tokenAmountOut = exitPool(poolAmountIn, poolTotal, _records_t_balance);
        require(_records_t_balance >= tokenAmountOut);

        // We try to generate free pool share 
        require(poolAmountOut > poolAmountIn); 
        require(tokenAmountOut == tokenAmountIn); 
        echidna_no_bug_found = false;
    }

}

{
  "optimizer": {
    "enabled": true,
    "runs": 1000
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "metadata": {
    "useLiteralContent": true
  },
  "libraries": {
    "contracts/utils/BuniSafeMath.sol": {
      "BuniSafeMath": "0x940f9cc489a1a7dd47a135cdacf9e8507a584c27"
    },
    "contracts/utils/RightsManager.sol": {
      "RightsManager": "0x8534c255bf2c06176e89235fe65e9a3132753d5c"
    },
    "contracts/utils/SmartPoolManager.sol": {
      "SmartPoolManager": "0x4cd95bbf3fcd61278e2e1b96de952166229dfe5e"
    }
  }
}