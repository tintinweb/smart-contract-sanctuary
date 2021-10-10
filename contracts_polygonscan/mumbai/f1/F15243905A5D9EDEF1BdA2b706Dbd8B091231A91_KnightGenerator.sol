// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

// SPDX-License-Identifier: MIT

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

//SPDX-License-Identifier: None
pragma solidity ^0.8.5;

interface IKnight {

    enum Gender {M, F}
    enum Race {Human, Dwarf, Orc, Ogre, Elf, Halfling, Undead, Gnome}

    struct Attributes {
        uint8 strength;
        uint8 vitality;
        uint8 size;
        uint8 stamina;
        uint8 dexterity;
        uint8 intelligence;
        uint8 luck;
    }

    struct Record {
        uint32 wins;
        uint32 losses;
        uint16 kills;
        uint16 tournamentWins;
    }

    struct SKnight {
        string name;
        Gender gender;
        Race race;
        Attributes attributes;
        uint16 portraitId;
        Record record;
        bool isDead;
        bool isMinting;
    }

    function addPortraitData(IKnight.Gender gender, IKnight.Race race, string[] calldata data) external;
    function getPortraitCid(IKnight.Gender gender, IKnight.Race race, uint16 portraitId) external view returns (string memory);
    function updateTokenURI(uint tokenId,string calldata tokenUri) external;

}

//SPDX-License-Identifier: None
pragma solidity ^0.8.5;

import "./IKnight.sol";

interface IKnightGenerator {

    function randomKnightInit(uint seed) external returns (
        string memory,
        IKnight.Gender,
        IKnight.Race,
        uint16
    );
    function randomKnightAttributes(
        uint seed,
        IKnight.Race race
    ) external returns (IKnight.Attributes memory);
    function addNameData(IKnight.Gender gender, IKnight.Race race, string[] calldata data) external;
    function removeNameData(IKnight.Gender gender, IKnight.Race race, string calldata data) external;
    function addTitleData(IKnight.Race race, string[] calldata data) external;
    function removeTitleData(IKnight.Race race, string calldata data) external;
    function addActivePortraitIndex(IKnight.Gender gender, IKnight.Race race, uint16[] memory data) external;
    function removeActivePortraitIndex(IKnight.Gender gender, IKnight.Race race, uint16 data) external;
    function getNamesCount(IKnight.Gender gender, IKnight.Race race) external view returns (uint);
    function getTitlesCount(IKnight.Race race) external view returns (uint);
    function getActivePortraitsCount(IKnight.Gender gender, IKnight.Race race) external view returns (uint);

}

//SPDX-License-Identifier: None
pragma solidity ^0.8.5;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./IKnightGenerator.sol";
import "./lib/UniformRandomNumber.sol";
import "./IKnight.sol";
import "./lib/Dice.sol";

