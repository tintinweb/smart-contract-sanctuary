// SPDX-License-Identifier: GPL-3.0

/// @title The BitstraysToken pseudo-random seed generator

/***********************************************************
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@%[email protected]@@@@@@@@@@@@
[email protected]@@@@@@..............................
./@@@@@@@@@[email protected]@@....*@@@@.......*@@@@@@@@@.
./@@@@@@@[email protected]@@@@[email protected]@@[email protected]@@@@[email protected]@@@@.
@%[email protected]@[email protected]@[email protected]@@[email protected]
@%**.........,**.........................................**@
@@@@##.....##(**#######   .........  ,#######  .......###@@@
@@@@@@[email protected]@@@#  @@   @@   .........  ,@@  @@@  [email protected]@@@@@
@@@@@@[email protected]@#  @@@@@@@   .........  ,@@@@@@@  [email protected]@@@@@
@@@@@@[email protected]@@@@       @@%............       [email protected]@@@@@
@@@@@@@@@..../@@@@@@@@@[email protected]@@@@@@@
@@@@@@@@@............                   [email protected]@@@@@@@
@@@@@@@@@@@..........  @@@@@@@@@@@@@@%  .........*@@@@@@@@@@
@@@@@@@@@@@@@%....   @@//////////////#@@  [email protected]@@@@@@@@@@@@
@@@@@@@@@@@@@@@@  @@@///////////////////@@   @@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@  ************************   @@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@                             @@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
************************************************************/

pragma solidity ^0.8.6;

import { IBitstraysSeeder } from './interfaces/IBitstraysSeeder.sol';
import { IBitstraysDescriptor } from './interfaces/IBitstraysDescriptor.sol';

contract BitstraysSeeder is IBitstraysSeeder {
    /**
     * @notice Generate a pseudo-random Bitstray seed using the previous blockhash and bitstray ID.
     */
    // prettier-ignore
    function generateSeed(uint256 bitstrayId, IBitstraysDescriptor descriptor) external view override returns (Seed memory) {
        uint256 pseudorandomness = uint256(
            keccak256(abi.encodePacked(blockhash(block.number - 1), bitstrayId))
        );

        uint256 backgroundCount = descriptor.backgroundCount();
        uint256 armsCount = descriptor.armsCount();
        uint256 shirtsCount = descriptor.shirtsCount();
        uint256 motivesCount = descriptor.motivesCount();
        uint256 headCount = descriptor.headCount();
        uint256 eyesCount = descriptor.eyesCount();
        uint256 mouthsCount = descriptor.mouthsCount();

        uint256 kings = 10; //number of king hads
        uint256 beanies = 26; //number of special heads

        uint48 rarity = uint48(uint48(pseudorandomness) % 100);

        if (rarity < 75) { //normal
            headCount = headCount-beanies-kings;
        } else if ( rarity > 75 && rarity < 90 ) {
            headCount = headCount-kings; //add special head
        }

        return Seed({
            background: uint48(
                uint48(pseudorandomness) % backgroundCount
            ),
            arms: uint48(
                uint48(pseudorandomness >> 240) % armsCount
            ),
            shirt: uint48(
                uint48(pseudorandomness >> 24) % shirtsCount
            ),
            motive: uint48(
                uint48(pseudorandomness >> 48) % motivesCount
            ),
            head: uint48(
                uint48(pseudorandomness >> 96) % headCount
            ),
            eyes: uint48(
                uint48(pseudorandomness >> 144) % eyesCount
            ),
            mouth: uint48(
                uint48(pseudorandomness >> 192) % mouthsCount
            )
        });
    }
}

// SPDX-License-Identifier: GPL-3.0

/// @title Interface for BitstraysSeeder

/***********************************************************
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@%[email protected]@@@@@@@@@@@@
[email protected]@@@@@@..............................
./@@@@@@@@@[email protected]@@....*@@@@.......*@@@@@@@@@.
./@@@@@@@[email protected]@@@@[email protected]@@[email protected]@@@@[email protected]@@@@.
@%[email protected]@[email protected]@[email protected]@@[email protected]
@%**.........,**.........................................**@
@@@@##.....##(**#######   .........  ,#######  .......###@@@
@@@@@@[email protected]@@@#  @@   @@   .........  ,@@  @@@  [email protected]@@@@@
@@@@@@[email protected]@#  @@@@@@@   .........  ,@@@@@@@  [email protected]@@@@@
@@@@@@[email protected]@@@@       @@%............       [email protected]@@@@@
@@@@@@@@@..../@@@@@@@@@[email protected]@@@@@@@
@@@@@@@@@............                   [email protected]@@@@@@@
@@@@@@@@@@@..........  @@@@@@@@@@@@@@%  .........*@@@@@@@@@@
@@@@@@@@@@@@@%....   @@//////////////#@@  [email protected]@@@@@@@@@@@@
@@@@@@@@@@@@@@@@  @@@///////////////////@@   @@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@  ************************   @@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@                             @@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
************************************************************/

