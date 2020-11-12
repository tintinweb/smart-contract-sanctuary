// File: @openzeppelin/contracts/GSN/Context.sol

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

// File: @openzeppelin/contracts/access/Ownable.sol


pragma solidity ^0.6.0;

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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: contracts/interfaces/IUniswapV1.sol


pragma solidity ^0.6.0;



interface IUniswapV1Factory {
    function getExchange(IERC20 token) external view returns (IUniswapV1Exchange exchange);
}

interface IUniswapV1Exchange {
    function getEthToTokenInputPrice(uint256 ethSold) external view returns (uint256 tokensBought);
    function getTokenToEthInputPrice(uint256 tokensSold) external view returns (uint256 ethBought);

    function ethToTokenSwapInput(uint256 minTokens, uint256 deadline)
        external payable returns (uint256 tokensBought);
    function tokenToEthSwapInput(uint256 tokensSold, uint256 minEth, uint256 deadline)
        external returns (uint256 ethBought);
}

// File: contracts/interfaces/IUniswapV2.sol


pragma solidity ^0.6.0;



interface IUniswapV2Factory {
    function getPair(IERC20 tokenA, IERC20 tokenB) external view returns (IUniswapV2Exchange pair);
}

interface IUniswapV2Exchange {
    function getReserves() external view returns(uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;
}

// File: contracts/interfaces/IBalancer.sol


pragma solidity ^0.6.0;



interface IBalancerPool {
    function getSwapFee() external view returns (uint256 balance);
    function getDenormalizedWeight(IERC20 token) external view returns (uint256 balance);
    function getBalance(IERC20 token) external view returns (uint256 balance);

    function swapExactAmountIn(
        IERC20 tokenIn,
        uint256 tokenAmountIn,
        IERC20 tokenOut,
        uint256 minAmountOut,
        uint256 maxPrice
    )
        external
        returns (uint256 tokenAmountOut, uint256 spotPriceAfter);
}

interface IBalancerRegistry {
    // Get info about pool pair for 1 SLOAD
    function getPairInfo(address pool, IERC20 fromToken, IERC20 destToken)
        external view returns(uint256 weight1, uint256 weight2, uint256 swapFee);

    // Pools
    function checkAddedPools(address pool)
        external view returns(bool);
    function getAddedPoolsLength()
        external view returns(uint256);
    function getAddedPools()
        external view returns(address[] memory);
    function getAddedPoolsWithLimit(uint256 offset, uint256 limit)
        external view returns(address[] memory result);

    // Tokens
    function getAllTokensLength()
        external view returns(uint256);
    function getAllTokens()
        external view returns(address[] memory);
    function getAllTokensWithLimit(uint256 offset, uint256 limit)
        external view returns(address[] memory result);

    // Pairs
    function getPoolsLength(IERC20 fromToken, IERC20 destToken)
        external view returns(uint256);
    function getPools(IERC20 fromToken, IERC20 destToken)
        external view returns(IBalancerPool[] memory);
    function getPoolsWithLimit(IERC20 fromToken, IERC20 destToken, uint256 offset, uint256 limit)
        external view returns(IBalancerPool[] memory result);
    function getBestPools(IERC20 fromToken, IERC20 destToken)
        external view returns(IBalancerPool[] memory pools);
    function getBestPoolsWithLimit(IERC20 fromToken, IERC20 destToken, uint256 limit)
        external view returns(IBalancerPool[] memory pools);

    // Get swap rates
    function getPoolReturn(address pool, IERC20 fromToken, IERC20 destToken, uint256 amount)
        external view returns(uint256);
    function getPoolReturns(address pool, IERC20 fromToken, IERC20 destToken, uint256[] calldata amounts)
        external view returns(uint256[] memory result);

    // Add and update registry
    function addPool(address pool) external returns(uint256 listed);
    function addPools(address[] calldata pools) external returns(uint256[] memory listed);
    function updatedIndices(address[] calldata tokens, uint256 lengthLimit) external;
}

// File: contracts/interfaces/IAaveRegistry.sol


pragma solidity ^0.6.0;



interface IAaveRegistry {
    function tokenByAToken(IERC20 aToken) external view returns(IERC20);
    function aTokenByToken(IERC20 token) external view returns(IERC20);
}

// File: contracts/interfaces/ICompoundRegistry.sol


pragma solidity ^0.6.0;



interface ICompoundRegistry {
    function tokenByCToken(IERC20 cToken) external view returns(IERC20);
    function cTokenByToken(IERC20 token) external view returns(IERC20);
}

// File: contracts/IOneRouter.sol


pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;



interface IOneRouterView {
    struct Swap {
        IERC20 destToken;
        uint256 flags;
        uint256 destTokenEthPriceTimesGasPrice;
        address[] disabledDexes;
    }

    struct Path {
        Swap[] swaps;
    }

    struct SwapResult {
        uint256[] returnAmounts;
        uint256[] estimateGasAmounts;
        uint256[][] distributions;
        address[][] dexes;
    }

    struct PathResult {
        SwapResult[] swaps;
    }

    function getReturn(
        IERC20 fromToken,
        uint256[] calldata amounts,
        Swap calldata swap
    )
        external
        view
        returns(
            Path[] memory paths,
            PathResult[] memory pathResults,
            SwapResult memory splitResult
        );

    function getSwapReturn(
        IERC20 fromToken,
        uint256[] calldata amounts,
        Swap calldata swap
    )
        external
        view
        returns(SwapResult memory result);

    function getPathReturn(
        IERC20 fromToken,
        uint256[] calldata amounts,
        Path calldata path
    )
        external
        view
        returns(PathResult memory result);

    function getMultiPathReturn(
        IERC20 fromToken,
        uint256[] calldata amounts,
        Path[] calldata paths
    )
        external
        view
        returns(
            PathResult[] memory pathResults,
            SwapResult memory splitResult
        );
}


abstract contract IOneRouter is IOneRouterView {
    struct Referral {
        address payable ref;
        uint256 fee;
    }

    struct SwapInput {
        IERC20 fromToken;
        IERC20 destToken;
        uint256 amount;
        uint256 minReturn;
        Referral referral;
    }

    struct SwapDistribution {
        uint256[] weights;
    }

    struct PathDistribution {
        SwapDistribution[] swapDistributions;
    }

    function makeSwap(
        SwapInput calldata input,
        Swap calldata swap,
        SwapDistribution calldata swapDistribution
    )
        external
        payable
        virtual
        returns(uint256 returnAmount);

    function makePathSwap(
        SwapInput calldata input,
        Path calldata path,
        PathDistribution calldata pathDistribution
    )
        external
        payable
        virtual
        returns(uint256 returnAmount);

    function makeMultiPathSwap(
        SwapInput calldata input,
        Path[] calldata paths,
        PathDistribution[] calldata pathDistributions,
        SwapDistribution calldata interPathsDistribution
    )
        external
        payable
        virtual
        returns(uint256 returnAmount);
}

// File: contracts/ISource.sol


pragma solidity ^0.6.0;



interface ISource {
    function calculate(IERC20 fromToken, uint256[] calldata amounts, IOneRouterView.Swap calldata swap)
        external view returns(uint256[] memory rets, address dex, uint256 gas);

    function swap(IERC20 fromToken, IERC20 destToken, uint256 amount, uint256 flags) external;
}

// File: contracts/OneRouterConstants.sol


pragma solidity ^0.6.0;



contract OneRouterConstants {
    uint256 constant internal _FLAG_DISABLE_ALL_SOURCES          = 0x100000000000000000000000000000000;
    uint256 constant internal _FLAG_DISABLE_RECALCULATION        = 0x200000000000000000000000000000000;
    uint256 constant internal _FLAG_ENABLE_CHI_BURN              = 0x400000000000000000000000000000000;
    uint256 constant internal _FLAG_ENABLE_CHI_BURN_ORIGIN       = 0x800000000000000000000000000000000;
    uint256 constant internal _FLAG_ENABLE_REFERRAL_GAS_DISCOUNT = 0x1000000000000000000000000000000000;


    uint256 constant internal _FLAG_DISABLE_KYBER_ALL =
        _FLAG_DISABLE_KYBER_1 +
        _FLAG_DISABLE_KYBER_2 +
        _FLAG_DISABLE_KYBER_3 +
        _FLAG_DISABLE_KYBER_4;
    uint256 constant internal _FLAG_DISABLE_CURVE_ALL =
        _FLAG_DISABLE_CURVE_COMPOUND +
        _FLAG_DISABLE_CURVE_USDT +
        _FLAG_DISABLE_CURVE_Y +
        _FLAG_DISABLE_CURVE_BINANCE +
        _FLAG_DISABLE_CURVE_SYNTHETIX +
        _FLAG_DISABLE_CURVE_PAX +
        _FLAG_DISABLE_CURVE_RENBTC +
        _FLAG_DISABLE_CURVE_TBTC +
        _FLAG_DISABLE_CURVE_SBTC;
    uint256 constant internal _FLAG_DISABLE_BALANCER_ALL =
        _FLAG_DISABLE_BALANCER_1 +
        _FLAG_DISABLE_BALANCER_2 +
        _FLAG_DISABLE_BALANCER_3;
    uint256 constant internal _FLAG_DISABLE_BANCOR_ALL =
        _FLAG_DISABLE_BANCOR_1 +
        _FLAG_DISABLE_BANCOR_2 +
        _FLAG_DISABLE_BANCOR_3;

    uint256 constant internal _FLAG_DISABLE_UNISWAP_V1      = 0x1;
    uint256 constant internal _FLAG_DISABLE_UNISWAP_V2      = 0x2;
    uint256 constant internal _FLAG_DISABLE_MOONISWAP       = 0x4;
    uint256 constant internal _FLAG_DISABLE_KYBER_1         = 0x8;
    uint256 constant internal _FLAG_DISABLE_KYBER_2         = 0x10;
    uint256 constant internal _FLAG_DISABLE_KYBER_3         = 0x20;
    uint256 constant internal _FLAG_DISABLE_KYBER_4         = 0x40;
    uint256 constant internal _FLAG_DISABLE_CURVE_COMPOUND  = 0x80;
    uint256 constant internal _FLAG_DISABLE_CURVE_USDT      = 0x100;
    uint256 constant internal _FLAG_DISABLE_CURVE_Y         = 0x200;
    uint256 constant internal _FLAG_DISABLE_CURVE_BINANCE   = 0x400;
    uint256 constant internal _FLAG_DISABLE_CURVE_SYNTHETIX = 0x800;
    uint256 constant internal _FLAG_DISABLE_CURVE_PAX       = 0x1000;
    uint256 constant internal _FLAG_DISABLE_CURVE_RENBTC    = 0x2000;
    uint256 constant internal _FLAG_DISABLE_CURVE_TBTC      = 0x4000;
    uint256 constant internal _FLAG_DISABLE_CURVE_SBTC      = 0x8000;
    uint256 constant internal _FLAG_DISABLE_BALANCER_1      = 0x10000;
    uint256 constant internal _FLAG_DISABLE_BALANCER_2      = 0x20000;
    uint256 constant internal _FLAG_DISABLE_BALANCER_3      = 0x40000;
    uint256 constant internal _FLAG_DISABLE_BANCOR_1        = 0x80000;
    uint256 constant internal _FLAG_DISABLE_BANCOR_2        = 0x100000;
    uint256 constant internal _FLAG_DISABLE_BANCOR_3        = 0x200000;
    uint256 constant internal _FLAG_DISABLE_OASIS           = 0x400000;
    uint256 constant internal _FLAG_DISABLE_DFORCE_SWAP     = 0x800000;
    uint256 constant internal _FLAG_DISABLE_SHELL           = 0x1000000;
    uint256 constant internal _FLAG_DISABLE_MSTABLE_MUSD    = 0x2000000;
    uint256 constant internal _FLAG_DISABLE_BLACK_HOLE_SWAP = 0x4000000;

    IERC20 constant internal _DAI = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    IERC20 constant internal _USDC = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    IERC20 constant internal _USDT = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);
    IERC20 constant internal _TUSD = IERC20(0x0000000000085d4780B73119b644AE5ecd22b376);
    IERC20 constant internal _BUSD = IERC20(0x4Fabb145d64652a948d72533023f6E7A623C7C53);
    IERC20 constant internal _SUSD = IERC20(0x57Ab1ec28D129707052df4dF418D58a2D46d5f51);
    IERC20 constant internal _PAX = IERC20(0x8E870D67F660D95d5be530380D0eC0bd388289E1);
    IERC20 constant internal _RENBTC = IERC20(0xEB4C2781e4ebA804CE9a9803C67d0893436bB27D);
    IERC20 constant internal _WBTC = IERC20(0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599);
    IERC20 constant internal _SBTC = IERC20(0xfE18be6b3Bd88A2D2A7f928d00292E7a9963CfC6);
    IERC20 constant internal _CHI = IERC20(0x0000000000004946c0e9F43F4Dee607b0eF1fA1c);
}

