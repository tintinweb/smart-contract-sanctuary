/**
 *Submitted for verification at Etherscan.io on 2021-03-13
*/

// File: contracts/libraries/TransferHelper.sol

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

// File: dxswap-core/contracts/interfaces/IDXswapPair.sol

pragma solidity >=0.5.0;

interface IDXswapPair {
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
    function swapFee() external view returns (uint32);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
    function setSwapFee(uint32) external;
}

// File: contracts/libraries/FixedPoint.sol

pragma solidity >=0.5.0;

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

// File: contracts/libraries/DXswapOracleLibrary.sol

pragma solidity >=0.5.0;



// library with helper methods for oracles that are concerned with computing average prices
library DXswapOracleLibrary {
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
        price0Cumulative = IDXswapPair(pair).price0CumulativeLast();
        price1Cumulative = IDXswapPair(pair).price1CumulativeLast();

        // if time has elapsed since the last update on the pair, mock the accumulated price values
        (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) = IDXswapPair(pair).getReserves();
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

// File: contracts/libraries/SafeMath.sol

pragma solidity =0.6.6;

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

// File: contracts/libraries/DXswapLibrary.sol

pragma solidity >=0.5.0;



library DXswapLibrary {
    using SafeMath for uint;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'DXswapLibrary: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'DXswapLibrary: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint(keccak256(abi.encodePacked(
            hex'ff',
            factory,
            keccak256(abi.encodePacked(token0, token1)),
            hex'd306a548755b9295ee49cc729e13ca4a45e00199bbd890fa146da43a50571776' // init code hash
        ))));
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IDXswapPair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }
    
    // fetches and sorts the reserves for a pair
    function getSwapFee(address factory, address tokenA, address tokenB) internal view returns (uint swapFee) {
        (address token0,) = sortTokens(tokenA, tokenB);
        swapFee = IDXswapPair(pairFor(factory, tokenA, tokenB)).swapFee();
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'DXswapLibrary: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'DXswapLibrary: INSUFFICIENT_LIQUIDITY');
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut, uint swapFee) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'DXswapLibrary: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'DXswapLibrary: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn.mul(uint(10000).sub(swapFee));
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(10000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut, uint swapFee) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'DXswapLibrary: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'DXswapLibrary: INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn.mul(amountOut).mul(10000);
        uint denominator = reserveOut.sub(amountOut).mul(uint(10000).sub(swapFee));
        amountIn = (numerator / denominator).add(1);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(address factory, uint amountIn, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'DXswapLibrary: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut, getSwapFee(factory, path[i], path[i + 1]));
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(address factory, uint amountOut, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'DXswapLibrary: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut, getSwapFee(factory, path[i - 1], path[i]));
        }
    }
}

// File: contracts/examples/OracleCreator.sol

pragma solidity =0.6.6;
pragma experimental ABIEncoderV2;