contract KnightGenerator is Ownable, IKnightGenerator {
    address private knightContractAddress;
    // Store mapping of how many times names have been used
    mapping(bytes32 => uint8) private usedKnightNames;
    // Store Name Data
    mapping(IKnight.Race => string[]) private maleNames;
    mapping(IKnight.Race => string[]) private femaleNames;
    // Store Titles Data
    mapping(IKnight.Race => string[]) private titles;
    // Store Active Portraits ids
    mapping(IKnight.Race => uint16[]) private malePortraitsActive;
    mapping(IKnight.Race => uint16[]) private femalePortraitsActive;

    constructor(address _knightContractAddress) {
        knightContractAddress = _knightContractAddress;
    }

    function randomKnightInit(
        uint seed
    ) external override returns (string memory, IKnight.Gender, IKnight.Race, uint16) {
        require(msg.sender == knightContractAddress, "Only calls from knightContract allowed!");
        IKnight.Race race = _getRandomKnightRace(uint(keccak256(abi.encode(seed, 1))));
        IKnight.Gender gender = _getRandomKnightGender(race, uint(keccak256(abi.encode(seed, 2))));
        string memory name = _getRandomKnightName(
            gender,
            race,
            uint(keccak256(abi.encode(seed, 3)))
        );
        uint16 portraitId = _getRandomPortraitId(gender, race, uint(keccak256(abi.encode(seed, 4))));
        return (name, gender, race, portraitId);
    }

    function randomKnightAttributes(
        uint seed,
        IKnight.Race race
    ) external override returns (IKnight.Attributes memory) {
        require(msg.sender == knightContractAddress, "Only calls from knightContract allowed!");
        uint8[7] memory attributes;
        uint sum;
        for (uint i = 1;i <= 6;i++) {
            if (i == 1 || ((sum / i > 10) && (sum / i < 13))) {
                attributes[i - 1] = uint8(Dice.rollDiceSet(3, 6, uint(keccak256(abi.encode(seed, i)))));
            } else {
                Dice.DiceBiasDirections diceBiasDirection = (sum / i < 10)
                ? Dice.DiceBiasDirections.Up
                : Dice.DiceBiasDirections.Down;
                attributes[i - 1] = uint8(
                    Dice.rollDiceSetBiased(
                        3,
                        5,
                        6,
                        uint(keccak256(abi.encode(seed, i))),
                        diceBiasDirection
                    )
                );
            }
            sum += attributes[i - 1];
        }
        if (sum >= 82 || sum <= 65) {
            // Not possible to hit 84
            return IKnight.Attributes(0, 0, 0, 0, 0, 0, 0);
        } else {
            attributes[6] = uint8(84 - sum);
            _shuffleAttributes(attributes, uint(keccak256(abi.encode(seed, attributes[0], attributes[6]))));
            _sortAttributes(attributes, race);
            return IKnight.Attributes(
                attributes[0],
                attributes[1],
                attributes[2],
                attributes[3],
                attributes[4],
                attributes[5],
                attributes[6]
            );
        }
    }

    function addNameData(
        IKnight.Gender gender,
        IKnight.Race race,
        string[] calldata data
    ) external override onlyOwner {
        if (gender == IKnight.Gender.F) {
            for (uint i = 0;i < data.length;i++) {
                femaleNames[race].push(data[i]);
            }
        } else {
            for (uint i = 0;i < data.length;i++) {
                maleNames[race].push(data[i]);
            }
        }
    }

    function removeNameData(
        IKnight.Gender gender,
        IKnight.Race race,
        string calldata data
    ) external override onlyOwner {
        // Expensive do not use unless necessary
        if (gender == IKnight.Gender.F) {
            for (uint i = 0;i < femaleNames[race].length;i++) {
                if (keccak256(abi.encodePacked(femaleNames[race][i])) == keccak256(abi.encodePacked(data))) {
                    femaleNames[race][i] = femaleNames[race][femaleNames[race].length - 1];
                    femaleNames[race].pop();
                    break;
                }
            }
        } else {
            for (uint i = 0;i < maleNames[race].length;i++) {
                if (keccak256(abi.encodePacked(maleNames[race][i])) == keccak256(abi.encodePacked(data))) {
                    maleNames[race][i] = maleNames[race][maleNames[race].length - 1];
                    maleNames[race].pop();
                    break;
                }
            }
        }
    }

    function addTitleData(
        IKnight.Race race,
        string[] calldata data
    ) external override onlyOwner {
        for (uint i = 0;i < data.length;i++) {
            titles[race].push(data[i]);
        }
    }

    function removeTitleData(
        IKnight.Race race,
        string calldata data
    ) external override onlyOwner {
        for (uint i = 0;i < titles[race].length;i++) {
            if (keccak256(abi.encodePacked(titles[race][i])) == keccak256(abi.encodePacked(data))) {
                titles[race][i] = titles[race][titles[race].length - 1];
                titles[race].pop();
                break;
            }
        }
    }

    function addActivePortraitIndex(
        IKnight.Gender gender,
        IKnight.Race race,
        uint16[] memory data
    ) public override {
        require(msg.sender == knightContractAddress || msg.sender == owner(), "Not authorized");
        if (gender == IKnight.Gender.F) {
            for (uint i = 0;i < data.length;i++) {
                femalePortraitsActive[race].push(data[i]);
            }
        } else {
            for (uint i = 0;i < data.length;i++) {
                malePortraitsActive[race].push(data[i]);
            }
        }
    }

    function removeActivePortraitIndex(
        IKnight.Gender gender,
        IKnight.Race race,
        uint16 data
    ) external override onlyOwner {
        // Expensive do not use unless necessary
        if (gender == IKnight.Gender.F) {
            for (uint16 i = 0;i < femalePortraitsActive[race].length;i++) {
                if (femalePortraitsActive[race][i] == data) {
                    femalePortraitsActive[race][i] = femalePortraitsActive[race][femalePortraitsActive[race].length - 1];
                    femalePortraitsActive[race].pop();
                    break;
                }
            }
        } else {
            for (uint16 i = 0;i < malePortraitsActive[race].length;i++) {
                if (malePortraitsActive[race][i] == data) {
                    malePortraitsActive[race][i] = malePortraitsActive[race][malePortraitsActive[race].length - 1];
                    malePortraitsActive[race].pop();
                    break;
                }
            }
        }
    }

    function getNamesCount(IKnight.Gender gender, IKnight.Race race) public view override returns (uint) {
        if (gender == IKnight.Gender.F) {
            return femaleNames[race].length;
        } else {
            return maleNames[race].length;
        }
    }

    function getTitlesCount(IKnight.Race race) public view override returns (uint) {
        return titles[race].length;
    }

    function getActivePortraitsCount(IKnight.Gender gender, IKnight.Race race) public view override returns (uint) {
        if (gender == IKnight.Gender.F) {
            return femalePortraitsActive[race].length;
        } else {
            return malePortraitsActive[race].length;
        }
    }

    function _getRandomKnightName(
        IKnight.Gender gender,
        IKnight.Race race,
        uint seed
    ) private returns (string memory) {
        uint8 attempts;
        uint8 nameIndex;
        string memory uniqueRandomName;
        while (attempts < 4) {
            attempts++;
            uniqueRandomName = _getRandomName(
                gender,
                race,
                uint(keccak256(abi.encode(seed, attempts)))
            );
            nameIndex = usedKnightNames[keccak256(abi.encodePacked(uniqueRandomName))];
            if (nameIndex == 0) {
                usedKnightNames[keccak256(abi.encodePacked(uniqueRandomName))]++;
                return uniqueRandomName;
            }
        }
        // Failed to find a unique name in 4 attempts - use this name + a roman numeral suffix
        if (nameIndex == 254) {
            // Reset back to 0
            delete usedKnightNames[keccak256(abi.encodePacked(uniqueRandomName))];
        } else {
            usedKnightNames[keccak256(abi.encodePacked(uniqueRandomName))]++;
        }
        return string(abi.encodePacked(
                uniqueRandomName,
                " ",
                _convertIntToRomanNumeral(++nameIndex)
            )
        );
    }

    function _getRandomName(
        IKnight.Gender gender,
        IKnight.Race race,
        uint seed
    ) private view returns (string memory) {
        uint nameLength = getNamesCount(gender, race);
        uint selectedNameIndex = UniformRandomNumber.uniform(seed, nameLength);
        uint selectedTitleIndex = UniformRandomNumber.uniform(
            uint(keccak256(abi.encode(seed, 1))),
            titles[race].length
        );
        if (gender == IKnight.Gender.F) {
            return string(abi.encodePacked(femaleNames[race][selectedNameIndex], " ", titles[race][selectedTitleIndex]));
        } else {
            return string(abi.encodePacked(maleNames[race][selectedNameIndex], " ", titles[race][selectedTitleIndex]));
        }
    }

    function _convertIntToRomanNumeral(uint8 number) private pure returns (string memory) {
        string[10] memory c = ["",  "C",  "CC",  "CCC",  "CD", "D", "DC", "DCC", "DCCC", "CM"];
        string[10] memory x = ["",  "X",  "XX",  "XXX",  "XL", "L", "LX", "LXX", "LXXX", "XC"];
        string[10] memory i = ["",  "I",  "II",  "III",  "IV", "V", "VI", "VII", "VIII", "IX"];
        string memory cc = c[(number % 1000) / 100];
        string memory xx = x[(number % 100) / 10];
        string memory ii = i[number % 10];
        return string(abi.encodePacked(cc, xx, ii));
    }

    function _getRandomKnightRace(uint seed) private pure returns (IKnight.Race) {
        uint raceRandomInt = UniformRandomNumber.uniform(seed, 100) + 1;
        if (raceRandomInt >= 71 && raceRandomInt <= 80) {
            return IKnight.Race.Dwarf;
        } else if (raceRandomInt >= 81 && raceRandomInt <= 88) {
            return IKnight.Race.Orc;
        } else if (raceRandomInt >= 89 && raceRandomInt <= 92) {
            return IKnight.Race.Ogre;
        } else if (raceRandomInt >= 93 && raceRandomInt <= 95) {
            return IKnight.Race.Elf;
        } else if (raceRandomInt >= 96 && raceRandomInt <= 97) {
            return IKnight.Race.Halfling;
        } else if (raceRandomInt == 98) {
            return IKnight.Race.Undead;
        } else if (raceRandomInt >= 99 && raceRandomInt <= 100) {
            return IKnight.Race.Gnome;
        }
        return IKnight.Race.Human;
    }

    function _getRandomKnightGender(IKnight.Race race, uint seed) private pure returns (IKnight.Gender) {
        if (race == IKnight.Race.Undead || race == IKnight.Race.Ogre) {
            return IKnight.Gender.M;
        }
        uint genderRandomInt = UniformRandomNumber.uniform(seed, 10);
        return genderRandomInt >= 8 ? IKnight.Gender.F : IKnight.Gender.M;
    }

    function _shuffleAttributes(uint8[7] memory attributes, uint seed) private pure {
        for (uint i = 0; i < 7; i++) {
            uint n = UniformRandomNumber.uniform(
                uint(keccak256(abi.encode(seed, i))),
                7
            );
            uint8 temp = attributes[n];
            attributes[n] = attributes[i];
            attributes[i] = temp;
        }
    }

    function _sortAttributes(uint8[7] memory attributes, IKnight.Race race) private pure  {
        if (race != IKnight.Race.Human) {
            uint8 maxAttributeVal;
            uint maxAttributeIndex;
            uint8 minAttributeVal;
            uint minAttributeIndex;
            uint bonusAttributeIndex;
            uint penaltyAttributeIndex;
            // Define bonusAttributeIndex/penaltyAttributeIndex based on race
            if (race == IKnight.Race.Orc) {
                // Strength
                bonusAttributeIndex = 0;
                // Intelligence
                penaltyAttributeIndex = 5;
            } else if (race == IKnight.Race.Dwarf) {
                // Vitality
                bonusAttributeIndex = 1;
                // Size
                penaltyAttributeIndex = 2;
            } else if (race == IKnight.Race.Ogre) {
                // Size
                bonusAttributeIndex = 2;
                // Dexterity
                penaltyAttributeIndex = 4;
            } else if (race == IKnight.Race.Undead) {
                // Stamina
                bonusAttributeIndex = 3;
                // Luck
                penaltyAttributeIndex = 6;
            } else if (race == IKnight.Race.Elf) {
                // Dexterity
                bonusAttributeIndex = 4;
                // Strength
                penaltyAttributeIndex = 0;
            } else if (race == IKnight.Race.Gnome) {
                // Intelligence
                bonusAttributeIndex = 5;
                // Size
                penaltyAttributeIndex = 2;
            } else if (race == IKnight.Race.Halfling) {
                // Luck
                bonusAttributeIndex = 6;
                // Size
                penaltyAttributeIndex = 2;
            }
            // Find max attribute index + value
            for (uint i = 0;i < 7;i++) {
                if (attributes[i] >= maxAttributeVal) {
                    maxAttributeVal = attributes[i];
                    maxAttributeIndex = i;
                }
            }
            // Switch maxAttributeIndex and bonusAttributeIndex values if bonusAttribute value is not already max
            if (bonusAttributeIndex != maxAttributeIndex) {
                attributes[maxAttributeIndex] = attributes[bonusAttributeIndex];
                attributes[bonusAttributeIndex] = maxAttributeVal;
            }
            // Need to determine min attribute position AFTER we switch max
            // Find min attribute index + value
            for (uint i = 0;i < 7;i++) {
                if (attributes[i] <= minAttributeVal || minAttributeVal == 0) {
                    minAttributeVal = attributes[i];
                    minAttributeIndex = i;
                }
            }
            // Switch minAttributeIndex and penaltyAttributeIndex values if penaltyAttribute value is not already min
            if (penaltyAttributeIndex != minAttributeIndex) {
                attributes[minAttributeIndex] = attributes[penaltyAttributeIndex];
                attributes[penaltyAttributeIndex] = minAttributeVal;
            }
        }
    }

    function _getRandomPortraitId(IKnight.Gender gender, IKnight.Race race, uint seed) private view returns (uint16) {
        uint totalActivePortraits = getActivePortraitsCount(gender, race);
        if (totalActivePortraits == 0) {
            revert("No active portraits");
        } else if (totalActivePortraits == 1) {
            return uint16(0);
        }
        return uint16(UniformRandomNumber.uniform(seed, totalActivePortraits));
    }

    function destroy() external onlyOwner {
        selfdestruct(payable(msg.sender));
    }

}

