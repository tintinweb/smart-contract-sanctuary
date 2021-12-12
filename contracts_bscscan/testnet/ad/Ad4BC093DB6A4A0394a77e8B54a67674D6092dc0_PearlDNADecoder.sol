// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "../../PearlNFT/IPearl.sol";

library Constants {
    function pearlShapeTypes() internal pure returns (string[6] memory) {
        return ["round", "drop", "button", "oval", "ringed", "baroque"];
    }

    function pearlBodyColorTypes() internal pure returns (string[12] memory) {
        return [
            "white",
            "black",
            "blue-green",
            "aubergine",
            "blue",
            "pink",
            "gold",
            "green",
            "brown",
            "silver",
            "grey",
            "cream"
        ];
    }

    function overtoneColorTypes() internal pure returns (string[12] memory) {
        return [
            "rainbow",
            "peacock",
            "blue-green",
            "aubergine",
            "red",
            "blue",
            "pink",
            "green",
            "gold",
            "rose",
            "silver",
            "cream"
        ];
    }

    // vals represent percentage basis points chance of occurrence of corresponding types
    function pearlShapeVals() internal pure returns (uint16[6] memory) {
        return [500, 800, 1200, 1500, 2500, 3500];
    }

    function pearlBodyColorVals() internal pure returns (uint16[12] memory) {
        return [100, 100, 200, 300, 500, 800, 800, 1000, 1200, 1500, 1500, 2000];
    }

    function overtoneColorVals() internal pure returns (uint16[12] memory) {
        return [10, 90, 200, 300, 500, 700, 1000, 1000, 1200, 1500, 1500, 2000];
    }

    function bodyColorMin() internal pure returns (uint256[3][12] memory) {
        return [
            [uint256(0), 0, 80],
            [uint256(0), 0, 3],
            [uint256(150), 40, 50],
            [uint256(270), 75, 20],
            [uint256(205), 70, 60],
            [uint256(300), 30, 80],
            [uint256(35), 70, 70],
            [uint256(90), 60, 60],
            [uint256(0), 80, 15],
            [uint256(0), 0, 55],
            [uint256(0), 0, 30],
            [uint256(40), 25, 80]
        ];
    }

    function bodyColorMax() internal pure returns (uint256[3][12] memory) {
        return [
            [uint256(0), 0, 100],
            [uint256(0), 0, 10],
            [uint256(170), 100, 90],
            [uint256(290), 100, 40],
            [uint256(240), 100, 100],
            [uint256(320), 90, 90],
            [uint256(45), 100, 95],
            [uint256(130), 90, 90],
            [uint256(20), 100, 40],
            [uint256(0), 0, 65],
            [uint256(0), 0, 50],
            [uint256(55), 45, 100]
        ];
    }

    function overtoneMin() internal pure returns (uint256[3][12] memory) {
        return [
            [uint256(0), 0, 80],
            [uint256(0), 0, 80],
            [uint256(150), 40, 50],
            [uint256(270), 75, 20],
            [uint256(0), 80, 80],
            [uint256(205), 70, 60],
            [uint256(300), 30, 80],
            [uint256(90), 60, 60],
            [uint256(35), 70, 70],
            [uint256(335), 40, 80],
            [uint256(0), 0, 55],
            [uint256(40), 25, 80]
        ];
    }

    function overtoneMax() internal pure returns (uint256[3][12] memory) {
        return [
            [uint256(0), 0, 100],
            [uint256(0), 0, 100],
            [uint256(170), 100, 90],
            [uint256(290), 100, 40],
            [uint256(5), 100, 100],
            [uint256(240), 100, 100],
            [uint256(320), 90, 90],
            [uint256(130), 90, 90],
            [uint256(45), 100, 95],
            [uint256(345), 60, 100],
            [uint256(0), 0, 65],
            [uint256(55), 45, 100]
        ];
    }
}

/**
 * @title PearlDNADecoder
 * @dev It interprets the traits from a pearl dna
 */
