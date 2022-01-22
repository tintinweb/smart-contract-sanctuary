// SPDX-License-Identifier: GPL-3.0

/// @title The WizardsToken pseudo-random seed generator.
// Modified version from NounsDAO.

pragma solidity ^0.8.6;

import {ISeeder} from "./ISeeder.sol";
import {IDescriptor} from "../descriptor/IDescriptor.sol";

contract Seeder is ISeeder {
    struct Counts {
        uint256 backgroundCount;
        uint256 skinsCount;
        uint256 mouthsCount;
        uint256 eyesCount;
        uint256 hatsCount;
        uint256 clothesCount;
        uint256 accessoryCount;
        uint256 bgItemCount;
    }

    /**
     * @notice Generate a pseudo-random Wizard seed using the previous blockhash and wizard ID.
     */
    function generateSeed(
        uint256 wizardId,
        IDescriptor descriptor,
        bool isOneOfOne,
        uint48 oneOfOneIndex
    ) external view override returns (Seed memory) {
        if (isOneOfOne) {
            return
                Seed({
                    background: 0,
                    skin: 0,
                    bgItem: 0,
                    accessory: 0,
                    clothes: 0,
                    mouth: 0,
                    eyes: 0,
                    hat: 0,
                    oneOfOne: isOneOfOne,
                    oneOfOneIndex: oneOfOneIndex
                });
        }

        uint256 pseudorandomness = getRandomness(wizardId);
        Counts memory counts = getCounts(descriptor);
        uint256 accShift = getAccShift(wizardId);
        uint256 clothShift = getClothShift(wizardId);

        return
            Seed({
                background: uint48(
                    uint48(pseudorandomness) % counts.backgroundCount
                ),
                skin: uint48(
                    uint48(pseudorandomness >> 48) % counts.skinsCount
                ),
                accessory: uint48(
                    uint48(pseudorandomness >> accShift) % counts.accessoryCount
                ),
                mouth: uint48(
                    uint48(pseudorandomness >> 144) % counts.mouthsCount
                ),
                eyes: uint48(
                    uint48(pseudorandomness >> 192) % counts.eyesCount
                ),
                hat: uint48(uint48(pseudorandomness >> 144) % counts.hatsCount),
                bgItem: uint48(
                    uint48(pseudorandomness >> accShift) % counts.bgItemCount
                ),
                clothes: uint48(
                    uint48(pseudorandomness >> clothShift) % counts.clothesCount
                ),
                oneOfOne: isOneOfOne,
                oneOfOneIndex: oneOfOneIndex
            });
    }

    function getCounts(IDescriptor descriptor)
        internal
        view
        returns (Counts memory)
    {
        return
            Counts({
                backgroundCount: descriptor.backgroundCount(),
                skinsCount: descriptor.skinsCount(),
                mouthsCount: descriptor.mouthsCount(),
                eyesCount: descriptor.eyesCount(),
                hatsCount: descriptor.hatsCount(),
                clothesCount: descriptor.clothesCount(),
                accessoryCount: descriptor.accessoryCount(),
                bgItemCount: descriptor.bgItemsCount()
            });
    }

    function getRandomness(uint256 wizardId) internal view returns (uint256) {
        uint256 pseudorandomness = uint256(
            keccak256(
                abi.encodePacked(
                    blockhash(block.number - 1),
                    wizardId,
                    block.difficulty,
                    block.coinbase
                )
            )
        );

        return pseudorandomness;
    }

    function getAccShift(uint256 wizardId) internal pure returns (uint256) {
        uint256 rem = wizardId % 2;
        uint256 shift = (rem == 0) ? 96 : 192;

        return shift;
    }

    function getClothShift(uint256 wizardId) internal pure returns (uint256) {
        uint256 rem = wizardId % 2;
        uint256 clothShift = (rem == 0) ? 48 : 144;

        return clothShift;
    }
}

// SPDX-License-Identifier: GPL-3.0

/// @title Interface for Seeder

