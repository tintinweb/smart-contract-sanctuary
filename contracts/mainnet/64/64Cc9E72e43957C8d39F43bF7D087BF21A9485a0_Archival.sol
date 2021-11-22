// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;
import '@openzeppelin/contracts/utils/math/SafeMath.sol';

library Archival {
    using SafeMath for uint256;

    function tokenName(uint256 tokenId) public pure returns (string memory name) {
        uint256 number = tokenId.mod(36);
        if(number == 0) {
            number = 36;
        }
        name = string(abi.encodePacked(toString(36), rollCode(tokenId), toString(number)));
    }

    function rollCode(uint256 tokenId) public pure returns (string memory code) {
        uint256 roll = tokenId.sub(1).div(36);
        uint256 rollPrefix = roll.div(26);
        uint256 rollSuffix = roll.mod(26);
        code = string(abi.encodePacked(letterMap(rollPrefix), letterMap(rollSuffix)));
    }

    function letterMap(uint256 num) public pure returns (string memory letter) {
        string[26] memory letters;
        letters[0] = 'A';
        letters[1] = 'B';
        letters[2] = 'C';
        letters[3] = 'D';
        letters[4] = 'E';
        letters[5] = 'F';
        letters[6] = 'G';
        letters[7] = 'H';
        letters[8] = 'I';
        letters[9] = 'J';
        letters[10] = 'K';
        letters[11] = 'L';
        letters[12] = 'M';
        letters[13] = 'N';
        letters[14] = 'O';
        letters[15] = 'P';
        letters[16] = 'Q';
        letters[17] = 'R';
        letters[18] = 'S';
        letters[19] = 'T';
        letters[20] = 'U';
        letters[21] = 'V';
        letters[22] = 'W';
        letters[23] = 'X';
        letters[24] = 'Y';
        letters[25] = 'Z';
        letter = letters[num];
    }

    function getDefaultSizes() public pure returns (uint256 default_width, uint256 default_height) {
        default_width = 10200;
        default_height = 6900;
    }

    function getWidthAndHeight(bool snippet, uint256 rotation) public pure returns (uint256 s_width, uint256 s_height) {
        (uint256 default_width, uint256 default_height) = getDefaultSizes();
        s_width = default_width;
        s_height = default_height;
        if(snippet) {
            s_height = (default_width / 38) * 35;
            if(rotation == 1 || rotation == 3) {
                s_width = s_height;
                s_height = default_width;
            }
        } else if(rotation == 1 || rotation == 3) {
            s_width = s_height;
            s_height = default_width;
        }
    }

    function makeSVG(string memory baseUri, string memory cid, bool snippet, uint256 rotation) public pure returns (string memory svg){
        (uint256 default_width, uint256 default_height) = getDefaultSizes();
        (uint256 s_width, uint256 s_height) = getWidthAndHeight(snippet, rotation);
        string memory transform;
        if(rotation == 1) {
            transform = string(abi.encodePacked('transform="rotate(90, ', toString(s_width / 2), ', ', toString(s_width / 2), ')"'));
        } else if(rotation == 2) {
            transform = string(abi.encodePacked('transform="rotate(180, ', toString(s_width / 2), ', ', toString(s_height / 2), ')"'));
        } else if(rotation == 3) {
            transform = string(abi.encodePacked('transform="rotate(270, ', toString(s_height / 2), ', ', toString(s_height / 2), ')"'));
        }
        svg = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ';
        svg = string(abi.encodePacked(svg, toString(s_width), ' ', toString(s_height), '"><image href="', baseUri, cid, '" height="', toString(default_height), '" width="', toString(default_width), '" ', transform, ' /></svg>'));
    }

    function makeSVGSnippet(string memory baseUri, string memory cid, bool snippet, uint256 rotation, uint256 tokenId, string memory film, string memory color) public pure returns (string memory svg){
        (uint256 default_width, uint256 default_height) = getDefaultSizes();
        (uint256 s_width, uint256 s_height) = getWidthAndHeight(snippet, rotation);
        uint256 number = tokenId.mod(36);
        if(number == 0) {
            number = 36;
        }
        string[11] memory parts;
        parts[0] = string(abi.encodePacked('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ', toString(s_width), ' ', toString(s_height), '"><g '));
        if(rotation == 1) {
            parts[1] = string(abi.encodePacked('transform="rotate(90, ', toString(s_width / 2), ', ', toString(s_width / 2), ')"'));
        } else if(rotation == 2) {
            parts[1] = string(abi.encodePacked('transform="rotate(180, ', toString(s_width / 2), ', ', toString(s_height / 2), ')"'));
        } else if(rotation == 3) {
            parts[1] = string(abi.encodePacked('transform="rotate(270, ', toString(s_height / 2), ', ', toString(s_height / 2), ')"'));
        }
        parts[2] = string(abi.encodePacked('><svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 3800 3500" height="', toString((default_width / 38) * 35), '" width="', toString(default_width), '"><path fill="#', color, '" d="M-8.2,3510.8V-8.6h3812.7v3519.4H-8.2z M849.9,343.4c-1.6-34.6,3.6-70-2.9-104.1c-18-59.1-90.5-37.1-136.9-41c-38.5-3.6-67.7,28.1-65.8,63.8c2.3,61.6-4.7,124.5,3.1,185.6c18.4,61.8,96.6,37,145,41.6C870.2,485.1,846.4,396.4,849.9,343.4z M849.9,3154.6c-0.1-30,0.3-60.1-0.2-90.1c-0.8-27.8-22.7-54.3-51.4-55.1c-30-0.8-59.9-0.1-89.9-0.3c-28.8-2.6-55.2,14.7-61.7,43.6c-6,59-0.6,119.2-2.4,178.6c-2.8,33.1,19.9,68.3,55.6,67.8c48.3-5.3,126.5,21.1,146.7-39C854.1,3225.8,848.1,3189.6,849.9,3154.6z M2034.9,343.7c-0.1,30.5,0.3,61.1,0,91.6c-0.2,33.7,32,56.6,64.1,54.2c49.2-2.4,135.5,17.1,139.3-54.7c0.1-60.6-0.2-121.2,0.1-181.7c0-31.2-28.6-56.2-59.3-54.9c-35.4,1.9-72.1-4.4-106.7,3.4c-28.6,9.2-40.6,38-37.5,66.4C2034.9,293.2,2034.9,318.5,2034.9,343.7z M2960.8,342.1c0.2,32.9-0.6,65.8,0.5,98.6c3,28.9,30.8,50,59.3,48.6c34.9-1.4,70.9,3.9,105.3-3.1c24.6-7.2,40.7-33.1,38.6-58.5c0-55.8,0-111.5,0-167.3c2.2-26.1-13-50.3-38.1-58.9c-34.2-7.4-70.3-1.5-105.2-3.3C2940.4,198.8,2964.1,288.2,2960.8,342.1L2960.8,342.1z M1312.4,343.6c-0.7-33.8,1.5-67.8-1.1-101.4c-16.7-62.7-92.7-39.8-140.8-43.9c-32.3-2.4-62.7,23.1-61.8,56.5c0.1,60.1,0.2,120.1,0,180.2c0,24.1,17.7,46.7,41.1,52.1c32.3,5.4,65.6,1.1,98.3,2.4C1334.3,490.2,1308.7,401.2,1312.4,343.6z M2702.2,343.5L2702.2,343.5c-3.2-50.4,18.8-136.9-52.7-144.8c-28.5-1.1-57.1-0.2-85.6-0.5c-37.3-3.7-68.1,24.8-66.7,59.4c0.1,58.6,0.1,117.2,0,175.9c0.5,13.5,5.7,26.4,14.6,36.6c11.8,14.7,30.6,19.5,48.7,19.4c28.5-0.4,57.1,0.4,85.6-0.2C2722.1,484.2,2698.7,395.7,2702.2,343.5z M386.3,345.2c-0.1-31.4,0.2-62.9-0.2-94.4c-1.5-31.8-30.4-54.4-61.4-52.6c-38,3.8-101.5-12.4-127.5,18.6c-11.6,12.2-15.8,27.9-14.4,44.8c0,58.2,0,116.3,0,174.4c0.4,20.6,13.2,38.5,31.4,47.6c35.5,12.1,75,3.1,111.9,5.8c29.8,1.4,59.1-21.8,59.8-52.7C386.6,406.2,386.2,375.7,386.3,345.2L386.3,345.2z M1776.1,344.8c-2.9-58,20.3-149.7-67.1-146.5c-34.8,3.1-91.9-9.8-117.9,14c-13.8,12.1-20,27.5-20.1,45.6c0,57.2-0.1,114.4-0.1,171.6c-1,36.7,30.4,63,66.3,60c33.4-1.9,68.2,4.3,100.9-3.6C1794.9,464.2,1771.3,391.8,1776.1,344.8L1776.1,344.8z M3423.3,343.4c2.7,81.4-22.6,155.1,91.5,146.1c24.8-1.3,51.1,3.4,75.2-3.6c25.4-8.4,38.8-33.3,38.2-59.3c-0.1-55.3-0.1-110.6,0-165.8c-0.2-80.3-86-60.2-141-62.4C3402.4,197.4,3426.7,288.5,3423.3,343.4L3423.3,343.4z M386.3,3155.1c-0.9-34.7,2-69.8-1.5-104.2c-6-21.2-24.9-40.1-47.7-41.3c-29.9-1-59.9-0.3-89.9-0.5c-32.7-3.6-65.1,19.7-64.4,54.5c-0.2,60.5,0,121.1-0.2,181.6c0.8,29.1,24.3,54,53.9,53.7c37.6-1.6,76.9,4.8,113.7-3.3c26.8-9.4,38.8-37.8,36-64.7C386.3,3205.6,386.3,3180.4,386.3,3155.1z M1108.9,3153.8c0.8,34.2-1.7,68.8,1,102.9c6.4,23.7,27.8,42.6,52.9,42.4c31.9,0.1,63.8,0,95.6,0c29.1,0.2,54.2-26.4,53.9-55.5c-0.2-60.1-0.2-120.1,0-180.2c-0.3-33.2-30.8-58.1-63.5-54.3c-25.7,0-51.4,0-77.1,0c-16.2-0.6-32.9,2.2-44.8,14.2c-11.9,11.4-18.3,25-18.1,41.8C1109.1,3094.7,1108.9,3124.3,1108.9,3153.8z M2034.9,3153.9L2034.9,3153.9c-0.1,30.5,0.4,61,0,91.5c0.3,28.9,25,53.9,54,53.5c37.2-1.7,75.8,4.3,112.3-3c21.9-7.6,37-29.2,37.1-52.5c-0.2-60.1-0.2-120.1,0-180.2c-0.4-28.1-23.4-53.4-52.1-54c-29.5-0.6-59-0.1-88.5-0.3c-31.6-3.5-62.8,20.2-62.7,53.3C2034.8,3092.9,2035,3123.4,2034.9,3153.9z M2497.2,3153.4L2497.2,3153.4c1.9,51.3-17.1,146,57.2,145.9c34.1-1.5,68.7,1.6,102.7-1c29.8-6.8,46.9-34.5,45.1-64.4c-0.2-56.2,0.2-112.5-0.1-168.8c-0.8-12.6-4.3-24.4-12.3-34.4c-12-16.2-30.2-22.8-50.2-21.6c-31.4,0.4-62.8-0.8-94.2,0.6C2477.3,3019.4,2501.4,3105,2497.2,3153.4z M1571,3153.3L1571,3153.3c1.2,34.2-2.6,68.9,2,102.8c17.2,64.5,98.6,37.7,147.9,43c33.5,0,57-31.3,55.2-63.6c-0.2-57.2,0.2-114.4-0.1-171.6c-1.5-32.3-29.7-58.3-62.2-54.8c-32.3,0.4-64.7-1-97,0.8C1551.3,3023.7,1575.4,3104.8,1571,3153.3z M2960.8,3153.8c1.8,35.9-4,73.1,3.1,108.2c23.4,58.7,97,30.7,145.2,37.2c33.5,0.7,59.2-31.7,55.3-64.1c-0.4-8.5,0.4-171.7-0.1-175.9c-1-13.9-8.3-26.6-18.4-36c-11.8-11.6-27.4-14.7-43.4-14.1c-30.4,0.2-60.9-0.5-91.3,0.4c-27.1,1-49.8,25.7-50.1,52.8C2960.4,3092.8,2960.9,3123.3,2960.8,3153.8z M3423.3,3153.6L3423.3,3153.6c1.6,35-3.6,71,2.8,105.5c19,60.1,95.4,35.2,143.1,40c36.8,2.4,62.1-31.7,59.1-66.8c-0.1-55.8,0.2-111.5-0.1-167.3c-0.7-9.6-2.6-18.9-7.6-27.3c-11.6-21.1-32.6-30.3-56.3-28.6c-31.4,0.4-62.8-0.9-94.1,0.7C3403.6,3022.6,3427.5,3104.9,3423.3,3153.6z"/></svg>'));
        parts[3] = '<style type="text/css"> @font-face { font-family: Teletactile; src: url("https://archive-app.netlify.app/Teletactile.ttf"); } .t0{font:300px "Teletactile", sans-serif;} </style>';
        parts[4] = '<text x="1850" y="400" class="t0" fill="orange">LH / ARCH</text>';
        parts[5] = string(abi.encodePacked('<text x="9150" y="400" class="t0" fill="orange">', toString(number), '</text>'));
        parts[6] = string(abi.encodePacked('<text x="9150" y="9250" class="t0" fill="orange">', toString(number), '</text>'));
        parts[7] = string(abi.encodePacked('<text x="1850" y="9250" class="t0" fill="orange">36', rollCode(tokenId), '</text>'));
        parts[8] = string(abi.encodePacked('<text x="3650" y="9250" class="t0" fill="orange">', film, '</text>'));
        parts[9] = string(abi.encodePacked('<image href="', baseUri, cid, '" height="6697" width="9900" x="150" y="1341" />'));
        parts[10] = '<g transform="scale(0.049)"><svg xmlns="http://www.w3.org/2000/svg" x="61500" y="181500" viewBox="0 0 130 70" style="enable-background:new 0 0 130 70;" xml:space="preserve"><style type="text/css">.st0{fill:none;stroke:orange;stroke-width:5;stroke-miterlimit:10;}</style><g><line class="st0" x1="3.5" y1="3.4" x2="3.5" y2="68.3"/><line class="st0" x1="5.9" y1="65.8" x2="19.1" y2="65.8"/><line class="st0" x1="19.1" y1="60.7" x2="39.2" y2="60.7"/><line class="st0" x1="5.9" y1="5.9" x2="19" y2="5.9"/><line class="st0" x1="19" y1="10.9" x2="39.1" y2="10.9"/><line class="st0" x1="39.2" y1="55.8" x2="59.3" y2="55.8"/><line class="st0" x1="39.2" y1="15.9" x2="59.2" y2="15.9"/><line class="st0" x1="59.3" y1="50.8" x2="79.4" y2="50.8"/><line class="st0" x1="59.2" y1="20.8" x2="79.3" y2="20.8"/><line class="st0" x1="79.3" y1="45.8" x2="99.4" y2="45.8"/><line class="st0" x1="79.3" y1="25.8" x2="99.4" y2="25.8"/><line class="st0" x1="99.4" y1="30.8" x2="114.4" y2="30.8"/><line class="st0" x1="99.4" y1="40.8" x2="114.4" y2="40.8"/><line class="st0" x1="114.4" y1="35.8" x2="129.3" y2="35.8"/></g></svg></g>';
        svg = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6], parts[7], parts[8], parts[9], parts[10], '</g></svg>'));
    }

    function makeAttributes(string memory film) public pure returns (string memory attributes) {
        attributes = string(abi.encodePacked('{"trait_type":"Film Type","value":"', film, '"}'));
    }

    function makeJson(string memory name, string memory description, string memory image, string memory svg, string memory attributes) public pure returns (string memory) {
        return string(abi.encodePacked('{"name": "', name, '", "description": "', description, '", "image": "', image, '", "svg": "', svg, '", "attributes": [', attributes, ']}'));
    }

    function toString(uint256 value) public pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT license
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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}