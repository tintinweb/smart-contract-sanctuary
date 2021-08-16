// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';
import '@uniswap/lib/contracts/libraries/FixedPoint.sol';
import '@uniswap/v2-periphery/contracts/libraries/UniswapV2OracleLibrary.sol';
import "./facades/ERC20Like.sol";


contract PriceOracle {
    using FixedPoint for *;
    IUniswapV2Pair public immutable pair;
    uint public immutable multiplier;
    uint private priceLast;
    uint public priceCumulativeLast;
    uint32 public blockTimestampLast;

    address public tokenA;
    address public tokenB;
    address public token0;

    constructor(IUniswapV2Pair _pair, address _tokenA, address _tokenB) public {
        pair = _pair;
        tokenA = _tokenA;
        tokenB = _tokenB;
        multiplier = uint(10)**(ERC20Like(_pair.token1()).decimals());
        (token0, ) = _tokenA < _tokenB
            ? (_tokenA, _tokenB)
            : (_tokenB, _tokenA);
        
        if(token0 == _tokenA) {
          priceCumulativeLast = _pair.price0CumulativeLast();
        } else {
          priceCumulativeLast = _pair.price1CumulativeLast();
        }
    }
    function update() public returns(uint) {
        uint112 reserve0;
        uint112 reserve1;
        (reserve0, reserve1, blockTimestampLast) = pair.getReserves();
        require(reserve0 != 0 && reserve1 != 0, 'PriceOracle: NO_RESERVES');

        uint _priceCumulative;
        (uint _price0Cumulative, uint _price1Cumulative, uint32 _blockTimestamp) =
            UniswapV2OracleLibrary.currentCumulativePrices(address(pair));
        if(token0 == tokenA) {
          _priceCumulative = _price0Cumulative;
        } else {
          _priceCumulative = _price1Cumulative;
        }
        uint _priceCumulativeLast = priceCumulativeLast;
        uint _blockTimestampLast = blockTimestampLast;
        uint _price;
        if (_blockTimestamp != _blockTimestampLast) {
            _price = FixedPoint.uq112x112(uint224((_priceCumulative - _priceCumulativeLast) /
                (_blockTimestamp - _blockTimestampLast))).mul(multiplier).decode144();
            priceLast = _price;
            priceCumulativeLast = _priceCumulative;
            blockTimestampLast = _blockTimestamp;
        } else {
            _price = priceLast;
        }
        return _price;
    }
    // note this will always return 0 before update has been called successfully for the first time.
    function consult() external view returns (uint) {
        uint _priceCumulative;

        (uint _price0Cumulative, uint _price1Cumulative, uint32 _blockTimestamp) =
            UniswapV2OracleLibrary.currentCumulativePrices(address(pair));

        if(token0 == tokenA) {
          _priceCumulative = _price0Cumulative;
        } else {
          _priceCumulative = _price1Cumulative;
        }
        uint _priceCumulativeLast = priceCumulativeLast;
        uint _blockTimestampLast = blockTimestampLast;
        // most recent price is already calculated.
        if (_blockTimestamp == _blockTimestampLast) {
            return priceLast;
        }
        return FixedPoint.uq112x112(uint224((_priceCumulative - _priceCumulativeLast) / 
            (_blockTimestamp - _blockTimestampLast))).mul(multiplier).decode144();
    }
    function updateAndConsult() external returns (uint) {
        return update();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.1;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

abstract contract ERC20Like is IERC20 {
    function totalSupply() external view virtual override returns (uint256);

    function balanceOf(address account) external view virtual override returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        virtual
    override
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        virtual
    override
        returns (uint256);

    function approve(address spender, uint256 amount)
        external
        virtual
    override
        returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external virtual override returns (bool);

    function name() public view virtual returns (string memory);

    function symbol() public view virtual returns (string memory);

    function decimals() public view virtual returns (uint8);

    function burn(uint256 value) public virtual;
}

// SPDX-License-Identifier: MIT

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