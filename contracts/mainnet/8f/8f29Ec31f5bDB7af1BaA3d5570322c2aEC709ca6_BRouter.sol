// SPDX-License-Identifier: MIT
pragma solidity >=0.6.6;

import "./IBFactory.sol";
import "./interfaces/IERC20.sol";
import "./BMath.sol";

/// @author Oiler Network
/// @title Balancer BPools Router
/// @notice Allows to route swaps and set approvals only once on behalf of the router
/// @notice Manages providing liquidity when a given pair does not exist
contract BRouter is BMath {
    uint256 constant MAX_UINT = 2**256 - 1;

    /// @dev Address of bFactory
    address public immutable factory;

    /// @dev Maps pairs to pools
    mapping(address => mapping(address => address)) public getPool;

    /// @dev Stores address of every created pool
    address[] public allPools;

    /// @dev Stores pool initial liquidity providers
    mapping(address => address) public initialLiquidityProviders;

    /// @dev Ensures tx is included in block no after deadline.
    modifier ensure(uint256 deadline) {
        require(deadline >= block.timestamp, "DEADLINE EXPIRED");
        _;
    }

    constructor(address _factory) public {
        factory = _factory;
    }

    // **** ADD LIQUIDITY ****
    /// @dev Adds liquidity to an existing pool or creates a new one if it's not existing
    function addLiquidity(
        address tokenA, // Option
        address tokenB, // Collateral
        uint256 amountA, // Amount of Options to add to liquidity
        uint256 amountB // Amount of Collateral to add to liquidity
    ) external returns (uint256 poolTokens) {
        address poolAddress = getPool[tokenA][tokenB];
        IBPool pool;
        require(IERC20(tokenA).transferFrom(msg.sender, address(this), amountA), "Token A transfer failed");
        require(IERC20(tokenB).transferFrom(msg.sender, address(this), amountB), "Token B transfer failed");

        // Create the pool if it doesn't exist yet
        // currently anyone can create a pool
        if (poolAddress == address(0)) {
            pool = IBFactory(factory).newBPool();
            initialLiquidityProviders[address(pool)] = msg.sender;
            IERC20(tokenA).approve(address(pool), MAX_UINT); // Approve maximum amount of tokens to the pool
            IERC20(tokenB).approve(address(pool), MAX_UINT); // TODO: This needs to be investigated for security
            pool.bind(tokenA, amountA, BONE);
            pool.bind(tokenB, amountB, BONE);
            pool.setSwapFee(0.05 * 1e18); // 5% fee
            pool.finalize();
            addPool(tokenA, tokenB, address(pool)); // Add pool to the pool registry
        } else {
            // Add liquidity to existing pool by join()
            pool = IBPool(poolAddress);
            uint256 poolTokensA = pool.getBalance(tokenA);
            uint256 poolTokensB = pool.getBalance(tokenB);
            uint256 ratioTokenA = bdiv(amountA, poolTokensA);
            uint256 ratioTokenB = bdiv(amountB, poolTokensB);
            uint256 poolAmountOut = bmul(pool.totalSupply(), min(ratioTokenA, ratioTokenB));
            poolAmountOut = bmul(poolAmountOut, 0.99999999 * 1e18);
            uint256[] memory maxAmountsIn = new uint256[](2);
            maxAmountsIn[0] = amountA;
            maxAmountsIn[1] = amountB;
            pool.joinPool(poolAmountOut, maxAmountsIn);
        }
        // Transfer pool liquidity tokens to msg.sender
        uint256 collected = pool.balanceOf(address(this));
        require(pool.transfer(msg.sender, collected), "ERR_ERC20_FAILED");

        uint256 stuckAmountA = IERC20(tokenA).balanceOf(address(this));
        uint256 stuckAmountB = IERC20(tokenB).balanceOf(address(this));

        require(IERC20(tokenA).transfer(msg.sender, stuckAmountA), "ERR_ERC20_FAILED");
        require(IERC20(tokenB).transfer(msg.sender, stuckAmountB), "ERR_ERC20_FAILED");

        return collected;
    }

    // **** REMOVE LIQUIDITY ****
    /// @dev Removes liquidity
    function removeLiquidity(
        address tokenA, // Option
        address tokenB, // Collateral
        uint256 poolAmountIn // Amount of pool share tokens to give up
    ) external returns (uint256[] memory amounts) {
        IBPool pool = IBPool(getPool[tokenA][tokenB]);
        pool.transferFrom(msg.sender, address(this), poolAmountIn);
        pool.approve(address(pool), poolAmountIn);

        if (bsub(pool.totalSupply(), poolAmountIn) == 0) {
            require(msg.sender == initialLiquidityProviders[address(pool)]);
        }

        uint256[] memory minAmountsOut = new uint256[](2);
        minAmountsOut[0] = 0;
        minAmountsOut[1] = 0;
        pool.exitPool(poolAmountIn, minAmountsOut);

        // Transfer pool tokens back to msg.sender
        amounts = new uint256[](2);
        amounts[0] = IERC20(tokenA).balanceOf(address(this));
        amounts[1] = IERC20(tokenB).balanceOf(address(this));
        require(IERC20(tokenA).transfer(msg.sender, amounts[0]), "ERR_ERC20_FAILED");
        require(IERC20(tokenB).transfer(msg.sender, amounts[1]), "ERR_ERC20_FAILED");
    }

    /// @dev Swaps tokens
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256 tokenAmountOut, uint256 spotPriceAfter) {
        return _swapExactTokensForTokens(amountIn, amountOutMin, path, to, deadline, MAX_UINT);
    }

    /// @dev Swaps tokens and ensures price did not exceed maxPrice
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline,
        uint256 maxPrice
    ) external returns (uint256 tokenAmountOut, uint256 spotPriceAfter) {
        return _swapExactTokensForTokens(amountIn, amountOutMin, path, to, deadline, maxPrice);
    }

    /// @dev Gets the token amounts held bPool specified by it's address
    function getReserves(address poolAddress) external view returns (uint256[] memory reserves) {
        IBPool pool = IBPool(poolAddress);
        address[] memory tokens = pool.getCurrentTokens();
        reserves = new uint256[](2);
        reserves[0] = pool.getBalance(tokens[0]);
        reserves[1] = pool.getBalance(tokens[1]);
        return reserves;
    }

    /// @dev Gets the token amounts held bPool specified by it's tokens
    function getReserves(address tokenA, address tokenB) external view returns (uint256[] memory reserves) {
        IBPool pool = getPoolByTokens(tokenA, tokenB);
        reserves = new uint256[](2);
        reserves[0] = pool.getBalance(tokenA);
        reserves[1] = pool.getBalance(tokenB);
        return reserves;
    }

    /// @dev Gets token price in bPool sans fee
    function getSpotPriceSansFee(address tokenA, address tokenB) external view returns (uint256 quote) {
        IBPool pool = getPoolByTokens(tokenA, tokenB);
        return pool.getSpotPriceSansFee(tokenA, tokenB);
    }

    /// @dev Gets token price in bPool with fee
    function getSpotPriceWithFee(address tokenA, address tokenB) external view returns (uint256 amountOut) {
        IBPool pool = getPoolByTokens(tokenA, tokenB);
        return pool.getSpotPrice(tokenA, tokenB);
    }

    /// @dev Return the bPool tokens held by a specific address together with their total supply
    function getPoolShare(
        address tokenA,
        address tokenB,
        address owner
    ) external view returns (uint256 tokens, uint256 poolTokens) {
        IBPool pool = getPoolByTokens(tokenA, tokenB);
        tokens = pool.balanceOf(owner);
        poolTokens = pool.totalSupply();
    }

    /// @dev Calculates the approximate amount out of tokens after swapping them.
    function getAmountOut(
        uint256 amountIn,
        address tokenIn,
        address tokenOut
    ) external view returns (uint256 amountOut) {
        IBPool pool = getPoolByTokens(tokenIn, tokenOut);
        return
            calcOutGivenIn(
                pool.getBalance(tokenIn),
                pool.getDenormalizedWeight(tokenIn),
                pool.getBalance(tokenOut),
                pool.getDenormalizedWeight(tokenOut),
                amountIn,
                pool.getSwapFee()
            );
    }

    /// @dev Calculates the approximate amount in of tokens after swapping them.
    function getAmountIn(
        uint256 amountOut,
        address tokenIn,
        address tokenOut
    ) external view returns (uint256 amountIn) {
        IBPool pool = getPoolByTokens(tokenIn, tokenOut);
        return
            calcInGivenOut(
                pool.getBalance(tokenIn),
                pool.getDenormalizedWeight(tokenIn),
                pool.getBalance(tokenOut),
                pool.getDenormalizedWeight(tokenOut),
                amountOut,
                pool.getSwapFee()
            );
    }

    /// @dev Returns fee amount of specific token pair pool.
    function getSwapFee(address tokenA, address tokenB) external view returns (uint256 fee) {
        IBPool pool = getPoolByTokens(tokenA, tokenB);
        return pool.getSwapFee();
    }

    function getSwapFee(address poolAddress) external view returns (uint256 fee) {
        return IBPool(poolAddress).getSwapFee();
    }

    /// @dev Queries mapped pairs and reverts if pair does not exist
    function getPoolByTokens(address tokenA, address tokenB) public view returns (IBPool pool) {
        address poolAddress = getPool[tokenA][tokenB];
        require(poolAddress != address(0), "Pool doesn't exist");
        return IBPool(poolAddress);
    }

    /// @dev return the number of existing pools
    function getAllPoolsLength() public view returns (uint256) {
        return allPools.length;
    }

    /// @dev Returns the smallest of two numbers.
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    // Add pool to Registry
    function addPool(
        address tokenA,
        address tokenB,
        address poolAddress
    ) internal {
        getPool[tokenA][tokenB] = poolAddress;
        getPool[tokenB][tokenA] = poolAddress; // populate mapping in the reverse direction
        allPools.push(poolAddress);
    }

    function _swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline,
        uint256 maxPrice
    ) internal ensure(deadline) returns (uint256 tokenAmountOut, uint256 spotPriceAfter) {
        IBPool pool = getPoolByTokens(path[0], path[1]);
        IERC20(path[0]).transferFrom(msg.sender, address(this), amountIn);

        (tokenAmountOut, spotPriceAfter) = pool.swapExactAmountIn(path[0], amountIn, path[1], amountOutMin, maxPrice);

        uint256 amount = IERC20(path[1]).balanceOf(address(this)); // Think if we should use tokenAmountOut
        require(IERC20(path[1]).transfer(to, amount), "ERR_ERC20_FAILED");
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.6.12;

import "./IBPool.sol";

interface IBFactory {
    function newBPool() external returns (IBPool);

    function setBLabs(address b) external;

    function collect(IBPool pool) external;

    function isBPool(address b) external view returns (bool);

    function getBLabs() external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.6.12;

// Interface declarations

/* solhint-disable func-order */

interface IERC20 {
    // Emitted when the allowance of a spender for an owner is set by a call to approve.
    // Value is the new allowance
    event Approval(address indexed owner, address indexed spender, uint256 value);

    // Emitted when value tokens are moved from one account (from) to another (to).
    // Note that value may be zero
    event Transfer(address indexed from, address indexed to, uint256 value);

    // Returns the amount of tokens in existence
    function totalSupply() external view returns (uint256);

    // Returns the amount of tokens owned by account
    function balanceOf(address account) external view returns (uint256);

    // Returns the remaining number of tokens that spender will be allowed to spend on behalf of owner
    // through transferFrom. This is zero by default
    // This value changes when approve or transferFrom are called
    function allowance(address owner, address spender) external view returns (uint256);

    // Sets amount as the allowance of spender over the caller’s tokens
    // Returns a boolean value indicating whether the operation succeeded
    // Emits an Approval event.
    function approve(address spender, uint256 amount) external returns (bool);

    // Moves amount tokens from the caller’s account to recipient
    // Returns a boolean value indicating whether the operation succeeded
    // Emits a Transfer event.
    function transfer(address recipient, uint256 amount) external returns (bool);

    // Moves amount tokens from sender to recipient using the allowance mechanism
    // Amount is then deducted from the caller’s allowance
    // Returns a boolean value indicating whether the operation succeeded
    // Emits a Transfer event
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.6.6;

import "./BNum.sol";

contract BMath is BBronze, BConst, BNum {
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
        uint256 tokenBalanceIn,
        uint256 tokenWeightIn,
        uint256 tokenBalanceOut,
        uint256 tokenWeightOut,
        uint256 swapFee
    ) public pure returns (uint256 spotPrice) {
        uint256 numer = bdiv(tokenBalanceIn, tokenWeightIn);
        uint256 denom = bdiv(tokenBalanceOut, tokenWeightOut);
        uint256 ratio = bdiv(numer, denom);
        uint256 scale = bdiv(BONE, bsub(BONE, swapFee));
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
        uint256 tokenBalanceIn,
        uint256 tokenWeightIn,
        uint256 tokenBalanceOut,
        uint256 tokenWeightOut,
        uint256 tokenAmountIn,
        uint256 swapFee
    ) public pure returns (uint256 tokenAmountOut) {
        uint256 weightRatio = bdiv(tokenWeightIn, tokenWeightOut);
        uint256 adjustedIn = bsub(BONE, swapFee);
        adjustedIn = bmul(tokenAmountIn, adjustedIn);
        uint256 y = bdiv(tokenBalanceIn, badd(tokenBalanceIn, adjustedIn));
        uint256 foo = bpow(y, weightRatio);
        uint256 bar = bsub(BONE, foo);
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
        uint256 tokenBalanceIn,
        uint256 tokenWeightIn,
        uint256 tokenBalanceOut,
        uint256 tokenWeightOut,
        uint256 tokenAmountOut,
        uint256 swapFee
    ) public pure returns (uint256 tokenAmountIn) {
        uint256 weightRatio = bdiv(tokenWeightOut, tokenWeightIn);
        uint256 diff = bsub(tokenBalanceOut, tokenAmountOut);
        uint256 y = bdiv(tokenBalanceOut, diff);
        uint256 foo = bpow(y, weightRatio);
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
        uint256 tokenBalanceIn,
        uint256 tokenWeightIn,
        uint256 poolSupply,
        uint256 totalWeight,
        uint256 tokenAmountIn,
        uint256 swapFee
    ) public pure returns (uint256 poolAmountOut) {
        // Charge the trading fee for the proportion of tokenAi
        // which is implicitly traded to the other pool tokens.
        // That proportion is (1- weightTokenIn)
        // tokenAiAfterFee = tAi * (1 - (1-weightTi) * poolFee);
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
        uint256 tokenBalanceIn,
        uint256 tokenWeightIn,
        uint256 poolSupply,
        uint256 totalWeight,
        uint256 poolAmountOut,
        uint256 swapFee
    ) public pure returns (uint256 tokenAmountIn) {
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
        uint256 tokenBalanceOut,
        uint256 tokenWeightOut,
        uint256 poolSupply,
        uint256 totalWeight,
        uint256 poolAmountIn,
        uint256 swapFee
    ) public pure returns (uint256 tokenAmountOut) {
        uint256 normalizedWeight = bdiv(tokenWeightOut, totalWeight);
        // charge exit fee on the pool token side
        // pAiAfterExitFee = pAi*(1-exitFee)
        uint256 poolAmountInAfterExitFee = bmul(poolAmountIn, bsub(BONE, EXIT_FEE));
        uint256 newPoolSupply = bsub(poolSupply, poolAmountInAfterExitFee);
        uint256 poolRatio = bdiv(newPoolSupply, poolSupply);

        // newBalTo = poolRatio^(1/weightTo) * balTo;
        uint256 tokenOutRatio = bpow(poolRatio, bdiv(BONE, normalizedWeight));
        uint256 newTokenBalanceOut = bmul(tokenOutRatio, tokenBalanceOut);

        uint256 tokenAmountOutBeforeSwapFee = bsub(tokenBalanceOut, newTokenBalanceOut);

        // charge swap fee on the output token side
        //uint tAo = tAoBeforeSwapFee * (1 - (1-weightTo) * swapFee)
        uint256 zaz = bmul(bsub(BONE, normalizedWeight), swapFee);
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
        uint256 tokenBalanceOut,
        uint256 tokenWeightOut,
        uint256 poolSupply,
        uint256 totalWeight,
        uint256 tokenAmountOut,
        uint256 swapFee
    ) public pure returns (uint256 poolAmountIn) {
        // charge swap fee on the output token side
        uint256 normalizedWeight = bdiv(tokenWeightOut, totalWeight);
        //uint tAoBeforeSwapFee = tAo / (1 - (1-weightTo) * swapFee) ;
        uint256 zoo = bsub(BONE, normalizedWeight);
        uint256 zar = bmul(zoo, swapFee);
        uint256 tokenAmountOutBeforeSwapFee = bdiv(tokenAmountOut, bsub(BONE, zar));

        uint256 newTokenBalanceOut = bsub(tokenBalanceOut, tokenAmountOutBeforeSwapFee);
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

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.6.12;

interface IBPool {
    function getSpotPrice(address tokenIn, address tokenOut) external view returns (uint256 spotPrice);

    function getSpotPriceSansFee(address tokenIn, address tokenOut) external view returns (uint256 spotPrice);

    function swapExactAmountIn(
        address tokenIn,
        uint256 tokenAmountIn,
        address tokenOut,
        uint256 minAmountOut,
        uint256 maxPrice
    ) external returns (uint256 tokenAmountOut, uint256 spotPriceAfter);

    function transferFrom(
        address src,
        address dst,
        uint256 amt
    ) external returns (bool);

    function approve(address dst, uint256 amt) external returns (bool);

    function transfer(address dst, uint256 amt) external returns (bool);

    function balanceOf(address whom) external view returns (uint256);

    function joinPool(uint256 poolAmountOut, uint256[] calldata maxAmountsIn) external;

    function exitPool(uint256 poolAmountIn, uint256[] calldata minAmountsOut) external;

    function finalize() external;

    function rebind(
        address token,
        uint256 balance,
        uint256 denorm
    ) external;

    function setSwapFee(uint256 swapFee) external;

    function setPublicSwap(bool publicSwap) external;

    function bind(
        address token,
        uint256 balance,
        uint256 denorm
    ) external;

    function unbind(address token) external;

    function gulp(address token) external;

    function isBound(address token) external view returns (bool);

    function getBalance(address token) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function getSwapFee() external view returns (uint256);

    function isPublicSwap() external view returns (bool);

    function getDenormalizedWeight(address token) external view returns (uint256);

    function getTotalDenormalizedWeight() external view returns (uint256);

    // solhint-disable-next-line func-name-mixedcase
    function EXIT_FEE() external view returns (uint256);

    function calcPoolOutGivenSingleIn(
        uint256 tokenBalanceIn,
        uint256 tokenWeightIn,
        uint256 poolSupply,
        uint256 totalWeight,
        uint256 tokenAmountIn,
        uint256 swapFee
    ) external pure returns (uint256 poolAmountOut);

    function calcSingleInGivenPoolOut(
        uint256 tokenBalanceIn,
        uint256 tokenWeightIn,
        uint256 poolSupply,
        uint256 totalWeight,
        uint256 poolAmountOut,
        uint256 swapFee
    ) external pure returns (uint256 tokenAmountIn);

    function calcSingleOutGivenPoolIn(
        uint256 tokenBalanceOut,
        uint256 tokenWeightOut,
        uint256 poolSupply,
        uint256 totalWeight,
        uint256 poolAmountIn,
        uint256 swapFee
    ) external pure returns (uint256 tokenAmountOut);

    function calcPoolInGivenSingleOut(
        uint256 tokenBalanceOut,
        uint256 tokenWeightOut,
        uint256 poolSupply,
        uint256 totalWeight,
        uint256 tokenAmountOut,
        uint256 swapFee
    ) external pure returns (uint256 poolAmountIn);

    function getCurrentTokens() external view returns (address[] memory tokens);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.6.6;

import "./BConst.sol";

// Core contract; can't be changed. So disable solhint (reminder for v2)

/* solhint-disable private-vars-leading-underscore */

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

    function bsubSign(uint256 a, uint256 b) internal pure returns (uint256, bool) {
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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.6.6;

import "./BColor.sol";

contract BConst is BBronze {
    uint256 public constant BONE = 10**18;

    uint256 public constant MIN_BOUND_TOKENS = 2;
    uint256 public constant MAX_BOUND_TOKENS = 8;

    uint256 public constant MIN_FEE = BONE / 10**6;
    uint256 public constant MAX_FEE = BONE / 10;
    uint256 public constant EXIT_FEE = 0;

    uint256 public constant MIN_WEIGHT = BONE;
    uint256 public constant MAX_WEIGHT = BONE * 50;
    uint256 public constant MAX_TOTAL_WEIGHT = BONE * 50;
    uint256 public constant MIN_BALANCE = BONE / 10**12;

    uint256 public constant INIT_POOL_SUPPLY = BONE * 100;

    uint256 public constant MIN_BPOW_BASE = 1 wei;
    uint256 public constant MAX_BPOW_BASE = (2 * BONE) - 1 wei;
    uint256 public constant BPOW_PRECISION = BONE / 10**10;

    uint256 public constant MAX_IN_RATIO = BONE / 2;
    uint256 public constant MAX_OUT_RATIO = (BONE / 3) + 1 wei;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.6.6;

// abstract contract BColor {
//     function getColor()
//         external view virtual
//         returns (bytes32);
// }

contract BBronze {
    function getColor() external pure returns (bytes32) {
        return bytes32("BRONZE");
    }
}

{
  "optimizer": {
    "enabled": false,
    "runs": 200
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
  "libraries": {}
}