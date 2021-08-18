/**
 *Submitted for verification at polygonscan.com on 2021-08-18
*/

// File: polygon_contracts/interfaces/IBEP20.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address _owner, address spender)
        external
        view
        returns (uint256);

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// File: polygon_contracts/interfaces/IPancakeV2.sol


pragma solidity ^0.8.0;


interface IUniRouter {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

interface IUniswapV2Factory {
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function getPair(IBEP20 tokenA, IBEP20 tokenB)
        external
        view
        returns (IUniswapV2Exchange pair);
}

interface IUniswapV2Exchange {
    //event Approval(address indexed owner, address indexed spender, uint value);
    //event Transfer(address indexed from, address indexed to, uint value);

    //function name() external pure returns (string memory);
    //function symbol() external pure returns (string memory);
    //function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function getReserves()
        external
        view
        returns (
            uint112 _reserve0,
            uint112 _reserve1,
            uint32 _blockTimestampLast
        );

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

    function token0() external view returns (address);

    function token1() external view returns (address);

    //function allowance(address owner, address spender) external view returns (uint);
    //function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint256 value) external returns (bool);

    //function transferFrom(address from, address to, uint value) external returns (bool);
    //function DOMAIN_SEPARATOR() external view returns (bytes32);
    //function PERMIT_TYPEHASH() external pure returns (bytes32);
    //function nonces(address owner) external view returns (uint);

    //function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    //event Mint(address indexed sender, uint amount0, uint amount1);
    //event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    /*event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);

function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
    */
}

// File: polygon_contracts/utils/PancakeV2Lib.sol


pragma solidity ^0.8.0;


contract UniswapUtils {
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB)
        internal
        pure
        returns (address token0, address token1)
    {
        (token0, token1) = tokenA < tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);
    }
}

library UniswapV2ExchangeLib {
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function getReturn(
        IUniswapV2Exchange exchange,
        IBEP20 fromToken,
        IBEP20 destToken,
        uint256 amountIn
    )
        internal
        view
        returns (
            uint256 result,
            bool needSync,
            bool needSkim
        )
    {
        uint256 reserveIn = fromToken.balanceOf(address(exchange));
        uint256 reserveOut = destToken.balanceOf(address(exchange));
        (uint112 reserve0, uint112 reserve1, ) = exchange.getReserves();
        if (fromToken > destToken) {
            (reserve0, reserve1) = (reserve1, reserve0);
        }
        needSync = (reserveIn < reserve0 || reserveOut < reserve1);
        needSkim = !needSync && (reserveIn > reserve0 || reserveOut > reserve1);

        uint256 amountInWithFee = amountIn * 997;
        uint256 numerator = amountInWithFee * min(reserveOut, reserve1);
        uint256 denominator = min(reserveIn, reserve0) * 1000 + amountInWithFee;
        result = (denominator == 0) ? 0 : numerator / denominator;
    }
}

// File: polygon_contracts/interfaces/ICurve.sol



pragma solidity ^0.8.0;

abstract contract ICurveFiCurve {
    function exchange(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy
    ) external virtual;

    /*
    function exchange_underlying(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy
    ) external virtual;
    */

    function exchange_underlying(
        uint256 i,
        uint256 j,
        uint256 dx,
        uint256 min_dy
    ) external virtual;

    function get_dy_underlying(
        int128 i,
        int128 j,
        uint256 dx
    ) external view virtual returns (uint256 out);

    function get_dy_underlying(
        uint256 i,
        uint256 j,
        uint256 dx
    ) external view virtual returns (uint256 out);

    function get_dy(
        int128 i,
        int128 j,
        uint256 dx
    ) external view virtual returns (uint256 out);

    function calculateSwap(
        uint8 i,
        uint8 j,
        uint256 dx
    ) external view virtual returns (uint256 out);

    function swap(
        uint8 i,
        uint8 j,
        uint256 dx,
        uint256 min_dy,
        uint256 deadline
    ) external virtual;

    function A() external view virtual returns (uint256);

    function balances(uint256 arg0) external view virtual returns (uint256);

    function balances(int128 arg0) external view virtual returns (uint256);

    function getTokenBalance(uint8 arg0)
        external
        view
        virtual
        returns (uint256);

    function fee() external view virtual returns (uint256);
}