//SPDX-License-Identifier: None
pragma solidity ^0.8.5;

import "./UniformRandomNumber.sol";

library Dice {
    enum DiceBiasDirections { Up, Down }

    function rollDiceSet(uint8 resultSetSize, uint upperLimit, uint seed) internal pure returns (uint) {
        uint sum;
        for (uint i = 0;i < resultSetSize;i++) {
            sum += UniformRandomNumber.uniform(
                uint(keccak256(abi.encode(seed, i))),
                upperLimit
            ) + 1;
        }
        return sum;
    }

    function rollDiceSetBiased(
        uint8 resultSetSize,
        uint8 totalSetSize,
        uint upperLimit,
        uint seed,
        DiceBiasDirections biasDirection
    ) internal pure returns (uint) {
        require(totalSetSize > resultSetSize, "Not biased");
        uint[] memory allResults = new uint[](totalSetSize);
        uint biasedSetSum;
        uint setCounter;
        for (uint i = 1;i <= totalSetSize;i++) {
            allResults[i - 1] = UniformRandomNumber.uniform(uint(keccak256(abi.encode(seed, i))), upperLimit) + 1;
        }
        // Sort allResults
        sortArray(allResults);
        if (biasDirection == DiceBiasDirections.Up) {
            for (uint c = allResults.length - 1;c >= 0;c--) {
                biasedSetSum += allResults[c];
                setCounter++;
                if (setCounter == resultSetSize) {
                    break;
                }
            }
        } else {
            for (uint c = 0;c <= allResults.length;c++) {
                biasedSetSum += allResults[c];
                setCounter++;
                if (setCounter == resultSetSize) {
                    break;
                }
            }
        }
        return biasedSetSum;
    }

    function sortArray(uint[] memory arr) internal pure {
        uint l = arr.length;
        for(uint i = 0; i < l; i++) {
            for(uint j = i+1; j < l ;j++) {
                if(arr[i] > arr[j]) {
                    uint temp = arr[i];
                    arr[i] = arr[j];
                    arr[j] = temp;
                }
            }
        }
    }

}

