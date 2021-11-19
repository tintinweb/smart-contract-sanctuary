// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

pragma abicoder v2;

import "./interfaces/IOniiChainDescriptor.sol";
import "./interfaces/IOniiChain.sol";
import "./libraries/NFTDescriptor.sol";
import "./libraries/DetailHelper.sol";
import "base64-sol/base64.sol";

/// @title Describes Onii
/// @notice Produces a string containing the data URI for a JSON metadata string
contract OniiChainDescriptor is IOniiChainDescriptor {
    /// @dev Max value for defining probabilities
    uint256 internal constant MAX = 100000;

    uint256[] internal BACKGROUND_ITEMS = [4000, 3400, 3080, 2750, 2400, 1900, 1200, 0];
    uint256[] internal SKIN_ITEMS = [2000, 1000, 0];
    uint256[] internal NOSE_ITEMS = [10, 0];
    uint256[] internal MARK_ITEMS = [50000, 40000, 31550, 24550, 18550, 13550, 9050, 5550, 2550, 550, 50, 10, 0];
    uint256[] internal EYEBROW_ITEMS = [65000, 40000, 20000, 10000, 4000, 0];
    uint256[] internal MASK_ITEMS = [20000, 14000, 10000, 6000, 2000, 1000, 100, 0];
    uint256[] internal EARRINGS_ITEMS = [50000, 38000, 28000, 20000, 13000, 8000, 5000, 2900, 1000, 100, 30, 0];
    uint256[] internal ACCESSORY_ITEMS = [
        50000,
        43000,
        36200,
        29700,
        23400,
        17400,
        11900,
        7900,
        4400,
        1400,
        400,
        200,
        11,
        1,
        0
    ];
    uint256[] internal MOUTH_ITEMS = [
        80000,
        63000,
        48000,
        36000,
        27000,
        19000,
        12000,
        7000,
        4000,
        2000,
        1000,
        500,
        50,
        0
    ];
    uint256[] internal HAIR_ITEMS = [
        97000,
        94000,
        91000,
        88000,
        85000,
        82000,
        79000,
        76000,
        73000,
        70000,
        67000,
        64000,
        61000,
        58000,
        55000,
        52000,
        49000,
        46000,
        43000,
        40000,
        37000,
        34000,
        31000,
        28000,
        25000,
        22000,
        19000,
        16000,
        13000,
        10000,
        3000,
        1000,
        0
    ];
    uint256[] internal EYE_ITEMS = [
        98000,
        96000,
        94000,
        92000,
        90000,
        88000,
        86000,
        84000,
        82000,
        80000,
        78000,
        76000,
        74000,
        72000,
        70000,
        68000,
        60800,
        53700,
        46700,
        39900,
        33400,
        27200,
        21200,
        15300,
        10600,
        6600,
        3600,
        2600,
        1700,
        1000,
        500,
        100,
        10,
        0
    ];

    /// @inheritdoc IOniiChainDescriptor
    function tokenURI(IOniiChain oniiChain, uint256 tokenId) external view override returns (string memory) {
        NFTDescriptor.SVGParams memory params = getSVGParams(oniiChain, tokenId);
        params.background = getBackgroundId(params);
        string memory image = Base64.encode(bytes(NFTDescriptor.generateSVGImage(params)));
        string memory name = NFTDescriptor.generateName(params, tokenId);
        string memory description = NFTDescriptor.generateDescription(params);
        string memory attributes = NFTDescriptor.generateAttributes(params);

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"',
                                name,
                                '", "description":"',
                                description,
                                '", "attributes":',
                                attributes,
                                ', "image": "',
                                "data:image/svg+xml;base64,",
                                image,
                                '"}'
                            )
                        )
                    )
                )
            );
    }

    /// @inheritdoc IOniiChainDescriptor
    function generateHairId(uint256 tokenId, uint256 seed) external view override returns (uint8) {
        return DetailHelper.generate(MAX, seed, HAIR_ITEMS, this.generateHairId.selector, tokenId);
    }

    /// @inheritdoc IOniiChainDescriptor
    function generateEyeId(uint256 tokenId, uint256 seed) external view override returns (uint8) {
        return DetailHelper.generate(MAX, seed, EYE_ITEMS, this.generateEyeId.selector, tokenId);
    }

    /// @inheritdoc IOniiChainDescriptor
    function generateEyebrowId(uint256 tokenId, uint256 seed) external view override returns (uint8) {
        return DetailHelper.generate(MAX, seed, EYEBROW_ITEMS, this.generateEyebrowId.selector, tokenId);
    }

    /// @inheritdoc IOniiChainDescriptor
    function generateNoseId(uint256 tokenId, uint256 seed) external view override returns (uint8) {
        return DetailHelper.generate(MAX, seed, NOSE_ITEMS, this.generateNoseId.selector, tokenId);
    }

    /// @inheritdoc IOniiChainDescriptor
    function generateMouthId(uint256 tokenId, uint256 seed) external view override returns (uint8) {
        return DetailHelper.generate(MAX, seed, MOUTH_ITEMS, this.generateMouthId.selector, tokenId);
    }

    /// @inheritdoc IOniiChainDescriptor
    function generateMarkId(uint256 tokenId, uint256 seed) external view override returns (uint8) {
        return DetailHelper.generate(MAX, seed, MARK_ITEMS, this.generateMarkId.selector, tokenId);
    }

    /// @inheritdoc IOniiChainDescriptor
    function generateEarringsId(uint256 tokenId, uint256 seed) external view override returns (uint8) {
        return DetailHelper.generate(MAX, seed, EARRINGS_ITEMS, this.generateEarringsId.selector, tokenId);
    }

    /// @inheritdoc IOniiChainDescriptor
    function generateAccessoryId(uint256 tokenId, uint256 seed) external view override returns (uint8) {
        return DetailHelper.generate(MAX, seed, ACCESSORY_ITEMS, this.generateAccessoryId.selector, tokenId);
    }

    /// @inheritdoc IOniiChainDescriptor
    function generateMaskId(uint256 tokenId, uint256 seed) external view override returns (uint8) {
        return DetailHelper.generate(MAX, seed, MASK_ITEMS, this.generateMaskId.selector, tokenId);
    }

    /// @inheritdoc IOniiChainDescriptor
    function generateSkinId(uint256 tokenId, uint256 seed) external view override returns (uint8) {
        return DetailHelper.generate(MAX, seed, SKIN_ITEMS, this.generateSkinId.selector, tokenId);
    }

    /// @dev Get SVGParams from OniiChain.Detail
    function getSVGParams(IOniiChain oniiChain, uint256 tokenId) private view returns (NFTDescriptor.SVGParams memory) {
        IOniiChain.Detail memory detail = oniiChain.details(tokenId);
        return
            NFTDescriptor.SVGParams({
                hair: detail.hair,
                eye: detail.eye,
                eyebrow: detail.eyebrow,
                nose: detail.nose,
                mouth: detail.mouth,
                mark: detail.mark,
                earring: detail.earrings,
                accessory: detail.accessory,
                mask: detail.mask,
                skin: detail.skin,
                original: detail.original,
                background: 0,
                timestamp: detail.timestamp,
                creator: detail.creator
            });
    }

    function getBackgroundId(NFTDescriptor.SVGParams memory params) private view returns (uint8) {
        uint256 score = itemScorePosition(params.hair, HAIR_ITEMS) +
            itemScoreProba(params.accessory, ACCESSORY_ITEMS) +
            itemScoreProba(params.earring, EARRINGS_ITEMS) +
            itemScoreProba(params.mask, MASK_ITEMS) +
            itemScorePosition(params.mouth, MOUTH_ITEMS) +
            (itemScoreProba(params.skin, SKIN_ITEMS) / 2) +
            itemScoreProba(params.skin, SKIN_ITEMS) +
            itemScoreProba(params.nose, NOSE_ITEMS) +
            itemScoreProba(params.mark, MARK_ITEMS) +
            itemScorePosition(params.eye, EYE_ITEMS) +
            itemScoreProba(params.eyebrow, EYEBROW_ITEMS);
        return DetailHelper.pickItems(score, BACKGROUND_ITEMS);
    }

    /// @dev Get item score based on his probability
    function itemScoreProba(uint8 item, uint256[] memory ITEMS) private pure returns (uint256) {
        uint256 raw = ((item == 1 ? MAX : ITEMS[item - 2]) - ITEMS[item - 1]);
        return ((raw >= 1000) ? raw * 6 : raw) / 1000;
    }

    /// @dev Get item score based on his index
    function itemScorePosition(uint8 item, uint256[] memory ITEMS) private pure returns (uint256) {
        uint256 raw = ITEMS[item - 1];
        return ((raw >= 1000) ? raw * 6 : raw) / 1000;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

pragma abicoder v2;

import "./IOniiChain.sol";

/// @title Describes Onii via URI
interface IOniiChainDescriptor {
    /// @notice Produces the URI describing a particular Onii (token id)
    /// @dev Note this URI may be a data: URI with the JSON contents directly inlined
    /// @param oniiChain The OniiChain contract
    /// @param tokenId The ID of the token for which to produce a description
    /// @return The URI of the ERC721-compliant metadata
    function tokenURI(IOniiChain oniiChain, uint256 tokenId) external view returns (string memory);

    /// @notice Generate randomly an ID for the hair item
    /// @param tokenId the current tokenId
    /// @param seed Used for the initialization of the number generator.
    /// @return the hair item id
    function generateHairId(uint256 tokenId, uint256 seed) external view returns (uint8);

    /// @notice Generate randomly an ID for the eye item
    /// @param tokenId the current tokenId
    /// @param seed Used for the initialization of the number generator.
    /// @return the eye item id
    function generateEyeId(uint256 tokenId, uint256 seed) external view returns (uint8);

    /// @notice Generate randomly an ID for the eyebrow item
    /// @param tokenId the current tokenId
    /// @param seed Used for the initialization of the number generator.
    /// @return the eyebrow item id
    function generateEyebrowId(uint256 tokenId, uint256 seed) external view returns (uint8);

    /// @notice Generate randomly an ID for the nose item
    /// @param tokenId the current tokenId
    /// @param seed Used for the initialization of the number generator.
    /// @return the nose item id
    function generateNoseId(uint256 tokenId, uint256 seed) external view returns (uint8);

    /// @notice Generate randomly an ID for the mouth item
    /// @param tokenId the current tokenId
    /// @param seed Used for the initialization of the number generator.
    /// @return the mouth item id
    function generateMouthId(uint256 tokenId, uint256 seed) external view returns (uint8);

    /// @notice Generate randomly an ID for the mark item
    /// @param tokenId the current tokenId
    /// @param seed Used for the initialization of the number generator.
    /// @return the mark item id
    function generateMarkId(uint256 tokenId, uint256 seed) external view returns (uint8);

    /// @notice Generate randomly an ID for the earrings item
    /// @param tokenId the current tokenId
    /// @param seed Used for the initialization of the number generator.
    /// @return the earrings item id
    function generateEarringsId(uint256 tokenId, uint256 seed) external view returns (uint8);

    /// @notice Generate randomly an ID for the accessory item
    /// @param tokenId the current tokenId
    /// @param seed Used for the initialization of the number generator.
    /// @return the accessory item id
    function generateAccessoryId(uint256 tokenId, uint256 seed) external view returns (uint8);

    /// @notice Generate randomly an ID for the mask item
    /// @param tokenId the current tokenId
    /// @param seed Used for the initialization of the number generator.
    /// @return the mask item id
    function generateMaskId(uint256 tokenId, uint256 seed) external view returns (uint8);

    /// @notice Generate randomly the skin colors
    /// @param tokenId the current tokenId
    /// @param seed Used for the initialization of the number generator.
    /// @return the skin item id
    function generateSkinId(uint256 tokenId, uint256 seed) external view returns (uint8);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

pragma abicoder v2;

/// @title OniiChain NFTs Interface
interface IOniiChain {
    /// @notice Details about the Onii
    struct Detail {
        uint8 hair;
        uint8 eye;
        uint8 eyebrow;
        uint8 nose;
        uint8 mouth;
        uint8 mark;
        uint8 earrings;
        uint8 accessory;
        uint8 mask;
        uint8 skin;
        bool original;
        uint256 timestamp;
        address creator;
    }

    /// @notice Returns the details associated with a given token ID.
    /// @dev Throws if the token ID is not valid.
    /// @param tokenId The ID of the token that represents the Onii
    /// @return detail memory
    function details(uint256 tokenId) external view returns (Detail memory detail);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

pragma abicoder v2;

import "./details/BackgroundDetail.sol";
import "./details/BodyDetail.sol";
import "./details/HairDetail.sol";
import "./details/MouthDetail.sol";
import "./details/NoseDetail.sol";
import "./details/EyesDetail.sol";
import "./details/EyebrowDetail.sol";
import "./details/MarkDetail.sol";
import "./details/AccessoryDetail.sol";
import "./details/EarringsDetail.sol";
import "./details/MaskDetail.sol";
import "./DetailHelper.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/// @notice Helper to generate SVGs
library NFTDescriptor {
    struct SVGParams {
        uint8 hair;
        uint8 eye;
        uint8 eyebrow;
        uint8 nose;
        uint8 mouth;
        uint8 mark;
        uint8 earring;
        uint8 accessory;
        uint8 mask;
        uint8 background;
        uint8 skin;
        bool original;
        uint256 timestamp;
        address creator;
    }

    /// @dev Combine all the SVGs to generate the final image
    function generateSVGImage(SVGParams memory params) internal view returns (string memory) {
        return
            string(
                abi.encodePacked(
                    generateSVGHead(),
                    DetailHelper.getDetailSVG(address(BackgroundDetail), params.background),
                    generateSVGFace(params),
                    DetailHelper.getDetailSVG(address(EarringsDetail), params.earring),
                    DetailHelper.getDetailSVG(address(HairDetail), params.hair),
                    DetailHelper.getDetailSVG(address(MaskDetail), params.mask),
                    DetailHelper.getDetailSVG(address(AccessoryDetail), params.accessory),
                    generateCopy(params.original),
                    "</svg>"
                )
            );
    }

    /// @dev Combine face items
    function generateSVGFace(SVGParams memory params) private view returns (string memory) {
        return
            string(
                abi.encodePacked(
                    DetailHelper.getDetailSVG(address(BodyDetail), params.skin),
                    DetailHelper.getDetailSVG(address(MarkDetail), params.mark),
                    DetailHelper.getDetailSVG(address(MouthDetail), params.mouth),
                    DetailHelper.getDetailSVG(address(NoseDetail), params.nose),
                    DetailHelper.getDetailSVG(address(EyesDetail), params.eye),
                    DetailHelper.getDetailSVG(address(EyebrowDetail), params.eyebrow)
                )
            );
    }

    /// @dev generate Json Metadata name
    function generateName(SVGParams memory params, uint256 tokenId) internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    BackgroundDetail.getItemNameById(params.background),
                    " Onii ",
                    Strings.toString(tokenId)
                )
            );
    }

    /// @dev generate Json Metadata description
    function generateDescription(SVGParams memory params) internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "Generated by ",
                    Strings.toHexString(uint256(uint160(params.creator))),
                    " at ",
                    Strings.toString(params.timestamp)
                )
            );
    }

    /// @dev generate SVG header
    function generateSVGHead() private pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<svg version="1.1" xmlns="http://www.w3.org/2000/svg" x="0px" y="0px"',
                    ' viewBox="0 0 420 420" style="enable-background:new 0 0 420 420;" xml:space="preserve">'
                )
            );
    }

    /// @dev generate the "Copy" SVG if the onii is not the original
    function generateCopy(bool original) private pure returns (string memory) {
        return
            !original
                ? string(
                    abi.encodePacked(
                        '<g id="Copy">',
                        '<path fill="none" stroke="#F26559" stroke-width="0.5" stroke-miterlimit="10" d="M239.5,300.6c-4.9,1.8-5.9,8.1,1.3,4.1"/>',
                        '<path fill="none" stroke="#F26559" stroke-width="0.5" stroke-miterlimit="10" d="M242.9,299.5c-2.6,0.8-1.8,4.3,0.8,4.2 C246.3,303.1,245.6,298.7,242.9,299.5"/>',
                        '<path fill="none" stroke="#F26559" stroke-width="0.5" stroke-miterlimit="10" d="M247.5,302.9c0.2-1.6-1.4-4-0.8-5.4 c0.4-1.2,2.5-1.4,3.2-0.3c0.1,1.5-0.9,2.7-2.3,2.5"/>',
                        '<path fill="none" stroke="#F26559" stroke-width="0.5" stroke-miterlimit="10" d="M250.6,295.4c1.1-0.1,2.2,0,3.3,0.1 c0.5-0.8,0.7-1.7,0.5-2.7"/>',
                        '<path fill="none" stroke="#F26559" stroke-width="0.5" stroke-miterlimit="10" d="M252.5,299.1c0.5-1.2,1.2-2.3,1.4-3.5"/>',
                        "</g>"
                    )
                )
                : "";
    }

    /// @dev generate Json Metadata attributes
    function generateAttributes(SVGParams memory params) internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "[",
                    getJsonAttribute("Body", BodyDetail.getItemNameById(params.skin), false),
                    getJsonAttribute("Hair", HairDetail.getItemNameById(params.hair), false),
                    getJsonAttribute("Mouth", MouthDetail.getItemNameById(params.mouth), false),
                    getJsonAttribute("Nose", NoseDetail.getItemNameById(params.nose), false),
                    getJsonAttribute("Eyes", EyesDetail.getItemNameById(params.eye), false),
                    getJsonAttribute("Eyebrow", EyebrowDetail.getItemNameById(params.eyebrow), false),
                    abi.encodePacked(
                        getJsonAttribute("Mark", MarkDetail.getItemNameById(params.mark), false),
                        getJsonAttribute("Accessory", AccessoryDetail.getItemNameById(params.accessory), false),
                        getJsonAttribute("Earrings", EarringsDetail.getItemNameById(params.earring), false),
                        getJsonAttribute("Mask", MaskDetail.getItemNameById(params.mask), false),
                        getJsonAttribute("Background", BackgroundDetail.getItemNameById(params.background), false),
                        getJsonAttribute("Original", params.original ? "true" : "false", true),
                        "]"
                    )
                )
            );
    }

    /// @dev Get the json attribute as
    ///    {
    ///      "trait_type": "Skin",
    ///      "value": "Human"
    ///    }
    function getJsonAttribute(
        string memory trait,
        string memory value,
        bool end
    ) private pure returns (string memory json) {
        return string(abi.encodePacked('{ "trait_type" : "', trait, '", "value" : "', value, '" }', end ? "" : ","));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

pragma abicoder v2;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";

/// @title Helper for details generation
library DetailHelper {
    /// @notice Call the library item function
    /// @param lib The library address
    /// @param id The item ID
    function getDetailSVG(address lib, uint8 id) internal view returns (string memory) {
        (bool success, bytes memory data) = lib.staticcall(
            abi.encodeWithSignature(string(abi.encodePacked("item_", Strings.toString(id), "()")))
        );
        require(success);
        return abi.decode(data, (string));
    }

    /// @notice Generate a random number and return the index from the
    ///         corresponding interval.
    /// @param max The maximum value to generate
    /// @param seed Used for the initialization of the number generator
    /// @param intervals the intervals
    /// @param selector Caller selector
    /// @param tokenId the current tokenId
    function generate(
        uint256 max,
        uint256 seed,
        uint256[] memory intervals,
        bytes4 selector,
        uint256 tokenId
    ) internal view returns (uint8) {
        uint256 generated = generateRandom(max, seed, tokenId, selector);
        return pickItems(generated, intervals);
    }

    /// @notice Generate random number between 1 and max
    /// @param max Maximum value of the random number
    /// @param seed Used for the initialization of the number generator
    /// @param tokenId Current tokenId used as seed
    /// @param selector Caller selector used as seed
    function generateRandom(
        uint256 max,
        uint256 seed,
        uint256 tokenId,
        bytes4 selector
    ) private view returns (uint256) {
        return
            (uint256(
                keccak256(
                    abi.encodePacked(block.difficulty, block.number, tx.origin, tx.gasprice, selector, seed, tokenId)
                )
            ) % (max + 1)) + 1;
    }

    /// @notice Pick an item for the given random value
    /// @param val The random value
    /// @param intervals The intervals for the corresponding items
    /// @return the item ID where : intervals[] index + 1 = item ID
    function pickItems(uint256 val, uint256[] memory intervals) internal pure returns (uint8) {
        for (uint256 i; i < intervals.length; i++) {
            if (val > intervals[i]) {
                return SafeCast.toUint8(i + 1);
            }
        }
        revert("DetailHelper::pickItems: No item");
    }
}

// SPDX-License-Identifier: MIT

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides a function for encoding some bytes in base64
library Base64 {
    string internal constant TABLE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';
        
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
            for {} lt(dataPtr, endPtr) {}
            {
               dataPtr := add(dataPtr, 3)
               
               // read 3 bytes
               let input := mload(dataPtr)
               
               // write 4 characters
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr( 6, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(        input,  0x3F)))))
               resultPtr := add(resultPtr, 1)
            }
            
            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }
        
        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

pragma abicoder v2;

import "base64-sol/base64.sol";