contract OracleCreator {
    using FixedPoint for *;
    using SafeMath for uint256;

    event OracleCreated(
        uint256 indexed _oracleIndex,
        address indexed _pair,
        uint256 _windowTime
    );

    struct Oracle{
        uint256 windowTime;
        address token0;
        address token1;
        IDXswapPair pair;
        uint32 blockTimestampLast;
        uint256 price0CumulativeLast;
        uint256 price1CumulativeLast;
        FixedPoint.uq112x112 price0Average;
        FixedPoint.uq112x112 price1Average;
        uint256 observationsCount;
        address owner;
    }

    mapping(uint256 => Oracle) public oracles;
    uint256 public oraclesIndex;

    function createOracle(
        uint256 windowTime,
        address pair
    ) public returns (uint256 oracleId) {
        IDXswapPair sourcePair = IDXswapPair(pair);
        address token0 = sourcePair.token0();
        address token1 = sourcePair.token1();
        (,, uint32 blockTimestampLast) =  sourcePair.getReserves();

        oracles[oraclesIndex] = Oracle({
            windowTime: windowTime,
            token0: token0,
            token1: token1,
            pair: sourcePair,
            blockTimestampLast: blockTimestampLast,
            price0CumulativeLast: sourcePair.price0CumulativeLast(),
            price1CumulativeLast: sourcePair.price1CumulativeLast(),
            price0Average: FixedPoint.uq112x112(0),
            price1Average: FixedPoint.uq112x112(0),
            observationsCount: 0,
            owner: msg.sender
        });
        oracleId = oraclesIndex;
        oraclesIndex++;
        emit OracleCreated(oracleId, address(sourcePair), windowTime);
    }

    function update(uint256 oracleIndex) public {
        Oracle storage oracle = oracles[oracleIndex];
        require(msg.sender == oracle.owner, 'OracleCreator: CALLER_NOT_OWNER');
        require(oracle.observationsCount < 2, 'OracleCreator: FINISHED_OBERSERVATION');
        (uint price0Cumulative, uint price1Cumulative, uint32 blockTimestamp) =
            DXswapOracleLibrary.currentCumulativePrices(address(oracle.pair));
        uint32 timeElapsed = blockTimestamp - oracle.blockTimestampLast; // overflow is desired

        // first update can be executed immediately. Ensure that at least one full period has passed since the first update 
        require(
          oracle.observationsCount == 0 || timeElapsed >= oracle.windowTime, 
          'OracleCreator: PERIOD_NOT_ELAPSED'
        );

        // overflow is desired, casting never truncates
        // cumulative price is in (uq112x112 price * seconds) units so we simply wrap it after division by time elapsed
        oracle.price0Average = FixedPoint.uq112x112(
          uint224((price0Cumulative - oracle.price0CumulativeLast) / timeElapsed)
        );
        oracle.price1Average = FixedPoint.uq112x112(
          uint224((price1Cumulative - oracle.price1CumulativeLast) / timeElapsed)
        );

        oracle.price0CumulativeLast = price0Cumulative;
        oracle.price1CumulativeLast = price1Cumulative;
        oracle.blockTimestampLast = blockTimestamp;
        oracle.observationsCount++;
    }

    // note this will always return 0 before update has been called successfully for the first time.
    function consult(uint256 oracleIndex, address token, uint256 amountIn) external view returns (uint256 amountOut) {
        Oracle storage oracle = oracles[oracleIndex];
        FixedPoint.uq112x112 memory avg;
        if (token == oracle.token0) { 
          avg = oracle.price0Average;
        } else {
          require(token == oracle.token1, 'OracleCreator: INVALID_TOKEN'); 
          avg = oracle.price1Average;
        }
        amountOut = avg.mul(amountIn).decode144();
    }

    function isOracleFinalized(uint256 oracleIndex) external view returns (bool){
        return oracles[oracleIndex].observationsCount == 2;
    }

    function getOracleDetails(uint256 oracleIndex) external view returns (Oracle memory) {
      return oracles[oracleIndex];
    }

}

// File: contracts/interfaces/IDXswapFactory.sol

pragma solidity >=0.5.0;

interface IDXswapFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function INIT_CODE_PAIR_HASH() external pure returns (bytes32);
    function feeTo() external view returns (address);
    function protocolFeeDenominator() external view returns (uint8);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
    function setProtocolFee(uint8 _protocolFee) external;
    function setSwapFee(address pair, uint32 swapFee) external;
}

// File: contracts/interfaces/IDXswapRouter.sol

pragma solidity >=0.6.2;


interface IDXswapRouter {
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
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut, uint swapFee) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut, uint swapFee) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);

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

// File: contracts/interfaces/IERC20.sol

pragma solidity >=0.5.0;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

// File: contracts/interfaces/IWETH.sol

pragma solidity >=0.5.0;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
    function balanceOf(address guy) external returns (uint);
    function approve(address guy, uint wad) external returns (bool);
}

// File: contracts/examples/DXswapRelayer.sol

