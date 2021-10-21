/**
 *Submitted for verification at polygonscan.com on 2021-10-21
*/

// Sources flattened with hardhat v2.6.6 https://hardhat.org

// File contracts/interfaces/ISPT.sol

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity =0.6.6;

interface ISPT {
  event Subscribed(
    address indexed subscriber,
    address indexed token,
    uint256 tokensPaid,
    uint256 expiryDate
  );

  function init(
    address wad_,
    address[] calldata path_,
    address factory_,
    uint256 window_,
    uint8 gran_
  ) external;

  function wad() external view returns (address);

  function path() external view returns (address[] memory);

  function deployer() external view returns (address);

  function price(uint256 period) external view returns (uint256, address);

  function pricenv(uint256 period) external returns (uint256, address);

  function subscribe(uint8 idx) external returns (uint256);
}


// File contracts/interfaces/IUniswapV2Factory.sol

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
  event PairCreated(
    address indexed token0,
    address indexed token1,
    address pair,
    uint256
  );

  function feeTo() external view returns (address);

  function feeToSetter() external view returns (address);

  function getPair(address tokenA, address tokenB)
    external
    view
    returns (address pair);

  function allPairs(uint256) external view returns (address pair);

  function allPairsLength() external view returns (uint256);

  function createPair(address tokenA, address tokenB)
    external
    returns (address pair);

  function setFeeTo(address) external;

  function setFeeToSetter(address) external;
}


// File contracts/interfaces/IUniswapV2Pair.sol

//SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
  event Approval(address indexed owner, address indexed spender, uint256 value);
  event Transfer(address indexed from, address indexed to, uint256 value);

  function name() external pure returns (string memory);

  function symbol() external pure returns (string memory);

  function decimals() external pure returns (uint8);

  function totalSupply() external view returns (uint256);

  function balanceOf(address owner) external view returns (uint256);

  function allowance(address owner, address spender)
    external
    view
    returns (uint256);

  function approve(address spender, uint256 value) external returns (bool);

  function transfer(address to, uint256 value) external returns (bool);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool);

  function DOMAIN_SEPARATOR() external view returns (bytes32);

  function PERMIT_TYPEHASH() external pure returns (bytes32);

  function nonces(address owner) external view returns (uint256);

  function permit(
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;

  event Mint(address indexed sender, uint256 amount0, uint256 amount1);
  event Burn(
    address indexed sender,
    uint256 amount0,
    uint256 amount1,
    address indexed to
  );
  event Swap(
    address indexed sender,
    uint256 amount0In,
    uint256 amount1In,
    uint256 amount0Out,
    uint256 amount1Out,
    address indexed to
  );
  event Sync(uint112 reserve0, uint112 reserve1);

  function MINIMUM_LIQUIDITY() external pure returns (uint256);

  function factory() external view returns (address);

  function token0() external view returns (address);

  function token1() external view returns (address);

  function getReserves()
    external
    view
    returns (
      uint112 reserve0,
      uint112 reserve1,
      uint32 blockTimestampLast
    );

  function price0CumulativeLast() external view returns (uint256);

  function price1CumulativeLast() external view returns (uint256);

  function kLast() external view returns (uint256);

  function mint(address to) external returns (uint256 liquidity);

  function burn(address to) external returns (uint256 amount0, uint256 amount1);

  function swap(
    uint256 amount0Out,
    uint256 amount1Out,
    address to,
    bytes calldata data
  ) external;

  function skim(address to) external;

  function sync() external;

  function initialize(address, address) external;
}


// File contracts/interfaces/IEnv.sol

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity =0.6.6;

interface IEnv {
  function rcv() external view returns (address);

  function dsc() external view returns (address);

  function max() external view returns (uint256);

  function fee() external view returns (uint256);

  function spt(address wad, address factory) external view returns (address);

  function end(address usr) external view returns (uint256);

  function active(address ctr) external view returns (bool);

  function month(uint8 idx) external view returns (uint256);

  function price(address wad, uint256 period) external view returns (uint256);

  function set_rcv(address rcv_) external;

  function set_max(uint256 max_) external;

  function set_end(uint256 end_, address guy) external;

  function set_fee(uint256 fee_) external;

