/**
 *Submitted for verification at Etherscan.io on 2021-07-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

/// @dev Common mathematical functions used in both PRBMathSD59x18 and PRBMathUD60x18. Note that this shared library
/// does not always assume the signed 59.18-decimal fixed-point or the unsigned 60.18-decimal fixed-point
// representation. When it does not, it is annonated in the function's NatSpec documentation.
library PRBMathCommon {
	/// @dev How many trailing decimals can be represented.
	uint256 internal constant SCALE = 1e18;

	/// @dev Largest power of two divisor of SCALE.
	uint256 internal constant SCALE_LPOTD = 262144;

	/// @dev SCALE inverted mod 2^256.
	uint256 internal constant SCALE_INVERSE = 78156646155174841979727994598816262306175212592076161876661508869554232690281;

	/// @notice Calculates the binary exponent of x using the binary fraction method.
	/// @dev Uses 128.128-bit fixed-point numbers - it is the most efficient way.
	/// @param x The exponent as an unsigned 128.128-bit fixed-point number.
	/// @return result The result as an unsigned 60x18 decimal fixed-point number.
	function exp2(uint256 x) internal pure returns (uint256 result) {
		unchecked {
			// Start from 0.5 in the 128.128-bit fixed-point format. We need to use uint256 because the intermediary
			// may get very close to 2^256, which doesn't fit in int256.
			result = 0x80000000000000000000000000000000;

			// Multiply the result by root(2, 2^-i) when the bit at position i is 1. None of the intermediary results overflows
			// because the initial result is 2^127 and all magic factors are less than 2^129.
			if (x & 0x80000000000000000000000000000000 > 0) result = (result * 0x16A09E667F3BCC908B2FB1366EA957D3E) >> 128;
			if (x & 0x40000000000000000000000000000000 > 0) result = (result * 0x1306FE0A31B7152DE8D5A46305C85EDED) >> 128;
			if (x & 0x20000000000000000000000000000000 > 0) result = (result * 0x1172B83C7D517ADCDF7C8C50EB14A7920) >> 128;
			if (x & 0x10000000000000000000000000000000 > 0) result = (result * 0x10B5586CF9890F6298B92B71842A98364) >> 128;
			if (x & 0x8000000000000000000000000000000 > 0) result = (result * 0x1059B0D31585743AE7C548EB68CA417FE) >> 128;
			if (x & 0x4000000000000000000000000000000 > 0) result = (result * 0x102C9A3E778060EE6F7CACA4F7A29BDE9) >> 128;
			if (x & 0x2000000000000000000000000000000 > 0) result = (result * 0x10163DA9FB33356D84A66AE336DCDFA40) >> 128;
			if (x & 0x1000000000000000000000000000000 > 0) result = (result * 0x100B1AFA5ABCBED6129AB13EC11DC9544) >> 128;
			if (x & 0x800000000000000000000000000000 > 0) result = (result * 0x10058C86DA1C09EA1FF19D294CF2F679C) >> 128;
			if (x & 0x400000000000000000000000000000 > 0) result = (result * 0x1002C605E2E8CEC506D21BFC89A23A011) >> 128;
			if (x & 0x200000000000000000000000000000 > 0) result = (result * 0x100162F3904051FA128BCA9C55C31E5E0) >> 128;
			if (x & 0x100000000000000000000000000000 > 0) result = (result * 0x1000B175EFFDC76BA38E31671CA939726) >> 128;
			if (x & 0x80000000000000000000000000000 > 0) result = (result * 0x100058BA01FB9F96D6CACD4B180917C3E) >> 128;
			if (x & 0x40000000000000000000000000000 > 0) result = (result * 0x10002C5CC37DA9491D0985C348C68E7B4) >> 128;
			if (x & 0x20000000000000000000000000000 > 0) result = (result * 0x1000162E525EE054754457D5995292027) >> 128;
			if (x & 0x10000000000000000000000000000 > 0) result = (result * 0x10000B17255775C040618BF4A4ADE83FD) >> 128;
			if (x & 0x8000000000000000000000000000 > 0) result = (result * 0x1000058B91B5BC9AE2EED81E9B7D4CFAC) >> 128;
			if (x & 0x4000000000000000000000000000 > 0) result = (result * 0x100002C5C89D5EC6CA4D7C8ACC017B7CA) >> 128;
			if (x & 0x2000000000000000000000000000 > 0) result = (result * 0x10000162E43F4F831060E02D839A9D16D) >> 128;
			if (x & 0x1000000000000000000000000000 > 0) result = (result * 0x100000B1721BCFC99D9F890EA06911763) >> 128;
			if (x & 0x800000000000000000000000000 > 0) result = (result * 0x10000058B90CF1E6D97F9CA14DBCC1629) >> 128;
			if (x & 0x400000000000000000000000000 > 0) result = (result * 0x1000002C5C863B73F016468F6BAC5CA2C) >> 128;
			if (x & 0x200000000000000000000000000 > 0) result = (result * 0x100000162E430E5A18F6119E3C02282A6) >> 128;
			if (x & 0x100000000000000000000000000 > 0) result = (result * 0x1000000B1721835514B86E6D96EFD1BFF) >> 128;
			if (x & 0x80000000000000000000000000 > 0) result = (result * 0x100000058B90C0B48C6BE5DF846C5B2F0) >> 128;
			if (x & 0x40000000000000000000000000 > 0) result = (result * 0x10000002C5C8601CC6B9E94213C72737B) >> 128;
			if (x & 0x20000000000000000000000000 > 0) result = (result * 0x1000000162E42FFF037DF38AA2B219F07) >> 128;
			if (x & 0x10000000000000000000000000 > 0) result = (result * 0x10000000B17217FBA9C739AA5819F44FA) >> 128;
			if (x & 0x8000000000000000000000000 > 0) result = (result * 0x1000000058B90BFCDEE5ACD3C1CEDC824) >> 128;
			if (x & 0x4000000000000000000000000 > 0) result = (result * 0x100000002C5C85FE31F35A6A30DA1BE51) >> 128;
			if (x & 0x2000000000000000000000000 > 0) result = (result * 0x10000000162E42FF0999CE3541B9FFFD0) >> 128;
			if (x & 0x1000000000000000000000000 > 0) result = (result * 0x100000000B17217F80F4EF5AADDA45554) >> 128;
			if (x & 0x800000000000000000000000 > 0) result = (result * 0x10000000058B90BFBF8479BD5A81B51AE) >> 128;
			if (x & 0x400000000000000000000000 > 0) result = (result * 0x1000000002C5C85FDF84BD62AE30A74CD) >> 128;
			if (x & 0x200000000000000000000000 > 0) result = (result * 0x100000000162E42FEFB2FED257559BDAA) >> 128;
			if (x & 0x100000000000000000000000 > 0) result = (result * 0x1000000000B17217F7D5A7716BBA4A9AF) >> 128;
			if (x & 0x80000000000000000000000 > 0) result = (result * 0x100000000058B90BFBE9DDBAC5E109CCF) >> 128;
			if (x & 0x40000000000000000000000 > 0) result = (result * 0x10000000002C5C85FDF4B15DE6F17EB0E) >> 128;
			if (x & 0x20000000000000000000000 > 0) result = (result * 0x1000000000162E42FEFA494F1478FDE05) >> 128;
			if (x & 0x10000000000000000000000 > 0) result = (result * 0x10000000000B17217F7D20CF927C8E94D) >> 128;
			if (x & 0x8000000000000000000000 > 0) result = (result * 0x1000000000058B90BFBE8F71CB4E4B33E) >> 128;
			if (x & 0x4000000000000000000000 > 0) result = (result * 0x100000000002C5C85FDF477B662B26946) >> 128;
			if (x & 0x2000000000000000000000 > 0) result = (result * 0x10000000000162E42FEFA3AE53369388D) >> 128;
			if (x & 0x1000000000000000000000 > 0) result = (result * 0x100000000000B17217F7D1D351A389D41) >> 128;
			if (x & 0x800000000000000000000 > 0) result = (result * 0x10000000000058B90BFBE8E8B2D3D4EDF) >> 128;
			if (x & 0x400000000000000000000 > 0) result = (result * 0x1000000000002C5C85FDF4741BEA6E77F) >> 128;
			if (x & 0x200000000000000000000 > 0) result = (result * 0x100000000000162E42FEFA39FE95583C3) >> 128;
			if (x & 0x100000000000000000000 > 0) result = (result * 0x1000000000000B17217F7D1CFB72B45E3) >> 128;
			if (x & 0x80000000000000000000 > 0) result = (result * 0x100000000000058B90BFBE8E7CC35C3F2) >> 128;
			if (x & 0x40000000000000000000 > 0) result = (result * 0x10000000000002C5C85FDF473E242EA39) >> 128;
			if (x & 0x20000000000000000000 > 0) result = (result * 0x1000000000000162E42FEFA39F02B772C) >> 128;
			if (x & 0x10000000000000000000 > 0) result = (result * 0x10000000000000B17217F7D1CF7D83C1A) >> 128;
			if (x & 0x8000000000000000000 > 0) result = (result * 0x1000000000000058B90BFBE8E7BDCBE2E) >> 128;
			if (x & 0x4000000000000000000 > 0) result = (result * 0x100000000000002C5C85FDF473DEA871F) >> 128;
			if (x & 0x2000000000000000000 > 0) result = (result * 0x10000000000000162E42FEFA39EF44D92) >> 128;
			if (x & 0x1000000000000000000 > 0) result = (result * 0x100000000000000B17217F7D1CF79E949) >> 128;
			if (x & 0x800000000000000000 > 0) result = (result * 0x10000000000000058B90BFBE8E7BCE545) >> 128;
			if (x & 0x400000000000000000 > 0) result = (result * 0x1000000000000002C5C85FDF473DE6ECA) >> 128;
			if (x & 0x200000000000000000 > 0) result = (result * 0x100000000000000162E42FEFA39EF366F) >> 128;
			if (x & 0x100000000000000000 > 0) result = (result * 0x1000000000000000B17217F7D1CF79AFA) >> 128;
			if (x & 0x80000000000000000 > 0) result = (result * 0x100000000000000058B90BFBE8E7BCD6E) >> 128;
			if (x & 0x40000000000000000 > 0) result = (result * 0x10000000000000002C5C85FDF473DE6B3) >> 128;
			if (x & 0x20000000000000000 > 0) result = (result * 0x1000000000000000162E42FEFA39EF359) >> 128;
			if (x & 0x10000000000000000 > 0) result = (result * 0x10000000000000000B17217F7D1CF79AC) >> 128;

			// Multiply the result by the integer part 2^n + 1. We have to shift by one bit extra because we have already divided
			// by two when we set the result equal to 0.5 above.
			result = result << ((x >> 128) + 1);

			// Convert the result to the signed 60.18-decimal fixed-point format.
			result = PRBMathCommon.mulDiv(result, 1e18, 2**128);
		}
	}

	/// @notice Finds the zero-based index of the first one in the binary representation of x.
	/// @dev See the note on msb in the "Find First Set" Wikipedia article https://en.wikipedia.org/wiki/Find_first_set
	/// @param x The uint256 number for which to find the index of the most significant bit.
	/// @return msb The index of the most significant bit as an uint256.
	function mostSignificantBit(uint256 x) internal pure returns (uint256 msb) {
		if (x >= 2**128) {
			x >>= 128;
			msb += 128;
		}
		if (x >= 2**64) {
			x >>= 64;
			msb += 64;
		}
		if (x >= 2**32) {
			x >>= 32;
			msb += 32;
		}
		if (x >= 2**16) {
			x >>= 16;
			msb += 16;
		}
		if (x >= 2**8) {
			x >>= 8;
			msb += 8;
		}
		if (x >= 2**4) {
			x >>= 4;
			msb += 4;
		}
		if (x >= 2**2) {
			x >>= 2;
			msb += 2;
		}
		if (x >= 2**1) {
			// No need to shift x any more.
			msb += 1;
		}
	}

	/// @notice Calculates floor(x*y÷denominator) with full precision.
	///
	/// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv.
	///
	/// Requirements:
	/// - The denominator cannot be zero.
	/// - The result must fit within uint256.
	///
	/// Caveats:
	/// - This function does not work with fixed-point numbers.
	///
	/// @param x The multiplicand as an uint256.
	/// @param y The multiplier as an uint256.
	/// @param denominator The divisor as an uint256.
	/// @return result The result as an uint256.
	function mulDiv(
		uint256 x,
		uint256 y,
		uint256 denominator
	) internal pure returns (uint256 result) {
		// 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2**256 and mod 2**256 - 1, then use
		// use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
		// variables such that product = prod1 * 2**256 + prod0.
		uint256 prod0; // Least significant 256 bits of the product
		uint256 prod1; // Most significant 256 bits of the product
		assembly {
			let mm := mulmod(x, y, not(0))
			prod0 := mul(x, y)
			prod1 := sub(sub(mm, prod0), lt(mm, prod0))
		}

		// Handle non-overflow cases, 256 by 256 division
		if (prod1 == 0) {
			require(denominator > 0);
			assembly {
				result := div(prod0, denominator)
			}
			return result;
		}

		// Make sure the result is less than 2**256. Also prevents denominator == 0.
		require(denominator > prod1);

		///////////////////////////////////////////////
		// 512 by 256 division.
		///////////////////////////////////////////////

		// Make division exact by subtracting the remainder from [prod1 prod0].
		uint256 remainder;
		assembly {
			// Compute remainder using mulmod.
			remainder := mulmod(x, y, denominator)

			// Subtract 256 bit number from 512 bit number
			prod1 := sub(prod1, gt(remainder, prod0))
			prod0 := sub(prod0, remainder)
		}

		// Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
		// See https://cs.stackexchange.com/q/138556/92363.
		unchecked {
			// Does not overflow because the denominator cannot be zero at this stage in the function.
			uint256 lpotdod = denominator & (~denominator + 1);
			assembly {
				// Divide denominator by lpotdod.
				denominator := div(denominator, lpotdod)

				// Divide [prod1 prod0] by lpotdod.
				prod0 := div(prod0, lpotdod)

				// Flip lpotdod such that it is 2**256 / lpotdod. If lpotdod is zero, then it becomes one.
				lpotdod := add(div(sub(0, lpotdod), lpotdod), 1)
			}

			// Shift in bits from prod1 into prod0.
			prod0 |= prod1 * lpotdod;

			// Invert denominator mod 2**256. Now that denominator is an odd number, it has an inverse modulo 2**256 such
			// that denominator * inv = 1 mod 2**256. Compute the inverse by starting with a seed that is correct for
			// four bits. That is, denominator * inv = 1 mod 2**4
			uint256 inverse = (3 * denominator) ^ 2;

			// Now use Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
			// in modular arithmetic, doubling the correct bits in each step.
			inverse *= 2 - denominator * inverse; // inverse mod 2**8
			inverse *= 2 - denominator * inverse; // inverse mod 2**16
			inverse *= 2 - denominator * inverse; // inverse mod 2**32
			inverse *= 2 - denominator * inverse; // inverse mod 2**64
			inverse *= 2 - denominator * inverse; // inverse mod 2**128
			inverse *= 2 - denominator * inverse; // inverse mod 2**256

			// Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
			// This will give us the correct result modulo 2**256. Since the precoditions guarantee that the outcome is
			// less than 2**256, this is the final result. We don't need to compute the high bits of the result and prod1
			// is no longer required.
			result = prod0 * inverse;
			return result;
		}
	}

	/// @notice Calculates floor(x*y÷1e18) with full precision.
	///
	/// @dev Variant of "mulDiv" with constant folding, i.e. in which the denominator is always 1e18. Before returning the
	/// final result, we add 1 if (x * y) % SCALE >= HALF_SCALE. Without this, 6.6e-19 would be truncated to 0 instead of
	/// being rounded to 1e-18.  See "Listing 6" and text above it at https://accu.org/index.php/journals/1717.
	///
	/// Requirements:
	/// - The result must fit within uint256.
	///
	/// Caveats:
	/// - The body is purposely left uncommented; see the NatSpec comments in "PRBMathCommon.mulDiv" to understand how this works.
	/// - It is assumed that the result can never be type(uint256).max when x and y solve the following two queations:
	///     1) x * y = type(uint256).max * SCALE
	///     2) (x * y) % SCALE >= SCALE / 2
	///
	/// @param x The multiplicand as an unsigned 60.18-decimal fixed-point number.
	/// @param y The multiplier as an unsigned 60.18-decimal fixed-point number.
	/// @return result The result as an unsigned 60.18-decimal fixed-point number.
	function mulDivFixedPoint(uint256 x, uint256 y) internal pure returns (uint256 result) {
		uint256 prod0;
		uint256 prod1;
		assembly {
			let mm := mulmod(x, y, not(0))
			prod0 := mul(x, y)
			prod1 := sub(sub(mm, prod0), lt(mm, prod0))
		}

		uint256 remainder;
		uint256 roundUpUnit;
		assembly {
			remainder := mulmod(x, y, SCALE)
			roundUpUnit := gt(remainder, 499999999999999999)
		}

		if (prod1 == 0) {
			unchecked {
				result = (prod0 / SCALE) + roundUpUnit;
				return result;
			}
		}

		require(SCALE > prod1);

		assembly {
			result := add(
				mul(
					or(
						div(sub(prod0, remainder), SCALE_LPOTD),
						mul(sub(prod1, gt(remainder, prod0)), add(div(sub(0, SCALE_LPOTD), SCALE_LPOTD), 1))
					),
					SCALE_INVERSE
				),
				roundUpUnit
			)
		}
	}

	/// @notice Calculates the square root of x, rounding down.
	/// @dev Uses the Babylonian method https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method.
	///
	/// Caveats:
	/// - This function does not work with fixed-point numbers.
	///
	/// @param x The uint256 number for which to calculate the square root.
	/// @return result The result as an uint256.
	function sqrt(uint256 x) internal pure returns (uint256 result) {
		if (x == 0) {
			return 0;
		}

		// Calculate the square root of the perfect square of a power of two that is the closest to x.
		uint256 xAux = uint256(x);
		result = 1;
		if (xAux >= 0x100000000000000000000000000000000) {
			xAux >>= 128;
			result <<= 64;
		}
		if (xAux >= 0x10000000000000000) {
			xAux >>= 64;
			result <<= 32;
		}
		if (xAux >= 0x100000000) {
			xAux >>= 32;
			result <<= 16;
		}
		if (xAux >= 0x10000) {
			xAux >>= 16;
			result <<= 8;
		}
		if (xAux >= 0x100) {
			xAux >>= 8;
			result <<= 4;
		}
		if (xAux >= 0x10) {
			xAux >>= 4;
			result <<= 2;
		}
		if (xAux >= 0x8) {
			result <<= 1;
		}

		// The operations can never overflow because the result is max 2^127 when it enters this block.
		unchecked {
			result = (result + x / result) >> 1;
			result = (result + x / result) >> 1;
			result = (result + x / result) >> 1;
			result = (result + x / result) >> 1;
			result = (result + x / result) >> 1;
			result = (result + x / result) >> 1;
			result = (result + x / result) >> 1; // Seven iterations should be enough
			uint256 roundedDownResult = x / result;
			return result >= roundedDownResult ? roundedDownResult : result;
		}
	}
}

/// @title PRBMathUD60x18
/// @author Paul Razvan Berg
/// @notice Smart contract library for advanced fixed-point math. It works with uint256 numbers considered to have 18
/// trailing decimals. We call this number representation unsigned 60.18-decimal fixed-point, since there can be up to 60
/// digits in the integer part and up to 18 decimals in the fractional part. The numbers are bound by the minimum and the
/// maximum values permitted by the Solidity type uint256.
library PRBMathUD60x18 {
	/// @dev Half the SCALE number.
	uint256 internal constant HALF_SCALE = 5e17;

	/// @dev log2(e) as an unsigned 60.18-decimal fixed-point number.
	uint256 internal constant LOG2_E = 1442695040888963407;

	/// @dev The maximum value an unsigned 60.18-decimal fixed-point number can have.
	uint256 internal constant MAX_UD60x18 = 115792089237316195423570985008687907853269984665640564039457584007913129639935;

	/// @dev The maximum whole value an unsigned 60.18-decimal fixed-point number can have.
	uint256 internal constant MAX_WHOLE_UD60x18 = 115792089237316195423570985008687907853269984665640564039457000000000000000000;

	/// @dev How many trailing decimals can be represented.
	uint256 internal constant SCALE = 1e18;

	/// @notice Calculates arithmetic average of x and y, rounding down.
	/// @param x The first operand as an unsigned 60.18-decimal fixed-point number.
	/// @param y The second operand as an unsigned 60.18-decimal fixed-point number.
	/// @return result The arithmetic average as an usigned 60.18-decimal fixed-point number.
	function avg(uint256 x, uint256 y) internal pure returns (uint256 result) {
		// The operations can never overflow.
		unchecked {
			// The last operand checks if both x and y are odd and if that is the case, we add 1 to the result. We need
			// to do this because if both numbers are odd, the 0.5 remainder gets truncated twice.
			result = (x >> 1) + (y >> 1) + (x & y & 1);
		}
	}

	/// @notice Yields the least unsigned 60.18 decimal fixed-point number greater than or equal to x.
	///
	/// @dev Optimised for fractional value inputs, because for every whole value there are (1e18 - 1) fractional counterparts.
	/// See https://en.wikipedia.org/wiki/Floor_and_ceiling_functions.
	///
	/// Requirements:
	/// - x must be less than or equal to MAX_WHOLE_UD60x18.
	///
	/// @param x The unsigned 60.18-decimal fixed-point number to ceil.
	/// @param result The least integer greater than or equal to x, as an unsigned 60.18-decimal fixed-point number.
	function ceil(uint256 x) internal pure returns (uint256 result) {
		require(x <= MAX_WHOLE_UD60x18);
		assembly {
			// Equivalent to "x % SCALE" but faster.
			let remainder := mod(x, SCALE)

			// Equivalent to "SCALE - remainder" but faster.
			let delta := sub(SCALE, remainder)

			// Equivalent to "x + delta * (remainder > 0 ? 1 : 0)" but faster.
			result := add(x, mul(delta, gt(remainder, 0)))
		}
	}

	/// @notice Divides two unsigned 60.18-decimal fixed-point numbers, returning a new unsigned 60.18-decimal fixed-point number.
	///
	/// @dev Uses mulDiv to enable overflow-safe multiplication and division.
	///
	/// Requirements:
	/// - y cannot be zero.
	///
	/// @param x The numerator as an unsigned 60.18-decimal fixed-point number.
	/// @param y The denominator as an unsigned 60.18-decimal fixed-point number.
	/// @param result The quotient as an unsigned 60.18-decimal fixed-point number.
	function div(uint256 x, uint256 y) internal pure returns (uint256 result) {
		result = PRBMathCommon.mulDiv(x, SCALE, y);
	}

	/// @notice Returns Euler's number as an unsigned 60.18-decimal fixed-point number.
	/// @dev See https://en.wikipedia.org/wiki/E_(mathematical_constant).
	function e() internal pure returns (uint256 result) {
		result = 2718281828459045235;
	}

	/// @notice Calculates the natural exponent of x.
	///
	/// @dev Based on the insight that e^x = 2^(x * log2(e)).
	///
	/// Requirements:
	/// - All from "log2".
	/// - x must be less than 88722839111672999628.
	///
	/// @param x The exponent as an unsigned 60.18-decimal fixed-point number.
	/// @return result The result as an unsigned 60.18-decimal fixed-point number.
	function exp(uint256 x) internal pure returns (uint256 result) {
		// Without this check, the value passed to "exp2" would be greater than 128e18.
		require(x < 88722839111672999628);

		// Do the fixed-point multiplication inline to save gas.
		unchecked {
			uint256 doubleScaleProduct = x * LOG2_E;
			result = exp2((doubleScaleProduct + HALF_SCALE) / SCALE);
		}
	}

	/// @notice Calculates the binary exponent of x using the binary fraction method.
	///
	/// @dev See https://ethereum.stackexchange.com/q/79903/24693.
	///
	/// Requirements:
	/// - x must be 128e18 or less.
	/// - The result must fit within MAX_UD60x18.
	///
	/// @param x The exponent as an unsigned 60.18-decimal fixed-point number.
	/// @return result The result as an unsigned 60.18-decimal fixed-point number.
	function exp2(uint256 x) internal pure returns (uint256 result) {
		// 2**128 doesn't fit within the 128.128-bit format used internally in this function.
		require(x < 128e18);

		unchecked {
			// Convert x to the 128.128-bit fixed-point format.
			uint256 x128x128 = (x << 128) / SCALE;

			// Pass x to the PRBMathCommon.exp2 function, which uses the 128.128-bit fixed-point number representation.
			result = PRBMathCommon.exp2(x128x128);
		}
	}

	/// @notice Yields the greatest unsigned 60.18 decimal fixed-point number less than or equal to x.
	/// @dev Optimised for fractional value inputs, because for every whole value there are (1e18 - 1) fractional counterparts.
	/// See https://en.wikipedia.org/wiki/Floor_and_ceiling_functions.
	/// @param x The unsigned 60.18-decimal fixed-point number to floor.
	/// @param result The greatest integer less than or equal to x, as an unsigned 60.18-decimal fixed-point number.
	function floor(uint256 x) internal pure returns (uint256 result) {
		assembly {
			// Equivalent to "x % SCALE" but faster.
			let remainder := mod(x, SCALE)

			// Equivalent to "x - remainder * (remainder > 0 ? 1 : 0)" but faster.
			result := sub(x, mul(remainder, gt(remainder, 0)))
		}
	}

	/// @notice Yields the excess beyond the floor of x.
	/// @dev Based on the odd function definition https://en.wikipedia.org/wiki/Fractional_part.
	/// @param x The unsigned 60.18-decimal fixed-point number to get the fractional part of.
	/// @param result The fractional part of x as an unsigned 60.18-decimal fixed-point number.
	function frac(uint256 x) internal pure returns (uint256 result) {
		assembly {
			result := mod(x, SCALE)
		}
	}

	/// @notice Calculates geometric mean of x and y, i.e. sqrt(x * y), rounding down.
	///
	/// @dev Requirements:
	/// - x * y must fit within MAX_UD60x18, lest it overflows.
	///
	/// @param x The first operand as an unsigned 60.18-decimal fixed-point number.
	/// @param y The second operand as an unsigned 60.18-decimal fixed-point number.
	/// @return result The result as an unsigned 60.18-decimal fixed-point number.
	function gm(uint256 x, uint256 y) internal pure returns (uint256 result) {
		if (x == 0) {
			return 0;
		}

		unchecked {
			// Checking for overflow this way is faster than letting Solidity do it.
			uint256 xy = x * y;
			require(xy / x == y);

			// We don't need to multiply by the SCALE here because the x*y product had already picked up a factor of SCALE
			// during multiplication. See the comments within the "sqrt" function.
			result = PRBMathCommon.sqrt(xy);
		}
	}

	/// @notice Calculates 1 / x, rounding towards zero.
	///
	/// @dev Requirements:
	/// - x cannot be zero.
	///
	/// @param x The unsigned 60.18-decimal fixed-point number for which to calculate the inverse.
	/// @return result The inverse as an unsigned 60.18-decimal fixed-point number.
	function inv(uint256 x) internal pure returns (uint256 result) {
		unchecked {
			// 1e36 is SCALE * SCALE.
			result = 1e36 / x;
		}
	}

	/// @notice Calculates the natural logarithm of x.
	///
	/// @dev Based on the insight that ln(x) = log2(x) / log2(e).
	///
	/// Requirements:
	/// - All from "log2".
	///
	/// Caveats:
	/// - All from "log2".
	/// - This doesn't return exactly 1 for 2718281828459045235, for that we would need more fine-grained precision.
	///
	/// @param x The unsigned 60.18-decimal fixed-point number for which to calculate the natural logarithm.
	/// @return result The natural logarithm as an unsigned 60.18-decimal fixed-point number.
	function ln(uint256 x) internal pure returns (uint256 result) {
		// Do the fixed-point multiplication inline to save gas. This is overflow-safe because the maximum value that log2(x)
		// can return is 196205294292027477728.
		unchecked { result = (log2(x) * SCALE) / LOG2_E; }
	}

	/// @notice Calculates the common logarithm of x.
	///
	/// @dev First checks if x is an exact power of ten and it stops if yes. If it's not, calculates the common
	/// logarithm based on the insight that log10(x) = log2(x) / log2(10).
	///
	/// Requirements:
	/// - All from "log2".
	///
	/// Caveats:
	/// - All from "log2".
	///
	/// @param x The unsigned 60.18-decimal fixed-point number for which to calculate the common logarithm.
	/// @return result The common logarithm as an unsigned 60.18-decimal fixed-point number.
	function log10(uint256 x) internal pure returns (uint256 result) {
		require(x >= SCALE);

		// Note that the "mul" in this block is the assembly mul operation, not the "mul" function defined in this contract.
		// prettier-ignore
		assembly {
			switch x
			case 1 { result := mul(SCALE, sub(0, 18)) }
			case 10 { result := mul(SCALE, sub(1, 18)) }
			case 100 { result := mul(SCALE, sub(2, 18)) }
			case 1000 { result := mul(SCALE, sub(3, 18)) }
			case 10000 { result := mul(SCALE, sub(4, 18)) }
			case 100000 { result := mul(SCALE, sub(5, 18)) }
			case 1000000 { result := mul(SCALE, sub(6, 18)) }
			case 10000000 { result := mul(SCALE, sub(7, 18)) }
			case 100000000 { result := mul(SCALE, sub(8, 18)) }
			case 1000000000 { result := mul(SCALE, sub(9, 18)) }
			case 10000000000 { result := mul(SCALE, sub(10, 18)) }
			case 100000000000 { result := mul(SCALE, sub(11, 18)) }
			case 1000000000000 { result := mul(SCALE, sub(12, 18)) }
			case 10000000000000 { result := mul(SCALE, sub(13, 18)) }
			case 100000000000000 { result := mul(SCALE, sub(14, 18)) }
			case 1000000000000000 { result := mul(SCALE, sub(15, 18)) }
			case 10000000000000000 { result := mul(SCALE, sub(16, 18)) }
			case 100000000000000000 { result := mul(SCALE, sub(17, 18)) }
			case 1000000000000000000 { result := 0 }
			case 10000000000000000000 { result := SCALE }
			case 100000000000000000000 { result := mul(SCALE, 2) }
			case 1000000000000000000000 { result := mul(SCALE, 3) }
			case 10000000000000000000000 { result := mul(SCALE, 4) }
			case 100000000000000000000000 { result := mul(SCALE, 5) }
			case 1000000000000000000000000 { result := mul(SCALE, 6) }
			case 10000000000000000000000000 { result := mul(SCALE, 7) }
			case 100000000000000000000000000 { result := mul(SCALE, 8) }
			case 1000000000000000000000000000 { result := mul(SCALE, 9) }
			case 10000000000000000000000000000 { result := mul(SCALE, 10) }
			case 100000000000000000000000000000 { result := mul(SCALE, 11) }
			case 1000000000000000000000000000000 { result := mul(SCALE, 12) }
			case 10000000000000000000000000000000 { result := mul(SCALE, 13) }
			case 100000000000000000000000000000000 { result := mul(SCALE, 14) }
			case 1000000000000000000000000000000000 { result := mul(SCALE, 15) }
			case 10000000000000000000000000000000000 { result := mul(SCALE, 16) }
			case 100000000000000000000000000000000000 { result := mul(SCALE, 17) }
			case 1000000000000000000000000000000000000 { result := mul(SCALE, 18) }
			case 10000000000000000000000000000000000000 { result := mul(SCALE, 19) }
			case 100000000000000000000000000000000000000 { result := mul(SCALE, 20) }
			case 1000000000000000000000000000000000000000 { result := mul(SCALE, 21) }
			case 10000000000000000000000000000000000000000 { result := mul(SCALE, 22) }
			case 100000000000000000000000000000000000000000 { result := mul(SCALE, 23) }
			case 1000000000000000000000000000000000000000000 { result := mul(SCALE, 24) }
			case 10000000000000000000000000000000000000000000 { result := mul(SCALE, 25) }
			case 100000000000000000000000000000000000000000000 { result := mul(SCALE, 26) }
			case 1000000000000000000000000000000000000000000000 { result := mul(SCALE, 27) }
			case 10000000000000000000000000000000000000000000000 { result := mul(SCALE, 28) }
			case 100000000000000000000000000000000000000000000000 { result := mul(SCALE, 29) }
			case 1000000000000000000000000000000000000000000000000 { result := mul(SCALE, 30) }
			case 10000000000000000000000000000000000000000000000000 { result := mul(SCALE, 31) }
			case 100000000000000000000000000000000000000000000000000 { result := mul(SCALE, 32) }
			case 1000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 33) }
			case 10000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 34) }
			case 100000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 35) }
			case 1000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 36) }
			case 10000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 37) }
			case 100000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 38) }
			case 1000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 39) }
			case 10000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 40) }
			case 100000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 41) }
			case 1000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 42) }
			case 10000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 43) }
			case 100000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 44) }
			case 1000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 45) }
			case 10000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 46) }
			case 100000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 47) }
			case 1000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 48) }
			case 10000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 49) }
			case 100000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 50) }
			case 1000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 51) }
			case 10000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 52) }
			case 100000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 53) }
			case 1000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 54) }
			case 10000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 55) }
			case 100000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 56) }
			case 1000000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 57) }
			case 10000000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 58) }
			case 100000000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 59) }
			default {
				result := MAX_UD60x18
			}
		}

		if (result == MAX_UD60x18) {
			// Do the fixed-point division inline to save gas. The denominator is log2(10).
			unchecked { result = (log2(x) * SCALE) / 332192809488736234; }
		}
	}

	/// @notice Calculates the binary logarithm of x.
	///
	/// @dev Based on the iterative approximation algorithm.
	/// https://en.wikipedia.org/wiki/Binary_logarithm#Iterative_approximation
	///
	/// Requirements:
	/// - x must be greater than or equal to SCALE, otherwise the result would be negative.
	///
	/// Caveats:
	/// - The results are nor perfectly accurate to the last digit, due to the lossy precision of the iterative approximation.
	///
	/// @param x The unsigned 60.18-decimal fixed-point number for which to calculate the binary logarithm.
	/// @return result The binary logarithm as an unsigned 60.18-decimal fixed-point number.
	function log2(uint256 x) internal pure returns (uint256 result) {
		require(x >= SCALE);
		unchecked {
			// Calculate the integer part of the logarithm and add it to the result and finally calculate y = x * 2^(-n).
			uint256 n = PRBMathCommon.mostSignificantBit(x / SCALE);

			// The integer part of the logarithm as an unsigned 60.18-decimal fixed-point number. The operation can't overflow
			// because n is maximum 255 and SCALE is 1e18.
			result = n * SCALE;

			// This is y = x * 2^(-n).
			uint256 y = x >> n;

			// If y = 1, the fractional part is zero.
			if (y == SCALE) {
				return result;
			}

			// Calculate the fractional part via the iterative approximation.
			// The "delta >>= 1" part is equivalent to "delta /= 2", but shifting bits is faster.
			for (uint256 delta = HALF_SCALE; delta > 0; delta >>= 1) {
				y = (y * y) / SCALE;

				// Is y^2 > 2 and so in the range [2,4)?
				if (y >= 2 * SCALE) {
					// Add the 2^(-m) factor to the logarithm.
					result += delta;

					// Corresponds to z/2 on Wikipedia.
					y >>= 1;
				}
			}
		}
	}

	/// @notice Multiplies two unsigned 60.18-decimal fixed-point numbers together, returning a new unsigned 60.18-decimal
	/// fixed-point number.
	/// @dev See the documentation for the "PRBMathCommon.mulDivFixedPoint" function.
	/// @param x The multiplicand as an unsigned 60.18-decimal fixed-point number.
	/// @param y The multiplier as an unsigned 60.18-decimal fixed-point number.
	/// @return result The result as an unsigned 60.18-decimal fixed-point number.
	function mul(uint256 x, uint256 y) internal pure returns (uint256 result) {
		result = PRBMathCommon.mulDivFixedPoint(x, y);
	}

	/// @notice Retrieves PI as an unsigned 60.18-decimal fixed-point number.
	function pi() internal pure returns (uint256 result) {
		result = 3141592653589793238;
	}

	/// @notice Raises x (unsigned 60.18-decimal fixed-point number) to the power of y (basic unsigned integer) using the
	/// famous algorithm "exponentiation by squaring".
	///
	/// @dev See https://en.wikipedia.org/wiki/Exponentiation_by_squaring
	///
	/// Requirements:
	/// - The result must fit within MAX_UD60x18.
	///
	/// Caveats:
	/// - All from "mul".
	/// - Assumes 0^0 is 1.
	///
	/// @param x The base as an unsigned 60.18-decimal fixed-point number.
	/// @param y The exponent as an uint256.
	/// @return result The result as an unsigned 60.18-decimal fixed-point number.
	function pow(uint256 x, uint256 y) internal pure returns (uint256 result) {
		// Calculate the first iteration of the loop in advance.
		result = y & 1 > 0 ? x : SCALE;

		// Equivalent to "for(y /= 2; y > 0; y /= 2)" but faster.
		for (y >>= 1; y > 0; y >>= 1) {
			x = mul(x, x);

			// Equivalent to "y % 2 == 1" but faster.
			if (y & 1 > 0) {
				result = mul(result, x);
			}
		}
	}

	/// @notice Returns 1 as an unsigned 60.18-decimal fixed-point number.
	function scale() internal pure returns (uint256 result) {
		result = SCALE;
	}

	/// @notice Calculates the square root of x, rounding down.
	/// @dev Uses the Babylonian method https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method.
	///
	/// Requirements:
	/// - x must be less than MAX_UD60x18 / SCALE.
	///
	/// Caveats:
	/// - The maximum fixed-point number permitted is 115792089237316195423570985008687907853269.984665640564039458.
	///
	/// @param x The unsigned 60.18-decimal fixed-point number for which to calculate the square root.
	/// @return result The result as an unsigned 60.18-decimal fixed-point .
	function sqrt(uint256 x) internal pure returns (uint256 result) {
		require(x < 115792089237316195423570985008687907853269984665640564039458);
		unchecked {
			// Multiply x by the SCALE to account for the factor of SCALE that is picked up when multiplying two unsigned
			// 60.18-decimal fixed-point numbers together (in this case, those two numbers are both the square root).
			result = PRBMathCommon.sqrt(x * SCALE);
		}
	}
}

interface Callable {
	function tokenCallback(address _from, uint256 _tokens, bytes calldata _data) external returns (bool);
}


contract LMAO {

	uint256 constant private UINT_MAX = type(uint256).max;
	uint256 constant private TOTAL_SUPPLY = 1e25; // 10M LMAO
	uint256 constant private STAKING_REWARDS = 35e23; // 3.5M LMAO

	string constant public name = "LMAO Token";
	string constant public symbol = "LMAO";
	uint8 constant public decimals = 18;

	struct User {
		uint256 balance;
		mapping(address => uint256) allowance;
	}

	struct Info {
		mapping(address => User) users;
		address staking;
	}
	Info private info;


	event Transfer(address indexed from, address indexed to, uint256 tokens);
	event Approval(address indexed owner, address indexed spender, uint256 tokens);


	constructor(address _owner) {
		uint256 _ownerTokens = TOTAL_SUPPLY - STAKING_REWARDS;
		info.users[_owner].balance = _ownerTokens;
		emit Transfer(address(0x0), _owner, _ownerTokens);
		info.staking = msg.sender;
		info.users[info.staking].balance = STAKING_REWARDS;
		emit Transfer(address(0x0), info.staking, STAKING_REWARDS);
	}

	function transfer(address _to, uint256 _tokens) external returns (bool) {
		return _transfer(msg.sender, _to, _tokens);
	}

	function approve(address _spender, uint256 _tokens) external returns (bool) {
		info.users[msg.sender].allowance[_spender] = _tokens;
		emit Approval(msg.sender, _spender, _tokens);
		return true;
	}

	function transferFrom(address _from, address _to, uint256 _tokens) external returns (bool) {
		uint256 _allowance = allowance(_from, msg.sender);
		require(_allowance >= _tokens);
		if (_allowance != UINT_MAX) {
			info.users[_from].allowance[msg.sender] -= _tokens;
		}
		return _transfer(_from, _to, _tokens);
	}

	function transferAndCall(address _to, uint256 _tokens, bytes calldata _data) external returns (bool) {
		_transfer(msg.sender, _to, _tokens);
		uint32 _size;
		assembly {
			_size := extcodesize(_to)
		}
		if (_size > 0) {
			require(Callable(_to).tokenCallback(msg.sender, _tokens, _data));
		}
		return true;
	}
	
	
	function stakingAddress() external view returns (address) {
		return info.staking;
	}
	
	function totalSupply() public pure returns (uint256) {
		return TOTAL_SUPPLY;
	}

	function balanceOf(address _user) public view returns (uint256) {
		return info.users[_user].balance;
	}

	function allowance(address _user, address _spender) public view returns (uint256) {
		return info.users[_user].allowance[_spender];
	}

	function allInfoFor(address _user) external view returns (uint256 totalTokens, uint256 userTOKENS, uint256 userBalance) {
		totalTokens = totalSupply();
		userTOKENS = _user.balance;
		userBalance = balanceOf(_user);
	}


	function _transfer(address _from, address _to, uint256 _tokens) internal returns (bool) {
		require(balanceOf(_from) >= _tokens);
		info.users[_from].balance -= _tokens;
		info.users[_to].balance += _tokens;
		emit Transfer(_from, _to, _tokens);
		return true;
	}
}


contract StakingRewards {

	using PRBMathUD60x18 for uint256;

	uint256 constant private FLOAT_SCALAR = 2**64;
	uint256 constant private PERCENT_FEE = 5;
	uint256 constant private X_TICK = 45 days;

	struct User {
		uint256 deposited;
		int256 scaledPayout;
	}

	struct Info {
		uint256 totalRewards;
		uint256 startTime;
		uint256 lastUpdated;
		uint256 pendingFee;
		uint256 scaledRewardsPerToken;
		uint256 totalDeposited;
		mapping(address => User) users;
		LMAO lmao;
	}
	Info private info;


	event Deposit(address indexed user, uint256 amount, uint256 fee);
	event Withdraw(address indexed user, uint256 amount, uint256 fee);
	event Claim(address indexed user, uint256 amount);
	event Reinvest(address indexed user, uint256 amount);
	event Reward(uint256 amount);


	constructor(uint256 _stakingRewardsStart) {
		info.startTime = block.timestamp < _stakingRewardsStart ? _stakingRewardsStart : block.timestamp;
		info.lastUpdated = info.startTime;
		info.lmao = new LMAO(msg.sender);
		info.totalRewards = info.lmao.balanceOf(address(this));
	}

	function update() public {
		uint256 _now = block.timestamp;
		if (_now > info.lastUpdated && info.totalDeposited > 0) {
			uint256 _reward = info.totalRewards.mul(_delta(_getX(info.lastUpdated), _getX(_now)));
			_disburse(_reward);
			info.lastUpdated = _now;
			if (info.pendingFee > 0) {
				_processFee(info.pendingFee);
				info.pendingFee = 0;
			}
		}
	}

	function deposit(uint256 _amount) external {
		depositFor(msg.sender, _amount);
	}

	function depositFor(address _user, uint256 _amount) public {
		require(_amount > 0);
		update();
		info.lmao.transferFrom(msg.sender, address(this), _amount);
		_deposit(_user, _amount);
	}

	function tokenCallback(address _from, uint256 _tokens, bytes calldata) external returns (bool) {
		require(msg.sender == address(info.lmao));
		require(_tokens > 0);
		_deposit(_from, _tokens);
		return true;
	}

	function disburse(uint256 _amount) public {
		require(_amount > 0);
		update();
		info.lmao.transferFrom(msg.sender, address(this), _amount);
		_disburse(_amount);
	}

	function withdrawAll() public {
		uint256 _deposited = depositedOf(msg.sender);
		if (_deposited > 0) {
			withdraw(_deposited);
		}
	}

	function withdraw(uint256 _amount) public {
		require(_amount > 0 && _amount <= depositedOf(msg.sender));
		update();
		info.totalDeposited -= _amount;
		info.users[msg.sender].deposited -= _amount;
		info.users[msg.sender].scaledPayout -= int256(_amount * info.scaledRewardsPerToken);
		uint256 _fee = _calculateFee(_amount);
		info.lmao.transfer(msg.sender, _amount - _fee);
		_processFee(_fee);
		emit Withdraw(msg.sender, _amount, _fee);
	}

	function claim() public {
		update();
		uint256 _rewards = rewardsOf(msg.sender);
		if (_rewards > 0) {
			info.users[msg.sender].scaledPayout += int256(_rewards * FLOAT_SCALAR);
			info.lmao.transfer(msg.sender, _rewards);
			emit Claim(msg.sender, _rewards);
		}
	}

	function reinvest() public {
		update();
		uint256 _rewards = rewardsOf(msg.sender);
		if (_rewards > 0) {
			info.users[msg.sender].scaledPayout += int256(_rewards * FLOAT_SCALAR);
			_deposit(msg.sender, _rewards);
			emit Reinvest(msg.sender, _rewards);
		}
	}

	
	function depositedOf(address _user) public view returns (uint256) {
		return info.users[_user].deposited;
	}
	
	function rewardsOf(address _user) public view returns (uint256) {
		return uint256(int256(info.scaledRewardsPerToken * depositedOf(_user)) - info.users[_user].scaledPayout) / FLOAT_SCALAR;
	}
	
	function currentRatePerDay() public view returns (uint256) {
		if (block.timestamp < info.startTime) {
			return 0;
		} else {
			return info.totalRewards.mul(_delta(_getX(block.timestamp), _getX(block.timestamp + 24 hours)));
		}
	}

	function totalDistributed() public view returns (uint256) {
		return info.totalRewards.mul(_sum(_getX(block.timestamp)));
	}

	function allInfoFor(address _user) external view returns (uint256 startTime, uint256 totalRewardsDistributed, uint256 rewardsRatePerDay, uint256 currentFeePercent, uint256 totalDeposited, uint256 virtualRewards, uint256 userTOKENS, uint256 userBalance, uint256 userAllowance, uint256 userDeposited, uint256 userRewards) {
		startTime = info.startTime;
		totalRewardsDistributed = totalDistributed();
		rewardsRatePerDay = currentRatePerDay();
		currentFeePercent = _calculateFee(1e20);
		totalDeposited = info.totalDeposited;
		virtualRewards = block.timestamp > info.lastUpdated ? info.totalRewards.mul(_delta(_getX(info.lastUpdated), _getX(block.timestamp))) : 0;
		userTOKENS = _user.balance;
		userBalance = info.lmao.balanceOf(_user);
		userAllowance = info.lmao.allowance(_user, address(this));
		userDeposited = depositedOf(_user);
		userRewards = rewardsOf(_user);
	}


	function _deposit(address _user, uint256 _amount) internal {
		uint256 _fee = _calculateFee(_amount);
		uint256 _deposited = _amount - _fee;
		info.totalDeposited += _deposited;
		info.users[_user].deposited += _deposited;
		info.users[_user].scaledPayout += int256(_deposited * info.scaledRewardsPerToken);
		_processFee(_fee);
		emit Deposit(_user, _amount, _fee);
	}
	
	function _processFee(uint256 _fee) internal {
		if (_fee > 0) {
			if (block.timestamp < info.startTime) {
				info.pendingFee += _fee;
			} else {
				_disburse(_fee);
			}
		}
	}

	function _disburse(uint256 _amount) internal {
		info.scaledRewardsPerToken += _amount * FLOAT_SCALAR / info.totalDeposited;
		emit Reward(_amount);
	}

	function _calculateFee(uint256 _amount) internal view returns (uint256) {
		return (_amount * PERCENT_FEE / 100).mul(1e18 - _sum(_getX(block.timestamp)));
	}
	
	function _getX(uint256 t) internal view returns (uint256) {
		uint256 _start = info.startTime;
		if (t < _start) {
			return 0;
		} else {
			return ((t - _start) * 1e18).div(X_TICK * 1e18);
		}
	}

	function _sum(uint256 x) internal pure returns (uint256) {
		uint256 _e2x = x.exp2();
		return (_e2x - 1e18).div(_e2x);
	}

	function _delta(uint256 x1, uint256 x2) internal pure returns (uint256) {
		require(x2 >= x1);
		return _sum(x2) - _sum(x1);
	}
}