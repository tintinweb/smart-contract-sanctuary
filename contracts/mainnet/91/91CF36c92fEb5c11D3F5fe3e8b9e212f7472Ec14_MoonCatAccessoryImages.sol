/**
 *Submitted for verification at Etherscan.io on 2022-01-14
*/

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.1;


interface IMoonCatReference {
    function doc (address contractAddress) external view returns (string memory name, string memory description, string memory details);
    function setDoc (address contractAddress, string calldata name, string calldata description) external;
}


interface IMoonCatTraits {
    function kTraitsOf (bytes5 catId) external view returns (bool genesis, bool pale, uint8 facing, uint8 expression, uint8 pattern, uint8 pose);
}

interface IMoonCatColors {
    function BasePalette (uint index) external view returns (uint8);
    function colorsOf (bytes5 catId) external view returns (uint8[24] memory);
    function accessoryColorsOf (bytes5 catId) external view returns (uint8[45] memory);
    function colorAlpha (uint8 id) external pure returns (uint8);
}

interface IMoonCatSVGs {
    function flip (bytes memory svgData) external pure returns (bytes memory);
    function getPixelData (uint8 facing, uint8 expression, uint8 pose, uint8 pattern, uint8[24] memory colors) external view returns (bytes memory);
    function boundingBox (uint8 facing, uint8 pose) external view returns (uint8 x, uint8 y, uint8 width, uint8 height);
    function glowGroup (bytes memory pixels, uint8 r, uint8 g, uint8 b) external pure returns (bytes memory);
    function svgTag (uint8 x, uint8 y, uint8 w, uint8 h) external pure returns (bytes memory);
    function uint2str (uint value) external pure returns (string memory);
}

interface IMoonCatRescue {
    function rescueOrder(uint256 tokenId) external view returns (bytes5);
    function catOwners(bytes5 catId) external view returns (address);
}

interface IMoonCatAccessories {
    function accessoryImageData (uint256 accessoryId) external view returns (bytes2[4] memory positions,
                                                                             bytes8[7] memory palettes,
                                                                             uint8 width,
                                                                             uint8 height,
                                                                             uint8 meta,
                                                                             bytes memory IDAT);

    function doesMoonCatOwnAccessory (uint256 rescueOrder, uint256 accessoryId) external view returns (bool);
    function balanceOf (uint256 rescueOrder) external view returns (uint256);
    struct OwnedAccessory {
        uint232 accessoryId;
        uint8 paletteIndex;
        uint16 zIndex;
    }
    function ownedAccessoryByIndex (uint256 rescueOrder, uint256 ownedAccessoryIndex) external view returns (OwnedAccessory memory);
}

interface IMoonCatSVGS {
    function imageOfExtended (bytes5 catId, bytes memory pre, bytes memory post) external view returns (string memory);
}


interface IReverseResolver {
    function claim(address owner) external returns (bytes32);
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

interface IERC721 {
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function ownerOf(uint256 tokenId) external view returns (address);
}

library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
                let resultPtr := add(result, 32)