/**
Copyright 2019 PoolTogether LLC

This file is part of PoolTogether.

PoolTogether is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation under version 3 of the License.

PoolTogether is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with PoolTogether.  If not, see <https://www.gnu.org/licenses/>.
*/
//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.5;

/**
 * @author Brendan Asselstine
 * @notice A library that uses entropy to select a random number within a bound.  Compensates for modulo bias.
 * @dev Thanks to https://medium.com/hownetworks/dont-waste-cycles-with-modulo-bias-35b6fdafcf94
 * @dev Modified https://github.com/pooltogether/uniform-random-number/blob/master/contracts/UniformRandomNumber.sol
 * @dev to work with solidity > 0.8.0 by coercing underflow: uint(-int(_upperBound))
 */
library UniformRandomNumber {
    /// @notice Select a random number without modulo bias using a random seed and upper bound
    /// @param _entropy The seed for randomness
    /// @param _upperBound The upper bound of the desired number
    /// @return A random number less than the _upperBound
    function uniform(uint256 _entropy, uint256 _upperBound) internal pure returns (uint256) {
        require(_upperBound > 0, "UniformRand/min-bound");
        uint256 min = uint(-int(_upperBound)) % _upperBound;
        uint256 random = _entropy;
        while (true) {
            if (random >= min) {
                break;
            }
            random = uint256(keccak256(abi.encodePacked(random)));
        }
        return random % _upperBound;
    }
}