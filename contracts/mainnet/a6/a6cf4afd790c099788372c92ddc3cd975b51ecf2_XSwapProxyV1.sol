/**
 *Submitted for verification at Etherscan.io on 2021-02-05
*/

// File: contracts/interface/IXPool.sol

pragma solidity 0.5.17;

interface IXPool {
    // XPToken
    event Approval(address indexed src, address indexed dst, uint256 amt);
    event Transfer(address indexed src, address indexed dst, uint256 amt);

    function totalSupply() external view returns (uint256);

    function balanceOf(address whom) external view returns (uint256);

    function allowance(address src, address dst)
        external
        view
        returns (uint256);

    function approve(address dst, uint256 amt) external returns (bool);

    function transfer(address dst, uint256 amt) external returns (bool);

    function transferFrom(
        address src,
        address dst,
        uint256 amt
    ) external returns (bool);

    // Swap
    function swapExactAmountIn(
        address tokenIn,
        uint256 tokenAmountIn,
        address tokenOut,
        uint256 minAmountOut,
        uint256 maxPrice
    ) external returns (uint256 tokenAmountOut, uint256 spotPriceAfter);

    function swapExactAmountOut(
        address tokenIn,
        uint256 maxAmountIn,
        address tokenOut,
        uint256 tokenAmountOut,
        uint256 maxPrice
    ) external returns (uint256 tokenAmountIn, uint256 spotPriceAfter);

    // Referral
    function swapExactAmountInRefer(
        address tokenIn,
        uint256 tokenAmountIn,
        address tokenOut,
        uint256 minAmountOut,
        uint256 maxPrice,
        address referrer
    ) external returns (uint256 tokenAmountOut, uint256 spotPriceAfter);

    function swapExactAmountOutRefer(
        address tokenIn,
        uint256 maxAmountIn,
        address tokenOut,
        uint256 tokenAmountOut,
        uint256 maxPrice,
        address referrer
    ) external returns (uint256 tokenAmountIn, uint256 spotPriceAfter);

    // Pool Data
    function isBound(address token) external view returns (bool);

    function getFinalTokens() external view returns (address[] memory tokens);

    function getBalance(address token) external view returns (uint256);

    function swapFee() external view returns (uint256);

    function exitFee() external view returns (uint256);

    function finalized() external view returns (uint256);

    function controller() external view returns (uint256);

    function xconfig() external view returns (uint256);

    function getDenormalizedWeight(address) external view returns (uint256);

    function getTotalDenormalizedWeight() external view returns (uint256);

    function getVersion() external view returns (bytes32);

    function calcInGivenOut(
        uint256 tokenBalanceIn,
        uint256 tokenWeightIn,
        uint256 tokenBalanceOut,
        uint256 tokenWeightOut,
        uint256 tokenAmountOut,
        uint256 _swapFee
    ) external pure returns (uint256 tokenAmountIn);

    function calcOutGivenIn(
        uint256 tokenBalanceIn,
        uint256 tokenWeightIn,
        uint256 tokenBalanceOut,
        uint256 tokenWeightOut,
        uint256 tokenAmountIn,
        uint256 _swapFee
    ) external pure returns (uint256 tokenAmountOut);

    // Pool Managment
    function setController(address _controller) external;

    function setExitFee(uint256 newFee) external;

    function finalize(uint256 _swapFee) external;

    function bind(address token, uint256 denorm) external;

    function joinPool(uint256 poolAmountOut, uint256[] calldata maxAmountsIn)
        external;

    function exitPool(uint256 poolAmountIn, uint256[] calldata minAmountsOut)
        external;

    function joinswapExternAmountIn(
        address tokenIn,
        uint256 tokenAmountIn,
        uint256 minPoolAmountOut
    ) external returns (uint256 poolAmountOut);

    function exitswapPoolAmountIn(
        address tokenOut,
        uint256 poolAmountIn,
        uint256 minAmountOut
    ) external returns (uint256 tokenAmountOut);

    // Pool Governance
    function updateSafu(address safu, uint256 fee) external;

    function updateFarm(bool isFarm) external;
}

// File: contracts/interface/IXFactory.sol

pragma solidity 0.5.17;


interface IXFactory {
    function newXPool() external returns (IXPool);
}

// File: contracts/interface/IXConfig.sol

pragma solidity 0.5.17;

interface IXConfig {
    function getCore() external view returns (address);

