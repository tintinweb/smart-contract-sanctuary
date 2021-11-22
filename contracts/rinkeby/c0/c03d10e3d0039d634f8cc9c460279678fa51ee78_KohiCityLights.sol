/**
 *Submitted for verification at Etherscan.io on 2021-11-22
*/

// Sources flattened with hardhat v2.6.8 https://hardhat.org

// File @openzeppelin/contracts/utils/[email protected]

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

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
        assembly {
            size := extcodesize(account)
        }
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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


// File @openzeppelin/contracts/utils/[email protected]

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}


// File contracts/V1/MathV1.sol

/* Copyright (c) 2021 Kohi Art Community, Inc. All rights reserved. */

pragma solidity ^0.8.0;

library MathV1 {
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a >= b ? a : b;
    }

    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    function max3(
        int256 a,
        int256 b,
        int256 c
    ) internal pure returns (int256) {
        int256 d = b >= c ? b : c;
        return a >= d ? a : d;
    }

    function min3(
        int256 a,
        int256 b,
        int256 c
    ) internal pure returns (int256) {
        int256 d = b < c ? b : c;
        return a < d ? a : d;
    }

    function abs(int256 x) internal pure returns (int256) {
        return x >= 0 ? x : -x;
    }

    function sign(int256 x) internal pure returns (int8) {
        return x == 0 ? int8(0) : x > 0 ? int8(1) : int8(-1);
    }
}


// File contracts/V1/Fix64V1.sol

/* Copyright (c) 2021 Kohi Art Community, Inc. All rights reserved. */

pragma solidity ^0.8.0;
/*
    Provides mathematical operations and representation in Q31.Q32 format.

    exp: Adapted from Petteri Aimonen's libfixmath
    
    See: https://github.com/PetteriAimonen/libfixmath
         https://github.com/PetteriAimonen/libfixmath/blob/master/LICENSE

    other functions: Adapted from Andr├⌐ Slupik's FixedMath.NET
                     https://github.com/asik/FixedMath.Net/blob/master/LICENSE.txt
         
    THIRD PARTY NOTICES:
    ====================

    libfixmath is Copyright (c) 2011-2021 Flatmush <[email protected]>,
    Petteri Aimonen <[email protected]>, & libfixmath AUTHORS

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE.

    Copyright 2012 Andr├⌐ Slupik

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    This project uses code from the log2fix library, which is under the following license:           
    The MIT License (MIT)

    Copyright (c) 2015 Dan Moulding
    
    Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), 
    to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, 
    and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
    
    The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
    IN THE SOFTWARE.
*/

library Fix64V1 {
    int64 public constant FRACTIONAL_PLACES = 32;
    int64 public constant ONE = 4294967296; // 1 << FRACTIONAL_PLACES
    int64 public constant TWO = ONE * 2;
    int64 public constant PI = 0x3243F6A88;
    int64 public constant TWO_PI = 0x6487ED511;
    int64 public constant MAX_VALUE = type(int64).max;
    int64 public constant MIN_VALUE = type(int64).min;
    int64 public constant PI_OVER_2 = 0x1921FB544;

    function countLeadingZeros(uint64 x) internal pure returns (int64) {        
        int64 result = 0;
        while ((x & 0xF000000000000000) == 0) {
            result += 4;
            x <<= 4;
        }
        while ((x & 0x8000000000000000) == 0) {
            result += 1;
            x <<= 1;
        }
        return result;
    }

    function div(int64 x, int64 y)
        internal
        pure
        returns (int64)
    {
        if (y == 0) {
            revert("attempted to divide by zero");
        }

        int64 xl = x;
        int64 yl = y;        

        uint64 remainder = uint64(xl >= 0 ? xl : -xl);
        uint64 divider = uint64((yl >= 0 ? yl : -yl));
        uint64 quotient = 0;
        int64 bitPos = 64 / 2 + 1;

        while ((divider & 0xF) == 0 && bitPos >= 4) {
            divider >>= 4;
            bitPos -= 4;
        }

        while (remainder != 0 && bitPos >= 0) {
            int64 shift = countLeadingZeros(remainder);
            if (shift > bitPos) {
                shift = bitPos;
            }
            remainder <<= uint64(shift);
            bitPos -= shift;

            uint64 d = remainder / divider;
            remainder = remainder % divider;
            quotient += d << uint64(bitPos);

            if ((d & ~(uint64(0xFFFFFFFFFFFFFFFF) >> uint64(bitPos)) != 0)) {
                return
                    ((xl ^ yl) & MIN_VALUE) == 0
                        ? MAX_VALUE
                        : MIN_VALUE;
            }

            remainder <<= 1;
            --bitPos;
        }

        ++quotient;
        int64 result = int64(quotient >> 1);
        if (((xl ^ yl) & MIN_VALUE) != 0) {
            result = -result;
        }

        return int64(result);
    }

    function mul(int64 x, int64 y)
        internal
        pure
        returns (int64)
    {
        int64 xl = x;
        int64 yl = y;

        uint64 xlo = (uint64)((xl & (int64)(0x00000000FFFFFFFF)));
        int64 xhi = xl >> 32; // FRACTIONAL_PLACES
        uint64 ylo = (uint64)(yl & (int64)(0x00000000FFFFFFFF));
        int64 yhi = yl >> 32; // FRACTIONAL_PLACES

        uint64 lolo = xlo * ylo;
        int64 lohi = int64(xlo) * yhi;
        int64 hilo = xhi * int64(ylo);
        int64 hihi = xhi * yhi;

        uint64 loResult = lolo >> 32; // FRACTIONAL_PLACES
        int64 midResult1 = lohi;
        int64 midResult2 = hilo;
        int64 hiResult = hihi << 32; // FRACTIONAL_PLACES

        int64 sum = int64(loResult) + midResult1 + midResult2 + hiResult;

        return int64(sum);
    }

    function mul_256(int x, int y)
        internal
        pure
        returns (int)
    {
        int xl = x;
        int yl = y;

        uint xlo = uint((xl & int(0x00000000FFFFFFFF)));
        int xhi = xl >> 32; // FRACTIONAL_PLACES
        uint ylo = uint(yl & int(0x00000000FFFFFFFF));
        int yhi = yl >> 32; // FRACTIONAL_PLACES

        uint lolo = xlo * ylo;
        int lohi = int(xlo) * yhi;
        int hilo = xhi * int(ylo);
        int hihi = xhi * yhi;

        uint loResult = lolo >> 32; // FRACTIONAL_PLACES
        int midResult1 = lohi;
        int midResult2 = hilo;
        int hiResult = hihi << 32; // FRACTIONAL_PLACES

        int sum = int(loResult) + midResult1 + midResult2 + hiResult;

        return sum;
    }

    function floor(int x) internal pure returns (int64) {
        return int64(x & 0xFFFFFFFF00000000);
    }

    function round(int x) internal pure returns (int) {
        int fractionalPart = x & 0x00000000FFFFFFFF;
        int integralPart = floor(x);
        if (fractionalPart < 0x80000000) return integralPart;
        if (fractionalPart > 0x80000000) return integralPart + ONE;
        if ((integralPart & ONE) == 0) return integralPart;
        return integralPart + ONE;
    }

    function sub(int64 x, int64 y)
        internal
        pure
        returns (int64)
    {
        int64 xl = x;
        int64 yl = y;
        int64 diff = xl - yl;
        if (((xl ^ yl) & (xl ^ diff) & MIN_VALUE) != 0) diff = xl < 0 ? MIN_VALUE : MAX_VALUE;
        return diff;
    }

    function add(int64 x, int64 y)
        internal
        pure
        returns (int64)
    {
        int64 xl = x;
        int64 yl = y;
        int64 sum = xl + yl;
        if ((~(xl ^ yl) & (xl ^ sum) & MIN_VALUE) != 0) sum = xl > 0 ? MAX_VALUE : MIN_VALUE;
        return sum;
    }

    function sign(int64 x) internal pure returns (int8) {
        return x == int8(0) ? int8(0) : x > int8(0) ? int8(1) : int8(-1);
    }

    function abs(int64 x) internal pure returns (int64) {
        int64 mask = x >> 63;
        return (x + mask) ^ mask;
    }
}


// File contracts/V1/SinLut256.sol

/* Copyright (c) 2021 Kohi Art Community Inc. All rights reserved. */

pragma solidity ^0.8.0;