  function stop(address ctr) external;

  function start(address ctr) external;
}


// File contracts/libraries/TransferHelper.sol

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeApprove: approve failed'
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeTransfer: transfer failed'
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::transferFrom: transferFrom failed'
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper::safeTransferETH: ETH transfer failed');
    }
}


// File contracts/libraries/SafeMath.sol

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity =0.6.6;

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMath {
  function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
    require((z = x + y) >= x, "ds-math-add-overflow");
  }

  function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
    require((z = x - y) <= x, "ds-math-sub-underflow");
  }

  function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
    require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
  }
}


// File contracts/libraries/FullMath.sol

// SPDX-License-Identifier: CC-BY-4.0
pragma solidity >=0.4.0;

// taken from https://medium.com/coinmonks/math-in-solidity-part-3-percents-and-proportions-4db014e080b1
// license is CC-BY-4.0
library FullMath {
    function fullMul(uint256 x, uint256 y) internal pure returns (uint256 l, uint256 h) {
        uint256 mm = mulmod(x, y, uint256(-1));
        l = x * y;
        h = mm - l;
        if (mm < l) h -= 1;
    }

    function fullDiv(
        uint256 l,
        uint256 h,
        uint256 d
    ) private pure returns (uint256) {
        uint256 pow2 = d & -d;
        d /= pow2;
        l /= pow2;
        l += h * ((-pow2) / pow2 + 1);
        uint256 r = 1;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        return l * r;
    }

    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 d
    ) internal pure returns (uint256) {
        (uint256 l, uint256 h) = fullMul(x, y);

        uint256 mm = mulmod(x, y, d);
        if (mm > l) h -= 1;
        l -= mm;

        if (h == 0) return l / d;

        require(h < d, 'FullMath: FULLDIV_OVERFLOW');
        return fullDiv(l, h, d);
    }
}


// File contracts/libraries/Babylonian.sol

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.4.0;

// computes square roots using the babylonian method
// https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method
library Babylonian {
    // credit for this implementation goes to
    // https://github.com/abdk-consulting/abdk-libraries-solidity/blob/master/ABDKMath64x64.sol#L687
    function sqrt(uint256 x) internal pure returns (uint256) {
        if (x == 0) return 0;
        // this block is equivalent to r = uint256(1) << (BitMath.mostSignificantBit(x) / 2);
        // however that code costs significantly more gas
        uint256 xx = x;
        uint256 r = 1;
        if (xx >= 0x100000000000000000000000000000000) {
            xx >>= 128;
            r <<= 64;
        }
        if (xx >= 0x10000000000000000) {
            xx >>= 64;
            r <<= 32;
        }
        if (xx >= 0x100000000) {
            xx >>= 32;
            r <<= 16;
        }
        if (xx >= 0x10000) {
            xx >>= 16;
            r <<= 8;
        }
        if (xx >= 0x100) {
            xx >>= 8;
            r <<= 4;
        }
        if (xx >= 0x10) {
            xx >>= 4;
            r <<= 2;
        }
        if (xx >= 0x8) {
            r <<= 1;
        }
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1; // Seven iterations should be enough
        uint256 r1 = x / r;
        return (r < r1 ? r : r1);
    }
}


// File contracts/libraries/BitMath.sol

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.5.0;

