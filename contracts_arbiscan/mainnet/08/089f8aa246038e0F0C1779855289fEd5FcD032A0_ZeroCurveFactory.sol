// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0;
import {ICurvePool} from '../interfaces/ICurvePool.sol';
import {IERC20} from 'oz410/token/ERC20/IERC20.sol';
import {ZeroCurveWrapper} from './ZeroCurveWrapper.sol';
import {ICurveInt128} from '../interfaces/CurvePools/ICurveInt128.sol';
import {ICurveInt256} from '../interfaces/CurvePools/ICurveInt256.sol';
import {ICurveUInt128} from '../interfaces/CurvePools/ICurveUInt128.sol';
import {ICurveUInt256} from '../interfaces/CurvePools/ICurveUInt256.sol';
import {ICurveUnderlyingInt128} from '../interfaces/CurvePools/ICurveUnderlyingInt128.sol';
import {ICurveUnderlyingInt256} from '../interfaces/CurvePools/ICurveUnderlyingInt256.sol';
import {ICurveUnderlyingUInt128} from '../interfaces/CurvePools/ICurveUnderlyingUInt128.sol';
import {ICurveUnderlyingUInt256} from '../interfaces/CurvePools/ICurveUnderlyingUInt256.sol';
import {CurveLib} from '../libraries/CurveLib.sol';


