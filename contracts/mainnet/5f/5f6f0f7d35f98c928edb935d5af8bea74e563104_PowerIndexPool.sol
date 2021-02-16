/**
 *Submitted for verification at Etherscan.io on 2021-02-16
*/

/*
https://powerpool.finance/

          wrrrw r wrr
         ppwr rrr wppr0       prwwwrp                                 prwwwrp                   wr0
        rr 0rrrwrrprpwp0      pp   pr  prrrr0 pp   0r  prrrr0  0rwrrr pp   pr  prrrr0  prrrr0    r0
        rrp pr   wr00rrp      prwww0  pp   wr pp w00r prwwwpr  0rw    prwww0  pp   wr pp   wr    r0
        r0rprprwrrrp pr0      pp      wr   pr pp rwwr wr       0r     pp      wr   pr wr   pr    r0
         prwr wrr0wpwr        00        www0   0w0ww    www0   0w     00        www0    www0   0www0
          wrr ww0rrrr

*/

// SPDX-License-Identifier: GPL-3.0

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

pragma solidity >=0.6.0 <0.8.0;

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

// File: contracts/balancer-core/BConst.sol
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
    // Minimum number of tokens in the pool
    uint public constant MIN_BOUND_TOKENS  = 2;
    // Maximum number of tokens in the pool
    uint public constant MAX_BOUND_TOKENS  = 9;
    // Minimum swap fee
    uint public constant MIN_FEE           = BONE / 10**6;
    // Maximum swap fee
    uint public constant MAX_FEE           = BONE / 10;
    // Minimum weight for token
    uint public constant MIN_WEIGHT        = 1000000000;
    // Maximum weight for token
    uint public constant MAX_WEIGHT        = BONE * 50;
    // Maximum total weight
    uint public constant MAX_TOTAL_WEIGHT  = BONE * 50;
    // Minimum balance for a token
    uint public constant MIN_BALANCE       = BONE / 10**12;
    // Initial pool tokens supply
    uint public constant INIT_POOL_SUPPLY  = BONE * 100;

    uint public constant MIN_BPOW_BASE     = 1 wei;
    uint public constant MAX_BPOW_BASE     = (2 * BONE) - 1 wei;
    uint public constant BPOW_PRECISION    = BONE / 10**10;
    // Maximum input tokens balance ratio for swaps.
    uint public constant MAX_IN_RATIO      = BONE / 2;
    // Maximum output tokens balance ratio for swaps.
    uint public constant MAX_OUT_RATIO     = (BONE / 3) + 1 wei;
}

// File: contracts/balancer-core/BNum.sol
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

// File: contracts/balancer-core/BToken.sol
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
    uint8   private _decimals;

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns(uint8) {
        return 18;
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

// File: contracts/interfaces/BMathInterface.sol

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

  function calcSingleInGivenPoolOut(
    uint256 tokenBalanceIn,
    uint256 tokenWeightIn,
    uint256 poolSupply,
    uint256 totalWeight,
    uint256 poolAmountOut,
    uint256 swapFee
  ) external pure returns (uint256 tokenAmountIn);
}

// File: contracts/balancer-core/BMath.sol
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
        public pure virtual
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
        public pure virtual
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
        public pure virtual override
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
        public pure virtual
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
        public pure virtual override
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
        public pure virtual
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
        public pure virtual
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

// File: contracts/interfaces/IPoolRestrictions.sol

pragma solidity 0.6.12;

interface IPoolRestrictions {
  function getMaxTotalSupply(address _pool) external view returns (uint256);

  function isVotingSignatureAllowed(address _votingAddress, bytes4 _signature) external view returns (bool);

  function isVotingSenderAllowed(address _votingAddress, address _sender) external view returns (bool);

  function isWithoutFee(address _addr) external view returns (bool);
}

// File: contracts/interfaces/BPoolInterface.sol

pragma solidity 0.6.12;



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

  function gulp(address) external;

  function callVoting(
    address voting,
    bytes4 signature,
    bytes calldata args,
    uint256 value
  ) external;

  function getMinWeight() external view returns (uint256);

  function getMaxBoundTokens() external view returns (uint256);
}

// File: @openzeppelin/contracts/math/SafeMath.sol

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

// File: @openzeppelin/contracts/utils/Address.sol

pragma solidity >=0.6.2 <0.8.0;

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

// File: @openzeppelin/contracts/token/ERC20/SafeERC20.sol