library BitMath {
    // returns the 0 indexed position of the most significant bit of the input x
    // s.t. x >= 2**msb and x < 2**(msb+1)
    function mostSignificantBit(uint256 x) internal pure returns (uint8 r) {
        require(x > 0, "BitMath::mostSignificantBit: zero");

        if (x >= 0x100000000000000000000000000000000) {
            x >>= 128;
            r += 128;
        }
        if (x >= 0x10000000000000000) {
            x >>= 64;
            r += 64;
        }
        if (x >= 0x100000000) {
            x >>= 32;
            r += 32;
        }
        if (x >= 0x10000) {
            x >>= 16;
            r += 16;
        }
        if (x >= 0x100) {
            x >>= 8;
            r += 8;
        }
        if (x >= 0x10) {
            x >>= 4;
            r += 4;
        }
        if (x >= 0x4) {
            x >>= 2;
            r += 2;
        }
        if (x >= 0x2) r += 1;
    }

    // returns the 0 indexed position of the least significant bit of the input x
    // s.t. (x & 2**lsb) != 0 and (x & (2**(lsb) - 1)) == 0)
    // i.e. the bit at the index is set and the mask of all lower bits is 0
    function leastSignificantBit(uint256 x) internal pure returns (uint8 r) {
        require(x > 0, "BitMath::leastSignificantBit: zero");

        r = 255;
        if (x & uint128(-1) > 0) {
            r -= 128;
        } else {
            x >>= 128;
        }
        if (x & uint64(-1) > 0) {
            r -= 64;
        } else {
            x >>= 64;
        }
        if (x & uint32(-1) > 0) {
            r -= 32;
        } else {
            x >>= 32;
        }
        if (x & uint16(-1) > 0) {
            r -= 16;
        } else {
            x >>= 16;
        }
        if (x & uint8(-1) > 0) {
            r -= 8;
        } else {
            x >>= 8;
        }
        if (x & 0xf > 0) {
            r -= 4;
        } else {
            x >>= 4;
        }
        if (x & 0x3 > 0) {
            r -= 2;
        } else {
            x >>= 2;
        }
        if (x & 0x1 > 0) r -= 1;
    }
}


// File contracts/libraries/FixedPoint.sol

