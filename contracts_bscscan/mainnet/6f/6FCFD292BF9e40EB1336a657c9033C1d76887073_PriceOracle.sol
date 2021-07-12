// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@pancakeswap-libs/pancake-swap-core/contracts/interfaces/IPancakePair.sol";
import "@bundle-dao/pancakeswap-peripheral/contracts/libraries/PancakeOracleLibrary.sol";
import "@bundle-dao/pancakeswap-peripheral/contracts/libraries/PancakeLibrary.sol";

import "../interfaces/IPriceOracle.sol";

contract PriceOracle is Ownable, IPriceOracle {
    using FixedPoint for *;

    struct PriceData {
        bool initialized;
        uint32 lastUpdatedAt;
        uint256 price0CumulativeLast;
        uint256 price1CumulativeLast;
        FixedPoint.uq112x112 price0Average;
        FixedPoint.uq112x112 price1Average;
    }

    /* ========== Storage ========== */

    uint256 public constant PERIOD = 15 minutes;
    address private _factory;
    address private _peg;
    mapping(address=>PriceData) private _prices;
    mapping(address=>address[]) private _referencePaths;

    /* ========== Constructor ========== */

    constructor(address factory, address peg) public {
        _factory = factory;
        _peg = peg;
    }

    /* ========== Control ========== */

    // Reference paths should all have same output token
    function setReferencePath(address token, address[] calldata path) 
        external onlyOwner 
    {
        require(_peg == path[path.length - 1], "ERR_BAD_REFERENCE_PATH");
        require(token == path[0], "ERR_BAD_REFERENCE_PATH");
        require(path.length >= 2, "ERR_BAD_PATH");
        _referencePaths[token] = path;

        address tokenA;
        address tokenB;

        for (uint256 i = 1; i < path.length; i++) {
            tokenA = path[i - 1];
            tokenB = path[i];
            initializePair(tokenA, tokenB);
        }
    }

    /* ========== Public ========== */

    function updateReference(address token) 
        external override 
    {
        address[] memory path = _referencePaths[token];
        require(path.length >= 2, "ERR_BAD_PATH");
        address tokenA;
        address tokenB;

        for (uint256 i = 1; i < path.length; i++) {
            tokenA = path[i - 1];
            tokenB = path[i];
            _update(tokenA, tokenB);
        }
    }

    function updatePath(address[] calldata path)
        public override
    {
        require(path.length >= 2, "ERR_BAD_PATH");
        address tokenA;
        address tokenB;

        for (uint256 i = 1; i < path.length; i++) {
            tokenA = path[i - 1];
            tokenB = path[i];
            _update(tokenA, tokenB);
        }
    } 

    function consultReference(address token, uint256 amountIn) 
        external view override 
        returns (uint256) 
    {
        address[] memory path = _referencePaths[token];
        require(path.length >= 2, "ERR_BAD_PATH");
        address tokenA;
        address tokenB;
        uint256 amount = amountIn;

        for (uint256 i = 1; i < path.length; i++) {
            tokenA = path[i - 1];
            tokenB = path[i];
            amount = _consult(tokenA, tokenB, amount);
        }

        return amount;
    }

    function consultPath(address[] calldata path, uint256 amountIn)
        external view override
        returns (uint256)
    {
        require(path.length >= 2, "ERR_BAD_PATH");
        address tokenA;
        address tokenB;
        uint256 amount = amountIn;

        for (uint256 i = 1; i < path.length; i++) {
            tokenA = path[i - 1];
            tokenB = path[i];
            amount = _consult(tokenA, tokenB, amount);
        }

        return amount;
    }

    function initializePair(address tokenA, address tokenB) 
        public override
    {
        require(address(tokenA) != address(0) && address(tokenB) != address(0), "ERR_BAD_ADDRESS");

        IPancakePair pair = IPancakePair(PancakeLibrary.pairFor(_factory, tokenA, tokenB));

        if (!_prices[address(pair)].initialized) {
            (uint256 reserve0, uint256 reserve1, uint32 blockTimestampLast) = pair.getReserves();
            require(reserve0 != 0 && reserve1 != 0, "ERR_NO_RESERVES"); // ensure that there's liquidity in the pair

            _prices[address(pair)] = PriceData({
                initialized: true,
                lastUpdatedAt: blockTimestampLast,
                price0CumulativeLast: pair.price0CumulativeLast(),
                price1CumulativeLast: pair.price0CumulativeLast(),
                price0Average: FixedPoint.uq112x112(0),
                price1Average: FixedPoint.uq112x112(0)
            });
        }
    }

    function getPeg() 
        external view override 
        returns (address) 
    {
        return _peg;
    }

    /* ========== Internal ========== */

    function _update(address tokenA, address tokenB) 
        internal 
    {
        IPancakePair pair = IPancakePair(PancakeLibrary.pairFor(_factory, tokenA, tokenB));
        PriceData memory priceData = _prices[address(pair)];
        require(priceData.initialized, "ERR_PAIR_NOT_INITIALIZED");

        (uint256 price0Cumulative, uint256 price1Cumulative, uint32 blockTimestamp) =
            PancakeOracleLibrary.currentCumulativePrices(address(pair));
        uint32 timeElapsed = blockTimestamp - priceData.lastUpdatedAt; // overflow is desired

        // ensure that at least one full period has passed since the last update
        if (timeElapsed >= PERIOD) {
            // overflow is desired, casting never truncates
            // cumulative price is in (uq112x112 price * seconds) units so we simply wrap it after division by time elapsed
            _prices[address(pair)].price0Average = FixedPoint.uq112x112(uint224((price0Cumulative - priceData.price0CumulativeLast) / timeElapsed));
            _prices[address(pair)].price1Average = FixedPoint.uq112x112(uint224((price1Cumulative - priceData.price1CumulativeLast) / timeElapsed));
            _prices[address(pair)].price0CumulativeLast = price0Cumulative;
            _prices[address(pair)].price1CumulativeLast = price1Cumulative;
            _prices[address(pair)].lastUpdatedAt = blockTimestamp;
        }
    }

    // note this will always return 0 before update has been called successfully for the first time.
    function _consult(address tokenIn, address tokenOut, uint256 amountIn) 
        internal view 
        returns (uint256) 
    {
        IPancakePair pair = IPancakePair(PancakeLibrary.pairFor(_factory, tokenIn, tokenOut));
        PriceData memory priceData = _prices[address(pair)];
        require(priceData.initialized, "ERR_PAIR_NOT_INITIALIZED");
        
        if (tokenIn == pair.token0()) {
            return priceData.price0Average.mul(amountIn).decode144();
        } else {
            require(tokenIn == pair.token1(), "ERR_INVALID_TOKEN");
            return priceData.price1Average.mul(amountIn).decode144();
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/Context.sol";
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
abstract contract Ownable is Context {
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
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

pragma solidity >=0.5.0;

interface IPancakePair {
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

pragma solidity >=0.5.0;

import "@pancakeswap-libs/pancake-swap-core/contracts/interfaces/IPancakePair.sol";
import '@uniswap/lib/contracts/libraries/FixedPoint.sol';

// library with helper methods for oracles that are concerned with computing average prices
library PancakeOracleLibrary {
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
        price0Cumulative = IPancakePair(pair).price0CumulativeLast();
        price1Cumulative = IPancakePair(pair).price1CumulativeLast();

        // if time has elapsed since the last update on the pair, mock the accumulated price values
        (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) = IPancakePair(pair).getReserves();
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

pragma solidity >=0.5.0;

import "@pancakeswap-libs/pancake-swap-core/contracts/interfaces/IPancakePair.sol";
import "@pancakeswap-libs/pancake-swap-core/contracts/interfaces/IPancakeFactory.sol";

import "./SafeMath.sol";

library PancakeLibrary {
    using SafeMath for uint;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'PancakeLibrary: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'PancakeLibrary: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal view returns (address pair) {
        return IPancakeFactory(factory).getPair(tokenA, tokenB);
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        pairFor(factory, tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IPancakePair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'PancakeLibrary: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'PancakeLibrary: INSUFFICIENT_LIQUIDITY');
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'PancakeLibrary: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'PancakeLibrary: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn.mul(998);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'PancakeLibrary: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'PancakeLibrary: INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn.mul(amountOut).mul(1000);
        uint denominator = reserveOut.sub(amountOut).mul(998);
        amountIn = (numerator / denominator).add(1);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(address factory, uint amountIn, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'PancakeLibrary: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(address factory, uint amountOut, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'PancakeLibrary: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IPriceOracle {
    function updateReference(address token) external;

    function updatePath(address[] calldata path) external;

    function consultReference(address token, uint256 amountIn) external view returns (uint256);

    function consultPath(address[] calldata path, uint256 amountIn) external view returns (uint256);

    function initializePair(address tokenA, address tokenB) external;

    function getPeg() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

pragma solidity >=0.4.0;

import './Babylonian.sol';

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
    uint private constant Q112 = uint(1) << RESOLUTION;
    uint private constant Q224 = Q112 << RESOLUTION;

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

    // take the reciprocal of a UQ112x112
    function reciprocal(uq112x112 memory self) internal pure returns (uq112x112 memory) {
        require(self._x != 0, 'FixedPoint: ZERO_RECIPROCAL');
        return uq112x112(uint224(Q224 / self._x));
    }

    // square root of a UQ112x112
    function sqrt(uq112x112 memory self) internal pure returns (uq112x112 memory) {
        return uq112x112(uint224(Babylonian.sqrt(uint256(self._x)) << 56));
    }
}

pragma solidity >=0.4.0;

// computes square roots using the babylonian method
// https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method
library Babylonian {
    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
        // else z = 0
    }
}

pragma solidity >=0.5.0;

interface IPancakeFactory {
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

pragma solidity ^0.6.6;

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