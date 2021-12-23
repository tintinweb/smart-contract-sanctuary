// SPDX-License-Identifier: GPL-3.0

/// @title Shapes pseudo-random seed generator

pragma solidity ^0.8.6;

import { IShapesSeeder } from './interfaces/IShapesSeeder.sol';
import { IShapesDescriptor } from './interfaces/IShapesDescriptor.sol';

contract ShapesSeeder is IShapesSeeder {
    /**
     * @notice Generate a pseudo-random Shape seed using the previous blockhash and Shape ID.
     */
    // prettier-ignore
    function generateSeed(uint256 shapeId, IShapesDescriptor descriptor) external view override returns (Seed memory) {
        uint256 pseudorandomness = uint256(
            keccak256(abi.encodePacked(blockhash(block.number - 1), shapeId))
        );

        uint256 backgroundCount = descriptor.backgroundCount();
        // uint256 paletteCount = descriptor.paletteCount();

        return Seed({
            background: uint48(
                uint48(pseudorandomness >> 7) % backgroundCount
            ),
            palette: uint48(
                3 // TODO reimplement
            )
        });
    }
}

// SPDX-License-Identifier: GPL-3.0

/// @title Interface for ShapesSeeder

pragma solidity ^0.8.6;

import { IShapesDescriptor } from './IShapesDescriptor.sol';

interface IShapesSeeder {
    struct Seed {
        uint48 background;
        uint48 palette;
    }

    function generateSeed(uint256 shapeId, IShapesDescriptor descriptor) external view returns (Seed memory);
}

// SPDX-License-Identifier: GPL-3.0

/// @title Interface for ShapesDescriptor

pragma solidity ^0.8.6;

import { IShapesSeeder } from './IShapesSeeder.sol';

interface IShapesDescriptor {
    event PartsLocked();

    event DataURIToggled(bool enabled);

    event BaseURIUpdated(string baseURI);

    function arePartsLocked() external returns (bool);

    function isDataURIEnabled() external returns (bool);

    function baseURI() external returns (string memory);

    function palettes(uint8 paletteIndex, uint256 colorIndex) external view returns (string memory);

    function backgrounds(uint256 index) external view returns (string memory);

    function backgroundCount() external view returns (uint256);

    function addManyColorsToPalette(uint8 paletteIndex, string[] calldata newColors) external;

    function addManyBackgrounds(string[] calldata backgrounds) external;

    function addColorToPalette(uint8 paletteIndex, string calldata color) external;

    function addBackground(string calldata background) external;

    function lockParts() external;

    function tokenURI(uint256 tokenId, IShapesSeeder.Seed memory seed) external view returns (string memory);

    function genericDataURI(
        string calldata name,
        string calldata description,
        IShapesSeeder.Seed memory seed
    ) external view returns (string memory);

    function generateSVGImage(IShapesSeeder.Seed memory seed) external view returns (string memory);
}