// File: @openzeppelin/contracts/math/SafeMath.sol


pragma solidity ^0.6.0;

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

// File: contracts/libraries/Algo.sol


pragma solidity ^0.6.0;



library Algo {
    using SafeMath for uint256;

    int256 public constant VERY_NEGATIVE_VALUE = -1e72;

    function findBestDistribution(int256[][] memory amounts, uint256 parts)
        internal
        pure
        returns(
            int256[] memory returnAmounts,
            uint256[][] memory distributions
        )
    {
        uint256 n = amounts.length;

        int256[][] memory answer = new int256[][](n); // int[n][parts+1]
        uint256[][] memory parent = new uint256[][](n); // int[n][parts+1]

        for (uint i = 0; i < n; i++) {
            answer[i] = new int256[](parts + 1);
            parent[i] = new uint256[](parts + 1);
        }

        for (uint j = 0; j <= parts; j++) {
            answer[0][j] = amounts[0][j];
            for (uint i = 1; i < n; i++) {
                answer[i][j] = VERY_NEGATIVE_VALUE;
            }
            parent[0][j] = 0;
        }

        for (uint i = 1; i < n; i++) {
            for (uint j = 0; j <= parts; j++) {
                answer[i][j] = answer[i - 1][j];
                parent[i][j] = j;

                for (uint k = 1; k <= j; k++) {
                    if (answer[i - 1][j - k] + amounts[i][k] > answer[i][j]) {
                        answer[i][j] = answer[i - 1][j - k] + amounts[i][k];
                        parent[i][j] = j - k;
                    }
                }
            }
        }

        distributions = new uint256[][](parts);
        returnAmounts = new int256[](parts);
        for (uint256 i = 1; i <= parts; i++) {
            uint256 partsLeft = i;
            distributions[i - 1] = new uint256[](n);
            for (uint curExchange = n - 1; partsLeft > 0; curExchange--) {
                distributions[i - 1][curExchange] = partsLeft - parent[curExchange][partsLeft];
                partsLeft = parent[curExchange][partsLeft];
            }

            returnAmounts[i - 1] = (answer[n - 1][i] == VERY_NEGATIVE_VALUE) ? 0 : answer[n - 1][i];
        }
    }
}

// File: @openzeppelin/contracts/utils/Address.sol


pragma solidity ^0.6.2;

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
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
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
        return _functionCallWithValue(target, data, 0, errorMessage);
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
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
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

// File: contracts/libraries/Address2.sol


pragma solidity ^0.6.0;