library SinLut256 {
    /**
     * @notice Lookup tables for computing the sine value for a given angle.
     * @param i The clamped and rounded angle integral to index into the table.
     * @return The sine value in fixed-point (Q31.32) space.
     */
    function sinlut(int256 i) external pure returns (int64) {
        if (i <= 127) {
            if (i <= 63) {
                if (i <= 31) {
                    if (i <= 15) {
                        if (i <= 7) {
                            if (i <= 3) {
                                if (i <= 1) {
                                    if (i == 0) {
                                        return 0;
                                    } else {
                                        return 26456769;
                                    }
                                } else {
                                    if (i == 2) {
                                        return 52912534;
                                    } else {
                                        return 79366292;
                                    }
                                }
                            } else {
                                if (i <= 5) {
                                    if (i == 4) {
                                        return 105817038;
                                    } else {
                                        return 132263769;
                                    }
                                } else {
                                    if (i == 6) {
                                        return 158705481;
                                    } else {
                                        return 185141171;
                                    }
                                }
                            }
                        } else {
                            if (i <= 11) {
                                if (i <= 9) {
                                    if (i == 8) {
                                        return 211569835;
                                    } else {
                                        return 237990472;
                                    }
                                } else {
                                    if (i == 10) {
                                        return 264402078;
                                    } else {
                                        return 290803651;
                                    }
                                }
                            } else {
                                if (i <= 13) {
                                    if (i == 12) {
                                        return 317194190;
                                    } else {
                                        return 343572692;
                                    }
                                } else {
                                    if (i == 14) {
                                        return 369938158;
                                    } else {
                                        return 396289586;
                                    }
                                }
                            }
                        }
                    } else {
                        if (i <= 23) {
                            if (i <= 19) {
                                if (i <= 17) {
                                    if (i == 16) {
                                        return 422625977;
                                    } else {
                                        return 448946331;
                                    }
                                } else {
                                    if (i == 18) {
                                        return 475249649;
                                    } else {
                                        return 501534935;
                                    }
                                }
                            } else {
                                if (i <= 21) {
                                    if (i == 20) {
                                        return 527801189;
                                    } else {
                                        return 554047416;
                                    }
                                } else {
                                    if (i == 22) {
                                        return 580272619;
                                    } else {
                                        return 606475804;
                                    }
                                }
                            }
                        } else {
                            if (i <= 27) {
                                if (i <= 25) {
                                    if (i == 24) {
                                        return 632655975;
                                    } else {
                                        return 658812141;
                                    }
                                } else {
                                    if (i == 26) {
                                        return 684943307;
                                    } else {
                                        return 711048483;
                                    }
                                }
                            } else {
                                if (i <= 29) {
                                    if (i == 28) {
                                        return 737126679;
                                    } else {
                                        return 763176903;
                                    }
                                } else {
                                    if (i == 30) {
                                        return 789198169;
                                    } else {
                                        return 815189489;
                                    }
                                }
                            }
                        }
                    }
                } else {
                    if (i <= 47) {
                        if (i <= 39) {
                            if (i <= 35) {
                                if (i <= 33) {
                                    if (i == 32) {
                                        return 841149875;
                                    } else {
                                        return 867078344;
                                    }
                                } else {
                                    if (i == 34) {
                                        return 892973912;
                                    } else {
                                        return 918835595;
                                    }
                                }
                            } else {
                                if (i <= 37) {
                                    if (i == 36) {
                                        return 944662413;
                                    } else {
                                        return 970453386;
                                    }
                                } else {
                                    if (i == 38) {
                                        return 996207534;
                                    } else {
                                        return 1021923881;
                                    }
                                }
                            }
                        } else {
                            if (i <= 43) {
                                if (i <= 41) {
                                    if (i == 40) {
                                        return 1047601450;
                                    } else {
                                        return 1073239268;
                                    }
                                } else {
                                    if (i == 42) {
                                        return 1098836362;
                                    } else {
                                        return 1124391760;
                                    }
                                }
                            } else {
                                if (i <= 45) {
                                    if (i == 44) {
                                        return 1149904493;
                                    } else {
                                        return 1175373592;
                                    }
                                } else {
                                    if (i == 46) {
                                        return 1200798091;
                                    } else {
                                        return 1226177026;
                                    }
                                }
                            }
                        }
                    } else {
                        if (i <= 55) {
                            if (i <= 51) {
                                if (i <= 49) {
                                    if (i == 48) {
                                        return 1251509433;
                                    } else {
                                        return 1276794351;
                                    }
                                } else {
                                    if (i == 50) {
                                        return 1302030821;
                                    } else {
                                        return 1327217884;
                                    }
                                }
                            } else {
                                if (i <= 53) {
                                    if (i == 52) {
                                        return 1352354586;
                                    } else {
                                        return 1377439973;
                                    }
                                } else {
                                    if (i == 54) {
                                        return 1402473092;
                                    } else {
                                        return 1427452994;
                                    }
                                }
                            }
                        } else {
                            if (i <= 59) {
                                if (i <= 57) {
                                    if (i == 56) {
                                        return 1452378731;
                                    } else {
                                        return 1477249357;
                                    }
                                } else {
                                    if (i == 58) {
                                        return 1502063928;
                                    } else {
                                        return 1526821503;
                                    }
                                }
                            } else {
                                if (i <= 61) {
                                    if (i == 60) {
                                        return 1551521142;
                                    } else {
                                        return 1576161908;
                                    }
                                } else {
                                    if (i == 62) {
                                        return 1600742866;
                                    } else {
                                        return 1625263084;
                                    }
                                }
                            }
                        }
                    }
                }
            } else {
                if (i <= 95) {
                    if (i <= 79) {
                        if (i <= 71) {
                            if (i <= 67) {
                                if (i <= 65) {
                                    if (i == 64) {
                                        return 1649721630;
                                    } else {
                                        return 1674117578;
                                    }
                                } else {
                                    if (i == 66) {
                                        return 1698450000;
                                    } else {
                                        return 1722717974;
                                    }
                                }
                            } else {
                                if (i <= 69) {
                                    if (i == 68) {
                                        return 1746920580;
                                    } else {
                                        return 1771056897;
                                    }
                                } else {
                                    if (i == 70) {
                                        return 1795126012;
                                    } else {
                                        return 1819127010;
                                    }
                                }
                            }
                        } else {
                            if (i <= 75) {
                                if (i <= 73) {
                                    if (i == 72) {
                                        return 1843058980;
                                    } else {
                                        return 1866921015;
                                    }
                                } else {
                                    if (i == 74) {
                                        return 1890712210;
                                    } else {
                                        return 1914431660;
                                    }
                                }
                            } else {
                                if (i <= 77) {
                                    if (i == 76) {
                                        return 1938078467;
                                    } else {
                                        return 1961651733;
                                    }
                                } else {
                                    if (i == 78) {
                                        return 1985150563;
                                    } else {
                                        return 2008574067;
                                    }
                                }
                            }
                        }
                    } else {
                        if (i <= 87) {
                            if (i <= 83) {
                                if (i <= 81) {
                                    if (i == 80) {
                                        return 2031921354;
                                    } else {
                                        return 2055191540;
                                    }
                                } else {
                                    if (i == 82) {
                                        return 2078383740;
                                    } else {
                                        return 2101497076;
                                    }
                                }
                            } else {
                                if (i <= 85) {
                                    if (i == 84) {
                                        return 2124530670;
                                    } else {
                                        return 2147483647;
                                    }
                                } else {
                                    if (i == 86) {
                                        return 2170355138;
                                    } else {
                                        return 2193144275;
                                    }
                                }
                            }
                        } else {
                            if (i <= 91) {
                                if (i <= 89) {
                                    if (i == 88) {
                                        return 2215850191;
                                    } else {
                                        return 2238472027;
                                    }
                                } else {
                                    if (i == 90) {
                                        return 2261008923;
                                    } else {
                                        return 2283460024;
                                    }
                                }
                            } else {
                                if (i <= 93) {
                                    if (i == 92) {
                                        return 2305824479;
                                    } else {
                                        return 2328101438;
                                    }
                                } else {
                                    if (i == 94) {
                                        return 2350290057;
                                    } else {
                                        return 2372389494;
                                    }
                                }
                            }
                        }
                    }
                } else {
                    if (i <= 111) {
                        if (i <= 103) {
                            if (i <= 99) {
                                if (i <= 97) {
                                    if (i == 96) {
                                        return 2394398909;
                                    } else {
                                        return 2416317469;
                                    }
                                } else {
                                    if (i == 98) {
                                        return 2438144340;
                                    } else {
                                        return 2459878695;
                                    }
                                }
                            } else {
                                if (i <= 101) {
                                    if (i == 100) {
                                        return 2481519710;
                                    } else {
                                        return 2503066562;
                                    }
                                } else {
                                    if (i == 102) {
                                        return 2524518435;
                                    } else {
                                        return 2545874514;
                                    }
                                }
                            }
                        } else {
                            if (i <= 107) {
                                if (i <= 105) {
                                    if (i == 104) {
                                        return 2567133990;
                                    } else {
                                        return 2588296054;
                                    }
                                } else {
                                    if (i == 106) {
                                        return 2609359905;
                                    } else {
                                        return 2630324743;
                                    }
                                }
                            } else {
                                if (i <= 109) {
                                    if (i == 108) {
                                        return 2651189772;
                                    } else {
                                        return 2671954202;
                                    }
                                } else {
                                    if (i == 110) {
                                        return 2692617243;
                                    } else {
                                        return 2713178112;
                                    }
                                }
                            }
                        }
                    } else {
                        if (i <= 119) {
                            if (i <= 115) {
                                if (i <= 113) {
                                    if (i == 112) {
                                        return 2733636028;
                                    } else {
                                        return 2753990216;
                                    }
                                } else {
                                    if (i == 114) {
                                        return 2774239903;
                                    } else {
                                        return 2794384321;
                                    }
                                }
                            } else {
                                if (i <= 117) {
                                    if (i == 116) {
                                        return 2814422705;
                                    } else {
                                        return 2834354295;
                                    }
                                } else {
                                    if (i == 118) {
                                        return 2854178334;
                                    } else {
                                        return 2873894071;
                                    }
                                }
                            }
                        } else {
                            if (i <= 123) {
                                if (i <= 121) {
                                    if (i == 120) {
                                        return 2893500756;
                                    } else {
                                        return 2912997648;
                                    }
                                } else {
                                    if (i == 122) {
                                        return 2932384004;
                                    } else {
                                        return 2951659090;
                                    }
                                }
                            } else {
                                if (i <= 125) {
                                    if (i == 124) {
                                        return 2970822175;
                                    } else {
                                        return 2989872531;
                                    }
                                } else {
                                    if (i == 126) {
                                        return 3008809435;
                                    } else {
                                        return 3027632170;
                                    }
                                }
                            }
                        }
                    }
                }
            }
        } else {
            if (i <= 191) {
                if (i <= 159) {
                    if (i <= 143) {
                        if (i <= 135) {
                            if (i <= 131) {
                                if (i <= 129) {
                                    if (i == 128) {
                                        return 3046340019;
                                    } else {
                                        return 3064932275;
                                    }
                                } else {
                                    if (i == 130) {
                                        return 3083408230;
                                    } else {
                                        return 3101767185;
                                    }
                                }
                            } else {
                                if (i <= 133) {
                                    if (i == 132) {
                                        return 3120008443;
                                    } else {
                                        return 3138131310;
                                    }
                                } else {
                                    if (i == 134) {
                                        return 3156135101;
                                    } else {
                                        return 3174019130;
                                    }
                                }
                            }
                        } else {
                            if (i <= 139) {
                                if (i <= 137) {
                                    if (i == 136) {
                                        return 3191782721;
                                    } else {
                                        return 3209425199;
                                    }
                                } else {
                                    if (i == 138) {
                                        return 3226945894;
                                    } else {
                                        return 3244344141;
                                    }
                                }
                            } else {
                                if (i <= 141) {
                                    if (i == 140) {
                                        return 3261619281;
                                    } else {
                                        return 3278770658;
                                    }
                                } else {
                                    if (i == 142) {
                                        return 3295797620;
                                    } else {
                                        return 3312699523;
                                    }
                                }
                            }
                        }
                    } else {
                        if (i <= 151) {
                            if (i <= 147) {
                                if (i <= 145) {
                                    if (i == 144) {
                                        return 3329475725;
                                    } else {
                                        return 3346125588;
                                    }
                                } else {
                                    if (i == 146) {
                                        return 3362648482;
                                    } else {
                                        return 3379043779;
                                    }
                                }
                            } else {
                                if (i <= 149) {
                                    if (i == 148) {
                                        return 3395310857;
                                    } else {
                                        return 3411449099;
                                    }
                                } else {
                                    if (i == 150) {
                                        return 3427457892;
                                    } else {
                                        return 3443336630;
                                    }
                                }
                            }
                        } else {
                            if (i <= 155) {
                                if (i <= 153) {
                                    if (i == 152) {
                                        return 3459084709;
                                    } else {
                                        return 3474701532;
                                    }
                                } else {
                                    if (i == 154) {
                                        return 3490186507;
                                    } else {
                                        return 3505539045;
                                    }
                                }
                            } else {
                                if (i <= 157) {
                                    if (i == 156) {
                                        return 3520758565;
                                    } else {
                                        return 3535844488;
                                    }
                                } else {
                                    if (i == 158) {
                                        return 3550796243;
                                    } else {
                                        return 3565613262;
                                    }
                                }
                            }
                        }
                    }
                } else {
                    if (i <= 175) {
                        if (i <= 167) {
                            if (i <= 163) {
                                if (i <= 161) {
                                    if (i == 160) {
                                        return 3580294982;
                                    } else {
                                        return 3594840847;
                                    }
                                } else {
                                    if (i == 162) {
                                        return 3609250305;
                                    } else {
                                        return 3623522808;
                                    }
                                }
                            } else {
                                if (i <= 165) {
                                    if (i == 164) {
                                        return 3637657816;
                                    } else {
                                        return 3651654792;
                                    }
                                } else {
                                    if (i == 166) {
                                        return 3665513205;
                                    } else {
                                        return 3679232528;
                                    }
                                }
                            }
                        } else {
                            if (i <= 171) {
                                if (i <= 169) {
                                    if (i == 168) {
                                        return 3692812243;
                                    } else {
                                        return 3706251832;
                                    }
                                } else {
                                    if (i == 170) {
                                        return 3719550786;
                                    } else {
                                        return 3732708601;
                                    }
                                }
                            } else {
                                if (i <= 173) {
                                    if (i == 172) {
                                        return 3745724777;
                                    } else {
                                        return 3758598821;
                                    }
                                } else {
                                    if (i == 174) {
                                        return 3771330243;
                                    } else {
                                        return 3783918561;
                                    }
                                }
                            }
                        }
                    } else {
                        if (i <= 183) {
                            if (i <= 179) {
                                if (i <= 177) {
                                    if (i == 176) {
                                        return 3796363297;
                                    } else {
                                        return 3808663979;
                                    }
                                } else {
                                    if (i == 178) {
                                        return 3820820141;
                                    } else {
                                        return 3832831319;
                                    }
                                }
                            } else {
                                if (i <= 181) {
                                    if (i == 180) {
                                        return 3844697060;
                                    } else {
                                        return 3856416913;
                                    }
                                } else {
                                    if (i == 182) {
                                        return 3867990433;
                                    } else {
                                        return 3879417181;
                                    }
                                }
                            }
                        } else {
                            if (i <= 187) {
                                if (i <= 185) {
                                    if (i == 184) {
                                        return 3890696723;
                                    } else {
                                        return 3901828632;
                                    }
                                } else {
                                    if (i == 186) {
                                        return 3912812484;
                                    } else {
                                        return 3923647863;
                                    }
                                }
                            } else {
                                if (i <= 189) {
                                    if (i == 188) {
                                        return 3934334359;
                                    } else {
                                        return 3944871565;
                                    }
                                } else {
                                    if (i == 190) {
                                        return 3955259082;
                                    } else {
                                        return 3965496515;
                                    }
                                }
                            }
                        }
                    }
                }
            } else {
                if (i <= 223) {
                    if (i <= 207) {
                        if (i <= 199) {
                            if (i <= 195) {
                                if (i <= 193) {
                                    if (i == 192) {
                                        return 3975583476;
                                    } else {
                                        return 3985519583;
                                    }
                                } else {
                                    if (i == 194) {
                                        return 3995304457;
                                    } else {
                                        return 4004937729;
                                    }
                                }
                            } else {
                                if (i <= 197) {
                                    if (i == 196) {
                                        return 4014419032;
                                    } else {
                                        return 4023748007;
                                    }
                                } else {
                                    if (i == 198) {
                                        return 4032924300;
                                    } else {
                                        return 4041947562;
                                    }
                                }
                            }
                        } else {
                            if (i <= 203) {
                                if (i <= 201) {
                                    if (i == 200) {
                                        return 4050817451;
                                    } else {
                                        return 4059533630;
                                    }
                                } else {
                                    if (i == 202) {
                                        return 4068095769;
                                    } else {
                                        return 4076503544;
                                    }
                                }
                            } else {
                                if (i <= 205) {
                                    if (i == 204) {
                                        return 4084756634;
                                    } else {
                                        return 4092854726;
                                    }
                                } else {
                                    if (i == 206) {
                                        return 4100797514;
                                    } else {
                                        return 4108584696;
                                    }
                                }
                            }
                        }
                    } else {
                        if (i <= 215) {
                            if (i <= 211) {
                                if (i <= 209) {
                                    if (i == 208) {
                                        return 4116215977;
                                    } else {
                                        return 4123691067;
                                    }
                                } else {
                                    if (i == 210) {
                                        return 4131009681;
                                    } else {
                                        return 4138171544;
                                    }
                                }
                            } else {
                                if (i <= 213) {
                                    if (i == 212) {
                                        return 4145176382;
                                    } else {
                                        return 4152023930;
                                    }
                                } else {
                                    if (i == 214) {
                                        return 4158713929;
                                    } else {
                                        return 4165246124;
                                    }
                                }
                            }
                        } else {
                            if (i <= 219) {
                                if (i <= 217) {
                                    if (i == 216) {
                                        return 4171620267;
                                    } else {
                                        return 4177836117;
                                    }
                                } else {
                                    if (i == 218) {
                                        return 4183893437;
                                    } else {
                                        return 4189791999;
                                    }
                                }
                            } else {
                                if (i <= 221) {
                                    if (i == 220) {
                                        return 4195531577;
                                    } else {
                                        return 4201111955;
                                    }
                                } else {
                                    if (i == 222) {
                                        return 4206532921;
                                    } else {
                                        return 4211794268;
                                    }
                                }
                            }
                        }
                    }
                } else {
                    if (i <= 239) {
                        if (i <= 231) {
                            if (i <= 227) {
                                if (i <= 225) {
                                    if (i == 224) {
                                        return 4216895797;
                                    } else {
                                        return 4221837315;
                                    }
                                } else {
                                    if (i == 226) {
                                        return 4226618635;
                                    } else {
                                        return 4231239573;
                                    }
                                }
                            } else {
                                if (i <= 229) {
                                    if (i == 228) {
                                        return 4235699957;
                                    } else {
                                        return 4239999615;
                                    }
                                } else {
                                    if (i == 230) {
                                        return 4244138385;
                                    } else {
                                        return 4248116110;
                                    }
                                }
                            }
                        } else {
                            if (i <= 235) {
                                if (i <= 233) {
                                    if (i == 232) {
                                        return 4251932639;
                                    } else {
                                        return 4255587827;
                                    }
                                } else {
                                    if (i == 234) {
                                        return 4259081536;
                                    } else {
                                        return 4262413632;
                                    }
                                }
                            } else {
                                if (i <= 237) {
                                    if (i == 236) {
                                        return 4265583990;
                                    } else {
                                        return 4268592489;
                                    }
                                } else {
                                    if (i == 238) {
                                        return 4271439015;
                                    } else {
                                        return 4274123460;
                                    }
                                }
                            }
                        }
                    } else {
                        if (i <= 247) {
                            if (i <= 243) {
                                if (i <= 241) {
                                    if (i == 240) {
                                        return 4276645722;
                                    } else {
                                        return 4279005706;
                                    }
                                } else {
                                    if (i == 242) {
                                        return 4281203321;
                                    } else {
                                        return 4283238485;
                                    }
                                }
                            } else {
                                if (i <= 245) {
                                    if (i == 244) {
                                        return 4285111119;
                                    } else {
                                        return 4286821154;
                                    }
                                } else {
                                    if (i == 246) {
                                        return 4288368525;
                                    } else {
                                        return 4289753172;
                                    }
                                }
                            }
                        } else {
                            if (i <= 251) {
                                if (i <= 249) {
                                    if (i == 248) {
                                        return 4290975043;
                                    } else {
                                        return 4292034091;
                                    }
                                } else {
                                    if (i == 250) {
                                        return 4292930277;
                                    } else {
                                        return 4293663567;
                                    }
                                }
                            } else {
                                if (i <= 253) {
                                    if (i == 252) {
                                        return 4294233932;
                                    } else {
                                        return 4294641351;
                                    }
                                } else {
                                    if (i == 254) {
                                        return 4294885809;
                                    } else {
                                        return 4294967296;
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}


// File contracts/V1/Trig256.sol

/* Copyright (c) 2021 Kohi Art Community, Inc. All rights reserved. */

pragma solidity ^0.8.0;
/*
    Provides trigonometric functions in Q31.Q32 format.

    exp: Adapted from Petteri Aimonen's libfixmath

    See: https://github.com/PetteriAimonen/libfixmath
         https://github.com/PetteriAimonen/libfixmath/blob/master/LICENSE

    other functions: Adapted from Andr├⌐ Slupik's FixedMath.NET
                     https://github.com/asik/FixedMath.Net/blob/master/LICENSE.txt
         
    THIRD PARTY NOTICES:
    ====================

    libfixmath is Copyright (c) 2011-2021 Flatmush <[email protected]>,
    Petteri Aimonen <[email protected]>, & libfixmath AUTHORS

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE.

    Copyright 2012 Andr├⌐ Slupik

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    This project uses code from the log2fix library, which is under the following license:           
    The MIT License (MIT)

    Copyright (c) 2015 Dan Moulding
    
    Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), 
    to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, 
    and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
    
    The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
    IN THE SOFTWARE.
*/

library Trig256 {
    int64 private constant LARGE_PI = 7244019458077122842;
    int64 private constant LN2 = 0xB17217F7;
    int64 private constant LN_MAX = 0x157CD0E702;
    int64 private constant LN_MIN = -0x162E42FEFA;
    int64 private constant E = -0x2B7E15162;

    function sin(int64 x)
        internal
        pure
        returns (int64)
    {       
        (
            int64 clamped,
            bool flipHorizontal,
            bool flipVertical
        ) = clamp(x);

        int64 lutInterval = Fix64V1.div(((256 - 1) * Fix64V1.ONE), Fix64V1.PI_OVER_2);
        int rawIndex = Fix64V1.mul_256(clamped, lutInterval);
        int64 roundedIndex = int64(Fix64V1.round(rawIndex));
        int64 indexError = Fix64V1.sub(int64(rawIndex), roundedIndex);     

        roundedIndex = roundedIndex >> 32; /* FRACTIONAL_PLACES */

        int64 nearestValueIndex = flipHorizontal
            ? (256 - 1) - roundedIndex
            : roundedIndex;

        int64 nearestValue = SinLut256.sinlut(nearestValueIndex);

        int64 secondNearestValue = SinLut256.sinlut(
            flipHorizontal
                ? (256 - 1) -
                    roundedIndex -
                    Fix64V1.sign(indexError)
                : roundedIndex + Fix64V1.sign(indexError)
        );

        int64 delta = Fix64V1.mul(indexError, Fix64V1.abs(Fix64V1.sub(nearestValue, secondNearestValue)));
        int64 interpolatedValue = nearestValue + (flipHorizontal ? -delta : delta);
        int64 finalValue = flipVertical ? -interpolatedValue: interpolatedValue;
    
        return finalValue;
    }

    function cos(int64 x)
        internal
        pure
        returns (int64)
    {
        int64 xl = x;
        int64 angle;
        if(xl > 0) {            
            angle = Fix64V1.add(xl, Fix64V1.sub(0 - Fix64V1.PI, Fix64V1.PI_OVER_2));            
        } else {            
            angle = Fix64V1.add(xl, Fix64V1.PI_OVER_2);
        }        
        return sin(angle);
    }

    function sqrt(int64 x)
        internal
        pure        
        returns (int64)
    {
        int64 xl = x;
        if (xl < 0)
            revert("negative value passed to sqrt");

        uint64 num = uint64(xl);
        uint64 result = uint64(0);
        uint64 bit = uint64(1) << (64 - 2);

        while (bit > num) bit >>= 2;
        for (uint8 i = 0; i < 2; ++i)
        {
            while (bit != 0)
            {
                if (num >= result + bit)
                {
                    num -= result + bit;
                    result = (result >> 1) + bit;
                }
                else
                {
                    result = result >> 1;
                }

                bit >>= 2;
            }

            if (i == 0)
            {
                if (num > (uint64(1) << (64 / 2)) - 1)
                {
                    num -= result;
                    num = (num << (64 / 2)) - uint64(0x80000000);
                    result = (result << (64 / 2)) + uint64(0x80000000);
                }
                else
                {
                    num <<= 64 / 2;
                    result <<= 64 / 2;
                }

                bit = uint64(1) << (64 / 2 - 2);
            }
        }

        if (num > result) ++result;
        return int64(result);
    }

     function log2_256(int x)
        internal
        pure        
        returns (int)
    {
        if (x <= 0) {
            revert("negative value passed to log2_256");
        }

        // This implementation is based on Clay. S. Turner's fast binary logarithm
        // algorithm (C. S. Turner,  "A Fast Binary Logarithm Algorithm", IEEE Signal
        //     Processing Mag., pp. 124,140, Sep. 2010.)

        int b = 1 << 31; // FRACTIONAL_PLACES - 1
        int y = 0;

        int rawX = x;
        while (rawX < Fix64V1.ONE) {
            rawX <<= 1;
            y -= Fix64V1.ONE;
        }

        while (rawX >= Fix64V1.ONE << 1) {
            rawX >>= 1;
            y += Fix64V1.ONE;
        }

        int z = rawX;

        for (uint8 i = 0; i < 32 /* FRACTIONAL_PLACES */; i++) {
            z = Fix64V1.mul_256(z, z);
            if (z >= Fix64V1.ONE << 1) {
                z = z >> 1;
                y += b;
            }
            b >>= 1;
        }

        return y;
    }

    function log_256(int x)
        internal
        pure        
        returns (int)
    {
        return Fix64V1.mul_256(log2_256(x), LN2);
    }

    function log2(int64 x)
        internal
        pure        
        returns (int64)
    {
        if (x <= 0) revert("non-positive value passed to log2");

        // This implementation is based on Clay. S. Turner's fast binary logarithm
        // algorithm (C. S. Turner,  "A Fast Binary Logarithm Algorithm", IEEE Signal
        //     Processing Mag., pp. 124,140, Sep. 2010.)

        int64 b = 1 << 31; // FRACTIONAL_PLACES - 1
        int64 y = 0;

        int64 rawX = x;
        while (rawX < Fix64V1.ONE)
        {
            rawX <<= 1;
            y -= Fix64V1.ONE;
        }

        while (rawX >= Fix64V1.ONE << 1)
        {
            rawX >>= 1;
            y += Fix64V1.ONE;
        }

        int64 z = rawX;

        for (int32 i = 0; i < Fix64V1.FRACTIONAL_PLACES; i++)
        {
            z = Fix64V1.mul(z, z);
            if (z >= Fix64V1.ONE << 1)
            {
                z = z >> 1;
                y += b;
            }

            b >>= 1;
        }

        return y;
    }

    function log(int64 x)
        internal
        pure        
        returns (int64)
    {
        return Fix64V1.mul(log2(x), LN2);
    }

    function exp(int64 x)
        internal
        pure        
        returns (int64)
    {
        if (x == 0) return Fix64V1.ONE;
        if (x == Fix64V1.ONE) return E;
        if (x >= LN_MAX) return Fix64V1.MAX_VALUE;
        if (x <= LN_MIN) return 0;

        /* The algorithm is based on the power series for exp(x):
         * http://en.wikipedia.org/wiki/Exponential_function#Formal_definition
         *
         * From term n, we get term n+1 by multiplying with x/n.
         * When the sum term drops to zero, we can stop summing.
         */

        // The power-series converges much faster on positive values
        // and exp(-x) = 1/exp(x).
        
        bool neg = (x < 0);
        if (neg) x = -x;

        int64 result = Fix64V1.add(
            int64(x),
            Fix64V1.ONE
        );
        int64 term = x;

        for (uint32 i = 2; i < 40; i++) {
            term = Fix64V1.mul(
                x,
                Fix64V1.div(term, int32(i) * Fix64V1.ONE)
            );
            result = Fix64V1.add(result, int64(term));
            if (term == 0) break;
        }

        if (neg) {
            result = Fix64V1.div(Fix64V1.ONE, result);
        }

        return result;
    }

    function clamp(int64 x)
        internal
        pure
        returns (
            int64,
            bool,
            bool
        )
    {
        int64 clamped2Pi = x;
        for (uint8 i = 0; i < 29; ++i) {
            clamped2Pi %= LARGE_PI >> i;
        }
        if (x < 0) {
            clamped2Pi += Fix64V1.TWO_PI;
        }

        bool flipVertical = clamped2Pi >= Fix64V1.PI;
        int64 clampedPi = clamped2Pi;
        while (clampedPi >= Fix64V1.PI) {
            clampedPi -= Fix64V1.PI;
        }

        bool flipHorizontal = clampedPi >= Fix64V1.PI_OVER_2;

        int64 clampedPiOver2 = clampedPi;
        if (clampedPiOver2 >= Fix64V1.PI_OVER_2)
            clampedPiOver2 -= Fix64V1.PI_OVER_2;

        return (clampedPiOver2, flipHorizontal, flipVertical);
    }
}


// File contracts/V1/RandomV1.sol

/* Copyright (c) 2021 Kohi Art Community, Inc. All rights reserved. */

pragma solidity ^0.8.0;
/*
    A pseudo-random number generator, adapted from and matching the algorithm for .NET maximum compatibility Random implementation.

    See: https://github.com/dotnet/runtime/blob/f7633f498a8be34bee739b240a0aa9ae6a660cd9/src/libraries/System.Private.CoreLib/src/System/Random.Net5CompatImpl.cs#L192
         https://github.com/dotnet/runtime/blob/main/LICENSE.TXT

    THIRD PARTY NOTICES:
    ====================

    The MIT License (MIT)

    Copyright (c) .NET Foundation and Contributors

    All rights reserved.

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE.
*/

library RandomV1 {

    int32 private constant MBIG = 0x7fffffff;
    int32 private constant MSEED = 161803398;

    struct PRNG {
        int32[56] _seedArray;
        int32 _inext;
        int32 _inextp;
    }
    
    function buildSeedTable(int32 seed) internal pure returns(PRNG memory prng) {
        uint8 ii = 0;
        int32 mj;
        int32 mk;

        int32 subtraction = (seed == type(int32).min) ? type(int32).max : int32(MathV1.abs(seed));
        mj = MSEED - subtraction;
        prng._seedArray[55] = mj;
        mk = 1;
        for (uint8 i = 1; i < 55; i++) {  
            if ((ii += 21) >= 55) {
                ii -= 55;
            }
            prng._seedArray[uint64(ii)] = mk;
            mk = mj - mk;
            if (mk < 0) mk += MBIG;
            mj = prng._seedArray[uint8(ii)];
        }

        for (uint8 k = 1; k < 5; k++) {

            for (uint8 i = 1; i < 56; i++) {                
                uint8 n = i + 30;           
                if (n >= 55) {
                    n -= 55;                
                }

                int64 an = prng._seedArray[1 + n];                
                int64 ai = prng._seedArray[i];
                prng._seedArray[i] = int32(ai - an);
                
                if (prng._seedArray[i] < 0) {
                    int64 x = prng._seedArray[i];
                    x += MBIG;
                    prng._seedArray[i] = int32(x);
                }               
            }
        }

        prng._inextp = 21;
    }   

    function next(PRNG memory prng, int32 maxValue) internal pure returns (int32) {
        require(maxValue >= 0, "maxValue < 0");

        int32 retval = next(prng);

        int64 fretval = retval * Fix64V1.ONE;
        int64 sample = Fix64V1.mul(fretval, Fix64V1.div(Fix64V1.ONE, MBIG * Fix64V1.ONE));
        int64 sr = Fix64V1.mul(sample, maxValue * Fix64V1.ONE);
        int32 r = int32(sr >> 32 /* FRACTIONAL_PLACES */);

        return r;
    }

    function next(PRNG memory prng, int32 minValue, int32 maxValue) internal pure returns(int32) {
        require(maxValue > minValue, "maxValue <= minValue");
        
        int64 range = maxValue - minValue;
        
        if (range <= type(int32).max) {
            int32 retval = next(prng);

            int64 fretval = retval * Fix64V1.ONE;
            int64 sample = Fix64V1.mul(fretval, Fix64V1.div(Fix64V1.ONE, MBIG * Fix64V1.ONE));
            int64 sr = Fix64V1.mul(sample, range * Fix64V1.ONE);
            int32 r = int32(sr >> 32  /* FRACTIONAL_PLACES */) + minValue;
            
            return r;
        }
        else {
            int64 fretval = nextForLargeRange(prng);
            int64 sr = Fix64V1.mul(fretval, range * Fix64V1.ONE);
            int32 r = int32(sr >> 32  /* FRACTIONAL_PLACES */) + minValue;
            return r;
        }
    }

    function next(PRNG memory prng) internal pure returns(int32) {

        int64 retVal;        
        int32 locINext = prng._inext;
        int32 locINextp = prng._inextp;

        if (++locINext >= 56) locINext = 1;
        if (++locINextp >= 56) locINextp = 1;

        int64 a = int64(prng._seedArray[uint32(locINext)]);
        int64 b = int64(prng._seedArray[uint32(locINextp)]);
        retVal = a - b;        

        if (retVal == MBIG) {
            retVal--;
        }
        if (retVal < 0) {
            retVal += MBIG;
        }

        prng._seedArray[uint32(locINext)] = int32(retVal);
        prng._inext = locINext;
        prng._inextp = locINextp;        

        int32 r = int32(retVal);
        return r;
    }

    function nextForLargeRange(PRNG memory prng) private pure returns(int64) {

        int sample1 = next(prng);
        int sample2 = next(prng);

        bool negative = sample2 % 2 == 0;
        if (negative) {
            sample1 = -sample1;
        }

        int64 d = int64(sample1) * Fix64V1.ONE;
        d = Fix64V1.add(int64(d), (type(int32).max - 1));
        d = Fix64V1.div(int64(d), int64(2) * (type(int32).max - 1));

        return d; 
    }

    function nextGaussian(PRNG memory prng) internal pure returns (int64 randNormal) {
        int64 u1 = Fix64V1.sub(Fix64V1.ONE, Fix64V1.mul(next(prng) * Fix64V1.ONE, Fix64V1.div(Fix64V1.ONE, Fix64V1.MAX_VALUE)));
        int64 u2 = Fix64V1.sub(Fix64V1.ONE, Fix64V1.mul(next(prng) * Fix64V1.ONE, Fix64V1.div(Fix64V1.ONE, Fix64V1.MAX_VALUE)));
        int64 sqrt = Trig256.sqrt(Fix64V1.mul(-2 * Fix64V1.ONE, Trig256.log(u1)));
        int64 randStdNormal = Fix64V1.mul(sqrt, Trig256.sin(Fix64V1.mul(Fix64V1.TWO, Fix64V1.mul(Fix64V1.PI, u2))));
        randNormal = Fix64V1.add(0, Fix64V1.mul(Fix64V1.ONE, randStdNormal));
        return randNormal;
    }
}


// File contracts/V1/IRenderer.sol

/* Copyright (c) 2021 Kohi Art Community, Inc. All rights reserved. */

pragma solidity ^0.8.0;
interface IRenderer {

    struct RenderArgs {
        int16 index;
        uint8 stage;
        int32 seed;        
        uint32[20480] buffer;
        RandomV1.PRNG prng;
    }

    /**
     * @notice Renders a chunk of the artwork, given an index.
     * @dev The output is an array of packed uint32s, in ARGB format.     
     */
    function render(RenderArgs memory args) external view returns (RenderArgs memory results);
}


// File contracts/Projects/CityLights/Errors.sol

/* Copyright (c) 2021 Kohi Art Community, Inc. All rights reserved. */

pragma solidity ^0.8.0;

error InvalidStage();
error IndexOutOfRange();

error AdminOnly();
error NoOwnerAddress();
error NoCreatorAddress();
error AddressMustBeSet();

error InvalidSeed();
error InvalidRenderer();
error InvalidOwnerRoyalty();

error SeedNotSet();
error SeedAlreadySet();

error CannotPurchaseFromContract();
error InsufficientFundsForPurchase();
error InvalidFundsDistribution();

error CollectionPaused();
error CollectionLocked();
error CollectionInactive();
error CollectionSoldOut();

error PresaleNotOpen();
error PublicSaleNotOpen();
error NotEligibleForPresale();
error NoRemainingPresaleMints();
error AccountExceedsMaxMints();

error RenderDisallowed();


// File contracts/Projects/CityLights/CityLightsProxy.sol

/* Copyright (c) 2021 eepmon. All rights reserved. */

pragma solidity ^0.8.0;
contract CityLightsProxy {

    using Address for address;

    address private _owner;
    address private _executor;

    constructor(address executor) {
        require(executor.isContract(), "invalid executor");
        _owner = msg.sender;
        _executor = executor;
    }

    function changeExecutor(address newExecutor) public {
        require(msg.sender == _owner, "owner only");
        require(newExecutor != address(0x0), "address must be set");
        _executor = newExecutor;
    }

    function getAttributes(int32 seed)
        external
        pure
        returns (string memory result)
    {
        RandomV1.PRNG memory prng = RandomV1.buildSeedTable(seed);
        result = string(abi.encodePacked('{"attributes":['));
        return string(abi.encodePacked(result, "]}"));
    }

    function render(IRenderer.RenderArgs memory args)
        external
        pure
        returns (IRenderer.RenderArgs memory results)
    {
        
    }
}


// File contracts/V1/IAttributes.sol

/* Copyright (c) 2021 Kohi Art Community, Inc. All rights reserved. */

pragma solidity ^0.8.0;

interface IAttributes {

    function getAttributes(int32 seed) external view returns (string memory attributes);
}


// File @openzeppelin/contracts/utils/introspection/[email protected]

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}


// File @openzeppelin/contracts/token/ERC721/[email protected]

pragma solidity ^0.8.0;

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}


// File @openzeppelin/contracts/token/ERC721/[email protected]

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}


// File @openzeppelin/contracts/token/ERC721/extensions/[email protected]

pragma solidity ^0.8.0;

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}


// File @openzeppelin/contracts/utils/[email protected]

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


// File @openzeppelin/contracts/utils/introspection/[email protected]

pragma solidity ^0.8.0;

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}


// File @openzeppelin/contracts/token/ERC721/[email protected]

pragma solidity ^0.8.0;







/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}


// File @openzeppelin/contracts/token/ERC721/extensions/[email protected]

pragma solidity ^0.8.0;

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}


// File @openzeppelin/contracts/token/ERC721/extensions/[email protected]

pragma solidity ^0.8.0;


/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}


// File @openzeppelin/contracts/security/[email protected]

pragma solidity ^0.8.0;

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}