pragma solidity =0.6.6;









contract DXswapRelayer {
    using SafeMath for uint256;

    event NewOrder(
        uint256 indexed _orderIndex,
        uint8 indexed _action
    );

    event ExecutedOrder(
        uint256 indexed _orderIndex
    );

    event WithdrawnExpiredOrder(
        uint256 indexed _orderIndex
    );

    event ChangedOwner(
        address payable indexed _newOwner
    );

    struct Order {
        uint8 action; // 1=provision; 2=removal
        address tokenA;
        address tokenB;
        uint256 amountA;
        uint256 amountB;
        uint256 liquidity;
        uint256 priceTolerance;
        uint256 minReserveA;
        uint256 minReserveB;
        address oraclePair;
        uint256 deadline;
        uint256 maxWindowTime;
        uint256 oracleId;
        address factory;
        bool executed;
    }

    uint256 public immutable GAS_ORACLE_UPDATE = 168364;
    uint256 public immutable PARTS_PER_MILLION = 1000000;
    uint256 public immutable BOUNTY = 0.01 ether;
    uint8 public immutable PROVISION = 1;
    uint8 public immutable REMOVAL = 2;
    
    address public immutable dxSwapFactory;
    address public immutable dxSwapRouter;
    address public immutable uniswapFactory;
    address public immutable uniswapRouter;
    address public immutable WETH;
    address payable public owner;

    OracleCreator public oracleCreator;
    uint256 public orderCount;
    mapping(uint256 => Order) orders;

    constructor(
        address payable _owner,
        address _dxSwapFactory,
        address _dxSwapRouter,
        address _uniswapFactory,
        address _uniswapRouter,
        address _WETH,
        OracleCreator _oracleCreater
    ) public {
        owner = _owner;
        dxSwapFactory = _dxSwapFactory;
        dxSwapRouter = _dxSwapRouter;
        uniswapFactory = _uniswapFactory;
        uniswapRouter = _uniswapRouter;
        WETH = _WETH;
        oracleCreator = _oracleCreater;
    }

    function orderLiquidityProvision(
        address tokenA,
        address tokenB,
        uint256 amountA,
        uint256 amountB,
        uint256 priceTolerance,
        uint256 minReserveA,
        uint256 minReserveB,
        uint256 maxWindowTime,
        uint256 deadline,
        address factory
    ) external payable returns (uint256 orderIndex) {
        require(factory == dxSwapFactory || factory == uniswapFactory, 'DXswapRelayer: INVALID_FACTORY');
        require(msg.sender == owner, 'DXswapRelayer: CALLER_NOT_OWNER');
        require(tokenA != tokenB, 'DXswapRelayer: INVALID_PAIR');
        require(tokenA < tokenB, 'DXswapRelayer: INVALID_TOKEN_ORDER');
        require(amountA > 0 && amountB > 0, 'DXswapRelayer: INVALID_TOKEN_AMOUNT');
        require(priceTolerance <= PARTS_PER_MILLION, 'DXswapRelayer: INVALID_TOLERANCE');
        require(block.timestamp <= deadline, 'DXswapRelayer: DEADLINE_REACHED');
        require(maxWindowTime > 30, 'DXswapRelayer: INVALID_WINDOWTIME');
        require(tokenA != address(0), 'DXswapRelayer: ZERO_ADDRESS');

        // Wrap native ETH if not already wrapped
        if(tokenA == WETH && IERC20(tokenA).balanceOf(address(this)) < amountA){
          IWETH(WETH).deposit{value: amountA}();
        } else if (tokenB == WETH && IERC20(tokenB).balanceOf(address(this)) < amountB){
          IWETH(WETH).deposit{value: amountB}();
        }
        
        require(IERC20(tokenA).balanceOf(address(this)) >= amountA, 'DXswapRelayer: INSUFFICIENT_TOKEN_A');
        require(IERC20(tokenB).balanceOf(address(this)) >= amountB, 'DXswapRelayer: INSUFFICIENT_TOKEN_B');

        address pair = _pair(tokenA, tokenB, factory);
        orderIndex = _OrderIndex();
        orders[orderIndex] = Order({
            action: PROVISION,
            tokenA: tokenA,
            tokenB: tokenB,
            amountA: amountA,
            amountB: amountB,
            liquidity: 0,
            priceTolerance: priceTolerance,
            minReserveA: minReserveA,
            minReserveB: minReserveB,
            oraclePair: pair,
            deadline: deadline,
            maxWindowTime: maxWindowTime,
            oracleId: 0,
            factory: factory,
            executed: false
        });
        emit NewOrder(orderIndex, PROVISION);

        (uint reserveA, uint reserveB,) = IDXswapPair(pair).getReserves();
        if (minReserveA == 0 && minReserveB == 0 && reserveA == 0 && reserveB == 0) {
            /* Non-circulating tokens can be provisioned immediately if reserve thresholds are set to zero */
            orders[orderIndex].executed = true;
            _pool(tokenA, tokenB, amountA, amountB, orders[orderIndex].amountA, orders[orderIndex].amountA);
            emit ExecutedOrder(orderIndex);
        } else {
            /* Create an oracle to calculate average price before providing liquidity */
            uint256 windowTime = _consultOracleParameters(amountA, amountB, reserveA, reserveB, maxWindowTime);
            orders[orderIndex].oracleId = oracleCreator.createOracle(windowTime, pair);
        }
    }

    function orderLiquidityRemoval(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountA,
        uint256 amountB,
        uint256 priceTolerance,
        uint256 minReserveA,
        uint256 minReserveB,
        uint256 maxWindowTime,
        uint256 deadline,
        address factory
    ) external returns (uint256 orderIndex) {
        require(factory == dxSwapFactory || factory == uniswapFactory, 'DXswapRelayer: INVALID_FACTORY');
        require(msg.sender == owner, 'DXswapRelayer: CALLER_NOT_OWNER');
        require(tokenA != tokenB, 'DXswapRelayer: INVALID_PAIR');
        require(tokenA < tokenB, 'DXswapRelayer: INVALID_TOKEN_ORDER');
        require(amountA > 0 && amountB > 0 && liquidity > 0, 'DXswapRelayer: INVALID_LIQUIDITY_AMOUNT');
        require(priceTolerance <= PARTS_PER_MILLION, 'DXswapRelayer: INVALID_TOLERANCE');
        require(block.timestamp <= deadline, 'DXswapRelayer: DEADLINE_REACHED');
        require(maxWindowTime > 30, 'DXswapRelayer: INVALID_WINDOWTIME');
        require(tokenA != address(0), 'DXswapRelayer: ZERO_ADDRESS');

        address pair = _pair(tokenA, tokenB, factory);
        orderIndex = _OrderIndex();
        orders[orderIndex] = Order({
            action: REMOVAL,
            tokenA: tokenA,
            tokenB: tokenB,
            amountA: amountA,
            amountB: amountB,
            liquidity: liquidity,
            priceTolerance: priceTolerance,
            minReserveA: minReserveA,
            minReserveB: minReserveB,
            oraclePair: pair,
            deadline: deadline,
            maxWindowTime: maxWindowTime,
            oracleId: 0,
            factory: factory,
            executed: false
        });

        address dxSwapPair = DXswapLibrary.pairFor(address(dxSwapFactory), tokenA, tokenB);
        (uint reserveA, uint reserveB,) = IDXswapPair(dxSwapPair).getReserves();
        uint256 windowTime = _consultOracleParameters(amountA, amountB, reserveA, reserveB, maxWindowTime);
        orders[orderIndex].oracleId = oracleCreator.createOracle(windowTime, pair);
        emit NewOrder(orderIndex, REMOVAL);
    }

    function executeOrder(uint256 orderIndex) external {
        Order storage order = orders[orderIndex];
        require(orderIndex < orderCount, 'DXswapRelayer: INVALID_ORDER');
        require(!order.executed, 'DXswapRelayer: ORDER_EXECUTED');
        require(oracleCreator.isOracleFinalized(order.oracleId) , 'DXswapRelayer: OBSERVATION_RUNNING');
        require(block.timestamp <= order.deadline, 'DXswapRelayer: DEADLINE_REACHED');

        address tokenA = order.tokenA;
        address tokenB = order.tokenB;
        uint256 amountA = oracleCreator.consult(order.oracleId, tokenB, order.amountB);
        uint256 amountB = oracleCreator.consult(order.oracleId, tokenA, order.amountA);
        
        /* Maximize token inputs */ 
        if(amountA <= order.amountA){
            amountB = order.amountB;
        } else {
            amountA = order.amountA;
        }
        uint256 minA = amountA.sub(amountA.mul(order.priceTolerance) / PARTS_PER_MILLION);
        uint256 minB = amountB.sub(amountB.mul(order.priceTolerance) / PARTS_PER_MILLION);

        order.executed = true;
        if(order.action == PROVISION){
            _pool(tokenA, tokenB, amountA, amountB, minA, minB);
        } else if (order.action == REMOVAL){
            address pair = _pair(tokenA, tokenB, dxSwapFactory);
            _unpool(
              tokenA, 
              tokenB, 
              pair, 
              order.liquidity,
              minA,
              minB
            );
        }
        emit ExecutedOrder(orderIndex);
    }

    // Updates a price oracle and sends a bounty to msg.sender
    function updateOracle(uint256 orderIndex) external {
        Order storage order = orders[orderIndex];
        require(block.timestamp <= order.deadline, 'DXswapRelayer: DEADLINE_REACHED');
        require(!oracleCreator.isOracleFinalized(order.oracleId) , 'DXswapRelayer: OBSERVATION_ENDED');
        uint256 amountBounty = GAS_ORACLE_UPDATE.mul(tx.gasprice).add(BOUNTY);
        
        (uint reserveA, uint reserveB,) = IDXswapPair(order.oraclePair).getReserves();
        require(
            reserveA >= order.minReserveA && reserveB >= order.minReserveB,
            'DXswapRelayer: RESERVE_TO_LOW'
        );
        oracleCreator.update(order.oracleId);
        if(address(this).balance >= amountBounty){
            TransferHelper.safeTransferETH(msg.sender, amountBounty);
        }
    }

    function withdrawExpiredOrder(uint256 orderIndex) external {
        Order storage order = orders[orderIndex];
        require(msg.sender == owner, 'DXswapRelayer: CALLER_NOT_OWNER');
        require(block.timestamp > order.deadline, 'DXswapRelayer: DEADLINE_NOT_REACHED');
        require(order.executed == false, 'DXswapRelayer: ORDER_EXECUTED');
        address tokenA = order.tokenA;
        address tokenB = order.tokenB;
        uint256 amountA = order.amountA;
        uint256 amountB = order.amountB;
        order.executed = true;

        if(tokenA == WETH){
          IWETH(WETH).withdraw(amountA);
          ETHWithdraw(amountA);
        } else {
          ERC20Withdraw(tokenA, amountA);
        }
        if (tokenB == WETH){
          IWETH(WETH).withdraw(amountB);
          ETHWithdraw(amountB);
        } else {
          ERC20Withdraw(tokenB, amountB);
        }
        emit WithdrawnExpiredOrder(orderIndex);
    }
    
    function _pool(
        address _tokenA,
        address _tokenB,
        uint256 _amountA,
        uint256 _amountB,
        uint256 _minA,
        uint256 _minB
    ) internal {
        uint256 amountA;
        uint256 amountB;
        uint256 liquidity;
        TransferHelper.safeApprove(_tokenA, dxSwapRouter, _amountA);
        TransferHelper.safeApprove(_tokenB, dxSwapRouter, _amountB);
        (amountA, amountB, liquidity) = IDXswapRouter(dxSwapRouter).addLiquidity(
            _tokenA,
            _tokenB,
            _amountA,
            _amountB,
            _minA,
            _minB,
            address(this),
            block.timestamp
        );
        TransferHelper.safeApprove(_tokenA, dxSwapRouter, 0);
        TransferHelper.safeApprove(_tokenB, dxSwapRouter, 0);
    }

    function _unpool(
        address _tokenA,
        address _tokenB,
        address _pair,
        uint256 _liquidity,
        uint256 _minA,
        uint256 _minB
    ) internal {
        TransferHelper.safeApprove(_pair, dxSwapRouter, _liquidity);
        (uint amountA, uint amountB) = IDXswapRouter(dxSwapRouter).removeLiquidity(
            _tokenA,
            _tokenB,
            _liquidity,
            _minA,
            _minB,
            address(this),
            block.timestamp
        );
        TransferHelper.safeApprove(_pair, dxSwapRouter, 0);
        if(_tokenA == WETH){
          IWETH(WETH).withdraw(amountA);
          ETHWithdraw(amountA);
        } else {
          ERC20Withdraw(_tokenA, amountA);
        }
        if (_tokenB == WETH){
          IWETH(WETH).withdraw(amountB);
          ETHWithdraw(amountB);
        } else {
          ERC20Withdraw(_tokenB, amountB);
        }
    }

    // Internal function to calculate the optimal time window for price observation
    function _consultOracleParameters(
        uint256 amountA,
        uint256 amountB,
        uint256 reserveA,
        uint256 reserveB,
        uint256 maxWindowTime
    ) internal view returns (uint256 windowTime) {
        if(reserveA > 0 && reserveB > 0){
            uint256 poolStake = (amountA.add(amountB)).mul(PARTS_PER_MILLION) / reserveA.add(reserveB);
            // poolStake: 0.1% = 1000; 1=10000; 10% = 100000;
            if(poolStake < 1000) {
              windowTime = 30;
            } else if (poolStake < 2500){
              windowTime = 60;
            } else if (poolStake < 5000){
              windowTime = 90;
            } else if (poolStake < 10000){
              windowTime = 120;
            } else {
              windowTime = 150;
            }
            windowTime = windowTime <= maxWindowTime ? windowTime : maxWindowTime;
        } else {
            windowTime = maxWindowTime;
        }
    }

    // Internal function to return the correct pair address on either DXswap or Uniswap
    function _pair(address tokenA, address tokenB, address factory) internal view returns (address pair) {
      require(factory == dxSwapFactory || factory == uniswapFactory, 'DXswapRelayer: INVALID_FACTORY');
      pair = IDXswapFactory(factory).getPair(tokenA, tokenB);
    }

    // Returns an OrderIndex that is used to reference liquidity orders
    function _OrderIndex() internal returns(uint256 orderIndex){
        orderIndex = orderCount;
        orderCount++;
    }
    
    // Allows the owner to withdraw any ERC20 from the relayer
    function ERC20Withdraw(address token, uint256 amount) public {
        require(msg.sender == owner, 'DXswapRelayer: CALLER_NOT_OWNER');
        TransferHelper.safeTransfer(token, owner, amount);
    }

    // Allows the owner to withdraw any ETH amount from the relayer
    function ETHWithdraw(uint256 amount) public {
        require(msg.sender == owner, 'DXswapRelayer: CALLER_NOT_OWNER');
        TransferHelper.safeTransferETH(owner, amount);
    }

    // Returns the data of one specific order
    function GetOrderDetails(uint256 orderIndex) external view returns (Order memory) {
      return orders[orderIndex];
    }

    function changeOwner(address payable _newOwner) external {
      require(msg.sender == owner, 'DXswapRelayer: CALLER_NOT_OWNER');
      owner = _newOwner;
      emit ChangedOwner(_newOwner);
    }

    receive() external payable {}
}