    function getSAFU() external view returns (address);

    function isFarmPool(address pool) external view returns (bool);

    function getMaxExitFee() external view returns (uint256);

    function getSafuFee() external view returns (uint256);

    function getSwapProxy() external view returns (address);

    function ethAddress() external pure returns (address);

    function hasPool(address[] calldata tokens, uint256[] calldata denorms)
        external
        view
        returns (bool exist, bytes32 sig);

    // add by XSwapProxy
    function addPoolSig(bytes32 sig) external;

    // remove by XSwapProxy
    function removePoolSig(bytes32 sig) external;
}

// File: contracts/interface/IERC20.sol

pragma solidity 0.5.17;

interface IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address _owner) external view returns (uint256 balance);

    function transfer(address _to, uint256 _value)
        external
        returns (bool success);

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool success);

    function approve(address _spender, uint256 _value)
        external
        returns (bool success);

    function allowance(address _owner, address _spender)
        external
        view
        returns (uint256 remaining);
}

// File: contracts/lib/XNum.sol

pragma solidity 0.5.17;

library XNum {
    uint256 public constant BONE = 10**18;
    uint256 public constant MIN_BPOW_BASE = 1 wei;
    uint256 public constant MAX_BPOW_BASE = (2 * BONE) - 1 wei;
    uint256 public constant BPOW_PRECISION = BONE / 10**10;

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
        //         = (product(a - i + 1, i=1-->k) * x^k) / (k!)
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

// File: contracts/lib/Address.sol

pragma solidity 0.5.17;

//https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v2.5.0/contracts/utils/Address.sol

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
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash =
            0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * _Available since v2.4.0._
     */
    function toPayable(address account)
        internal
        pure
        returns (address payable)
    {
        return address(uint160(account));
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
     *
     * _Available since v2.4.0._
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount).gas(9100)("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }
}

// File: contracts/lib/SafeERC20.sol

pragma solidity 0.5.17;



//https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v2.5.0/contracts/token/ERC20/SafeERC20.sol

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}

// File: contracts/lib/ReentrancyGuard.sol

pragma solidity 0.5.17;

//https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v2.5.0/contracts/utils/ReentrancyGuard.sol

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 *
 * _Since v2.5.0:_ this module is now much more gas efficient, given net gas
 * metering changes introduced in the Istanbul hardfork.
 */
contract ReentrancyGuard {
    bool private _notEntered;

    constructor() internal {
        // Storing an initial non-zero value makes deployment a bit more
        // expensive, but in exchange the refund on every call to nonReentrant
        // will be lower in amount. Since refunds are capped to a percetange of
        // the total transaction's gas, it is best to keep them low in cases
        // like this one, to increase the likelihood of the full refund coming
        // into effect.
        _notEntered = true;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_notEntered, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _notEntered = false;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _notEntered = true;
    }
}

// File: contracts/XSwapProxyV1.sol

pragma solidity 0.5.17;
pragma experimental ABIEncoderV2;








// WETH9
interface IWETH {
    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address, uint256) external returns (bool);

    function transfer(address to, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function deposit() external payable;

    function withdraw(uint256 amount) external;
}

