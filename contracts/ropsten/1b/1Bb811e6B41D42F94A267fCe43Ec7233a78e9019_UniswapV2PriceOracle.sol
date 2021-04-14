// SPDX-License-Identifier: Apache-2.0

pragma solidity >=0.6.0;

import './libraries/UQ112x112.sol';
import './libraries/PhutureLibrary.sol';
import './libraries/SafeMath.sol';
import './libraries/TransferHelper.sol';

import './interfaces/IIndex.sol';
import './interfaces/IIndexFactory.sol';
import './interfaces/IUniswapV2Factory.sol';
import './interfaces/IUniswapV2Pair.sol';
import './interfaces/IUniswapV2Router02.sol';
import './interfaces/IUniswapV2PriceOracle.sol';

// TODO: check is this can be optimized by merging PhutureFactory+IndexFund

contract UniswapV2PriceOracle is IUniswapV2PriceOracle {
    using SafeMath for uint;
    using UQ112x112 for uint224;

    struct PriceFactor {
        uint32 blockTimestampLast; // uses single storage slot, accessible via getReserves

        uint priceCumulativeLast; // USD / quote * dt

        uint lastPriceCumulativeLast;
        uint tempPriceCumulativeLast;

        uint indexPrice;

        uint32 lastPriceCumulativeLastBlockTimestamp;          // uses single storage slot: 160 + 32 = 192 / 256
        uint32 tempPriceCumulativeLastBlockTimestamp;          // uses single storage slot: 160 + 32 + 32 = 224 / 256
        uint32 priceOracleInterval;                            // uses single storage slot: 160 + 32 + 32 + 32 = 256 / 256
    }
    
    address public override factory;
    address public override usd;

    mapping(address => PriceFactor) private priceFactors;

    constructor () public {
        
    }

    function initialize(address _factory, address _usd) external override {
        factory = _factory;
        usd = _usd;
    }

    function getPairInfo(address asset) internal view returns (uint32 _timestamp, uint256 _cumulativeLast) {
        IUniswapV2Factory uniswapFactory = IUniswapV2Factory(IIndexFactory(factory).exchangeFactory());
        IUniswapV2Pair pair = IUniswapV2Pair(uniswapFactory.getPair(usd, asset));

        (,, _timestamp) = pair.getReserves();
        _cumulativeLast = usd == pair.token0() ? pair.price0CumulativeLast() : pair.price1CumulativeLast();
    }
    // update reserves and, on the first call per block, price accumulators
    function getPrice(address asset) external override returns(uint price) {
        PriceFactor storage priceFactor = priceFactors[asset];

        (priceFactor.blockTimestampLast, priceFactor.priceCumulativeLast) = getPairInfo(asset);

        uint oracleTimeElapsed = priceFactor.blockTimestampLast - priceFactor.tempPriceCumulativeLastBlockTimestamp;
        if (oracleTimeElapsed > priceFactor.priceOracleInterval) {
            priceFactor.lastPriceCumulativeLast = priceFactor.tempPriceCumulativeLast;
            priceFactor.lastPriceCumulativeLastBlockTimestamp = priceFactor.tempPriceCumulativeLastBlockTimestamp;
            priceFactor.tempPriceCumulativeLast = priceFactor.priceCumulativeLast;
            priceFactor.tempPriceCumulativeLastBlockTimestamp = priceFactor.blockTimestampLast;
        }
       
        (uint _priceUSDInQuoteUQ, uint32 _timeInterval) = priceUSDInQuoteUQ(asset);
        if (_timeInterval > 0) { 
            priceFactor.indexPrice = _priceUSDInQuoteUQ;
        }
        return priceFactor.indexPrice;
    }

    function setPriceOracleInterval(address asset, uint32 _priceOracleInterval) external override {
        require(_priceOracleInterval > 0, 'Phuture: INVALID');
        priceFactors[asset].priceOracleInterval = _priceOracleInterval;
        // TODO: check how interval change affects priceUSDInQuoteUQ
    }

    /// @dev external caller must check _timeInterval != 0 to ensure that price is correct
    /// @dev _timeInterval can be 0 when block.timestamp % 2**32 == 0 which results in 0 price 
    /// @return _priceUSDInQuoteUQ in UQ, TWOP for _timeElapsed interval
    /// @return _timeElapsed in seconds, time elapsed since the last oracle check

    function priceUSDInQuoteUQ(address asset) public view returns (uint _priceUSDInQuoteUQ, uint32 _timeElapsed) {
        PriceFactor storage priceFactor = priceFactors[asset];

        (uint32 blockTimestampLast, uint256 priceCumulativeLast) = getPairInfo(asset);

        _timeElapsed = blockTimestampLast - priceFactor.lastPriceCumulativeLastBlockTimestamp;
        _priceUSDInQuoteUQ = _timeElapsed > 0 ? (priceCumulativeLast - priceFactor.lastPriceCumulativeLast) / _timeElapsed : 0;
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity >=0.5.16;

// a library for handling binary fixed point numbers (https://en.wikipedia.org/wiki/Q_(number_format))

// range: [0, 2**112 - 1]
// resolution: 1 / 2**112

library UQ112x112 {
    uint224 constant Q112 = 2**112;

    // encode a uint112 as a UQ112x112
    function encode(uint112 y) internal pure returns (uint224 z) {
        z = uint224(y) * Q112; // never overflows
    }

    // divide a UQ112x112 by a uint112, returning a UQ112x112
    function uqdiv(uint224 x, uint112 y) internal pure returns (uint224 z) {
        z = x / uint224(y);
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity >=0.5.0;

import '../interfaces/IPhuturePair.sol';
import '../interfaces/IPhutureFactory.sol';
import "./SafeMath.sol";

library PhutureLibrary {
    using SafeMath for uint;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'PhutureLibrary: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'PhutureLibrary: ZERO_ADDRESS');
    }

    function nonUSD(address USD, address tokenA, address tokenB) internal pure returns (address) {
        return tokenA == USD ? tokenB : tokenA;
    }

    function pairNonUSD(address factory, address USD, address tokenA, address tokenB) internal view returns (address pair) {
        return pairFor(factory, nonUSD(USD, tokenA, tokenB));
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenQuote) internal view returns (address pair) {
        // TODO: Restore commented out code before production deployment.
        // TODO: Optimization below would require code hash resets on every PhuturePair change.
        // pair = address(uint(keccak256(abi.encodePacked(
        //         hex'ff',
        //         factory,
        //         keccak256(abi.encodePacked(tokenQuote)),
        //         hex'2ea7d903602a6ba050c50b64effb15a6f6000afa3aceb8fb5cb6fe950d550668' // init code hash
        //     ))));
        pair = IPhutureFactory(factory).getPair(tokenQuote);

    }

    // fetches and sorts the reserves for a pair
    function getReservesUnsorted(address factory, address tokenQuote) internal view returns (uint reserveUSD, uint reserveQuote) {
        (reserveUSD, reserveQuote,) = IPhuturePair(pairFor(factory, tokenQuote)).getReserves();
    }

    function getReservesSorted(address factory, address USD, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        address pair = pairFor(factory, nonUSD(USD, tokenA, tokenB));
        (uint reserveUSD, uint reserveQuote,) = IPhuturePair(pair).getReserves();
        (reserveA, reserveB) = tokenA == USD ? (reserveUSD, reserveQuote) : (reserveQuote, reserveUSD);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountUSD, uint reserveUSD, uint reserveQuote) internal pure returns (uint amountQuote) {
        require(amountUSD > 0, 'PhutureLibrary: INSUFFICIENT_AMOUNT');
        require(reserveUSD > 0 && reserveQuote > 0, 'PhutureLibrary: INSUFFICIENT_LIQUIDITY');
        amountQuote = amountUSD.mul(reserveQuote) / reserveUSD;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'PhutureLibrary: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'PhutureLibrary: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn.mul(997);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'PhutureLibrary: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'PhutureLibrary: INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn.mul(amountOut).mul(1000);
        uint denominator = reserveOut.sub(amountOut).mul(997);
        amountIn = (numerator / denominator).add(1);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(address factory, address USD, uint amountIn, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'PhutureLibrary: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = getReservesSorted(factory, USD, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(address factory, address USD, uint amountOut, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'PhutureLibrary: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut) = getReservesSorted(factory, USD, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity >=0.6.6;

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

pragma solidity >=0.5.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IIndex {

    event IndexMinted(address indexed owner, uint value);
    event IndexBurned(address indexed owner, uint value);

    function factory() external view returns (address);
    function creator() external view returns (address);

    function assets(uint i) external view returns (address);
    function weights(uint i) external view returns (uint8);

    function depositUSD(uint256 _amount, uint256[] calldata minAssetAmounts ) external;
    function deposit(address[] memory _assets, uint256[] memory _amounts) external;
    function withdraw(uint256 _amount) external;
    function initialize(
        address _creator,
        address[] memory _assets, 
        uint8[] memory _weights,
        string memory _name, 
        string memory _symbol,
        uint8 _decimals
        // uint positionUSD
    ) external;
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity >=0.5.0;

interface IIndexFactory { 
    event Evaluate(address indexed asset, uint USDValueOfAsset, uint USDValue);
    event IndexCreated(address indexed creator, address index, address[] _assets, uint8[] _weights, string _name, string _symbol, uint256 _decimals);

    // TODO: creator must trasfer ownershio to indexFund
    function indexFund() external view returns (address);
    function setEnabled(bool _enabled) external;

    function indices(bytes32) external view returns (address index);
    function allIndices(uint) external view returns (address index);
    function allIndicesLength() external view returns (uint);
    function usd() external view returns(address);
    function exchangeFactory() external view returns(address);
    function exchangeRouter() external view returns(address);
    function oracle() external view returns (address);

    function valueUSD() external view returns (uint);
    function valueUSDOf(address asset) external view returns (uint);
    function evaluate(address asset, uint priceUSDInAssetUQ) external;
}

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
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
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

pragma solidity >=0.5.0;

interface IUniswapV2PriceOracle {
    
    function factory() external view returns (address);
    function usd() external view returns (address);

    // function priceCumulativeLast() external view returns (uint);
    // function priceUSDInQuoteUQ() external view returns (uint _priceUSDInQuoteUQ, uint32 _timeElapsed);

    function getPrice(address asset) external returns (uint256 price);
    function initialize(address _factory, address _usd) external;
    function setPriceOracleInterval(address asset, uint32 _priceOracleInterval) external;
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity >=0.5.0;

import './IPhutureERC20.sol';

interface IPhuturePair is IPhutureERC20 {
    event Mint(address indexed sender, uint amountUSD, uint amountQuote);
    event Burn(address indexed sender, uint amountUSD, uint amountQuote, address indexed to);
    event Swap(
        address indexed sender,
        uint amountUSDIn,
        uint amountQuoteIn,
        uint amountUSDOut,
        uint amountQuoteOut,
        address indexed to
    );
    event Sync(uint112 reserveUSD, uint112 reserveQuote);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function priceOracleInterval() external view returns (uint32);
    function factory() external view returns (address);
    function indexFund() external view returns (address);
    function tokenUSD() external view returns (address);
    function tokenQuote() external view returns (address);
    function getReserves() external view returns (uint112 reserveUSD, uint112 reserveQuote, uint32 blockTimestampLast);
    function priceCumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);
    function priceUSDInQuoteUQ() external view returns (uint _priceUSDInQuoteUQ, uint32 _timeElapsed);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amountUSD, uint amountQuote);
    function swap(uint amountUSDOut, uint amountQuoteOut, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address, address _indexFund, uint32 _priceOracleInterval) external;
    function setPriceOracleInterval(uint32 _priceOracleInterval) external;
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity >=0.5.0;

interface IPhutureFactory {
    event PairCreated(address indexed tokenUSD, address indexed tokenQuote, address pair, uint);

    function USD() external view returns (address);

    function feeTo() external view returns (address);
    function governance() external view returns (address);
    function indexFund() external view returns (address);

    function priceOracleInterval() external view returns (uint32);

    function getPair(address tokenQuote) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenQuote) external returns (address pair);

    function setFeeTo(address) external;
    function setGovernance(address) external;

    function setPriceOracleInterval(uint32 _interval) external;
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity >=0.5.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IPhutureERC20 is IERC20 {}

// SPDX-License-Identifier: MIT

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

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

{
  "optimizer": {
    "enabled": true,
    "runs": 999999
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
  "libraries": {}
}