pragma solidity >=0.6.0 <0.8.0;




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
    using SafeMath for uint256;
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
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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

// File: contracts/balancer-core/BPool.sol
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






contract BPool is BToken, BMath, BPoolInterface {
    using SafeERC20 for IERC20;

    struct Record {
        bool bound;   // is token bound to pool
        uint index;   // private
        uint denorm;  // denormalized weight
        uint balance;
    }

  /* ==========  EVENTS  ========== */

    /** @dev Emitted when tokens are swapped. */
    event LOG_SWAP(
        address indexed caller,
        address indexed tokenIn,
        address indexed tokenOut,
        uint256         tokenAmountIn,
        uint256         tokenAmountOut
    );

    /** @dev Emitted when underlying tokens are deposited for pool tokens. */
    event LOG_JOIN(
        address indexed caller,
        address indexed tokenIn,
        uint256         tokenAmountIn
    );

    /** @dev Emitted when pool tokens are burned for underlying. */
    event LOG_EXIT(
        address indexed caller,
        address indexed tokenOut,
        uint256         tokenAmountOut
    );

    /** @dev Emitted on calling any method with `_logs_` modifier. */
    event LOG_CALL(
        bytes4  indexed sig,
        address indexed caller,
        bytes           data
    ) anonymous;

    /** @dev Emitted on calling external voting contract. */
    event LOG_CALL_VOTING(
        address indexed voting,
        bool    indexed success,
        bytes4  indexed inputSig,
        bytes           inputData,
        bytes           outputData
    );

    /** @dev Emitted on taking community fee. */
    event LOG_COMMUNITY_FEE(
        address indexed caller,
        address indexed receiver,
        address indexed token,
        uint256         tokenAmount
    );

  /* ==========  Modifiers  ========== */

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

  /* ==========  Storage  ========== */

    bool private _mutex;

    // CONTROLLER contract. Able to modify swap fee, swap community fee,
    // community entree fee, community exit fee,
    // change token weights, bind, unbind and rebind tokens,
    // set wrapper contract, enable wrapper mode, change CONTROLLER.
    address internal _controller;

    // True if PUBLIC can call SWAP & JOIN functions
    bool private _publicSwap;

    // Address of contract which wraps pool operations:
    // join, exit and swaps.
    address private _wrapper;
    // Restriction to execute pool operations only from wrapper contract.
    // True if only wrapper can execute pool operations.
    bool private _wrapperMode;

    // Contract for getting restrictions:
    // Max total supply and voting calls.
    IPoolRestrictions private _restrictions;

    // `setSwapFee` require CONTROLLER
    uint private _swapFee;
    // `_communitySwapFee`, `_communityJoinFee`, `_communityExitFee`
    // defines the commissions sent to `_communityFeeReceiver`
    uint private _communitySwapFee;
    uint private _communityJoinFee;
    uint private _communityExitFee;
    // Community commission contract. Collects
    // `_communitySwapFee`, `_communityJoinFee`, `_communityExitFee`
    // for voting in underlying protocols, receiving rewards.
    address private _communityFeeReceiver;
    // `finalize` require CONTROLLER
    // `finalize` sets `PUBLIC can SWAP`, `PUBLIC can JOIN`
    bool private _finalized;

    // Array of underlying pool tokens.
    address[] internal _tokens;
    // Pool's underlying tokens Internal records.
    mapping(address => Record) internal _records;
    // Total pool's denormalized weight.
    uint internal _totalWeight;

    // Last block when account address made a swap.
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

  /* ==========  Token Queries  ========== */

    /**
     * @notice Check if a token is bound to the pool.
     * @param t Token contracts address.
     * @return TRUE if the token is bounded, FALSE - if not.
     */
    function isBound(address t)
        external view override
        returns (bool)
    {
        return _records[t].bound;
    }

    /**
     * @notice Get the number of tokens bound to the pool.
     * @return bound tokens number.
     */
    function getNumTokens()
        external view
        returns (uint)
    {
        return _tokens.length;
    }

    /**
      * @notice Get all bound tokens.
      * @return tokens - bound token address array.
     */
    function getCurrentTokens()
        external view override
        _viewlock_
        returns (address[] memory tokens)
    {
        return _tokens;
    }

    /**
      * @notice Get all bound tokens with a finalization check.
      * @return tokens - bound token address array.
     */
    function getFinalTokens()
        external view override
        _viewlock_
        returns (address[] memory tokens)
    {
        _requireContractIsFinalized();
        return _tokens;
    }

    /**
      * @notice Returns the denormalized weight of a bound token.
      * @param token Token contract address.
      * @return Bound token denormalized weight.
     */
    function getDenormalizedWeight(address token)
        external view override
        _viewlock_
        returns (uint)
    {

        _requireTokenIsBound(token);
        return _getDenormWeight(token);
    }

    /**
     * @notice Get the total denormalized weight of the pool.
     * @return Total denormalized weight of all bound tokens.
     */
    function getTotalDenormalizedWeight()
        external view override
        _viewlock_
        returns (uint)
    {
        return _getTotalWeight();
    }

    /**
     * @notice Returns the normalized weight of a bound token.
     * @param token Token contract address.
     * @return Bound token normalized weight.
     */
    function getNormalizedWeight(address token)
        external view
        _viewlock_
        returns (uint)
    {

        _requireTokenIsBound(token);
        return bdiv(_getDenormWeight(token), _getTotalWeight());
    }

    /**
     * @notice Returns the stored balance of a bound token.
     * @param token Token contract address.
     * @return Bound token balance
     */
    function getBalance(address token)
        external view override
        _viewlock_
        returns (uint)
    {

        _requireTokenIsBound(token);
        return _records[token].balance;
    }

  /* ==========  Config Queries  ========== */

    /**
     * @notice Check if tokens swap and joining the pool allowed.
     * @return TRUE if allowed, FALSE if not.
     */
    function isPublicSwap()
        external view override
        returns (bool)
    {
        return _publicSwap;
    }

    /**
     * @notice Check if pool is finalized.
     * @return TRUE if finalized, FALSE if not.
     */
    function isFinalized()
        external view override
        returns (bool)
    {
        return _finalized;
    }

    /**
     * @notice Returns the swap fee rate.
     * @return pool's swap fee rate.
     */
    function getSwapFee()
        external view override
        _viewlock_
        returns (uint)
    {
        return _swapFee;
    }

    /**
     * @notice Returns the community fee rate and community fee receiver.
     * @return communitySwapFee - community swap fee rate.
     * @return communityJoinFee - community join fee rate.
     * @return communityExitFee - community exit fee rate.
     * @return communityFeeReceiver - community fee receiver address.
     */
    function getCommunityFee()
        external view override
        _viewlock_
        returns (uint communitySwapFee, uint communityJoinFee, uint communityExitFee, address communityFeeReceiver)
    {
        return (_communitySwapFee, _communityJoinFee, _communityExitFee, _communityFeeReceiver);
    }

    /**
     * @notice Returns the controller address.
     * @return controller contract address.
     */
    function getController()
        external view
        _viewlock_
        returns (address)
    {
        return _controller;
    }

    /**
     * @notice Returns the wrapper address.
     * @return pool wrapper contract address.
     */
    function getWrapper()
        external view
        _viewlock_
        returns (address)
    {
        return _wrapper;
    }

    /**
     * @notice Check if wrapper mode is enabled.
     * @return TRUE if wrapper mode enabled, FALSE if not.
     */
    function getWrapperMode()
        external view
        _viewlock_
        returns (bool)
    {
        return _wrapperMode;
    }

    /**
     * @notice Returns the restrictions contract address.
     * @return pool restrictions contract address.
     */
    function getRestrictions()
        external view override
        _viewlock_
        returns (address)
    {
        return address(_restrictions);
    }

  /* ==========  Configuration Actions  ========== */

    /**
     * @notice Set the swap fee.
     * @dev Swap fee must be between 0.0001% and 10%.
     * @param swapFee swap fee left in the pool.
     */
    function setSwapFee(uint swapFee)
        external override
        _logs_
        _lock_
    {
        _onlyController();
        _requireFeeInBounds(swapFee);
        _swapFee = swapFee;
    }

    /**
     * @notice Set the community fee and community fee receiver.
     * @dev Community fee must be between 0.0001% and 10%.
     * @param communitySwapFee Fee for Community treasury from each swap
     * @param communityJoinFee Fee for Community treasury from each join.
     * @param communityExitFee Fee for Community treasury from each exit.
     * @param communityFeeReceiver Community treasury contract address.
     */
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

    /**
     * @notice Set the restrictions contract address.
     * @param restrictions Pool's restrictions contract.
     */
    function setRestrictions(IPoolRestrictions restrictions)
        external
        _logs_
        _lock_
    {
        _onlyController();
        _restrictions = restrictions;
    }

    /**
     * @notice Set the controller address.
     * @param manager New controller contract address.
     */
    function setController(address manager)
        external override
        _logs_
        _lock_
    {
        _onlyController();
        _controller = manager;
    }

    /**
     * @notice Activates public swap.
     * @dev Possible only when pool is not finalized.
     * @param public_ boolean variable, TRUE if active, FALSE if not.
     */
    function setPublicSwap(bool public_)
        external override
        _logs_
        _lock_
    {
        _requireContractIsNotFinalized();
        _onlyController();
        _publicSwap = public_;
    }

    /**
     * @notice Set the wrapper contract address and mode.
     * @param wrapper Wrapper contract address.
     * @param wrapperMode TRUE if enabled, FALSE if disabled.
     */
    function setWrapper(address wrapper, bool wrapperMode)
        external
        _logs_
        _lock_
    {
        _onlyController();
        _wrapper = wrapper;
        _wrapperMode = wrapperMode;
    }

    /**
     * @notice Finalize the pool, enable swaps, mint pool share token.
     */
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

    /* ==========  Voting Management Actions  ========== */

        /**
       * @notice Call target external contract with provided signature and data.
       * @param voting Destination contract address.
       * @param signature Destination contract method signature.
       * @param args Arguments of the called method.
       * @param value Transaction value.
       * @dev Can call only controller contract. Checks if destination address and signature allowed.
       */


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

    /* ==========  Token Management Actions  ========== */

    /**
     * @notice Bind a token with depositing initial balance.
     * @param token Address of the token to bind.
     * @param balance Initial token balance.
     * @param denorm Token denormalized weight.
     */
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

    /**
     * @notice Rebind token with changing balance and denormalized weight.
     * @param token Address of the token to rebind.
     * @param balance New token balance.
     * @param denorm Desired weight for the token.
     */
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

    /**
     * @notice Remove a token from the pool.
     * @dev Replaces the address in the tokens array with the last address, then removes it from the array.
     * @param token Bound token address.
     */
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

    /**
     * @notice Absorb any tokens that have been sent to this contract into the pool.
     * @param token Bound token address.
     */
    function gulp(address token)
        external override
        _logs_
        _lock_
    {
        _onlyWrapperOrNotWrapperMode();
        if (_records[token].bound) {
          _records[token].balance = IERC20(token).balanceOf(address(this));
        } else {
          IERC20(token).safeTransfer(_communityFeeReceiver, IERC20(token).balanceOf(address(this)));
        }
    }

    /* ==========  Price Queries  ========== */

    /**
     * @notice Returns the spot price for `tokenOut` in terms of `tokenIn`.
     * @param tokenIn Bound tokenIn address.
     * @param tokenOut Bound tokenOut address.
     * @return spotPrice - amount of tokenIn in wei for 1 ether of tokenOut.
     */

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

    /**
     * @notice Returns the spot price for `tokenOut` in terms of `tokenIn` without swapFee.
     * @param tokenIn Bound tokenIn address.
     * @param tokenOut Bound tokenOut address.
     * @return spotPrice - amount of tokenIn in wei for 1 ether of tokenOut.
     */
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

    /* ==========  Liquidity Provider Actions and Token Swaps  ========== */

    /**
     * @notice Mint new pool tokens by providing the proportional amount of each
     * underlying token's balance relative to the proportion of pool tokens minted.
     * @param poolAmountOut Amount of pool tokens to mint
     * @param maxAmountsIn Maximum amount of each token to pay in the same order as the pool's _tokens list.
     */
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

    /**
     * @notice Burns `poolAmountIn` pool tokens in exchange for the amounts of each
     * underlying token's balance proportional to the ratio of tokens burned to
     * total pool supply. The amount of each token transferred to the caller must
     * be greater than or equal to the associated minimum output amount from the
     * `minAmountsOut` array.
     *
     * @param poolAmountIn Exact amount of pool tokens to burn
     * @param minAmountsOut Minimum amount of each token to receive, in the same
     * order as the pool's _tokens list.
     */
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

    /**
    * @notice Execute a token swap with a specified amount of input
    * tokens and a minimum amount of output tokens.
    * @dev Will revert if `tokenOut` is uninitialized.
    * @param tokenIn Token to swap in.
    * @param tokenAmountIn Exact amount of `tokenIn` to swap in.
    * @param tokenOut Token to swap out.
    * @param minAmountOut Minimum amount of `tokenOut` to receive.
    * @param maxPrice Maximum ratio of input to output tokens.
    * @return tokenAmountOut
    * @return spotPriceAfter
    */
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
    /**
    * @dev Trades at most `maxAmountIn` of `tokenIn` for exactly `tokenAmountOut`
    * of `tokenOut`.
    *
    * Returns the actual input amount and the new spot price after the swap,
    * which can not exceed `maxPrice`.
    *
    * @param tokenIn Token to swap in
    * @param maxAmountIn Maximum amount of `tokenIn` to pay
    * @param tokenOut Token to swap out
    * @param tokenAmountOut Exact amount of `tokenOut` to receive
    * @param maxPrice Maximum ratio of input to output tokens
    * @return tokenAmountIn
    * @return spotPriceAfter
    */
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

    /**
     * @dev Pay `tokenAmountIn` of `tokenIn` to mint at least `minPoolAmountOut`
     * pool tokens.
     *
     * The pool implicitly swaps `(1- weightTokenIn) * tokenAmountIn` to the other
     * underlying tokens. Thus a swap fee is charged against the input tokens.
     *
     * @param tokenIn Token to send the pool
     * @param tokenAmountIn Exact amount of `tokenIn` to pay
     * @param minPoolAmountOut Minimum amount of pool tokens to mint
     * @return poolAmountOut - Amount of pool tokens minted
     */
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

    /**
     * @dev Pay up to `maxAmountIn` of `tokenIn` to mint exactly `poolAmountOut`.
     *
     * The pool implicitly swaps `(1- weightTokenIn) * tokenAmountIn` to the other
     * underlying tokens. Thus a swap fee is charged against the input tokens.
     *
     * @param tokenIn Token to send the pool
     * @param poolAmountOut Exact amount of pool tokens to mint
     * @param maxAmountIn Maximum amount of `tokenIn` to pay
     * @return tokenAmountIn - Amount of `tokenIn` paid
     */
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

    /**
     * @dev Burns `poolAmountIn` pool tokens in exchange for at least `minAmountOut`
     * of `tokenOut`. Returns the number of tokens sent to the caller.
     *
     * The pool implicitly burns the tokens for all underlying tokens and swaps them
     * to the desired output token. A swap fee is charged against the output tokens.
     *
     * @param tokenOut Token to receive
     * @param poolAmountIn Exact amount of pool tokens to burn
     * @param minAmountOut Minimum amount of `tokenOut` to receive
     * @return tokenAmountOut - Amount of `tokenOut` received
     */
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

    /**
    * @dev Burn up to `maxPoolAmountIn` for exactly `tokenAmountOut` of `tokenOut`.
    * Returns the number of pool tokens burned.
    *
    * The pool implicitly burns the tokens for all underlying tokens and swaps them
    * to the desired output token. A swap fee is charged against the output tokens.
    *
    * @param tokenOut Token to receive
    * @param tokenAmountOut Exact amount of `tokenOut` to receive
    * @param maxPoolAmountIn Maximum amount of pool tokens to burn
    * @return poolAmountIn - Amount of pool tokens burned
    */
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

    /* ==========  Underlying Token Internal Functions  ========== */

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

    /* ==========  Require Checks Functions  ========== */

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

    /* ==========  Token Query Internal Functions  ========== */

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

    /* ==========  Other Public getters  ========== */
    /**
    * @dev Calculate result amount after taking community fee.
    * @param tokenAmountIn Token amount.
    * @param communityFee Community fee amount.
    * @return tokenAmountInAfterFee Amount after taking fee.
    * @return tokenAmountFee Result fee amount.
    */
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

    /**
    * @dev Returns MIN_WEIGHT constant.
    * @return MIN_WEIGHT.
    */
    function getMinWeight()
        external view override
        returns (uint)
    {
        return MIN_WEIGHT;
    }

    /**
    * @dev Returns MAX_BOUND_TOKENS constant.
    * @return MAX_BOUND_TOKENS.
    */
    function getMaxBoundTokens()
        external view override
        returns (uint)
    {
      return MAX_BOUND_TOKENS;
    }
}

