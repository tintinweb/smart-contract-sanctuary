// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "./IDNADecoder.sol";

library Constants {
    // SHARED COLOR CONSTANTS: Tongue, lip, inner
    function sharedColorTypes() internal pure returns (string[10] memory) {
        return ["red", "blue", "green", "yellow", "white", "black", "purple", "pink", "orange", "brown"];
    }

    function sharedColorsBoost() internal pure returns (uint8[10] memory) {
        return [0, 20, 20, 20, 20, 20, 20, 20, 0, 20];
    }

    function sharedColorsDp() internal pure returns (uint8[10] memory) {
        return [7, 4, 12, 15, 20, 1, 5, 9, 12, 15];
    }

    function sharedColorVals() internal pure returns (uint256[3][10] memory) {
        return [
            [uint256(1000 + 360), uint256(1000 + 0), uint256(1000 + 0)],
            [uint256(1000 + 142), uint256(1000 + -55), uint256(1000 + -10)],
            [uint256(1000 + 215), uint256(1000 + -55), uint256(1000 + -10)],
            [uint256(1000 + 300), uint256(1000 + -55), uint256(1000 + 120)],
            [uint256(1000 + 0), uint256(1000 + -625), uint256(1000 + 160)],
            [uint256(1000 + 0), uint256(1000 + -525), uint256(1000 + -40)],
            [uint256(1000 + 70), uint256(1000 + -55), uint256(1000 + -10)],
            [uint256(1000 + 15), uint256(1000 + -145), uint256(1000 + 110)],
            [uint256(1000 + 340), uint256(1000 + -20), uint256(1000 + 40)],
            [uint256(1000 + 360), uint256(1000 + -75), uint256(1000 + -90)]
        ];
    }

    function sharedColorMinAdj() internal pure returns (uint256[3][10] memory) {
        return [
            [uint256(0), 40, 20],
            [uint256(12), 100, 100],
            [uint256(25), 130, 80],
            [uint256(4), 170, 75],
            [uint256(0), 0, 20],
            [uint256(0), 0, 30],
            [uint256(20), 120, 80],
            [uint256(15), 30, 60],
            [uint256(15), 30, 10],
            [uint256(30), 50, 70]
        ];
    }

    function sharedColorMaxAdj() internal pure returns (uint256[3][10] memory) {
        return [
            [uint256(0), 25, 20],
            [uint256(18), 80, 100],
            [uint256(60), 80, 30],
            [uint256(5), 20, 20],
            [uint256(0), 0, 10],
            [uint256(0), 0, 30],
            [uint256(15), 50, 50],
            [uint256(15), 35, 20],
            [uint256(5), 30, 20],
            [uint256(5), 50, 30]
        ];
    }

    function shellShapes() internal pure returns (string[11] memory) {
        return [
            "common",
            "heart",
            "spade",
            "bigMouth",
            "threeLipped",
            "fan",
            "octo",
            "sharpTooth",
            "barnacle",
            "hamburger",
            "maxima"
        ];
    }

    function shellShapesDp() internal pure returns (uint8[11] memory) {
        return [25, 8, 10, 8, 10, 15, 10, 3, 6, 5, 0];
    }

    function shellShapesBoost() internal pure returns (uint8[11] memory) {
        return [0, 30, 0, 30, 0, 0, 0, 30, 30, 30, 50];
    }

    function shellShapeTypes() internal pure returns (uint8[11] memory) {
        return [0, 1, 0, 1, 0, 0, 0, 3, 5, 2, 4];
    }

    // TONGUE SHAPE CONSTANTS
    function tongueShapes() internal pure returns (string[5] memory) {
        return ["common", "forked", "heart", "star", "spiral"];
    }

    function tongueShapesBoost() internal pure returns (uint8[5] memory) {
        return [0, 0, 20, 20, 20];
    }

    function tongueShapesDp() internal pure returns (uint8[5] memory) {
        return [50, 25, 15, 8, 2];
    }

    function tongueShapeTypes() internal pure returns (uint8[5] memory) {
        return [0, 0, 2, 3, 4];
    }

    // SHELL COLOR CONSTANTS
    function shellColorVals() internal pure returns (int256[3][10] memory) {
        return [
            [int256(142), 170, -120],
            [int256(360), 205, -130],
            [int256(215), 170, -120],
            [int256(300), 170, 0],
            [int256(0), -200, 20],
            [int256(0), -300, -330],
            [int256(80), 170, -120],
            [int256(15), 80, 0],
            [int256(340), 170, -70],
            [int256(360), 150, -270]
        ];
    }

    function shellColorMinAdj() internal pure returns (int256[3][10] memory) {
        return [
            [int256(0), -20, -70],
            [int256(-2), -100, -100],
            [int256(-5), -130, -80],
            [int256(-0), -170, -75],
            [int256(0), 0, -20],
            [int256(0), 0, -70],
            [int256(-0), -120, -80],
            [int256(-5), -30, -100],
            [int256(-5), -40, -60],
            [int256(-0), -50, -50]
        ];
    }

    function shellColorMaxAdj() internal pure returns (int256[3][10] memory) {
        return [
            [int256(0), 45, 20],
            [int256(18), 80, 100],
            [int256(60), 80, 90],
            [int256(15), 45, 40],
            [int256(0), 0, 30],
            [int256(0), 0, 50],
            [int256(15), 50, 120],
            [int256(15), 35, 20],
            [int256(5), 30, 20],
            [int256(5), 50, 70]
        ];
    }

    // PATTERN CONSTANTS
    function patternStyles() internal pure returns (string[13] memory) {
        return [
            "none",
            "hearts",
            "flowers",
            "clovers",
            "diamonds",
            "stars",
            "tris",
            "spades",
            "polkadots",
            "saint",
            "exes",
            "arrows",
            "moroccan"
        ];
    }

    function patternBoost() internal pure returns (uint8[13] memory) {
        return [0, 20, 0, 0, 20, 20, 0, 20, 0, 20, 0, 20, 20];
    }

    function patternDp() internal pure returns (uint8[13] memory) {
        return [30, 6, 7, 10, 5, 3, 8, 4, 6, 10, 8, 2, 1];
    }

    function patternShapeTypes() internal pure returns (uint8[13] memory) {
        return [0, 1, 0, 0, 2, 3, 0, 2, 0, 5, 0, 3, 4];
    }

    // OTHER TRAITS INITIAL VALUES;
    function lifeSpan() internal pure returns (uint8[2] memory) {
        return [5, 15];
    }

    function size() internal pure returns (uint8[2] memory) {
        return [1, 100];
    }
}

