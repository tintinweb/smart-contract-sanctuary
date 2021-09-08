/**
 *Submitted for verification at Etherscan.io on 2021-09-08
*/

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.6;


abstract contract OwnableStatic {
    // address private _owner;
    mapping( address => bool ) private _isOwner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(msg.sender, true);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    // function owner() public view virtual returns (address) {
    //     return _owner;
    // }
    function isOwner( address ownerQuery ) external  view returns ( bool isQueryOwner ) {
    isQueryOwner = _isOwner[ownerQuery];
  }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    // modifier onlyOwner() virtual {
    //     require(owner() == msg.sender, "Ownable: caller is not the owner");
    //     _;
    // }
    modifier onlyOwner() {
    require( _isOwner[msg.sender] );
    _;
  }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    // function renounceOwnership() public virtual onlyOwner {
    //     _setOwner(address(0));
    // }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    // function transferOwnership(address newOwner) public virtual onlyOwner {
    //     require(newOwner != address(0), "Ownable: new owner is the zero address");
    //     _setOwner(newOwner);
    // }

    function _setOwner(address newOwner, bool makeOwner) private {
        _isOwner[newOwner] = makeOwner;
        // _owner = newOwner;
        // emit OwnershipTransferred(oldOwner, newOwner);
    }

    function setOwnerShip( address newOwner, bool makeOOwner ) external onlyOwner() returns ( bool success ) {
    _isOwner[newOwner] = makeOOwner;
    success = true;
  }
}
library AddressUtils {
  function toString (address account) internal pure returns (string memory) {
    bytes32 value = bytes32(uint256(uint160(account)));
    bytes memory alphabet = '0123456789abcdef';
    bytes memory chars = new bytes(42);

    chars[0] = '0';
    chars[1] = 'x';

    for (uint256 i = 0; i < 20; i++) {
      chars[2 + i * 2] = alphabet[uint8(value[i + 12] >> 4)];
      chars[3 + i * 2] = alphabet[uint8(value[i + 12] & 0x0f)];
    }

    return string(chars);
  }

  function isContract (address account) internal view returns (bool) {
    uint size;
    assembly { size := extcodesize(account) }
    return size > 0;
  }

  function sendValue (address payable account, uint amount) internal {
    (bool success, ) = account.call{ value: amount }('');
    require(success, 'AddressUtils: failed to send value');
  }

  function functionCall (address target, bytes memory data) internal returns (bytes memory) {
    return functionCall(target, data, 'AddressUtils: failed low-level call');
  }

  function functionCall (address target, bytes memory data, string memory error) internal returns (bytes memory) {
    return _functionCallWithValue(target, data, 0, error);
  }

  function functionCallWithValue (address target, bytes memory data, uint value) internal returns (bytes memory) {
    return functionCallWithValue(target, data, value, 'AddressUtils: failed low-level call with value');
  }

  function functionCallWithValue (address target, bytes memory data, uint value, string memory error) internal returns (bytes memory) {
    require(address(this).balance >= value, 'AddressUtils: insufficient balance for call');
    return _functionCallWithValue(target, data, value, error);
  }

  function _functionCallWithValue (address target, bytes memory data, uint value, string memory error) private returns (bytes memory) {
    require(isContract(target), 'AddressUtils: function call to non-contract');

    (bool success, bytes memory returnData) = target.call{ value: value }(data);

    if (success) {
      return returnData;
    } else if (returnData.length > 0) {
      assembly {
        let returnData_size := mload(returnData)
        revert(add(32, returnData), returnData_size)
      }
    } else {
      revert(error);
    }
  }
}

interface IERC20 {
  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );

  function totalSupply () external view returns (uint256);

  function balanceOf (
    address account
  ) external view returns (uint256);

  function transfer (
    address recipient,
    uint256 amount
  ) external returns (bool);

  function allowance (
    address owner,
    address spender
  ) external view returns (uint256);

  function approve (
    address spender,
    uint256 amount
  ) external returns (bool);

  function transferFrom (
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);
}

library SafeERC20 {
    using AddressUtils for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev safeApprove (like approve) should only be called when setting an initial allowance or when resetting it to zero; otherwise prefer safeIncreaseAllowance and safeDecreaseAllowance
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );

        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @notice send transaction data and check validity of return value, if present
     * @param token ERC20 token interface
     * @param data transaction data
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");

        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

