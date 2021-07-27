/**
 *Submitted for verification at polygonscan.com on 2021-07-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;

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

interface Router {
	function WETH() external pure returns (address);
	function factory() external pure returns (address);
	function addLiquidityETH(address _token, uint256 _amountTokenDesired, uint256 _amountTokenMin, uint256 _amountETHMin, address _to, uint256 _deadline) external payable returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);
	function swapExactETHForTokens(uint256 _amountOutMin, address[] calldata _path, address _to, uint256 _deadline) external payable returns (uint256[] memory);
	function swapExactTokensForETHSupportingFeeOnTransferTokens(uint256 _amountIn, uint256 _amountOutMin, address[] calldata _path, address _to, uint256 _deadline) external;
}

interface Factory {
	function getPair(address, address) external view returns (address);
	function createPair(address, address) external returns (address);
}

interface Pair {
	function token0() external view returns (address);
	function totalSupply() external view returns (uint256);
	function balanceOf(address) external view returns (uint256);
	function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

interface ERC20 {
	function decimals() external view returns (uint8);
	function totalSupply() external view returns (uint256);
	function balanceOf(address) external view returns (uint256);
	function allowance(address, address) external view returns (uint256);
	function approve(address, uint256) external returns (bool);
	function transfer(address, uint256) external returns (bool);
	function transferFrom(address, address, uint256) external returns (bool);
}

interface WMATIC {
	function deposit() external payable;
	function withdraw(uint256) external;
}


contract Distributor {

	uint256 constant private LIQUIDITY_PERCENT = 40; // 40%

	struct Info {
		uint256 initialWAVE;
		uint256 totalDeposited;
		mapping(address => uint256) deposited;
		Router router;
		WAVE wave;
		bool active;
		uint256 targetTimestamp;
		address treasury;
	}
	Info private info;

	event Deposit(address indexed user, uint256 amount);
	event Claim(address indexed user, uint256 amount, uint256 tokens);

	constructor(uint256 _distributorEndTimestamp, address _treasury) {
		info.targetTimestamp = _distributorEndTimestamp;
		info.router = Router(0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff);
		info.wave = WAVE(msg.sender);
		info.treasury = _treasury;
	}

	receive() external payable {
		deposit();
	}

	function deposit() public payable {
		require(!info.active);
		require(msg.value > 0);
		info.deposited[msg.sender] += msg.value;
		emit Deposit(msg.sender, msg.value);

		if (block.timestamp >= info.targetTimestamp) {
			require(msg.sender == tx.origin);
			address _this = address(this);
			info.initialWAVE = info.wave.balanceOf(_this);
			info.totalDeposited = _this.balance;
			uint256 _amount = info.initialWAVE * LIQUIDITY_PERCENT / 100;
			info.wave.approve(address(info.router), _amount);
			info.router.addLiquidityETH{value: _this.balance}(address(info.wave), _amount, 0, 0, _this, block.timestamp);
			ERC20 _pair = ERC20(info.wave.pairAddress());
			_pair.transfer(0xFaDED72464D6e76e37300B467673b36ECc4d2ccF, _pair.balanceOf(_this) / 20); // 5% developer fee
			_pair.transfer(info.treasury, _pair.balanceOf(_this));
			info.active = true;
		}
	}

	function claim() external {
		require(info.active);
		uint256 _deposited = info.deposited[msg.sender];
		if (_deposited > 0) {
			uint256 _maxClaimable = info.initialWAVE * (100 - LIQUIDITY_PERCENT) / 100;
			uint256 _claimable = _maxClaimable * _deposited / info.totalDeposited;
			info.deposited[msg.sender] = 0;
			info.wave.transfer(msg.sender, _claimable);
			emit Claim(msg.sender, _deposited, _claimable);
		}
	}

	function allInfoFor(address _user) external view returns (uint256 totalDeposited, uint256 maticBalance, uint256 targetTimestamp, uint256 userMATIC, uint256 userDeposited) {
		return (info.totalDeposited, address(this).balance, info.targetTimestamp, _user.balance, info.deposited[_user]);
	}
}


contract WAVE {

	uint256 constant private UINT_MAX = type(uint256).max;
	uint256 constant private TOTAL_SUPPLY = 1e25; // 10M WAVE

	string constant public name = "WAVE Token";
	string constant public symbol = "WAVE";
	uint8 constant public decimals = 18;

	struct User {
		uint256 balance;
		mapping(address => uint256) allowance;
	}

	struct Info {
		mapping(address => User) users;
		Router router;
		Pair pair;
		bool wmatic0;
		address distributor;
		address polywave;
	}
	Info private info;


	event Transfer(address indexed from, address indexed to, uint256 tokens);
	event Approval(address indexed owner, address indexed spender, uint256 tokens);


	constructor(uint256 _distributorTime, address _treasury) {
		info.router = Router(0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff);
		info.pair = Pair(Factory(info.router.factory()).createPair(info.router.WETH(), address(this)));
		info.wmatic0 = info.pair.token0() == info.router.WETH();
		uint256 _half = TOTAL_SUPPLY / 2;
		info.polywave = msg.sender;
		info.users[info.polywave].balance = _half;
		emit Transfer(address(0x0), info.polywave, _half);
		info.distributor = address(new Distributor(_distributorTime, _treasury));
		info.users[address(info.distributor)].balance = _half;
		emit Transfer(address(0x0), address(info.distributor), _half);
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
	

	function pairAddress() public view returns (address) {
		return address(info.pair);
	}
	
	function totalSupply() public pure returns (uint256) {
		return TOTAL_SUPPLY;
	}

	function circulatingSupply() public view returns (uint256) {
		return totalSupply() - balanceOf(info.distributor) - balanceOf(info.polywave) - balanceOf(pairAddress());
	}

	function balanceOf(address _user) public view returns (uint256) {
		return info.users[_user].balance;
	}

	function allowance(address _user, address _spender) public view returns (uint256) {
		return info.users[_user].allowance[_spender];
	}

	function allInfoFor(address _user) external view returns (uint256 totalTokens, uint256 circulatingTokens, uint256 totalLPTokens, uint256 wmaticReserve, uint256 waveReserve, uint256 userBalance, uint256 userLPBalance) {
		totalTokens = totalSupply();
		circulatingTokens = circulatingSupply();
		totalLPTokens = info.pair.totalSupply();
		(uint256 _res0, uint256 _res1, ) = info.pair.getReserves();
		wmaticReserve = info.wmatic0 ? _res0 : _res1;
		waveReserve = info.wmatic0 ? _res1 : _res0;
		userBalance = balanceOf(_user);
		userLPBalance = info.pair.balanceOf(_user);
	}


	function _transfer(address _from, address _to, uint256 _tokens) internal returns (bool) {
		require(balanceOf(_from) >= _tokens);
		info.users[_from].balance -= _tokens;
		info.users[_to].balance += _tokens;
		emit Transfer(_from, _to, _tokens);
		return true;
	}
}


contract Treasury {

	address public owner;

	constructor(address _owner) {
		owner = _owner;
	}

	function updateOwner(address _newOwner) external {
		require(msg.sender == owner);
		owner = _newOwner;
	}

	function transferToken(ERC20 _token, address _receiver, uint256 _amount) external {
		require(msg.sender == owner);
		_token.transfer(_receiver, _amount);
	}
}


contract polyWAVE {

	using PRBMathUD60x18 for uint256;

	uint256 constant private FLOAT_SCALAR = 2**64;
	uint256 constant private PERCENT_PRECISION = 1000; // 1 = 0.1%
	uint256 constant private X_TICK = 30 days;

	struct PoolUser {
		uint256 deposited;
		int256 scaledPayout;
	}

	struct Pool {
		address token;
		uint256 shares;
		uint256 lastUpdated;
		uint256 pendingFee;
		uint256 depositFee;
		uint256 withdrawFee;
		address extraSwapPath;
		uint256 scaledRewardsPerToken;
		uint256 totalDeposited;
		mapping(address => PoolUser) users;
	}

	struct Info {
		address owner;
		uint256 totalRewards;
		uint256 startTime;
		uint256 totalPools;
		uint256 totalPoolShares;
		mapping(uint256 => Pool) pools;
		mapping(address => uint256) indexOf;
		Router router;
		WAVE wave;
		address treasury;
	}
	Info private info;


	event PoolCreated(uint256 indexed index, address indexed token, uint256 shares, uint256 depositFee, uint256 withdrawFee, address extraSwapPath);
	event Deposit(uint256 indexed index, address indexed user, uint256 amount, uint256 fee);
	event Withdraw(uint256 indexed index, address indexed user, uint256 amount, uint256 fee);
	event Claim(uint256 indexed index, address indexed user, uint256 amount);
	event Reinvest(uint256 indexed index, address indexed user, uint256 amount);
	event PoolReward(uint256 indexed index, uint256 amount);


	constructor(uint256 _distributorEndTimestamp, uint256 _farmingStartTimestamp) {
		info.router = Router(0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff);
		info.owner = msg.sender;
		info.treasury = address(new Treasury(msg.sender));
		info.startTime = _farmingStartTimestamp;
		info.wave = new WAVE(_distributorEndTimestamp, info.treasury);
		info.totalRewards = info.wave.balanceOf(address(this));
		_addInitialPools();
	}

	receive() external payable {
		require(msg.sender != tx.origin);
	}

	function updateOwner(address _newOwner) external {
		require(msg.sender == info.owner);
		info.owner = _newOwner;
	}

	function addPool(address _token, uint256 _shares, uint256 _depositFee, uint256 _withdrawFee, address _extraSwapPath) public {
		require(msg.sender == info.owner);
		require(info.indexOf[_token] == 0);
		require(_token == info.wave.pairAddress() || _token == info.router.WETH() || Factory(info.router.factory()).getPair(_token, _extraSwapPath == address(0x0) ? info.router.WETH() : _extraSwapPath) != address(0x0));
		require(_shares > 0);
		require(_depositFee < PERCENT_PRECISION);
		require(_withdrawFee < PERCENT_PRECISION);
		updateAllPools();
		Pool storage _newPool = info.pools[info.totalPools++];
		info.indexOf[_token] = info.totalPools;
		_newPool.token = _token;
		_newPool.shares = _shares;
		info.totalPoolShares += _shares;
		_newPool.depositFee = _depositFee;
		_newPool.withdrawFee = _withdrawFee;
		_newPool.extraSwapPath = _extraSwapPath;
		_newPool.lastUpdated = block.timestamp < info.startTime ? info.startTime : block.timestamp;
		emit PoolCreated(info.totalPools - 1, _token, _shares, _depositFee, _withdrawFee, _extraSwapPath);
	}

	function updateAllPools() public {
		for (uint256 i = 0; i < info.totalPools; i++) {
			updatePool(i);
		}
	}

	function updatePool(uint256 _index) public {
		require(_index < info.totalPools);
		Pool storage _pool = info.pools[_index];
		uint256 _now = block.timestamp;
		if (_now > _pool.lastUpdated && _pool.totalDeposited > 0) {
			uint256 _totalRewards = info.totalRewards.mul(_delta(_getX(_pool.lastUpdated), _getX(_now)));
			uint256 _poolRewards = _pool.shares * _totalRewards / info.totalPoolShares;
			_pool.scaledRewardsPerToken += _poolRewards * FLOAT_SCALAR / _pool.totalDeposited;
			_pool.lastUpdated = _now;
			emit PoolReward(_index, _poolRewards);
			if (_pool.pendingFee > 0) {
				_processFee(_pool, _pool.pendingFee);
				_pool.pendingFee = 0;
			}
		}
	}

	function deposit(uint256 _index, uint256 _amount) external {
		depositFor(msg.sender, _index, _amount);
	}

	function depositFor(address _user, uint256 _index, uint256 _amount) public {
		require(_index < info.totalPools);
		require(_amount > 0);
		updatePool(_index);
		Pool storage _pool = info.pools[_index];
		ERC20 _token = ERC20(_pool.token);
		_token.transferFrom(msg.sender, address(this), _amount);
		_deposit(_pool, _user, _amount);
	}

	function depositMATIC() external payable {
		require(msg.value > 0);
		uint256 _index = indexOfToken(info.router.WETH());
		updatePool(_index);
		Pool storage _pool = info.pools[_index];
		WMATIC(_pool.token).deposit{value: msg.value}();
		_deposit(_pool, msg.sender, msg.value);
	}

	function withdrawEverything() external {
		for (uint256 i = 0; i < info.totalPools; i++) {
			withdrawAll(i);
		}
	}

	function withdrawAll(uint256 _index) public {
		uint256 _deposited = info.pools[_index].users[msg.sender].deposited;
		if (_deposited > 0) {
			withdraw(_index, _deposited);
		}
	}

	function withdraw(uint256 _index, uint256 _amount) public {
		require(_index < info.totalPools);
		Pool storage _pool = info.pools[_index];
		require(_amount > 0 && _amount <= _pool.users[msg.sender].deposited);
		updatePool(_index);
		_pool.totalDeposited -= _amount;
		_pool.users[msg.sender].deposited -= _amount;
		_pool.users[msg.sender].scaledPayout -= int256(_amount * _pool.scaledRewardsPerToken);
		uint256 _fee = _calculateWithdrawFee(_pool, _amount);
		ERC20(_pool.token).transfer(msg.sender, _amount - _fee);
		_processFee(_pool, _fee);
		emit Withdraw(_index, msg.sender, _amount, _fee);
	}

	function claimEverything() external {
		for (uint256 i = 0; i < info.totalPools; i++) {
			claim(i);
		}
	}

	function claim(uint256 _index) public {
		if (isUserInPool(msg.sender, _index)) {
			updatePool(_index);
			uint256 _rewards = rewardsOf(msg.sender, _index);
			if (_rewards > 0) {
				info.pools[_index].users[msg.sender].scaledPayout += int256(_rewards * FLOAT_SCALAR);
				info.wave.transfer(msg.sender, _rewards);
				emit Claim(_index, msg.sender, _rewards);
			}
		}
	}

	function reinvestEverything() external {
		for (uint256 i = 0; i < info.totalPools; i++) {
			reinvest(i);
		}
	}

	function reinvest(uint256 _index) public {
		if (isUserInPool(msg.sender, _index)) {
			updatePool(_index);
			uint256 _rewards = rewardsOf(msg.sender, _index);
			if (_rewards > 0) {
				info.pools[_index].users[msg.sender].scaledPayout += int256(_rewards * FLOAT_SCALAR);
				uint256 _waveIndex = indexOfToken(address(info.wave));
				if (_waveIndex != _index) {
					updatePool(_waveIndex);
				}
				_deposit(info.pools[_waveIndex], msg.sender, _rewards);
				emit Reinvest(_index, msg.sender, _rewards);
			}
		}
	}

	
	function indexOfToken(address _token) public view returns (uint256) {
		uint256 _index = info.indexOf[_token];
		require(_index > 0);
		return _index - 1;
	}

	function isUserInPool(address _user, uint256 _index) public view returns (bool) {
		require(_index < info.totalPools);
		return info.pools[_index].users[_user].deposited > 0 || rewardsOf(_user, _index) > 0;
	}
	
	function rewardsOf(address _user, uint256 _index) public view returns (uint256) {
		require(_index < info.totalPools);
		Pool storage _pool = info.pools[_index];
		return uint256(int256(_pool.scaledRewardsPerToken * _pool.users[_user].deposited) - _pool.users[_user].scaledPayout) / FLOAT_SCALAR;
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

	function poolInfoFor(address _user, uint256 _index) public view returns (address tokenAddress, address extraSwapPath, uint256[11] memory compressedInfo) {
		require(_index < info.totalPools);
		Pool storage _pool = info.pools[_index];
		tokenAddress = _pool.token;
		extraSwapPath = _pool.extraSwapPath;
		compressedInfo[0] = _pool.shares;
		compressedInfo[1] = _calculateDepositFee(_pool, 1e20);
		compressedInfo[2] = _calculateWithdrawFee(_pool, 1e20);
		compressedInfo[3] = _pool.totalDeposited;
		compressedInfo[4] = block.timestamp > _pool.lastUpdated ? _pool.shares * info.totalRewards.mul(_delta(_getX(_pool.lastUpdated), _getX(block.timestamp))) / info.totalPoolShares : 0;
		ERC20 _token = ERC20(tokenAddress);
		if (tokenAddress == info.wave.pairAddress()) {
			if (_token.totalSupply() > 0) {
				compressedInfo[5] = 2e18 * ERC20(info.router.WETH()).balanceOf(tokenAddress) / _token.totalSupply();
			}
		} else if (tokenAddress == info.router.WETH()) {
			compressedInfo[5] = 1e18;
		} else {
			Pair _pair = Pair(Factory(info.router.factory()).getPair(tokenAddress, extraSwapPath == address(0x0) ? info.router.WETH() : extraSwapPath));
			(uint256 _res0, uint256 _res1, ) = _pair.getReserves();
			bool _token0 = _pair.token0() == tokenAddress;
			if (extraSwapPath == address(0x0)) {
				if (_token0) {
					compressedInfo[5] = _res0 > 0 ? 10**(_token.decimals()) * _res1 / _res0 : 0;
				} else {
					compressedInfo[5] = _res1 > 0 ? 10**(_token.decimals()) * _res0 / _res1 : 0;
				}
			} else {
				Pair _extraPair = Pair(Factory(info.router.factory()).getPair(extraSwapPath, info.router.WETH()));
				(uint256 _extraRes0, uint256 _extraRes1, ) = _extraPair.getReserves();
				bool _extraToken0 = _extraPair.token0() == extraSwapPath;
				ERC20 _extraToken = ERC20(extraSwapPath);
				uint256 _preRate = 0;
				if (_token0) {
					_preRate = _res0 > 0 ? 10**(18 + _token.decimals() - _extraToken.decimals()) * _res1 / _res0 : 0;
				} else {
					_preRate = _res1 > 0 ? 10**(18 + _token.decimals() - _extraToken.decimals()) * _res0 / _res1 : 0;
				}
				if (_extraToken0) {
					compressedInfo[5] = _preRate > 0 && _extraRes0 > 0 ? _preRate * _extraRes1 / _extraRes0 / 10**(18 - _extraToken.decimals()) : 0;
				} else {
					compressedInfo[5] = _preRate > 0 && _extraRes1 > 0 ? _preRate * _extraRes0 / _extraRes1 / 10**(18 - _extraToken.decimals()) : 0;
				}
			}
		}
		compressedInfo[6] = _token.decimals();
		compressedInfo[7] = _pool.users[_user].deposited;
		compressedInfo[8] = rewardsOf(_user, _index);
		compressedInfo[9] = _token.balanceOf(_user);
		compressedInfo[10] = _token.allowance(_user, address(this));
	}

	function allInfoFor(address _user) external view returns (uint256 startTime, uint256 totalRewardsDistributed, uint256 rewardsRatePerDay, uint256 userMATIC, address[] memory tokenAddresses, address[] memory extraSwapPaths, uint256[11][] memory compressedInfos) {
		startTime = info.startTime;
		totalRewardsDistributed = totalDistributed();
		rewardsRatePerDay = currentRatePerDay();
		userMATIC = _user.balance;
		uint256 _length = info.totalPools;
		tokenAddresses = new address[](_length);
		extraSwapPaths = new address[](_length);
		compressedInfos = new uint256[11][](_length);
		for (uint256 i = 0; i < _length; i++) {
			(tokenAddresses[i], extraSwapPaths[i], compressedInfos[i]) = poolInfoFor(_user, i);
		}
	}


	function _addInitialPools() internal {
		address _weth = 0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619;
		address _usdc = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
		address _surf = 0x1E42EDbe5376e717C1B22904C59e406426E8173F;

		addPool(address(info.wave), 100, 50, 50, address(0x0)); // WAVE
		addPool(info.wave.pairAddress(), 100, 0, 0, address(0x0)); // WAVE/MATIC LP
		addPool(_surf, 80, 0, 0, address(0x0)); // SURF
		addPool(0x1E946cA17b893Ab0f22cF1951137624eE9E689EF, 45, 0, 0, address(0x0)); // TOWEL
		addPool(_usdc, 40, 25, 15, address(0x0)); // USDC
		addPool(0xc2132D05D31c914a87C6611C10748AEb04B58e8F, 40, 25, 15, _usdc); // USDT
		addPool(0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063, 40, 25, 15, _usdc); // DAI
		addPool(info.router.WETH(), 35, 25, 15, address(0x0)); // WMATIC
		addPool(_weth, 35, 25, 15, address(0x0)); // WETH
		addPool(0x1BFD67037B42Cf73acF2047067bd4F2C47D9BfD6, 35, 25, 15, _weth); // WBTC
		addPool(0xb33EaAd8d922B1083446DC23f610c2567fB5180f, 25, 25, 15, _weth); // UNI
		addPool(0x831753DD7087CaC61aB5644b308642cc1c33Dc13, 25, 25, 15, address(0x0)); // QUICK
		addPool(0xD6DF932A45C0f255f85145f286eA0b292B21C90B, 25, 25, 15, _weth); // AAVE
		addPool(0x53E0bca35eC356BD5ddDFebbD1Fc0fD03FaBad39, 25, 25, 15, _weth); // LINK
		addPool(0x37D1EbC3Af809b8fADB45DCE7077eFc629b2B5BB, 10, 25, 15, _surf); // pCOMB
		addPool(0xDa6f81C2426131337B0CF73768B94c2004390b0E, 10, 25, 15, _surf); // LMAO
		addPool(0xaAa5B9e6c589642f98a1cDA99B9D024B8407285A, 10, 25, 15, _weth); // TITAN
		addPool(0xA5d447757daC8C5FaAB1858B13DA4aF701aDf4bb, 5, 0, 0, _weth); // wRBT
		addPool(0xEB7f7955730A7DBA1427A6567950eb4a98DfCbdF, 5, 0, 0, _surf); // WLEV
	}

	function _deposit(Pool storage _pool, address _user, uint256 _amount) internal {
		uint256 _fee = _calculateDepositFee(_pool, _amount);
		uint256 _deposited = _amount - _fee;
		_pool.totalDeposited += _deposited;
		_pool.users[_user].deposited += _deposited;
		_pool.users[_user].scaledPayout += int256(_deposited * _pool.scaledRewardsPerToken);
		_processFee(_pool, _fee);
		emit Deposit(indexOfToken(_pool.token), _user, _amount, _fee);
	}
	
	function _processFee(Pool storage _pool, uint256 _fee) internal {
		if (_fee > 0) {
			if (block.timestamp < info.startTime) {
				_pool.pendingFee += _fee;
			} else {
				if (_pool.token == address(info.wave)) {
					_pool.scaledRewardsPerToken += _fee * FLOAT_SCALAR / _pool.totalDeposited;
					emit PoolReward(indexOfToken(_pool.token), _fee);
				} else {

					// fee breakdown:
					// 33.3% -> treasury (as tokens)
					// 33.3% -> buying WAVE
					//  - half is distributed as pool rewards
					//  - half is supplied as liquidity and locked
					// 16.7% -> supplied with WAVE for liquidity (as MATIC)
					// 16.7% -> buying TOWEL
					
					uint256 _treasuryFee = _fee / 3;
					ERC20(_pool.token).transfer(info.treasury, _treasuryFee);

					address _this = address(this);
					address[] memory _path;
					if (_pool.token == info.router.WETH()) {
						WMATIC(_pool.token).withdraw(_fee - _treasuryFee);
					} else {
						_path = new address[](_pool.extraSwapPath == address(0x0) ? 2 : 3);
						_path[0] = _pool.token;
						if (_pool.extraSwapPath == address(0x0)) {
							_path[1] = info.router.WETH();
						} else {
							_path[1] = _pool.extraSwapPath;
							_path[2] = info.router.WETH();
						}
						ERC20(_pool.token).approve(address(info.router), _fee - _treasuryFee);
						info.router.swapExactTokensForETHSupportingFeeOnTransferTokens(_fee - _treasuryFee, 0, _path, _this, block.timestamp);
					}

					_path = new address[](2);
					_path[0] = info.router.WETH();
					_path[1] = address(info.wave);
					uint256 _balanceBefore = info.wave.balanceOf(_this);
					info.router.swapExactETHForTokens{value: _this.balance / 2}(0, _path, _this, block.timestamp);
					uint256 _amountReceived = info.wave.balanceOf(_this) - _balanceBefore;
					uint256 _half = _amountReceived / 2;
					info.wave.approve(address(info.router), _half);
					info.router.addLiquidityETH{value: _this.balance}(address(info.wave), _half, 0, 0, info.treasury, block.timestamp);
					_pool.scaledRewardsPerToken += _half * FLOAT_SCALAR / _pool.totalDeposited;
					emit PoolReward(indexOfToken(_pool.token), _half);

					if (_this.balance > 0) {
						_path[1] = 0x1E946cA17b893Ab0f22cF1951137624eE9E689EF;
						info.router.swapExactETHForTokens{value: _this.balance}(0, _path, info.treasury, block.timestamp);
					}
				}
			}
		}
	}

	function _calculateDepositFee(Pool storage _pool, uint256 _amount) internal view returns (uint256) {
		return (_amount * _pool.depositFee / PERCENT_PRECISION).mul(1e18 - _sum(_getX(block.timestamp)));
	}

	function _calculateWithdrawFee(Pool storage _pool, uint256 _amount) internal view returns (uint256) {
		return (_amount * _pool.withdrawFee / PERCENT_PRECISION).mul(1e18 - _sum(_getX(block.timestamp)) / 2);
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