pragma solidity ^0.8.6;

import { IBitstraysDescriptor } from './IBitstraysDescriptor.sol';

interface IBitstraysSeeder {
    struct Seed {
        uint48 background;
        uint48 arms;
        uint48 shirt;
        uint48 motive;
        uint48 head;
        uint48 eyes;
        uint48 mouth;
    }

    function generateSeed(uint256 bitstrayId, IBitstraysDescriptor descriptor) external view returns (Seed memory);
}

// SPDX-License-Identifier: GPL-3.0

/// @title Interface for BitstraysDescriptor

/***********************************************************
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@%[email protected]@@@@@@@@@@@@
[email protected]@@@@@@..............................
./@@@@@@@@@[email protected]@@....*@@@@.......*@@@@@@@@@.
./@@@@@@@[email protected]@@@@[email protected]@@[email protected]@@@@[email protected]@@@@.
@%[email protected]@[email protected]@[email protected]@@[email protected]
@%**.........,**.........................................**@
@@@@##.....##(**#######   .........  ,#######  .......###@@@
@@@@@@[email protected]@@@#  @@   @@   .........  ,@@  @@@  [email protected]@@@@@
@@@@@@[email protected]@#  @@@@@@@   .........  ,@@@@@@@  [email protected]@@@@@
@@@@@@[email protected]@@@@       @@%............       [email protected]@@@@@
@@@@@@@@@..../@@@@@@@@@[email protected]@@@@@@@
@@@@@@@@@............                   [email protected]@@@@@@@
@@@@@@@@@@@..........  @@@@@@@@@@@@@@%  .........*@@@@@@@@@@
@@@@@@@@@@@@@%....   @@//////////////#@@  [email protected]@@@@@@@@@@@@
@@@@@@@@@@@@@@@@  @@@///////////////////@@   @@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@  ************************   @@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@                             @@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
************************************************************/

pragma solidity ^0.8.6;

import { IBitstraysSeeder } from './IBitstraysSeeder.sol';

interface IBitstraysDescriptor {
    
    event PartsLocked();

    event DataURIToggled(bool enabled);

    event AttributesToggled(bool enabled);

    event BaseURIUpdated(string baseURI);

    function arePartsLocked() external returns (bool);

    function areAttributesEnabled() external returns (bool);

    function isDataURIEnabled() external returns (bool);

    function baseURI() external returns (string memory);

    function palettes(uint8 paletteIndex, uint256 colorIndex) external view returns (string memory);
    
    function metadata(uint8 index, uint256 traitIndex) external view returns (string memory);

    function traitNames(uint256 index) external view returns (string memory);

    function backgrounds(uint256 index) external view returns (string memory);

    function arms(uint256 index) external view returns (bytes memory);

    function shirts(uint256 index) external view returns (bytes memory);

    function motives(uint256 index) external view returns (bytes memory);

    function heads(uint256 index) external view returns (bytes memory);

    function eyes(uint256 index) external view returns (bytes memory);

    function mouths(uint256 index) external view returns (bytes memory);

    function backgroundCount() external view returns (uint256);

    function armsCount() external view returns (uint256);

    function shirtsCount() external view returns (uint256);

    function motivesCount() external view returns (uint256);

    function headCount() external view returns (uint256);

    function eyesCount() external view returns (uint256);

    function mouthsCount() external view returns (uint256);

    function addManyMetadata(string[] calldata _metadata) external;

    function addManyColorsToPalette(uint8 paletteIndex, string[] calldata newColors) external;

    function addManyBackgrounds(string[] calldata backgrounds) external;

    function addManyArms(bytes[] calldata _arms) external;

    function addManyShirts(bytes[] calldata _shirts) external;

    function addManyMotives(bytes[] calldata _motives) external;

    function addManyHeads(bytes[] calldata _heads) external;

    function addManyEyes(bytes[] calldata _eyes) external;

    function addManyMouths(bytes[] calldata _mouths) external;

    function addColorToPalette(uint8 paletteIndex, string calldata color) external;

    function addBackground(string calldata background) external;

    function addArms(bytes calldata body) external;

    function addShirt(bytes calldata shirt) external;

    function addMotive(bytes calldata motive) external;

    function addHead(bytes calldata head) external;

    function addEyes(bytes calldata eyes) external;

    function addMouth(bytes calldata mouth) external;

    function lockParts() external;

    function toggleDataURIEnabled() external;

    function toggleAttributesEnabled() external;

    function setBaseURI(string calldata baseURI) external;

    function tokenURI(uint256 tokenId, IBitstraysSeeder.Seed memory seed) external view returns (string memory);

    function dataURI(uint256 tokenId, IBitstraysSeeder.Seed memory seed) external view returns (string memory);

    function genericDataURI(
        string calldata name,
        string calldata description,
        IBitstraysSeeder.Seed memory seed
    ) external view returns (string memory);

    function generateSVGImage(IBitstraysSeeder.Seed memory seed) external view returns (string memory);
}