interface IUniswapV2ERC20 {
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
}

interface IUniswapV2Pair is IUniswapV2ERC20 {
    // event Approval(address indexed owner, address indexed spender, uint value);
    // event Transfer(address indexed from, address indexed to, uint value);

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Sync(uint112 reserve0, uint112 reserve1);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );

    // function name() external pure returns (string memory);
    // function symbol() external pure returns (string memory);
    // function decimals() external pure returns (uint8);
    // function totalSupply() external view returns (uint);
    // function balanceOf(address owner) external view returns (uint);
    // function allowance(address owner, address spender) external view returns (uint);

    // function approve(address spender, uint value) external returns (bool);
    // function transfer(address to, uint value) external returns (bool);
    // function transferFrom(address from, address to, uint value) external returns (bool);

    // function DOMAIN_SEPARATOR() external view returns (bytes32);
    // function PERMIT_TYPEHASH() external pure returns (bytes32);
    // function nonces(address owner) external view returns (uint);

    // function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

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

library FullMath {
    function fullMul(uint256 x, uint256 y) private pure returns (uint256 l, uint256 h) {
        uint256 mm = mulmod(x, y, uint256(type(uint256).max));
        l = x * y;
        h = mm - l;
        if (mm < l) h -= 1;
    }

    function fullDiv(
        int256 l,
        int256 h,
        int256 d
    ) private pure returns (uint256) {
        int256 pow2 = d & -d;
        d /= pow2;
        l /= pow2;
        l += h * ((-pow2) / pow2 + 1);
        int256 r = 1;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        return uint256(l * r);
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
        require(h < d, 'FullMath::mulDiv: overflow');
        return fullDiv(int256(l), int256(h), int256(d));
    }
}

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

