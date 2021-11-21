/**
 *Submitted for verification at Etherscan.io on 2021-11-21
*/

// File: contracts/StringBuffer.sol

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @notice Holds a string that can expand dynamically.
 */
struct StringBuffer {
    string[] buffer;
    uint numberOfStrings;
    uint totalStringLength;
}

library StringBufferLibrary {
    /**
     * @dev Copies 32 bytes of `src` starting at `srcIndex` into `dst` starting at `dstIndex`.
     */
    function memcpy32(string memory src, uint srcIndex, bytes memory dst, uint dstIndex) internal pure {
        assembly {
            mstore(add(add(dst, 32), dstIndex), mload(add(add(src, 32), srcIndex)))
        }
    }

    /**
     * @dev Copies 1 bytes of `src` at `srcIndex` into `dst` at `dstIndex`.
     *      This uses the same amount of gas as `memcpy32`, so prefer `memcpy32` if at all possible.
     */
    function memcpy1(string memory src, uint srcIndex, bytes memory dst, uint dstIndex) internal pure {
        assembly {
            mstore8(add(add(dst, 32), dstIndex), shr(248, mload(add(add(src, 32), srcIndex))))
        }
    }

    /**
     * @dev Copies a string into `dst` starting at `dstIndex` with a maximum length of `dstLen`.
     *      This function will not write beyond `dstLen`. However, if `dstLen` is not reached, it may write zeros beyond the length of the string.
     */
    function copyString(string memory src, bytes memory dst, uint dstIndex, uint dstLen) internal pure returns (uint) {
        uint srcIndex;
        uint srcLen = bytes(src).length;

        for (; srcLen > 31 && srcIndex < srcLen && srcIndex < dstLen - 31; srcIndex += 32) {
            memcpy32(src, srcIndex, dst, dstIndex + srcIndex);
        }
        for (; srcIndex < srcLen && srcIndex < dstLen; ++srcIndex) {
            memcpy1(src, srcIndex, dst, dstIndex + srcIndex);
        }

        return dstIndex + srcLen;
    }

    /**
     * @dev Adds `str` to the end of the internal buffer.
     */
    function pushToStringBuffer(StringBuffer memory self, string memory str) internal pure returns (StringBuffer memory) {
        if (self.buffer.length == self.numberOfStrings) {
            string[] memory newBuffer = new string[](self.buffer.length * 2);
            for (uint i = 0; i < self.buffer.length; ++i) {
                newBuffer[i] = self.buffer[i];
            }
            self.buffer = newBuffer;
        }

        self.buffer[self.numberOfStrings] = str;
        self.numberOfStrings++;
        self.totalStringLength += bytes(str).length;

        return self;
    }

    /**
     * @dev Concatenates `str` to the end of the last string in the internal buffer.
     */
    function concatToLastString(StringBuffer memory self, string memory str) internal pure {
        if (self.numberOfStrings == 0) {
            self.numberOfStrings++;
        }
        uint idx = self.numberOfStrings - 1;
        self.buffer[idx] = string(abi.encodePacked(self.buffer[idx], str));

        self.totalStringLength += bytes(str).length;
    }

    /**
     * @notice Creates a new empty StringBuffer
     * @dev The initial capacity is 16 strings
     */
    function empty() external pure returns (StringBuffer memory) {
        return StringBuffer(new string[](1), 0, 0);
    }

    /**
     * @notice Converts the contents of the StringBuffer into a string.
     * @dev This runs in O(n) time.
     */
    function get(StringBuffer memory self) internal pure returns (string memory) {
        bytes memory output = new bytes(self.totalStringLength);

        uint ptr = 0;
        for (uint i = 0; i < self.numberOfStrings; ++i) {
            ptr = copyString(self.buffer[i], output, ptr, self.totalStringLength);
        }

        return string(output);
    }

    /**
     * @notice Appends a string to the end of the StringBuffer
     * @dev Internally the StringBuffer keeps a `string[]` that doubles in size when extra capacity is needed.
     */
    function append(StringBuffer memory self, string memory str) internal pure {
        uint idx = self.numberOfStrings == 0 ? 0 : self.numberOfStrings - 1;
        if (bytes(self.buffer[idx]).length + bytes(str).length <= 1024) {
            concatToLastString(self, str);
        } else {
            pushToStringBuffer(self, str);
        }
    }
}

// File: contracts/Integer.sol


pragma solidity ^0.8.0;

library Integer {
    /**
     * @dev Gets the bit at the given position in the given integer.
     *      31 is the leftmost bit, 0 is the rightmost bit.
     *
     *      For example: bitAt(2, 0) == 0, because the rightmost bit of 10 is 0
     *                   bitAt(2, 1) == 1, because the second to last bit of 10 is 1
     */
    function bitAt(uint integer, uint pos) external pure returns (uint) {
        require(pos <= 31, "pos > 31");

        return (integer & (1 << pos)) >> pos;
    }

    /**
     * @dev Gets the value of the bits between left and right, both inclusive, in the given integer.
     *      31 is the leftmost bit, 0 is the rightmost bit.
     *      
     *      For example: bitsFrom(10, 3, 1) == 7 (101 in binary), because 10 is *101*0 in binary
     *                   bitsFrom(10, 2, 0) == 2 (010 in binary), because 10 is 1*010* in binary
     */
    function bitsFrom(uint integer, uint left, uint right) external pure returns (uint) {
        require(left >= right, "left > right");
        require(left <= 31, "left > 31");

        uint delta = left - right + 1;

        return (integer & (((1 << delta) - 1) << right)) >> right;
    }
}

// File: contracts/Rarities.sol


pragma solidity ^0.8.0;

library Rarities {
    function dominant() internal pure returns (uint16[8] memory ret) {
        ret = [
            2500,
            2200,
            1900,
            1300,
            800,
            600,
            400,
            300
        ];
    }
    
    function recessive() internal pure returns (uint16[6] memory ret) {
        ret = [
            4000,
            2500,
            1500,
            1000,
            600,
            400
        ];
    }
    
    function outfit() internal pure returns (uint16[27] memory ret) {
        ret = [
            700,
            700,
            700,
            600,
            600,
            600,
            600,
            600,
            600,
            600,
            600,
            500,
            500,
            400,
            400,
            300,
            200,
            200,
            100,
            100,
            100,
            75,
            50,
            50,
            50,
            50,
            25
        ];
    }
    
    function handaccessory() internal pure returns (uint16[16] memory ret) {
        ret = [
            5000,
            600,
            600,
            600,
            600,
            510,
            500,
            500,
            300,
            300,
            150,
            100,
            100,
            75,
            40,
            25
        ];
    }
    
    function mouth() internal pure returns (uint16[22] memory ret) {
        ret = [
            2000,
            1000,
            1000,
            1000,
            700,
            700,
            700,
            700,
            400,
            300,
            300,
            300,
            175,
            100,
            100,
            100,
            100,
            100,
            75,
            75,
            50,
            25
        ];
    }
    
    function eyes() internal pure returns (uint16[24] memory ret) {
        ret = [
            2500,
            600,
            600,
            600,
            600,
            600,
            600,
            400,
            400,
            400,
            400,
            400,
            400,
            400,
            400,
            100,
            100,
            100,
            100,
            75,
            75,
            75,
            50,
            25
        ];
    }
    
    function headaccessory() internal pure returns (uint16[29] memory ret) {
        ret = [
            3000,
            500,
            500,
            500,
            500,
            500,
            500,
            500,
            500,
            400,
            300,
            300,
            200,
            200,
            200,
            200,
            200,
            100,
            100,
            100,
            100,
            100,
            100,
            100,
            100,
            75,
            50,
            50,
            25
        ];
    }
}
// File: contracts/Rng.sol


pragma solidity ^0.8.0;

/**
 * @title A pseudo random number generator
 *
 * @dev This is not a true random number generator because smart contracts must be deterministic (every node a transaction goes to must produce the same result).
 *      True randomness requires an oracle which is both expensive in terms of gas and would take a critical part of the project off the chain.
 */
struct Rng {
    bytes32 state;
}

/**
 * @title A library for working with the Rng struct.
 *
 * @dev Rng cannot be a contract because then anyone could manipulate it by generating random numbers.
 */