// File @openzeppelin/contracts/token/ERC721/extensions/[email protected]
pragma solidity ^0.8.0;


/**
 * @dev ERC721 token with pausable token transfers, minting and burning.
 *
 * Useful for scenarios such as preventing trades until the end of an evaluation
 * period, or having an emergency switch for freezing all token transfers in the
 * event of a large bug.
 */
abstract contract ERC721Pausable is ERC721, Pausable {
    /**
     * @dev See {ERC721-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        require(!paused(), "ERC721Pausable: token transfer while paused");
    }
}


// File @openzeppelin/contracts/token/ERC721/extensions/[email protected]

pragma solidity ^0.8.0;


/**
 * @title ERC721 Burnable Token
 * @dev ERC721 Token that can be irreversibly burned (destroyed).
 */
abstract contract ERC721Burnable is Context, ERC721 {
    /**
     * @dev Burns `tokenId`. See {ERC721-_burn}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function burn(uint256 tokenId) public virtual {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721Burnable: caller is not owner nor approved");
        _burn(tokenId);
    }
}


// File @openzeppelin/contracts/access/[email protected]

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}


// File @openzeppelin/contracts/access/[email protected]

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerable is IAccessControl {
    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}


// File @openzeppelin/contracts/access/[email protected]

pragma solidity ^0.8.0;




/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}


// File @openzeppelin/contracts/utils/structs/[email protected]

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}


// File @openzeppelin/contracts/access/[email protected]

pragma solidity ^0.8.0;



/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerable is IAccessControlEnumerable, AccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(bytes32 => EnumerableSet.AddressSet) private _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view override returns (address) {
        return _roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view override returns (uint256) {
        return _roleMembers[role].length();
    }

    /**
     * @dev Overload {grantRole} to track enumerable memberships
     */
    function grantRole(bytes32 role, address account) public virtual override(AccessControl, IAccessControl) {
        super.grantRole(role, account);
        _roleMembers[role].add(account);
    }

    /**
     * @dev Overload {revokeRole} to track enumerable memberships
     */
    function revokeRole(bytes32 role, address account) public virtual override(AccessControl, IAccessControl) {
        super.revokeRole(role, account);
        _roleMembers[role].remove(account);
    }

    /**
     * @dev Overload {renounceRole} to track enumerable memberships
     */
    function renounceRole(bytes32 role, address account) public virtual override(AccessControl, IAccessControl) {
        super.renounceRole(role, account);
        _roleMembers[role].remove(account);
    }

    /**
     * @dev Overload {_setupRole} to track enumerable memberships
     */
    function _setupRole(bytes32 role, address account) internal virtual override {
        super._setupRole(role, account);
        _roleMembers[role].add(account);
    }
}


// File contracts/Projects/CityLights/KohiCityLights.sol

/* Copyright (c) 2021 Kohi Art Community, Inc. All rights reserved. */

pragma solidity ^0.8.0;
interface IBloomList {
    function updateAdmin(address newAdmin) external;
    function isInBloomList(address _address) external view returns (bool);    
}

/*                                                                                
                                     &@@@@@@@@@@@        @@@@@@@@@@@@@@         
                                 @@@@@@@@@@@@@@@@@@%  @@@@@@@@@@@@@@@@@@@@      
           @@@@@@@@@@@@@@@    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@     
        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@  @@@@@@@@@@@@@@@@@@@@@ @@@@@@@@@@@@@    
     /@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&   #@@@@@@@@@@@@@@@@@@@    @@@@@@@@@@@    
    @@@@@@@@@@@   (@@@@@@@@@@@@@@@@@@    %@@@@@@@@@@@@@@@@@@     @@@@@@@@@@@@   
   @@@@@@@@@@@*    [email protected]@@@@@@@@@@@@@@@     @@@@@@@@@@@@@@@@@@      @@@@@@@@@@@@   
   @@@@@@@@@@@      @@@@@@@@@@@@@@@@@    @@@@@@@@@@@@@@@@@@      @@@@@@@@@@@    
  @@@@@@@@@@@&     ,@@@@@@@@@@@@@@@@@   @@@@@@@@@@@@@@@@@@       @@@@@@@@@@@    
  @@@@@@@@@@@@    /@@@@@@@@@@@@@@@@@@/ @@@@@@@@@@@@@@@@@@@      @@@@@@@@@@@     
  @@@@@@@@@@@@   @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@      @@@@@@@@@@@      
  (@@@@@@@@@@@@@@@@@@@@@@@ @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@     @@@@@@@@@@@       
   @@@@@@@@@@@@@@@@@@@@@    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@    @@@@@@@@@@@        
    @@@@@@@@@@@@@@@@@        @@@@@@@@@@@@@@@@@@@@@@@@@@@   @@@@@@@@@@@          
      @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@,@@@@@@@@@@@            
         @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@              
             (@@@@@@@@@@@@@@@@@@   @@@@@@@@@@@@@@@@@@@@@@@@@@@@                 
                                      @@@@@@@@@@@@@@@@@@@@@                     
                                            @@@@@@@@@@@                #@@@@@,  
                                            @@@@@@@@@@@          @@@@@@@@@@@@@@@
                          @@@@@@@@@@.       @@@@@@@@@@@       @@@@@@@@@@@@@@@@, 
                        @@@@@@@@@@@@@@@@    @@@@@@@@@@@    &@@@@@@@@@@@         
                        &@@@@@@@@@@@@@@@@@# @@@@@@@@@@@   @@@@@@@@@@@           
                         @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*@@@@@@@@@@@@            
                          @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@              
                           @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@               
                            @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                
                              @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                 
                               @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&                 
                                 @@@@@@@@@@@@@@@@@@@@@@@@@@@@@                  
                                   @@@@@@@@@@@@@@@@@@@@@@@@@@                   
                                     @@@@@@@@@@@@@@@@@@@@@@@                    
                                       @@@@@@@@@@@@@@@@@@@@(                    
                                         @@@@@@@@@@@@@@@@@&                     
                                           @@@@@@@@@@@@@@(                      
                                             @@@@@@@@@@@                        
                                              [email protected]@@@@#                           
*/

contract KohiCityLights is Context, AccessControlEnumerable, ERC721, ERC721Enumerable, ERC721Pausable, ERC721Burnable {

    using Address for address;

    struct Collection {
        string name;
        string baseTokenUri;        
        string description;
        string license;
        uint priceInWei;
        int32 seed;
        uint minted;
        uint mintedMax;        
        uint mintedMaxPerOwner;
        uint lockAt;
        bool paused;
        bool active;        
        string creatorName;
        address payable creatorAddress;        
        address _renderer;
    }
    
    mapping(uint8 => Collection) internal collections;   
    
    event CollectionMinted (
        uint256 indexed tokenId,        
        address indexed recipient,        
        uint256 mintId,
        uint256 priceInWei,
        int32 seed
    );

    uint private lastTokenId;  
    mapping(address => uint) private ownerMints;
    mapping(uint => int32) internal tokenSeed;

    bool private locked;
    bool private presale;    

    uint8 private ownerRoyalty;
    address payable private ownerAddress;

    address private _admin;
    address private _ownership;

    uint presalePriceInWei;
    mapping(address => uint) presaleMints;
    mapping(uint => bool) presoldTokens;

    constructor(address ownership) ERC721("Kohi", "KOHI") {        
        lastTokenId = 0;
        _admin = _msgSender();
        _contractUri = "https://kohi.art/metadata";
        _ownership = ownership;
        presalePriceInWei = 330000000000000000;
        _pause();      
    }

    string private _contractUri;

    /*
    * @dev See: https://docs.opensea.io/docs/contract-level-metadata
    */
    function contractURI() public view returns (string memory) {
        return _contractUri;
    }

    function updateContractUri(string memory contractUri) public {
        if(_msgSender() != _admin) revert AdminOnly();
        _contractUri = contractUri;
    }

    function updateAdmin(address newAdmin) public {
        if(_msgSender() != _admin) revert AdminOnly();
        if(newAdmin == address(0x0)) revert AddressMustBeSet();
        _admin = newAdmin;       
    }

    function updateOwnerData(uint8 royalty, address payable newAddress) public {
        if(_msgSender() != _admin) revert AdminOnly();
        if(newAddress == address(0x0)) revert AddressMustBeSet();
        if(royalty == 0 || royalty > 100) revert InvalidOwnerRoyalty();        
        ownerRoyalty = royalty;
        ownerAddress = newAddress;
    }

    function getPresale() external view returns (bool) {
        return presale;
    }

    function togglePresale() external {
        if(_msgSender() != _admin) revert AdminOnly();
        if(presale) {
            presale = false;
        } else {
            presale = true;
        }        
    }

    function toggleLocked() external {
        if(_msgSender() != _admin) revert AdminOnly();
        if(locked) {
            locked = false;
        } else {
            locked = true;
        } 
    }

    function togglePaused() external {
        if(_msgSender() != _admin) revert AdminOnly();
        if(paused()) {
            _unpause();
        }
        else {
            _pause();
        }
    }

    function setPresalePrice(uint priceInWei) public {
        if(_msgSender() != _admin) revert AdminOnly();
        presalePriceInWei = priceInWei;
    }

    function setPrice(uint priceInWei) public {
        if(_msgSender() != _admin) revert AdminOnly();
        collections[0].priceInWei = priceInWei;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControlEnumerable, ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override (ERC721, ERC721Enumerable, ERC721Pausable) {
        super._beforeTokenTransfer(from, to, tokenId);   
        if(collections[0].paused) revert CollectionPaused();                    
    }

    function getCollection() public view returns (Collection memory collection) {        
        return collections[0];
    }

    function updateCollection(Collection memory collection) public {
        if(_msgSender() != _admin) revert AdminOnly();
        if(collection._renderer == address(0x0) || !collection._renderer.isContract()) revert InvalidRenderer();
        collections[0] = collection;
    }
        
    /**
     * @notice Sets the collection's unique seed. It cannot be modified once set.
     * @dev This is a source of external entropy, by the contract owner, to avoid determinism on PRNG that could exploit the mint's parameters.
     */
    function setSeed(int32 seed) external {  
        if(_msgSender() != _admin) revert AdminOnly();
        if(seed == 0) revert InvalidSeed();
        if(collections[0].seed != 0) revert SeedAlreadySet();
        collections[0].seed = seed;
    }

    function getSeed() external view returns (int32) {  
        if(_msgSender() != _admin) revert AdminOnly();
        if(collections[0].seed == 0) revert SeedNotSet();
        return collections[0].seed;
    }

    function getOwnership() external view returns(address) {
        if(_msgSender() != _admin) revert AdminOnly();
        return _ownership;
    }

    function setOwnership(address newOwnership) external {
        if(_msgSender() != _admin) revert AdminOnly();
        _ownership = newOwnership;
    }

    function releaseControl() external {
        if(_msgSender() != _admin) revert AdminOnly();
        IBloomList(_ownership).updateAdmin(_msgSender());
    }       

    function purchasePresale(uint count) external payable {
        purchasePresaleFor(_msgSender(), count);
    }   

    function purchasePresaleFor(address recipient, uint count) public payable {
        if(!presale) revert PresaleNotOpen();

        address minter = _msgSender();
        uint balance = IERC721(_ownership).balanceOf(minter);        
        bool inBloomList = IBloomList(_ownership).isInBloomList(minter);
        
        // start with simple eligibility check
        if(!inBloomList && balance < 1) revert NotEligibleForPresale();

        // get count of all owned kintsugi tokens not already presold
        uint presaleBalance = 0;
        for(uint i = 0; i < balance; i++) {  
            uint tokenId = IERC721Enumerable(_ownership).tokenOfOwnerByIndex(minter, i);
            if(!presoldTokens[tokenId]) {
                presaleBalance++;
                presoldTokens[tokenId] = true;
                if(presaleBalance >= count) {
                    break; // have enough
                }
            }
        }
        
        // if in bloom list, with no entitlements, give one if they haven't minted one
        if(inBloomList && presaleBalance == 0 && presaleMints[minter] == 0) {
            presaleBalance = 1;
        }

        // if minter's count is over their balance, adjust it down
        count = uint(MathV1.min(int(count), int(presaleBalance)));

        // final balance check before minting
        if(count == 0) revert NoRemainingPresaleMints();

        // edge case: minter wants to buy multiple but we have less supply than their count,
        //            but don't want them to get nothing
        int remaining = MathV1.max(0, int(collections[0].mintedMax) - MathV1.min(int(collections[0].lockAt), int(collections[0].minted)));
        count = uint(MathV1.min(int(count), remaining));
        if(count == 0) revert CollectionSoldOut();

        presaleMints[minter] = presaleMints[minter] + count;
        mint(minter, recipient, presalePriceInWei, count);
    }

    function purchase(uint count) external payable {
        purchaseFor(_msgSender(), count);
    }

    function purchaseFor(address recipient, uint count) public payable {        
        if(presale) revert PublicSaleNotOpen();

        address minter = _msgSender();

        uint mintedMaxPerOwner = collections[0].mintedMaxPerOwner;
        if(mintedMaxPerOwner != 0) {            
            // reset for presale minters
            uint totalMintsAllowed = mintedMaxPerOwner + presaleMints[minter];
            if(ownerMints[minter] >= totalMintsAllowed) revert AccountExceedsMaxMints();
        }

        // edge case: minter wants to buy multiple but we have less supply than their count,
        //            but don't want them to get nothing
        int remaining = MathV1.max(0, int(collections[0].mintedMax) - MathV1.min(int(collections[0].lockAt), int(collections[0].minted)));
        count = uint(MathV1.min(int(count), remaining));
        if(count == 0) revert CollectionSoldOut();

        mint(_msgSender(), recipient, collections[0].priceInWei, count);        
    }

    function mint(address minter, address recipient, uint priceInWei, uint count) private {        
        if(ownerAddress == address(0x0)) revert NoOwnerAddress();          
        if(minter.isContract()) revert CannotPurchaseFromContract();
        
        if(locked && minter != _admin) revert CollectionLocked();

        uint totalPrice = priceInWei * count;  
        if(msg.value < totalPrice) revert InsufficientFundsForPurchase();      

        Collection memory collection = collections[0];        
        if(collection.creatorAddress == address(0x0)) revert NoCreatorAddress();      
        if(!collection.active && minter != _admin) revert CollectionInactive(); 
        if(collection.seed == 0) revert SeedNotSet();

        for(uint i = 0; i < count; i++) {
            uint256 nextTokenId = lastTokenId + 1;
            int32 seed = int32(int(uint(keccak256(abi.encodePacked(collection.seed, block.number, minter, recipient, nextTokenId)))));        
            lastTokenId = nextTokenId;        
            tokenSeed[lastTokenId] = seed;        
            collections[0].minted = collection.minted + 1;
            ownerMints[minter] = ownerMints[minter] + 1;

            _safeMint(recipient, nextTokenId);
            emit CollectionMinted(nextTokenId, recipient, collection.minted, collection.priceInWei, seed);

            if(collection.lockAt > 0) {
                if(lastTokenId >= collection.lockAt)
                    locked = true;     
            }
        }

        distributeFunds(totalPrice, collection.creatorAddress);
    }

    function distributeFunds(uint priceInWei, address payable creatorAddress) private {
        if (msg.value > 0) {
            uint overpaid = msg.value - priceInWei;
            if (overpaid > 0) {
                payable(_msgSender()).transfer(overpaid);
            }

            uint dueToOwner = ownerRoyalty * priceInWei / 100;
            uint paidToOwner;  
            if (dueToOwner > 0) {                
                ownerAddress.transfer(dueToOwner);
                paidToOwner = dueToOwner;
            }

            uint dueToCreator = priceInWei - paidToOwner;
            uint paidToCreator;
            if (dueToCreator > 0) {                
                creatorAddress.transfer(dueToCreator);
                paidToCreator = dueToCreator;
            }

            if(priceInWei - paidToOwner - paidToCreator != 0) {
                revert InvalidFundsDistribution();           
            }
        }
    }   
    
    function ownsToken(address owner, uint tokenId) public view returns (bool) {
        for(uint i = 0; i < balanceOf(owner); i++) {
            if(tokenId == tokenOfOwnerByIndex(owner, i)) {
                return true;
            }            
        }
        return false;
    }  

    /**
    * @dev See {IERC721Metadata-tokenURI}.
    */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        Collection memory collection = collections[0];
        string memory baseURI = collection.baseTokenUri;
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, Strings.toString(tokenId))) : "";
    }

    function setRenderer(address renderer) external {
        if(_msgSender() != _admin) revert AdminOnly();
        collections[0]._renderer = renderer;
    }

    /**
     * @notice Retrieve's an artwork's attributes, given a token ID.
     */
    function getAttributes(uint tokenId) external view returns (string memory attributes) {
        if(_msgSender() != _admin && !ownsToken(_msgSender(), tokenId)) revert RenderDisallowed();
        return IAttributes(collections[0]._renderer).getAttributes(tokenSeed[tokenId]);
    }

    /**
     * @notice Begins rendering an artwork given a token ID, and continuation arguments, which must be owned by the caller.
     */
    function _render(uint tokenId, IRenderer.RenderArgs memory args) private view returns (IRenderer.RenderArgs memory results) {
        if(_msgSender() != _admin && !ownsToken(_msgSender(), tokenId)) revert RenderDisallowed();
        if(args.seed != tokenSeed[tokenId]) revert InvalidSeed();  
        return IRenderer(collections[0]._renderer).render(args);
    }

    /**
     * @notice Continues rendering an artwork given a token ID and previous arguments. Token must be owned by the caller.
     */
    function render(uint tokenId, IRenderer.RenderArgs memory args) external view returns (IRenderer.RenderArgs memory results) {        
        return _render(tokenId, args);
    }

    /**
     * @notice Begins rendering an artwork given a token ID. Token must be owned by the caller.
     */
    function beginRender(uint tokenId) external view returns (IRenderer.RenderArgs memory results) {        
        uint32[20480] memory buffer;
        RandomV1.PRNG memory prng;
        return _render(tokenId, IRenderer.RenderArgs(0, 0, tokenSeed[tokenId], buffer, prng));
    }
}