/// @title Background SVG generator
library BackgroundDetail {
    /// @dev background N°1 => Ordinary
    function item_1() public pure returns (string memory) {
        return base("636363", "CFCFCF", "ABABAB");
    }

    /// @dev background N°2 => Unusual
    function item_2() public pure returns (string memory) {
        return base("004A06", "61E89B", "12B55F");
    }

    /// @dev background N°3 => Surprising
    function item_3() public pure returns (string memory) {
        return base("1A4685", "6BF0E3", "00ADC7");
    }

    /// @dev background N°4 => Impressive
    function item_4() public pure returns (string memory) {
        return base("380113", "D87AE6", "8A07BA");
    }

    /// @dev background N°5 => Extraordinary
    function item_5() public pure returns (string memory) {
        return base("A33900", "FAF299", "FF9121");
    }

    /// @dev background N°6 => Phenomenal
    function item_6() public pure returns (string memory) {
        return base("000000", "C000E8", "DED52C");
    }

    /// @dev background N°7 => Artistic
    function item_7() public pure returns (string memory) {
        return base("FF00E3", "E8E18B", "00C4AD");
    }

    /// @dev background N°8 => Unreal
    function item_8() public pure returns (string memory) {
        return base("CCCC75", "54054D", "001E2E");
    }

    /// @notice Return the background name of the given id
    /// @param id The background Id
    function getItemNameById(uint8 id) public pure returns (string memory name) {
        name = "";
        if (id == 1) {
            name = "Ordinary";
        } else if (id == 2) {
            name = "Unusual";
        } else if (id == 3) {
            name = "Surprising";
        } else if (id == 4) {
            name = "Impressive";
        } else if (id == 5) {
            name = "Extraordinary";
        } else if (id == 6) {
            name = "Phenomenal";
        } else if (id == 7) {
            name = "Artistic";
        } else if (id == 8) {
            name = "Unreal";
        }
    }

    /// @dev The base SVG for the backgrounds
    function base(
        string memory stop1,
        string memory stop2,
        string memory stop3
    ) private pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<g id="Background">',
                    '<radialGradient id="gradient" cx="210" cy="-134.05" r="210.025" gradientTransform="matrix(1 0 0 -1 0 76)" gradientUnits="userSpaceOnUse">',
                    "<style>",
                    ".color-anim {animation: col 6s infinite;animation-timing-function: ease-in-out;}",
                    "@keyframes col {0%,51% {stop-color:none} 52% {stop-color:#FFBAF7} 53%,100% {stop-color:none}}",
                    "</style>",
                    "<stop offset='0' class='color-anim' style='stop-color:#",
                    stop1,
                    "'/>",
                    "<stop offset='0.66' style='stop-color:#",
                    stop2,
                    "'><animate attributeName='offset' dur='18s' values='0.54;0.8;0.54' repeatCount='indefinite' keyTimes='0;.4;1'/></stop>",
                    "<stop offset='1' style='stop-color:#",
                    stop3,
                    "'><animate attributeName='offset' dur='18s' values='0.86;1;0.86' repeatCount='indefinite'/></stop>",
                    abi.encodePacked(
                        "</radialGradient>",
                        '<path fill="url(#gradient)" d="M390,420H30c-16.6,0-30-13.4-30-30V30C0,13.4,13.4,0,30,0h360c16.6,0,30,13.4,30,30v360C420,406.6,406.6,420,390,420z"/>',
                        '<path id="Border" opacity="0.4" fill="none" stroke="#FFFFFF" stroke-width="2" stroke-miterlimit="10" d="M383.4,410H36.6C21.9,410,10,398.1,10,383.4V36.6C10,21.9,21.9,10,36.6,10h346.8c14.7,0,26.6,11.9,26.6,26.6v346.8 C410,398.1,398.1,410,383.4,410z"/>',
                        '<path id="Mask" opacity="0.1" fill="#48005E" d="M381.4,410H38.6C22.8,410,10,397.2,10,381.4V38.6 C10,22.8,22.8,10,38.6,10h342.9c15.8,0,28.6,12.8,28.6,28.6v342.9C410,397.2,397.2,410,381.4,410z"/>',
                        "</g>"
                    )
                )
            );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

pragma abicoder v2;

import "base64-sol/base64.sol";