// File: polygon_contracts/utils/CurvedPolygon.sol


pragma solidity ^0.8.0;


/**
 * @dev reverse-engineered utils to help Curve amount calculations
 */
contract CurveUtils {
    address internal constant CURVE_AAVE =
        0x445FE580eF8d70FF569aB36e80c647af338db351;

    address internal constant CURVE_3POOL =
        0x751B1e21756bDbc307CBcC5085c042a0e9AaEf36;

    address internal constant CURVE_3CRYPTO =
        0x3FCD5De6A9fC8A99995c406c77DDa3eD7E406f81;
    address internal constant IRON = 0x837503e8A8753ae17fB8C8151B8e6f586defCb57;

    address internal constant DAI_ADDRESS =
        0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063;
    address internal constant USDC_ADDRESS =
        0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
    address internal constant USDT_ADDRESS =
        0xc2132D05D31c914a87C6611C10748AEb04B58e8F;
    address internal constant WBTC_ADDRESS =
        0x1BFD67037B42Cf73acF2047067bd4F2C47D9BfD6;
    address internal constant ETH_ADDRESS =
        0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619;

    mapping(address => mapping(address => int8)) internal curveIndex;

    //mapping(address => mapping(int8 => address)) internal reverseCurveIndex;

    /**
     * @dev get index of a token in Curve pool contract
     */
    function getCurveIndex(address curve, address token)
        internal
        view
        returns (int8)
    {
        // to avoid 'stack too deep' compiler issue
        return curveIndex[curve][token] - 1;
    }

    /**
     * @dev init internal variables at creation
     */
    function init() public virtual {
        curveIndex[CURVE_AAVE][DAI_ADDRESS] = 1; // actual index is 1 less
        curveIndex[CURVE_AAVE][USDC_ADDRESS] = 2;
        curveIndex[CURVE_AAVE][USDT_ADDRESS] = 3;

        /*
        reverseCurveIndex[CURVE_AAVE][1] = DAI_ADDRESS;
        reverseCurveIndex[CURVE_AAVE][2] = USDC_ADDRESS;
        reverseCurveIndex[CURVE_AAVE][3] = USDT_ADDRESS;
        */

        curveIndex[CURVE_3CRYPTO][DAI_ADDRESS] = 1; // actual index is 1 less
        curveIndex[CURVE_3CRYPTO][USDC_ADDRESS] = 2;
        curveIndex[CURVE_3CRYPTO][USDT_ADDRESS] = 3; // 1-3 is from base pool
        curveIndex[CURVE_3CRYPTO][WBTC_ADDRESS] = 4;
        curveIndex[CURVE_3CRYPTO][ETH_ADDRESS] = 5;
        /*
        reverseCurveIndex[CURVE_3CRYPTO][1] = DAI_ADDRESS;
        reverseCurveIndex[CURVE_3CRYPTO][2] = USDC_ADDRESS;
        reverseCurveIndex[CURVE_3CRYPTO][3] = USDT_ADDRESS;
        reverseCurveIndex[CURVE_3CRYPTO][4] = WBTC_ADDRESS;
        reverseCurveIndex[CURVE_3CRYPTO][5] = ETH_ADDRESS;
        */

        curveIndex[IRON][USDC_ADDRESS] = 1; // actual index is 1 less
        curveIndex[IRON][USDT_ADDRESS] = 2;
        curveIndex[IRON][DAI_ADDRESS] = 3;
        /*
        reverseCurveIndex[IRON][0] = USDC_ADDRESS;
        reverseCurveIndex[IRON][1] = USDT_ADDRESS;
        reverseCurveIndex[IRON][2] = DAI_ADDRESS;
        */
    }
}