// SPDX-License-Identifier: GPL-3.0-or-later
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
        uint256 _x;
    }

    uint8 public constant RESOLUTION = 112;
    uint256 public constant Q112 = 0x10000000000000000000000000000; // 2**112
    uint256 private constant Q224 = 0x100000000000000000000000000000000000000000000000000000000; // 2**224
    uint256 private constant LOWER_MASK = 0xffffffffffffffffffffffffffff; // decimal of UQ*x112 (lower 112 bits)

    // encode a uint112 as a UQ112x112
    function encode(uint112 x) internal pure returns (uq112x112 memory) {
        return uq112x112(uint224(x) << RESOLUTION);
    }

    // encodes a uint144 as a UQ144x112
    function encode144(uint144 x) internal pure returns (uq144x112 memory) {
        return uq144x112(uint256(x) << RESOLUTION);
    }

    // decode a UQ112x112 into a uint112 by truncating after the radix point
    function decode(uq112x112 memory self) internal pure returns (uint112) {
        return uint112(self._x >> RESOLUTION);
    }

    // decode a UQ144x112 into a uint144 by truncating after the radix point
    function decode144(uq144x112 memory self) internal pure returns (uint144) {
        return uint144(self._x >> RESOLUTION);
    }

    // multiply a UQ112x112 by a uint, returning a UQ144x112
    // reverts on overflow
    function mul(uq112x112 memory self, uint256 y) internal pure returns (uq144x112 memory) {
        uint256 z = 0;
        require(y == 0 || (z = self._x * y) / y == self._x, 'FixedPoint::mul: overflow');
        return uq144x112(z);
    }

    // multiply a UQ112x112 by an int and decode, returning an int
    // reverts on overflow
    function muli(uq112x112 memory self, int256 y) internal pure returns (int256) {
        uint256 z = FullMath.mulDiv(self._x, uint256(y < 0 ? -y : y), Q112);
        require(z < 2**255, 'FixedPoint::muli: overflow');
        return y < 0 ? -int256(z) : int256(z);
    }

    // multiply a UQ112x112 by a UQ112x112, returning a UQ112x112
    // lossy
    function muluq(uq112x112 memory self, uq112x112 memory other) internal pure returns (uq112x112 memory) {
        if (self._x == 0 || other._x == 0) {
            return uq112x112(0);
        }
        uint112 upper_self = uint112(self._x >> RESOLUTION); // * 2^0
        uint112 lower_self = uint112(self._x & LOWER_MASK); // * 2^-112
        uint112 upper_other = uint112(other._x >> RESOLUTION); // * 2^0
        uint112 lower_other = uint112(other._x & LOWER_MASK); // * 2^-112

        // partial products
        uint224 upper = uint224(upper_self) * upper_other; // * 2^0
        uint224 lower = uint224(lower_self) * lower_other; // * 2^-224
        uint224 uppers_lowero = uint224(upper_self) * lower_other; // * 2^-112
        uint224 uppero_lowers = uint224(upper_other) * lower_self; // * 2^-112

        // so the bit shift does not overflow
        require(upper <= uint112(-1), 'FixedPoint::muluq: upper overflow');

        // this cannot exceed 256 bits, all values are 224 bits
        uint256 sum = uint256(upper << RESOLUTION) + uppers_lowero + uppero_lowers + (lower >> RESOLUTION);

        // so the cast does not overflow
        require(sum <= uint224(-1), 'FixedPoint::muluq: sum overflow');

        return uq112x112(uint224(sum));
    }

    // divide a UQ112x112 by a UQ112x112, returning a UQ112x112
    function divuq(uq112x112 memory self, uq112x112 memory other) internal pure returns (uq112x112 memory) {
        require(other._x > 0, 'FixedPoint::divuq: division by zero');
        if (self._x == other._x) {
            return uq112x112(uint224(Q112));
        }
        if (self._x <= uint144(-1)) {
            uint256 value = (uint256(self._x) << RESOLUTION) / other._x;
            require(value <= uint224(-1), 'FixedPoint::divuq: overflow');
            return uq112x112(uint224(value));
        }

        uint256 result = FullMath.mulDiv(Q112, self._x, other._x);
        require(result <= uint224(-1), 'FixedPoint::divuq: overflow');
        return uq112x112(uint224(result));
    }

    // returns a UQ112x112 which represents the ratio of the numerator to the denominator
    // can be lossy
    function fraction(uint256 numerator, uint256 denominator) internal pure returns (uq112x112 memory) {
        require(denominator > 0, 'FixedPoint::fraction: division by zero');
        if (numerator == 0) return FixedPoint.uq112x112(0);

        if (numerator <= uint144(-1)) {
            uint256 result = (numerator << RESOLUTION) / denominator;
            require(result <= uint224(-1), 'FixedPoint::fraction: overflow');
            return uq112x112(uint224(result));
        } else {
            uint256 result = FullMath.mulDiv(numerator, Q112, denominator);
            require(result <= uint224(-1), 'FixedPoint::fraction: overflow');
            return uq112x112(uint224(result));
        }
    }

    // take the reciprocal of a UQ112x112
    // reverts on overflow
    // lossy
    function reciprocal(uq112x112 memory self) internal pure returns (uq112x112 memory) {
        require(self._x != 0, 'FixedPoint::reciprocal: reciprocal of zero');
        require(self._x != 1, 'FixedPoint::reciprocal: overflow');
        return uq112x112(uint224(Q224 / self._x));
    }

    // square root of a UQ112x112
    // lossy between 0/1 and 40 bits
    function sqrt(uq112x112 memory self) internal pure returns (uq112x112 memory) {
        if (self._x <= uint144(-1)) {
            return uq112x112(uint224(Babylonian.sqrt(uint256(self._x) << 112)));
        }

        uint8 safeShiftBits = 255 - BitMath.mostSignificantBit(self._x);
        safeShiftBits -= safeShiftBits % 2;
        return uq112x112(uint224(Babylonian.sqrt(uint256(self._x) << safeShiftBits) << ((112 - safeShiftBits) / 2)));
    }
}


