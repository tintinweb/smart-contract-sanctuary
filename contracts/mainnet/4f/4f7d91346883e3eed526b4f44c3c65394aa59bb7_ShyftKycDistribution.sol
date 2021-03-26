/**
 *Submitted for verification at Etherscan.io on 2021-03-26
*/

pragma solidity ^0.7.1;
//SPDX-License-Identifier: UNLICENSED

/* New ERC23 contract interface */

interface IErc223 {
    function totalSupply() external view returns (uint);

    function balanceOf(address who) external view returns (uint);

    function transfer(address to, uint value) external returns (bool ok);
    function transfer(address to, uint value, bytes memory data) external returns (bool ok);
    
    event Transfer(address indexed from, address indexed to, uint value, bytes indexed data);
}

/**
* @title Contract that will work with ERC223 tokens.
*/

interface IErc223ReceivingContract {
    /**
     * @dev Standard ERC223 function that will handle incoming token transfers.
     *
     * @param _from  Token sender address.
     * @param _value Amount of tokens.
     * @param _data  Transaction metadata.
     */
    function tokenFallback(address _from, uint _value, bytes memory _data) external returns (bool ok);
}


interface IErc20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address tokenOwner) external view returns (uint balance);
    function transfer(address to, uint tokens) external returns (bool success);

    function allowance(address tokenOwner, address spender) external view returns (uint remaining);
    function approve(address spender, uint tokens) external returns (bool success);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}



interface IShyftKycContractRegistry  {
    function isShyftKycContract(address _addr) external view returns (bool result);
    function getCurrentContractAddress() external view returns (address);
    function getContractAddressOfVersion(uint _version) external view returns (address);
    function getContractVersionOfAddress(address _address) external view returns (uint256 result);

    function getAllTokenLocations(address _addr, uint256 _bip32X_type) external view returns (bool[] memory resultLocations, uint256 resultNumFound);
    function getAllTokenLocationsAndBalances(address _addr, uint256 _bip32X_type) external view returns (bool[] memory resultLocations, uint256[] memory resultBalances, uint256 resultNumFound, uint256 resultTotalBalance);
}

pragma experimental ABIEncoderV2;



/*
 * ABDK Math 64.64 Smart Contract Library.  Copyright © 2019 by ABDK Consulting.
 * Author: Mikhail Vladimirov <[email protected]>
 */


/**
 * Smart contract library of mathematical functions operating with signed
 * 64.64-bit fixed point numbers.  Signed 64.64-bit fixed point number is
 * basically a simple fraction whose numerator is signed 128-bit integer and
 * denominator is 2^64.  As long as denominator is always the same, there is no
 * need to store it, thus in Solidity signed 64.64-bit fixed point numbers are
 * represented by int128 type holding only the numerator.
 */