// File contracts/V1/TypesV1.sol

/* Copyright (c) 2021 Kohi Art Community, Inc. All rights reserved. */

pragma solidity ^0.8.0;

library TypesV1 {
    /**
     * @dev Represents a point in two-dimensional space.
     */
    struct Point2D {
        int256 x;
        int256 y;
    }

    /**
     * @dev Represents a chunked rendering region.
     */
    struct Chunk2D {
        uint16 index;
        uint16 width;
        uint16 height;
        uint16 chunkWidth;
        uint16 chunkHeight;
        uint32 startX;
        uint32 startY;
    }
}


// File contracts/V1/GeometryV1.sol

/* Copyright (c) 2021 Kohi Art Community, Inc. All rights reserved. */

pragma solidity ^0.8.0;
library GeometryV1 {
        
    struct Triangle2D {
        TypesV1.Point2D v0;
        TypesV1.Point2D v1;
        TypesV1.Point2D v2;
        uint32 strokeColor;
        uint32 fillColor;
        TypesV1.Chunk2D chunk;
    }

    struct Line2D {
        TypesV1.Point2D v0;
        TypesV1.Point2D v1;
        uint32 color;
        TypesV1.Chunk2D chunk;
    }

    struct Polygon2D {
        TypesV1.Point2D[40960] vertices;
        uint32 vertexCount;
        uint32 strokeColor;
        uint32 fillColor;
        TypesV1.Chunk2D chunk;
    }

    function edge(
        TypesV1.Point2D memory a,
        TypesV1.Point2D memory b,
        TypesV1.Point2D memory c
    ) external pure returns (int256) {
        return ((b.y - a.y) * (c.x - a.x)) - ((b.x - a.x) * (c.y - a.y));
    }

    function getBoundingBox(TypesV1.Point2D[] memory vertices)
        external
        pure
        returns (TypesV1.Point2D memory tl, TypesV1.Point2D memory br)
    {
        int256 xMax = vertices[0].x;
        int256 xMin = vertices[0].x;
        int256 yMax = vertices[0].y;
        int256 yMin = vertices[0].y;

        for (uint256 i; i < vertices.length; i++) {
            TypesV1.Point2D memory p = vertices[i];

            if (p.x > xMax) xMax = p.x;
            if (p.x < xMin) xMin = p.x;
            if (p.y > yMax) yMax = p.y;
            if (p.y < yMin) yMin = p.y;
        }

        return (TypesV1.Point2D(xMin, yMin), TypesV1.Point2D(xMax, yMax));
    }
}


