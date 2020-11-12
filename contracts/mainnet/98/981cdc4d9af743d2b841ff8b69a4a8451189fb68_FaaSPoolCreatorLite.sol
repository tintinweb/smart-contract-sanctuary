// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

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

    function balanceOf(address whom) public override view returns (uint) {
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
contract BMathLite is BNum {
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


}

interface IBFactory {
    function collectedToken() external view returns (address);
}

contract BPoolLite is BToken, BMathLite {
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

    event LOG_COLLECTED_FUND(
        address indexed collectedToken,
        uint256 collectedAmount
    );

    event LOG_FINALIZE(
        uint swapFee,
        uint initPoolSupply,
        uint version,
        address[] bindTokens,
        uint[] bindDenorms,
        uint[] balances
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

    uint public version = 2001;
    address public factory;    // BFactory address to push token exitFee to
    address public controller; // has CONTROL role

    // `setSwapFee` and `finalize` require CONTROL
    // `finalize` sets `PUBLIC can SWAP`, `PUBLIC can JOIN`
    uint public swapFee;
    uint public collectedFee; // 0.05% | https://yfv.finance/vip-vote/vip_5
    uint public exitFee;
    bool public finalized;

    address[] internal _tokens;
    mapping(address => Record) internal _records;
    uint private _totalWeight;

    constructor(address _factory) public {
        controller = _factory;
        factory = _factory;
        swapFee = BConst.DEFAULT_FEE;
        collectedFee = BConst.DEFAULT_COLLECTED_FEE;
        exitFee = BConst.DEFAULT_EXIT_FEE;
        finalized = false;
    }

    function setCollectedFee(uint _collectedFee) public {
        require(msg.sender == factory, "!fctr");
        require(_collectedFee <= BConst.MAX_COLLECTED_FEE, ">maxCoFee");
        require(bmul(_collectedFee, 2) <= swapFee, ">sFee/2");
        collectedFee = _collectedFee;
    }

    function setExitFee(uint _exitFee) public {
        require(!finalized, "fnl");
        require(msg.sender == factory, "!fctr");
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
        require(finalized, "!fnl");
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

    function setController(address _controller)
    external
    _lock_
    {
        require(msg.sender == controller, "!cntler");
        controller = _controller;
    }

    function finalize(
        uint _swapFee,
        uint _initPoolSupply,
        address[] calldata _bindTokens,
        uint[] calldata _bindDenorms
    ) external _lock_ {
        require(msg.sender == controller, "!cntler");
        require(!finalized, "fnl");

        require(_swapFee >= BConst.MIN_FEE, "<minFee");
        require(_swapFee <= BConst.MAX_FEE, ">maxFee");
        require(bmul(collectedFee, 2) <= _swapFee, "<Fee*2");
        swapFee = _swapFee;

        require(_initPoolSupply >= BConst.MIN_INIT_POOL_SUPPLY, "<minInitPSup");
        require(_initPoolSupply <= BConst.MAX_INIT_POOL_SUPPLY, ">maxInitPSup");

        require(_bindTokens.length >= BConst.MIN_BOUND_TOKENS, "<minTokens");
        require(_bindTokens.length < BConst.MAX_BOUND_TOKENS, ">maxTokens");
        require(_bindTokens.length == _bindDenorms.length, "erLengMism");

        uint totalWeight = 0;
        uint256[] memory balances = new uint[](_bindTokens.length);
        for (uint i = 0; i < _bindTokens.length; i++) {
            address token = _bindTokens[i];
            uint denorm = _bindDenorms[i];
            uint balance = BToken(token).balanceOf(address(this));
            balances[i] = balance;
            require(!_records[token].bound, "bound");
            require(denorm >= BConst.MIN_WEIGHT, "<minWeight");
            require(denorm <= BConst.MAX_WEIGHT, ">maxWeight");
            require(balance >= BConst.MIN_BALANCE, "<minBal");
            _records[token] = Record({
                bound : true,
                index : i,
                denorm : denorm,
                balance : balance
                });
            totalWeight = badd(totalWeight, denorm);
        }
        require(totalWeight <= BConst.MAX_TOTAL_WEIGHT, ">maxTWeight");
        _totalWeight = totalWeight;
        _tokens = _bindTokens;
        finalized = true;
        _mintPoolShare(_initPoolSupply);
        _pushPoolShare(msg.sender, _initPoolSupply);
        emit LOG_FINALIZE(swapFee, _initPoolSupply, version, _bindTokens, _bindDenorms, balances);
    }

    // Absorb any tokens that have been sent to this contract into the pool
    function gulp(address token)
    external
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
    external virtual
    _lock_
    {
        require(finalized, "!fnl");

        uint poolTotal = totalSupply();
        uint ratio = bdiv(poolAmountOut, poolTotal);
        require(ratio != 0, "erMApr");

        for (uint i = 0; i < _tokens.length; i++) {
            address t = _tokens[i];
            uint bal = _records[t].balance;
            uint tokenAmountIn = bmul(ratio, bal);
            require(tokenAmountIn != 0, "erMApr");
            require(tokenAmountIn <= maxAmountsIn[i], "<limIn");
            _records[t].balance = badd(_records[t].balance, tokenAmountIn);
            emit LOG_JOIN(msg.sender, t, tokenAmountIn);
            _pullUnderlying(t, msg.sender, tokenAmountIn);
        }
        _mintPoolShare(poolAmountOut);
        _pushPoolShare(msg.sender, poolAmountOut);
    }

    function exitPool(uint poolAmountIn, uint[] calldata minAmountsOut)
    external virtual
    _lock_
    {
        require(finalized, "!fnl");

        uint poolTotal = totalSupply();
        uint _exitFee = bmul(poolAmountIn, exitFee);
        uint pAiAfterExitFee = bsub(poolAmountIn, _exitFee);
        uint ratio = bdiv(pAiAfterExitFee, poolTotal);
        require(ratio != 0, "erMApr");

        _pullPoolShare(msg.sender, poolAmountIn);
        if (_exitFee > 0) {
            _pushPoolShare(factory, _exitFee);
        }
        _burnPoolShare(pAiAfterExitFee);

        for (uint i = 0; i < _tokens.length; i++) {
            address t = _tokens[i];
            uint bal = _records[t].balance;
            uint tokenAmountOut = bmul(ratio, bal);
            require(tokenAmountOut != 0, "erMApr");
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
    returns (uint tokenAmountOut, uint spotPriceAfter)
    {

        require(_records[tokenIn].bound, "!bound");
        require(_records[tokenOut].bound, "!bound");

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
        require(spotPriceAfter >= spotPriceBefore, "erMApr");
        require(spotPriceAfter <= maxPrice, ">limPrice");
        require(spotPriceBefore <= bdiv(tokenAmountIn, tokenAmountOut), "erMApr");

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
    returns (uint tokenAmountIn, uint spotPriceAfter)
    {
        require(_records[tokenIn].bound, "!bound");
        require(_records[tokenOut].bound, "!bound");

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
        require(spotPriceAfter >= spotPriceBefore, "erMApr");
        require(spotPriceAfter <= maxPrice, ">limPrice");
        require(spotPriceBefore <= bdiv(tokenAmountIn, tokenAmountOut), "erMApr");

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
    returns (uint poolAmountOut)

    {
        require(finalized, "!fnl");
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

    function exitswapPoolAmountIn(address tokenOut, uint poolAmountIn, uint minAmountOut)
    external
    _lock_
    returns (uint tokenAmountOut)
    {
        require(finalized, "!fnl");
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
        if (_exitFee > 0) {
            _pushPoolShare(factory, _exitFee);
        }
        (, tokenAmountOut) = _pushCollectedFundGivenOut(address(this), poolAmountIn, tokenOut, tokenAmountOut);
        _pushUnderlying(tokenOut, msg.sender, tokenAmountOut);

        return tokenAmountOut;
    }

    // ==
    // 'Underlying' token-manipulation functions make external calls but are NOT locked
    // You must `_lock_` or otherwise ensure reentry-safety
    //
    // Fixed ERC-20 transfer revert for some special token such as USDT
    function _pullUnderlying(address erc20, address from, uint amount) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = erc20.call(abi.encodeWithSelector(0x23b872dd, from, address(this), amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), '!_pullU');
    }

    function _pushUnderlying(address erc20, address to, uint amount) internal
    {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = erc20.call(abi.encodeWithSelector(0xa9059cbb, to, amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), '!_pushU');
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

interface IFaaSPool {
    function stake(uint) external;
    function withdraw(uint) external;
    function getReward(uint8 _pid, address _account) external;
    function getAllRewards(address _account) external;
    function pendingReward(uint8 _pid, address _account) external view returns (uint);
    function emergencyWithdraw() external;
}

interface IFaaSRewardFund {
    function balance(IERC20 _token) external view returns (uint);
    function safeTransfer(IERC20 _token, address _to, uint _value) external;
}

// This implements BPool contract, and allows for generalized staking, yield farming, and token distribution.
contract FaaSPoolLite is BPoolLite, IFaaSPool {
    using SafeMath for uint;

    // Info of each user.
    struct UserInfo {
        uint amount;
        mapping(uint8 => uint) rewardDebt;
        mapping(uint8 => uint) accumulatedEarned; // will accumulate every time user harvest
        mapping(uint8 => uint) lockReward;
        mapping(uint8 => uint) lockRewardReleased;
        uint lastStakeTime;
    }

    // Info of each rewardPool funding.
    struct RewardPoolInfo {
        IERC20 rewardToken;     // Address of rewardPool token contract.
        uint lastRewardBlock;   // Last block number that rewardPool distribution occurs.
        uint endRewardBlock;    // Block number which rewardPool distribution ends.
        uint rewardPerBlock;    // Reward token amount to distribute per block.
        uint accRewardPerShare; // Accumulated rewardPool per share, times 1e18.

        uint lockRewardPercent; // Lock reward percent - 0 to disable lock & vesting
        uint startVestingBlock; // Block number which vesting starts.
        uint endVestingBlock;   // Block number which vesting ends.
        uint numOfVestingBlocks;

        uint totalPaidRewards;
    }

    mapping(address => UserInfo) private userInfo;
    RewardPoolInfo[] public rewardPoolInfo;

    IFaaSRewardFund public rewardFund;
    address public exchangeProxy;
    uint public unstakingFrozenTime = 3 days;

    event Deposit(address indexed account, uint256 amount);
    event Withdraw(address indexed account, uint256 amount);
    event RewardPaid(uint8 pid, address indexed account, uint256 amount);

    constructor(address _factory) public BPoolLite(_factory) {
    }

    modifier onlyController() {
        require(msg.sender == controller, "!cntler");
        _;
    }

    function setRewardFund(IFaaSRewardFund _rewardFund) public onlyController {
        rewardFund = _rewardFund;
    }

    function setExchangeProxy(address _exchangeProxy) public onlyController {
        exchangeProxy = _exchangeProxy;
    }

    function setUnstakingFrozenTime(uint _unstakingFrozenTime) public onlyController {
        assert(unstakingFrozenTime <= 30 days); // do not lock fund for too long, please!
        unstakingFrozenTime = _unstakingFrozenTime;
    }

    function addRewardPool(IERC20 _rewardToken, uint256 _startBlock, uint256 _endRewardBlock, uint256 _rewardPerBlock,
        uint256 _lockRewardPercent, uint256 _startVestingBlock, uint256 _endVestingBlock) public onlyController {
        require(rewardPoolInfo.length < 8, "exceed rwdPoolLim");
        require(_startVestingBlock <= _endVestingBlock, "sVB>eVB");
        _startBlock = (block.number > _startBlock) ? block.number : _startBlock;
        require(_startBlock < _endRewardBlock, "sB>=eB");
        updateReward();
        rewardPoolInfo.push(RewardPoolInfo({
            rewardToken : _rewardToken,
            lastRewardBlock : _startBlock,
            endRewardBlock : _endRewardBlock,
            rewardPerBlock : _rewardPerBlock,
            accRewardPerShare : 0,
            lockRewardPercent : _lockRewardPercent,
            startVestingBlock : _startVestingBlock,
            endVestingBlock : _endVestingBlock,
            numOfVestingBlocks: _endVestingBlock - _startVestingBlock,
            totalPaidRewards: 0
            }));
    }

    function updateRewardPool(uint8 _pid, uint256 _endRewardBlock, uint256 _rewardPerBlock) public onlyController {
        updateReward(_pid);
        RewardPoolInfo storage rewardPool = rewardPoolInfo[_pid];
        require(block.number <= rewardPool.endRewardBlock, "late");
        rewardPool.endRewardBlock = _endRewardBlock;
        rewardPool.rewardPerBlock = _rewardPerBlock;
    }

    function joinPool(uint poolAmountOut, uint[] calldata maxAmountsIn) external override {
        joinPoolFor(msg.sender, poolAmountOut, maxAmountsIn);
    }

    function joinPoolFor(address account, uint poolAmountOut, uint[] calldata maxAmountsIn) public _lock_ {
        require(msg.sender == account || msg.sender == exchangeProxy, "!(prx||own)");
        _joinPool(account, poolAmountOut, maxAmountsIn);
        _stakePoolShare(account, poolAmountOut);
    }

    function joinPoolNotStake(uint poolAmountOut, uint[] calldata maxAmountsIn) external _lock_ {
        _joinPool(msg.sender, poolAmountOut, maxAmountsIn);
        _pushPoolShare(msg.sender, poolAmountOut);
    }

    function _joinPool(address account, uint poolAmountOut, uint[] calldata maxAmountsIn) internal {
        require(finalized, "!fnl");

        uint rewardTotal = totalSupply();
        uint ratio = bdiv(poolAmountOut, rewardTotal);
        require(ratio != 0, "erMApr");

        for (uint i = 0; i < _tokens.length; i++) {
            address t = _tokens[i];
            uint bal = _records[t].balance;
            uint tokenAmountIn = bmul(ratio, bal);
            require(tokenAmountIn != 0 && tokenAmountIn <= maxAmountsIn[i], "erMApr||<limIn");
            _records[t].balance = badd(_records[t].balance, tokenAmountIn);
            emit LOG_JOIN(account, t, tokenAmountIn);
            _pullUnderlying(t, msg.sender, tokenAmountIn);
        }
        _mintPoolShare(poolAmountOut);
    }

    function stake(uint _shares) external override {
        uint _before = balanceOf(address(this));
        _pullPoolShare(msg.sender, _shares);
        uint _after = balanceOf(address(this));
        _shares = bsub(_after, _before); // Additional check for deflationary tokens
        _stakePoolShare(msg.sender, _shares);
    }

    function _stakePoolShare(address _account, uint _shares) internal {
        UserInfo storage user = userInfo[_account];
        getAllRewards(_account);
        user.amount = user.amount.add(_shares);
        uint8 rewardPoolLength = uint8(rewardPoolInfo.length);
        for (uint8 _pid = 0; _pid < rewardPoolLength; ++_pid) {
            user.rewardDebt[_pid] = user.amount.mul(rewardPoolInfo[_pid].accRewardPerShare).div(1e18);
        }
        user.lastStakeTime = block.timestamp;
        emit Deposit(_account, _shares);
    }

    function unfrozenStakeTime(address _account) public view returns (uint) {
        return userInfo[_account].lastStakeTime + unstakingFrozenTime;
    }

    function withdraw(uint _amount) public override {
        UserInfo storage user = userInfo[msg.sender];
        require(user.amount >= _amount, "am>us.am");
        require(block.timestamp >= user.lastStakeTime.add(unstakingFrozenTime), "frozen");
        getAllRewards(msg.sender);
        user.amount = bsub(user.amount, _amount);
        uint8 rewardPoolLength = uint8(rewardPoolInfo.length);
        for (uint8 _pid = 0; _pid < rewardPoolLength; ++_pid) {
            user.rewardDebt[_pid] = user.amount.mul(rewardPoolInfo[_pid].accRewardPerShare).div(1e18);
        }
        _pushPoolShare(msg.sender, _amount);
        emit Withdraw(msg.sender, _amount);
    }

    // using PUSH pattern for using by Proxy if needed
    function getAllRewards(address _account) public override {
        uint8 rewardPoolLength = uint8(rewardPoolInfo.length);
        for (uint8 _pid = 0; _pid < rewardPoolLength; ++_pid) {
            getReward(_pid, _account);
        }
    }

    function getReward(uint8 _pid, address _account) public override {
        updateReward(_pid);
        UserInfo storage user = userInfo[_account];
        RewardPoolInfo storage rewardPool = rewardPoolInfo[_pid];
        uint _pendingReward = user.amount.mul(rewardPool.accRewardPerShare).div(1e18).sub(user.rewardDebt[_pid]);
        uint _lockRewardPercent = rewardPool.lockRewardPercent;
        if (_lockRewardPercent > 0) {
            if (block.number > rewardPool.endVestingBlock) {
                uint _unlockReward = user.lockReward[_pid].sub(user.lockRewardReleased[_pid]);
                if (_unlockReward > 0) {
                    _pendingReward = _pendingReward.add(_unlockReward);
                    user.lockRewardReleased[_pid] = user.lockRewardReleased[_pid].add(_unlockReward);
                }
            } else {
                if (_pendingReward > 0) {
                    uint _toLocked = _pendingReward.mul(_lockRewardPercent).div(100);
                    _pendingReward = _pendingReward.sub(_toLocked);
                    user.lockReward[_pid] = user.lockReward[_pid].add(_toLocked);
                }
                if (block.number > rewardPool.startVestingBlock) {
                    uint _toReleased = user.lockReward[_pid].mul(block.number.sub(rewardPool.startVestingBlock)).div(rewardPool.numOfVestingBlocks);
                    uint _lockRewardReleased = user.lockRewardReleased[_pid];
                    if (_toReleased > _lockRewardReleased) {
                        uint _unlockReward = _toReleased.sub(_lockRewardReleased);
                        user.lockRewardReleased[_pid] = _lockRewardReleased.add(_unlockReward);
                        _pendingReward = _pendingReward.add(_unlockReward);
                    }
                }
            }
        }
        if (_pendingReward > 0) {
            user.accumulatedEarned[_pid] = user.accumulatedEarned[_pid].add(_pendingReward);
            rewardPool.totalPaidRewards = rewardPool.totalPaidRewards.add(_pendingReward);
            rewardFund.safeTransfer(rewardPool.rewardToken, _account, _pendingReward);
            emit RewardPaid(_pid, _account, _pendingReward);
            user.rewardDebt[_pid] = user.amount.mul(rewardPoolInfo[_pid].accRewardPerShare).div(1e18);
        }
    }

    function pendingReward(uint8 _pid, address _account) public override view returns (uint _pending) {
        UserInfo storage user = userInfo[_account];
        RewardPoolInfo storage rewardPool = rewardPoolInfo[_pid];
        uint _accRewardPerShare = rewardPool.accRewardPerShare;
        uint lpSupply = balanceOf(address(this));
        uint _endRewardBlockApplicable = block.number > rewardPool.endRewardBlock ? rewardPool.endRewardBlock : block.number;
        if (_endRewardBlockApplicable > rewardPool.lastRewardBlock && lpSupply != 0) {
            uint _numBlocks = _endRewardBlockApplicable.sub(rewardPool.lastRewardBlock);
            uint _incRewardPerShare = _numBlocks.mul(rewardPool.rewardPerBlock).mul(1e18).div(lpSupply);
            _accRewardPerShare = _accRewardPerShare.add(_incRewardPerShare);
        }
        _pending = user.amount.mul(_accRewardPerShare).div(1e18).sub(user.rewardDebt[_pid]);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw() external override {
        UserInfo storage user = userInfo[msg.sender];
        uint _amount = user.amount;
        _pushPoolShare(msg.sender, _amount);
        user.amount = 0;
        uint8 rewardPoolLength = uint8(rewardPoolInfo.length);
        for (uint8 _pid = 0; _pid < rewardPoolLength; ++_pid) {
            user.rewardDebt[_pid] = 0;
        }
        emit Withdraw(msg.sender, _amount);
    }

    function getUserInfo(uint8 _pid, address _account) public view returns (uint amount, uint rewardDebt, uint accumulatedEarned, uint lockReward, uint lockRewardReleased) {
        UserInfo storage user = userInfo[_account];
        amount = user.amount;
        rewardDebt = user.rewardDebt[_pid];
        accumulatedEarned = user.accumulatedEarned[_pid];
        lockReward = user.lockReward[_pid];
        lockRewardReleased = user.lockRewardReleased[_pid];
    }

    function exitPool(uint poolAmountIn, uint[] calldata minAmountsOut) external override _lock_ {
        require(finalized, "!fnl");

        uint rewardTotal = totalSupply();
        uint _exitFee = bmul(poolAmountIn, exitFee);
        uint pAiAfterExitFee = bsub(poolAmountIn, _exitFee);
        uint ratio = bdiv(pAiAfterExitFee, rewardTotal);
        require(ratio != 0, "erMApr");

        uint _externalShares = balanceOf(msg.sender);
        if (_externalShares < poolAmountIn) {
            uint _withdrawShares = bsub(poolAmountIn, _externalShares);
            uint _stakedShares = userInfo[msg.sender].amount;
            require(_stakedShares >= _withdrawShares, "stk<wdr");
            withdraw(_withdrawShares);
        }

        _pullPoolShare(msg.sender, poolAmountIn);
        if (_exitFee > 0) {
            _pushPoolShare(factory, _exitFee);
        }
        _burnPoolShare(pAiAfterExitFee);

        for (uint i = 0; i < _tokens.length; i++) {
            address t = _tokens[i];
            uint bal = _records[t].balance;
            uint tokenAmountOut = bmul(ratio, bal);
            require(tokenAmountOut != 0, "erMApr");
            require(tokenAmountOut >= minAmountsOut[i], "<limO");
            _records[t].balance = bsub(_records[t].balance, tokenAmountOut);
            emit LOG_EXIT(msg.sender, t, tokenAmountOut);
            _pushUnderlying(t, msg.sender, tokenAmountOut);
        }
    }

    function updateReward() public {
        uint8 rewardPoolLength = uint8(rewardPoolInfo.length);
        for (uint8 _pid = 0; _pid < rewardPoolLength; ++_pid) {
            updateReward(_pid);
        }
    }

    function updateReward(uint8 _pid) public {
        RewardPoolInfo storage rewardPool = rewardPoolInfo[_pid];
        uint _endRewardBlockApplicable = block.number > rewardPool.endRewardBlock ? rewardPool.endRewardBlock : block.number;
        if (_endRewardBlockApplicable > rewardPool.lastRewardBlock) {
            uint lpSupply = balanceOf(address(this));
            if (lpSupply > 0) {
                uint _numBlocks = _endRewardBlockApplicable.sub(rewardPool.lastRewardBlock);
                uint _incRewardPerShare = _numBlocks.mul(rewardPool.rewardPerBlock).mul(1e18).div(lpSupply);
                rewardPool.accRewardPerShare = rewardPool.accRewardPerShare.add(_incRewardPerShare);
            }
            rewardPool.lastRewardBlock = _endRewardBlockApplicable;
        }
    }
}

contract FaaSPoolCreatorLite {
    function newBPool() external returns (BPoolLite) {
        return new FaaSPoolLite(msg.sender);
    }
}