// File contracts/libraries/UniswapV2Library.sol

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity >=0.5.0;
library UniswapV2Library {
  using SafeMath for uint256;

  // returns sorted token addresses, used to handle return values from pairs sorted in this order
  function sortTokens(address tokenA, address tokenB)
    internal
    pure
    returns (address token0, address token1)
  {
    require(tokenA != tokenB, "UniswapV2Library: IDENTICAL_ADDRESSES");
    (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
    require(token0 != address(0), "UniswapV2Library: ZERO_ADDRESS");
  }

  // calculates the CREATE2 address for a pair without making any external calls
  function pairFor(
    address factory,
    address tokenA,
    address tokenB
  ) internal pure returns (address pair) {
    (address token0, address token1) = sortTokens(tokenA, tokenB);
    pair = address(
      uint256(
        keccak256(
          abi.encodePacked(
            hex"ff",
            factory,
            keccak256(abi.encodePacked(token0, token1)),
            hex"96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f" // init code hash
          )
        )
      )
    );
  }

  // fetches and sorts the reserves for a pair
  function getReserves(
    address factory,
    address tokenA,
    address tokenB
  ) internal view returns (uint256 reserveA, uint256 reserveB) {
    (address token0, ) = sortTokens(tokenA, tokenB);
    (uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(
      pairFor(factory, tokenA, tokenB)
    ).getReserves();
    (reserveA, reserveB) = tokenA == token0
      ? (reserve0, reserve1)
      : (reserve1, reserve0);
  }

  // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
  function quote(
    uint256 amountA,
    uint256 reserveA,
    uint256 reserveB
  ) internal pure returns (uint256 amountB) {
    require(amountA > 0, "UniswapV2Library: INSUFFICIENT_AMOUNT");
    require(
      reserveA > 0 && reserveB > 0,
      "UniswapV2Library: INSUFFICIENT_LIQUIDITY"
    );
    amountB = amountA.mul(reserveB) / reserveA;
  }

  // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
  function getAmountOut(
    uint256 amountIn,
    uint256 reserveIn,
    uint256 reserveOut
  ) internal pure returns (uint256 amountOut) {
    require(amountIn > 0, "UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT");
    require(
      reserveIn > 0 && reserveOut > 0,
      "UniswapV2Library: INSUFFICIENT_LIQUIDITY"
    );
    uint256 amountInWithFee = amountIn.mul(997);
    uint256 numerator = amountInWithFee.mul(reserveOut);
    uint256 denominator = reserveIn.mul(1000).add(amountInWithFee);
    amountOut = numerator / denominator;
  }

  // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
  function getAmountIn(
    uint256 amountOut,
    uint256 reserveIn,
    uint256 reserveOut
  ) internal pure returns (uint256 amountIn) {
    require(amountOut > 0, "UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT");
    require(
      reserveIn > 0 && reserveOut > 0,
      "UniswapV2Library: INSUFFICIENT_LIQUIDITY"
    );
    uint256 numerator = reserveIn.mul(amountOut).mul(1000);
    uint256 denominator = reserveOut.sub(amountOut).mul(997);
    amountIn = (numerator / denominator).add(1);
  }

  // performs chained getAmountOut calculations on any number of pairs
  function getAmountsOut(
    address factory,
    uint256 amountIn,
    address[] memory path
  ) internal view returns (uint256[] memory amounts) {
    require(path.length >= 2, "UniswapV2Library: INVALID_PATH");
    amounts = new uint256[](path.length);
    amounts[0] = amountIn;
    for (uint256 i; i < path.length - 1; i++) {
      (uint256 reserveIn, uint256 reserveOut) = getReserves(
        factory,
        path[i],
        path[i + 1]
      );
      amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
    }
  }

  // performs chained getAmountIn calculations on any number of pairs
  function getAmountsIn(
    address factory,
    uint256 amountOut,
    address[] memory path
  ) internal view returns (uint256[] memory amounts) {
    require(path.length >= 2, "UniswapV2Library: INVALID_PATH");
    amounts = new uint256[](path.length);
    amounts[amounts.length - 1] = amountOut;
    for (uint256 i = path.length - 1; i > 0; i--) {
      (uint256 reserveIn, uint256 reserveOut) = getReserves(
        factory,
        path[i - 1],
        path[i]
      );
      amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
    }
  }
}


// File contracts/libraries/UniswapV2OracleLibrary.sol

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity >=0.5.0;
// library with helper methods for oracles that are concerned with computing average prices
library UniswapV2OracleLibrary {
  using FixedPoint for *;

  // helper function that returns the current block timestamp within the range of uint32, i.e. [0, 2**32 - 1]
  function currentBlockTimestamp() internal view returns (uint32) {
    return uint32(block.timestamp % 2**32);
  }

  // produces the cumulative price using counterfactuals to save gas and avoid a call to sync.
  function currentCumulativePrices(address pair)
    internal
    view
    returns (
      uint256 price0Cumulative,
      uint256 price1Cumulative,
      uint32 blockTimestamp
    )
  {
    blockTimestamp = currentBlockTimestamp();
    price0Cumulative = IUniswapV2Pair(pair).price0CumulativeLast();
    price1Cumulative = IUniswapV2Pair(pair).price1CumulativeLast();

    // if time has elapsed since the last update on the pair, mock the accumulated price values
    (
      uint112 reserve0,
      uint112 reserve1,
      uint32 blockTimestampLast
    ) = IUniswapV2Pair(pair).getReserves();
    if (blockTimestampLast != blockTimestamp) {
      // subtraction overflow is desired
      uint32 timeElapsed = blockTimestamp - blockTimestampLast;
      // addition overflow is desired
      // counterfactual
      price0Cumulative +=
        uint256(FixedPoint.fraction(reserve1, reserve0)._x) *
        timeElapsed;
      // counterfactual
      price1Cumulative +=
        uint256(FixedPoint.fraction(reserve0, reserve1)._x) *
        timeElapsed;
    }
  }
}


// File contracts/oracle.sol

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity =0.6.6;
// sliding window oracle that uses observations collected over a window to provide moving price averages in the past
// `windowSize` with a precision of `windowSize / granularity`
// note this is a singleton oracle and only needs to be deployed once per desired parameters, which
// differs from the simple oracle which must be deployed once per pair.
contract Oracle {
  using FixedPoint for *;
  using SafeMath for uint256;

  struct Observation {
    uint256 timestamp;
    uint256 price0Cumulative;
    uint256 price1Cumulative;
  }

  address public factory;
  // the desired amount of time over which the moving average should be computed, e.g. 24 hours
  uint256 public windowSize;
  // the number of observations stored for each pair, i.e. how many price observations are stored for the window.
  // as granularity increases from 1, more frequent updates are needed, but moving averages become more precise.
  // averages are computed over intervals with sizes in the range:
  //   [windowSize - (windowSize / granularity) * 2, windowSize]
  // e.g. if the window size is 24 hours, and the granularity is 24, the oracle will return the average price for
  //   the period:
  //   [now - [22 hours, 24 hours], now]
  uint8 public granularity;
  // this is redundant with granularity and windowSize, but stored for gas savings & informational purposes.
  uint256 public periodSize;

  // mapping from pair address to a list of price observations of that pair
  mapping(address => Observation[]) public pairObservations;

  // returns the index of the observation corresponding to the given timestamp
  function observationIndexOf(uint256 timestamp)
    public
    view
    returns (uint8 index)
  {
    uint256 epochPeriod = timestamp / periodSize;
    return uint8(epochPeriod % granularity);
  }

  // returns the observation from the oldest epoch (at the beginning of the window) relative to the current time
  function getFirstObservationInWindow(address pair)
    private
    view
    returns (Observation storage firstObservation)
  {
    uint8 observationIndex = observationIndexOf(block.timestamp);
    // no overflow issue. if observationIndex + 1 overflows, result is still zero.
    uint8 firstObservationIndex = (observationIndex + 1) % granularity;
    firstObservation = pairObservations[pair][firstObservationIndex];
  }

  // update the cumulative price for the observation at the current timestamp. each observation is updated at most
  // once per epoch period.
  function update(address tokenA, address tokenB) external {
    address pair = UniswapV2Library.pairFor(factory, tokenA, tokenB);

    // populate the array with empty observations (first call only)
    for (uint256 i = pairObservations[pair].length; i < granularity; i++) {
      pairObservations[pair].push();
    }

    // get the observation for the current period
    uint8 observationIndex = observationIndexOf(block.timestamp);
    Observation storage observation = pairObservations[pair][observationIndex];

    // we only want to commit updates once per period (i.e. windowSize / granularity)
    uint256 timeElapsed = block.timestamp - observation.timestamp;
    if (timeElapsed > periodSize) {
      (
        uint256 price0Cumulative,
        uint256 price1Cumulative,

      ) = UniswapV2OracleLibrary.currentCumulativePrices(pair);
      observation.timestamp = block.timestamp;
      observation.price0Cumulative = price0Cumulative;
      observation.price1Cumulative = price1Cumulative;
    }
  }

  // given the cumulative prices of the start and end of a period, and the length of the period, compute the average
  // price in terms of how much amount out is received for the amount in
  function computeAmountOut(
    uint256 priceCumulativeStart,
    uint256 priceCumulativeEnd,
    uint256 timeElapsed,
    uint256 amountIn
  ) private pure returns (uint256 amountOut) {
    // overflow is desired.
    FixedPoint.uq112x112 memory priceAverage = FixedPoint.uq112x112(
      uint224((priceCumulativeEnd - priceCumulativeStart) / timeElapsed)
    );
    amountOut = priceAverage.mul(amountIn).decode144();
  }

  // returns the amount out corresponding to the amount in for a given token using the moving average over the time
  // range [now - [windowSize, windowSize - periodSize * 2], now]
  // update must have been called for the bucket corresponding to timestamp `now - windowSize`
  function consult(
    address tokenIn,
    uint256 amountIn,
    address tokenOut
  ) external view returns (uint256 amountOut) {
    address pair = UniswapV2Library.pairFor(factory, tokenIn, tokenOut);
    Observation storage firstObservation = getFirstObservationInWindow(pair);

    uint256 timeElapsed = block.timestamp - firstObservation.timestamp;
    require(
      timeElapsed <= windowSize,
      "SlidingWindowOracle: MISSING_HISTORICAL_OBSERVATION"
    );
    // should never happen.
    require(
      timeElapsed >= windowSize - periodSize * 2,
      "SlidingWindowOracle: UNEXPECTED_TIME_ELAPSED"
    );

    (
      uint256 price0Cumulative,
      uint256 price1Cumulative,

    ) = UniswapV2OracleLibrary.currentCumulativePrices(pair);
    (address token0, ) = UniswapV2Library.sortTokens(tokenIn, tokenOut);

    if (token0 == tokenIn) {
      return
        computeAmountOut(
          firstObservation.price0Cumulative,
          price0Cumulative,
          timeElapsed,
          amountIn
        );
    } else {
      return
        computeAmountOut(
          firstObservation.price1Cumulative,
          price1Cumulative,
          timeElapsed,
          amountIn
        );
    }
  }
}


// File contracts/spt.sol

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity =0.6.6;







contract SPT is ISPT, Oracle {
  using SafeMath for uint256;
  uint256 private immutable MONTH = 30 days;

  address[] private PATH;
  bytes4 private constant SELECTOR =
    bytes4(keccak256(bytes("transfer(address,uint256)")));
  IEnv private immutable env;

  address public override wad;

  function _safeTransfer(
    address token,
    address to,
    uint256 value
  ) private {
    (bool success, bytes memory data) = token.call(
      abi.encodeWithSelector(SELECTOR, to, value)
    );
    require(success && (data.length == 0 || abi.decode(data, (bool))), "TF");
  }

  constructor() public {
    env = IEnv(msg.sender);
  }

  function init(
    address wad_,
    address[] calldata path_,
    address factory_,
    uint256 window_,
    uint8 gran_
  ) external override {
    require(msg.sender == address(env), "SPT/not-authorized");
    require(gran_ > 1, "SlidingWindowOracle: GRANULARITY");
    require(
      (periodSize = window_ / gran_) * gran_ == window_,
      "SlidingWindowOracle: WINDOW_NOT_EVENLY_DIVISIBLE"
    );
    wad = wad_;
    factory = factory_;
    PATH = path_;
    windowSize = window_;
    granularity = gran_;
  }

  function path() external view override returns (address[] memory) {
    return PATH;
  }

  function deployer() external view override returns (address) {
    return address(env);
  }

  // unupdated, run getPriceUpdated before using this.
  function price(uint256 period)
    external
    view
    override
    returns (uint256, address)
  {
    uint256 val = env.price(wad, period);
    address dst;
    for (uint256 i; i < PATH.length - 1; i++) {
      address src = PATH[i];
      dst = PATH[i + 1];
      val = this.consult(src, val, dst);
    }
    return (val, dst);
  }

  function pricenv(uint256 period)
    external
    override
    returns (uint256, address)
  {
    uint256 val = env.price(wad, period);
    address dst;
    for (uint256 i; i < PATH.length - 1; i++) {
      address src = PATH[i];
      dst = PATH[i + 1];
      this.update(src, dst);
      val = this.consult(src, val, dst);
    }
    return (val, dst);
  }

  function subscribe(uint8 idx) external override returns (uint256) {
    uint256 end_old = env.end(msg.sender);
    uint256 period = env.month(idx);
    address rcv = env.rcv();
    uint256 end = end_old == 0
      ? block.timestamp.add(period.mul(MONTH))
      : end_old.add(period.mul(MONTH));
    uint256 MAX_MONTHS = env.max().mul(MONTH);
    // new expiry date can not be more than 12 months from now;
    require((end.sub(block.timestamp)) <= MAX_MONTHS, "SPT/max-reached");

    (uint256 val, address src) = this.pricenv(period);
    val = val.mul(period);

    TransferHelper.safeTransferFrom(src, msg.sender, rcv, val);
    env.set_end(end, msg.sender);
    emit Subscribed(msg.sender, src, val, end);
    return end;
  }
}


// File contracts/auth.sol

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity =0.6.6;

contract Auth {
  mapping(address => bool) private _wards;

  function ward(address guy) public view virtual returns (bool) {
    return _wards[guy];
  }

  modifier auth() {
    require(_wards[msg.sender] == true, "auth/unauthorized");
    _;
  }

  function rely(address guy) external auth {
    _wards[guy] = true;
  }

  function deny(address guy) external auth {
    _wards[guy] = false;
  }

  constructor() public {
    _wards[msg.sender] = true;
  }
}


// File contracts/interfaces/IDiscounter.sol

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity >=0.6.6;

interface IDiscounter {
  function calc(
    address wad,
    uint256 fee,
    uint256 period
  ) external view returns (uint256);
}


// File contracts/env.sol

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity =0.6.6;

contract Env is Auth, IEnv {
  address public override dsc;
  uint256 public override max;
  uint256 public override fee;
  address public override rcv;

  uint256[] internal months;

  // token -> factory -> sub address
  mapping(address => mapping(address => address)) public override spt;

  // usr -> expiration date
  mapping(address => uint256) public override end;

  // spt -> bool
  mapping(address => bool) public override active;

  modifier handler() {
    require(active[msg.sender], "Deployer/inactive");
    _;
  }

  constructor(
    uint8[] memory months_,
    uint256 fee_,
    uint256 max_
  ) public {
    max = max_;
    fee = fee_;
    months = months_;
    rcv = msg.sender;
  }

  function set_rcv(address rcv_) external override auth {
    rcv = rcv_;
  }

  function month(uint8 idx) external view override returns (uint256) {
    require(idx < months.length, "Deployer/exceeds-array");
    return months[idx];
  }

  function price(address wad, uint256 period)
    external
    view
    override
    returns (uint256)
  {
    if (dsc != address(0)) {
      return IDiscounter(dsc).calc(wad, fee, period);
    }
    return fee;
  }

  function set_max(uint256 max_) external override auth {
    max = max_;
  }

  function set_end(uint256 end_, address guy) external override handler {
    end[guy] = end_;
  }

  function set_fee(uint256 fee_) external override auth {
    fee = fee_;
  }

  function stop(address ctr) external override auth {
    active[ctr] = false;
  }

  function start(address ctr) external override auth {
    active[ctr] = true;
  }
}


// File contracts/deployer.sol

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity =0.6.6;
contract Deployer is Env {
  event SptDeployed(
    address indexed ctr,
    address[] indexed path,
    address indexed factory
  );

  constructor(
    uint8[] memory months_,
    uint256 fee_,
    uint256 max_
  ) public Env(months_, fee_, max_) {}

  function deploy(
    address wad,
    address[] calldata path,
    address factory,
    uint256 window,
    uint8 gran
  ) external auth returns (address ctr) {
    require(path[path.length - 1] == wad, "Deployer/incorrect-path");
    require(spt[wad][factory] == address(0), "Deployer/active");
    bytes memory bytecode = type(SPT).creationCode;
    bytes32 salt = keccak256(abi.encodePacked(path[0], wad, factory));
    assembly {
      ctr := create2(0, add(bytecode, 32), mload(bytecode), salt)
    }
    ISPT(ctr).init(wad, path, factory, window, gran);
    spt[wad][factory] = ctr;
    active[ctr] = true;
    emit SptDeployed(ctr, path, factory);
    return ctr;
  }
}