contract ZeroCurveFactory {
	event CreateWrapper(address _wrapper);

	function createWrapper(
		bool _underlying,
		uint256 _tokenInIndex,
		uint256 _tokenOutIndex,
		address _pool
	) public payable {
		emit CreateWrapper(address(new ZeroCurveWrapper(_tokenInIndex, _tokenOutIndex, _pool, _underlying)));
	}
	fallback() payable external { /* no op */ }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0;

import {IERC20} from 'oz410/token/ERC20/IERC20.sol';
import {SafeERC20} from 'oz410/token/ERC20/SafeERC20.sol';
import {ICurvePool} from '../interfaces/ICurvePool.sol';
import { CurveLib } from "../libraries/CurveLib.sol";
import {SafeMath} from 'oz410/math/SafeMath.sol';

contract ZeroCurveWrapper {
	bool public immutable underlying;
	uint256 public immutable tokenInIndex;
	uint256 public immutable tokenOutIndex;
	address public immutable tokenInAddress;
	address public immutable tokenOutAddress;
	address public immutable pool;
	bytes4 public immutable coinsUnderlyingSelector;
	bytes4 public immutable coinsSelector;
	bytes4 public immutable getDySelector;
	bytes4 public immutable exchangeSelector;

	using SafeMath for uint256;
	using SafeERC20 for IERC20;
	using CurveLib for CurveLib.ICurve;

	function getPool() internal view returns (CurveLib.ICurve memory result) {
		result = CurveLib.fromSelectors(pool, underlying, coinsSelector, coinsUnderlyingSelector, exchangeSelector, getDySelector);
	}
	constructor(
		uint256 _tokenInIndex,
		uint256 _tokenOutIndex,
		address _pool,
		bool _underlying
	) {
		underlying = _underlying;
		tokenInIndex = _tokenInIndex;
		tokenOutIndex = _tokenOutIndex;
		pool = _pool;
		CurveLib.ICurve memory curve = CurveLib.duckPool(_pool, _underlying);
		coinsUnderlyingSelector = curve.coinsUnderlyingSelector;
		coinsSelector = curve.coinsSelector;
		exchangeSelector = curve.exchangeSelector;
		getDySelector = curve.getDySelector;
		address _tokenInAddress = tokenInAddress = curve.coins(_tokenInIndex);
		address _tokenOutAddress = tokenOutAddress = curve.coins(_tokenOutIndex);
		IERC20(_tokenInAddress).safeApprove(_pool, type(uint256).max / 2);
	}

	function estimate(uint256 _amount) public returns (uint256 result) {
		result = getPool().get_dy(tokenInIndex, tokenOutIndex, _amount);
	}

	function convert(address _module) external payable returns (uint256 _actualOut) {
		uint256 _balance = IERC20(tokenInAddress).balanceOf(address(this));
		uint256 _startOut = IERC20(tokenOutAddress).balanceOf(address(this));
		getPool().exchange(tokenInIndex, tokenOutIndex, _balance, _balance / 0x10);
		_actualOut = IERC20(tokenOutAddress).balanceOf(address(this)) - _startOut;
		IERC20(tokenOutAddress).safeTransfer(msg.sender, _actualOut);
	}
	receive() external payable { /* noop */ }
	fallback() external payable { /* noop */ }
}

pragma solidity >=0.6.0;

interface ICurveETHUInt256 {
  function exchange(uint256 i, uint256 j, uint256 dx, uint256 min_dy, bool use_eth) external payable returns (uint256) ;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0;

interface ICurveInt128 {
	function get_dy(
		int128,
		int128,
		uint256
	) external view returns (uint256);

	function exchange(
		int128,
		int128,
		uint256,
		uint256
	) external returns (uint256);

	function coins(int128) external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0;

interface ICurveInt256 {
	function get_dy(
		int256,
		int256,
		uint256
	) external view returns (uint256);

	function exchange(
		int256,
		int256,
		uint256,
		uint256
	) external returns (uint256);

	function coins(int256) external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0;

interface ICurveUInt128 {
	function get_dy(
		uint128,
		uint128,
		uint256
	) external view returns (uint256);

	function exchange(
		uint128,
		uint128,
		uint256,
		uint256
	) external returns (uint256);

	function coins(uint128) external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0;

interface ICurveUInt256 {
	function get_dy(
		uint256,
		uint256,
		uint256
	) external view returns (uint256);

	function exchange(
		uint256,
		uint256,
		uint256,
		uint256
	) external returns (uint256);

	function coins(uint256) external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0;

interface ICurveUnderlyingInt128 {
	function get_dy_underlying(
		int128,
		int128,
		uint256
	) external view returns (uint256);

	function exchange_underlying(
		int128,
		int128,
		uint256,
		uint256
	) external returns (uint256);

	function underlying_coins(int128) external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0;

interface ICurveUnderlyingInt256 {
	function get_dy_underlying(
		int256,
		int256,
		uint256
	) external view returns (uint256);

	function exchange_underlying(
		int256,
		int256,
		uint256,
		uint256
	) external returns (uint256);

	function underlying_coins(int256) external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0;

interface ICurveUnderlyingUInt128 {
	function get_dy_underlying(
		uint128,
		uint128,
		uint256
	) external view returns (uint256);

	function exchange_underlying(
		uint128,
		uint128,
		uint256,
		uint256
	) external returns (uint256);

	function underlying_coins(uint128) external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0;

interface ICurveUnderlyingUInt256 {
	function get_dy_underlying(
		uint256,
		uint256,
		uint256
	) external view returns (uint256);

	function exchange_underlying(
		uint256,
		uint256,
		uint256,
		uint256
	) external returns (uint256);

	function underlying_coins(uint256) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

interface ICurvePool {
	function get_dy(
		int128,
		int128,
		uint256
	) external view returns (uint256);

	function get_dy(
		uint256,
		uint256,
		uint256
	) external view returns (uint256);

	function get_dy_underlying(
		int128,
		int128,
		uint256
	) external view returns (uint256);

	function get_dy_underlying(
		uint256,
		uint256,
		uint256
	) external view returns (uint256);

	function exchange(
		int128,
		int128,
		uint256,
		uint256
	) external;

	function exchange(
		uint256,
		uint256,
		uint256,
		uint256
	) external;

	function exchange_underlying(
		int128,
		int128,
		uint256,
		uint256
	) external;

	function exchange_underlying(
		uint256,
		uint256,
		uint256,
		uint256
	) external;

	function coins(int128) external view returns (address);

	function coins(int256) external view returns (address);

	function coins(uint128) external view returns (address);

	function coins(uint256) external view returns (address);

	function underlying_coins(int128) external view returns (address);

	function underlying_coins(uint128) external view returns (address);

	function underlying_coins(int256) external view returns (address);

	function underlying_coins(uint256) external view returns (address);
}

pragma solidity >=0.6.0;

import {ICurveInt128} from '../interfaces/CurvePools/ICurveInt128.sol';
import {ICurveUInt128} from '../interfaces/CurvePools/ICurveUInt128.sol';

import {ICurveInt256} from '../interfaces/CurvePools/ICurveInt256.sol';

import {ICurveUInt256} from '../interfaces/CurvePools/ICurveUInt256.sol';
import {ICurveETHUInt256} from '../interfaces/CurvePools/ICurveETHUInt256.sol';
import {ICurveUnderlyingUInt128} from '../interfaces/CurvePools/ICurveUnderlyingUInt128.sol';
import {ICurveUnderlyingUInt256} from '../interfaces/CurvePools/ICurveUnderlyingUInt256.sol';
import {ICurveUnderlyingInt128} from '../interfaces/CurvePools/ICurveUnderlyingInt128.sol';
import {ICurveUnderlyingInt256} from '../interfaces/CurvePools/ICurveUnderlyingInt256.sol';
import {RevertCaptureLib} from './RevertCaptureLib.sol';

library CurveLib {
	address constant weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
	struct ICurve {
		address pool;
		bool underlying;
		bytes4 coinsSelector;
		bytes4 exchangeSelector;
		bytes4 getDySelector;
		bytes4 coinsUnderlyingSelector;
	}

	function hasWETH(address pool, bytes4 coinsSelector) internal returns (bool) {
		for (uint256 i = 0; ; i++) {
			(bool success, bytes memory result) = pool.staticcall{gas: 2e5}(abi.encodePacked(coinsSelector, i));
			if (!success || result.length == 0) return false;
			address coin = abi.decode(result, (address));
			if (coin == weth) return true;
		}
	}

	function coins(ICurve memory curve, uint256 i) internal view returns (address result) {
		(bool success, bytes memory returnData) = curve.pool.staticcall(
			abi.encodeWithSelector(curve.coinsSelector, i)
		);
		require(success, '!coins');
		(result) = abi.decode(returnData, (address));
	}

	function underlying_coins(ICurve memory curve, uint256 i) internal view returns (address result) {
		(bool success, bytes memory returnData) = curve.pool.staticcall(
			abi.encodeWithSelector(curve.coinsUnderlyingSelector, i)
		);
		require(success, '!underlying_coins');
		(result) = abi.decode(returnData, (address));
	}

	function get_dy(
		ICurve memory curve,
		uint256 i,
		uint256 j,
		uint256 amount
	) internal view returns (uint256 result) {
		(bool success, bytes memory returnData) = curve.pool.staticcall(
			abi.encodeWithSelector(curve.getDySelector, i, j, amount)
		);
		require(success, '!get_dy');
		(result) = abi.decode(returnData, (uint256));
	}

	function exchange(
		ICurve memory curve,
		uint256 i,
		uint256 j,
		uint256 dx,
		uint256 min_dy
	) internal {
		(bool success, bytes memory returnData) = curve.pool.call{gas: gasleft()}(
			abi.encodeWithSelector(curve.exchangeSelector, i, j, dx, min_dy)
		);
		if (!success) revert(RevertCaptureLib.decodeError(returnData));
	}


	function toDynamic(bytes4[4] memory ary) internal pure returns (bytes4[] memory result) {
		result = new bytes4[](ary.length);
		for (uint256 i = 0; i < ary.length; i++) {
			result[i] = ary[i];
		}
	}

	function toDynamic(bytes4[5] memory ary) internal pure returns (bytes4[] memory result) {
		result = new bytes4[](ary.length);
		for (uint256 i = 0; i < ary.length; i++) {
			result[i] = ary[i];
		}
	}

	function testSignatures(
		address target,
		bytes4[] memory signatures,
		bytes memory callData
	) internal returns (bytes4 result) {
		for (uint256 i = 0; i < signatures.length; i++) {
			(, bytes memory returnData) = target.staticcall(abi.encodePacked(signatures[i], callData));
			if (returnData.length != 0) return signatures[i];
		}
		return bytes4(0x0);
	}

	function testExchangeSignatures(
		address target,
		bytes4[] memory signatures,
		bytes memory callData
	) internal returns (bytes4 result) {
		for (uint256 i = 0; i < signatures.length; i++) {
			uint256 gasStart = gasleft();
			(bool success, ) = target.call{gas: 2e5}(abi.encodePacked(signatures[i], callData));
			uint256 gasUsed = gasStart - gasleft();
			if (gasUsed > 10000) return signatures[i];
		}
		return bytes4(0x0);
	}

	function toBytes(bytes4 sel) internal pure returns (bytes memory result) {
		result = new bytes(4);
		bytes32 selWord = bytes32(sel);
		assembly {
			mstore(add(0x20, result), selWord)
		}
	}

	function duckPool(address pool, bool underlying) internal returns (ICurve memory result) {
		result.pool = pool;
		result.underlying = underlying;
		result.coinsSelector = result.underlying
			? testSignatures(
				pool,
				toDynamic(
					[
						ICurveUnderlyingInt128.underlying_coins.selector,
						ICurveUnderlyingInt256.underlying_coins.selector,
						ICurveUnderlyingUInt128.underlying_coins.selector,
						ICurveUnderlyingUInt256.underlying_coins.selector
					]
				),
				abi.encode(0)
			)
			: testSignatures(
				pool,
				toDynamic(
					[
						ICurveInt128.coins.selector,
						ICurveInt256.coins.selector,
						ICurveUInt128.coins.selector,
						ICurveUInt256.coins.selector
					]
				),
				abi.encode(0)
			);
		result.exchangeSelector = result.underlying
			? testExchangeSignatures(
				pool,
				toDynamic(
					[
						ICurveUnderlyingUInt256.exchange_underlying.selector,
						ICurveUnderlyingInt128.exchange_underlying.selector,
						ICurveUnderlyingInt256.exchange_underlying.selector,
						ICurveUnderlyingUInt128.exchange_underlying.selector
					]
				),
				abi.encode(0, 0, 1000000000, type(uint256).max / 0x10, false)
			)
			: testExchangeSignatures(
				pool,
				toDynamic(
					[
						ICurveUInt256.exchange.selector,
						ICurveInt128.exchange.selector,
						ICurveInt256.exchange.selector,
						ICurveUInt128.exchange.selector,
						ICurveETHUInt256.exchange.selector
					]
				),
				abi.encode(0, 0, 1000000000, type(uint256).max / 0x10, false)
			);
		if (result.exchangeSelector == bytes4(0x0)) result.exchangeSelector = ICurveUInt256.exchange.selector; //hasWETH(pool, result.coinsSelector) ? ICurveETHUInt256.exchange.selector : ICurveUInt256.exchange.selector;
		result.getDySelector = testSignatures(
			pool,
			toDynamic(
				[
					ICurveInt128.get_dy.selector,
					ICurveInt256.get_dy.selector,
					ICurveUInt128.get_dy.selector,
					ICurveUInt256.get_dy.selector
				]
			),
			abi.encode(0, 1, 1000000000)
		);
	}

	function fromSelectors(
		address pool,
		bool underlying,
		bytes4 coinsSelector,
		bytes4 coinsUnderlyingSelector,
		bytes4 exchangeSelector,
		bytes4 getDySelector
	) internal pure returns (ICurve memory result) {
		result.pool = pool;
		result.coinsSelector = coinsSelector;
		result.coinsUnderlyingSelector = coinsUnderlyingSelector;
		result.exchangeSelector = exchangeSelector;
		result.getDySelector = getDySelector;
	}
}

pragma experimental ABIEncoderV2;
// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

library MemcpyLib {
  function memcpy(bytes32 dest, bytes32 src, uint256 len) internal pure {
    assembly {
      for {} iszero(lt(len, 0x20)) { len := sub(len, 0x20) } {
        mstore(dest, mload(src))
        dest := add(dest, 0x20)
        src := add(src, 0x20)
      }
      let mask := sub(shl(mul(sub(32, len), 8), 1), 1)
      mstore(dest, or(and(mload(src), not(mask)), and(mload(dest), mask)))
    }
  }
}

pragma experimental ABIEncoderV2;
// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

import { SliceLib } from "./SliceLib.sol";

library RevertCaptureLib {
  using SliceLib for *;
  uint32 constant REVERT_WITH_REASON_MAGIC = 0x08c379a0; // keccak256("Error(string)")
  function decodeString(bytes memory input) internal pure returns (string memory retval) {
    (retval) = abi.decode(input, (string));
  }
  function decodeError(bytes memory buffer) internal pure returns (string memory) {
    if (buffer.length == 0) return "captured empty revert buffer";
    if (uint32(uint256(bytes32(buffer.toSlice(0, 4).asWord()))) != REVERT_WITH_REASON_MAGIC) return "captured a revert error, but it doesn't conform to the standard";
    bytes memory revertMessageEncoded = buffer.toSlice(4).copy();
    if (revertMessageEncoded.length == 0) return "captured empty revert message";
    (string memory revertMessage) = decodeString(revertMessageEncoded);
    return revertMessage;
  }
}

pragma experimental ABIEncoderV2;
// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

import { MemcpyLib } from "./MemcpyLib.sol";

library SliceLib {
  struct Slice {
    uint256 data;
    uint256 length;
    uint256 offset;
  }
  function toPtr(bytes memory input, uint256 offset) internal pure returns (uint256 data) {
    assembly {
      data := add(input, add(offset, 0x20))
    }
  }
  function toSlice(bytes memory input, uint256 offset, uint256 length) internal pure returns (Slice memory retval) {
    retval.data = toPtr(input, offset);
    retval.length = length;
    retval.offset = offset;
  }
  function toSlice(bytes memory input) internal pure returns (Slice memory) {
    return toSlice(input, 0);
  }
  function toSlice(bytes memory input, uint256 offset) internal pure returns (Slice memory) {
    if (input.length < offset) offset = input.length;
    return toSlice(input, offset, input.length - offset);
  }
  function toSlice(Slice memory input, uint256 offset, uint256 length) internal pure returns (Slice memory) {
    return Slice({
      data: input.data + offset,
      offset: input.offset + offset,
      length: length
    });
  }
  function toSlice(Slice memory input, uint256 offset) internal pure returns (Slice memory) {
    return toSlice(input, offset, input.length - offset);
  }
  function toSlice(Slice memory input) internal pure returns (Slice memory) {
    return toSlice(input, 0);
  }
  function maskLastByteOfWordAt(uint256 data) internal pure returns (uint8 lastByte) {
    assembly {
      lastByte := and(mload(data), 0xff)
    }
  }
  function get(Slice memory slice, uint256 index) internal pure returns (bytes1 result) {
    return bytes1(maskLastByteOfWordAt(slice.data - 0x1f + index));
  }
  function setByteAt(uint256 ptr, uint8 value) internal pure {
    assembly {
      mstore8(ptr, value)
    }
  }
  function set(Slice memory slice, uint256 index, uint8 value) internal pure {
    setByteAt(slice.data + index, value);
  }
  function wordAt(uint256 ptr, uint256 length) internal pure returns (bytes32 word) {
    assembly {
      let mask := sub(shl(mul(length, 0x8), 0x1), 0x1)
      word := and(mload(sub(ptr, sub(0x20, length))), mask)
    }
  }
  function asWord(Slice memory slice) internal pure returns (bytes32 word) {
    uint256 data = slice.data;
    uint256 length = slice.length;
    return wordAt(data, length);
  }
  function toDataStart(bytes memory input) internal pure returns (bytes32 start) {
    assembly {
      start := add(input, 0x20)
    }
  }
  function copy(Slice memory slice) internal pure returns (bytes memory retval) {
    uint256 length = slice.length;
    retval = new bytes(length);
    bytes32 src = bytes32(slice.data);
    bytes32 dest = toDataStart(retval);
    MemcpyLib.memcpy(dest, src, length);
  }
  function keccakAt(uint256 data, uint256 length) internal pure returns (bytes32 result) {
    assembly {
      result := keccak256(data, length)
    }
  }
  function toKeccak(Slice memory slice) internal pure returns (bytes32 result) {
    return keccakAt(slice.data, slice.length);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

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
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
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
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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
        return functionCallWithValue(target, data, 0, errorMessage);
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
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
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