// File: polygon_contracts/access/Context.sol


pragma solidity ^0.8.0;

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
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: polygon_contracts/access/Ownable.sol



pragma solidity ^0.8.0;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function initialize() internal {
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
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    /*
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }*/

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: polygon_contracts/interfaces/IWETH.sol



pragma solidity ^0.8.0;

interface IWETH {
    function deposit() external payable;

    function withdraw(uint256 wad) external;

    function balanceOf(address account) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);
}

// File: polygon_contracts/XPentagon.sol


pragma solidity ^0.8.0;







//import "./interfaces/IMDEX.sol";

/**
 * @title XPentagon exchanger contract for Polygon
 * @dev this is an implementation of a split exchange that takes the input amount and proposes a better price
 * given the liquidity obtained from multiple AMM DEX exchanges considering their liquidity at the moment
 * might also help mitigating a flashloan attack
 */
contract XPentagon is Ownable, CurveUtils, UniswapUtils {
    //using Address for address;
    using UniswapV2ExchangeLib for IUniswapV2Exchange;

    IBEP20 private constant ZERO =
        IBEP20(0x0000000000000000000000000000000000000000);
    //IBEP20 private constant ETH_ADDRESS =
    //    IBEP20(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
    IBEP20 private constant WMATIC_TOKEN =
        IBEP20(0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270);

    address private constant QUICKSWAP_FACTORY =
        0x5757371414417b8C6CAad45bAeF941aBc7d3Ab32;

    address private constant SUSHISWAP_FACTORY =
        0xc35DADB65012eC5796536bD9864eD8773aBc74C4;

    address private constant DFYN_FACTORY =
        0xE7Fb3e833eFE5F9c441105EB65Ef8b261266423B;

    address private constant BONUS_ADDRESS =
        0x8c545be506a335e24145EdD6e01D2754296ff018;
    IWETH internal constant WMATIC = IWETH(address(WMATIC_TOKEN));

    uint256 private constant PC_DENOMINATOR = 1e5;
    address[] private exchanges = [
        QUICKSWAP_FACTORY,
        SUSHISWAP_FACTORY,
        DFYN_FACTORY,
        CURVE_3CRYPTO,
        IRON
    ];

    address[] private viaTokens = [
        address(WMATIC_TOKEN),
        ETH_ADDRESS,
        USDC_ADDRESS
    ];

    uint256 private constant ex_count = 5;
    uint256 public slippageFee; //1000 = 1% slippage
    uint256 public minPc;

    bool private initialized;

    /** @dev helper to identify if we work with BNB
     */
    function isMATIC(IBEP20 token) internal pure returns (bool) {
        return (address(token) == address(ZERO));
    }

    /** @dev helper to identify if we work with wmatic
     */
    function isWMATIC(IBEP20 token) internal pure returns (bool) {
        return (address(token) == address(WMATIC_TOKEN));
    }

    /** @dev helper to identify if we work with BNB or wmatic
     */
    function isofMATIC(IBEP20 token) internal pure returns (bool) {
        return (address(token) == address(ZERO) ||
            address(token) == address(WMATIC_TOKEN));
    }

    /**
     * @dev initializer method instead of a constructor - though we don't normally use proxy here we still might want to
     */
    function init() public virtual override {
        require(!initialized, "Initialized");
        initialized = true;
        Ownable.initialize(); // Do not forget this call!
        _init();
    }

    /**
     * @dev internal variable initialization
     */
    function _init() internal virtual {
        slippageFee = 1000; //1%
        minPc = 15000; // 10%
        CurveUtils.init();
    }

    /**
     * @dev re-initializer might be helpful for the cases where proxy's storage is corrupted by an old contact, but we cannot run init as we have the owner address already.
     * This method might help fixing the storage state.
     */
    function reInit() public virtual onlyOwner {
        _init();
    }

    /**
     * @dev set the slippage %%
     */
    function setMinPc(uint256 _minPC) external onlyOwner {
        minPc = _minPC;
    }

    /**
     * @dev set the slippage %%
     */
    function setSlippageFee(uint256 _slippageFee) external onlyOwner {
        slippageFee = _slippageFee;
    }

    /**
     * @dev universal method to get the given AMM address reserves
     */
    function getReserves(
        IBEP20 fromToken,
        IBEP20 toToken,
        address factory
    ) public view returns (uint256 reserveA, uint256 reserveB) {
        IBEP20 _from = isMATIC(fromToken) ? WMATIC_TOKEN : fromToken;
        IBEP20 _to = isMATIC(toToken) ? WMATIC_TOKEN : toToken;

        address fromAddress = address(_from);
        address toAddress = address(_to);

        if (
            factory == QUICKSWAP_FACTORY ||
            factory == SUSHISWAP_FACTORY ||
            factory == DFYN_FACTORY
        ) {
            IUniswapV2Factory uniFactory = IUniswapV2Factory(factory);
            IUniswapV2Exchange pair = uniFactory.getPair(_from, _to);

            if (address(pair) != address(0)) {
                (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();

                (address token0, ) = sortTokens(fromAddress, toAddress);
                (reserveA, reserveB) = fromAddress == token0
                    ? (reserve0, reserve1)
                    : (reserve1, reserve0);
            }
        } else {
            // CURVE
            int8 fromIndex = curveIndex[factory][fromAddress];
            int8 toIndex = curveIndex[factory][toAddress];
            ICurveFiCurve curve = ICurveFiCurve(factory);

            reserveA = 0;
            reserveB = 0;
            if (fromIndex > 0 && toIndex > 0) {
                if (factory == IRON) {
                    //uint8 index
                    reserveA = curve.getTokenBalance(
                        uint8(getCurveIndex(factory, fromAddress))
                    );
                    reserveB = curve.getTokenBalance(
                        uint8(getCurveIndex(factory, toAddress))
                    );
                } else {
                    if (fromIndex <= 3) {
                        //Curve base pool
                        reserveA = ICurveFiCurve(CURVE_AAVE).balances(
                            uint256(uint8(fromIndex - 1))
                        );
                    } else {
                        reserveA = ICurveFiCurve(CURVE_3POOL).balances(
                            uint256(uint8(fromIndex - 3))
                        );
                    }
                    if (toIndex <= 3) {
                        //Curve base pool
                        reserveB = ICurveFiCurve(CURVE_AAVE).balances(
                            uint256(uint8(toIndex - 1))
                        );
                    } else {
                        reserveB = ICurveFiCurve(CURVE_3POOL).balances(
                            uint256(uint8(toIndex - 3))
                        );
                    }
                }
            }
        }
    }

    /**
     * @dev Method to get the full reserves for the 2 token to be exchanged plus the proposed distribution to obtain the best price
     */

    function getFullReserves(IBEP20 fromToken, IBEP20 toToken)
        public
        view
        returns (
            uint256 fromTotal,
            uint256 destTotal,
            uint256[ex_count] memory dist,
            uint256[2][ex_count] memory res
        )
    {
        for (uint256 i = 0; i < ex_count; i++) {
            (uint256 balance0, uint256 balance1) = getReserves(
                fromToken,
                toToken,
                exchanges[i]
            );
            fromTotal += balance0;
            destTotal += balance1; //balance1 is toToken and the bigger it is  the juicier for us

            (res[i][0], res[i][1]) = (balance0, balance1);
        }

        if (destTotal > 0) {
            for (uint256 i = 0; i < ex_count; i++) {
                dist[i] = (res[i][1] * PC_DENOMINATOR) / destTotal;
            }
        }
    }

    /**
     * @dev Standard Uniswap V2 way to calculate the output amount given the input amount
     */
    /*
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountOut) {
        uint256 amountInWithFee = amountIn * 997;
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = reserveIn * 1000 + amountInWithFee;
        amountOut = numerator / denominator;
    }*/

    /**
     * @dev Method to get a direct quote between the given tokens - might not be always available
     * as there might not be any direct liquidity between them
     */
    function quoteDirect(
        IBEP20 fromToken,
        IBEP20 toToken,
        uint256 amount
    )
        public
        view
        returns (uint256 returnAmount, uint256[ex_count] memory swapAmounts)
    {
        (
            ,
            ,
            uint256[ex_count] memory distribution, //uint256[2][ex_count] memory reserves

        ) = getFullReserves(fromToken, toToken);

        uint256 addDistribution;
        uint256 eligible;
        uint256 lastNonZeroIndex;

        for (uint256 i = 0; i < ex_count; i++) {
            if (distribution[i] > minPc) {
                lastNonZeroIndex = i;
                eligible++;
            } else {
                addDistribution += distribution[i];
                distribution[i] = 0;
            }
        }

        uint256 remainingAmount = amount;
        address fromAddress = address(fromToken);
        address toAddress = address(toToken);

        for (uint256 i = 0; i <= lastNonZeroIndex; i++) {
            //address factory = exchanges[i];
            if (distribution[i] > 0) {
                if (addDistribution > 0) {
                    distribution[i] += addDistribution / eligible;
                }

                if (i == lastNonZeroIndex) {
                    swapAmounts[i] = remainingAmount;
                } else {
                    swapAmounts[i] =
                        (amount * distribution[i]) /
                        PC_DENOMINATOR;
                }

                if (
                    exchanges[i] == QUICKSWAP_FACTORY ||
                    exchanges[i] == SUSHISWAP_FACTORY ||
                    exchanges[i] == DFYN_FACTORY
                ) {
                    //IUniswapV2Factory uniFactory = IUniswapV2Factory(factory);

                    (uint256 uniAmount, , , ) = getUniReturn(
                        exchanges[i],
                        fromToken,
                        toToken,
                        swapAmounts[i]
                    );

                    returnAmount += uniAmount;
                } else {
                    returnAmount += getReturnAmountCurve(
                        exchanges[i],
                        getCurveIndex(exchanges[i], fromAddress),
                        getCurveIndex(exchanges[i], toAddress),
                        swapAmounts[i]
                    );
                }
                remainingAmount -= swapAmounts[i];
            }
        }
    }

    function getReturnAmountCurve(
        address factory,
        int8 ixFrom,
        int8 ixTo,
        uint256 amount
    ) internal view returns (uint256 returnAmount) {
        ICurveFiCurve curve = ICurveFiCurve(factory);
        returnAmount = 0;

        if (factory == IRON) {
            try
                curve.calculateSwap(uint8(ixFrom), uint8(ixTo), amount)
            returns (uint256 _returnAmount) {
                returnAmount += _returnAmount;
            } catch {}
        } else {
            try
                curve.get_dy_underlying(
                    uint256(uint8(ixFrom)),
                    uint256(uint8(ixTo)),
                    amount
                )
            returns (uint256 _returnAmount) {
                returnAmount += _returnAmount;
            } catch {}
        }
    }

    /**
     * @dev Method to get a best quote between the direct and through the WETH -
     * as there is more liquidity between token/ETH than token0/token1
     */
    function quote(
        IBEP20 fromToken,
        IBEP20 toToken,
        uint256 amount
    )
        public
        view
        returns (
            uint256 returnAmount,
            uint256[ex_count] memory swapAmountsIn,
            uint256[ex_count] memory swapAmountsOut,
            address swapVia
        )
    {
        swapVia = address(0);
        if (fromToken == toToken) {
            returnAmount = amount;
        } else {
            ///TODO: quoteDirect gives revert
            (
                uint256 returnAmountDirect,
                uint256[ex_count] memory swapAmounts1
            ) = quoteDirect(fromToken, toToken, amount);
            returnAmount = returnAmountDirect;
            swapAmountsIn = swapAmounts1;

            if (isMATIC(toToken)) {
                toToken = WMATIC_TOKEN;
            }

            if (isMATIC(fromToken)) {
                fromToken = WMATIC_TOKEN;
            }

            uint256 returnAmountVia;
            uint256[ex_count] memory swapAmounts2;
            uint256[ex_count] memory swapAmounts3;

            for (uint256 i = 0; i < viaTokens.length; i++) {
                address viaToken = viaTokens[i];
                if (
                    (address(toToken) != viaToken) &&
                    (address(fromToken) != viaToken)
                ) {
                    (
                        returnAmountVia,
                        swapAmounts2,
                        swapAmounts3
                    ) = getReturnVia(
                        fromToken,
                        toToken,
                        amount,
                        IBEP20(viaToken)
                    );

                    if (returnAmountVia > returnAmount) {
                        returnAmount = returnAmountVia;
                        swapAmountsIn = swapAmounts2;
                        swapAmountsOut = swapAmounts3;
                        swapVia = viaToken;
                    }
                }
            }
        }
    }

    function getReturnVia(
        IBEP20 fromToken,
        IBEP20 toToken,
        uint256 amount,
        IBEP20 viaToken
    )
        public
        view
        returns (
            uint256,
            uint256[ex_count] memory,
            uint256[ex_count] memory
        )
    {
        (
            uint256 returnAmountViaToken,
            uint256[ex_count] memory swapAmounts2
        ) = quoteDirect(fromToken, viaToken, amount);
        (
            uint256 returnAmountVia,
            uint256[ex_count] memory swapAmounts3
        ) = quoteDirect(viaToken, toToken, returnAmountViaToken);

        return (returnAmountVia, swapAmounts2, swapAmounts3);
    }

    /**
     * @dev run a swap across multiple exchanges given the splitted amounts
     * @param swapAmounts - array of splitted amounts
     */
    function executeSwap(
        IBEP20 fromToken,
        IBEP20 toToken,
        uint256[ex_count] memory swapAmounts
    ) internal returns (uint256 returnAmount) {
        for (uint256 i = 0; i < swapAmounts.length; i++) {
            if (swapAmounts[i] > 0) {
                address factory = exchanges[i];
                uint256 thisBalance = fromToken.balanceOf(address(this));
                uint256 swapAmount = min(thisBalance, swapAmounts[i]);

                if (factory == CURVE_3CRYPTO || factory == IRON) {
                    returnAmount += _swapOnCurve(
                        fromToken,
                        toToken,
                        swapAmount,
                        factory
                    );
                } else {
                    returnAmount += _swapOnUniswapV2Internal(
                        fromToken,
                        toToken,
                        swapAmount,
                        factory
                    );
                }
            }
        }
    }

    /**
     * @dev Main function to run a swap
     * @param slipProtect - enable/disable slip protection
     */
    function swap(
        IBEP20 fromToken,
        IBEP20 toToken,
        uint256 amount,
        bool slipProtect
    ) public payable virtual returns (uint256 returnAmount) {
        if (fromToken == toToken) {
            return amount;
        }

        if (isMATIC(fromToken)) {
            amount = msg.value;
            WMATIC.deposit{value: amount}();
            fromToken = WMATIC_TOKEN;
        } else {
            require(
                fromToken.allowance(msg.sender, address(this)) > amount,
                "Not enough token approved"
            );
            amount = min(fromToken.balanceOf(msg.sender), amount);
            require(amount > 0, "No token balance");
            fromToken.transferFrom(msg.sender, address(this), amount);
        }

        bool unwrap = false;
        if (isMATIC(toToken)) {
            unwrap = true;
            toToken = WMATIC_TOKEN;
        }

        amount = min(fromToken.balanceOf(address(this)), amount);

        (
            uint256 returnQuoteAmount,
            uint256[ex_count] memory swapAmountsIn,
            uint256[ex_count] memory swapAmountsOut,
            address swapVia
        ) = quote(fromToken, toToken, amount);

        uint256 minAmount;
        if (slipProtect) {
            uint256 feeSlippage = (returnQuoteAmount * slippageFee) /
                PC_DENOMINATOR;
            minAmount = returnQuoteAmount - feeSlippage;
        }
        require(returnQuoteAmount > 0, "Zero quote");
        if (swapVia != address(0)) {
            executeSwap(fromToken, IBEP20(swapVia), swapAmountsIn);
            returnAmount = executeSwap(
                IBEP20(swapVia),
                toToken,
                swapAmountsOut
            );
        } else {
            returnAmount = executeSwap(fromToken, toToken, swapAmountsIn);
        }
        require(returnAmount >= minAmount, "Slippage is too high");

        if (unwrap) {
            WMATIC.withdraw(IBEP20(WMATIC_TOKEN).balanceOf(address(this)));
            payable(msg.sender).transfer(address(this).balance);
        } else {
            toToken.transfer(msg.sender, returnAmount);
        }
    }

    /**
     * @dev fallback function to withdraw tokens from contract
     * - not normally needed
     */
    function transferTokenBack(address TokenAddress)
        external
        onlyOwner
        returns (uint256 returnBalance)
    {
        IBEP20 Token = IBEP20(TokenAddress);
        returnBalance = Token.balanceOf(address(this));
        if (returnBalance > 0) {
            Token.transfer(msg.sender, returnBalance);
        }
    }

    function _swapOnCurve(
        IBEP20 fromToken,
        IBEP20 toToken,
        uint256 amount,
        address exchange
    ) internal returns (uint256 returnAmount) {
        //using curve
        ICurveFiCurve curve = ICurveFiCurve(exchange);
        if (fromToken.allowance(address(this), exchange) < amount) {
            fromToken.approve(exchange, 0);
            fromToken.approve(exchange, type(uint256).max);
        }

        uint256 startBalance = toToken.balanceOf(address(this));

        // actual index is -1
        if (exchange == IRON) {
            curve.swap(
                uint8(getCurveIndex(exchange, address(fromToken))),
                uint8(getCurveIndex(exchange, address(toToken))),
                amount,
                0,
                type(uint256).max
            );
        } else {
            curve.exchange_underlying(
                uint256(uint8(getCurveIndex(exchange, address(fromToken)))),
                uint256(uint8(getCurveIndex(exchange, address(toToken)))),
                amount,
                0
            );
        }
        return toToken.balanceOf(address(this)) - startBalance;
    }

    function _swapOnUniswapV2Internal(
        IBEP20 fromToken,
        IBEP20 toToken,
        uint256 amount,
        address factory
    ) internal returns (uint256 returnAmount) {
        (
            uint256 uniAmount,
            bool needSync,
            bool needSkim,
            IUniswapV2Exchange exchange
        ) = getUniReturn(factory, fromToken, toToken, amount);
        returnAmount = uniAmount;

        if (needSync) {
            exchange.sync();
        } else if (needSkim) {
            exchange.skim(BONUS_ADDRESS);
        }

        fromToken.transfer(address(exchange), amount);
        if (uint160(address(fromToken)) < uint160(address(toToken))) {
            exchange.swap(0, returnAmount, address(this), "");
        } else {
            exchange.swap(returnAmount, 0, address(this), "");
        }
    }

    function getUniReturn(
        address factory,
        IBEP20 fromToken,
        IBEP20 toToken,
        uint256 amount
    )
        internal
        view
        returns (
            uint256 returnAmount,
            bool needSync,
            bool needSkim,
            IUniswapV2Exchange exchange
        )
    {
        IUniswapV2Factory uniFactory = IUniswapV2Factory(factory);
        exchange = uniFactory.getPair(fromToken, toToken);

        (returnAmount, needSync, needSkim) = exchange.getReturn(
            fromToken,
            toToken,
            amount
        );
    }

    /**
     * @dev payable fallback to allow for wmatic withdrawal
     */
    receive() external payable {}
}