pragma solidity ^0.8.6;

import { IDescriptor } from '../descriptor/IDescriptor.sol';

// "Skin", "Cloth", "Eye", "Mouth", "Acc", "Item", "Hat"
interface ISeeder {
    struct Seed {
        uint48 background;
        uint48 skin;
        uint48 clothes;
        uint48 eyes;
        uint48 mouth;
        uint48 accessory;
        uint48 bgItem;
        uint48 hat;
        bool oneOfOne;
        uint48 oneOfOneIndex;
    }

    function generateSeed(uint256 wizardId, IDescriptor descriptor, bool isOneOfOne, uint48 isOneOfOneIndex) external view returns (Seed memory);
}

// SPDX-License-Identifier: GPL-3.0

/// @title Interface for Descriptor

pragma solidity ^0.8.6;

import { ISeeder } from '../seeder/ISeeder.sol';

interface IDescriptor {
    event PartsLocked();

    event DataURIToggled(bool enabled);

    event BaseURIUpdated(string baseURI);

    function arePartsLocked() external returns (bool);

    function isDataURIEnabled() external returns (bool);    

    function baseURI() external returns (string memory);

    function palettes(uint8 paletteIndex, uint256 colorIndex) external view returns (string memory);

    function addManyColorsToPalette(uint8 paletteIndex, string[] calldata newColors) external;

    function addColorToPalette(uint8 paletteIndex, string calldata color) external;


    function backgrounds(uint256 index) external view returns (string memory);    

    function backgroundCount() external view returns (uint256);

    function addManyBackgrounds(string[] calldata backgrounds) external;

    function addBackground(string calldata background) external;    

    
    
    function oneOfOnes(uint256 index) external view returns (bytes memory);

    function oneOfOnesCount() external view returns (uint256);

    function addOneOfOne(bytes calldata _oneOfOne) external;

    function addManyOneOfOnes(bytes[] calldata _oneOfOnes) external;    


    function skins(uint256 index) external view returns (bytes memory);

    function skinsCount() external view returns (uint256);

    function addManySkins(bytes[] calldata skins) external;

    function addSkin(bytes calldata skin) external;


    function hats(uint256 index) external view returns (bytes memory);

    function hatsCount() external view returns (uint256);

    function addManyHats(bytes[] calldata hats) external;

    function addHat(bytes calldata hat) external;

    
    function clothes(uint256 index) external view returns (bytes memory);

    function clothesCount() external view returns (uint256);

    function addManyClothes(bytes[] calldata ears) external;

    function addClothes(bytes calldata ear) external;


    function mouths(uint256 index) external view returns (bytes memory);

    function mouthsCount() external view returns (uint256);

    function addManyMouths(bytes[] calldata mouths) external;

    function addMouth(bytes calldata mouth) external;

    
    function eyes(uint256 index) external view returns (bytes memory);

    function eyesCount() external view returns (uint256);

    function addManyEyes(bytes[] calldata eyes) external;

    function addEyes(bytes calldata eye) external;


    function accessory(uint256 index) external view returns (bytes memory);

    function accessoryCount() external view returns (uint256);

    function addManyAccessories(bytes[] calldata noses) external;

    function addAccessory(bytes calldata nose) external;


    function bgItems(uint256 index) external view returns (bytes memory);

    function bgItemsCount() external view returns (uint256);

    function addManyBgItems(bytes[] calldata noses) external;

    function addBgItem(bytes calldata nose) external;


    function lockParts() external;

    function toggleDataURIEnabled() external;

    function setBaseURI(string calldata baseURI) external;

    function tokenURI(uint256 tokenId, ISeeder.Seed memory seed) external view returns (string memory);

    function dataURI(uint256 tokenId, ISeeder.Seed memory seed) external view returns (string memory);

    function genericDataURI(
        string calldata name,
        string calldata description,
        ISeeder.Seed memory seed
    ) external view returns (string memory);

    function generateSVGImage(ISeeder.Seed memory seed) external view returns (string memory);
}