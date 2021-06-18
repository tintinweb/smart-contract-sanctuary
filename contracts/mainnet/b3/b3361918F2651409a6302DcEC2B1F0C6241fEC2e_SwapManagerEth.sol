pragma solidity >=0.4.0;

// a library for handling binary fixed point numbers (https://en.wikipedia.org/wiki/Q_(number_format))
library FixedPoint {
    // range: [0, 2**112 - 1]
    // resolution: 1 / 2**112
    struct uq112x112 {
        uint224 _x;
    }

    // range: [0, 2**144 - 1]
    // resolution: 1 / 2**112
    struct uq144x112 {
        uint _x;
    }

    uint8 private constant RESOLUTION = 112;

    // encode a uint112 as a UQ112x112
    function encode(uint112 x) internal pure returns (uq112x112 memory) {
        return uq112x112(uint224(x) << RESOLUTION);
    }

    // encodes a uint144 as a UQ144x112
    function encode144(uint144 x) internal pure returns (uq144x112 memory) {
        return uq144x112(uint256(x) << RESOLUTION);
    }

    // divide a UQ112x112 by a uint112, returning a UQ112x112
    function div(uq112x112 memory self, uint112 x) internal pure returns (uq112x112 memory) {
        require(x != 0, 'FixedPoint: DIV_BY_ZERO');
        return uq112x112(self._x / uint224(x));
    }

    // multiply a UQ112x112 by a uint, returning a UQ144x112
    // reverts on overflow
    function mul(uq112x112 memory self, uint y) internal pure returns (uq144x112 memory) {
        uint z;
        require(y == 0 || (z = uint(self._x) * y) / y == uint(self._x), "FixedPoint: MULTIPLICATION_OVERFLOW");
        return uq144x112(z);
    }

    // returns a UQ112x112 which represents the ratio of the numerator to the denominator
    // equivalent to encode(numerator).div(denominator)
    function fraction(uint112 numerator, uint112 denominator) internal pure returns (uq112x112 memory) {
        require(denominator > 0, "FixedPoint: DIV_BY_ZERO");
        return uq112x112((uint224(numerator) << RESOLUTION) / denominator);
    }

    // decode a UQ112x112 into a uint112 by truncating after the radix point
    function decode(uq112x112 memory self) internal pure returns (uint112) {
        return uint112(self._x >> RESOLUTION);
    }

    // decode a UQ144x112 into a uint144 by truncating after the radix point
    function decode144(uq144x112 memory self) internal pure returns (uint144) {
        return uint144(self._x >> RESOLUTION);
    }
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

import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';
import '@uniswap/lib/contracts/libraries/FixedPoint.sol';

// library with helper methods for oracles that are concerned with computing average prices
library UniswapV2OracleLibrary {
    using FixedPoint for *;

    // helper function that returns the current block timestamp within the range of uint32, i.e. [0, 2**32 - 1]
    function currentBlockTimestamp() internal view returns (uint32) {
        return uint32(block.timestamp % 2 ** 32);
    }

    // produces the cumulative price using counterfactuals to save gas and avoid a call to sync.
    function currentCumulativePrices(
        address pair
    ) internal view returns (uint price0Cumulative, uint price1Cumulative, uint32 blockTimestamp) {
        blockTimestamp = currentBlockTimestamp();
        price0Cumulative = IUniswapV2Pair(pair).price0CumulativeLast();
        price1Cumulative = IUniswapV2Pair(pair).price1CumulativeLast();

        // if time has elapsed since the last update on the pair, mock the accumulated price values
        (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) = IUniswapV2Pair(pair).getReserves();
        if (blockTimestampLast != blockTimestamp) {
            // subtraction overflow is desired
            uint32 timeElapsed = blockTimestamp - blockTimestampLast;
            // addition overflow is desired
            // counterfactual
            price0Cumulative += uint(FixedPoint.fraction(reserve1, reserve0)._x) * timeElapsed;
            // counterfactual
            price1Cumulative += uint(FixedPoint.fraction(reserve0, reserve1)._x) * timeElapsed;
        }
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.3;

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/lib/contracts/libraries/FixedPoint.sol";

import "@uniswap/v2-periphery/contracts/libraries/UniswapV2OracleLibrary.sol";
import "./interfaces/IOracleSimple.sol";

// fixed window oracle that recomputes the average price for the entire period once every period
// note that the price average is only guaranteed to be over at least 1 period, but may be over a longer period
contract OracleSimple is IOracleSimple {
    using FixedPoint for *;

    /* solhint-disable var-name-mixedcase */
    uint256 public immutable PERIOD;
    IUniswapV2Pair public immutable PAIR;

    /* solhint-enable */

    address public immutable token0;
    address public immutable token1;

    uint256 public price0CumulativeLast;
    uint256 public price1CumulativeLast;
    uint32 public blockTimestampLast;
    FixedPoint.uq112x112 public price0Average;
    FixedPoint.uq112x112 public price1Average;
    bool public isStale;

    constructor(address _pair, uint256 _period) {
        PERIOD = _period;
        IUniswapV2Pair pair = IUniswapV2Pair(_pair);
        PAIR = pair;
        token0 = pair.token0();
        token1 = pair.token1();
        price0CumulativeLast = pair.price0CumulativeLast(); // fetch the current accumulated price value (1 / 0)
        price1CumulativeLast = pair.price1CumulativeLast(); // fetch the current accumulated price value (0 / 1)
        uint112 reserve0;
        uint112 reserve1;
        (reserve0, reserve1, blockTimestampLast) = pair.getReserves();
        require(reserve0 != 0 && reserve1 != 0, "OracleSimple: NO_RESERVES"); // ensure that there's liquidity in the pair
    }

    function update() external override returns (bool) {
        (
            uint256 price0Cumulative,
            uint256 price1Cumulative,
            uint32 blockTimestamp
        ) = UniswapV2OracleLibrary.currentCumulativePrices(address(PAIR));
        uint32 timeElapsed = blockTimestamp - blockTimestampLast; // overflow is desired

        // ensure that at least one full period has passed since the last update
        if (timeElapsed < PERIOD) return false;

        // overflow is desired, casting never truncates
        // cumulative price is in (uq112x112 price * seconds) units so we simply wrap it after division by time elapsed
        price0Average = FixedPoint.uq112x112(
            uint224((price0Cumulative - price0CumulativeLast) / timeElapsed)
        );
        price1Average = FixedPoint.uq112x112(
            uint224((price1Cumulative - price1CumulativeLast) / timeElapsed)
        );

        price0CumulativeLast = price0Cumulative;
        price1CumulativeLast = price1Cumulative;
        blockTimestampLast = blockTimestamp;
        return true;
    }

    // note this will always return 0 before update has been called successfully for the first time.
    function consult(address token, uint256 amountIn)
        external
        view
        override
        returns (uint256 amountOut)
    {
        if (token == token0) {
            amountOut = price0Average.mul(amountIn).decode144();
        } else {
            require(token == token1, "OracleSimple: INVALID_TOKEN");
            amountOut = price1Average.mul(amountIn).decode144();
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

import "./OracleSimple.sol";
import "./interfaces/ISwapManager.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

abstract contract SwapManagerBase is ISwapManager {
    uint256 public constant override N_DEX = 2;
    /* solhint-disable */
    string[N_DEX] public dexes = ["UNISWAP", "SUSHISWAP"];
    address[N_DEX] public override ROUTERS;
    address[N_DEX] public factories;

    /* solhint-enable */

    constructor(
        string[2] memory _dexes,
        address[2] memory _routers,
        address[2] memory _factories
    ) {
        dexes = _dexes;
        ROUTERS = _routers;
        factories = _factories;
    }

    function bestPathFixedInput(
        address _from,
        address _to,
        uint256 _amountIn,
        uint256 _i
    ) public view virtual override returns (address[] memory path, uint256 amountOut);

    function bestPathFixedOutput(
        address _from,
        address _to,
        uint256 _amountOut,
        uint256 _i
    ) public view virtual override returns (address[] memory path, uint256 amountIn);

    function bestOutputFixedInput(
        address _from,
        address _to,
        uint256 _amountIn
    )
        external
        view
        override
        returns (
            address[] memory path,
            uint256 amountOut,
            uint256 rIdx
        )
    {
        // Iterate through each DEX and evaluate the best output
        for (uint256 i = 0; i < N_DEX; i++) {
            (address[] memory tPath, uint256 tAmountOut) = bestPathFixedInput(
                _from,
                _to,
                _amountIn,
                i
            );
            if (tAmountOut > amountOut) {
                path = tPath;
                amountOut = tAmountOut;
                rIdx = i;
            }
        }
        return (path, amountOut, rIdx);
    }

    function bestInputFixedOutput(
        address _from,
        address _to,
        uint256 _amountOut
    )
        external
        view
        override
        returns (
            address[] memory path,
            uint256 amountIn,
            uint256 rIdx
        )
    {
        // Iterate through each DEX and evaluate the best input
        for (uint256 i = 0; i < N_DEX; i++) {
            (address[] memory tPath, uint256 tAmountIn) = bestPathFixedOutput(
                _from,
                _to,
                _amountOut,
                i
            );
            if (amountIn == 0 || tAmountIn < amountIn) {
                if (tAmountIn != 0) {
                    path = tPath;
                    amountIn = tAmountIn;
                    rIdx = i;
                }
            }
        }
    }

    // Rather than let the getAmountsOut call fail due to low liquidity, we
    // catch the error and return 0 in place of the reversion
    // this is useful when we want to proceed with logic
    function safeGetAmountsOut(
        uint256 _amountIn,
        address[] memory _path,
        uint256 _i
    ) public view override returns (uint256[] memory result) {
        try IUniswapV2Router02(ROUTERS[_i]).getAmountsOut(_amountIn, _path) returns (
            uint256[] memory amounts
        ) {
            result = amounts;
        } catch {
            result = new uint256[](_path.length);
            result[0] = _amountIn;
        }
    }

    // Just a wrapper for the uniswap call
    // This can fail (revert) in two scenarios
    // 1. (path.length == 2 && insufficient reserves)
    // 2. (path.length > 2 and an intermediate pair has an output amount of 0)
    function unsafeGetAmountsOut(
        uint256 _amountIn,
        address[] memory _path,
        uint256 _i
    ) external view override returns (uint256[] memory result) {
        result = IUniswapV2Router02(ROUTERS[_i]).getAmountsOut(_amountIn, _path);
    }

    // Rather than let the getAmountsIn call fail due to low liquidity, we
    // catch the error and return 0 in place of the reversion
    // this is useful when we want to proceed with logic (occurs when amountOut is
    // greater than avaiable reserve (ds-math-sub-underflow)
    function safeGetAmountsIn(
        uint256 _amountOut,
        address[] memory _path,
        uint256 _i
    ) public view override returns (uint256[] memory result) {
        try IUniswapV2Router02(ROUTERS[_i]).getAmountsIn(_amountOut, _path) returns (
            uint256[] memory amounts
        ) {
            result = amounts;
        } catch {
            result = new uint256[](_path.length);
            result[_path.length - 1] = _amountOut;
        }
    }

    // Just a wrapper for the uniswap call
    // This can fail (revert) in one scenario
    // 1. amountOut provided is greater than reserve for out currency
    function unsafeGetAmountsIn(
        uint256 _amountOut,
        address[] memory _path,
        uint256 _i
    ) external view override returns (uint256[] memory result) {
        result = IUniswapV2Router02(ROUTERS[_i]).getAmountsIn(_amountOut, _path);
    }

    function comparePathsFixedInput(
        address[] memory pathA,
        address[] memory pathB,
        uint256 _amountIn,
        uint256 _i
    ) public view override returns (address[] memory path, uint256 amountOut) {
        path = pathA;
        amountOut = safeGetAmountsOut(_amountIn, pathA, _i)[pathA.length - 1];
        uint256 bAmountOut = safeGetAmountsOut(_amountIn, pathB, _i)[pathB.length - 1];
        if (bAmountOut > amountOut) {
            path = pathB;
            amountOut = bAmountOut;
        }
    }

    function comparePathsFixedOutput(
        address[] memory pathA,
        address[] memory pathB,
        uint256 _amountOut,
        uint256 _i
    ) public view override returns (address[] memory path, uint256 amountIn) {
        path = pathA;
        amountIn = safeGetAmountsIn(_amountOut, pathA, _i)[0];
        uint256 bAmountIn = safeGetAmountsIn(_amountOut, pathB, _i)[0];
        if (bAmountIn == 0) return (path, amountIn);
        if (amountIn == 0 || bAmountIn < amountIn) {
            path = pathB;
            amountIn = bAmountIn;
        }
    }

    // TWAP Oracle Factory
    address[] private _oracles;
    mapping(address => bool) private _isOurs;
    // Pair -> period -> oracle
    mapping(address => mapping(uint256 => address)) private _oraclesByPair;

    function ours(address a) external view override returns (bool) {
        return _isOurs[a];
    }

    function oracleCount() external view override returns (uint256) {
        return _oracles.length;
    }

    function oracleAt(uint256 idx) external view override returns (address) {
        require(idx < _oracles.length, "Index exceeds list length");
        return _oracles[idx];
    }

    function getOracle(
        address _tokenA,
        address _tokenB,
        uint256 _period,
        uint256 _i
    ) external view override returns (address) {
        return _oraclesByPair[IUniswapV2Factory(factories[_i]).getPair(_tokenA, _tokenB)][_period];
    }

    function createOrUpdateOracle(
        address _tokenA,
        address _tokenB,
        uint256 _period,
        uint256 _i
    ) external override returns (address oracleAddr) {
        address pair = IUniswapV2Factory(factories[_i]).getPair(_tokenA, _tokenB);
        require(pair != address(0), "Nonexistant-pair");

        // If the oracle exists, try to update it
        if (_oraclesByPair[pair][_period] != address(0)) {
            OracleSimple(_oraclesByPair[pair][_period]).update();
            oracleAddr = _oraclesByPair[pair][_period];
            return oracleAddr;
        }

        // create new oracle contract
        oracleAddr = address(new OracleSimple(pair, _period));

        // remember oracle
        _oracles.push(oracleAddr);
        _isOurs[oracleAddr] = true;
        _oraclesByPair[pair][_period] = oracleAddr;

        // log creation
        emit OracleCreated(msg.sender, oracleAddr, _period);
    }

    function consultForFree(
        address _from,
        address _to,
        uint256 _amountIn,
        uint256 _period,
        uint256 _i
    ) public view override returns (uint256 amountOut, uint256 lastUpdatedAt) {
        OracleSimple oracle = OracleSimple(
            _oraclesByPair[IUniswapV2Factory(factories[_i]).getPair(_from, _to)][_period]
        );
        lastUpdatedAt = oracle.blockTimestampLast();
        amountOut = oracle.consult(_from, _amountIn);
    }

    /// get the data we want and pay the gas to update
    function consult(
        address _from,
        address _to,
        uint256 _amountIn,
        uint256 _period,
        uint256 _i
    )
        public
        override
        returns (
            uint256 amountOut,
            uint256 lastUpdatedAt,
            bool updated
        )
    {
        OracleSimple oracle = OracleSimple(
            _oraclesByPair[IUniswapV2Factory(factories[_i]).getPair(_from, _to)][_period]
        );
        lastUpdatedAt = oracle.blockTimestampLast();
        amountOut = oracle.consult(_from, _amountIn);
        try oracle.update() {
            updated = true;
        } catch {
            updated = false;
        }
    }

    function updateOracles() external override returns (uint256 updated, uint256 expected) {
        expected = _oracles.length;
        for (uint256 i = 0; i < expected; i++) {
            if (OracleSimple(_oracles[i]).update()) updated++;
        }
    }

    function updateOracles(address[] memory _oracleAddrs)
        external
        override
        returns (uint256 updated, uint256 expected)
    {
        expected = _oracleAddrs.length;
        for (uint256 i = 0; i < expected; i++) {
            if (OracleSimple(_oracleAddrs[i]).update()) updated++;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

import "./OracleSimple.sol";
import "./SwapManagerBase.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract SwapManagerEth is SwapManagerBase {
    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    /* solhint-enable */
    /** 
     UNISWAP: {router: 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D, factory: 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f}
     SUSHISWAP: {router: 0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F, factory: 0xC0AEe478e3658e2610c5F7A4A2E1777cE9e4f2Ac}
    */
    constructor()
        SwapManagerBase(
            ["UNISWAP", "SUSHISWAP"],
            [
                0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D,
                0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F
            ],
            [0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f, 0xC0AEe478e3658e2610c5F7A4A2E1777cE9e4f2Ac]
        )
    {}

    function bestPathFixedInput(
        address _from,
        address _to,
        uint256 _amountIn,
        uint256 _i
    ) public view override returns (address[] memory path, uint256 amountOut) {
        path = new address[](2);
        path[0] = _from;
        path[1] = _to;
        if (_from == WETH || _to == WETH) {
            amountOut = safeGetAmountsOut(_amountIn, path, _i)[path.length - 1];
            return (path, amountOut);
        }

        address[] memory pathB = new address[](3);
        pathB[0] = _from;
        pathB[1] = WETH;
        pathB[2] = _to;
        // is one of these WETH
        if (IUniswapV2Factory(factories[_i]).getPair(_from, _to) == address(0x0)) {
            // does a direct liquidity pair not exist?
            amountOut = safeGetAmountsOut(_amountIn, pathB, _i)[pathB.length - 1];
            path = pathB;
        } else {
            // if a direct pair exists, we want to know whether pathA or path B is better
            (path, amountOut) = comparePathsFixedInput(path, pathB, _amountIn, _i);
        }
    }

    function bestPathFixedOutput(
        address _from,
        address _to,
        uint256 _amountOut,
        uint256 _i
    ) public view override returns (address[] memory path, uint256 amountIn) {
        path = new address[](2);
        path[0] = _from;
        path[1] = _to;
        if (_from == WETH || _to == WETH) {
            amountIn = safeGetAmountsIn(_amountOut, path, _i)[0];
            return (path, amountIn);
        }

        address[] memory pathB = new address[](3);
        pathB[0] = _from;
        pathB[1] = WETH;
        pathB[2] = _to;

        // is one of these WETH
        if (IUniswapV2Factory(factories[_i]).getPair(_from, _to) == address(0x0)) {
            // does a direct liquidity pair not exist?
            amountIn = safeGetAmountsIn(_amountOut, pathB, _i)[0];
            path = pathB;
        } else {
            // if a direct pair exists, we want to know whether pathA or path B is better
            (path, amountIn) = comparePathsFixedOutput(path, pathB, _amountOut, _i);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.3;

interface IOracleSimple {
    function update() external returns (bool);

    function consult(address token, uint256 amountIn) external view returns (uint256 amountOut);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

/* solhint-disable func-name-mixedcase */

interface ISwapManager {
    event OracleCreated(address indexed _sender, address indexed _newOracle, uint256 _period);

    function N_DEX() external view returns (uint256);

    function ROUTERS(uint256 i) external view returns (address);

    function bestOutputFixedInput(
        address _from,
        address _to,
        uint256 _amountIn
    )
        external
        view
        returns (
            address[] memory path,
            uint256 amountOut,
            uint256 rIdx
        );

    function bestPathFixedInput(
        address _from,
        address _to,
        uint256 _amountIn,
        uint256 _i
    ) external view returns (address[] memory path, uint256 amountOut);

    function bestInputFixedOutput(
        address _from,
        address _to,
        uint256 _amountOut
    )
        external
        view
        returns (
            address[] memory path,
            uint256 amountIn,
            uint256 rIdx
        );

    function bestPathFixedOutput(
        address _from,
        address _to,
        uint256 _amountOut,
        uint256 _i
    ) external view returns (address[] memory path, uint256 amountIn);

    function safeGetAmountsOut(
        uint256 _amountIn,
        address[] memory _path,
        uint256 _i
    ) external view returns (uint256[] memory result);

    function unsafeGetAmountsOut(
        uint256 _amountIn,
        address[] memory _path,
        uint256 _i
    ) external view returns (uint256[] memory result);

    function safeGetAmountsIn(
        uint256 _amountOut,
        address[] memory _path,
        uint256 _i
    ) external view returns (uint256[] memory result);

    function unsafeGetAmountsIn(
        uint256 _amountOut,
        address[] memory _path,
        uint256 _i
    ) external view returns (uint256[] memory result);

    function comparePathsFixedInput(
        address[] memory pathA,
        address[] memory pathB,
        uint256 _amountIn,
        uint256 _i
    ) external view returns (address[] memory path, uint256 amountOut);

    function comparePathsFixedOutput(
        address[] memory pathA,
        address[] memory pathB,
        uint256 _amountOut,
        uint256 _i
    ) external view returns (address[] memory path, uint256 amountIn);

    function ours(address a) external view returns (bool);

    function oracleCount() external view returns (uint256);

    function oracleAt(uint256 idx) external view returns (address);

    function getOracle(
        address _tokenA,
        address _tokenB,
        uint256 _period,
        uint256 _i
    ) external view returns (address);

    function createOrUpdateOracle(
        address _tokenA,
        address _tokenB,
        uint256 _period,
        uint256 _i
    ) external returns (address oracleAddr);

    function consultForFree(
        address _from,
        address _to,
        uint256 _amountIn,
        uint256 _period,
        uint256 _i
    ) external view returns (uint256 amountOut, uint256 lastUpdatedAt);

    /// get the data we want and pay the gas to update
    function consult(
        address _from,
        address _to,
        uint256 _amountIn,
        uint256 _period,
        uint256 _i
    )
        external
        returns (
            uint256 amountOut,
            uint256 lastUpdatedAt,
            bool updated
        );

    function updateOracles() external returns (uint256 updated, uint256 expected);

    function updateOracles(address[] memory _oracleAddrs)
        external
        returns (uint256 updated, uint256 expected);
}

{
  "evmVersion": "istanbul",
  "libraries": {},
  "metadata": {
    "bytecodeHash": "ipfs",
    "useLiteralContent": true
  },
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "remappings": [],
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}