contract PearlDNADecoder is Initializable {
    using SafeMathUpgradeable for uint256;

    struct Traits {
        string shape;
        string color;
        string overtone;
        uint256 size;
        uint256 lustre;
        uint256 nacreQuality;
        uint256 surface;
        bool glow;
        string rarity;
        uint256 rarityValue;
        uint256[3][2] HSV;
    }

    IPearl public pearl;

    mapping(uint256 => Traits) public dnaToTraits;

    // global
    uint256[3][2] private HSV;
    uint256[] private rngDigits;
    uint256 private rarityValue;
    // rarity is increased as clam reaches end of lifespan
    uint256 private rarityIncreaser;

    event PearlDnaDecoded(uint256 timestamp, uint256 rng);

    function initialize(IPearl _pearl) public virtual initializer {
        pearl = _pearl;
        rarityValue = 1e12;
    }

    /**
     * @dev convenience function to get all dna traits.
     */
    function getDNADecoded(uint256 _rng) external view returns (Traits memory) {
        return (dnaToTraits[_rng]);
    }

    /**
     * @dev Increase the chance of occurrence of a value
     * @param val The value that needs to be increased
     * @param increaser Used to increase the value
     * @return Increased value
     */
    function increaseRarityOfVal(uint256 val, uint256 increaser) private pure returns (uint256) {
        if (increaser == 0) return val;

        uint256 portion = val.mul(increaser).div(100);
        /// @dev rarityIncreaser is either 0, 5, 10, 15, or 20
        /// @dev val < 100 means either 10 or 90 (overtoneColorVals)
        if (val < 100 && increaser % 2 != 0) portion = portion.add(1); // float values get rounded down, add 1 to compensate
        return val.add(portion);
    }

    /**
     * @dev Get pearl shape based on the input number and the arrays of vals and types.
     * @param _num 0-9999
     * @return result The shape (string)
     */
    function getPearlShape(uint256 _num, uint8[6] memory pearlShapeNumber) private returns (string memory result) {
        // pearlShapeNumber corresponds to the 'old' pearlShapeTypes array in clam dna decoder:
        // ["default", "ringed", "button", "drop", "round", "oval"];
        // But the new pearlShapeTypes array definition in Constants in this contract is:
        // ["round", "drop", "button", "oval", "ringed", "baroque"]
        // The index changes 'old' to 'new' are: 0 -> 5, 1 -> 4, 2 -> 2, 3 -> 1, 4 -> 0, 5 -> 3
        // and in reverse ('new' to 'old'): 0 -> 4, 1 -> 3, 2 -> 2, 3 -> 5, 4 -> 1, 5 -> 0
        uint8[6] memory oldPearlShapeNumberIndices = [4, 3, 2, 5, 1, 0];

        uint256 position;
        for (uint256 j; j < Constants.pearlShapeVals().length; j++) {
            uint256 dropRate = increaseRarityOfVal(
                increaseRarityOfVal(uint256(Constants.pearlShapeVals()[j]), rarityIncreaser),
                pearlShapeNumber[oldPearlShapeNumberIndices[j]]
            );
            uint256 upper = dropRate.add(position).sub(1);

            if (_num >= position && _num <= upper) {
                // INCREASE RARITY
                rarityValue = (rarityValue.mul(uint256(Constants.pearlShapeVals()[j]))).div(10000);

                result = Constants.pearlShapeTypes()[j];
                break;
            }
            position = upper.add(1);
        }
        return result;
    }

    function getTypeFromVals(
        uint256 _num,
        string[12] memory _types,
        uint16[12] memory _vals,
        uint256[3][12] memory min,
        uint256[3][12] memory max,
        uint8[10] memory boostValues
    ) private returns (string memory result, uint256[3] memory _HSV) {
        // old pearlBodyColorTypes array in clam dna decoder:
        // ["default", "blue", "green", "gold", "white", "black", "aubergine", "pink", "default", "brown"]
        // new array here (above, in Constants):
        // ["white", "black", "blue-green", "aubergine", "blue", "pink", "gold", "green", "brown", "silver", "grey", "cream"]
        // new colors which can not be boosted as per the old array: blue-green, silver, grey, cream
        // transpose old to new: 0 -> x, 1 -> 4, 2 -> 7, 3 -> 6, 4 -> 0, 5 -> 1, 6 -> 3, 7 -> 5, 8 -> x, 9 -> 8
        // new to old transpose: 0 -> 4, 1 -> 5, 2 -> x, 3 -> 6, 4 -> 1, 5 -> 7, 6 -> 3, 7 -> 2, 8 -> 9, 9 -> x, 10 -> x, 11 -> x
        // deliberately picking "default" (0) boost value for indices 2, 9, 10, 11
        uint8[12] memory oldBodyColorIndices = [4, 5, 0, 6, 1, 7, 3, 2, 9, 0, 0, 0];
        uint256 position;
        for (uint256 j; j < _vals.length; j++) {
            uint256 dropRate = increaseRarityOfVal(
                increaseRarityOfVal(uint256(_vals[j]), rarityIncreaser),
                boostValues[oldBodyColorIndices[j]]
            );
            uint256 upper = dropRate.add(position).sub(1);

            if (_num >= position && _num <= upper) {
                // INCREASE RARITY
                rarityValue = rarityValue.mul(uint256(_vals[j])).div(10000);

                result = _types[j];

                _HSV = setHSV(min[j], max[j]);
                break;
            }
            position = upper.add(1);
        }
        return (result, _HSV);
    }

    /**
     * @notice The rarity as a string based on the rarityValue. The lower the rarityValue, the rarer the Pearl
     */
    function getRarityInString() public view returns (string memory) {
        string memory value;
        if (rarityValue < uint256(18e6)) {
            value = "Legendary";
        } else if (rarityValue < uint256(80e6)) {
            value = "Epic";
        } else if (rarityValue < uint256(250e6)) {
            value = "Ultra Rare";
        } else if (rarityValue < uint256(700e6)) {
            value = "Rare";
        } else if (rarityValue < uint256(1600e6)) {
            value = "Uncommon";
        } else {
            value = "Common";
        }
        return value;
    }

    function getGlowValue(uint256 _num) private pure returns (bool glowValue) {
        if (_num == 999) {
            glowValue = true;
        } else {
            glowValue = false;
        }
    }

    function random(uint256 seed, uint256 mod) private view returns (uint256) {
        bytes32 bHash = blockhash(block.number - 1);
        uint256 randomNumber = uint256(uint256(keccak256(abi.encodePacked(block.timestamp, bHash, seed))) % mod);

        return randomNumber;
    }

    function setHSV(uint256[3] memory min, uint256[3] memory max) private view returns (uint256[3] memory) {
        uint256 H = min[0] + (random(2, (max[0] - min[0] + 1)));
        uint256 S = min[1] + (random(3, (max[1] - min[1] + 1)));
        uint256 V = min[2] + (random(5, (max[2] - min[2] + 1)));
        return [H, S, V];
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

    /// @dev helper functions for decodeTraitsFromDNA

    /**
     * @dev rarityIncreaser is percentage added to the vals to increase the chance of a rarer trait.
     * rarityIncreaser is calculated based on the lifespan of the mother clam.
     * As fewer pearls remain to give birth to, the chance for a rarer Pearl increases.
     * @param _pearlId The pearl id
     */
    function setRarityIncreaser(uint256 _pearlId) private {
        (, , uint256 pearlsRemaining, , , ) = pearl.pearlData(_pearlId);
        if (pearlsRemaining == 4) rarityIncreaser = 5;
        if (pearlsRemaining == 3) rarityIncreaser = 10;
        if (pearlsRemaining == 2) rarityIncreaser = 15;
        if (pearlsRemaining == 1) rarityIncreaser = 20;
    }

    function getNumForMainTraits(uint8[4] memory nums) private view returns (uint256) {
        return
            rngDigits[nums[0]].add((rngDigits[nums[1]]).mul(10)).add((rngDigits[nums[2]]).mul(100)).add(
                (rngDigits[nums[3]]).mul(1000)
            );
    }

    function setPearlShape(uint256 rng, uint8[6] memory pearlShapeNumber) private {
        uint256 num = getNumForMainTraits([0, 1, 2, 3]);
        dnaToTraits[rng].shape = getPearlShape(num, pearlShapeNumber);
    }

    function setColorAndOvertoneTraits(uint256 rng, uint8[10] memory pearlBodyColorNumber) private {
        // bodyColor
        uint256 num = getNumForMainTraits([4, 5, 6, 7]);
        (string memory bodyColor, uint256[3] memory hsvBodyColor) = getTypeFromVals(
            num,
            Constants.pearlBodyColorTypes(),
            Constants.pearlBodyColorVals(),
            Constants.bodyColorMin(),
            Constants.bodyColorMax(),
            pearlBodyColorNumber
        );
        dnaToTraits[rng].color = bodyColor;
        dnaToTraits[rng].HSV[0] = hsvBodyColor;

        // overtone
        num = getNumForMainTraits([8, 9, 10, 11]);
        (string memory overtone, uint256[3] memory hsvOvertone) = getTypeFromVals(
            num,
            Constants.overtoneColorTypes(),
            Constants.overtoneColorVals(),
            Constants.overtoneMin(),
            Constants.overtoneMax(),
            [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
        );

        dnaToTraits[rng].overtone = overtone;
        dnaToTraits[rng].HSV[1] = hsvOvertone;
    }

    function setRemainingTraits(uint256 rng) private {
        dnaToTraits[rng].size = rngDigits[12].add(rngDigits[13].mul(10)).add(1);
        dnaToTraits[rng].lustre = rngDigits[14].add(rngDigits[15].mul(10)).add(1);
        dnaToTraits[rng].nacreQuality = rngDigits[16].add(rngDigits[17].mul(10)).add(1);
        dnaToTraits[rng].surface = rngDigits[18].add(rngDigits[19].mul(10)).add(1);

        // GLOW TRAITS
        uint256 num = rngDigits[20].add(rngDigits[21].mul(10)).add(rngDigits[22].mul(100));

        dnaToTraits[rng].glow = getGlowValue(num);

        dnaToTraits[rng].rarity = getRarityInString();

        dnaToTraits[rng].rarityValue = rarityValue;
    }

    /**
     * @notice Calculate traits based on dna
     * @dev Decode traits and register this in mapping based on dna (rng)
     * @param rng the dna
     * @param pearlId Pearl id
     */
    function decodeTraitsFromDNA(
        uint256 rng,
        uint256 pearlId,
        uint8[10] memory pearlBodyColorNumber,
        uint8[6] memory pearlShapeNumber
    ) external {
        require(address(pearl) != address(0), "Pearl address not initialized");

        generateDigits(rng);

        setRarityIncreaser(pearlId);

        // Pearl SHAPE TRAIT
        setPearlShape(rng, pearlShapeNumber);

        // Color traits
        setColorAndOvertoneTraits(rng, pearlBodyColorNumber);

        setRemainingTraits(rng);

        emit PearlDnaDecoded(block.timestamp, rng);

        // reset global values
        delete rngDigits;
        delete HSV;
        delete rarityIncreaser;
        rarityValue = 1e12;
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

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721EnumerableUpgradeable.sol";

interface IPearl is IERC721EnumerableUpgradeable {
    /// @notice Info about pearl
    /// `birthTime` block timestamp of birth
    /// `dna` random generated number
    /// `pearlsRemaining` amount of pearls that mother clam had left when giving birth to this pearl. The lower the amount, the rarer the pearl should be
    struct PearlInfo {
        uint256 birthTime;
        uint256 dna;
        uint256 pearlsRemaining;
        uint256 gemBoost;
        uint256 pearlPrice; // pearl price at the time of mint
        uint256 clamId; // id of 'mother' clam
    }

    function pearlData(uint256)
        external
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        );

    function mint(
        address to,
        uint256 dna,
        uint256 pearlPrice,
        uint256 pearlsRemaining,
        uint256 pearlBoostM,
        uint256 clamId,
        uint8[10] memory pearlBodyColorNumber,
        uint8[6] memory pearlShapeNumber
    ) external;

    function burn(uint256) external;

    function nextPearlId() external view returns (uint256);

    function calculateBonusRewards(
        uint256 pearlPrice,
        uint256 size,
        uint256 lustre,
        uint256 nacreQuality,
        uint256 surface,
        uint256 rarityValue
    ) external pure returns (uint256);

    function legacyCalculateBonusRewards(
        uint256 baseGemRewards,
        uint256 size,
        uint256 lustre,
        uint256 nacreQuality,
        uint256 surface,
        uint256 rarityValue
    ) external pure returns (uint256);
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "./IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721EnumerableUpgradeable is IERC721Upgradeable {

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "../../introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
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