library Address2 {
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(Address.isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
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


pragma solidity ^0.6.0;




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

// File: contracts/libraries/UniERC20.sol


pragma solidity ^0.6.0;





library UniERC20 {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 public constant ETH_ADDRESS = IERC20(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
    IERC20 public constant ZERO_ADDRESS = IERC20(0);

    function isETH(IERC20 token) internal pure returns(bool) {
        return (token == ZERO_ADDRESS || token == ETH_ADDRESS);
    }

    function uniBalanceOf(IERC20 token, address account) internal view returns (uint256) {
        if (isETH(token)) {
            return account.balance;
        } else {
            return token.balanceOf(account);
        }
    }

    function uniTransfer(IERC20 token, address payable to, uint256 amount) internal {
        if (amount > 0) {
            if (isETH(token)) {
                to.transfer(amount);
            } else {
                token.safeTransfer(to, amount);
            }
        }
    }

    function uniTransferFromSender(IERC20 token, address payable target, uint256 amount) internal {
        if (amount > 0) {
            if (isETH(token)) {
                require(msg.value >= amount, "UniERC20: not enough value");
                target.transfer(amount);
                if (msg.value > amount) {
                    // Return remainder if exist
                    msg.sender.transfer(msg.value.sub(amount));
                }
            } else {
                token.safeTransferFrom(msg.sender, target, amount);
            }
        }
    }

    function uniApprove(IERC20 token, address to, uint256 amount) internal {
        if (!isETH(token)) {
            if (amount == 0) {
                token.safeApprove(to, 0);
                return;
            }

            uint256 allowance = token.allowance(address(this), to);
            if (allowance < amount) {
                if (allowance > 0) {
                    token.safeApprove(to, 0);
                }
                token.safeApprove(to, amount);
            }
        }
    }

    function uniDecimals(IERC20 token) internal view returns (uint256) {
        if (isETH(token)) {
            return 18;
        }

        (bool success, bytes memory data) = address(token).staticcall{ gas: 20000 }(
            abi.encodeWithSignature("decimals()")
        );
        if (!success) {
            (success, data) = address(token).staticcall{ gas: 20000 }(
                abi.encodeWithSignature("DECIMALS()")
            );
        }

        return success ? abi.decode(data, (uint8)) : 18;
    }

    function uniSymbol(IERC20 token) internal view returns(string memory) {
        if (isETH(token)) {
            return "ETH";
        }

        (bool success, bytes memory data) = address(token).staticcall{ gas: 20000 }(
            abi.encodeWithSignature("symbol()")
        );
        if (!success) {
            (success, data) = address(token).staticcall{ gas: 20000 }(
                abi.encodeWithSignature("SYMBOL()")
            );
        }

        if (success && data.length >= 96) {
            (uint256 offset, uint256 len) = abi.decode(data, (uint256, uint256));
            if (offset == 0x20 && len > 0 && len <= 256) {
                return string(abi.decode(data, (bytes)));
            }
        }

        if (success && data.length == 32) {
            uint len = 0;
            while (len < data.length && data[len] >= 0x20 && data[len] <= 0x7E) {
                len++;
            }

            if (len > 0) {
                bytes memory result = new bytes(len);
                for (uint i = 0; i < len; i++) {
                    result[i] = data[i];
                }
                return string(result);
            }
        }

        return _toHex(address(token));
    }

    function _toHex(address account) private pure returns(string memory) {
        return _toHex(abi.encodePacked(account));
    }

    function _toHex(bytes memory data) private pure returns(string memory) {
        bytes memory str = new bytes(2 + data.length * 2);
        str[0] = "0";
        str[1] = "x";
        uint j = 2;
        for (uint i = 0; i < data.length; i++) {
            uint a = uint8(data[i]) >> 4;
            uint b = uint8(data[i]) & 0x0f;
            str[j++] = byte(uint8(a + 48 + (a/10)*39));
            str[j++] = byte(uint8(b + 48 + (b/10)*39));
        }

        return string(str);
    }
}

// File: contracts/libraries/RevertReason.sol


pragma solidity ^0.6.0;


library RevertReason {
    function parse(bytes memory data, string memory message) internal pure returns (string memory) {
        (, string memory reason) = abi.decode(abi.encodePacked(bytes28(0), data), (uint256, string));
        return string(abi.encodePacked(message, reason));
    }
}

// File: contracts/libraries/FlagsChecker.sol


pragma solidity ^0.6.0;


library FlagsChecker {
    function check(uint256 flags, uint256 flag) internal pure returns(bool) {
        return (flags & flag) != 0;
    }
}

// File: contracts/libraries/DynamicMemoryArray.sol


pragma solidity ^0.6.0;




library DynamicMemoryArray {
    using SafeMath for uint256;

    struct Addresses {
        uint256 length;
        address[1000] _arr;
    }

    function at(DynamicMemoryArray.Addresses memory self, uint256 index) internal pure returns(address) {
        require(index < self.length, "DynMemArr: out of range");
        return self._arr[index];
    }

    function push(DynamicMemoryArray.Addresses memory self, address item) internal pure returns(uint256) {
        require(self.length < self._arr.length, "DynMemArr: out of limit");
        self._arr[self.length++] = item;
        return self.length;
    }

    function pop(DynamicMemoryArray.Addresses memory self) internal pure returns(address) {
        require(self.length > 0, "DynMemArr: already empty");
        return self._arr[--self.length];
    }

    function copy(DynamicMemoryArray.Addresses memory self) internal pure returns(address[] memory arr) {
        arr = new address[](self.length);
        for (uint i = 0; i < arr.length; i++) {
            arr[i] = self._arr[i];
        }
    }
}

// File: contracts/sources/UniswapV1Source.sol


pragma solidity ^0.6.0;







contract UniswapV1SourceView {
    using SafeMath for uint256;
    using UniERC20 for IERC20;

    IUniswapV1Factory constant private _FACTORY = IUniswapV1Factory(0xc0a47dFe034B400B47bDaD5FecDa2621de6c4d95);

    function _calculateUniswapV1Formula(uint256 fromBalance, uint256 toBalance, uint256 amount) private pure returns(uint256) {
        if (amount > 0) {
            return amount.mul(toBalance).mul(997).div(
                fromBalance.mul(1000).add(amount.mul(997))
            );
        }
    }

    function _calculateUniswapV1(IERC20 fromToken, uint256[] memory amounts, IOneRouterView.Swap memory swap) internal view returns(uint256[] memory rets, address dex, uint256 gas) {
        rets = new uint256[](amounts.length);

        if (fromToken.isETH() || swap.destToken.isETH()) {
            IUniswapV1Exchange exchange = _FACTORY.getExchange(fromToken.isETH() ? swap.destToken : fromToken);
            if (exchange == IUniswapV1Exchange(0)) {
                return (rets, address(0), 0);
            }

            for (uint t = 0; t < swap.disabledDexes.length; t++) {
                if (swap.disabledDexes[t] == address(exchange)) {
                    return (rets, address(0), 0);
                }
            }

            uint256 fromBalance = fromToken.uniBalanceOf(address(exchange));
            uint256 destBalance = swap.destToken.uniBalanceOf(address(exchange));
            for (uint i = 0; i < amounts.length; i++) {
                rets[i] = _calculateUniswapV1Formula(fromBalance, destBalance, amounts[i]);
            }
            return (rets, address(exchange), 60_000);
        }
    }
}


contract UniswapV1SourceSwap {
    using UniERC20 for IERC20;

    IUniswapV1Factory constant private _FACTORY = IUniswapV1Factory(0xc0a47dFe034B400B47bDaD5FecDa2621de6c4d95);

    function _swapOnUniswapV1(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 /*flags*/
    ) internal {
        IUniswapV1Exchange exchange = _FACTORY.getExchange(fromToken.isETH() ? destToken : fromToken);
        fromToken.uniApprove(address(exchange), amount);
        if (fromToken.isETH()) {
            exchange.ethToTokenSwapInput{ value: amount }(1, block.timestamp);
        } else {
            exchange.tokenToEthSwapInput(amount, 1, block.timestamp);
        }
    }
}


contract UniswapV1SourcePublic is ISource, UniswapV1SourceView, UniswapV1SourceSwap {
    receive() external payable {
        // solhint-disable-next-line avoid-tx-origin
        require(msg.sender != tx.origin, "ETH deposit rejected");
    }

    function calculate(IERC20 fromToken, uint256[] memory amounts, IOneRouterView.Swap memory swap) public view override returns(uint256[] memory rets, address dex, uint256 gas) {
        return _calculateUniswapV1(fromToken, amounts, swap);
    }

    function swap(IERC20 fromToken, IERC20 destToken, uint256 amount, uint256 flags) public override {
        return _swapOnUniswapV1(fromToken, destToken, amount, flags);
    }
}

// File: @openzeppelin/contracts/math/Math.sol


pragma solidity ^0.6.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// File: contracts/interfaces/IWETH.sol


pragma solidity ^0.6.0;



abstract contract IWETH is IERC20 {
    function deposit() external payable virtual;
    function withdraw(uint256 amount) external virtual;
}

// File: contracts/sources/UniswapV2Source.sol


pragma solidity ^0.6.0;









library UniswapV2Helper {
    using Math for uint256;
    using SafeMath for uint256;
    using UniERC20 for IERC20;

    IUniswapV2Factory constant public FACTORY = IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);
    IWETH constant public WETH = IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    function getReturns(
        IUniswapV2Exchange exchange,
        IERC20 fromToken,
        IERC20 destToken,
        uint256[] memory amounts
    ) internal view returns (
        uint256[] memory results,
        uint256 reserveIn,
        uint256 reverseOut,
        bool needSync,
        bool needSkim
    ) {
        return _getReturns(
            exchange,
            fromToken.isETH() ? UniswapV2Helper.WETH : fromToken,
            destToken.isETH() ? UniswapV2Helper.WETH : destToken,
            amounts
        );
    }

    function _getReturns(
        IUniswapV2Exchange exchange,
        IERC20 fromToken,
        IERC20 destToken,
        uint256[] memory amounts
    ) private view returns (
        uint256[] memory results,
        uint256 reserveIn,
        uint256 reserveOut,
        bool needSync,
        bool needSkim
    ) {
        reserveIn = fromToken.uniBalanceOf(address(exchange));
        reserveOut = destToken.uniBalanceOf(address(exchange));
        (uint112 reserve0, uint112 reserve1,) = exchange.getReserves();
        if (fromToken > destToken) {
            (reserve0, reserve1) = (reserve1, reserve0);
        }
        needSync = (reserveIn < reserve0 || reserveOut < reserve1);
        needSkim = !needSync && (reserveIn > reserve0 || reserveOut > reserve1);

        reserveIn = Math.min(reserveIn, reserve0);
        reserveOut = Math.min(reserveOut, reserve1);

        results = new uint256[](amounts.length);
        for (uint i = 0; i < amounts.length; i++) {
            results[i] = calculateUniswapV2Formula(reserveIn, reserveOut, amounts[i]);
        }
    }

    function calculateUniswapV2Formula(uint256 reserveIn, uint256 reserveOut, uint256 amount) internal pure returns(uint256) {
        if (amount > 0) {
            return amount.mul(reserveOut).mul(997).div(
                reserveIn.mul(1000).add(amount.mul(997))
            );
        }
    }
}


contract UniswapV2SourceView {
    using SafeMath for uint256;
    using UniERC20 for IERC20;
    using UniswapV2Helper for IUniswapV2Exchange;

    function _calculateUniswapV2(IERC20 fromToken, uint256[] memory amounts, IOneRouterView.Swap memory swap) internal view returns(uint256[] memory rets, address dex, uint256 gas) {
        rets = new uint256[](amounts.length);

        IERC20 fromTokenWrapped = fromToken.isETH() ? UniswapV2Helper.WETH : fromToken;
        IERC20 destTokenWrapped = swap.destToken.isETH() ? UniswapV2Helper.WETH : swap.destToken;
        IUniswapV2Exchange exchange = UniswapV2Helper.FACTORY.getPair(fromTokenWrapped, destTokenWrapped);
        if (exchange == IUniswapV2Exchange(0)) {
            return (rets, address(0), 0);
        }

        for (uint t = 0; t < swap.disabledDexes.length; t++) {
            if (swap.disabledDexes[t] == address(exchange)) {
                return (rets, address(0), 0);
            }
        }

        (rets,,,,) = exchange.getReturns(fromToken, swap.destToken, amounts);
        return (rets, address(exchange), 50_000 + (fromToken.isETH() || swap.destToken.isETH() ? 0 : 30_000));
    }
}


contract UniswapV2SourceSwap {
    using UniERC20 for IERC20;
    using SafeMath for uint256;
    using UniswapV2Helper for IUniswapV2Exchange;

    function _swapOnUniswapV2(IERC20 fromToken, IERC20 destToken, uint256 amount, uint256 flags) internal {
        if (fromToken.isETH()) {
            UniswapV2Helper.WETH.deposit{ value: amount }();
        }

        _swapOnUniswapV2Wrapped(
            fromToken.isETH() ? UniswapV2Helper.WETH : fromToken,
            destToken.isETH() ? UniswapV2Helper.WETH : destToken,
            amount,
            flags
        );

        if (destToken.isETH()) {
            UniswapV2Helper.WETH.withdraw(UniswapV2Helper.WETH.balanceOf(address(this)));
        }
    }

    function _swapOnUniswapV2Wrapped(IERC20 fromToken, IERC20 destToken, uint256 amount, uint256 /*flags*/) private {
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = amount;

        IUniswapV2Exchange exchange = UniswapV2Helper.FACTORY.getPair(fromToken, destToken);
        (
            /*uint256[] memory returnAmounts*/,
            uint256 reserveIn,
            uint256 reserveOut,
            bool needSync,
            bool needSkim
        ) = exchange.getReturns(fromToken, destToken, amounts);

        if (needSync) {
            exchange.sync();
        }
        else if (needSkim) {
            exchange.skim(0x68a17B587CAF4f9329f0e372e3A78D23A46De6b5);
        }

        fromToken.uniTransfer(payable(address(exchange)), amount);
        uint256 confirmed = fromToken.uniBalanceOf(address(exchange)).sub(reserveIn);
        uint256 returnAmount = UniswapV2Helper.calculateUniswapV2Formula(reserveIn, reserveOut, confirmed);

        if (fromToken < destToken) {
            exchange.swap(0, returnAmount, address(this), "");
        } else {
            exchange.swap(returnAmount, 0, address(this), "");
        }
    }
}


contract UniswapV2SourcePublic is ISource, UniswapV2SourceView, UniswapV2SourceSwap {
    function calculate(IERC20 fromToken, uint256[] memory amounts, IOneRouterView.Swap memory swap) public view override returns(uint256[] memory rets, address dex, uint256 gas) {
        return _calculateUniswapV2(fromToken, amounts, swap);
    }

    function swap(IERC20 fromToken, IERC20 destToken, uint256 amount, uint256 flags) public override {
        return _swapOnUniswapV2(fromToken, destToken, amount, flags);
    }
}

// File: contracts/interfaces/IMooniswap.sol


pragma solidity ^0.6.0;



interface IMooniswapRegistry {
    function pools(IERC20 token1, IERC20 token2) external view returns(IMooniswap);
    function isPool(address addr) external view returns(bool);
}


interface IMooniswap {
    function fee() external view returns (uint256);
    function tokens(uint256 i) external view returns (IERC20);
    function getBalanceForAddition(IERC20 token) external view returns(uint256);
    function getBalanceForRemoval(IERC20 token) external view returns(uint256);
    function getReturn(IERC20 fromToken, IERC20 destToken, uint256 amount) external view returns(uint256 returnAmount);

    function deposit(uint256[] calldata amounts, uint256[] calldata minAmounts) external payable returns(uint256 fairSupply);
    function withdraw(uint256 amount, uint256[] calldata minReturns) external;
    function swap(IERC20 fromToken, IERC20 destToken, uint256 amount, uint256 minReturn, address referral) external payable returns(uint256 returnAmount);
}

// File: contracts/sources/MooniswapSource.sol


pragma solidity ^0.6.0;







library MooniswapHelper {
    using SafeMath for uint256;
    using UniERC20 for IERC20;

    IMooniswapRegistry constant public REGISTRY = IMooniswapRegistry(0x71CD6666064C3A1354a3B4dca5fA1E2D3ee7D303);

    function getReturn(
        IMooniswap mooniswap,
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount
    ) internal view returns(uint256 ret) {
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = amount;
        uint256[] memory rets = getReturns(mooniswap, fromToken, destToken, amounts);
        if (rets.length > 0) {
            return rets[0];
        }
    }

    function getReturns(
        IMooniswap mooniswap,
        IERC20 fromToken,
        IERC20 destToken,
        uint256[] memory amounts
    ) internal view returns(uint256[] memory rets) {
        rets = new uint256[](amounts.length);

        uint256 fee = mooniswap.fee();
        uint256 fromBalance = mooniswap.getBalanceForAddition(fromToken.isETH() ? UniERC20.ZERO_ADDRESS : fromToken);
        uint256 destBalance = mooniswap.getBalanceForRemoval(destToken.isETH() ? UniERC20.ZERO_ADDRESS : destToken);
        if (fromBalance > 0 && destBalance > 0) {
            for (uint i = 0; i < amounts.length; i++) {
                uint256 amount = amounts[i].sub(amounts[i].mul(fee).div(1e18));
                rets[i] = amount.mul(destBalance).div(
                    fromBalance.add(amount)
                );
            }
        }
    }
}


contract MooniswapSourceView {
    using SafeMath for uint256;
    using UniERC20 for IERC20;
    using MooniswapHelper for IMooniswap;

    function _calculateMooniswap(IERC20 fromToken, uint256[] memory amounts, IOneRouterView.Swap memory swap) internal view returns(uint256[] memory rets, address dex, uint256 gas) {
        IMooniswap mooniswap = MooniswapHelper.REGISTRY.pools(
            fromToken.isETH() ? UniERC20.ZERO_ADDRESS : fromToken,
            swap.destToken.isETH() ? UniERC20.ZERO_ADDRESS : swap.destToken
        );
        if (mooniswap == IMooniswap(0)) {
            return (new uint256[](0), address(0), 0);
        }

        for (uint t = 0; t < swap.disabledDexes.length; t++) {
            if (swap.disabledDexes[t] == address(mooniswap)) {
                return (new uint256[](0), address(0), 0);
            }
        }

        rets = mooniswap.getReturns(fromToken, swap.destToken, amounts);
        if (rets.length == 0 || rets[0] == 0) {
            return (new uint256[](0), address(0), 0);
        }

        return (rets, address(mooniswap), (fromToken.isETH() || swap.destToken.isETH()) ? 80_000 : 110_000);
    }
}


contract MooniswapSourceSwap {
    using UniERC20 for IERC20;

    function _swapOnMooniswap(IERC20 fromToken, IERC20 destToken, uint256 amount, uint256 /*flags*/) internal {
        IMooniswap mooniswap = MooniswapHelper.REGISTRY.pools(
            fromToken.isETH() ? UniERC20.ZERO_ADDRESS : fromToken,
            destToken.isETH() ? UniERC20.ZERO_ADDRESS : destToken
        );

        fromToken.uniApprove(address(mooniswap), amount);
        mooniswap.swap{ value: fromToken.isETH() ? amount : 0 }(
            fromToken.isETH() ? UniERC20.ZERO_ADDRESS : fromToken,
            destToken.isETH() ? UniERC20.ZERO_ADDRESS : destToken,
            amount,
            0,
            0x68a17B587CAF4f9329f0e372e3A78D23A46De6b5
        );
    }
}


contract MooniswapSourcePublic is ISource, MooniswapSourceView, MooniswapSourceSwap {
    receive() external payable {
        // solhint-disable-next-line avoid-tx-origin
        require(msg.sender != tx.origin, "ETH deposit rejected");
    }

    function calculate(IERC20 fromToken, uint256[] memory amounts, IOneRouterView.Swap memory swap) public view override returns(uint256[] memory rets, address dex, uint256 gas) {
        return _calculateMooniswap(fromToken, amounts, swap);
    }

    function swap(IERC20 fromToken, IERC20 destToken, uint256 amount, uint256 flags) public override {
        return _swapOnMooniswap(fromToken, destToken, amount, flags);
    }
}

// File: contracts/interfaces/IKyber.sol


pragma solidity ^0.6.0;



interface IKyberStorage {
    function getReserveIdsPerTokenSrc(IERC20 token) external view returns (bytes32[] memory);
    function getReserveAddressesByReserveId(bytes32 reserveId) external view returns (IKyberReserve[] memory reserveAddresses);
}


interface IKyberReserve {
    function getConversionRate(IERC20 src, IERC20 dest, uint srcQty, uint blockNumber) external view returns(uint);
}


interface IKyberHintHandler {
    enum TradeType {
        BestOfAll,
        MaskIn,
        MaskOut,
        Split
    }

    function buildTokenToEthHint(
        IERC20 tokenSrc,
        TradeType tokenToEthType,
        bytes32[] calldata tokenToEthReserveIds,
        uint256[] calldata tokenToEthSplits
    ) external view returns (bytes memory hint);

    function buildEthToTokenHint(
        IERC20 tokenDest,
        TradeType ethToTokenType,
        bytes32[] calldata ethToTokenReserveIds,
        uint256[] calldata ethToTokenSplits
    ) external view returns (bytes memory hint);
}


interface IKyberNetworkProxy {
    function getExpectedRateAfterFee(
        IERC20 src,
        IERC20 dest,
        uint256 srcQty,
        uint256 platformFeeBps,
        bytes calldata hint
    ) external view returns (uint256 expectedRate);

    function tradeWithHintAndFee(
        IERC20 src,
        uint256 srcAmount,
        IERC20 dest,
        address payable destAddress,
        uint256 maxDestAmount,
        uint256 minConversionRate,
        address payable platformWallet,
        uint256 platformFeeBps,
        bytes calldata hint
    ) external payable returns (uint256 destAmount);
}

// File: contracts/sources/KyberSource.sol


pragma solidity ^0.6.0;









library KyberHelper {
    using UniERC20 for IERC20;

    IKyberNetworkProxy constant public PROXY = IKyberNetworkProxy(0x9AAb3f75489902f3a48495025729a0AF77d4b11e);
    IKyberStorage constant public STORAGE = IKyberStorage(0xC8fb12402cB16970F3C5F4b48Ff68Eb9D1289301);
    IKyberHintHandler constant public HINT_HANDLER = IKyberHintHandler(0xa1C0Fa73c39CFBcC11ec9Eb1Afc665aba9996E2C);

    // https://github.com/CryptoManiacsZone/1inchProtocol/blob/master/KyberReserves.md
    bytes1 constant public RESERVE_BRIDGE_PREFIX = 0xbb;
    bytes32 constant public RESERVE_ID_1 = 0xff4b796265722046707200000000000000000000000000000000000000000000; // 0x63825c174ab367968EC60f061753D3bbD36A0D8F
    bytes32 constant public RESERVE_ID_2 = 0xffabcd0000000000000000000000000000000000000000000000000000000000; // 0x7a3370075a54B187d7bD5DceBf0ff2B5552d4F7D
    bytes32 constant public RESERVE_ID_3 = 0xff4f6e65426974205175616e7400000000000000000000000000000000000000; // 0x4f32BbE8dFc9efD54345Fc936f9fEF1048746fCF

    function getReserveId(IERC20 fromToken, IERC20 destToken) internal view returns(bytes32) {
        if (fromToken.isETH() || destToken.isETH()) {
            bytes32[] memory reserveIds = STORAGE.getReserveIdsPerTokenSrc(
                fromToken.isETH() ? destToken : fromToken
            );

            for (uint i = 0; i < reserveIds.length; i++) {
                if (reserveIds[i][0] != RESERVE_BRIDGE_PREFIX &&
                    reserveIds[i] != RESERVE_ID_1 &&
                    reserveIds[i] != RESERVE_ID_2 &&
                    reserveIds[i] != RESERVE_ID_3)
                {
                    return reserveIds[i];
                }
            }
        }
    }
}


contract KyberSourceView is OneRouterConstants {
    using SafeMath for uint256;
    using UniERC20 for IERC20;
    using FlagsChecker for uint256;

    function _calculateKyber1(IERC20 fromToken, uint256[] memory amounts, IOneRouterView.Swap memory swap) internal view returns(uint256[] memory rets, address dex, uint256 gas) {
        return _calculateKyber(fromToken, amounts, swap, KyberHelper.RESERVE_ID_1);
    }

    function _calculateKyber2(IERC20 fromToken, uint256[] memory amounts, IOneRouterView.Swap memory swap) internal view returns(uint256[] memory rets, address dex, uint256 gas) {
        return _calculateKyber(fromToken, amounts, swap, KyberHelper.RESERVE_ID_2);
    }

    function _calculateKyber3(IERC20 fromToken, uint256[] memory amounts, IOneRouterView.Swap memory swap) internal view returns(uint256[] memory rets, address dex, uint256 gas) {
        return _calculateKyber(fromToken, amounts, swap, KyberHelper.RESERVE_ID_3);
    }

    function _calculateKyber4(IERC20 fromToken, uint256[] memory amounts, IOneRouterView.Swap memory swap) internal view returns(uint256[] memory rets, address dex, uint256 gas) {
        bytes32 reserveId = KyberHelper.getReserveId(fromToken, swap.destToken);
        if (reserveId != 0) {
            return _calculateKyber(fromToken, amounts, swap, reserveId);
        }
    }

    // Fix for "Stack too deep"
    struct Decimals {
        uint256 fromTokenDecimals;
        uint256 destTokenDecimals;
    }

    function _calculateKyber(IERC20 fromToken, uint256[] memory amounts, IOneRouterView.Swap memory swap, bytes32 reserveId) private view returns(uint256[] memory rets, address dex, uint256 gas) {
        rets = new uint256[](amounts.length);

        IKyberReserve reserve = KyberHelper.STORAGE.getReserveAddressesByReserveId(reserveId)[0];

        for (uint t = 0; t < swap.disabledDexes.length; t++) {
            if (swap.disabledDexes[t] == address(reserve)) {
                return (rets, address(0), 0);
            }
        }

        Decimals memory decimals = Decimals({
            fromTokenDecimals: 10 ** IERC20(fromToken).uniDecimals(),
            destTokenDecimals: 10 ** IERC20(swap.destToken).uniDecimals()
        });
        for (uint i = 0; i < amounts.length; i++) {
            if (i > 0 && rets[i - 1] == 0) {
                break;
            }

            uint256 amount = amounts[0].mul(uint256(1e18).sub((swap.flags >> 255) * 1e15)).div(1e18);
            try reserve.getConversionRate(
                fromToken.isETH() ? UniERC20.ETH_ADDRESS : fromToken,
                swap.destToken.isETH() ? UniERC20.ETH_ADDRESS : swap.destToken,
                amount,
                block.number
            )
            returns(uint256 rate) {
                uint256 preResult = amounts[i].mul(rate).mul(decimals.destTokenDecimals);
                rets[i] = preResult.div(decimals.fromTokenDecimals).div(1e18);
            } catch {
            }
        }

        return (rets, address(reserve), 100_000);
    }
}


contract KyberSourceSwap {
    using UniERC20 for IERC20;

    function _swapOnKyber1(IERC20 fromToken, IERC20 destToken, uint256 amount, uint256 flags) internal {
        _swapOnKyber(fromToken, destToken, amount, flags, KyberHelper.RESERVE_ID_1);
    }

    function _swapOnKyber2(IERC20 fromToken, IERC20 destToken, uint256 amount, uint256 flags) internal {
        _swapOnKyber(fromToken, destToken, amount, flags, KyberHelper.RESERVE_ID_2);
    }

    function _swapOnKyber3(IERC20 fromToken, IERC20 destToken, uint256 amount, uint256 flags) internal {
        _swapOnKyber(fromToken, destToken, amount, flags, KyberHelper.RESERVE_ID_3);
    }

    function _swapOnKyber4(IERC20 fromToken, IERC20 destToken, uint256 amount, uint256 flags) internal {
        _swapOnKyber(fromToken, destToken, amount, flags, KyberHelper.getReserveId(fromToken, destToken));
    }

    function _swapOnKyber(IERC20 fromToken, IERC20 destToken, uint256 amount, uint256 flags, bytes32 reserveId) internal {
        bytes32[] memory reserveIds = new bytes32[](1);
        reserveIds[0] = reserveId;

        bytes memory hint;
        if (fromToken.isETH()) {
            hint = KyberHelper.HINT_HANDLER.buildEthToTokenHint(destToken, IKyberHintHandler.TradeType.MaskIn, reserveIds, new uint256[](0));
        }
        else {
            hint = KyberHelper.HINT_HANDLER.buildTokenToEthHint(fromToken, IKyberHintHandler.TradeType.MaskIn, reserveIds, new uint256[](0));
        }

        fromToken.uniApprove(address(KyberHelper.PROXY), amount);
        KyberHelper.PROXY.tradeWithHintAndFee{ value: fromToken.isETH() ? amount : 0 }(
            fromToken,
            amount,
            destToken,
            payable(address(this)),
            uint256(-1),
            0,
            0x68a17B587CAF4f9329f0e372e3A78D23A46De6b5,
            (flags >> 255) * 10,
            hint
        );
    }

    function _kyberGetHint(IERC20 fromToken, IERC20 destToken, bytes32 reserveId) private view returns(bytes memory) {
        bytes32[] memory reserveIds = new bytes32[](1);
        reserveIds[0] = reserveId;

        if (fromToken.isETH()) {
            try KyberHelper.HINT_HANDLER.buildEthToTokenHint(destToken, IKyberHintHandler.TradeType.MaskIn, reserveIds, new uint256[](0))
            returns (bytes memory data) {
                return data;
            } catch {}
        }

        if (destToken.isETH()) {
            try KyberHelper.HINT_HANDLER.buildTokenToEthHint(fromToken, IKyberHintHandler.TradeType.MaskIn, reserveIds, new uint256[](0))
            returns (bytes memory data) {
                return data;
            } catch {}
        }
    }
}


contract KyberSourcePublic1 is ISource, KyberSourceView, KyberSourceSwap {
    receive() external payable {
        // solhint-disable-next-line avoid-tx-origin
        require(msg.sender != tx.origin, "ETH deposit rejected");
    }

    function calculate(IERC20 fromToken, uint256[] memory amounts, IOneRouterView.Swap memory swap) public view override returns(uint256[] memory rets, address dex, uint256 gas) {
        return _calculateKyber1(fromToken, amounts, swap);
    }

    function swap(IERC20 fromToken, IERC20 destToken, uint256 amount, uint256 flags) public override {
        return _swapOnKyber1(fromToken, destToken, amount, flags);
    }
}


contract KyberSourcePublic2 is ISource, KyberSourceView, KyberSourceSwap {
    receive() external payable {
        // solhint-disable-next-line avoid-tx-origin
        require(msg.sender != tx.origin, "ETH deposit rejected");
    }

    function calculate(IERC20 fromToken, uint256[] memory amounts, IOneRouterView.Swap memory swap) public view override returns(uint256[] memory rets, address dex, uint256 gas) {
        return _calculateKyber2(fromToken, amounts, swap);
    }

    function swap(IERC20 fromToken, IERC20 destToken, uint256 amount, uint256 flags) public override {
        return _swapOnKyber2(fromToken, destToken, amount, flags);
    }
}


contract KyberSourcePublic3 is ISource, KyberSourceView, KyberSourceSwap {
    receive() external payable {
        // solhint-disable-next-line avoid-tx-origin
        require(msg.sender != tx.origin, "ETH deposit rejected");
    }

    function calculate(IERC20 fromToken, uint256[] memory amounts, IOneRouterView.Swap memory swap) public view override returns(uint256[] memory rets, address dex, uint256 gas) {
        return _calculateKyber3(fromToken, amounts, swap);
    }

    function swap(IERC20 fromToken, IERC20 destToken, uint256 amount, uint256 flags) public override {
        return _swapOnKyber3(fromToken, destToken, amount, flags);
    }
}


contract KyberSourcePublic4 is ISource, KyberSourceView, KyberSourceSwap {
    receive() external payable {
        // solhint-disable-next-line avoid-tx-origin
        require(msg.sender != tx.origin, "ETH deposit rejected");
    }

    function calculate(IERC20 fromToken, uint256[] memory amounts, IOneRouterView.Swap memory swap) public view override returns(uint256[] memory rets, address dex, uint256 gas) {
        return _calculateKyber4(fromToken, amounts, swap);
    }

    function swap(IERC20 fromToken, IERC20 destToken, uint256 amount, uint256 flags) public override {
        return _swapOnKyber4(fromToken, destToken, amount, flags);
    }
}

// File: contracts/interfaces/ICurve.sol


pragma solidity ^0.6.0;


interface ICurve {
    // solhint-disable-next-line func-name-mixedcase
    function get_dy_underlying(int128 i, int128 j, uint256 dx) external view returns(uint256 dy);

    // solhint-disable-next-line func-name-mixedcase
    function get_dy(int128 i, int128 j, uint256 dx) external view returns(uint256 dy);

    // solhint-disable-next-line func-name-mixedcase
    function exchange_underlying(int128 i, int128 j, uint256 dx, uint256 minDy) external;

    // solhint-disable-next-line func-name-mixedcase
    function exchange(int128 i, int128 j, uint256 dx, uint256 minDy) external;
}


interface ICurveRegistry {
    // solhint-disable-next-line func-name-mixedcase
    function get_pool_info(address pool)
        external
        view
        returns(
            uint256[8] memory balances,
            uint256[8] memory underlyingBalances,
            uint256[8] memory decimals,
            uint256[8] memory underlyingDecimals,
            address lpToken,
            uint256 a,
            uint256 fee
        );
}


interface ICurveCalculator {
    // solhint-disable-next-line func-name-mixedcase
    function get_dy(
        int128 nCoins,
        uint256[8] calldata balances,
        uint256 amp,
        uint256 fee,
        uint256[8] calldata rates,
        uint256[8] calldata precisions,
        bool underlying,
        int128 i,
        int128 j,
        uint256[100] calldata dx
    ) external view returns(uint256[100] memory dy);
}

// File: contracts/sources/CurveSource.sol


pragma solidity ^0.6.0;









library CurveHelper {
    ICurve constant public CURVE_COMPOUND = ICurve(0xA2B47E3D5c44877cca798226B7B8118F9BFb7A56);
    ICurve constant public CURVE_USDT = ICurve(0x52EA46506B9CC5Ef470C5bf89f17Dc28bB35D85C);
    ICurve constant public CURVE_Y = ICurve(0x45F783CCE6B7FF23B2ab2D70e416cdb7D6055f51);
    ICurve constant public CURVE_BINANCE = ICurve(0x79a8C46DeA5aDa233ABaFFD40F3A0A2B1e5A4F27);
    ICurve constant public CURVE_SYNTHETIX = ICurve(0xA5407eAE9Ba41422680e2e00537571bcC53efBfD);
    ICurve constant public CURVE_PAX = ICurve(0x06364f10B501e868329afBc005b3492902d6C763);
    ICurve constant public CURVE_RENBTC = ICurve(0x93054188d876f558f4a66B2EF1d97d16eDf0895B);
    ICurve constant public CURVE_SBTC = ICurve(0x7fC77b5c7614E1533320Ea6DDc2Eb61fa00A9714);

    function dynarr(IERC20[2] memory tokens) internal pure returns(IERC20[] memory result) {
        result = new IERC20[](tokens.length);
        for (uint i = 0; i < tokens.length; i++) {
            result[i] = tokens[i];
        }
    }

    function dynarr(IERC20[3] memory tokens) internal pure returns(IERC20[] memory result) {
        result = new IERC20[](tokens.length);
        for (uint i = 0; i < tokens.length; i++) {
            result[i] = tokens[i];
        }
    }

    function dynarr(IERC20[4] memory tokens) internal pure returns(IERC20[] memory result) {
        result = new IERC20[](tokens.length);
        for (uint i = 0; i < tokens.length; i++) {
            result[i] = tokens[i];
        }
    }
}


contract CurveSourceView is OneRouterConstants {
    using SafeMath for uint256;
    using UniERC20 for IERC20;
    using FlagsChecker for uint256;

    ICurveCalculator constant private _CURVE_CALCULATOR = ICurveCalculator(0xc1DB00a8E5Ef7bfa476395cdbcc98235477cDE4E);
    ICurveRegistry constant private _CURVE_REGISTRY = ICurveRegistry(0x7002B727Ef8F5571Cb5F9D70D13DBEEb4dFAe9d1);

    function _calculateCurveCompound(IERC20 fromToken, uint256[] memory amounts, IOneRouterView.Swap memory swap) internal view returns(uint256[] memory rets, address dex, uint256 gas) {
        return (_calculateCurveSelector(fromToken, swap, amounts, CurveHelper.CURVE_COMPOUND, true, CurveHelper.dynarr([_DAI, _USDC])), address(CurveHelper.CURVE_COMPOUND), 720_000);
    }

    function _calculateCurveUSDT(IERC20 fromToken, uint256[] memory amounts, IOneRouterView.Swap memory swap) internal view returns(uint256[] memory rets, address dex, uint256 gas) {
        return (_calculateCurveSelector(fromToken, swap, amounts, CurveHelper.CURVE_USDT, true, CurveHelper.dynarr([_DAI, _USDC, _USDT])), address(CurveHelper.CURVE_USDT), 720_000);
    }

    function _calculateCurveY(IERC20 fromToken, uint256[] memory amounts, IOneRouterView.Swap memory swap) internal view returns(uint256[] memory rets, address dex, uint256 gas) {
        return (_calculateCurveSelector(fromToken, swap, amounts, CurveHelper.CURVE_Y, true, CurveHelper.dynarr([_DAI, _USDC, _USDT, _TUSD])), address(CurveHelper.CURVE_Y), 1_400_000);
    }

    function _calculateCurveBinance(IERC20 fromToken, uint256[] memory amounts, IOneRouterView.Swap memory swap) internal view returns(uint256[] memory rets, address dex, uint256 gas) {
        return (_calculateCurveSelector(fromToken, swap, amounts, CurveHelper.CURVE_BINANCE, true, CurveHelper.dynarr([_DAI, _USDC, _USDT, _BUSD])), address(CurveHelper.CURVE_BINANCE), 1_400_000);
    }

    function _calculateCurveSynthetix(IERC20 fromToken, uint256[] memory amounts, IOneRouterView.Swap memory swap) internal view returns(uint256[] memory rets, address dex, uint256 gas) {
        return (_calculateCurveSelector(fromToken, swap, amounts, CurveHelper.CURVE_SYNTHETIX, true, CurveHelper.dynarr([_DAI, _USDC, _USDT, _SUSD])), address(CurveHelper.CURVE_SYNTHETIX), 200_000);
    }

    function _calculateCurvePAX(IERC20 fromToken, uint256[] memory amounts, IOneRouterView.Swap memory swap) internal view returns(uint256[] memory rets, address dex, uint256 gas) {
        return (_calculateCurveSelector(fromToken, swap, amounts, CurveHelper.CURVE_PAX, true, CurveHelper.dynarr([_DAI, _USDC, _USDT, _PAX])), address(CurveHelper.CURVE_PAX), 1_000_000);
    }

    function _calculateCurveRENBTC(IERC20 fromToken, uint256[] memory amounts, IOneRouterView.Swap memory swap) internal view returns(uint256[] memory rets, address dex, uint256 gas) {
        return (_calculateCurveSelector(fromToken, swap, amounts, CurveHelper.CURVE_RENBTC, false, CurveHelper.dynarr([_RENBTC, _WBTC])), address(CurveHelper.CURVE_RENBTC), 130_000);
    }

    function _calculateCurveSBTC(IERC20 fromToken, uint256[] memory amounts, IOneRouterView.Swap memory swap) internal view returns(uint256[] memory rets, address dex, uint256 gas) {
        return (_calculateCurveSelector(fromToken, swap, amounts, CurveHelper.CURVE_SBTC, false, CurveHelper.dynarr([_RENBTC, _WBTC, _SBTC])), address(CurveHelper.CURVE_SBTC), 150_000);
    }

    function _calculateCurveSelector(
        IERC20 fromToken,
        IOneRouterView.Swap memory swap,
        uint256[] memory amounts,
        ICurve curve,
        bool haveUnderlying,
        IERC20[] memory tokens
    ) private view returns(uint256[] memory rets) {
        rets = new uint256[](amounts.length);

        for (uint t = 0; t < swap.disabledDexes.length; t++) {
            if (swap.disabledDexes[t] == address(curve)) {
                return rets;
            }
        }

        int128 i = 0;
        int128 j = 0;
        for (uint t = 0; t < tokens.length; t++) {
            if (fromToken == tokens[t]) {
                i = int128(t + 1);
            }
            if (swap.destToken == tokens[t]) {
                j = int128(t + 1);
            }
        }

        if (i == 0 || j == 0) {
            return rets;
        }

        bytes memory data = abi.encodePacked(
            uint256(haveUnderlying ? 1 : 0),
            uint256(i - 1),
            uint256(j - 1),
            _toFixedArray100(amounts)
        );

        (
            uint256[8] memory balances,
            uint256[8] memory precisions,
            uint256[8] memory rates,
            uint256 amp,
            uint256 fee
        ) = _getCurvePoolInfo(curve, haveUnderlying);

        bool success;
        (success, data) = address(_CURVE_CALCULATOR).staticcall(
            abi.encodePacked(
                abi.encodeWithSelector(
                    _CURVE_CALCULATOR.get_dy.selector,
                    tokens.length,
                    balances,
                    amp,
                    fee,
                    rates,
                    precisions
                ),
                data
            )
        );

        if (!success || data.length == 0) {
            return rets;
        }

        uint256[100] memory dy = abi.decode(data, (uint256[100]));
        for (uint t = 0; t < amounts.length; t++) {
            rets[t] = dy[t];
        }
    }

    function _getCurvePoolInfo(
        ICurve curve,
        bool haveUnderlying
    ) private view returns(
        uint256[8] memory balances,
        uint256[8] memory precisions,
        uint256[8] memory rates,
        uint256 amp,
        uint256 fee
    ) {
        uint256[8] memory underlyingBalances;
        uint256[8] memory decimals;
        uint256[8] memory underlyingDecimals;

        (
            balances,
            underlyingBalances,
            decimals,
            underlyingDecimals,
            /*address lpToken*/,
            amp,
            fee
        ) = _CURVE_REGISTRY.get_pool_info(address(curve));

        for (uint k = 0; k < 8 && balances[k] > 0; k++) {
            precisions[k] = 10 ** (18 - (haveUnderlying ? underlyingDecimals : decimals)[k]);
            if (haveUnderlying) {
                rates[k] = underlyingBalances[k].mul(1e18).div(balances[k]);
            } else {
                rates[k] = 1e18;
            }
        }
    }

    function _toFixedArray100(uint256[] memory values) private pure returns(uint256[100] memory rets) {
        for (uint i = 0; i < values.length; i++) {
            rets[i] = values[i];
        }
    }
}


contract CurveSourceSwap is OneRouterConstants {
    using UniERC20 for IERC20;

    function _swapOnCurveCompound(IERC20 fromToken, IERC20 destToken, uint256 amount, uint256 /*flags*/) internal {
        _swapOnCurve(CurveHelper.CURVE_COMPOUND, true, CurveHelper.dynarr([_DAI, _USDC]), fromToken, destToken, amount);
    }

    function _swapOnCurveUSDT(IERC20 fromToken, IERC20 destToken, uint256 amount, uint256 /*flags*/) internal {
        _swapOnCurve(CurveHelper.CURVE_USDT, true, CurveHelper.dynarr([_DAI, _USDC, _USDT]), fromToken, destToken, amount);
    }

    function _swapOnCurveY(IERC20 fromToken, IERC20 destToken, uint256 amount, uint256 /*flags*/) internal {
        _swapOnCurve(CurveHelper.CURVE_Y, true, CurveHelper.dynarr([_DAI, _USDC, _USDT, _TUSD]), fromToken, destToken, amount);
    }

    function _swapOnCurveBinance(IERC20 fromToken, IERC20 destToken, uint256 amount, uint256 /*flags*/) internal {
        _swapOnCurve(CurveHelper.CURVE_BINANCE, true, CurveHelper.dynarr([_DAI, _USDC, _USDT, _BUSD]), fromToken, destToken, amount);
    }

    function _swapOnCurveSynthetix(IERC20 fromToken, IERC20 destToken, uint256 amount, uint256 /*flags*/) internal {
        _swapOnCurve(CurveHelper.CURVE_SYNTHETIX, true, CurveHelper.dynarr([_DAI, _USDC, _USDT, _SUSD]), fromToken, destToken, amount);
    }

    function _swapOnCurvePAX(IERC20 fromToken, IERC20 destToken, uint256 amount, uint256 /*flags*/) internal {
        _swapOnCurve(CurveHelper.CURVE_PAX, true, CurveHelper.dynarr([_DAI, _USDC, _USDT, _PAX]), fromToken, destToken, amount);
    }

    function _swapOnCurveRENBTC(IERC20 fromToken, IERC20 destToken, uint256 amount, uint256 /*flags*/) internal {
        _swapOnCurve(CurveHelper.CURVE_RENBTC, false, CurveHelper.dynarr([_RENBTC, _WBTC]), fromToken, destToken, amount);
    }

    function _swapOnCurveSBTC(IERC20 fromToken, IERC20 destToken, uint256 amount, uint256 /*flags*/) internal {
        _swapOnCurve(CurveHelper.CURVE_SBTC, false, CurveHelper.dynarr([_RENBTC, _WBTC, _SBTC]), fromToken, destToken, amount);
    }

    function _swapOnCurve(
        ICurve curve,
        bool underlying,
        IERC20[] memory tokens,
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount
    ) private {
        int128 i = 0;
        int128 j = 0;
        for (uint t = 0; t < tokens.length; t++) {
            if (fromToken == tokens[t]) {
                i = int128(t + 1);
            }
            if (destToken == tokens[t]) {
                j = int128(t + 1);
            }
        }

        fromToken.uniApprove(address(curve), amount);
        if (underlying) {
            curve.exchange_underlying(i - 1, j - 1, amount, 0);
        } else {
            curve.exchange(i - 1, j - 1, amount, 0);
        }
    }
}


contract CurveSourcePublicCompound is ISource, CurveSourceView, CurveSourceSwap {
    function calculate(IERC20 fromToken, uint256[] memory amounts, IOneRouterView.Swap memory swap) public view override returns(uint256[] memory rets, address dex, uint256 gas) {
        return _calculateCurveCompound(fromToken, amounts, swap);
    }

    function swap(IERC20 fromToken, IERC20 destToken, uint256 amount, uint256 flags) public override {
        return _swapOnCurveCompound(fromToken, destToken, amount, flags);
    }
}


contract CurveSourcePublicUSDT is ISource, CurveSourceView, CurveSourceSwap {
    function calculate(IERC20 fromToken, uint256[] memory amounts, IOneRouterView.Swap memory swap) public view override returns(uint256[] memory rets, address dex, uint256 gas) {
        return _calculateCurveUSDT(fromToken, amounts, swap);
    }

    function swap(IERC20 fromToken, IERC20 destToken, uint256 amount, uint256 flags) public override {
        return _swapOnCurveUSDT(fromToken, destToken, amount, flags);
    }
}


contract CurveSourcePublicY is ISource, CurveSourceView, CurveSourceSwap {
    function calculate(IERC20 fromToken, uint256[] memory amounts, IOneRouterView.Swap memory swap) public view override returns(uint256[] memory rets, address dex, uint256 gas) {
        return _calculateCurveY(fromToken, amounts, swap);
    }

    function swap(IERC20 fromToken, IERC20 destToken, uint256 amount, uint256 flags) public override {
        return _swapOnCurveY(fromToken, destToken, amount, flags);
    }
}


contract CurveSourcePublicBinance is ISource, CurveSourceView, CurveSourceSwap {
    function calculate(IERC20 fromToken, uint256[] memory amounts, IOneRouterView.Swap memory swap) public view override returns(uint256[] memory rets, address dex, uint256 gas) {
        return _calculateCurveBinance(fromToken, amounts, swap);
    }

    function swap(IERC20 fromToken, IERC20 destToken, uint256 amount, uint256 flags) public override {
        return _swapOnCurveBinance(fromToken, destToken, amount, flags);
    }
}


contract CurveSourcePublicSynthetix is ISource, CurveSourceView, CurveSourceSwap {
    function calculate(IERC20 fromToken, uint256[] memory amounts, IOneRouterView.Swap memory swap) public view override returns(uint256[] memory rets, address dex, uint256 gas) {
        return _calculateCurveSynthetix(fromToken, amounts, swap);
    }

    function swap(IERC20 fromToken, IERC20 destToken, uint256 amount, uint256 flags) public override {
        return _swapOnCurveSynthetix(fromToken, destToken, amount, flags);
    }
}


contract CurveSourcePublicPAX is ISource, CurveSourceView, CurveSourceSwap {
    function calculate(IERC20 fromToken, uint256[] memory amounts, IOneRouterView.Swap memory swap) public view override returns(uint256[] memory rets, address dex, uint256 gas) {
        return _calculateCurvePAX(fromToken, amounts, swap);
    }

    function swap(IERC20 fromToken, IERC20 destToken, uint256 amount, uint256 flags) public override {
        return _swapOnCurvePAX(fromToken, destToken, amount, flags);
    }
}


contract CurveSourcePublicRENBTC is ISource, CurveSourceView, CurveSourceSwap {
    function calculate(IERC20 fromToken, uint256[] memory amounts, IOneRouterView.Swap memory swap) public view override returns(uint256[] memory rets, address dex, uint256 gas) {
        return _calculateCurveRENBTC(fromToken, amounts, swap);
    }

    function swap(IERC20 fromToken, IERC20 destToken, uint256 amount, uint256 flags) public override {
        return _swapOnCurveRENBTC(fromToken, destToken, amount, flags);
    }
}


contract CurveSourcePublicSBTC is ISource, CurveSourceView, CurveSourceSwap {
    function calculate(IERC20 fromToken, uint256[] memory amounts, IOneRouterView.Swap memory swap) public view override returns(uint256[] memory rets, address dex, uint256 gas) {
        return _calculateCurveSBTC(fromToken, amounts, swap);
    }

    function swap(IERC20 fromToken, IERC20 destToken, uint256 amount, uint256 flags) public override {
        return _swapOnCurveSBTC(fromToken, destToken, amount, flags);
    }
}

// File: contracts/OneRouter.sol


pragma solidity ^0.6.0;




















// import "./sources/BalancerSource.sol";


contract PathsAdvisor is OneRouterConstants {
    using UniERC20 for IERC20;

    IAaveRegistry constant private _AAVE_REGISTRY = IAaveRegistry(0xEd8b133B7B88366E01Bb9E38305Ab11c26521494);
    ICompoundRegistry constant private _COMPOUND_REGISTRY = ICompoundRegistry(0xF451Dbd7Ba14BFa7B1B78A766D3Ed438F79EE1D1);

    function getPathsForTokens(IERC20 fromToken, IERC20 destToken) external view returns(IERC20[][] memory paths) {
        IERC20[4] memory midTokens = [_DAI, _USDC, _USDT, _WBTC];
        paths = new IERC20[][](2 + midTokens.length);

        IERC20 aFromToken = _AAVE_REGISTRY.aTokenByToken(fromToken);
        IERC20 aDestToken = _AAVE_REGISTRY.aTokenByToken(destToken);
        if (aFromToken != IERC20(0)) {
            aFromToken = _COMPOUND_REGISTRY.cTokenByToken(fromToken);
        }
        if (aDestToken != IERC20(0)) {
            aDestToken = _COMPOUND_REGISTRY.cTokenByToken(destToken);
        }

        uint index = 0;
        paths[index] = new IERC20[](0);
        index++;

        if (!fromToken.isETH() && !aFromToken.isETH() && !destToken.isETH() && !aDestToken.isETH()) {
            paths[index] = new IERC20[](1);
            paths[index][0] = UniERC20.ETH_ADDRESS;
            index++;
        }

        for (uint i = 0; i < midTokens.length; i++) {
            if (fromToken != midTokens[i] && aFromToken != midTokens[i] && destToken != midTokens[i] && aDestToken != midTokens[i]) {
                paths[index] = new IERC20[](
                    1 +
                    ((aFromToken != IERC20(0)) ? 1 : 0) +
                    ((aDestToken != IERC20(0)) ? 1 : 0)
                );

                paths[index][0] = aFromToken;
                paths[index][paths[index].length / 2] = midTokens[i];
                if (aDestToken != IERC20(0)) {
                    paths[index][paths[index].length - 1] = aDestToken;
                }
                index++;
            }
        }

        IERC20[][] memory paths2 = new IERC20[][](index);
        for (uint i = 0; i < paths2.length; i++) {
            paths2[i] = paths[i];
        }
        paths = paths2;
    }
}


contract HotSwapSources is Ownable {
    uint256 public sourcesCount = 15;
    mapping(uint256 => ISource) public sources;
    PathsAdvisor public pathsAdvisor;

    constructor() public {
        pathsAdvisor = new PathsAdvisor();
    }

    function setSource(uint256 index, ISource source) external onlyOwner {
        require(index <= sourcesCount, "Router: index is too high");
        sources[index] = source;
        sourcesCount = Math.max(sourcesCount, index + 1);
    }

    function setPathsForTokens(PathsAdvisor newPathsAdvisor) external onlyOwner {
        pathsAdvisor = newPathsAdvisor;
    }

    function _getPathsForTokens(IERC20 fromToken, IERC20 destToken) internal view returns(IERC20[][] memory paths) {
        return pathsAdvisor.getPathsForTokens(fromToken, destToken);
    }
}


contract OneRouterView is
    OneRouterConstants,
    IOneRouterView,
    HotSwapSources,
    UniswapV1SourceView,
    UniswapV2SourceView,
    MooniswapSourceView,
    KyberSourceView,
    CurveSourceView
    // BalancerSourceView
{
    using UniERC20 for IERC20;
    using SafeMath for uint256;
    using FlagsChecker for uint256;
    using DynamicMemoryArray for DynamicMemoryArray.Addresses;

    function getReturn(IERC20 fromToken, uint256[] memory amounts, Swap memory swap)
        public
        view
        override
        returns(
            Path[] memory paths,
            PathResult[] memory pathResults,
            SwapResult memory splitResult
        )
    {
        IERC20[][] memory midTokens = _getPathsForTokens(fromToken, swap.destToken);

        paths = new Path[](midTokens.length);
        pathResults = new PathResult[](paths.length);
        DynamicMemoryArray.Addresses memory disabledDexes;
        for (uint i = 0; i < paths.length; i++) {
            paths[i] = Path({swaps: new Swap[](1 + midTokens[i - 1].length)});
            for (uint j = 0; j < midTokens[i - 1].length; j++) {
                if (fromToken == midTokens[i - 1][j] || swap.destToken == midTokens[i - 1][j]) {
                    paths[i] = Path({swaps: new Swap[](1)});
                    break;
                }

                paths[i].swaps[j] = Swap({
                    destToken: midTokens[i - 1][j],
                    flags: swap.flags,
                    destTokenEthPriceTimesGasPrice: _scaleDestTokenEthPriceTimesGasPrice(fromToken, midTokens[i - 1][j], swap.destTokenEthPriceTimesGasPrice),
                    disabledDexes: disabledDexes.copy()
                });
            }
            paths[i].swaps[paths[i].swaps.length - 1] = swap;

            pathResults[i] = getPathReturn(fromToken, amounts, paths[i]);
            for (uint j = 0; j < pathResults[i].swaps.length; j++) {
                for (uint k = 0; k < pathResults[i].swaps[j].dexes.length; k++) {
                    for (uint t = 0; t < pathResults[i].swaps[j].dexes[k].length; t++) {
                        if (pathResults[i].swaps[j].dexes[k][t] != address(0)) {
                            disabledDexes.push(pathResults[i].swaps[j].dexes[k][t]);
                        }
                    }
                }
            }
        }

        splitResult = bestDistributionAmongPaths(paths, pathResults);
    }

    function getMultiPathReturn(IERC20 fromToken, uint256[] memory amounts, Path[] memory paths)
        public
        view
        override
        returns(
            PathResult[] memory pathResults,
            SwapResult memory splitResult
        )
    {
        pathResults = new PathResult[](paths.length);
        for (uint i = 0; i < paths.length; i++) {
            pathResults[i] = getPathReturn(fromToken, amounts, paths[i]);
        }
        splitResult = bestDistributionAmongPaths(paths, pathResults);
    }

    function bestDistributionAmongPaths(Path[] memory paths, PathResult[] memory pathResults) public pure returns(SwapResult memory) {
        uint256[][] memory input = new uint256[][](paths.length);
        uint256[][] memory gases = new uint256[][](paths.length);
        uint256[][] memory costs = new uint256[][](paths.length);
        for (uint i = 0; i < pathResults.length; i++) {
            Swap memory subSwap = paths[i].swaps[paths[i].swaps.length - 1];
            SwapResult memory swapResult = pathResults[i].swaps[pathResults[i].swaps.length - 1];

            input[i] = new uint256[](swapResult.returnAmounts.length);
            gases[i] = new uint256[](swapResult.returnAmounts.length);
            costs[i] = new uint256[](swapResult.returnAmounts.length);
            for (uint j = 0; j < swapResult.returnAmounts.length; j++) {
                input[i][j] = swapResult.returnAmounts[j];
                gases[i][j] = swapResult.estimateGasAmounts[j];
                costs[i][j] = swapResult.estimateGasAmounts[j].mul(subSwap.destTokenEthPriceTimesGasPrice).div(1e18);
            }
        }
        return _findBestDistribution(input, costs, gases, input[0].length);
    }

    function getPathReturn(IERC20 fromToken, uint256[] memory amounts, Path memory path)
        public
        view
        override
        returns(PathResult memory result)
    {
        result.swaps = new SwapResult[](path.swaps.length);

        for (uint i = 0; i < path.swaps.length; i++) {
            result.swaps[i] = getSwapReturn(fromToken, amounts, path.swaps[i]);
            fromToken = path.swaps[i].destToken;
            amounts = result.swaps[i].returnAmounts;
        }
    }

    function getSwapReturn(IERC20 fromToken, uint256[] memory amounts, Swap memory swap)
        public
        view
        override
        returns(SwapResult memory result)
    {
        if (fromToken == swap.destToken) {
            result.returnAmounts = amounts;
            return result;
        }

        function(IERC20,uint256[] memory,Swap memory) view returns(uint256[] memory, address, uint256)[15] memory reserves = [
            _calculateUniswapV1,
            _calculateUniswapV2,
            _calculateMooniswap,
            _calculateKyber1,
            _calculateKyber2,
            _calculateKyber3,
            _calculateKyber4,
            _calculateCurveCompound,
            _calculateCurveUSDT,
            _calculateCurveY,
            _calculateCurveBinance,
            _calculateCurveSynthetix,
            _calculateCurvePAX,
            _calculateCurveRENBTC,
            _calculateCurveSBTC
            // _calculateBalancer1,
            // _calculateBalancer2,
            // _calculateBalancer3,
            // calculateBancor,
            // calculateOasis,
            // calculateDforceSwap,
            // calculateShell,
            // calculateMStableMUSD,
            // calculateBlackHoleSwap
        ];

        uint256[][] memory input = new uint256[][](sourcesCount);
        uint256[][] memory gases = new uint256[][](sourcesCount);
        uint256[][] memory costs = new uint256[][](sourcesCount);
        bool disableAll = swap.flags.check(_FLAG_DISABLE_ALL_SOURCES);
        for (uint i = 0; i < sourcesCount; i++) {
            uint256 gas;
            if (disableAll == swap.flags.check(1 << i)) {
                if (sources[i] != ISource(0)) {
                    (input[i], , gas) = sources[i].calculate(fromToken, amounts, swap);
                }
                else if (i < reserves.length) {
                    (input[i], , gas) = reserves[i](fromToken, amounts, swap);
                }
            }

            gases[i] = new uint256[](amounts.length);
            costs[i] = new uint256[](amounts.length);
            uint256 fee = gas.mul(swap.destTokenEthPriceTimesGasPrice).div(1e18);
            for (uint j = 0; j < amounts.length; j++) {
                gases[i][j] = gas;
                costs[i][j] = fee;
            }
        }

        result = _findBestDistribution(input, costs, gases, amounts.length);
    }

    function _calculateNoReturn(IERC20 fromToken, uint256[] memory amounts, IOneRouterView.Swap memory swap)
        private view returns(uint256[] memory rets, uint256 gas)
    {
    }

    function _scaleDestTokenEthPriceTimesGasPrice(IERC20 fromToken, IERC20 destToken, uint256 destTokenEthPriceTimesGasPrice) private view returns(uint256) {
        if (fromToken == destToken) {
            return destTokenEthPriceTimesGasPrice;
        }

        uint256 mul = _cheapGetPrice(UniERC20.ETH_ADDRESS, destToken, 0.001 ether);
        uint256 div = _cheapGetPrice(UniERC20.ETH_ADDRESS, fromToken, 0.001 ether);
        return (div == 0) ? 0 : destTokenEthPriceTimesGasPrice.mul(mul).div(div);
    }

    function _cheapGetPrice(IERC20 fromToken, IERC20 destToken, uint256 amount) private view returns(uint256 returnAmount) {
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = amount;

        uint256 flags = _FLAG_DISABLE_RECALCULATION |
            _FLAG_DISABLE_ALL_SOURCES |
            _FLAG_DISABLE_UNISWAP_V1 |
            _FLAG_DISABLE_UNISWAP_V2;

        return this.getSwapReturn(
            fromToken,
            amounts,
            Swap({
                destToken: destToken,
                flags: flags,
                destTokenEthPriceTimesGasPrice: 0,
                disabledDexes: new address[](0)
            })
        ).returnAmounts[0];
    }

    function _findBestDistribution(uint256[][] memory input, uint256[][] memory costs, uint256[][] memory gases, uint256 parts)
        private pure returns(SwapResult memory result)
    {
        int256[][] memory matrix = new int256[][](input.length);
        for (uint i = 0; i < input.length; i++) {
            matrix[i] = new int256[](1 + parts);
            matrix[i][0] = Algo.VERY_NEGATIVE_VALUE;
            for (uint j = 0; j < parts; j++) {
                matrix[i][j + 1] =
                    (j < input[i].length && input[i][j] != 0)
                    ? int256(input[i][j]) - int256(costs[i][j])
                    : Algo.VERY_NEGATIVE_VALUE;
            }
        }

        (, result.distributions) = Algo.findBestDistribution(matrix, parts);

        result.returnAmounts = new uint256[](parts);
        result.estimateGasAmounts = new uint256[](parts);
        for (uint i = 0; i < input.length; i++) {
            for (uint j = 0; j < parts; j++) {
                if (result.distributions[j][i] > 0) {
                    uint256 index = result.distributions[j][i] - 1;
                    result.returnAmounts[j] = result.returnAmounts[j].add(index < input[i].length ? input[i][index] : 0);
                    result.estimateGasAmounts[j] = result.estimateGasAmounts[j].add(gases[i][j]);
                }
            }
        }
    }
}


contract OneRouter is
    OneRouterConstants,
    IOneRouter,
    HotSwapSources,
    UniswapV1SourceSwap,
    UniswapV2SourceSwap,
    MooniswapSourceSwap,
    KyberSourceSwap,
    CurveSourceSwap
    // BalancerSourceSwap
{
    using UniERC20 for IERC20;
    using SafeMath for uint256;
    using Address2 for address;
    using FlagsChecker for uint256;

    IOneRouterView public oneRouterView;

    constructor(IOneRouterView _oneRouterView) public {
        oneRouterView = _oneRouterView;
    }

    receive() external payable {
        // solhint-disable-next-line avoid-tx-origin
        require(msg.sender != tx.origin, "ETH deposit rejected");
    }

    function getReturn(
        IERC20 fromToken,
        uint256[] calldata amounts,
        Swap calldata swap
    )
        external
        view
        override
        returns(
            Path[] memory paths,
            PathResult[] memory pathResults,
            SwapResult memory splitResult
        )
    {
        return oneRouterView.getReturn(fromToken, amounts, swap);
    }

    function getSwapReturn(
        IERC20 fromToken,
        uint256[] calldata amounts,
        Swap calldata swap
    )
        external
        view
        override
        returns(SwapResult memory result)
    {
        return oneRouterView.getSwapReturn(fromToken, amounts, swap);
    }

    function getPathReturn(
        IERC20 fromToken,
        uint256[] calldata amounts,
        Path calldata path
    )
        external
        view
        override
        returns(PathResult memory result)
    {
        return oneRouterView.getPathReturn(fromToken, amounts, path);
    }

    function getMultiPathReturn(
        IERC20 fromToken,
        uint256[] calldata amounts,
        Path[] calldata paths
    )
        external
        view
        override
        returns(
            PathResult[] memory pathResults,
            SwapResult memory splitResult
        )
    {
        return oneRouterView.getMultiPathReturn(fromToken, amounts, paths);
    }

    function makeSwap(
        SwapInput memory input,
        Swap memory swap,
        SwapDistribution memory swapDistribution
    )
        public
        payable
        override
        returns(uint256 returnAmount)
    {
        Path memory path = Path({
            swaps: new IOneRouterView.Swap[](1)
        });
        path.swaps[0] = swap;

        PathDistribution memory pathDistribution = PathDistribution({
            swapDistributions: new SwapDistribution[](1)
        });
        pathDistribution.swapDistributions[0] = swapDistribution;

        return makePathSwap(input, path, pathDistribution);
    }

    function makePathSwap(
        SwapInput memory input,
        Path memory path,
        PathDistribution memory pathDistribution
    )
        public
        payable
        override
        returns(uint256 returnAmount)
    {
        Path[] memory paths = new Path[](1);
        paths[0] = path;

        PathDistribution[] memory pathDistributions = new PathDistribution[](1);
        pathDistributions[0] = pathDistribution;

        SwapDistribution memory swapDistribution = SwapDistribution({
            weights: new uint256[](1)
        });
        swapDistribution.weights[0] = 1;

        return makeMultiPathSwap(input, paths, pathDistributions, swapDistribution);
    }

    struct Indexes {
        uint p; // path
        uint s; // swap
        uint i; // index
    }

    function makeMultiPathSwap(
        SwapInput memory input,
        Path[] memory paths,
        PathDistribution[] memory pathDistributions,
        SwapDistribution memory interPathsDistribution
    )
        public
        payable
        override
        returns(uint256 returnAmount)
    {
        require(msg.value == (input.fromToken.isETH() ? input.amount : 0), "Wrong msg.value");
        require(paths.length == pathDistributions.length, "Wrong arrays length");
        require(paths.length == interPathsDistribution.weights.length, "Wrong arrays length");

        input.fromToken.uniTransferFromSender(address(this), input.amount);

        function(IERC20,IERC20,uint256,uint256)[15] memory reserves = [
            _swapOnUniswapV1,
            _swapOnUniswapV2,
            _swapOnMooniswap,
            _swapOnKyber1,
            _swapOnKyber2,
            _swapOnKyber3,
            _swapOnKyber4,
            _swapOnCurveCompound,
            _swapOnCurveUSDT,
            _swapOnCurveY,
            _swapOnCurveBinance,
            _swapOnCurveSynthetix,
            _swapOnCurvePAX,
            _swapOnCurveRENBTC,
            _swapOnCurveSBTC
            // _swapOnBalancer1,
            // _swapOnBalancer2,
            // _swapOnBalancer3,
            // _swapOnBancor,
            // _swapOnOasis,
            // _swapOnDforceSwap,
            // _swapOnShell,
            // _swapOnMStableMUSD,
            // _swapOnBlackHoleSwap
        ];

        uint256 interTotalWeight = 0;
        for (uint i = 0; i < interPathsDistribution.weights.length; i++) {
            interTotalWeight = interTotalWeight.add(interPathsDistribution.weights[i]);
        }

        Indexes memory z;
        for (z.p = 0; z.p < pathDistributions.length && interTotalWeight > 0; z.p++) {
            uint256 confirmed = input.fromToken.uniBalanceOf(address(this))
                    .mul(interPathsDistribution.weights[z.p])
                    .div(interTotalWeight);
            interTotalWeight = interTotalWeight.sub(interPathsDistribution.weights[z.p]);

            IERC20 token = input.fromToken;
            for (z.s = 0; z.s < pathDistributions[z.p].swapDistributions.length; z.s++) {
                uint256 totalSwapWeight = 0;
                for (z.i = 0; z.i < pathDistributions[z.p].swapDistributions[z.s].weights.length; z.i++) {
                    totalSwapWeight = totalSwapWeight.add(pathDistributions[z.p].swapDistributions[z.s].weights[z.i]);
                }

                for (z.i = 0; z.i < pathDistributions[z.p].swapDistributions[z.s].weights.length && totalSwapWeight > 0; z.i++) {
                    uint256 amount = ((z.s == 0) ? confirmed : token.uniBalanceOf(address(this)))
                        .mul(pathDistributions[z.p].swapDistributions[z.s].weights[z.i])
                        .div(totalSwapWeight);
                    totalSwapWeight = totalSwapWeight.sub(pathDistributions[z.p].swapDistributions[z.s].weights[z.i]);

                    if (sources[z.i] != ISource(0)) {
                        address(sources[z.i]).functionDelegateCall(
                            abi.encodeWithSelector(
                                sources[z.i].swap.selector,
                                input.fromToken,
                                input.destToken,
                                amount,
                                paths[z.p].swaps[z.s].flags
                            ),
                            "Delegatecall failed"
                        );
                    }
                    else if (z.i < reserves.length) {
                        reserves[z.i](input.fromToken, input.destToken, amount, paths[z.p].swaps[z.s].flags);
                    }
                }

                token = paths[z.p].swaps[z.s].destToken;
            }
        }

        uint256 remaining = input.fromToken.uniBalanceOf(address(this));
        returnAmount = input.destToken.uniBalanceOf(address(this));
        require(returnAmount >= input.minReturn, "Min returns is not enough");
        input.fromToken.uniTransfer(msg.sender, remaining);
        input.destToken.uniTransfer(msg.sender, returnAmount);
    }
}