contract XSwapProxyV1 is ReentrancyGuard {
    using XNum for uint256;
    using SafeERC20 for IERC20;

    uint256 public constant MAX = 2**256 - 1;
    uint256 public constant BONE = 10**18;
    uint256 public constant MIN_BOUND_TOKENS = 2;
    uint256 public constant MAX_BOUND_TOKENS = 8;

    uint256 public constant MIN_BATCH_SWAPS = 1;
    uint256 public constant MAX_BATCH_SWAPS = 4;

    // WETH9
    IWETH weth;

    IXConfig public xconfig;

    constructor(address _weth, address _xconfig) public {
        weth = IWETH(_weth);
        xconfig = IXConfig(_xconfig);
    }

    function() external payable {}

    // Batch Swap
    struct Swap {
        address pool;
        uint256 tokenInParam; // tokenInAmount / maxAmountIn
        uint256 tokenOutParam; // minAmountOut / tokenAmountOut
        uint256 maxPrice;
    }

    function batchSwapExactIn(
        Swap[] memory swaps,
        address tokenIn,
        address tokenOut,
        uint256 totalAmountIn,
        uint256 minTotalAmountOut
    ) public payable returns (uint256 totalAmountOut) {
        return
            batchSwapExactInRefer(
                swaps,
                tokenIn,
                tokenOut,
                totalAmountIn,
                minTotalAmountOut,
                address(0x0)
            );
    }

    function batchSwapExactInRefer(
        Swap[] memory swaps,
        address tokenIn,
        address tokenOut,
        uint256 totalAmountIn,
        uint256 minTotalAmountOut,
        address referrer
    ) public payable nonReentrant returns (uint256 totalAmountOut) {
        require(
            swaps.length >= MIN_BATCH_SWAPS && swaps.length <= MAX_BATCH_SWAPS,
            "ERR_BATCH_COUNT"
        );

        IERC20 TI = IERC20(tokenIn);
        IERC20 TO = IERC20(tokenOut);

        transferFromAllTo(TI, totalAmountIn, address(this));

        uint256 actualTotalIn = 0;
        for (uint256 i = 0; i < swaps.length; i++) {
            Swap memory swap = swaps[i];
            IXPool pool = IXPool(swap.pool);

            if (TI.allowance(address(this), swap.pool) < totalAmountIn) {
                TI.safeApprove(swap.pool, 0);
                TI.safeApprove(swap.pool, MAX);
            }

            (uint256 tokenAmountOut, ) =
                pool.swapExactAmountInRefer(
                    tokenIn,
                    swap.tokenInParam,
                    tokenOut,
                    swap.tokenOutParam,
                    swap.maxPrice,
                    referrer
                );

            actualTotalIn = actualTotalIn.badd(swap.tokenInParam);
            totalAmountOut = tokenAmountOut.badd(totalAmountOut);
        }
        require(actualTotalIn <= totalAmountIn, "ERR_ACTUAL_IN");
        require(totalAmountOut >= minTotalAmountOut, "ERR_LIMIT_OUT");

        transferAll(TO, totalAmountOut);
        transferAll(TI, getBalance(tokenIn));
        return totalAmountOut;
    }

    function batchSwapExactOut(
        Swap[] memory swaps,
        address tokenIn,
        address tokenOut,
        uint256 maxTotalAmountIn
    ) public payable returns (uint256 totalAmountIn) {
        return
            batchSwapExactOutRefer(
                swaps,
                tokenIn,
                tokenOut,
                maxTotalAmountIn,
                address(0x0)
            );
    }

    function batchSwapExactOutRefer(
        Swap[] memory swaps,
        address tokenIn,
        address tokenOut,
        uint256 maxTotalAmountIn,
        address referrer
    ) public payable nonReentrant returns (uint256 totalAmountIn) {
        require(
            swaps.length >= MIN_BATCH_SWAPS && swaps.length <= MAX_BATCH_SWAPS,
            "ERR_BATCH_COUNT"
        );

        IERC20 TI = IERC20(tokenIn);
        IERC20 TO = IERC20(tokenOut);

        transferFromAllTo(TI, maxTotalAmountIn, address(this));

        for (uint256 i = 0; i < swaps.length; i++) {
            Swap memory swap = swaps[i];
            IXPool pool = IXPool(swap.pool);

            if (TI.allowance(address(this), swap.pool) < maxTotalAmountIn) {
                TI.safeApprove(swap.pool, 0);
                TI.safeApprove(swap.pool, MAX);
            }

            (uint256 tokenAmountIn, ) =
                pool.swapExactAmountOutRefer(
                    tokenIn,
                    swap.tokenInParam,
                    tokenOut,
                    swap.tokenOutParam,
                    swap.maxPrice,
                    referrer
                );
            totalAmountIn = tokenAmountIn.badd(totalAmountIn);
        }
        require(totalAmountIn <= maxTotalAmountIn, "ERR_LIMIT_IN");

        transferAll(TO, getBalance(tokenOut));
        transferAll(TI, getBalance(tokenIn));
    }

    // Multihop Swap
    struct MSwap {
        address pool;
        address tokenIn;
        address tokenOut;
        uint256 swapAmount; // tokenInAmount / tokenOutAmount
        uint256 limitReturnAmount; // minAmountOut / maxAmountIn
        uint256 maxPrice;
    }

    function multihopBatchSwapExactIn(
        MSwap[][] memory swapSequences,
        address tokenIn,
        address tokenOut,
        uint256 totalAmountIn,
        uint256 minTotalAmountOut
    ) public payable returns (uint256 totalAmountOut) {
        return
            multihopBatchSwapExactInRefer(
                swapSequences,
                tokenIn,
                tokenOut,
                totalAmountIn,
                minTotalAmountOut,
                address(0x0)
            );
    }

    function multihopBatchSwapExactInRefer(
        MSwap[][] memory swapSequences,
        address tokenIn,
        address tokenOut,
        uint256 totalAmountIn,
        uint256 minTotalAmountOut,
        address referrer
    ) public payable nonReentrant returns (uint256 totalAmountOut) {
        require(
            swapSequences.length >= MIN_BATCH_SWAPS &&
                swapSequences.length <= MAX_BATCH_SWAPS,
            "ERR_BATCH_COUNT"
        );

        transferFromAllTo(IERC20(tokenIn), totalAmountIn, address(this));

        uint256 actualTotalIn = 0;
        for (uint256 i = 0; i < swapSequences.length; i++) {
            require(tokenIn == swapSequences[i][0].tokenIn, "ERR_NOT_MATCH");
            actualTotalIn = actualTotalIn.badd(swapSequences[i][0].swapAmount);

            uint256 tokenAmountOut = 0;
            for (uint256 k = 0; k < swapSequences[i].length; k++) {
                MSwap memory swap = swapSequences[i][k];

                IERC20 SwapTokenIn = IERC20(swap.tokenIn);
                if (k == 1) {
                    // Makes sure that on the second swap the output of the first was used
                    // so there is not intermediate token leftover
                    swap.swapAmount = tokenAmountOut;
                }

                IXPool pool = IXPool(swap.pool);
                if (
                    SwapTokenIn.allowance(address(this), swap.pool) <
                    totalAmountIn
                ) {
                    SwapTokenIn.safeApprove(swap.pool, 0);
                    SwapTokenIn.safeApprove(swap.pool, MAX);
                }

                (tokenAmountOut, ) = pool.swapExactAmountInRefer(
                    swap.tokenIn,
                    swap.swapAmount,
                    swap.tokenOut,
                    swap.limitReturnAmount,
                    swap.maxPrice,
                    referrer
                );
            }
            // This takes the amountOut of the last swap
            totalAmountOut = tokenAmountOut.badd(totalAmountOut);
        }

        require(actualTotalIn <= totalAmountIn, "ERR_ACTUAL_IN");
        require(totalAmountOut >= minTotalAmountOut, "ERR_LIMIT_OUT");

        transferAll(IERC20(tokenOut), totalAmountOut);
        transferAll(IERC20(tokenIn), getBalance(tokenIn));
    }

    function multihopBatchSwapExactOut(
        MSwap[][] memory swapSequences,
        address tokenIn,
        address tokenOut,
        uint256 maxTotalAmountIn
    ) public payable returns (uint256 totalAmountIn) {
        return
            multihopBatchSwapExactOutRefer(
                swapSequences,
                tokenIn,
                tokenOut,
                maxTotalAmountIn,
                address(0x0)
            );
    }

    function multihopBatchSwapExactOutRefer(
        MSwap[][] memory swapSequences,
        address tokenIn,
        address tokenOut,
        uint256 maxTotalAmountIn,
        address referrer
    ) public payable nonReentrant returns (uint256 totalAmountIn) {
        require(
            swapSequences.length >= MIN_BATCH_SWAPS &&
                swapSequences.length <= MAX_BATCH_SWAPS,
            "ERR_BATCH_COUNT"
        );

        transferFromAllTo(IERC20(tokenIn), maxTotalAmountIn, address(this));

        for (uint256 i = 0; i < swapSequences.length; i++) {
            require(tokenIn == swapSequences[i][0].tokenIn, "ERR_NOT_MATCH");

            uint256 tokenAmountInFirstSwap;
            // Specific code for a simple swap and a multihop (2 swaps in sequence)
            if (swapSequences[i].length == 1) {
                MSwap memory swap = swapSequences[i][0];
                IERC20 SwapTokenIn = IERC20(swap.tokenIn);

                IXPool pool = IXPool(swap.pool);
                if (
                    SwapTokenIn.allowance(address(this), swap.pool) <
                    maxTotalAmountIn
                ) {
                    SwapTokenIn.safeApprove(swap.pool, 0);
                    SwapTokenIn.safeApprove(swap.pool, MAX);
                }

                (tokenAmountInFirstSwap, ) = pool.swapExactAmountOutRefer(
                    swap.tokenIn,
                    swap.limitReturnAmount,
                    swap.tokenOut,
                    swap.swapAmount,
                    swap.maxPrice,
                    referrer
                );
            } else {
                // Consider we are swapping A -> B and B -> C. The goal is to buy a given amount
                // of token C. But first we need to buy B with A so we can then buy C with B
                // To get the exact amount of C we then first need to calculate how much B we'll need:
                uint256 intermediateTokenAmount;
                // This would be token B as described above
                MSwap memory secondSwap = swapSequences[i][1];
                IXPool poolSecondSwap = IXPool(secondSwap.pool);
                intermediateTokenAmount = poolSecondSwap.calcInGivenOut(
                    poolSecondSwap.getBalance(secondSwap.tokenIn),
                    poolSecondSwap.getDenormalizedWeight(secondSwap.tokenIn),
                    poolSecondSwap.getBalance(secondSwap.tokenOut),
                    poolSecondSwap.getDenormalizedWeight(secondSwap.tokenOut),
                    secondSwap.swapAmount,
                    poolSecondSwap.swapFee()
                );

                //// Buy intermediateTokenAmount of token B with A in the first pool
                MSwap memory firstSwap = swapSequences[i][0];
                IERC20 FirstSwapTokenIn = IERC20(firstSwap.tokenIn);
                IXPool poolFirstSwap = IXPool(firstSwap.pool);
                if (
                    FirstSwapTokenIn.allowance(address(this), firstSwap.pool) <
                    MAX
                ) {
                    FirstSwapTokenIn.safeApprove(firstSwap.pool, 0);
                    FirstSwapTokenIn.safeApprove(firstSwap.pool, MAX);
                }

                (tokenAmountInFirstSwap, ) = poolFirstSwap.swapExactAmountOut(
                    firstSwap.tokenIn,
                    firstSwap.limitReturnAmount,
                    firstSwap.tokenOut,
                    intermediateTokenAmount, // This is the amount of token B we need
                    firstSwap.maxPrice
                );

                //// Buy the final amount of token C desired
                IERC20 SecondSwapTokenIn = IERC20(secondSwap.tokenIn);
                if (
                    SecondSwapTokenIn.allowance(
                        address(this),
                        secondSwap.pool
                    ) < MAX
                ) {
                    SecondSwapTokenIn.safeApprove(secondSwap.pool, 0);
                    SecondSwapTokenIn.safeApprove(secondSwap.pool, MAX);
                }

                poolSecondSwap.swapExactAmountOut(
                    secondSwap.tokenIn,
                    secondSwap.limitReturnAmount,
                    secondSwap.tokenOut,
                    secondSwap.swapAmount,
                    secondSwap.maxPrice
                );
            }
            totalAmountIn = tokenAmountInFirstSwap.badd(totalAmountIn);
        }

        require(totalAmountIn <= maxTotalAmountIn, "ERR_LIMIT_IN");

        transferAll(IERC20(tokenOut), getBalance(tokenOut));
        transferAll(IERC20(tokenIn), getBalance(tokenIn));
    }

    // Pool Management
    function create(
        address factoryAddress,
        address[] calldata tokens,
        uint256[] calldata balances,
        uint256[] calldata denorms,
        uint256 swapFee,
        uint256 exitFee
    ) external payable nonReentrant returns (address) {
        require(tokens.length == balances.length, "ERR_LENGTH_MISMATCH");
        require(tokens.length == denorms.length, "ERR_LENGTH_MISMATCH");
        require(tokens.length >= MIN_BOUND_TOKENS, "ERR_MIN_TOKENS");
        require(tokens.length <= MAX_BOUND_TOKENS, "ERR_MAX_TOKENS");

        // check pool exist
        (bool exist, bytes32 sig) = xconfig.hasPool(tokens, denorms);
        require(!exist, "ERR_POOL_EXISTS");

        // create new pool
        IXPool pool = IXFactory(factoryAddress).newXPool();
        bool hasETH = false;
        for (uint256 i = 0; i < tokens.length; i++) {
            if (
                transferFromAllTo(IERC20(tokens[i]), balances[i], address(pool))
            ) {
                hasETH = true;
                pool.bind(address(weth), denorms[i]);
            } else {
                pool.bind(tokens[i], denorms[i]);
            }
        }
        require(msg.value == 0 || hasETH, "ERR_INVALID_PAY");
        pool.setExitFee(exitFee);
        pool.finalize(swapFee);

        xconfig.addPoolSig(sig);
        pool.transfer(msg.sender, pool.balanceOf(address(this)));

        return address(pool);
    }

    function joinPool(
        address poolAddress,
        uint256 poolAmountOut,
        uint256[] calldata maxAmountsIn
    ) external payable nonReentrant {
        IXPool pool = IXPool(poolAddress);

        address[] memory tokens = pool.getFinalTokens();
        require(maxAmountsIn.length == tokens.length, "ERR_LENGTH_MISMATCH");

        bool hasEth = false;
        for (uint256 i = 0; i < tokens.length; i++) {
            if (msg.value > 0 && tokens[i] == address(weth)) {
                transferFromAllAndApprove(
                    xconfig.ethAddress(),
                    maxAmountsIn[i],
                    poolAddress
                );
                hasEth = true;
            } else {
                transferFromAllAndApprove(
                    tokens[i],
                    maxAmountsIn[i],
                    poolAddress
                );
            }
        }
        require(msg.value == 0 || hasEth, "ERR_INVALID_PAY");
        pool.joinPool(poolAmountOut, maxAmountsIn);
        for (uint256 i = 0; i < tokens.length; i++) {
            if (hasEth) {
                transferAll(
                    IERC20(xconfig.ethAddress()),
                    getBalance(xconfig.ethAddress())
                );
            } else {
                transferAll(IERC20(tokens[i]), getBalance(tokens[i]));
            }
        }
        pool.transfer(msg.sender, pool.balanceOf(address(this)));
    }

    function joinswapExternAmountIn(
        address poolAddress,
        address tokenIn,
        uint256 tokenAmountIn,
        uint256 minPoolAmountOut
    ) external payable nonReentrant {
        IXPool pool = IXPool(poolAddress);

        bool hasEth = false;
        if (transferFromAllAndApprove(tokenIn, tokenAmountIn, poolAddress)) {
            hasEth = true;
        }
        require(msg.value == 0 || hasEth, "ERR_INVALID_PAY");

        if (hasEth) {
            uint256 poolAmountOut =
                pool.joinswapExternAmountIn(
                    address(weth),
                    tokenAmountIn,
                    minPoolAmountOut
                );
            pool.transfer(msg.sender, poolAmountOut);
        } else {
            uint256 poolAmountOut =
                pool.joinswapExternAmountIn(
                    tokenIn,
                    tokenAmountIn,
                    minPoolAmountOut
                );
            pool.transfer(msg.sender, poolAmountOut);
        }
    }

    // Internal
    function getBalance(address token) internal view returns (uint256) {
        if (token == xconfig.ethAddress()) {
            return weth.balanceOf(address(this));
        }
        return IERC20(token).balanceOf(address(this));
    }

    function transferAll(IERC20 token, uint256 amount) internal returns (bool) {
        if (amount == 0) {
            return true;
        }
        if (address(token) == xconfig.ethAddress()) {
            weth.withdraw(amount);
            (bool xfer, ) = msg.sender.call.value(amount).gas(9100)("");
            require(xfer, "ERR_ETH_FAILED");
        } else {
            token.safeTransfer(msg.sender, amount);
        }
        return true;
    }

    function transferFromAllTo(
        IERC20 token,
        uint256 amount,
        address to
    ) internal returns (bool hasETH) {
        hasETH = false;
        if (address(token) == xconfig.ethAddress()) {
            require(amount == msg.value, "ERR_TOKEN_AMOUNT");
            weth.deposit.value(amount)();
            weth.transfer(to, amount);
            hasETH = true;
        } else {
            token.safeTransferFrom(msg.sender, to, amount);
        }
    }

    function transferFromAllAndApprove(
        address token,
        uint256 amount,
        address spender
    ) internal returns (bool hasETH) {
        hasETH = false;
        if (token == xconfig.ethAddress()) {
            require(amount == msg.value, "ERR_TOKEN_AMOUNT");
            weth.deposit.value(amount)();
            if (weth.allowance(address(this), spender) < amount) {
                IERC20(address(weth)).safeApprove(spender, 0);
                IERC20(address(weth)).safeApprove(spender, amount);
            }
            hasETH = true;
        } else {
            IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
            if (IERC20(token).allowance(address(this), spender) < amount) {
                IERC20(token).safeApprove(spender, 0);
                IERC20(token).safeApprove(spender, amount);
            }
        }
    }
}