/**
 * @title DNADecoder
 * @dev It interprets the traits from a clam dna
 */
contract DNADecoder is IDNADecoder, Initializable {
    using SafeMathUpgradeable for uint256;

    mapping(uint256 => Traits) public dnaToTraits;

    // global
    uint256[] private rngDigits;
    uint256 num; // it needs to remain to upgrade contract, even if not used due to legacy.
    uint256[3][4] private defaultHSV;
    uint256[3][4] private adjHSV;
    uint256 private rarityValue;
    string[10] private pearlBodyColor;
    uint8[10] private pearlBodyColorNumber;
    string[6] private pearlShape;
    uint8[6] private pearlShapeNumber;

    event DnaDecoded(uint256 timestamp, uint256 rng, bool isMaxima);

    function initialize() public virtual initializer {
        rarityValue = 1e18;
    }

    /**
     * @dev convenience function to get all dna traits. May have duplication.
     */
    function getDNADecoded(uint256 _rng) public view override returns (Traits memory) {
        return dnaToTraits[_rng];
    }

    // @dev necessary to avoid 'Unknown dynamically sized type' which happened when calling 'getDNADecoded'
    function getTraits(uint256 _rng)
        public
        view
        override
        returns (
            uint256,
            uint256,
            uint256,
            uint8[10] memory,
            uint8[6] memory
        )
    {
        Traits memory traits = dnaToTraits[_rng];
        return (traits.size, traits.lifespan, traits.rarityValue, traits.pearlBodyColorNumber, traits.pearlShapeNumber);
    }

    function getShellShape(uint256 _num) private returns (string memory result) {
        uint256 position;
        for (uint256 j; j < Constants.shellShapesDp().length; j++) {
            uint256 upper = uint256(Constants.shellShapesDp()[j]).mul(10).add(position).sub(1);

            if (_num >= position && _num <= upper) {
                // INCREASE RARITY
                rarityValue = (rarityValue.mul(uint256(Constants.shellShapesDp()[j]))).div(100);

                // PEARL BOOST
                if (Constants.shellShapeTypes()[j] > 0) {
                    pearlShapeNumber[Constants.shellShapeTypes()[j]] += Constants.shellShapesBoost()[j];
                }

                result = Constants.shellShapes()[j];
                break;
            }
            position = upper.add(1);
        }
        return result;
    }

    function getTongueShape(uint256 _num) private returns (string memory result) {
        uint256 position;
        for (uint256 j; j < Constants.tongueShapesDp().length; j++) {
            uint256 upper = uint256(Constants.tongueShapesDp()[j]).mul(10).add(position).sub(1);
            if (_num >= position && _num <= upper) {
                // INCREASE RARITY

                rarityValue = (rarityValue.mul(uint256(Constants.tongueShapesDp()[j]))).div(100);

                // PEARL BOOST
                if (Constants.tongueShapeTypes()[j] > 0) {
                    pearlShapeNumber[Constants.tongueShapeTypes()[j]] += Constants.tongueShapesBoost()[j];
                }

                result = Constants.tongueShapes()[j];
                break;
            }
            position = upper.add(1);
        }
        return result;
    }

    function getColorTraits(
        uint256 _num,
        uint8[10] memory colorsDp,
        uint8[10] memory colorsBoost,
        string[10] memory colors,
        uint256[3][10] memory colorVals,
        uint256[3][10] memory colorMinAdj,
        uint256[3][10] memory colorMaxAdj
    )
        internal
        returns (
            string memory result,
            uint256[3] memory defaultHSVInner,
            uint256[3] memory adjHSVInner
        )
    {
        uint256 position;
        for (uint256 j; j < colorsDp.length; j++) {
            uint256 upper = uint256(colorsDp[j]) * 10 + position - 1;

            if (_num >= position && _num <= upper) {
                // INCREASE RARITY
                rarityValue = (rarityValue.mul(uint256(colorsDp[j]))).div(100);

                // PEARL BOOST
                pearlBodyColorNumber[j] = pearlBodyColorNumber[j] + colorsBoost[j];

                result = colors[j];
                // Set Adjusted HSV
                defaultHSVInner = colorVals[j];
                adjHSVInner = setHSV(colorVals[j], colorMinAdj[j], colorMaxAdj[j]);
                break;
            }
            position = upper + 1;
        }

        return (result, defaultHSVInner, adjHSVInner);
    }

    function getPattern(uint256 _num) private returns (string memory result) {
        uint256 position;
        for (uint256 j; j < Constants.patternDp().length; j++) {
            uint256 upper = uint256(Constants.patternDp()[j]).mul(10).add(position).sub(1);

            if (_num >= position && _num <= upper) {
                // INCREASE RARITY
                rarityValue = (rarityValue.mul(uint256(Constants.patternDp()[j]))).div(100);

                // PEARL BOOST
                if (Constants.patternShapeTypes()[j] > 0) {
                    pearlShapeNumber[Constants.patternShapeTypes()[j]] =
                        pearlShapeNumber[Constants.patternShapeTypes()[j]] +
                        Constants.patternBoost()[j];
                }

                // SET PATTERN STYLE
                result = Constants.patternStyles()[j];
                break;
            }
            position = upper.add(1);
        }
        return result;
    }

    function getRarityInString() internal view returns (string memory) {
        string memory value;
        if (rarityValue < uint256(150e7)) {
            value = "Legendary";
        } else if (rarityValue < uint256(725e7)) {
            value = "Epic";
        } else if (rarityValue < uint256(3000e7)) {
            value = "Ultra Rare";
        } else if (rarityValue < uint256(10200e7)) {
            value = "Rare";
        } else if (rarityValue < (32300e7)) {
            value = "Uncommon";
        } else {
            value = "Common";
        }
        return value;
    }

    function random(uint256 seed, uint256 mod) private view returns (uint256) {
        bytes32 bHash = blockhash(block.number - 1);
        uint256 randomNumber = uint256(uint256(keccak256(abi.encodePacked(block.timestamp, bHash, seed))) % mod);
        return randomNumber;
    }

    function setHSV(
        uint256[3] memory val,
        uint256[3] memory minAdj,
        uint256[3] memory maxAdj
    ) private view returns (uint256[3] memory) {
        uint256 adjH = val[0] - minAdj[0] + (random(2, (maxAdj[0] + minAdj[0] + 1)));
        uint256 adjS = val[1] - minAdj[1] + (random(3, (maxAdj[1] + minAdj[1] + 1)));
        uint256 adjV = val[2] - minAdj[2] + (random(5, (maxAdj[2] + minAdj[2] + 1)));

        return [adjH, adjS, adjV];
    }

    function getGlowValue(uint256 _num) private pure returns (bool glowValue) {
        if (_num == 999) {
            glowValue = true;
        } else {
            glowValue = false;
        }
    }

    /**
     * @dev adds elements to rngDigits
     * Digits are added backwards
     */
    function generateDigits(uint256 _num) private {
        uint256 _number = _num;
        while (_number > 0) {
            uint8 digit = uint8(_number % 10);
            _number = _number / 10;
            rngDigits.push(digit);
        }
    }

    /**
     * @dev adds color traits; used in setColorTraits
     */
    function addColorTraits(uint256 _num)
        private
        returns (
            string memory,
            uint256[3] memory,
            uint256[3] memory
        )
    {
        (string memory color, uint256[3] memory defaultHSVInner, uint256[3] memory adjHSVInner) = getColorTraits(
            _num,
            Constants.sharedColorsDp(),
            Constants.sharedColorsBoost(),
            Constants.sharedColorTypes(),
            Constants.sharedColorVals(),
            Constants.sharedColorMinAdj(),
            Constants.sharedColorMaxAdj()
        );

        return (color, defaultHSVInner, adjHSVInner);
    }

    /**
     * @dev helper function for decodeTraitsFromDNA
     */
    function setColorTraits(uint256 rng) private {
        setTongueColorTraits(rng);
        setShellColorTraits(rng);
        setInnerColorTraits(rng);
        setLipColorTraits(rng);

        dnaToTraits[rng].defaultHSV = defaultHSV;
        dnaToTraits[rng].adjHSV = adjHSV;
    }

    function setTongueColorTraits(uint256 rng) private {
        uint256 num = rngDigits[6].add((rngDigits[7]).mul(10)).add((rngDigits[8]).mul(100));
        (
            string memory tongueColor,
            uint256[3] memory tongueDefaultHSVInner,
            uint256[3] memory tongueAdjHSVInner
        ) = addColorTraits(num);
        dnaToTraits[rng].tongueColor = tongueColor;
        defaultHSV[0] = tongueDefaultHSVInner;
        adjHSV[0] = tongueAdjHSVInner;
    }

    function setShellColorTraits(uint256 rng) private {
        uint256 num = rngDigits[9].add((rngDigits[10]).mul(10)).add((rngDigits[11]).mul(100));
        (
            string memory shellColor,
            uint256[3] memory shellDefaultHSVInner,
            uint256[3] memory shellAdjHSVInner
        ) = addColorTraits(num);
        dnaToTraits[rng].shellColor = shellColor;
        defaultHSV[1] = shellDefaultHSVInner;
        adjHSV[1] = shellAdjHSVInner;
    }

    function setInnerColorTraits(uint256 rng) private {
        uint256 num = rngDigits[12].add(rngDigits[13].mul(10)).add(rngDigits[14].mul(100));
        (
            string memory innerColor,
            uint256[3] memory innerDefaultHSVInner,
            uint256[3] memory innerAdjHSVInner
        ) = addColorTraits(num);
        dnaToTraits[rng].innerColor = innerColor;
        defaultHSV[2] = innerDefaultHSVInner;
        adjHSV[2] = innerAdjHSVInner;
    }

    function setLipColorTraits(uint256 rng) private {
        uint256 num = rngDigits[15].add(rngDigits[16].mul(10)).add(rngDigits[17].mul(100));
        (
            string memory lipColor,
            uint256[3] memory lipDefaultHSVInner,
            uint256[3] memory lipAdjHSVInner
        ) = addColorTraits(num);

        dnaToTraits[rng].lipColor = lipColor;
        defaultHSV[3] = lipDefaultHSVInner;
        adjHSV[3] = lipAdjHSVInner;
    }

    /**
     * @dev helper function for decodeTraitsFromDNA
     */
    function setShellShape(uint256 rng, bool isMaxima) private {
        // SHELL SHAPE TRAIT
        if (isMaxima) {
            dnaToTraits[rng].shellShape = "maxima";
        } else {
            uint256 num = rngDigits[0].add((rngDigits[1]).mul(10)).add((rngDigits[2]).mul(100));
            dnaToTraits[rng].shellShape = getShellShape(num);
        }
    }

    /**
     * @dev helper function for decodeTraitsFromDNA
     */
    function setRemainingTraits(uint256 rng, bool isMaxima) private {
        // TONGUE SHAPE TRAIT
        uint256 num = rngDigits[3].add(rngDigits[4].mul(10)).add(rngDigits[5].mul(100));

        dnaToTraits[rng].tongueShape = getTongueShape(num);

        // PATTERN TRAIT
        num = rngDigits[18].add(rngDigits[19].mul(10)).add(rngDigits[20].mul(100));

        dnaToTraits[rng].pattern = getPattern(num);

        // SIZE TRAITS
        num = rngDigits[21].add(rngDigits[22].mul(10));
        dnaToTraits[rng].size = num + 1;

        // LIFE SPAN TRAITS
        num = rngDigits[23].add(rngDigits[24].mul(10));

        dnaToTraits[rng].lifespan = (Constants.lifeSpan()[0] +
            ((num % (Constants.lifeSpan()[1] - Constants.lifeSpan()[0])) + 1));

        // GLOW TRAITS
        num = rngDigits[25].add(rngDigits[26].mul(10)).add(rngDigits[27].mul(100));

        dnaToTraits[rng].glow = getGlowValue(num);

        if (isMaxima) {
            rarityValue = rarityValue.div(10);
        }

        dnaToTraits[rng].rarity = getRarityInString();

        dnaToTraits[rng].rarityValue = rarityValue;

        dnaToTraits[rng].pearlShapeNumber = pearlShapeNumber;
        dnaToTraits[rng].pearlBodyColorNumber = pearlBodyColorNumber;
    }

    /**
     * @dev decode and set traits
     */
    function decodeTraitsFromDNA(uint256 rng, bool isMaxima) public override {
        generateDigits(rng);

        //Color traits
        setColorTraits(rng);

        // SHELL SHAPE TRAIT
        setShellShape(rng, isMaxima);

        setRemainingTraits(rng, isMaxima);

        emit DnaDecoded(block.timestamp, rng, isMaxima);

        // reset global values
        delete pearlShapeNumber;
        delete pearlBodyColorNumber;
        delete defaultHSV;
        delete adjHSV;
        delete rngDigits;
        rarityValue = 1e18;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
library SafeMathUpgradeable {
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

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

interface IDNADecoder {
    struct Traits {
        string tongueShape;
        string tongueColor;
        string shellShape;
        string shellColor;
        string innerColor;
        string lipColor;
        string pattern;
        uint256 size;
        uint256 lifespan;
        bool glow;
        string rarity;
        uint256 rarityValue;
        uint8[10] pearlBodyColorNumber;
        uint8[6] pearlShapeNumber;
        uint256[3][4] defaultHSV;
        uint256[3][4] adjHSV;
    }

    function decodeTraitsFromDNA(uint256, bool) external;

    function getDNADecoded(uint256) external view returns (Traits memory);

    /// @dev necessary to avoid 'Unknown dynamically sized type', which happened when calling 'getDNADecoded'
    function getTraits(uint256)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint8[10] memory,
            uint8[6] memory
        );
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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