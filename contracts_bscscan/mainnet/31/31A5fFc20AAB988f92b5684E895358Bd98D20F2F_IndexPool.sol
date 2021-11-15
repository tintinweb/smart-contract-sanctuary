// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;


/************************************************************************************************
Originally from https://github.com/balancer-labs/balancer-core/blob/master/contracts/BConst.sol

This source code has been modified from the original, which was copied from the github repository
at commit hash f4ed5d65362a8d6cec21662fb6eae233b0babc1f.

Subject to the GPL-3.0 license
*************************************************************************************************/


contract BConst {
  uint256 public constant VERSION_NUMBER = 1;

/* ---  Weight Updates  --- */

  // Minimum time passed between each weight update for a token.
  uint256 internal constant WEIGHT_UPDATE_DELAY = 1 hours;

  // Maximum percent by which a weight can adjust at a time
  // relative to the current weight.
  // The number of iterations needed to move from weight A to weight B is the floor of:
  // (A > B): (ln(A) - ln(B)) / ln(1.01)
  // (B > A): (ln(A) - ln(B)) / ln(0.99)
  uint256 internal constant WEIGHT_CHANGE_PCT = BONE/100;

  uint256 internal constant BONE = 10**18;

  uint256 internal constant MIN_BOUND_TOKENS = 2;
  uint256 internal constant MAX_BOUND_TOKENS = 25;

  // Minimum swap fee.
  uint256 internal constant MIN_FEE = BONE / 10**6;
  // Maximum swap or exit fee.
  uint256 internal constant MAX_FEE = BONE / 10;
  // Actual exit fee. 1%
  uint256 internal constant EXIT_FEE = 1e16; 

  // Default total of all desired weights. Can differ by up to BONE.
  uint256 internal constant DEFAULT_TOTAL_WEIGHT = BONE * 25;
  // Minimum weight for any token (1/100).
  uint256 internal constant MIN_WEIGHT = BONE / 8;
  uint256 internal constant MAX_WEIGHT = BONE * 25;
  // Maximum total weight.
  uint256 internal constant MAX_TOTAL_WEIGHT = BONE * 26;
  // Minimum balance for a token (only applied at initialization)
  uint256 internal constant MIN_BALANCE = BONE / 10**12;
  // Initial pool tokens
  uint256 internal constant INIT_POOL_SUPPLY = BONE * 100;

  uint256 internal constant MIN_BPOW_BASE = 1 wei;
  uint256 internal constant MAX_BPOW_BASE = (2 * BONE) - 1 wei;
  uint256 internal constant BPOW_PRECISION = BONE / 10**10;

  // Maximum ratio of input tokens to balance for swaps.
  uint256 internal constant MAX_IN_RATIO = BONE / 2;
  // Maximum ratio of output tokens to balance for swaps.
  uint256 internal constant MAX_OUT_RATIO = (BONE / 3) + 1 wei;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

import "./BNum.sol";


/*
Originally from https://github.com/balancer-labs/balancer-core/blob/master/contracts/BMath.sol
This source code has been modified from the original, which was copied from the github repository
at commit hash f4ed5d65362a8d6cec21662fb6eae233b0babc1f.
Subject to the GPL-3.0 license
*/


contract BMath is BConst, BNum {
  /*
    // calcSpotPrice                                                                             
    // sP = spotPrice                                                                            
    // bI = tokenBalanceIn                ( bI / wI )         1                                  
    // bO = tokenBalanceOut         sP =  -----------  *  ----------                             
    // wI = tokenWeightIn                 ( bO / wO )     ( 1 - sF )                             
    // wO = tokenWeightOut                                                                       
    // sF = swapFee                                                                              
  */
  function calcSpotPrice(
    uint256 tokenBalanceIn,
    uint256 tokenWeightIn,
    uint256 tokenBalanceOut,
    uint256 tokenWeightOut,
    uint256 swapFee
  ) internal pure returns (uint256 spotPrice) {
    uint256 numer = bdiv(tokenBalanceIn, tokenWeightIn);
    uint256 denom = bdiv(tokenBalanceOut, tokenWeightOut);
    uint256 ratio = bdiv(numer, denom);
    uint256 scale = bdiv(BONE, bsub(BONE, swapFee));
    return (spotPrice = bmul(ratio, scale));
  }

   /*
    // calcOutGivenIn                                                                            
    // aO = tokenAmountOut                                                                       
    // bO = tokenBalanceOut                                                                      
    // bI = tokenBalanceIn              /      /            bI             \    (wI / wO) \      
    // aI = tokenAmountIn    aO = bO * |  1 - | --------------------------  | ^            |     
    // wI = tokenWeightIn               \      \ ( bI + ( aI * ( 1 - sF )) /              /      
    // wO = tokenWeightOut                                                                       
    // sF = swapFee                                                                              
  */
  function calcOutGivenIn(
    uint256 tokenBalanceIn,
    uint256 tokenWeightIn,
    uint256 tokenBalanceOut,
    uint256 tokenWeightOut,
    uint256 tokenAmountIn,
    uint256 swapFee
  ) internal pure returns (uint256 tokenAmountOut) {
    uint256 weightRatio = bdiv(tokenWeightIn, tokenWeightOut);
    uint256 adjustedIn = bsub(BONE, swapFee);
    adjustedIn = bmul(tokenAmountIn, adjustedIn);
    uint256 y = bdiv(tokenBalanceIn, badd(tokenBalanceIn, adjustedIn));
    uint256 foo = bpow(y, weightRatio);
    uint256 bar = bsub(BONE, foo);
    tokenAmountOut = bmul(tokenBalanceOut, bar);
    return tokenAmountOut;
  }

  /*
    // calcInGivenOut                                                                            
    // aI = tokenAmountIn                                                                        
    // bO = tokenBalanceOut               /  /     bO      \    (wO / wI)      \                 
    // bI = tokenBalanceIn          bI * |  | ------------  | ^            - 1  |                
    // aO = tokenAmountOut    aI =        \  \ ( bO - aO ) /                   /                 
    // wI = tokenWeightIn           --------------------------------------------                 
    // wO = tokenWeightOut                          ( 1 - sF )                                   
    // sF = swapFee                                                                              
  */
  function calcInGivenOut(
    uint256 tokenBalanceIn,
    uint256 tokenWeightIn,
    uint256 tokenBalanceOut,
    uint256 tokenWeightOut,
    uint256 tokenAmountOut,
    uint256 swapFee
  ) internal pure returns (uint256 tokenAmountIn) {
    uint256 weightRatio = bdiv(tokenWeightOut, tokenWeightIn);
    uint256 diff = bsub(tokenBalanceOut, tokenAmountOut);
    uint256 y = bdiv(tokenBalanceOut, diff);
    uint256 foo = bpow(y, weightRatio);
    foo = bsub(foo, BONE);
    tokenAmountIn = bsub(BONE, swapFee);
    tokenAmountIn = bdiv(bmul(tokenBalanceIn, foo), tokenAmountIn);
    return tokenAmountIn;
  }

  
    // calcPoolOutGivenSingleIn                                                                  
    // pAo = poolAmountOut         /                                              \              
    // tAi = tokenAmountIn        ///      /     //    wI \      \\       \     wI \             
    // wI = tokenWeightIn        //| tAi *| 1 - || 1 - --  | * sF || + tBi \    --  \            
    // tW = totalWeight     pAo=||  \      \     \\    tW /      //         | ^ tW   | * pS - pS 
    // tBi = tokenBalanceIn      \\  ------------------------------------- /        /            
    // pS = poolSupply            \\                    tBi               /        /             
    // sF = swapFee                \                                              /              
  
    // Charge the trading fee for the proportion of tokenAi
    ///  which is implicitly traded to the other pool tokens.
    // That proportion is (1- weightTokenIn)
    // tokenAiAfterFee = tAi * (1 - (1-weightTi) * poolFee);
  function calcPoolOutGivenSingleIn(
    uint256 tokenBalanceIn,
    uint256 tokenWeightIn,
    uint256 poolSupply,
    uint256 totalWeight,
    uint256 tokenAmountIn,
    uint256 swapFee
  ) internal pure returns (uint256 poolAmountOut) {
    uint256 normalizedWeight = bdiv(tokenWeightIn, totalWeight);
    uint256 zaz = bmul(bsub(BONE, normalizedWeight), swapFee);
    uint256 tokenAmountInAfterFee = bmul(tokenAmountIn, bsub(BONE, zaz));

    uint256 newTokenBalanceIn = badd(tokenBalanceIn, tokenAmountInAfterFee);
    uint256 tokenInRatio = bdiv(newTokenBalanceIn, tokenBalanceIn);

    // uint newPoolSupply = (ratioTi ^ weightTi) * poolSupply;
    uint256 poolRatio = bpow(tokenInRatio, normalizedWeight);
    uint256 newPoolSupply = bmul(poolRatio, poolSupply);
    poolAmountOut = bsub(newPoolSupply, poolSupply);
    return poolAmountOut;
  }

  /*
    // calcSingleInGivenPoolOut                                                                  
    // tAi = tokenAmountIn              //(pS + pAo)\     /    1    \\                           
    // pS = poolSupply                 || ---------  | ^ | --------- || * bI - bI                
    // pAo = poolAmountOut              \\    pS    /     \(wI / tW)//                           
    // bI = balanceIn          tAi =  --------------------------------------------               
    // wI = weightIn                              /      wI  \                                   
    // tW = totalWeight                          |  1 - ----  |  * sF                            
    // sF = swapFee                               \      tW  /                                  
  */
  function calcSingleInGivenPoolOut(
    uint256 tokenBalanceIn,
    uint256 tokenWeightIn,
    uint256 poolSupply,
    uint256 totalWeight,
    uint256 poolAmountOut,
    uint256 swapFee
  ) internal pure returns (uint256 tokenAmountIn) {
    uint256 normalizedWeight = bdiv(tokenWeightIn, totalWeight);
    uint256 newPoolSupply = badd(poolSupply, poolAmountOut);
    uint256 poolRatio = bdiv(newPoolSupply, poolSupply);

    //uint newBalTi = poolRatio^(1/weightTi) * balTi;
    uint256 boo = bdiv(BONE, normalizedWeight);
    uint256 tokenInRatio = bpow(poolRatio, boo);
    uint256 newTokenBalanceIn = bmul(tokenInRatio, tokenBalanceIn);
    uint256 tokenAmountInAfterFee = bsub(newTokenBalanceIn, tokenBalanceIn);
    // Do reverse order of fees charged in joinswap_ExternAmountIn, this way
    //     ``` pAo == joinswap_ExternAmountIn(Ti, joinswap_PoolAmountOut(pAo, Ti)) ```
    //uint tAi = tAiAfterFee / (1 - (1-weightTi) * swapFee) ;
    uint256 zar = bmul(bsub(BONE, normalizedWeight), swapFee);
    tokenAmountIn = bdiv(tokenAmountInAfterFee, bsub(BONE, zar));
    return tokenAmountIn;
  }

  /*
    // calcSingleOutGivenPoolIn                                                                  
    // tAo = tokenAmountOut            /      /                                             \\   
    // bO = tokenBalanceOut           /      // pS - (pAi * (1 - eF)) \     /    1    \      \\  
    // pAi = poolAmountIn            | bO - || ----------------------- | ^ | --------- | * b0 || 
    // ps = poolSupply                \      \\          pS           /     \(wO / tW)/      //  
    // wI = tokenWeightIn      tAo =   \      \                                             //   
    // tW = totalWeight                    /     /      wO \       \                             
    // sF = swapFee                    *  | 1 - |  1 - ---- | * sF  |                            
    // eF = exitFee                        \     \      tW /       /                             
  */
  function calcSingleOutGivenPoolIn(
    uint256 tokenBalanceOut,
    uint256 tokenWeightOut,
    uint256 poolSupply,
    uint256 totalWeight,
    uint256 poolAmountIn,
    uint256 swapFee
  ) internal pure returns (uint256 tokenAmountOut) {
    uint256 normalizedWeight = bdiv(tokenWeightOut, totalWeight);
    // charge exit fee on the pool token side
    // pAiAfterExitFee = pAi*(1-exitFee)
    uint256 poolAmountInAfterExitFee = bmul(poolAmountIn, bsub(BONE, EXIT_FEE));
    uint256 newPoolSupply = bsub(poolSupply, poolAmountInAfterExitFee);
    uint256 poolRatio = bdiv(newPoolSupply, poolSupply);

    // newBalTo = poolRatio^(1/weightTo) * balTo;
    uint256 tokenOutRatio = bpow(poolRatio, bdiv(BONE, normalizedWeight));
    uint256 newTokenBalanceOut = bmul(tokenOutRatio, tokenBalanceOut);

    uint256 tokenAmountOutBeforeSwapFee = bsub(
      tokenBalanceOut,
      newTokenBalanceOut
    );

    // charge swap fee on the output token side
    //uint tAo = tAoBeforeSwapFee * (1 - (1-weightTo) * swapFee)
    uint256 zaz = bmul(bsub(BONE, normalizedWeight), swapFee);
    tokenAmountOut = bmul(tokenAmountOutBeforeSwapFee, bsub(BONE, zaz));
    return tokenAmountOut;
  }

  /*
    // calcPoolInGivenSingleOut                                                                  
    // pAi = poolAmountIn               // /               tAo             \\     / wO \     \   
    // bO = tokenBalanceOut            // | bO - -------------------------- |\   | ---- |     \  
    // tAo = tokenAmountOut      pS - ||   \     1 - ((1 - (tO / tW)) * sF)/  | ^ \ tW /  * pS | 
    // ps = poolSupply                 \\ -----------------------------------/                /  
    // wO = tokenWeightOut  pAi =       \\               bO                 /                /   
    // tW = totalWeight           -------------------------------------------------------------  
    // sF = swapFee                                        ( 1 - eF )                            
    // eF = exitFee                                                                              
    */
  function calcPoolInGivenSingleOut(
    uint256 tokenBalanceOut,
    uint256 tokenWeightOut,
    uint256 poolSupply,
    uint256 totalWeight,
    uint256 tokenAmountOut,
    uint256 swapFee
  ) internal pure returns (uint256 poolAmountIn) {
    // charge swap fee on the output token side
    uint256 normalizedWeight = bdiv(tokenWeightOut, totalWeight);
    //uint tAoBeforeSwapFee = tAo / (1 - (1-weightTo) * swapFee) ;
    uint256 zoo = bsub(BONE, normalizedWeight);
    uint256 zar = bmul(zoo, swapFee);
    uint256 tokenAmountOutBeforeSwapFee = bdiv(tokenAmountOut, bsub(BONE, zar));

    uint256 newTokenBalanceOut = bsub(
      tokenBalanceOut,
      tokenAmountOutBeforeSwapFee
    );
    uint256 tokenOutRatio = bdiv(newTokenBalanceOut, tokenBalanceOut);

    //uint newPoolSupply = (ratioTo ^ weightTo) * poolSupply;
    uint256 poolRatio = bpow(tokenOutRatio, normalizedWeight);
    uint256 newPoolSupply = bmul(poolRatio, poolSupply);
    uint256 poolAmountInAfterExitFee = bsub(poolSupply, newPoolSupply);

    // charge exit fee on the pool token side
    // pAi = pAiAfterExitFee/(1-exitFee)
    poolAmountIn = bdiv(poolAmountInAfterExitFee, bsub(BONE, EXIT_FEE));
    return poolAmountIn;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

import "./BConst.sol";


/************************************************************************************************
Originally from https://github.com/balancer-labs/balancer-core/blob/master/contracts/BNum.sol

This source code has been modified from the original, which was copied from the github repository
at commit hash f4ed5d65362a8d6cec21662fb6eae233b0babc1f.

Subject to the GPL-3.0 license
*************************************************************************************************/


contract BNum is BConst {
  function btoi(uint256 a) internal pure returns (uint256) {
    return a / BONE;
  }

  function bfloor(uint256 a) internal pure returns (uint256) {
    return btoi(a) * BONE;
  }

  function badd(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "ERR_ADD_OVERFLOW");
    return c;
  }

  function bsub(uint256 a, uint256 b) internal pure returns (uint256) {
    (uint256 c, bool flag) = bsubSign(a, b);
    require(!flag, "ERR_SUB_UNDERFLOW");
    return c;
  }

  function bsubSign(uint256 a, uint256 b)
    internal
    pure
    returns (uint256, bool)
  {
    if (a >= b) {
      return (a - b, false);
    } else {
      return (b - a, true);
    }
  }

  function bmul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c0 = a * b;
    require(a == 0 || c0 / a == b, "ERR_MUL_OVERFLOW");
    uint256 c1 = c0 + (BONE / 2);
    require(c1 >= c0, "ERR_MUL_OVERFLOW");
    uint256 c2 = c1 / BONE;
    return c2;
  }

  function bdiv(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0, "ERR_DIV_ZERO");
    uint256 c0 = a * BONE;
    require(a == 0 || c0 / a == BONE, "ERR_DIV_INTERNAL"); // bmul overflow
    uint256 c1 = c0 + (b / 2);
    require(c1 >= c0, "ERR_DIV_INTERNAL"); //  badd require
    uint256 c2 = c1 / b;
    return c2;
  }

  // DSMath.wpow
  function bpowi(uint256 a, uint256 n) internal pure returns (uint256) {
    uint256 z = n % 2 != 0 ? a : BONE;

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
  function bpow(uint256 base, uint256 exp) internal pure returns (uint256) {
    require(base >= MIN_BPOW_BASE, "ERR_BPOW_BASE_TOO_LOW");
    require(base <= MAX_BPOW_BASE, "ERR_BPOW_BASE_TOO_HIGH");

    uint256 whole = bfloor(exp);
    uint256 remain = bsub(exp, whole);

    uint256 wholePow = bpowi(base, btoi(whole));

    if (remain == 0) {
      return wholePow;
    }

    uint256 partialResult = bpowApprox(base, remain, BPOW_PRECISION);
    return bmul(wholePow, partialResult);
  }

  function bpowApprox(
    uint256 base,
    uint256 exp,
    uint256 precision
  ) internal pure returns (uint256) {
    // term 0:
    uint256 a = exp;
    (uint256 x, bool xneg) = bsubSign(base, BONE);
    uint256 term = BONE;
    uint256 sum = term;
    bool negative = false;

    // term(k) = numer / denom
    //         = (product(a - i - 1, i=1-->k) * x^k) / (k!)
    // each iteration, multiply previous term by (a-(k-1)) * x / k
    // continue until term is less than precision
    for (uint256 i = 1; term >= precision; i++) {
      uint256 bigK = i * BONE;
      (uint256 c, bool cneg) = bsubSign(a, bsub(bigK, BONE));
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

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

import "./BNum.sol";


/************************************************************************************************
Originally from https://github.com/balancer-labs/balancer-core/blob/master/contracts/BToken.sol

This source code has been modified from the original, which was copied from the github repository
at commit hash f4ed5d65362a8d6cec21662fb6eae233b0babc1f.

Subject to the GPL-3.0 license
*************************************************************************************************/


// Highly opinionated token implementation
interface IERC20 {
  function name() external view returns (string memory);

  function symbol() external view returns (string memory);

  function decimals() external view returns (uint8);

  function totalSupply() external view returns (uint256);

  function balanceOf(address whom) external view returns (uint256);

  function allowance(address src, address dst) external view returns (uint256);

  function approve(address dst, uint256 amt) external returns (bool);

  function transfer(address dst, uint256 amt) external returns (bool);

  function transferFrom(
    address src,
    address dst,
    uint256 amt
  ) external returns (bool);
}


contract BTokenBase is BNum {
  mapping(address => uint256) internal _balance;
  mapping(address => mapping(address => uint256)) internal _allowance;
  uint256 internal _totalSupply;

  event Approval(address indexed src, address indexed dst, uint256 amt);
  event Transfer(address indexed src, address indexed dst, uint256 amt);

  function _mint(uint256 amt) internal {
    _balance[address(this)] = badd(_balance[address(this)], amt);
    _totalSupply = badd(_totalSupply, amt);
    emit Transfer(address(0), address(this), amt);
  }

  function _burn(uint256 amt) internal {
    require(_balance[address(this)] >= amt, "ERR_INSUFFICIENT_BAL");
    _balance[address(this)] = bsub(_balance[address(this)], amt);
    _totalSupply = bsub(_totalSupply, amt);
    emit Transfer(address(this), address(0), amt);
  }

  function _move(
    address src,
    address dst,
    uint256 amt
  ) internal {
    require(_balance[src] >= amt, "ERR_INSUFFICIENT_BAL");
    _balance[src] = bsub(_balance[src], amt);
    _balance[dst] = badd(_balance[dst], amt);
    emit Transfer(src, dst, amt);
  }

  function _push(address to, uint256 amt) internal {
    _move(address(this), to, amt);
  }

  function _pull(address from, uint256 amt) internal {
    _move(from, address(this), amt);
  }
}


contract BToken is BTokenBase, IERC20 {
  uint8 private constant DECIMALS = 18;
  string private _name;
  string private _symbol;

  function _initializeToken(string memory name_, string memory symbol_) internal {
    require(
      bytes(_name).length == 0 &&
      bytes(name_).length != 0 &&
      bytes(symbol_).length != 0,
      "ERR_BTOKEN_INITIALIZED"
    );
    _name = name_;
    _symbol = symbol_;
  }

  function name()
    external
    override
    view
    returns (string memory)
  {
    return _name;
  }

  function symbol()
    external
    override
    view
    returns (string memory)
  {
    return _symbol;
  }

  function decimals()
    external
    override
    view
    returns (uint8)
  {
    return DECIMALS;
  }

  function allowance(address src, address dst)
    external
    override
    view
    returns (uint256)
  {
    return _allowance[src][dst];
  }

  function balanceOf(address whom) external override view returns (uint256) {
    return _balance[whom];
  }

  function totalSupply() public override view returns (uint256) {
    return _totalSupply;
  }

  function approve(address dst, uint256 amt) external override returns (bool) {
    _allowance[msg.sender][dst] = amt;
    emit Approval(msg.sender, dst, amt);
    return true;
  }

  function increaseApproval(address dst, uint256 amt) external returns (bool) {
    _allowance[msg.sender][dst] = badd(_allowance[msg.sender][dst], amt);
    emit Approval(msg.sender, dst, _allowance[msg.sender][dst]);
    return true;
  }

  function decreaseApproval(address dst, uint256 amt) external returns (bool) {
    uint256 oldValue = _allowance[msg.sender][dst];
    if (amt > oldValue) {
      _allowance[msg.sender][dst] = 0;
    } else {
      _allowance[msg.sender][dst] = bsub(oldValue, amt);
    }
    emit Approval(msg.sender, dst, _allowance[msg.sender][dst]);
    return true;
  }

  function transfer(address dst, uint256 amt) external override returns (bool) {
    _move(msg.sender, dst, amt);
    return true;
  }

  function transferFrom(
    address src,
    address dst,
    uint256 amt
  ) external override returns (bool) {
    require(
      msg.sender == src || amt <= _allowance[src][msg.sender],
      "ERR_BTOKEN_BAD_CALLER"
    );
    _move(src, dst, amt);
    if (msg.sender != src && _allowance[src][msg.sender] != uint256(-1)) {
      _allowance[src][msg.sender] = bsub(_allowance[src][msg.sender], amt);
      emit Approval(msg.sender, dst, _allowance[src][msg.sender]);
    }
    return true;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;
pragma experimental ABIEncoderV2;

/* ========== Internal Inheritance ========== */
import "./BToken.sol";
import "./BMath.sol";

/* ========== Internal Interfaces ========== */
import "../../interfaces/IFlashLoanRecipient.sol";
import "../../interfaces/IIndexPool.sol";
import "../../interfaces/ICompLikeToken.sol";
import "../../interfaces/ITokenUnbindHandler.sol";

// IP_1

contract IndexPool is BToken, BMath, IIndexPool {

/* ==========  EVENTS  ========== */

  // IP_E_1.1
  event LOG_SWAP(
    address indexed caller,
    address indexed tokenIn,
    address indexed tokenOut,
    uint256 tokenAmountIn,
    uint256 tokenAmountOut
  );

  // IP_E_1.2 
  event LOG_JOIN(
    address indexed caller,
    address indexed tokenIn,
    uint256 tokenAmountIn
  );

  // IP_E_1.3
  event LOG_EXIT(
    address indexed caller,
    address indexed tokenOut,
    uint256 tokenAmountOut
  );

  // IP_E_1.4
  event LOG_DENORM_UPDATED(address indexed token, uint256 newDenorm);

  // IP_E_1.5
  event LOG_DESIRED_DENORM_SET(address indexed token, uint256 desiredDenorm);

  // IP_E_1.6
  event LOG_TOKEN_REMOVED(address token);

  // IP_E_1.7
  event LOG_TOKEN_ADDED(
    address indexed token,
    uint256 desiredDenorm,
    uint256 minimumBalance
  );

  // IP_E_1.8
  event LOG_MINIMUM_BALANCE_UPDATED(address token, uint256 minimumBalance);

  // IP_E_1.9
  event LOG_TOKEN_READY(address indexed token);

  // IP_E_1.10
  event LOG_PUBLIC_SWAP_ENABLED();

  // IP_E_1.11
  event LOG_MAX_TOKENS_UPDATED(uint256 maxPoolTokens);

  // IP_E_1.12
  event LOG_EXIT_FEE_RECIPIENT_UPDATED(address exitFeeRecipient);

/* ==========  Modifiers  ========== */

  modifier _lock_ {
    require(!_mutex, "REENTRY");
    _mutex = true;
    _;
    _mutex = false;
  }

  modifier _viewlock_() {
    require(!_mutex, "REENTRY");
    _;
  }

  modifier _control_ {
    require(msg.sender == _controller, "NOT_CONTROLLER");
    _;
  }

  modifier _public_ {
    require(_publicSwap, "NOT_PUBLIC");
    _;
  }

/* ==========  Storage  ========== */

  bool internal _mutex;

  // Account with CONTROL role. Able to modify the swap fee,
  // adjust token weights, bind and unbind tokens and lock
  // public swaps & joins.
  address internal _controller;

  // Contract that handles unbound tokens.
  ITokenUnbindHandler internal _unbindHandler;

  // True if PUBLIC can call SWAP & JOIN functions
  bool internal _publicSwap;

  // `setSwapFee` requires CONTROL
  uint256 internal _swapFee;

  // Array of underlying tokens in the pool.
  address[] internal _tokens;

  // Internal records of the pool's underlying tokens
  mapping(address => Record) internal _records;

  // Total denormalized weight of the pool.
  uint256 internal _totalWeight;

  // Minimum balances for tokens which have been added without the
  // requisite initial balance.
  mapping(address => uint256) internal _minimumBalances;

  // Maximum LP tokens that can be bound.
  // Used in alpha to restrict the economic impact of a catastrophic
  // failure. It can be gradually increased as the pool continues to
  // not be exploited.
  uint256 internal _maxPoolTokens;

  // The uniswapV2oracle used for the pool. 
  address internal _oracle; 

  // The uniswapV2router used for this pool.
  address internal _router; 

  // Recipient for exit fees
  address internal _exitFeeRecipient;
  address internal _exitFeeRecipientAdditional;

/* ==========  Controls  ========== */

  // IP_C_1.1
  function configure(
    address controller,
    string calldata name,
    string calldata symbol,
    address uniswapV2oracle,
    address uniswapV2router,
    address exitFeeRecipient,
    address exitFeeRecipientAdditional
  ) external override {
    require(_controller == address(0), "CONFIGURED");
    require(
      controller != address(0) && exitFeeRecipient != address(0) && exitFeeRecipientAdditional != address(0), "NA"
    );
    _controller = controller;
    // default fee is 1%
    _swapFee = BONE / 100;
    _initializeToken(name, symbol);
    _oracle = uniswapV2oracle; 
    _router = uniswapV2router;
    _exitFeeRecipient = exitFeeRecipient;
    _exitFeeRecipientAdditional = exitFeeRecipientAdditional;
  }

  // IP_C_1.2
  function initialize(
    address[] calldata tokens,
    uint256[] calldata balances,
    uint96[] calldata denorms,
    address tokenProvider,
    address unbindHandler
  )
    external
    override
    _control_
  {
    require(_tokens.length == 0, "INITIALIZED");
    uint256 len = tokens.length;
    require(len >= MIN_BOUND_TOKENS, "MT");
    require(len <= MAX_BOUND_TOKENS, "MXT");
    require(balances.length == len && denorms.length == len, "AL");
    uint256 totalWeight = 0;
    for (uint256 i = 0; i < len; i++) {
      address token = tokens[i];
      uint96 denorm = denorms[i];
      uint256 balance = balances[i];
      require(denorm >= MIN_WEIGHT, "MW");
      require(denorm <= MAX_WEIGHT, "MXW");
      require(balance >= MIN_BALANCE, "MB");
      _records[token] = Record({
        bound: true,
        ready: true,
        lastDenormUpdate: uint40(block.timestamp),
        denorm: denorm,
        desiredDenorm: denorm,
        index: uint8(i),
        balance: balance
      });
      _tokens.push(token);
      totalWeight = badd(totalWeight, denorm);
      _pullUnderlying(token, tokenProvider, balance);
    }
    require(totalWeight <= MAX_TOTAL_WEIGHT, "MTW");
    _totalWeight = totalWeight;
    _publicSwap = true;
    emit LOG_PUBLIC_SWAP_ENABLED();
    _mintPoolShare(INIT_POOL_SUPPLY);
    _pushPoolShare(tokenProvider, INIT_POOL_SUPPLY);
    _unbindHandler = ITokenUnbindHandler(unbindHandler);
  }

  // IP_C_1.3
  function setMaxPoolTokens(uint256 maxPoolTokens) external override _control_ {
    _maxPoolTokens = maxPoolTokens;
    emit LOG_MAX_TOKENS_UPDATED(maxPoolTokens);
  }

  // IP_C_1.4
  function setExitFeeRecipient(address exitFeeRecipient, bool additional) external override _control_ {
    require(exitFeeRecipient != address(0), "NA");
    if (additional) {
      _exitFeeRecipientAdditional = exitFeeRecipient;
    } else {
      _exitFeeRecipient = exitFeeRecipient;
    }
    emit LOG_EXIT_FEE_RECIPIENT_UPDATED(exitFeeRecipient);
  }

  // IP_C_1.5
  function delegateCompLikeToken(address token,address delegatee)
    external
    override
    _control_
  {
    ICompLikeToken(token).delegate(delegatee);
  }

/* ==========  Token Management Actions  ========== */

  // IP_TMA_1.1
  function reweighTokens(
    address[] calldata tokens,
    uint96[] calldata desiredDenorms
  )
    external
    override
    _lock_
    _control_
  {
    require(desiredDenorms.length == tokens.length, "AL");
    for (uint256 i = 0; i < tokens.length; i++)
      _setDesiredDenorm(tokens[i], desiredDenorms[i]);
  }

  // IP_TMA_1.2
  function reindexTokens(
    address[] calldata tokens,
    uint96[] calldata desiredDenorms,
    uint256[] calldata minimumBalances
  )
    external
    override
    _lock_
    _control_
  {
    require(
      desiredDenorms.length == tokens.length && minimumBalances.length == tokens.length,
      "AL"
    );
    // This size may not be the same as the input size, as it is possible
    // to temporarily exceed the index size while tokens are being phased in
    // or out.
    uint256 tLen = _tokens.length;
    bool[] memory receivedIndices = new bool[](tLen);
    // We need to read token records in two separate loops, so
    // write them to memory to avoid duplicate storage reads.
    Record[] memory records = new Record[](tokens.length);
    // Read all the records from storage and mark which of the existing tokens
    // were represented in the reindex call.
    for (uint256 i = 0; i < tokens.length; i++) {
      records[i] = _records[tokens[i]];
      if (records[i].bound) receivedIndices[records[i].index] = true;
    }
    // If any bound tokens were not sent in this call, set their desired weights to 0.
    for (uint256 i = 0; i < tLen; i++) {
      if (!receivedIndices[i]) {
        _setDesiredDenorm(_tokens[i], 0);
      }
    }
    for (uint256 i = 0; i < tokens.length; i++) {
      address token = tokens[i];
      // If an input weight is less than the minimum weight, use that instead.
      uint96 denorm = desiredDenorms[i];
      if (denorm < MIN_WEIGHT) denorm = uint96(MIN_WEIGHT);
      if (!records[i].bound) {
        // If the token is not bound, bind it.
        _bind(token, minimumBalances[i], denorm);
      } else {
        _setDesiredDenorm(token, denorm);
      }
    }
  }

  // IP_TMA_1.3
  function setMinimumBalance(
    address token,
    uint256 minimumBalance
  )
    external
    override
    _control_
  {
    Record storage record = _records[token];
    require(record.bound, "NB");
    require(!record.ready, "R");
    _minimumBalances[token] = minimumBalance;
    emit LOG_MINIMUM_BALANCE_UPDATED(token, minimumBalance);
  }

/* ==========  Liquidity Provider Actions  ========== */

  // IP_LPA_1.1
  function joinPool(uint256 poolAmountOut, uint256[] calldata maxAmountsIn)
    external
    override
    _lock_
    _public_
  {
    uint256 poolTotal = totalSupply();
    uint256 ratio = bdiv(poolAmountOut, poolTotal);
    require(ratio != 0, "MA");
    require(maxAmountsIn.length == _tokens.length, "AL");

    uint256 maxPoolTokens = _maxPoolTokens;
    if (maxPoolTokens > 0) {
      require(
        badd(poolTotal, poolAmountOut) <= maxPoolTokens,
        "MPT"
      );
    }

    for (uint256 i = 0; i < maxAmountsIn.length; i++) {
      address t = _tokens[i];
      (Record memory record, uint256 realBalance) = _getInputToken(t);
      uint256 tokenAmountIn = bmul(ratio, record.balance);
      require(tokenAmountIn != 0, "MA");
      require(tokenAmountIn <= maxAmountsIn[i], "LI");
      _updateInputToken(t, record, badd(realBalance, tokenAmountIn));
      emit LOG_JOIN(msg.sender, t, tokenAmountIn);
      _pullUnderlying(t, msg.sender, tokenAmountIn);
    }
    _mintPoolShare(poolAmountOut);
    _pushPoolShare(msg.sender, poolAmountOut);
  }

  // IP_LPA_1.2
  function joinswapExternAmountIn(
    address tokenIn,
    uint256 tokenAmountIn,
    uint256 minPoolAmountOut
  )
    external
    override
    _lock_
    _public_
    returns (uint256/* poolAmountOut */)
  {
    (Record memory inRecord, uint256 realInBalance) = _getInputToken(tokenIn);

    require(tokenAmountIn != 0, "ZI");

    require(
      tokenAmountIn <= bmul(inRecord.balance, MAX_IN_RATIO),
      "MIR"
    );

    uint256 poolAmountOut = calcPoolOutGivenSingleIn(
      inRecord.balance,
      inRecord.denorm,
      _totalSupply,
      _totalWeight,
      tokenAmountIn,
      _swapFee
    );

    uint256 maxPoolTokens = _maxPoolTokens;
    if (maxPoolTokens > 0) {
      require(
        badd(_totalSupply, poolAmountOut) <= maxPoolTokens,
        "MPT"
      );
    }

    require(poolAmountOut >= minPoolAmountOut, "LO");

    _updateInputToken(tokenIn, inRecord, badd(realInBalance, tokenAmountIn));

    emit LOG_JOIN(msg.sender, tokenIn, tokenAmountIn);

    _mintPoolShare(poolAmountOut);
    _pushPoolShare(msg.sender, poolAmountOut);
    _pullUnderlying(tokenIn, msg.sender, tokenAmountIn);

    return poolAmountOut;
  }

  // IP_LPA_1.3
  function joinswapPoolAmountOut(
    address tokenIn,
    uint256 poolAmountOut,
    uint256 maxAmountIn
  )
    external
    override
    _lock_
    _public_
    returns (uint256/* tokenAmountIn */)
  {
    uint256 maxPoolTokens = _maxPoolTokens;
    if (maxPoolTokens > 0) {
      require(
        badd(_totalSupply, poolAmountOut) <= maxPoolTokens,
        "MPT"
      );
    }

    (Record memory inRecord, uint256 realInBalance) = _getInputToken(tokenIn);

    uint256 tokenAmountIn = calcSingleInGivenPoolOut(
      inRecord.balance,
      inRecord.denorm,
      _totalSupply,
      _totalWeight,
      poolAmountOut,
      _swapFee
    );

    require(tokenAmountIn != 0, "MA");
    require(tokenAmountIn <= maxAmountIn, "LI");

    require(
      tokenAmountIn <= bmul(inRecord.balance, MAX_IN_RATIO),
      "MIR"
    );

    _updateInputToken(tokenIn, inRecord, badd(realInBalance, tokenAmountIn));

    emit LOG_JOIN(msg.sender, tokenIn, tokenAmountIn);

    _mintPoolShare(poolAmountOut);
    _pushPoolShare(msg.sender, poolAmountOut);
    _pullUnderlying(tokenIn, msg.sender, tokenAmountIn);

    return tokenAmountIn;
  }

  // IP_LPA_1.4
  function exitPool(uint256 poolAmountIn, uint256[] calldata minAmountsOut)
    external
    override
    _lock_
  {
    require(minAmountsOut.length == _tokens.length, "AL");
    uint256 poolTotal = totalSupply();
    uint256 exitFee = bmul(poolAmountIn, EXIT_FEE);
    uint256 pAiAfterExitFee = bsub(poolAmountIn, exitFee);
    uint256 ratio = bdiv(pAiAfterExitFee, poolTotal);
    require(ratio != 0, "MA");

    _pullPoolShare(msg.sender, poolAmountIn);
    _pushPoolShare(_exitFeeRecipient, exitFee / 2);
    _pushPoolShare(_exitFeeRecipientAdditional, exitFee - (exitFee / 2));
    _burnPoolShare(pAiAfterExitFee);
    for (uint256 i = 0; i < minAmountsOut.length; i++) {
      address t = _tokens[i];
      Record memory record = _records[t];
      if (record.ready) {
        uint256 tokenAmountOut = bmul(ratio, record.balance);
        require(tokenAmountOut != 0, "MA");
        require(tokenAmountOut >= minAmountsOut[i], "LO");

        _records[t].balance = bsub(record.balance, tokenAmountOut);
        emit LOG_EXIT(msg.sender, t, tokenAmountOut);
        _pushUnderlying(t, msg.sender, tokenAmountOut);
      } else {
        // If the token is not initialized, it can not exit the pool.
        require(minAmountsOut[i] == 0, "ONR");
      }
    }
  }

  // IP_LPA_1.5
  function exitswapPoolAmountIn(
    address tokenOut,
    uint256 poolAmountIn,
    uint256 minAmountOut
  )
    external
    override
    _lock_
    returns (uint256/* tokenAmountOut */)
  {
    Record memory outRecord = _getOutputToken(tokenOut);

    uint256 tokenAmountOut = calcSingleOutGivenPoolIn(
      outRecord.balance,
      outRecord.denorm,
      _totalSupply,
      _totalWeight,
      poolAmountIn,
      _swapFee
    );

    require(tokenAmountOut >= minAmountOut, "LO");

    require(
      tokenAmountOut <= bmul(outRecord.balance, MAX_OUT_RATIO),
      "MOR"
    );

    _pushUnderlying(tokenOut, msg.sender, tokenAmountOut);
    _records[tokenOut].balance = bsub(outRecord.balance, tokenAmountOut);
    _decreaseDenorm(outRecord, tokenOut);
    uint256 exitFee = bmul(poolAmountIn, EXIT_FEE);

    emit LOG_EXIT(msg.sender, tokenOut, tokenAmountOut);

    _pullPoolShare(msg.sender, poolAmountIn);
    _burnPoolShare(bsub(poolAmountIn, exitFee));
    _pushPoolShare(_exitFeeRecipient, exitFee / 2);
    _pushPoolShare(_exitFeeRecipientAdditional, exitFee - (exitFee / 2));

    return tokenAmountOut;
  }

  // IP_LPA_1.6
  function exitswapExternAmountOut(
    address tokenOut,
    uint256 tokenAmountOut,
    uint256 maxPoolAmountIn
  )
    external
    override
    _lock_
    returns (uint256/* poolAmountIn */)
  {
    Record memory outRecord = _getOutputToken(tokenOut);
    require(
      tokenAmountOut <= bmul(outRecord.balance, MAX_OUT_RATIO),
      "MOR"
    );

    uint256 poolAmountIn = calcPoolInGivenSingleOut(
      outRecord.balance,
      outRecord.denorm,
      _totalSupply,
      _totalWeight,
      tokenAmountOut,
      _swapFee
    );

    require(poolAmountIn != 0, "MA");
    require(poolAmountIn <= maxPoolAmountIn, "LI");

    _pushUnderlying(tokenOut, msg.sender, tokenAmountOut);
    _records[tokenOut].balance = bsub(outRecord.balance, tokenAmountOut);
    _decreaseDenorm(outRecord, tokenOut);

    uint256 exitFee = bmul(poolAmountIn, EXIT_FEE);

    emit LOG_EXIT(msg.sender, tokenOut, tokenAmountOut);

    _pullPoolShare(msg.sender, poolAmountIn);
    _burnPoolShare(bsub(poolAmountIn, exitFee));
    _pushPoolShare(_exitFeeRecipient, exitFee / 2);
    _pushPoolShare(_exitFeeRecipientAdditional, exitFee - (exitFee / 2));

    return poolAmountIn;
  }

/* ==========  Other  ========== */

  // IP_O_1.1
  function gulp(address token) external override _lock_ {
    Record storage record = _records[token];
    uint256 balance = IERC20(token).balanceOf(address(this));
    if (record.bound) {
      if (!record.ready) {
        uint256 minimumBalance = _minimumBalances[token];
        if (balance >= minimumBalance) {
          _minimumBalances[token] = 0;
          record.ready = true;
          emit LOG_TOKEN_READY(token);
          uint256 additionalBalance = bsub(balance, minimumBalance);
          uint256 balRatio = bdiv(additionalBalance, minimumBalance);
          uint96 newDenorm = uint96(badd(MIN_WEIGHT, bmul(MIN_WEIGHT, balRatio)));
          record.denorm = newDenorm;
          record.lastDenormUpdate = uint40(block.timestamp);
          _totalWeight = badd(_totalWeight, newDenorm);
          emit LOG_DENORM_UPDATED(token, record.denorm);
        }
      }
      _records[token].balance = balance;
    } else {
      _pushUnderlying(token, address(_unbindHandler), balance);
      _unbindHandler.handleUnbindToken(token, balance);
    }
  }

/* ==========  Flash Loan  ========== */

  // IP_FL_1.1
  function flashBorrow(
    address recipient,
    address token,
    uint256 amount,
    bytes calldata data
  )
    external
    override
    _lock_
  {
    Record storage record = _records[token];
    require(record.bound, "NB");
    uint256 balStart = IERC20(token).balanceOf(address(this));
    require(balStart >= amount, "IB");
    _pushUnderlying(token, address(recipient), amount);
    uint256 fee = bmul(balStart, _swapFee);
    uint256 amountDue = badd(amount, fee);
    IFlashLoanRecipient(recipient).receiveFlashLoan(token, amount, amountDue, data);
    uint256 balEnd = IERC20(token).balanceOf(address(this));
    require(
      balEnd > balStart && balEnd >= amountDue,
      "IP"
    );
    record.balance = balEnd;
    // If the payment brings the token above its minimum balance,
    // clear the minimum and mark the token as ready.
    if (!record.ready) {
      uint256 minimumBalance = _minimumBalances[token];
      if (balEnd >= minimumBalance) {
        _minimumBalances[token] = 0;
        record.ready = true;
        emit LOG_TOKEN_READY(token);
        uint256 additionalBalance = bsub(balEnd, minimumBalance);
        uint256 balRatio = bdiv(additionalBalance, minimumBalance);
        uint96 newDenorm = uint96(badd(MIN_WEIGHT, bmul(MIN_WEIGHT, balRatio)));
        record.denorm = newDenorm;
        record.lastDenormUpdate = uint40(block.timestamp);
        _totalWeight = badd(_totalWeight, newDenorm);
        emit LOG_DENORM_UPDATED(token, record.denorm);
      }
    }
  }

/* ==========  Token Swaps  ========== */

  // IP_TS_1.1
  function swapExactAmountIn(
    address tokenIn,
    uint256 tokenAmountIn,
    address tokenOut,
    uint256 minAmountOut,
    uint256 maxPrice
  )
    external
    override
    _lock_
    _public_
    returns (uint256/* tokenAmountOut */, uint256/* spotPriceAfter */)
  {
    (Record memory inRecord, uint256 realInBalance) = _getInputToken(tokenIn);
    Record memory outRecord = _getOutputToken(tokenOut);

    require(
      tokenAmountIn <= bmul(inRecord.balance, MAX_IN_RATIO),
      "MIR"
    );

    uint256 spotPriceBefore = calcSpotPrice(
      inRecord.balance,
      inRecord.denorm,
      outRecord.balance,
      outRecord.denorm,
      _swapFee
    );
    require(spotPriceBefore <= maxPrice, "BLP");

    uint256 tokenAmountOut = calcOutGivenIn(
      inRecord.balance,
      inRecord.denorm,
      outRecord.balance,
      outRecord.denorm,
      tokenAmountIn,
      _swapFee
    );

    require(tokenAmountOut >= minAmountOut, "LO");

    _pullUnderlying(tokenIn, msg.sender, tokenAmountIn);
    _pushUnderlying(tokenOut, msg.sender, tokenAmountOut);

    realInBalance = badd(realInBalance, tokenAmountIn);
    _updateInputToken(tokenIn, inRecord, realInBalance);
    if (inRecord.ready) {
      inRecord.balance = realInBalance;
    }
    // Update the in-memory record for the spotPriceAfter calculation,
    // then update the storage record with the local balance.
    outRecord.balance = bsub(outRecord.balance, tokenAmountOut);
    _records[tokenOut].balance = outRecord.balance;
    // If needed, update the output token's weight.
    _decreaseDenorm(outRecord, tokenOut);

    uint256 spotPriceAfter = calcSpotPrice(
      inRecord.balance,
      inRecord.denorm,
      outRecord.balance,
      outRecord.denorm,
      _swapFee
    );

    require(spotPriceAfter >= spotPriceBefore, "MA2");
    require(spotPriceAfter <= maxPrice, "LP");
    require(
      spotPriceBefore <= bdiv(tokenAmountIn, tokenAmountOut),
      "MA"
    );

    emit LOG_SWAP(msg.sender, tokenIn, tokenOut, tokenAmountIn, tokenAmountOut);

    return (tokenAmountOut, spotPriceAfter);
  }

  // IP_TS_1.2
  function swapExactAmountOut(
    address tokenIn,
    uint256 maxAmountIn,
    address tokenOut,
    uint256 tokenAmountOut,
    uint256 maxPrice
  )
    external
    override
    _lock_
    _public_
    returns (uint256 /* tokenAmountIn */, uint256 /* spotPriceAfter */)
  {
    (Record memory inRecord, uint256 realInBalance) = _getInputToken(tokenIn);
    Record memory outRecord = _getOutputToken(tokenOut);

    require(
      tokenAmountOut <= bmul(outRecord.balance, MAX_OUT_RATIO),
      "MOR"
    );

    uint256 spotPriceBefore = calcSpotPrice(
      inRecord.balance,
      inRecord.denorm,
      outRecord.balance,
      outRecord.denorm,
      _swapFee
    );
    require(spotPriceBefore <= maxPrice, "BLP");

    uint256 tokenAmountIn = calcInGivenOut(
      inRecord.balance,
      inRecord.denorm,
      outRecord.balance,
      outRecord.denorm,
      tokenAmountOut,
      _swapFee
    );

    require(tokenAmountIn <= maxAmountIn, "LI");

    _pullUnderlying(tokenIn, msg.sender, tokenAmountIn);
    _pushUnderlying(tokenOut, msg.sender, tokenAmountOut);

    // Update the balance and (if necessary) weight of the input token.
    realInBalance = badd(realInBalance, tokenAmountIn);
    _updateInputToken(tokenIn, inRecord, realInBalance);
    if (inRecord.ready) {
      inRecord.balance = realInBalance;
    }
    // Update the in-memory record for the spotPriceAfter calculation,
    // then update the storage record with the local balance.
    outRecord.balance = bsub(outRecord.balance, tokenAmountOut);
    _records[tokenOut].balance = outRecord.balance;
    // If needed, update the output token's weight.
    _decreaseDenorm(outRecord, tokenOut);

    uint256 spotPriceAfter = calcSpotPrice(
      inRecord.balance,
      inRecord.denorm,
      outRecord.balance,
      outRecord.denorm,
      _swapFee
    );

    require(spotPriceAfter >= spotPriceBefore, "MA");
    require(spotPriceAfter <= maxPrice, "LP");
    require(
      spotPriceBefore <= bdiv(tokenAmountIn, tokenAmountOut),
      "MA"
    );

    emit LOG_SWAP(msg.sender, tokenIn, tokenOut, tokenAmountIn, tokenAmountOut);

    return (tokenAmountIn, spotPriceAfter);
  }

/* ==========  Config Queries  ========== */

  function oracle() external view override returns (address) {
    return _oracle;
  }

  function router() external view override returns (address) {
    return _router;
  }

  // IP_CQ_1.1
  function isPublicSwap() external view override returns (bool) {
    return _publicSwap;
  }

  // IP_CQ_1.2
  function getSwapFee() external view override returns (uint256/* swapFee */) {
    return _swapFee;
  }

  // IP_CQ_1.3
  function getExitFee() external view override  returns (uint256/* exitFee */) {
    return EXIT_FEE;
  }

  // IP_CQ_1.4
  function getController() external view override returns (address)
  {
    return _controller;
  }

/* ==========  Token Queries  ========== */
  function getMaxPoolTokens() external view override returns (uint256) {
    return _maxPoolTokens;
  }

  // IP_TQ_1.1
  function isBound(address t) external view override returns (bool) {
    return _records[t].bound;
  }

  // IP_TQ_1.2
  function getNumTokens() external view override returns (uint256) {
    return _tokens.length;
  }

  // IP_TQ_1.3
  function getCurrentTokens()
    external
    view
    override
    _viewlock_
    returns (address[] memory tokens)
  {
    tokens = _tokens;
  }

 // IP_TQ_1.4
  function getCurrentDesiredTokens()
    external
    view
    override
    _viewlock_
    returns (address[] memory tokens)
  {
    address[] memory tempTokens = _tokens;
    tokens = new address[](tempTokens.length);
    uint256 usedIndex = 0;
    for (uint256 i = 0; i < tokens.length; i++) {
      address token = tempTokens[i];
      if (_records[token].desiredDenorm > 0) {
        tokens[usedIndex++] = token;
      }
    }
    assembly { mstore(tokens, usedIndex) }
  }

  // IP_TQ_1.5
  function getDenormalizedWeight(address token)
    external
    view
    override
    _viewlock_
    returns (uint256/* denorm */)
  {
    require(_records[token].bound, "NB");
    return _records[token].denorm;
  }

  // IP_TQ_1.6
  function getTokenRecord(address token)
    external
    view
    override
    _viewlock_
    returns (Record memory record)
  {
    record = _records[token];
    require(record.bound, "NB");
  }

  // IP_TQ_1.7
  function extrapolatePoolValueFromToken()
    external
    view
    override
    _viewlock_
    returns (address/* token */, uint256/* extrapolatedValue */)
  {
    address token;
    uint256 extrapolatedValue;
    uint256 len = _tokens.length;
    for (uint256 i = 0; i < len; i++) {
      token = _tokens[i];
      Record storage record = _records[token];
      if (record.ready && record.desiredDenorm > 0) {
        extrapolatedValue = bmul(
          record.balance,
          bdiv(_totalWeight, record.denorm)
        );
        break;
      }
    }
    require(extrapolatedValue > 0, "NR");
    return (token, extrapolatedValue);
  }

  // IP_TQ_1.8
  function getTotalDenormalizedWeight()
    external
    view
    override
    _viewlock_
    returns (uint256)
  {
    return _totalWeight;
  }

  // IP_TQ_1.9
  function getBalance(address token) external view override _viewlock_ returns (uint256) {
    Record storage record = _records[token];
    require(record.bound, "NB");
    return record.balance;
  }

  // IP_TQ_1.10
  function getMinimumBalance(address token) external view override _viewlock_ returns (uint256) {
    Record memory record = _records[token];
    require(record.bound, "NB");
    require(!record.ready, "R");
    return _minimumBalances[token];
  }

  // IP_TQ_1.11
  function getUsedBalance(address token) external view override _viewlock_ returns (uint256) {
    Record memory record = _records[token];
    require(record.bound, "NB");
    if (!record.ready) {
      return _minimumBalances[token];
    }
    return record.balance;
  }

/* ==========  Price Queries  ========== */
  // IP_PQ_1.1
  function getSpotPrice(address tokenIn, address tokenOut)
    external
    view
    override
    _viewlock_
    returns (uint256)
  {
    (Record memory inRecord,) = _getInputToken(tokenIn);
    Record memory outRecord = _getOutputToken(tokenOut);
    return
      calcSpotPrice(
        inRecord.balance,
        inRecord.denorm,
        outRecord.balance,
        outRecord.denorm,
        _swapFee
      );
  }

/* ==========  Pool Share Internal Functions  ========== */

  function _pullPoolShare(address from, uint256 amount) internal {
    _pull(from, amount);
  }

  function _pushPoolShare(address to, uint256 amount) internal {
    _push(to, amount);
  }

  function _mintPoolShare(uint256 amount) internal {
    _mint(amount);
  }

  function _burnPoolShare(uint256 amount) internal {
    _burn(amount);
  }

/* ==========  Underlying Token Internal Functions  ========== */
  // 'Underlying' token-manipulation functions make external calls but are NOT locked
  // You must `_lock_` or otherwise ensure reentry-safety

  function _pullUnderlying(
    address erc20,
    address from,
    uint256 amount
  ) internal {
    (bool success, bytes memory data) = erc20.call(
      abi.encodeWithSelector(
        IERC20.transferFrom.selector,
        from,
        address(this),
        amount
      )
    );
    require(
      success && (data.length == 0 || abi.decode(data, (bool))),
      "ERC20_FALSE"
    );
  }

  function _pushUnderlying(
    address erc20,
    address to,
    uint256 amount
  ) internal {
    (bool success, bytes memory data) = erc20.call(
      abi.encodeWithSelector(
        IERC20.transfer.selector,
        to,
        amount
      )
    );
    require(
      success && (data.length == 0 || abi.decode(data, (bool))),
      "ERC20_FALSE"
    );
  }

/* ==========  Token Management Internal Functions  ========== */

  // IP_TMIF_1.1
  function _bind(
    address token,
    uint256 minimumBalance,
    uint96 desiredDenorm
  ) internal {
    require(!_records[token].bound, "IS_BOUND");

    require(desiredDenorm >= MIN_WEIGHT, "MW");
    require(desiredDenorm <= MAX_WEIGHT, "MXW");
    require(minimumBalance >= MIN_BALANCE, "MB");

    _records[token] = Record({
      bound: true,
      ready: false,
      lastDenormUpdate: 0,
      denorm: 0,
      desiredDenorm: desiredDenorm,
      index: uint8(_tokens.length),
      balance: 0
    });
    _tokens.push(token);
    _minimumBalances[token] = minimumBalance;
    emit LOG_TOKEN_ADDED(token, desiredDenorm, minimumBalance);
  }

  // IP_TMIF_1.2
  function _unbind(address token) internal {
    Record memory record = _records[token];
    uint256 tokenBalance = record.balance;

    // Swap the token-to-unbind with the last token,
    // then delete the last token
    uint256 index = record.index;
    uint256 last = _tokens.length - 1;
    // Only swap the token with the last token if it is not
    // already at the end of the array.
    if (index != last) {
      _tokens[index] = _tokens[last];
      _records[_tokens[index]].index = uint8(index);
    }
    _tokens.pop();
    _records[token] = Record({
      bound: false,
      ready: false,
      lastDenormUpdate: 0,
      denorm: 0,
      desiredDenorm: 0,
      index: 0,
      balance: 0
    });
    // transfer any remaining tokens out
    _pushUnderlying(token, address(_unbindHandler), tokenBalance);
    _unbindHandler.handleUnbindToken(token, tokenBalance);
    emit LOG_TOKEN_REMOVED(token);
  }

  function _setDesiredDenorm(address token, uint96 desiredDenorm) internal {
    Record storage record = _records[token];
    require(record.bound, "NB");
    // If the desired weight is 0, this will trigger a gradual unbinding of the token.
    // Therefore the weight only needs to be above the minimum weight if it isn't 0.
    require(
      desiredDenorm >= MIN_WEIGHT || desiredDenorm == 0,
      "MW"
    );
    require(desiredDenorm <= MAX_WEIGHT, "MXW");
    record.desiredDenorm = desiredDenorm;
    emit LOG_DESIRED_DENORM_SET(token, desiredDenorm);
  }

  function _increaseDenorm(Record memory record, address token) internal {
    // If the weight does not need to increase or the token is not
    // initialized, don't do anything.
    if (
      record.denorm >= record.desiredDenorm ||
      !record.ready ||
      block.timestamp - record.lastDenormUpdate < WEIGHT_UPDATE_DELAY
    ) return;
    uint96 oldWeight = record.denorm;
    uint96 denorm = record.desiredDenorm;
    uint256 maxDiff = bmul(oldWeight, WEIGHT_CHANGE_PCT);
    uint256 diff = bsub(denorm, oldWeight);
    if (diff > maxDiff) {
      denorm = uint96(badd(oldWeight, maxDiff));
      diff = maxDiff;
    }
    _totalWeight = badd(_totalWeight, diff);
    require(_totalWeight <= MAX_TOTAL_WEIGHT, "MTW");
    // Update the in-memory denorm value for spot-price computations.
    record.denorm = denorm;
    // Update the storage record
    _records[token].denorm = denorm;
    _records[token].lastDenormUpdate = uint40(block.timestamp);
    emit LOG_DENORM_UPDATED(token, denorm);
  }

  function _decreaseDenorm(Record memory record, address token) internal {
    // If the weight does not need to decrease, don't do anything.
    if (
      record.denorm <= record.desiredDenorm ||
      !record.ready ||
      block.timestamp - record.lastDenormUpdate < WEIGHT_UPDATE_DELAY
    ) return;
    uint96 oldWeight = record.denorm;
    uint96 denorm = record.desiredDenorm;
    uint256 maxDiff = bmul(oldWeight, WEIGHT_CHANGE_PCT);
    uint256 diff = bsub(oldWeight, denorm);
    if (diff > maxDiff) {
      denorm = uint96(bsub(oldWeight, maxDiff));
      diff = maxDiff;
    }
    if (denorm <= MIN_WEIGHT) {
      denorm = 0;
      _totalWeight = bsub(_totalWeight, denorm);
      // Because this is removing the token from the pool, the
      // in-memory denorm value is irrelevant, as it is only used
      // to calculate the new spot price, but the spot price calc
      // will throw if it is passed 0 for the denorm.
      _unbind(token);
    } else {
      _totalWeight = bsub(_totalWeight, diff);
      // Update the in-memory denorm value for spot-price computations.
      record.denorm = denorm;
      // Update the stored denorm value
      _records[token].denorm = denorm;
      _records[token].lastDenormUpdate = uint40(block.timestamp);
      emit LOG_DENORM_UPDATED(token, denorm);
    }
  }

  // IP_TMIF_1.3
  function _updateInputToken(
    address token,
    Record memory record,
    uint256 realBalance
  )
    internal
  {
    if (!record.ready) {
      // Check if the minimum balance has been reached
      if (realBalance >= record.balance) {
        // Remove the minimum balance record
        _minimumBalances[token] = 0;
        // Mark the token as initialized
        _records[token].ready = true;
        record.ready = true;
        emit LOG_TOKEN_READY(token);
        // Set the initial denorm value to the minimum weight times one plus
        // the ratio of the increase in balance over the minimum to the minimum
        // balance.
        // weight = (1 + ((bal - min_bal) / min_bal)) * min_weight
        uint256 additionalBalance = bsub(realBalance, record.balance);
        uint256 balRatio = bdiv(additionalBalance, record.balance);
        record.denorm = uint96(badd(MIN_WEIGHT, bmul(MIN_WEIGHT, balRatio)));
        _records[token].denorm = record.denorm;
        _records[token].lastDenormUpdate = uint40(block.timestamp);
        _totalWeight = badd(_totalWeight, record.denorm);
        emit LOG_DENORM_UPDATED(token, record.denorm);
      } else {
        uint256 realToMinRatio = bdiv(
          bsub(record.balance, realBalance),
          record.balance
        );
        uint256 weightPremium = bmul(MIN_WEIGHT / 10, realToMinRatio);
        record.denorm = uint96(badd(MIN_WEIGHT, weightPremium));
      }
      // If the token is still not ready, do not adjust the weight.
    } else {
      // If the token is already initialized, update the weight (if any adjustment
      // is needed).
      _increaseDenorm(record, token);
    }
    // Regardless of whether the token is initialized, store the actual new balance.
    _records[token].balance = realBalance;
  }

/* ==========  Token Query Internal Functions  ========== */

  // IP_TQIF_1.1
  function _getInputToken(address token)
    internal
    view
    returns (Record memory record, uint256 realBalance)
  {
    record = _records[token];
    require(record.bound, "NB");

    realBalance = record.balance;
    // If the input token is not initialized, we use the minimum
    // initial weight and minimum initial balance instead of the
    // real values for price and output calculations.
    if (!record.ready) {
      record.balance = _minimumBalances[token];
      uint256 realToMinRatio = bdiv(
        bsub(record.balance, realBalance),
        record.balance
      );
      uint256 weightPremium = bmul(MIN_WEIGHT / 10, realToMinRatio);
      record.denorm = uint96(badd(MIN_WEIGHT, weightPremium));
    }
  }

  function _getOutputToken(address token)
    internal
    view
    returns (Record memory record)
  {
    record = _records[token];
    require(record.bound, "NB");
    // Tokens which have not reached their minimum balance can not be
    // swapped out.
    require(record.ready, "ONR");
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;


interface ICompLikeToken {
  function delegate(address delegatee) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

interface IFlashLoanRecipient {
  function receiveFlashLoan(
    address tokenBorrowed,
    uint256 amountBorrowed,
    uint256 amountDue,
    bytes calldata data
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;
pragma experimental ABIEncoderV2;


interface IIndexPool {
  /**
   * @dev Token record data structure
   * @param bound is token bound to pool
   * @param ready has token been initialized
   * @param lastDenormUpdate timestamp of last denorm change
   * @param denorm denormalized weight
   * @param desiredDenorm desired denormalized weight (used for incremental changes)
   * @param index index of address in tokens array
   * @param balance token balance
   */
  struct Record {
    bool bound;
    bool ready;
    uint40 lastDenormUpdate;
    uint96 denorm;
    uint96 desiredDenorm;
    uint8 index;
    uint256 balance;
  }

  function configure(
    address controller,
    string calldata name,
    string calldata symbol,
    address uniswapV2oracle,
    address uniswapV2router,
    address exitFeeReciver,
    address exitFeeReciverAdditional
  ) external;

  function initialize(
    address[] calldata tokens,
    uint256[] calldata balances,
    uint96[] calldata denorms,
    address tokenProvider,
    address unbindHandler
  ) external;

  function setMaxPoolTokens(uint256 maxPoolTokens) external;

  function delegateCompLikeToken(address token, address delegatee) external;

  function setExitFeeRecipient(address exitFeeRecipient, bool additional) external;

  function reweighTokens(
    address[] calldata tokens,
    uint96[] calldata desiredDenorms
  ) external;

  function reindexTokens(
    address[] calldata tokens,
    uint96[] calldata desiredDenorms,
    uint256[] calldata minimumBalances
  ) external;

  function setMinimumBalance(address token, uint256 minimumBalance) external;

  function joinPool(uint256 poolAmountOut, uint256[] calldata maxAmountsIn) external;

  function joinswapExternAmountIn(
    address tokenIn,
    uint256 tokenAmountIn,
    uint256 minPoolAmountOut
  ) external returns (uint256/* poolAmountOut */);

  function joinswapPoolAmountOut(
    address tokenIn,
    uint256 poolAmountOut,
    uint256 maxAmountIn
  ) external returns (uint256/* tokenAmountIn */);

  function exitPool(uint256 poolAmountIn, uint256[] calldata minAmountsOut) external;

  function exitswapPoolAmountIn(
    address tokenOut,
    uint256 poolAmountIn,
    uint256 minAmountOut
  )
    external returns (uint256/* tokenAmountOut */);

  function exitswapExternAmountOut(
    address tokenOut,
    uint256 tokenAmountOut,
    uint256 maxPoolAmountIn
  ) external returns (uint256/* poolAmountIn */);

  function gulp(address token) external;

  function flashBorrow(
    address recipient,
    address token,
    uint256 amount,
    bytes calldata data
  ) external;

  function swapExactAmountIn(
    address tokenIn,
    uint256 tokenAmountIn,
    address tokenOut,
    uint256 minAmountOut,
    uint256 maxPrice
  ) external returns (uint256/* tokenAmountOut */, uint256/* spotPriceAfter */);

  function swapExactAmountOut(
    address tokenIn,
    uint256 maxAmountIn,
    address tokenOut,
    uint256 tokenAmountOut,
    uint256 maxPrice
  ) external returns (uint256 /* tokenAmountIn */, uint256 /* spotPriceAfter */);

  function oracle() external view returns (address);

  function router() external view returns (address);

  function isPublicSwap() external view returns (bool);

  function getSwapFee() external view returns (uint256/* swapFee */);

  function getController() external view returns (address);

  function getMaxPoolTokens() external view returns (uint256);

  function isBound(address t) external view returns (bool);

  function getNumTokens() external view returns (uint256);

  function getCurrentTokens() external view returns (address[] memory tokens);

  function getCurrentDesiredTokens() external view returns (address[] memory tokens);

  function getDenormalizedWeight(address token) external view returns (uint256/* denorm */);

  function getTokenRecord(address token) external view returns (Record memory record);

  function extrapolatePoolValueFromToken() external view returns (address/* token */, uint256/* extrapolatedValue */);

  function getTotalDenormalizedWeight() external view returns (uint256);

  function getBalance(address token) external view returns (uint256);

  function getMinimumBalance(address token) external view returns (uint256);

  function getUsedBalance(address token) external view returns (uint256);

  function getSpotPrice(address tokenIn, address tokenOut) external view returns (uint256);

  function getExitFee() external view returns (uint256/* exitFee */);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

interface ITokenUnbindHandler {
  /**
   * @dev Receive `amount` of `token` from the pool.
   */
  function handleUnbindToken(address token, uint256 amount) external;
}