/// @title Body SVG generator
library BodyDetail {
    /// @dev Body N°1 => Human
    function item_1() public pure returns (string memory) {
        return base("FFEBB4", "FFBE94");
    }

    /// @dev Body N°2 => Shadow
    function item_2() public pure returns (string memory) {
        return base("2d2d2d", "000000");
    }

    /// @dev Body N°3 => Light
    function item_3() public pure returns (string memory) {
        return base("ffffff", "696969");
    }

    /// @notice Return the skin name of the given id
    /// @param id The skin Id
    function getItemNameById(uint8 id) public pure returns (string memory name) {
        name = "";
        if (id == 1) {
            name = "Human";
        } else if (id == 2) {
            name = "Shadow";
        } else if (id == 3) {
            name = "Light";
        }
    }

    /// @dev The base SVG for the body
    function base(string memory skin, string memory shadow) private pure returns (string memory) {
        string memory pathBase = "<path fill-rule='evenodd' clip-rule='evenodd' fill='#";
        string memory strokeBase = "' stroke='#000000' stroke-linecap='round' stroke-miterlimit='10'";

        return
            string(
                abi.encodePacked(
                    '<g id="Body">',
                    pathBase,
                    skin,
                    strokeBase,
                    " d='M177.1,287.1c0.8,9.6,0.3,19.3-1.5,29.2c-0.5,2.5-2.1,4.7-4.5,6c-15.7,8.5-41.1,16.4-68.8,24.2c-7.8,2.2-9.1,11.9-2,15.7c69,37,140.4,40.9,215.4,6.7c6.9-3.2,7-12.2,0.1-15.4c-21.4-9.9-42.1-19.7-53.1-26.2c-2.5-1.5-4-3.9-4.3-6.5c-0.7-7.4-0.9-16.1-0.3-25.5c0.7-10.8,2.5-20.3,4.4-28.2'/>",
                    abi.encodePacked(
                        pathBase,
                        shadow,
                        "' d='M177.1,289c0,0,23.2,33.7,39.3,29.5s40.9-20.5,40.9-20.5c1.2-8.7,2.4-17.5,3.5-26.2c-4.6,4.7-10.9,10.2-19,15.3c-10.8,6.8-21,10.4-28.5,12.4L177.1,289z'/>",
                        pathBase,
                        skin,
                        strokeBase,
                        " d='M301.3,193.6c2.5-4.6,10.7-68.1-19.8-99.1c-29.5-29.9-96-34-128.1-0.3s-23.7,105.6-23.7,105.6s12.4,59.8,24.2,72c0,0,32.3,24.8,40.7,29.5c8.4,4.8,16.4,2.2,16.4,2.2c15.4-5.7,25.1-10.9,33.3-17.4'/>",
                        pathBase
                    ),
                    skin,
                    strokeBase,
                    " d='M141.8,247.2c0.1,1.1-11.6,7.4-12.9-7.1c-1.3-14.5-3.9-18.2-9.3-34.5s9.1-8.4,9.1-8.4'/>",
                    abi.encodePacked(
                        pathBase,
                        skin,
                        strokeBase,
                        " d='M254.8,278.1c7-8.6,13.9-17.2,20.9-25.8c1.2-1.4,2.9-2.1,4.6-1.7c3.9,0.8,11.2,1.2,12.8-6.7c2.3-11,6.5-23.5,12.3-33.6c3.2-5.7,0.7-11.4-2.2-15.3c-2.1-2.8-6.1-2.7-7.9,0.2c-2.6,4-5,7.9-7.6,11.9'/>",
                        "<polygon fill-rule='evenodd' clip-rule='evenodd' fill='#",
                        skin,
                        "' points='272,237.4 251.4,270.4 260.9,268.6 276.9,232.4'/>",
                        "<path d='M193.3,196.4c0.8,5.1,1,10.2,1,15.4c0,2.6-0.1,5.2-0.4,7.7c-0.3,2.6-0.7,5.1-1.3,7.6h-0.1c0.1-2.6,0.3-5.1,0.4-7.7c0.2-2.5,0.4-5.1,0.6-7.6c0.1-2.6,0.2-5.1,0.1-7.7C193.5,201.5,193.4,198.9,193.3,196.4L193.3,196.4z'/>",
                        "<path fill='#",
                        shadow
                    ),
                    "' d='M197.8,242.8l-7.9-3.5c-0.4-0.2-0.5-0.7-0.2-1.1l3.2-3.3c0.4-0.4,1-0.5,1.5-0.3l12.7,4.6c0.6,0.2,0.6,1.1-0.1,1.3l-8.7,2.4C198.1,242.9,197.9,242.9,197.8,242.8z'/>",
                    "</g>"
                )
            );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

pragma abicoder v2;

import "base64-sol/base64.sol";
import "./constants/Colors.sol";

/// @title Hair SVG generator
library HairDetail {
    /// @dev Hair N°1 => Classic Brown
    function item_1() public pure returns (string memory) {
        return base(classicHairs(Colors.BROWN));
    }

    /// @dev Hair N°2 => Classic Black
    function item_2() public pure returns (string memory) {
        return base(classicHairs(Colors.BLACK));
    }

    /// @dev Hair N°3 => Classic Gray
    function item_3() public pure returns (string memory) {
        return base(classicHairs(Colors.GRAY));
    }

    /// @dev Hair N°4 => Classic White
    function item_4() public pure returns (string memory) {
        return base(classicHairs(Colors.WHITE));
    }

    /// @dev Hair N°5 => Classic Blue
    function item_5() public pure returns (string memory) {
        return base(classicHairs(Colors.BLUE));
    }

    /// @dev Hair N°6 => Classic Yellow
    function item_6() public pure returns (string memory) {
        return base(classicHairs(Colors.YELLOW));
    }

    /// @dev Hair N°7 => Classic Pink
    function item_7() public pure returns (string memory) {
        return base(classicHairs(Colors.PINK));
    }

    /// @dev Hair N°8 => Classic Red
    function item_8() public pure returns (string memory) {
        return base(classicHairs(Colors.RED));
    }

    /// @dev Hair N°9 => Classic Purple
    function item_9() public pure returns (string memory) {
        return base(classicHairs(Colors.PURPLE));
    }

    /// @dev Hair N°10 => Classic Green
    function item_10() public pure returns (string memory) {
        return base(classicHairs(Colors.GREEN));
    }

    /// @dev Hair N°11 => Classic Saiki
    function item_11() public pure returns (string memory) {
        return base(classicHairs(Colors.SAIKI));
    }

    /// @dev Hair N°12 => Classic 2 Brown
    function item_12() public pure returns (string memory) {
        return base(classicTwoHairs(Colors.BROWN));
    }

    /// @dev Hair N°13 => Classic 2 Black
    function item_13() public pure returns (string memory) {
        return base(classicTwoHairs(Colors.BLACK));
    }

    /// @dev Hair N°14 => Classic 2 Gray
    function item_14() public pure returns (string memory) {
        return base(classicTwoHairs(Colors.GRAY));
    }

    /// @dev Hair N°15 => Classic 2 White
    function item_15() public pure returns (string memory) {
        return base(classicTwoHairs(Colors.WHITE));
    }

    /// @dev Hair N°16 => Classic 2 Blue
    function item_16() public pure returns (string memory) {
        return base(classicTwoHairs(Colors.BLUE));
    }

    /// @dev Hair N°17 => Classic 2 Yellow
    function item_17() public pure returns (string memory) {
        return base(classicTwoHairs(Colors.YELLOW));
    }

    /// @dev Hair N°18 => Classic 2 Pink
    function item_18() public pure returns (string memory) {
        return base(classicTwoHairs(Colors.PINK));
    }

    /// @dev Hair N°19 => Classic 2 Red
    function item_19() public pure returns (string memory) {
        return base(classicTwoHairs(Colors.RED));
    }

    /// @dev Hair N°20 => Classic 2 Purple
    function item_20() public pure returns (string memory) {
        return base(classicTwoHairs(Colors.PURPLE));
    }

    /// @dev Hair N°21 => Classic 2 Green
    function item_21() public pure returns (string memory) {
        return base(classicTwoHairs(Colors.GREEN));
    }

    /// @dev Hair N°22 => Classic 2 Saiki
    function item_22() public pure returns (string memory) {
        return base(classicTwoHairs(Colors.SAIKI));
    }

    /// @dev Hair N°23 => Short Black
    function item_23() public pure returns (string memory) {
        return base(shortHairs(Colors.BLACK));
    }

    /// @dev Hair N°24 => Short Blue
    function item_24() public pure returns (string memory) {
        return base(shortHairs(Colors.BLUE));
    }

    /// @dev Hair N°25 => Short Pink
    function item_25() public pure returns (string memory) {
        return base(shortHairs(Colors.PINK));
    }

    /// @dev Hair N°26 => Short White
    function item_26() public pure returns (string memory) {
        return base(shortHairs(Colors.WHITE));
    }

    /// @dev Hair N°27 => Spike Black
    function item_27() public pure returns (string memory) {
        return base(spike(Colors.BLACK));
    }

    /// @dev Hair N°28 => Spike Blue
    function item_28() public pure returns (string memory) {
        return base(spike(Colors.BLUE));
    }

    /// @dev Hair N°29 => Spike Pink
    function item_29() public pure returns (string memory) {
        return base(spike(Colors.PINK));
    }

    /// @dev Hair N°30 => Spike White
    function item_30() public pure returns (string memory) {
        return base(spike(Colors.WHITE));
    }

    /// @dev Hair N°31 => Monk
    function item_31() public pure returns (string memory) {
        return base(monk());
    }

    /// @dev Hair N°32 => Nihon
    function item_32() public pure returns (string memory) {
        return
            base(
                string(
                    abi.encodePacked(
                        monk(),
                        '<path opacity="0.36" fill="#6E5454" stroke="#8A8A8A" stroke-width="0.5" stroke-miterlimit="10" d=" M287.5,206.8c0,0,0.1-17.4-2.9-20.3c-3.1-2.9-7.3-8.7-7.3-8.7s0.6-24.8-2.9-31.8c-3.6-7-3.9-24.3-35-23.6 c-30.3,0.7-42.5,5.4-42.5,5.4s-14.2-8.2-43-3.8c-19.3,4.9-17.2,50.1-17.2,50.1s-5.6,9.5-6.2,14.8c-0.6,5.3-0.3,8.3-0.3,8.3 S111,72.1,216.8,70.4c108.4-1.7,87.1,121.7,85.1,122.4C295.4,190.1,293.9,197.7,287.5,206.8z"/>',
                        '<g opacity="0.33">',
                        '<ellipse transform="matrix(0.7071 -0.7071 0.7071 0.7071 0.367 227.089)" fill="#FFFFFF" cx="274.3" cy="113.1" rx="1.4" ry="5.3"/>',
                        '<ellipse transform="matrix(0.5535 -0.8328 0.8328 0.5535 32.4151 255.0608)" fill="#FFFFFF" cx="254.1" cy="97.3" rx="4.2" ry="16.3"/>',
                        "</g>",
                        '<path fill="#FFFFFF" stroke="#2B232B" stroke-miterlimit="10" d="M136.2,125.1c0,0,72,9.9,162.2,0c0,0,4.4,14.9,4.8,26.6 c0,0-125.4,20.9-172.6-0.3C129.5,151.3,132.9,130.3,136.2,125.1z"/>',
                        '<polygon fill="#FFFFFF" stroke="#2B232B" stroke-miterlimit="10" points="306.2,138 324.2,168.1 330,160"/>',
                        '<path fill="#FFFFFF" stroke="#2B232B" stroke-miterlimit="10" d="M298.4,125.1l34.2,54.6l-18,15.5l-10.7-43.5 C302.3,142.2,299.9,128.8,298.4,125.1z"/>',
                        '<ellipse opacity="0.87" fill="#FF0039" cx="198.2" cy="144.1" rx="9.9" ry="10.8"/>'
                    )
                )
            );
    }

    /// @dev Hair N°33 => Bald
    function item_33() public pure returns (string memory) {
        return
            base(
                string(
                    abi.encodePacked(
                        '<ellipse transform="matrix(0.7071 -0.7071 0.7071 0.7071 0.1733 226.5807)" fill="#FFFFFF" cx="273.6" cy="113.1" rx="1.4" ry="5.3"/>',
                        '<ellipse transform="matrix(0.5535 -0.8328 0.8328 0.5535 32.1174 254.4671)" fill="#FFFFFF" cx="253.4" cy="97.3" rx="4.2" ry="16.3"/>'
                    )
                )
            );
    }

    /// @dev Generate classic hairs with the given color
    function classicHairs(string memory hairsColor) private pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "<path fill='#",
                    hairsColor,
                    "' stroke='#000000'  stroke-width='0.5' stroke-miterlimit='10' d='M252.4,71.8c0,0-15.1-13.6-42.6-12.3l15.6,8.8c0,0-12.9-0.9-28.4-1.3c-6.1-0.2-21.8,3.3-38.3-1.4c0,0,7.3,7.2,9.4,7.7c0,0-30.6,13.8-47.3,34.2c0,0,10.7-8.9,16.7-10.9c0,0-26,25.2-31.5,70c0,0,9.2-28.6,15.5-34.2c0,0-10.7,27.4-5.3,48.2c0,0,2.4-14.5,4.9-19.2c-1,14.1,2.4,33.9,13.8,47.8c0,0-3.3-15.8-2.2-21.9l8.8-17.9c0.1,4.1,1.3,8.1,3.1,12.3c0,0,13-36.1,19.7-43.9c0,0-2.9,15.4-1.1,29.6c0,0,6.8-23.5,16.9-36.8c0,0-4.6,15.6-2.7,31.9c0,0,9.4-26.2,10.4-28.2l-2.7,9.2c0,0,4.1,21.6,3.8,25.3c0,0,8.4-10.3,21.2-52l-2.9,12c0,0,9.8,20.3,10.3,22.2s-1.3-13.9-1.3-13.9s12.4,21.7,13.5,26c0,0,5.5-20.8,3.4-35.7l1.1,9.6c0,0,15,20.3,16.4,30.1s-0.1-23.4-0.1-23.4s13.8,30.6,17,39.4c0,0,1.9-17,1.4-19.4s8.5,34.6,4.4,46c0,0,11.7-16.4,11.5-21.4c1.4,0.8-1.3,22.6-4,26.3c0,0,3.2-0.3,8.4-9.3c0,0,11.1-13.4,11.8-11.7c0.7,1.7,1.8-2.9,5.5,10.2l2.6-7.6c0,0-0.4,15.4-3.3,21.4c0,0,14.3-32.5,10.4-58.7c0,0,3.7,9.3,4.4,16.9s3.1-32.8-7.7-51.4c0,0,6.9,3.9,10.8,4.8c0,0-12.6-12.5-13.6-15.9c0,0-14.1-25.7-39.1-34.6c0,0,9.3-3.2,15.6,0.2C286.5,78.8,271.5,66.7,252.4,71.8z'/>",
                    '<path fill="none" stroke="#000000" stroke-width="0.5" stroke-miterlimit="10" d="M286,210c0,0,8.5-10.8,8.6-18.7"/>',
                    '<path fill="none" stroke="#000000" stroke-width="0.5" stroke-linecap="round" stroke-miterlimit="10" d="M132.5,190.4c0,0-1.3-11.3,0.3-16.9"/>',
                    '<path fill="none" stroke="#000000" stroke-width="0.5" stroke-linecap="round" stroke-miterlimit="10" d="M141.5,170c0,0-1-6.5,1.6-20.4"/>',
                    '<path opacity="0.2" d="M267.7,151.7l-0.3,30.9c0,0,1.9-18.8,1.8-19.3s8.6,43.5,3.9,47.2c0,0,11.9-18.8,12.1-21.5s0,22-3.9,25c0,0,6-4.4,8.6-10.1c0,0,6.1-7,9.9-10.7c0,0,3.9-1,6.8,8.2l2.8-6.9c0,0,0.1,13.4-1.3,16.1c0,0,10.5-28.2,7.9-52.9c0,0,4.7,8.3,4.9,17.1c0.1,8.8,1.7-8.6,0.2-17.8c0,0-6.5-13.9-8.2-15.4c0,0,2.2,14.9,1.3,18.4c0,0-8.2-15.1-11.4-17.3c0,0,1.2,41-1.6,46.1c0,0-6.8-22.7-11.4-26.5c0,0,0.7,17.4-3.6,23.2C284.5,183.3,280.8,169.9,267.7,151.7z"/>',
                    '<path opacity="0.2" d="M234.3,137.1c0,0,17.1,23.2,16.7,30.2s-0.2-13.3-0.2-13.3s-11.7-22-17.6-26.2L234.3,137.1z"/>',
                    '<polygon opacity="0.2" points="250.7,143.3 267.5,162.9 267.3,181.9"/>',
                    '<path opacity="0.2" d="M207.4,129.2l9.7,20.7l-1-13.7c0,0,11.6,21,13.5,25.4l1.4-5l-17.6-27.4l1,7.5l-6-12.6L207.4,129.2z"/>',
                    '<path opacity="0.2" d="M209.2,118c0,0-13.7,36.6-18.5,40.9c-1.7-7.2-1.9-7.9-4.2-20.3c0,0-0.1,2.7-1.4,5.3c0.7,8.2,4.1,24.4,4,24.5S206.4,136.6,209.2,118z"/>',
                    '<path opacity="0.2" d="M187.6,134.7c0,0-9.6,25.5-10,26.9l-0.4-3.6C177.1,158.1,186.8,135.8,187.6,134.7z"/>',
                    '<path opacity="0.2" fill-rule="evenodd" clip-rule="evenodd" d="M180.7,129.6c0,0-16.7,22.3-17.7,24.2s0,12.4,0.3,12.8S165.9,153,180.7,129.6z"/>',
                    '<path opacity="0.2" fill-rule="evenodd" clip-rule="evenodd" d="M180.4,130.6c0,0-0.2,20.5-0.6,21.5c-0.4,0.9-2.6,5.8-2.6,5.8S176.1,147.1,180.4,130.6z"/>',
                    abi.encodePacked(
                        '<path opacity="0.2" d="M163.9,138c0,0-16.3,25.3-17.9,26.3c0,0-3.8-12.8-3-14.7s-9.6,10.3-9.9,17c0,0-8.4-0.6-11-7.4c-1-2.5,1.4-9.1,2.1-12.2c0,0-6.5,7.9-9.4,22.5c0,0,0.6,8.8,1.1,10c0,0,3.5-14.8,4.9-17.7c0,0-0.3,33.3,13.6,46.7c0,0-3.7-18.6-2.6-21l9.4-18.6c0,0,2.1,10.5,3.1,12.3l13.9-33.1L163.9,138z"/>',
                        '<path fill="#FFFFFF" d="M204,82.3c0,0-10.3,24.4-11.5,30.4c0,0,11.1-20.6,12.6-20.8c0,0,11.4,20.4,12,22.2C217.2,114.1,208.2,88.2,204,82.3z"/>',
                        '<path fill="#FFFFFF" d="M185.6,83.5c0,0-1,29.2,0,39.2c0,0-4-21.4-3.6-25.5c0.4-4-13.5,19.6-16,23.9c0,0,7.5-20.6,10.5-25.8c0,0-14.4,9.4-22,21.3C154.6,116.7,170.1,93.4,185.6,83.5z"/>',
                        '<path fill="#FFFFFF" d="M158.6,96.2c0,0-12,15.3-14.7,23.2"/>',
                        '<path fill="#FFFFFF" d="M125.8,125.9c0,0,9.5-20.6,23.5-27.7"/>',
                        '<path fill="#FFFFFF" d="M296.5,121.6c0,0-9.5-20.6-23.5-27.7"/>',
                        '<path fill="#FFFFFF" d="M216.1,88.5c0,0,10.9,19.9,11.6,23.6s3.7-5.5-10.6-23.6"/>',
                        '<path fill="#FFFFFF" d="M227,92c0,0,21.1,25.4,22,27.4s-4.9-23.8-12.9-29.5c0,0,9.5,20.7,9.9,21.9C246.3,113,233.1,94.1,227,92z"/>',
                        '<path fill="#FFFFFF" d="M263.1,119.5c0,0-9.5-26.8-10.6-28.3s15.5,14.1,16.2,22.5c0,0-11.1-16.1-11.8-16.9C256.1,96,264.3,114.1,263.1,119.5z"/>'
                    )
                )
            );
    }

    /// @dev Generate classic 2 hairs with the given color
    function classicTwoHairs(string memory hairsColor) private pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "<polygon fill='#",
                    hairsColor,
                    "' points='188.2,124.6 198.3,128.1 211.2,124.3 197.8,113.2'/>",
                    '<polygon opacity="0.5" points="188.4,124.7 198.3,128.1 211.7,124.2 197.7,113.6"/>',
                    "<path fill='#",
                    hairsColor,
                    "' stroke='#000000' stroke-width='0.5' stroke-miterlimit='10' d='M274,209.6c1,0.9,10.1-12.8,10.5-18.3 c1.1,3.2-0.2,16.8-2.9,20.5c0,0,3.7-0.7,8.3-6.5c0,0,11.1-13.4,11.8-11.7c0.7,1.7,1.8-2.9,5.5,10.2l2.6-7.6 c0,0-0.4,15.4-3.3,21.4c0,0,14.3-32.5,10.4-58.7c0,0,3.7,9.3,4.4,16.9s3.1-32.8-7.7-51.4c0,0,6.9,3.9,10.8,4.8 c0,0-12.6-12.5-13.6-15.9c0,0-14.1-25.7-39.1-34.6c0,0,9.3-3.2,15.6,0.2c-0.1-0.1-15.1-12.2-34.2-7.1c0,0-15.1-13.6-42.6-12.3 l15.6,8.8c0,0-12.9-0.9-28.4-1.3c-6.1-0.2-21.8,3.3-38.3-1.4c0,0,7.3,7.2,9.4,7.7c0,0-30.6,13.8-47.3,34.2 c0,0,10.7-8.9,16.7-10.9c0,0-26,25.2-31.5,70c0,0,9.2-28.6,15.5-34.2c0,0-10.7,27.4-5.3,48.2c0,0,2.4-14.5,4.9-19.2 c-1,14.1,2.4,33.9,13.8,47.8c0,0-3.3-15.8-2.2-21.9l8.8-17.9c0.1,4.1,1.3,8.1,3.1,12.3c0,0,13-36.1,19.7-43.9 c0,0-2.9,15.4-1.1,29.6c0,0,7.2-26.8,17.3-40.1c0,0,0.8,0.1,17.6-7.6c6.3,3.1,8,1.4,17.9,7.7c4.1,5.3,13.8,31.9,15.6,41.5 c3.4-7.3,5.6-19,5.2-29.5c2.7,3.7,8.9,19.9,9.6,34.3c0,0,7.9-15.9,5.9-29c0-0.2,0.2,14.5,0.3,14.3c0,0,12.1,19.9,14.9,19.7 c0-0.8-1.7-12.9-1.7-12.8c1.3,5.8,2.8,23.3,3.1,27.1l5-9.5C276.2,184,276.8,204.9,274,209.6z'/>",
                    '<path fill="none" stroke="#000000" stroke-width="0.5" stroke-miterlimit="10" d="M286.7,210c0,0,8.5-10.8,8.6-18.7"/>',
                    '<path fill="none" stroke="#000000" stroke-width="0.5" stroke-linecap="round" stroke-miterlimit="10" d="M133.2,190.4 c0,0-1.3-11.3,0.3-16.9"/>',
                    abi.encodePacked(
                        '<path fill="none" stroke="#000000" stroke-width="0.5" stroke-linecap="round" stroke-miterlimit="10" d="M142.2,170 c0,0-1-6.5,1.6-20.4"/>',
                        '<path opacity="0.2" fill-rule="evenodd" clip-rule="evenodd" d="M180.6,128.2 c0,0-15.9,23.7-16.9,25.6s0,12.4,0.3,12.8S165.8,151.6,180.6,128.2z"/>',
                        '<path opacity="0.2" d="M164.6,138c0,0-16.3,25.3-17.9,26.3c0,0-3.8-12.8-3-14.7s-9.6,10.3-9.9,17 c0,0-8.4-0.6-11-7.4c-1-2.5,1.4-9.1,2.1-12.2c0,0-6.5,7.9-9.4,22.5c0,0,0.6,8.8,1.1,10c0,0,3.5-14.8,4.9-17.7 c0,0-0.3,33.3,13.6,46.7c0,0-3.7-18.6-2.6-21l9.4-18.6c0,0,2.1,10.5,3.1,12.3l13.9-33.1L164.6,138z"/>',
                        '<path opacity="0.16" d="M253.3,155.9c0.8,4.4,8.1,12.1,13.1,11.7l1.6,11c0,0-5.2-3.9-14.7-19.9 V155.9z"/>',
                        '<path opacity="0.16" d="M237.6,139.4c0,0,4.4,3,13.9,21.7c0,0-4.3,12-4.6,12.4 C246.6,173.9,248.5,162.8,237.6,139.4z"/>',
                        '<path opacity="0.17" d="M221,136.7c0,0,5.2,4,14.4,23c0,0-1.2,4.6-3.1,8.9 C227.7,152.4,227.1,149.9,221,136.7z"/>',
                        '<path opacity="0.2" d="M272.1,152.6c-2.4,8.1-3.6,13.8-4.9,17.9c0,0,1.3,12.8,2.1,22.2 c4.7-8.4,5.4-8.8,5.4-9c-0.1-0.5,3.6,11.2-0.7,25.9c1.6,1,13.3-16.9,11.9-20.6c-1-2.5-0.4,19.8-4.3,22.8c0,0,6.4-2.2,9-7.9 c0,0,6.1-7,9.9-10.7c0,0,3.9-1,6.8,8.2l2.8-6.9c0,0,0.1,13.4-1.3,16.1c0,0,10.5-28.2,7.9-52.9c0,0,4.7,8.3,4.9,17.1 c0.1,8.8,1.7-8.6,0.2-17.8c0,0-6.5-13.9-8.2-15.4c0,0,2.2,14.9,1.3,18.4c0,0-8.2-15.1-11.4-17.3c0,0,1.2,41-1.6,46.1 c0,0-6.8-22.7-11.4-26.5c0,0-1.8,15.7-5,22.9C283.7,183,280.5,166.7,272.1,152.6z"/>'
                    ),
                    abi.encodePacked(
                        '<path opacity="0.14" d="M198.2,115.2c-0.9-3.9,3.2-35.1,34.7-36C227.6,78.5,198.9,99.8,198.2,115.2z"/>',
                        '<g opacity="0.76">',
                        '<path fill="#FFFFFF" d="M153,105.9c0,0-12,15.3-14.7,23.2"/>',
                        '<path fill="#FFFFFF" d="M126.5,125.9c0,0,9.5-20.6,23.5-27.7"/>',
                        '<path fill="#FFFFFF" d="M297.2,121.6c0,0-9.5-20.6-23.5-27.7"/>',
                        '<path fill="#FFFFFF" d="M241.9,109.4c0,0,10.9,19.9,11.6,23.6s3.7-5.5-10.6-23.6"/>',
                        '<path fill="#FFFFFF" d="M155.1,117.3c0,0-10.9,19.9-11.6,23.6s-3.7-5.5,10.6-23.6"/>',
                        '<path fill="#FFFFFF" d="M256.1,101.5c0,0,21.1,25.4,22,27.4c0.9,2-4.9-23.8-12.9-29.5c0,0,9.5,20.7,9.9,21.9 C275.4,122.5,262.2,103.6,256.1,101.5z"/>',
                        '<path fill="#FFFFFF" d="M230,138.5c0,0-12.9-24.9-14.1-26.4c-1.2-1.4,18.2,11.9,19.3,20.2c0,0-11.9-13-12.7-13.7 C221.8,117.9,230.9,133,230,138.5z"/>',
                        '<path fill="#FFFFFF" d="M167,136.6c0,0,15.5-24.5,17-25.8c1.5-1.2-19.1,10.6-21.6,18.8c0,0,15-13.5,15.8-14.2 C179.2,114.8,166.8,130.9,167,136.6z"/>',
                        "</g>"
                    )
                )
            );
    }

    /// @dev Generate mohawk with the given color
    function spike(string memory hairsColor) private pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "<path fill='#",
                    hairsColor,
                    "' d='M287.3,207.1c0,0-0.4-17.7-3.4-20.6c-3.1-2.9-7.3-8.7-7.3-8.7s0.6-24.8-2.9-31.8c-3.6-7-3.9-24.3-35-23.6c-30.3,0.7-42.5,5.4-42.5,5.4s-14.2-8.2-43-3.8c-19.3,4.9-17.2,50.1-17.2,50.1s-5.6,9.5-6.2,14.8c-0.6,5.3-0.3,8.3-0.3,8.3c0.9-0.2-19.1-126.3,86.7-126.8c108.4-0.3,87.1,121.7,85.1,122.4C294.5,191.6,293.7,198,287.3,207.1z'/>",
                    '<path fill-rule="evenodd" clip-rule="evenodd" fill="#212121" stroke="#000000" stroke-miterlimit="10" d="M196,124.6c0,0-30.3-37.5-20.6-77.7c0,0,0.7,18,12,25.1c0,0-8.6-13.4-0.3-33.4c0,0,2.7,15.8,10.7,23.4c0,0-2.7-18.4,2.2-29.6c0,0,9.7,23.2,13.9,26.3c0,0-6.5-17.2,5.4-27.7c0,0-0.8,18.6,9.8,25.4c0,0-2.7-11,4-18.9c0,0,1.2,25.1,6.6,29.4c0,0-2.7-12,2.1-20c0,0,6,24,8.6,28.5c-9.1-2.6-17.9-3.2-26.6-3C223.7,72.3,198,80.8,196,124.6z"/>',
                    crop()
                )
            );
    }

    function shortHairs(string memory hairsColor) private pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "<path fill='#",
                    hairsColor,
                    "' d='M287.3,207.1c0,0-0.4-17.7-3.4-20.6c-3.1-2.9-7.3-8.7-7.3-8.7s0.6-24.8-2.9-31.8c-3.6-7-3.9-24.3-35-23.6c-30.3,0.7-42.5,5.4-42.5,5.4s-14.2-8.2-43-3.8c-19.3,4.9-17.2,50.1-17.2,50.1s-5.6,9.5-6.2,14.8c-0.6,5.3-0.3,8.3-0.3,8.3c0.9-0.2-19.1-126.3,86.7-126.8c108.4-0.3,87.1,121.7,85.1,122.4C294.5,191.6,293.7,198,287.3,207.1z'/>",
                    '<path fill="#212121" stroke="#000000" stroke-miterlimit="10" d="M134.9,129.3c1-8.7,2.8-19.9,2.6-24.1 c1.1,2,4.4,6.1,4.7,6.9c2-15.1,3.9-18.6,6.6-28.2c0.1,5.2,0.4,6.1,4.6,11.9c0.1-7,4.5-17.6,8.8-24.3c0.6,3,4,8.2,5.8,10.7 c2.4-7,8.6-13.4,14.5-17.9c-0.3,3.4-0.1,6.8,0.7,10.1c4.9-5.1,7.1-8.7,15.6-15.4c-0.2,4.5,1.8,9,5.1,12c4.1-3.7,7.7-8,10.6-12.7 c0.6,3.7,1.4,7.3,2.5,10.8c2.6-4.6,7.9-8.4,12.4-11.3c1.5,3.5,1.3,11,5.9,11.7c7.1,1.1,10-3.3,11.4-10.1 c2.2,6.6,4.8,12.5,9.4,17.7c4.2,0.5,5.7-5.6,4.2-9c4.2,5.8,8.4,11.6,12.5,17.4c0.7-2.9,0.9-5.9,0.6-8.8 c3.4,7.6,9.1,16.7,13.6,23.6c0-1.9,1.8-8.5,1.8-10.4c2.6,7.3,7.7,17.9,10.3,36.6c0.2,1.1-23.8,7.5-28.8,10.1 c-1.2-2.3-2.2-4.3-6.2-8c-12.1-5.7-35.6-7.9-54.5-2.2c-16.3,4.8-21.5-2.3-31.3-3.1c-11.8-1.8-31.1-1.7-36.2,10.7 C139.6,133.6,137.9,132.2,134.9,129.3z"/>',
                    '<polygon fill="#212121" points="270.7,138.4 300.2,129 300.7,131.1 271.3,139.9"/>',
                    '<polygon fill="#212121" points="141.1,137 134,131.7 133.8,132.9 140.8,137.7 "/>',
                    crop()
                )
            );
    }

    /// @dev Generate crop SVG
    function crop() private pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<g id="Light" opacity="0.14">',
                    '<ellipse transform="matrix(0.7071 -0.7071 0.7071 0.7071 0.1603 226.5965)" fill="#FFFFFF" cx="273.6" cy="113.1" rx="1.4" ry="5.3"/>',
                    '<ellipse transform="matrix(0.5535 -0.8328 0.8328 0.5535 32.0969 254.4865)" fill="#FFFFFF" cx="253.4" cy="97.3" rx="4.2" ry="16.3"/>',
                    "</g>",
                    '<path opacity="0.05" fill-rule="evenodd" clip-rule="evenodd" d="M276.4,163.7c0,0,0.2-1.9,0.2,14.1c0,0,6.5,7.5,8.5,11s2.6,17.8,2.6,17.8l7-11.2c0,0,1.8-3.2,6.6-2.6c0,0,5.6-13.1,2.2-42.2C303.5,150.6,294.2,162.1,276.4,163.7z"/>',
                    '<path opacity="0.1" fill-rule="evenodd" clip-rule="evenodd" d="M129.2,194.4c0,0-0.7-8.9,6.8-20.3c0,0-0.2-21.2,1.3-22.9c-3.7,0-6.7-0.5-7.7-2.4C129.6,148.8,125.8,181.5,129.2,194.4z"/>'
                )
            );
    }

    /// @dev Generate monk SVG
    function monk() private pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<path opacity="0.36" fill="#6E5454" stroke="#8A8A8A" stroke-width="0.5" stroke-miterlimit="10" d="M286.8,206.8c0,0,0.1-17.4-2.9-20.3c-3.1-2.9-7.3-8.7-7.3-8.7s0.6-24.8-2.9-31.8c-3.6-7-3.9-24.3-35-23.6c-30.3,0.7-42.5,5.4-42.5,5.4s-14.2-8.2-43-3.8c-19.3,4.9-17.2,50.1-17.2,50.1s-5.6,9.5-6.2,14.8c-0.6,5.3-0.3,8.3-0.3,8.3S110.3,72.1,216.1,70.4c108.4-1.7,87.1,121.7,85.1,122.4C294.7,190.1,293.2,197.7,286.8,206.8z"/>',
                    '<g id="Bald" opacity="0.33">',
                    '<ellipse transform="matrix(0.7071 -0.7071 0.7071 0.7071 0.1603 226.5965)" fill="#FFFFFF" cx="273.6" cy="113.1" rx="1.4" ry="5.3"/>',
                    '<ellipse transform="matrix(0.5535 -0.8328 0.8328 0.5535 32.0969 254.4865)" fill="#FFFFFF" cx="253.4" cy="97.3" rx="4.2" ry="16.3"/>',
                    "</g>"
                )
            );
    }

    /// @notice Return the hair cut name of the given id
    /// @param id The hair Id
    function getItemNameById(uint8 id) public pure returns (string memory name) {
        name = "";
        if (id == 1) {
            name = "Classic Brown";
        } else if (id == 2) {
            name = "Classic Black";
        } else if (id == 3) {
            name = "Classic Gray";
        } else if (id == 4) {
            name = "Classic White";
        } else if (id == 5) {
            name = "Classic Blue";
        } else if (id == 6) {
            name = "Classic Yellow";
        } else if (id == 7) {
            name = "Classic Pink";
        } else if (id == 8) {
            name = "Classic Red";
        } else if (id == 9) {
            name = "Classic Purple";
        } else if (id == 10) {
            name = "Classic Green";
        } else if (id == 11) {
            name = "Classic Saiki";
        } else if (id == 12) {
            name = "Classic Brown";
        } else if (id == 13) {
            name = "Classic 2 Black";
        } else if (id == 14) {
            name = "Classic 2 Gray";
        } else if (id == 15) {
            name = "Classic 2 White";
        } else if (id == 16) {
            name = "Classic 2 Blue";
        } else if (id == 17) {
            name = "Classic 2 Yellow";
        } else if (id == 18) {
            name = "Classic 2 Pink";
        } else if (id == 19) {
            name = "Classic 2 Red";
        } else if (id == 20) {
            name = "Classic 2 Purple";
        } else if (id == 21) {
            name = "Classic 2 Green";
        } else if (id == 22) {
            name = "Classic 2 Saiki";
        } else if (id == 23) {
            name = "Short Black";
        } else if (id == 24) {
            name = "Short Blue";
        } else if (id == 25) {
            name = "Short Pink";
        } else if (id == 26) {
            name = "Short White";
        } else if (id == 27) {
            name = "Spike Black";
        } else if (id == 28) {
            name = "Spike Blue";
        } else if (id == 29) {
            name = "Spike Pink";
        } else if (id == 30) {
            name = "Spike White";
        } else if (id == 31) {
            name = "Monk";
        } else if (id == 32) {
            name = "Nihon";
        } else if (id == 33) {
            name = "Bald";
        }
    }

    /// @dev The base SVG for the hair
    function base(string memory children) private pure returns (string memory) {
        return string(abi.encodePacked('<g id="Hair">', children, "</g>"));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

pragma abicoder v2;

import "base64-sol/base64.sol";

/// @title Mouth SVG generator
library MouthDetail {
    /// @dev Mouth N°1 => Neutral
    function item_1() public pure returns (string memory) {
        return
            base(
                string(
                    abi.encodePacked(
                        '<path d="M178.3,262.7c3.3-0.2,6.6-0.1,9.9,0c3.3,0.1,6.6,0.3,9.8,0.8c-3.3,0.3-6.6,0.3-9.9,0.2C184.8,263.6,181.5,263.3,178.3,262.7z"/>',
                        '<path d="M201.9,263.4c1.2-0.1,2.3-0.1,3.5-0.2l3.5-0.2l6.9-0.3c2.3-0.1,4.6-0.2,6.9-0.4c1.2-0.1,2.3-0.2,3.5-0.3l1.7-0.2c0.6-0.1,1.1-0.2,1.7-0.2c-2.2,0.8-4.5,1.1-6.8,1.4s-4.6,0.5-7,0.6c-2.3,0.1-4.6,0.2-7,0.1C206.6,263.7,204.3,263.6,201.9,263.4z"/>',
                        '<path d="M195.8,271.8c0.8,0.5,1.8,0.8,2.7,1s1.8,0.4,2.7,0.5s1.8,0,2.8-0.1c0.9-0.1,1.8-0.5,2.8-0.8c-0.7,0.7-1.6,1.3-2.6,1.6c-1,0.3-2,0.5-3,0.4s-2-0.3-2.9-0.8C197.3,273.2,196.4,272.7,195.8,271.8z"/>'
                    )
                )
            );
    }

    /// @dev Mouth N°2 => Smile
    function item_2() public pure returns (string memory) {
        return
            base(
                string(
                    abi.encodePacked(
                        '<path d="M178.2,259.6c1.6,0.5,3.3,0.9,4.9,1.3c1.6,0.4,3.3,0.8,4.9,1.1c1.6,0.4,3.3,0.6,4.9,0.9c1.7,0.3,3.3,0.4,5,0.6c-1.7,0.2-3.4,0.3-5.1,0.2c-1.7-0.1-3.4-0.3-5.1-0.7C184.5,262.3,181.2,261.2,178.2,259.6z"/>',
                        '<path d="M201.9,263.4l7-0.6c2.3-0.2,4.7-0.4,7-0.7c2.3-0.2,4.6-0.6,6.9-1c0.6-0.1,1.2-0.2,1.7-0.3l1.7-0.4l1.7-0.5l1.6-0.7c-0.5,0.3-1,0.7-1.5,0.9l-1.6,0.8c-1.1,0.4-2.2,0.8-3.4,1.1c-2.3,0.6-4.6,1-7,1.3s-4.7,0.4-7.1,0.5C206.7,263.6,204.3,263.6,201.9,263.4z"/>',
                        '<path d="M195.8,271.8c0.8,0.5,1.8,0.8,2.7,1s1.8,0.4,2.7,0.5s1.8,0,2.8-0.1c0.9-0.1,1.8-0.5,2.8-0.8c-0.7,0.7-1.6,1.3-2.6,1.6c-1,0.3-2,0.5-3,0.4s-2-0.3-2.9-0.8C197.3,273.2,196.4,272.7,195.8,271.8z"/>'
                    )
                )
            );
    }

    /// @dev Mouth N°3 => Sulk
    function item_3() public pure returns (string memory) {
        return
            base(
                string(
                    abi.encodePacked(
                        '<path fill="none" stroke="#000000" stroke-miterlimit="10" d="M179.2,263.2c0,0,24.5,3.1,43.3-0.6"/>',
                        '<path fill="none" stroke="#000000" stroke-miterlimit="10" d="M176.7,256.8c0,0,6.7,6.8-0.6,11"/>',
                        '<path fill="none" stroke="#000000" stroke-miterlimit="10" d="M225.6,256.9c0,0-6.5,7,1,11"/>'
                    )
                )
            );
    }

    /// @dev Mouth N°4 => Poker
    function item_4() public pure returns (string memory) {
        return
            base(
                string(
                    abi.encodePacked(
                        '<line id="Poker" fill="none" stroke="#000000" stroke-linecap="round" stroke-miterlimit="10" x1="180" y1="263" x2="226" y2="263"/>'
                    )
                )
            );
    }

    /// @dev Mouth N°5 => Angry
    function item_5() public pure returns (string memory) {
        return
            base(
                string(
                    abi.encodePacked(
                        '<path fill="#FFFFFF" stroke="#000000" stroke-linecap="round" stroke-miterlimit="10" d="M207.5,257.1c-7,1.4-17.3,0.3-21-0.9c-4-1.2-7.7,3.1-8.6,7.2c-0.5,2.5-1.2,7.4,3.4,10.1c5.9,2.4,5.6,0.1,9.2-1.9c3.4-2,10-1.1,15.3,1.9c5.4,3,13.4,2.2,17.9-0.4c2.9-1.7,3.3-7.6-4.2-14.1C217.3,257.2,215.5,255.5,207.5,257.1"/>',
                        '<path fill="#FFFFFF" stroke="#000000" stroke-linecap="round" stroke-miterlimit="10" d="M205.9,265.5l4.1-2.2c0,0,3.7,2.9,5,3s4.9-3.2,4.9-3.2l3.9,1.4"/>',
                        '<polyline fill="#FFFFFF" stroke="#000000" stroke-linecap="round" stroke-miterlimit="10" points="177.8,265.3 180.2,263.4 183.3,265.5 186,265.4"/>'
                    )
                )
            );
    }

    /// @dev Mouth N°6 => Big Smile
    function item_6() public pure returns (string memory) {
        return
            base(
                string(
                    abi.encodePacked(
                        '<path fill="#FFFFFF" stroke="#000000" stroke-miterlimit="10" d="M238.1,255.9c-26.1,4-68.5,0.3-68.5,0.3C170.7,256.3,199.6,296.4,238.1,255.9"/>',
                        '<path fill-rule="evenodd" clip-rule="evenodd" fill="#FFFFFF" stroke="#000000" stroke-linecap="round" stroke-miterlimit="10" d="M176.4,262.7c0,0,7.1,2.2,12,2.1"/>',
                        '<path fill-rule="evenodd" clip-rule="evenodd" fill="#FFFFFF" stroke="#000000" stroke-linecap="round" stroke-miterlimit="10" d="M230.6,262.8c0,0-10.4,2.1-17.7,1.8"/>'
                    )
                )
            );
    }

    /// @dev Mouth N°7 => Evil
    function item_7() public pure returns (string memory) {
        return
            base(
                string(
                    abi.encodePacked(
                        '<path fill="#FFFFFF" stroke="#000000" stroke-miterlimit="10" d="M174.7,261.7c0,0,16.1-1.1,17.5-1.5s34.5,6.3,36.5,5.5s4.6-1.9,4.6-1.9s-14.1,8-43.6,7.9c0,0-3.9-0.7-4.7-1.8S177.1,262.1,174.7,261.7z"/>',
                        '<polyline fill="none" stroke="#000000" stroke-miterlimit="10" points="181.6,266.7 185.5,265.3 189.1,266.5 190.3,265.9"/>',
                        '<polyline fill="none" stroke="#000000" stroke-miterlimit="10" points="198.2,267 206.3,266.2 209.6,267.7 213.9,266.3 216.9,267.5 225.3,267"/>'
                    )
                )
            );
    }

    /// @dev Mouth N°8 => Tongue
    function item_8() public pure returns (string memory) {
        return
            base(
                string(
                    abi.encodePacked(
                        '<path fill="#FF155D" d="M206.5,263.1c0,0,4,11.2,12.5,9.8c11.3-1.8,6.3-11.8,6.3-11.8L206.5,263.1z"/>',
                        '<line fill="none" stroke="#73093E" stroke-miterlimit="10" x1="216.7" y1="262.5" x2="218.5" y2="267.3"/>',
                        '<path fill="none" stroke="#000000" stroke-linecap="round" stroke-miterlimit="10" d="M201.9,263.4c0,0,20.7,0.1,27.7-4.3"/>',
                        '<path fill="none" stroke="#000000" stroke-linecap="round" stroke-miterlimit="10" d="M178.2,259.6c0,0,9.9,4.2,19.8,3.9"/>'
                    )
                )
            );
    }

    /// @dev Mouth N°9 => Drool
    function item_9() public pure returns (string memory) {
        return
            base(
                string(
                    abi.encodePacked(
                        '<path fill="#FEBCA6" stroke="#000000" stroke-width="0.5" stroke-miterlimit="10" d="M190.4,257.5c2.5,0.6,5.1,0.8,7.7,0.5l17-2.1c0,0,13.3-1.8,12,3.6c-1.3,5.4-2.4,9.3-5.3,9.8c0,0,3.2,9.7-2.9,9c-3.7-0.4-2.4-7.7-2.4-7.7s-15.4,4.6-33.1-1.7c-1.8-0.6-3.6-2.6-4.4-3.9c-5.1-7.7-2-9.5-2-9.5S175.9,253.8,190.4,257.5z"/>'
                    )
                )
            );
    }

    /// @dev Mouth N°10 => O
    function item_10() public pure returns (string memory) {
        return
            base(
                string(
                    abi.encodePacked(
                        '<ellipse transform="matrix(0.9952 -9.745440e-02 9.745440e-02 0.9952 -24.6525 20.6528)" opacity="0.84" fill-rule="evenodd" clip-rule="evenodd" cx="199.1" cy="262.7" rx="3.2" ry="4.6"/>'
                    )
                )
            );
    }

    /// @dev Mouth N°11 => Dubu
    function item_11() public pure returns (string memory) {
        return
            base(
                string(
                    abi.encodePacked(
                        '<path fill="none" stroke="#000000" stroke-width="0.75" stroke-linecap="round" stroke-miterlimit="10" d="M204.2,262c-8.9-7-25.1-3.5-4.6,6.6c-22-3.8-3.2,11.9,4.8,6"/>'
                    )
                )
            );
    }

    /// @dev Mouth N°12 => Stitch
    function item_12() public pure returns (string memory) {
        return
            base(
                string(
                    abi.encodePacked(
                        '<g opacity="0.84" fill-rule="evenodd" clip-rule="evenodd">',
                        '<ellipse transform="matrix(0.9994 -3.403963e-02 3.403963e-02 0.9994 -8.8992 6.2667)" cx="179.6" cy="264.5" rx="2.3" ry="4.3"/>',
                        '<ellipse transform="matrix(0.9996 -2.866329e-02 2.866329e-02 0.9996 -7.485 5.0442)"  cx="172.2" cy="263.6" rx="1.5" ry="2.9"/>',
                        '<ellipse transform="matrix(0.9996 -2.866329e-02 2.866329e-02 0.9996 -7.4594 6.6264)" cx="227.4" cy="263.5" rx="1.5" ry="2.9"/>',
                        '<ellipse transform="matrix(0.9994 -3.403963e-02 3.403963e-02 0.9994 -8.8828 7.6318)"  cx="219.7" cy="264.7" rx="2.5" ry="4.7"/>',
                        '<ellipse transform="matrix(0.9994 -3.403963e-02 3.403963e-02 0.9994 -8.9179 6.57)" cx="188.5" cy="265.2" rx="2.9" ry="5.4"/>',
                        '<ellipse transform="matrix(0.9994 -3.403963e-02 3.403963e-02 0.9994 -8.9153 7.3225)" cx="210.6" cy="265.5" rx="2.9" ry="5.4"/>',
                        '<ellipse transform="matrix(0.9992 -3.983298e-02 3.983298e-02 0.9992 -10.4094 8.1532)" cx="199.4" cy="265.3" rx="4" ry="7.2"/>',
                        "</g>"
                    )
                )
            );
    }

    /// @dev Mouth N°13 => Uwu
    function item_13() public pure returns (string memory) {
        return
            base(
                string(
                    abi.encodePacked(
                        '<polyline fill="#FFFFFF" stroke="#000000" stroke-width="0.5" stroke-miterlimit="10" points="212.7,262.9 216,266.5 217.5,261.7"/>',
                        '<path fill="none" stroke="#000000" stroke-width="0.75" stroke-linecap="round" stroke-linejoin="round" stroke-miterlimit="10" d="M176.4,256c0,0,5.7,13.4,23.1,4.2"/>',
                        '<path fill="none" stroke="#000000" stroke-width="0.75" stroke-linecap="round" stroke-linejoin="round" stroke-miterlimit="10" d="M224.7,254.8c0,0-9.5,15-25.2,5.4"/>'
                    )
                )
            );
    }

    /// @dev Mouth N°14 => Monster
    function item_14() public pure returns (string memory) {
        return
            base(
                string(
                    abi.encodePacked(
                        '<path fill="#FFFFFF" stroke="#000000" stroke-width="0.75" stroke-miterlimit="10" d="M161.4,255c0,0,0.5,0.1,1.3,0.3 c4.2,1,39.6,8.5,84.8-0.7C247.6,254.7,198.9,306.9,161.4,255z"/>',
                        '<polyline fill="none" stroke="#000000" stroke-width="0.75" stroke-linejoin="round" stroke-miterlimit="10" points="165.1,258.9 167,256.3 170.3,264.6 175.4,257.7 179.2,271.9 187,259.1 190.8,276.5 197,259.7 202.1,277.5 207.8,259.1 213.8,275.4 217.9,258.7 224.1,271.2 226.5,257.9 232.7,266.2 235.1,256.8 238.6,262.1 241.3,255.8 243.8,257.6"/>'
                    )
                )
            );
    }

    /// @notice Return the mouth name of the given id
    /// @param id The mouth Id
    function getItemNameById(uint8 id) public pure returns (string memory name) {
        name = "";
        if (id == 1) {
            name = "Neutral";
        } else if (id == 2) {
            name = "Smile";
        } else if (id == 3) {
            name = "Sulk";
        } else if (id == 4) {
            name = "Poker";
        } else if (id == 5) {
            name = "Angry";
        } else if (id == 6) {
            name = "Big Smile";
        } else if (id == 7) {
            name = "Evil";
        } else if (id == 8) {
            name = "Tongue";
        } else if (id == 9) {
            name = "Drool";
        } else if (id == 10) {
            name = "O";
        } else if (id == 11) {
            name = "Dubu";
        } else if (id == 12) {
            name = "Stitch";
        } else if (id == 13) {
            name = "Uwu";
        } else if (id == 14) {
            name = "Monster";
        }
    }

    /// @dev The base SVG for the mouth
    function base(string memory children) private pure returns (string memory) {
        return string(abi.encodePacked('<g id="Mouth">', children, "</g>"));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

pragma abicoder v2;

import "base64-sol/base64.sol";

/// @title Nose SVG generator
library NoseDetail {
    /// @dev Nose N°1 => Classic
    function item_1() public pure returns (string memory) {
        return "";
    }

    /// @dev Nose N°2 => Bleeding
    function item_2() public pure returns (string memory) {
        return
            base(
                string(
                    abi.encodePacked(
                        '<path fill="#E90000" d="M205.8,254.1C205.8,254.1,205.9,254.1,205.8,254.1c0.1,0,0.1,0.1,0.1,0.1c0,0.2,0,0.5-0.2,0.7c-0.1,0.1-0.3,0.1-0.4,0.1c-0.4,0-0.8,0.1-1.2,0.1c-0.2,0-0.7,0.2-0.8,0s0.1-0.4,0.2-0.5c0.3-0.2,0.7-0.2,1-0.3C204.9,254.3,205.4,254.1,205.8,254.1z"/>',
                        '<path fill="#E90000" d="M204.3,252.8c0.3-0.1,0.6-0.2,0.9-0.1c0.1,0.2,0.1,0.4,0.2,0.6c0,0.1,0,0.1,0,0.2c0,0.1-0.1,0.1-0.2,0.1c-0.7,0.2-1.4,0.3-2.1,0.5c-0.2,0-0.3,0.1-0.4-0.1c0-0.1-0.1-0.2,0-0.3c0.1-0.2,0.4-0.3,0.6-0.4C203.6,253.1,203.9,252.9,204.3,252.8z"/>',
                        '<path fill="#FF0000" d="M204.7,240.2c0.3,1.1,0.1,2.3-0.1,3.5c-0.3,2-0.5,4.1,0,6.1c0.1,0.4,0.3,0.9,0.2,1.4c-0.2,0.9-1.1,1.3-2,1.6c-0.1,0-0.2,0.1-0.4,0.1c-0.3-0.1-0.4-0.5-0.4-0.8c-0.1-1.9,0.5-3.9,0.8-5.8c0.3-1.7,0.3-3.2-0.1-4.8c-0.1-0.5-0.3-0.9,0.1-1.3C203.4,239.7,204.6,239.4,204.7,240.2z"/>'
                    )
                )
            );
    }

    /// @notice Return the nose name of the given id
    /// @param id The nose Id
    function getItemNameById(uint8 id) public pure returns (string memory name) {
        name = "";
        if (id == 1) {
            name = "Classic";
        } else if (id == 2) {
            name = "Bleeding";
        }
    }

    /// @dev The base SVG for the Nose
    function base(string memory children) private pure returns (string memory) {
        return string(abi.encodePacked('<g id="Nose bonus">', children, "</g>"));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

pragma abicoder v2;

import "base64-sol/base64.sol";
import "./constants/Colors.sol";

/// @title Eyes SVG generator
library EyesDetail {
    /// @dev Eyes N°1 => Color White/Brown
    function item_1() public pure returns (string memory) {
        return eyesNoFillAndColorPupils(Colors.WHITE, Colors.BROWN);
    }

    /// @dev Eyes N°2 => Color White/Gray
    function item_2() public pure returns (string memory) {
        return eyesNoFillAndColorPupils(Colors.WHITE, Colors.GRAY);
    }

    /// @dev Eyes N°3 => Color White/Blue
    function item_3() public pure returns (string memory) {
        return eyesNoFillAndColorPupils(Colors.WHITE, Colors.BLUE);
    }

    /// @dev Eyes N°4 => Color White/Green
    function item_4() public pure returns (string memory) {
        return eyesNoFillAndColorPupils(Colors.WHITE, Colors.GREEN);
    }

    /// @dev Eyes N°5 => Color White/Black
    function item_5() public pure returns (string memory) {
        return eyesNoFillAndColorPupils(Colors.WHITE, Colors.BLACK_DEEP);
    }

    /// @dev Eyes N°6 => Color White/Yellow
    function item_6() public pure returns (string memory) {
        return eyesNoFillAndColorPupils(Colors.WHITE, Colors.YELLOW);
    }

    /// @dev Eyes N°7 => Color White/Red
    function item_7() public pure returns (string memory) {
        return eyesNoFillAndColorPupils(Colors.WHITE, Colors.RED);
    }

    /// @dev Eyes N°8 => Color White/Purple
    function item_8() public pure returns (string memory) {
        return eyesNoFillAndColorPupils(Colors.WHITE, Colors.PURPLE);
    }

    /// @dev Eyes N°9 => Color White/Pink
    function item_9() public pure returns (string memory) {
        return eyesNoFillAndColorPupils(Colors.WHITE, Colors.PINK);
    }

    /// @dev Eyes N°10 => Color White/White
    function item_10() public pure returns (string memory) {
        return eyesNoFillAndColorPupils(Colors.WHITE, Colors.WHITE);
    }

    /// @dev Eyes N°11 => Color Black/Blue
    function item_11() public pure returns (string memory) {
        return eyesNoFillAndColorPupils(Colors.BLACK, Colors.BLUE);
    }

    /// @dev Eyes N°12 => Color Black/Yellow
    function item_12() public pure returns (string memory) {
        return eyesNoFillAndColorPupils(Colors.BLACK, Colors.YELLOW);
    }

    /// @dev Eyes N°13 => Color Black/White
    function item_13() public pure returns (string memory) {
        return eyesNoFillAndColorPupils(Colors.BLACK, Colors.WHITE);
    }

    /// @dev Eyes N°14 => Color Black/Red
    function item_14() public pure returns (string memory) {
        return eyesNoFillAndColorPupils(Colors.BLACK, Colors.RED);
    }

    /// @dev Eyes N°15 => Blank White/White
    function item_15() public pure returns (string memory) {
        return eyesNoFillAndBlankPupils(Colors.WHITE, Colors.WHITE);
    }

    /// @dev Eyes N°16 => Blank Black/White
    function item_16() public pure returns (string memory) {
        return eyesNoFillAndBlankPupils(Colors.BLACK_DEEP, Colors.WHITE);
    }

    /// @dev Eyes N°17 => Shine (no-fill)
    function item_17() public pure returns (string memory) {
        return
            base(
                string(
                    abi.encodePacked(
                        eyesNoFill(Colors.WHITE),
                        '<path fill="#FFEE00" stroke="#000000" stroke-width="0.5" stroke-miterlimit="10" d="M161.4,195.1c1.4,7.4,1.4,7.3,8.8,8.8 c-7.4,1.4-7.3,1.4-8.8,8.8c-1.4-7.4-1.4-7.3-8.8-8.8C160,202.4,159.9,202.5,161.4,195.1z"/>',
                        '<path fill="#FFEE00" stroke="#000000" stroke-width="0.5" stroke-miterlimit="10" d="M236.1,194.9c1.4,7.4,1.4,7.3,8.8,8.8 c-7.4,1.4-7.3,1.4-8.8,8.8c-1.4-7.4-1.4-7.3-8.8-8.8C234.8,202.3,234.7,202.3,236.1,194.9z"/>'
                    )
                )
            );
    }

    /// @dev Eyes N°18 => Stun (no-fill)
    function item_18() public pure returns (string memory) {
        return
            base(
                string(
                    abi.encodePacked(
                        eyesNoFill(Colors.WHITE),
                        '<path d="M233.6,205.2c0.2-0.8,0.6-1.7,1.3-2.3c0.4-0.3,0.9-0.5,1.3-0.4c0.5,0.1,0.9,0.4,1.2,0.8c0.5,0.8,0.6,1.8,0.6,2.7c0,0.9-0.4,1.9-1.1,2.6c-0.7,0.7-1.7,1.1-2.7,1c-1-0.1-1.8-0.7-2.5-1.2c-0.7-0.5-1.4-1.2-1.9-2c-0.5-0.8-0.8-1.8-0.7-2.8c0.1-1,0.5-1.9,1.1-2.6c0.6-0.7,1.4-1.3,2.2-1.7c1.7-0.8,3.6-1,5.3-0.6c0.9,0.2,1.8,0.5,2.5,1.1c0.7,0.6,1.2,1.5,1.3,2.4c0.3,1.8-0.3,3.7-1.4,4.9c1-1.4,1.4-3.2,1-4.8c-0.2-0.8-0.6-1.5-1.3-2c-0.6-0.5-1.4-0.8-2.2-0.9c-1.6-0.2-3.4,0-4.8,0.7c-1.4,0.7-2.7,2-2.8,3.5c-0.2,1.5,0.9,3,2.2,4c0.7,0.5,1.3,1,2.1,1.1c0.7,0.1,1.5-0.2,2.1-0.7c0.6-0.5,0.9-1.3,1-2.1c0.1-0.8,0-1.7-0.4-2.3c-0.2-0.3-0.5-0.6-0.8-0.7c-0.4-0.1-0.8,0-1.1,0.2C234.4,203.6,233.9,204.4,233.6,205.2z"/>',
                        '<path d="M160.2,204.8c0.7-0.4,1.6-0.8,2.5-0.7c0.4,0,0.9,0.3,1.2,0.7c0.3,0.4,0.3,0.9,0.2,1.4c-0.2,0.9-0.8,1.7-1.5,2.3c-0.7,0.6-1.6,1.1-2.6,1c-1,0-2-0.4-2.6-1.2c-0.7-0.8-0.8-1.8-1-2.6c-0.1-0.9-0.1-1.8,0.1-2.8c0.2-0.9,0.7-1.8,1.5-2.4c0.8-0.6,1.7-1,2.7-1c0.9-0.1,1.9,0.1,2.7,0.4c1.7,0.6,3.2,1.8,4.2,3.3c0.5,0.7,0.9,1.6,1,2.6c0.1,0.9-0.2,1.9-0.8,2.6c-1.1,1.5-2.8,2.4-4.5,2.5c1.7-0.3,3.3-1.3,4.1-2.7c0.4-0.7,0.6-1.5,0.5-2.3c-0.1-0.8-0.5-1.5-1-2.2c-1-1.3-2.4-2.4-3.9-2.9c-1.5-0.5-3.3-0.5-4.5,0.5c-1.2,1-1.5,2.7-1.3,4.3c0.1,0.8,0.2,1.6,0.7,2.2c0.4,0.6,1.2,0.9,1.9,1c0.8,0,1.5-0.2,2.2-0.8c0.6-0.5,1.2-1.2,1.4-1.9c0.1-0.4,0.1-0.8-0.1-1.1c-0.2-0.3-0.5-0.6-0.9-0.6C161.9,204.2,161,204.4,160.2,204.8z"/>'
                    )
                )
            );
    }

    /// @dev Eyes N°19 => Squint (no-fill)
    function item_19() public pure returns (string memory) {
        return
            base(
                string(
                    abi.encodePacked(
                        eyesNoFill(Colors.WHITE),
                        '<path d="M167.3,203.7c0.1,7.7-12,7.7-11.9,0C155.3,196,167.4,196,167.3,203.7z"/>',
                        '<path d="M244.8,205.6c-1.3,7.8-13.5,5.6-12-2.2C234.2,195.6,246.4,197.9,244.8,205.6z"/>'
                    )
                )
            );
    }

    /// @dev Eyes N°20 => Shock (no-fill)
    function item_20() public pure returns (string memory) {
        return
            base(
                string(
                    abi.encodePacked(
                        eyesNoFill(Colors.WHITE),
                        '<path fill-rule="evenodd" clip-rule="evenodd" d="M163.9,204c0,2.7-4.2,2.7-4.1,0C159.7,201.3,163.9,201.3,163.9,204z"/>',
                        '<path fill-rule="evenodd" clip-rule="evenodd" d="M236.7,204c0,2.7-4.2,2.7-4.1,0C232.5,201.3,236.7,201.3,236.7,204z"/>'
                    )
                )
            );
    }

    /// @dev Eyes N°21 => Cat (no-fill)
    function item_21() public pure returns (string memory) {
        return
            base(
                string(
                    abi.encodePacked(
                        eyesNoFill(Colors.WHITE),
                        '<path d="M238.4,204.2c0.1,13.1-4.5,13.1-4.5,0C233.8,191.2,238.4,191.2,238.4,204.2z"/>',
                        '<path d="M164.8,204.2c0.1,13-4.5,13-4.5,0C160.2,191.2,164.8,191.2,164.8,204.2z"/>'
                    )
                )
            );
    }

    /// @dev Eyes N°22 => Ether (no-fill)
    function item_22() public pure returns (string memory) {
        return
            base(
                string(
                    abi.encodePacked(
                        eyesNoFill(Colors.WHITE),
                        '<path d="M161.7,206.4l-4.6-2.2l4.6,8l4.6-8L161.7,206.4z"/>',
                        '<path d="M165.8,202.6l-4.1-7.1l-4.1,7.1l4.1-1.9L165.8,202.6z"/>',
                        '<path d="M157.9,203.5l3.7,1.8l3.8-1.8l-3.8-1.8L157.9,203.5z"/>',
                        '<path d="M236.1,206.6l-4.6-2.2l4.6,8l4.6-8L236.1,206.6z"/>',
                        '<path d="M240.2,202.8l-4.1-7.1l-4.1,7.1l4.1-1.9L240.2,202.8z"/>',
                        '<path d="M232.4,203.7l3.7,1.8l3.8-1.8l-3.8-1.8L232.4,203.7z"/>'
                    )
                )
            );
    }

    /// @dev Eyes N°23 => Feels
    function item_23() public pure returns (string memory) {
        return
            base(
                string(
                    abi.encodePacked(
                        '<path d="M251.1,201.4c0.7,0.6,1,2.2,1,2.7c-0.1-0.4-1.4-1.1-2.2-1.7c-0.2,0.1-0.4,0.4-0.6,0.5c0.5,0.7,0.7,2,0.7,2.5c-0.1-0.4-1.3-1.1-2.1-1.6c-2.7,1.7-6.4,3.2-11.5,3.7c-8.1,0.7-16.3-1.7-20.9-6.4c5.9,3.1,13.4,4.5,20.9,3.8c6.6-0.6,12.7-2.9,17-6.3C253.4,198.9,252.6,200.1,251.1,201.4z"/>',
                        '<path d="M250,205.6L250,205.6C250.1,205.9,250.1,205.8,250,205.6z"/>',
                        '<path d="M252.1,204.2L252.1,204.2C252.2,204.5,252.2,204.4,252.1,204.2z"/>',
                        '<path d="M162.9,207.9c-4.1-0.4-8-1.4-11.2-2.9c-0.7,0.3-3.1,1.4-3.3,1.9c0.1-0.6,0.3-2.2,1.3-2.8c0.1-0.1,0.2-0.1,0.3-0.1c-0.2-0.1-0.5-0.3-0.7-0.4c-0.8,0.4-3,1.3-3.2,1.9c0.1-0.6,0.3-2.2,1.3-2.8c0.1-0.1,0.3-0.1,0.5-0.1c-0.9-0.7-1.7-1.6-2.4-2.4c1.5,1.1,6.9,4.2,17.4,5.3c11.9,1.2,18.3-4,19.8-4.7C177.7,205.3,171.4,208.8,162.9,207.9z"/>',
                        '<path d="M148.5,207L148.5,207C148.5,207.1,148.5,207.2,148.5,207z"/>',
                        '<path d="M146.2,205.6L146.2,205.6C146.2,205.7,146.2,205.7,146.2,205.6z"/>'
                    )
                )
            );
    }

    /// @dev Eyes N°24 => Happy
    function item_24() public pure returns (string memory) {
        return
            base(
                string(
                    abi.encodePacked(
                        '<path d="M251.5,203.5c0.7-0.7,0.9-2.5,0.9-3.2c-0.1,0.5-1.3,1.4-2.2,1.9c-0.2-0.2-0.4-0.4-0.6-0.6c0.5-0.8,0.7-2.4,0.7-3 c-0.1,0.5-1.2,1.4-2.1,1.9c-2.6-1.9-6.2-3.8-11-4.3c-7.8-0.8-15.7,2-20.1,7.5c5.7-3.6,12.9-5.3,20.1-4.5 c6.4,0.8,12.4,2.9,16.5,6.9C253.3,205.1,252.3,204,251.5,203.5z"/>',
                        '<path d="M250.3,198.6L250.3,198.6C250.4,198.2,250.4,198.3,250.3,198.6z"/>',
                        '<path d="M252.4,200.3L252.4,200.3C252.5,199.9,252.5,200,252.4,200.3z"/>',
                        '<path d="M228.2,192.6c1.1-0.3,2.3-0.5,3.5-0.6c1.1-0.1,2.4-0.1,3.5,0s2.4,0.3,3.5,0.5s2.3,0.6,3.3,1.1l0,0 c-1.1-0.3-2.3-0.6-3.4-0.8c-1.1-0.3-2.3-0.4-3.4-0.5c-1.1-0.1-2.4-0.2-3.5-0.1C230.5,192.3,229.4,192.4,228.2,192.6L228.2,192.6z"/>',
                        '<path d="M224.5,193.8c-0.9,0.6-2,1.1-3,1.7c-0.9,0.6-2,1.2-3,1.7c0.4-0.4,0.8-0.8,1.2-1.1s0.9-0.7,1.4-0.9c0.5-0.3,1-0.6,1.5-0.8C223.3,194.2,223.9,193.9,224.5,193.8z"/>',
                        '<path d="M161.3,195.8c-3.7,0.4-7.2,1.6-10.1,3.5c-0.6-0.3-2.8-1.6-3-2.3c0.1,0.7,0.3,2.6,1.1,3.3c0.1,0.1,0.2,0.2,0.3,0.2 c-0.2,0.2-0.4,0.3-0.6,0.5c-0.7-0.4-2.7-1.5-2.9-2.2c0.1,0.7,0.3,2.6,1.1,3.3c0.1,0.1,0.3,0.2,0.4,0.2c-0.8,0.8-1.6,1.9-2.2,2.9 c1.3-1.4,6.3-5,15.8-6.3c10.9-1.4,16.7,4.7,18,5.5C174.8,198.9,169.1,194.8,161.3,195.8z"/>',
                        '<path d="M148.2,196.9L148.2,196.9C148.2,196.8,148.2,196.7,148.2,196.9z"/>',
                        '<path d="M146.1,198.6L146.1,198.6C146.1,198.5,146.1,198.4,146.1,198.6z"/>',
                        '<path d="M167.5,192.2c-1.1-0.2-2.3-0.3-3.5-0.3c-1.1,0-2.4,0-3.5,0.2c-1.1,0.1-2.3,0.3-3.4,0.5c-1.1,0.3-2.3,0.5-3.4,0.8 c2.1-0.9,4.3-1.5,6.7-1.7c1.1-0.1,2.4-0.1,3.5-0.1C165.3,191.7,166.4,191.9,167.5,192.2z"/>',
                        '<path d="M171.4,193.4c0.6,0.2,1.1,0.3,1.7,0.6c0.5,0.3,1,0.5,1.6,0.8c0.5,0.3,1,0.6,1.4,0.9c0.5,0.3,0.9,0.7,1.3,1 c-1-0.5-2.1-1.1-3-1.6C173.3,194.5,172.3,193.9,171.4,193.4z"/>'
                    )
                )
            );
    }

    /// @dev Eyes N°25 => Arrow
    function item_25() public pure returns (string memory) {
        return
            base(
                string(
                    abi.encodePacked(
                        '<path fill="none" stroke="#000000" stroke-width="1.5" stroke-linejoin="round" stroke-miterlimit="10" d="M251.4,192.5l-30.8,8 c10.9,1.9,20.7,5,29.5,9.1"/>',
                        '<path fill="none" stroke="#000000" stroke-width="1.5" stroke-linejoin="round" stroke-miterlimit="10" d="M149.4,192.5l30.8,8 c-10.9,1.9-20.7,5-29.5,9.1"/>'
                    )
                )
            );
    }

    /// @dev Eyes N°26 => Closed
    function item_26() public pure returns (string memory) {
        return
            base(
                string(
                    abi.encodePacked(
                        '<line fill="none" stroke="#000000" stroke-width="2" stroke-linecap="round" stroke-miterlimit="10" x1="216.3" y1="200.2" x2="259" y2="198.3"/>',
                        '<line fill="none" stroke="#000000" stroke-width="2" stroke-linecap="round" stroke-miterlimit="10" x1="179.4" y1="200.2" x2="143.4" y2="198.3"/>'
                    )
                )
            );
    }

    /// @dev Eyes N°27 => Suspicious
    function item_27() public pure returns (string memory) {
        return
            base(
                string(
                    abi.encodePacked(
                        '<path opacity="0.81" fill="#FFFFFF" d="M220.3,202.5c-0.6,4.6,0.1,5.8,1.6,8.3 c0.9,1.5,1,2.5,8.2-1.2c6.1,0.4,8.2-1.6,16,2.5c3,0,4-3.8,5.1-7.7c0.6-2.2-0.2-4.6-2-5.9c-3.4-2.5-9-6-13.4-5.3 c-3.9,0.7-7.7,1.9-11.3,3.6C222.3,197.9,221,197.3,220.3,202.5z"/>',
                        '<path d="M251.6,200c0.7-0.8,0.9-2.9,0.9-3.7c-0.1,0.6-1.3,1.5-2,2.2c-0.2-0.2-0.4-0.5-0.6-0.7c0.5-1,0.7-2.7,0.7-3.4 c-0.1,0.6-1.2,1.5-1.9,2.1c-2.4-2.2-5.8-4.4-10.4-4.9c-7.4-1-14.7,2.3-18.9,8.6c5.3-4.2,12.1-6,18.9-5.1c6,0.9,11.5,4,15.4,8.5 C253.6,203.4,252.9,201.9,251.6,200z"/>',
                        '<path d="M250.5,194.4L250.5,194.4C250.6,194,250.6,194.1,250.5,194.4z"/>',
                        '<path d="M252.4,196.3L252.4,196.3C252.5,195.9,252.5,196,252.4,196.3z"/>',
                        '<path d="M229.6,187.6c1.1-0.3,2.1-0.6,3.3-0.7c1.1-0.1,2.2-0.1,3.3,0s2.2,0.3,3.3,0.6s2.1,0.7,3.1,1.3l0,0 c-1.1-0.3-2.1-0.7-3.2-0.9c-1.1-0.3-2.1-0.5-3.2-0.6c-1.1-0.1-2.2-0.2-3.3-0.1C231.9,187.2,230.8,187.3,229.6,187.6L229.6,187.6 z"/>',
                        '<path d="M226.1,189c-0.9,0.7-1.8,1.3-2.8,1.9c-0.9,0.7-1.8,1.4-2.8,1.9c0.4-0.5,0.8-0.9,1.2-1.3c0.4-0.4,0.9-0.8,1.4-1.1 s1-0.7,1.5-0.9C225.1,189.4,225.7,189.1,226.1,189z"/>',
                        '<path fill="none" stroke="#000000" stroke-linecap="round" stroke-miterlimit="10" d="M222,212.8c0,0,9.8-7.3,26.9,0"/>',
                        '<path fill-rule="evenodd" clip-rule="evenodd" stroke="#000000" stroke-miterlimit="10" d="M229,195.2c0,0-4.6,8.5,0.7,14.4 c0,0,8.8-1.5,11.6,0.4c0,0,4.7-5.7,1.5-12.5S229,195.2,229,195.2z"/>',
                        '<path opacity="0.81" fill="#FFFFFF" d="M177.1,202.5c0.6,4.6-0.1,5.8-1.6,8.3 c-0.9,1.5-1,2.5-8.2-1.2c-6.1,0.4-8.2-1.6-16,2.5c-3,0-4-3.8-5.1-7.7c-0.6-2.2,0.2-4.6,2-5.9c3.4-2.5,9-6,13.4-5.3 c3.9,0.7,7.7,1.9,11.3,3.6C175.2,197.9,176.4,197.3,177.1,202.5z"/>',
                        '<path d="M145.9,200c-0.7-0.8-0.9-2.9-0.9-3.7c0.1,0.6,1.3,1.5,2,2.2c0.2-0.2,0.4-0.5,0.6-0.7c-0.5-1-0.7-2.7-0.7-3.4 c0.1,0.6,1.2,1.5,1.9,2.1c2.4-2.2,5.8-4.4,10.4-4.9c7.4-1,14.7,2.3,18.9,8.6c-5.3-4.2-12.1-6-18.9-5.1c-6,0.9-11.5,4-15.4,8.5 C143.8,203.4,144.5,201.9,145.9,200z"/>',
                        '<path d="M146.9,194.4L146.9,194.4C146.9,194,146.9,194.1,146.9,194.4z"/>',
                        abi.encodePacked(
                            '<path d="M145,196.3L145,196.3C144.9,195.9,144.9,196,145,196.3z"/>',
                            '<path d="M167.8,187.6c-1.1-0.3-2.1-0.6-3.3-0.7c-1.1-0.1-2.2-0.1-3.3,0s-2.2,0.3-3.3,0.6s-2.1,0.7-3.1,1.3l0,0 c1.1-0.3,2.1-0.7,3.2-0.9c1.1-0.3,2.1-0.5,3.2-0.6c1.1-0.1,2.2-0.2,3.3-0.1C165.6,187.2,166.6,187.3,167.8,187.6L167.8,187.6z"/>',
                            '<path d="M171.3,189c0.9,0.7,1.8,1.3,2.8,1.9c0.9,0.7,1.8,1.4,2.8,1.9c-0.4-0.5-0.8-0.9-1.2-1.3c-0.4-0.4-0.9-0.8-1.4-1.1 s-1-0.7-1.5-0.9C172.4,189.4,171.8,189.1,171.3,189z"/>',
                            '<path fill="none" stroke="#000000" stroke-linecap="round" stroke-miterlimit="10" d="M175.4,212.8c0,0-9.8-7.3-26.9,0"/>',
                            '<path fill-rule="evenodd" clip-rule="evenodd" stroke="#000000" stroke-miterlimit="10" d="M168.5,195.2c0,0,4.6,8.5-0.7,14.4 c0,0-8.8-1.5-11.6,0.4c0,0-4.7-5.7-1.5-12.5S168.5,195.2,168.5,195.2z"/>'
                        )
                    )
                )
            );
    }

    /// @dev Eyes N°28 => Annoyed 1
    function item_28() public pure returns (string memory) {
        return
            base(
                string(
                    abi.encodePacked(
                        '<line fill="none" stroke="#000000" stroke-linecap="round" stroke-miterlimit="10" x1="218" y1="195.2" x2="256" y2="195.2"/>',
                        '<path stroke="#000000" stroke-miterlimit="10" d="M234,195.5c0,5.1,4.1,9.2,9.2,9.2s9.2-4.1,9.2-9.2"/>',
                        '<line fill="none" stroke="#000000" stroke-linecap="round" stroke-miterlimit="10" x1="143.2" y1="195.7" x2="181.1" y2="195.7"/>',
                        '<path stroke="#000000" stroke-miterlimit="10" d="M158.7,196c0,5.1,4.1,9.2,9.2,9.2c5.1,0,9.2-4.1,9.2-9.2"/>'
                    )
                )
            );
    }

    /// @dev Eyes N°29 => Annoyed 2
    function item_29() public pure returns (string memory) {
        return
            base(
                string(
                    abi.encodePacked(
                        '<line fill="none" stroke="#000000" stroke-linecap="round" stroke-miterlimit="10" x1="218" y1="195.2" x2="256" y2="195.2"/>',
                        '<path stroke="#000000" stroke-miterlimit="10" d="M228,195.5c0,5.1,4.1,9.2,9.2,9.2s9.2-4.1,9.2-9.2"/>',
                        '<line fill="none" stroke="#000000" stroke-linecap="round" stroke-miterlimit="10" x1="143.2" y1="195.7" x2="181.1" y2="195.7"/>',
                        '<path stroke="#000000" stroke-miterlimit="10" d="M152.7,196c0,5.1,4.1,9.2,9.2,9.2c5.1,0,9.2-4.1,9.2-9.2"/>'
                    )
                )
            );
    }

    /// @dev Eyes N°30 => RIP
    function item_30() public pure returns (string memory) {
        return
            base(
                string(
                    abi.encodePacked(
                        '<line fill="none" stroke="#000000" stroke-width="3" stroke-linecap="square" stroke-miterlimit="10" x1="225.7" y1="190.8" x2="242.7" y2="207.8"/>',
                        '<line fill="none" stroke="#000000" stroke-width="3" stroke-linecap="square" stroke-miterlimit="10" x1="225.7" y1="207.8" x2="243.1" y2="190.8"/>',
                        '<line fill="none" stroke="#000000" stroke-width="3" stroke-linecap="square" stroke-miterlimit="10" x1="152.8" y1="190.8" x2="169.8" y2="207.8"/>',
                        '<line fill="none" stroke="#000000" stroke-width="3" stroke-linecap="square" stroke-miterlimit="10" x1="152.8" y1="207.8" x2="170.3" y2="190.8"/>'
                    )
                )
            );
    }

    /// @dev Eyes N°31 => Heart
    function item_31() public pure returns (string memory) {
        return
            base(
                string(
                    abi.encodePacked(
                        '<path fill="#F44336" stroke="#C90005" stroke-miterlimit="10" d="M161.1,218.1c0.2,0.2,0.4,0.3,0.7,0.3s0.5-0.1,0.7-0.3l12.8-14.1 c5.3-5.9,1.5-16-6-16c-4.6,0-6.7,3.6-7.5,4.3c-0.8-0.7-2.9-4.3-7.5-4.3c-7.6,0-11.4,10.1-6,16L161.1,218.1z"/>',
                        '<path fill="#F44336" stroke="#C90005" stroke-miterlimit="10" d="M235.3,218.1c0.2,0.2,0.5,0.3,0.8,0.3s0.6-0.1,0.8-0.3l13.9-14.1 c5.8-5.9,1.7-16-6.6-16c-4.9,0-7.2,3.6-8.1,4.3c-0.9-0.7-3.1-4.3-8.1-4.3c-8.2,0-12.4,10.1-6.6,16L235.3,218.1z"/>'
                    )
                )
            );
    }

    /// @dev Eyes N°32 => Scribble
    function item_32() public pure returns (string memory) {
        return
            base(
                string(
                    abi.encodePacked(
                        '<polyline fill="none" stroke="#000000" stroke-linecap="round" stroke-miterlimit="10" points="222.5,195.2 252.2,195.2 222.5,199.4 250.5,199.4 223.9,202.8 247.4,202.8"/>',
                        '<polyline fill="none" stroke="#000000" stroke-linecap="round" stroke-miterlimit="10" points="148.2,195.2 177.9,195.2 148.2,199.4 176.2,199.4 149.6,202.8 173.1,202.8"/>'
                    )
                )
            );
    }

    /// @dev Eyes N°33 => Wide
    function item_33() public pure returns (string memory) {
        return
            base(
                string(
                    abi.encodePacked(
                        '<ellipse fill-rule="evenodd" clip-rule="evenodd" fill="#FFFFFF" cx="236.7" cy="200.1" rx="12.6" ry="14.9"/>',
                        '<path d="M249.4,200.1c0,3.6-1,7.3-3.2,10.3c-1.1,1.5-2.5,2.8-4.1,3.7s-3.5,1.4-5.4,1.4s-3.7-0.6-5.3-1.5s-3-2.2-4.1-3.6c-2.2-2.9-3.4-6.5-3.5-10.2c-0.1-3.6,1-7.4,3.3-10.4c1.1-1.5,2.6-2.7,4.2-3.6c1.6-0.9,3.5-1.4,5.4-1.4s3.8,0.5,5.4,1.4c1.6,0.9,3,2.2,4.1,3.7C248.4,192.9,249.4,196.5,249.4,200.1z M249.3,200.1c0-1.8-0.3-3.6-0.9-5.3c-0.6-1.7-1.5-3.2-2.6-4.6c-2.2-2.7-5.5-4.5-9-4.5s-6.7,1.8-8.9,4.6c-2.2,2.7-3.3,6.2-3.4,9.8c-0.1,3.5,1,7.2,3.2,10s5.6,4.6,9.1,4.5c3.5,0,6.8-1.9,9-4.6C248,207.3,249.3,203.7,249.3,200.1z"/>',
                        '<ellipse fill-rule="evenodd" clip-rule="evenodd" fill="#FFFFFF" cx="163" cy="200.1" rx="12.6" ry="14.9"/>',
                        '<path d="M175.6,200.1c0,3.6-1,7.3-3.2,10.3c-1.1,1.5-2.5,2.8-4.1,3.7s-3.5,1.4-5.4,1.4s-3.7-0.6-5.3-1.5s-3-2.2-4.1-3.6c-2.2-2.9-3.4-6.5-3.5-10.2c-0.1-3.6,1-7.4,3.3-10.4c1.1-1.5,2.6-2.7,4.2-3.6c1.6-0.9,3.5-1.4,5.4-1.4s3.8,0.5,5.4,1.4c1.6,0.9,3,2.2,4.1,3.7C174.6,192.9,175.6,196.5,175.6,200.1z M175.5,200.1c0-1.8-0.3-3.6-0.9-5.3c-0.6-1.7-1.5-3.2-2.6-4.6c-2.2-2.7-5.5-4.5-9-4.5s-6.7,1.8-8.9,4.6c-2.2,2.7-3.3,6.2-3.4,9.8c-0.1,3.5,1,7.2,3.2,10s5.6,4.6,9.1,4.5c3.5,0,6.8-1.9,9-4.6C174.3,207.3,175.5,203.7,175.5,200.1z"/>'
                    )
                )
            );
    }

    /// @dev Eyes N°34 => Dubu
    function item_34() public pure returns (string memory) {
        return
            base(
                string(
                    abi.encodePacked(
                        '<path fill="none" stroke="#000000" stroke-linecap="round" stroke-miterlimit="10" d="M241.6,195.9c-8.7-7.2-25.1-4-4.7,6.6c-21.9-4.3-3.4,11.8,4.7,6.1"/>',
                        '<path fill="none" stroke="#000000" stroke-linecap="round" stroke-miterlimit="10" d="M167.6,195.9c-8.7-7.2-25.1-4-4.7,6.6c-21.9-4.3-3.4,11.8,4.7,6.1"/>'
                    )
                )
            );
    }

    /// @dev Right and left eyes (color pupils + eyes)
    function eyesNoFillAndColorPupils(string memory scleraColor, string memory pupilsColor)
        private
        pure
        returns (string memory)
    {
        return base(string(abi.encodePacked(eyesNoFill(scleraColor), colorPupils(pupilsColor))));
    }

    /// @dev Right and left eyes (blank pupils + eyes)
    function eyesNoFillAndBlankPupils(string memory scleraColor, string memory pupilsColor)
        private
        pure
        returns (string memory)
    {
        return base(string(abi.encodePacked(eyesNoFill(scleraColor), blankPupils(pupilsColor))));
    }

    /// @dev Right and left eyes
    function eyesNoFill(string memory scleraColor) private pure returns (string memory) {
        return string(abi.encodePacked(eyeLeftNoFill(scleraColor), eyeRightNoFill(scleraColor)));
    }

    /// @dev Eye right and no fill
    function eyeRightNoFill(string memory scleraColor) private pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "<path fill='#",
                    scleraColor,
                    "' d='M220.9,203.6c0.5,3.1,1.7,9.6,7.1,10.1 c7,1.1,21,4.3,23.2-9.3c1.3-7.1-9.8-11.4-15.4-11.2C230.7,194.7,220.5,194.7,220.9,203.6z'/>",
                    '<path d="M250.4,198.6c-0.2-0.2-0.4-0.5-0.6-0.7"/>',
                    '<path d="M248.6,196.6c-7.6-7.9-23.4-6.2-29.3,3.7c10-8.2,26.2-6.7,34.4,3.4c0-0.3-0.7-1.8-2-3.7"/>',
                    '<path d="M229.6,187.6c4.2-1.3,9.1-1,13,1.2C238.4,187.4,234,186.6,229.6,187.6L229.6,187.6z"/>',
                    '<path d="M226.1,189c-1.8,1.3-3.7,2.7-5.6,3.9C221.9,191.1,224,189.6,226.1,189z"/>',
                    '<path d="M224.5,212.4c5.2,2.5,19.7,3.5,24-0.9C244.2,216.8,229.6,215.8,224.5,212.4z"/>'
                )
            );
    }

    /// @dev Eye right and no fill
    function eyeLeftNoFill(string memory scleraColor) private pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "<path fill='#",
                    scleraColor,
                    "' d='M175.7,199.4c2.4,7.1-0.6,13.3-4.1,13.9 c-5,0.8-15.8,1-18.8,0c-5-1.7-6.1-12.4-6.1-12.4C156.6,191.4,165,189.5,175.7,199.4z'/>",
                    '<path d="M147.5,198.7c-0.8,1-1.5,2.1-2,3.3c7.5-8.5,24.7-10.3,31.7-0.9c-5.8-10.3-17.5-13-26.4-5.8"/>',
                    '<path d="M149.4,196.6c-0.2,0.2-0.4,0.4-0.6,0.6"/>',
                    '<path d="M166.2,187.1c-4.3-0.8-8.8,0.1-13,1.4C157,186.4,162,185.8,166.2,187.1z"/>',
                    '<path d="M169.8,188.5c2.2,0.8,4.1,2.2,5.6,3.8C173.5,191.1,171.6,189.7,169.8,188.5z"/>',
                    '<path d="M174.4,211.8c-0.2,0.5-0.8,0.8-1.2,1c-0.5,0.2-1,0.4-1.5,0.6c-1,0.3-2.1,0.5-3.1,0.7c-2.1,0.4-4.2,0.5-6.3,0.7 c-2.1,0.1-4.3,0.1-6.4-0.3c-1.1-0.2-2.1-0.5-3.1-0.9c-0.9-0.5-2-1.1-2.4-2.1c0.6,0.9,1.6,1.4,2.5,1.7c1,0.3,2,0.6,3,0.7 c2.1,0.3,4.2,0.3,6.2,0.2c2.1-0.1,4.2-0.2,6.3-0.5c1-0.1,2.1-0.3,3.1-0.5c0.5-0.1,1-0.2,1.5-0.4c0.2-0.1,0.5-0.2,0.7-0.3 C174.1,212.2,174.3,212.1,174.4,211.8z"/>'
                )
            );
    }

    /// @dev Generate color pupils
    function colorPupils(string memory pupilsColor) private pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "<path fill='#",
                    pupilsColor,
                    "' d='M235,194.9c10.6-0.2,10.6,19,0,18.8C224.4,213.9,224.4,194.7,235,194.9z'/>",
                    '<path d="M235,199.5c3.9-0.1,3.9,9.6,0,9.5C231.1,209.1,231.1,199.4,235,199.5z"/>',
                    '<path fill="#FFFFFF" d="M239.1,200.9c3.4,0,3.4,2.5,0,2.5C235.7,203.4,235.7,200.8,239.1,200.9z"/>',
                    "<path fill='#",
                    pupilsColor,
                    "' d='M161.9,194.6c10.5-0.4,11,18.9,0.4,18.9C151.7,213.9,151.3,194.6,161.9,194.6z'/>",
                    '<path d="M162,199.2c3.9-0.2,4.1,9.5,0.2,9.5C158.2,208.9,158.1,199.2,162,199.2z"/>',
                    '<path fill="#FFFFFF" d="M157.9,200.7c3.4-0.1,3.4,2.5,0,2.5C154.6,203.3,154.5,200.7,157.9,200.7z"/>'
                )
            );
    }

    /// @dev Generate blank pupils
    function blankPupils(string memory pupilsColor) private pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    abi.encodePacked(
                        "<path fill='#",
                        pupilsColor,
                        "' stroke='#000000' stroke-width='0.25' stroke-miterlimit='10' d='M169.2,204.2c0.1,11.3-14.1,11.3-13.9,0C155.1,192.9,169.3,192.9,169.2,204.2z'/>",
                        "<path fill='#",
                        pupilsColor,
                        "' stroke='#000000' stroke-width='0.25' stroke-miterlimit='10' d='M243.1,204.3c0.1,11.3-14.1,11.3-13.9,0C229,193,243.2,193,243.1,204.3z'/>"
                    )
                )
            );
    }

    /// @notice Return the eyes name of the given id
    /// @param id The eyes Id
    function getItemNameById(uint8 id) public pure returns (string memory name) {
        name = "";
        if (id == 1) {
            name = "Color White/Brown";
        } else if (id == 2) {
            name = "Color White/Gray";
        } else if (id == 3) {
            name = "Color White/Blue";
        } else if (id == 4) {
            name = "Color White/Green";
        } else if (id == 5) {
            name = "Color White/Black";
        } else if (id == 6) {
            name = "Color White/Yellow";
        } else if (id == 7) {
            name = "Color White/Red";
        } else if (id == 8) {
            name = "Color White/Purple";
        } else if (id == 9) {
            name = "Color White/Pink";
        } else if (id == 10) {
            name = "Color White/White";
        } else if (id == 11) {
            name = "Color Black/Blue";
        } else if (id == 12) {
            name = "Color Black/Yellow";
        } else if (id == 13) {
            name = "Color Black/White";
        } else if (id == 14) {
            name = "Color Black/Red";
        } else if (id == 15) {
            name = "Blank White/White";
        } else if (id == 16) {
            name = "Blank Black/White";
        } else if (id == 17) {
            name = "Shine";
        } else if (id == 18) {
            name = "Stunt";
        } else if (id == 19) {
            name = "Squint";
        } else if (id == 20) {
            name = "Shock";
        } else if (id == 21) {
            name = "Cat";
        } else if (id == 22) {
            name = "Ether";
        } else if (id == 23) {
            name = "Feels";
        } else if (id == 24) {
            name = "Happy";
        } else if (id == 25) {
            name = "Arrow";
        } else if (id == 26) {
            name = "Closed";
        } else if (id == 27) {
            name = "Suspicious";
        } else if (id == 28) {
            name = "Annoyed 1";
        } else if (id == 29) {
            name = "Annoyed 2";
        } else if (id == 30) {
            name = "RIP";
        } else if (id == 31) {
            name = "Heart";
        } else if (id == 32) {
            name = "Scribble";
        } else if (id == 33) {
            name = "Wide";
        } else if (id == 34) {
            name = "Dubu";
        }
    }

    /// @dev The base SVG for the eyes
    function base(string memory children) private pure returns (string memory) {
        return string(abi.encodePacked('<g id="Eyes">', children, "</g>"));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

pragma abicoder v2;

import "base64-sol/base64.sol";

/// @title Eyebrow SVG generator
library EyebrowDetail {
    /// @dev Eyebrow N°1 => Classic
    function item_1() public pure returns (string memory) {
        return
            base(
                string(
                    abi.encodePacked(
                        '<path fill="#150000" d="M213.9,183.1c13.9-5.6,28.6-3,42.7-0.2C244,175,225.8,172.6,213.9,183.1z"/>',
                        '<path fill="#150000" d="M179.8,183.1c-10.7-10.5-27-8.5-38.3-0.5C154.1,179.7,167.6,177.5,179.8,183.1z"/>'
                    )
                )
            );
    }

    /// @dev Eyebrow N°2 => Thick
    function item_2() public pure returns (string memory) {
        return
            base(
                string(
                    abi.encodePacked(
                        '<path fill-rule="evenodd" clip-rule="evenodd" stroke="#000000" stroke-miterlimit="10" d="M211.3,177.6c0,0,28.6-6.6,36.2-6.2c7.7,0.4,13,3,16.7,6.4c0,0-26.9,5.3-38.9,5.9C213.3,184.3,212.9,183.8,211.3,177.6z"/>',
                        '<path fill-rule="evenodd" clip-rule="evenodd" stroke="#000000" stroke-miterlimit="10" d="M188.2,177.6c0,0-27.9-6.7-35.4-6.3c-7.5,0.4-12.7,2.9-16.2,6.3c0,0,26.3,5.3,38,6C186.2,184.3,186.7,183.7,188.2,177.6z"/>'
                    )
                )
            );
    }

    /// @dev Eyebrow N°3 => Punk
    function item_3() public pure returns (string memory) {
        return
            base(
                string(
                    abi.encodePacked(
                        '<path fill-rule="evenodd" clip-rule="evenodd" stroke="#000000" stroke-miterlimit="10" d="M258.6,179.1l-2-2.3 c3.1,0.4,5.6,1,7.6,1.7C264.2,178.6,262,178.8,258.6,179.1z M249.7,176.3c-0.7,0-1.5,0-2.3,0c-7.6,0-36.1,3.2-36.1,3.2 c-0.4,2.9-3.8,3.5,8.1,3c6.6-0.3,23.6-2,32.3-2.8L249.7,176.3z"/>',
                        '<path fill-rule="evenodd" clip-rule="evenodd" stroke="#000000" stroke-miterlimit="10" d="M140.2,179.1l1.9-2.3 c-3,0.4-5.4,1-7.3,1.7C134.8,178.6,136.9,178.8,140.2,179.1z M148.8,176.3c0.7,0,1.4,0,2.2,0c7.3,0,34.7,3.2,34.7,3.2 c0.4,2.9,3.6,3.5-7.8,3c-6.3-0.3-22.7-2-31-2.8L148.8,176.3z"/>'
                    )
                )
            );
    }

    /// @dev Eyebrow N°4 => Small
    function item_4() public pure returns (string memory) {
        return
            base(
                string(
                    abi.encodePacked(
                        '<path fill-rule="evenodd" clip-rule="evenodd" d="M236.3,177c-11.3-5.1-18-3.1-20.3-2.1c-0.1,0-0.2,0.1-0.3,0.2c-0.3,0.1-0.5,0.3-0.6,0.3l0,0l0,0l0,0c-1,0.7-1.7,1.7-1.9,3c-0.5,2.6,1.2,5,3.8,5.5s5-1.2,5.5-3.8c0.1-0.3,0.1-0.6,0.1-1C227.4,175.6,236.3,177,236.3,177z"/>',
                        '<path fill-rule="evenodd" clip-rule="evenodd" d="M160.2,176.3c10.8-4.6,17.1-2.5,19.2-1.3c0.1,0,0.2,0.1,0.3,0.2c0.3,0.1,0.4,0.3,0.5,0.3l0,0l0,0l0,0c0.9,0.7,1.6,1.8,1.8,3.1c0.4,2.6-1.2,5-3.7,5.4s-4.7-1.4-5.1-4c-0.1-0.3-0.1-0.6-0.1-1C168.6,175.2,160.2,176.3,160.2,176.3z"/>'
                    )
                )
            );
    }

    /// @dev Eyebrow N°5 => Shaved
    function item_5() public pure returns (string memory) {
        return
            base(
                string(
                    abi.encodePacked(
                        '<g opacity="0.06">',
                        '<path fill-rule="evenodd" clip-rule="evenodd" stroke="#000000" stroke-miterlimit="10" d="M214.5,178 c0,0,20.6-3.5,26.1-3.3s9.4,1.6,12,3.4c0,0-19.4,2.8-28,3.1C215.9,181.6,215.6,181.3,214.5,178z"/>',
                        '<path fill-rule="evenodd" clip-rule="evenodd" stroke="#000000" stroke-miterlimit="10" d="M180.8,178 c0,0-20.1-3.6-25.5-3.4c-5.4,0.2-9.1,1.5-11.7,3.4c0,0,18.9,2.8,27.4,3.2C179.4,181.6,179.8,181.3,180.8,178z"/>',
                        "</g>"
                    )
                )
            );
    }

    /// @dev Eyebrow N°6 => Elektric
    function item_6() public pure returns (string memory) {
        return
            base(
                string(
                    abi.encodePacked(
                        '<path fill-rule="evenodd" clip-rule="evenodd" d="M208.9,177.6c14.6-1.5,47.8-6.5,51.6-6.6l-14.4,4.1l19.7,3.2 c-20.2-0.4-40.9-0.1-59.2,2.6C206.6,179.9,207.6,178.5,208.9,177.6z"/>',
                        '<path fill-rule="evenodd" clip-rule="evenodd" d="M185.1,177.7c-13.3-1.5-43.3-6.7-46.7-6.9l13.1,4.2l-17.8,3.1 c18.2-0.3,37,0.1,53.6,2.9C187.2,180,186.2,178.6,185.1,177.7z"/>'
                    )
                )
            );
    }

    /// @notice Return the eyebrow name of the given id
    /// @param id The eyebrow Id
    function getItemNameById(uint8 id) public pure returns (string memory name) {
        name = "";
        if (id == 1) {
            name = "Classic";
        } else if (id == 2) {
            name = "Thick";
        } else if (id == 3) {
            name = "Punk";
        } else if (id == 4) {
            name = "Small";
        } else if (id == 5) {
            name = "Shaved";
        } else if (id == 6) {
            name = "Elektric";
        }
    }

    /// @dev The base SVG for the Eyebrow
    function base(string memory children) private pure returns (string memory) {
        return string(abi.encodePacked('<g id="Eyebrow">', children, "</g>"));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

pragma abicoder v2;

import "base64-sol/base64.sol";

/// @title Mark SVG generator
library MarkDetail {
    /// @dev Mark N°1 => Classic
    function item_1() public pure returns (string memory) {
        return "";
    }

    /// @dev Mark N°2 => Blush Cheeks
    function item_2() public pure returns (string memory) {
        return
            base(
                string(
                    abi.encodePacked(
                        '<g opacity="0.71">',
                        '<ellipse fill="#FF7478" cx="257.6" cy="221.2" rx="11.6" ry="3.6"/>',
                        '<ellipse fill="#FF7478" cx="146.9" cy="221.5" rx="9.6" ry="3.6"/>',
                        "</g>"
                    )
                )
            );
    }

    /// @dev Mark N°3 => Dark Circle
    function item_3() public pure returns (string memory) {
        return
            base(
                string(
                    abi.encodePacked(
                        '<path d="M160.1,223.2c4.4,0.2,8.7-1.3,12.7-3.2C169.3,222.7,164.4,223.9,160.1,223.2z"/>',
                        '<path d="M156.4,222.4c-2.2-0.4-4.3-1.6-6.1-3C152.3,220.3,154.4,221.4,156.4,222.4z"/>',
                        '<path d="M234.5,222.7c4.9,0.1,9.7-1.4,14.1-3.4C244.7,222.1,239.3,223.4,234.5,222.7z"/>',
                        '<path d="M230.3,221.9c-2.5-0.4-4.8-1.5-6.7-2.9C225.9,219.9,228.2,221,230.3,221.9z"/>'
                    )
                )
            );
    }

    /// @dev Mark N°4 => Chin scar
    function item_4() public pure returns (string memory) {
        return
            base(
                string(
                    abi.encodePacked(
                        '<path fill="#E83342" d="M195.5,285.7l17,8.9C212.5,294.6,206.1,288.4,195.5,285.7z"/>',
                        '<path fill="#E83342" d="M211.2,285.7l-17,8.9C194.1,294.6,200.6,288.4,211.2,285.7z"/>'
                    )
                )
            );
    }

    /// @dev Mark N°5 => Blush
    function item_5() public pure returns (string memory) {
        return
            base(
                string(
                    abi.encodePacked(
                        '<ellipse opacity="0.52" fill-rule="evenodd" clip-rule="evenodd" fill="#FF7F83" cx="196.8" cy="222" rx="32.8" ry="1.9"/>'
                    )
                )
            );
    }

    /// @dev Mark N°6 => Chin
    function item_6() public pure returns (string memory) {
        return
            base(
                string(
                    abi.encodePacked(
                        '<path d="M201.3,291.9c0.2-0.6,0.4-1.3,1-1.8c0.3-0.2,0.7-0.4,1.1-0.3c0.4,0.1,0.7,0.4,0.9,0.7c0.4,0.6,0.5,1.4,0.5,2.1 c0,0.7-0.3,1.5-0.8,2c-0.5,0.6-1.3,0.9-2.1,0.8c-0.8-0.1-1.5-0.5-2-0.9c-0.6-0.4-1.1-1-1.5-1.6c-0.4-0.6-0.6-1.4-0.6-2.2 c0.2-1.6,1.4-2.8,2.7-3.4c1.3-0.6,2.8-0.8,4.2-0.5c0.7,0.1,1.4,0.4,2,0.9c0.6,0.5,0.9,1.2,1,1.9c0.2,1.4-0.2,2.9-1.2,3.9 c0.7-1.1,1-2.5,0.7-3.8c-0.2-0.6-0.5-1.2-1-1.5c-0.5-0.4-1.1-0.6-1.7-0.6c-1.3-0.1-2.6,0-3.7,0.6c-1.1,0.5-2,1.5-2.1,2.6 c-0.1,1.1,0.7,2.2,1.6,3c0.5,0.4,1,0.8,1.5,0.8c0.5,0.1,1.1-0.1,1.5-0.5c0.4-0.4,0.7-0.9,0.7-1.6c0.1-0.6,0-1.3-0.3-1.8 c-0.1-0.3-0.4-0.5-0.6-0.6c-0.3-0.1-0.6,0-0.8,0.1C201.9,290.7,201.5,291.3,201.3,291.9z"/>'
                    )
                )
            );
    }

    /// @dev Mark N°7 => Yinyang
    function item_7() public pure returns (string memory) {
        return
            base(
                string(
                    abi.encodePacked(
                        '<path opacity="0.86" d="M211.5,161.1c0-8.2-6.7-14.9-14.9-14.9c-0.2,0-0.3,0-0.5,0l0,0 H196c-0.1,0-0.2,0-0.2,0c-0.2,0-0.4,0-0.5,0c-7.5,0.7-13.5,7.1-13.5,14.8c0,8.2,6.7,14.9,14.9,14.9 C204.8,176,211.5,169.3,211.5,161.1z M198.4,154.2c0,1-0.8,1.9-1.9,1.9c-1,0-1.9-0.8-1.9-1.9c0-1,0.8-1.9,1.9-1.9 C197.6,152.3,198.4,153.1,198.4,154.2z M202.9,168.2c0,3.6-3.1,6.6-6.9,6.6l0,0c-7.3-0.3-13.2-6.3-13.2-13.7c0-6,3.9-11.2,9.3-13 c-2,1.3-3.4,3.6-3.4,6.2c0,4,3.3,7.3,7.3,7.3l0,0C199.8,161.6,202.9,164.5,202.9,168.2z M196.6,170.3c-1,0-1.9-0.8-1.9-1.9 c0-1,0.8-1.9,1.9-1.9c1,0,1.9,0.8,1.9,1.9C198.4,169.5,197.6,170.3,196.6,170.3z"/>'
                    )
                )
            );
    }

    /// @dev Mark N°8 => Scar
    function item_8() public pure returns (string memory) {
        return
            base(
                string(
                    abi.encodePacked(
                        '<path id="Scar" fill="#FF7478" d="M236.2,148.7c0,0-7.9,48.9-1.2,97.3C235,246,243.8,201.5,236.2,148.7z"/>'
                    )
                )
            );
    }

    /// @dev Mark N°9 => Sun
    function item_9() public pure returns (string memory) {
        return
            base(
                string(
                    abi.encodePacked(
                        '<circle fill="#7F0068" cx="195.8" cy="161.5" r="11.5"/>',
                        '<polygon fill="#7F0068" points="195.9,142.4 192.4,147.8 199.3,147.8"/>',
                        '<polygon fill="#7F0068" points="209.6,158.1 209.6,164.9 214.9,161.5"/>',
                        '<polygon fill="#7F0068" points="195.9,180.6 199.3,175.2 192.4,175.2"/>',
                        '<polygon fill="#7F0068" points="182.1,158.1 176.8,161.5 182.1,164.9"/>',
                        '<polygon fill="#7F0068" points="209.3,148 203.1,149.4 208,154.2"/>',
                        '<polygon fill="#7F0068" points="209.3,175 208,168.8 203.1,173.6"/>',
                        '<polygon fill="#7F0068" points="183.7,168.8 182.4,175 188.6,173.6"/>',
                        '<polygon fill="#7F0068" points="188.6,149.4 182.4,148 183.7,154.2"/>'
                    )
                )
            );
    }

    /// @dev Mark N°10 => Moon
    function item_10() public pure returns (string memory) {
        return
            base(
                string(
                    abi.encodePacked(
                        '<path fill="#7F0068" d="M197.2,142.1c-5.8,0-10.9,2.9-13.9,7.3c2.3-2.3,5.4-3.7,8.9-3.7c7.1,0,12.9,5.9,12.9,13.3 s-5.8,13.3-12.9,13.3c-3.4,0-6.6-1.4-8.9-3.7c3.1,4.4,8.2,7.3,13.9,7.3c9.3,0,16.9-7.6,16.9-16.9S206.6,142.1,197.2,142.1z"/>'
                    )
                )
            );
    }

    /// @dev Mark N°11 => Third Eye
    function item_11() public pure returns (string memory) {
        return
            base(
                string(
                    abi.encodePacked(
                        '<path opacity="0.81" fill="#FFFFFF" d="M184.4,159.3c0.7,3.5,0.8,8.5,6.3,8.8 c5.5,1.6,23.2,4.2,23.8-7.6c1.2-6.1-10-9.5-15.5-9.3C193.8,152.6,184.1,153.5,184.4,159.3z"/>',
                        '<path d="M213.6,155.6c-0.2-0.2-0.4-0.4-0.6-0.6"/>',
                        '<path d="M211.8,154c-7.7-6.6-23.5-4.9-29.2,3.6c9.9-7.1,26.1-6.1,34.4,2.4c0-0.3-0.7-1.5-2-3.1"/>',
                        '<path d="M197.3,146.8c4.3-0.6,9.1,0.3,12.7,2.7C206,147.7,201.8,146.5,197.3,146.8L197.3,146.8z M193.6,147.5 c-2,0.9-4.1,1.8-6.1,2.6C189.2,148.8,191.5,147.8,193.6,147.5z"/>',
                        '<path d="M187.6,167.2c5.2,2,18.5,3.2,23.3,0.1C206.3,171.3,192.7,170,187.6,167.2z"/>',
                        '<path fill="#0B1F26" d="M199.6,151c11.1-0.2,11.1,17.4,0,17.3C188.5,168.4,188.5,150.8,199.6,151z"/>'
                    )
                )
            );
    }

    /// @dev Mark N°12 => Tori
    function item_12() public pure returns (string memory) {
        return
            base(
                string(
                    abi.encodePacked(
                        '<line fill="none" stroke="#000000" stroke-width="0.5" stroke-linecap="round" stroke-linejoin="round" stroke-miterlimit="10" x1="231.2" y1="221.5" x2="231.2" y2="228.4"/>',
                        '<path fill="none" stroke="#000000" stroke-width="0.5" stroke-linecap="round" stroke-linejoin="round" stroke-miterlimit="10" d="M228.6,221.2c0,0,3.2,0.4,5.5,0.2"/>',
                        '<path fill-rule="evenodd" clip-rule="evenodd" fill="none" stroke="#000000" stroke-width="0.5" stroke-linecap="round" stroke-linejoin="round" stroke-miterlimit="10" d="M237.3,221.5c0,0-3.5,3.1,0,6.3C240.8,231,242.2,221.5,237.3,221.5z"/>',
                        '<path fill-rule="evenodd" clip-rule="evenodd" fill="none" stroke="#000000" stroke-width="0.5" stroke-linecap="round" stroke-linejoin="round" stroke-miterlimit="10" d="M243.2,227.8l-1.2-6.4c0,0,8.7-2,1,2.8l3.2,3"/>',
                        '<line fill-rule="evenodd" clip-rule="evenodd" fill="#FFEBB4" stroke="#000000" stroke-width="0.5" stroke-linecap="round" stroke-linejoin="round" stroke-miterlimit="10" x1="248.5" y1="221" x2="248.5" y2="227.5"/>',
                        '<path d="M254.2,226c0,0,0.1,0,0.1,0c0,0,0.1,0,0.1-0.1l1.3-2.2c0.5-0.9-0.2-2.2-1.2-2c-0.6,0.1-0.8,0.7-0.9,0.8 c-0.1-0.1-0.5-0.5-1.1-0.4c-1,0.2-1.3,1.7-0.4,2.3L254.2,226z"/>'
                    )
                )
            );
    }

    /// @dev Mark N°13 => Ether
    function item_13() public pure returns (string memory) {
        return
            base(
                string(
                    abi.encodePacked(
                        '<path fill="#2B2B2B" stroke="#000000" stroke-miterlimit="10" d="M196.5,159.9l-12.4-5.9l12.4,21.6l12.4-21.6L196.5,159.9z"/>',
                        '<path fill="#2B2B2B" stroke="#000000" stroke-miterlimit="10" d="M207.5,149.6l-11-19.1l-11,19.2l11-5.2L207.5,149.6z"/>',
                        '<path fill="#2B2B2B" stroke="#000000" stroke-miterlimit="10" d="M186.5,152.2l10.1,4.8l10.1-4.8l-10.1-4.8L186.5,152.2z"/>'
                    )
                )
            );
    }

    /// @notice Return the mark name of the given id
    /// @param id The mark Id
    function getItemNameById(uint8 id) public pure returns (string memory name) {
        name = "";
        if (id == 1) {
            name = "Classic";
        } else if (id == 2) {
            name = "Blush Cheeks";
        } else if (id == 3) {
            name = "Dark Circle";
        } else if (id == 4) {
            name = "Chin Scar";
        } else if (id == 5) {
            name = "Blush";
        } else if (id == 6) {
            name = "Chin";
        } else if (id == 7) {
            name = "Yinyang";
        } else if (id == 8) {
            name = "Scar";
        } else if (id == 9) {
            name = "Sun";
        } else if (id == 10) {
            name = "Moon";
        } else if (id == 11) {
            name = "Third Eye";
        } else if (id == 12) {
            name = "Tori";
        } else if (id == 13) {
            name = "Ether";
        }
    }

    /// @dev The base SVG for the hair
    function base(string memory children) private pure returns (string memory) {
        return string(abi.encodePacked('<g id="Mark">', children, "</g>"));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

pragma abicoder v2;

import "base64-sol/base64.sol";
import "./constants/Colors.sol";

/// @title Accessory SVG generator
library AccessoryDetail {
    /// @dev Accessory N°1 => Classic
    function item_1() public pure returns (string memory) {
        return "";
    }

    /// @dev Accessory N°2 => Glasses
    function item_2() public pure returns (string memory) {
        return base(glasses("D1F5FF", "000000", "0.31"));
    }

    /// @dev Accessory N°3 => Bow Tie
    function item_3() public pure returns (string memory) {
        return
            base(
                string(
                    abi.encodePacked(
                        '<path fill="none" stroke="#000000" stroke-width="7" stroke-miterlimit="10" d="M176.2,312.5 c3.8,0.3,26.6,7.2,81.4-0.4"/>',
                        '<path fill-rule="evenodd" clip-rule="evenodd" fill="#DF0849" stroke="#000000" stroke-miterlimit="10" d="M211.3,322.1 c-2.5-0.3-5-0.5-7.4,0c-1.1,0-1.9-1.4-1.9-3.1v-4.5c0-1.7,0.9-3.1,1.9-3.1c2.3,0.6,4.8,0.5,7.4,0c1.1,0,1.9,1.4,1.9,3.1v4.5 C213.2,320.6,212.3,322.1,211.3,322.1z"/>',
                        '<path fill="#DF0849" stroke="#000000" stroke-miterlimit="10" d="M202.4,321.5c0,0-14,5.6-17.7,5.3c-1.1-0.1-2.5-4.6-1.2-10.5 c0,0-1-2.2-0.3-9.5c0.4-3.4,19.2,5.1,19.2,5.1S201,316.9,202.4,321.5z"/>',
                        '<path fill="#DF0849" stroke="#000000" stroke-miterlimit="10" d="M212.6,321.5c0,0,14,5.6,17.7,5.3c1.1-0.1,2.5-4.6,1.2-10.5 c0,0,1-2.2,0.3-9.5c-0.4-3.4-19.2,5.1-19.2,5.1S213.9,316.9,212.6,321.5z"/>',
                        '<path opacity="0.41" d="M213.6,315.9l6.4-1.1l-3.6,1.9l4.1,1.1l-7-0.6L213.6,315.9z M201.4,316.2l-6.4-1.1l3.6,1.9l-4.1,1.1l7-0.6L201.4,316.2z"/>'
                    )
                )
            );
    }

    /// @dev Accessory N°4 => Monk Beads Classic
    function item_4() public pure returns (string memory) {
        return base(monkBeads("63205A"));
    }

    /// @dev Accessory N°5 => Monk Beads Silver
    function item_5() public pure returns (string memory) {
        return base(monkBeads("C7D2D4"));
    }

    /// @dev Accessory N°6 => Power Pole
    function item_6() public pure returns (string memory) {
        return
            base(
                string(
                    abi.encodePacked(
                        '<path fill="#FF6F4F" stroke="#000000" stroke-width="0.75" stroke-miterlimit="10" d="M272.3,331.9l55.2-74.4c0,0,3,4.3,8.7,7.5l-54,72.3"/>',
                        '<polygon fill="#BA513A" points="335.9,265.3 334.2,264.1 279.9,336.1 281.8,337.1"/>',
                        '<ellipse transform="matrix(0.6516 -0.7586 0.7586 0.6516 -82.3719 342.7996)" fill="#B54E36" stroke="#000000" stroke-width="0.25" stroke-miterlimit="10" cx="332" cy="261.1" rx="1.2" ry="6.1"/>',
                        '<path fill="none" stroke="#B09E00" stroke-miterlimit="10" d="M276.9,335.3c-52.7,31.1-119.3,49.4-120.7,49"/>'
                    )
                )
            );
    }

    /// @dev Accessory N°7 => Vintage Glasses
    function item_7() public pure returns (string memory) {
        return base(glasses("FC55FF", "DFA500", "0.31"));
    }

    /// @dev Accessory N°8 => Monk Beads Gold
    function item_8() public pure returns (string memory) {
        return base(monkBeads("FFDD00"));
    }

    /// @dev Accessory N°9 => Eye Patch
    function item_9() public pure returns (string memory) {
        return
            base(
                string(
                    abi.encodePacked(
                        '<path fill="#FCFEFF" stroke="#4A6362" stroke-miterlimit="10" d="M253.6,222.7H219c-4.7,0-8.5-3.8-8.5-8.5v-20.8 c0-4.7,3.8-8.5,8.5-8.5h34.6c4.7,0,8.5,3.8,8.5,8.5v20.8C262.1,218.9,258.3,222.7,253.6,222.7z"/>',
                        '<path fill="none" stroke="#4A6362" stroke-width="0.75" stroke-miterlimit="10" d="M250.1,218.9h-27.6c-3.8,0-6.8-3.1-6.8-6.8 v-16.3c0-3.8,3.1-6.8,6.8-6.8h27.6c3.8,0,6.8,3.1,6.8,6.8V212C257,215.8,253.9,218.9,250.1,218.9z"/>',
                        '<line fill="none" stroke="#3C4F4E" stroke-linecap="round" stroke-miterlimit="10" x1="211.9" y1="188.4" x2="131.8" y2="183.1"/>',
                        '<line fill="none" stroke="#3C4F4E" stroke-linecap="round" stroke-miterlimit="10" x1="259.9" y1="188.1" x2="293.4" y2="196.7"/>',
                        '<line fill="none" stroke="#3C4F4E" stroke-linecap="round" stroke-miterlimit="10" x1="259.2" y1="220.6" x2="277.5" y2="251.6"/>',
                        '<line fill="none" stroke="#3C4F4E" stroke-linecap="round" stroke-miterlimit="10" x1="211.4" y1="219.1" x2="140.5" y2="242"/>',
                        '<g fill-rule="evenodd" clip-rule="evenodd" fill="#636363" stroke="#4A6362" stroke-width="0.25" stroke-miterlimit="10"><ellipse cx="250.9" cy="215" rx="0.8" ry="1.1"/><ellipse cx="236.9" cy="215" rx="0.8" ry="1.1"/><ellipse cx="250.9" cy="203.9" rx="0.8" ry="1.1"/><ellipse cx="250.9" cy="193.8" rx="0.8" ry="1.1"/><ellipse cx="236.9" cy="193.8" rx="0.8" ry="1.1"/><ellipse cx="221.3" cy="215" rx="0.8" ry="1.1"/><ellipse cx="221.3" cy="203.9" rx="0.8" ry="1.1"/><ellipse cx="221.3" cy="193.8" rx="0.8" ry="1.1"/></g>'
                    )
                )
            );
    }

    /// @dev Accessory N°10 => Sun Glasses
    function item_10() public pure returns (string memory) {
        return base(glasses(Colors.BLACK, Colors.BLACK_DEEP, "1"));
    }

    /// @dev Accessory N°11 => Monk Beads Diamond
    function item_11() public pure returns (string memory) {
        return base(monkBeads("AAFFFD"));
    }

    /// @dev Accessory N°12 => Horns
    function item_12() public pure returns (string memory) {
        return
            base(
                string(
                    abi.encodePacked(
                        '<path fill-rule="evenodd" clip-rule="evenodd" fill="#212121" stroke="#000000" stroke-linejoin="round" stroke-miterlimit="10" d="M257.7,96.3c0,0,35-18.3,46.3-42.9c0,0-0.9,37.6-23.2,67.6C269.8,115.6,261.8,107.3,257.7,96.3z"/>',
                        '<path fill-rule="evenodd" clip-rule="evenodd" fill="#212121" stroke="#000000" stroke-linejoin="round" stroke-miterlimit="10" d="M162,96.7c0,0-33-17.3-43.7-40.5c0,0,0.9,35.5,21.8,63.8C150.6,114.9,158.1,107.1,162,96.7z"/>'
                    )
                )
            );
    }

    /// @dev Accessory N°13 => Halo
    function item_13() public pure returns (string memory) {
        return
            base(
                string(
                    abi.encodePacked(
                        '<path fill="#F6FF99" stroke="#000000" stroke-miterlimit="10" d="M136,67.3c0,14.6,34.5,26.4,77,26.4s77-11.8,77-26.4s-34.5-26.4-77-26.4S136,52.7,136,67.3L136,67.3z M213,79.7c-31.4,0-56.9-6.4-56.9-14.2s25.5-14.2,56.9-14.2s56.9,6.4,56.9,14.2S244.4,79.7,213,79.7z"/>'
                    )
                )
            );
    }

    /// @dev Accessory N°14 => Saiki Power
    function item_14() public pure returns (string memory) {
        return
            base(
                string(
                    abi.encodePacked(
                        '<line fill="none" stroke="#000000" stroke-width="5" stroke-miterlimit="10" x1="270.5" y1="105.7" x2="281.7" y2="91.7"/>',
                        '<circle fill="#EB7FFF" stroke="#000000" stroke-miterlimit="10" cx="285.7" cy="85.2" r="9.2"/>',
                        '<line fill="none" stroke="#000000" stroke-width="5" stroke-miterlimit="10" x1="155.8" y1="105.7" x2="144.5" y2="91.7"/>',
                        '<circle fill="#EB7FFF" stroke="#000000" stroke-miterlimit="10" cx="138.7" cy="85.2" r="9.2"/>',
                        '<path opacity="0.17" d="M287.3,76.6c0,0,10.2,8.2,0,17.1c0,0,7.8-0.7,7.4-9.5 C293,75.9,287.3,76.6,287.3,76.6z"/>',
                        '<path opacity="0.17" d="M137,76.4c0,0-10.2,8.2,0,17.1c0,0-7.8-0.7-7.4-9.5 C131.4,75.8,137,76.4,137,76.4z"/>',
                        '<ellipse transform="matrix(0.4588 -0.8885 0.8885 0.4588 80.0823 294.4391)" fill="#FFFFFF" cx="281.8" cy="81.5" rx="2.1" ry="1.5"/>',
                        '<ellipse transform="matrix(0.8885 -0.4588 0.4588 0.8885 -21.756 74.6221)" fill="#FFFFFF" cx="142.7" cy="82.1" rx="1.5" ry="2.1"/>',
                        '<path fill="none" stroke="#000000" stroke-miterlimit="10" d="M159.6,101.4c0,0-1.1,4.4-7.4,7.2"/>',
                        '<path fill="none" stroke="#000000" stroke-miterlimit="10" d="M267.2,101.4c0,0,1.1,4.4,7.4,7.2"/>',
                        abi.encodePacked(
                            '<polygon opacity="0.68" fill="#7FFF35" points="126,189.5 185.7,191.8 188.6,199.6 184.6,207.4 157.3,217.9 128.6,203.7"/>',
                            '<polygon opacity="0.68" fill="#7FFF35" points="265.7,189.5 206.7,191.8 203.8,199.6 207.7,207.4 234.8,217.9 263.2,203.7"/>',
                            '<polyline fill="#FFFFFF" stroke="#424242" stroke-width="0.5" stroke-miterlimit="10" points="196.5,195.7 191.8,195.4 187,190.9 184.8,192.3 188.5,198.9 183,206.8 187.6,208.3 193.1,201.2 196.5,201.2"/>',
                            '<polyline fill="#FFFFFF" stroke="#424242" stroke-width="0.5" stroke-miterlimit="10" points="196.4,195.7 201.1,195.4 205.9,190.9 208.1,192.3 204.4,198.9 209.9,206.8 205.3,208.3 199.8,201.2 196.4,201.2"/>',
                            '<polygon fill="#FFFFFF" stroke="#424242" stroke-width="0.5" stroke-miterlimit="10" points="123.8,189.5 126.3,203 129.2,204.4 127.5,189.5"/>',
                            '<polygon fill="#FFFFFF" stroke="#424242" stroke-width="0.5" stroke-miterlimit="10" points="265.8,189.4 263.3,203.7 284.3,200.6 285.3,189.4"/>'
                        )
                    )
                )
            );
    }

    /// @dev Accessory N°15 => No Face
    function item_15() public pure returns (string memory) {
        return
            base(
                string(
                    abi.encodePacked(
                        '<path fill="#F5F4F3" stroke="#000000" stroke-miterlimit="10" d="M285.5,177.9c0,68.3-19.6,127.3-77.9,128.2 c-58.4,0.9-74.4-57.1-74.4-125.4s14.4-103.5,72.7-103.5C266.7,77.2,285.5,109.6,285.5,177.9z"/>',
                        '<path opacity="0.08" d="M285.4,176.9c0,68.3-19.4,127.6-78,129.3 c27.2-17.6,28.3-49.1,28.3-117.3s23.8-86-30-111.6C266.4,77.3,285.4,108.7,285.4,176.9z"/>',
                        '<ellipse cx="243.2" cy="180.7" rx="16.9" ry="6.1"/>',
                        '<path d="M231.4,273.6c0.3-7.2-12.1-6.1-27.2-6.1s-27.4-1.4-27.2,6.1c0.1,3.4,12.1,6.1,27.2,6.1S231.3,277,231.4,273.6z"/>',
                        '<ellipse cx="162" cy="180.5" rx="16.3" ry="6"/>',
                        '<path fill="#F2EDED" stroke="#000000" stroke-linecap="round" stroke-miterlimit="10" d="M149.7,191.4c0,0,6.7,5.8,20.5,0.6"/>',
                        '<path fill="#F2EDED" stroke="#000000" stroke-linecap="round" stroke-miterlimit="10" d="M232.9,191.3c0,0,6.6,5.7,20.4,0.6"/>',
                        '<path fill="#F2EDED" stroke="#000000" stroke-linecap="round" stroke-miterlimit="10" d="M192.7,285.1c0,0,9.2,3.5,21.6,0"/>',
                        '<path fill="#996DAD" d="M150.8,200.5c1.5-3.6,17.2-3.4,18.8-0.4c1.8,3.2-4.8,45.7-6.6,46C159.8,246.8,148.1,211.1,150.8,200.5z"/>',
                        '<path fill="#996DAD" d="M233.9,199.8c1.5-3.6,18-2.7,19.7,0.3c3.7,6.4-6.5,45.5-9.3,45.4C241,245.2,231.1,210.4,233.9,199.8z"/>',
                        '<path fill="#996DAD" d="M231.3,160.6c1.3,2.3,14.7,2.1,16.1,0.2c1.6-2-4.1-27.7-7.2-28.2C236.9,132.2,229,154.1,231.3,160.6z"/>',
                        '<path fill="#996DAD" d="M152.9,163.2c1.3,2.3,14.7,2.1,16.1,0.2c1.6-2-4.1-27.7-7.2-28.2C158.6,134.8,150.6,156.6,152.9,163.2z"/>'
                    )
                )
            );
    }

    /// @dev Generate glasses with the given color and opacity
    function glasses(
        string memory color,
        string memory stroke,
        string memory opacity
    ) private pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<circle fill="none" stroke="#',
                    stroke,
                    '" stroke-miterlimit="10" cx="161.5" cy="201.7" r="23.9"/>',
                    '<circle fill="none" stroke="#',
                    stroke,
                    '" stroke-miterlimit="10" cx="232.9" cy="201.7" r="23.9"/>',
                    '<circle opacity="',
                    opacity,
                    '" fill="#',
                    color,
                    '" cx="161.5" cy="201.7" r="23.9"/>',
                    abi.encodePacked(
                        '<circle opacity="',
                        opacity,
                        '" fill="#',
                        color,
                        '" cx="232.9" cy="201.7" r="23.9"/>',
                        '<path fill="none" stroke="#',
                        stroke,
                        '" stroke-miterlimit="10" d="M256.8,201.7l35.8-3.2 M185.5,201.7 c0,0,14.7-3.1,23.5,0 M137.6,201.7l-8.4-3.2"/>'
                    )
                )
            );
    }

    /// @dev Generate Monk Beads SVG with the given color
    function monkBeads(string memory color) private pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<g fill="#',
                    color,
                    '" stroke="#2B232B" stroke-miterlimit="10" stroke-width="0.75">',
                    '<ellipse transform="matrix(0.9999 -1.689662e-02 1.689662e-02 0.9999 -5.3439 3.0256)" cx="176.4" cy="317.8" rx="7.9" ry="8"/>',
                    '<ellipse transform="matrix(0.9999 -1.689662e-02 1.689662e-02 0.9999 -5.458 3.2596)" cx="190.2" cy="324.6" rx="7.9" ry="8"/>',
                    '<ellipse transform="matrix(0.9999 -1.689662e-02 1.689662e-02 0.9999 -5.5085 3.5351)" cx="206.4" cy="327.8" rx="7.9" ry="8"/>',
                    '<ellipse transform="matrix(0.9999 -1.689662e-02 1.689662e-02 0.9999 -5.4607 4.0856)" cx="239.1" cy="325.2" rx="7.9" ry="8"/>',
                    '<ellipse transform="matrix(0.9999 -1.693338e-02 1.693338e-02 0.9999 -5.386 4.3606)" cx="254.8" cy="320.2" rx="7.9" ry="8"/>',
                    '<ellipse transform="matrix(0.9999 -1.689662e-02 1.689662e-02 0.9999 -5.5015 3.8124)" cx="222.9" cy="327.5" rx="7.9" ry="8"/>',
                    "</g>",
                    '<path opacity="0.14" d="M182,318.4 c0.7,1.3-0.4,3.4-2.5,4.6c-2.1,1.2-4.5,1-5.2-0.3c-0.7-1.3,0.4-3.4,2.5-4.6C178.9,316.9,181.3,317,182,318.4z M190.5,325.7 c-2.1,1.2-3.2,3.2-2.5,4.6c0.7,1.3,3.1,1.5,5.2,0.3s3.2-3.2,2.5-4.6C195,324.6,192.7,324.5,190.5,325.7z M206.7,328.6 c-2.1,1.2-3.2,3.2-2.5,4.6c0.7,1.3,3.1,1.5,5.2,0.3c2.1-1.2,3.2-3.2,2.5-4.6C211.1,327.6,208.8,327.5,206.7,328.6z M223.2,328.4 c-2.1,1.2-3.2,3.2-2.5,4.6c0.7,1.3,3.1,1.5,5.2,0.3c2.1-1.2,3.2-3.2,2.5-4.6S225.3,327.3,223.2,328.4z M239.8,325.7 c-2.1,1.2-3.2,3.2-2.5,4.6c0.7,1.3,3.1,1.5,5.2,0.3c2.1-1.2,3.2-3.2,2.5-4.6C244.3,324.7,242,324.5,239.8,325.7z M255.7,320.9 c-2.1,1.2-3.2,3.2-2.5,4.6c0.7,1.3,3.1,1.5,5.2,0.3c2.1-1.2,3.2-3.2,2.5-4.6C260.1,319.9,257.8,319.7,255.7,320.9z"/>',
                    abi.encodePacked(
                        '<g fill="#FFFFFF" stroke="#FFFFFF" stroke-miterlimit="10">',
                        '<path d="M250.4,318.9c0.6,0.6,0.5-0.9,1.3-2c0.8-1,2.4-1.2,1.8-1.8 c-0.6-0.6-1.9-0.2-2.8,0.9C250,317,249.8,318.3,250.4,318.9z"/>',
                        '<path d="M234.4,323.6c0.7,0.6,0.5-0.9,1.4-1.9c1-1,2.5-1.1,1.9-1.7 c-0.7-0.6-1.9-0.3-2.8,0.7C234.1,321.7,233.8,323,234.4,323.6z"/>',
                        '<path d="M218.2,325.8c0.6,0.6,0.6-0.9,1.4-1.8c1-1,2.5-1,1.9-1.6 c-0.6-0.6-1.9-0.4-2.8,0.6C217.8,323.9,217.6,325.2,218.2,325.8z"/>',
                        '<path d="M202.1,325.5c0.6,0.6,0.6-0.9,1.7-1.7s2.6-0.8,2-1.5 c-0.6-0.6-1.8-0.5-2.9,0.4C202,323.5,201.5,324.8,202.1,325.5z"/>',
                        '<path d="M186.2,322c0.6,0.6,0.6-0.9,1.7-1.7c1-0.8,2.6-0.8,2-1.5 c-0.6-0.6-1.8-0.5-2.9,0.3C186,320.1,185.7,321.4,186.2,322z"/>',
                        '<path d="M171.7,315.4c0.6,0.6,0.6-0.9,1.5-1.8s2.5-0.9,1.9-1.6 s-1.9-0.4-2.8,0.5C171.5,313.5,171.1,314.9,171.7,315.4z"/>',
                        "</g>"
                    )
                )
            );
    }

    /// @notice Return the accessory name of the given id
    /// @param id The accessory Id
    function getItemNameById(uint8 id) public pure returns (string memory name) {
        name = "";
        if (id == 1) {
            name = "Classic";
        } else if (id == 2) {
            name = "Glasses";
        } else if (id == 3) {
            name = "Bow Tie";
        } else if (id == 4) {
            name = "Monk Beads Classic";
        } else if (id == 5) {
            name = "Monk Beads Silver";
        } else if (id == 6) {
            name = "Power Pole";
        } else if (id == 7) {
            name = "Vintage Glasses";
        } else if (id == 8) {
            name = "Monk Beads Gold";
        } else if (id == 9) {
            name = "Eye Patch";
        } else if (id == 10) {
            name = "Sun Glasses";
        } else if (id == 11) {
            name = "Monk Beads Diamond";
        } else if (id == 12) {
            name = "Horns";
        } else if (id == 13) {
            name = "Halo";
        } else if (id == 14) {
            name = "Saiki Power";
        } else if (id == 15) {
            name = "No Face";
        }
    }

    /// @dev The base SVG for the accessory
    function base(string memory children) private pure returns (string memory) {
        return string(abi.encodePacked('<g id="Accessory">', children, "</g>"));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

pragma abicoder v2;

import "base64-sol/base64.sol";

/// @title Earrings SVG generator
library EarringsDetail {
    /// @dev Earrings N°1 => Classic
    function item_1() public pure returns (string memory) {
        return "";
    }

    /// @dev Earrings N°2 => Circle
    function item_2() public pure returns (string memory) {
        return base(circle("000000"));
    }

    /// @dev Earrings N°3 => Circle Silver
    function item_3() public pure returns (string memory) {
        return base(circle("C7D2D4"));
    }

    /// @dev Earrings N°4 => Ring
    function item_4() public pure returns (string memory) {
        return base(ring("000000"));
    }

    /// @dev Earrings N°5 => Circle Gold
    function item_5() public pure returns (string memory) {
        return base(circle("FFDD00"));
    }

    /// @dev Earrings N°6 => Ring Gold
    function item_6() public pure returns (string memory) {
        return base(ring("FFDD00"));
    }

    /// @dev Earrings N°7 => Heart
    function item_7() public pure returns (string memory) {
        return
            base(
                string(
                    abi.encodePacked(
                        '<path d="M284.3,247.9c0.1,0.1,0.1,0.1,0.2,0.1s0.2,0,0.2-0.1l3.7-3.8c1.5-1.6,0.4-4.3-1.8-4.3c-1.3,0-1.9,1-2.2,1.2c-0.2-0.2-0.8-1.2-2.2-1.2c-2.2,0-3.3,2.7-1.8,4.3L284.3,247.9z"/>',
                        '<path d="M135,246.6c0,0,0.1,0.1,0.2,0.1s0.1,0,0.2-0.1l3.1-3.1c1.3-1.3,0.4-3.6-1.5-3.6c-1.1,0-1.6,0.8-1.8,1c-0.2-0.2-0.7-1-1.8-1c-1.8,0-2.8,2.3-1.5,3.6L135,246.6z"/>'
                    )
                )
            );
    }

    /// @dev Earrings N°8 => Gold
    function item_8() public pure returns (string memory) {
        return
            base(
                string(
                    abi.encodePacked(
                        '<path d="M298.7,228.1l-4.7-1.6c0,0-0.1,0-0.1-0.1v-0.1c2.8-2.7,7.1-17.2,7.2-17.4c0-0.1,0.1-0.1,0.1-0.1l0,0c5.3,1.1,5.6,2.2,5.7,2.4c-3.1,5.4-8,16.7-8.1,16.8C298.9,228,298.8,228.1,298.7,228.1C298.8,228.1,298.8,228.1,298.7,228.1z" style="fill: #fff700;stroke: #000;stroke-miterlimit: 10;stroke-width: 0.75px"/>'
                    )
                )
            );
    }

    /// @dev Earrings N°9 => Circle Diamond
    function item_9() public pure returns (string memory) {
        return base(circle("AAFFFD"));
    }

    /// @dev Earrings N°10 => Drop Heart
    function item_10() public pure returns (string memory) {
        return
            base(
                string(
                    abi.encodePacked(
                        drop(true),
                        '<path fill="#F44336" d="M285.4,282.6c0.1,0.1,0.2,0.2,0.4,0.2s0.3-0.1,0.4-0.2l6.7-6.8c2.8-2.8,0.8-7.7-3.2-7.7c-2.4,0-3.5,1.8-3.9,2.1c-0.4-0.3-1.5-2.1-3.9-2.1c-4,0-6,4.9-3.2,7.7L285.4,282.6z"/>',
                        drop(false),
                        '<path fill="#F44336" d="M134.7,282.5c0.1,0.1,0.2,0.2,0.4,0.2s0.3-0.1,0.4-0.2l6.7-6.8c2.8-2.8,0.8-7.7-3.2-7.7c-2.4,0-3.5,1.8-3.9,2.1c-0.4-0.3-1.5-2.1-3.9-2.1c-4,0-6,4.9-3.2,7.7L134.7,282.5z"/>'
                    )
                )
            );
    }

    /// @dev Earrings N11 => Ether
    function item_11() public pure returns (string memory) {
        return
            base(
                string(
                    abi.encodePacked(
                        '<path d="M285.7,242.7l-4.6-2.2l4.6,8l4.6-8L285.7,242.7z"/>',
                        '<path d="M289.8,238.9l-4.1-7.1l-4.1,7.1l4.1-1.9L289.8,238.9z"/>',
                        '<path d="M282,239.9l3.7,1.8l3.8-1.8l-3.8-1.8L282,239.9z"/>',
                        '<path d="M134.5,241.8l-3.4-1.9l3.7,7.3l2.8-7.7L134.5,241.8z"/>',
                        '<path d="M137.3,238l-3.3-6.5l-2.5,6.9l2.8-2L137.3,238z"/>',
                        '<path d="M131.7,239.2l2.8,1.5l2.6-1.8l-2.8-1.5L131.7,239.2z"/>'
                    )
                )
            );
    }

    /// @dev Earrings N°12 => Drop Ether
    function item_12() public pure returns (string memory) {
        return
            base(
                string(
                    abi.encodePacked(
                        drop(true),
                        '<path d="M285.7,279.7l-4.6-2.2l4.6,8l4.6-8L285.7,279.7z"/>',
                        '<path d="M289.8,275.9l-4.1-7.1l-4.1,7.1l4.1-1.9L289.8,275.9z"/>',
                        '<path d="M282,276.9l3.7,1.8l3.8-1.8l-3.8-1.8L282,276.9z"/><path d="M282,276.9l3.7,1.8l3.8-1.8l-3.8-1.8L282,276.9z"/>',
                        drop(false),
                        '<path d="M135.1,279.7l-4-2.2l4,8l4-8L135.1,279.7z"/>',
                        '<path d="M138.7,275.9l-3.6-7.1l-3.6,7.1l3.6-1.9L138.7,275.9z"/>',
                        '<path d="M131.8,276.9l3.3,1.8l3.3-1.8l-3.3-1.8L131.8,276.9z"/>'
                    )
                )
            );
    }

    /// @dev earring drop
    function drop(bool right) private pure returns (string memory) {
        return
            string(
                right
                    ? abi.encodePacked(
                        '<circle cx="285.7" cy="243.2" r="3.4"/>',
                        '<line fill="none" stroke="#000000" stroke-miterlimit="10" x1="285.7" y1="243.2" x2="285.7" y2="270.2"/>'
                    )
                    : abi.encodePacked(
                        '<ellipse cx="135.1" cy="243.2" rx="3" ry="3.4"/>',
                        '<line fill="none" stroke="#000000" stroke-miterlimit="10" x1="135.1" y1="243.2" x2="135.1" y2="270.2"/>'
                    )
            );
    }

    /// @dev Generate circle SVG with the given color
    function circle(string memory color) private pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<ellipse fill="#',
                    color,
                    '" stroke="#000000" cx="135.1" cy="243.2" rx="3" ry="3.4"/>',
                    '<ellipse fill="#',
                    color,
                    '" stroke="#000000" cx="286.1" cy="243.2" rx="3.3" ry="3.4"/>'
                )
            );
    }

    /// @dev Generate ring SVG with the given color
    function ring(string memory color) private pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<path fill="none" stroke="#',
                    color,
                    '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" stroke-miterlimit="10" d="M283.5,246c0,0-4.2,2-3.1,6.1c1,4.1,5.1,3.6,5.4,3.5s3.1-0.9,3-5"/>',
                    '<path fill="none" stroke="#',
                    color,
                    '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" stroke-miterlimit="10" d="M134.3,244.7c0,0-4.2,2-3.1,6.1c1,4.1,5.1,3.6,5.4,3.5c0.3-0.1,3.1-0.9,3-5"/>'
                )
            );
    }

    /// @notice Return the earring name of the given id
    /// @param id The earring Id
    function getItemNameById(uint8 id) public pure returns (string memory name) {
        name = "";
        if (id == 1) {
            name = "Classic";
        } else if (id == 2) {
            name = "Circle";
        } else if (id == 3) {
            name = "Circle Silver";
        } else if (id == 4) {
            name = "Ring";
        } else if (id == 5) {
            name = "Circle Gold";
        } else if (id == 6) {
            name = "Ring Gold";
        } else if (id == 7) {
            name = "Heart";
        } else if (id == 8) {
            name = "Gold";
        } else if (id == 9) {
            name = "Circle Diamond";
        } else if (id == 10) {
            name = "Drop Heart";
        } else if (id == 11) {
            name = "Ether";
        } else if (id == 12) {
            name = "Drop Ether";
        }
    }

    /// @dev The base SVG for the earrings
    function base(string memory children) private pure returns (string memory) {
        return string(abi.encodePacked('<g id="Earrings">', children, "</g>"));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

pragma abicoder v2;

import "base64-sol/base64.sol";
import "./constants/Colors.sol";

/// @title Masks SVG generator
library MaskDetail {
    /// @dev Mask N°1 => Maskless
    function item_1() public pure returns (string memory) {
        return "";
    }

    /// @dev Mask N°2 => Classic
    function item_2() public pure returns (string memory) {
        return base(classicMask("575673"));
    }

    /// @dev Mask N°3 => Blue
    function item_3() public pure returns (string memory) {
        return base(classicMask(Colors.BLUE));
    }

    /// @dev Mask N°4 => Pink
    function item_4() public pure returns (string memory) {
        return base(classicMask(Colors.PINK));
    }

    /// @dev Mask N°5 => Black
    function item_5() public pure returns (string memory) {
        return base(classicMask(Colors.BLACK));
    }

    /// @dev Mask N°6 => Bandage White
    function item_6() public pure returns (string memory) {
        return base(string(abi.encodePacked(classicMask("F5F5F5"), bandage())));
    }

    /// @dev Mask N°7 => Bandage Classic
    function item_7() public pure returns (string memory) {
        return base(string(abi.encodePacked(classicMask("575673"), bandage())));
    }

    /// @dev Mask N°8 => Nihon
    function item_8() public pure returns (string memory) {
        return
            base(
                string(
                    abi.encodePacked(
                        classicMask("F5F5F5"),
                        '<ellipse opacity="0.87" fill="#FF0039" cx="236.1" cy="259.8" rx="13.4" ry="14.5"/>'
                    )
                )
            );
    }

    /// @dev Generate classic mask SVG with the given color
    function classicMask(string memory color) public pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<path fill="#',
                    color,
                    '" stroke="#000000" stroke-miterlimit="10" d=" M175.7,317.7c0,0,20,15.1,82.2,0c0,0-1.2-16.2,3.7-46.8l14-18.7c0,0-41.6-27.8-77.6-37.1c-1.1-0.3-3-0.7-4-0.2 c-19.1,8.1-51.5,33-51.5,33s7.5,20.9,9.9,22.9s24.8,19.4,24.8,19.4s0,0,0,0.1C177.3,291.2,178,298.3,175.7,317.7z"/>',
                    '<path fill="none" stroke="#000000" stroke-linecap="round" stroke-miterlimit="10" d="M177.1,290.1 c0,0,18.3,14.7,26.3,15s15.1-3.8,15.9-4.3c0.9-0.4,11.6-4.5,25.2-14.1"/>',
                    '<line fill="none" stroke="#000000" stroke-linecap="round" stroke-miterlimit="10" x1="266.6" y1="264.4" x2="254.5" y2="278.7"/>',
                    '<path opacity="0.21" d="M197.7,243.5l-7.9-3.5c-0.4-0.2-0.5-0.7-0.2-1.1l3.2-3.3 c0.4-0.4,1-0.5,1.5-0.3l12.7,4.6c0.6,0.2,0.6,1.1-0.1,1.3l-8.7,2.4C198,243.6,197.8,243.6,197.7,243.5z"/>',
                    '<path opacity="0.24" fill-rule="evenodd" clip-rule="evenodd" d="M177.2,291.1 c0,0,23,32.3,39.1,28.1s41.9-20.9,41.9-20.9c1.2-8.7,2.1-18.9,3.2-27.6c-4.6,4.7-12.8,13.2-20.9,18.3c-5,3.1-21.2,14.5-34.9,16 C198.3,305.8,177.2,291.1,177.2,291.1z"/>'
                )
            );
    }

    /// @dev Generate bandage SVG
    function bandage() public pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<path fill="none" stroke="#000000" stroke-miterlimit="10" d="M142.9,247.9c34.3-21.9,59.3-27.4,92.4-18.5 M266.1,264.1c-21-16.2-60.8-36.4-73.9-29.1c-12.8,7.1-36.4,15.6-45.8,22.7 M230.9,242.8c-32.4,2.5-54.9,0.1-81.3,22.7 M259.8,272.3c-19.7-13.9-46.1-24.1-70.3-25.9 M211.6,250.1c-18.5,1.9-41.8,11.2-56.7,22 M256.7,276.1c-46-11.9-50.4-25.6-94,2.7 M229,267.5c-19.9,0.3-42,9.7-60.6,15.9 M238.4,290.6c-11-3.9-39.3-14.6-51.2-14 M214.5,282.5c-10.3-2.8-23,7.6-30.7,12.6 M221.6,299.8c-3.8-5.5-22.1-7.1-27-11.4 M176.2,312.4c8.2,7.3,65.1,6.4,81.2-2.6 M177.3,305.3c11.1,3.6,15.5,4.2,34.6,2.9 c14.5-1,33.2-2.7,46.2-9.2 M224.4,298.4c9,0,25.6-3.3,34.1-6 M249,285.8c3.6-0.2,7.1-1,10.5-2.3 M215.1,225.7 c-6-1.3-11.9-2.3-17.9-3.6c-4.8-1-9.8-2.1-14.7-1.3"/>'
                )
            );
    }

    /// @notice Return the mask name of the given id
    /// @param id The mask Id
    function getItemNameById(uint8 id) public pure returns (string memory name) {
        name = "";
        if (id == 1) {
            name = "Maskless";
        } else if (id == 2) {
            name = "Classic";
        } else if (id == 3) {
            name = "Blue";
        } else if (id == 4) {
            name = "Pink";
        } else if (id == 5) {
            name = "Black";
        } else if (id == 6) {
            name = "Bandage White";
        } else if (id == 7) {
            name = "Bandage Classic";
        } else if (id == 8) {
            name = "Nihon";
        }
    }

    /// @dev The base SVG for the eyes
    function base(string memory children) private pure returns (string memory) {
        return string(abi.encodePacked('<g id="Mask">', children, "</g>"));
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

pragma abicoder v2;

/// @title Color constants
library Colors {
    string internal constant BLACK = "33333D";
    string internal constant BLACK_DEEP = "000000";
    string internal constant BLUE = "7FBCFF";
    string internal constant BROWN = "735742";
    string internal constant GRAY = "7F8B8C";
    string internal constant GREEN = "2FC47A";
    string internal constant PINK = "FF78A9";
    string internal constant PURPLE = "A839A4";
    string internal constant RED = "D9005E";
    string internal constant SAIKI = "F02AB6";
    string internal constant WHITE = "F7F7F7";
    string internal constant YELLOW = "EFED8F";
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

