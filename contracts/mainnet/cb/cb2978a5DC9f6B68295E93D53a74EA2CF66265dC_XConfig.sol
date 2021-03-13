/**
 *Submitted for verification at Etherscan.io on 2021-03-13
*/

// File: contracts/XConst.sol

pragma solidity 0.5.17;

contract XConst {
    uint256 public constant BONE = 10**18;

    uint256 public constant MIN_BOUND_TOKENS = 2;
    uint256 public constant MAX_BOUND_TOKENS = 8;

    uint256 public constant EXIT_ZERO_FEE = 0;

    uint256 public constant MIN_WEIGHT = BONE;
    uint256 public constant MAX_WEIGHT = BONE * 50;
    uint256 public constant MAX_TOTAL_WEIGHT = BONE * 50;

    // min effective value: 0.000001 TOKEN
    uint256 public constant MIN_BALANCE = 10**6;

    // BONE/(10**10) XPT
    uint256 public constant MIN_POOL_AMOUNT = 10**8;

    uint256 public constant INIT_POOL_SUPPLY = BONE * 100;

    uint256 public constant MAX_IN_RATIO = BONE / 2;
    uint256 public constant MAX_OUT_RATIO = (BONE / 3) + 1 wei;
}

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

    function isFarmPool() external view returns (uint256);

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

// File: contracts/XConfig.sol

pragma solidity 0.5.17;