// File contracts/V1/LCG64.sol

/* Copyright (c) 2021 Kohi Art Community, Inc. All rights reserved. */

pragma solidity ^0.8.0;
/*
    An implementation of a Linear Congruential Generator in Q31.Q32 format.
    Adapted from the algorithm used by p5js, which is licensed under the LGPL v2.1.

    See: https://github.com/processing/p5.js/blob/374acfb44588bfd565c54d61264df197d798d121/src/math/noise.js
         https://github.com/processing/p5.js/blob/main/license.txt
         
    This adaptation was necessary to ensure generative art in p5js produces identical results for noise values in Solidity.

    THIRD PARTY NOTICES:
    ====================

                        GNU LESSER GENERAL PUBLIC LICENSE
                       Version 2.1, February 1999

 Copyright (C) 1991, 1999 Free Software Foundation, Inc.
 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
 Everyone is permitted to copy and distribute verbatim copies
 of this license document, but changing it is not allowed.

(This is the first released version of the Lesser GPL.  It also counts
 as the successor of the GNU Library Public License, version 2, hence
 the version number 2.1.)

                            Preamble

  The licenses for most software are designed to take away your
freedom to share and change it.  By contrast, the GNU General Public
Licenses are intended to guarantee your freedom to share and change
free software--to make sure the software is free for all its users.

  This license, the Lesser General Public License, applies to some
specially designated software packages--typically libraries--of the
Free Software Foundation and other authors who decide to use it.  You
can use it too, but we suggest you first think carefully about whether
this license or the ordinary General Public License is the better
strategy to use in any particular case, based on the explanations below.

  When we speak of free software, we are referring to freedom of use,
not price.  Our General Public Licenses are designed to make sure that
you have the freedom to distribute copies of free software (and charge
for this service if you wish); that you receive source code or can get
it if you want it; that you can change the software and use pieces of
it in new free programs; and that you are informed that you can do
these things.

  To protect your rights, we need to make restrictions that forbid
distributors to deny you these rights or to ask you to surrender these
rights.  These restrictions translate to certain responsibilities for
you if you distribute copies of the library or if you modify it.

  For example, if you distribute copies of the library, whether gratis
or for a fee, you must give the recipients all the rights that we gave
you.  You must make sure that they, too, receive or can get the source
code.  If you link other code with the library, you must provide
complete object files to the recipients, so that they can relink them
with the library after making changes to the library and recompiling
it.  And you must show them these terms so they know their rights.

  We protect your rights with a two-step method: (1) we copyright the
library, and (2) we offer you this license, which gives you legal
permission to copy, distribute and/or modify the library.

  To protect each distributor, we want to make it very clear that
there is no warranty for the free library.  Also, if the library is
modified by someone else and passed on, the recipients should know
that what they have is not the original version, so that the original
author's reputation will not be affected by problems that might be
introduced by others.

  Finally, software patents pose a constant threat to the existence of
any free program.  We wish to make sure that a company cannot
effectively restrict the users of a free program by obtaining a
restrictive license from a patent holder.  Therefore, we insist that
any patent license obtained for a version of the library must be
consistent with the full freedom of use specified in this license.

  Most GNU software, including some libraries, is covered by the
ordinary GNU General Public License.  This license, the GNU Lesser
General Public License, applies to certain designated libraries, and
is quite different from the ordinary General Public License.  We use
this license for certain libraries in order to permit linking those
libraries into non-free programs.

  When a program is linked with a library, whether statically or using
a shared library, the combination of the two is legally speaking a
combined work, a derivative of the original library.  The ordinary
General Public License therefore permits such linking only if the
entire combination fits its criteria of freedom.  The Lesser General
Public License permits more lax criteria for linking other code with
the library.

  We call this license the "Lesser" General Public License because it
does Less to protect the user's freedom than the ordinary General
Public License.  It also provides other free software developers Less
of an advantage over competing non-free programs.  These disadvantages
are the reason we use the ordinary General Public License for many
libraries.  However, the Lesser license provides advantages in certain
special circumstances.

  For example, on rare occasions, there may be a special need to
encourage the widest possible use of a certain library, so that it becomes
a de-facto standard.  To achieve this, non-free programs must be
allowed to use the library.  A more frequent case is that a free
library does the same job as widely used non-free libraries.  In this
case, there is little to gain by limiting the free library to free
software only, so we use the Lesser General Public License.

  In other cases, permission to use a particular library in non-free
programs enables a greater number of people to use a large body of
free software.  For example, permission to use the GNU C Library in
non-free programs enables many more people to use the whole GNU
operating system, as well as its variant, the GNU/Linux operating
system.

  Although the Lesser General Public License is Less protective of the
users' freedom, it does ensure that the user of a program that is
linked with the Library has the freedom and the wherewithal to run
that program using a modified version of the Library.

  The precise terms and conditions for copying, distribution and
modification follow.  Pay close attention to the difference between a
"work based on the library" and a "work that uses the library".  The
former contains code derived from the library, whereas the latter must
be combined with the library in order to run.

                  GNU LESSER GENERAL PUBLIC LICENSE
   TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION

  0. This License Agreement applies to any software library or other
program which contains a notice placed by the copyright holder or
other authorized party saying it may be distributed under the terms of
this Lesser General Public License (also called "this License").
Each licensee is addressed as "you".

  A "library" means a collection of software functions and/or data
prepared so as to be conveniently linked with application programs
(which use some of those functions and data) to form executables.

  The "Library", below, refers to any such software library or work
which has been distributed under these terms.  A "work based on the
Library" means either the Library or any derivative work under
copyright law: that is to say, a work containing the Library or a
portion of it, either verbatim or with modifications and/or translated
straightforwardly into another language.  (Hereinafter, translation is
included without limitation in the term "modification".)

  "Source code" for a work means the preferred form of the work for
making modifications to it.  For a library, complete source code means
all the source code for all modules it contains, plus any associated
interface definition files, plus the scripts used to control compilation
and installation of the library.

  Activities other than copying, distribution and modification are not
covered by this License; they are outside its scope.  The act of
running a program using the Library is not restricted, and output from
such a program is covered only if its contents constitute a work based
on the Library (independent of the use of the Library in a tool for
writing it).  Whether that is true depends on what the Library does
and what the program that uses the Library does.

  1. You may copy and distribute verbatim copies of the Library's
complete source code as you receive it, in any medium, provided that
you conspicuously and appropriately publish on each copy an
appropriate copyright notice and disclaimer of warranty; keep intact
all the notices that refer to this License and to the absence of any
warranty; and distribute a copy of this License along with the
Library.

  You may charge a fee for the physical act of transferring a copy,
and you may at your option offer warranty protection in exchange for a
fee.

  2. You may modify your copy or copies of the Library or any portion
of it, thus forming a work based on the Library, and copy and
distribute such modifications or work under the terms of Section 1
above, provided that you also meet all of these conditions:

    a) The modified work must itself be a software library.

    b) You must cause the files modified to carry prominent notices
    stating that you changed the files and the date of any change.

    c) You must cause the whole of the work to be licensed at no
    charge to all third parties under the terms of this License.

    d) If a facility in the modified Library refers to a function or a
    table of data to be supplied by an application program that uses
    the facility, other than as an argument passed when the facility
    is invoked, then you must make a good faith effort to ensure that,
    in the event an application does not supply such function or
    table, the facility still operates, and performs whatever part of
    its purpose remains meaningful.

    (For example, a function in a library to compute square roots has
    a purpose that is entirely well-defined independent of the
    application.  Therefore, Subsection 2d requires that any
    application-supplied function or table used by this function must
    be optional: if the application does not supply it, the square
    root function must still compute square roots.)

These requirements apply to the modified work as a whole.  If
identifiable sections of that work are not derived from the Library,
and can be reasonably considered independent and separate works in
themselves, then this License, and its terms, do not apply to those
sections when you distribute them as separate works.  But when you
distribute the same sections as part of a whole which is a work based
on the Library, the distribution of the whole must be on the terms of
this License, whose permissions for other licensees extend to the
entire whole, and thus to each and every part regardless of who wrote
it.

Thus, it is not the intent of this section to claim rights or contest
your rights to work written entirely by you; rather, the intent is to
exercise the right to control the distribution of derivative or
collective works based on the Library.

In addition, mere aggregation of another work not based on the Library
with the Library (or with a work based on the Library) on a volume of
a storage or distribution medium does not bring the other work under
the scope of this License.

  3. You may opt to apply the terms of the ordinary GNU General Public
License instead of this License to a given copy of the Library.  To do
this, you must alter all the notices that refer to this License, so
that they refer to the ordinary GNU General Public License, version 2,
instead of to this License.  (If a newer version than version 2 of the
ordinary GNU General Public License has appeared, then you can specify
that version instead if you wish.)  Do not make any other change in
these notices.

  Once this change is made in a given copy, it is irreversible for
that copy, so the ordinary GNU General Public License applies to all
subsequent copies and derivative works made from that copy.

  This option is useful when you wish to copy part of the code of
the Library into a program that is not a library.

  4. You may copy and distribute the Library (or a portion or
derivative of it, under Section 2) in object code or executable form
under the terms of Sections 1 and 2 above provided that you accompany
it with the complete corresponding machine-readable source code, which
must be distributed under the terms of Sections 1 and 2 above on a
medium customarily used for software interchange.

  If distribution of object code is made by offering access to copy
from a designated place, then offering equivalent access to copy the
source code from the same place satisfies the requirement to
distribute the source code, even though third parties are not
compelled to copy the source along with the object code.

  5. A program that contains no derivative of any portion of the
Library, but is designed to work with the Library by being compiled or
linked with it, is called a "work that uses the Library".  Such a
work, in isolation, is not a derivative work of the Library, and
therefore falls outside the scope of this License.

  However, linking a "work that uses the Library" with the Library
creates an executable that is a derivative of the Library (because it
contains portions of the Library), rather than a "work that uses the
library".  The executable is therefore covered by this License.
Section 6 states terms for distribution of such executables.

  When a "work that uses the Library" uses material from a header file
that is part of the Library, the object code for the work may be a
derivative work of the Library even though the source code is not.
Whether this is true is especially significant if the work can be
linked without the Library, or if the work is itself a library.  The
threshold for this to be true is not precisely defined by law.

  If such an object file uses only numerical parameters, data
structure layouts and accessors, and small macros and small inline
functions (ten lines or less in length), then the use of the object
file is unrestricted, regardless of whether it is legally a derivative
work.  (Executables containing this object code plus portions of the
Library will still fall under Section 6.)

  Otherwise, if the work is a derivative of the Library, you may
distribute the object code for the work under the terms of Section 6.
Any executables containing that work also fall under Section 6,
whether or not they are linked directly with the Library itself.

  6. As an exception to the Sections above, you may also combine or
link a "work that uses the Library" with the Library to produce a
work containing portions of the Library, and distribute that work
under terms of your choice, provided that the terms permit
modification of the work for the customer's own use and reverse
engineering for debugging such modifications.

  You must give prominent notice with each copy of the work that the
Library is used in it and that the Library and its use are covered by
this License.  You must supply a copy of this License.  If the work
during execution displays copyright notices, you must include the
copyright notice for the Library among them, as well as a reference
directing the user to the copy of this License.  Also, you must do one
of these things:

    a) Accompany the work with the complete corresponding
    machine-readable source code for the Library including whatever
    changes were used in the work (which must be distributed under
    Sections 1 and 2 above); and, if the work is an executable linked
    with the Library, with the complete machine-readable "work that
    uses the Library", as object code and/or source code, so that the
    user can modify the Library and then relink to produce a modified
    executable containing the modified Library.  (It is understood
    that the user who changes the contents of definitions files in the
    Library will not necessarily be able to recompile the application
    to use the modified definitions.)

    b) Use a suitable shared library mechanism for linking with the
    Library.  A suitable mechanism is one that (1) uses at run time a
    copy of the library already present on the user's computer system,
    rather than copying library functions into the executable, and (2)
    will operate properly with a modified version of the library, if
    the user installs one, as long as the modified version is
    interface-compatible with the version that the work was made with.

    c) Accompany the work with a written offer, valid for at
    least three years, to give the same user the materials
    specified in Subsection 6a, above, for a charge no more
    than the cost of performing this distribution.

    d) If distribution of the work is made by offering access to copy
    from a designated place, offer equivalent access to copy the above
    specified materials from the same place.

    e) Verify that the user has already received a copy of these
    materials or that you have already sent this user a copy.

  For an executable, the required form of the "work that uses the
Library" must include any data and utility programs needed for
reproducing the executable from it.  However, as a special exception,
the materials to be distributed need not include anything that is
normally distributed (in either source or binary form) with the major
components (compiler, kernel, and so on) of the operating system on
which the executable runs, unless that component itself accompanies
the executable.

  It may happen that this requirement contradicts the license
restrictions of other proprietary libraries that do not normally
accompany the operating system.  Such a contradiction means you cannot
use both them and the Library together in an executable that you
distribute.

  7. You may place library facilities that are a work based on the
Library side-by-side in a single library together with other library
facilities not covered by this License, and distribute such a combined
library, provided that the separate distribution of the work based on
the Library and of the other library facilities is otherwise
permitted, and provided that you do these two things:

    a) Accompany the combined library with a copy of the same work
    based on the Library, uncombined with any other library
    facilities.  This must be distributed under the terms of the
    Sections above.

    b) Give prominent notice with the combined library of the fact
    that part of it is a work based on the Library, and explaining
    where to find the accompanying uncombined form of the same work.

  8. You may not copy, modify, sublicense, link with, or distribute
the Library except as expressly provided under this License.  Any
attempt otherwise to copy, modify, sublicense, link with, or
distribute the Library is void, and will automatically terminate your
rights under this License.  However, parties who have received copies,
or rights, from you under this License will not have their licenses
terminated so long as such parties remain in full compliance.

  9. You are not required to accept this License, since you have not
signed it.  However, nothing else grants you permission to modify or
distribute the Library or its derivative works.  These actions are
prohibited by law if you do not accept this License.  Therefore, by
modifying or distributing the Library (or any work based on the
Library), you indicate your acceptance of this License to do so, and
all its terms and conditions for copying, distributing or modifying
the Library or works based on it.

  10. Each time you redistribute the Library (or any work based on the
Library), the recipient automatically receives a license from the
original licensor to copy, distribute, link with or modify the Library
subject to these terms and conditions.  You may not impose any further
restrictions on the recipients' exercise of the rights granted herein.
You are not responsible for enforcing compliance by third parties with
this License.

  11. If, as a consequence of a court judgment or allegation of patent
infringement or for any other reason (not limited to patent issues),
conditions are imposed on you (whether by court order, agreement or
otherwise) that contradict the conditions of this License, they do not
excuse you from the conditions of this License.  If you cannot
distribute so as to satisfy simultaneously your obligations under this
License and any other pertinent obligations, then as a consequence you
may not distribute the Library at all.  For example, if a patent
license would not permit royalty-free redistribution of the Library by
all those who receive copies directly or indirectly through you, then
the only way you could satisfy both it and this License would be to
refrain entirely from distribution of the Library.

If any portion of this section is held invalid or unenforceable under any
particular circumstance, the balance of the section is intended to apply,
and the section as a whole is intended to apply in other circumstances.

It is not the purpose of this section to induce you to infringe any
patents or other property right claims or to contest validity of any
such claims; this section has the sole purpose of protecting the
integrity of the free software distribution system which is
implemented by public license practices.  Many people have made
generous contributions to the wide range of software distributed
through that system in reliance on consistent application of that
system; it is up to the author/donor to decide if he or she is willing
to distribute software through any other system and a licensee cannot
impose that choice.

This section is intended to make thoroughly clear what is believed to
be a consequence of the rest of this License.

  12. If the distribution and/or use of the Library is restricted in
certain countries either by patents or by copyrighted interfaces, the
original copyright holder who places the Library under this License may add
an explicit geographical distribution limitation excluding those countries,
so that distribution is permitted only in or among countries not thus
excluded.  In such case, this License incorporates the limitation as if
written in the body of this License.

  13. The Free Software Foundation may publish revised and/or new
versions of the Lesser General Public License from time to time.
Such new versions will be similar in spirit to the present version,
but may differ in detail to address new problems or concerns.

Each version is given a distinguishing version number.  If the Library
specifies a version number of this License which applies to it and
"any later version", you have the option of following the terms and
conditions either of that version or of any later version published by
the Free Software Foundation.  If the Library does not specify a
license version number, you may choose any version ever published by
the Free Software Foundation.

  14. If you wish to incorporate parts of the Library into other free
programs whose distribution conditions are incompatible with these,
write to the author to ask for permission.  For software which is
copyrighted by the Free Software Foundation, write to the Free
Software Foundation; we sometimes make exceptions for this.  Our
decision will be guided by the two goals of preserving the free status
of all derivatives of our free software and of promoting the sharing
and reuse of software generally.

                            NO WARRANTY

  15. BECAUSE THE LIBRARY IS LICENSED FREE OF CHARGE, THERE IS NO
WARRANTY FOR THE LIBRARY, TO THE EXTENT PERMITTED BY APPLICABLE LAW.
EXCEPT WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR
OTHER PARTIES PROVIDE THE LIBRARY "AS IS" WITHOUT WARRANTY OF ANY
KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
PURPOSE.  THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE
LIBRARY IS WITH YOU.  SHOULD THE LIBRARY PROVE DEFECTIVE, YOU ASSUME
THE COST OF ALL NECESSARY SERVICING, REPAIR OR CORRECTION.

  16. IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN
WRITING WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY
AND/OR REDISTRIBUTE THE LIBRARY AS PERMITTED ABOVE, BE LIABLE TO YOU
FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL OR
CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE THE
LIBRARY (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE LIBRARY TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH
DAMAGES.

                     END OF TERMS AND CONDITIONS
*/

