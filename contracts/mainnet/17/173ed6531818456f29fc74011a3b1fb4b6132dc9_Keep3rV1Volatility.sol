/**
 *Submitted for verification at Etherscan.io on 2021-02-07
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

interface IKeep3rV1Oracle {
    function sample(address tokenIn, uint amountIn, address tokenOut, uint points, uint window) external view returns (uint[] memory);
    function current(address tokenIn, uint amountIn, address tokenOut) external view returns (uint amountOut);
}

interface IERC20 {
    function decimals() external view returns (uint);
}

contract Keep3rV1Volatility {
    
    uint private constant FIXED_1 = 0x080000000000000000000000000000000;
    uint private constant FIXED_2 = 0x100000000000000000000000000000000;
    uint private constant SQRT_1 = 13043817825332782212;
    uint private constant LNX = 3988425491;
    uint private constant LOG_10_2 = 3010299957;
    uint private constant LOG_E_2 = 6931471806;
    uint private constant BASE = 1e10;
    
    IKeep3rV1Oracle public constant KV1O = IKeep3rV1Oracle(0xf67Ab1c914deE06Ba0F264031885Ea7B276a7cDa);
    address public constant WETH = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    function floorLog2(uint256 _n) public pure returns (uint8) {
        uint8 res = 0;

        if (_n < 256) {
            // At most 8 iterations
            while (_n > 1) {
                _n >>= 1;
                res += 1;
            }
        } else {
            // Exactly 8 iterations
            for (uint8 s = 128; s > 0; s >>= 1) {
                if (_n >= (uint(1) << s)) {
                    _n >>= s;
                    res |= s;
                }
            }
        }

        return res;
    }
    
    function ln(uint256 x) public pure returns (uint) {
        uint res = 0;

        // If x >= 2, then we compute the integer part of log2(x), which is larger than 0.
        if (x >= FIXED_2) {
            uint8 count = floorLog2(x / FIXED_1);
            x >>= count; // now x < 2
            res = count * FIXED_1;
        }

        // If x > 1, then we compute the fraction part of log2(x), which is larger than 0.
        if (x > FIXED_1) {
            for (uint8 i = 127; i > 0; --i) {
                x = (x * x) / FIXED_1; // now 1 < x < 4
                if (x >= FIXED_2) {
                    x >>= 1; // now 1 < x < 2
                    res += uint(1) << (i - 1);
                }
            }
        }

        return res * LOG_E_2 / BASE;
    }
    
    /**
     * @dev computes e ^ (x / FIXED_1) * FIXED_1
     * input range: 0 <= x <= OPT_EXP_MAX_VAL - 1
     * auto-generated via 'PrintFunctionOptimalExp.py'
     * Detailed description:
     * - Rewrite the input as a sum of binary exponents and a single residual r, as small as possible
     * - The exponentiation of each binary exponent is given (pre-calculated)
     * - The exponentiation of r is calculated via Taylor series for e^x, where x = r
     * - The exponentiation of the input is calculated by multiplying the intermediate results above
     * - For example: e^5.521692859 = e^(4 + 1 + 0.5 + 0.021692859) = e^4 * e^1 * e^0.5 * e^0.021692859
     */
    function optimalExp(uint256 x) public pure returns (uint256) {
        uint256 res = 0;

        uint256 y;
        uint256 z;

        z = y = x % 0x10000000000000000000000000000000; // get the input modulo 2^(-3)
        z = (z * y) / FIXED_1;
        res += z * 0x10e1b3be415a0000; // add y^02 * (20! / 02!)
        z = (z * y) / FIXED_1;
        res += z * 0x05a0913f6b1e0000; // add y^03 * (20! / 03!)
        z = (z * y) / FIXED_1;
        res += z * 0x0168244fdac78000; // add y^04 * (20! / 04!)
        z = (z * y) / FIXED_1;
        res += z * 0x004807432bc18000; // add y^05 * (20! / 05!)
        z = (z * y) / FIXED_1;
        res += z * 0x000c0135dca04000; // add y^06 * (20! / 06!)
        z = (z * y) / FIXED_1;
        res += z * 0x0001b707b1cdc000; // add y^07 * (20! / 07!)
        z = (z * y) / FIXED_1;
        res += z * 0x000036e0f639b800; // add y^08 * (20! / 08!)
        z = (z * y) / FIXED_1;
        res += z * 0x00000618fee9f800; // add y^09 * (20! / 09!)
        z = (z * y) / FIXED_1;
        res += z * 0x0000009c197dcc00; // add y^10 * (20! / 10!)
        z = (z * y) / FIXED_1;
        res += z * 0x0000000e30dce400; // add y^11 * (20! / 11!)
        z = (z * y) / FIXED_1;
        res += z * 0x000000012ebd1300; // add y^12 * (20! / 12!)
        z = (z * y) / FIXED_1;
        res += z * 0x0000000017499f00; // add y^13 * (20! / 13!)
        z = (z * y) / FIXED_1;
        res += z * 0x0000000001a9d480; // add y^14 * (20! / 14!)
        z = (z * y) / FIXED_1;
        res += z * 0x00000000001c6380; // add y^15 * (20! / 15!)
        z = (z * y) / FIXED_1;
        res += z * 0x000000000001c638; // add y^16 * (20! / 16!)
        z = (z * y) / FIXED_1;
        res += z * 0x0000000000001ab8; // add y^17 * (20! / 17!)
        z = (z * y) / FIXED_1;
        res += z * 0x000000000000017c; // add y^18 * (20! / 18!)
        z = (z * y) / FIXED_1;
        res += z * 0x0000000000000014; // add y^19 * (20! / 19!)
        z = (z * y) / FIXED_1;
        res += z * 0x0000000000000001; // add y^20 * (20! / 20!)
        res = res / 0x21c3677c82b40000 + y + FIXED_1; // divide by 20! and then add y^1 / 1! + y^0 / 0!

        if ((x & 0x010000000000000000000000000000000) != 0)
            res = (res * 0x1c3d6a24ed82218787d624d3e5eba95f9) / 0x18ebef9eac820ae8682b9793ac6d1e776; // multiply by e^2^(-3)
        if ((x & 0x020000000000000000000000000000000) != 0)
            res = (res * 0x18ebef9eac820ae8682b9793ac6d1e778) / 0x1368b2fc6f9609fe7aceb46aa619baed4; // multiply by e^2^(-2)
        if ((x & 0x040000000000000000000000000000000) != 0)
            res = (res * 0x1368b2fc6f9609fe7aceb46aa619baed5) / 0x0bc5ab1b16779be3575bd8f0520a9f21f; // multiply by e^2^(-1)
        if ((x & 0x080000000000000000000000000000000) != 0)
            res = (res * 0x0bc5ab1b16779be3575bd8f0520a9f21e) / 0x0454aaa8efe072e7f6ddbab84b40a55c9; // multiply by e^2^(+0)
        if ((x & 0x100000000000000000000000000000000) != 0)
            res = (res * 0x0454aaa8efe072e7f6ddbab84b40a55c5) / 0x00960aadc109e7a3bf4578099615711ea; // multiply by e^2^(+1)
        if ((x & 0x200000000000000000000000000000000) != 0)
            res = (res * 0x00960aadc109e7a3bf4578099615711d7) / 0x0002bf84208204f5977f9a8cf01fdce3d; // multiply by e^2^(+2)
        if ((x & 0x400000000000000000000000000000000) != 0)
            res = (res * 0x0002bf84208204f5977f9a8cf01fdc307) / 0x0000003c6ab775dd0b95b4cbee7e65d11; // multiply by e^2^(+3)

        return res;
    }
    
    function quote(address tokenIn, address tokenOut, uint t) public view returns (uint call, uint put) {
        uint _price = price(tokenIn, tokenOut);
        return quotePrice(tokenIn, tokenIn == WETH ? tokenOut : WETH, t, _price, _price);
    }
    
    function price(address tokenIn, address tokenOut) public view returns (uint) {
        if (tokenIn == WETH) {
            return KV1O.current(WETH, 1e18, tokenOut);
        } else {
            uint _weth = KV1O.current(tokenIn, uint(10)**IERC20(tokenIn).decimals(), WETH);
            if (tokenOut == WETH) {
                return _weth;
            } else {
                return KV1O.current(WETH, _weth, tokenOut);
            }
        }
    }
    
    function quotePrice(address tokenIn, address tokenOut, uint t, uint sp, uint st) public view returns (uint call, uint put) {
        uint v = rVol(tokenIn, tokenOut, 4, 24);
        return quoteAll(t, v, sp, st);
    }
    
    function quoteAll(uint t, uint v, uint sp, uint st) public pure returns (uint call, uint put) {
        uint _c;
        uint _p;
        
        if (sp > st) {
            _c = C(t, v, sp, st);
            _p = st-sp+_c;
        } else {
            _p = C(t, v, st, sp);
            _c = st-sp+_p;
        }
        return (_c, _p);
    }
	
	function C(uint t, uint v, uint sp, uint st) public pure returns (uint) {
	    if (sp == st) {
	        return LNX * sp / 1e10 * v / 1e18 * sqrt(1e18 * t / 365) / 1e9;
	    }
	    uint sigma = ((v**2)/2);
        uint sigmaB = 1e36;
        
        uint sig = 1e18 * sigma / sigmaB * t / 365;
        
        uint sSQRT = v * sqrt(1e18 * t / 365) / 1e9;
        
        uint d1 = 1e18 * ln(FIXED_1 * sp / st) / FIXED_1;
        d1 = (d1 + sig) * 1e18 / sSQRT;
        uint d2 = d1 - sSQRT;
        
        uint cdfD1 = ncdf(FIXED_1 * d1 / 1e18);
        uint cdfD2 = cdf(int(FIXED_1) * int(d2) / 1e18);
        
        return sp * cdfD1 / 1e14 - st * cdfD2 / 1e14;
	}
    
    function ncdf(uint x) public pure returns (uint) {
        int t1 = int(1e7 + (2315419 * x / FIXED_1));
        uint exp = x / 2 * x / FIXED_1;
        int d = int(3989423 * FIXED_1 / optimalExp(uint(exp)));
        uint prob = uint(d * (3193815 + ( -3565638 + (17814780 + (-18212560 + 13302740 * 1e7 / t1) * 1e7 / t1) * 1e7 / t1) * 1e7 / t1) * 1e7 / t1);
        if( x > 0 ) prob = 1e14 - prob;
        return prob;
    }

    /**
     * @notice Takes the absolute value of a given number
     * @dev Helper function
     * @param _number The specified number
     * @return The absolute value of the number
     */
    function abs(int256 _number) public pure returns (uint256) {
        return _number < 0 ? uint256(_number * (-1)) : uint256(_number);
    }
    
    function cdf(int x) public pure returns (uint) {
        int t1 = int(1e7 + int(2315419 * abs(x) / FIXED_1));
        uint exp = uint(x / 2 * x) / FIXED_1;
        int d = int(3989423 * FIXED_1 / optimalExp(uint(exp)));
        uint prob = uint(d * (3193815 + ( -3565638 + (17814780 + (-18212560 + 13302740 * 1e7 / t1) * 1e7 / t1) * 1e7 / t1) * 1e7 / t1) * 1e7 / t1);
        if( x > 0 ) prob = 1e14 - prob;
        return prob;
    }
    
    function generalLog(uint256 x) public pure returns (uint) {
        uint res = 0;

        // If x >= 2, then we compute the integer part of log2(x), which is larger than 0.
        if (x >= FIXED_2) {
            uint8 count = floorLog2(x / FIXED_1);
            x >>= count; // now x < 2
            res = count * FIXED_1;
        }

        // If x > 1, then we compute the fraction part of log2(x), which is larger than 0.
        if (x > FIXED_1) {
            for (uint8 i = 127; i > 0; --i) {
                x = (x * x) / FIXED_1; // now 1 < x < 4
                if (x >= FIXED_2) {
                    x >>= 1; // now 1 < x < 2
                    res += uint(1) << (i - 1);
                }
            }
        }

        return res * LOG_10_2 / BASE;
    }
    
    function sqrt(uint x) public pure returns (uint y) {
        uint z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }
    
    function vol(uint[] memory p) public pure returns (uint x) {
        for (uint8 i = 1; i <= (p.length-1); i++) {
            x += ((generalLog(p[i] * FIXED_1) - generalLog(p[i-1] * FIXED_1)))**2;
            //denom += FIXED_1**2;
        }
        //return (sum, denom);
        x = sqrt(uint(252) * sqrt(x / (p.length-1)));
        return uint(1e18) * x / SQRT_1;
    }
    
    function rVol(address tokenIn, address tokenOut, uint points, uint window) public view returns (uint) {
        return vol(KV1O.sample(tokenIn, uint(10)**IERC20(tokenIn).decimals(), tokenOut, points, window));
    }
    
    function rVolHourly(address tokenIn, address tokenOut, uint points) external view returns (uint) {
        return rVol(tokenIn, tokenOut, points, 2);
    }
    
    function rVolDaily(address tokenIn, address tokenOut, uint points) external view returns (uint) {
        return rVol(tokenIn, tokenOut, points, 48);
    }
    
    function rVolWeekly(address tokenIn, address tokenOut, uint points) external view returns (uint) {
        return rVol(tokenIn, tokenOut, points, 336);
    }
    
    function rVolHourlyRecent(address tokenIn, address tokenOut) external view returns (uint) {
        return rVol(tokenIn, tokenOut, 2, 2);
    }
    
    function rVolDailyRecent(address tokenIn, address tokenOut) external view returns (uint) {
        return rVol(tokenIn, tokenOut, 2, 48);
    }
    
    function rVolWeeklyRecent(address tokenIn, address tokenOut) external view returns (uint) {
        return rVol(tokenIn, tokenOut, 2, 336);
    }
}