library ABDKMath64x64 {
    /*
     * Minimum value signed 64.64-bit fixed point number may have.
     */
    int128 private constant MIN_64x64 = -0x80000000000000000000000000000000;

    /*
     * Maximum value signed 64.64-bit fixed point number may have.
     */
    int128 private constant MAX_64x64 = 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

    /**
     * Convert signed 256-bit integer number into signed 64.64-bit fixed point
     * number.  Revert on overflow.
     *
     * @param x signed 256-bit integer number
     * @return signed 64.64-bit fixed point number
     */
    function fromInt (int256 x) internal pure returns (int128) {
        require (x >= -0x8000000000000000 && x <= 0x7FFFFFFFFFFFFFFF);
        return int128 (x << 64);
    }

    /**
     * Convert signed 64.64 fixed point number into signed 64-bit integer number
     * rounding down.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 64-bit integer number
     */
    function toInt (int128 x) internal pure returns (int64) {
        return int64 (x >> 64);
    }

    /**
     * Convert unsigned 256-bit integer number into signed 64.64-bit fixed point
     * number.  Revert on overflow.
     *
     * @param x unsigned 256-bit integer number
     * @return signed 64.64-bit fixed point number
     */
    function fromUInt (uint256 x) internal pure returns (int128) {
        require (x <= 0x7FFFFFFFFFFFFFFF);
        return int128 (x << 64);
    }

    /**
     * Convert signed 64.64 fixed point number into unsigned 64-bit integer
     * number rounding down.  Revert on underflow.
     *
     * @param x signed 64.64-bit fixed point number
     * @return unsigned 64-bit integer number
     */
    function toUInt (int128 x) internal pure returns (uint64) {
        require (x >= 0);
        return uint64 (x >> 64);
    }

    /**
     * Convert signed 128.128 fixed point number into signed 64.64-bit fixed point
     * number rounding down.  Revert on overflow.
     *
     * @param x signed 128.128-bin fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function from128x128 (int256 x) internal pure returns (int128) {
        int256 result = x >> 64;
        require (result >= MIN_64x64 && result <= MAX_64x64);
        return int128 (result);
    }

    /**
     * Convert signed 64.64 fixed point number into signed 128.128 fixed point
     * number.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 128.128 fixed point number
     */
    function to128x128 (int128 x) internal pure returns (int256) {
        return int256 (x) << 64;
    }

    /**
     * Calculate x + y.  Revert on overflow.
     *
     * @param x signed 64.64-bit fixed point number
     * @param y signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function add (int128 x, int128 y) internal pure returns (int128) {
        int256 result = int256(x) + y;
        require (result >= MIN_64x64 && result <= MAX_64x64);
        return int128 (result);
    }

    /**
     * Calculate x - y.  Revert on overflow.
     *
     * @param x signed 64.64-bit fixed point number
     * @param y signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function sub (int128 x, int128 y) internal pure returns (int128) {
        int256 result = int256(x) - y;
        require (result >= MIN_64x64 && result <= MAX_64x64);
        return int128 (result);
    }

    /**
     * Calculate x * y rounding down.  Revert on overflow.
     *
     * @param x signed 64.64-bit fixed point number
     * @param y signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function mul (int128 x, int128 y) internal pure returns (int128) {
        int256 result = int256(x) * y >> 64;
        require (result >= MIN_64x64 && result <= MAX_64x64);
        return int128 (result);
    }

    /**
     * Calculate x * y rounding towards zero, where x is signed 64.64 fixed point
     * number and y is signed 256-bit integer number.  Revert on overflow.
     *
     * @param x signed 64.64 fixed point number
     * @param y signed 256-bit integer number
     * @return signed 256-bit integer number
     */
    function muli (int128 x, int256 y) internal pure returns (int256) {
        if (x == MIN_64x64) {
            require (y >= -0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF &&
            y <= 0x1000000000000000000000000000000000000000000000000);
            return -y << 63;
        } else {
            bool negativeResult = false;
            if (x < 0) {
                x = -x;
                negativeResult = true;
            }
            if (y < 0) {
                y = -y; // We rely on overflow behavior here
                negativeResult = !negativeResult;
            }
            uint256 absoluteResult = mulu (x, uint256 (y));
            if (negativeResult) {
                require (absoluteResult <=
                    0x8000000000000000000000000000000000000000000000000000000000000000);
                return -int256 (absoluteResult); // We rely on overflow behavior here
            } else {
                require (absoluteResult <=
                    0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
                return int256 (absoluteResult);
            }
        }
    }

    /**
     * Calculate x * y rounding down, where x is signed 64.64 fixed point number
     * and y is unsigned 256-bit integer number.  Revert on overflow.
     *
     * @param x signed 64.64 fixed point number
     * @param y unsigned 256-bit integer number
     * @return unsigned 256-bit integer number
     */
    function mulu (int128 x, uint256 y) internal pure returns (uint256) {
        if (y == 0) return 0;

        require (x >= 0);

        uint256 lo = (uint256 (x) * (y & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)) >> 64;
        uint256 hi = uint256 (x) * (y >> 128);

        require (hi <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
        hi <<= 64;

        require (hi <=
            0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF - lo);
        return hi + lo;
    }

    /**
     * Calculate x / y rounding towards zero.  Revert on overflow or when y is
     * zero.
     *
     * @param x signed 64.64-bit fixed point number
     * @param y signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function div (int128 x, int128 y) internal pure returns (int128) {
        require (y != 0);
        int256 result = (int256 (x) << 64) / y;
        require (result >= MIN_64x64 && result <= MAX_64x64);
        return int128 (result);
    }

    /**
     * Calculate x / y rounding towards zero, where x and y are signed 256-bit
     * integer numbers.  Revert on overflow or when y is zero.
     *
     * @param x signed 256-bit integer number
     * @param y signed 256-bit integer number
     * @return signed 64.64-bit fixed point number
     */
    function divi (int256 x, int256 y) internal pure returns (int128) {
        require (y != 0);

        bool negativeResult = false;
        if (x < 0) {
            x = -x; // We rely on overflow behavior here
            negativeResult = true;
        }
        if (y < 0) {
            y = -y; // We rely on overflow behavior here
            negativeResult = !negativeResult;
        }
        uint128 absoluteResult = divuu (uint256 (x), uint256 (y));
        if (negativeResult) {
            require (absoluteResult <= 0x80000000000000000000000000000000);
            return -int128 (absoluteResult); // We rely on overflow behavior here
        } else {
            require (absoluteResult <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
            return int128 (absoluteResult); // We rely on overflow behavior here
        }
    }

    /**
     * Calculate x / y rounding towards zero, where x and y are unsigned 256-bit
     * integer numbers.  Revert on overflow or when y is zero.
     *
     * @param x unsigned 256-bit integer number
     * @param y unsigned 256-bit integer number
     * @return signed 64.64-bit fixed point number
     */
    function divu (uint256 x, uint256 y) internal pure returns (int128) {
        require (y != 0);
        uint128 result = divuu (x, y);
        require (result <= uint128 (MAX_64x64));
        return int128 (result);
    }

    /**
     * Calculate -x.  Revert on overflow.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function neg (int128 x) internal pure returns (int128) {
        require (x != MIN_64x64);
        return -x;
    }

    /**
     * Calculate |x|.  Revert on overflow.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function abs (int128 x) internal pure returns (int128) {
        require (x != MIN_64x64);
        return x < 0 ? -x : x;
    }

    /**
     * Calculate 1 / x rounding towards zero.  Revert on overflow or when x is
     * zero.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function inv (int128 x) internal pure returns (int128) {
        require (x != 0);
        int256 result = int256 (0x100000000000000000000000000000000) / x;
        require (result >= MIN_64x64 && result <= MAX_64x64);
        return int128 (result);
    }

    /**
     * Calculate arithmetics average of x and y, i.e. (x + y) / 2 rounding down.
     *
     * @param x signed 64.64-bit fixed point number
     * @param y signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function avg (int128 x, int128 y) internal pure returns (int128) {
        return int128 ((int256 (x) + int256 (y)) >> 1);
    }

    /**
     * Calculate geometric average of x and y, i.e. sqrt (x * y) rounding down.
     * Revert on overflow or in case x * y is negative.
     *
     * @param x signed 64.64-bit fixed point number
     * @param y signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function gavg (int128 x, int128 y) internal pure returns (int128) {
        int256 m = int256 (x) * int256 (y);
        require (m >= 0);
        require (m <
            0x4000000000000000000000000000000000000000000000000000000000000000);
        return int128 (sqrtu (uint256 (m)));
    }

    /**
     * Calculate x^y assuming 0^0 is 1, where x is signed 64.64 fixed point number
     * and y is unsigned 256-bit integer number.  Revert on overflow.
     *
     * @param x signed 64.64-bit fixed point number
     * @param y uint256 value
     * @return signed 64.64-bit fixed point number
     */
    function pow (int128 x, uint256 y) internal pure returns (int128) {
        uint256 absoluteResult;
        bool negativeResult = false;
        if (x >= 0) {
            absoluteResult = powu (uint256 (x) << 63, y);
        } else {
            // We rely on overflow behavior here
            absoluteResult = powu (uint256 (uint128 (-x)) << 63, y);
            negativeResult = y & 1 > 0;
        }

        absoluteResult >>= 63;

        if (negativeResult) {
            require (absoluteResult <= 0x80000000000000000000000000000000);
            return -int128 (absoluteResult); // We rely on overflow behavior here
        } else {
            require (absoluteResult <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
            return int128 (absoluteResult); // We rely on overflow behavior here
        }
    }

    /**
     * Calculate sqrt (x) rounding down.  Revert if x < 0.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function sqrt (int128 x) internal pure returns (int128) {
        require (x >= 0);
        return int128 (sqrtu (uint256 (x) << 64));
    }

    /**
     * Calculate binary logarithm of x.  Revert if x <= 0.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function log_2 (int128 x) internal pure returns (int128) {
        require (x > 0);

        int256 msb = 0;
        int256 xc = x;
        if (xc >= 0x10000000000000000) { xc >>= 64; msb += 64; }
        if (xc >= 0x100000000) { xc >>= 32; msb += 32; }
        if (xc >= 0x10000) { xc >>= 16; msb += 16; }
        if (xc >= 0x100) { xc >>= 8; msb += 8; }
        if (xc >= 0x10) { xc >>= 4; msb += 4; }
        if (xc >= 0x4) { xc >>= 2; msb += 2; }
        if (xc >= 0x2) msb += 1;  // No need to shift xc anymore

        int256 result = msb - 64 << 64;
        uint256 ux = uint256 (x) << uint256 (127 - msb);
        for (int256 bit = 0x8000000000000000; bit > 0; bit >>= 1) {
            ux *= ux;
            uint256 b = ux >> 255;
            ux >>= 127 + b;
            result += bit * int256 (b);
        }

        return int128 (result);
    }

    /**
     * Calculate natural logarithm of x.  Revert if x <= 0.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function ln (int128 x) internal pure returns (int128) {
        require (x > 0);

        return int128 (
            uint256 (log_2 (x)) * 0xB17217F7D1CF79ABC9E3B39803F2F6AF >> 128);
    }

    /**
     * Calculate binary exponent of x.  Revert on overflow.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function exp_2 (int128 x) internal pure returns (int128) {
        require (x < 0x400000000000000000); // Overflow

        if (x < -0x400000000000000000) return 0; // Underflow

        uint256 result = 0x80000000000000000000000000000000;

        if (x & 0x8000000000000000 > 0)
            result = result * 0x16A09E667F3BCC908B2FB1366EA957D3E >> 128;
        if (x & 0x4000000000000000 > 0)
            result = result * 0x1306FE0A31B7152DE8D5A46305C85EDEC >> 128;
        if (x & 0x2000000000000000 > 0)
            result = result * 0x1172B83C7D517ADCDF7C8C50EB14A791F >> 128;
        if (x & 0x1000000000000000 > 0)
            result = result * 0x10B5586CF9890F6298B92B71842A98363 >> 128;
        if (x & 0x800000000000000 > 0)
            result = result * 0x1059B0D31585743AE7C548EB68CA417FD >> 128;
        if (x & 0x400000000000000 > 0)
            result = result * 0x102C9A3E778060EE6F7CACA4F7A29BDE8 >> 128;
        if (x & 0x200000000000000 > 0)
            result = result * 0x10163DA9FB33356D84A66AE336DCDFA3F >> 128;
        if (x & 0x100000000000000 > 0)
            result = result * 0x100B1AFA5ABCBED6129AB13EC11DC9543 >> 128;
        if (x & 0x80000000000000 > 0)
            result = result * 0x10058C86DA1C09EA1FF19D294CF2F679B >> 128;
        if (x & 0x40000000000000 > 0)
            result = result * 0x1002C605E2E8CEC506D21BFC89A23A00F >> 128;
        if (x & 0x20000000000000 > 0)
            result = result * 0x100162F3904051FA128BCA9C55C31E5DF >> 128;
        if (x & 0x10000000000000 > 0)
            result = result * 0x1000B175EFFDC76BA38E31671CA939725 >> 128;
        if (x & 0x8000000000000 > 0)
            result = result * 0x100058BA01FB9F96D6CACD4B180917C3D >> 128;
        if (x & 0x4000000000000 > 0)
            result = result * 0x10002C5CC37DA9491D0985C348C68E7B3 >> 128;
        if (x & 0x2000000000000 > 0)
            result = result * 0x1000162E525EE054754457D5995292026 >> 128;
        if (x & 0x1000000000000 > 0)
            result = result * 0x10000B17255775C040618BF4A4ADE83FC >> 128;
        if (x & 0x800000000000 > 0)
            result = result * 0x1000058B91B5BC9AE2EED81E9B7D4CFAB >> 128;
        if (x & 0x400000000000 > 0)
            result = result * 0x100002C5C89D5EC6CA4D7C8ACC017B7C9 >> 128;
        if (x & 0x200000000000 > 0)
            result = result * 0x10000162E43F4F831060E02D839A9D16D >> 128;
        if (x & 0x100000000000 > 0)
            result = result * 0x100000B1721BCFC99D9F890EA06911763 >> 128;
        if (x & 0x80000000000 > 0)
            result = result * 0x10000058B90CF1E6D97F9CA14DBCC1628 >> 128;
        if (x & 0x40000000000 > 0)
            result = result * 0x1000002C5C863B73F016468F6BAC5CA2B >> 128;
        if (x & 0x20000000000 > 0)
            result = result * 0x100000162E430E5A18F6119E3C02282A5 >> 128;
        if (x & 0x10000000000 > 0)
            result = result * 0x1000000B1721835514B86E6D96EFD1BFE >> 128;
        if (x & 0x8000000000 > 0)
            result = result * 0x100000058B90C0B48C6BE5DF846C5B2EF >> 128;
        if (x & 0x4000000000 > 0)
            result = result * 0x10000002C5C8601CC6B9E94213C72737A >> 128;
        if (x & 0x2000000000 > 0)
            result = result * 0x1000000162E42FFF037DF38AA2B219F06 >> 128;
        if (x & 0x1000000000 > 0)
            result = result * 0x10000000B17217FBA9C739AA5819F44F9 >> 128;
        if (x & 0x800000000 > 0)
            result = result * 0x1000000058B90BFCDEE5ACD3C1CEDC823 >> 128;
        if (x & 0x400000000 > 0)
            result = result * 0x100000002C5C85FE31F35A6A30DA1BE50 >> 128;
        if (x & 0x200000000 > 0)
            result = result * 0x10000000162E42FF0999CE3541B9FFFCF >> 128;
        if (x & 0x100000000 > 0)
            result = result * 0x100000000B17217F80F4EF5AADDA45554 >> 128;
        if (x & 0x80000000 > 0)
            result = result * 0x10000000058B90BFBF8479BD5A81B51AD >> 128;
        if (x & 0x40000000 > 0)
            result = result * 0x1000000002C5C85FDF84BD62AE30A74CC >> 128;
        if (x & 0x20000000 > 0)
            result = result * 0x100000000162E42FEFB2FED257559BDAA >> 128;
        if (x & 0x10000000 > 0)
            result = result * 0x1000000000B17217F7D5A7716BBA4A9AE >> 128;
        if (x & 0x8000000 > 0)
            result = result * 0x100000000058B90BFBE9DDBAC5E109CCE >> 128;
        if (x & 0x4000000 > 0)
            result = result * 0x10000000002C5C85FDF4B15DE6F17EB0D >> 128;
        if (x & 0x2000000 > 0)
            result = result * 0x1000000000162E42FEFA494F1478FDE05 >> 128;
        if (x & 0x1000000 > 0)
            result = result * 0x10000000000B17217F7D20CF927C8E94C >> 128;
        if (x & 0x800000 > 0)
            result = result * 0x1000000000058B90BFBE8F71CB4E4B33D >> 128;
        if (x & 0x400000 > 0)
            result = result * 0x100000000002C5C85FDF477B662B26945 >> 128;
        if (x & 0x200000 > 0)
            result = result * 0x10000000000162E42FEFA3AE53369388C >> 128;
        if (x & 0x100000 > 0)
            result = result * 0x100000000000B17217F7D1D351A389D40 >> 128;
        if (x & 0x80000 > 0)
            result = result * 0x10000000000058B90BFBE8E8B2D3D4EDE >> 128;
        if (x & 0x40000 > 0)
            result = result * 0x1000000000002C5C85FDF4741BEA6E77E >> 128;
        if (x & 0x20000 > 0)
            result = result * 0x100000000000162E42FEFA39FE95583C2 >> 128;
        if (x & 0x10000 > 0)
            result = result * 0x1000000000000B17217F7D1CFB72B45E1 >> 128;
        if (x & 0x8000 > 0)
            result = result * 0x100000000000058B90BFBE8E7CC35C3F0 >> 128;
        if (x & 0x4000 > 0)
            result = result * 0x10000000000002C5C85FDF473E242EA38 >> 128;
        if (x & 0x2000 > 0)
            result = result * 0x1000000000000162E42FEFA39F02B772C >> 128;
        if (x & 0x1000 > 0)
            result = result * 0x10000000000000B17217F7D1CF7D83C1A >> 128;
        if (x & 0x800 > 0)
            result = result * 0x1000000000000058B90BFBE8E7BDCBE2E >> 128;
        if (x & 0x400 > 0)
            result = result * 0x100000000000002C5C85FDF473DEA871F >> 128;
        if (x & 0x200 > 0)
            result = result * 0x10000000000000162E42FEFA39EF44D91 >> 128;
        if (x & 0x100 > 0)
            result = result * 0x100000000000000B17217F7D1CF79E949 >> 128;
        if (x & 0x80 > 0)
            result = result * 0x10000000000000058B90BFBE8E7BCE544 >> 128;
        if (x & 0x40 > 0)
            result = result * 0x1000000000000002C5C85FDF473DE6ECA >> 128;
        if (x & 0x20 > 0)
            result = result * 0x100000000000000162E42FEFA39EF366F >> 128;
        if (x & 0x10 > 0)
            result = result * 0x1000000000000000B17217F7D1CF79AFA >> 128;
        if (x & 0x8 > 0)
            result = result * 0x100000000000000058B90BFBE8E7BCD6D >> 128;
        if (x & 0x4 > 0)
            result = result * 0x10000000000000002C5C85FDF473DE6B2 >> 128;
        if (x & 0x2 > 0)
            result = result * 0x1000000000000000162E42FEFA39EF358 >> 128;
        if (x & 0x1 > 0)
            result = result * 0x10000000000000000B17217F7D1CF79AB >> 128;

        result >>= uint256 (63 - (x >> 64));
        require (result <= uint256 (MAX_64x64));

        return int128 (result);
    }

    /**
     * Calculate natural exponent of x.  Revert on overflow.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function exp (int128 x) internal pure returns (int128) {
        require (x < 0x400000000000000000); // Overflow

        if (x < -0x400000000000000000) return 0; // Underflow

        return exp_2 (
            int128 (int256 (x) * 0x171547652B82FE1777D0FFDA0D23A7D12 >> 128));
    }

    /**
     * Calculate x / y rounding towards zero, where x and y are unsigned 256-bit
     * integer numbers.  Revert on overflow or when y is zero.
     *
     * @param x unsigned 256-bit integer number
     * @param y unsigned 256-bit integer number
     * @return unsigned 64.64-bit fixed point number
     */
    function divuu (uint256 x, uint256 y) private pure returns (uint128) {
        require (y != 0);

        uint256 result;

        if (x <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
            result = (x << 64) / y;
        else {
            uint256 msb = 192;
            uint256 xc = x >> 192;
            if (xc >= 0x100000000) { xc >>= 32; msb += 32; }
            if (xc >= 0x10000) { xc >>= 16; msb += 16; }
            if (xc >= 0x100) { xc >>= 8; msb += 8; }
            if (xc >= 0x10) { xc >>= 4; msb += 4; }
            if (xc >= 0x4) { xc >>= 2; msb += 2; }
            if (xc >= 0x2) msb += 1;  // No need to shift xc anymore

            result = (x << 255 - msb) / ((y - 1 >> msb - 191) + 1);
            require (result <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);

            uint256 hi = result * (y >> 128);
            uint256 lo = result * (y & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);

            uint256 xh = x >> 192;
            uint256 xl = x << 64;

            if (xl < lo) xh -= 1;
            xl -= lo; // We rely on overflow behavior here
            lo = hi << 128;
            if (xl < lo) xh -= 1;
            xl -= lo; // We rely on overflow behavior here

            assert (xh == hi >> 128);

            result += xl / y;
        }

        require (result <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
        return uint128 (result);
    }

    /**
     * Calculate x^y assuming 0^0 is 1, where x is unsigned 129.127 fixed point
     * number and y is unsigned 256-bit integer number.  Revert on overflow.
     *
     * @param x unsigned 129.127-bit fixed point number
     * @param y uint256 value
     * @return unsigned 129.127-bit fixed point number
     */
    function powu (uint256 x, uint256 y) private pure returns (uint256) {
        if (y == 0) return 0x80000000000000000000000000000000;
        else if (x == 0) return 0;
        else {
            int256 msb = 0;
            uint256 xc = x;
            if (xc >= 0x100000000000000000000000000000000) { xc >>= 128; msb += 128; }
            if (xc >= 0x10000000000000000) { xc >>= 64; msb += 64; }
            if (xc >= 0x100000000) { xc >>= 32; msb += 32; }
            if (xc >= 0x10000) { xc >>= 16; msb += 16; }
            if (xc >= 0x100) { xc >>= 8; msb += 8; }
            if (xc >= 0x10) { xc >>= 4; msb += 4; }
            if (xc >= 0x4) { xc >>= 2; msb += 2; }
            if (xc >= 0x2) msb += 1;  // No need to shift xc anymore

            int256 xe = msb - 127;
            if (xe > 0) x >>= uint256 (xe);
            else x <<= uint256 (-xe);

            uint256 result = 0x80000000000000000000000000000000;
            int256 re = 0;

            while (y > 0) {
                if (y & 1 > 0) {
                    result = result * x;
                    y -= 1;
                    re += xe;
                    if (result >=
                        0x8000000000000000000000000000000000000000000000000000000000000000) {
                        result >>= 128;
                        re += 1;
                    } else result >>= 127;
                    if (re < -127) return 0; // Underflow
                    require (re < 128); // Overflow
                } else {
                    x = x * x;
                    y >>= 1;
                    xe <<= 1;
                    if (x >=
                        0x8000000000000000000000000000000000000000000000000000000000000000) {
                        x >>= 128;
                        xe += 1;
                    } else x >>= 127;
                    if (xe < -127) return 0; // Underflow
                    require (xe < 128); // Overflow
                }
            }

            if (re > 0) result <<= uint256 (re);
            else if (re < 0) result >>= uint256 (-re);

            return result;
        }
    }

    /**
     * Calculate sqrt (x) rounding down, where x is unsigned 256-bit integer
     * number.
     *
     * @param x unsigned 256-bit integer number
     * @return unsigned 128-bit integer number
     */
    function sqrtu (uint256 x) private pure returns (uint128) {
        if (x == 0) return 0;
        else {
            uint256 xx = x;
            uint256 r = 1;
            if (xx >= 0x100000000000000000000000000000000) { xx >>= 128; r <<= 64; }
            if (xx >= 0x10000000000000000) { xx >>= 64; r <<= 32; }
            if (xx >= 0x100000000) { xx >>= 32; r <<= 16; }
            if (xx >= 0x10000) { xx >>= 16; r <<= 8; }
            if (xx >= 0x100) { xx >>= 8; r <<= 4; }
            if (xx >= 0x10) { xx >>= 4; r <<= 2; }
            if (xx >= 0x8) { r <<= 1; }
            r = (r + x / r) >> 1;
            r = (r + x / r) >> 1;
            r = (r + x / r) >> 1;
            r = (r + x / r) >> 1;
            r = (r + x / r) >> 1;
            r = (r + x / r) >> 1;
            r = (r + x / r) >> 1; // Seven iterations should be enough
            uint256 r1 = x / r;
            return uint128 (r < r1 ? r : r1);
        }
    }
}

/*
 * ABDK Math Quad Smart Contract Library.  Copyright © 2019 by ABDK Consulting.
 * Author: Mikhail Vladimirov <[email protected]>
 */


/**
 * Smart contract library of mathematical functions operating with IEEE 754
 * quadruple-precision binary floating-point numbers (quadruple precision
 * numbers).  As long as quadruple precision numbers are 16-bytes long, they are
 * represented by bytes16 type.
 */
library ABDKMathQuad {
    /*
     * 0.
     */
    bytes16 private constant POSITIVE_ZERO = 0x00000000000000000000000000000000;

    /*
     * -0.
     */
    bytes16 private constant NEGATIVE_ZERO = 0x80000000000000000000000000000000;

    /*
     * +Infinity.
     */
    bytes16 private constant POSITIVE_INFINITY = 0x7FFF0000000000000000000000000000;

    /*
     * -Infinity.
     */
    bytes16 private constant NEGATIVE_INFINITY = 0xFFFF0000000000000000000000000000;

    /*
     * Canonical NaN value.
     */
    bytes16 private constant NaN = 0x7FFF8000000000000000000000000000;

    /**
     * Convert signed 256-bit integer number into quadruple precision number.
     *
     * @param x signed 256-bit integer number
     * @return quadruple precision number
     */
    function fromInt (int256 x) internal pure returns (bytes16) {
        if (x == 0) return bytes16 (0);
        else {
            // We rely on overflow behavior here
            uint256 result = uint256 (x > 0 ? x : -x);

            uint256 msb = msb (result);
            if (msb < 112) result <<= 112 - msb;
            else if (msb > 112) result >>= msb - 112;

            result = result & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF | 16383 + msb << 112;
            if (x < 0) result |= 0x80000000000000000000000000000000;

            return bytes16 (uint128 (result));
        }
    }

    /**
     * Convert quadruple precision number into signed 256-bit integer number
     * rounding towards zero.  Revert on overflow.
     *
     * @param x quadruple precision number
     * @return signed 256-bit integer number
     */
    function toInt (bytes16 x) internal pure returns (int256) {
        uint256 exponent = uint128 (x) >> 112 & 0x7FFF;

        require (exponent <= 16638); // Overflow
        if (exponent < 16383) return 0; // Underflow

        uint256 result = uint256 (uint128 (x)) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF |
        0x10000000000000000000000000000;

        if (exponent < 16495) result >>= 16495 - exponent;
        else if (exponent > 16495) result <<= exponent - 16495;

        if (uint128 (x) >= 0x80000000000000000000000000000000) { // Negative
            require (result <= 0x8000000000000000000000000000000000000000000000000000000000000000);
            return -int256 (result); // We rely on overflow behavior here
        } else {
            require (result <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
            return int256 (result);
        }
    }

    /**
     * Convert unsigned 256-bit integer number into quadruple precision number.
     *
     * @param x unsigned 256-bit integer number
     * @return quadruple precision number
     */
    function fromUInt (uint256 x) internal pure returns (bytes16) {
        if (x == 0) return bytes16 (0);
        else {
            uint256 result = x;

            uint256 msb = msb (result);
            if (msb < 112) result <<= 112 - msb;
            else if (msb > 112) result >>= msb - 112;

            result = result & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF | 16383 + msb << 112;

            return bytes16 (uint128 (result));
        }
    }

    /**
     * Convert quadruple precision number into unsigned 256-bit integer number
     * rounding towards zero.  Revert on underflow.  Note, that negative floating
     * point numbers in range (-1.0 .. 0.0) may be converted to unsigned integer
     * without error, because they are rounded to zero.
     *
     * @param x quadruple precision number
     * @return unsigned 256-bit integer number
     */
    function toUInt (bytes16 x) internal pure returns (uint256) {
        uint256 exponent = uint128 (x) >> 112 & 0x7FFF;

        if (exponent < 16383) return 0; // Underflow

        require (uint128 (x) < 0x80000000000000000000000000000000); // Negative

        require (exponent <= 16638); // Overflow
        uint256 result = uint256 (uint128 (x)) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF |
        0x10000000000000000000000000000;

        if (exponent < 16495) result >>= 16495 - exponent;
        else if (exponent > 16495) result <<= exponent - 16495;

        return result;
    }

    /**
     * Convert signed 128.128 bit fixed point number into quadruple precision
     * number.
     *
     * @param x signed 128.128 bit fixed point number
     * @return quadruple precision number
     */
    function from128x128 (int256 x) internal pure returns (bytes16) {
        if (x == 0) return bytes16 (0);
        else {
            // We rely on overflow behavior here
            uint256 result = uint256 (x > 0 ? x : -x);

            uint256 msb = msb (result);
            if (msb < 112) result <<= 112 - msb;
            else if (msb > 112) result >>= msb - 112;

            result = result & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF | 16255 + msb << 112;
            if (x < 0) result |= 0x80000000000000000000000000000000;

            return bytes16 (uint128 (result));
        }
    }

    /**
     * Convert quadruple precision number into signed 128.128 bit fixed point
     * number.  Revert on overflow.
     *
     * @param x quadruple precision number
     * @return signed 128.128 bit fixed point number
     */
    function to128x128 (bytes16 x) internal pure returns (int256) {
        uint256 exponent = uint128 (x) >> 112 & 0x7FFF;

        require (exponent <= 16510); // Overflow
        if (exponent < 16255) return 0; // Underflow

        uint256 result = uint256 (uint128 (x)) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF |
        0x10000000000000000000000000000;

        if (exponent < 16367) result >>= 16367 - exponent;
        else if (exponent > 16367) result <<= exponent - 16367;

        if (uint128 (x) >= 0x80000000000000000000000000000000) { // Negative
            require (result <= 0x8000000000000000000000000000000000000000000000000000000000000000);
            return -int256 (result); // We rely on overflow behavior here
        } else {
            require (result <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
            return int256 (result);
        }
    }

    /**
     * Convert signed 64.64 bit fixed point number into quadruple precision
     * number.
     *
     * @param x signed 64.64 bit fixed point number
     * @return quadruple precision number
     */
    function from64x64 (int128 x) internal pure returns (bytes16) {
        if (x == 0) return bytes16 (0);
        else {
            // We rely on overflow behavior here
            uint256 result = uint128 (x > 0 ? x : -x);

            uint256 msb = msb (result);
            if (msb < 112) result <<= 112 - msb;
            else if (msb > 112) result >>= msb - 112;

            result = result & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF | 16319 + msb << 112;
            if (x < 0) result |= 0x80000000000000000000000000000000;

            return bytes16 (uint128 (result));
        }
    }

    /**
     * Convert quadruple precision number into signed 64.64 bit fixed point
     * number.  Revert on overflow.
     *
     * @param x quadruple precision number
     * @return signed 64.64 bit fixed point number
     */
    function to64x64 (bytes16 x) internal pure returns (int128) {
        uint256 exponent = uint128 (x) >> 112 & 0x7FFF;

        require (exponent <= 16446); // Overflow
        if (exponent < 16319) return 0; // Underflow

        uint256 result = uint256 (uint128 (x)) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF |
        0x10000000000000000000000000000;

        if (exponent < 16431) result >>= 16431 - exponent;
        else if (exponent > 16431) result <<= exponent - 16431;

        if (uint128 (x) >= 0x80000000000000000000000000000000) { // Negative
            require (result <= 0x80000000000000000000000000000000);
            return -int128 (result); // We rely on overflow behavior here
        } else {
            require (result <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
            return int128 (result);
        }
    }

    /**
     * Convert octuple precision number into quadruple precision number.
     *
     * @param x octuple precision number
     * @return quadruple precision number
     */
    function fromOctuple (bytes32 x) internal pure returns (bytes16) {
        bool negative = x & 0x8000000000000000000000000000000000000000000000000000000000000000 > 0;

        uint256 exponent = uint256 (x) >> 236 & 0x7FFFF;
        uint256 significand = uint256 (x) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

        if (exponent == 0x7FFFF) {
            if (significand > 0) return NaN;
            else return negative ? NEGATIVE_INFINITY : POSITIVE_INFINITY;
        }

        if (exponent > 278526)
            return negative ? NEGATIVE_INFINITY : POSITIVE_INFINITY;
        else if (exponent < 245649)
            return negative ? NEGATIVE_ZERO : POSITIVE_ZERO;
        else if (exponent < 245761) {
            significand = (significand | 0x100000000000000000000000000000000000000000000000000000000000) >> 245885 - exponent;
            exponent = 0;
        } else {
            significand >>= 124;
            exponent -= 245760;
        }

        uint128 result = uint128 (significand | exponent << 112);
        if (negative) result |= 0x80000000000000000000000000000000;

        return bytes16 (result);
    }

    /**
     * Convert quadruple precision number into octuple precision number.
     *
     * @param x quadruple precision number
     * @return octuple precision number
     */
    function toOctuple (bytes16 x) internal pure returns (bytes32) {
        uint256 exponent = uint128 (x) >> 112 & 0x7FFF;

        uint256 result = uint128 (x) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

        if (exponent == 0x7FFF) exponent = 0x7FFFF; // Infinity or NaN
        else if (exponent == 0) {
            if (result > 0) {
                uint256 msb = msb (result);
                result = result << 236 - msb & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
                exponent = 245649 + msb;
            }
        } else {
            result <<= 124;
            exponent += 245760;
        }

        result |= exponent << 236;
        if (uint128 (x) >= 0x80000000000000000000000000000000)
            result |= 0x8000000000000000000000000000000000000000000000000000000000000000;

        return bytes32 (result);
    }

    /**
     * Convert double precision number into quadruple precision number.
     *
     * @param x double precision number
     * @return quadruple precision number
     */
    function fromDouble (bytes8 x) internal pure returns (bytes16) {
        uint256 exponent = uint64 (x) >> 52 & 0x7FF;

        uint256 result = uint64 (x) & 0xFFFFFFFFFFFFF;

        if (exponent == 0x7FF) exponent = 0x7FFF; // Infinity or NaN
        else if (exponent == 0) {
            if (result > 0) {
                uint256 msb = msb (result);
                result = result << 112 - msb & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
                exponent = 15309 + msb;
            }
        } else {
            result <<= 60;
            exponent += 15360;
        }

        result |= exponent << 112;
        if (x & 0x8000000000000000 > 0)
            result |= 0x80000000000000000000000000000000;

        return bytes16 (uint128 (result));
    }

    /**
     * Convert quadruple precision number into double precision number.
     *
     * @param x quadruple precision number
     * @return double precision number
     */
    function toDouble (bytes16 x) internal pure returns (bytes8) {
        bool negative = uint128 (x) >= 0x80000000000000000000000000000000;

        uint256 exponent = uint128 (x) >> 112 & 0x7FFF;
        uint256 significand = uint128 (x) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

        if (exponent == 0x7FFF) {
            if (significand > 0) return 0x7FF8000000000000; // NaN
            else return negative ?
            bytes8 (0xFFF0000000000000) : // -Infinity
            bytes8 (0x7FF0000000000000); // Infinity
        }

        if (exponent > 17406)
            return negative ?
            bytes8 (0xFFF0000000000000) : // -Infinity
            bytes8 (0x7FF0000000000000); // Infinity
        else if (exponent < 15309)
            return negative ?
            bytes8 (0x8000000000000000) : // -0
            bytes8 (0x0000000000000000); // 0
        else if (exponent < 15361) {
            significand = (significand | 0x10000000000000000000000000000) >> 15421 - exponent;
            exponent = 0;
        } else {
            significand >>= 60;
            exponent -= 15360;
        }

        uint64 result = uint64 (significand | exponent << 52);
        if (negative) result |= 0x8000000000000000;

        return bytes8 (result);
    }

    /**
     * Test whether given quadruple precision number is NaN.
     *
     * @param x quadruple precision number
     * @return true if x is NaN, false otherwise
     */
    function isNaN (bytes16 x) internal pure returns (bool) {
        return uint128 (x) & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF >
        0x7FFF0000000000000000000000000000;
    }

    /**
     * Test whether given quadruple precision number is positive or negative
     * infinity.
     *
     * @param x quadruple precision number
     * @return true if x is positive or negative infinity, false otherwise
     */
    function isInfinity (bytes16 x) internal pure returns (bool) {
        return uint128 (x) & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF ==
        0x7FFF0000000000000000000000000000;
    }

    /**
     * Calculate sign of x, i.e. -1 if x is negative, 0 if x if zero, and 1 if x
     * is positive.  Note that sign (-0) is zero.  Revert if x is NaN.
     *
     * @param x quadruple precision number
     * @return sign of x
     */
    function sign (bytes16 x) internal pure returns (int8) {
        uint128 absoluteX = uint128 (x) & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

        require (absoluteX <= 0x7FFF0000000000000000000000000000); // Not NaN

        if (absoluteX == 0) return 0;
        else if (uint128 (x) >= 0x80000000000000000000000000000000) return -1;
        else return 1;
    }

    /**
     * Calculate sign (x - y).  Revert if either argument is NaN, or both
     * arguments are infinities of the same sign.
     *
     * @param x quadruple precision number
     * @param y quadruple precision number
     * @return sign (x - y)
     */
    function cmp (bytes16 x, bytes16 y) internal pure returns (int8) {
        uint128 absoluteX = uint128 (x) & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

        require (absoluteX <= 0x7FFF0000000000000000000000000000); // Not NaN

        uint128 absoluteY = uint128 (y) & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

        require (absoluteY <= 0x7FFF0000000000000000000000000000); // Not NaN

        // Not infinities of the same sign
        require (x != y || absoluteX < 0x7FFF0000000000000000000000000000);

        if (x == y) return 0;
        else {
            bool negativeX = uint128 (x) >= 0x80000000000000000000000000000000;
            bool negativeY = uint128 (y) >= 0x80000000000000000000000000000000;

            if (negativeX) {
                if (negativeY) return absoluteX > absoluteY ? -1 : int8 (1);
                else return -1;
            } else {
                if (negativeY) return 1;
                else return absoluteX > absoluteY ? int8 (1) : -1;
            }
        }
    }

    /**
     * Test whether x equals y.  NaN, infinity, and -infinity are not equal to
     * anything.
     *
     * @param x quadruple precision number
     * @param y quadruple precision number
     * @return true if x equals to y, false otherwise
     */
    function eq (bytes16 x, bytes16 y) internal pure returns (bool) {
        if (x == y) {
            return uint128 (x) & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF <
            0x7FFF0000000000000000000000000000;
        } else return false;
    }

    /**
     * Calculate x + y.  Special values behave in the following way:
     *
     * NaN + x = NaN for any x.
     * Infinity + x = Infinity for any finite x.
     * -Infinity + x = -Infinity for any finite x.
     * Infinity + Infinity = Infinity.
     * -Infinity + -Infinity = -Infinity.
     * Infinity + -Infinity = -Infinity + Infinity = NaN.
     *
     * @param x quadruple precision number
     * @param y quadruple precision number
     * @return quadruple precision number
     */
    function add (bytes16 x, bytes16 y) internal pure returns (bytes16) {
        uint256 xExponent = uint128 (x) >> 112 & 0x7FFF;
        uint256 yExponent = uint128 (y) >> 112 & 0x7FFF;

        if (xExponent == 0x7FFF) {
            if (yExponent == 0x7FFF) {
                if (x == y) return x;
                else return NaN;
            } else return x;
        } else if (yExponent == 0x7FFF) return y;
        else {
            bool xSign = uint128 (x) >= 0x80000000000000000000000000000000;
            uint256 xSignifier = uint128 (x) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
            if (xExponent == 0) xExponent = 1;
            else xSignifier |= 0x10000000000000000000000000000;

            bool ySign = uint128 (y) >= 0x80000000000000000000000000000000;
            uint256 ySignifier = uint128 (y) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
            if (yExponent == 0) yExponent = 1;
            else ySignifier |= 0x10000000000000000000000000000;

            if (xSignifier == 0) return y == NEGATIVE_ZERO ? POSITIVE_ZERO : y;
            else if (ySignifier == 0) return x == NEGATIVE_ZERO ? POSITIVE_ZERO : x;
            else {
                int256 delta = int256 (xExponent) - int256 (yExponent);

                if (xSign == ySign) {
                    if (delta > 112) return x;
                    else if (delta > 0) ySignifier >>= uint256 (delta);
                    else if (delta < -112) return y;
                    else if (delta < 0) {
                        xSignifier >>= uint256 (-delta);
                        xExponent = yExponent;
                    }

                    xSignifier += ySignifier;

                    if (xSignifier >= 0x20000000000000000000000000000) {
                        xSignifier >>= 1;
                        xExponent += 1;
                    }

                    if (xExponent == 0x7FFF)
                        return xSign ? NEGATIVE_INFINITY : POSITIVE_INFINITY;
                    else {
                        if (xSignifier < 0x10000000000000000000000000000) xExponent = 0;
                        else xSignifier &= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

                        return bytes16 (uint128 (
                                (xSign ? 0x80000000000000000000000000000000 : 0) |
                                (xExponent << 112) |
                                xSignifier));
                    }
                } else {
                    if (delta > 0) {
                        xSignifier <<= 1;
                        xExponent -= 1;
                    } else if (delta < 0) {
                        ySignifier <<= 1;
                        xExponent = yExponent - 1;
                    }

                    if (delta > 112) ySignifier = 1;
                    else if (delta > 1) ySignifier = (ySignifier - 1 >> uint256 (delta - 1)) + 1;
                    else if (delta < -112) xSignifier = 1;
                    else if (delta < -1) xSignifier = (xSignifier - 1 >> uint256 (-delta - 1)) + 1;

                    if (xSignifier >= ySignifier) xSignifier -= ySignifier;
                    else {
                        xSignifier = ySignifier - xSignifier;
                        xSign = ySign;
                    }

                    if (xSignifier == 0)
                        return POSITIVE_ZERO;

                    uint256 msb = msb (xSignifier);

                    if (msb == 113) {
                        xSignifier = xSignifier >> 1 & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
                        xExponent += 1;
                    } else if (msb < 112) {
                        uint256 shift = 112 - msb;
                        if (xExponent > shift) {
                            xSignifier = xSignifier << shift & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
                            xExponent -= shift;
                        } else {
                            xSignifier <<= xExponent - 1;
                            xExponent = 0;
                        }
                    } else xSignifier &= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

                    if (xExponent == 0x7FFF)
                        return xSign ? NEGATIVE_INFINITY : POSITIVE_INFINITY;
                    else return bytes16 (uint128 (
                            (xSign ? 0x80000000000000000000000000000000 : 0) |
                            (xExponent << 112) |
                            xSignifier));
                }
            }
        }
    }

    /**
     * Calculate x - y.  Special values behave in the following way:
     *
     * NaN - x = NaN for any x.
     * Infinity - x = Infinity for any finite x.
     * -Infinity - x = -Infinity for any finite x.
     * Infinity - -Infinity = Infinity.
     * -Infinity - Infinity = -Infinity.
     * Infinity - Infinity = -Infinity - -Infinity = NaN.
     *
     * @param x quadruple precision number
     * @param y quadruple precision number
     * @return quadruple precision number
     */
    function sub (bytes16 x, bytes16 y) internal pure returns (bytes16) {
        return add (x, y ^ 0x80000000000000000000000000000000);
    }

    /**
     * Calculate x * y.  Special values behave in the following way:
     *
     * NaN * x = NaN for any x.
     * Infinity * x = Infinity for any finite positive x.
     * Infinity * x = -Infinity for any finite negative x.
     * -Infinity * x = -Infinity for any finite positive x.
     * -Infinity * x = Infinity for any finite negative x.
     * Infinity * 0 = NaN.
     * -Infinity * 0 = NaN.
     * Infinity * Infinity = Infinity.
     * Infinity * -Infinity = -Infinity.
     * -Infinity * Infinity = -Infinity.
     * -Infinity * -Infinity = Infinity.
     *
     * @param x quadruple precision number
     * @param y quadruple precision number
     * @return quadruple precision number
     */
    function mul (bytes16 x, bytes16 y) internal pure returns (bytes16) {
        uint256 xExponent = uint128 (x) >> 112 & 0x7FFF;
        uint256 yExponent = uint128 (y) >> 112 & 0x7FFF;

        if (xExponent == 0x7FFF) {
            if (yExponent == 0x7FFF) {
                if (x == y) return x ^ y & 0x80000000000000000000000000000000;
                else if (x ^ y == 0x80000000000000000000000000000000) return x | y;
                else return NaN;
            } else {
                if (y & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF == 0) return NaN;
                else return x ^ y & 0x80000000000000000000000000000000;
            }
        } else if (yExponent == 0x7FFF) {
            if (x & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF == 0) return NaN;
            else return y ^ x & 0x80000000000000000000000000000000;
        } else {
            uint256 xSignifier = uint128 (x) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
            if (xExponent == 0) xExponent = 1;
            else xSignifier |= 0x10000000000000000000000000000;

            uint256 ySignifier = uint128 (y) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
            if (yExponent == 0) yExponent = 1;
            else ySignifier |= 0x10000000000000000000000000000;

            xSignifier *= ySignifier;
            if (xSignifier == 0)
                return (x ^ y) & 0x80000000000000000000000000000000 > 0 ?
                NEGATIVE_ZERO : POSITIVE_ZERO;

            xExponent += yExponent;

            uint256 msb =
            xSignifier >= 0x200000000000000000000000000000000000000000000000000000000 ? 225 :
            xSignifier >= 0x100000000000000000000000000000000000000000000000000000000 ? 224 :
            msb (xSignifier);

            if (xExponent + msb < 16496) { // Underflow
                xExponent = 0;
                xSignifier = 0;
            } else if (xExponent + msb < 16608) { // Subnormal
                if (xExponent < 16496)
                    xSignifier >>= 16496 - xExponent;
                else if (xExponent > 16496)
                    xSignifier <<= xExponent - 16496;
                xExponent = 0;
            } else if (xExponent + msb > 49373) {
                xExponent = 0x7FFF;
                xSignifier = 0;
            } else {
                if (msb > 112)
                    xSignifier >>= msb - 112;
                else if (msb < 112)
                    xSignifier <<= 112 - msb;

                xSignifier &= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

                xExponent = xExponent + msb - 16607;
            }

            return bytes16 (uint128 (uint128 ((x ^ y) & 0x80000000000000000000000000000000) |
            xExponent << 112 | xSignifier));
        }
    }

    /**
     * Calculate x / y.  Special values behave in the following way:
     *
     * NaN / x = NaN for any x.
     * x / NaN = NaN for any x.
     * Infinity / x = Infinity for any finite non-negative x.
     * Infinity / x = -Infinity for any finite negative x including -0.
     * -Infinity / x = -Infinity for any finite non-negative x.
     * -Infinity / x = Infinity for any finite negative x including -0.
     * x / Infinity = 0 for any finite non-negative x.
     * x / -Infinity = -0 for any finite non-negative x.
     * x / Infinity = -0 for any finite non-negative x including -0.
     * x / -Infinity = 0 for any finite non-negative x including -0.
     *
     * Infinity / Infinity = NaN.
     * Infinity / -Infinity = -NaN.
     * -Infinity / Infinity = -NaN.
     * -Infinity / -Infinity = NaN.
     *
     * Division by zero behaves in the following way:
     *
     * x / 0 = Infinity for any finite positive x.
     * x / -0 = -Infinity for any finite positive x.
     * x / 0 = -Infinity for any finite negative x.
     * x / -0 = Infinity for any finite negative x.
     * 0 / 0 = NaN.
     * 0 / -0 = NaN.
     * -0 / 0 = NaN.
     * -0 / -0 = NaN.
     *
     * @param x quadruple precision number
     * @param y quadruple precision number
     * @return quadruple precision number
     */
    function div (bytes16 x, bytes16 y) internal pure returns (bytes16) {
        uint256 xExponent = uint128 (x) >> 112 & 0x7FFF;
        uint256 yExponent = uint128 (y) >> 112 & 0x7FFF;

        if (xExponent == 0x7FFF) {
            if (yExponent == 0x7FFF) return NaN;
            else return x ^ y & 0x80000000000000000000000000000000;
        } else if (yExponent == 0x7FFF) {
            if (y & 0x0000FFFFFFFFFFFFFFFFFFFFFFFFFFFF != 0) return NaN;
            else return POSITIVE_ZERO | (x ^ y) & 0x80000000000000000000000000000000;
        } else if (y & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF == 0) {
            if (x & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF == 0) return NaN;
            else return POSITIVE_INFINITY | (x ^ y) & 0x80000000000000000000000000000000;
        } else {
            uint256 ySignifier = uint128 (y) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
            if (yExponent == 0) yExponent = 1;
            else ySignifier |= 0x10000000000000000000000000000;

            uint256 xSignifier = uint128 (x) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
            if (xExponent == 0) {
                if (xSignifier != 0) {
                    uint shift = 226 - msb (xSignifier);

                    xSignifier <<= shift;

                    xExponent = 1;
                    yExponent += shift - 114;
                }
            }
            else {
                xSignifier = (xSignifier | 0x10000000000000000000000000000) << 114;
            }

            xSignifier = xSignifier / ySignifier;
            if (xSignifier == 0)
                return (x ^ y) & 0x80000000000000000000000000000000 > 0 ?
                NEGATIVE_ZERO : POSITIVE_ZERO;

            assert (xSignifier >= 0x1000000000000000000000000000);

            uint256 msb =
            xSignifier >= 0x80000000000000000000000000000 ? msb (xSignifier) :
            xSignifier >= 0x40000000000000000000000000000 ? 114 :
            xSignifier >= 0x20000000000000000000000000000 ? 113 : 112;

            if (xExponent + msb > yExponent + 16497) { // Overflow
                xExponent = 0x7FFF;
                xSignifier = 0;
            } else if (xExponent + msb + 16380  < yExponent) { // Underflow
                xExponent = 0;
                xSignifier = 0;
            } else if (xExponent + msb + 16268  < yExponent) { // Subnormal
                if (xExponent + 16380 > yExponent)
                    xSignifier <<= xExponent + 16380 - yExponent;
                else if (xExponent + 16380 < yExponent)
                    xSignifier >>= yExponent - xExponent - 16380;

                xExponent = 0;
            } else { // Normal
                if (msb > 112)
                    xSignifier >>= msb - 112;

                xSignifier &= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

                xExponent = xExponent + msb + 16269 - yExponent;
            }

            return bytes16 (uint128 (uint128 ((x ^ y) & 0x80000000000000000000000000000000) |
            xExponent << 112 | xSignifier));
        }
    }

    /**
     * Calculate -x.
     *
     * @param x quadruple precision number
     * @return quadruple precision number
     */
    function neg (bytes16 x) internal pure returns (bytes16) {
        return x ^ 0x80000000000000000000000000000000;
    }

    /**
     * Calculate |x|.
     *
     * @param x quadruple precision number
     * @return quadruple precision number
     */
    function abs (bytes16 x) internal pure returns (bytes16) {
        return x & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
    }

    /**
     * Calculate square root of x.  Return NaN on negative x excluding -0.
     *
     * @param x quadruple precision number
     * @return quadruple precision number
     */
    function sqrt (bytes16 x) internal pure returns (bytes16) {
        if (uint128 (x) >  0x80000000000000000000000000000000) return NaN;
        else {
            uint256 xExponent = uint128 (x) >> 112 & 0x7FFF;
            if (xExponent == 0x7FFF) return x;
            else {
                uint256 xSignifier = uint128 (x) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
                if (xExponent == 0) xExponent = 1;
                else xSignifier |= 0x10000000000000000000000000000;

                if (xSignifier == 0) return POSITIVE_ZERO;

                bool oddExponent = xExponent & 0x1 == 0;
                xExponent = xExponent + 16383 >> 1;

                if (oddExponent) {
                    if (xSignifier >= 0x10000000000000000000000000000)
                        xSignifier <<= 113;
                    else {
                        uint256 msb = msb (xSignifier);
                        uint256 shift = (226 - msb) & 0xFE;
                        xSignifier <<= shift;
                        xExponent -= shift - 112 >> 1;
                    }
                } else {
                    if (xSignifier >= 0x10000000000000000000000000000)
                        xSignifier <<= 112;
                    else {
                        uint256 msb = msb (xSignifier);
                        uint256 shift = (225 - msb) & 0xFE;
                        xSignifier <<= shift;
                        xExponent -= shift - 112 >> 1;
                    }
                }

                uint256 r = 0x10000000000000000000000000000;
                r = (r + xSignifier / r) >> 1;
                r = (r + xSignifier / r) >> 1;
                r = (r + xSignifier / r) >> 1;
                r = (r + xSignifier / r) >> 1;
                r = (r + xSignifier / r) >> 1;
                r = (r + xSignifier / r) >> 1;
                r = (r + xSignifier / r) >> 1; // Seven iterations should be enough
                uint256 r1 = xSignifier / r;
                if (r1 < r) r = r1;

                return bytes16 (uint128 (xExponent << 112 | r & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF));
            }
        }
    }

    /**
     * Calculate binary logarithm of x.  Return NaN on negative x excluding -0.
     *
     * @param x quadruple precision number
     * @return quadruple precision number
     */
    function log_2 (bytes16 x) internal pure returns (bytes16) {
        if (uint128 (x) > 0x80000000000000000000000000000000) return NaN;
        else if (x == 0x3FFF0000000000000000000000000000) return POSITIVE_ZERO;
        else {
            uint256 xExponent = uint128 (x) >> 112 & 0x7FFF;
            if (xExponent == 0x7FFF) return x;
            else {
                uint256 xSignifier = uint128 (x) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
                if (xExponent == 0) xExponent = 1;
                else xSignifier |= 0x10000000000000000000000000000;

                if (xSignifier == 0) return NEGATIVE_INFINITY;

                bool resultNegative;
                uint256 resultExponent = 16495;
                uint256 resultSignifier;

                if (xExponent >= 0x3FFF) {
                    resultNegative = false;
                    resultSignifier = xExponent - 0x3FFF;
                    xSignifier <<= 15;
                } else {
                    resultNegative = true;
                    if (xSignifier >= 0x10000000000000000000000000000) {
                        resultSignifier = 0x3FFE - xExponent;
                        xSignifier <<= 15;
                    } else {
                        uint256 msb = msb (xSignifier);
                        resultSignifier = 16493 - msb;
                        xSignifier <<= 127 - msb;
                    }
                }

                if (xSignifier == 0x80000000000000000000000000000000) {
                    if (resultNegative) resultSignifier += 1;
                    uint256 shift = 112 - msb (resultSignifier);
                    resultSignifier <<= shift;
                    resultExponent -= shift;
                } else {
                    uint256 bb = resultNegative ? 1 : 0;
                    while (resultSignifier < 0x10000000000000000000000000000) {
                        resultSignifier <<= 1;
                        resultExponent -= 1;

                        xSignifier *= xSignifier;
                        uint256 b = xSignifier >> 255;
                        resultSignifier += b ^ bb;
                        xSignifier >>= 127 + b;
                    }
                }

                return bytes16 (uint128 ((resultNegative ? 0x80000000000000000000000000000000 : 0) |
                resultExponent << 112 | resultSignifier & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF));
            }
        }
    }

    /**
     * Calculate natural logarithm of x.  Return NaN on negative x excluding -0.
     *
     * @param x quadruple precision number
     * @return quadruple precision number
     */
    function ln (bytes16 x) internal pure returns (bytes16) {
        return mul (log_2 (x), 0x3FFE62E42FEFA39EF35793C7673007E5);
    }

    /**
     * Calculate 2^x.
     *
     * @param x quadruple precision number
     * @return quadruple precision number
     */
    function pow_2 (bytes16 x) internal pure returns (bytes16) {
        bool xNegative = uint128 (x) > 0x80000000000000000000000000000000;
        uint256 xExponent = uint128 (x) >> 112 & 0x7FFF;
        uint256 xSignifier = uint128 (x) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

        if (xExponent == 0x7FFF && xSignifier != 0) return NaN;
        else if (xExponent > 16397)
            return xNegative ? POSITIVE_ZERO : POSITIVE_INFINITY;
        else if (xExponent < 16255)
            return 0x3FFF0000000000000000000000000000;
        else {
            if (xExponent == 0) xExponent = 1;
            else xSignifier |= 0x10000000000000000000000000000;

            if (xExponent > 16367)
                xSignifier <<= xExponent - 16367;
            else if (xExponent < 16367)
                xSignifier >>= 16367 - xExponent;

            if (xNegative && xSignifier > 0x406E00000000000000000000000000000000)
                return POSITIVE_ZERO;

            if (!xNegative && xSignifier > 0x3FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
                return POSITIVE_INFINITY;

            uint256 resultExponent = xSignifier >> 128;
            xSignifier &= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
            if (xNegative && xSignifier != 0) {
                xSignifier = ~xSignifier;
                resultExponent += 1;
            }

            uint256 resultSignifier = 0x80000000000000000000000000000000;
            if (xSignifier & 0x80000000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x16A09E667F3BCC908B2FB1366EA957D3E >> 128;
            if (xSignifier & 0x40000000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1306FE0A31B7152DE8D5A46305C85EDEC >> 128;
            if (xSignifier & 0x20000000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1172B83C7D517ADCDF7C8C50EB14A791F >> 128;
            if (xSignifier & 0x10000000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x10B5586CF9890F6298B92B71842A98363 >> 128;
            if (xSignifier & 0x8000000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1059B0D31585743AE7C548EB68CA417FD >> 128;
            if (xSignifier & 0x4000000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x102C9A3E778060EE6F7CACA4F7A29BDE8 >> 128;
            if (xSignifier & 0x2000000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x10163DA9FB33356D84A66AE336DCDFA3F >> 128;
            if (xSignifier & 0x1000000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x100B1AFA5ABCBED6129AB13EC11DC9543 >> 128;
            if (xSignifier & 0x800000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x10058C86DA1C09EA1FF19D294CF2F679B >> 128;
            if (xSignifier & 0x400000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1002C605E2E8CEC506D21BFC89A23A00F >> 128;
            if (xSignifier & 0x200000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x100162F3904051FA128BCA9C55C31E5DF >> 128;
            if (xSignifier & 0x100000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000B175EFFDC76BA38E31671CA939725 >> 128;
            if (xSignifier & 0x80000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x100058BA01FB9F96D6CACD4B180917C3D >> 128;
            if (xSignifier & 0x40000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x10002C5CC37DA9491D0985C348C68E7B3 >> 128;
            if (xSignifier & 0x20000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000162E525EE054754457D5995292026 >> 128;
            if (xSignifier & 0x10000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x10000B17255775C040618BF4A4ADE83FC >> 128;
            if (xSignifier & 0x8000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000058B91B5BC9AE2EED81E9B7D4CFAB >> 128;
            if (xSignifier & 0x4000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x100002C5C89D5EC6CA4D7C8ACC017B7C9 >> 128;
            if (xSignifier & 0x2000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x10000162E43F4F831060E02D839A9D16D >> 128;
            if (xSignifier & 0x1000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x100000B1721BCFC99D9F890EA06911763 >> 128;
            if (xSignifier & 0x800000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x10000058B90CF1E6D97F9CA14DBCC1628 >> 128;
            if (xSignifier & 0x400000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000002C5C863B73F016468F6BAC5CA2B >> 128;
            if (xSignifier & 0x200000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x100000162E430E5A18F6119E3C02282A5 >> 128;
            if (xSignifier & 0x100000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000B1721835514B86E6D96EFD1BFE >> 128;
            if (xSignifier & 0x80000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x100000058B90C0B48C6BE5DF846C5B2EF >> 128;
            if (xSignifier & 0x40000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x10000002C5C8601CC6B9E94213C72737A >> 128;
            if (xSignifier & 0x20000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000162E42FFF037DF38AA2B219F06 >> 128;
            if (xSignifier & 0x10000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x10000000B17217FBA9C739AA5819F44F9 >> 128;
            if (xSignifier & 0x8000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000058B90BFCDEE5ACD3C1CEDC823 >> 128;
            if (xSignifier & 0x4000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x100000002C5C85FE31F35A6A30DA1BE50 >> 128;
            if (xSignifier & 0x2000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x10000000162E42FF0999CE3541B9FFFCF >> 128;
            if (xSignifier & 0x1000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x100000000B17217F80F4EF5AADDA45554 >> 128;
            if (xSignifier & 0x800000000000000000000000 > 0) resultSignifier = resultSignifier * 0x10000000058B90BFBF8479BD5A81B51AD >> 128;
            if (xSignifier & 0x400000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000002C5C85FDF84BD62AE30A74CC >> 128;
            if (xSignifier & 0x200000000000000000000000 > 0) resultSignifier = resultSignifier * 0x100000000162E42FEFB2FED257559BDAA >> 128;
            if (xSignifier & 0x100000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000B17217F7D5A7716BBA4A9AE >> 128;
            if (xSignifier & 0x80000000000000000000000 > 0) resultSignifier = resultSignifier * 0x100000000058B90BFBE9DDBAC5E109CCE >> 128;
            if (xSignifier & 0x40000000000000000000000 > 0) resultSignifier = resultSignifier * 0x10000000002C5C85FDF4B15DE6F17EB0D >> 128;
            if (xSignifier & 0x20000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000162E42FEFA494F1478FDE05 >> 128;
            if (xSignifier & 0x10000000000000000000000 > 0) resultSignifier = resultSignifier * 0x10000000000B17217F7D20CF927C8E94C >> 128;
            if (xSignifier & 0x8000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000058B90BFBE8F71CB4E4B33D >> 128;
            if (xSignifier & 0x4000000000000000000000 > 0) resultSignifier = resultSignifier * 0x100000000002C5C85FDF477B662B26945 >> 128;
            if (xSignifier & 0x2000000000000000000000 > 0) resultSignifier = resultSignifier * 0x10000000000162E42FEFA3AE53369388C >> 128;
            if (xSignifier & 0x1000000000000000000000 > 0) resultSignifier = resultSignifier * 0x100000000000B17217F7D1D351A389D40 >> 128;
            if (xSignifier & 0x800000000000000000000 > 0) resultSignifier = resultSignifier * 0x10000000000058B90BFBE8E8B2D3D4EDE >> 128;
            if (xSignifier & 0x400000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000002C5C85FDF4741BEA6E77E >> 128;
            if (xSignifier & 0x200000000000000000000 > 0) resultSignifier = resultSignifier * 0x100000000000162E42FEFA39FE95583C2 >> 128;
            if (xSignifier & 0x100000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000B17217F7D1CFB72B45E1 >> 128;
            if (xSignifier & 0x80000000000000000000 > 0) resultSignifier = resultSignifier * 0x100000000000058B90BFBE8E7CC35C3F0 >> 128;
            if (xSignifier & 0x40000000000000000000 > 0) resultSignifier = resultSignifier * 0x10000000000002C5C85FDF473E242EA38 >> 128;
            if (xSignifier & 0x20000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000162E42FEFA39F02B772C >> 128;
            if (xSignifier & 0x10000000000000000000 > 0) resultSignifier = resultSignifier * 0x10000000000000B17217F7D1CF7D83C1A >> 128;
            if (xSignifier & 0x8000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000058B90BFBE8E7BDCBE2E >> 128;
            if (xSignifier & 0x4000000000000000000 > 0) resultSignifier = resultSignifier * 0x100000000000002C5C85FDF473DEA871F >> 128;
            if (xSignifier & 0x2000000000000000000 > 0) resultSignifier = resultSignifier * 0x10000000000000162E42FEFA39EF44D91 >> 128;
            if (xSignifier & 0x1000000000000000000 > 0) resultSignifier = resultSignifier * 0x100000000000000B17217F7D1CF79E949 >> 128;
            if (xSignifier & 0x800000000000000000 > 0) resultSignifier = resultSignifier * 0x10000000000000058B90BFBE8E7BCE544 >> 128;
            if (xSignifier & 0x400000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000002C5C85FDF473DE6ECA >> 128;
            if (xSignifier & 0x200000000000000000 > 0) resultSignifier = resultSignifier * 0x100000000000000162E42FEFA39EF366F >> 128;
            if (xSignifier & 0x100000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000B17217F7D1CF79AFA >> 128;
            if (xSignifier & 0x80000000000000000 > 0) resultSignifier = resultSignifier * 0x100000000000000058B90BFBE8E7BCD6D >> 128;
            if (xSignifier & 0x40000000000000000 > 0) resultSignifier = resultSignifier * 0x10000000000000002C5C85FDF473DE6B2 >> 128;
            if (xSignifier & 0x20000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000162E42FEFA39EF358 >> 128;
            if (xSignifier & 0x10000000000000000 > 0) resultSignifier = resultSignifier * 0x10000000000000000B17217F7D1CF79AB >> 128;
            if (xSignifier & 0x8000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000058B90BFBE8E7BCD5 >> 128;
            if (xSignifier & 0x4000000000000000 > 0) resultSignifier = resultSignifier * 0x100000000000000002C5C85FDF473DE6A >> 128;
            if (xSignifier & 0x2000000000000000 > 0) resultSignifier = resultSignifier * 0x10000000000000000162E42FEFA39EF34 >> 128;
            if (xSignifier & 0x1000000000000000 > 0) resultSignifier = resultSignifier * 0x100000000000000000B17217F7D1CF799 >> 128;
            if (xSignifier & 0x800000000000000 > 0) resultSignifier = resultSignifier * 0x10000000000000000058B90BFBE8E7BCC >> 128;
            if (xSignifier & 0x400000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000002C5C85FDF473DE5 >> 128;
            if (xSignifier & 0x200000000000000 > 0) resultSignifier = resultSignifier * 0x100000000000000000162E42FEFA39EF2 >> 128;
            if (xSignifier & 0x100000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000B17217F7D1CF78 >> 128;
            if (xSignifier & 0x80000000000000 > 0) resultSignifier = resultSignifier * 0x100000000000000000058B90BFBE8E7BB >> 128;
            if (xSignifier & 0x40000000000000 > 0) resultSignifier = resultSignifier * 0x10000000000000000002C5C85FDF473DD >> 128;
            if (xSignifier & 0x20000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000162E42FEFA39EE >> 128;
            if (xSignifier & 0x10000000000000 > 0) resultSignifier = resultSignifier * 0x10000000000000000000B17217F7D1CF6 >> 128;
            if (xSignifier & 0x8000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000058B90BFBE8E7A >> 128;
            if (xSignifier & 0x4000000000000 > 0) resultSignifier = resultSignifier * 0x100000000000000000002C5C85FDF473C >> 128;
            if (xSignifier & 0x2000000000000 > 0) resultSignifier = resultSignifier * 0x10000000000000000000162E42FEFA39D >> 128;
            if (xSignifier & 0x1000000000000 > 0) resultSignifier = resultSignifier * 0x100000000000000000000B17217F7D1CE >> 128;
            if (xSignifier & 0x800000000000 > 0) resultSignifier = resultSignifier * 0x10000000000000000000058B90BFBE8E6 >> 128;
            if (xSignifier & 0x400000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000002C5C85FDF472 >> 128;
            if (xSignifier & 0x200000000000 > 0) resultSignifier = resultSignifier * 0x100000000000000000000162E42FEFA38 >> 128;
            if (xSignifier & 0x100000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000000B17217F7D1B >> 128;
            if (xSignifier & 0x80000000000 > 0) resultSignifier = resultSignifier * 0x100000000000000000000058B90BFBE8D >> 128;
            if (xSignifier & 0x40000000000 > 0) resultSignifier = resultSignifier * 0x10000000000000000000002C5C85FDF46 >> 128;
            if (xSignifier & 0x20000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000000162E42FEFA2 >> 128;
            if (xSignifier & 0x10000000000 > 0) resultSignifier = resultSignifier * 0x10000000000000000000000B17217F7D0 >> 128;
            if (xSignifier & 0x8000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000000058B90BFBE7 >> 128;
            if (xSignifier & 0x4000000000 > 0) resultSignifier = resultSignifier * 0x100000000000000000000002C5C85FDF3 >> 128;
            if (xSignifier & 0x2000000000 > 0) resultSignifier = resultSignifier * 0x10000000000000000000000162E42FEF9 >> 128;
            if (xSignifier & 0x1000000000 > 0) resultSignifier = resultSignifier * 0x100000000000000000000000B17217F7C >> 128;
            if (xSignifier & 0x800000000 > 0) resultSignifier = resultSignifier * 0x10000000000000000000000058B90BFBD >> 128;
            if (xSignifier & 0x400000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000000002C5C85FDE >> 128;
            if (xSignifier & 0x200000000 > 0) resultSignifier = resultSignifier * 0x100000000000000000000000162E42FEE >> 128;
            if (xSignifier & 0x100000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000000000B17217F6 >> 128;
            if (xSignifier & 0x80000000 > 0) resultSignifier = resultSignifier * 0x100000000000000000000000058B90BFA >> 128;
            if (xSignifier & 0x40000000 > 0) resultSignifier = resultSignifier * 0x10000000000000000000000002C5C85FC >> 128;
            if (xSignifier & 0x20000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000000000162E42FD >> 128;
            if (xSignifier & 0x10000000 > 0) resultSignifier = resultSignifier * 0x10000000000000000000000000B17217E >> 128;
            if (xSignifier & 0x8000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000000000058B90BE >> 128;
            if (xSignifier & 0x4000000 > 0) resultSignifier = resultSignifier * 0x100000000000000000000000002C5C85E >> 128;
            if (xSignifier & 0x2000000 > 0) resultSignifier = resultSignifier * 0x10000000000000000000000000162E42E >> 128;
            if (xSignifier & 0x1000000 > 0) resultSignifier = resultSignifier * 0x100000000000000000000000000B17216 >> 128;
            if (xSignifier & 0x800000 > 0) resultSignifier = resultSignifier * 0x10000000000000000000000000058B90A >> 128;
            if (xSignifier & 0x400000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000000000002C5C84 >> 128;
            if (xSignifier & 0x200000 > 0) resultSignifier = resultSignifier * 0x100000000000000000000000000162E41 >> 128;
            if (xSignifier & 0x100000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000000000000B1720 >> 128;
            if (xSignifier & 0x80000 > 0) resultSignifier = resultSignifier * 0x100000000000000000000000000058B8F >> 128;
            if (xSignifier & 0x40000 > 0) resultSignifier = resultSignifier * 0x10000000000000000000000000002C5C7 >> 128;
            if (xSignifier & 0x20000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000000000000162E3 >> 128;
            if (xSignifier & 0x10000 > 0) resultSignifier = resultSignifier * 0x10000000000000000000000000000B171 >> 128;
            if (xSignifier & 0x8000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000000000000058B8 >> 128;
            if (xSignifier & 0x4000 > 0) resultSignifier = resultSignifier * 0x100000000000000000000000000002C5B >> 128;
            if (xSignifier & 0x2000 > 0) resultSignifier = resultSignifier * 0x10000000000000000000000000000162D >> 128;
            if (xSignifier & 0x1000 > 0) resultSignifier = resultSignifier * 0x100000000000000000000000000000B16 >> 128;
            if (xSignifier & 0x800 > 0) resultSignifier = resultSignifier * 0x10000000000000000000000000000058A >> 128;
            if (xSignifier & 0x400 > 0) resultSignifier = resultSignifier * 0x1000000000000000000000000000002C4 >> 128;
            if (xSignifier & 0x200 > 0) resultSignifier = resultSignifier * 0x100000000000000000000000000000161 >> 128;
            if (xSignifier & 0x100 > 0) resultSignifier = resultSignifier * 0x1000000000000000000000000000000B0 >> 128;
            if (xSignifier & 0x80 > 0) resultSignifier = resultSignifier * 0x100000000000000000000000000000057 >> 128;
            if (xSignifier & 0x40 > 0) resultSignifier = resultSignifier * 0x10000000000000000000000000000002B >> 128;
            if (xSignifier & 0x20 > 0) resultSignifier = resultSignifier * 0x100000000000000000000000000000015 >> 128;
            if (xSignifier & 0x10 > 0) resultSignifier = resultSignifier * 0x10000000000000000000000000000000A >> 128;
            if (xSignifier & 0x8 > 0) resultSignifier = resultSignifier * 0x100000000000000000000000000000004 >> 128;
            if (xSignifier & 0x4 > 0) resultSignifier = resultSignifier * 0x100000000000000000000000000000001 >> 128;

            if (!xNegative) {
                resultSignifier = resultSignifier >> 15 & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
                resultExponent += 0x3FFF;
            } else if (resultExponent <= 0x3FFE) {
                resultSignifier = resultSignifier >> 15 & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
                resultExponent = 0x3FFF - resultExponent;
            } else {
                resultSignifier = resultSignifier >> resultExponent - 16367;
                resultExponent = 0;
            }

            return bytes16 (uint128 (resultExponent << 112 | resultSignifier));
        }
    }

    /**
     * Calculate e^x.
     *
     * @param x quadruple precision number
     * @return quadruple precision number
     */
    function exp (bytes16 x) internal pure returns (bytes16) {
        return pow_2 (mul (x, 0x3FFF71547652B82FE1777D0FFDA0D23A));
    }

    /**
     * Get index of the most significant non-zero bit in binary representation of
     * x.  Reverts if x is zero.
     *
     * @return index of the most significant non-zero bit in binary representation
     *         of x
     */
    function msb (uint256 x) private pure returns (uint256) {
        require (x > 0);

        uint256 result = 0;

        if (x >= 0x100000000000000000000000000000000) { x >>= 128; result += 128; }
        if (x >= 0x10000000000000000) { x >>= 64; result += 64; }
        if (x >= 0x100000000) { x >>= 32; result += 32; }
        if (x >= 0x10000) { x >>= 16; result += 16; }
        if (x >= 0x100) { x >>= 8; result += 8; }
        if (x >= 0x10) { x >>= 4; result += 4; }
        if (x >= 0x4) { x >>= 2; result += 2; }
        if (x >= 0x2) result += 1; // No need to shift x anymore

        return result;
    }
}



/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error
 */
library SafeMath {
  /**
   * @dev Multiplies two unsigned integers, reverts on overflow.
   */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

  /**
   * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
   */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // Solidity only automatically asserts when dividing by 0
    require(b > 0);
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  /**
   * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
   */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

  /**
   * @dev Adds two unsigned integers, reverts on overflow.
   */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

  /**
   * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
   * reverts when dividing by zero.
   */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}







interface IShyftKycContract is IErc20, IErc223, IErc223ReceivingContract {
    function balanceOf(address tokenOwner) external view override(IErc20, IErc223) returns (uint balance);
    function totalSupply() external view override(IErc20, IErc223) returns (uint);
    function transfer(address to, uint tokens) external override(IErc20, IErc223) returns (bool success);

    function getNativeTokenType() external view returns (uint256 result);

    function withdrawNative(address payable _to, uint256 _value) external returns (bool ok);
    function withdrawToExternalContract(address _to, uint256 _value) external returns (bool ok);
    function withdrawToShyftKycContract(address _shyftKycContractAddress, address _to, uint256 _value) external returns (bool ok);

    function migrateFromKycContract(address _to) external payable returns(bool result);
    function updateContract(address _addr) external returns (bool);

    function getBalanceBip32X(address _identifiedAddress, uint256 _bip32X_type) external view returns (uint256 balance);

    function getOnlyAcceptsKycInput(address _identifiedAddress) external view returns (bool result);
    function getOnlyAcceptsKycInputPermanently(address _identifiedAddress) external view returns (bool result);
}



/// @dev
/// | This contract manages the distribution contracts for the Shyft Network. It is built to enable a native-mode or erc20-mode distribution with specific distribution tables (with individual cycles with %'s and times).
/// | For each of the individuals allocated to, they have their own (potentially unique) distribution table, along with a potential cutoff (reduction) & the address which is managing that, as well as total distributed and any cliff/vesting information.
/// @notice
/// |  This function should be disabled before launch, but for testing purposes there is a requirement to be able to receive native fuel, so this is done in the most strict mode possible, by checking ownership before value transfer can occur.
/// |  receive() external payable {
/// |      if (msg.sender != owner) {
/// |          revert();
/// |      }
/// |  }
/// |
/// | As such, the grunt setup file ('root'/Gruntfile.js) performs some operations to mirror this file to 'root'/Tests/ShyftKycDistribution_OutputForTestCompatibility.sol whenever any "test" related Grunt command is executed.

contract ShyftKycDistribution {
    using SafeMath for uint256;

    /// @dev Event for new shyft total claimed. created.
    event EVT_shyftClaimed(address indexed recipient, uint256 indexed amountClaimed, uint256 totalAllocated, uint256 grandTotalClaimed, uint256 timeStamp);

    /// @dev Event for new allocation created.
    event EVT_newAllocation(address indexed recipient, uint256 totalAllocated, uint256 endCliff, uint256 endVesting, uint256 cutoffTokenAmount, address cutoffAdminAddress, bytes32 distributionTableHash);

    /// @dev Event for cutoff being triggered.
    event EVT_cutoffTriggered(address indexed recipient, uint256 modifiedAllocation, uint256 amountClaimed, uint256 remainingDistribution, uint256 tokensToReturnToCore);

    /// @dev Event for cutoff being triggered (for the "over allocated" case where a user has already withdrawn more tokens than would have been available post-cutoff).
    event EVT_cutoffTriggeredOverAllocated(address indexed recipient, uint256 modifiedAllocation, uint256 amountClaimed, uint256 overAllocatedDistribution, uint256 tokensToReturnToCore);

    /// @dev The kyc contract registry address for erc20 token transfer mode.
    address public kycContractRegistryAddress;

    /// @dev The decimal factor for calculations (saves gas if it's pre-set here).
    uint256 private constant decimalFactor = 10**uint256(18);

    /// @dev The initial supply. Needs to be hardcoded for launch.
    uint256 public constant INITIAL_SUPPLY = 322982495 * decimalFactor;

    /// @dev The total amount of tokens claimed.
    uint256 public totalClaimed;

    /// @dev The start time for this distribution contract.
    uint256 public startTime;

    /// @dev Struct for the distribution cycles, with time periods of starting, ending, percentage of tokens and a 64.64 floating point representation for the percentages.
    struct distributionCycle {
        uint256 timePeriodStart;
        uint256 timePeriodEnd;
        uint256 percentTokens;
        int128 percentTokens_fixedPoint;
    }

    /// @dev Struct for the Allocations with vesting, cutoff, and distribution table information.
    struct Allocation {
        uint256 endCliff;       // Tokens are locked until
        uint256 endVesting;     // This is when the tokens are fully unvested
        uint256 totalAllocated; // Total tokens allocated
        uint256 amountClaimed;  // Total tokens claimed
        uint256 cutoffTokenAmount;   // Amount of tokens reduced
        address cutoffAdminAddress;  // address that has the ability to trigger the cutoff
        bool    cutoffEnabled;     // whether the cutoff is enabled
        bytes32 distributionTableHash;
    }

    /// @dev Struct for the distribution table - if it exists, its string name, an array of the distribution cycles, an array of the total percentage (cumulative) at the end of the cycles.
    struct distributionTable {
        bool exists;
        string distributionTableName;

        distributionCycle[] cyclesArray;
        int128[] totalPercentAtEndOfCycleArray_fixedPoint;
    }

    /// @dev Mapping for keccak hash to distribution table.
    mapping(bytes32 => distributionTable) distributionHashToTableMapping;

    /// @dev Mapping for address to allocations.
    mapping (address => Allocation) public allocations;

    /// @dev Address for the any of the cutoff tokens to be transferred to.
    address payable public shyftCoreTokenAddress;

    /// @dev Whether this distribution contract is outputting to the Shyft KYC Contract token address.
    bool public transferTokenMode;

    /// @dev The owner of this contract.
    address owner;

    /// @param _transferTokenMode Whether this contract transfers tokens from the primary shyft kyc contract in the registry.
    /// @dev Constructor function - Sets the start time and token transfer mode. False equates to native, True equates to erc20 token transfer mode.
    constructor (bool _transferTokenMode) {
        startTime = block.timestamp;

        owner = msg.sender;
        transferTokenMode = _transferTokenMode;
    }

    /// @param _vestEndSeconds When the vest ends in seconds.
    /// @param _cycles An array of "distributionCycle"-formatted cycles.
    /// @param _totalPercentAtEndOfCycles_18DecimalPrecision An array of the total percentage of distribution at the end of the cycles (cumulative).
    /// @dev Internal method to assist setup up for a new distribution table with cycles and the total percentages of each cycle. Takes in a storage array and modifies it, erasing modifications if there's an error that was calculated.
    /// @return result
    ///    | 8 = (error) time period didn't start as the previous ended
    ///    | 7 = (error) time period is higher than full vesting days
    ///    | 6 = (error) time period does not end on the full vesting day
    ///    | 5 = (error) allocation cycle does not equal 100%
    ///    | 4 = (error) allocation cycle has zero percentage
    ///    | 3 = (error) allocation cycles do not match
    ///    | 0 = successfully calculated distribution table

    function calculateDistributionTable(distributionTable storage _distributionTable,
                                        uint256 _vestEndSeconds,
                                        distributionCycle[] memory _cycles,
                                        uint256[] memory _totalPercentAtEndOfCycles_18DecimalPrecision) internal returns (uint8 result) {
        distributionCycle memory prevCycle;
        uint8 errorCode;

        uint256 totalPercentFromCycles = 0;

        for (uint256 i = 0; i < _cycles.length; i++) {
            distributionCycle memory curCycle = _cycles[i];

            // take care of the first index
            if (i == 0) {
                if (curCycle.timePeriodStart != 0) {
                    //time period does not start immediately
                    errorCode = 9;
                    break;
                }
            } else {
                // always check for time alignment
                if (curCycle.timePeriodStart != prevCycle.timePeriodEnd) {
                    //time period didn't start as the previous ended
                    errorCode = 8;
                    break;
                }
                // take care of intermediate indexes
                if (i != _cycles.length - 1) {
                    if (curCycle.timePeriodEnd > _vestEndSeconds) {
                        //time period is higher than full vesting days
                        errorCode = 7;
                        break;
                    }
                } else {
                    //take care of the last index
                    if (curCycle.timePeriodEnd != _vestEndSeconds) {
                        //time period does not end on the full vesting day
                        errorCode = 6;
                        break;
                    }

                    if (totalPercentFromCycles.add(curCycle.percentTokens) != (decimalFactor)) {
                        //allocation cycle does not equal 100%
                        errorCode = 5;
                        break;
                    }
                }
            }

            if (_totalPercentAtEndOfCycles_18DecimalPrecision[i] == 0) {
                //allocation cycle has zero percentage
                errorCode = 4;
                break;
            }

            totalPercentFromCycles = totalPercentFromCycles.add(curCycle.percentTokens);

            if (i > 0) {
                if (_totalPercentAtEndOfCycles_18DecimalPrecision[i] != totalPercentFromCycles) {
                    //allocation cycles do not match
                    errorCode = 3;
                    break;
                }
            } else {
                if (_totalPercentAtEndOfCycles_18DecimalPrecision[i] != totalPercentFromCycles) {
                    //allocation cycles do not match
                    errorCode = 3;
                    break;
                }
            }

            prevCycle = curCycle;

            if (errorCode == 0) {
                curCycle.percentTokens_fixedPoint = ABDKMath64x64.div(ABDKMath64x64.fromUInt(curCycle.percentTokens), ABDKMath64x64.fromUInt(decimalFactor));

                _distributionTable.totalPercentAtEndOfCycleArray_fixedPoint.push(ABDKMath64x64.div(ABDKMath64x64.fromUInt(_totalPercentAtEndOfCycles_18DecimalPrecision[i]), ABDKMath64x64.fromUInt(decimalFactor)));
                _distributionTable.cyclesArray.push(curCycle);
            } else {
                //cleanup in case of an error
                delete _distributionTable.totalPercentAtEndOfCycleArray_fixedPoint;
                delete _distributionTable.cyclesArray;

                break;
            }
        }

        //return results of calculation
        return (errorCode);
    }

    /// @param _distributionTableName The name of this distribution table.
    /// @param _vestEndSeconds When the vest ends in seconds.
    /// @param _cycles An array of "distributionCycle"-formatted cycles.
    /// @param _totalPercentAtEndOfCycles_18DecimalPrecision An array of the total percentage of distribution at the end of the cycles (cumulative).
    /// @dev Sets up a new distribution table with cycles and the total percentages of each cycle.
    /// @return success
    ///    | true = set new distribution table
    ///    | false = error in distribution table
    /// @return result
    ///    | [uint256] = (success) distribution table keccak hash for further reference (in uint256 format)
    ///    | 9 = (error) time period does not start immediately
    ///    | 8 = (error) time period didn't start as the previous ended
    ///    | 7 = (error) time period is higher than full vesting days
    ///    | 6 = (error) time period does not end on the full vesting day
    ///    | 5 = (error) allocation cycle does not equal 100%
    ///    | 4 = (error) allocation cycle has zero percentage
    ///    | 3 = (error) allocation cycles do not match
    ///    | 2 = (error) distribution table already exists
    ///    | 1 = (error) lengths of inputs do not match
    ///    | 0 = (error) not owner

    function setupDistributionTable(string memory _distributionTableName,
                                    uint256 _vestEndSeconds,
                                    distributionCycle[] memory _cycles,
                                    uint256[] memory _totalPercentAtEndOfCycles_18DecimalPrecision) public returns (bool success, uint256 result) {
        if (msg.sender == owner) {
            if (_cycles.length == _totalPercentAtEndOfCycles_18DecimalPrecision.length) {
                bytes32 distributionTableHash = keccak256(abi.encodePacked(_distributionTableName));

                distributionTable storage newDistributionTable = distributionHashToTableMapping[distributionTableHash];

                if (newDistributionTable.exists != true) {

                    (uint8 errorCode) = calculateDistributionTable(newDistributionTable, _vestEndSeconds, _cycles, _totalPercentAtEndOfCycles_18DecimalPrecision);

                    if (errorCode == 0) {
                        newDistributionTable.exists = true;

                        newDistributionTable.distributionTableName = _distributionTableName;

                        //set new distribution table
                        return (true, uint256(distributionTableHash));
                    } else {
                        //error in distribution table, return error code
                        return (false, errorCode);
                    }
                } else {
                    //distribution table already exists
                    return (false, 2);
                }
            } else {
                //lengths of inputs do not match
                return (false, 1);
            }
        } else {
            //not owner
            return (false, 0);
        }
    }

    /// @param _recipient The address of the recipient.
    /// @param _totalAllocated The total tokens allocated.
    /// @param _endCliffDays The end of the cliff (in days).
    /// @param _endVestingDays The end of the vesting (in days).
    /// @param _cutoffTokenAmount The amount of tokens that can be reduced from this allocation if triggered by the cutoff address.
    /// @param _cutoffAdminAddress The address of the actor responsible for performing the cutoff (reduction) of the token allocation.
    /// @param _distributionTableHash The hash of the distribution table that this allocation follows.
    /// @dev Sets the allocation for a specific recipient with cliff, vest, potential reduction if cutoff is triggered, and the distribution table hash. Also blocks recipients from being added twice (referencing the distribution table hash) as an additional precautionary measure.
    /// @return result should be "1" if all is processed successfully.

    function setAllocation( address _recipient,
                            uint256 _totalAllocated,
                            uint256 _endCliffDays,
                            uint256 _endVestingDays,
                            uint256 _cutoffTokenAmount,
                            address _cutoffAdminAddress,
                            bytes32 _distributionTableHash) public returns (uint8 result) {
        require(msg.sender == owner);
        require(_recipient != address(0));
        require(allocations[_recipient].distributionTableHash == bytes32(0));
        require(_totalAllocated <= INITIAL_SUPPLY);
        require(_totalAllocated >= _cutoffTokenAmount);
        require(_endCliffDays <= _endVestingDays);

        Allocation storage a = allocations[_recipient];
        a.endCliff = startTime.add(_endCliffDays.mul(1 days));
        a.endVesting = startTime.add(_endVestingDays.mul(1 days));
        a.totalAllocated = _totalAllocated;
        a.cutoffTokenAmount = _cutoffTokenAmount;
        a.cutoffAdminAddress = _cutoffAdminAddress;
        a.distributionTableHash = _distributionTableHash;

        emit EVT_newAllocation(_recipient, _totalAllocated, _endCliffDays, _endVestingDays, _cutoffTokenAmount, _cutoffAdminAddress, _distributionTableHash);

        return 1;
    }

    /// @param _amount The amount of tokens to send to the Shyft Core address.
    /// @dev An internal function to add cutoff tokens back to the Shyft Core token pool.
    function addCutoffTokensToCore(uint256 _amount) internal {
        if (transferTokenMode == true) {
            IShyftKycContractRegistry kycContractRegistry = IShyftKycContractRegistry(kycContractRegistryAddress);

            //@note: only transfers out to the first contract, which has a balance outstanding of the totality of the
            // distribution amount.

            IShyftKycContract kycContract = IShyftKycContract(kycContractRegistry.getContractAddressOfVersion(0));

            bool contractTxSuccess = kycContract.transfer(shyftCoreTokenAddress, _amount);

            // need to revert due to transactional logic.
            if (contractTxSuccess == false) {
                revert();
            }
        } else {
            // not limiting gas here so you can transfer to contracts etc.
            (bool nativeTxSuccess, ) = shyftCoreTokenAddress.call{value: _amount}("");

            // need to revert due to transactional logic.
            if (nativeTxSuccess == false) {
                revert();
            }
        }
    }

    /// @param _recipient The address of the recipient.
    /// @dev | Triggers the cutoff (reduction in allocation) for this recipient. This must be called by the address that has been specified previously to be the administrator for this recipient. If there are any tokens remaining from the distribution (total-cutoff) those are returned to the Shyft Core pool.
    ///      | The algorithm is: "remaining = (total - cutoff) - withdrawn", as long as "withdrawn" is lower than the newly cutoff allocation, otherwise it'll return how many tokens are over-allocated.
    /// @return result
    ///    | 3 = set the cutoff for this recipient, still has distribution
    ///    | 2 = set the cutoff for this recipient, was over already over-allocated
    ///    | 1 = cutoff already triggered
    ///    | 0 = not the cutoff admin address designated for this recipient
    /// @return distributionFound if triggered, will return the remaining distribution

    function triggerCutoff(address _recipient) public returns (uint8 result, uint256 distributionFound) {
        if (allocations[_recipient].cutoffEnabled == false) {
            if (msg.sender == allocations[_recipient].cutoffAdminAddress) {
                allocations[_recipient].cutoffEnabled = true;

                uint256 modifiedAllocation = allocations[_recipient].totalAllocated.sub(allocations[_recipient].cutoffTokenAmount);

                if (allocations[_recipient].amountClaimed < modifiedAllocation) {
                    // gets under-allocated distribution
                    //
                    // scenario: user has claimed 600 of 1000 tokens already, with a 10% cutoff.
                    // cutoff reduced them to 900 tokens total. so return an under-allocated (900 - 600) amount.
                    //
                    // to calculate the tokens that should be returned to the shyft core treasury that handles cutoff
                    // tokens, we:
                    //
                    // 1. take the total amount minus the cutoff, which gives us the modified allocation.
                    // 2. we know that the tokens distributed already lower than this modified allocation.
                    // 3. we know that there will be further distributions to this user.
                    // 4. therefore the tokens returned to the shyft treasury would be: "modified allocation - claimed"

                    uint256 remainingAvailableDistribution = modifiedAllocation.sub(allocations[_recipient].amountClaimed);

                    uint256 tokensToReturnToCore = allocations[_recipient].cutoffTokenAmount;
                    addCutoffTokensToCore(tokensToReturnToCore);

                    emit EVT_cutoffTriggered(_recipient, modifiedAllocation, allocations[_recipient].amountClaimed, remainingAvailableDistribution, tokensToReturnToCore);

                    //set the cutoff for this recipient, still has distribution
                    return (3, remainingAvailableDistribution);
                } else {
                    // gets over-allocated distribution
                    //
                    // scenario: user has claimed 600 of 1000 tokens already, with a 50% cutoff.
                    // cutoff reduced them to 500 tokens total. so return an over-allocated (600 - 500) amount.
                    //
                    // to calculate the tokens that should be returned to the shyft core treasury that handles cutoff
                    // tokens, we:
                    // 1. take the total amount minus the cutoff, which gives us the modified allocation.
                    // 2. we know that the tokens distributed already are higher than this modified allocation.
                    // 3. we know that there will be no further distribution to this user.
                    // 4. therefore the tokens returned to the shyft treasury would be: "total - claimed"

                    uint256 overAllocatedDistribution = allocations[_recipient].amountClaimed.sub(modifiedAllocation);

                    uint256 tokensToReturnToCore = allocations[_recipient].totalAllocated.sub(allocations[_recipient].amountClaimed);
                    addCutoffTokensToCore(tokensToReturnToCore);

                    emit EVT_cutoffTriggeredOverAllocated(_recipient, modifiedAllocation, allocations[_recipient].amountClaimed, overAllocatedDistribution, tokensToReturnToCore);

                    //set the cutoff for this recipient, was over already over-allocated
                    return (2, overAllocatedDistribution);
                }
            } else {
                //cutoff already triggered
                return (1, 0);
            }
        } else {
            //not the cutoff admin address designated for this recipient
            return (0, 0);
        }
    }


    /// @param _recipient The address of the recipient.
    /// @param _currentDistributionTime The distribution time to calculate the cycle with.
    /// @dev Gets the current cycle number for the recipient at the specified distribution time.
    /// @return curCycle the current distribution cycle for this recipient at the specified distribution time.

    function getCurrentCycleNumber(address _recipient, uint256 _currentDistributionTime) public view returns(uint256 curCycle) {
        uint256 foundCycle = 0;

        distributionTable storage distTable = distributionHashToTableMapping[allocations[_recipient].distributionTableHash];

        // check whether the last cycle has already ended.
        if (distTable.cyclesArray[distTable.cyclesArray.length - 1].timePeriodEnd < _currentDistributionTime) {
            return distTable.cyclesArray.length - 1;
        } else {
            for (uint256 i = 0; i < distTable.cyclesArray.length; i++) {
                bool distributionCycleMatches = (distTable.cyclesArray[i].timePeriodStart < _currentDistributionTime &&
                                                 distTable.cyclesArray[i].timePeriodEnd >= _currentDistributionTime);

                if (distributionCycleMatches == true) {
                    foundCycle = i;
                    break;
                }
            }
        }

        return foundCycle;
    }

    /// @param _recipient The address of the recipient.
    /// @param _timePeriodStart The start of the time period to calculate.
    /// @param _timePeriodEnd The end of the time period to calculate.
    /// @param _percentTokens_fixedPoint The percentage (in 64.64 floating point format).
    /// @param _prevCyclesPercent The previous cycle's percentage (cumulative for all previous cycles).
    /// @param _referenceTime The reference time for the calculation.
    /// @dev An internal function to help calculate the new total to be able to be claimed.
    /// @return result the new total claimed

    function calculateNewTotal(address _recipient, uint256 _timePeriodStart, uint256 _timePeriodEnd, int128 _percentTokens_fixedPoint, int128 _prevCyclesPercent, uint256 _referenceTime) internal view returns(uint256 result) {
        int128 curCyclePercent = ABDKMath64x64.divi(int256(((_referenceTime.sub(allocations[_recipient].endCliff).sub(_timePeriodStart)))), int256(_timePeriodEnd.sub(_timePeriodStart)));

        int128 totalPercentOfUsersTokens = ABDKMath64x64.add(_prevCyclesPercent, ABDKMath64x64.mul(_percentTokens_fixedPoint, curCyclePercent));

        uint256 tokensAllocated = allocations[_recipient].totalAllocated;

        if (allocations[_recipient].cutoffEnabled == true) {
            tokensAllocated = tokensAllocated.sub(allocations[_recipient].cutoffTokenAmount);
        }

        bytes16 quadFrom64x64TotalPercentOfUsersTokens = ABDKMathQuad.from64x64(totalPercentOfUsersTokens);

        //@note: algo: newTotal = (_recipient's) totalAllocated * (_percentTokens_fixedPoint * (_prevCyclesPercent + curCyclePercent))
        uint256 newTotalClaimed = ABDKMathQuad.toUInt(ABDKMathQuad.mul(ABDKMathQuad.fromUInt(tokensAllocated), quadFrom64x64TotalPercentOfUsersTokens));

        //the new total claimed
        return newTotalClaimed;
    }

    /// @param _recipient The address of the recipient.
    /// @param _referenceTime The reference time for the calculation.
    /// @dev Gets the tokens available to be claimed for this recipient.
    /// @return result
    ///    | 3 = got tokens claimed
    ///    | 2 = already claimed all tokens possible thus far (requires more time to pass)
    ///    | 1 = already claimed all tokens possible
    ///    | 0 = block timestamp invalid
    /// @return tokensTransferred the amount of tokens transferred (in total, including previously claimed tokens)
    /// @return tokensReceived the amount of tokens received (total tokens - previously claimed)
    /// @return currentCycleNumber the current distribution cycle number for this recipient

    function getTokensAvailable(address _recipient, uint256 _referenceTime) public view returns (uint8 result, uint256 tokensTransferred, uint256 tokensReceived, uint256 currentCycleNumber) {
        if (_referenceTime > allocations[_recipient].endCliff) {
            uint256 tokensAllocated = allocations[_recipient].totalAllocated;

            if (allocations[_recipient].cutoffEnabled == true) {
                tokensAllocated = tokensAllocated.sub(allocations[_recipient].cutoffTokenAmount);
            }

            if (allocations[_recipient].amountClaimed < tokensAllocated) {
                uint256 newTotalClaimed;
                uint256 cycleNumber;

                //check whether the reference time is above the cliff + vest period, if so the calculations are simpler
                if (_referenceTime > allocations[_recipient].endVesting) {
                    newTotalClaimed = tokensAllocated.sub(allocations[_recipient].amountClaimed);

                    //it's the last cycle
                    distributionTable storage distTable = distributionHashToTableMapping[allocations[_recipient].distributionTableHash];
                    cycleNumber = distTable.cyclesArray.length - 1;
                } else {
                    // from start of cliff
                    cycleNumber = getCurrentCycleNumber(_recipient, _referenceTime.sub(allocations[_recipient].endCliff));

                    //default to zero percent for the first cycle
                    int128 prevCyclesPercent = 0;

                    distributionCycle storage curCycle = distributionHashToTableMapping[allocations[_recipient].distributionTableHash].cyclesArray[cycleNumber];

                    // integrate the previous total percents if cycleNumber > 0
                    if (cycleNumber > 0) {
                        prevCyclesPercent = distributionHashToTableMapping[allocations[_recipient].distributionTableHash].totalPercentAtEndOfCycleArray_fixedPoint[cycleNumber - 1];
                    }

                    newTotalClaimed = calculateNewTotal(_recipient, curCycle.timePeriodStart, curCycle.timePeriodEnd, curCycle.percentTokens_fixedPoint, prevCyclesPercent, _referenceTime);
                }

                // check whether the new total to be claimed is higher than the current amount claimed (can occur with cutoffs)
                if (newTotalClaimed > allocations[_recipient].amountClaimed) {
                    //got tokens claimed
                    return (3, newTotalClaimed, newTotalClaimed.sub(allocations[_recipient].amountClaimed), cycleNumber);
                } else {
                    //already claimed all tokens possible thus far (requires more time to pass)
                    return (2, newTotalClaimed, 0, cycleNumber);
                }
            } else {
                //already claimed all tokens possible
                return (1, 0, 0, 0);
            }
        } else {
            //block timestamp invalid
            return (0, 0, 0, 0);
        }
    }

    /// @param _recipient The address of the recipient.
    /// @dev Allows a user to claim their allocated tokens. *Any* address can perform the claim on *any* recipient for the purposes of abstracting the gas cost for those recipients (ie an external party can pay for the gas of the claim function, for their client).
    /// @notice In any case where there has been an attempt to transfer tokens, this function will revert() if there is an error in the sending/claiming process.
    /// @return success
    ///    | true = claimed tokens successfully
    ///    | false = error in sending, or preconditions not met (see "result")
    /// @return result
    ///    | (any number) = (success) the number of tokens that have been claimed
    ///    | 3 = (error) already claimed all available tokens from entire vesting period
    ///    | 2 = (error) block timestamp is lower than cliff
    ///    | 1 = (error) already claimed all tokens possible thus far (requires more time to pass)
    ///    | 0 = (error) could not get tokens allocated
    /// @return timeStamp the current block timestamp

    function claimTokens(address _recipient) public returns (bool success, uint256 result, uint256 timeStamp) {
        uint256 tokensAllocated = allocations[_recipient].totalAllocated;

        if (allocations[_recipient].cutoffEnabled == true) {
            tokensAllocated = tokensAllocated.sub(allocations[_recipient].cutoffTokenAmount);
        }

        if (allocations[_recipient].amountClaimed >= tokensAllocated) {
            //already claimed all available tokens from entire vesting period
            return (false, 3, 0);
        }

        if (block.timestamp < allocations[_recipient].endCliff) {
            //block timestamp is lower than cliff
            return (false, 2, 0);
        }

        require(block.timestamp >= startTime);

        // Calculate new claimed amounts
        uint256 newTotalClaimed;
        if (allocations[_recipient].endVesting > block.timestamp) {
            // get tokens available for distribution (including already allocated ones).
            (uint8 getTokensResult, uint256 tokensAvailable, , ) = getTokensAvailable(_recipient, block.timestamp);

            if (getTokensResult != 3) {
                if (getTokensResult == 2) {
                    //already claimed all tokens possible thus far (requires more time to pass)
                    return (false, 1, 0);
                } else {
                    //could not get tokens allocated
                    return (false, 0, 0);
                }
            } else {
                newTotalClaimed = tokensAvailable;
            }

        } else {
            // Transfer the total amount less previously claimed tokens
            newTotalClaimed = tokensAllocated;
        }

        // Amount to be transferred
        uint256 transferAmount = newTotalClaimed.sub(allocations[_recipient].amountClaimed);

        // Update allocations once transfer completed
        allocations[_recipient].amountClaimed = newTotalClaimed;

        totalClaimed = totalClaimed.add(transferAmount);

        if (transferTokenMode == true) {
            IShyftKycContractRegistry kycContractRegistry = IShyftKycContractRegistry(kycContractRegistryAddress);

            //@note: only transfers out to the first contract, which has a balance outstanding of the totality of the
            // distribution amount.

            IShyftKycContract kycContract = IShyftKycContract(kycContractRegistry.getContractAddressOfVersion(0));

            bool contractTxSuccess = kycContract.transfer(_recipient, transferAmount);

            // need to revert due to transactional logic.
            if (contractTxSuccess == false) {
                revert();
            }
        } else {
            // not limiting gas here so you can transfer to contracts etc.
            (bool nativeTxSuccess, ) = _recipient.call{value: transferAmount}("");

            // need to revert due to transactional logic.
            if (nativeTxSuccess == false) {
                revert();
            }
        }

        emit EVT_shyftClaimed(_recipient, transferAmount, newTotalClaimed, totalClaimed, block.timestamp);

        //claimed tokens successfully
        return (true, transferAmount, block.timestamp);
    }

    /// @param _address The address of the KYC contract registry.
    /// @dev Sets the KYC contract registry address so that (in the case where this is a token vs native fuel distribution) the claim process can correctly identify the contract it is distributing to.
    /// @return result
    ///    | true = set registry contract successfully
    ///    | false = has already been set, or not the owner

    function setKycContractRegistryAddress(address _address) public returns (bool result) {
        if (kycContractRegistryAddress == address(0) && msg.sender == owner) {
            kycContractRegistryAddress = _address;

            //set registry contract successfully
            return true;
        } else {

            //has already been set, or not the owner
            return false;
        }
    }

    /// @param _address The address of the Shyft Core token address.
    /// @dev Sets the Shyft Core token address so that any cutoff tokens are properly allocated back to a Shyft Core wallet.
    /// @return result
    ///    | true = set shyft core token address successfully
    ///    | false = has already been set, or not the owner

    function setShyftCoreTokenAddress(address payable _address) public returns (bool result) {
        if (shyftCoreTokenAddress == address(0) && msg.sender == owner) {
            shyftCoreTokenAddress = _address;

            //set shyft core token address successfully
            return true;
        } else {

            //has already been set, or not the owner
            return false;
        }
    }

    /// @dev Disables the ability of the Owner (initial deployer) of this contract to set any new allocations. The call can only be completed correctly by the Owner.
    /// @return result
    ///    | true = completed disabling new allocations
    ///    | false = not owner

    function disableSettingNewAllocations() public returns (bool result) {
        if (msg.sender == owner) {
            owner = address(0);

            // completed disabling new allocations
            return true;
        } else {
            // not owner
            return false;
        }
    }
}