library LCG64 {
    uint64 internal constant M = 4294967296;
    uint32 internal constant A = 1664525;
    uint32 internal constant C = 1013904223;

    function next(uint64 z) internal pure returns(uint64, int64) {                
                
        uint256 r = uint(A) * uint(z) + uint(C);            
        uint64 g = uint64(r % M);           
        
        int lz = Trig256.log_256(int64(g) * int(Fix64V1.ONE));
        int lm = Trig256.log_256(int64(M) * int(Fix64V1.ONE));
        int64 lml = Fix64V1.sub(int64(lz), int64(lm));
        int64 v = Trig256.exp(lml);

        return (g, v);
    }
}


// File contracts/3D/Renderer.sol

/* Copyright (c) 2021 Kohi Art Community, Inc. All rights reserved. */

pragma solidity ^0.8.0;

contract Renderer {

    struct Vector2 {
        int64 x;
        int64 y;
    }

    struct Vector3 {
        int64 x;
        int64 y;
        int64 z;
    }

    struct Face {
        int32 a;
        int32 b;
        int32 c;
        Vector3 normal;
    }

    struct Camera {
        Vector3 position;
        Vector3 target;
    }
    
    struct Material {
        string id;
        string name;
        string diffuse;
    }

    struct ScanLine {
        int32 currentY;
        int64 ndotla;
        int64 ndotlb;
        int64 ndotlc;
        int64 ndotld;
        int64 ua;
        int64 ub;
        int64 uc;
        int64 ud;
        int64 va;
        int64 vb;
        int64 vc;
        int64 vd;
    }

    struct Vertex {
        Vector3 position;
        Vector3 normal;
        Vector3 world;
        Vector3 texture;
    }

    struct Texture {
        int32 height;
        int32 width;
        uint32 buffer;
    }
    
    struct Mesh {
        string name;
        Vertex[] vertices;
        Face[] faces;
        Vector3 position;
        Vector3 rotation;
        Texture texture;
    }        
}

