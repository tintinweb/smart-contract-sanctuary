// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./CityParkUtils.sol";

library CityParkArt {

    using SafeMath for uint16;
    using Strings for uint256;
    using Strings for uint8;
    using Strings for uint16;

    function _generateFirstTriangle(CityParkUtils.ColorXY memory colorXY) public pure returns (string memory) {
        return string(abi.encodePacked( 
            "<polygon points='",
            (colorXY.x-50).toString(),
            ",",
            colorXY.y.toString(),
            ", ",
            (colorXY.x+25).toString(),
            ",",
            (colorXY.y-150).toString(),
            ", ",
            (colorXY.x+100).toString(),
            ",",
            colorXY.y.toString(),
            "' style='fill:",
            colorXY.color,
            "'/>"
        ));
    }

    function _generateSecondTriangle(CityParkUtils.ColorXY memory colorXY) public pure returns (string memory) {
        return string(abi.encodePacked( 
            "<polygon points='",
            (colorXY.x-70).toString(),
            ",",
            (colorXY.y+80).toString(),
            ", ",
            (colorXY.x+25).toString(),
            ",",
            (colorXY.y-70).toString(),
            ", ",
            (colorXY.x+120).toString(),
            ",",
            (colorXY.y+80).toString(),
            "' style='fill:",
            colorXY.color,
            "'/>"
        ));
    }

    function _generateTreeTriangles(CityParkUtils.ColorXY memory colorXY) public pure returns (string memory) {
      return string(abi.encodePacked(
            _generateFirstTriangle(colorXY),
            _generateSecondTriangle(colorXY)
      ));
    }

    function _generateTrees(CityParkUtils.Art memory artData) public pure returns (string memory) {
        string memory trees = '';
        for (uint i = 0; i < artData.numTrees; i++) {
            CityParkUtils.ColorXY memory colorXY = CityParkUtils.ColorXY({
                x: CityParkUtils.seededRandom(80,790,i*i,artData),
                y: CityParkUtils.seededRandom(150,500,i*i+1,artData),
                color: artData.overrideWhite ? CityParkUtils.getBWColor(i*2+3,artData) : CityParkUtils.getColor(i*2+3,artData)
            });
 
          trees = string(abi.encodePacked(
              trees,
              "<rect width='50' height='200' x='",
              colorXY.x.toString(),
              "' y='",
              colorXY.y.toString(),
              "'",
              " style='fill:",
              colorXY.color,
              "'/>",
              _generateTreeTriangles(colorXY)
            ));
        }

        return trees;
    }

    function _generateWindows(CityParkUtils.Art memory artData, CityParkUtils.ColorXY memory colorXY) public pure returns (string memory) {
        string memory windowColor = CityParkUtils.getColor(artData.randomSeed+3, artData);

        return string(abi.encodePacked(
            "<circle cx='",
            (colorXY.x + 80).toString(),
            "' cy='",
            (colorXY.y).toString(),
            "' r='15' style='fill:",
            windowColor,
            "' /><circle cx='",
            (colorXY.x - 80).toString(),
            "' cy='",
            (colorXY.y).toString(),
            "' r='15' style='fill:",
            windowColor,
            "' /><circle cx='",
            (colorXY.x).toString(),
            "' cy='",
            (colorXY.y).toString(),
            "' r='15' style='fill:",
            windowColor,
            "' />"
        ));
    }

    function _generateUFO(CityParkUtils.Art memory artData) public pure returns (string memory) {
        CityParkUtils.ColorXY memory colorXY = CityParkUtils.ColorXY({
            x: CityParkUtils.seededRandom(160,680,6,artData),
            y: CityParkUtils.seededRandom(60,300,9,artData),
            color: artData.overrideWhite ? CityParkUtils.getBWColor(69420,artData) : CityParkUtils.getColor(69420,artData)
        });

        return string(abi.encodePacked(
            "<ellipse rx='50' ry='80' cx='",
            colorXY.x.toString(),
            "' cy='",
            colorXY.y.toString(),
            "'",
            " style='fill:",
            colorXY.color,
            ";stroke-width:7;stroke:rgb(0,0,0)'/>",
            "<ellipse rx='150' ry='50' cx='",
            colorXY.x.toString(),
            "' cy='",
            colorXY.y.toString(),
            "'",
            " style='fill:",
            colorXY.color,
            ";stroke-width:3;stroke:rgb(0,0,0)'/>",
            "<ellipse rx='50' ry='80' cx='",
            colorXY.x.toString(),
            "' cy='",
            colorXY.y.toString(),
            "'",
            " style='fill:",
            colorXY.color,
            "'/>",
            _generateWindows(artData, colorXY)
        ));
    }

    function _generateSunLines(CityParkUtils.ColorXY memory colorXY) public pure returns (string memory) {
        string memory sunLines = '';
        for (uint16 i = 0; i < 8; i++) {
            sunLines = string(abi.encodePacked(
                sunLines,
                _generateSunLine(colorXY, uint16(i.mul(45)))
            ));
        }
        return sunLines;
    }

    function _generateSunLine(CityParkUtils.ColorXY memory colorXY, uint16 rotate) public pure returns (string memory) {
      return string(abi.encodePacked(
            "<path stroke='",
            colorXY.color,
            "' style='transform:rotate(",
            rotate.toString(),
            "deg);transform-origin:",
            colorXY.x.toString(),
            "px ",
            colorXY.y.toString(),
            "px' d='M",
            colorXY.x.toString(),
            " ",
            (colorXY.y-65).toString(),
            "V ",
            (colorXY.y-105).toString(),
            "' stroke-width='25' />"
      ));
    }

    function _generateSun(CityParkUtils.Art memory artData) public pure returns (string memory) {
        CityParkUtils.ColorXY memory colorXY = CityParkUtils.ColorXY({
            x: CityParkUtils.seededRandom(120,760,4,artData),
            y: CityParkUtils.seededRandom(105,300,20,artData),
            color: artData.overrideWhite ? CityParkUtils.getBWColor(6969,artData) : CityParkUtils.getColor(6969,artData)
        });

        return string(abi.encodePacked(
            "<circle  r='50' cx='",
            colorXY.x.toString(),
            "' cy='",
            colorXY.y.toString(),
            "' style='fill:",
            colorXY.color,
            "'/>",
            _generateSunLines(colorXY)
        ));
    }

    function _generateRug(CityParkUtils.Art memory artData) public pure returns (string memory) {
        string memory rug = '';
        uint rotateLeft = CityParkUtils.seededRandom(0, 1, 99, artData);
        uint randDegrees =  CityParkUtils.seededRandom(0, 90, 199, artData);
        string memory rotateStr = '';
        string memory oppRotateStr = '';
        if (rotateLeft == 0) {
            rotateStr = string(abi.encodePacked("-", randDegrees.toString()));
            oppRotateStr = string(abi.encodePacked("-", (randDegrees+90).toString()));
        } else {
            rotateStr = randDegrees.toString();
            oppRotateStr = string(abi.encodePacked("-", (90-randDegrees).toString()));
        }

        rug = string(abi.encodePacked(
            rug,
            "<rect width='1200' height='1500' x='600' y='-460' style='fill:",
            artData.overrideWhite ? CityParkUtils.getBWColor(9876,artData) : CityParkUtils.getColor(9876,artData),
            ";stroke-width:3;stroke:black' transform='rotate(",
            rotateStr,
            ")'/>"
        ));

        rug = string(abi.encodePacked(rug, _generateStripes(artData, oppRotateStr)));

        return rug;
    }

    function _generateStripes(CityParkUtils.Art memory artData, string memory oppRotateStr) public pure returns (string memory) {
        string memory stripes = '';
        uint numStripes = CityParkUtils.seededRandom(1, 4, 666, artData);
        for (uint i = 0; i < numStripes; i++) {
            string memory stripeColor = CityParkUtils.getColor(i*i+3,artData);
            uint randomPlace = CityParkUtils.seededRandom(100, 1100, i*2+3, artData);
            string memory xString;
            if (randomPlace > 600) {
                xString = string(abi.encodePacked("-", (randomPlace-600).toString()));
            } else {
                xString = (600-randomPlace).toString();
            }

            stripes = string(abi.encodePacked(
                stripes,
                "<rect width='50' height='1500' x='",
                xString,
                "' y='600'",
                " style='fill:",
                stripeColor,
                ";stroke-width:3;stroke:black' transform='rotate(",
                oppRotateStr,
                ")'/>"
            ));
        }
        return stripes;
    }

    function _generateAllBricks(CityParkUtils.Art memory artData) public pure returns (string memory) {
        uint numBrickStructures = CityParkUtils.seededRandom(1,3,5555555,artData);
        string memory allBricks = '';
        for (uint i = 0; i < numBrickStructures; i++) {
            string memory localBricks = _generateBricks(artData);
            bool xPos =  CityParkUtils.seededRandom(0,2,i*i+69,artData) > 1;
            bool yPos =  CityParkUtils.seededRandom(0,2,i*i+420,artData) > 1;
            uint randX = CityParkUtils.seededRandom(0,300,i*i+888,artData);
            uint randY = CityParkUtils.seededRandom(0,300,i*i+777,artData);

            string memory xString;
            string memory yString;
            if (xPos) {
                xString = randX.toString();
            } else {
                xString = string(abi.encodePacked("-", randX.toString()));
            }

            if (yPos) {
                yString = randY.toString();
            } else {
                yString = string(abi.encodePacked("-", randY.toString()));
            }

            localBricks = string(abi.encodePacked(
                "<g transform='translate(",
                xString,
                ",",
                yString,
                ")'>",
                localBricks
            ));
            allBricks = string(abi.encodePacked(allBricks, localBricks));
        }
        return allBricks;
    }

    function _generateBricks(CityParkUtils.Art memory artData) public pure returns (string memory) {
        string memory bricks = '';
        CityParkUtils.ColorXY memory colorXY = CityParkUtils.ColorXY({
            x: 300,
            y: 600,
            color: artData.overrideWhite ? CityParkUtils.getBWColor(1234, artData) : CityParkUtils.getColor(1234, artData)
        });
        uint numBricks = CityParkUtils.seededRandom(1,10,69,artData);
        uint height = CityParkUtils.seededRandom(0,10,70,artData);
        if (height % 2 == 0) {
            height++;
        }

        // Single half brick beginning
        for (uint i = 0; i < height / 2 + 1; i++) {
            bricks = string(abi.encodePacked(
                bricks,
                "<rect width='50' height='40' x='300' y='",
                (640+(80*i)).toString(),
                "' style='fill:",
                colorXY.color,
                ";stroke-width:3;stroke:black' transform='skewY(-10)'/>"
            ));
        }

        // Main brick faces
        for (uint i = 0; i < numBricks; i++) {
            for (uint j = 0; j < height / 2 + 1; j++) {

                // Top row, full row
                bricks = string(abi.encodePacked(
                    bricks,
                    "<rect width='100' height='40' x='",
                    (300+(i*100)).toString(),
                    "' y='",
                    (600+(80*j)).toString(),
                    "' style='fill:",
                    colorXY.color,
                    ";stroke-width:3;stroke:black' transform='skewY(-10)'/>"
                ));
            }

            // Handle negative x value
            uint baseXPos = 495;
            uint xLocPos;
            uint xLocNeg;
            string memory xString;
            if (i >= 5) {
                xLocNeg = 5 + ((i-5)*100);
                xString = xLocNeg.toString();
            } else {
                xLocPos = baseXPos - (i*100);
                xString = string(abi.encodePacked("-", xLocPos.toString()));
            }

            // Top face
            bricks = string(abi.encodePacked(
                bricks,
                "<rect width='100' height='40' x='",
                xString,
                "' y='560' style='fill:",
                colorXY.color,
                ";stroke-width:3;stroke:black' transform='skewY(-10) skewX(53)'/>"
            ));

            if (i != numBricks-1) {
                for (uint j = 0; j < height / 2 + 1; j++) {
                    bricks = string(abi.encodePacked(
                        bricks,
                        "<rect width='100' height='40' x='",
                        (350+(i*100)).toString(),
                        "' y='",
                        (640+(80*j)).toString(),
                        "' style='fill:",
                        colorXY.color,
                        ";stroke-width:3;stroke:black' transform='skewY(-10)'/>"
                    ));
                }
            }
        }

        // Single half brick end
        for (uint i = 0; i < height / 2 + 1; i++) {
            bricks = string(abi.encodePacked(
                bricks,
                "<rect width='50' height='40' x='",
                (250+(numBricks*100)).toString(),
                "' y='",
                (640+(80*i)).toString(),
                "' style='fill:",
                colorXY.color,
                ";stroke-width:3;stroke:black' transform='skewY(-10)'/>"
            ));
        }


        // Brick left face
        for (uint i = 0; i < height+1; i++) {
            string memory yString = '';
            if (i >= 6) {
                yString = (600+(15+((i-6)*40))).toString();
            } else {
                yString = (600-(225-(i*40))).toString();
            }


            bricks = string(abi.encodePacked(
                bricks,
                "<rect width='50' height='40' x='250' y='",
                yString,
                "' style='fill:",
                colorXY.color,
                ";stroke-width:3;stroke:black' transform='skewY(30)'/>"
            ));
        }

        bricks = string(abi.encodePacked(bricks, '</g>'));
        return bricks;
    }

    function _generateFence(CityParkUtils.Art memory artData) public pure returns (string memory) {
        string memory fence = '';
        uint howWide = CityParkUtils.seededRandom(1,7,69,artData);

        for (uint i = 0; i < 3; i++) {
            fence = string(abi.encodePacked(
                fence,
                "<rect width='",
                (howWide*100).toString(),
                "' height='20' x='275' y='",
                (600+(50*i)).toString(),
                "' style='fill:%23fff' />"
            ));
        }

        for (uint i = 0; i < howWide; i++) {
            uint xStart = 300+(i*100);
            fence = string(abi.encodePacked(
                "<rect width='50' height='150' x='",
                xStart.toString(),
                "' ' y='600' style='fill:%23fff' />",
                "<polygon points='",
                xStart.toString(),
                ",600, ",
                (xStart+25).toString(),
                ",550, ",
                (xStart+50).toString(),
                ",600' style='fill:%23fff' />"
            ));
        }

        fence = string(abi.encodePacked(fence, '</g>'));
        return fence;
    }

    function _generateAllFences(CityParkUtils.Art memory artData) public pure returns (string memory) {
        uint numFenceStructures = CityParkUtils.seededRandom(1,3,333333333,artData);
        string memory allFences = '';
        for (uint i = 0; i < numFenceStructures; i++) {
            string memory localFences = _generateFence(artData);
            bool xPos =  CityParkUtils.seededRandom(0,2,i*i+69,artData) > 1;
            bool yPos =  CityParkUtils.seededRandom(0,2,i*i+420,artData) > 1;
            uint randX = CityParkUtils.seededRandom(0,300,i*i+888,artData);
            uint randY = CityParkUtils.seededRandom(0,300,i*i+777,artData);

            string memory xString;
            string memory yString;
            if (xPos) {
                xString = randX.toString();
            } else {
                xString = string(abi.encodePacked("-", randX.toString()));
            }

            if (yPos) {
                yString = randY.toString();
            } else {
                yString = string(abi.encodePacked("-", randY.toString()));
            }

            localFences = string(abi.encodePacked(
                "<g transform='translate(",
                xString,
                ",",
                yString,
                ")'>",
                localFences
            ));
            localFences = string(abi.encodePacked(allFences, localFences));
        }
        return allFences;
    }
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

library CityParkUtils {

    using SafeMath for uint16;
    using Strings for uint256;
    using Strings for uint8;
    using Strings for uint16;

    struct Art {
        uint8 numTrees;
        bool hasUFO;
        bool hasSun;
        bool hasFence;
        bool hasBricks;
        bool overrideWhite;
        uint48 randomTimestamp;
        uint128 randomDifficulty;
        uint256 randomSeed;
    }

    struct ColorXY {
        uint16 x;
        uint16 y;
        string color;
    }

    string public constant _imageFooter = "</svg>";
    string public constant _borderRect = "<rect width='100%' height='166%' y='-33%' rx='20' style='fill:none;stroke:black;stroke-width:20'></rect>";

    function getColor(uint seed, Art memory artData) public pure returns(string memory) {
        return ['%23a85dee', '%2323cd73', '%23ef2839', '%230bd2fa', '%23fdd131'][seededRandom(0,5,seed,artData)];
    }

    function getBWColor(uint seed, Art memory artData) public pure returns(string memory) {
        return ['%23ffffff', '%23e8e8e8', '%23e0e0e0', '%23aeaeae', '%236e6e6e'][seededRandom(0,5,seed,artData)];
    }

    function _generateHeader(uint seed, Art memory artData) public pure returns (string memory) {
        string memory header = "data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink' id='citypark' width='300' height='500' viewBox='0 0 1000 1000' style='background-color:";
        return string(abi.encodePacked(
            header,
            getColor(seed, artData),
            "'><!--You are loved.-->"
        ));
    }

    function _boolToString(bool value) public pure returns (string memory) {
        if (value) {
            return "True";
        } else {
            return "False";
        }
    }

    function seededRandom(uint low, uint high, uint seed, Art memory artData) public pure returns (uint16) {
        return uint16(uint(uint256(keccak256(abi.encodePacked(seed, uint256(keccak256(abi.encodePacked(artData.randomDifficulty, artData.randomTimestamp, artData.randomSeed)))))))%high + low);
    }

    function _wrapTrait(string memory trait, string memory value) public pure returns(string memory) {
        return string(abi.encodePacked(
            '{"trait_type":"',
            trait,
            '","value":"',
            value,
            '"}'
        ));
    }
}