                for {
                     let i := 0
                } lt(i, len) {

            } {
            i := add(i, 3)
            let input := and(mload(add(data, i)), 0xffffff)

            let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
            out := shl(8, out)
            out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
            out := shl(8, out)
            out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
            out := shl(8, out)
            out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
            out := shl(224, out)

            mstore(resultPtr, out)

            resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
                          case 1 {
                                  mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
                }
            case 2 {
                    mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}

/**
 * @title AccessoryPNGs
 * @notice On Chain MoonCat Accessory Image Generation
 * @dev Builds PNGs of MoonCat Accessories
 */
contract MoonCatAccessoryImages {

    /* External Contracts */

    IMoonCatRescue MoonCatRescue = IMoonCatRescue(0x60cd862c9C687A9dE49aecdC3A99b74A4fc54aB6);
    IMoonCatAccessories MoonCatAccessories = IMoonCatAccessories(0x8d33303023723dE93b213da4EB53bE890e747C63);

    IMoonCatReference MoonCatReference;
    IMoonCatTraits MoonCatTraits;
    IMoonCatColors MoonCatColors;
    IMoonCatSVGs MoonCatSVGs;

    address MoonCatAcclimatorAddress = 0xc3f733ca98E0daD0386979Eb96fb1722A1A05E69;

    /* CRC */

    uint32[256] CRCTable = [0x0,0x77073096,0xee0e612c,0x990951ba,0x76dc419,0x706af48f,0xe963a535,0x9e6495a3,0xedb8832,0x79dcb8a4,0xe0d5e91e,0x97d2d988,0x9b64c2b,0x7eb17cbd,0xe7b82d07,0x90bf1d91,0x1db71064,0x6ab020f2,0xf3b97148,0x84be41de,0x1adad47d,0x6ddde4eb,0xf4d4b551,0x83d385c7,0x136c9856,0x646ba8c0,0xfd62f97a,0x8a65c9ec,0x14015c4f,0x63066cd9,0xfa0f3d63,0x8d080df5,0x3b6e20c8,0x4c69105e,0xd56041e4,0xa2677172,0x3c03e4d1,0x4b04d447,0xd20d85fd,0xa50ab56b,0x35b5a8fa,0x42b2986c,0xdbbbc9d6,0xacbcf940,0x32d86ce3,0x45df5c75,0xdcd60dcf,0xabd13d59,0x26d930ac,0x51de003a,0xc8d75180,0xbfd06116,0x21b4f4b5,0x56b3c423,0xcfba9599,0xb8bda50f,0x2802b89e,0x5f058808,0xc60cd9b2,0xb10be924,0x2f6f7c87,0x58684c11,0xc1611dab,0xb6662d3d,0x76dc4190,0x1db7106,0x98d220bc,0xefd5102a,0x71b18589,0x6b6b51f,0x9fbfe4a5,0xe8b8d433,0x7807c9a2,0xf00f934,0x9609a88e,0xe10e9818,0x7f6a0dbb,0x86d3d2d,0x91646c97,0xe6635c01,0x6b6b51f4,0x1c6c6162,0x856530d8,0xf262004e,0x6c0695ed,0x1b01a57b,0x8208f4c1,0xf50fc457,0x65b0d9c6,0x12b7e950,0x8bbeb8ea,0xfcb9887c,0x62dd1ddf,0x15da2d49,0x8cd37cf3,0xfbd44c65,0x4db26158,0x3ab551ce,0xa3bc0074,0xd4bb30e2,0x4adfa541,0x3dd895d7,0xa4d1c46d,0xd3d6f4fb,0x4369e96a,0x346ed9fc,0xad678846,0xda60b8d0,0x44042d73,0x33031de5,0xaa0a4c5f,0xdd0d7cc9,0x5005713c,0x270241aa,0xbe0b1010,0xc90c2086,0x5768b525,0x206f85b3,0xb966d409,0xce61e49f,0x5edef90e,0x29d9c998,0xb0d09822,0xc7d7a8b4,0x59b33d17,0x2eb40d81,0xb7bd5c3b,0xc0ba6cad,0xedb88320,0x9abfb3b6,0x3b6e20c,0x74b1d29a,0xead54739,0x9dd277af,0x4db2615,0x73dc1683,0xe3630b12,0x94643b84,0xd6d6a3e,0x7a6a5aa8,0xe40ecf0b,0x9309ff9d,0xa00ae27,0x7d079eb1,0xf00f9344,0x8708a3d2,0x1e01f268,0x6906c2fe,0xf762575d,0x806567cb,0x196c3671,0x6e6b06e7,0xfed41b76,0x89d32be0,0x10da7a5a,0x67dd4acc,0xf9b9df6f,0x8ebeeff9,0x17b7be43,0x60b08ed5,0xd6d6a3e8,0xa1d1937e,0x38d8c2c4,0x4fdff252,0xd1bb67f1,0xa6bc5767,0x3fb506dd,0x48b2364b,0xd80d2bda,0xaf0a1b4c,0x36034af6,0x41047a60,0xdf60efc3,0xa867df55,0x316e8eef,0x4669be79,0xcb61b38c,0xbc66831a,0x256fd2a0,0x5268e236,0xcc0c7795,0xbb0b4703,0x220216b9,0x5505262f,0xc5ba3bbe,0xb2bd0b28,0x2bb45a92,0x5cb36a04,0xc2d7ffa7,0xb5d0cf31,0x2cd99e8b,0x5bdeae1d,0x9b64c2b0,0xec63f226,0x756aa39c,0x26d930a,0x9c0906a9,0xeb0e363f,0x72076785,0x5005713,0x95bf4a82,0xe2b87a14,0x7bb12bae,0xcb61b38,0x92d28e9b,0xe5d5be0d,0x7cdcefb7,0xbdbdf21,0x86d3d2d4,0xf1d4e242,0x68ddb3f8,0x1fda836e,0x81be16cd,0xf6b9265b,0x6fb077e1,0x18b74777,0x88085ae6,0xff0f6a70,0x66063bca,0x11010b5c,0x8f659eff,0xf862ae69,0x616bffd3,0x166ccf45,0xa00ae278,0xd70dd2ee,0x4e048354,0x3903b3c2,0xa7672661,0xd06016f7,0x4969474d,0x3e6e77db,0xaed16a4a,0xd9d65adc,0x40df0b66,0x37d83bf0,0xa9bcae53,0xdebb9ec5,0x47b2cf7f,0x30b5ffe9,0xbdbdf21c,0xcabac28a,0x53b39330,0x24b4a3a6,0xbad03605,0xcdd70693,0x54de5729,0x23d967bf,0xb3667a2e,0xc4614ab8,0x5d681b02,0x2a6f2b94,0xb40bbe37,0xc30c8ea1,0x5a05df1b,0x2d02ef8d];

    /**
     * @dev Create a cyclic redundancy check (CRC) value for a given set of data.
     *
     * This is the error-detecting code used for the PNG data format to validate each chunk of data within the file. This Solidity implementation
     * is needed to be able to dynamically create PNG files piecemeal.
     */
    function crc32 (bytes memory data) public view returns (uint32) {
        uint32 crc = type(uint32).max;
        for (uint i = 0; i < data.length; i++) {
            uint8 byt;
            assembly {
            byt := mload(add(add(data, 0x1), i))
            }
            crc = (crc >> 8) ^ CRCTable[(crc & 255) ^ byt];
        }
        return ~crc;
    }

    /* accessoryPNGs */

    uint64 constant public PNGHeader = 0x89504e470d0a1a0a;
    uint96 constant public PNGFooter = 0x0000000049454e44ae426082;
    uint40 constant internal IHDRDetails = 0x0803000000;

    /**
     * @dev Assemble a block of data into a valid PNG file chunk.
     */
    function generatePNGChunk (string memory typeCode, bytes memory data) public view returns (bytes memory) {
        uint32 crc = crc32(abi.encodePacked(typeCode, data));
        return abi.encodePacked(uint32(data.length),
                                typeCode,
                                data,
                                crc);
    }

    /**
     * @dev Take metadata about an individual Accessory and the MoonCat wearing it, and render the Accessory as a PNG image.
     */
    function assemblePNG (uint8[45] memory accessoryColors, bytes8 palette, uint8 width, uint8 height, bytes memory IDAT)
        internal
        view
        returns (bytes memory)
    {

        bytes memory colors = new bytes(27);
        bytes memory alphas = new bytes(9);

        for (uint i = 0; i < 8; i++) {
            uint256 colorIndex = uint256(uint8(palette[i]));
            alphas[i + 1] = bytes1(MoonCatColors.colorAlpha(uint8(colorIndex)));

            if (colorIndex > 113) {
                colorIndex = (colorIndex - 113) * 3;
                colors[i * 3 + 3] = bytes1(accessoryColors[colorIndex]);
                colors[i * 3 + 4] = bytes1(accessoryColors[colorIndex + 1]);
                colors[i * 3 + 5] = bytes1(accessoryColors[colorIndex + 2]);
            } else {
                colorIndex = colorIndex * 3;
                colors[i * 3 + 3] = bytes1(MoonCatColors.BasePalette(colorIndex));
                colors[i * 3 + 4] = bytes1(MoonCatColors.BasePalette(colorIndex + 1));
                colors[i * 3 + 5] = bytes1(MoonCatColors.BasePalette(colorIndex + 2));
            }
        }

        return abi.encodePacked(PNGHeader,
                                generatePNGChunk("IHDR", abi.encodePacked(uint32(width), uint32(height), IHDRDetails)),
                                generatePNGChunk("PLTE", colors),//abi.encodePacked(colors)),
                                generatePNGChunk("tRNS", alphas),
                                generatePNGChunk("IDAT", IDAT),
                                PNGFooter);
    }

    /**
     * @dev For a given MoonCat rescue order and Accessory ID and palette ID, render as PNG.
     * The PNG output is converted to a base64-encoded blob, which is the format used for encoding into an SVG or inline HTML.
     */
    function accessoryPNG (uint256 rescueOrder, uint256 accessoryId, uint16 paletteIndex) public view returns (string memory) {
        require(rescueOrder < 25440, "Invalid Rescue Order");
        bytes5 catId = MoonCatRescue.rescueOrder(rescueOrder);
        uint8[45] memory accessoryColors = MoonCatColors.accessoryColorsOf(catId);
        (,bytes8[7] memory palettes, uint8 width, uint8 height,,bytes memory IDAT) = MoonCatAccessories.accessoryImageData(accessoryId);
        return string(abi.encodePacked("data:image/png;base64,",
                                       Base64.encode(assemblePNG(accessoryColors, palettes[paletteIndex], width, height, IDAT))));
    }

    /* Composite */

    struct PreppedAccessory {
        uint16 zIndex;

        uint8 offsetX;
        uint8 offsetY;
        uint8 width;
        uint8 height;

        bool mirror;
        bool background;

        bytes8 palette;
        bytes IDAT;
    }

    /**
     * @dev Given a list of accessories, sort them by z-index.
     */
    function sortAccessories(PreppedAccessory[] memory pas) internal pure {
        for (uint i = 1; i < pas.length; i++) {
            PreppedAccessory memory pa = pas[i];
            uint key = pa.zIndex;
            uint j = i;
            while (j > 0 && pas[j - 1].zIndex > key) {
                pas[j] = pas[j - 1];
                j--;
            }
            pas[j] = pa;
        }
    }

    /**
     * @dev Given a MoonCat and accessory's basic information, derive colors and other metadata for them.
     */
    function prepAccessory (uint8 facing, uint8 pose,  bool allowUnverified, IMoonCatAccessories.OwnedAccessory memory accessory)
        internal
        view
        returns (PreppedAccessory memory)
    {
        (bytes2[4] memory positions,
         bytes8[7] memory palettes,
         uint8 width, uint8 height,
         uint8 meta,
         bytes memory IDAT) = MoonCatAccessories.accessoryImageData(accessory.accessoryId);

        bytes2 position = positions[pose];
        uint8 offsetX = uint8(position[0]);
        uint8 offsetY = uint8(position[1]);
        bool mirror;
        if (facing == 1) {
            mirror = ((meta >> 1) & 1) == 1;
            if (((meta >> 2) & 1) == 1) { // mirrorPlacement
                if (!mirror) {
                    offsetX = 128 - offsetX - width;
                }
            } else if (mirror) {
                offsetX = 128 - offsetX - width;
            }
        }

        uint16 zIndex = accessory.zIndex;
        if (!allowUnverified) {
            zIndex = zIndex * (meta >> 7); // check for approval
        }

        return PreppedAccessory(zIndex,
                                offsetX, offsetY,
                                width, height,
                                mirror,
                                (meta & 1) == 1, // background
                                palettes[accessory.paletteIndex],
                                IDAT);
    }

    /**
     * @dev Given a MoonCat and a set of basic Accessories' information, derive their metadata and split into foreground/background lists.
     */
    function prepAccessories (uint256 rescueOrder, uint8 facing, uint8 pose, bool allowUnverified, IMoonCatAccessories.OwnedAccessory[] memory accessories) public view returns (PreppedAccessory[] memory, PreppedAccessory[] memory) {
        PreppedAccessory[] memory preppedAccessories = new PreppedAccessory[](accessories.length);
        uint bgCount = 0;
        uint fgCount = 0;
        for (uint i = 0; i < accessories.length; i++) {
            IMoonCatAccessories.OwnedAccessory memory accessory = accessories[i];
            require(MoonCatAccessories.doesMoonCatOwnAccessory(rescueOrder, accessory.accessoryId), "Accessory Not Owned By MoonCat");
            if (accessory.zIndex > 0) {
                preppedAccessories[i] = prepAccessory(facing, pose, allowUnverified, accessory);
                if (preppedAccessories[i].background) {
                    bgCount++;
                } else {
                    fgCount++;
                }
            }
        }
        PreppedAccessory[] memory background = new PreppedAccessory[](bgCount);
        PreppedAccessory[] memory foreground = new PreppedAccessory[](fgCount);

        bgCount = 0;
        fgCount = 0;

        for (uint i = 0; i < preppedAccessories.length; i++) {
            if (preppedAccessories[i].zIndex > 0) {
                if (preppedAccessories[i].background) {
                    background[bgCount] = preppedAccessories[i];
                    bgCount++;
                } else {
                    foreground[fgCount] = preppedAccessories[i];
                    fgCount++;
                }
            }
        }
        sortAccessories(background);
        sortAccessories(foreground);
        return (background, foreground);
    }

    /**
     * @dev Convert a MoonCat facing and pose trait information into an SVG viewBox definition to set that canvas size.
     */
    function initialBoundingBox (uint8 facing, uint8 pose) internal view returns (uint8, uint8, uint8, uint8) {
        (uint8 x1, uint8 y1, uint8 width, uint8 height) = MoonCatSVGs.boundingBox(facing, pose);
        return (x1, y1, x1 + width, y1 + height);
    }

    /**
     * @dev Given a MoonCat's pose information and a list of Accessories, calculate a bounding box that will cover them all.
     */
    function getBoundingBox (uint8 facing, uint8 pose, PreppedAccessory[] memory background, PreppedAccessory[] memory foreground)
        internal
        view
        returns (uint8, uint8, uint8, uint8)
    {
        (uint8 x1, uint8 y1, uint8 x2, uint8 y2) = initialBoundingBox(facing, pose);

        uint8 offsetX;

        for (uint i = 0; i < background.length; i++) {
            PreppedAccessory memory pa = background[i];
            if (pa.zIndex > 0) {
                if (pa.mirror) {
                    offsetX = 128 - pa.offsetX - pa.width;
                } else {
                    offsetX = pa.offsetX;
                }
                if (offsetX < x1) x1 = offsetX;
                if (pa.offsetY < y1) y1 = pa.offsetY;
                if ((offsetX + pa.width) > x2) x2 = offsetX + pa.width;
                if ((pa.offsetY + pa.height) > y2) y2 = pa.offsetY + pa.height;
            }
        }

        for (uint i = 0; i < foreground.length; i++) {
            PreppedAccessory memory pa = foreground[i];
            if (pa.zIndex > 0) {
                if (pa.mirror) {
                    offsetX = 128 - pa.offsetX - pa.width;
                } else {
                    offsetX = pa.offsetX;
                }
                if (offsetX < x1) x1 = offsetX;
                if (pa.offsetY < y1) y1 = pa.offsetY;
                if ((offsetX + pa.width) > x2) x2 = offsetX + pa.width;
                if ((pa.offsetY + pa.height) > y2) y2 = pa.offsetY + pa.height;
            }
        }

        return (x1, y1, x2 - x1, y2 - y1);
    }

    /**
     * @dev Given an Accessory's metadata, generate a PNG image of that Accessory and wrap in an SVG image object.
     */
    function accessorySVGSnippet (PreppedAccessory memory pa, uint8[45] memory accessoryColors)
        internal
        view
        returns (bytes memory)
    {
        bytes memory img = assemblePNG(accessoryColors, pa.palette, pa.width, pa.height, pa.IDAT);
        bytes memory snippet = abi.encodePacked("<image x=\"", MoonCatSVGs.uint2str(pa.offsetX),
                                                "\" y=\"", MoonCatSVGs.uint2str(pa.offsetY),
                                                "\" width=\"", MoonCatSVGs.uint2str(pa.width),
                                                "\" height=\"", MoonCatSVGs.uint2str(pa.height),
                                                "\" href=\"data:image/png;base64,", Base64.encode(img),
                                                "\"/>");

        if (pa.mirror) {
            return MoonCatSVGs.flip(snippet);
        }

        return snippet;
    }

    /**
     * @dev Given a set of metadata about MoonCat and desired Accessories to render on it, generate an SVG of that appearance.
     */
    function assembleSVG (uint8 x,
                          uint8 y,
                          uint8 width,
                          uint8 height,
                          bytes memory mooncatPixelData,
                          uint8[45] memory accessoryColors,
                          PreppedAccessory[] memory background,
                          PreppedAccessory[] memory foreground,
                          uint8 glowLevel)
        internal
        view
        returns (string memory)
    {

        bytes memory bg;
        bytes memory fg;

        for (uint i = background.length; i >= 1; i--) {
            bg = abi.encodePacked(bg, accessorySVGSnippet(background[i - 1], accessoryColors));
        }

        for (uint i = 0; i < foreground.length; i++) {
            fg = abi.encodePacked(fg, accessorySVGSnippet(foreground[i], accessoryColors));
        }

        if (glowLevel == 0) {
            return string(abi.encodePacked(MoonCatSVGs.svgTag(x, y, width, height),
                                           bg,
                                           mooncatPixelData,
                                           fg,
                                           "</svg>"));
        } else if (glowLevel == 1) {
            return string(abi.encodePacked(MoonCatSVGs.svgTag(x, y, width, height),
                                           MoonCatSVGs.glowGroup(mooncatPixelData,
                                                                 accessoryColors[0],
                                                                 accessoryColors[1],
                                                                 accessoryColors[2]),
                                           bg,
                                           mooncatPixelData,
                                           fg,
                                           "</svg>"));
        } else {
            return string(abi.encodePacked(MoonCatSVGs.svgTag(x, y, width, height),
                                           MoonCatSVGs.glowGroup(abi.encodePacked(bg,
                                                                                  mooncatPixelData,
                                                                                  fg),
                                                                 accessoryColors[0],
                                                                 accessoryColors[1],
                                                                 accessoryColors[2]),
                                           "</svg>"));
        }
    }

    /**
     * @dev Given a set of metadata about MoonCat and desired Accessories to render on it, generate an SVG of that appearance.
     */
    function assembleSVG (uint8 facing,
                          uint8 pose,
                          bytes memory mooncatPixelData,
                          uint8[45] memory accessoryColors,
                          PreppedAccessory[] memory background,
                          PreppedAccessory[] memory foreground,
                          uint8 glowLevel)
        internal
        view
        returns (string memory)
    {
        (uint8 x, uint8 y, uint8 width, uint8 height) = getBoundingBox(facing, pose, background, foreground);
        return assembleSVG(x, y, width, height, mooncatPixelData, accessoryColors, background, foreground, glowLevel);
    }

    /**
     * @dev Given a MoonCat Rescue Order and a list of Accessories they own, render an SVG of them wearing those accessories.
     */
    function accessorizedImageOf (uint256 rescueOrder, IMoonCatAccessories.OwnedAccessory[] memory accessories, uint8 glowLevel, bool allowUnverified)
        public
        view
        returns (string memory)
    {
        uint8 facing;
        uint8 pose;
        bytes memory mooncatPixelData;
        uint8[45] memory accessoryColors;
        {
            require(rescueOrder < 25440, "Invalid Rescue Order");
            bytes5 catId = MoonCatRescue.rescueOrder(rescueOrder);
            uint8[24] memory colors = MoonCatColors.colorsOf(catId);
            {
                uint8 expression;
                uint8 pattern;
                (,, facing, expression, pattern, pose) = MoonCatTraits.kTraitsOf(catId);
                mooncatPixelData = MoonCatSVGs.getPixelData(facing, expression, pose, pattern, colors);
            }
            accessoryColors = MoonCatColors.accessoryColorsOf(catId);
        }

        (PreppedAccessory[] memory background, PreppedAccessory[] memory foreground) = prepAccessories(rescueOrder, facing, pose, allowUnverified, accessories);
        return assembleSVG(facing, pose, mooncatPixelData, accessoryColors, background, foreground, glowLevel);
    }

    /**
     * @dev Given a MoonCat Rescue Order, look up what Accessories they are currently wearing, and render an SVG of them wearing those accessories.
     */
    function accessorizedImageOf (uint256 rescueOrder, uint8 glowLevel, bool allowUnverified)
        public
        view
        returns (string memory)
    {
        uint accessoryCount = MoonCatAccessories.balanceOf(rescueOrder);
        IMoonCatAccessories.OwnedAccessory[] memory accessories = new IMoonCatAccessories.OwnedAccessory[](accessoryCount);
        for (uint i = 0; i < accessoryCount; i++) {
            accessories[i] = MoonCatAccessories.ownedAccessoryByIndex(rescueOrder, i);
        }
        return accessorizedImageOf(rescueOrder, accessories, glowLevel, allowUnverified);
    }

    /**
     * @dev Given a MoonCat Rescue Order, look up what verified Accessories they are currently wearing, and render an SVG of them wearing those accessories.
     */
    function accessorizedImageOf (uint256 rescueOrder, uint8 glowLevel)
        public
        view
        returns (string memory)
    {
        return accessorizedImageOf(rescueOrder, glowLevel, false);
    }

    /**
     * @dev Given a MoonCat Rescue Order, look up what verified Accessories they are currently wearing, and render an unglowing SVG of them wearing those accessories.
     */
    function accessorizedImageOf (uint256 rescueOrder)
        public
        view
        returns (string memory)
    {
        return accessorizedImageOf(rescueOrder, 0, false);
    }

    /**
     * @dev Given a MoonCat Rescue Order and an Accessory ID, return the bounding box of the Accessory, relative to the MoonCat.
     */
    function placementOf (uint256 rescueOrder, uint256 accessoryId)
        public
        view
        returns (uint8 offsetX, uint8 offsetY, uint8 width, uint8 height, bool mirror, bool background)
    {
        bytes5 catId = MoonCatRescue.rescueOrder(rescueOrder);
        (,, uint8 facing,,, uint8 pose) = MoonCatTraits.kTraitsOf(catId);
        bytes2[4] memory positions;
        uint8 meta;
        (positions,, width, height, meta,) = MoonCatAccessories.accessoryImageData(accessoryId);
        bytes2 position = positions[pose];

        background = (meta & 1) == 1;

        bool mirrorPlacement;
        if (facing == 1) {
            mirror = ((meta >> 1) & 1) == 1;
            mirrorPlacement = ((meta >> 2) & 1) == 1;
        }

        offsetX = uint8(position[0]);
        offsetY = uint8(position[1]);

        if (mirrorPlacement) {
            offsetX = 128 - offsetX - width;
        }
    }

    /* General */

    /**
     * @dev Get documentation about this contract.
     */
    function doc() public view returns (string memory name, string memory description, string memory details) {
        return MoonCatReference.doc(address(this));
    }

    constructor (address MoonCatReferenceAddress, address MoonCatTraitsAddress, address MoonCatColorsAddress, address MoonCatSVGsAddress) {
        owner = payable(msg.sender);
        // https://docs.ens.domains/contract-api-reference/reverseregistrar#claim-address
        IReverseResolver(0x084b1c3C81545d370f3634392De611CaaBFf8148).claim(msg.sender);

        MoonCatReference = IMoonCatReference(MoonCatReferenceAddress);
        MoonCatTraits = IMoonCatTraits(MoonCatTraitsAddress);
        MoonCatColors = IMoonCatColors(MoonCatColorsAddress);
        MoonCatSVGs = IMoonCatSVGs(MoonCatSVGsAddress);
    }

    address payable public owner;

    modifier onlyOwner () {
        require(msg.sender == owner, "Only Owner");
        _;
    }

    /**
     * @dev Allow current `owner` to transfer ownership to another address.
     */
    function transferOwnership (address payable newOwner) public onlyOwner {
        owner = newOwner;
    }

    /**
     * @dev Update the location of the Reference Contract.
     */
    function setReferenceContract (address referenceContract) public onlyOwner {
        MoonCatReference = IMoonCatReference(referenceContract);
    }

    /**
     * @dev Rescue ERC20 assets sent directly to this contract.
     */
    function withdrawForeignERC20(address tokenContract) public onlyOwner {
        IERC20 token = IERC20(tokenContract);
        token.transfer(owner, token.balanceOf(address(this)));
    }

    /**
     * @dev Rescue ERC721 assets sent directly to this contract.
     */
    function withdrawForeignERC721(address tokenContract, uint256 tokenId) public onlyOwner {
        IERC721(tokenContract).safeTransferFrom(address(this), owner, tokenId);
    }
}