library RngLibrary {
    /**
     * Creates a new Rng.
     */
    function newRng() internal view returns (Rng memory) {
        return Rng(getEntropy());
    }

    /**
     * Creates a pseudo-random value from the current block miner's address and sender.
     */
    function getEntropy() internal view returns (bytes32) {
        return keccak256(abi.encodePacked(block.coinbase, msg.sender));
    }

    /**
     * Generates a random uint256.
     */
    function generate(Rng memory self) internal view returns (uint256) {
        self.state = keccak256(abi.encodePacked(getEntropy(), self.state));
        return uint256(self.state);
    }

    /**
     * Generates a random uint256 from min to max inclusive.
     *
     * @dev This function is not subject to modulo bias.
     *      The chance that this function has to reroll is astronomically unlikely, but it can theoretically reroll forever.
     */
    function generate(Rng memory self, uint min, uint max) internal view returns (uint256) {
        require(min <= max, "min > max");

        uint delta = max - min;

        if (delta == 0) {
            return min;
        }

        return generate(self) % (delta + 1) + min;
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol



pragma solidity ^0.8.0;

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol



pragma solidity ^0.8.0;


/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// File: contracts/Enums.sol


pragma solidity ^0.8.0;

enum RerollTrait {
    BgColor,
    Outfit,
    HandAccessory,
    Mouth,
    Eyes,
    HeadAccessory
}

enum Special {
    NONE,
    DEVIL,
    GHOST,
    HIPPIE,
    JOKER,
    PRISONER,
    SQUID_GAME,
    WHERES_WALDO,
    HAZMAT,
    ASTRONAUT
}

enum Dominant {
    SKELETON,
    VAMPIRE,
    MUMMY,
    GHOST,
    WITCH,
    FRANKENSTEIN,
    WEREWOLF,
    PUMPKINHEAD
}

enum Recessive {
    SKELETON,
    VAMPIRE,
    MUMMY,
    GHOST,
    DEVIL,
    KONG
}

enum BgColor {
    DARK_BLUE,
    GRAY,
    LIGHT_BLUE,
    ORANGE,
    PINK,
    PURPLE,
    RED,
    TAN,
    TEAL,
    GREEN,
    RAINBOW
}

enum Outfit {
    WHITE_SHORTS,
    PINK_SHORTS,
    GRAY_PANTS,
    WHITE_AND_BLUE,
    PURPLE_SHORTS,
    PINK_AND_PURPLE,
    BROWN_AND_WHITE,
    BROWN_AND_BLUE,
    BLUE_SHORTS,
    BLUE_AND_WHITE,
    UNDERGARMENTS,
    LOUNGEWEAR,
    HOBO,
    SPORTS_JERSEY,
    GOLD_CHAIN,
    PAJAMAS,
    OVERALLS,
    SPEEDO,
    NINJA_SUIT,
    KARATE_UNIFORM,
    NONE,
    LUMBERJACK,
    PRIEST,
    TUX,
    SKELETON,
    CAMO,
    ARMOR
}

enum HandAccessory {
    NONE,
    BLOODY_KNIFE,
    BOW_AND_ARROW,
    SWORD,
    PITCHFORK,
    WAND,
    SPIKED_BASEBALL_BAT,
    ENERGY_DRINK,
    NINJA_STARS,
    NUNCHUCKS,
    POOP,
    FLAMETHROWER,
    HOOKS,
    WEIGHTS,
    SKULL,
    BRAIN
}

enum Mouth {
    NONE,
    HAPPY,
    MAD,
    SMILE,
    FANGS,
    HAPPY_FANGS,
    MAD_FANGS,
    SMILE_FANGS,
    SINGLE_TOOTH,
    DIRTY_TEETH,
    SMILE_DIRTY_TEETH,
    MAD_DIRTY_TEETH,
    BLOODY_FANGS,
    BLACK_MASK,
    HAPPY_BUCK_TEETH,
    HAPPY_SINGLE_TOOTH,
    MAD_SINGLE_TOOTH,
    SMILE_SINGLE_TOOTH,
    BREATHING_FIRE,
    GOLD_GRILLS,
    KISS,
    SMOKING_JOINT
}

enum Eyes {
    NONE,
    BLACK_EYE,
    BLACKOUT,
    BLEEDING,
    BLOODSHOT,
    WATERY,
    WHITE,
    BIGGER_BLACK_EYES,
    BIGGER_BLEEDING,
    BIGGER_WATERY,
    SMALLER_BLACK_EYES,
    SMALLER_BLEEDING,
    SMALLER_BLOODSHOT,
    SMALLER_WATERY,
    SMALLER,
    SUNGLASSES,
    EYE_PATCH,
    VR_HEADSET,
    DEAD,
    _3D_GLASSES,
    HEART_EYES,
    LASER_GLASSES,
    NINJA_MASK,
    LASER_EYES
}

enum HeadAccessory {
    NONE,
    BUCKET_HAT,
    FLOWER,
    SPORTS_HEADBAND,
    CHEF_HAT,
    BLUE_DURAG,
    RED_DURAG,
    SPIKY_HAIR,
    BONES,
    RICE_HAT,
    BEANIE_CAP,
    SANTA_HAT,
    HEAD_WOUND,
    HEADPHONES,
    GOLD_STUDS,
    WIZARD_HAT,
    LONG_HAIR,
    AIR_PODS,
    WHITE_PARTY_HAT,
    BLUE_PARTY_HAT,
    RED_PARTY_HAT,
    GREEN_PARTY_HAT,
    YELLOW_PARTY_HAT,
    PURPLE_PARTY_HAT,
    PIRATE_HAT,
    KING_CROWN,
    JOKER_HAT,
    DEVIL_HORNS,
    BRAINS
}

library Enums {
    function toString(Special v) external pure returns (string memory) {
        if (v == Special.NONE) {
            return "";
        }
    
        if (v == Special.DEVIL) {
            return "Devil";
        }
    
        if (v == Special.GHOST) {
            return "Ghost";
        }
    
        if (v == Special.HIPPIE) {
            return "Hippie";
        }
    
        if (v == Special.JOKER) {
            return "Society";
        }
    
        if (v == Special.PRISONER) {
            return "Prisoner";
        }
    
        if (v == Special.SQUID_GAME) {
            return "Squid Girl";
        }
    
        if (v == Special.WHERES_WALDO) {
            return "Where's Waldo?";
        }
    
        if (v == Special.HAZMAT) {
            return "Hazmat";
        }
    
        if (v == Special.ASTRONAUT) {
            return "Astronaut";
        }
        revert("invalid special");
    }
    
    function toString(Dominant v) external pure returns (string memory) {
        if (v == Dominant.SKELETON) {
            return "Skeleton";
        }
    
        if (v == Dominant.VAMPIRE) {
            return "Vampire";
        }
    
        if (v == Dominant.MUMMY) {
            return "Mummy";
        }
    
        if (v == Dominant.GHOST) {
            return "Ghost";
        }
    
        if (v == Dominant.WITCH) {
            return "Witch";
        }
    
        if (v == Dominant.FRANKENSTEIN) {
            return "Frankenstein";
        }
    
        if (v == Dominant.WEREWOLF) {
            return "Werewolf";
        }
    
        if (v == Dominant.PUMPKINHEAD) {
            return "Pumpkinhead";
        }
        revert("invalid dominant");
    }
    
    function toString(Recessive v) external pure returns (string memory) {
        if (v == Recessive.SKELETON) {
            return "Skeleton";
        }
    
        if (v == Recessive.VAMPIRE) {
            return "Vampire";
        }
    
        if (v == Recessive.MUMMY) {
            return "Mummy";
        }
    
        if (v == Recessive.GHOST) {
            return "Ghost";
        }
    
        if (v == Recessive.DEVIL) {
            return "Devil";
        }
    
        if (v == Recessive.KONG) {
            return "Kong";
        }
        revert("invalid recessive");
    }
    
    function toString(BgColor v) external pure returns (string memory) {
        if (v == BgColor.DARK_BLUE) {
            return "Dark Blue";
        }
    
        if (v == BgColor.GRAY) {
            return "Gray";
        }
    
        if (v == BgColor.LIGHT_BLUE) {
            return "Light Blue";
        }
    
        if (v == BgColor.ORANGE) {
            return "Orange";
        }
    
        if (v == BgColor.PINK) {
            return "Pink";
        }
    
        if (v == BgColor.PURPLE) {
            return "Purple";
        }
    
        if (v == BgColor.RED) {
            return "Red";
        }
    
        if (v == BgColor.TAN) {
            return "Tan";
        }
    
        if (v == BgColor.TEAL) {
            return "Teal";
        }
    
        if (v == BgColor.GREEN) {
            return "Green";
        }
    
        if (v == BgColor.RAINBOW) {
            return "Rainbow";
        }
        revert("invalid bgcolor");
    }
    
    function toString(Outfit v) external pure returns (string memory) {
        if (v == Outfit.WHITE_SHORTS) {
            return "White Shorts";
        }
    
        if (v == Outfit.PINK_SHORTS) {
            return "Pink Shorts";
        }
    
        if (v == Outfit.GRAY_PANTS) {
            return "Gray Pants";
        }
    
        if (v == Outfit.WHITE_AND_BLUE) {
            return "White and Blue";
        }
    
        if (v == Outfit.PURPLE_SHORTS) {
            return "Purple Shorts";
        }
    
        if (v == Outfit.PINK_AND_PURPLE) {
            return "Pink and Purple";
        }
    
        if (v == Outfit.BROWN_AND_WHITE) {
            return "Brown and White";
        }
    
        if (v == Outfit.BROWN_AND_BLUE) {
            return "Brown and Blue";
        }
    
        if (v == Outfit.BLUE_SHORTS) {
            return "Blue Shorts";
        }
    
        if (v == Outfit.BLUE_AND_WHITE) {
            return "Blue and White";
        }
    
        if (v == Outfit.UNDERGARMENTS) {
            return "Undergarments";
        }
    
        if (v == Outfit.LOUNGEWEAR) {
            return "Loungewear";
        }
    
        if (v == Outfit.HOBO) {
            return "Hobo";
        }
    
        if (v == Outfit.SPORTS_JERSEY) {
            return "Sports Jersey";
        }
    
        if (v == Outfit.GOLD_CHAIN) {
            return "Gold Chain";
        }
    
        if (v == Outfit.PAJAMAS) {
            return "Pajamas";
        }
    
        if (v == Outfit.OVERALLS) {
            return "Overalls";
        }
    
        if (v == Outfit.SPEEDO) {
            return "Speedo";
        }
    
        if (v == Outfit.NINJA_SUIT) {
            return "Ninja Suit";
        }
    
        if (v == Outfit.KARATE_UNIFORM) {
            return "Karate Uniform";
        }
    
        if (v == Outfit.NONE) {
            return "";
        }
    
        if (v == Outfit.LUMBERJACK) {
            return "Lumberjack";
        }
    
        if (v == Outfit.PRIEST) {
            return "Priest";
        }
    
        if (v == Outfit.TUX) {
            return "Tux";
        }
    
        if (v == Outfit.SKELETON) {
            return "Skeleton";
        }
    
        if (v == Outfit.CAMO) {
            return "Camo";
        }
    
        if (v == Outfit.ARMOR) {
            return "Armor";
        }
        revert("invalid outfit");
    }
    
    function toString(HandAccessory v) external pure returns (string memory) {
        if (v == HandAccessory.NONE) {
            return "";
        }
    
        if (v == HandAccessory.BLOODY_KNIFE) {
            return "Bloody Knife";
        }
    
        if (v == HandAccessory.BOW_AND_ARROW) {
            return "Bow and Arrow";
        }
    
        if (v == HandAccessory.SWORD) {
            return "Sword";
        }
    
        if (v == HandAccessory.PITCHFORK) {
            return "Pitchfork";
        }
    
        if (v == HandAccessory.WAND) {
            return "Wand";
        }
    
        if (v == HandAccessory.SPIKED_BASEBALL_BAT) {
            return "Spiked Baseball Bat";
        }
    
        if (v == HandAccessory.ENERGY_DRINK) {
            return "Energy Drink";
        }
    
        if (v == HandAccessory.NINJA_STARS) {
            return "Ninja Stars";
        }
    
        if (v == HandAccessory.NUNCHUCKS) {
            return "Nunchucks";
        }
    
        if (v == HandAccessory.POOP) {
            return "Poop";
        }
    
        if (v == HandAccessory.FLAMETHROWER) {
            return "Flamethrower";
        }
    
        if (v == HandAccessory.HOOKS) {
            return "Hooks";
        }
    
        if (v == HandAccessory.WEIGHTS) {
            return "Weights";
        }
    
        if (v == HandAccessory.SKULL) {
            return "Skull";
        }
    
        if (v == HandAccessory.BRAIN) {
            return "Brain";
        }
        revert("invalid handaccessory");
    }
    
    function toString(Mouth v) external pure returns (string memory) {
        if (v == Mouth.NONE) {
            return "";
        }
    
        if (v == Mouth.HAPPY) {
            return "Happy";
        }
    
        if (v == Mouth.MAD) {
            return "Mad";
        }
    
        if (v == Mouth.SMILE) {
            return "Smile";
        }
    
        if (v == Mouth.FANGS) {
            return "Fangs";
        }
    
        if (v == Mouth.HAPPY_FANGS) {
            return "Happy Fangs";
        }
    
        if (v == Mouth.MAD_FANGS) {
            return "Mad Fangs";
        }
    
        if (v == Mouth.SMILE_FANGS) {
            return "Smile Fangs";
        }
    
        if (v == Mouth.SINGLE_TOOTH) {
            return "Single Tooth";
        }
    
        if (v == Mouth.DIRTY_TEETH) {
            return "Dirty Teeth";
        }
    
        if (v == Mouth.SMILE_DIRTY_TEETH) {
            return "Smile Dirty Teeth";
        }
    
        if (v == Mouth.MAD_DIRTY_TEETH) {
            return "Mad Dirty Teeth";
        }
    
        if (v == Mouth.BLOODY_FANGS) {
            return "Bloody Fangs";
        }
    
        if (v == Mouth.BLACK_MASK) {
            return "Black Mask";
        }
    
        if (v == Mouth.HAPPY_BUCK_TEETH) {
            return "Happy Buck Teeth";
        }
    
        if (v == Mouth.HAPPY_SINGLE_TOOTH) {
            return "Happy Single Tooth";
        }
    
        if (v == Mouth.MAD_SINGLE_TOOTH) {
            return "Mad Single Tooth";
        }
    
        if (v == Mouth.SMILE_SINGLE_TOOTH) {
            return "Smile Single Tooth";
        }
    
        if (v == Mouth.BREATHING_FIRE) {
            return "Breathing Fire";
        }
    
        if (v == Mouth.GOLD_GRILLS) {
            return "Gold Grills";
        }
    
        if (v == Mouth.KISS) {
            return "Kiss";
        }
    
        if (v == Mouth.SMOKING_JOINT) {
            return "Smoking Joint";
        }
        revert("invalid mouth");
    }
    
    function toString(Eyes v) external pure returns (string memory) {
        if (v == Eyes.NONE) {
            return "";
        }
    
        if (v == Eyes.BLACK_EYE) {
            return "Black Eye";
        }
    
        if (v == Eyes.BLACKOUT) {
            return "Blackout";
        }
    
        if (v == Eyes.BLEEDING) {
            return "Bleeding";
        }
    
        if (v == Eyes.BLOODSHOT) {
            return "Bloodshot";
        }
    
        if (v == Eyes.WATERY) {
            return "Watery";
        }
    
        if (v == Eyes.WHITE) {
            return "White";
        }
    
        if (v == Eyes.BIGGER_BLACK_EYES) {
            return "Bigger Black Eyes";
        }
    
        if (v == Eyes.BIGGER_BLEEDING) {
            return "Bigger Bleeding";
        }
    
        if (v == Eyes.BIGGER_WATERY) {
            return "Bigger Watery";
        }
    
        if (v == Eyes.SMALLER_BLACK_EYES) {
            return "Smaller Black Eyes";
        }
    
        if (v == Eyes.SMALLER_BLEEDING) {
            return "Smaller Bleeding";
        }
    
        if (v == Eyes.SMALLER_BLOODSHOT) {
            return "Smaller Bloodshot";
        }
    
        if (v == Eyes.SMALLER_WATERY) {
            return "Smaller Watery";
        }
    
        if (v == Eyes.SMALLER) {
            return "Smaller";
        }
    
        if (v == Eyes.SUNGLASSES) {
            return "Sunglasses";
        }
    
        if (v == Eyes.EYE_PATCH) {
            return "Eye Patch";
        }
    
        if (v == Eyes.VR_HEADSET) {
            return "VR Headset";
        }
    
        if (v == Eyes.DEAD) {
            return "Dead";
        }
    
        if (v == Eyes._3D_GLASSES) {
            return "3D Glasses";
        }
    
        if (v == Eyes.HEART_EYES) {
            return "Heart Eyes";
        }
    
        if (v == Eyes.LASER_GLASSES) {
            return "Laser Glasses";
        }
    
        if (v == Eyes.NINJA_MASK) {
            return "Ninja Mask";
        }
    
        if (v == Eyes.LASER_EYES) {
            return "Laser Eyes";
        }
        revert("invalid eyes");
    }
    
    function toString(HeadAccessory v) external pure returns (string memory) {
        if (v == HeadAccessory.NONE) {
            return "";
        }
    
        if (v == HeadAccessory.BUCKET_HAT) {
            return "Bucket Hat";
        }
    
        if (v == HeadAccessory.FLOWER) {
            return "Flower";
        }
    
        if (v == HeadAccessory.SPORTS_HEADBAND) {
            return "Sports Headband";
        }
    
        if (v == HeadAccessory.CHEF_HAT) {
            return "Chef Hat";
        }
    
        if (v == HeadAccessory.BLUE_DURAG) {
            return "Blue Durag";
        }
    
        if (v == HeadAccessory.RED_DURAG) {
            return "Red Durag";
        }
    
        if (v == HeadAccessory.SPIKY_HAIR) {
            return "Spiky Hair";
        }
    
        if (v == HeadAccessory.BONES) {
            return "Bones";
        }
    
        if (v == HeadAccessory.RICE_HAT) {
            return "Rice Hat";
        }
    
        if (v == HeadAccessory.BEANIE_CAP) {
            return "Beanie Cap";
        }
    
        if (v == HeadAccessory.SANTA_HAT) {
            return "Santa Hat";
        }
    
        if (v == HeadAccessory.HEAD_WOUND) {
            return "Head Wound";
        }
    
        if (v == HeadAccessory.HEADPHONES) {
            return "Headphones";
        }
    
        if (v == HeadAccessory.GOLD_STUDS) {
            return "Gold Studs";
        }
    
        if (v == HeadAccessory.WIZARD_HAT) {
            return "Wizard Hat";
        }
    
        if (v == HeadAccessory.LONG_HAIR) {
            return "Long Hair";
        }
    
        if (v == HeadAccessory.AIR_PODS) {
            return "Air Pods";
        }
    
        if (v == HeadAccessory.WHITE_PARTY_HAT) {
            return "White Party Hat";
        }
    
        if (v == HeadAccessory.BLUE_PARTY_HAT) {
            return "Blue Party Hat";
        }
    
        if (v == HeadAccessory.RED_PARTY_HAT) {
            return "Red Party Hat";
        }
    
        if (v == HeadAccessory.GREEN_PARTY_HAT) {
            return "Green Party Hat";
        }
    
        if (v == HeadAccessory.YELLOW_PARTY_HAT) {
            return "Yellow Party Hat";
        }
    
        if (v == HeadAccessory.PURPLE_PARTY_HAT) {
            return "Purple Party Hat";
        }
    
        if (v == HeadAccessory.PIRATE_HAT) {
            return "Pirate Hat";
        }
    
        if (v == HeadAccessory.KING_CROWN) {
            return "King Crown";
        }
    
        if (v == HeadAccessory.JOKER_HAT) {
            return "Joker Hat";
        }
    
        if (v == HeadAccessory.DEVIL_HORNS) {
            return "Devil Horns";
        }
    
        if (v == HeadAccessory.BRAINS) {
            return "Brains";
        }
        revert("invalid headaccessory");
    }
}

// File: contracts/Sprites.sol


pragma solidity ^0.8.0;


library Sprites {
    bytes public constant BODY_SPRITE = hex"4D50300259820013541196AAB08009428012D615975C50049180094B8CCBB0300248E004A5C765D81C012080024B0432EC900090480125825976490048280092594CB4C38A0027A4532D4D52800ACC14CBB25002416004928B65CB2C0098717579E58014112D9748B0029AA5D5EB16005760B65D92C0120C002494632E5980098655E698009C655E798005044C65D230014CCABD4300154CABD63000AEC18CBB2600239A004828D65CB34009871B579E6801411359748D0029AA6D5EB1A005764D65DA34011CE002416732D30E38009E91CCB5354E002B32732ED1C008E780120F3D9740F47513DCAA4C9ECBB47801209400094BA0CB586500049440094BA2CBB08802524004B35265A726900151649975D2004B4C0098AA6CBAC980120D50009C9A8CB54654004754009052ACB96A80130D55969C9AA005455565D65400AECAACBB4A80232C004725665A516B0013155996ACBAC005869665DB5801157002310BB2D24A5C0096B2ECB57617002CB6BB2EE2E008AC0011876197218004A600096830CBA2C00149661975D800596000B4DB0CBB8C00223200451D965C864012990025ACCB2EBB200B2C80169C6597759004468008A3B4CB90D001297680165A002D38D32EEB40088D8011466D971DB004A6C0096B36CBAED802D36005B71B65DD6C008A338004A2DC00262AE32D5977000B6E380096E80130F7596A08BA005255D65D6740131E00269CF32E7BC00A4F0014D4799755E004B7C00986BECB9CF8029BE005455F65D67C012E000261B032E74000A7000151581975A000261D08014D584000";

    function getBgHex(BgColor c) external pure returns (string memory) {
        // i don't think a map would be more efficient here, because SLOAD costs 800 gas.
        if (c == BgColor.DARK_BLUE) {
            return "2B3585";
        }
        if (c == BgColor.GRAY) {
            return "868586";
        }
        if (c == BgColor.LIGHT_BLUE) {
            return "57C8E5";
        }
        if (c == BgColor.ORANGE) {
            return "F3952E";
        }
        if (c == BgColor.PINK) {
            return "EABED9";
        }
        if (c == BgColor.PURPLE) {
            return "8558A4";
        }
        if (c == BgColor.RED) {
            return "E76160";
        }
        if (c == BgColor.TAN) {
            return "EED498";
        }
        if (c == BgColor.TEAL) {
            return "7BCAB0";
        }
        if (c == BgColor.GREEN) {
            return "1A763B";
        }
        if (c == BgColor.RAINBOW) {
            return "FF0000";
        }
        revert("Invalid BgColor");
    }

    function getEyesSprite(Eyes v) external pure returns (bytes memory) {
        if (v == Eyes.NONE) {
            return hex"";
        }
        
        if (v == Eyes._3D_GLASSES) {
            return hex"925002594554C34A224E28AB3CA225229F4A6A1526AA53EAB1526B05002516004B30B224D2CAA9C796445044B0029265C9AA16FA5558B93572C012CC224C30AA9A718449E615691926A663E9515324D58C7D4B35969869A449C695679ACBA46B2D4D4364D54D7D5635969871CCB5354E6580";
        }
    
        if (v == Eyes.BIGGER_BLACK_EYES) {
            return hex"4B38A0029AC5002516004B38B26CF2C0148B0029AC5936B96009460025995798600134E32AF3CC00523000A6A1957AA6002B1957AE600251A004B34D26CE34013CD65D235974CD002A2C6936B9A004B34E004E39974CE65AA2C70000";
        }
    
        if (v == Eyes.BIGGER_BLEEDING) {
            return hex"4B38A0029AC5002516004B38BABCF2C0148B0029AC5D5EB96009460025995798600134E32AF3CC00523000A6A1957AA6002B1957AE600251A004B34D72CE34013CD65D235974CD002A2C6B96B9A0096700261CE59A700271CCBA6732EA1C00AA7396B1C00987B96A9EE5";
        }
    
        if (v == Eyes.BIGGER_WATERY) {
            return hex"4B38A0029AC5002516004B38BABCF2C0148B0029AC5D5EB96009460025995798600134E32AF3CC00523000A6A1957AA6002B1957AE600251A004B34D194E34013CD65D235974CD002A2C68CAB9A004B34E004E39974CE65AA2C70000";
        }
    
        if (v == Eyes.BLACK_EYE) {
            return hex"4C38A0029AA5002596004C38BABCF2C0148B0029AA5936B1600966002619579A6002719579E600291800A6655EA1800AA655EB180096680130E36AF3CD00523400A6A9A4DAC680130E3800A6A9C000";
        }
    
        if (v == Eyes.BLACKOUT) {
            return hex"4C38A0029AA50012CF2C00A4B16004B3CC00292C60012CF3400A4B1A004C38E0029AA70000";
        }
    
        if (v == Eyes.BLEEDING) {
            return hex"4C38A0029AA5002596004C38BABCF2C0148B0029AA5D5EB1600966002619579A6002719579E600291800A6655EA1800AA655EB180096680130E35CB3CD00523400A6A9AE5AC680261C009A739671C00A67002A1CE5AA700269EE5A87B940";
        }
    
        if (v == Eyes.BLOODSHOT) {
            return hex"4C38A0029AA500259600985C3E697439C5BCE79600A4580299712A85D0EA96FBAC58025980098650E698009C650E79800A4600299943A86002A9943AC600259A00986BEE69B439C6C4A79A00A4680299B0FA86D0EA9AF3AC680130E3800A6A9C00";
        }
    
        if (v == Eyes.DEAD) {
            return hex"4C38A65A9AA532E596CB985802696CB9C5802796CBA45B2E99600A85B2EA9600AC5B2D2CC319734C00271E632D493319750C002AAC632E59ACB98680269ACB9C680279ACBA46B2E99A00A86B2EA9A00AC6B2D30E3996A6A9CCB0";
        }
    
        if (v == Eyes.EYE_PATCH) {
            return hex"A0200280A005044600511C00A291000524C90029AC50014972C00A4C1800A46B2D4D734014CE65AA2C7000";
        }
    
        if (v == Eyes.HEART_EYES) {
            return hex"4B30A97CD29969C7952F524CA97D42996AAB152F4B3CB97A92C5CBD2CF325EA4B192F966B2D30E365F3CD65D23596A6A9B2FAC6B2E61CCB9A74BE71CCBA6732EA1D2FAA732C0";
        }
    
        if (v == Eyes.LASER_EYES) {
            return hex"4C38BA0A9AE5D06619414D38CA5A7A0650699941545CCA5AC3665053D03696A291B41586CDA5AE3E6D054523A96A6A1D415C7CEA5B04275054D43E96AAB1F416084FA5AAAC852D5D84282AEC234B59691A0ACB4952D6DC4A82B6E274B5D793A0AEBCA52D7E05282BF02B4BC2AD070AD4B0";
        }
    
        if (v == Eyes.LASER_GLASSES) {
            return hex"4928926A59E497941124E2A49927A545C92F58249B24A26A52E5002C144D9259352902D86A2A16D5555CB61D82C9B24C26A52E6002C184D92693528D35869C99AD5545CD61D8349A9871CCB5354E6580";
        }
    
        if (v == Eyes.NINJA_MASK) {
            return hex"8A500125828008CC1600492CC004C32AF34C004E32AE9E91800A6655EA1800AA655D598300092C1A004C38E65A9AA732C0";
        }
    
        if (v == Eyes.SMALLER_BLACK_EYES) {
            return hex"4B38A65A92A532D2CF2D96A4B16CB96600130D309B38C004F319748C65D33000A8A984DAC600259A00986D5D34E34013CD65D235974CD005436AEAAB1A004C34E26CE39974CE65AA2A7134";
        }
    
        if (v == Eyes.SMALLER_BLEEDING) {
            return hex"4C3CA65A92A532E596CB4C34B00271E5B2D4932D96A8A9600AC5B2E5980098655D34E30013CC65D231974CC005432AEAAB180096680130D35CB38D004F359748D65D33400A8A9AE5AC680261CE59A700271CCBA6732EA1CE5AA700261EE5A87B94";
        }
    
        if (v == Eyes.SMALLER_BLOODSHOT) {
            return hex"4C3CA65A92A532E596CB4C34B00271E5B2D4932D96A8A9600AC5B2E5980098650D34E30013CC65D231974CC00543286AAB180096680261B309A6D0E71A009E6B2E91ACBA66802A1B30AA6D0EB1A004C34E004E39974CE65AA2A70000";
        }
    
        if (v == Eyes.SMALLER) {
            return hex"4C38A65A9AA532E596CB4C34B00271E5B2D4932D96A8A9600AC5B2E5980098655D34E30013CC65D231974CC005432AEAAB180096680130D36AF38D004F359748D65D33400A8A9B57AC680130D380138E65D33996A8A9C000";
        }
    
        if (v == Eyes.SMALLER_WATERY) {
            return hex"4C3CA65A9AA532E596CB4C34B00271E5B2D4932D96A8A9600AC5B2E5980098655D34E30013CC65D231974CC005432AEAAB180096680130D346538D004F359748D65D33400A8A9A32AC680130D380138E65D33996A8A9C000";
        }
    
        if (v == Eyes.SUNGLASSES) {
            return hex"4928A1AA59C53113D2286AA6B14C45760A1ACA2D8896616009A58D6716009E5B12916C4A658D55152C0158B1AD72D8928C624B300130C1AA69C6002798C4A463114D4300154C1AD630015CC624A35892CD1AA61A680271AC49E6B2E91ACBA66B12A1A355558D005735889669CC49C732E99CCB5458E620";
        }
    
        if (v == Eyes.VR_HEADSET) {
            return hex"4960A00249458012CC2C9B34B21A71E5936816435148B26D32C86A8A964DAC590D5D82C0128C004B309B30C21A69C6136798435044C26D23086A6A184DAA610EB184DAE600251A0096690D30D349B38D21A7A0693689A43524CD26D43486AAB1A4DAE68012D63800";
        }
    
        if (v == Eyes.WATERY) {
            return hex"4C38A0029AA5002596004C38BABCF2C0148B0029AA5D5EB1600966002619579A6002719579E600291800A6655EA1800AA655EB180096680130E34653CD00523400A6A9A32AC680130E3800A6A9C000";
        }
    
        if (v == Eyes.WHITE) {
            return hex"4C38A0029AA5002596004C38BABCF2C0148B0029AA5D5EB160096600130E32AF3CC00523000A6A9957AC600259A004C38DABCF340148D0029AA6D5EB1A004C38E0029AA70000";
        }
        revert("invalid eyes");
    } 
    
    function getHeadAccessorySprite(HeadAccessory v) external pure returns (bytes memory) {
        if (v == HeadAccessory.NONE) {
            return hex"";
        }

        if (v == HeadAccessory.AIR_PODS) {
            return hex"461CEABAD36755E31F57B67D5E32157B6855C0";
        }
    
        if (v == HeadAccessory.BEANIE_CAP) {
            return hex"495400048040092A82B3565C10049080094B84B3B01002486004A5C359D80C0124400252E22CEC0800902801258153F6450048180124659CA19072C659CC190734659CE19073C659D0190744659D219074C659D4190754659D619075C659D8190764600481C0124759CA1D072C759CC1D0734759CE1D073C759D01D0744759D21D074C759D41D0754759D61D075C759D81D076470024B04000";
        }
    
        if (v == HeadAccessory.BLUE_DURAG) {
            return hex"4D50322A5AC2115297148B68522A4B231152581C8B68722A43241140";
        }
    
        if (v == HeadAccessory.BLUE_PARTY_HAT) {
            return hex"94000270000A60002B80009208025024A960802682009C092A78200A408029824AA80802B0200AE092AC02009210025044A961002684009C112A78400A410029844AA81002B0400AE112AC040092180128B0C9530300269E19294110C00A4A064AAA18015970C956030049100094B884AB0200248A004A5C52558140124600252E312AC0C00496070000";
        }
    
        if (v == HeadAccessory.BONES) {
            return hex"8C6002D98008A680231B57B66D5EE1A008A700231D198E755E41D19B27466D1D57B67466E1C008A780231F57B67D5EE1E008C8002DA000";
        }
    
        if (v == HeadAccessory.BRAINS) {
            return hex"4D5020025981802686E64E3C39E500DCCA29873CA81B995560C0128400259A24E6708D94F4049CD111B34849CD311B2A8B0939AE200248A00942B612CC161D3456CA7262C3AA0AD955585875715B1605004818009250D1496334930D1A293865EA7A4345298CBD545468A5619A4AEC0D14B2300120A1C012C763261C3C3278EBD5044786521D7AA6A8F0CAC3B195D91C0096B10000";
        }
    
        if (v == HeadAccessory.BUCKET_HAT) {
            return hex"4C540004B040098A824AAC0802504004B582255708012830025AC192AB86009420012D610955C4004A140096B0A24AE2801209180094B8C4A5864600471C0090C8E4AB438012192000";
        }
    
        if (v == HeadAccessory.CHEF_HAT) {
            return hex"47200002494055D2CE00009E9015753580002BB0055D65A00011810023B40D5ED82008C10011DA0AAF6C200470C0090C8757B418023880048644ABDA100090C8A009030012581AAF64600481C009268F579C38013D21EAF4C7002A303D5EC8E00496080000";
        }
    
        if (v == HeadAccessory.DEVIL_HORNS) {
            return hex"8C000238113900002C8000B4044ED80008C08011C8062724100580400B2D0313B60802384004824289A51610015970800B0C8513B4100238600482C389CC0C01543002B301C4EC860090200124B122730400551000ACC0913B2200124B1400ACC0A000";
        }
    
        if (v == HeadAccessory.FLOWER) {
            return hex"981CD6589079824E268907942CD658B38982D1668B389C2CD658D079834E268D07983CD4";
        }
    
        if (v == HeadAccessory.GOLD_STUDS) {
            return hex"8E7C7ED1F1F0";
        }
    
        if (v == HeadAccessory.GREEN_PARTY_HAT) {
            return hex"94000270000A60002B800092080250257960802682009C095E78200A4080298257A80802B0200AE095EC020092100250457961002684009C115E78400A4100298457A81002B0400AE115EC040092180128B0CAF30300269E195D4110C00A4A0657AA18015970CAF6030049100094B8857B0200248A004A5C52BD8140124600252E315EC0C00496070000";
        }
    
        if (v == HeadAccessory.HEADPHONES) {
            return hex"4C54100259810015560800925860056603002412200161910008E40A005968500230E300169B1801187005B1C008A310005B708004524017090045280170A00452C011CB0AC82C1564B055A2C2B70B0045300118C0FC7302B20C0559301568C0ADB303F70C00228C687E39A1590682AC9A0AB468556DC343E8A31C1F8E705641C0AB2702AD1C155B70E0FC63C3F1CF0AC83C1564F055A3C2B6CF0FC7402B210055940156900A80";
        }
    
        if (v == HeadAccessory.HEAD_WOUND) {
            return hex"4B304004A14012C5A34C1629345004918012865ECB1A2930600251638000";
        }
    
        if (v == HeadAccessory.JOKER_HAT) {
            return hex"452800028220002B8000586C0945C000088582009E080141106A748100560400AEE0328BA080110D08013C2002822154E9040054542002B3214A169B0801702945D080114300241E18014110EA6A4986005460394590C01703002422200149812516440024A0280145716516050024A030014571A5160600252E3800";
        }
    
        if (v == HeadAccessory.KING_CROWN) {
            return hex"4928000282200015D800012010024940D3E582009E0801411069F48100560400AEC034FB20802484004A2C2A7A61A10027840050442A7D20800A8A8400565C2A7D8080124300251A1D3E706004F483A7D30C00A8B874FB01802488004A5C4A7D81001245004A169F2C555A61E2D3E80AAB51505A7D51556ACB8B4FB0280248C004A2C6A7CC1A389A80D4FA234714951A9F5868E571A9F6060024B03800";
        }
    
        if (v == HeadAccessory.LONG_HAIR) {
            return hex"4D503764B11D898A8905AC23B250AEC4B585905715D924676252E34EAC0CEC903BB124A1E74AEC0F3AB23BB12092274B0C913A904CEAC933A9054EAC953A905CEAC973A9064EAC993A906CEAC9B3A9074EAC9D3A907CEAC9F3A9084EACA13A908CEACA33A9094EACA53A909CEACA73A90A4EACA93A90ACEACAB3A90B4EACAD3A90BCEACAF3A0";
        }
    
        if (v == HeadAccessory.PIRATE_HAT) {
            return hex"9A000138F01E2A088000524C078D40001301004D05E3381004F05E2A088200A40BC698200A80BC6A8200961002604F14D3C200282213C5494080154278D60801283004B0DE298A8600AC1BC6B86004720400249423C52CF1000A0888E752584002BB023C565A10008A30A004720578A49C280278B5750445005216AEA6C0A005968578ADB8280119B18008E70E005368700249840015582000";
        }
    
        if (v == HeadAccessory.PURPLE_PARTY_HAT) {
            return hex"94000270000A60002B8000920802502A2960802682009C0A8A78200A40802982A2A80802B0200AE0A8AC0200921002504A2961002684009C128A78400A41002984A2A81002B0400AE128AC040092180128B0D4530300269E1A894110C00A4A06A2AA18015970D456030049100094B88A2B0200248A004A5C55158140124600252E328AC0C00496070000";
        }
    
        if (v == HeadAccessory.RED_DURAG) {
            return hex"4D5037525AC23A929715D56857524B233A92581DD568775243243A80";
        }
    
        if (v == HeadAccessory.RED_PARTY_HAT) {
            return hex"94000270000A60002B8000920802502E4960802682009C0B9278200A40802982E4A80802B0200AE0B92C0200921002504E4961002684009C139278400A41002984E4A81002B0400AE1392C040092180128B0DC930300269E1B914110C00A4A06E4AA18015970DC96030049100094B88E4B0200248A004A5C57258140124600252E3392C0C00496070000";
        }
    
        if (v == HeadAccessory.RICE_HAT) {
            return hex"4E4C0004D04009C9833DA80802604004D502885508012C300262A1CF6B06009420012D612215C400249428012D615C0AEC0A00472060024B0344165A18011870023B43CF6D8E0047688000";
        }
    
        if (v == HeadAccessory.SANTA_HAT) {
            return hex"4854000230E08012150650ACB82008A10011870AAF2020024AE14A2C04008A18011870EAE90486004A5C394580C008C38800922001297125160400481401245944A16032C5944C1603345944E16033C594501603445945216034C594541603545945616035C59458160364500481801246744A19DF2C6744C19DF346744E19DF3C6745019DF446745219DF4C6745419DF546745619DF5C6745819DF64600481C01247ABCA1E952C7ABCC1E95347ABCE1E953C7ABD01E95447ABD21E954C7ABD41E95547ABD61E955C7ABD81E956470024B040000";
        }
    
        if (v == HeadAccessory.SPIKY_HAIR) {
            return hex"96080278200A40802B02004C34200282210015150801184005B10008E40A00596850045240170900230E500169B28000";
        }
    
        if (v == HeadAccessory.SPORTS_HEADBAND) {
            return hex"4A2C56DA62A2BA559715B724669CA19B69660CE94D3C68AA82234BA90C51535068AAAAC33A6B8CDBB0334E48ED3943B6D2CC1DD29A78F15A03CBA88F57A439454D41E2AAAB0EE9AE3B6EC0ED34A2C86DA62A43A559721B60";
        }
    
        if (v == HeadAccessory.WHITE_PARTY_HAT) {
            return hex"94000270000A60002B800092080250357960802682009C0D5E78200A4080298357A80802B0200AE0D5EC020092100250557961002684009C155E78400A4100298557A81002B0400AE155EC040092180128B0EAF30300269E1D5D4110C00A4A0757AA18015970EAF6030049100094B8957B0200248A004A5C5ABD8140124600252E355EC0C00496070000";
        }
    
        if (v == HeadAccessory.WIZARD_HAT) {
            return hex"9E00014110043480004E04009E90221A60802704004F48210D30801343002720188688754524C310D40C0096608004D3C410D012A8A2A08215558400249428012D01443445AA292C28855D814012060024B03086C8C00466C70000";
        }
    
        if (v == HeadAccessory.YELLOW_PARTY_HAT) {
            return hex"94000270000A60002B80009208025034E960802682009C0D3A78200A408029834EA80802B0200AE0D3AC02009210025054E961002684009C153A78400A410029854EA81002B0400AE153AC040092180128B0E9D30300269E1D394110C00A4A074EAA18015970E9D6030049100094B894EB0200248A004A5C5A758140124600252E353AC0C00496070000";
        }
        revert("invalid headaccessory");
    } 
    
    function getOutfitSprite(Outfit v) external pure returns (bytes memory) {
        if (v == Outfit.NONE) {
            return hex"";
        }

        if (v == Outfit.ARMOR) {
            return hex"47253002C34980232800472544E251AA0015175000B0D28B6B6A0022AA008CAA723AA8F482D51ECC5457355492726A802A2A92AAA8AEB2A3DAEA8AD619547B695495B556D715004658008E42C3D92B0AE52C0096B0F662C2B9AB23D39359255164E5558575961ED7580161615ACB4B0F6DAC008AB80232E9C4721747A494B8025AE3D98B8AD3505D1EA2A2E9CAAB8AEB2E3D57617002CB4BA3EDAE9CB8B8022B0008CC2723B08F90C0025300096C0F66302B4D45847A928C272AB02BACC0F6BB000B2C002D308FB6C272E300088C8011476457219004A6400966323D9AC8AD392651F4D94E546456AAB323DAEC802CB2005A71915DD640111A004569388C3B48F90D0025340096D15930D687A9C9B42B5455A1ED668AD5DA00596800B4DB48FB8D272EB40088D8011466D391DB004A6C012DB34261CD8AD3D26C7AA6AB62BACD9A2BB600B4D8016DC6D3975B00228CE00128B700131C15A69CE23E7B82B5045C2B527056A6A388FAAE0AD5977000B6E380096E80130D75389C7BA8F5045D002926EA3D515753959D004B780131E4E269CF1A27BC00A4F0014D478D155E4E5678012DF00261AF8AE73E00A6F8015157C5759F004A8000966409C9B023E74000A70002A408F555A04E578001261004A8538966C28F9D08029C200545A147D78539621000";
        }
    
        if (v == Outfit.BLUE_AND_WHITE) {
            return hex"4C354002A2AA0025AA004C355252726A8015155495595004B580098AAC4AACB00252E004B59725575C012980025ACC12ABB00094C8012D664955D900252ED002536004B59BABD76C00945B8004C55CABAB2EE0025BA004C3DDABA822E80149576AF59D0000";
        }
    
        if (v == Outfit.BLUE_SHORTS) {
            return hex"4A5DA004A6C0096B364AAED80128B700098AB84A565DC004B7400987BA4A5045D00292AE92AB3A00";
        }
    
        if (v == Outfit.BROWN_AND_BLUE) {
            return hex"4C354002A2AA0025AA004C355612726A8015155585595004B580098AACC2ACB00252E004B59761575C012980025ACC30ABB00094C8012D665855D900252ED002536004B59B25576C00945B8004C55C252B2EE0025BA004C3DD252822E801495749559D0000";
        }
    
        if (v == Outfit.BROWN_AND_WHITE) {
            return hex"4C354002A2AA0025AA004C355612726A8015155585595004B580098AACC2ACB00252E004B59761575C012980025ACC30ABB00094C8012D665855D900252ED002536004B59BABD76C00945B8004C55CABAB2EE0025BA004C3DDABA822E80149576AF59D0000";
        }
    
        if (v == Outfit.CAMO) {
            return hex"48354002A32A0023AA0090A94A4AA6F94A9C92CC54A5355272726A802A2A4EAAAA82B2A52AEAA82C2A72B2A996D2A008CB0023AC6F90B14A4AC6594B0012CC5941356274E58A53D637D058A5456505258CB4D62954589CAAB2C52AEB0016195941696295B580115700230EB9CA42EA049297004B5CCB317504D5C9D397504F5CE541750515CCB49737D35CE551727555CE559732ABB0B802CAE52B4B9BEDAE72B8B8022B0008CC1963B05290C0025300096C282630729AC13A730529EC19683052A2C1BE93052A6C196A304EAAC282B3065AEC002CB000B4C14ADB065B8C002232008ACA8118764DF219004A64012D9394C64DF359274E65413D932D064E5459502926C9CAA324EAAC94AB326FAEC802CB200B4C9CADB26FB8C94AEB20094D0012CF689CA08B4E15259A2757680129B004B6CDF31B294D6D4139B394F6D4141B39516D40A4A36655559B29576C00945B80098E1966B8529CE1967B8A0A0E14A8B86FA4E1CA9B852A8E282AB865565DC004B740131D32CD74A539D37CF74A4A08BA00A4E94A9BAA0A8E94AABA72ACE8025BC0098F14A6BCA09CF14A7BC00A4F0029BC65A8F1BEABC52ACF0025BE0098F9CA6BE6F9CF8029BE00A8F9BEABE52ACF80128B8000986C0DC9D00029C000545606E2B2F00024C2004A3616E4E84014E1002A2F0B72C42000";
        }
    
        if (v == Outfit.GOLD_CHAIN) {
            return hex"4C354002A2AA0025AA009AAD5D3935401515ABD654012D6004D5AAF396A7A7A4B55E9AD36A8B55EB2C0094B80130E5EAF3D7A7A822BD5E92F3653557ABD75C0129800259EC55E8314FA2C4D949662AF5D8004A640096B3357AEC801297680129B0025ACD92ABB6004A2DC00262AE12959770012DD00261EE9294117400A4ABA4AACE8000";
        }
    
        if (v == Outfit.GRAY_PANTS) {
            return hex"4A5DA004A6C00967B6805045B00292CDA02BB60094E0012CE71013DC002822E202938005359C405770012DD00262AEA02B3A0096F00130E7900A08BC005355E40567800986BE805455F400";
        }
    
        if (v == Outfit.HOBO) {
            return hex"4C354002A2AA0025AA004C355574E54014D5002A2AAABAB2A0096B00130E595CA6AACAEACB00252E004B3D7572928BABAB2EAEAEB802530004B3D857292CC2BABB00094C8012CC655C9C832AE525995757640094BB40094D8012D66D535DB002516E0013557152ACBB80096E80130F7552A08BA005355D54D67400";
        }
    
        if (v == Outfit.KARATE_UNIFORM) {
            return hex"48354002A32A0023AA0048355ABA726A80151956AF695004658008E7AD57A0B49545A5AAF6D600455C008C42F574929700259CBD5E7AF2550597ABABB0B80165B5EAF717004560008C3B15790C002530004B358ABCE624A9EB3157AEC002CB0005A6D8ABDC600111900228ECC964320094C8012CC66AF35992A72CCD5EBB200B2C80169C664B75900252ED0025360096DC9530F6EAEA08B6005259BABD76C0129C00259CE55E7B8005045CABD27000A6B3957AEE00253A004B59DABD774012DE00261CF55D3D27800A6ABD57ACF0025BE004C35FABCE7C014DF002A2AFD5EB3E00";
        }
    
        if (v == Outfit.LOUNGEWEAR) {
            return hex"4C354002A2AA00120D54949C9AA00546552523B4B1291885C952970025ACB92ABAE00596D725230EC12A530004B59825576000B4DB04A451D9254A640096B324AAEC80169C649494BB40094D8012CF6D00A08B6005259B40576C0129C00259CE2027B8005045C40527000A6B3880AEE0025BA004C55D405674012DE00261CF2014117800A6ABC80ACF00130D7D00A8ABE800";
        }
    
        if (v == Outfit.LUMBERJACK) {
            return hex"48354002A32A0023AA0090AB3A4AAAC94AB3A5AAAC98AB3A6AAAC4E4D50054559D5555656559D5D55658559D655565A54011960047586921656495869296004B5869316564D5869396564F58694165651586949656535869516565558695965657580161656595869696565B5801157002310BB3924A5C012D7564C5D9D357564E5D9D3D756505D9D45756525D9D4D756545D9D55756565D9CAEC2E00B2BAB2D2ECEB6BAB2E2E008AC002330AC8EC0D24300094C0025B03498C2B26B0349CC2B27B034A0C2B28B034A4C2B29B034A8C2B2AB034ACC2B2BB000B2C002D30ACB6C0D2E300088C8022B2AC8CCB3A3B2AC90C8025320096CAB2632CE9ACAB2732CE9ECAB2832CEA2CAB2932CEA6CAB2A32CEAACAB2B32CEAEC802CB200B4CB3ADB2ACB8CB3AEB20094D0025B43498D2B26B4349CD2B27B434A0D2B28B434A4D2B29B434A8D2B2AB434ACD2B2BB40094D8012D66C3D5DB004A700096B381EAEE0025BA004C3DD0F2822E801495743D59D004B780131E244D78BB39E0ECF780149E0053783D51E2ED5789159E004B7C00986BE1E9CF8029BE005455F0F567C00945C0004C3600F4E80014E00054803B5600F2B2F00024C2004A36156CE84014E1002A2F0AB6C4200";
        }
    
        if (v == Outfit.NINJA_SUIT) {
            return hex"48354002A32A0011CB5400986AB224E4D50054541CAABAA3858695002316B00130D585739661CF5A44A0B2C2B576D6002298B80134E5C573D761D05E44A2AAE2B56717002290C002530004B3D80750618745891292CC03ABB00059718002210C801290640145961D26644A6BB20059759002522D002934C35359A9157680094BB6004A5DC00252EE8012D678009673E005359F0000";
        }
    
        if (v == Outfit.OVERALLS) {
            return hex"49354002A30A00124C55FB35529A726A802A2A53556157EC959FB296002598B3F66AC534E4D67ED458A6AAB2CFDAEB002C2CFD49297002598BBF66AE534E4D77ED45CA6AAB2EFD57617004A60012D87ECC60A73585F2726C14EA30BEAAC14EB30FDAEC002532004B39929A7A4C8E94D664A75D9004A6800966B4534E4DA1D2A2CD14EBB40094D8012D66CA75DB004A7000967B8535045C1D292CE14EBB80096E80130E74A73DD1D2822E80293A3A5355D29D674012DE00261AF14E73C3A9EF00293C00A6F0E951578A759E004B7C00986BE3A9CF8029BE005455F1D567C000";
        }
    
        if (v == Outfit.PAJAMAS) {
            return hex"48354002A32A0023AA00482953C4B54C33153C4D54C29C9AA00A8A9E2AAA61ACA9E15D954C3695004658008E4AC6194B0025AC6198B1E26AC619CB1E27AC61A0B1E28AC2EA4B1E29AC61A8B1E2AAC61ACB1E2BAC00586963C5B5801157002310B9E124A5C012D730CC5CF135730CE5CF13D730D05CF145717525CF14D730D45CF155730D65CF0AEC2E00596D730DC5C0115800230EC1864300094C0025B06198C1E26B0619CC1E27B061A0C1E28B02EA4C1E29B061A8C1E2AB061ACC1E2BB000B2C00169B60F1718004464008A3B27890C8025320096C986632789AC986732789EC98683278A2C8BA93278A6C986A3278AAC986B3278AEC802CB2005A71930DD640129A0025ACD0BABB40094D8025B66198D9E26B6619CD9E27B661A0D9E28B661A4D9E29B661A8D9E2AB661ACD9E2BB60094E0025B86198E1E26B8619CE1E27B861A0E1E28B861A4E1E29B861A8E1E2AB861ACE1E2BB80096E80263A789AE98673A789EE985411740149D3C5374C351D3C5574C359D004B780131E3C4D78C339E3C4F780149E005378C351E3C5578C359E004B7C0131F3C4D7CC339F00537C0151F3C557CC359F000";
        }
    
        if (v == Outfit.PINK_AND_PURPLE) {
            return hex"4C354002A2AA0025AA004C35566A726A801515559B595004B580098AACCDACB00252E004B59766D75C012980025ACC336BB00094C8012D6659B5D900252ED002536004B59B54D76C00945B8004C55C54AB2EE0025BA004C3DD54A822E801495755359D0000";
        }
    
        if (v == Outfit.PINK_SHORTS) {
            return hex"4A5DA004A6C0096B36F0AED80128B700098AB8F0565DC004B7400987BAF05045D00292AEBC2B3A00";
        }
    
        if (v == Outfit.PRIEST) {
            return hex"48354002A32A0011DA54008C7AC0050456ABA936B00115C5C008A430004A5D8002CB8C001108640094BB2005975900252ED0012976C0094BB8004B59D00259EF00149678009673E005359F00259D00014D680009674200535A1000";
        }
    
        if (v == Outfit.PURPLE_SHORTS) {
            return hex"4A5DA004A6C0096B36A9AED80128B700098AB8A9565DC004B7400987BAA95045D00292AEAA6B3A00";
        }
    
        if (v == Outfit.SKELETON) {
            return hex"48354002A32A0011C85400925AB574C555002B30AD5D65A54008C3AC0090B55D24B58009872D579EB0014115AAF4960029AAB55D5985801656ABAD36B0011465C011D7ABA41CB8013D25EAEA6CAE00B4BD5D6DC5C008A330008EC55E430004A3D8002822C55D4976001658005A62AEB6E300044159004666AE8E432004A3D9002822CD5D4976400B2D3200B6CD5D71D6400882B4008CD55D1C86800947B4005045AABA92ED00165A68016DAABAE3AD002236008ADD5D1876C00947B6005045BABA92ED80169B6C0171BABDD6C008A338004A3DC002822E55D4977000B6E38004B35D00271EED5D4117400A49BB575459D004C780135EABA71EF001493780151EABD578009663E009AFD5E73E00A6F802A3F575559F004B8001320ABA69D00014D48001560ABD68000987420053561000";
        }
    
        if (v == Outfit.SPEEDO) {
            return hex"94D0012D669975DA004A6C0096B3677AED80139370EF3DD3BA822E80293A77";
        }
    
        if (v == Outfit.SPORTS_JERSEY) {
            return hex"4C354002A2AA0025AA0098AD5E6AABC4E4D500545579555ABD654012D6004C5AAF3565E4E59989E92CD1A6B332A2CBCAAB55EB2C0094B8025AF5798BAF134E5D993D768D05EAEA29AED1A8BB32AAEBCACBD5EBAE0094C0025B0BC4C358662720C3468B157524D868AA2AC332B30BCAEC0025320096CAF2632D19ACB3139065A3459ABA926CB4551565995995E57640094BB4004B59B66262AE33130F7598A4ABACC0";
        }
    
        if (v == Outfit.TUX) {
            return hex"48354002A32A0011DA54008C6AC004E3D6ABA822B0014935AAEA8DAC00453970027A4BD5D4D45C00AAB2ED057717002290C00128E60009E93157535D8002CB8C001108640094732004F499ABA9AEC80165D640094734004F49AABA9AED00128E6C009E93757535DB00252EE0012D67400967BC005259E00259CF8014D67C009674000535A000259D08014D684000";
        }
    
        if (v == Outfit.UNDERGARMENTS) {
            return hex"4C354002A2AA0025AA009AAD5D3935401515ABD654012D60026A8B55EB2C0094B8013155EAF5D7004A600096B3157AEC002532004B599ABD7640094BB40094D8012D66EAF5DB002516E00131572AEACBB80096E80130F76AEA08BA005255DABD674000";
        }
    
        if (v == Outfit.WHITE_AND_BLUE) {
            return hex"4C354002A2AA0025AA009AAD5D3935401515ABD654012D60026A8B55EB2C0094B8013155EAF5D7004A600096B3157AEC002532004B599ABD7640094BB40094D8012D66C955DB002516E0013157094ACBB80096E80130F7494A08BA005255D255674000";
        }
    
        if (v == Outfit.WHITE_SHORTS) {
            return hex"4A5DA004A6C0096B3757AED80128B700098AB957565DC004B7400987BB575045D00292AED5EB3A00";
        }
        revert("invalid outfit");
    } 
    
    function getMouthSprite(Mouth v) external pure returns (bytes memory) {
        if (v == Mouth.NONE) {
            return hex"";
        }

        if (v == Mouth.BLACK_MASK) {
            return hex"90686AC9A1A4828E0D27A470015D9383528F0D25AC7802B9E1A4C55000251688693154400ACBA21A4D51200272698000";
        }
    
        if (v == Mouth.BLOODY_FANGS) {
            return hex"9C90027A557504524DD24AAF4D2004F4E99493A64F521B49486CF55A94956A00";
        }
    
        if (v == Mouth.BREATHING_FIRE) {
            return hex"5B70D942C3474A16DC3A8574E942A2E7CA161A3E84B6E1F4DBA7D0AF1F28514D0942A2E850961D429B790A15F42514119428A68D0951E469B7D1A16046513D294504A84A2F254DBE950B02528A09CA14534E84A8F274DBE9D0B02728514D4942A2EA50961D529B794A15F5250A8BAB2858695A12DB8AD36EAB42BCACA161A5A50B6E2D42BAB4A16DC5E500";
        }
    
        if (v == Mouth.DIRTY_TEETH) {
            return hex"9C90027A47EA091AA8A47EA491AA9A4000";
        }
    
        if (v == Mouth.FANGS) {
            return hex"9C90027A5575045200524AAF4D2004F4EAF493AB80";
        }
    
        if (v == Mouth.GOLD_GRILLS) {
            return hex"9C90027A4F4A094868A4F4A494869A4000";
        }
    
        if (v == Mouth.HAPPY_BUCK_TEETH) {
            return hex"9A8802A22004E3D2002822955D49348009E92600";
        }
    
        if (v == Mouth.HAPPY_FANGS) {
            return hex"9A8802A22009C90027A5575045200524AAF4D20027A49800";
        }
    
        if (v == Mouth.HAPPY) {
            return hex"9A8802A22004E4D20027A49800";
        }
    
        if (v == Mouth.HAPPY_SINGLE_TOOTH) {
            return hex"9A8802A22004E3D200504AAEA29A4004F4930000";
        }
    
        if (v == Mouth.KISS) {
            return hex"A28B7938F49974126A28A6932E8A6DE0";
        }
    
        if (v == Mouth.MAD_DIRTY_TEETH) {
            return hex"4F491004E48013D23F5048D54523F5248D54D20000";
        }
    
        if (v == Mouth.MAD_FANGS) {
            return hex"4F491004E48013D2ABA822932E92557A690027A757A49D5C";
        }
    
        if (v == Mouth.MAD) {
            return hex"4F491004E48009E924CBA69000";
        }
    
        if (v == Mouth.MAD_SINGLE_TOOTH) {
            return hex"4F491004E48013D265D04AAEA2924CBA690000";
        }
    
        if (v == Mouth.SINGLE_TOOTH) {
            return hex"4E3D200504AAEA29A400";
        }
    
        if (v == Mouth.SMILE_DIRTY_TEETH) {
            return hex"9C88029A2009C932E7A400A091AA8A47EA490029A4CB";
        }
    
        if (v == Mouth.SMILE_FANGS) {
            return hex"9C88029A2009C932E7A5575045200524AAF4D265CF4EAF493AB8";
        }
    
        if (v == Mouth.SMILE) {
            return hex"9C88029A2009C932D3D248014D2658";
        }
    
        if (v == Mouth.SMILE_SINGLE_TOOTH) {
            return hex"9C88029A2009C932E7A400A0955D45248014D26580";
        }
    
        if (v == Mouth.SMOKING_JOINT) {
            return hex"B06CCEB9D0AAE7BE6C20EDB08B6E8A441A491DA9A48FA89296AA4A4AC930EBA4D6";
        }
        revert("invalid mouth");
    } 
    
    function getHandAccessorySprite(HandAccessory v) external pure returns (bytes memory) {
        if (v == HandAccessory.NONE) {
            return hex"";
        }

        if (v == HandAccessory.BLOODY_KNIFE) {
            return hex"82B33D0425CF2841B07982CBAD0C464F311A3CC5680101B75A28CD9E60BAEB";
        }
    
        if (v == HandAccessory.BOW_AND_ARROW) {
            return hex"8C9A222A8888CA0F222A888CA8F222C888CB0F21AE888CB8F21B0888CC0F21B2888CC8F20343C4109A5AC3691088334B586DA223363C86E2223383C86EA2233A3C88F22233C3C88FA2233E3C8B02223403C8D0A200";
        }
    
        if (v == HandAccessory.BRAIN) {
            return hex"42197004160010988643617A882B10C8CC2F63B00080C8020B31484CAF50C666291D95EC8640101A004169B2843B50E90D0020360082DCE6136D94311B9CC56DB319B9CC76DB321B00208EE000";
        }
    
        if (v == HandAccessory.ENERGY_DRINK) {
            return hex"8A9D562295586A89D10556070D613A20AB40E1AE2788BB962AF0386C40E230278AC40D0C4660715913A188D40E2B4274311B81C56C4E";
        }
    
        if (v == HandAccessory.FLAMETHROWER) {
            return hex"80BCA20314282C4A1147604D019A6C166850999444644D159414664ED1D93348644C800B54D84D50A1B5284415A414668ED1DA3348684D01BA6C16E8509B94446C4D15B41466CED1DB33486C4D01CA14172508A338268EE1264382680ECA11C8744C";
        }
    
        if (v == HandAccessory.HOOKS) {
            return hex"4521809ACB8C04D108644AB2EB2254421A282CBAD1411076CC8B4EB6644519C3A2DB8E1D22BA80B8EA022BC808EF202D3C80B8F20233E80B6FA000";
        }
    
        if (v == HandAccessory.NINJA_STARS) {
            return hex"8AD2C2F34B086DAC22369A8AD9FEE36B0BADA6AF367F88E1FE2B89A8CE2C2EB87FBCE26AFB8B088EAC2EBAB0";
        }
    
        if (v == HandAccessory.NUNCHUCKS) {
            return hex"441DA44AD3AD226236898EDA26D3689BADA26238898EE226D3889BAE22623A898EEA26D3A89BAEA250C478011DE44DA7912BAF3C0088F8023BE895969F005D7C008E44000B500023C200";
        }
    
        if (v == HandAccessory.PITCHFORK) {
            return hex"82720611E818082061A081828A061A2818492050014D030D340C3510311540C4590315740C5610319940C669031DB40C7710321D40C87902";
        }
    
        if (v == HandAccessory.POOP) {
            return hex"82851E123408694C61272C82A46212B0986B3FA22EAF86C28D1056150841B296441994C2086D22D1076918841B6874419B4300";
        }
    
        if (v == HandAccessory.SKULL) {
            return hex"411D7002002C00108662AE8E4300080C80104766AF2190040680105AABA106D002235574519A00476AAF21A00406C0105BABA106D802237574519B00476EAF21B00407000823B95790E0020BA004219DABC7740105E00427AAF0DE00447AAF15E00467AAF1DE00210CF800";
        }
    
        if (v == HandAccessory.SPIKED_BASEBALL_BAT) {
            return hex"827A02020564005142C345010122B41490B0922B20869A162A68084A15A1A88588A15A0AA804315542C5590A8A32E858CC1C118764E11DA380";
        }
    
        if (v == HandAccessory.SWORD) {
            return hex"806A0601C814004F40C1410282122818492050834D030D440A188AA0622C818CB19A22E8145197334460CD158714660CC862B2668CCA0518769031DB4080";
        }
    
        if (v == HandAccessory.WAND) {
            return hex"829D460AB5086AD460AC7384B13E0AF5184B9CE1AE4F86C1CE2304F88C9CE2B24F8AD1CE3344F0";
        }
    
        if (v == HandAccessory.WEIGHTS) {
            return hex"84C05EFB017410990BAFC0C85D002682EBF0B4174005B0BA13EDBD58216C2E80138175F85C0BA084E85D7E0742F09E0BDF782E";
        }
        revert("invalid handaccessory");
    }
} 

// File: contracts/SpecialSprites.sol


pragma solidity ^0.8.0;


library SpecialSprites {
    function getSpecialSprite(Special v) external pure returns (bytes memory) {
        if (v == Special.ASTRONAUT) {
            return hex"40840022018081135406AEAB082044010202450AAC8C504044B582ABABC210110090C0894B875758843022010201124B12AE98708204F4440A292A202D59812AEB2F8804C0255B08804402050224942D5D2CD14409C80A145158505ABB02D5D661140900602411AAC8438C0448246ABA51A308138F1828A0B8C0B58646ABAD4230110071C089048F574A30710269E38514171C16B0C8F575A84702200C4012390B790455D24C20409A790145060805D922AF6885BADC2401100624091C95BC826AE92592204C3890A27B0482EC9357B44ADD6E1240880314048E52DE41557492CA10261C50513D8281764AABDA296EB7094044018B02472D6F20BABA496588130E2C289EC160BB25D5ED16B75B84B02200C6012398B790655D24A304096698144E60C05D932AF68C5BADC26011007340920DABA49468812CD34289CC1A0BB26D5D6A134088039C044824EABCA38409669C144E5CE05AC32755D69D380978EAB2FC270110083C0924FABCA3C409669E144E5CF05D83EAEB309E0440210022494855D2CD40289CB200B57610ABACC2801100244090D1AB2212881128C46AF3510A2728882D55746AEB10A204402920225AC955D5E14808805A60498998D3544EAF55331AB4298110075009214ABA494A1192CC52AE9AA286355594ABABB0A35ECA9575A85402200CA8111DA56AEB70AA0480B0120AD5642156022326B55EA2CD7556D6ABAE42B0110045C088A5AF574C3575BA724BD5E9AE46A8BD5EAAE4656717ABAEBEB81302F56C2B81100460088A4315792C01129762AF618022CB8C55D7616008801B20444219ABC96408945B26398CD5E6B2304E559ABAB2EC98EC320459759ABAF42C8110036808883B5574825A02252ED55D6196808B4EB5575E85A022006D8111076EAE904B6044A5DB6BAC32D81169D6EAEBD0B604400DC02220CE35D1C9700894BB9575869C022DBAE35D7A17008801BA044419DABA394E8112D676AEAED3A045B75DABAF42E8110037808882BD574629E02259EF55D4117808A4B3D57576DE022E3AF55D7A178088053E044B39F6BA7A4F8114D67DAEAF0BE04400E03EA20D03251CA80FA96741574F4A03EA9AD055D5DC80FABAFC063608603EC0856E8214263431615BA311098D24E86AE9E84263514A15BA9B10D5D65B84C6B90C2B70";
        }
    
        if (v == Special.DEVIL) {
            return hex"40100154500311800047022720000490030945802A4C4001FA8A600A951700316001559000168089DB0000B8E8058BC00357E000B18401FA00608FD10504551810023900C4E482009408A92CC047E9A78258504811FA9AE08AAC02005968189DB04017012C2EBE083582104B08010458431021FA28C10AA384004824289A516100131008B0A2A843F565C2002C32144ED0400B61161720081B8422C400CB104306A10619611050C7F18315470C0090587134C543002B301C4EC8600B419616E10C1A801080D431042C228C20FE3882A90200124B12273040026A8232EA88005660489D91000B50880D400C506A20A2961188147E9258A004C54565AB302801661141A8020C0D451862C47187F2062C49180094B8CCBB0300165A181B6C60CAE4230350031C1A8828E19462072C491C0094B8ECBB03802C8E0D5A7070CAEC23835002201A86310198E4162410004960865D92000B4E90195E80806E120330090CC1241A84392199048012582597649002D384866E9211BC4866F920D608490CA00E5066414004928A65A59C50013D22996A6B14005760A65D92800B4D94195C74A08AF4250650032C3310B08A28C586639611905802496CB9458012CE2E273CB0028225B2E916005358B89D72C0160B65D92C0168B08DB2C32B8E96115E7CB0CE02C2384B0CC03022821981988604514630331CC08C8300124C65CA30012CC89CC30009A719139E6001411319748C0029A8644EA9800AC644EB9800B0632EC9800B46046D98195C78C08DF3032C10981180684609A1984684619A1988684514634331CD0024126B2E51A004B34D89CE34009E91ACBA6680151636275CD002C326B2ED1A005B70D08DD3452BD01A11C268A601C11827065084382314E0CC638231CE002414732D2CD38009C99CCB5458E002BB2732ED1C00B6704571E38537CE08B04270A601E1182786611E118678A51063C231CF00241E7B2E81E8EA27B954993D9768F002DC278A500240228622029451D008A41280012974196B0CA0005A85014A0028845085445319108A39088A64A2004A39165A7A488014D74597611002CBC88A6FA21C6085114C0485305208A10E90A64241C9290A6524004B35265CE48009E924CBA6900151649975D2005848536520E2D3C90A57E0483985214A00498A61A61C441D314C84C3892526299698013154D9759300574C3961314ACB498716DC4C52BB0261CC298A60281C4109414C3503888328298EA07120D50009C9A8CB54654002D36A072E28295D8140E615052800AA1C84A8A50C654391D5002414AB2E5AA004C35565A726A8015155597595002BB2AB2ED2A005B8550E200AB07232C004725665A516B0013155996ACBAC005869665DB5800B90AC1C400970E2188B98A2AE004621765A494B8012D65D96AEC2E00596D765DC5C00BAF2E625F8570E2002C07108360C5118654560008C3B0CB90C0024B01C94C0012D0619745800292CC32EBB000B0C072CB0005A6D865DC6001758652F3EC18982160390190E2084C98A1B2CA88C8011476597219004964C52990025ACCB2EBB200B0C98ACB2005A71965DD6401799652FC0C98B0B21C4005A314269950DA85C468008A3B4CB90D0024B4624A5DA005868C565A002D38D32EEB400BCD42EFB4CA6085A31406CC505B65426E170DB91C46C008A336CB8ED8024366292DB2A536004B59B16576C0161B65596CC569B002DB8DB2EEB600BCDC8EFB70BC0DB2B0B66280E32A0B90B84E48E1B91D88E45914670011DC85C8719525C85A516E0013157058ACBB800B0E42ECB8CAB4E42D6DC700175C8B5E723B7DC91E0721785C6540759505D85C276470DD8EC4762D15D8EC676471DD85C8759525D85CA76472DD00261EE8B14117400A4ABA2CACE802BBB23B0EC2ECBACAB4EC2EDBB23B8EC76EBB16BCEC76FBB23C0EC2F0BACA80F32A0BD0B84F48E1BD1D88F45A2BD1D8CF48E3BD0B90F32A4BD0B94F48E5BD1D98F00134E78593DE002822F32A93C005351E1655780159E8ED77A4761E85D9799569E85DB7A4771E8EDD7A2D79E8EDF7A4781E85E1799501F17A084F8C50C57C5F19F18C77C5E904BE3194F8BE5BE004C35F164E7C009E83E2FA2F8C693E2FA6F8015157C5959F00577C5F61F18D97C5EB4E3E315D79F17AFC2F8C60405483011D08380A88834047472202A49808F2A02A4B8000986C0CB9D00013D280A94E0002A2B032EB4000576202A59808EB4EC054BD011D7E080A986023A00308E508384591211CC584591A11CC78458904C2394A2E116261D08013D08472A29422C53561005684735E1162C3308E6D422CB708E571D8458BD04239C308B00";
        }
    
        if (v == Special.GHOST) {
            return hex"4034003A7360021720000F840042016081D311041148100A9AE0822C020959741042F40081F082084028203A5A01022884035254204560812AEF04085F80203E1081080486074A30304269E18028060351503002ABC18217E00C0F843042010201D24A101096608009A24D13901222A298900A823D95561000AEF0808BE201D82110108038A0748245044A14009668B344E40588A8A62C0151615ED5C5002C422821006180E8E40C0892300128D1A689C80D11514C6802A2E33DAC0C005984604200C381D1C81C1124700251A3CD13901E22A298F00545C77B581C00B2D8E095C84704200C401E3900890400124D22689C81111514C8802A3043DAC90005A6C804AE424021006240F1C90448240092693344E40988A8A64C0151825ED649002D38482576124108029407461CA0448280092695344E40A88A8A6540151829ED64A002D38502576128108029607461CB04482C0092597344C38B0027A05C454522E00A6A96005660B7B592C00B4E16095D84B04200A601D187301120C00249464D12CC300134C4A271E600281911A26401493300150C4A2AAC60015D831ED64C002D3A60257A130108029A078C682239A00482CD9A261C68013D03622A291B005354D002B326BDAD1A005B74D04AF426821004380E8A31C088E700120D3A689C81D11514CE802A3273DAD1C005B84E04A006781D1063C111CF00241A7CD138F3E2340F14513C00A499F005464F7B5A3C00B709E09400D003A20E80212094000946A1344E41088A8A6840151741ECB0CA0005A71004AEC2803D003440E884220892880128D466939188CF4401411215144BF49100534600A8BA2F6B0880165B4412B8EA20FBC88417E1441E802240745252044A4800966A5349C90027A442A0917D45248854D2002A2C93DABA4005869204ADC090430A40F400D303A20A98211874C12905260896980130D4E689C82711514D3802A2A9BDAB260057853082006A01D105501119404C75010906A8004E41488A8A6A4015195000B50A810400D503A20CA8223AA00482959A4B5400986AB344E4D5002A2AABDAB2A00576557B5A5400B70AA10400D603C4581115604C658008E4AD344A2D600261AB4D13905A22A29AD00545567B2B2EB00161A59ED6D6002E42B0410035C0F11704455C008C42F344929700259ABCD13905E22A29AF00545977B2BB0B80165B5DED717002EC2B841003600F118044560008C3B13490C0024B00994C0012CD62689C83111514D8802A2CC3DABB000B0C042CB0005A6D87B5C6000BAFB010C0C03F0B007400D903C464008A3B33490C8024B20994C8012CD66689C83311514D9802A2CCBDABB200B0C842CB2005A7197B5D6400BD03210C2C81D003680F11A00228ED4D24340092D025297680161A08596800B4E34F6BAD00179F6820C10B407400DB03C46C008A337348ED8024360892D826536004B35B9A2720DC454536E00A8B36F6AED8016196C2169B002DB8DBDAEB600BCD8417E16C0E801B80788E02114670008E4380992E04128B7000986B9344E41C88A8A6E40151571ECACBB8005869C082DB8E002EB8105E85C03A006E81E23A084521D04A494E8425BA004C35D9A271EEC454117400A49BB005455D7B567400AEEBA105E85D03A006F01E23C084525E04A516F04263C009AF4D273D119EF001411782149E00537A0151E7B557800ACE3C105D85E03A004F81D0C57C108C4BE0994F8425BE004C35F9A4E7C009E93E10A6F8015157DED59F002BB6F8417217C0E8014007431A004239500265C0004C3609A4E80009E94010A7000151581ED5A0002BB500416E1800E8014207431E1042417082530E84009E942105356100568420AECC2095A7A1042FC3081C";
        }
    
        if (v == Special.HAZMAT) {
            return hex"4038024A7A404C94E1009300125A09809253540664AB082494004224C2092686384499010ED24A089296B05325770224DD08CEBD084498019250430D2688486494A5C3992C421925008109292C09325980424E110968038A49483059926A828015591664B4E8A495E7C549B042292500718929048D324A2C601262A30015971804B0C8D325A70624AEC0324F08C494018724A3903CC924A1C012C75BA61A3AA93931C015075BAAAC3AA95D81C00B2D0F32B639257211D26803104947208994920052885BA59842A934E212E9E91000A642DD5152154ACB9097B0400965A2264B6F1049BE44DD821209300924C124968429249462099949240494592AA4C3494BA71E4A2941124014895BA9A84AA9556252F5C945582404B2D93325C78924AFC04CDF09249400CA24C428CF14A24A31054CA494029452A92CC292E9A7148A4F48A00532954A8A9497565CA45582804B2D95325C7CA24E02A6F84A24A00A59251882E6524B014A2C012CB4BA61A5A293932C0150B4BAAAC5A2AB9600B0580965B2E64B9096494014C24A31064CA498024A5CC00583004B2D99325C84C24A00A6925189366528D0125AC6802B9A02586CD992E42692500638928E49D3294708D2D638015CE11AC3474C96E138928031E494724F992516788D30E3C009E91E235354F002B2E788D61A3E64B709E498081250424126863A0499084C924A40052D002CC4047350004E40469E92000A6808EA2000AA808EB20055761001594264B50A049400D149A20E8926422024929102A598880A6A2239C88027A205504510052440B4D10054444755100564404AEC2205B2880969D449379148AFC2892500449268A3A44990900924A480B2D201261A908E724029E9001411480B49200534804A8AA423AC90095D8480B652012D42912602649829CDD0884C92925260296981530D4E649C7A6025045302A92698095154E6559302ABB098096614C92800A937421D424A41CA4CA7A805504540152500AA6CA9325A71424DD50CEBD0A84980ACDD04654928ED2B325B85524A00AB1251925A654D600545A65556002B36B4C972158928022E49454D799545C00AAE2F325D85724A008C125148626525824A52EC4CAC304959718992EBCC126FB0676085824C0649305933A106C925108666525924A52ECCCAC324959759992F42C9250036892883B4024825A24A52ED4C96196892B4EB402BCD126FB43B6085A24C06C6E821B649441DB012412D9252976E64B0CB6495A75B015E6C6F7DB25B042D9260383B82E12D083709288338024725C24A52EE4C9619709369C1DADBAE00AF3891BEE0DF03849C2E0EE03A4B82E8EE13A4B86E8ED10674051DD25C874769253A494B59D992BB0E92565A7476B6EBA02BCEA46FBA37C0E92F0BA3B80F12E0BC3B84F12E1BC9188F2D22BC918CF0DE3BC4B90F0EE4BC4B94F0DD2CF7A64A08BC495259E992BB0F0DECBC3BB4F12EDBC375C79E25AFC0F0DF0BC4B80F92E0BE3B84F8C61BE9188F8BE2BE378CF8C63BE2F90F8C64BE3B94F8BD2CE7C049E83E2FA2F8EE93E2F5359F01577C5F61F48D97C5EB4EBE31BCFA46FBE31C0F8DF0BE3181012E0C0478501510C481228A340478F015120980772A02A259D00093D080A94601DD28122A6B4002AF01516198122B4E40545D7A048AFC101530C047400E11BC485228A3C2379108ED24E84009E942375362100598522B4E4237BB0A457A1846E0";
        }
    
        if (v == Special.HIPPIE) {
            return hex"402008424A402794D90210B4F813E60840A4200A0C21194053CAAD03085B8019F6106908020508452424F251812E935408F8AAB049E576C2842E4014FB085484004384210E1A7920A0D752C33E262A196EB067CAE1A7961B0E10B90873E4004484210E227920911752843E2598216D3541080AAB085BAE21F1619113CB4E09085D8449F4016108228A9E462055D24B02C0965A153CB6E8B085E8459F20063279108197492C0D02596864F2DBC34217E11A7C8010E9E431875D23903B152581E04B2D8E9E5C787842FC23CF9001213C84290BA461C862C820F92482DA52E432EC105BB241F169B213CB8F11085F8489F40253C82212BA451C962A412496D2972596B0C925BB44AE96DC253CBAF9308608499F200652E9106298B1CA3E4828B724A202516532D30E282E9E914CB5354A0BAB2E532EC1440B2516ED147CB652E971D293CBCF95086084A9F20045AE90C52D8B18B6FC72CF920B2DC92C8128B65CB2C2E98716FF9E585D4112D9748B0BA9AA5BFEB1617AE5B2EC1640B2596ED167CB65AE971D2D3CBCF97086084B9F200462E90C5318B18CA44730F920C2DC9308094598179863FE698009C63FD3D2302F4CC7FD4300154C7FAB2E605EC1840B2616ED187CB662E971E313CBF01908C264F900135748421AC54518DA44734F920D2DC9348128D65CB342E9871AFF9E685D411359748D0BA9AA6BFEB1A17AE6B2EC1A40B2696ED1A7C5B70D5D2EBC6A797E0361184D9F4039748219CC54414EA4463A7D1CE3E4838B724E202516732D30E382E9E91CCB5354E0BAB2E732EC1C40B2716ED1C7C5B70E5D2EBC72797E03A1184E9F403D748219EC5887D211463E7D1CF3E483CB724F20251E7B2E81E8EA27B954973D9760F20593CB768F3E2DB87AE975E3D3CBF01F08C27CFA020BA4109062A1888521146427D1D03E4840B725020252E832EC2040B2816ED207C5B7105D2EBC82797E042118509F40457482122C5868D21106467D1D13E4844B725120252E8B2EC2240B2896ED227C5B7115D2EBC8A797E046118519F40497482124C58695211064A7D1D23E4848B7252204A4800966A4CB4E4D2002A2C932EBA400B09102CA45BB491F2DA4BA5C7924F2FC094230A53E809AE90424D8B0D3A4220C9CFA3A67C90996E4A640949AEA5A6004C55365D64C015D36FD84C816532DDA4CF96D35D2E3A9A797A04E118539F40517482128C586A521106527D1D43E4850B725420251AA0013935196A8BA800B0A102CA85BB4A1F2DA8BA5C7544F2F40A4230A93E80AAE9042558B0D5A4220CACFA3AA7C90A96E4AA4094AB8E5AA004C355482726A8015155521595005755C7615205954B76953E2DBAAA7979F5610C10AB3E80B2E9042598A8622D488AB4FA32C008EB1F242C5B92B10128B5800986AC909CB16A7AC3350456835258674D62D2A2AB2415975801616205958B76963E5B58017164F2EBEB4218215A7C800AEBA84BB161AEDF88BD222AE004621771A494B8025AEC04C357484E5C673D7832822BCB692F06A6B8CD5155D21597602BB0B80165B5DC7717002EBCBC217E15E7C800B0BA84C3161B0DF88C5222B000461D871C86001258844A60012D860261AC242730339EC419411625B49883536066A8AB090ACC302BB000B0C2EACB0005A6D871DC6001758842F42C4F9001657509962C365BF1190045652B1995947652B21900496611299004B6580986B2909CC8CE7B3065045996D2660D4D919AA2ACA42B32C0AEC802C329EB2C802D3295B6CACAE3295BAC802F33085F8599F2002D2E9083698B11A00228ED32E4340092D4225340096D30130D69209C9B4005455A485669815DA0058693D65A002D38D32EEB4005E85A9F2004DAEA1B6C588D8011466D971DB002412DCFA5360096DB0130D6D209C9B6E35455B48566D815DB002C32DC22D36005B71B65DD6C00BD0B73E4009C5D43718B11C6FA28CE0011C9727D29C004B7180986B8904E4DC71AA2AE242B38C0AEE00161A7210B6E38005D81C9F6172908013ABA4311D62C575BE8C3BB484829D9F4B7400987BAE35045D00292AEB8EB3A005765D842D3EECF982176908013CBA4311E62C579BE8C3BD484829E9F4B78009873CE39EF00283D08A2F4FA93C005355E71D67800AEF3D3E5F85EA42006FAE91057D8B19F6FA390FD2124A7E7D2DF00261AFB8E73E004F49F9F537C00A8ABEE3ACF8015DD7E7CBD03F48C2FB7D003817488340C58F037D20982912A09F4B8000986C0CB9D00013D2827D4E0002A2B032EB4000576E09F2E3D05217E081BF86062C0853C82242BA451E162C885BE925C3484C3A10027A50CF94D58400ACD433E5B721A42EBF0B7D821858A0";
        }
    
        if (v == Special.JOKER) {
            return hex"404005C28C200010100570A308200404025C28C2100100C0D709A706224F4830DA9A818895610C0080508B84B30411269C20593D21044A6A081655584112BC220010091571285112598285934E14189E90A1653505062AAC285AB8A225884500201032E248C224A2C606261C33B93D21818A6A8CEE565C606581844B308C00401C75C481C2D24706252E3BBAC0E0CB238596A11C0080310B8472080B249643B930E21709E910EE535485C2B3043B965A202CB709000401895C47242D20906249C4BBA792B85044977522570A6C12EEB24832D12165B84900200C52E11C8284492614EE9A501939329DD50A032AB053B965A2844B7094004014B5C462C2D1CB11482C1892596EE4C38B0327A45BB94D52C0CACC16EEB25832D1622B658597212C0080298B8461CC1148301892518EE966002619579A6002719579E600141131DD48C005332AF50C005532AF58C002BB063BAC980C5A6CC112E426001005357118D114734189059AEE4C38D0327A46BB94D5340CACC9AEEB46832D9A225C84D00200A72E231C228E700120C39DD34E03272673BAA1C065564E775A38016CE112E4270010053D7118F11473C009079EEEA07AFE89EA75264F775A3C016CF112E42780100541708C3A0224825000251683BA620B84D51077554170ACBA0EE58650002D368089721400080322B8472111149440094622EE4D3915C27A48B2D4D44570AABA2EEB0880165A4444B70A200401D20048484492524004B352774E49969E924B8A6932D51649DD5D200584971652112D4292E100B4C00987A6EE504535C292A9BBAB2600578535C201AA00139351DCA8CA8005A8545C200EA80120A54D32D500261AA9313935400A8AAA4CACA8015D954D3695002DC2AAE100658008E4AC694A2D6004C58D3356264E59F93D634A822B08A92C69A6B3E2A2C4CAAB1A55975800B0D2C69B6B0017215970802AE004621734A494B8012CD5CD3397264F5DF8A08AE69A4BBE29AE4C5459734ABB0B80165B5CD3717002EC2BAE100560008C3B0694829800259AC1A67304C4F4187E28A4C3E29B04C5459834D760016185C596000B4DB069B8C00176161708023200451D92CA414C8012CD64D33992627A0CBF145265F14D9262A2CC9A6BB200B0CAE2CB2005A7192CDD6400BD0B2B84011A00228ED32D20A68012DA34A61AD13139069F8A29B4F85455A265668D35DA0058697165A002D38D32EEB4005E85A5C2008D8011466D968E5360096D93130F6DF8A08B67B5255B7C566C995DB002C32DAE2D36005B71B65DD6C00BD0B6B8402DC00262AE1ED5977000B0D38B85B71C002EC2E2E100B7400987BA7B5045D00292AE9EEB3A005785D5C2018F00134E78F69E83C00A2F2E293C005351E3DD57800AD0BCB8402DF00261AF9ED3907C00A293EB8A6F8015157CF759F002BC2FAE100B8000986C0CB4E4200028A502E29C0005456065D68000AF0C0B8404210028A50AE14D58400AD0C2B8";
        }
    
        if (v == Special.PRISONER) {
            return hex"401002B4501D28C500569603A531000AD44074A92C015AB80E9587002B5D01D2BD0805640081344304AD101344505D3181344704AC9050268960BA530E04D13C12B5004D144174D204D14C12B2A2C09A2B82E958681345B04AD701345D05D3781345F04ACC108268401022B4509D28C504569613A531008AD44274A92C115AB84E9587022B5D09D2BD084568019A2086564210334450DD28C4066892195A50668961BA6606684D40392510DD2A4A0724AA195AB0668AE1BA6C0668B2195969C0CD174374AF4019A308656401042B4511D28C508569623A5310124944474A92C2492B88E9587042B5D11D2BD0885640085344314AD105344515D3185344714AC9048A68942C9258AE94C405925115D2A4B0B24AE2BA561914D1685925B14AD705345D15D3785345F14ACC108A68401062B4519D28C40C5649286924B19D29880D24A233A54961A495C674AC32349169C18AD74674AF42315A00E688239590841CD114774A31039A124A1E492C774A6203C9288EE95258792571DD360792591CAD687922DB839A2E8EE95E80734611CAC80210568A43A518720AC90511249643A5310224944874A92C4492B90E958648922D38415AE90E95E8482B200449A2192568849A2292E98C49A23925690480124A25972C974A6204B2E892E95258965D725D360965D92401689345B24AD709345D25D3789345F24ACC1092684010A2B4529D28C3945690500124A29972CA74A620532E894E95258A65D729D360A65D92800B4E1456BA53A57A128AD00B34412CAC84216688A5BA51872CD120B0024945B2E596E94C40B65D12DD2A4B16CBAE5BA6C16CBB2580169C2CD174B74AF4059A3096564010C2B4531D28C3985690600124A31972CC74A61A6136718004F40C65D131D348C65D33000A8A984DAC6002B98E9B0632EC98005A70C2B5D31D2BD098564008D344334AD10D344535D318D344734009051ACB966BA661B574D38D0027A06B2E89AE9A46B2E99A00A86D5D55634015CD74AC326B2ED1A00B6695AE1A68BA6BA6F1A68BE695982134D08021C568A73A631C568E700120A39972CE74A61A7135390399744E74A926732D515389B58E65D739D2B0C9CCBB470016DC38AD74E74AF42715A01EC8827B0611EBB4310F34453DD318F34473C009051ECB967BA530F3D9740F47513DD2A4B1ECBAE7BA56193D9768F002DB879A2E9EE95E80F34613CAD01060C1417709058A188815A2A0E9461D02B24128002520CB9683A5310419745074A92C832EBA0E958650002D38815AEA0E95E8502B40457705158C245430D12B4444D115174C644D11D12B4844D1251004A45972D174A6208B2E8A2E95259165D745D3611002CB489A2DA256B889A2EA2E9BC89A2FA256608513440496305250C2493286224568A93A518948AD292004B49D2986A4CB4E412005149D2A49A4005459265D749D2B0E2456BA93A57A148AD01334414CAC84226688A9BA51884CD12532B4A4CD12D374A6209B2E8A6E95255365D64C015D374D84CD16532B2D3899A2EA6E95E81334614CAD0142B41517684228568AA3A518750AC905280096A3A530D50009C828CBA2A3A54935196A8B2800AEA3A56195000B4E2856BAA3A57A150AC8012A8A86A95A22A688AABA632A688EA80120A56492D574A61AAC91390540145574A926A8015155649595005755D2B0CAB24B4A802DAA56B8A9A2EAAE9BCA9A2FAA5660855342008B15A2ACE98CB0011C95A49296004B59D2986AD249CB4AA7AD24A0B4AE8ACE9524D6952A2AB492B2C00AEB3A561A5A496D6005C58AD75674AF40B15B0AC8A80B9A20AE564211734455DD28C42F2449297004B5DD2986AF249CBCA93D05E5345774D25E56A6A2E12AABCA6B2F24AEBBA6C2E00596D7925C5C0175774DE5CD0BF02EC9C2BA29001611484230568AC3A51876249218004960AD298004B61D29883124A2C3A69312A53598925761D361845596000B4DB124B8C002EB0E95E858452004CA761B25688C8022B2E9461D98D486401259344A64012D974A620CC928B2E952599925765D361945596400B4E331ABACBA57A1651480134A686D15A234008AD3A5187699721A004968AD29A004B69D29883400A2D3A549668015DA74D868AD65A002D38D32EEB4E95E81A2B616914800B65484DA2A1B65488D8022B6E98CDB2E3B6004825B2A4A6C012DB74A620DC928B6E95259B92576DD2B0CB654B4D8016DC6D9775B74AF40D95B0B68A4011C2E4571D319C002392E1725380096E3A5310724945C74A92AE492B3800AEE3A6C386B5969C2E2DB8E002EB8E95E85C2E2008E9922BAE94629D324B75D2987BB24A0E8028BAE95255D925674015DD74AC38E992EBAE95E85D322008F1BA2BCE94629E374B79D331E00269CF4927BC00A0F1BA8BCE9A4F0014D47A4955E005678DD5DE74AC38F1BAEBCE95E85E372008F9D62BEE94629F3ACB7DD2986BF1E9CF8013D07CEB45F74D27CEB4DF002A2AFC6AB3E00AEFBA561C7CEB75F74AF42F9D500480FB16074A31501F65C0E94C36065CE80009E8407DA303A69407DA7000151581975A0005781D2B0E407DBB03A57A180FA80242848B0BA518A85092E174A61D08013D0850946174D28508A6AC200AD0A12BC2E958721425D85D2BD0C2840";
        }
    
        if (v == Special.SQUID_GAME) {
            return hex"400C09DC401BA8B0813B400819DA18A0B7518C06769AA02F7558419DA01414ED2D609EEAEF853BC013770853B402439DA5181BDD3540C00AAB86F7587839DAFC21B75008127692508F74B584002BB023DD65D1276BD088DD401C59DA4142BDD2D61400AEC8AF75A8459DA00E34ED20919EE9468C004E4C6ABAA2E300161919EEB508D3B400479DA1063B751071E769048EF74A347004E1EAE9E90E00A63D5D5171C00B0C8EF75A8479DC0227682210DD451C89DC821EE92690009C455D3D220014C8ABAA304002C90F75A8489DA00A4B7518726772097BA49A4802713574F489005326AEA8C1200B24BDD6A12676803953B9053DD24D280138AABA7A45002995575460A005929EEB50953B401CB9DC82DEE92696004E4CBABAA305802C96F75A84B9DA00E64EE418F74960C005931EEB50993B401CD9DC835EE92C1A00B26BDD69E36777CD6EB0426CED0073A769049CF74A5CE002C3273DD69D3A76BD01CDDC274ED0073E769049EF74A5CF002C327BDD6A13E76804213B9283DD29740016107BACC284ED00246770D16EA2108CED24A45EE96B2200576117BACC28CED0014A7684224DD452529DA51693DD3154800ACBA4F7588529DA0149CEE5A6004C3537BA72698015154DEF593002BC29CED007527690528F74B31400269CA3DD3D25000A6A28F755594002BB2A3DD6A152768032B3B472D57BCC54009AA2AF7AAA80159A55EEB70AB3B401569DA316B3DE62C004D4167BD15800A4A2CF7AAB00159B59EEB90AD3B401179DA296BBDE62E004D4177BD15C00A4A2EF7AAB80159C5DEEBB0AF3B401189DA290C3DE4B13B4A3187BCD60009C830F7A2C00149361EF518002AAEC3DEC313B597187BAEC2C4ED003667688432F792CCED28C65EF359002720CBDE8B200524D97BD46400AABB2F7B0CCED65D65EEBD0B33B400DAA92210D3DE4B5524A31A7BCD68009C834F7A2D00149369EF51A002AAED3DEC35525975A7BAF42D5490036EA4883B6F74825BA9252ED8016196EA4B4EB6F7BCDD117E16EA4801B9444419C7BA392E51129771EEB0D39445B75C7BAF42E51100376888833A004729DA225ACEBDD5DA7688B6EBA005E85DA22006F45D10578008C5BD174C3DE7BA822F45D49579EEACDBD175C75E002F42F45D00A7E2E9673EF74F49F8BA9ACFBDD5E17E2E80541044B3A00027A504114D68000AF0C1044022182249D08013D28608A6C420059861820";
        }
    
        if (v == Special.WHERES_WALDO) {
            return hex"800235047018E906008D9A000138F024F4000028A8031D559011AB5000C7C20235001051A84402C74930146A6A40802982C75460146ACBE0B1D821051A800848D4220263A49412352CC08009A9055753542002B30123565F098EC10848D4008346A1921B1E506004B543ABAB2E180161E0D8EBF0868D400C446A210231E488004A5C4ABD81000B2E88C75E84446A0082A35147158F2050024B02D5EC8A005A70563AEC22A35005191A8C38CC748646002D36331D721191A8030E8D8E38012191E4F687002DC23A35006211A8ED10005B84846A00E4A3520A24D896B12CB57649362D424A35006291A8E4146C492CA65A61C50013D22996A6A9400565CA65AC3851B1761291A803968D90580124A2D972CB00261C5D5E796005044B65D22C00A6A9757AC58015D82D9764B002D425A35007311A905980098655E698009C655D3D230014CCABD4300154CABAB3260016A1311B00D63A08C6A3639A004828D65CB34009871B579E6801411359748D0029AA6D5EB1A005764D65DA3400B701A8DC26B1D002398E8631C8D8E700120B39969871C004F48E65A9AA7001599399768E002DBC72357E1398E8021EC74518F46C73C009079ECBA079B689E605264F65DA3C00B6E1E8D5D84F63A00C831E3A08D4825000252E832D619400169046ADC2831D008458F25100252E8B2EC22005985163A012931E524004B35265A726900151649975D2002C42931D00A4DB52D300262A9B2EB2600578536D200EA36920D50009C9A8CB54654002D42A36900655B51D5002414AC9E5AA004C35593A726A801515564F595002BB2AC9ED2A005B8556D200AB3CA32C0047256ABA516B0013155AAEACBAC0058696ABDB5800B90ACF24011779455C008C42F27492970025ACBC9D5D85C00B2DAF27B8B8017615DE480230F28AC00118762AF218004961E52980025ACC55EBB000B0C3CACB0005A6D8ABDC6000BB0B0F2400D98DC464008A3B32790C8024B31B94C8012D6664F5D900586637659002D38CC9EEB2005E8598DA006D46E23400451DAABC8680125A8DCA680096B3557AED002C351BB2D00169C6AAF75A002F42D46D0036E3711B00228CDB2E3B6004825B8DCA6C0096B3636AED8016196E3769B002DB8DB2EEB6005E85B8DA006E4FE238004519C65C77000904B93F4A2DC00262AE0D95977000B0CB93FB4E0016DC719775C002F42E4FD004767E8A33A004729D9FCB7400987BA365045D00292AE8DAB3A005769D9FADB8E801761767E8053D3F96F00130E786D3DE002822F4FE93C005355E1B567800AF0BD3F4029FA4CB7C00986BE369CF8013D27E934DF002A2AF8DAB3E005785FA4A013052528E80009E94149535E0002C430525008869326100251B0AE6742004F4A1A4D38400A8BC2B9B108016618692";
        }
        revert("invalid special");
    } 
}

// File: contracts/BitMonster.sol


pragma solidity ^0.8.0;


struct BitMonster {
    bool genesis;
    bool superYield;
    Special special;
    Dominant dominant;
    Recessive recessive;
    BgColor bgColor;
    Outfit outfit;
    HandAccessory handAccessory;
    Mouth mouth;
    Eyes eyes;
    HeadAccessory headAccessory;
}

// File: contracts/BitMonsterGen.sol


pragma solidity ^0.8.0;





library BitMonsterGen {
    using RngLibrary for Rng;

    function getRandomBgColor(Rng memory rng) internal view returns (BgColor) {
        if (rng.generate(1, 1000) == 1) {
            return BgColor.RAINBOW;
        }
        return BgColor(rng.generate(0, 9));
    }

    function getRandomDominant(Rng memory rng) internal view returns (Dominant) {
        // all rarities are out of 10000
        uint rn = rng.generate(0, 9999);
        uint16[8] memory rarities = Rarities.dominant();
    
        for (uint i = 0; i < rarities.length; ++i) {
            if (rarities[i] > rn) {
                return Dominant(i);
            }
            rn -= rarities[i];
        }
        revert("getRandomDominant() is fucked");
    } 
    
    function getRandomRecessive(Rng memory rng) internal view returns (Recessive) {
        // all rarities are out of 10000
        uint rn = rng.generate(0, 9999);
        uint16[6] memory rarities = Rarities.recessive();
    
        for (uint i = 0; i < rarities.length; ++i) {
            if (rarities[i] > rn) {
                return Recessive(i);
            }
            rn -= rarities[i];
        }
        revert("getRandomRecessive() is fucked");
    } 
    
    function getRandomOutfit(Rng memory rng) internal view returns (Outfit) {
        // all rarities are out of 10000
        uint rn = rng.generate(0, 9999);
        uint16[27] memory rarities = Rarities.outfit();
    
        for (uint i = 0; i < rarities.length; ++i) {
            if (rarities[i] > rn) {
                return Outfit(i);
            }
            rn -= rarities[i];
        }
        revert("getRandomOutfit() is fucked");
    } 
    
    function getRandomHandAccessory(Rng memory rng) internal view returns (HandAccessory) {
        // all rarities are out of 10000
        uint rn = rng.generate(0, 9999);
        uint16[16] memory rarities = Rarities.handaccessory();
    
        for (uint i = 0; i < rarities.length; ++i) {
            if (rarities[i] > rn) {
                return HandAccessory(i);
            }
            rn -= rarities[i];
        }
        revert("getRandomHandAccessory() is fucked");
    } 
    
    function getRandomMouth(Rng memory rng) internal view returns (Mouth) {
        // all rarities are out of 10000
        uint rn = rng.generate(0, 9999);
        uint16[22] memory rarities = Rarities.mouth();
    
        for (uint i = 0; i < rarities.length; ++i) {
            if (rarities[i] > rn) {
                return Mouth(i);
            }
            rn -= rarities[i];
        }
        revert("getRandomMouth() is fucked");
    } 
    
    function getRandomEyes(Rng memory rng) internal view returns (Eyes) {
        // all rarities are out of 10000
        uint rn = rng.generate(0, 9999);
        uint16[24] memory rarities = Rarities.eyes();
    
        for (uint i = 0; i < rarities.length; ++i) {
            if (rarities[i] > rn) {
                return Eyes(i);
            }
            rn -= rarities[i];
        }
        revert("getRandomEyes() is fucked");
    } 
    
    function getRandomHeadAccessory(Rng memory rng) internal view returns (HeadAccessory) {
        // all rarities are out of 10000
        uint rn = rng.generate(0, 9999);
        uint16[29] memory rarities = Rarities.headaccessory();
    
        for (uint i = 0; i < rarities.length; ++i) {
            if (rarities[i] > rn) {
                return HeadAccessory(i);
            }
            rn -= rarities[i];
        }
        revert("getRandomHeadAccessory() is fucked");
    } 

    function generateUnspecialBitMonster(Rng memory rng) internal view returns (BitMonster memory) {
        BitMonster memory ret = BitMonster({
            genesis:       true,
            superYield:    rng.generate(0, 99) == 0,
            special:       Special.NONE,
            dominant:      getRandomDominant(rng),
            recessive:     getRandomRecessive(rng),
            bgColor:       getRandomBgColor(rng),
            outfit:        getRandomOutfit(rng),
            handAccessory: getRandomHandAccessory(rng),
            mouth:         getRandomMouth(rng),
            eyes:          getRandomEyes(rng),
            headAccessory: getRandomHeadAccessory(rng)
        });

        return ret;
    }

    function generateSpecialBitMonster(Rng memory rng, bool[9] memory mintedSpecials) internal view returns (BitMonster memory) {
        uint available = mintedSpecials.length;
        for (uint i = 0; i < mintedSpecials.length; ++i) {
            if (mintedSpecials[i]) {
                available--;
            }
        }

        if (available == 0) {
            return generateUnspecialBitMonster(rng);
        }

        uint rn = rng.generate(0, available - 1);
        uint special;

        // generate a random special index, skipping specials that do not exist
        for (special = 0; special < 9; ++special) {
            if (mintedSpecials[special]) {
                continue;
            }
            if (rn == 0) {
                break;
            }
            rn -= 1;
        }

        require(!mintedSpecials[special]);
        mintedSpecials[special] = true;

        return BitMonster({
            genesis:       true,
            superYield:    rng.generate(0, 4) == 0,
            // + 1 because 0 is None
            special:       Special(special + 1),
            dominant:      getRandomDominant(rng),
            recessive:     getRandomRecessive(rng),
            bgColor:       BgColor.DARK_BLUE,
            outfit:        Outfit.NONE,
            handAccessory: HandAccessory.NONE,
            mouth:         Mouth.NONE,
            eyes:          Eyes.NONE,
            headAccessory: HeadAccessory.NONE
        });
    }

    function rerollTrait(Rng memory rng, BitMonster memory bm, RerollTrait trait) internal view {
        bm.genesis = false;
        if (trait == RerollTrait.BgColor) {
            BgColor existing = bm.bgColor;
            while (bm.bgColor == existing) {
                bm.bgColor = getRandomBgColor(rng);
            }
        }
        else if (trait == RerollTrait.Outfit) {
            Outfit existing = bm.outfit;
            while (bm.outfit == existing) {
                bm.outfit = getRandomOutfit(rng);
            }
        }
        else if (trait == RerollTrait.HandAccessory) {
            HandAccessory existing = bm.handAccessory;
            while (bm.handAccessory == existing) {
                bm.handAccessory = getRandomHandAccessory(rng);
            }
        }
        else if (trait == RerollTrait.Mouth) {
            Mouth existing = bm.mouth;
            while (bm.mouth == existing) {
                bm.mouth = getRandomMouth(rng);
            }
        }
        else if (trait == RerollTrait.Eyes) {
            Eyes existing = bm.eyes;
            while (bm.eyes == existing) {
                bm.eyes = getRandomEyes(rng);
            }
        }
        else if (trait == RerollTrait.HeadAccessory) {
            HeadAccessory existing = bm.headAccessory;
            while (bm.headAccessory == existing) {
                bm.headAccessory = getRandomHeadAccessory(rng);
            }
        }
        else {
            revert("Invalid reroll trait");
        }
    }

    function rerollAll(Rng memory rng, BitMonster memory bm) internal view {
        bm.genesis = false;
        bm.bgColor = getRandomBgColor(rng);
        bm.outfit = getRandomOutfit(rng);
        bm.handAccessory = getRandomHandAccessory(rng);
        bm.mouth = getRandomMouth(rng);
        bm.eyes = getRandomEyes(rng);
        bm.headAccessory = getRandomHeadAccessory(rng);
    }
}

// File: contracts/Base64.sol


pragma solidity ^0.8.0;

// shamelessly stolen from the anonymice contract
library Base64 {
    string internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function encode(bytes memory data) external pure returns (string memory) {
        if (data.length == 0) return "";

        // load the table into memory
        string memory table = TABLE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {

            } lt(dataPtr, endPtr) {

            } {
                dataPtr := add(dataPtr, 3)

                // read 3 bytes
                let input := mload(dataPtr)

                // write 4 characters
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(input, 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }
        }

        return result;
    }
}

// File: @openzeppelin/contracts/utils/Strings.sol



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

// File: contracts/Colors.sol


pragma solidity ^0.8.0;




library Colors {
    using StringBufferLibrary for StringBuffer;

    function uintToColorString(uint value) internal pure returns (string memory) {
        require(value >= 0x000000 && value <= 0xFFFFFF, "color out of range");
        bytes memory symbols = "0123456789ABCDEF";
        bytes memory buf = new bytes(6);

        for (uint i = 0; i < 6; ++i) {
            buf[5 - i] = symbols[Integer.bitsFrom(value, (i * 4) + 3, i * 4)];
        }

        return string(abi.encodePacked(buf));
    }

    function getRainbowCss(StringBuffer memory sb) internal pure {
        bytes memory colors = hex"FF0000FF8800FFFF0000FF0000FFFF8800FFFF00FF";

        for (uint i = 0; i < colors.length; i += 3) {
            uint val = (uint(uint8(colors[i])) << 16) + (uint(uint8(colors[i + 1])) << 8) + uint(uint8(colors[i + 2]));
            sb.append(string(abi.encodePacked(
                ".r",
                Strings.toString(i / 3),
                "{fill:#",
                uintToColorString(val),
                "}"
            )));
        }
    }

    function getColorCss(StringBuffer memory sb) internal pure {
        bytes memory colors = hex"0000000202020606050A0B0A10193D11111111578B121212121312131313134C8C14172315592D1616161717171718181719181A0C0D1A19191A1A1A1A1D2D1B589E1B6C371D1D1D1E0F101E1E1E1F1F1F207F3F210F0F225084234F812363AF24283A243E86258541262626263C9227272728282728389429100F2A0F0E2A10102A2A2A2A2B2A2B39912B84BF2C2C2B2E2E2E31313131B0DA32B44A3311113333333383C533B04A3434343535353565A235924436363638383838429B3913123A21123A3A3A3B17173B3B3A3B51A33D4B9F3D4FA23E3E3E3E689C3F40404058A7408940412668414141433217433B364444444450A24454254575B24646464762AD49484849B2494A14134A2B754B65AF4E2B144E4E4F4E77AB4F4F4F502323514B29519ACC521212535352535353536B3454555454B948555555562C825636185756525938355A54375B5B5C5B5D285D35175D5D5D607A35623D2562636363646464656564A5DA65AFE06868686969696A38956A39176B6B6B6E41196F6E6F70717171726E717272727560737374743F1A75441B76441B773C197878787979797A461D7B481D7BCCF27C13197C7C7C7F461E7FC34A802A2A80808080836781461E814B1F818182824D1F82828283848484191C8485858584858588C2858972868C368886868951A08A51218A7F7C8A83818A8A8A8B26268B53228C62A98D8D8D8E52A18F1A298F553E916928925724929292939393965426979B7F97CA52982524983839989898992D2C9D7E4F9DD6E49E9E9E9F1D21A11F4BA2A1A1A33534A35F2FA3A2A1A46A45A51E22A59332A5D099A92451AEE2F8AFAEAEB0B0B1B12325B1CA36B32126B471AFB51F35B52125B72426B82025B8305DBAB9BABC262ABD2428C0C0C0C22126C43465C83464C8AF88C8C8C8C9AC60CAEAF2CB4549CBE199CCAA47CCCB6ACD2C2DCD7F4BCE2227CF393ED33E6FD3D3D3D42027D4D4D4D52628D53229D6AC57D6D5D5D6E377D71F27D796C2D7C427D9BD92DB6E71DBB927DBD4D3DBDCBDDC2727DC8A32DCDCDCDD2126DD888BDD9B33DDDDDDE0B794E0E0DFE0E2C1E11F26E14243E1E2E1E2B486E2BB6FE2E65DE3494AE38E75E3BE9FE3E3E3E43A34E44C7EE58C8EE6618DE6A2A4E6BD43E6E9C6E79598E81D25E85C8AE8E7E7E97A63E9BF95E9C6A9E9E8E8EA8D26EACA9BEB3837EB6763EB8D25EBC220EBC376EBC71DEC1D25EC4A45EC8E25ECECECED1C24ED1E25ED2024ED8B22ED8E25ED8E26EDCEB3EE9B57EF3E23EF474DEFB1B2EFD2BAEFE920EFEEEEEFF4CEF04E4FF0C519F0ED7AF15E5FF16C97F1CA7DF1F6F7F278A0F2CD5EF3B282F3D5A7F3D9C3F48588F57E20F5C8C9F5CCA4F5F085F6A1ABF6E0CEF6F09CF7DDB4F7F8F8F8AFB1F8D1D1F8ED87F9DB07FACE0BFCF7BCFDFBE3FED7B2FEE900FFC709FFCD05FFF9DBFFFFFF";
        for (uint i = 0; i < colors.length; i += 3) {
            uint val = (uint(uint8(colors[i])) << 16) + (uint(uint8(colors[i + 1])) << 8) + uint(uint8(colors[i + 2]));
            sb.append(string(abi.encodePacked(
                ".c",
                Strings.toString(i / 3),
                "{fill:#",
                uintToColorString(val),
                "}"
            )));
        }
    }
}

// File: contracts/Renderer.sol


pragma solidity ^0.8.0;








enum RendererState {
    HEADER,
    HEADER_ZERO,
    PIXEL_COL,
    ROW_LCOL,
    ROW_RCOL,
    ROW,
    COLOR
}

library Renderer {
    using StringBufferLibrary for StringBuffer;

    uint256 private constant COL_BITS = 6;
    uint256 private constant ROW_BITS = 6;
    uint256 private constant COLOR_BITS = 9;

    function renderBg(BgColor c) public pure returns (string memory) {
        if (c == BgColor.RAINBOW) {
            return "<rect x='0' y='0' width='34' height='34'><animate attributeName='class' values='r0;r1;r2;r3;r4;r5;r6' dur='1s' repeatCount='indefinite'/></rect>";
        }
        else {
            string memory color = Sprites.getBgHex(c);
            return
                string(
                    abi.encodePacked(
                        "<rect style='fill: #",
                        color,
                        "' x='0' y='0' width='34' height='34'/>"
                    )
                );
        }
    }

    function renderSprite(bytes memory b, StringBuffer memory sb) public pure {
        RendererState state = RendererState.HEADER;
        uint256 buffer = 0;
        uint256 bufferPos = 0;
        uint256 lcol = 0;
        uint256 rcol = 0;
        uint256 col = 0;
        uint256 row = 0;
        bool isRow = false;

        for (uint256 i = 0; i < b.length; ++i) {
            uint256 byt = uint256(uint8(b[i]));
            for (int256 j = 7; j >= 0; --j) {
                uint256 bit = Integer.bitAt(byt, uint256(j));

                if (state == RendererState.HEADER) {
                    if (bit == 0) {
                        // 01 starts a row
                        state = RendererState.HEADER_ZERO;
                    } else {
                        // 1 starts a pixel
                        isRow = false;
                        state = RendererState.PIXEL_COL;
                    }
                } else if (state == RendererState.HEADER_ZERO) {
                    if (bit == 0) {
                        // 00 ends the sequence
                        return;
                    } else {
                        // 01 starts a row
                        isRow = true;
                        state = RendererState.ROW_LCOL;
                    }
                } else if (state == RendererState.PIXEL_COL) {
                    buffer = buffer * 2 + bit;
                    bufferPos++;
                    if (bufferPos == COL_BITS) {
                        col = buffer;
                        buffer = 0;
                        bufferPos = 0;
                        state = RendererState.ROW;
                    }
                } else if (state == RendererState.ROW_LCOL) {
                    buffer = buffer * 2 + bit;
                    bufferPos++;
                    if (bufferPos == COL_BITS) {
                        lcol = buffer;
                        buffer = 0;
                        bufferPos = 0;
                        state = RendererState.ROW_RCOL;
                    }
                } else if (state == RendererState.ROW_RCOL) {
                    buffer = buffer * 2 + bit;
                    bufferPos++;
                    if (bufferPos == COL_BITS) {
                        rcol = buffer;
                        buffer = 0;
                        bufferPos = 0;
                        state = RendererState.ROW;
                    }
                } else if (state == RendererState.ROW) {
                    buffer = buffer * 2 + bit;
                    bufferPos++;
                    if (bufferPos == ROW_BITS) {
                        row = buffer;
                        buffer = 0;
                        bufferPos = 0;
                        state = RendererState.COLOR;
                    }
                } else {
                    buffer = buffer * 2 + bit;
                    bufferPos++;
                    if (bufferPos == COLOR_BITS) {
                        if (isRow) {
                            sb.append(
                                string(
                                    abi.encodePacked(
                                        "<rect class='c",
                                        Strings.toString(buffer),
                                        "' x='",
                                        Strings.toString(lcol),
                                        "' y='"
                                    )
                                )
                            );
                            sb.append(
                                string(
                                    abi.encodePacked(
                                        Strings.toString(row),
                                        "' width='",
                                        Strings.toString(rcol - lcol + 1),
                                        "' height='1'/>"
                                    )
                                )
                            );
                        } else {
                            sb.append(
                                string(
                                    abi.encodePacked(
                                        "<rect class='c",
                                        Strings.toString(buffer),
                                        "' x='"
                                    )
                                )
                            );
                            sb.append(
                                string(
                                    abi.encodePacked(
                                        Strings.toString(col),
                                        "' y='",
                                        Strings.toString(row),
                                        "' width='1' height='1'/>"
                                    )
                                )
                            );
                        }
                        buffer = 0;
                        bufferPos = 0;
                        state = RendererState.HEADER;
                    }
                }
            }
        }
    }

    function debugSpriteToSvg(bytes memory sprite)
        public
        pure
        returns (string memory)
    {
        StringBuffer memory sb = StringBufferLibrary.empty();

        sb.append(
            "<svg class='nft' xmlns='http://www.w3.org/2000/svg' viewBox='0 0 34 34' height='100%' width='100%'>"
        );
        renderSprite(sprite, sb);
        sb.append("<style>svg.nft{shape-rendering: crispEdges}");
        Colors.getColorCss(sb);
        sb.append("</style></svg>");

        return sb.get();
    }

    function addSvgHeader(StringBuffer memory sb) internal pure {
        sb.append(
            "<svg class='nft' xmlns='http://www.w3.org/2000/svg' viewBox='0 0 34 34' height='100%' width='100%'>"
        );
    }

    function addSvgFooter(StringBuffer memory sb) internal pure {
        sb.append("<style>svg.nft{shape-rendering: crispEdges}");
        Colors.getColorCss(sb);
        Colors.getRainbowCss(sb);
        sb.append("</style></svg>");
    }

    function bitMonsterToSvg(BitMonster memory bm)
        external
        pure
        returns (string memory)
    {
        StringBuffer memory sb = StringBufferLibrary.empty();

        addSvgHeader(sb);
        if (bm.special == Special.NONE) {
            sb.append(renderBg(bm.bgColor));
            renderSprite(Sprites.BODY_SPRITE, sb);
            renderSprite(Sprites.getOutfitSprite(bm.outfit), sb);
            renderSprite(Sprites.getHandAccessorySprite(bm.handAccessory), sb);
            if (bm.mouth != Mouth.BREATHING_FIRE) {
                renderSprite(Sprites.getMouthSprite(bm.mouth), sb);
            }
            if (bm.eyes != Eyes.LASER_EYES) {
                renderSprite(Sprites.getEyesSprite(bm.eyes), sb);
            }
            renderSprite(Sprites.getHeadAccessorySprite(bm.headAccessory), sb);
            if (bm.mouth == Mouth.BREATHING_FIRE) {
                renderSprite(Sprites.getMouthSprite(bm.mouth), sb);
            }
            if (bm.eyes == Eyes.LASER_EYES) {
                renderSprite(Sprites.getEyesSprite(bm.eyes), sb);
            }
        }
        else {
            renderSprite(SpecialSprites.getSpecialSprite(bm.special), sb);
        }
        addSvgFooter(sb);

        return sb.get();
    }
}

// File: @openzeppelin/contracts/utils/Context.sol



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

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol



pragma solidity ^0.8.0;




/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// File: @openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol



pragma solidity ^0.8.0;



/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        uint256 currentAllowance = allowance(account, _msgSender());
        require(currentAllowance >= amount, "ERC20: burn amount exceeds allowance");
        unchecked {
            _approve(account, _msgSender(), currentAllowance - amount);
        }
        _burn(account, amount);
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol



pragma solidity ^0.8.0;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: @openzeppelin/contracts/utils/Address.sol



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

// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol



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

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol



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

// File: @openzeppelin/contracts/utils/introspection/ERC165.sol



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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol



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

// File: @openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol



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

// File: contracts/IBitMonsters.sol


pragma solidity ^0.8.0;



interface IBitMonsters is IERC721Enumerable {
    function getBitMonster(uint256 tokenId) external view returns (BitMonster memory);
    function setBitMonster(uint256 tokenId, BitMonster memory bm) external;
    function createBitMonster(BitMonster memory bm, address owner) external;
    function isAdmin(address addr) external view returns (bool);
}
// File: contracts/BitMonstersAddon.sol


pragma solidity ^0.8.0;



/**
 * @title A contract should inherit this if it provides functionality for the Bit Monsters contract.
 */
abstract contract BitMonstersAddon is Ownable {
    IBitMonsters internal bitMonsters;

    modifier onlyAdmin() {
        require(bitMonsters.isAdmin(msg.sender), "admins only");
        _;
    }

    modifier ownsToken(uint tokenId) {
        require(bitMonsters.ownerOf(tokenId) == msg.sender, "you don't own this shit");
        _;
    }

    /**
     * @notice This must be called before the Brainz contract can be used.
     *
     * @dev Within the BitMonsters contract, call initializeBrainz().
     */
    function setBitMonstersContract(IBitMonsters _contract) external onlyOwner {
        bitMonsters = _contract;
    }
}

// File: contracts/Metadata.sol


pragma solidity ^0.8.0;







struct JsonAttribute {
    string key;
    string value;
}

contract Metadata is BitMonstersAddon {
    using Strings for uint;
    using Enums for *;
    using StringBufferLibrary for StringBuffer;

    mapping (uint256 => string) private names;

    function specialOsBgColor(Special s) internal pure returns (string memory) {
        if (s == Special.NONE) {
            return "FFFFFF";
        } 
        if (s == Special.DEVIL) {
            return "FF0000";
        }
        if (s == Special.GHOST) {
            return "FFFFFF";
        }
        if (s == Special.HIPPIE) {
            return "FF00FF";
        }
        if (s == Special.JOKER) {
            return "00FF00";
        }
        if (s == Special.PRISONER) {
            return "FFFF00";
        }
        if (s == Special.SQUID_GAME) {
            return "0088FF";
        }
        if (s == Special.WHERES_WALDO) {
            return "CC0000";
        }
        if (s == Special.HAZMAT) {
            return "FFFF00";
        }
        if (s == Special.ASTRONAUT) {
            return "000000";
        }
        revert("Invalid special given");
    }

    function makeOsMetadataArray(JsonAttribute[] memory attributes) public pure returns (string memory) {
        StringBuffer memory sb = StringBufferLibrary.empty();

        sb.append("[");
        bool empty = true;

        for (uint i = 0; i < attributes.length; ++i) {
            if (bytes(attributes[i].value).length > 0) {
                sb.append(string(abi.encodePacked(
                    empty ? "" : ",",
                    '{"trait_type":"',
                    attributes[i].key,
                    '","value":"',
                    attributes[i].value,
                    '"}'
                )));
                empty = false;
            }
        }

        sb.append("]");
        return sb.get();
    }

    function getName(uint tokenId) public view returns (string memory name) {
        name = names[tokenId];
        if (bytes(name).length == 0) {
            name = string(abi.encodePacked("Bit Monster #", Strings.toString(tokenId)));
        }
    }

    function setName(uint tokenId, string memory name) external ownsToken(tokenId) {
        bytes memory b = bytes(name);
        for (uint i = 0; i < b.length; ++i) {
            uint8 char = uint8(b[i]);
            //              0-9                         A-Z                         a-z                   space
            if (!(char >= 48 && char <= 57 || char >= 65 && char <= 90 || char >= 97 && char <= 122 || char == 32)) {
                revert("all chars must be [a-zA-Z0-9]");
            }
        }
        names[tokenId] = name;
    }

    function getMetadataJson(uint tokenId) external view returns (string memory) {
        BitMonster memory m = bitMonsters.getBitMonster(tokenId);
        string memory svg = Renderer.bitMonsterToSvg(m);
        string memory svgDataUrl = string(abi.encodePacked(
            "data:image/svg+xml;base64,",
            string(Base64.encode(bytes(svg)))
        ));

        JsonAttribute[] memory attributes;
        string memory bgColor;
        if (m.special != Special.NONE) {
            attributes = new JsonAttribute[](5);
            attributes[4] = JsonAttribute("Legendary", m.special.toString());
            bgColor = specialOsBgColor(m.special);
        }
        else {
            attributes = new JsonAttribute[](10);
            attributes[4] = JsonAttribute("Background Color", m.bgColor.toString());
            attributes[5] = JsonAttribute("Outfit", m.outfit.toString());
            attributes[6] = JsonAttribute("Hand Accessory", m.handAccessory.toString());
            attributes[7] = JsonAttribute("Mouth", m.mouth.toString());
            attributes[8] = JsonAttribute("Eyes", m.eyes.toString());
            attributes[9] = JsonAttribute("Head Accessory", m.headAccessory.toString());
            bgColor = Sprites.getBgHex(m.bgColor);
        }
        attributes[0] = JsonAttribute("Super Yield", m.superYield ? "true" : "");
        attributes[1] = JsonAttribute("Genesis", m.genesis ? "true" : "");
        attributes[2] = JsonAttribute("Dominant Gene", m.dominant.toString());
        attributes[3] = JsonAttribute("Recessive Gene", m.recessive.toString());

        return string(abi.encodePacked(
            '{"name":"',
            getName(tokenId),
            '","description":"8==D","image":"',
            svgDataUrl,
            '","attributes":',
            makeOsMetadataArray(attributes),
            ',"background_color":"',
            bgColor,
            '"}'
        ));
    }
}

// File: contracts/Minter.sol


pragma solidity ^0.8.0;







/**
 * @title Controls who (if anyone) can mint a Bit Monster.
 *
 * @dev In web3, these are represented as 0 (NotAllowed), 1 (WhitelistOnly), and 2 (AllAllowed).
 */
enum MintingState {
    NotAllowed,
    WhitelistOnly,
    AllAllowed
}

contract Minter is BitMonstersAddon {
    using RngLibrary for Rng;

    uint256 constant public WHITELIST_PER = 6;

    address payable private payHere;
    // 0 == "not whitelisted"
    // 1000 + x == "whitelisted and x whitelists left"
    mapping (address => uint256) public whitelist;
    MintingState public mintingState;

    bool[9] public mintedSpecials;
    uint private mintedSpecialsCount = 0;

    Rng private rng;

    constructor(address payable paymentAddress, address[] memory whitelistedAddrs) {
        payHere = paymentAddress;
        whitelist[paymentAddress] = WHITELIST_PER + 1000;
        for (uint i = 0; i < whitelistedAddrs.length; ++i) {
            whitelist[whitelistedAddrs[i]] = WHITELIST_PER + 1000;
        }
        rng = RngLibrary.newRng();
    }

    /**
     * Adds someone to the whitelist.
     */
    function addToWhitelist(address[] memory addrs) external onlyAdmin {
        for (uint i = 0; i < addrs.length; ++i) {
            if (whitelist[addrs[i]] == 0) {
                whitelist[addrs[i]] = WHITELIST_PER + 1000;
            }
        }
    }

    /**
     * Removes someone from the whitelist.
     */
    function removeFromWhitelist(address addr) external onlyAdmin {
        delete whitelist[addr];
    }

    /**
     * Generates a random Bit Monster.
     *
     * 9/6666 bit monsters will be special, which means they're prebuilt images instead of assembled from the 6 attributes a normal Bit Monster has.
     * All 9 specials are guaranteed to be minted by the time all 6666 Bit Monsters are minted.
     * The chance of a special at each roll is roughly even, although there's a slight dip in chance in the mid-range.
     */
    function generateBitMonster(Rng memory rn, bool[9] memory ms) internal returns (BitMonster memory) {
        uint count = bitMonsters.totalSupply();

        int ub = 6666 - int(count) - 1 - (90 - int(mintedSpecialsCount) * 10);
        if (ub < 0) {
            ub = 0;
        }

        BitMonster memory m;
        if (rn.generate(0, uint(ub)) <= (6666 - count) / 666) {
            m = BitMonsterGen.generateSpecialBitMonster(rn, ms);
        }
        else {
            m = BitMonsterGen.generateUnspecialBitMonster(rn);
        }

        if (m.special != Special.NONE) {
            mintedSpecialsCount++;
        }
        rng = rn;
        return m;
    }

    /**
     * Sets the MintingState. See MintingState above.
     * By default, no one is allowed to mint. This function must be called before any Bit Monsters can be minted.
     */
    function setMintingState(MintingState state) external onlyAdmin {
        mintingState = state;
    }

    /**
     * Mints some Bit Monsters.
     *
     * @param count The number of Bit Monsters to mint. Must be >= 1 and <= 10.
     *              You must send 0.06 ETH for each Bit Monster you want to mint.
     */
    function mint(uint count) external payable {
        require(count >= 1 && count <= 10, "Count must be >=1 and <=10");
        require(!Address.isContract(msg.sender), "Contracts cannot mint");
        require(mintingState != MintingState.NotAllowed, "Minting is not allowed atm");

        if (mintingState == MintingState.WhitelistOnly) {
            require(whitelist[msg.sender] >= 1000 + count, "Not enough whitelisted mints");
            whitelist[msg.sender] -= count;
        }

        require(msg.value == count * 0.06 ether, "Send exactly 0.06 ETH for each mint");

        Rng memory rn = rng;
        bool[9] memory ms = mintedSpecials;

        for (uint i = 0; i < count; ++i) {
            bitMonsters.createBitMonster(generateBitMonster(rn, ms), msg.sender);
        }

        rng = rn;
        mintedSpecials = ms;

        Address.sendValue(payHere, msg.value);
    }

    /**
     * Mint for a giveaway.
     */
    function giveawayMint(address[] memory winners) external onlyAdmin {
        Rng memory rn = rng;

        for (uint i = 0; i < winners.length; ++i) {
            bitMonsters.createBitMonster(BitMonsterGen.generateUnspecialBitMonster(rn), winners[i]);
        }

        rng = rn;
    }
}
// File: contracts/Brainz.sol


pragma solidity ^0.8.0;









// shamelessly "inspired by" the anonymice cheeth contract

/**
 * @title The contract for the Brainz token and staking. At the moment, these can only be obtained by staking Bit Monsters.
 */
contract Brainz is ERC20Burnable, BitMonstersAddon {
    using RngLibrary for Rng;

    mapping (uint => uint) public tokenIdToTimestamp;
    Rng private rng = RngLibrary.newRng();

    constructor() ERC20("Brainz", "BRAINZ") {
    }

    function adminMint(address addr, uint256 count) external onlyAdmin {
        _mint(addr, count * 1 ether);
    }

    function adminBurn(address addr, uint256 count) external onlyAdmin {
        _burn(addr, count * 1 ether);
    }

    /**
     * Claims all Brainz from all staked Bit Monsters the caller owns.
     */
    function claimBrainz() external {
        uint count = bitMonsters.balanceOf(msg.sender);
        uint total = 0;

        for (uint i = 0; i < count; ++i) {
            uint tokenId = bitMonsters.tokenOfOwnerByIndex(msg.sender, i);
            uint rewards = calculateRewards(tokenId);
            if (rewards > 0) {
                tokenIdToTimestamp[tokenId] = block.timestamp - ((block.timestamp - tokenIdToTimestamp[tokenId]) % 86400);
            }
            total += rewards;
        }

        _mint(msg.sender, total);
    }

    function rewardRate(BitMonster memory m) public pure returns (uint) {
        return ((m.genesis ? 2 : 1) * (m.special != Special.NONE ? 2 : 1) + (m.superYield ? 1 : 0)) * 1 ether;
    }

    /**
     * Returns the amount of pending Brainz the caller can currently claim.
     */
    function calculateRewards(uint tokenId) public view returns (uint) {
        BitMonster memory m = bitMonsters.getBitMonster(tokenId);
        uint nDays = (block.timestamp - tokenIdToTimestamp[tokenId]) / 86400;

        return rewardRate(m) * nDays;
    }

    /**
     * Tracks the Bit Monster with the given tokenId for reward calculation.
     */
    function register(uint tokenId) external onlyAdmin {
        require(tokenIdToTimestamp[tokenId] == 0, "already staked");
        tokenIdToTimestamp[tokenId] = block.timestamp;
    }

    /**
     * Stake your Brainz a-la OSRS Duel Arena.
     *
     * 50% chance of multiplying your Brainz by 1.9x rounded up.
     * 50% chance of losing everything you stake.
     */
    function stake(uint count) external returns (bool won) {
        require(count > 0, "Must stake at least one BRAINZ");
        require(balanceOf(msg.sender) >= count, "You don't have that many tokens");

        Rng memory rn = rng;

        if (rn.generate(0, 1) == 0) {
            _mint(msg.sender, (count - count / 10) * 1 ether);
            won = true;
        }
        else {
            _burn(msg.sender, count * 1 ether);
            won = false;
        }

        rng = rn;
    }
}

// File: contracts/Mutator.sol


pragma solidity ^0.8.0;







contract Mutator is BitMonstersAddon {
    using RngLibrary for Rng;

    Brainz private brainz;
    Rng private rng = RngLibrary.newRng();

    constructor(Brainz _brainz) {
        brainz = _brainz;
    }

    function rerollTrait(uint256 tokenId, RerollTrait trait) external ownsToken(tokenId) {
        BitMonster memory bm = bitMonsters.getBitMonster(tokenId);
        require(bm.special == Special.NONE, "Specials cannot be rerolled");

        Rng memory rn = rng;

        uint brainzCount;
        if (trait == RerollTrait.BgColor) {
            brainzCount = 4;
        }
        else if (trait == RerollTrait.HandAccessory) {
            brainzCount = 10;
        }
        else {
            brainzCount = 8;
        }

        brainz.adminBurn(msg.sender, brainzCount);

        BitMonsterGen.rerollTrait(rn, bm, trait);

        bitMonsters.setBitMonster(tokenId, bm);
        rng = rn;
    }

    function rerollAll(uint256 tokenId) external ownsToken(tokenId) {
        BitMonster memory bm = bitMonsters.getBitMonster(tokenId);
        require(bm.special == Special.NONE, "Specials cannot be rerolled");

        Rng memory rn = rng;

        brainz.adminBurn(msg.sender, 10);

        BitMonsterGen.rerollAll(rn, bm);

        bitMonsters.setBitMonster(tokenId, bm);
        rng = rn;
    }

    function mutate(uint256 donorId, uint256 recipientId, RerollTrait trait, uint256 brainzCount) external ownsToken(donorId) ownsToken(recipientId) returns (bool donorBurnt, bool recipientSuccess) {
        require(bitMonsters.ownerOf(donorId) == msg.sender, "you don't own the donor");
        require(bitMonsters.ownerOf(recipientId) == msg.sender, "you don't own the recipient");
        require(donorId != recipientId, "the donor and recipient are the same");
        require(brainzCount > 0, "must use at least one brainz");

        brainz.adminBurn(msg.sender, brainzCount);

        BitMonster memory donor = bitMonsters.getBitMonster(donorId);
        BitMonster memory recipient = bitMonsters.getBitMonster(recipientId);

        require(donor.special == Special.NONE && recipient.special == Special.NONE, "can't mutate special");
        require(trait != RerollTrait.BgColor || donor.bgColor != BgColor.RAINBOW, "rainbow bg cannot be mutated");

        Rng memory rn = rng;

        // success rate of mutation = brainz / (brainz + 3)
        if (rn.generate(1, brainzCount + 3) <= brainzCount) {
            recipientSuccess = true;
            recipient.genesis = false;
            if (trait == RerollTrait.BgColor) {
                recipient.bgColor = donor.bgColor;
            }
            else if (trait == RerollTrait.Outfit) {
                recipient.outfit = donor.outfit;
            }
            else if (trait == RerollTrait.HandAccessory) {
                recipient.handAccessory = donor.handAccessory;
            }
            else if (trait == RerollTrait.Mouth) {
                recipient.mouth = donor.mouth;
            }
            else if (trait == RerollTrait.Eyes) {
                recipient.eyes = donor.eyes;
            }
            else if (trait == RerollTrait.HeadAccessory) {
                recipient.headAccessory = donor.headAccessory;
            }
            else {
                revert("Invalid trait");
            }
        }
        // chance of burning the donor trait is a flat 1/3
        if (rn.generate(1, 3) == 1) {
            donorBurnt = true;
            donor.genesis = false;

            // background color can't be burned
            if (trait == RerollTrait.Outfit) {
                donor.outfit = Outfit.NONE;
            }
            else if (trait == RerollTrait.HandAccessory) {
                donor.handAccessory = HandAccessory.NONE;
            }
            else if (trait == RerollTrait.Mouth) {
                donor.mouth = Mouth.NONE;
            }
            else if (trait == RerollTrait.Eyes) {
                donor.eyes = Eyes.NONE;
            }
            else if (trait == RerollTrait.HeadAccessory) {
                donor.headAccessory = HeadAccessory.NONE;
            }
        }

        bitMonsters.setBitMonster(donorId, donor);
        bitMonsters.setBitMonster(recipientId, recipient);

        rng = rn;
    }
}

// File: @openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol



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

// File: @openzeppelin/contracts/token/ERC721/ERC721.sol



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

// File: @openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol



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

// File: contracts/BitMonsters.sol


pragma solidity ^0.8.0;











/**
 * @title The Bit Monsters contract. This is where all of the magic happens.
 */
contract BitMonsters is IBitMonsters, ERC721Enumerable, Ownable {
    uint256 constant public SUPPLY_LIMIT = 6666;
    using RngLibrary for Rng;

    mapping (uint256 => BitMonster) public tokenIdToBitMonster;

    Brainz public brainz;
    Mutator public mutator;
    Minter public minter;
    Metadata public metadata;
    mapping (address => bool) private admins;

    bool private initialized;

    /**
     * @param whitelistedAddrs The addresses that are allowed to mint when the mintingState is WhiteListOnly.
                               The owner of the contract is automatically whitelisted, so the owning address doesn't need to be given.
     */
    constructor(address[] memory whitelistedAddrs) ERC721("Bit Monsters", unicode"💰🧟") {
        brainz = new Brainz();
        mutator = new Mutator(brainz);
        minter = new Minter(payable(msg.sender), whitelistedAddrs);
        metadata = new Metadata();
        address[5] memory a = [msg.sender, address(brainz), address(mutator), address(minter), address(metadata)];
        for (uint i = 0; i < a.length; ++i) {
            admins[a[i]] = true;
        }
    }

    function isAdmin(address addr) public view override returns (bool) {
        return owner() == addr || admins[addr];
    }

    modifier onlyAdmin() {
        require(isAdmin(msg.sender), "admins only");
        _;
    }

    function addAdmin(address addr) external onlyAdmin {
        admins[addr] = true;
    }

    function removeAdmin(address addr) external onlyAdmin {
        admins[addr] = false;
    }

    /**
     * Initializes the sub contracts so they're ready for use.
     * @notice IMPORTANT: This must be called before any other contract functions.
     *
     * @dev This can't be done in the constructor, because the contract doesn't have an address until the transaction is mined.
     */
    function initialize() external onlyAdmin {
        if (initialized) {
            return;
        }
        initialized = true;

        admins[address(this)] = true;
        brainz.setBitMonstersContract(this);
        metadata.setBitMonstersContract(this);
        mutator.setBitMonstersContract(this);
        minter.setBitMonstersContract(this);
    }

    /**
     * Returns the metadata of the Bit Monster corresponding to the given tokenId as a base64-encoded JSON object. Meant for use with OpenSea.
     *
     * @dev This function can take a painful amount of time to run, sometimes exceeding 9 minutes in length. Use getBitMonster() instead for frontends.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "the token doesn't exist");

        string memory metadataRaw = metadata.getMetadataJson(tokenId);
        string memory metadataB64 = Base64.encode(bytes(metadataRaw));

        return string(abi.encodePacked(
            "data:application/json;base64,",
            metadataB64
        ));
    }

    /**
     * Returns the internal representation of the Bit Monster corresponding to the given tokenId.
     */
    function getBitMonster(uint256 tokenId) external view override returns (BitMonster memory) {
        return tokenIdToBitMonster[tokenId];
    }

    function setBitMonster(uint256 tokenId, BitMonster memory bm) public override onlyAdmin {
        tokenIdToBitMonster[tokenId] = bm;
    }

    function createBitMonster(BitMonster memory bm, address owner) external override onlyAdmin {
        uint total = totalSupply();
        require(total <= SUPPLY_LIMIT, "Supply limit reached");

        uint tid = total + 1;
        _mint(owner, tid);
        setBitMonster(tid, bm);

        brainz.register(tid);
    }
}