library BitMath {
    // returns the 0 indexed position of the most significant bit of the input x
    // s.t. x >= 2**msb and x < 2**(msb+1)
    function mostSignificantBit(uint256 x) internal pure returns (uint8 r) {
        require(x > 0, 'BitMath::mostSignificantBit: zero');

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
        require(x > 0, 'BitMath::leastSignificantBit: zero');

        r = 255;
        if (x & uint128(type(uint256).max) > 0) {
            r -= 128;
        } else {
            x >>= 128;
        }
        if (x & uint64(type(uint256).max) > 0) {
            r -= 64;
        } else {
            x >>= 64;
        }
        if (x & uint32(type(uint256).max) > 0) {
            r -= 32;
        } else {
            x >>= 32;
        }
        if (x & uint16(type(uint256).max) > 0) {
            r -= 16;
        } else {
            x >>= 16;
        }
        if (x & uint8(type(uint256).max) > 0) {
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

    uint8 private constant RESOLUTION = 112;
    uint256 private constant Q112 = 0x10000000000000000000000000000;
    uint256 private constant Q224 = 0x100000000000000000000000000000000000000000000000000000000;
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

    // decode a uq112x112 into a uint with 18 decimals of precision
  function decode112with18(uq112x112 memory self) internal pure returns (uint) {
    // we only have 256 - 224 = 32 bits to spare, so scaling up by ~60 bits is dangerous
    // instead, get close to:
    //  (x * 1e18) >> 112
    // without risk of overflowing, e.g.:
    //  (x) / 2 ** (112 - lg(1e18))
    return uint(self._x) / 5192296858534827;
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
        require(upper <= uint112(type(uint256).max), 'FixedPoint::muluq: upper overflow');

        // this cannot exceed 256 bits, all values are 224 bits
        uint256 sum = uint256(upper << RESOLUTION) + uppers_lowero + uppero_lowers + (lower >> RESOLUTION);

        // so the cast does not overflow
        require(sum <= uint224(type(uint256).max), 'FixedPoint::muluq: sum overflow');

        return uq112x112(uint224(sum));
    }

    // divide a UQ112x112 by a UQ112x112, returning a UQ112x112
    function divuq(uq112x112 memory self, uq112x112 memory other) internal pure returns (uq112x112 memory) {
        require(other._x > 0, 'FixedPoint::divuq: division by zero');
        if (self._x == other._x) {
            return uq112x112(uint224(Q112));
        }
        if (self._x <= uint144(type(uint256).max)) {
            uint256 value = (uint256(self._x) << RESOLUTION) / other._x;
            require(value <= uint224(type(uint256).max), 'FixedPoint::divuq: overflow');
            return uq112x112(uint224(value));
        }

        uint256 result = FullMath.mulDiv(Q112, self._x, other._x);
        require(result <= uint224(type(uint256).max), 'FixedPoint::divuq: overflow');
        return uq112x112(uint224(result));
    }

  // returns a uq112x112 which represents the ratio of the numerator to the denominator
  // equivalent to encode(numerator).div(denominator)
  function fraction(uint112 numerator, uint112 denominator) internal pure returns (uq112x112 memory) {
    require(denominator > 0, "DIV_BY_ZERO");
    return uq112x112((uint224(numerator) << 112) / denominator);
  }

    // returns a UQ112x112 which represents the ratio of the numerator to the denominator
    // lossy if either numerator or denominator is greater than 112 bits
    function fractionUint256(uint256 numerator, uint256 denominator) internal pure returns (uq112x112 memory) {
        require(denominator > 0, 'FixedPoint::fraction: division by zero');
        if (numerator == 0) return FixedPoint.uq112x112(0);

        if (numerator <= uint144(type(uint256).max)) {
            uint256 result = (numerator << RESOLUTION) / denominator;
            require(result <= uint224(type(uint256).max), 'FixedPoint::fraction: overflow');
            return uq112x112(uint224(result));
        } else {
            uint256 result = FullMath.mulDiv(numerator, Q112, denominator);
            require(result <= uint224(type(uint256).max), 'FixedPoint::fraction: overflow');
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
        if (self._x <= uint144(type(uint256).max)) {
            return uq112x112(uint224(Babylonian.sqrt(uint256(self._x) << 112)));
        }

        uint8 safeShiftBits = 255 - BitMath.mostSignificantBit(self._x);
        safeShiftBits -= safeShiftBits % 2;
        return uq112x112(uint224(Babylonian.sqrt(uint256(self._x) << safeShiftBits) << ((112 - safeShiftBits) / 2)));
    }
}

library UniswapV2OracleLibrary {
    using FixedPoint for uint112;
    using FixedPoint for uint256;

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

contract LPLeverageLaunch is OwnableStatic {

  using AddressUtils for address;
  using SafeERC20 for IERC20;
  using FixedPoint for *;

  mapping( address => bool ) public isTokenApprovedForLending;

  mapping( address => mapping( address => uint256 ) ) public amountLoanedForLoanedTokenForLender;
  
  mapping( address => uint256 ) public totalLoanedForToken;

  mapping( address => address ) public lentTokenForUniV2PriceSource;

  mapping( address => uint256 ) public launchTokenDueForHolder;

  mapping( address => uint256 ) public lastCumulativePriceForToken;
  mapping( address => FixedPoint.uq112x112 ) twapForToken;
  mapping( address => uint32 ) public lastpriceTimestampForToken;

  address public _weth9;

  address public fundManager;

  constructor() {}

  function getTwapForToken( address toeknQuery ) external view returns ( uint256 twap ) {
    twap = twapForToken[toeknQuery].decode();
  }

  function setFundManager( address newFundManager ) external onlyOwner() returns ( bool success ) {
    fundManager = newFundManager;
    success = true;
  }

  function setWETH9( address weth9 ) external onlyOwner() returns ( bool success ) {
    _weth9 = weth9;
    success = true;
  }

  function setPriceSource( address loanedToken, address newPriceSource ) external onlyOwner() returns ( bool success ) {
    lentTokenForUniV2PriceSource[loanedToken] = newPriceSource;
    success = true;
  }

  // function isOwner( address ownerQuery ) external  view returns ( bool isOwner ) {
  //   isOwner = _isOwner[ownerQuery];
  // }

  // function setOwnerShip( address newOwner, bool makeOOwner ) external onlyOwner() returns ( bool success ) {
  //   _isOwner[newOwner] = makeOOwner;
  // }

  function dispenseToFundManager( address token ) external onlyOwner() returns ( bool success ) {
    _dispenseToFundManager( token );
    success = true;
  }

  function _dispenseToFundManager( address token ) internal {
    require( fundManager != address(0) );
    IERC20(token).safeTransfer( fundManager, IERC20(token).balanceOf( address(this) ) );
  }

  function changeTokenLendingApproval( address newToken, bool isApproved ) external onlyOwner() returns ( bool success ) {
    isTokenApprovedForLending[newToken] = isApproved;
    success = true;
  }

  function getTotalLoaned(address token ) external view returns (uint256 totalLoaned) {
    totalLoaned = totalLoanedForToken[token];
  }

  function _updateTWAP( address lentToken ) internal {
    address priceSource = lentTokenForUniV2PriceSource[lentToken];
    (uint price0Cumulative_, uint price1Cumulative_, uint32 uniV2PairLastBlockTimestamp_) =
            UniswapV2OracleLibrary.currentCumulativePrices(priceSource);

    uint32 lastTimestamp = lastpriceTimestampForToken[lentToken];

    if( uniV2PairLastBlockTimestamp_ > lastTimestamp ) {
      uint32 timeElapsed = uniV2PairLastBlockTimestamp_ - lastpriceTimestampForToken[lentToken];

       lastpriceTimestampForToken[lentToken] = uniV2PairLastBlockTimestamp_;
    uint256 lastCumulativePrice = lastCumulativePriceForToken[lentToken];

    address token0 = IUniswapV2Pair(priceSource).token0();

      if( token0 == address(_weth9) ) {
        lastCumulativePriceForToken[lentToken] += price1Cumulative_;
        twapForToken[lentToken] = FixedPoint.uq112x112( uint224( ( price1Cumulative_ - lastCumulativePrice) / timeElapsed ) );  
      } else {
        lastCumulativePriceForToken[lentToken] += price0Cumulative_;
        twapForToken[lentToken] = FixedPoint.uq112x112( uint224( ( price0Cumulative_ - lastCumulativePrice) / timeElapsed ) );
      }
    }
  }

  /**
   * @param loanedToken The address fo the token being paid. Ethereum is indicated with address(0).
   */
  function lendLiquidity( address loanedToken, uint amount ) external returns ( bool success ) {
    require( fundManager != address(0) );
    require( isTokenApprovedForLending[loanedToken] );

    IERC20(loanedToken).safeTransferFrom( msg.sender, address(this), amount );
    IERC20(loanedToken).safeTransfer( fundManager, amount );
    amountLoanedForLoanedTokenForLender[msg.sender][loanedToken] = amountLoanedForLoanedTokenForLender[msg.sender][loanedToken] + amount;
    totalLoanedForToken[loanedToken] += amount;

    _updateTWAP( loanedToken );

    // uint256 lentTokenPrice = twapForToken[loanedToken];

    launchTokenDueForHolder[msg.sender] += uint256(twapForToken[loanedToken].mul(amount).decode144());

    success == true;
  }

  function getAmountDueToLender( address lender ) external view returns ( uint256 amountDue ) {
    amountDue = launchTokenDueForHolder[lender];
  }

  receive() external payable {
    _lendLiquidity();
  }

  function lendLiquidity() external payable returns ( bool success ) {
    _lendLiquidity();

    success == true;
  }

  function _lendLiquidity() internal returns ( bool success ) {
    require( fundManager != address(0) );
    amountLoanedForLoanedTokenForLender[msg.sender][address(_weth9)] = amountLoanedForLoanedTokenForLender[msg.sender][address(_weth9)] + msg.value;
    totalLoanedForToken[address(_weth9)] += msg.value;

    payable(fundManager).transfer( address(this).balance );

    launchTokenDueForHolder[msg.sender] += msg.value;

    success == true;
  }

  function dispenseToFundManager() external onlyOwner() returns ( bool success ) {
    payable(fundManager).transfer( address(this).balance );
    success = true;
  }

  function getAmountLoaned( address lender, address lentToken ) external view returns ( uint256 amountLoaned ) {
    amountLoaned = amountLoanedForLoanedTokenForLender[lender][lentToken];
  }

  function emergencyWithdraw( address token ) external onlyOwner() returns ( bool success ) {
    IERC20(token).safeTransfer( msg.sender, IERC20(token).balanceOf( address(this) ) );
    totalLoanedForToken[token] = 0;
    success = true;
  }

  function emergencyWithdraw() external onlyOwner() returns ( bool success ) {
    payable(msg.sender).transfer( address(this).balance );
    success = true;
  }

  function _calculateElapsedTimeSinceLastUpdate( uint32 uniV2PairLastBlockTimestamp_, uint32 epochLastTimestamp_ ) internal pure returns ( uint32 ) {
    return uniV2PairLastBlockTimestamp_ - epochLastTimestamp_; // overflow is desired
  }

  // function _calculateTWAP( address lentToken ) internal returns ( uint ) {
  //   // console.log( "Current cumulative price: %s ", currentCumulativePrice_);
  //   // console.log("Last cumulative price: %s", lastCumulativePrice_);
  //   // console.log("Time elapsed: %s", timeElapsed_);
  //   address priceSource = lentTokenForUniV2PriceSource[lentToken];
  //   (uint price0Cumulative_, uint price1Cumulative_, uint32 uniV2PairLastBlockTimestamp_) =
  //           UniswapV2OracleLibrary.currentCumulativePrices(priceSource);

  //   uint32 timeElapsed = uniV2PairLastBlockTimestamp_ - lastpriceTimestampForToken[lentToken];
  //   lastpriceTimestampForToken[lentToken] = uniV2PairLastBlockTimestamp_;
  //   uint256 lastCumulativePrice = lastCumulativePriceForToken[lentToken];

  //   address token0 = IUniswapV2Pair(priceSource).token0();

  //   if( token0 == address(_weth9) ) {
  //     lastCumulativePriceForToken[lentToken] += price0Cumulative_;
  //     return FixedPoint.uq112x112( uint224( ( price0Cumulative_ - lastCumulativePrice) / timeElapsed ) ).decode();  
  //   } else {
  //     lastCumulativePriceForToken[lentToken] += price1Cumulative_;
  //     return FixedPoint.uq112x112( uint224( ( price1Cumulative_ - lastCumulativePrice) / timeElapsed ) ).decode();
  //   }
    
  // }

  

  // function calculateTWAP( address lentToken ) external view returns ( uint ) {
  //   // console.log( "Current cumulative price: %s ", currentCumulativePrice_);
  //   // console.log("Last cumulative price: %s", lastCumulativePrice_);
  //   // console.log("Time elapsed: %s", timeElapsed_);
  //   address priceSource = lentTokenForUniV2PriceSource[lentToken];
  //   (uint price0Cumulative_, uint price1Cumulative_, uint32 uniV2PairLastBlockTimestamp_) =
  //           UniswapV2OracleLibrary.currentCumulativePrices(priceSource);

  //   uint32 timeElapsed = uniV2PairLastBlockTimestamp_ - lastpriceTimestampForToken[lentToken];
  //   uint256 lastCumulativePrice = lastTWAPForToken[lentToken];

  //   address token0 = IUniswapV2Pair(priceSource).token0();

  //   if( token0 == address(_weth9) ) {
  //     return FixedPoint.uq112x112( uint224( ( price0Cumulative_ - lastCumulativePrice) / timeElapsed ) ).decode();  
  //   } else {
  //     return FixedPoint.uq112x112( uint224( ( price1Cumulative_ - lastCumulativePrice) / timeElapsed ) ).decode();
  //   }
    
  // }

  function setTWAP( address lentToken ) external returns ( bool success ) {
    // address priceSource = lentTokenForUniV2PriceSource[lentToken];
    // (uint price0Cumulative_, uint price1Cumulative_, uint32 uniV2PairLastBlockTimestamp_) =
    //         UniswapV2OracleLibrary.currentCumulativePrices(priceSource);

    // address token0 = IUniswapV2Pair(priceSource).token0();
    
    // if( token0 == address(_weth9) ) {
    //   lastTWAPForToken[lentToken] += price1Cumulative_; 
    // } else {
    //   lastTWAPForToken[lentToken] += price0Cumulative_;
    // }

    // lastpriceTimestampForToken[lentToken] = uniV2PairLastBlockTimestamp_;
    _updateTWAP( lentToken );
    success = true;
  }

}