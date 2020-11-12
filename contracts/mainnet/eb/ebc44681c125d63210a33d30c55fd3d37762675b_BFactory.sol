// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

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
library BConst {
    uint public constant BONE                     = 10**18;

    uint public constant MIN_BOUND_TOKENS         = 2;
    uint public constant MAX_BOUND_TOKENS         = 8;

    uint public constant DEFAULT_FEE              = BONE * 3 / 1000; // 0.3%
    uint public constant MIN_FEE                  = BONE / 10**6;
    uint public constant MAX_FEE                  = BONE / 10;

    uint public constant DEFAULT_COLLECTED_FEE    = BONE / 2000; // 0.05%
    uint public constant MAX_COLLECTED_FEE        = BONE / 200; // 0.5%

    uint public constant DEFAULT_EXIT_FEE         = 0;
    uint public constant MAX_EXIT_FEE             = BONE / 1000; // 0.1%

    uint public constant MIN_WEIGHT               = BONE;
    uint public constant MAX_WEIGHT               = BONE * 50;
    uint public constant MAX_TOTAL_WEIGHT         = BONE * 50;
    uint public constant MIN_BALANCE              = BONE / 10**12;

    uint public constant DEFAULT_INIT_POOL_SUPPLY = BONE * 100;
    uint public constant MIN_INIT_POOL_SUPPLY     = BONE / 1000;
    uint public constant MAX_INIT_POOL_SUPPLY     = BONE * 10**18;

    uint public constant MIN_BPOW_BASE            = 1 wei;
    uint public constant MAX_BPOW_BASE            = (2 * BONE) - 1 wei;
    uint public constant BPOW_PRECISION           = BONE / 10**10;

    uint public constant MAX_IN_RATIO             = BONE / 2;
    uint public constant MAX_OUT_RATIO            = (BONE / 3) + 1 wei;
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
contract BNum {

    function btoi(uint a)
        internal pure 
        returns (uint)
    {
        return a / BConst.BONE;
    }

    function bfloor(uint a)
        internal pure
        returns (uint)
    {
        return btoi(a) * BConst.BONE;
    }

    function badd(uint a, uint b)
        internal pure
        returns (uint)
    {
        uint c = a + b;
        require(c >= a, "add overflow");
        return c;
    }

    function bsub(uint a, uint b)
        internal pure
        returns (uint)
    {
        (uint c, bool flag) = bsubSign(a, b);
        require(!flag, "sub underflow");
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
        require(a == 0 || c0 / a == b, "mul overflow");
        uint c1 = c0 + (BConst.BONE / 2);
        require(c1 >= c0, "mul overflow");
        uint c2 = c1 / BConst.BONE;
        return c2;
    }

    function bdiv(uint a, uint b)
        internal pure
        returns (uint)
    {
        require(b != 0, "div by 0");
        uint c0 = a * BConst.BONE;
        require(a == 0 || c0 / a == BConst.BONE, "div internal"); // bmul overflow
        uint c1 = c0 + (b / 2);
        require(c1 >= c0, "div internal"); //  badd require
        uint c2 = c1 / b;
        return c2;
    }

    // DSMath.wpow
    function bpowi(uint a, uint n)
        internal pure
        returns (uint)
    {
        uint z = n % 2 != 0 ? a : BConst.BONE;

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
        require(base >= BConst.MIN_BPOW_BASE, "base too low");
        require(base <= BConst.MAX_BPOW_BASE, "base too high");

        uint whole  = bfloor(exp);   
        uint remain = bsub(exp, whole);

        uint wholePow = bpowi(base, btoi(whole));

        if (remain == 0) {
            return wholePow;
        }

        uint partialResult = bpowApprox(base, remain, BConst.BPOW_PRECISION);
        return bmul(wholePow, partialResult);
    }

    function bpowApprox(uint base, uint exp, uint precision)
        internal pure
        returns (uint)
    {
        // term 0:
        uint a     = exp;
        (uint x, bool xneg)  = bsubSign(base, BConst.BONE);
        uint term = BConst.BONE;
        uint sum   = term;
        bool negative = false;


        // term(k) = numer / denom 
        //         = (product(a - i - 1, i=1-->k) * x^k) / (k!)
        // each iteration, multiply previous term by (a-(k-1)) * x / k
        // continue until term is less than precision
        for (uint i = 1; term >= precision; i++) {
            uint bigK = i * BConst.BONE;
            (uint c, bool cneg) = bsubSign(a, bsub(bigK, BConst.BONE));
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
// Highly opinionated token implementation
interface IERC20 {
    event Approval(address indexed src, address indexed dst, uint amt);
    event Transfer(address indexed src, address indexed dst, uint amt);

    function totalSupply() external view returns (uint);
    function balanceOf(address whom) external view returns (uint);
    function allowance(address src, address dst) external view returns (uint);

    function approve(address dst, uint amt) external returns (bool);
    function transfer(address dst, uint amt) external returns (bool);
    function transferFrom(
        address src, address dst, uint amt
    ) external returns (bool);
}

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
        require(_balance[address(this)] >= amt, "!bal");
        _balance[address(this)] = bsub(_balance[address(this)], amt);
        _totalSupply = bsub(_totalSupply, amt);
        emit Transfer(address(this), address(0), amt);
    }

    function _move(address src, address dst, uint amt) internal {
        require(_balance[src] >= amt, "!bal");
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

contract BToken is BTokenBase, IERC20 {
    string  private _name     = "Value Liquidity Provider";
    string  private _symbol   = "VLP";
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
        require(msg.sender == src || amt <= _allowance[src][msg.sender], "!spender");
        _move(src, dst, amt);
        if (msg.sender != src && _allowance[src][msg.sender] != uint256(-1)) {
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
contract BMath is BNum {
    /**********************************************************************************************
    // calcSpotPrice                                                                             //
    // sP = spotPrice                                                                            //
    // bI = tokenBalanceIn                ( bI / wI )         1                                  //
    // bO = tokenBalanceOut         sP =  -----------  *  ----------                             //
    // wI = tokenWeightIn                 ( bO / wO )     ( 1 - sF )                             //
    // wO = tokenWeightOut                                                                       //
    // sF = swapFee (+ collectedFee)                                                             //
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
        uint scale = bdiv(BConst.BONE, bsub(BConst.BONE, swapFee));
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
    // sF = swapFee (+ collectedFee)                                                             //
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
        uint adjustedIn = bsub(BConst.BONE, swapFee);
        adjustedIn = bmul(tokenAmountIn, adjustedIn);
        uint y = bdiv(tokenBalanceIn, badd(tokenBalanceIn, adjustedIn));
        uint foo = bpow(y, weightRatio);
        uint bar = bsub(BConst.BONE, foo);
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
    // sF = swapFee (+ collectedFee)                                                             //
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
        foo = bsub(foo, BConst.BONE);
        tokenAmountIn = bsub(BConst.BONE, swapFee);
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
    // sF = swapFee (+ collectedFee)\                                              /              //
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
        // @dev Charge the trading fee for the proportion of tokenAi
        // which is implicitly traded to the other pool tokens.
        // That proportion is (1- weightTokenIn)
        // tokenAiAfterFee = tAi * (1 - (1-weightTi) * poolFee);
        uint normalizedWeight = bdiv(tokenWeightIn, totalWeight);
        uint zaz = bmul(bsub(BConst.BONE, normalizedWeight), swapFee);
        uint tokenAmountInAfterFee = bmul(tokenAmountIn, bsub(BConst.BONE, zaz));

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
    // sF = swapFee (+ collectedFee)              \      tW  /                                   //
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
        uint boo = bdiv(BConst.BONE, normalizedWeight);
        uint tokenInRatio = bpow(poolRatio, boo);
        uint newTokenBalanceIn = bmul(tokenInRatio, tokenBalanceIn);
        uint tokenAmountInAfterFee = bsub(newTokenBalanceIn, tokenBalanceIn);
        // Do reverse order of fees charged in joinswap_ExternAmountIn, this way 
        //     ``` pAo == joinswap_ExternAmountIn(Ti, joinswap_PoolAmountOut(pAo, Ti)) ```
        //uint tAi = tAiAfterFee / (1 - (1-weightTi) * swapFee) ;
        uint zar = bmul(bsub(BConst.BONE, normalizedWeight), swapFee);
        tokenAmountIn = bdiv(tokenAmountInAfterFee, bsub(BConst.BONE, zar));
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
    // sF = swapFee (+ collectedFee)   *  | 1 - |  1 - ---- | * sF  |                            //
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
    )
        public pure
        returns (uint tokenAmountOut)
    {
        uint normalizedWeight = bdiv(tokenWeightOut, totalWeight);
        // charge exit fee on the pool token side
        // pAiAfterExitFee = pAi*(1-exitFee)
        uint poolAmountInAfterExitFee = bmul(poolAmountIn, bsub(BConst.BONE, exitFee));
        uint newPoolSupply = bsub(poolSupply, poolAmountInAfterExitFee);
        uint poolRatio = bdiv(newPoolSupply, poolSupply);
     
        // newBalTo = poolRatio^(1/weightTo) * balTo;
        uint tokenOutRatio = bpow(poolRatio, bdiv(BConst.BONE, normalizedWeight));
        uint newTokenBalanceOut = bmul(tokenOutRatio, tokenBalanceOut);

        uint tokenAmountOutBeforeSwapFee = bsub(tokenBalanceOut, newTokenBalanceOut);

        // charge swap fee on the output token side 
        //uint tAo = tAoBeforeSwapFee * (1 - (1-weightTo) * swapFee)
        uint zaz = bmul(bsub(BConst.BONE, normalizedWeight), swapFee);
        tokenAmountOut = bmul(tokenAmountOutBeforeSwapFee, bsub(BConst.BONE, zaz));
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
    // sF = swapFee (+ collectedFee)                       ( 1 - eF )                            //
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
    )
        public pure
        returns (uint poolAmountIn)
    {

        // charge swap fee on the output token side 
        uint normalizedWeight = bdiv(tokenWeightOut, totalWeight);
        //uint tAoBeforeSwapFee = tAo / (1 - (1-weightTo) * swapFee) ;
        uint zoo = bsub(BConst.BONE, normalizedWeight);
        uint zar = bmul(zoo, swapFee);
        uint tokenAmountOutBeforeSwapFee = bdiv(tokenAmountOut, bsub(BConst.BONE, zar));

        uint newTokenBalanceOut = bsub(tokenBalanceOut, tokenAmountOutBeforeSwapFee);
        uint tokenOutRatio = bdiv(newTokenBalanceOut, tokenBalanceOut);

        //uint newPoolSupply = (ratioTo ^ weightTo) * poolSupply;
        uint poolRatio = bpow(tokenOutRatio, normalizedWeight);
        uint newPoolSupply = bmul(poolRatio, poolSupply);
        uint poolAmountInAfterExitFee = bsub(poolSupply, newPoolSupply);

        // charge exit fee on the pool token side
        // pAi = pAiAfterExitFee/(1-exitFee)
        poolAmountIn = bdiv(poolAmountInAfterExitFee, bsub(BConst.BONE, exitFee));
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
interface IBFactory {
    function collectedToken() external view returns(address);
}

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
    event LOG_COLLECTED_FUND(
        address indexed collectedToken,
        uint256         collectedAmount
    );

    modifier _lock_() {
        require(!_mutex, "reentry");
        _mutex = true;
        _;
        _mutex = false;
    }

    modifier _viewlock_() {
        require(!_mutex, "reentry");
        _;
    }

    bool private _mutex;

    uint public version = 1001;
    address public factory;    // BFactory address to push token exitFee to
    address public controller; // has CONTROL role
    bool public publicSwap;

    // `setSwapFee` and `finalize` require CONTROL
    // `finalize` sets `PUBLIC can SWAP`, `PUBLIC can JOIN`
    uint public initPoolSupply;
    uint public swapFee;
    uint public collectedFee; // 0.05% | https://yfv.finance/vip-vote/vip_5
    uint public exitFee;
    bool public finalized;

    address[] private _tokens;
    mapping(address => Record) private _records;
    uint private _totalWeight;

    constructor(address _factory) public {
        controller = _factory;
        factory = _factory;
        initPoolSupply = BConst.DEFAULT_INIT_POOL_SUPPLY;
        swapFee = BConst.DEFAULT_FEE;
        collectedFee = BConst.DEFAULT_COLLECTED_FEE;
        exitFee = BConst.DEFAULT_EXIT_FEE;
        publicSwap = false;
        finalized = false;
    }

    function setInitPoolSupply(uint _initPoolSupply) public _logs_ {
        require(!finalized, "finalized");
        require(msg.sender == controller, "!controller");
        require(_initPoolSupply >= BConst.MIN_INIT_POOL_SUPPLY, "<minInitPoolSup");
        require(_initPoolSupply <= BConst.MAX_INIT_POOL_SUPPLY, ">maxInitPoolSup");
        initPoolSupply = _initPoolSupply;
    }

    function setCollectedFee(uint _collectedFee) public _logs_ {
        require(msg.sender == factory, "!factory");
        require(_collectedFee <= BConst.MAX_COLLECTED_FEE, ">maxCoFee");
        require(bmul(_collectedFee, 2) <= swapFee, ">swapFee/2");
        collectedFee = _collectedFee;
    }

    function setExitFee(uint _exitFee) public _logs_ {
        require(!finalized, "finalized");
        require(msg.sender == factory, "!factory");
        require(_exitFee <= BConst.MAX_EXIT_FEE, ">maxExitFee");
        exitFee = _exitFee;
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
        require(finalized, "!finalized");
        return _tokens;
    }

    function getDenormalizedWeight(address token)
        external view
        _viewlock_
        returns (uint)
    {

        require(_records[token].bound, "!bound");
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

        require(_records[token].bound, "!bound");
        uint denorm = _records[token].denorm;
        return bdiv(denorm, _totalWeight);
    }

    function getBalance(address token)
        external view
        _viewlock_
        returns (uint)
    {

        require(_records[token].bound, "!bound");
        return _records[token].balance;
    }

    function setSwapFee(uint _swapFee)
        external
        _lock_
        _logs_
    {
        require(!finalized, "finalized");
        require(msg.sender == controller, "!controller");
        require(_swapFee >= BConst.MIN_FEE, "<minFee");
        require(_swapFee <= BConst.MAX_FEE, ">maxFee");
        require(bmul(collectedFee, 2) <= _swapFee, "<collectedFee*2");
        swapFee = _swapFee;
    }

    function setController(address _controller)
        external
        _lock_
        _logs_
    {
        require(msg.sender == controller, "!controller");
        controller = _controller;
    }

    function setPublicSwap(bool _publicSwap)
        external
        _lock_
        _logs_
    {
        require(!finalized, "finalized");
        require(msg.sender == controller, "!controller");
        publicSwap = _publicSwap;
    }

    function finalize()
        external
        _lock_
        _logs_
    {
        require(msg.sender == controller, "!controller");
        require(!finalized, "finalized");
        require(_tokens.length >= BConst.MIN_BOUND_TOKENS, "<minTokens");

        finalized = true;
        publicSwap = true;

        _mintPoolShare(initPoolSupply);
        _pushPoolShare(msg.sender, initPoolSupply);
    }


    function bind(address token, uint balance, uint denorm)
        external
        _logs_
        // _lock_  Bind does not lock because it jumps to `rebind`, which does
    {
        require(msg.sender == controller, "!controller");
        require(!_records[token].bound, "bound");
        require(!finalized, "finalized");

        require(_tokens.length < BConst.MAX_BOUND_TOKENS, ">maxTokens");

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
        _lock_
        _logs_
    {

        require(msg.sender == controller, "!controller");
        require(_records[token].bound, "!bound");
        require(!finalized, "finalized");

        require(denorm >= BConst.MIN_WEIGHT, "<minWeight");
        require(denorm <= BConst.MAX_WEIGHT, ">maxWeight");
        require(balance >= BConst.MIN_BALANCE, "<minBal");

        // Adjust the denorm and totalWeight
        uint oldWeight = _records[token].denorm;
        if (denorm > oldWeight) {
            _totalWeight = badd(_totalWeight, bsub(denorm, oldWeight));
            require(_totalWeight <= BConst.MAX_TOTAL_WEIGHT, ">maxTWeight");
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
            uint tokenExitFee = bmul(tokenBalanceWithdrawn, exitFee);
            _pushUnderlying(token, msg.sender, bsub(tokenBalanceWithdrawn, tokenExitFee));
            _pushUnderlying(token, factory, tokenExitFee);
        }
    }

    function unbind(address token)
        external
        _lock_
        _logs_
    {

        require(msg.sender == controller, "!controller");
        require(_records[token].bound, "!bound");
        require(!finalized, "finalized");

        uint tokenBalance = _records[token].balance;
        uint tokenExitFee = bmul(tokenBalance, exitFee);

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
        _pushUnderlying(token, factory, tokenExitFee);
    }

    // Absorb any tokens that have been sent to this contract into the pool
    function gulp(address token)
        external
        _logs_
        _lock_
    {
        require(_records[token].bound, "!bound");
        _records[token].balance = IERC20(token).balanceOf(address(this));
    }

    function getSpotPrice(address tokenIn, address tokenOut)
        external view
        _viewlock_
        returns (uint spotPrice)
    {
        require(_records[tokenIn].bound, "!bound");
        require(_records[tokenOut].bound, "!bound");
        Record storage inRecord = _records[tokenIn];
        Record storage outRecord = _records[tokenOut];
        return calcSpotPrice(inRecord.balance, inRecord.denorm, outRecord.balance, outRecord.denorm, swapFee);
    }

    function getSpotPriceSansFee(address tokenIn, address tokenOut)
        external view
        _viewlock_
        returns (uint spotPrice)
    {
        require(_records[tokenIn].bound, "!bound");
        require(_records[tokenOut].bound, "!bound");
        Record storage inRecord = _records[tokenIn];
        Record storage outRecord = _records[tokenOut];
        return calcSpotPrice(inRecord.balance, inRecord.denorm, outRecord.balance, outRecord.denorm, 0);
    }

    function joinPool(uint poolAmountOut, uint[] calldata maxAmountsIn)
        external
        _lock_
        _logs_
    {
        require(finalized, "!finalized");

        uint poolTotal = totalSupply();
        uint ratio = bdiv(poolAmountOut, poolTotal);
        require(ratio != 0, "errMathAprox");

        for (uint i = 0; i < _tokens.length; i++) {
            address t = _tokens[i];
            uint bal = _records[t].balance;
            uint tokenAmountIn = bmul(ratio, bal);
            require(tokenAmountIn != 0, "errMathAprox");
            require(tokenAmountIn <= maxAmountsIn[i], "<limIn");
            _records[t].balance = badd(_records[t].balance, tokenAmountIn);
            emit LOG_JOIN(msg.sender, t, tokenAmountIn);
            _pullUnderlying(t, msg.sender, tokenAmountIn);
        }
        _mintPoolShare(poolAmountOut);
        _pushPoolShare(msg.sender, poolAmountOut);
    }

    function exitPool(uint poolAmountIn, uint[] calldata minAmountsOut)
        external
        _lock_
        _logs_
    {
        require(finalized, "!finalized");

        uint poolTotal = totalSupply();
        uint _exitFee = bmul(poolAmountIn, exitFee);
        uint pAiAfterExitFee = bsub(poolAmountIn, _exitFee);
        uint ratio = bdiv(pAiAfterExitFee, poolTotal);
        require(ratio != 0, "errMathAprox");

        _pullPoolShare(msg.sender, poolAmountIn);
        _pushPoolShare(factory, _exitFee);
        _burnPoolShare(pAiAfterExitFee);

        for (uint i = 0; i < _tokens.length; i++) {
            address t = _tokens[i];
            uint bal = _records[t].balance;
            uint tokenAmountOut = bmul(ratio, bal);
            require(tokenAmountOut != 0, "errMathAprox");
            require(tokenAmountOut >= minAmountsOut[i], "<limO");
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
        _lock_
        _logs_
        returns (uint tokenAmountOut, uint spotPriceAfter)
    {

        require(_records[tokenIn].bound, "!bound");
        require(_records[tokenOut].bound, "!bound");
        require(publicSwap, "!publicSwap");

        Record storage inRecord = _records[address(tokenIn)];
        Record storage outRecord = _records[address(tokenOut)];

        require(tokenAmountIn <= bmul(inRecord.balance, BConst.MAX_IN_RATIO), ">maxIRat");

        uint spotPriceBefore = calcSpotPrice(
                                    inRecord.balance,
                                    inRecord.denorm,
                                    outRecord.balance,
                                    outRecord.denorm,
                                    swapFee
                                );
        require(spotPriceBefore <= maxPrice, "badLimPrice");

        tokenAmountOut = calcOutGivenIn(
                            inRecord.balance,
                            inRecord.denorm,
                            outRecord.balance,
                            outRecord.denorm,
                            tokenAmountIn,
                            swapFee
                        );
        require(tokenAmountOut >= minAmountOut, "<limO");

        inRecord.balance = badd(inRecord.balance, tokenAmountIn);
        outRecord.balance = bsub(outRecord.balance, tokenAmountOut);

        spotPriceAfter = calcSpotPrice(
                                inRecord.balance,
                                inRecord.denorm,
                                outRecord.balance,
                                outRecord.denorm,
                                swapFee
                            );
        require(spotPriceAfter >= spotPriceBefore, "errMathAprox");
        require(spotPriceAfter <= maxPrice, ">limPrice");
        require(spotPriceBefore <= bdiv(tokenAmountIn, tokenAmountOut), "errMathAprox");

        emit LOG_SWAP(msg.sender, tokenIn, tokenOut, tokenAmountIn, tokenAmountOut);

        _pullUnderlying(tokenIn, msg.sender, tokenAmountIn);
        uint _subTokenAmountIn;
        (_subTokenAmountIn, tokenAmountOut) = _pushCollectedFundGivenOut(tokenIn, tokenAmountIn, tokenOut, tokenAmountOut);
        if (_subTokenAmountIn > 0) inRecord.balance = bsub(inRecord.balance, _subTokenAmountIn);
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
        _lock_
        _logs_
        returns (uint tokenAmountIn, uint spotPriceAfter)
    {
        require(_records[tokenIn].bound, "!bound");
        require(_records[tokenOut].bound, "!bound");
        require(publicSwap, "!publicSwap");

        Record storage inRecord = _records[address(tokenIn)];
        Record storage outRecord = _records[address(tokenOut)];

        require(tokenAmountOut <= bmul(outRecord.balance, BConst.MAX_OUT_RATIO), ">maxORat");

        uint spotPriceBefore = calcSpotPrice(
                                    inRecord.balance,
                                    inRecord.denorm,
                                    outRecord.balance,
                                    outRecord.denorm,
                                    swapFee
                                );
        require(spotPriceBefore <= maxPrice, "badLimPrice");

        tokenAmountIn = calcInGivenOut(
                            inRecord.balance,
                            inRecord.denorm,
                            outRecord.balance,
                            outRecord.denorm,
                            tokenAmountOut,
                            swapFee
                        );
        require(tokenAmountIn <= maxAmountIn, "<limIn");

        inRecord.balance = badd(inRecord.balance, tokenAmountIn);
        outRecord.balance = bsub(outRecord.balance, tokenAmountOut);

        spotPriceAfter = calcSpotPrice(
                                inRecord.balance,
                                inRecord.denorm,
                                outRecord.balance,
                                outRecord.denorm,
                                swapFee
                            );
        require(spotPriceAfter >= spotPriceBefore, "errMathAprox");
        require(spotPriceAfter <= maxPrice, ">limPrice");
        require(spotPriceBefore <= bdiv(tokenAmountIn, tokenAmountOut), "errMathAprox");

        emit LOG_SWAP(msg.sender, tokenIn, tokenOut, tokenAmountIn, tokenAmountOut);

        _pullUnderlying(tokenIn, msg.sender, tokenAmountIn);
        _pushUnderlying(tokenOut, msg.sender, tokenAmountOut);
        uint _collectedFeeAmount = _pushCollectedFundGivenIn(tokenIn, tokenAmountIn);
        if (_collectedFeeAmount > 0) inRecord.balance = bsub(inRecord.balance, _collectedFeeAmount);

        return (tokenAmountIn, spotPriceAfter);
    }


    function joinswapExternAmountIn(address tokenIn, uint tokenAmountIn, uint minPoolAmountOut)
        external
        _lock_
        _logs_
        returns (uint poolAmountOut)

    {        
        require(finalized, "!finalized");
        require(_records[tokenIn].bound, "!bound");
        require(tokenAmountIn <= bmul(_records[tokenIn].balance, BConst.MAX_IN_RATIO), ">maxIRat");

        Record storage inRecord = _records[tokenIn];

        poolAmountOut = calcPoolOutGivenSingleIn(
                            inRecord.balance,
                            inRecord.denorm,
                            _totalSupply,
                            _totalWeight,
                            tokenAmountIn,
                            swapFee
                        );

        require(poolAmountOut >= minPoolAmountOut, "<limO");

        inRecord.balance = badd(inRecord.balance, tokenAmountIn);

        emit LOG_JOIN(msg.sender, tokenIn, tokenAmountIn);

        _mintPoolShare(poolAmountOut);
        _pullUnderlying(tokenIn, msg.sender, tokenAmountIn);
        uint _subTokenAmountIn;
        (_subTokenAmountIn, poolAmountOut) = _pushCollectedFundGivenOut(tokenIn, tokenAmountIn, address(this), poolAmountOut);
        if (_subTokenAmountIn > 0) inRecord.balance = bsub(inRecord.balance, _subTokenAmountIn);
        _pushPoolShare(msg.sender, poolAmountOut);

        return poolAmountOut;
    }

    function joinswapPoolAmountOut(address tokenIn, uint poolAmountOut, uint maxAmountIn)
        external
        _lock_
        _logs_
        returns (uint tokenAmountIn)
    {
        require(finalized, "!finalized");
        require(_records[tokenIn].bound, "!bound");

        Record storage inRecord = _records[tokenIn];

        tokenAmountIn = calcSingleInGivenPoolOut(
                            inRecord.balance,
                            inRecord.denorm,
                            _totalSupply,
                            _totalWeight,
                            poolAmountOut,
                            swapFee
                        );

        require(tokenAmountIn != 0, "errMathAprox");
        require(tokenAmountIn <= maxAmountIn, "<limIn");
        
        require(tokenAmountIn <= bmul(_records[tokenIn].balance, BConst.MAX_IN_RATIO), ">maxIRat");

        inRecord.balance = badd(inRecord.balance, tokenAmountIn);

        emit LOG_JOIN(msg.sender, tokenIn, tokenAmountIn);

        _mintPoolShare(poolAmountOut);
        _pushPoolShare(msg.sender, poolAmountOut);
        _pullUnderlying(tokenIn, msg.sender, tokenAmountIn);
        uint _collectedFeeAmount = _pushCollectedFundGivenIn(tokenIn, tokenAmountIn);
        if (_collectedFeeAmount > 0) inRecord.balance = bsub(inRecord.balance, _collectedFeeAmount);

        return tokenAmountIn;
    }

    function exitswapPoolAmountIn(address tokenOut, uint poolAmountIn, uint minAmountOut)
        external
        _lock_
        _logs_
        returns (uint tokenAmountOut)
    {
        require(finalized, "!finalized");
        require(_records[tokenOut].bound, "!bound");

        Record storage outRecord = _records[tokenOut];

        tokenAmountOut = calcSingleOutGivenPoolIn(
                            outRecord.balance,
                            outRecord.denorm,
                            _totalSupply,
                            _totalWeight,
                            poolAmountIn,
                            swapFee,
                            exitFee
                        );

        require(tokenAmountOut >= minAmountOut, "<limO");
        
        require(tokenAmountOut <= bmul(_records[tokenOut].balance, BConst.MAX_OUT_RATIO), ">maxORat");

        outRecord.balance = bsub(outRecord.balance, tokenAmountOut);

        uint _exitFee = bmul(poolAmountIn, exitFee);

        emit LOG_EXIT(msg.sender, tokenOut, tokenAmountOut);

        _pullPoolShare(msg.sender, poolAmountIn);
        _burnPoolShare(bsub(poolAmountIn, _exitFee));
        _pushPoolShare(factory, _exitFee);
        (, tokenAmountOut) = _pushCollectedFundGivenOut(address(this), poolAmountIn, tokenOut, tokenAmountOut);
        _pushUnderlying(tokenOut, msg.sender, tokenAmountOut);

        return tokenAmountOut;
    }

    function exitswapExternAmountOut(address tokenOut, uint tokenAmountOut, uint maxPoolAmountIn)
        external
        _lock_
        _logs_
        returns (uint poolAmountIn)
    {
        require(finalized, "!finalized");
        require(_records[tokenOut].bound, "!bound");
        require(tokenAmountOut <= bmul(_records[tokenOut].balance, BConst.MAX_OUT_RATIO), ">maxORat");

        Record storage outRecord = _records[tokenOut];

        poolAmountIn = calcPoolInGivenSingleOut(
                            outRecord.balance,
                            outRecord.denorm,
                            _totalSupply,
                            _totalWeight,
                            tokenAmountOut,
                            swapFee,
                            exitFee
                        );

        require(poolAmountIn != 0, "errMathAprox");
        require(poolAmountIn <= maxPoolAmountIn, "<limIn");

        outRecord.balance = bsub(outRecord.balance, tokenAmountOut);

        uint _exitFee = bmul(poolAmountIn, exitFee);

        emit LOG_EXIT(msg.sender, tokenOut, tokenAmountOut);

        _pullPoolShare(msg.sender, poolAmountIn);
        uint _collectedFeeAmount = _pushCollectedFundGivenIn(address(this), poolAmountIn);
        _burnPoolShare(bsub(bsub(poolAmountIn, _exitFee), _collectedFeeAmount));
        _pushPoolShare(factory, _exitFee);
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
        require(xfer, "errErc20");
    }

    function _pushUnderlying(address erc20, address to, uint amount)
        internal
    {
        bool xfer = IERC20(erc20).transfer(to, amount);
        require(xfer, "errErc20");
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

    function _pushCollectedFundGivenOut(address _tokenIn, uint _tokenAmountIn, address _tokenOut, uint _tokenAmountOut) internal returns (uint subTokenAmountIn, uint tokenAmountOut) {
        subTokenAmountIn = 0;
        tokenAmountOut = _tokenAmountOut;
        if (collectedFee > 0) {
            address _collectedToken = IBFactory(factory).collectedToken();
            if (_collectedToken == _tokenIn) {
                subTokenAmountIn = bdiv(bmul(_tokenAmountIn, collectedFee), BConst.BONE);
                _pushUnderlying(_tokenIn, factory, subTokenAmountIn);
                emit LOG_COLLECTED_FUND(_tokenIn, subTokenAmountIn);
            } else {
                uint _collectedFeeAmount = bdiv(bmul(_tokenAmountOut, collectedFee), BConst.BONE);
                _pushUnderlying(_tokenOut, factory, _collectedFeeAmount);
                tokenAmountOut = bsub(_tokenAmountOut, _collectedFeeAmount);
                emit LOG_COLLECTED_FUND(_tokenOut, _collectedFeeAmount);
            }
        }
    }

    // always push out _tokenIn (already have)
    function _pushCollectedFundGivenIn(address _tokenIn, uint _tokenAmountIn) internal returns (uint collectedFeeAmount) {
        collectedFeeAmount = 0;
        if (collectedFee > 0) {
            address _collectedToken = IBFactory(factory).collectedToken();
            if (_collectedToken != address(0)) {
                collectedFeeAmount = bdiv(bmul(_tokenAmountIn, collectedFee), BConst.BONE);
                _pushUnderlying(_tokenIn, factory, collectedFeeAmount);
                emit LOG_COLLECTED_FUND(_tokenIn, collectedFeeAmount);
            }
        }
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
// Builds new BPools, logging their addresses and providing `isBPool(address) -> (bool)`
interface IBPoolCreator {
    function newBPool() external returns (BPool);
}

contract BFactory {
    event LOG_NEW_POOL(
        address indexed caller,
        address indexed pool
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
        BPool bpool = bpoolCreator.newBPool();
        _isBPool[address(bpool)] = true;
        emit LOG_NEW_POOL(msg.sender, address(bpool));
        bpool.setController(msg.sender);
        bpool.setExitFee(defaultExitFee);
        return bpool;
    }

    IBPoolCreator public bpoolCreator;
    address public governance;
    address public collectedToken = 0x49E833337ECe7aFE375e44F4E3e8481029218E5c; // Value Liquidity Token (VALUE)
    address public collectedFund = 0xb7b2Ea8A1198368f950834875047aA7294A2bDAa; // set to insurance fund at start
    uint public defaultExitFee = BConst.DEFAULT_EXIT_FEE;

    constructor() public {
        governance = msg.sender;
    }

    function setBpoolCreator(IBPoolCreator _bpoolCreator) external {
        require(msg.sender == governance, "!governance");
        bpoolCreator = _bpoolCreator;
    }

    function setGovernance(address _governance) external {
        require(msg.sender == governance, "!governance");
        governance = _governance;
    }

    function collect(IERC20 token) external {
        uint collected = token.balanceOf(address(this));
        bool xfer = token.transfer(collectedFund, collected);
        require(xfer, "errErc20");
    }

    function setCollectedFund(address _collectedFund) external {
        require(msg.sender == governance, '!governance');
        collectedFund = _collectedFund;
    }

    function setPoolCollectedFee(BPool pool, uint _collectedFee) external {
        require(msg.sender == governance, '!governance');
        pool.setCollectedFee(_collectedFee);
    }

    function setCollectedToken(address _collectedToken) external {
        require(msg.sender == governance, '!governance');
        collectedToken = _collectedToken;
    }

    function setDefaultExitFee(uint _defaultExitFee) external {
        require(msg.sender == governance, '!governance');
        defaultExitFee = _defaultExitFee;
    }

    /**
     * This function allows governance to take unsupported tokens out of the contract.
     * This is in an effort to make someone whole, should they seriously mess up.
     * There is no guarantee governance will vote to return these.
     * It also allows for removal of airdropped tokens.
     */
    function governanceRecoverUnsupported(IERC20 _token, uint256 amount, address to) external {
        require(msg.sender == governance, "!governance");
        _token.transfer(to, amount);
    }
}