/**
1. SAFU is a multi-sig account
2. SAFU is the core of XConfig contract instance
3. DEV firstly deploys XConfig contract, then setups the xconfig.core and xconfig.safu to SAFU with setSAFU() and setCore() 
*/
contract XConfig is XConst {
    using XNum for uint256;
    using Address for address;
    using SafeERC20 for IERC20;

    address private core;

    // Secure Asset Fund for Users(SAFU) address
    address private safu;
    uint256 public SAFU_FEE = (5 * BONE) / 10000; // 0.05%

    // Swap Proxy Address
    address private swapProxy;

    // ETH and WETH address
    address public constant ETH_ADDR =
        address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
    address public weth;

    // pool sigs for pool deduplication
    // key: keccak256(tokens[i], norms[i]), value: pool_address
    mapping(bytes32 => address) public poolSigs;
    uint256 public poolSigCount;
    // empty pool: if XPT totalSupply <= MIN_EFFECTIVE_XPT
    uint256 public minEffeciveXPT = 10**14; //0.0001 XPT

    uint256 public maxExitFee = BONE / 1000; // 0.1%

    event INIT_SAFU(address indexed addr);
    event SET_CORE(address indexed core, address indexed coreNew);

    event SET_SAFU(address indexed safu, address indexed safuNew);
    event SET_SAFU_FEE(uint256 indexed fee, uint256 indexed feeNew);

    event SET_PROXY(address indexed proxy, address indexed proxyNew);

    event ADD_POOL_SIG(
        address indexed caller,
        address indexed pool,
        bytes32 sig
    );
    event RM_POOL_SIG(
        address indexed caller,
        address indexed pool,
        bytes32 sig
    );

    event ADD_FARM_POOL(address indexed pool);
    event RM_FARM_POOL(address indexed pool);
    event SET_MFXPT(uint256 amount);

    event COLLECT(address indexed token, uint256 amount);

    modifier onlyCore() {
        require(msg.sender == core, "ERR_CORE_AUTH");
        _;
    }

    constructor(address _weth) public {
        require(_weth != address(0), "ERR_ZERO_ADDR");
        weth = _weth;
        core = msg.sender;
        safu = address(this);
        emit INIT_SAFU(address(this));
    }

    function getCore() external view returns (address) {
        return core;
    }

    function getSAFU() external view returns (address) {
        return safu;
    }

    function getMaxExitFee() external view returns (uint256) {
        return maxExitFee;
    }

    function getSafuFee() external view returns (uint256) {
        return SAFU_FEE;
    }

    function getSwapProxy() external view returns (address) {
        return swapProxy;
    }

    /**
     * pool deduplication
     * @dev check pool existence which has the same tokens(sorted by address) and weights
     * the denorms will allways between [10**18, 50 * 10**18]
     * @notice if pool is address(0), means not created yet
     * @return pool exists and pool sig
     */
    function dedupPool(address[] calldata tokens, uint256[] calldata denorms)
        external
        returns (bool exist, bytes32 sig)
    {
        require(msg.sender == swapProxy, "ERR_NOT_SWAPPROXY");
        require(tokens.length == denorms.length, "ERR_LENGTH_MISMATCH");
        require(tokens.length >= MIN_BOUND_TOKENS, "ERR_MIN_TOKENS");
        require(tokens.length <= MAX_BOUND_TOKENS, "ERR_MAX_TOKENS");

        uint256 totalWeight = 0;
        address[] memory finalTokens = new address[](tokens.length);
        for (uint8 i = 0; i < tokens.length; i++) {
            if (i > 0) {
                //token address must bt sorted
                require(tokens[i] > tokens[i - 1], "ERR_TOKENS_NOT_SORTED");
            }

            finalTokens[i] = tokens[i];
            if (tokens[i] == ETH_ADDR) {
                finalTokens[i] = weth;
            }
            totalWeight = totalWeight.badd(denorms[i]);
        }

        //pool sig generated
        bytes memory poolInfo;
        for (uint8 i = 0; i < finalTokens.length; i++) {
            //normalized weight (multiplied by 100)
            uint256 nWeight = denorms[i].bmul(100).bdiv(totalWeight);
            poolInfo = abi.encodePacked(poolInfo, finalTokens[i], nWeight);
        }
        sig = keccak256(poolInfo);

        //check empty pool
        address pool = poolSigs[sig];
        if (pool != address(0)) {
            IERC20 TP = IERC20(pool);

            if (TP.totalSupply() > minEffeciveXPT) {
                return (true, sig);
            } else {
                //remove sig
                removePoolSig(sig);
            }
        }
        exist = false;
    }

    // add pool's sig
    // only allow called by swapProxy
    function addPoolSig(bytes32 sig, address pool) external {
        require(msg.sender == swapProxy, "ERR_NOT_SWAPPROXY");
        require(pool != address(0), "ERR_ZERO_ADDR");
        require(sig != 0, "ERR_NOT_SIG");

        if (poolSigs[sig] == address(0)) {
            //add new sig
            poolSigCount = poolSigCount.badd(1);
        }

        poolSigs[sig] = pool;
        emit ADD_POOL_SIG(msg.sender, pool, sig);
    }

    // remove pool's sig
    function removePoolSig(bytes32 sig) internal {
        require(sig != 0, "ERR_NOT_SIG");

        if (poolSigs[sig] != address(0)) {
            emit RM_POOL_SIG(msg.sender, poolSigs[sig], sig);
            delete poolSigs[sig];
            poolSigCount = poolSigCount.bsub(1);
        }
    }

    // manually batch update poolSig, called by core
    function updatePoolSigs(bytes32[] calldata sigs, address[] calldata pools)
        external
        onlyCore
    {
        require(sigs.length == pools.length, "ERR_LENGTH_MISMATCH");
        require(pools.length > 0 && pools.length <= 30, "ERR_BATCH_COUNT");

        for (uint8 i = 0; i < sigs.length; i++) {
            bytes32 sig = sigs[i];
            address pool = pools[i];
            require(sig != 0, "ERR_NOT_SIG");

            //remove
            if (pool == address(0)) {
                removePoolSig(sig);
                continue;
            }

            //update
            if (poolSigs[sig] != address(0)) {
                //over write
                poolSigs[sig] = pool;
            } else {
                //add new
                poolSigs[sig] = pool;
                poolSigCount = poolSigCount.badd(1);
                emit ADD_POOL_SIG(msg.sender, pool, sig);
            }
        }
    }

    function setCore(address _core) external onlyCore {
        require(_core != address(0), "ERR_ZERO_ADDR");
        emit SET_CORE(core, _core);
        core = _core;
    }

    function setSAFU(address _safu) external onlyCore {
        require(_safu != address(0), "ERR_ZERO_ADDR");
        emit SET_SAFU(safu, _safu);
        safu = _safu;
    }

    function setMaxExitFee(uint256 _fee) external onlyCore {
        require(_fee <= (BONE / 10), "INVALID_EXIT_FEE");
        maxExitFee = _fee;
    }

    function setSafuFee(uint256 _fee) external onlyCore {
        require(_fee <= (BONE / 10), "INVALID_SAFU_FEE");
        emit SET_SAFU_FEE(SAFU_FEE, _fee);
        SAFU_FEE = _fee;
    }

    function setMinEffeciveXPT(uint256 _mfxpt) external onlyCore {
        minEffeciveXPT = _mfxpt;
        emit SET_MFXPT(_mfxpt);
    }

    function setSwapProxy(address _proxy) external onlyCore {
        require(_proxy != address(0), "ERR_ZERO_ADDR");
        emit SET_PROXY(swapProxy, _proxy);
        swapProxy = _proxy;
    }

    // update SAFU address and SAFE_FEE to pools
    function updateSafu(address[] calldata pools) external onlyCore {
        require(pools.length > 0 && pools.length <= 30, "ERR_BATCH_COUNT");

        for (uint8 i = 0; i < pools.length; i++) {
            require(Address.isContract(pools[i]), "ERR_NOT_CONTRACT");

            IXPool pool = IXPool(pools[i]);
            pool.updateSafu(safu, SAFU_FEE);
        }
    }

    // update isFarmPool status to pools
    function updateFarm(address[] calldata pools, bool isFarm)
        external
        onlyCore
    {
        require(pools.length > 0 && pools.length <= 30, "ERR_BATCH_COUNT");

        for (uint8 i = 0; i < pools.length; i++) {
            require(Address.isContract(pools[i]), "ERR_NOT_CONTRACT");

            IXPool pool = IXPool(pools[i]);
            pool.updateFarm(isFarm);

            if (isFarm) {
                emit ADD_FARM_POOL(pools[i]);
            } else {
                emit RM_FARM_POOL(pools[i]);
            }
        }
    }

    // collect any tokens in this contract to safu
    function collect(address token) external onlyCore {
        IERC20 TI = IERC20(token);

        uint256 collected = TI.balanceOf(address(this));
        TI.safeTransfer(safu, collected);

        emit COLLECT(token, collected);
    }
}