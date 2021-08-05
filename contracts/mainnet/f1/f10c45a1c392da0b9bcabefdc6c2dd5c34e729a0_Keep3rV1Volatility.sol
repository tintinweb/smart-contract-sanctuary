/**
 *Submitted for verification at Etherscan.io on 2020-11-16
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

interface IKeep3rV1Oracle {
    function sample(address tokenIn, uint amountIn, address tokenOut, uint points, uint window) external view returns (uint[] memory);
}

interface IERC20 {
    function decimals() external view returns (uint);
}

contract Keep3rV1Volatility {
    
    uint private constant FIXED_1 = 0x080000000000000000000000000000000;
    uint private constant FIXED_2 = 0x100000000000000000000000000000000;
    uint private constant SQRT_1 = 13043817825332782212;
    uint private constant LOG_10_2 = 3010299957;
    uint private constant BASE = 1e10;
    
    IKeep3rV1Oracle public constant KV1O = IKeep3rV1Oracle(0x73353801921417F465377c8d898c6f4C0270282C);

    function floorLog2(uint256 _n) internal pure returns (uint8) {
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
    
    function generalLog(uint256 x) internal pure returns (uint) {
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
    
    function sqrt(uint x) internal pure returns (uint y) {
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