// File: contracts/interfaces/PowerIndexPoolInterface.sol

pragma solidity 0.6.12;


interface PowerIndexPoolInterface is BPoolInterface {
  function initialize(
    string calldata name,
    string calldata symbol,
    uint256 minWeightPerSecond,
    uint256 maxWeightPerSecond
  ) external;

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

  function getWeightPerSecondBounds() external view returns (uint256, uint256);

  function setWeightPerSecondBounds(uint256, uint256) external;

  function setWrapper(address, bool) external;

  function getWrapperMode() external view returns (bool);
}

// File: @openzeppelin/contracts/proxy/Initializable.sol

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;


/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
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
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

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

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        // extcodesize checks the size of the code stored in an address, and
        // address returns the current address. Since the code is still not
        // deployed when running a constructor, any checks on its code size will
        // yield zero, making it an effective way to detect if a contract is
        // under construction or not.
        address self = address(this);
        uint256 cs;
        // solhint-disable-next-line no-inline-assembly
        assembly { cs := extcodesize(self) }
        return cs == 0;
    }
}

// File: contracts/PowerIndexPool.sol

pragma solidity 0.6.12;

contract PowerIndexPool is BPool, Initializable {
  /// @notice The event emitted when a dynamic weight set to token.
  event SetDynamicWeight(
    address indexed token,
    uint256 fromDenorm,
    uint256 targetDenorm,
    uint256 fromTimestamp,
    uint256 targetTimestamp
  );

  /// @notice The event emitted when weight per second bounds set.
  event SetWeightPerSecondBounds(uint256 minWeightPerSecond, uint256 maxWeightPerSecond);

  struct DynamicWeight {
    uint256 fromTimestamp;
    uint256 targetTimestamp;
    uint256 targetDenorm;
  }

  /// @dev Mapping for storing dynamic weights settings. fromDenorm stored in _records mapping as denorm variable.
  mapping(address => DynamicWeight) private _dynamicWeights;

  /// @dev Min weight per second limit.
  uint256 private _minWeightPerSecond;
  /// @dev Max weight per second limit.
  uint256 private _maxWeightPerSecond;

  constructor() public BPool("", "") {}

  function initialize(
    string calldata name,
    string calldata symbol,
    address controller,
    uint256 minWeightPerSecond,
    uint256 maxWeightPerSecond
  ) external initializer {
    _name = name;
    _symbol = symbol;
    _controller = controller;
    _minWeightPerSecond = minWeightPerSecond;
    _maxWeightPerSecond = maxWeightPerSecond;
  }

  /*** Controller Interface ***/

  /**
   * @notice Set minimum and maximum weight per second by controller.
   * @param minWeightPerSecond Minimum weight per second.
   * @param maxWeightPerSecond Maximum weight per second.
   */
  function setWeightPerSecondBounds(uint256 minWeightPerSecond, uint256 maxWeightPerSecond) public _logs_ _lock_ {
    _onlyController();
    _minWeightPerSecond = minWeightPerSecond;
    _maxWeightPerSecond = maxWeightPerSecond;

    emit SetWeightPerSecondBounds(minWeightPerSecond, maxWeightPerSecond);
  }

  /**
   * @notice Set dynamic weight for token by controller contract.
   * @param token Token to change weight.
   * @param targetDenorm Target weight. fromDenorm will fetch from current value of _getDenormWeight.
   * @param fromTimestamp Start timestamp for changing weight.
   * @param targetTimestamp Target timestamp for changing weight.
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
   * @notice Bind and setDynamicWeight at the same time.
   * @param token Token for bind.
   * @param balance Initial token balance.
   * @param targetDenorm Target weight.
   * @param fromTimestamp Start timestamp to change weight.
   * @param targetTimestamp Target timestamp to change weight.
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
   * @dev Override parent unbind function.
   * @param token Token for unbind.
   */
  function unbind(address token) public override {
    super.unbind(token);

    _dynamicWeights[token] = DynamicWeight(0, 0, 0);
  }

  /**
   * @dev Override parent bind function and disable.
   */
  function bind(
    address token,
    uint256 balance,
    uint256 denorm
  ) public override {
    super.bind(token, balance, denorm);
  }

  /**
   * @notice Override parent rebind function. Allowed only for calling from bind function.
   * @param token Token for rebind.
   * @param balance Balance for rebind.
   * @param denorm Weight for rebind.
   */
  function rebind(
    address token,
    uint256 balance,
    uint256 denorm
  ) public override {
    super.rebind(token, balance, denorm);
    _dynamicWeights[token].fromTimestamp = 0;
    _dynamicWeights[token].targetTimestamp = 0;
    _dynamicWeights[token].targetDenorm = 0;
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