// File contracts/V1/GraphicsV1.sol

/* Copyright (c) 2021 Kohi Art Community, Inc. All rights reserved. */

pragma solidity ^0.8.0;

library GraphicsV1 {
    
    function setPixel(
        uint32[20480 /* 128 * 160 */] memory result,
        uint256 width,
        int256 x,
        int256 y,
        uint32 color
    ) internal pure {
        uint256 p = uint256(int256(width) * y + x);
        result[p] = blend(result[p], color);
    }

    function blend(uint32 bg, uint32 fg) internal pure returns (uint32) {
        uint32 r1 = bg >> 16;
        uint32 g1 = bg >> 8;
        uint32 b1 = bg;
        
        uint32 a2 = fg >> 24;
        uint32 r2 = fg >> 16;
        uint32 g2 = fg >> 8;
        uint32 b2 = fg;
        
        uint32 alpha = (a2 & 0xFF) + 1;
        uint32 inverseAlpha = 257 - alpha;

        uint32 r = (alpha * (r2 & 0xFF) + inverseAlpha * (r1 & 0xFF)) >> 8;
        uint32 g = (alpha * (g2 & 0xFF) + inverseAlpha * (g1 & 0xFF)) >> 8;
        uint32 b = (alpha * (b2 & 0xFF) + inverseAlpha * (b1 & 0xFF)) >> 8;

        uint32 rgb = 0;
        rgb |= uint32(0xFF) << 24;
        rgb |= r << 16;
        rgb |= g << 8;
        rgb |= b;

        return rgb;
    }

    function setOpacity(uint32 color, uint32 opacity) internal pure returns (uint32) {

        require(opacity > 0 && opacity <= 255, "opacity must be between 0 and 255");
        
        uint32 r = color >> 16 & 0xFF;
        uint32 g = color >> 8 & 0xFF;
        uint32 b = color & 0xFF;

        uint32 rgb = 0;
        rgb |= opacity << 24;
        rgb |= r << 16;
        rgb |= g << 8;
        rgb |= b;

        return uint32(rgb);     
    }
}