// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

pragma abicoder v2;

import "./libraries/NFTDescriptor.sol";
import "./libraries/DetailHelper.sol";
import "base64-sol/base64.sol";
import "./interfaces/IRobotDescriptor.sol";
import "./interfaces/IRobot.sol";

/// @title Describes Robot
/// @notice Produces a string containing the data URI for a JSON metadata string
contract RobotDescriptor is IRobotDescriptor {
    /// @dev Max value for defining probabilities
    uint256 internal constant MAX = 100000;

    uint256[] internal BACKGROUND_ITEMS = [9050, 8725, 8500, 8300, 8125, 7950, 7000, 0];
    uint256[] internal SKIN_ITEMS = [66000, 32700, 200, 0];
    uint256[] internal NOSE_ITEMS = [82000, 66000, 51000, 37000, 24000, 12000, 200, 0];
    uint256[] internal MARK_ITEMS = [
        91800,
        85700,
        79700,
        73800,
        68000,
        62600,
        57300,
        52100,
        47000,
        42000,
        37200,
        32600,
        28200,
        24000,
        20000,
        16100,
        12300,
        8700,
        5200,
        2500,
        200,
        0
    ];
    uint256[] internal EYEBROW_ITEMS = [
        92000,
        84000,
        76000,
        68000,
        61000,
        54000,
        47000,
        42100,
        38100,
        34100,
        30100,
        26100,
        22100,
        18100,
        15100,
        12100,
        9100,
        6100,
        3100,
        200,
        0
    ];
    uint256[] internal MASK_ITEMS = [
        91000,
        83000,
        75000,
        67000,
        59000,
        52000,
        45000,
        38000,
        31000,
        24000,
        20000,
        16000,
        12000,
        8000,
        5000,
        3010,
        2010,
        1010,
        10,
        0
    ];
    uint256[] internal EARRINGS_ITEMS = [
        90100,
        81600,
        73100,
        64600,
        56100,
        48100,
        40100,
        33100,
        26100,
        19100,
        12100,
        8100,
        4100,
        200,
        0
    ];
    uint256[] internal ACCESSORY_ITEMS = [
        88000,
        79500,
        71500,
        64000,
        56500,
        49500,
        42500,
        35750,
        29000,
        22500,
        16000,
        10000,
        4000,
        300,
        100,
        0
    ];
    uint256[] internal MOUTH_ITEMS = [
        92000,
        84400,
        77100,
        69900,
        62800,
        55900,
        49100,
        42400,
        35800,
        29300,
        22800,
        16500,
        10500,
        8000,
        5500,
        3500,
        1500,
        0
    ];
    uint256[] internal HAIR_ITEMS = [
        90350,
        82100,
        74100,
        66350,
        59100,
        52100,
        45350,
        39100,
        33100,
        27350,
        22100,
        17100,
        12350,
        8100,
        4100,
        200,
        0
    ];
    uint256[] internal EYE_ITEMS = [
        93000,
        86000,
        79000,
        73000,
        67000,
        61000,
        55000,
        49500,
        44500,
        39500,
        35000,
        30500,
        26500,
        22500,
        18500,
        15000,
        12000,
        9000,
        6000,
        3000,
        1000,
        200,
        0
    ];

    /// @inheritdoc IRobotDescriptor
    function tokenURI(IRobot robot, uint256 tokenId) external view override returns (string memory) {
        NFTDescriptor.SVGParams memory params = getSVGParams(robot, tokenId);
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

    /// @inheritdoc IRobotDescriptor
    function generateHairId(uint256 tokenId, uint256 seed) external view override returns (uint8) {
        return DetailHelper.generate(MAX, seed, HAIR_ITEMS, this.generateHairId.selector, tokenId);
    }

    /// @inheritdoc IRobotDescriptor
    function generateEyeId(uint256 tokenId, uint256 seed) external view override returns (uint8) {
        return DetailHelper.generate(MAX, seed, EYE_ITEMS, this.generateEyeId.selector, tokenId);
    }

    /// @inheritdoc IRobotDescriptor
    function generateEyebrowId(uint256 tokenId, uint256 seed) external view override returns (uint8) {
        return DetailHelper.generate(MAX, seed, EYEBROW_ITEMS, this.generateEyebrowId.selector, tokenId);
    }

    /// @inheritdoc IRobotDescriptor
    function generateNoseId(uint256 tokenId, uint256 seed) external view override returns (uint8) {
        return DetailHelper.generate(MAX, seed, NOSE_ITEMS, this.generateNoseId.selector, tokenId);
    }

    /// @inheritdoc IRobotDescriptor
    function generateMouthId(uint256 tokenId, uint256 seed) external view override returns (uint8) {
        return DetailHelper.generate(MAX, seed, MOUTH_ITEMS, this.generateMouthId.selector, tokenId);
    }

    /// @inheritdoc IRobotDescriptor
    function generateMarkId(uint256 tokenId, uint256 seed) external view override returns (uint8) {
        return DetailHelper.generate(MAX, seed, MARK_ITEMS, this.generateMarkId.selector, tokenId);
    }

    /// @inheritdoc IRobotDescriptor
    function generateEarringsId(uint256 tokenId, uint256 seed) external view override returns (uint8) {
        return DetailHelper.generate(MAX, seed, EARRINGS_ITEMS, this.generateEarringsId.selector, tokenId);
    }

    /// @inheritdoc IRobotDescriptor
    function generateAccessoryId(uint256 tokenId, uint256 seed) external view override returns (uint8) {
        return DetailHelper.generate(MAX, seed, ACCESSORY_ITEMS, this.generateAccessoryId.selector, tokenId);
    }

    /// @inheritdoc IRobotDescriptor
    function generateMaskId(uint256 tokenId, uint256 seed) external view override returns (uint8) {
        return DetailHelper.generate(MAX, seed, MASK_ITEMS, this.generateMaskId.selector, tokenId);
    }

    /// @inheritdoc IRobotDescriptor
    function generateSkinId(uint256 tokenId, uint256 seed) external view override returns (uint8) {
        return DetailHelper.generate(MAX, seed, SKIN_ITEMS, this.generateSkinId.selector, tokenId);
    }

    /// @dev Get SVGParams from Robot.Detail
    function getSVGParams(IRobot robot, uint256 tokenId)
        private
        view
        returns (NFTDescriptor.SVGParams memory)
    {
        IRobot.Detail memory detail = robot.details(tokenId);
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
                background: 0,
                timestamp: detail.timestamp,
                creator: detail.creator
            });
    }

    function getBackgroundId(NFTDescriptor.SVGParams memory params) private view returns (uint8) {
        uint256 score = itemScoreProba(params.hair, HAIR_ITEMS) +
            itemScoreProba(params.accessory, ACCESSORY_ITEMS) +
            itemScoreProba(params.earring, EARRINGS_ITEMS) +
            itemScoreProba(params.mask, MASK_ITEMS) +
            itemScoreProba(params.mouth, MOUTH_ITEMS) +
            itemScoreProba(params.skin, SKIN_ITEMS) +
            itemScoreProba(params.nose, NOSE_ITEMS) +
            itemScoreProba(params.mark, MARK_ITEMS) +
            itemScoreProba(params.eye, EYE_ITEMS) +
            itemScoreProba(params.eyebrow, EYEBROW_ITEMS);
        return DetailHelper.pickItems(score, BACKGROUND_ITEMS);
    }

    /// @dev Get item score based on his probability
    function itemScoreProba(uint8 item, uint256[] memory ITEMS) private pure returns (uint256) {
        uint256 raw = ((item == 1 ? MAX : ITEMS[item - 2]) - ITEMS[item - 1]);
        return multiplicator(raw) / 100;
    }

    /// @dev Get item score based on his index
    function itemScorePosition(uint8 item, uint256[] memory ITEMS) private pure returns (uint256) {
        uint256 raw = ITEMS[item - 1];
        return multiplicator(raw) / 100;
    }

    /// @dev multiply score if rare
    function multiplicator(uint256 raw) private pure returns (uint256 result) {
        if (raw > 10000) {
            result = raw * 12;
        } else if (raw > 2000) {
            result = raw * 6;
        } else if (raw > 1000) {
            result = raw * 3;
        } else {
            result = raw;
        }
    }
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
                    DetailHelper.getDetailSVG(address(AccessoryDetail), params.accessory),
                    DetailHelper.getDetailSVG(address(MaskDetail), params.mask),
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
                    " Robot ",
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
                    '<svg version="1.1" xmlns="http://www.w3.org/2000/svg" x="0px" y="0px" xmlns:xlink="http://www.w3.org/1999/xlink"',
                    ' viewBox="0 0 420 420" style="enable-background:new 0 0 420 420;" xml:space="preserve">'
                )
            );
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
                        getJsonAttribute("Background", BackgroundDetail.getItemNameById(params.background), true),
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

import "./IRobot.sol";

/// @title Describes Robot via URI
interface IRobotDescriptor {
    /// @notice Produces the URI describing a particular Robot (token id)
    /// @dev Note this URI may be a data: URI with the JSON contents directly inlined
    /// @param robot The robot contract
    /// @param tokenId The ID of the token for which to produce a description
    /// @return The URI of the ERC721-compliant metadata
    function tokenURI(IRobot robot, uint256 tokenId) external view returns (string memory);

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

/// @title Robot NFTs Interface
interface IRobot {
    /// @notice Details about the Robot
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
        uint256 timestamp;
        address creator;
    }

    /// @notice Returns the details associated with a given token ID.
    /// @dev Throws if the token ID is not valid.
    /// @param tokenId The ID of the token that represents the Robot
    /// @return detail memory
    function details(uint256 tokenId) external view returns (Detail memory detail);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

pragma abicoder v2;

import "base64-sol/base64.sol";

/// @title Background SVG generator
library BackgroundDetail {
    /// @dev Background N°1 => Ordinary
    function item_1() public pure returns (string memory) {
        return
            base(
                string(
                    abi.encodePacked(
                        '<g id="Ordinary"><radialGradient id="radial-gradient" cx="210" cy="212" r="210" gradientTransform="matrix(1, 0, 0, -1, 0, 422)" gradientUnits="userSpaceOnUse"> <stop offset="0" stop-color="#726680"/> <stop offset="1" stop-color="#4a4a4a"/> </radialGradient>',
                        background("323232"),
                        "</g>"
                    )
                )
            );
    }

    /// @dev Background N°2 => Uncommon
    function item_2() public pure returns (string memory) {
        return
            base(
                string(
                    abi.encodePacked(
                        '<g id="Uncommon"><radialGradient id="radial-gradient" cx="210" cy="212" r="210" gradientTransform="matrix(1, 0, 0, -1, 0, 422)" gradientUnits="userSpaceOnUse"> <stop offset="0" stop-color="#2fa675"/> <stop offset="1" stop-color="#106c48"/> </radialGradient>',
                        background("125443"),
                        "</g>"
                    )
                )
            );
    }

    /// @dev Background N°3 => Surprising
    function item_3() public pure returns (string memory) {
        return
            base(
                string(
                    abi.encodePacked(
                        '<g id="Surprising"><radialGradient id="radial-gradient" cx="210" cy="212" r="210" gradientTransform="matrix(1, 0, 0, -1, 0, 422)" gradientUnits="userSpaceOnUse"> <stop offset="0" stop-color="#4195ad"/> <stop offset="1" stop-color="#2b6375"/> </radialGradient>',
                        background("204b59"),
                        "</g>"
                    )
                )
            );
    }

    /// @dev Background N°4 => Impressive
    function item_4() public pure returns (string memory) {
        return
            base(
                string(
                    abi.encodePacked(
                        '<g id="Impressive"><radialGradient id="radial-gradient" cx="210" cy="212" r="210" gradientTransform="matrix(1, 0, 0, -1, 0, 422)" gradientUnits="userSpaceOnUse"> <stop offset="0" stop-color="#991fc4"/> <stop offset="1" stop-color="#61147d"/> </radialGradient>',
                        background("470f5c"),
                        "</g>"
                    )
                )
            );
    }

    /// @dev Background N°5 => Bloody
    function item_5() public pure returns (string memory) {
        return
            base(
                string(
                    abi.encodePacked(
                        '<g id="Bloody"><radialGradient id="radial-gradient" cx="210" cy="212" r="210" gradientTransform="matrix(1, 0, 0, -1, 0, 422)" gradientUnits="userSpaceOnUse"> <stop offset="0" stop-color="#8c134f"/> <stop offset="1" stop-color="#6d0738"/> </radialGradient>',
                        background("410824"),
                        "</g>"
                    )
                )
            );
    }

    /// @dev Background N°6 => Phenomenal
    function item_6() public pure returns (string memory) {
        return
            base(
                string(
                    abi.encodePacked(
                        '<g id="Phenomenal"><radialGradient id="radial-gradient" cx="210" cy="212" r="210" gradientTransform="matrix(1, 0, 0, -1, 0, 422)" gradientUnits="userSpaceOnUse"> <stop offset="0" stop-color="#fff38d"/> <stop offset="1" stop-color="#d68e4b"/> </radialGradient>',
                        background("bd4e4a"),
                        "</g>"
                    )
                )
            );
    }

    /// @dev Background N°7 => Artistic
    function item_7() public pure returns (string memory) {
        return
            base(
                string(
                    abi.encodePacked(
                        '<g id="Artistic"><radialGradient id="radial-gradient" cx="210" cy="-1171.6" r="210" gradientTransform="matrix(1, 0, 0, -1, 0, -961.6)" gradientUnits="userSpaceOnUse"> <stop offset="0.5" stop-color="#fff9ab"/> <stop offset="1" stop-color="#16c7b5"/> </radialGradient>',
                        background("ff9fd7"),
                        "</g>"
                    )
                )
            );
    }

    /// @dev Background N°8 => Unreal
    function item_8() public pure returns (string memory) {
        return
            base(
                string(
                    abi.encodePacked(
                        '<g id="Unreal"><radialGradient id="radial-gradient" cx="210.05" cy="209.5" r="209.98" gradientUnits="userSpaceOnUse"> <stop offset="0" stop-color="#634363"/><stop offset="1" stop-color="#04061c"/></radialGradient>',
                        background("000"),
                        "</g>"
                    )
                )
            );
    }

    function background(string memory color) private pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<path d="M389.9,419.5H30.1a30,30,0,0,1-30-30V29.5a30,30,0,0,1,30-30H390a30,30,0,0,1,30,30v360A30.11,30.11,0,0,1,389.9,419.5Z" transform="translate(0 0.5)" fill="url(#radial-gradient)"/> <g> <path id="Main_Spin" fill="#',
                    color,
                    '" stroke="#',
                    color,
                    '" stroke-miterlimit="10" d="M210,63.3c-192.6,3.5-192.6,290,0,293.4 C402.6,353.2,402.6,66.7,210,63.3z M340.8,237.5c-0.6,2.9-1.4,5.7-2.2,8.6c-43.6-13.6-80.9,37.8-54.4,75.1 c-4.9,3.2-10.1,6.1-15.4,8.8c-33.9-50.6,14.8-117.8,73.3-101.2C341.7,231.7,341.4,234.6,340.8,237.5z M331.4,265.5 c-7.9,17.2-19.3,32.4-33.3,44.7c-15.9-23.3,7.6-55.7,34.6-47.4C332.3,263.7,331.8,264.6,331.4,265.5z M332.5,209.6 C265,202.4,217,279,252.9,336.5c-5.8,1.9-11.7,3.5-17.7,4.7c-40.3-73.8,24.6-163.5,107.2-148c0.6,6,1.2,12.2,1.1,18.2 C339.9,210.6,336.2,210,332.5,209.6z M87.8,263.9c28.7-11.9,56,24,36.3,48.4C108.5,299.2,96.2,282.5,87.8,263.9z M144.3,312.7 c17.8-38.8-23.4-81.6-62.6-65.5c-1.7-5.7-2.9-11.5-3.7-17.4c60-20.6,112.7,49.4,76,101.5c-5.5-2.4-10.7-5.3-15.6-8.5 C140.7,319.6,142.7,316.3,144.3,312.7z M174.2,330.4c32.6-64-28.9-138.2-97.7-118c-0.3-6.1,0.4-12.4,0.9-18.5 c85-18.6,151.7,71.7,110.8,147.8c-6.1-1-12.2-2.4-18.1-4.1C171.6,335.3,173,332.9,174.2,330.4z M337,168.6c-7-0.7-14.4-0.8-21.4-0.2 c-43.1-75.9-167.4-75.9-210.7-0.2c-7.3-0.6-14.9,0-22.1,0.9C118.2,47.7,301.1,47.3,337,168.6z M281.1,175.9c-3,1.1-5.9,2.3-8.7,3.6 c-29.6-36.1-93.1-36.7-123.4-1.2c-5.8-2.5-11.9-4.5-18-6.1c36.6-50.4,122.9-50,159,0.7C286.9,173.8,284,174.8,281.1,175.9z M249.6,193.1c-2.4,1.8-4.7,3.6-7,5.6c-16.4-15.6-46-16.4-63.2-1.5c-4.7-3.8-9.6-7.3-14.7-10.5c23.9-24.1,69.1-23.5,92.2,1.3 C254.4,189.6,252,191.3,249.6,193.1z M211.9,239.2c-5.2-10.8-11.8-20.7-19.7-29.4c10.7-8.1,27.9-7.3,37.9,1.6 C222.8,219.7,216.7,229.1,211.9,239.2z"> <animateTransform attributeName="transform" begin="0s" dur="20s" type="rotate" from="-360 210 210" to="0 210 210" repeatCount="indefinite" /> </path> <g id="Spin_Inverse"> <circle fill="none" stroke="#',
                    color,
                    '" stroke-width="7" stroke-dasharray="22.2609,22.2609" cx="210" cy="210" r="163"> <animateTransform attributeName="transform" begin="0s" dur="20s" type="rotate" from="360 210 210" to="0 210 210" repeatCount="indefinite" /> </circle> </g> <g id="Spin"> <circle fill="none" stroke="#',
                    color,
                    '" stroke-width="7" stroke-dasharray="22.2041,22.2041" cx="210" cy="210" r="183.8"> <animateTransform attributeName="transform" begin="0s" dur="20s" type="rotate" from="-360 210 210" to="0 210 210" repeatCount="indefinite" /> </circle> </g> </g>'
                )
            );
    }

    /// @notice Return the skin name of the given id
    /// @param id The skin Id
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
            name = "Bloody";
        } else if (id == 6) {
            name = "Phenomenal";
        } else if (id == 7) {
            name = "Artistic";
        } else if (id == 8) {
            name = "Unreal";
        }
    }

    /// @dev The base SVG for the body
    function base(string memory children) private pure returns (string memory) {
        return string(abi.encodePacked('<g id="background">', children, "</g>"));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

pragma abicoder v2;

import "base64-sol/base64.sol";

/// @title Body SVG generator
library BodyDetail {
    /// @dev Body N°1 => Blood Robot
    function item_1() public pure returns (string memory) {
        return base(body("E31466"), "Robot Blood");
    }

    /// @dev Body N°2 => Moon Robot
    function item_2() public pure returns (string memory) {
        return base(body("2A2C38"), "Robot Moon");
    }

    /// @dev Body N°3 => Robot
    function item_3() public pure returns (string memory) {
        return base(body("FFDAEA"), "Robot");
    }

    /// @dev Body N°4 => Kintaro
    function item_4() public pure returns (string memory) {
        return
            base(
                '<linearGradient id="Neck" gradientUnits="userSpaceOnUse" x1="210.607" y1="386.503" x2="210.607" y2="256.4"> <stop offset="0" style="stop-color:#FFB451"/> <stop offset="0.4231" style="stop-color:#F7E394"/> <stop offset="1" style="stop-color:#FF9B43"/> </linearGradient> <path id="Neck" fill="url(#Neck)" stroke="#000000" stroke-width="3" stroke-linecap="round" stroke-miterlimit="10" d=" M175.8,276.8c0.8,10,1.1,20.2-0.7,30.4c-0.5,2.6-2.2,4.9-4.7,6.3c-16.4,8.9-41.4,17.2-70.2,25.2c-8.1,2.3-9.5,12.4-2.1,16.4 c71.9,38.5,146.3,42.5,224.4,7c7.2-3.3,7.3-12.7,0.1-16c-22.3-10.3-43.5-23.1-54.9-29.9c-3-1.8-4.8-5.2-5.1-8.3 c-0.7-7.7-0.7-12.5-0.1-22.2c0.7-11.3,2.6-21.2,4.6-29.3"/> <path id="Shadow" opacity="0.51" enable-background="new " d="M178.1,279c0,0,24.2,35,41,30.6s41.7-21.6,41.7-21.6 c1.2-9.1,1.9-17.1,3.7-26c-4.8,4.9-10.4,9.2-18.8,14.5c-11.3,7.1-22,11.3-29.8,13.3L178.1,279z"/> <linearGradient id="Head" gradientUnits="userSpaceOnUse" x1="222.2862" y1="294.2279" x2="222.2862" y2="63.3842"> <stop offset="0" style="stop-color:#FFB451"/> <stop offset="0.4231" style="stop-color:#F7E394"/> <stop offset="1" style="stop-color:#FF9B43"/> </linearGradient> <path id="Head" fill="url(#Head)" stroke="#000000" stroke-width="3" stroke-linecap="round" stroke-miterlimit="10" d=" M313.9,168.8c-0.6-0.8-12.2,8.3-12.2,8.3c0.3-4.9,11.8-53.1-17.3-86c-15.9-17.4-42.2-27.1-69.9-27.7 c-24.5-0.5-48.7,10.9-61.6,24.4c-33.5,35-20.1,98.2-20.1,98.2c0.6,10.9,9.1,63.4,21.3,74.6c0,0,33.7,25.7,42.4,30.6 c8.8,5,17.1,2.3,17.1,2.3c16-5.9,47.7-25.9,56.8-37.6l0.2-0.2c6.9-9.1,3.9-5.8,11.2-14.8c1.3-1.5,3-2.2,4.8-1.8 c4.1,0.8,11.7,1.3,13.3-7c2.4-11.5,2.6-25.1,8.6-35.5C311.7,190.8,315.9,184.6,313.9,168.8z"/> <linearGradient id="Ear" gradientUnits="userSpaceOnUse" x1="130.4586" y1="236.7255" x2="130.4586" y2="171.798"> <stop offset="0" style="stop-color:#FFB451"/> <stop offset="0.4231" style="stop-color:#F7E394"/> <stop offset="1" style="stop-color:#FF9B43"/> </linearGradient> <path id="Ear" fill="url(#Ear)" stroke="#000000" stroke-width="3" stroke-linecap="round" stroke-miterlimit="10" d=" M141.9,236c0.1,1.1-8.3,3-9.7-12.1s-7.3-31-12.6-48c-3.8-12.2,12.2,6.7,12.2,6.7"/> <g id="Ear2"> <path d="M304,174.7c-0.5,1.3-0.3,2.2-1.2,3.1c-0.9,0.8-2.3,2.1-3.2,2.9c-1.8,1.7-4.4,3-6,5s-2.9,4.1-4.2,6.3 c-0.6,1-1.3,2.2-1.9,3.3l-1.7,3.4l-0.2-0.1l1.4-3.6c0.5-1.1,0.9-2.4,1.5-3.5c1.1-2.3,2.3-4.6,3.8-6.8s3-4.4,5.1-5.9 c1-0.8,2.2-1.5,3.2-2.1c1.1-0.6,2.2-1.1,3.1-2L304,174.7z"/> </g> <g id="Body"> <g> <path d="M222.2,339.7c18.6-1.3,37.3-2,55.9-2C259.5,339,240.9,339.8,222.2,339.7z"/> </g> <g> <path d="M142.3,337.2c16.9,0.1,33.7,1,50.6,2.3C176,339.2,159.3,338.5,142.3,337.2z"/> </g> <g> <path d="M199.3,329.2c7.3,14.3,4.6,10.4,17.1,0.1C207.5,339,204.7,346.2,199.3,329.2z"/> </g> <path opacity="0.19" enable-background="new " d="M199.3,329.2c0,0,3.5,9.3,5.3,10.1c1.8,0.8,11.6-10,11.6-10 C209.9,330.9,204,331.1,199.3,329.2z"/> </g> <line fill="none" stroke="#000000" stroke-width="2" stroke-linecap="round" stroke-miterlimit="10" x1="132.7" y1="184.2" x2="130.7" y2="182.3"/>',
                "Kintaro"
            );
    }

    function body(string memory color) private pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<path id="Neck" display="inline"  fill="#',
                    color,
                    '" stroke="#000000" stroke-width="3" stroke-linecap="round" stroke-miterlimit="10" d="M175.8,276.8c0.8,10,1.1,20.2-0.7,30.4c-0.5,2.6-2.2,4.9-4.7,6.3c-16.4,8.9-41.4,17.2-70.2,25.2c-8.1,2.3-9.5,12.4-2.1,16.4c71.9,38.5,146.3,42.5,224.4,7c7.2-3.3,7.3-12.7,0.1-16c-22.3-10.3-43.5-23.1-54.9-29.9c-3-1.8-4.8-5.2-5.1-8.3c-0.7-7.7-0.7-12.5-0.1-22.2c0.7-11.3,2.6-21.2,4.6-29.3"  /><path id="Shadow" display="inline" opacity="0.51"  enable-background="new    " d="M178.1,279c0,0,24.2,35,41,30.6s41.7-21.6,41.7-21.6c1.2-9.1,1.9-17.1,3.7-26c-4.8,4.9-10.4,9.2-18.8,14.5c-11.3,7.1-22,11.3-29.8,13.3L178.1,279z"  /><path id="Head" display="inline"  fill="#',
                    color,
                    '" stroke="#000000" stroke-width="3" stroke-linecap="round" stroke-miterlimit="10" d="M313.9,168.8c-0.6-0.8-12.2,8.3-12.2,8.3c0.3-4.9,11.8-53.1-17.3-86c-15.9-17.4-42.2-27.1-69.9-27.7c-24.5-0.5-48.7,10.9-61.6,24.4c-33.5,35-20.1,98.2-20.1,98.2c0.6,10.9,9.1,63.4,21.3,74.6c0,0,33.7,25.7,42.4,30.6c8.8,5,17.1,2.3,17.1,2.3c16-5.9,47.7-25.9,56.8-37.6l0.2-0.2c6.9-9.1,3.9-5.8,11.2-14.8c1.3-1.5,3-2.2,4.8-1.8c4.1,0.8,11.7,1.3,13.3-7c2.4-11.5,2.6-25.1,8.6-35.5C311.7,190.8,315.9,184.6,313.9,168.8z"  /><path id="Ear" display="inline"  fill="#',
                    color,
                    '" stroke="#000000" stroke-width="3" stroke-linecap="round" stroke-miterlimit="10" d="M141.9,236c0.1,1.1-8.3,3-9.7-12.1s-7.3-31-12.6-48c-3.8-12.2,12.2,6.7,12.2,6.7"  /><g id="Ear2" display="inline" ><path d="M304,174.7c-0.5,1.3-0.3,2.2-1.2,3.1c-0.9,0.8-2.3,2.1-3.2,2.9c-1.8,1.7-4.4,3-6,5s-2.9,4.1-4.2,6.3c-0.6,1-1.3,2.2-1.9,3.3l-1.7,3.4l-0.2-0.1l1.4-3.6c0.5-1.1,0.9-2.4,1.5-3.5c1.1-2.3,2.3-4.6,3.8-6.8s3-4.4,5.1-5.9c1-0.8,2.2-1.5,3.2-2.1c1.1-0.6,2.2-1.1,3.1-2L304,174.7z" /></g><g id="Body" display="inline" ><g><path d="M222.2,339.7c18.6-1.3,37.3-2,55.9-2C259.5,339,240.9,339.8,222.2,339.7z" /></g><g><path d="M142.3,337.2c16.9,0.1,33.7,1,50.6,2.3C176,339.2,159.3,338.5,142.3,337.2z" /></g><g><path d="M199.3,329.2c7.3,14.3,4.6,10.4,17.1,0.1C207.5,339,204.7,346.2,199.3,329.2z" /></g><path opacity="0.19"  enable-background="new    " d="M199.3,329.2c0,0,3.5,9.3,5.3,10.1c1.8,0.8,11.6-10,11.6-10C209.9,330.9,204,331.1,199.3,329.2z" /></g> <line x1="132.69" y1="184.23" x2="130.73" y2="182.28" fill="#e31466" stroke="#000" stroke-linecap="round" stroke-miterlimit="10" stroke-width="2"/>'
                )
            );
    }

    /// @notice Return the skin name of the given id
    /// @param id The skin Id
    function getItemNameById(uint8 id) public pure returns (string memory name) {
        name = "";
        if (id == 1) {
            name = "Robot Blood";
        } else if (id == 2) {
            name = "Robot Moon";
        } else if (id == 3) {
            name = "Robot";
        } else if (id == 4) {
            name = "Kintaro";
        }
    }

    /// @dev The base SVG for the body
    function base(string memory children, string memory name) private pure returns (string memory) {
        return string(abi.encodePacked('<g id="body"><g id="', name, '">', children, "</g></g>"));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

pragma abicoder v2;

import "base64-sol/base64.sol";

/// @title Hair SVG generator
library HairDetail {
    /// @dev Hair N°1 => Hair Blood
    function item_1() public pure returns (string memory) {
        return base(longHair("E31466"), "Hair Blood");
    }

    /// @dev Hair N°2 => Tattoo Blood
    function item_2() public pure returns (string memory) {
        return base(tattoo("B50D5E"), "Tattoo Blood");
    }

    /// @dev Hair N°3 => Tattoo Moon
    function item_3() public pure returns (string memory) {
        return base(tattoo("000000"), "Tattoo Moon");
    }

    /// @dev Hair N°4 => Tattoo Pure
    function item_4() public pure returns (string memory) {
        return base(tattoo("FFEDED"), "Tattoo Pure");
    }

    /// @dev Hair N°5 => Monk Blood
    function item_5() public pure returns (string memory) {
        return base(shortHair("B50D5E"), "Monk Blood");
    }

    /// @dev Hair N°6 => Monk Moon
    function item_6() public pure returns (string memory) {
        return base(shortHair("001015"), "Monk Moon");
    }

    /// @dev Hair N°7 => Monk Pure
    function item_7() public pure returns (string memory) {
        return base(shortHair("FFEDED"), "Monk Pure");
    }

    /// @dev Hair N°8 => Flame Blood
    function item_8() public pure returns (string memory) {
        return base(flame("E31466"), "Flame Blood");
    }

    /// @dev Hair N°9 => Flame Moon
    function item_9() public pure returns (string memory) {
        return base(flame("2A2C38"), "Flame Moon");
    }

    /// @dev Hair N°10 => Flame Pure
    function item_10() public pure returns (string memory) {
        return base(flame("FFDAEA"), "Flame Pure");
    }

    /// @dev Hair N°11 => Top eyes
    function item_11() public pure returns (string memory) {
        return
            base(
                '<path d="M212.26,68.64S205.37,71,201.72,84c-1.28,4.6-.79,11.21,1.45,18a30.33,30.33,0,0,0,9.55-16.12C213.83,81.08,213.79,75.34,212.26,68.64Z" transform="translate(0 0.5)" /> <path d="M215.93,75.57a28.82,28.82,0,0,1,.15,6.15A36.91,36.91,0,0,1,215,87.81a24.33,24.33,0,0,1-2.36,5.75,23.15,23.15,0,0,1-3.74,4.93c.28-.37.58-.83.88-1.29l.43-.6.35-.63.8-1.31.72-1.34a35.55,35.55,0,0,0,2.16-5.71,36.25,36.25,0,0,0,1.24-6,18.25,18.25,0,0,0,.26-3C215.83,77.61,215.83,76.62,215.93,75.57Z" transform="translate(0 0.5)"/> <path d="M199,85.3c0,1.23-.07,2.45,0,3.69s0,2.39.17,3.64a16.5,16.5,0,0,0,.61,3.63,20,20,0,0,0,1.07,3.53,14.31,14.31,0,0,1-1.45-3.33c-.32-1.2-.48-2.37-.7-3.64,0-1.24-.12-2.4-.07-3.71A32.65,32.65,0,0,1,199,85.3Z" transform="translate(0 0.5)"/> <ellipse cx="211.04" cy="79.75" rx="2.78" ry="0.69" transform="matrix(0.09, -1, 1, 0.09, 111.76, 282.83)" fill="#fff"/>',
                "Top Eyes"
            );
    }

    /// @dev Hair N°12 => Middle eyes
    function item_12() public pure returns (string memory) {
        return
            base(
                '<path d="M213,104.52s-10.09,8.91-23.55-.09C189.55,104.37,200.24,95.64,213,104.52Z" transform="translate(0 0.5)" /> <path d="M211.51,101.33a16.75,16.75,0,0,0-3.14-1.5A23.51,23.51,0,0,0,205,98.9a16.16,16.16,0,0,0-3.53-.27,14.89,14.89,0,0,0-3.43.56c.26,0,.57-.07.88-.1l.41,0,.41,0,.87-.06h.85a21.36,21.36,0,0,1,3.46.35,23,23,0,0,1,3.37.82,12.29,12.29,0,0,1,1.6.58C210.44,100.9,210.94,101.13,211.51,101.33Z" transform="translate(0 0.5)"/> <path d="M199.85,109.75c-.83-.13-1.65-.25-2.48-.43s-1.59-.31-2.42-.55a11,11,0,0,1-2.35-.84,13.15,13.15,0,0,1-2.24-1.14,9.12,9.12,0,0,0,2.06,1.37c.76.36,1.53.6,2.35.91s1.6.36,2.48.48A20.38,20.38,0,0,0,199.85,109.75Z" transform="translate(0 0.5)"/> <ellipse cx="205.62" cy="102.76" rx="0.47" ry="1.89" transform="translate(68.77 287.95) rotate(-80.02)" fill="#fff"/>',
                "Middle Eyes"
            );
    }

    /// @dev Hair N°13 => Side eyes
    function item_13() public pure returns (string memory) {
        return
            base(
                '<g id="Eye"> <path d="M289,147.2s-10.34-8.61-3.5-23.28C285.51,124,295.77,133.19,289,147.2Z" transform="translate(0 0.5)" /> <path d="M281.77,135c0-.83,0-1.67.05-2.51s.06-1.62.17-2.47a10.81,10.81,0,0,1,.47-2.46,13.76,13.76,0,0,1,.78-2.38,9.71,9.71,0,0,0-1,2.24c-.24.81-.36,1.6-.53,2.46s-.12,1.63-.1,2.53A20.5,20.5,0,0,0,281.77,135Z" transform="translate(0 0.5)"/> <ellipse cx="287.94" cy="130.66" rx="0.47" ry="1.89" transform="translate(-26.21 95.24) rotate(-17.88)" fill="#fff"/> </g> <g id="Eye-2" > <path d="M137,147.2s7.8-8.61,2.65-23.28C139.6,124,131.86,133.19,137,147.2Z" transform="translate(0 0.5)" /> <path d="M142.42,135c0-.83,0-1.67,0-2.51s0-1.62-.13-2.47a14.29,14.29,0,0,0-.35-2.46,16.86,16.86,0,0,0-.59-2.38,11,11,0,0,1,.78,2.24c.18.81.28,1.6.4,2.46s.09,1.63.08,2.53A25.66,25.66,0,0,1,142.42,135Z" transform="translate(0 0.5)"/> <ellipse cx="137.95" cy="129.7" rx="1.89" ry="0.36" transform="translate(-25.79 225.29) rotate(-73.38)" fill="#fff"/></g>',
                "Side Eyes"
            );
    }

    /// @dev Hair N°14 => Akuma
    function item_14() public pure returns (string memory) {
        return base("", "Akuma");
    }

    /// @dev Hair N°15 => Hair Moon
    function item_15() public pure returns (string memory) {
        return base(longHair("2A2C38"), "Hair Moon");
    }

    /// @dev Hair N°16 => Hair Pure
    function item_16() public pure returns (string memory) {
        return base(longHair("FFDAEA"), "Hair Pure");
    }

    /// @dev Hair N°17 => Tattoo kin
    function item_17() public pure returns (string memory) {
        return
            base(
                '<g id="Tattoo_kin" display="inline" ><linearGradient id="SVGID_00000011722690206770933430000008680616382255612556_" gradientUnits="userSpaceOnUse" x1="210.6601" y1="-54.3" x2="210.6601" y2="11.1777" gradientTransform="matrix(1 0 0 -1 0 76)"><stop offset="0" style="stop-color:#FFB451" /><stop offset="0.4231" style="stop-color:#F7E394" /><stop offset="1" style="stop-color:#FF9B43" /></linearGradient><path  fill="url(#SVGID_00000011722690206770933430000008680616382255612556_)" d="M192.1,67.4c-6.5,21.1,2,49.3,5.5,62.9c0,0,6.9-39.2,34-63.9C220.8,63.6,198.1,64.9,192.1,67.4z" /></g>',
                "Tattoo kin"
            );
    }

    function flame(string memory color) private pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<path display="inline" fill="#',
                    color,
                    '" d="M292.2,168.8c-2.7,2.1-7.7,6-10.4,8.1c3.5-8,7-18.9,7.2-24c-2.4,1.6-6.8,4.7-9.3,4.1 c3.9-12.3,4.2-11.6,4.6-24.2c-2.5,2-8.9,9.3-11.5,11.2c0.5-5.9,0.8-14.3,1.4-20.1c-3.3,3.4-7.6,2.6-12.5,4c-0.5-5,1.3-7,3.5-11.6 c-9.8,4-24.7,6-34.9,8.6c-0.1-2.4-0.6-6.3,0.7-8.1c-10.4,5-26.7,9.3-31.8,12.4c-4.1-2.8-16.9-9.3-19.7-12.9 c-0.1,1.6,0.7,8,0.6,9.6c-5.4-3.8-6.2-3-12-6.8c0.5,2.6,0.3,3.6,0.8,6.2c-7.2-2.8-14.4-5.7-21.6-8.5c1.8,4,3.5,8,5.3,12 c-3.6,0.6-9.9-1.8-12-4.9c-3,7.8-0.1,12.2,0,20.5c-2-2-3.9-6.4-5.4-8.6c0.5,9.6,1,19.1,1.6,28.7c-1.6-0.6-2.7-2-3.1-3.5 c-0.1,5.8,2.6,20.6,4,26.4c-0.8-0.8-5.5-10.9-5.7-12.1c4.3,7.9,4.1,10.5,5.4,26.3c0.9-0.9-5.5-17-8-19.4 c-1.7-15.4-5.3-33.7-9.1-48.8c2,3.6,3.9,7.3,5.8,11c-0.7-13.8-0.7-27.6-0.1-41.4c-0.2,5.9,0.7,11.9,2.6,17.4 c0.5-11.3,2.2-22.4,5.2-33.3c-0.1,4.1,0.4,8.1,1.6,12c2.8-10,6.3-19.8,10.3-29.3c0.8,4.7,1.7,9.4,2.4,14.1 c3.6-9.9,7.9-15.5,14.6-23.7c0.2,4,0.4,7.8,0.7,11.8c6.9-8.9,15-16.8,24.1-23.2c-0.5,4.4-1,8.8-1.6,13.1 c6.1-5.7,11.7-9.7,17.8-15.4c0.3,4.4,1.3,7,1.6,11.5c4-5.4,8.1-9.6,12.1-15c1.4,6.1,2,11.3,2.2,17.6c4.8-4.7,8.1-10,8.4-16.7 c4.2,7.4,7.9,10.6,9.8,18.9c2.5-8.4,4.8-11,4.7-19.8c4.4,10.1,6.8,14.3,9.6,24c0.9-4.6,4.1-11.5,5-16c6.3,6.7,9.1,14.6,12.4,23 c0.7-7.6,5.7-10.6,3.5-17.9c6.5,10.7,4.6,15.2,8.6,27.7c2.9-5.3,4.4-13.3,5.5-19.4c2.7,8,7.7,23.1,9.4,31.5 c0.7-2.7,3.1-3.3,3.5-9.9c2.8,7.7,3.3,8.4,3.5,23.4c1.1-7.4,4.3-3.3,4.5-10.8c3.8,9.6,1.4,14.8,0.4,22.6c-0.1,0.9,4.2-0.4,5.1-1.5 c1-1.3-2.1,12.4-2.8,14.3c-0.5,1.4-1.9,2.7-1.4,8.4c2.2-3.1,2.5-3,4.3-6.4c1.3,11.3-2.3,6-4.7,25.5c1.9-2.5,3.9-1.1,5.6-3.5 c-2.8,7.8-0.4,9.8-6.9,14c-3.3,2.1-11.2,10.3-14.2,13.5c1.6-3.3-2.9,9.8-8.2,18.8C284.5,199.5,289.7,170.7,292.2,168.8z"/>'
                )
            );
    }

    function tattoo(string memory color) private pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<path d="M193.2,67.36c-6.5,21.1,3,50.54,6.48,64.14,0,0,5.91-44.63,33.11-64.86C222,63.84,201.2,64.36,193.2,67.36Z" fill="#',
                    color,
                    '" transform="translate(-0.1)"/>'
                )
            );
    }

    function longHair(string memory color) private pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<g ><polygon fill="#',
                    color,
                    '" points="188.1,115.5 198.2,119 211.1,115.2 197.7,104.1 "/><polygon opacity="0.5" enable-background="new    " points="188.3,115.6 198.2,119 211.6,115.1 197.6,104.5 "/><path fill="#',
                    color,
                    '" stroke="#000000" stroke-width="2" stroke-miterlimit="10" d="M273.7,200.6c4.2-5.9,10.1-12.8,10.5-18.3c1.1,3.2,2,11.7,1.5,15.8c0,0,5.7-10.8,10.6-15.6c6.4-6.3,13.9-10.2,17.2-14.4c2.3,6.4,1.4,15.3-4.7,28.1c0,0,0.4,9.2-0.7,15.3c3.3-5.9,12.8-36.2,8.5-61.6c0,0,3.7,9.3,4.4,16.9s3.1-32.8-7.7-51.4c0,0,6.9,3.9,10.8,4.8c0,0-12.6-12.5-13.6-15.9c0,0-14.1-25.7-39.1-34.6c0,0,9.3-3.2,15.6,0.2c-0.1-0.1-15.1-12.2-34.2-7.1c0,0-15.1-13.6-42.6-12.3l15.6,8.8c0,0-12.9-0.9-28.4-1.3c-6.1-0.2-21.8,3.3-38.3-1.4c0,0,7.3,7.2,9.4,7.7c0,0-30.6,13.8-47.3,34.2c0,0,10.7-8.9,16.7-10.9c0,0-26,25.2-31.5,70c0,0,9.2-28.6,15.5-34.2c0,0-10.7,27.4-5.3,48.2c0,0,2.4-14.5,4.9-19.2c-1,14.1,2.4,33.9,13.8,47.8c0,0-3.3-15.8-2.2-21.9l8.8-17.9c0.1,4.1,1.3,8.1,3.1,12.3c0,0,13-36.1,19.7-43.9c0,0-2.9,15.4-1.1,29.6c0,0,7.2-26.8,17.3-40.1c0,0,0.8,0.1,17.6-7.6c6.3,3.1,8,1.4,17.9,7.7c4.1,5.3,13.8,31.9,15.6,41.5c3.4-7.3,5.6-19,5.2-29.5c2.7,3.7,8.9,19.9,9.6,34.3c4.3-6,6.4-27.8,5.9-29c0,1.2,0.2,14.8,0.3,14.3c0,0,12.1,19.9,14.9,19.7c0-0.8-1.7-12.9-1.7-12.8c1.3,5.8,2.8,23.3,3.1,27.1l5-9.5C274.6,176.2,275.4,194.5,273.7,200.6z"/><g><path fill="none" stroke="#000000" stroke-width="0.5" stroke-miterlimit="10" d="M295.2,182.2"/><path fill="none" stroke="#000000" stroke-width="0.5" stroke-miterlimit="10" d="M286.6,200.9"/><path fill="none" stroke="#000000" stroke-width="2" stroke-linecap="round" stroke-miterlimit="10" d="M133.1,181.3c0,0-1.3-11.3,0.3-16.9"/><path fill="none" stroke="#000000" stroke-width="2" stroke-linecap="round" stroke-miterlimit="10" d="M142.1,160.9c0,0-1-6.5,1.6-20.4"/></g></g><g  id="Shadow"><path opacity="0.2"  enable-background="new    " d="M180.5,119.1c0,0-15.9,23.7-16.9,25.6s0,12.4,0.3,12.8S165.7,142.5,180.5,119.1z"/><path opacity="0.2" enable-background="new    " d="M164.5,128.9c0,0-16.3,25.3-17.9,26.3c0,0-3.8-12.8-3-14.7s-9.6,10.3-9.9,17c0,0-8.4-0.6-11-7.4c-1-2.5,1.4-9.1,2.1-12.2c0,0-6.5,7.9-9.4,22.5c0,0,0.6,8.8,1.1,10c0,0,3.5-14.8,4.9-17.7c0,0-0.3,33.3,13.6,46.7c0,0-3.7-18.6-2.6-21l9.4-18.6c0,0,2.1,10.5,3.1,12.3l13.9-33.1L164.5,128.9z"/><path opacity="0.16" enable-background="new    " d="M253.2,146.8c0.8,4.4,8.1,12.1,13.1,11.7l1.6,11c0,0-5.2-3.9-14.7-19.9V146.8z"/><path opacity="0.16" enable-background="new    " d="M237.5,130.3c0,0,4.4,3,13.9,21.7c0,0-4.3,12-4.6,12.4C246.5,164.8,248.4,153.7,237.5,130.3z"/><path opacity="0.17" enable-background="new    " d="M220.9,127.6c0,0,5.2,4,14.4,23c0,0-1.2,4.6-3.1,8.9C227.6,143.3,227,140.8,220.9,127.6z"/><path opacity="0.2" enable-background="new    " d="M272,143.7c-2.4,8.1-3.6,13.8-4.9,17.9c0,0,1.3,12.8,2.1,22.2c4.7-8.4,4.7-8.4,5.4-9c0.2,0.6,3.1,11.9-1.2,26.6c5.1-6.7,10.4-14.9,11-21.3c1.1,3.7,1.7,15,1.2,19.1c0,0,7.1-7.4,12.3-11.3c0,0,8.7-3.5,12.5-7.2c0,0,2.2,1.4-1.2,11.6l3.7-8c0,0-2.7,19.9-3.4,22.5c0,0,9.8-33.3,7.2-58c0,0,4.7,8.3,4.9,17.1c0.1,8.8,1.7-8.6,0.2-17.8c0,0-6.5-13.9-8.2-15.4c0,0,1.3,10.1,0.4,13.6c0,0-7.3-10.3-10.5-12.5c0,0,1.1,30.2-1.7,35.3c0,0-6.1-17-10.7-20.8c0,0-2.4,20.9-5.6,28.1C283.6,174.1,280.4,157.8,272,143.7z"/><path opacity="0.14" enable-background="new    " d="M198.1,106.1c-0.9-3.9,3.2-35.1,34.7-36C227.5,69.4,198.8,90.7,198.1,106.1z"/></g><g id="Light" opacity="0.64"> <path d="M128,115.68s9.5-20.6,23.5-27.7A231.28,231.28,0,0,0,128,115.68Z" transform="translate(-0.48 0.37)" fill="#fff"/> <path d="M302.32,118.62s-12.77-26.38-29.75-35A151.52,151.52,0,0,1,302.32,118.62Z" transform="translate(-0.48 0.37)" fill="#fff"/> <path d="M251.35,127.49s-9.25-18.73-11.63-21.13,5,1.76,12.17,20.33" transform="translate(-0.48 0.37)" fill="#fff"/> <path d="M168.21,103.68s-10.66,10.79-16,23.94C157.36,118,168.21,103.68,168.21,103.68Z" transform="translate(-0.48 0.37)" fill="#fff"/> <path d="M170,126.1s7.5-21.3,8.4-22.5-12.6,11.4-13.1,18c0,0,9-12.8,9.5-13.5S168.8,121.8,170,126.1Z" transform="translate(-0.48 0.37)" fill="#fff"/> <path d="M233.09,127.55s-7.5-21.3-8.4-22.5,12.6,11.4,13.1,18c0,0-9-12.8-9.5-13.5S234.29,123.25,233.09,127.55Z" transform="translate(-0.48 0.37)" fill="#fff"/> </g>'
                )
            );
    }

    function spike(string memory color) private pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<path  display="inline"  fill="#',
                    color,
                    '" stroke="#',
                    color,
                    '" stroke-miterlimit="10" d="M197.7,120.1c0,0-26.4-38.7-18-80.2c0,0,0.6,18.5,10.4,25.8c0,0-7.5-13.9-0.3-34.5c0,0,2.3,16.4,9.3,24.1c0,0-2.3-19.1,1.9-30.5c0,0,8.4,23.9,12.1,27.1c0,0-2.8-16.2,4.8-28.6c0,0,2.2,17.1,8.5,26.2c0,0-2.3-11.5,3.4-19.6c0,0,1,25.8,5.7,30.3c0,0-2.3-12.4,1.8-20.7c0,0,3.6,24.4,5.9,29c-7.9-2.6-14.6-2.1-22.2-1.9C221.3,67,199.4,74.8,197.7,120.1z"/>'
                )
            );
    }

    function shortHair(string memory color) private pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<path display="inline" fill="#',
                    color,
                    '" d="M288.2,192.7c0,0,0.1-18.3-2.9-21.5c-3.1-3-7.4-9.2-7.4-9.2s0.3-22.2-3.2-29.6c-3.6-7.4-4.6-19.5-36.1-18.7c-30.7,0.7-41.1,5.8-41.1,5.8s-13.1-7.7-41.9-4c-19.6,5.2-20.3,42.6-20.3,42.6s-1.3,9.2-1.9,14.7c-0.6,5.6-0.3,8.5-0.3,8.5c-0.9,11.8-27.4-116.1,81.3-119.6c110.4,6.8,89.8,101.8,86.7,115.3C295.8,180.8,294.7,183.1,288.2,192.7z"  />',
                    '<g id="Shadow" display="inline" > <path opacity="7.000000e-02"  enable-background="new    " d="M277,141.5c0,0,0.9,3.6,0.9,20.6c0,0,6.6,7.9,8.6,11.7c2,3.6,2.6,18.8,2.6,18.8l5.4-9.2c0,0,1.5-1.8,5.7-4c0,0,7-15.6,3.4-46.3C303.7,133.1,295.1,139.9,277,141.5z" /> <path opacity="7.000000e-02"  enable-background="new    " d="M132.9,182.7c0,0,0.4-11.3,2.3-24.4c0,0,1.9-15.1,3.4-21.9c-1.9,0-6.9,0-8.5-1.1C130,135.3,128.7,177.5,132.9,182.7z" /> </g>'
                )
            );
    }

    /// @notice Return the skin name of the given id
    /// @param id The skin Id
    function getItemNameById(uint8 id) public pure returns (string memory name) {
        name = "";
        if (id == 1) {
            name = "Hair Blood";
        } else if (id == 2) {
            name = "Tattoo Blood";
        } else if (id == 3) {
            name = "Tattoo Moon";
        } else if (id == 4) {
            name = "Tattoo Pure";
        } else if (id == 5) {
            name = "Monk Blood";
        } else if (id == 6) {
            name = "Monk Moon";
        } else if (id == 7) {
            name = "Monk Pure";
        } else if (id == 8) {
            name = "Flame Blood";
        } else if (id == 9) {
            name = "Flame Moon";
        } else if (id == 10) {
            name = "Flame Pure";
        } else if (id == 11) {
            name = "Top eyes";
        } else if (id == 12) {
            name = "Middle eyes";
        } else if (id == 13) {
            name = "Side eyes";
        } else if (id == 14) {
            name = "Akuma";
        } else if (id == 15) {
            name = "Hair Moon";
        } else if (id == 16) {
            name = "Hair Pure";
        } else if (id == 17) {
            name = "Tatoo Kin";
        }
    }

    /// @dev The base SVG for the body
    function base(string memory children, string memory name) private pure returns (string memory) {
        return string(abi.encodePacked('<g id="hair"><g id="', name, '">', children, "</g></g>"));
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
                '<g display="inline" ><path d="M177.1,251.1c3.6-0.2,7.4-0.1,11,0s7.4,0.3,10.9,0.9c-3.6,0.3-7.4,0.3-11,0.2C184.4,252.1,180.7,251.8,177.1,251.1z" /></g><g display="inline" ><path d="M203.5,251.9c10.1-0.7,19.1,0.1,29.2-1.3C222.6,253.7,213.9,252.6,203.5,251.9z" /></g><g display="inline" ><path d="M196.7,261.5c0.9,0.5,2.1,0.9,2.9,1.1c0.8,0.2,2.1,0.4,2.9,0.5c0.8,0.1,2.1,0,3.1-0.1s2.1-0.5,3.1-0.9c-0.8,0.8-1.9,1.5-2.8,1.9c-1.1,0.3-2.3,0.5-3.3,0.4c-1.1-0.1-2.3-0.3-3.2-0.9C198.5,263.1,197.4,262.5,196.7,261.5z" /></g>',
                "Neutral"
            );
    }

    /// @dev Mouth N°2 => Canine
    function item_2() public pure returns (string memory) {
        return
            base(
                '<g display="inline" ><polyline  fill="#FFFFFF" points="222.4,251.9 225.5,260.1 230,251.7 " /><path d="M222.4,251.9c0.6,1.4,1.1,2.6,1.8,4c0.5,1.4,1,2.7,1.6,4h-0.4c0.3-0.7,0.7-1.4,1.1-2.1l1.1-2.1c0.8-1.4,1.6-2.7,2.4-4.1c-0.6,1.5-1.4,2.9-2.1,4.3l-1,2.1c-0.4,0.7-0.7,1.5-1.1,2.1l-0.3,0.5l-0.2-0.5c-0.5-1.4-1-2.7-1.5-4.1C223.3,254.7,222.8,253.3,222.4,251.9z" /></g><g display="inline" ><polyline  fill="#FFFFFF" points="187.3,252 184,259.7 180,251.5 " /><path d="M187.3,252c-0.4,1.4-0.9,2.7-1.5,4c-0.5,1.4-1,2.6-1.6,4l-0.2,0.5l-0.3-0.5c-0.3-0.6-0.6-1.4-1-2.1l-1-2.1c-0.6-1.4-1.3-2.7-1.9-4.2c0.8,1.4,1.5,2.6,2.2,4l1,2c0.3,0.7,0.7,1.4,1,2.1h-0.4c0.5-1.3,1-2.6,1.7-3.9C186.2,254.5,186.7,253.2,187.3,252z" /></g><path display="inline"  d="M174.6,251c0,0,24.6,3.4,60.2,0.5"  /><g display="inline" ><path d="M195.8,256.6c1.1,0.3,2.4,0.5,3.5,0.6c1.3,0.1,2.4,0.2,3.6,0.2s2.4-0.1,3.6-0.2s2.4-0.2,3.6-0.4c-0.6,0.2-1.1,0.4-1.8,0.6c-0.6,0.1-1.3,0.3-1.8,0.4c-1.3,0.2-2.5,0.3-3.8,0.3s-2.5-0.1-3.8-0.3C197.9,257.6,196.8,257.2,195.8,256.6z" /></g>',
                "Canine"
            );
    }

    /// @dev Mouth N°3 => Canine up
    function item_3() public pure returns (string memory) {
        return
            base(
                '<g display="inline" ><polyline  fill="#FFFFFF" points="219.5,252.5 222.7,244.3 227.4,252.8 " /><path d="M219.5,252.5c0.6-1.4,1.1-2.6,1.9-4c0.5-1.4,1-2.7,1.7-4h-0.4c0.3,0.7,0.7,1.4,1.1,2.1l1.1,2.1c0.8,1.4,1.7,2.7,2.5,4.1c-0.6-1.5-1.5-2.9-2.2-4.3l-1-2.1c-0.4-0.7-0.7-1.5-1.1-2.1l-0.3-0.5l-0.2,0.5c-0.5,1.4-1,2.7-1.6,4.1C220.3,249.6,219.9,251,219.5,252.5z" /></g><g display="inline" ><polyline  fill="#FFFFFF" points="185,252.4 181.8,244.5 177.4,252.7 " /><path d="M185,252.4c-0.4-1.4-0.9-2.7-1.5-4c-0.5-1.4-1-2.6-1.6-4l-0.2-0.5l-0.3,0.5c-0.3,0.6-0.6,1.4-1.1,2.1l-1.1,2.1c-0.6,1.4-1.4,2.7-2,4.2c0.8-1.4,1.6-2.6,2.3-4l1.1-2c0.3-0.7,0.7-1.4,1.1-2.1h-0.4c0.5,1.3,1,2.6,1.7,3.9C183.9,249.9,184.4,251.1,185,252.4z" /></g><path display="inline"  d="M171.9,252.3c0,0,25.6,3.2,62.8,0"  /><g display="inline" ><path d="M194.1,257.7c1.1,0.3,2.5,0.5,3.6,0.6c1.4,0.1,2.5,0.2,3.9,0.2s2.5-0.1,3.9-0.2s2.5-0.2,3.9-0.4c-0.6,0.2-1.1,0.4-1.9,0.6c-0.6,0.1-1.4,0.3-1.9,0.4c-1.4,0.2-2.6,0.3-4,0.3s-2.6-0.1-4-0.3C196.4,258.7,195.2,258.3,194.1,257.7z" /></g>',
                "Canine up"
            );
    }

    /// @dev Mouth N°4 => Poker
    function item_4() public pure returns (string memory) {
        return
            base(
                '<g id="Poker" ><path d="M174.5,253.4c2.7-0.4,5.4-0.6,8-0.7c2.7-0.1,5.4-0.2,8-0.1c2.7,0.1,5.4,0.4,8,0.5c2.7,0.1,5.4,0,8-0.2c2.7-0.2,5.4-0.3,8-0.4c2.7-0.1,5.4-0.2,8-0.1c5.4,0.1,10.7,0.3,16.1,1c0.1,0,0.1,0.1,0.1,0.1c0,0,0,0.1-0.1,0.1c-5.4,0.6-10.7,0.9-16.1,1c-2.7,0-5.4-0.1-8-0.1c-2.7,0-5.4-0.2-8-0.4c-2.7-0.2-5.4-0.3-8-0.2c-2.7,0.1-5.4,0.4-8,0.5c-2.7,0.1-5.4,0.1-8-0.1c-2.7-0.1-5.4-0.3-8-0.7C174.4,253.6,174.4,253.5,174.5,253.4C174.4,253.4,174.5,253.4,174.5,253.4z" /></g>',
                "Poker"
            );
    }

    /// @dev Mouth N°5 => Angry
    function item_5() public pure returns (string memory) {
        return
            base(
                '<g display="inline" ><path fill="#FFFFFF" d="M211.5,246.9c-7.9,1.5-19.6,0.3-23.8-0.9c-4.5-1.3-8.6,3.2-9.7,7.5c-0.5,2.6-1.4,7.7,3.9,10.5c6.7,2.5,6.4,0.1,10.4-2c3.9-2.1,11.3-1.1,17.3,2c6.1,3.1,15.1,2.3,20.2-0.4c3.2-1.8,3.8-7.9-4.8-14.7C222.5,247,220.4,245.2,211.5,246.9" /><path d="M211.5,247c-4.1,1-8.3,1.2-12.4,1.2c-2.1,0-4.2-0.2-6.3-0.4c-1-0.1-2.1-0.3-3.1-0.4c-0.5-0.1-1-0.2-1.6-0.3c-0.3-0.1-0.6-0.1-0.8-0.2c-0.2,0-0.4-0.1-0.6-0.1c-1.7-0.2-3.5,0.6-4.9,1.9c-1.4,1.3-2.5,3-3.1,4.8c-0.5,1.9-0.8,4-0.3,5.8c0.2,0.9,0.7,1.8,1.3,2.6c0.6,0.7,1.4,1.4,2.3,1.9l0,0c1.6,0.6,3.2,1.2,4.9,1c1.6-0.1,2.8-1.6,4.3-2.5c1.4-1,3.2-1.6,5-1.8c1.8-0.2,3.5-0.1,5.3,0.1c1.7,0.2,3.5,0.7,5.1,1.2c0.8,0.3,1.7,0.6,2.5,1s1.6,0.7,2.3,1c3,1.1,6.4,1.4,9.7,1.1c1.6-0.2,3.3-0.4,4.9-0.9c0.8-0.2,1.6-0.5,2.3-0.8c0.4-0.1,0.7-0.3,1.1-0.5l0.4-0.3c0.1-0.1,0.2-0.2,0.4-0.3c0.9-0.9,1.1-2.4,0.8-3.9s-1.1-2.9-2-4.3c-0.9-1.3-2.1-2.5-3.3-3.7c-0.6-0.6-1.3-1.1-1.9-1.6c-0.7-0.5-1.3-0.9-2.1-1.2c-1.5-0.6-3.2-0.8-4.9-0.8C214.9,246.6,213.2,246.8,211.5,247c-0.1,0-0.1,0-0.1-0.1s0-0.1,0.1-0.1c1.7-0.4,3.4-0.8,5.1-0.9c1.7-0.2,3.5-0.1,5.3,0.5c0.9,0.3,1.7,0.7,2.4,1.2s1.4,1,2.1,1.6c1.4,1.1,2.7,2.3,3.8,3.7s2.1,3,2.5,4.9c0.5,1.8,0.3,4.1-1.2,5.8c-0.2,0.2-0.4,0.4-0.6,0.6c-0.2,0.2-0.5,0.3-0.7,0.5c-0.4,0.2-0.8,0.4-1.2,0.6c-0.8,0.4-1.7,0.7-2.6,0.9c-1.7,0.5-3.5,0.8-5.3,0.9c-3.5,0.2-7.2-0.1-10.5-1.5c-0.8-0.4-1.7-0.8-2.4-1.1c-0.7-0.4-1.5-0.7-2.3-1c-1.6-0.6-3.2-1.1-4.8-1.4s-3.3-0.5-5-0.4s-3.2,0.5-4.7,1.4c-0.7,0.4-1.4,0.9-2.1,1.4c-0.7,0.5-1.6,1-2.5,1c-0.9,0.1-1.8-0.1-2.7-0.3c-0.9-0.2-1.7-0.5-2.5-0.8l0,0l0,0c-0.9-0.5-1.8-1.1-2.6-1.9c-0.7-0.8-1.3-1.8-1.7-2.8c-0.7-2.1-0.5-4.3-0.1-6.5c0.5-2.2,1.6-4.1,3.2-5.7c0.8-0.8,1.7-1.5,2.8-1.9c1.1-0.5,2.3-0.7,3.5-0.5c0.3,0,0.6,0.1,0.9,0.2c0.3,0.1,0.5,0.1,0.7,0.2c0.5,0.1,1,0.2,1.5,0.3c1,0.2,2,0.4,3,0.5c2,0.3,4.1,0.5,6.1,0.7c4.1,0.3,8.2,0.4,12.3,0c0.1,0,0.1,0,0.1,0.1C211.6,246.9,211.6,247,211.5,247z" /></g><g display="inline" ><path fill="#FFFFFF" d="M209.7,255.6l4.6-2.3c0,0,4.2,3,5.6,3.1s5.5-3.3,5.5-3.3l4.4,1.5" /><path d="M209.7,255.5c0.6-0.7,1.3-1.2,2-1.7s1.5-0.9,2.2-1.3l0.5-0.2l0.4,0.3c0.8,0.7,1.5,1.6,2.4,2.2c0.4,0.3,0.9,0.6,1.4,0.8s1.1,0.3,1.4,0.3c0.2-0.1,0.7-0.4,1.1-0.7c0.4-0.3,0.8-0.6,1.2-0.9c0.8-0.6,1.6-1.3,2.5-1.9l0.5-0.4l0.4,0.2c0.7,0.3,1.4,0.7,2.1,1c0.7,0.4,1.4,0.8,2,1.3c0,0,0.1,0.1,0,0.1h-0.1c-0.8,0-1.6-0.1-2.4-0.2c-0.8-0.1-1.5-0.3-2.3-0.5l1-0.2c-0.8,0.8-1.7,1.4-2.7,2c-0.5,0.3-1,0.6-1.5,0.8c-0.6,0.2-1.1,0.4-1.9,0.4c-0.8-0.2-1.1-0.6-1.6-0.8c-0.5-0.3-0.9-0.6-1.4-0.8c-1-0.5-2.1-0.7-3-1.3l0.9,0.1c-0.7,0.4-1.5,0.7-2.4,1c-0.8,0.3-1.7,0.5-2.6,0.6C209.7,255.7,209.6,255.6,209.7,255.5C209.6,255.6,209.6,255.5,209.7,255.5z" /></g><g display="inline" ><polyline fill="#FFFFFF" points="177.9,255.4 180.5,253.4 184.2,255.6 187.1,255.5 " /><path d="M177.8,255.3c0.1-0.4,0.2-0.6,0.3-0.9c0.2-0.3,0.3-0.5,0.5-0.7s0.4-0.4,0.6-0.5c0.2-0.1,0.6-0.2,0.8-0.2l0.6-0.1l0.1,0.1c0.2,0.3,0.5,0.6,0.8,0.8s0.7,0.2,1.1,0.3c0.4,0,0.7,0.1,1.1,0.3c0.3,0.1,0.7,0.3,1,0.4l-0.6-0.2c0.5,0,1,0.1,1.5,0.2c0.2,0.1,0.5,0.2,0.7,0.3s0.5,0.2,0.7,0.4c0.1,0,0.1,0.1,0,0.2l0,0c-0.2,0.2-0.5,0.3-0.7,0.5c-0.2,0.1-0.5,0.2-0.7,0.3c-0.5,0.2-1,0.3-1.4,0.3h-0.3l-0.3-0.2c-0.3-0.2-0.6-0.4-0.9-0.7c-0.3-0.2-0.5-0.5-0.8-0.8c-0.2-0.3-0.5-0.6-0.8-0.8s-0.6-0.3-1-0.3h0.6c-0.1,0.3-0.3,0.6-0.5,0.8s-0.4,0.3-0.7,0.5c-0.2,0.1-0.5,0.2-0.8,0.3s-0.6,0.1-1,0.1C177.9,255.5,177.8,255.4,177.8,255.3L177.8,255.3z" /></g>',
                "Angry"
            );
    }

    /// @dev Mouth N°6 => Sulk
    function item_6() public pure returns (string memory) {
        return
            base(
                '<path display="inline" fill="none" stroke="#000000" stroke-width="2" stroke-miterlimit="10" d="M178.5,252.7c0,0,27.4,3.6,48.5,0.1"  /><g display="inline" ><path d="M175.6,245.9c0.9,0.7,1.8,1.6,2.4,2.6c0.6,1,1.1,2.2,1.1,3.4c0,0.3,0,0.6-0.1,0.9l-0.2,0.9c-0.3,0.5-0.5,1.1-1,1.6c-0.4,0.5-0.9,0.8-1.5,1.1c-0.5,0.3-1,0.5-1.7,0.7c0.4-0.4,0.9-0.7,1.4-1.1c0.4-0.4,0.8-0.7,1-1.3c0.6-0.8,1-1.9,0.9-2.9c0-1-0.3-2.1-0.8-3.1C176.9,247.9,176.4,247,175.6,245.9z" /></g><g display="inline" ><path d="M230.5,246.9c-0.6,0.9-1.3,2-1.7,3s-0.7,2.1-0.7,3.1s0.3,2.1,1,2.9c0.3,0.5,0.7,0.8,1.1,1.3c0.4,0.4,0.9,0.7,1.4,1.1c-0.5-0.2-1.1-0.4-1.7-0.7s-1-0.6-1.5-1.1c-0.5-0.4-0.7-1-1-1.6l-0.2-0.9c-0.1-0.3-0.1-0.6-0.1-0.9c0-1.3,0.4-2.5,1.1-3.5C228.7,248.5,229.5,247.6,230.5,246.9z" /></g>',
                "Sulk"
            );
    }

    /// @dev Mouth N°7 => Tongue
    function item_7() public pure returns (string memory) {
        return
            base(
                '<path display="inline" fill="#FF155D" d="M208.3,255.3c0,0,4.3,11.7,13.4,10.2c12.2-1.9,6.8-12.3,6.8-12.3L208.3,255.3z"  /><line display="inline" fill="none" stroke="#73093E" stroke-miterlimit="10" x1="219.3" y1="254.7" x2="221.2" y2="259.7"  /><path display="inline" fill="none" stroke="#000000" stroke-linecap="round" stroke-miterlimit="10" d="M203.4,255.6c0,0,22.3,0.1,29.7-4.5"  /><path display="inline" fill="none" stroke="#000000" stroke-linecap="round" stroke-miterlimit="10" d="M177.9,251.6c0,0,10.6,4.4,21.3,4.1"  />',
                "Tongue"
            );
    }

    /// @dev Mouth N°8 => None
    function item_8() public pure returns (string memory) {
        return base("", "None");
    }

    /// @dev Mouth N°9 => Fantom
    function item_9() public pure returns (string memory) {
        return
            base(
                '<path d="M220.3,255.4l-4.9,7.8c-.4.6-.9.6-1.3,0l-4.8-7.8a2.56,2.56,0,0,1,0-2.1l4.9-7.8c.4-.6.9-.6,1.3,0l4.8,7.8A2,2,0,0,1,220.3,255.4Zm-11.9-.1-4.9,7.8c-.4.6-.9.6-1.3,0l-4.8-7.8a2.56,2.56,0,0,1,0-2.1l4.9-7.8c.4-.6.9-.6,1.3,0l4.8,7.8A2,2,0,0,1,208.4,255.3Zm-12.3-.1-4.9,7.8c-.4.6-.9.6-1.3,0l-4.8-7.8a2.56,2.56,0,0,1,0-2.1l4.9-7.8c.4-.6.9-.6,1.3,0l4.8,7.8A2,2,0,0,1,196.1,255.2Z" transform="translate(0 0.5)" fill="none" stroke="#000" stroke-width="2"/> <path d="M190.8,244.8l23.9.2m-24,18.6,23.9.2m-17.1-9.6,11.2.1" transform="translate(0 0.5)" fill="none" stroke="#000" stroke-linecap="square" stroke-width="2"/>',
                "Fantom"
            );
    }

    /// @dev Mouth N°10 => Evil
    function item_10() public pure returns (string memory) {
        return
            base(
                '<g display="inline" ><path fill="#FFFFFF" d="M177.3,250.9c0,0,16.5-1.1,17.8-1.6c1.4-0.4,35.2,6.6,37.2,5.7c2.1-0.8,4.7-2,4.7-2s-14.4,8.3-44.5,8.2c0,0-4-0.7-4.8-1.9C186.8,258.3,179.7,251.4,177.3,250.9z" /><path d="M177.2,250.9c0.3-0.1,0.4-0.1,0.6-0.1l0.6-0.1l1.1-0.1l2.2-0.3l4.4-0.5l4.4-0.5l2.2-0.3l1.1-0.2c0.4-0.1,0.7-0.1,1-0.2h0.1c0.5-0.1,0.6,0,0.9,0l0.7,0.1l1.3,0.2l2.7,0.4c1.8,0.3,3.5,0.6,5.3,0.9c3.5,0.7,7,1.4,10.5,2.1c3.5,0.7,7,1.4,10.5,1.9c0.9,0.1,1.8,0.2,2.6,0.3c0.9,0.1,1.8,0.2,2.6,0.1c0.1,0,0.4-0.1,0.6-0.2l0.6-0.3l1.2-0.5l2.4-1.1l0.3,0.7c-3.4,1.9-7,3.2-10.7,4.3s-7.4,1.9-11.2,2.6l-2.8,0.5c-0.9,0.1-1.9,0.2-2.8,0.4c-1.9,0.3-3.8,0.4-5.7,0.5s-3.8,0.2-5.7,0.3h-5.7h-0.1l0,0c-0.9-0.2-1.8-0.4-2.6-0.7c-0.4-0.2-0.9-0.3-1.3-0.5c-0.4-0.2-0.9-0.5-1.2-1v0.1c-0.7-0.8-1.5-1.6-2.3-2.4s-1.6-1.6-2.4-2.3c-0.8-0.8-1.6-1.5-2.5-2.2c-0.4-0.4-0.9-0.7-1.3-1C178.3,251.4,177.8,251.2,177.2,250.9z M177.4,250.9c0.3,0,0.5,0,0.8,0.2c0.3,0.1,0.5,0.2,0.8,0.4c0.5,0.3,1,0.6,1.4,0.9c0.9,0.6,1.8,1.3,2.7,2s1.7,1.4,2.6,2.2c0.8,0.8,1.7,1.5,2.5,2.3v0.1c0.1,0.2,0.5,0.4,0.8,0.6c0.4,0.2,0.8,0.3,1.2,0.4c0.8,0.2,1.6,0.4,2.5,0.6h-0.1l5.7-0.2c1.9-0.1,3.8-0.2,5.7-0.4c3.8-0.3,7.5-0.7,11.3-1.3c3.7-0.6,7.4-1.3,11.1-2.3c1.8-0.5,3.6-1,5.4-1.6c1.8-0.6,3.6-1.3,5.2-2.1l0.3,0.7l-2.5,1l-1.2,0.5l-0.6,0.3c-0.2,0.1-0.4,0.2-0.7,0.2c-1,0.1-1.8-0.1-2.7-0.2c-0.9-0.1-1.8-0.2-2.7-0.4l-10.6-1.6c-3.5-0.5-7.1-1-10.6-1.6l-5.3-0.9l-2.6-0.4l-1.3-0.2l-0.6-0.1c-0.2,0-0.5,0-0.4,0h0.1c-0.5,0.1-0.9,0.2-1.2,0.2l-1.1,0.1c-0.7,0.1-1.5,0.1-2.2,0.2l-4.5,0.3c-1.5,0.1-3,0.2-4.5,0.2l-2.2,0.1h-1.1h-0.6C177.7,250.9,177.5,251,177.4,250.9z" /></g><g display="inline" ><path d="M184.2,256.2c0.5-0.5,1.2-0.9,1.8-1.1c0.3-0.1,0.7-0.1,1.1-0.2c0.4,0,0.7-0.2,1-0.3l0,0h0.1c0.3,0.1,0.7,0.1,1,0.1s0.7,0.1,1,0.2c0.7,0.1,1.3,0.4,1.9,0.7h-0.3c0.4-0.1,0.8-0.2,1.3-0.3v0.1c-0.3,0.4-0.6,0.6-0.9,0.9l-0.1,0.1h-0.2c-0.7-0.1-1.3-0.2-1.9-0.5c-0.3-0.1-0.6-0.2-0.9-0.4c-0.3-0.2-0.6-0.3-0.9-0.5h0.1c-0.3,0.1-0.7,0.2-1,0.4s-0.6,0.4-0.9,0.6C185.7,256.1,185,256.3,184.2,256.2L184.2,256.2z" /></g><g display="inline" ><path d="M201.3,256.5c1.3-0.4,2.7-0.6,4-0.8s2.7-0.4,4.1-0.4h0.1h0.1c1.1,0.6,2.2,1.3,3.3,1.8h-0.1c1.5-0.5,2.9-1.2,4.3-1.7h0.1l0.2,0.1c1.1,0.4,2.1,0.8,3.1,1.2h-0.2c1.5-0.1,3-0.2,4.5-0.2s3,0,4.5,0.1v0.1c-1.5,0.3-2.9,0.5-4.4,0.6c-1.5,0.2-3,0.3-4.4,0.3h-0.1h-0.1c-1-0.5-2-0.9-3.1-1.4h0.3c-1.5,0.4-3,0.8-4.5,1.3h-0.1h-0.1c-1.1-0.6-2.3-1-3.5-1.4h0.2c-1.3,0.3-2.7,0.4-4,0.5C204,256.6,202.7,256.6,201.3,256.5L201.3,256.5z" /></g>',
                "Evil"
            );
    }

    /// @dev Mouth N°11 => Monster
    function item_11() public pure returns (string memory) {
        return
            base(
                '<polyline display="inline" fill="none" stroke="#000000" stroke-width="0.5" stroke-linejoin="round" stroke-miterlimit="10" points="145.8,244.7 150,250.4 153.3,242.5 157.5,255 165.4,242.3 170.3,260.1 179.5,243 185.4,263.2 194.4,243.5 202.9,265.5 212.8,243.8 219.6,263.1 227.1,243.5 235.2,259.1 242.5,243 250.3,254.8 255.6,242.3 260.3,251.8 265.6,241.8 269.8,248.8 274.2,241 276.3,244.6 "  />',
                "Monster"
            );
    }

    /// @dev Mouth N°12 => Drool
    function item_12() public pure returns (string memory) {
        return
            base(
                '<path display="inline" stroke="#000000" stroke-width="0.5" stroke-miterlimit="10" d="M191.1,248c2.8,0.6,7.8,1.6,10.9,1.2l17.1-2.7c0,0,13.1-2.3,13.3,3.9c-1,6.3-2.3,10.5-5.5,11.2c0,0,3.7,10.8-3.2,10.2c-4.2-0.4-2.8-8.6-2.8-8.6s-19.9,5-40.1-1.9c-3.4-1.5-8.4-10-5.2-14.5C177.6,245.4,181.5,244.9,191.1,248z"  />',
                "Drool"
            );
    }

    /// @dev Mouth N°13 => UwU Kitsune
    function item_13() public pure returns (string memory) {
        return
            base(
                '<polyline display="inline" fill="#FFFFFF" stroke="#000000" stroke-width="0.75" stroke-miterlimit="10" points="217.9,254.7 221.2,259.6 224.3,251.9 "  /><g display="inline" ><path d="M178,246.5c1.4,2,3,3.8,4.8,5.3c0.5,0.4,0.9,0.8,1.4,1.1l0.8,0.5c0.3,0.2,0.5,0.3,0.8,0.4c1.1,0.5,2.3,0.7,3.5,0.8c2.4,0.1,4.8-0.4,7.1-0.9l3.5-1.1c1.1-0.5,2.3-0.9,3.4-1.3c0,0,0.1,0,0.1,0c0,0,0,0,0,0.1c-1,0.7-2.1,1.3-3.2,1.9c-1.1,0.5-2.3,1-3.5,1.4c-0.6,0.1-1.2,0.3-1.8,0.4l-0.9,0.2l-0.9,0.1c-0.6,0-1.3,0.1-1.9,0.1c-0.6-0.1-1.3-0.2-1.9-0.2c-0.6-0.1-1.2-0.3-1.8-0.4c-0.6-0.1-1.2-0.4-1.8-0.6c-0.6-0.2-1.2-0.4-1.7-0.7c-0.6-0.2-1.1-0.6-1.7-0.9C180.3,251.1,178.7,249,178,246.5C177.9,246.6,177.9,246.5,178,246.5C178,246.5,178,246.5,178,246.5L178,246.5z" /></g><g display="inline" ><path d="M231.1,245.2c-1.2,2.4-3.1,4.5-5.2,6.1c-1.1,0.8-2.3,1.4-3.6,1.9c-1.2,0.6-2.5,1.1-3.7,1.5c-2.6,0.8-5.4,0.9-8.1,0.2c-2.6-0.7-5.1-1.9-7.2-3.6c0,0,0,0,0-0.1c0,0,0,0,0.1,0c2.4,1.1,4.9,2.1,7.4,2.7c2.5,0.6,5.1,0.7,7.7,0.3c1.3-0.2,2.6-0.6,3.7-1.2c1.2-0.6,2.2-1.4,3.2-2.3C227.4,248.9,229.3,247.1,231.1,245.2C231.1,245.1,231.1,245.1,231.1,245.2C231.1,245.1,231.1,245.2,231.1,245.2z" /></g>',
                "UwU Kitsune"
            );
    }

    /// @dev Mouth N°14 => Stitch
    function item_14() public pure returns (string memory) {
        return
            base(
                '<g display="inline" ><path d="M146.7,249c10.6,1.8,21.4,2.9,32.1,3.9c2.7,0.2,5.3,0.5,8,0.7s5.4,0.3,8,0.5c5.4,0.2,10.7,0.2,16.2,0.1c5.4-0.1,10.7-0.5,16.2-0.7l8-0.6c1.4-0.1,2.7-0.2,4.1-0.3l4-0.4c10.7-1,21.3-2.9,31.9-4.8v0.1l-7.9,1.9l-4,0.8c-1.4,0.3-2.6,0.5-4,0.7l-8,1.4c-2.7,0.4-5.3,0.6-8,1c-5.3,0.7-10.7,0.9-16.2,1.4c-5.4,0.2-10.7,0.4-16.2,0.3c-10.7-0.1-21.6-0.3-32.3-0.9C167.9,252.9,157.1,251.5,146.7,249L146.7,249z" /></g><path display="inline" stroke="#000000" stroke-width="0.75" stroke-miterlimit="10" d="M192.9,254.2c0,0,7.8-2.1,17.5,0.2C210.4,254.4,201.6,257.3,192.9,254.2z"  /><g display="inline" ><path fill="#FFFFFF" stroke="#000000" stroke-width="0.75" stroke-miterlimit="10" d="M215.2,250.7c0,0,1.1-3.4,2.8-1c0,0,0.5,5.3-0.7,9.9c0,0-1,2.2-1.6-0.6C215.2,256.2,216.3,255.9,215.2,250.7z" /><path fill="#FFFFFF" stroke="#000000" stroke-width="0.75" stroke-miterlimit="10" d="M223.3,250.9c0,0,1-3.1,2.5-0.9c0,0,0.5,4.7-0.6,8.9c0,0-0.9,1.9-1.4-0.5C223.3,255.8,224.2,255.5,223.3,250.9z" /><path fill="#FFFFFF" stroke="#000000" stroke-width="0.75" stroke-miterlimit="10" d="M229.7,250.8c0,0,0.9-2.7,2.2-0.8c0,0,0.4,4.1-0.5,7.7c0,0-0.8,1.7-1.1-0.4C229.7,255,230.6,254.8,229.7,250.8z" /><path fill="#FFFFFF" stroke="#000000" stroke-width="0.75" stroke-miterlimit="10" d="M235.2,250.5c0,0,0.8-2.4,2-0.7c0,0,0.4,3.6-0.5,6.9c0,0-0.7,1.5-1-0.4C235.4,254.3,236,254.1,235.2,250.5z" /></g><g display="inline" ><path fill="#FFFFFF" stroke="#000000" stroke-width="0.75" stroke-miterlimit="10" d="M188.4,250.3c0,0-1.1-3.4-2.8-1c0,0-0.5,5.3,0.7,9.9c0,0,1,2.2,1.6-0.6S187.1,255.5,188.4,250.3z" /><path fill="#FFFFFF" stroke="#000000" stroke-width="0.75" stroke-miterlimit="10" d="M180.4,250.5c0,0-1-3.1-2.5-0.9c0,0-0.5,4.7,0.6,8.9c0,0,0.9,1.9,1.4-0.5C180.3,255.5,179.4,255,180.4,250.5z" /><path fill="#FFFFFF" stroke="#000000" stroke-width="0.75" stroke-miterlimit="10" d="M173.8,250.4c0,0-0.9-2.7-2.2-0.8c0,0-0.4,4.1,0.5,7.7c0,0,0.8,1.7,1.1-0.4C173.6,254.7,172.9,254.4,173.8,250.4z" /><path fill="#FFFFFF" stroke="#000000" stroke-width="0.75" stroke-miterlimit="10" d="M168.2,250c0,0-0.8-2.4-2-0.7c0,0-0.4,3.6,0.5,6.9c0,0,0.7,1.5,1-0.4C168.2,253.9,167.5,253.7,168.2,250z" /></g>',
                "Stitch"
            );
    }

    /// @dev Mouth N°15 => Pantin
    function item_15() public pure returns (string memory) {
        return
            base(
                '<path display="inline"  d="M227.4,254h-46.7c-0.5,0-0.9-0.4-0.9-0.9v-2c0-0.5,0.4-0.9,0.9-0.9h46.7c0.5,0,0.9,0.4,0.9,0.9v2C228.2,253.7,228,254,227.4,254z"  /><path display="inline"  stroke="#000000" stroke-linecap="round" stroke-miterlimit="10" d="M180.4,251.1c-0.9,9.5-0.5,18.8,0.5,29.7"  /><path display="inline"  stroke="#000000" stroke-linecap="round" stroke-miterlimit="10" d="M227.7,251c0.5,10.5,0.1,22.5-0.7,35.3"  />',
                "Pantin"
            );
    }

    /// @dev Mouth N°16 => Akuma
    function item_16() public pure returns (string memory) {
        return
            base(
                '<path display="inline" d="M278,243.1c-8.1,1.5-18.1,4.2-26.3,5.5c-8.1,1.4-16.3,2.5-24.6,2.8l0.3-0.2l-5.6,10.9l-0.4,0.7l-0.4-0.7l-5.3-10.4l0.4,0.2c-4.8,0.3-9.6,0.6-14.4,0.5c-4.8,0-9.6-0.5-14.4-1.1l0.4-0.2l-5.7,11.3l-0.3,0.5l-0.3-0.5l-5.9-11.6l0.2,0.1l-7.6-0.6c-2.5-0.2-5.1-0.6-7.6-1.1c-1.3-0.2-2.5-0.5-3.8-0.8s-2.5-0.6-3.8-1c-2.4-0.7-4.9-1.5-7.3-2.4v-0.1c2.5,0.4,5,1,7.5,1.6c1.3,0.2,2.5,0.5,3.8,0.8l3.8,0.8c2.5,0.5,5,1.1,7.5,1.6s5,0.8,7.6,0.8h0.1l0.1,0.1l6.1,11.6h-0.5l5.5-11.3l0.1-0.2h0.3c4.8,0.5,9.5,1,14.3,1s9.6-0.2,14.4-0.5h0.3l0.1,0.2l5.3,10.4h-0.7l5.7-10.8l0.1-0.2h0.2c8.2-0.2,16.4-1.3,24.5-2.6c8-1.1,16.2-2.7,24.3-4L278,243.1z"  />',
                "Akuma"
            );
    }

    /// @dev Mouth N°17 => Monster Teeth
    function item_17() public pure returns (string memory) {
        return
            base(
                '<path display="inline" fill="#FFFFFF" stroke="#000000" stroke-width="0.75" stroke-miterlimit="10" d="M165.5,241.9c0,0,0.5,0.1,1.4,0.3c4.3,1.2,36.4,12.1,81.4-1c0.1,0.1-17.5,28.2-43.1,28.6C192.4,270.1,181.1,263.4,165.5,241.9z"  /><polyline display="inline" fill="none" stroke="#000000" stroke-width="0.75" stroke-linejoin="round" stroke-miterlimit="10" points="168.6,245.8 171.3,243.6 173.9,252.6 177.5,245.1 181.7,260.4 188.2,246.8 192.8,267.3 198.5,247.8 204,269.9 209,247.9 215.5,268.3 219.3,247.1 225.4,264 228.2,246 234,257.8 236.7,244.5 240.4,251.4 243.1,242.7 245.9,245.1 "  /><g display="inline" opacity="0.52" ><path d="M246.1,239.5c1.9-0.8,3.5-1.4,5.9-1.9l0.6-0.1l-0.2,0.6c-0.6,2.2-1.3,4.5-2.1,6.5c0.3-2.4,0.8-4.6,1.4-6.9l0.4,0.5C250.1,239,248.2,239.4,246.1,239.5z" /></g><g display="inline" opacity="0.52" ><path d="M168,240.4c-2-0.2-4-0.5-5.9-0.8l0.4-0.5c0.6,2.4,1.3,4.7,1.5,7.2c-0.9-2.2-1.6-4.6-2.2-7l-0.2-0.6l0.6,0.1C164.1,239,165.9,239.7,168,240.4z" /></g>',
                "Monster Teeth"
            );
    }

    /// @dev Mouth N°18 => Dubu
    function item_18() public pure returns (string memory) {
        return
            base(
                '<g display="inline" ><path d="M204,251.4c-2.2-1.2-4.5-2.1-6.9-2.6c-1.2-0.2-2.4-0.4-3.6-0.4c-1.1,0-2.4,0.2-3.1,0.7c-0.4,0.2-0.5,0.5-0.5,0.9s0.3,1,0.6,1.5c0.6,1,1.5,1.9,2.5,2.6c2,1.5,4.3,2.6,6.6,3.6l3.3,1.4l-3.7-0.3c-2.4-0.2-4.9-0.4-7.2-0.2c-0.6,0.1-1.1,0.2-1.5,0.4c-0.4,0.2-0.7,0.4-0.6,0.5c0,0.1,0,0.5,0.3,0.9s0.6,0.8,1,1.2c1.7,1.5,3.8,2.6,6,3.3c2.2,0.6,4.7,0.8,6.9-0.4h0.1v0.1c-0.9,0.9-2.1,1.5-3.4,1.7c-1.3,0.3-2.6,0.2-3.9,0c-2.6-0.4-5-1.5-7.1-3.2c-0.5-0.4-1-1-1.4-1.6s-0.8-1.5-0.6-2.6c0.1-0.5,0.5-1,0.8-1.3c0.2-0.2,0.4-0.3,0.5-0.4c0.2-0.1,0.4-0.2,0.6-0.3c0.7-0.3,1.4-0.4,2.1-0.4c2.7-0.2,5.1,0.3,7.5,0.9l-0.4,1.1l-1.6-1c-0.5-0.3-1.1-0.7-1.6-1l-1.6-1c-0.5-0.4-1.1-0.7-1.6-1.1c-1-0.7-2.1-1.5-3-2.5c-0.4-0.5-0.9-1.1-1.1-1.9c-0.1-0.4-0.1-0.9,0.1-1.3c0.2-0.4,0.4-0.8,0.8-1.1c1.3-1,2.8-1.1,4.1-1.2c1.4,0,2.7,0.2,3.9,0.6c2.5,0.8,4.9,2.1,6.6,4v0.1C204.1,251.4,204.1,251.4,204,251.4z" /></g>',
                "Dubu"
            );
    }

    /// @notice Return the skin name of the given id
    /// @param id The skin Id
    function getItemNameById(uint8 id) public pure returns (string memory name) {
        name = "";
        if (id == 1) {
            name = "Neutral";
        } else if (id == 2) {
            name = "Canine";
        } else if (id == 3) {
            name = "Canine up";
        } else if (id == 4) {
            name = "Poker";
        } else if (id == 5) {
            name = "Angry";
        } else if (id == 6) {
            name = "Sulk";
        } else if (id == 7) {
            name = "Tongue";
        } else if (id == 8) {
            name = "None";
        } else if (id == 9) {
            name = "Fantom";
        } else if (id == 10) {
            name = "Evil";
        } else if (id == 11) {
            name = "Monster";
        } else if (id == 12) {
            name = "Drool";
        } else if (id == 13) {
            name = "UwU Kitsune";
        } else if (id == 14) {
            name = "Stitch";
        } else if (id == 15) {
            name = "Pantin";
        } else if (id == 16) {
            name = "Akuma";
        } else if (id == 17) {
            name = "Monster Teeth";
        } else if (id == 18) {
            name = "Dubu";
        }
    }

    /// @dev The base SVG for the body
    function base(string memory children, string memory name) private pure returns (string memory) {
        return string(abi.encodePacked('<g id="mouth"><g id="', name, '">', children, "</g></g>"));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

pragma abicoder v2;

import "base64-sol/base64.sol";

/// @title Nose SVG generator
library NoseDetail {
    /// @dev Nose N°1 => Kitsune Blood
    function item_1() public pure returns (string memory) {
        return
            base(
                '<path display="inline" fill="#B50D5E" stroke="#B50D5E" stroke-miterlimit="10" d="M193.2,224.9c5.1,0.6,10.3,1,16.4,0c0.4-0.1,0.7,0.5,0.3,0.8l-7.4,5.9c-0.5,0.4-1.3,0.4-1.8,0l-7.9-6C192.5,225.4,192.7,224.8,193.2,224.9z"  />',
                "Kitsune Blood"
            );
    }

    /// @dev Nose N°2 => Kitsune Moon
    function item_2() public pure returns (string memory) {
        return
            base(
                '<path display="inline" stroke="#000000" stroke-miterlimit="10" d="M193.2,224.9c5.1,0.6,10.3,1,16.4,0c0.4-0.1,0.7,0.5,0.3,0.8l-7.4,5.9c-0.5,0.4-1.3,0.4-1.8,0l-7.9-6C192.5,225.4,192.7,224.8,193.2,224.9z"  />',
                "Kitsune Moon"
            );
    }

    // @dev Nose N°3 => None
    function item_3() public pure returns (string memory) {
        return base("", "None");
    }

    /// @dev Nose N°4 => Kitsune Pure
    function item_4() public pure returns (string memory) {
        return
            base(
                '<path display="inline" fill="#FFEDED" stroke="#FFEDED" stroke-miterlimit="10" d="M193.2,224.9c5.1,0.6,10.3,1,16.4,0c0.4-0.1,0.7,0.5,0.3,0.8l-7.4,5.9c-0.5,0.4-1.3,0.4-1.8,0l-7.9-6C192.5,225.4,192.7,224.8,193.2,224.9z"  />',
                "Kitsune Pure"
            );
    }

    /// @dev Nose N°5 => Nosetril
    function item_5() public pure returns (string memory) {
        return
            base(
                '<path display="inline" stroke="#000000" stroke-width="0.75" stroke-miterlimit="10" d="M196.4,229.2c-0.4,0.3-2.1-0.9-4.1-2.5c-1.9-1.6-3-2.7-2.6-2.9c0.4-0.3,2.5,0,4.2,1.8C195.4,227.2,196.8,228.8,196.4,229.2z"  /><path display="inline" stroke="#000000" stroke-width="0.75" stroke-miterlimit="10" d="M206.5,228.7c0.3,0.4,2.2-0.3,4.2-1.7c2-1.5,3.5-2,3.2-2.4s-2.5-0.7-4.5,0.7C207.4,226.9,206.1,228.2,206.5,228.7z"  />',
                "Nosetril"
            );
    }

    /// @dev Nose N°6 => Akuma
    function item_6() public pure returns (string memory) {
        return
            base(
                '<path opacity="0.5" stroke="#000000" stroke-miterlimit="10" enable-background="new    " d="M191.6,224.5c6.1,1,12.2,1.7,19.8,0.4l-8.9,6.8c-0.5,0.4-1.3,0.4-1.8,0L191.6,224.5z"  /><path stroke="#000000" stroke-width="0.75" stroke-miterlimit="10" d="M196.4,229.2c-0.4,0.3-2.1-0.9-4.1-2.5c-1.9-1.6-3-2.7-2.6-2.9c0.4-0.3,2.5,0,4.2,1.8C195.4,227.2,196.8,228.8,196.4,229.2z"  /><path stroke="#000000" stroke-width="0.75" stroke-miterlimit="10" d="M206.5,228.7c0.3,0.4,2.2-0.3,4.2-1.7c2-1.5,3.5-2,3.2-2.4s-2.5-0.7-4.5,0.7C207.4,226.9,206.1,228.2,206.5,228.7z"  />',
                "Akuma"
            );
    }

    /// @dev Nose N°7 => Human
    function item_7() public pure returns (string memory) {
        return
            base(
                '<g display="inline" ><path d="M193.5,190.1c1.5,9,1.7,18.4-0.7,27.3h-0.1C193.2,208.2,194.4,199.2,193.5,190.1L193.5,190.1z" /></g><path display="inline" opacity="0.56" enable-background="new    " d="M198.6,231.3l-8.2-3.6c-0.4-0.2-0.5-0.7-0.2-1.1l3.3-3.4c0.4-0.4,1-0.5,1.6-0.3l13.2,4.8c0.6,0.2,0.6,1.1-0.1,1.4l-9.1,2.5C199,231.5,198.8,231.5,198.6,231.3z"  />',
                "Human"
            );
    }

    /// @dev Nose N°8 => Bleeding
    function item_8() public pure returns (string memory) {
        return
            base(
                '<g display="inline" ><path d="M193.5,190.1c1.5,9,1.7,18.4-0.7,27.3h-0.1C193.2,208.2,194.4,199.2,193.5,190.1L193.5,190.1z" /></g><path display="inline" opacity="0.56" enable-background="new    " d="M198.6,231.3l-8.2-3.6c-0.4-0.2-0.5-0.7-0.2-1.1l3.3-3.4c0.4-0.4,1-0.5,1.6-0.3l13.2,4.8c0.6,0.2,0.6,1.1-0.1,1.4l-9.1,2.5C199,231.5,198.8,231.5,198.6,231.3z"  /><g display="inline" ><path fill="#E90000" d="M204.7,242c0.7-0.3,1.1,0,1.1,0.7C204.2,243.4,201.3,243.5,204.7,242z" /><path fill="#FF0000" d="M205,229.5c0.5,3.1-1.1,6.4-0.1,9.6c0.8,1.6-0.6,2.9-2.2,3.1c-1.4-3.4,1.7-7.8,0.3-11.4C202.2,229.5,204.7,228.3,205,229.5z" /></g>',
                "Bleeding"
            );
    }

    /// @notice Return the skin name of the given id
    /// @param id The skin Id
    function getItemNameById(uint8 id) public pure returns (string memory name) {
        name = "";
        if (id == 1) {
            name = "Akuma";
        } else if (id == 2) {
            name = "Human";
        } else if (id == 3) {
            name = "Kitsune Blood";
        } else if (id == 4) {
            name = "Kitsune Moon";
        } else if (id == 5) {
            name = "Nosetril";
        } else if (id == 6) {
            name = "Kitsune Pure";
        } else if (id == 7) {
            name = "None";
        } else if (id == 8) {
            name = "Bleeding";
        }
    }

    /// @dev The base SVG for the body
    function base(string memory children, string memory name) private pure returns (string memory) {
        return string(abi.encodePacked('<g id="nose"><g id="', name, '">', children, "</g></g>"));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

pragma abicoder v2;

import "base64-sol/base64.sol";
import "./Eyes/EyesParts1.sol";
import "./Eyes/EyesParts2.sol";

/// @title Eyes SVG generator
library EyesDetail {
    /// @dev Eyes N°1 => Happy
    function item_1() public pure returns (string memory) {
        return base(EyesParts2.item_5(), "Happy");
    }

    /// @dev Eyes N°2 => Feels
    function item_2() public pure returns (string memory) {
        return base(EyesParts2.item_4(), "Feels");
    }

    /// @dev Eyes N°3 => Pupils Blood
    function item_3() public pure returns (string memory) {
        return base(EyesParts1.item_11(), "Pupils Blood");
    }

    /// @dev Eyes N°4 => Spiral
    function item_4() public pure returns (string memory) {
        return base(EyesParts1.item_10(), "Spiral");
    }

    /// @dev Eyes N°5 => Pupils Moon
    function item_5() public pure returns (string memory) {
        return base(EyesParts1.item_9(), "Pupils Moon");
    }

    /// @dev Eyes N°6 => Rip
    function item_6() public pure returns (string memory) {
        return base(EyesParts2.item_9(), "Rip");
    }

    /// @dev Eyes N°7 => Pupils pure
    function item_7() public pure returns (string memory) {
        return base(EyesParts1.item_15(), "Pupils Pure");
    }

    /// @dev Eyes N°8 => Akuma
    function item_8() public pure returns (string memory) {
        return base(EyesParts1.item_8(), "Akuma");
    }

    /// @dev Eyes N°9 => Scribble
    function item_9() public pure returns (string memory) {
        return base(EyesParts2.item_8(), "Scribble");
    }

    /// @dev Eyes N°10 => Arrow
    function item_10() public pure returns (string memory) {
        return base(EyesParts2.item_7(), "Arrow");
    }

    /// @dev Eyes N°11 => Globes
    function item_11() public pure returns (string memory) {
        return base(EyesParts1.item_7(), "Globes");
    }

    /// @dev Eyes N°12 => Stitch
    function item_12() public pure returns (string memory) {
        return base(EyesParts1.item_6(), "Stitch");
    }

    /// @dev Eyes N°13 => Closed
    function item_13() public pure returns (string memory) {
        return base(EyesParts2.item_6(), "Closed");
    }

    /// @dev Eyes N°14 => Kitsune
    function item_14() public pure returns (string memory) {
        return base(EyesParts1.item_13(), "Kitsune");
    }

    /// @dev Eyes N°15 => Moon
    function item_15() public pure returns (string memory) {
        return base(EyesParts1.item_12(), "Moon");
    }

    /// @dev Eyes N°16 => Shine
    function item_16() public pure returns (string memory) {
        return base(EyesParts1.item_5(), "Shine");
    }

    /// @dev Eyes N°17 => Shock
    function item_17() public pure returns (string memory) {
        return base(EyesParts1.item_14(), "Shock");
    }

    /// @dev Eyes N°18 => Tomoe Blood
    function item_18() public pure returns (string memory) {
        return base(EyesParts1.item_4(), "Tomoe Blood");
    }

    /// @dev Eyes N°19 => Stitched
    function item_19() public pure returns (string memory) {
        return base(EyesParts2.item_3(), "Stitched");
    }

    /// @dev Eyes N°20 => Tomoe Pure
    function item_20() public pure returns (string memory) {
        return base(EyesParts1.item_3(), "Tomoe Pure");
    }

    /// @dev Eyes N°21 => Pupils Pure-Blood
    function item_21() public pure returns (string memory) {
        return base(EyesParts1.item_2(), "Pupils Pure-Blood");
    }

    /// @dev Eyes N°22 => Dubu
    function item_22() public pure returns (string memory) {
        return base(EyesParts2.item_1(), "Dubu");
    }

    /// @dev Eyes N°23 => Moon Kin
    function item_23() public pure returns (string memory) {
        return base(EyesParts1.item_1(), "Moon Kin");
    }

    /// @notice Return the skin name of the given id
    /// @param id The skin Id
    function getItemNameById(uint8 id) public pure returns (string memory name) {
        name = "";
        if (id == 1) {
            name = "Happy";
        } else if (id == 2) {
            name = "Feels";
        } else if (id == 3) {
            name = "Pupils Blood";
        } else if (id == 4) {
            name = "Spiral";
        } else if (id == 5) {
            name = "Pupils Moon";
        } else if (id == 6) {
            name = "Rip";
        } else if (id == 7) {
            name = "Pupils Pure";
        } else if (id == 8) {
            name = "Akuma";
        } else if (id == 9) {
            name = "Scribble";
        } else if (id == 10) {
            name = "Arrow";
        } else if (id == 11) {
            name = "Globes";
        } else if (id == 12) {
            name = "Stitch";
        } else if (id == 13) {
            name = "Closed";
        } else if (id == 14) {
            name = "Kitsune";
        } else if (id == 15) {
            name = "Moon";
        } else if (id == 16) {
            name = "Shine";
        } else if (id == 17) {
            name = "Shock";
        } else if (id == 18) {
            name = "Tomoe Blood";
        } else if (id == 19) {
            name = "Stitched";
        } else if (id == 20) {
            name = "Tomoe Pure";
        } else if (id == 21) {
            name = "Pupils Pure-Blood";
        } else if (id == 22) {
            name = "Dubu";
        } else if (id == 23) {
            name = "Moon Kin";
        }
    }

    /// @dev The base SVG for the body
    function base(string memory children, string memory name) private pure returns (string memory) {
        return string(abi.encodePacked('<g id="eyes"><g id="', name, '">', children, "</g></g>"));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

pragma abicoder v2;

import "base64-sol/base64.sol";

/// @title Eyebrow SVG generator
library EyebrowDetail {
    /// @dev Eyebrow N°1 => Kitsune Blood
    function item_1() public pure returns (string memory) {
        return base(kitsune("B50D5E"), "Kitsune Blood");
    }

    /// @dev Eyebrow N°2 => Kitsune Moon
    function item_2() public pure returns (string memory) {
        return base(kitsune("000000"), "Kitsune Moon");
    }

    /// @dev Eyebrow N°3 => Slayer Blood
    function item_3() public pure returns (string memory) {
        return base(slayer("B50D5E"), "Slayer Blood");
    }

    /// @dev Eyebrow N°4 => Slayer Moon
    function item_4() public pure returns (string memory) {
        return base(slayer("000000"), "Slayer Moon");
    }

    /// @dev Eyebrow N°5 => Shaved
    function item_5() public pure returns (string memory) {
        return
            base(
                '<g opacity="0.06"><path d="M218.3,173s24.22-3.6,30.64-3.4,11,1.7,14.08,3.5c0,0-22.75,2.9-32.89,3.2S219.77,176.44,218.3,173Z" transform="translate(-0.4)" stroke="#000" stroke-miterlimit="10" fill-rule="evenodd"/> <path d="M187,173.34s-23.54-3.8-30-3.5-10.7,1.6-13.74,3.5c0,0,22.19,2.9,32.21,3.3C185.24,177,185.91,176.74,187,173.34Z" transform="translate(-0.4)" stroke="#000" stroke-miterlimit="10" fill-rule="evenodd"/></g>',
                "Shaved"
            );
    }

    /// @dev Eyebrow N°6 => Thick Blood
    function item_6() public pure returns (string memory) {
        return base(thick("B50D5E"), "Thick Blood");
    }

    /// @dev Eyebrow N°7 => Thick Moon
    function item_7() public pure returns (string memory) {
        return base(thick("000000"), "Thick Moon");
    }

    /// @dev Eyebrow N°8 => None
    function item_8() public pure returns (string memory) {
        return base("", "None");
    }

    /// @dev Eyebrow N°9 => Electric Blood
    function item_9() public pure returns (string memory) {
        return base(electric("B50D5E"), "Electric Blood");
    }

    /// @dev Eyebrow N°10 => Electric Moon
    function item_10() public pure returns (string memory) {
        return base(electric("000000"), "Electric Moon");
    }

    /// @dev Eyebrow N°11 => Robot Blood
    function item_11() public pure returns (string memory) {
        return base(robot("B50D5E"), "Robot Blood");
    }

    /// @dev Eyebrow N°12 => Robot Moon
    function item_12() public pure returns (string memory) {
        return base(robot("000000"), "Robot Moon");
    }

    /// @dev Eyebrow N°13 => Tomoe Blood
    function item_13() public pure returns (string memory) {
        return base(tomoe("B50D5E"), "Tomoe Blood");
    }

    /// @dev Eyebrow N°14 => Tomoe Moon
    function item_14() public pure returns (string memory) {
        return base(tomoe("000000"), "Tomoe Moon");
    }

    /// @dev Eyebrow N°15 => Kitsune Pure
    function item_15() public pure returns (string memory) {
        return base(kitsune("FFEDED"), "Kitsune Pure");
    }

    /// @dev Eyebrow N°16 => Slayer Pure
    function item_16() public pure returns (string memory) {
        return base(slayer("FFEDED"), "Slayer Pure");
    }

    /// @dev Eyebrow N°17 => Thick Pure
    function item_17() public pure returns (string memory) {
        return base(thick("FFEDED"), "Thick Pure");
    }

    /// @dev Eyebrow N°18 => Electric Pure
    function item_18() public pure returns (string memory) {
        return base(electric("FFEDED"), "Electric Pure");
    }

    /// @dev Eyebrow N°19 => Robot Pure
    function item_19() public pure returns (string memory) {
        return base(robot("FFEDED"), "Robot Pure");
    }

    /// @dev Eyebrow N°20 => Tomoe Pure
    function item_20() public pure returns (string memory) {
        return base(tomoe("FFEDED"), "Tomoe Pure");
    }

    /// @dev Eyebrow N°21 => Tomoe Kin
    function item_21() public pure returns (string memory) {
        return
            base(
                '<linearGradient id="Tomoe_Gold_Gradient" gradientUnits="userSpaceOnUse" x1="215.6498" y1="-442.1553" x2="232" y2="-442.1553" gradientTransform="matrix(1 0 0 -1 0 -270)" ><stop offset="0" style="stop-color:#FFB451" /><stop offset="0.5259" style="stop-color:#F7E394" /><stop offset="1" style="stop-color:#FF9B43" /></linearGradient><path display="inline"  fill="url(#Tomoe_Gold_Gradient)" d="M232,168.9c-6.7-3.4-11.3-1.9-12.8-1.2c-0.1,0-0.3,0.1-0.4,0.1c-2.6,1-3.9,4.1-2.7,6.6c1,2.6,4.1,3.9,6.6,2.7c2.6-1,3.9-4.1,2.7-6.6c0-0.1-0.1-0.2-0.1-0.2C228.1,168.4,232,168.9,232,168.9z M221.4,174.1c-0.9,0.3-1.8,0-2.2-0.9c-0.3-0.9,0-1.8,0.9-2.2c0.9-0.3,1.8,0,2.2,0.9C222.7,172.7,222.2,173.7,221.4,174.1z"  /><linearGradient id="SVGID_00000169552172318176501370000006213919017808816827_" gradientUnits="userSpaceOnUse" x1="171" y1="-442.5519" x2="187.1496" y2="-442.5519" gradientTransform="matrix(1 0 0 -1 0 -270)" ><stop offset="0" style="stop-color:#FFB451" /><stop offset="0.5259" style="stop-color:#F7E394" /><stop offset="1" style="stop-color:#FF9B43" /></linearGradient><path display="inline"  fill="url(#SVGID_00000169552172318176501370000006213919017808816827_)" d="M184.2,168.3c-0.9-0.5-5.7-2.8-13.2,1c0,0,3.8-0.5,6.6,1.3c-0.1,0.1-0.1,0.2-0.2,0.3c-1.2,2.5,0.1,5.6,2.7,6.6c2.5,1.2,5.6-0.1,6.6-2.7C187.9,172.4,186.7,169.4,184.2,168.3z M183.8,173.6c-0.4,0.9-1.3,1.2-2.2,0.9c-0.9-0.4-1.4-1.4-0.9-2.2c0.4-0.9,1.3-1.2,2.2-0.9C183.8,171.8,184.1,172.7,183.8,173.6z"  />',
                "Tomoe Kin"
            );
    }

    function electric(string memory color) private pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<path display="inline"  fill="#',
                    color,
                    '" d="M216,176.7c14.2-2.2,47-5.6,50.4-6.6l-14.8-0.7l17.4-9.1c-17.8,7.7-37.5,12.9-56.3,13.3C213.1,174.8,214.6,176.1,216,176.7z"  /><path display="inline"  fill="#',
                    color,
                    '" d="M186.7,176.7c-12.8-2.1-44.8-5.3-48-6.3l13.5-0.9l-15.4-8.8c15.9,7.4,33.7,11.9,49,13.2C186.1,175.2,186.5,175.5,186.7,176.7z"  />'
                )
            );
    }

    function robot(string memory color) private pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<circle display="inline"  fill="#',
                    color,
                    '" cx="184.1" cy="170" r="5.5"  /><circle display="inline"  fill="#',
                    color,
                    '" cx="217" cy="169.8" r="5.5"  />'
                )
            );
    }

    function kitsune(string memory color) private pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<path display="inline"  fill="#',
                    color,
                    '" d="M238.3,166.9c-12.3-3.9-19-1.1-21.3,0.2c-0.1,0-0.2,0.1-0.3,0.2c-0.3,0.1-0.5,0.4-0.6,0.4l0,0l0,0l0,0c-0.9,0.8-1.6,2-1.6,3.3c-0.2,2.7,1.9,5,4.6,5.2c2.7,0.2,5-1.9,5.2-4.6c0.1-0.3,0-0.6,0-1C228.9,166.5,238.3,166.9,238.3,166.9z"  /><path display="inline"  fill="#',
                    color,
                    '" d="M162.6,166.8c12.3-3.9,19-1,21.3,0.3c0.1,0,0.2,0.1,0.3,0.2c0.3,0.1,0.5,0.4,0.6,0.4l0,0l0,0l0,0c0.9,0.8,1.6,2,1.6,3.3c0.2,2.7-1.9,5-4.6,5.2c-2.7,0.2-5-1.9-5.2-4.6c-0.1-0.3,0-0.6,0-1C172,166.5,162.6,166.8,162.6,166.8z"  />'
                )
            );
    }

    function slayer(string memory color) private pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<path display="inline" fill="#',
                    color,
                    '" d="M217.3,168.6c-0.8,1.5-4.8,12.6,9.4,9.9c0,0,9.6-4.5,12.5-8.1c0,0-6.7,0.6-8.1,1.5c0,0,7.2-3.2,8.5-6.7c0,0-11.4,2.1-12,3.9c0,0,2.7-4.7,4.2-5.3s-7.6,1.4-8.5,3.5c-0.9,2.2,0.5-5.6,2.1-6.1C227,160.7,220.2,163,217.3,168.6z"/> <path display="inline" fill="#',
                    color,
                    '" d="M186.6,168.5c0.8,1.5,4.8,12.6-9.4,9.9c0,0-9.6-4.5-12.5-8.1c0,0,6.7,0.6,8.1,1.5c0,0-7.2-3.2-8.5-6.7c0,0,11.4,2.1,12,3.9c0,0-2.7-4.7-4.2-5.3s7.6,1.4,8.5,3.5c0.9,2.2-0.5-5.6-2.1-6.1C176.9,160.7,183.9,162.9,186.6,168.5z"/>'
                )
            );
    }

    function tomoe(string memory color) private pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<g display="inline"> <path  fill="#',
                    color,
                    '" d="M218.6,168c0,0,5-3.3,13.4,0.9c0,0-4-0.5-6.8,1.4"/> <path  fill="#',
                    color,
                    '" d="M218.8,167.8c-2.6,1-3.9,4.1-2.7,6.6c1,2.6,4.1,3.9,6.6,2.7 c2.6-1,3.9-4.1,2.7-6.6C224.3,168.1,221.4,166.8,218.8,167.8z M221.4,174.1c-0.9,0.3-1.8,0-2.2-0.9c-0.3-0.9,0-1.8,0.9-2.2 c0.9-0.3,1.8,0,2.2,0.9C222.7,172.7,222.2,173.7,221.4,174.1z"/> </g> <g display="inline"> <path  fill="#',
                    color,
                    '" d="M184.4,168.4c0,0-5-3.3-13.4,0.9c0,0,4-0.5,6.8,1.4"/> <path  fill="#',
                    color,
                    '" d="M184,168.2c2.6,1,3.9,4.1,2.7,6.6c-1,2.6-4.1,3.9-6.6,2.7 c-2.6-1-3.9-4.1-2.7-6.6C178.7,168.4,181.5,167.2,184,168.2z M181.6,174.5c0.9,0.3,1.8,0,2.2-0.9c0.3-0.9,0-1.8-0.9-2.2 c-0.9-0.3-1.8,0-2.2,0.9C180.2,173.1,180.7,174.1,181.6,174.5z"/> </g>'
                )
            );
    }

    function thick(string memory color) private pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<g id="Thick_L" > <path  fill="#',
                    color,
                    '" d="M213.7,173.6c-0.6-1.4,0.1-3.1,1.6-3.5c1.7-0.5,4.3-1.2,7.5-1.7 c1.5-0.3,13.2-4.2,14.4-4.9c0.2,0.9-6.2,4.1-4.9,3.9c7.3-1.2,14.7-2.2,18.1-2c3.6,0.1,6.4,0.4,9,1.2c0.6,0.2,5.3,1.1,5.9,1.4 c0.4,0.2-3-0.1-2.6,0.1c1.9,0.9,3.6,1.9,5.1,3c0,0-28,4.7-40.5,5.3C217.3,176.8,215,176.6,213.7,173.6z"/> </g> <g id="Thick_R" > <path  fill="#',
                    color,
                    '" d="M187.1,173.7c0.6-1.4-0.1-3.1-1.6-3.5c-6.2-1.9-8.9-2-7.3-1.7 c-1.5-0.3-12.4-4.7-13.7-5.3c-0.2,0.9,5.6,4.6,4.5,4.4c-7.1-1.2-14.2-2.2-17.5-2c-3.5,0.1-6.2,0.4-8.7,1.2 c-0.6,0.2-5.1,1.1-5.7,1.4c-0.4,0.2,2.9-0.1,2.5,0.1c-1.8,0.9-3.5,1.9-4.9,3c0,0,27.1,4.7,39.3,5.3 C183.6,176.9,185.9,176.7,187.1,173.7z"/> </g>'
                )
            );
    }

    /// @notice Return the skin name of the given id
    /// @param id The skin Id
    function getItemNameById(uint8 id) public pure returns (string memory name) {
        name = "";
        if (id == 1) {
            name = "Kitsune Blood";
        } else if (id == 2) {
            name = "Kitsune Moon";
        } else if (id == 3) {
            name = "Slayer Blood";
        } else if (id == 4) {
            name = "Slayer Moon";
        } else if (id == 5) {
            name = "Shaved";
        } else if (id == 6) {
            name = "Thick Blood";
        } else if (id == 7) {
            name = "Thick Moon";
        } else if (id == 8) {
            name = "None";
        } else if (id == 9) {
            name = "Electric Blood";
        } else if (id == 10) {
            name = "Electric Moon";
        } else if (id == 11) {
            name = "Robot Blood";
        } else if (id == 12) {
            name = "Robot Moon";
        } else if (id == 13) {
            name = "Tomoe Blood";
        } else if (id == 14) {
            name = "Tomoe Moon";
        } else if (id == 15) {
            name = "Kitsune Pure";
        } else if (id == 16) {
            name = "Slayer Pure";
        } else if (id == 17) {
            name = "Thick Pure";
        } else if (id == 18) {
            name = "Electric Pure";
        } else if (id == 19) {
            name = "Robot Pure";
        } else if (id == 20) {
            name = "Tomoe Pure";
        } else if (id == 21) {
            name = "Tomoe Kin";
        }
    }

    /// @dev The base SVG for the body
    function base(string memory children, string memory name) private pure returns (string memory) {
        return string(abi.encodePacked('<g id="eyebrow"><g id="', name, '">', children, "</g></g>"));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

pragma abicoder v2;

import "base64-sol/base64.sol";

/// @title Mark SVG generator
library MarkDetail {
    /// @dev Mark N°1 => None
    function item_1() public pure returns (string memory) {
        return base("", "None");
    }

    /// @dev Mark N°2 => Dark circle
    function item_2() public pure returns (string memory) {
        return
            base(
                '<g display="inline" ><path d="M163,210.9c4.8,0.2,9.5-1.4,13.9-3.3C173,210.4,167.7,211.7,163,210.9z" /><path d="M159,210.1c-2.4-0.4-4.7-1.7-6.7-3.1C154.5,207.9,156.8,209,159,210.1z" /></g><g display="inline" ><path d="M236.6,210.4c5.3,0.1,10.5-1.5,15.3-3.5C247.8,209.8,241.9,211.1,236.6,210.4z" /><path d="M232.1,209.6c-2.7-0.4-5.2-1.6-7.3-3C227.3,207.5,229.8,208.6,232.1,209.6z" /></g>',
                "Dark Circle"
            );
    }

    /// @dev Mark N°3 => Akuma Blood
    function item_3() public pure returns (string memory) {
        return base(akuma("b50d5e"), "Akuma Blood");
    }

    /// @dev Mark N°4 => Brother
    function item_4() public pure returns (string memory) {
        return
            base(
                '<g display="inline" ><path  d="M220.1,206.2c0,0,15.2,24.7,32.7,39.1" /><path d="M220.1,206.2c1.3,1.8,2.4,3.5,3.8,5.2c1.3,1.8,2.5,3.4,3.8,5.1c2.6,3.4,5.1,6.7,7.8,10c2.6,3.3,5.5,6.4,8.3,9.6c1.5,1.6,2.9,3.1,4.5,4.6c1.5,1.6,3.1,2.9,4.6,4.5c-3.4-2.6-6.6-5.4-9.6-8.3c-3-3-5.8-6.2-8.5-9.5s-5.3-6.7-7.7-10.1C224.6,213.4,222.2,209.9,220.1,206.2z" /></g><g display="inline" ><path  d="M182.1,207c0,0-9.1,20.2-23.7,37.8" /><path d="M182.1,207c-1.4,3.4-3,6.9-4.7,10.1c-1.7,3.3-3.5,6.6-5.5,9.7c-2,3.1-4.1,6.3-6.3,9.3s-4.6,5.8-7.1,8.6c1-1.6,2.2-3,3.2-4.5l1.7-2.3l1.6-2.3c2.1-3.1,4.2-6.1,6-9.4c2-3.1,3.9-6.4,5.7-9.6c0.9-1.6,1.9-3.2,2.7-4.9C180.5,210.2,181.2,208.6,182.1,207z" /></g>',
                "Brother"
            );
    }

    /// @dev Mark N°5 => Chin Spiral
    function item_5() public pure returns (string memory) {
        return
            base(
                '<path display="inline" d="M203.4,279.3c0.2-0.6,0.4-1.4,1-1.9c0.3-0.2,0.7-0.4,1.1-0.3c0.4,0.1,0.7,0.4,0.9,0.7c0.4,0.6,0.5,1.5,0.5,2.2s-0.3,1.6-0.8,2.1c-0.5,0.6-1.4,0.9-2.2,0.8s-1.6-0.5-2.1-0.9c-0.6-0.4-1.1-1-1.6-1.7c-0.4-0.6-0.6-1.5-0.6-2.3c0.2-1.7,1.5-2.9,2.8-3.5c1.4-0.6,2.9-0.8,4.4-0.5c0.7,0.1,1.5,0.4,2.1,0.9s0.9,1.3,1,2c0.2,1.5-0.2,3-1.3,4.1c0.7-1.1,1-2.6,0.7-4c-0.2-0.6-0.5-1.3-1-1.6c-0.5-0.4-1.1-0.6-1.8-0.6c-1.4-0.1-2.7,0-3.9,0.6c-1.1,0.5-2.1,1.6-2.2,2.7c-0.1,1.1,0.7,2.3,1.7,3.1c0.5,0.4,1,0.8,1.6,0.8c0.5,0.1,1.1-0.1,1.6-0.5c0.4-0.4,0.7-0.9,0.7-1.7c0.1-0.6,0-1.4-0.3-1.9c-0.1-0.3-0.4-0.5-0.6-0.6c-0.3-0.1-0.6,0-0.8,0.1C204,278,203.5,278.7,203.4,279.3z"  />',
                "Chin Spiral"
            );
    }

    /// @dev Mark N°6 => Akuma Moon
    function item_6() public pure returns (string memory) {
        return base(akuma("000000"), "Akuma Moon");
    }

    /// @dev Mark N°7 => Full Moon
    function item_7() public pure returns (string memory) {
        return
            base(
                '<ellipse display="inline" fill="#B50D5E" cx="200.9" cy="146.5" rx="13.4" ry="13.4"  />',
                "Blood Full Moon"
            );
    }

    /// @dev Mark N°8 => Moon Blood
    function item_8() public pure returns (string memory) {
        return
            base(
                '<path display="inline" fill="#B50D5E" d="M218.2,146.2c0.2-6-2.7-11.5-7.2-14.7c2.3,2.5,3.8,5.7,3.6,9.4c-0.2,7.4-6.5,13.2-14.2,13s-13.7-6.4-13.5-13.8c0.1-3.5,1.7-6.9,4.1-9.2c-4.7,3.1-7.8,8.3-8,14.3c-0.2,9.7,7.5,17.8,17.2,18C209.7,163.6,217.9,156,218.2,146.2z"  />',
                "Blood Moon"
            );
    }

    /// @dev Mark N°9 => Tomoe Blood
    function item_9() public pure returns (string memory) {
        return base(tomoe("B50D5E"), "Tomoe Blood");
    }

    /// @dev Mark N°10 => Scar
    function item_10() public pure returns (string memory) {
        return
            base(
                '<path fill="#FF7478" d="M239.9,133.5c0,0-7.5,51,0.2,101.2C240.1,234.7,248.8,188.3,239.9,133.5z"  />',
                "Scar"
            );
    }

    /// @dev Mark N°11 => Tomoe Moon
    function item_11() public pure returns (string memory) {
        return base(tomoe("000000"), "Tomoe Moon");
    }

    /// @dev Mark N°12 => Cheeks Blood
    function item_12() public pure returns (string memory) {
        return
            base(
                '<g display="inline" ><path fill="#E31466" d="M175.8,215.3c-8.6,0.4-17,0.3-25-0.3c-0.4,0-0.8-0.4-0.8-0.8v-3c0-0.4,0.4-0.8,0.8-0.8c7.7,0.7,16.2,0.8,25,0.3c0.4,0,0.8,0.4,0.8,0.8v3C176.5,214.9,176.2,215.3,175.8,215.3z" /><path fill="#E31466" d="M175.5,223.6c-8.6,0.4-17,0.3-25-0.3c-0.4,0-0.8-0.4-0.8-0.8v-3c0-0.4,0.4-0.8,0.8-0.8c7.7,0.7,16.2,0.8,25,0.3c0.4,0,0.8,0.4,0.8,0.8v3C176.3,223.3,176,223.6,175.5,223.6z" /></g><g display="inline" ><path fill="#E31466" d="M255.8,215.5c-8.6,0.6-17,0.7-25,0.2c-0.4,0-0.8-0.3-0.8-0.8v-3c0-0.4,0.3-0.8,0.8-0.8c7.7,0.5,16.2,0.4,25-0.2c0.4,0,0.8,0.3,0.8,0.8v3C256.7,215.1,256.4,215.5,255.8,215.5z" /><path fill="#E31466" d="M255.8,223.9c-8.6,0.6-17,0.7-25,0.2c-0.4,0-0.8-0.3-0.8-0.8v-3c0-0.4,0.3-0.8,0.8-0.8c7.7,0.5,16.2,0.4,25-0.2c0.4,0,0.8,0.3,0.8,0.8v3C256.5,223.5,256.2,223.9,255.8,223.9z" /></g>',
                "Cheeks Blood"
            );
    }

    /// @dev Mark N°13 => Kitsune
    function item_13() public pure returns (string memory) {
        return
            base(
                '<g display="inline" ><g><path  fill="#B50D5E" d="M264,242c0,0-11.8-5.9-30.5-6.8" /><path fill="#B50D5E" d="M264,242c-1.3-0.4-2.5-0.9-3.8-1.3c-1.3-0.4-2.5-0.8-3.8-1.1c-2.5-0.7-5-1.4-7.6-1.9c-2.5-0.5-5.1-1-7.7-1.5c-2.6-0.4-5.2-0.7-7.8-1c1.4,0,2.6,0,4,0c1.4,0.1,2.6,0.1,4,0.3c2.6,0.2,5.2,0.7,7.8,1.1c2.6,0.5,5.1,1.3,7.6,2.1C259.4,239.7,261.9,240.6,264,242z" /></g><g><path  fill="#B50D5E" d="M267.1,232.8c0,0-11.8-5.9-30.5-6.8" /><path fill="#B50D5E" d="M267.1,232.8c-1.3-0.4-2.5-0.9-3.8-1.3c-1.3-0.4-2.5-0.8-3.8-1.1c-2.5-0.7-5-1.4-7.6-1.9c-2.5-0.5-5.1-1-7.7-1.5s-5.2-0.7-7.8-1c1.4,0,2.6,0,4,0c1.4,0.1,2.6,0.1,4,0.3c2.6,0.2,5.2,0.7,7.8,1.1c2.6,0.5,5.1,1.3,7.6,2.1C262.4,230.5,264.9,231.5,267.1,232.8z" /></g><g><path  fill="#B50D5E" d="M268.1,223.4c0,0-11.8-5.9-30.5-6.8" /><path fill="#B50D5E" d="M268.1,223.4c-1.3-0.4-2.5-0.9-3.8-1.3c-1.3-0.4-2.5-0.8-3.8-1.1c-2.5-0.7-5-1.4-7.6-1.9c-2.5-0.5-5.1-1-7.7-1.5c-2.6-0.4-5.2-0.7-7.8-1c1.4,0,2.6,0,4,0c1.4,0.1,2.6,0.1,4,0.3c2.6,0.2,5.2,0.7,7.8,1.1c2.6,0.5,5.1,1.3,7.6,2.1C263.4,221.1,265.9,222.1,268.1,223.4z" /></g></g><g display="inline" ><g><path  fill="#B50D5E" d="M142.9,223c0,0,11-5.7,28.8-6.5" /><path fill="#B50D5E" d="M142.9,223c2.1-1.3,4.5-2.2,6.8-3s4.8-1.5,7.2-2.1c2.4-0.5,4.9-0.9,7.4-1.1c1.3-0.1,2.5-0.2,3.8-0.2s2.5,0,3.8,0c-2.5,0.3-4.9,0.6-7.3,1s-4.8,0.8-7.3,1.4c-2.4,0.5-4.8,1.1-7.2,1.8c-1.1,0.3-2.4,0.7-3.5,1C145.2,222.2,144.1,222.6,142.9,223z" /></g><g><path  fill="#B50D5E" d="M148.1,241.8c0,0,11-5.7,28.8-6.5" /><path fill="#B50D5E" d="M148.1,241.8c2.1-1.3,4.5-2.2,6.8-3s4.8-1.5,7.2-2.1c2.4-0.5,4.9-0.9,7.4-1.1c1.3-0.1,2.5-0.2,3.8-0.2s2.5,0,3.8,0c-2.5,0.3-4.9,0.6-7.3,1s-4.8,0.8-7.3,1.4c-2.4,0.5-4.8,1.1-7.2,1.8c-1.1,0.3-2.4,0.7-3.5,1C150.4,240.9,149.3,241.4,148.1,241.8z" /></g><g><path  fill="#B50D5E" d="M145.1,232.6c0,0,11-5.7,28.8-6.5" /><path fill="#B50D5E" d="M145.1,232.6c2.1-1.3,4.5-2.2,6.8-3s4.8-1.5,7.2-2.1c2.4-0.5,4.9-0.9,7.4-1.1c1.3-0.1,2.5-0.2,3.8-0.2s2.5,0,3.8,0c-2.5,0.3-4.9,0.6-7.3,1c-2.4,0.4-4.8,0.8-7.3,1.4c-2.4,0.5-4.8,1.1-7.2,1.8c-1.1,0.3-2.4,0.7-3.5,1C147.4,231.8,146.3,232.2,145.1,232.6z" /></g></g>',
                "Kitsune"
            );
    }

    /// @dev Mark N°14 => Cheeks Pure
    function item_14() public pure returns (string memory) {
        return
            base(
                '<g display="inline" ><path fill="#FFEDED" d="M173.8,217.3c-8.6,0.4-17,0.3-25-0.3c-0.4,0-0.8-0.4-0.8-0.8v-3c0-0.4,0.4-0.8,0.8-0.8c7.7,0.7,16.2,0.8,25,0.3c0.4,0,0.8,0.4,0.8,0.8v3C174.5,216.9,174.2,217.3,173.8,217.3z" /><path fill="#FFEDED" d="M173.5,225.6c-8.6,0.4-17,0.3-25-0.3c-0.4,0-0.8-0.4-0.8-0.8v-3c0-0.4,0.4-0.8,0.8-0.8c7.7,0.7,16.2,0.8,25,0.3c0.4,0,0.8,0.4,0.8,0.8v3C174.3,225.3,174,225.6,173.5,225.6z" /></g><g display="inline" ><path fill="#FFEDED" d="M253.8,217.5c-8.6,0.6-17,0.7-25,0.2c-0.4,0-0.8-0.3-0.8-0.8v-3c0-0.4,0.3-0.8,0.8-0.8c7.7,0.5,16.2,0.4,25-0.2c0.4,0,0.8,0.3,0.8,0.8v3C254.7,217.1,254.4,217.5,253.8,217.5z" /><path fill="#FFEDED" d="M253.8,225.9c-8.6,0.6-17,0.7-25,0.2c-0.4,0-0.8-0.3-0.8-0.8v-3c0-0.4,0.3-0.8,0.8-0.8c7.7,0.5,16.2,0.4,25-0.2c0.4,0,0.8,0.3,0.8,0.8v3C254.5,225.5,254.2,225.9,253.8,225.9z" /></g>',
                "Cheeks Pure"
            );
    }

    /// @dev Mark N°15 => YinYang
    function item_15() public pure returns (string memory) {
        return
            base(
                '<path d="M218.1,361.41a15.58,15.58,0,0,0-15.5-15.5h-1.3a15.48,15.48,0,0,0,1.4,30.9A15.22,15.22,0,0,0,218.1,361.41Zm-13.7-7.1a2,2,0,1,1-2-2A1.94,1.94,0,0,1,204.4,354.31Zm4.7,14.5a7,7,0,0,1-7.2,6.9h0a14.4,14.4,0,0,1-13.8-14.3,14.18,14.18,0,0,1,9.7-13.5,7.83,7.83,0,0,0-3.5,6.5,7.6,7.6,0,0,0,7.6,7.6h0A7,7,0,0,1,209.1,368.81Zm-6.6,2.2a2,2,0,1,1,2-2A2.07,2.07,0,0,1,202.5,371Z" transform="translate(0 0.5)" fill="#0a0a02" opacity="0.93" style="isolation: isolate"/> <circle cx="143.6" cy="355.84" r="6.81" fill="#0a0a02"/> <circle cx="263.68" cy="359.93" r="6.81" fill="none" stroke="#000"/>',
                "YinYang"
            );
    }

    /// @dev Mark N°16 => Double Scar
    function item_16() public pure returns (string memory) {
        return
            base(
                '<path id="Scar" display="inline" fill="#FF7478" d="M239.9,133.5c0,0-7.5,51,0.2,101.2C240.1,234.7,248.8,188.3,239.9,133.5z"  /><path id="Scar" display="inline" fill="#FF7478" d="M163.7,135.1c0,0-6.9,51.1,1.6,101.2C165.2,236.2,173.1,189.8,163.7,135.1z"  />',
                "Double Scar"
            );
    }

    /// @dev Mark N°17 => Moon Pure
    function item_17() public pure returns (string memory) {
        return
            base(
                '<path display="inline" fill="#FFEDED" d="M218.2,146.2c0.2-6-2.7-11.5-7.2-14.7c2.3,2.5,3.8,5.7,3.6,9.4c-0.2,7.4-6.5,13.2-14.2,13s-13.7-6.4-13.5-13.8c0.1-3.5,1.7-6.9,4.1-9.2c-4.7,3.1-7.8,8.3-8,14.3c-0.2,9.7,7.5,17.8,17.2,18C209.7,163.6,217.9,156,218.2,146.2z"  />',
                "Pure Moon"
            );
    }

    /// @dev Mark N°18 => Akuma Pure
    function item_18() public pure returns (string memory) {
        return base(akuma("FFEDED"), "Akuma Pure");
    }

    /// @dev Mark N°19 => Tomoe Pure
    function item_19() public pure returns (string memory) {
        return base(tomoe("FFEDED"), "Tomoe Pure");
    }

    /// @dev Mark N°20 => Eye
    function item_20() public pure returns (string memory) {
        return
            base(
                '<path d="M203.3,344.4c0,0-16.4,12.2-7.2,35C196.3,379.3,212.5,366.2,203.3,344.4z"/> <g> <path d="M208.4,351.4c0.4,2.1,0.6,4.2,0.5,6.3c-0.1,2.1-0.3,4.2-0.7,6.3s-1.1,4.2-2.1,6.1c-0.8,1.9-2.2,3.7-3.5,5.3 c0.3-0.4,0.5-0.9,0.8-1.4l0.4-0.6l0.3-0.7l0.7-1.4l0.7-1.4c0.8-1.9,1.4-3.9,1.9-6c0.5-2,0.7-4.1,0.9-6.2c0.1-1,0.1-2.1,0.1-3.1 C208.4,353.5,208.4,352.4,208.4,351.4z"/> </g> <g> <path d="M191.5,362.4c-0.1,1.3-0.1,2.5-0.1,3.8c0,1.3,0,2.5,0.1,3.8c0,1.3,0.2,2.5,0.5,3.8c0.2,1.2,0.5,2.4,1,3.7 c-0.6-1-1.1-2.3-1.4-3.5c-0.3-1.2-0.4-2.5-0.6-3.8c0-1.3,0-2.5,0-3.8C191.1,364.8,191.2,363.6,191.5,362.4z"/> </g> <ellipse transform="matrix(3.212132e-02 -0.9995 0.9995 3.212132e-02 -158.675 548.08)"  fill="#FFFFFF" cx="203.7" cy="356" rx="2.9" ry="0.7"/>',
                "Eye"
            );
    }

    /// @dev Mark N°21 => TORI
    function item_21() public pure returns (string memory) {
        return
            base(
                '<line display="inline" fill="none" stroke="#000000" stroke-width="0.5" stroke-linecap="round" stroke-linejoin="round" stroke-miterlimit="10" x1="234.4" y1="209.2" x2="234.4" y2="216.3"  /><path display="inline" fill="none" stroke="#000000" stroke-width="0.5" stroke-linecap="round" stroke-linejoin="round" stroke-miterlimit="10" d="M231.8,208.8c0,0,3.3,0.4,5.7,0.2"  /><path display="inline" fill="none" stroke="#000000" stroke-width="0.5" stroke-linecap="round" stroke-linejoin="round" stroke-miterlimit="10" d="M240.9,209.2c0,0-3.6,3.2,0,6.6S245.9,209.2,240.9,209.2z"  /><path display="inline" fill="none" stroke="#000000" stroke-width="0.5" stroke-linecap="round" stroke-linejoin="round" stroke-miterlimit="10" d="M246.9,215.7l-1.3-6.7c0,0,9.1-2.1,1,2.9l3.3,3.1"  /><line display="inline" fill="none" stroke="#000000" stroke-width="0.5" stroke-linecap="round" stroke-linejoin="round" stroke-miterlimit="10" x1="252.4" y1="208.6" x2="252.4" y2="215.4"  />',
                "TORI"
            );
    }

    /// @dev Mark N°22 => Kin Moon
    function item_22() public pure returns (string memory) {
        return
            base(
                '<linearGradient id="Kin Moon Gradient" gradientUnits="userSpaceOnUse" x1="182.9962" y1="-417.0576" x2="218.2097" y2="-417.0576" gradientTransform="matrix(1 0 0 -1 0 -270)" ><stop offset="0" style="stop-color:#FFB451" /><stop offset="0.5259" style="stop-color:#F7EC94" /><stop offset="1" style="stop-color:#FF9121" /></linearGradient><path fill="url(#Kin_Moon_Gradient)" d="M218.2,146.2c0.2-6-2.7-11.5-7.2-14.7c2.3,2.5,3.8,5.7,3.6,9.4c-0.2,7.4-6.5,13.2-14.2,13s-13.7-6.4-13.5-13.8c0.1-3.5,1.7-6.9,4.1-9.2c-4.7,3.1-7.8,8.3-8,14.3c-0.2,9.7,7.5,17.8,17.2,18C209.7,163.6,217.9,156,218.2,146.2z"  />',
                "Kin Moon"
            );
    }

    function tomoe(string memory color) private pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<path d="M289,339.8h0a5,5,0,1,0,0,7.3l.4-.4v.1c2.7,1.9,3.6,5.8,3.6,5.8C293.9,343.3,289,339.8,289,339.8Zm-2.2,5a1.7,1.7,0,1,1,.1-2.4A1.72,1.72,0,0,1,286.8,344.8Z" fill="#',
                    color,
                    '" /> <path d="M275.1,347.9h0a5,5,0,1,0-2.5,6.6c.1-.1.2-.1.4-.2,1.8,2.7,1.5,6.6,1.5,6.6C277.8,353.8,275.8,349.2,275.1,347.9Zm-3.9,3.5a1.62,1.62,0,0,1-2.2-.8,1.66,1.66,0,1,1,2.2.8Z" fill="#',
                    color,
                    '" /> <path d="M136.6,339.1a5.08,5.08,0,0,0-6.9,0h0s-4.9,3.5-4,12.8c0,0,.9-3.9,3.6-5.8V346c.1.1.2.3.4.4a5,5,0,1,0,6.9-7.3Zm-2.2,4.9a2,2,0,0,1-2.4.1,1.7,1.7,0,1,1,2.4-.1Z" fill="#',
                    color,
                    '" /> <path d="M150.5,344.6a5.14,5.14,0,0,0-6.7,2.5c0,.1-.1.1-.1.2-.7,1.4-2.5,6,.7,12.9,0,0-.3-3.9,1.5-6.6.1.1.2.1.4.2a5.06,5.06,0,0,0,4.2-9.2Zm-.7,5.3a1.66,1.66,0,1,1-.8-2.2A1.65,1.65,0,0,1,149.8,349.9Z" fill="#',
                    color,
                    '" />',
                    abi.encodePacked(
                        '<path d="M224.09,355.4a5.13,5.13,0,0,0-6.4-2.9,5.06,5.06,0,1,0,3.5,9.5c.1-.1.3-.1.4-.2,1.6,2.9,1,6.8,1,6.8C226.89,360.9,224.49,356,224.09,355.4Zm-4,3.5a2,2,0,0,1-2.2-1,1.71,1.71,0,1,1,2.2,1Z" fill="#',
                        color,
                        '" /> <path d="M189.79,352a4.94,4.94,0,0,0-6.5,2.5h0s-3.3,5,.8,13.4c0,0-.4-4,1.4-6.8h0a.76.76,0,0,0,.4.2,5,5,0,0,0,3.9-9.3Zm-.6,5.3c-.2,1-1.2,1.3-2.2.9a1.68,1.68,0,1,1,2.2-.9Z" fill="#',
                        color,
                        '" />'
                    )
                )
            );
    }

    function akuma(string memory color) private pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<g id="Eye_Mark" > <path d="M237.6,223c0-3.6,2.6-85.2,2.8-88.9s-1.8-24.7-1.6-28.3c5.6-6.5,12-33.11,15.92-33.27-4.46,2.4-8.32,29.47-11.52,33.27l-.2,31.1c.13,4.65-2.48,81.07-2.2,86.2a17.68,17.68,0,0,0-1.6,2.2A23.4,23.4,0,0,0,237.6,223Z" transform="translate(0 0.5)" fill="#',
                    color,
                    '"/> </g> <g id="Eye_Mark-2"> <path d="M163.2,221.8c-.1-3.6.1-88.4.2-92s1.8-21.8,2-25.4c5.5-6.6,13.87-34.73,18.37-34.63-5.3,2-11.77,33-14.87,37l-2.8,25.6c.2,3.6,0,85.7.3,89.3l-1.7,3.1Z" transform="translate(0 0.5)" fill="#',
                    color,
                    '"/> </g>'
                )
            );
    }

    /// @notice Return the skin name of the given id
    /// @param id The skin Id
    function getItemNameById(uint8 id) public pure returns (string memory name) {
        name = "";
        if (id == 1) {
            name = "None";
        } else if (id == 2) {
            name = "Dark Circle";
        } else if (id == 3) {
            name = "Akuma Blood";
        } else if (id == 4) {
            name = "Brother";
        } else if (id == 5) {
            name = "Chin Spiral";
        } else if (id == 6) {
            name = "Akuma Moon";
        } else if (id == 7) {
            name = "Full Moon";
        } else if (id == 8) {
            name = "Moon Blood";
        } else if (id == 9) {
            name = "Tomoe Blood";
        } else if (id == 10) {
            name = "Scar";
        } else if (id == 11) {
            name = "Tomoe Moon";
        } else if (id == 12) {
            name = "Cheeks Blood";
        } else if (id == 13) {
            name = "Kitsune";
        } else if (id == 14) {
            name = "Cheeks Pure";
        } else if (id == 15) {
            name = "YinYang";
        } else if (id == 16) {
            name = "Double Scar";
        } else if (id == 17) {
            name = "Moon Pure";
        } else if (id == 18) {
            name = "Akuma Pure";
        } else if (id == 19) {
            name = "Tomoe Pure";
        } else if (id == 20) {
            name = "Eye";
        } else if (id == 21) {
            name = "TORI";
        } else if (id == 22) {
            name = "Kin Moon";
        }
    }

    /// @dev The base SVG for the body
    function base(string memory children, string memory name) private pure returns (string memory) {
        return string(abi.encodePacked('<g id="mark"><g id="', name, '">', children, "</g></g>"));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

pragma abicoder v2;

import "base64-sol/base64.sol";
import "./constants/Colors.sol";

/// @title Accessory SVG generator
library AccessoryDetail {
    /// @dev Accessory N°1 => None
    function item_1() public pure returns (string memory) {
        return base("", "None");
    }

    /// @dev Accessory N°2 => Horn Blood
    function item_2() public pure returns (string memory) {
        return base(horn("E31466"), "Horn Blood");
    }

    /// @dev Accessory N°3 => Small Horn Blood
    function item_3() public pure returns (string memory) {
        return base(small_horn("E31466"), "Small Horn Blood");
    }

    /// @dev Accessory N°4 => Monk Blood
    function item_4() public pure returns (string memory) {
        return base(monk("B50D5E"), "Monk Blood");
    }

    /// @dev Accessory N°5 => Horn Moon
    function item_5() public pure returns (string memory) {
        return base(horn("2A2C38"), "Horn Moon");
    }

    /// @dev Accessory N°6 => Small Horn Moon
    function item_6() public pure returns (string memory) {
        return base(small_horn("2A2C38"), "Small Horn Moon");
    }

    /// @dev Accessory N°7 => Monk Moon
    function item_7() public pure returns (string memory) {
        return base(monk("242630"), "Moon Monk");
    }

    /// @dev Accessory N°8 => Power Stick
    function item_8() public pure returns (string memory) {
        return
            base(
                '<g display="inline" ><path stroke="#000000" stroke-miterlimit="10" d="M279.7,105.3l21.9-26.8c-0.1-0.8-2.8-7.3-10.8-8.8l-21.9,26.8C270.8,101.9,274.2,105.2,279.7,105.3z" /><g><path d="M279.6,109.5c-1.7,0.2-3.5,0.1-5.2-0.3s-3.3-1.3-4.8-2.3c-1.4-1-2.6-2.4-3.5-4c-0.5-0.7-0.8-1.6-1.1-2.4c-0.3-0.8-0.5-1.7-0.7-2.5c0.4,0.7,0.7,1.6,1.1,2.3c0.4,0.7,0.8,1.5,1.4,2.1c0.9,1.4,2.2,2.5,3.4,3.5c1.4,1,2.8,1.8,4.4,2.4C276.1,109,277.8,109.3,279.6,109.5z" /></g></g><g id="Power_Head" display="inline" ><path stroke="#000000" stroke-miterlimit="10" d="M147.2,105.1l-21.9-26.8c0.1-0.8,2.8-7.3,10.8-8.8l21.8,26.8C156,101.9,152.7,105,147.2,105.1z" /><g><path d="M147.2,109.4c1.7-0.1,3.3-0.5,4.9-1.1c1.6-0.5,3-1.4,4.4-2.4s2.5-2.2,3.4-3.5c0.5-0.6,0.9-1.5,1.4-2.1c0.4-0.7,0.7-1.6,1.1-2.3c-0.2,0.8-0.4,1.7-0.7,2.5s-0.6,1.7-1.1,2.4c-0.8,1.6-2.1,2.8-3.5,4c-1.5,1-3,1.9-4.8,2.3C150.8,109.6,149,109.7,147.2,109.4z" /></g></g>',
                "Power Stick"
            );
    }

    /// @dev Accessory N°9 => Kitsune
    function item_9() public pure returns (string memory) {
        return
            base(
                '<g display="inline" ><path fill="#FFDAEA" stroke="#000000" stroke-miterlimit="10" d="M247.2,90.4c9-7.5,17.4-14.8,41.9-26.4c0,0,1.8,35.4-6.7,48.6" /><path fill="#141113" d="M254.7,94.6c7.2-6.9,18.6-15.9,27.9-18.6c0.3,1.4,1.7,14.3-6,32.6C276.7,108.6,263.3,101.6,254.7,94.6z" /></g><g display="inline" ><path fill="#FFDAEA" stroke="#000000" stroke-miterlimit="10" d="M174.7,89.1c-8.7-7.4-16.9-14.6-40.7-25.9c0,0-2,24.6,6.5,47.8" /><path fill="#141113" d="M167.7,93.3c-6.8-6.8-17.6-15.8-26.3-18.4c-0.3,1.3-1.6,14.1,5.6,32.3C147,107.2,159.7,100.3,167.7,93.3z" /></g><polyline display="inline"  fill="#FFDAEA" stroke="#000000" stroke-width="0.5" stroke-linecap="round" stroke-miterlimit="10" points="138.6,66.4 137.7,59.4 136.2,64.3 132,59.3 134.2,65.6 126.8,62.7 134.7,68.7 "  /><polyline display="inline"  fill="#FFDAEA" stroke="#000000" stroke-width="0.5" stroke-linecap="round" stroke-miterlimit="10" points="284.4,66.9 285.4,59.9 286.8,64.8 291,59.8 288.8,66.1 296.3,63.2 288.4,69.2 "  />',
                "Kitsune"
            );
    }

    /// @dev Accessory N°10 => Horn Pure
    function item_10() public pure returns (string memory) {
        return base(horn("FFDAEA"), "Horn Pure");
    }

    /// @dev Accessory N°11 => Small Horn Pure
    function item_11() public pure returns (string memory) {
        return base(small_horn("FFDAEA"), "Small Horn Pure");
    }

    /// @dev Accessory N°12 => Heart
    function item_12() public pure returns (string memory) {
        return
            base(
                '<path id="Heart" d="M185,360.8c1.1-10.4,9.9-19.1,21.7-18c9.6,0.8,16.1,10.8,15,21.2c-1.1,10.4-11.2,18.3-20.9,17.3S183.8,371.2,185,360.8z"/>',
                "Heart"
            );
    }

    /// @dev Accessory N°13 => Monk Pure
    function item_13() public pure returns (string memory) {
        return base(monk("FFEDED"), "Monk Pure");
    }

    /// @dev Accessory N°14 => Power Head
    function item_14() public pure returns (string memory) {
        return
            base(
                '<g display="inline" ><path stroke="#000000" stroke-miterlimit="10" d="M280.3,87.8l6.6-15.5c-0.2-0.3-2.6-3.1-7-2.9l-6.5,15.5C275.4,87.3,277.6,88.4,280.3,87.8z" /><g><path d="M280.9,89.9c-0.8,0.5-1.8,0.7-2.7,0.8c-0.9,0.1-2-0.1-2.9-0.4c-0.9-0.4-1.8-0.8-2.5-1.6c-0.7-0.6-1.3-1.6-1.6-2.4c0.7,0.6,1.4,1.3,2.1,1.8s1.5,0.9,2.3,1.3C277.3,89.9,279.1,90,280.9,89.9z" /></g></g><g display="inline" ><path stroke="#000000" stroke-miterlimit="10" d="M288.8,109.2l11.5-16.4c-0.1-0.4-1.9-4.1-6.5-4.5l-11.4,16.4C283.7,107.9,285.7,109.4,288.8,109.2z" /><g><path d="M288.9,111.7c-0.9,0.4-2,0.5-3,0.4s-2.1-0.4-2.9-1s-1.7-1.4-2.2-2.3c-0.3-0.4-0.4-0.9-0.6-1.4c-0.1-0.5-0.2-1-0.3-1.5c0.3,0.4,0.5,0.8,0.8,1.3c0.3,0.4,0.5,0.8,0.8,1.1c0.6,0.7,1.3,1.4,2.1,1.9C284.8,111.3,286.9,111.6,288.9,111.7z" /></g></g><g display="inline" ><path stroke="#000000" stroke-miterlimit="10" d="M151.4,101.6L143,83.5c-0.4-0.2-4.1-0.6-6.5,3l8.3,18.1C148.1,105,150.3,104.2,151.4,101.6z" /><g><path d="M153.4,102.9c-0.1,0.9-0.4,1.9-0.9,2.6c-0.5,0.8-1.3,1.5-2.2,2c-0.8,0.4-1.9,0.7-2.8,0.6c-0.5,0-0.9-0.1-1.5-0.2c-0.4-0.1-0.9-0.3-1.4-0.5c0.5,0,0.9,0,1.4,0s0.9,0,1.4-0.1c0.8-0.1,1.7-0.4,2.4-0.7C151.4,105.8,152.6,104.4,153.4,102.9z" /></g></g><g display="inline" ><path stroke="#000000" stroke-miterlimit="10" d="M258.9,80.7l8-20.6c-0.2-0.4-2.5-3.6-7-2.6L252,78.1C253.8,80.8,256.1,81.8,258.9,80.7z" /><g><path d="M259.7,83.2c-1.6,1.1-3.8,1.7-5.7,1c-0.9-0.3-1.9-0.8-2.5-1.7c-0.4-0.3-0.6-0.8-0.8-1.3c-0.2-0.4-0.4-0.9-0.6-1.4c0.3,0.4,0.6,0.7,0.9,1.1c0.3,0.3,0.6,0.7,1,0.9c0.6,0.6,1.5,1,2.3,1.4c0.8,0.3,1.8,0.3,2.7,0.3C257.9,83.7,258.8,83.5,259.7,83.2z" /></g></g><g display="inline" ><path stroke="#000000" stroke-miterlimit="10" d="M224.8,71.6l0.1-16c-0.3-0.2-3.4-1.9-7.1,0l-0.1,16C220.3,73.1,222.7,73.2,224.8,71.6z" /><g><path d="M226.3,73.3c-0.5,0.7-1.3,1.4-2.1,1.8s-1.8,0.6-2.7,0.7c-0.9,0-1.9-0.1-2.7-0.5c-0.8-0.3-1.6-0.9-2.2-1.6c0.8,0.3,1.7,0.6,2.5,0.7c0.8,0.2,1.7,0.3,2.4,0.2C222.9,74.6,224.6,74.1,226.3,73.3z" /></g></g><g display="inline" ><path stroke="#000000" stroke-miterlimit="10" d="M263.2,106l3.5-12.9c-0.2-0.3-2.2-2.2-5.4-1.5l-3.4,12.9C259.6,106.2,261.3,106.8,263.2,106z" /><g><path d="M264,107.5c-0.5,0.5-1.1,0.8-1.9,1c-0.7,0.2-1.5,0.2-2.3,0c-0.7-0.2-1.5-0.5-2-1c-0.6-0.4-1-1-1.4-1.8c0.6,0.4,1.1,0.7,1.8,1c0.5,0.3,1.1,0.5,1.8,0.6C261.3,108,262.4,107.9,264,107.5z" /></g></g><g display="inline" ><path stroke="#000000" stroke-miterlimit="10" d="M241.3,105.3l2.1-12.4c-0.2-0.2-3-1.9-6.8-1l-2,12.4C236.8,105.6,239.1,106.1,241.3,105.3z" /><g><path d="M242.5,107.1c-0.7,0.4-1.5,0.7-2.3,0.9c-0.8,0.2-1.7,0.2-2.5,0.1s-1.7-0.3-2.4-0.7c-0.4-0.2-0.7-0.4-1-0.6s-0.6-0.5-0.9-0.8c0.7,0.4,1.5,0.8,2.2,1c0.7,0.3,1.6,0.5,2.3,0.6C239.2,107.9,240.9,107.7,242.5,107.1z" /></g></g><g display="inline" ><path stroke="#000000" stroke-miterlimit="10" d="M225.2,96.1l1.3-13.5c-0.2-0.2-2.8-1.8-6.1-0.5l-1.3,13.5C221.2,96.9,223.3,97.2,225.2,96.1z" /><g><path d="M226.3,98.1c-1.1,1-2.7,1.6-4.4,1.5c-0.8-0.1-1.6-0.2-2.3-0.6c-0.3-0.1-0.7-0.4-1-0.6s-0.6-0.5-0.8-0.7c0.7,0.3,1.4,0.7,2.1,0.9c0.7,0.3,1.5,0.4,2.2,0.4c0.7,0.1,1.5,0,2.2-0.2C224.8,98.7,225.6,98.4,226.3,98.1z" /></g></g><g display="inline" ><path stroke="#000000" stroke-miterlimit="10" d="M204.5,100.5l-0.6-17.2c-0.3-0.2-3.5-1.8-7.1,0.3l0.7,17.2C200,102.2,202.4,102.2,204.5,100.5z" /><g><path d="M206.1,103.4c-0.5,0.8-1.1,1.5-2,1.9c-0.8,0.5-1.8,0.8-2.7,0.8c-0.9,0.1-1.9,0-2.8-0.4c-0.4-0.1-0.8-0.4-1.3-0.6c-0.4-0.3-0.7-0.5-1-0.8c0.4,0.1,0.8,0.3,1.3,0.4c0.4,0.1,0.8,0.3,1.3,0.3c0.8,0.2,1.7,0.2,2.5,0.2C202.9,105,204.5,104.3,206.1,103.4z" /></g></g><g display="inline" ><path stroke="#000000" stroke-miterlimit="10" d="M185.2,95.3l-1.9-12.9c-0.3-0.2-3.1-1-5.9,0.9l2,12.9C181.6,97,183.6,96.8,185.2,95.3z" /><g><path d="M186.8,97.3c-0.3,0.7-0.9,1.3-1.6,1.8c-0.6,0.4-1.4,0.7-2.2,0.9c-0.8,0.1-1.6,0.1-2.4-0.1c-0.7-0.2-1.5-0.5-2.1-1c0.7,0.1,1.5,0.2,2.2,0.2s1.4,0,2.1-0.1C184.2,98.7,185.4,98.1,186.8,97.3z" /></g></g><g display="inline" ><path stroke="#000000" stroke-miterlimit="10" d="M171.7,107.8l-2.3-11.9c-0.3-0.1-3-0.7-5.7,1.1l2.4,11.9C168,109.5,170.1,109.2,171.7,107.8z" /><g><path d="M173.2,109.5c-0.3,0.7-0.8,1.3-1.5,1.8c-0.6,0.4-1.4,0.8-2.1,0.9c-0.7,0.2-1.6,0.2-2.3,0c-0.7-0.1-1.5-0.4-2.1-0.8c0.7,0,1.5,0.1,2.1,0.1c0.7,0,1.4-0.1,2-0.2C170.6,111,171.9,110.4,173.2,109.5z" /></g></g><g display="inline" ><path stroke="#000000" stroke-miterlimit="10" d="M241,70.8l4.3-17.9c-0.2-0.3-3-2.8-7.2-1.7l-4.2,17.9C236,71.3,238.4,72,241,70.8z" /><g><path d="M241.9,73c-0.7,0.6-1.6,1.1-2.5,1.4s-2,0.3-2.9,0.1c-0.9-0.2-1.9-0.6-2.7-1.3c-0.4-0.3-0.7-0.6-1-1s-0.5-0.7-0.8-1.1c0.4,0.2,0.7,0.5,1.1,0.8c0.4,0.2,0.7,0.5,1.1,0.7c0.7,0.4,1.6,0.7,2.4,0.8C238.4,73.8,240.1,73.5,241.9,73z" /></g></g><g display="inline" ><path stroke="#000000" stroke-miterlimit="10" d="M184.9,72.2l-4.1-17.5c-0.3-0.2-3.4-1.3-6.1,1.5l4.2,17.5C181.3,74.7,183.3,74.4,184.9,72.2z" /><g><path d="M186.5,73.8c-0.2,0.8-0.6,1.6-1.3,2.2c-0.6,0.6-1.4,1.1-2.2,1.4c-0.8,0.2-1.8,0.3-2.6,0c-0.4-0.1-0.8-0.3-1.3-0.4c-0.4-0.2-0.7-0.4-1-0.7c0.4,0.1,0.8,0.2,1.3,0.2c0.4,0,0.7,0.1,1.1,0.1c0.7,0.1,1.5,0,2.2-0.2C184.2,75.9,185.4,74.9,186.5,73.8z" /></g></g><g display="inline" ><path stroke="#000000" stroke-miterlimit="10" d="M167.3,82.7l-6.7-16.6c-0.4-0.1-4-0.5-6.7,2.7l6.7,16.6C163.6,86,165.9,85.2,167.3,82.7z" /><g><path d="M169.3,83.9c-0.2,0.9-0.6,1.8-1.3,2.5c-0.6,0.7-1.4,1.4-2.3,1.8c-0.9,0.4-1.9,0.6-2.8,0.5c-0.5,0-0.9-0.1-1.4-0.2c-0.4-0.1-0.8-0.3-1.3-0.5c0.5,0,0.9,0,1.4,0s0.8,0,1.3-0.1c0.8-0.1,1.7-0.3,2.4-0.7C166.9,86.6,168,85.4,169.3,83.9z" /></g></g><g display="inline" ><path stroke="#000000" stroke-miterlimit="10" d="M206.1,67.6l-0.8-19.4c-0.3-0.3-3.2-2.1-6.6,0.3l0.9,19.4C201.9,69.5,204,69.6,206.1,67.6z" /><g><path d="M207.3,69.6c-0.3,0.8-0.9,1.5-1.7,2c-0.7,0.5-1.6,0.9-2.5,1s-1.9,0-2.7-0.5c-0.4-0.1-0.7-0.5-1.1-0.7c-0.3-0.3-0.6-0.6-0.9-0.9c0.4,0.1,0.8,0.3,1.1,0.5c0.4,0.1,0.7,0.3,1.1,0.4c0.7,0.2,1.6,0.3,2.3,0.2C204.5,71.4,205.9,70.7,207.3,69.6z" /></g></g>',
                "Power Head"
            );
    }

    /// @dev Accessory N°15 => Horn Kin
    function item_15() public pure returns (string memory) {
        return
            base(
                '<g display="inline" ><linearGradient id="Gradientkinhorn" gradientUnits="userSpaceOnUse" x1="255.6" y1="-356" x2="304.8" y2="-356" gradientTransform="matrix(1 0 0 -1 0 -270)"><stop offset="0" stop-color="#FFB451" /><stop offset="0.5259" stop-color="#F7EC94" /><stop offset="1" stop-color="#FF9121" /></linearGradient><path  fill="url(#Gradientkinhorn)" stroke="#000000" stroke-miterlimit="10" d="M255.6,94.5c0,0,36.9-18,49.2-42.8c0,0-1.8,38.5-25.6,68.6C267.8,114.5,259.6,105.9,255.6,94.5z" /><linearGradient id="SVGID_00000038399919860379428020000001905538202183111590_" gradientUnits="userSpaceOnUse" x1="255.4985" y1="-377.2515" x2="279.7115" y2="-377.2515" gradientTransform="matrix(1 0 0 -1 0 -270)"><stop offset="0" style="stop-color:#FF9519" /><stop offset="1" style="stop-color:#FAF299" /></linearGradient><path fill="none" stroke="url(#SVGID_00000038399919860379428020000001905538202183111590_)" stroke-width="2" stroke-miterlimit="10" d="M256.5,94.8c-0.1,0.2,4.9,18.5,22.9,24.4" /></g><g display="inline" ><linearGradient id="SVGID_00000104701910233288470920000016524603851795941768_" gradientUnits="userSpaceOnUse" x1="113.3" y1="-355.45" x2="162.5" y2="-355.45" gradientTransform="matrix(1 0 0 -1 0 -270)"><stop offset="0" style="stop-color:#FFB451" /><stop offset="0.5259" style="stop-color:#F7EC94" /><stop offset="1" style="stop-color:#FF9121" /></linearGradient><path  fill="url(#SVGID_00000104701910233288470920000016524603851795941768_)" stroke="#000000" stroke-miterlimit="10" d="M162.5,94c0,0-36.9-18.1-49.2-43c0,0,1.8,38.6,25.6,68.9C150.3,114.1,158.5,105.4,162.5,94z" /><linearGradient id="SVGID_00000029029394541148799170000005544420656428366773_" gradientUnits="userSpaceOnUse" x1="138.6048" y1="-376.8041" x2="162.8014" y2="-376.8041" gradientTransform="matrix(1 0 0 -1 0 -270)"><stop offset="0" style="stop-color:#FAF299" /><stop offset="1" style="stop-color:#FF9121" /></linearGradient><path fill="none" stroke="url(#SVGID_00000029029394541148799170000005544420656428366773_)" stroke-width="2" stroke-miterlimit="10" d="M161.8,94.3c0.1,0.2-5.1,19-22.9,24.5" /></g>',
                "Horn Kin"
            );
    }

    /// @dev Accessory N°16 => Monk Kin
    function item_16() public pure returns (string memory) {
        return
            base(
                '<defs> <linearGradient id="linear-gradient" x1="257.85" y1="1709.77" x2="272.05" y2="1695.57" gradientTransform="translate(0 -1384)" gradientUnits="userSpaceOnUse"> <stop offset="0" stop-color="#ffb451"/> <stop offset="0.42" stop-color="#f7e394"/> <stop offset="1" stop-color="#ff9b43"/> </linearGradient> <linearGradient id="linear-gradient-2" x1="242.56" y1="1715.18" x2="256.76" y2="1700.98" xlink:href="#linear-gradient"/> <linearGradient id="linear-gradient-3" x1="161.86" y1="1707.28" x2="176.06" y2="1693.08" xlink:href="#linear-gradient"/> <linearGradient id="linear-gradient-4" x1="175.75" y1="1714.87" x2="189.95" y2="1700.67" xlink:href="#linear-gradient"/> <linearGradient id="linear-gradient-5" x1="191.56" y1="1719.18" x2="205.76" y2="1704.98" xlink:href="#linear-gradient"/> <linearGradient id="linear-gradient-6" x1="208.26" y1="1720.38" x2="222.46" y2="1706.18" xlink:href="#linear-gradient"/> <linearGradient id="linear-gradient-7" x1="225.16" y1="1718.48" x2="239.36" y2="1704.28" xlink:href="#linear-gradient"/> <linearGradient id="linear-gradient-9" x1="169.39" y1="1691.99" x2="174.74" y2="1686.64" xlink:href="#linear-gradient"/> <linearGradient id="linear-gradient-10" x1="264.55" y1="1693.85" x2="268.48" y2="1689.92" xlink:href="#linear-gradient"/> </defs> <g transform="translate(-0.4 0.5)" stroke="#000" stroke-miterlimit="10" stroke-width="2" > <path d="M264,308.6a10.1,10.1,0,1,1-9,11A10,10,0,0,1,264,308.6Z" fill="url(#linear-gradient)"/> <path d="M248.7,314a10.1,10.1,0,1,1-9,11A10.14,10.14,0,0,1,248.7,314Z" fill="url(#linear-gradient-2)"/> <path d="M168,306.1a10.1,10.1,0,1,1-9,11A10.14,10.14,0,0,1,168,306.1Z" fill="url(#linear-gradient-3)"/> <path d="M181.9,313.7a10.1,10.1,0,1,1-9,11A10,10,0,0,1,181.9,313.7Z" fill="url(#linear-gradient-4)"/> <path d="M197.7,318a10.1,10.1,0,1,1-9,11A10.14,10.14,0,0,1,197.7,318Z" fill="url(#linear-gradient-5)"/> <path d="M214.4,319.2a10.1,10.1,0,1,1-9,11A10.14,10.14,0,0,1,214.4,319.2Z" fill="url(#linear-gradient-6)"/> <path d="M231.3,317.3a10.1,10.1,0,1,1-9,11A10.14,10.14,0,0,1,231.3,317.3Z" fill="url(#linear-gradient-7)"/> <path d="M214.4,319.2a10.1,10.1,0,1,1-9,11A10.14,10.14,0,0,1,214.4,319.2Z" fill="url(#linear-gradient-6)"/> <path d="M167.5,306.1s3-4.2,7.1-3.6l-.5,4.7A10.06,10.06,0,0,0,167.5,306.1Z" fill="url(#linear-gradient-9)"/> <path d="M271.3,310.1s-.5-4.7-8.1-5.9l.3,4.6S268.8,308.5,271.3,310.1Z" fill="url(#linear-gradient-10)"/> </g> <g> <ellipse cx="165.9" cy="320.26" rx="3.1" ry="5.1" transform="matrix(0.52, -0.85, 0.85, 0.52, -194.29, 295.55)" opacity="0.54" style="isolation: isolate"/> <ellipse cx="181.14" cy="328.73" rx="2.9" ry="5.3" transform="translate(-187.37 402.52) rotate(-72.4)" opacity="0.54" style="isolation: isolate"/> <ellipse cx="197.91" cy="332.97" rx="3.1" ry="5.5" transform="translate(-150.25 504.05) rotate(-85.4)" opacity="0.54" style="isolation: isolate"/> <ellipse cx="215.27" cy="334.66" rx="2.6" ry="5.6" transform="translate(-123.74 544.14) rotate(-88.93)" opacity="0.54" style="isolation: isolate"/> <ellipse cx="233.31" cy="332.31" rx="5.3" ry="3.1" transform="translate(-51.03 42.57) rotate(-9.3)" opacity="0.54" style="isolation: isolate"/> <ellipse cx="251.59" cy="329.19" rx="5.3" ry="3.1" transform="translate(-83.61 85.61) rotate(-16.52)" opacity="0.54" style="isolation: isolate"/> <ellipse cx="268.21" cy="322.31" rx="5.6" ry="3.1" transform="translate(-128.36 185.43) rotate(-31.11)" opacity="0.54" style="isolation: isolate"/> </g>',
                "Monk Kin"
            );
    }

    function small_horn(string memory color) private pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    abi.encodePacked(
                        '<g display="inline" ><path  fill="#',
                        color,
                        '" stroke="#000000" stroke-miterlimit="10" d="M257.5,100.7c0,0,10.6-0.7,16.6-12.7c0,0,6.3,10.6-5.2,25.1C263.4,110.3,259.4,106.1,257.5,100.7z" /><path  fill="#',
                        color,
                        '" stroke="#',
                        color,
                        '" stroke-miterlimit="10" d="M258.2,101.1c0,0.1,1,9.2,10.6,11.4" /></g>'
                    ),
                    abi.encodePacked(
                        '<g display="inline" ><path  fill="#',
                        color,
                        '" stroke="#000000" stroke-miterlimit="10" d="M159.4,101.6c0,0-10.6-0.7-16.6-12.7c0,0-6.3,10.6,5.2,25.1C153.4,111.2,157.5,107,159.4,101.6z" /><path  fill="#',
                        color,
                        '" stroke="#',
                        color,
                        '" stroke-miterlimit="10" d="M158.9,102c0,0.1-1.5,9.4-10.7,11.3" /></g>'
                    )
                )
            );
    }

    function horn(string memory color) private pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<g><path d="M255.6,94.5s36.9-18,49.2-42.8c0,0-1.8,38.5-25.6,68.6C267.8,114.5,259.6,105.9,255.6,94.5Z" transform="translate(0 0.5)" fill="#',
                    color,
                    '" stroke="#000" stroke-miterlimit="10" /> <path d="M256.7,94.8c-.1.2,4.3,18.1,22.8,24.4" transform="translate(0 0.5)" fill="none" stroke="#',
                    color,
                    '" stroke-miterlimit="10" stroke-width="2"/> </g> <g> <path d="M160.5,94s-36.9-18.1-49.2-43c0,0,1.8,38.6,25.6,68.9C148.3,114.1,156.5,105.4,160.5,94Z" transform="translate(0 0.5)" fill="#',
                    color,
                    '" stroke="#000" stroke-miterlimit="10" /> <path d="M159.7,94.1c.1.2-5.1,19-22.9,24.5" transform="translate(0 0.5)" fill="none" stroke="#',
                    color,
                    '" stroke-miterlimit="10" stroke-width="2"/></g>'
                )
            );
    }

    function monk(string memory color) private pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    abi.encodePacked(
                        '<g display="inline" ><path fill="#',
                        color,
                        '" stroke="#000000" stroke-width="2" stroke-miterlimit="10" d="M271.3,310.1c0,0-0.5-4.7-8.1-5.9l0.3,4.6C263.5,308.8,268.8,308.5,271.3,310.1z" /><ellipse transform="matrix(0.9951 -9.859076e-02 9.859076e-02 0.9951 -30.1289 27.6785)" fill="#',
                        color,
                        '" stroke="#000000" stroke-width="1.9991" stroke-miterlimit="10.001" cx="265" cy="318.7" rx="10" ry="10.1" /><ellipse transform="matrix(0.9951 -9.868323e-02 9.868323e-02 0.9951 -30.7637 26.2227)" fill="#',
                        color,
                        '" stroke="#000000" stroke-width="1.9993" stroke-miterlimit="10.0012" cx="249.7" cy="324.1" rx="10" ry="10.1" /><ellipse transform="matrix(0.9952 -9.784912e-02 9.784912e-02 0.9952 -30.1289 18.0538)" fill="#',
                        color,
                        '" stroke="#000000" stroke-width="2" stroke-miterlimit="10.0039" cx="169" cy="316.2" rx="10" ry="10.1" />'
                    ),
                    abi.encodePacked(
                        '<ellipse transform="matrix(0.9952 -9.784608e-02 9.784608e-02 0.9952 -30.8049 19.4498)" fill="#',
                        color,
                        '" stroke="#000000" stroke-width="2" stroke-miterlimit="10.0039" cx="182.9" cy="323.8" rx="10" ry="10.1" /><ellipse transform="matrix(0.9952 -9.784740e-02 9.784740e-02 0.9952 -31.1502 21.0167)" fill="#',
                        color,
                        '" stroke="#000000" stroke-width="2" stroke-miterlimit="10.0039" cx="198.7" cy="328.1" rx="10" ry="10.1" />'
                    ),
                    abi.encodePacked(
                        '<ellipse transform="matrix(0.9952 -9.784740e-02 9.784740e-02 0.9952 -31.1875 22.6565)" fill="#',
                        color,
                        '" stroke="#000000" stroke-width="2" stroke-miterlimit="10.0039" cx="215.4" cy="329.3" rx="10" ry="10.1" /><ellipse transform="matrix(0.9952 -9.784871e-02 9.784871e-02 0.9952 -30.9209 24.3013)" fill="#',
                        color,
                        '" stroke="#000000" stroke-width="2" stroke-miterlimit="10.0039" cx="232.3" cy="327.4" rx="10" ry="10.1" /><ellipse transform="matrix(0.9952 -9.784740e-02 9.784740e-02 0.9952 -31.1875 22.6565)" fill="#',
                        color,
                        '" stroke="#000000" stroke-width="2" stroke-miterlimit="10.0039" cx="215.4" cy="329.3" rx="10" ry="10.1" /><path fill="#',
                        color,
                        '" stroke="#000000" stroke-width="2" stroke-miterlimit="10" d="M167.5,306.1c0,0,3-4.2,7.1-3.6l-0.5,4.7C174.2,307.2,171.4,305.5,167.5,306.1z" /></g><g display="inline" ><ellipse transform="matrix(0.5209 -0.8536 0.8536 0.5209 -193.8937 295.0872)" opacity="0.54"  enable-background="new    " cx="165.9" cy="320.3" rx="3.1" ry="5.1" /><ellipse transform="matrix(0.3023 -0.9532 0.9532 0.3023 -186.8647 402.0681)" opacity="0.54"  enable-background="new    " cx="181.2" cy="328.7" rx="2.9" ry="5.3" /><ellipse transform="matrix(8.016321e-02 -0.9968 0.9968 8.016321e-02 -149.6992 503.476)" opacity="0.54"  enable-background="new    " cx="197.9" cy="332.8" rx="3.1" ry="5.5" /><ellipse transform="matrix(1.864555e-02 -0.9998 0.9998 1.864555e-02 -123.3718 543.6663)" opacity="0.54"  enable-background="new    " cx="215.3" cy="334.7" rx="2.6" ry="5.6" /><ellipse transform="matrix(0.9869 -0.1616 0.1616 0.9869 -50.6334 42.0687)" opacity="0.54"  enable-background="new    " cx="233.3" cy="332.3" rx="5.3" ry="3.1" /><ellipse transform="matrix(0.9587 -0.2843 0.2843 0.9587 -83.2092 85.1148)" opacity="0.54"  enable-background="new    " cx="251.6" cy="329.2" rx="5.3" ry="3.1" /><ellipse transform="matrix(0.8562 -0.5167 0.5167 0.8562 -127.9572 184.9349)" opacity="0.54"  enable-background="new    " cx="268.2" cy="322.3" rx="5.6" ry="3.1" /></g>'
                    )
                )
            );
    }

    /// @notice Return the skin name of the given id
    /// @param id The skin Id
    function getItemNameById(uint8 id) public pure returns (string memory name) {
        name = "";
        if (id == 1) {
            name = "None";
        } else if (id == 2) {
            name = "Horn Blood";
        } else if (id == 3) {
            name = "Small Horn Blood";
        } else if (id == 4) {
            name = "Monk Blood";
        } else if (id == 5) {
            name = "Horn Moon";
        } else if (id == 6) {
            name = "Small Horn Moon";
        } else if (id == 7) {
            name = "Monk Moon";
        } else if (id == 8) {
            name = "Power Stick";
        } else if (id == 9) {
            name = "Kitsune";
        } else if (id == 10) {
            name = "Horn Pure";
        } else if (id == 11) {
            name = "Small Horn Pure";
        } else if (id == 12) {
            name = "Heart";
        } else if (id == 13) {
            name = "Monk Pure";
        } else if (id == 14) {
            name = "Power Head";
        } else if (id == 15) {
            name = "Horn Kin";
        } else if (id == 16) {
            name = "Monk Kin";
        }
    }

    /// @dev The base SVG for the body
    function base(string memory children, string memory name) private pure returns (string memory) {
        return string(abi.encodePacked('<g id="accessory"><g id="', name, '">', children, "</g></g>"));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

pragma abicoder v2;

import "base64-sol/base64.sol";

/// @title Earrings SVG generator
library EarringsDetail {
    /// @dev Earrings N°1 => None
    function item_1() public pure returns (string memory) {
        return base("", "None");
    }

    /// @dev Earrings N°2 => Circle Blood
    function item_2() public pure returns (string memory) {
        return
            base(
                '<g display="inline" ><ellipse fill="#B50D5E" cx="137.6" cy="229.1" rx="2.5" ry="3" /></g><g display="inline" ><ellipse fill="#B50D5E" cx="291.6" cy="231.8" rx="3.4" ry="3.5" /></g>',
                "Circle Blood"
            );
    }

    /// @dev Earrings N°3 => Circle Moon
    function item_3() public pure returns (string memory) {
        return
            base(
                '<g display="inline" ><ellipse cx="137.6" cy="229.1" rx="2.5" ry="3" /></g><g display="inline" ><ellipse cx="291.6" cy="231.8" rx="3.4" ry="3.5" /></g>',
                "Circle Moon"
            );
    }

    /// @dev Earrings N°4 => Ring Blood
    function item_4() public pure returns (string memory) {
        return
            base(
                '<path display="inline" fill="none" stroke="#B50D5E" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" stroke-miterlimit="10" d="M289,234.7c0,0-4.4,2.1-3.2,6.4c1,4.3,4.4,4,4.8,4c0.3,0,3.9-0.2,3.9-4.2"  /><path display="inline" fill="none" stroke="#B50D5E" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" stroke-miterlimit="10" d="M137,232.9c0,0-4.4,2.1-3.2,6.4c1,4.3,4.5,3.8,4.8,3.6c0.4-0.1,1.6,0.2,3.4-2.3"  />',
                "Ring Blood"
            );
    }

    /// @dev Earrings N°5 => Ring Moon
    function item_5() public pure returns (string memory) {
        return
            base(
                '<path display="inline" fill="none" stroke="#000000" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" stroke-miterlimit="10" d="M289,234.7c0,0-4.4,2.1-3.2,6.4c1,4.3,4.4,4,4.8,4c0.3,0,3.9-0.2,3.9-4.2"  /><path display="inline" fill="none" stroke="#000000" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" stroke-miterlimit="10" d="M137,232.9c0,0-4.4,2.1-3.2,6.4c1,4.3,4.5,3.8,4.8,3.6c0.4-0.1,1.6,0.2,3.4-2.3"  />',
                "Ring Moon"
            );
    }

    /// @dev Earrings N°6 => Monk Blood
    function item_6() public pure returns (string memory) {
        return
            base(
                '<g display="inline" ><g><ellipse transform="matrix(0.9952 -9.784740e-02 9.784740e-02 0.9952 -23.5819 29.5416)" fill="#B50D5E" stroke="#000000" stroke-width="1" stroke-miterlimit="10.0039" cx="289.4" cy="255.2" rx="8" ry="8.1" /><ellipse transform="matrix(1.784754e-02 -0.9998 0.9998 1.784754e-02 24.9032 543.924)" opacity="0.54"  fill="#33112E" enable-background="new    " cx="289.3" cy="259.3" rx="2.2" ry="4.9" /></g><path fill="#A5CBCC" stroke="#000000" stroke-miterlimit="10.0039" d="M283.4,250.2c3.9,0.5,8.2,0.4,12.1-0.1C295.7,250.1,289.6,243,283.4,250.2z" /><line fill="none" stroke="#000000" stroke-width="2" stroke-linecap="round" stroke-miterlimit="10.0039" x1="289.9" y1="244.7" x2="289.6" y2="247.3" /></g><g display="inline" ><g><ellipse transform="matrix(0.9952 -9.784740e-02 9.784740e-02 0.9952 -24.1729 14.6915)" fill="#B50D5E" stroke="#000000" stroke-width="1" stroke-miterlimit="10.0039" cx="137.7" cy="253.8" rx="8" ry="8.1" /><ellipse transform="matrix(1.784754e-02 -0.9998 0.9998 1.784754e-02 -122.6851 390.7122)" opacity="0.54"  fill="#33112E" enable-background="new    " cx="137.5" cy="257.8" rx="2.2" ry="4.9" /></g><path fill="#A5CBCC" stroke="#000000" stroke-miterlimit="10.0039" d="M131.8,248.8c3.9,0.5,8.1,0.4,12-0.1C143.7,248.6,138,241.6,131.8,248.8z" /><line fill="none" stroke="#000000" stroke-width="2" stroke-linecap="round" stroke-miterlimit="10.0039" x1="138" y1="243.2" x2="137.8" y2="245.8" /></g><g id="Ring" display="inline" ><path fill="none" stroke="#000000" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" stroke-miterlimit="10" d="M289,234.7c0,0-4.4,2.1-3.2,6.4c1,4.3,5.3,3.8,5.6,3.6s3.2-0.9,3.1-5.2" /><path fill="none" stroke="#000000" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" stroke-miterlimit="10" d="M137,232.9c0,0-4.4,2.1-3.2,6.4c1,4.3,5.3,3.8,5.6,3.6c0.3-0.1,3.3-0.6,3.2-4.8" /></g>',
                "Monk Blood"
            );
    }

    /// @dev Earrings N°7 => Tomoe Moon
    function item_7() public pure returns (string memory) {
        return
            base(
                '<path display="inline" fill="none" stroke="#000000" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" stroke-miterlimit="10" d="M289,234.7c0,0-4.4,2.1-3.2,6.4c1,4.3,5.3,3.8,5.6,3.6s3.2-0.9,3.1-5.2"  /><path display="inline" fill="none" stroke="#000000" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" stroke-miterlimit="10" d="M135.9,232.9c0,0-4.4,2.1-3.2,6.4c1,4.3,5.3,3.8,5.6,3.6c0.3-0.1,3.3-0.6,3.2-4.8"  /><g display="inline" ><path  d="M294.7,250.1c0,0-2,5.6-11.3,7.4c0,0,3.4-2,4.6-5.2" /><path  d="M294.6,250.4c1.5-2.4,0.6-5.5-1.8-6.9c-2.4-1.5-5.5-0.6-6.9,1.8c-1.5,2.4-0.6,5.5,1.8,6.9C290.1,253.5,293.2,252.8,294.6,250.4z M288.8,247c0.5-0.8,1.5-1,2.3-0.6c0.8,0.5,1,1.5,0.6,2.3c-0.5,0.8-1.5,1-2.3,0.6C288.5,248.9,288.4,247.8,288.8,247z" /></g><g display="inline" ><path  d="M131.8,247.3c0,0,0.4,6,8.8,10.2c0,0-2.7-2.8-3-6.3" /><path  d="M131.8,247.6c-0.7-2.7,0.9-5.4,3.6-6.1s5.4,0.9,6.1,3.6c0.7,2.7-0.9,5.4-3.6,6.1C135.2,252,132.6,250.3,131.8,247.6z M138.3,245.9c-0.2-0.9-1.1-1.5-2.1-1.3c-0.9,0.2-1.5,1.1-1.3,2.1c0.2,0.9,1.1,1.5,2.1,1.3C138,247.7,138.5,246.8,138.3,245.9z" /></g>',
                "Tomoe Moon"
            );
    }

    /// @dev Earrings N°8 => Circle Pure
    function item_8() public pure returns (string memory) {
        return
            base(
                '<g display="inline" ><ellipse fill="#FFEDED" cx="137.6" cy="229.1" rx="2.5" ry="3" /></g><g display="inline" ><ellipse fill="#FFEDED" cx="291.6" cy="231.8" rx="3.4" ry="3.5" /></g>',
                "Circle Pure"
            );
    }

    /// @dev Earrings N°9 => Ring Pure
    function item_9() public pure returns (string memory) {
        return
            base(
                '<path display="inline" fill="none" stroke="#FFEDED" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" stroke-miterlimit="10" d="M289,234.7c0,0-4.4,2.1-3.2,6.4c1,4.3,4.4,4,4.8,4c0.3,0,3.9-0.2,3.9-4.2"  /><path display="inline" fill="none" stroke="#FFEDED" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" stroke-miterlimit="10" d="M137,232.9c0,0-4.4,2.1-3.2,6.4c1,4.3,4.5,3.8,4.8,3.6c0.4-0.1,1.6,0.2,3.4-2.3"  />',
                "Ring Pure"
            );
    }

    /// @dev Earrings N°10 => Monk Moon
    function item_10() public pure returns (string memory) {
        return
            base(
                '<g display="inline" ><g><ellipse transform="matrix(0.9952 -9.784740e-02 9.784740e-02 0.9952 -23.5819 29.5416)" fill="#2A2C38" stroke="#000000" stroke-width="1" stroke-miterlimit="10.0039" cx="289.4" cy="255.2" rx="8" ry="8.1" /><ellipse transform="matrix(1.784754e-02 -0.9998 0.9998 1.784754e-02 24.9032 543.924)" opacity="0.54"  fill="#33112E" enable-background="new    " cx="289.3" cy="259.3" rx="2.2" ry="4.9" /></g><path fill="#A5CBCC" stroke="#000000" stroke-miterlimit="10.0039" d="M283.4,250.2c3.9,0.5,8.2,0.4,12.1-0.1C295.7,250.1,289.6,243,283.4,250.2z" /><line fill="none" stroke="#000000" stroke-width="2" stroke-linecap="round" stroke-miterlimit="10.0039" x1="289.9" y1="244.7" x2="289.6" y2="247.3" /></g><g display="inline" ><g><ellipse transform="matrix(0.9952 -9.784740e-02 9.784740e-02 0.9952 -24.1729 14.6915)" fill="#2A2C38" stroke="#000000" stroke-width="1" stroke-miterlimit="10.0039" cx="137.7" cy="253.8" rx="8" ry="8.1" /><ellipse transform="matrix(1.784754e-02 -0.9998 0.9998 1.784754e-02 -122.6851 390.7122)" opacity="0.54"  fill="#33112E" enable-background="new    " cx="137.5" cy="257.8" rx="2.2" ry="4.9" /></g><path fill="#A5CBCC" stroke="#000000" stroke-miterlimit="10.0039" d="M131.8,248.8c3.9,0.5,8.1,0.4,12-0.1C143.7,248.6,138,241.6,131.8,248.8z" /><line fill="none" stroke="#000000" stroke-width="2" stroke-linecap="round" stroke-miterlimit="10.0039" x1="138" y1="243.2" x2="137.8" y2="245.8" /></g><g id="Ring" display="inline" ><path fill="none" stroke="#000000" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" stroke-miterlimit="10" d="M289,234.7c0,0-4.4,2.1-3.2,6.4c1,4.3,5.3,3.8,5.6,3.6s3.2-0.9,3.1-5.2" /><path fill="none" stroke="#000000" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" stroke-miterlimit="10" d="M137,232.9c0,0-4.4,2.1-3.2,6.4c1,4.3,5.3,3.8,5.6,3.6c0.3-0.1,3.3-0.6,3.2-4.8" /></g>',
                "Monk Moon"
            );
    }

    /// @dev Earrings N°11 => Tomoe Drop Moon
    function item_11() public pure returns (string memory) {
        return
            base(
                '<g display="inline" ><ellipse cx="291.2" cy="231.8" rx="3.5" ry="3.5" /><line fill="none" stroke="#000000" stroke-miterlimit="10" x1="291.2" y1="231.8" x2="291.2" y2="259.8" /><path  d="M292.2,258.2c-2.5-1.2-5.5,0-6.7,2.5c-1.1,2.5,0,5.5,2.5,6.7c0.1,0.1,0.2,0.1,0.4,0.1c-0.9,3.2-4.1,5.5-4.1,5.5c6.6-1.9,9.1-5.6,10-7.4c0.1-0.2,0.3-0.4,0.4-0.7C295.8,262.4,294.7,259.4,292.2,258.2z M288.5,262.1c0.4-0.8,1.4-1.3,2.2-0.8c0.8,0.4,1.3,1.4,0.8,2.2c-0.4,0.8-1.4,1.3-2.2,0.8C288.5,264,288.1,262.9,288.5,262.1z" /></g><g display="inline" ><ellipse cx="139" cy="231.7" rx="2.6" ry="2.8" /><line fill="none" stroke="#000000" stroke-miterlimit="10" x1="138.5" y1="231.8" x2="138.5" y2="259.8" /><path  d="M140.2,258.9c-2.5-1.1-5.5,0-6.7,2.5c-1.1,2.5,0,5.5,2.5,6.7c0.1,0.1,0.2,0.1,0.4,0.1c-0.9,3.2-4.1,5.5-4.1,5.5c6.8-2,9.3-5.9,10.1-7.6c0.1-0.2,0.2-0.3,0.3-0.5C143.8,263.1,142.7,260.1,140.2,258.9z M136.5,262.8c0.4-0.8,1.4-1.3,2.2-0.8s1.3,1.4,0.8,2.2c-0.4,0.8-1.4,1.3-2.2,0.8C136.5,264.7,136,263.7,136.5,262.8z" /></g>',
                "Tomoe Drop Moon"
            );
    }

    /// @dev Earrings N°12 => Tomoe Pure
    function item_12() public pure returns (string memory) {
        return
            base(
                '<path display="inline" fill="none" stroke="#000000" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" stroke-miterlimit="10" d="M289,234.7c0,0-4.4,2.1-3.2,6.4c1,4.3,5.3,3.8,5.6,3.6s3.2-0.9,3.1-5.2"  /><path display="inline" fill="none" stroke="#000000" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" stroke-miterlimit="10" d="M135.9,232.9c0,0-4.4,2.1-3.2,6.4c1,4.3,5.3,3.8,5.6,3.6c0.3-0.1,3.3-0.6,3.2-4.8"  /><g display="inline" ><path  fill="#FFEDED" d="M294.7,250.1c0,0-2,5.6-11.3,7.4c0,0,3.4-2,4.6-5.2" /><path  fill="#FFEDED" d="M294.6,250.4c1.5-2.4,0.6-5.5-1.8-6.9c-2.4-1.5-5.5-0.6-6.9,1.8c-1.5,2.4-0.6,5.5,1.8,6.9C290.1,253.5,293.2,252.8,294.6,250.4z M288.8,247c0.5-0.8,1.5-1,2.3-0.6c0.8,0.5,1,1.5,0.6,2.3c-0.5,0.8-1.5,1-2.3,0.6C288.5,248.9,288.4,247.8,288.8,247z" /></g><g display="inline" ><path  fill="#FFEDED" d="M131.8,247.3c0,0,0.4,6,8.8,10.2c0,0-2.7-2.8-3-6.3" /><path  fill="#FFEDED" d="M131.8,247.6c-0.7-2.7,0.9-5.4,3.6-6.1s5.4,0.9,6.1,3.6c0.7,2.7-0.9,5.4-3.6,6.1C135.2,252,132.6,250.3,131.8,247.6z M138.3,245.9c-0.2-0.9-1.1-1.5-2.1-1.3c-0.9,0.2-1.5,1.1-1.3,2.1c0.2,0.9,1.1,1.5,2.1,1.3C138,247.7,138.5,246.8,138.3,245.9z" /></g>',
                "Tomoe Pure"
            );
    }

    /// @dev Earrings N°13 => Monk Pure
    function item_13() public pure returns (string memory) {
        return
            base(
                '<g display="inline" ><g><ellipse transform="matrix(0.9952 -9.784740e-02 9.784740e-02 0.9952 -23.5819 29.5416)" fill="#FFEDED" stroke="#000000" stroke-width="1" stroke-miterlimit="10.0039" cx="289.4" cy="255.2" rx="8" ry="8.1" /><ellipse transform="matrix(1.784754e-02 -0.9998 0.9998 1.784754e-02 24.9032 543.924)" opacity="0.54"  fill="#33112E" enable-background="new    " cx="289.3" cy="259.3" rx="2.2" ry="4.9" /></g><path fill="#A5CBCC" stroke="#000000" stroke-miterlimit="10.0039" d="M283.4,250.2c3.9,0.5,8.2,0.4,12.1-0.1C295.7,250.1,289.6,243,283.4,250.2z" /><line fill="none" stroke="#000000" stroke-width="2" stroke-linecap="round" stroke-miterlimit="10.0039" x1="289.9" y1="244.7" x2="289.6" y2="247.3" /></g><g display="inline" ><g><ellipse transform="matrix(0.9952 -9.784740e-02 9.784740e-02 0.9952 -24.1729 14.6915)" fill="#FFEDED" stroke="#000000" stroke-width="1" stroke-miterlimit="10.0039" cx="137.7" cy="253.8" rx="8" ry="8.1" /><ellipse transform="matrix(1.784754e-02 -0.9998 0.9998 1.784754e-02 -122.6851 390.7122)" opacity="0.54"  fill="#33112E" enable-background="new    " cx="137.5" cy="257.8" rx="2.2" ry="4.9" /></g><path fill="#A5CBCC" stroke="#000000" stroke-miterlimit="10.0039" d="M131.8,248.8c3.9,0.5,8.1,0.4,12-0.1C143.7,248.6,138,241.6,131.8,248.8z" /><line fill="none" stroke="#000000" stroke-width="2" stroke-linecap="round" stroke-miterlimit="10.0039" x1="138" y1="243.2" x2="137.8" y2="245.8" /></g><g id="Ring" display="inline" ><path fill="none" stroke="#000000" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" stroke-miterlimit="10" d="M289,234.7c0,0-4.4,2.1-3.2,6.4c1,4.3,5.3,3.8,5.6,3.6s3.2-0.9,3.1-5.2" /><path fill="none" stroke="#000000" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" stroke-miterlimit="10" d="M137,232.9c0,0-4.4,2.1-3.2,6.4c1,4.3,5.3,3.8,5.6,3.6c0.3-0.1,3.3-0.6,3.2-4.8" /></g>',
                "Monk Pure"
            );
    }

    /// @dev Earrings N°14 => Tomoe Drop Pure
    function item_14() public pure returns (string memory) {
        return
            base(
                '<g display="inline" ><ellipse cx="291.2" cy="231.8" rx="3.5" ry="3.5" /><line fill="none" stroke="#000000" stroke-miterlimit="10" x1="291.2" y1="231.8" x2="291.2" y2="259.8" /><path  fill="#FFEDED" d="M292.2,258.2c-2.5-1.2-5.5,0-6.7,2.5c-1.1,2.5,0,5.5,2.5,6.7c0.1,0.1,0.2,0.1,0.4,0.1c-0.9,3.2-4.1,5.5-4.1,5.5c6.6-1.9,9.1-5.6,10-7.4c0.1-0.2,0.3-0.4,0.4-0.7C295.8,262.4,294.7,259.4,292.2,258.2z M288.5,262.1c0.4-0.8,1.4-1.3,2.2-0.8c0.8,0.4,1.3,1.4,0.8,2.2c-0.4,0.8-1.4,1.3-2.2,0.8C288.5,264,288.1,262.9,288.5,262.1z" /></g><g display="inline" ><ellipse cx="139" cy="231.7" rx="2.6" ry="2.8" /><line fill="none" stroke="#000000" stroke-miterlimit="10" x1="138.5" y1="231.8" x2="138.5" y2="259.8" /><path  fill="#FFEDED" d="M140.2,258.9c-2.5-1.1-5.5,0-6.7,2.5c-1.1,2.5,0,5.5,2.5,6.7c0.1,0.1,0.2,0.1,0.4,0.1c-0.9,3.2-4.1,5.5-4.1,5.5c6.8-2,9.3-5.9,10.1-7.6c0.1-0.2,0.2-0.3,0.3-0.5C143.8,263.1,142.7,260.1,140.2,258.9z M136.5,262.8c0.4-0.8,1.4-1.3,2.2-0.8s1.3,1.4,0.8,2.2c-0.4,0.8-1.4,1.3-2.2,0.8C136.5,264.7,136,263.7,136.5,262.8z" /></g>',
                "Tomoe Drop Pure"
            );
    }

    /// @dev Earrings N°15 => Tomoe Drop Gold
    function item_15() public pure returns (string memory) {
        return
            base(
                '<g display="inline" ><ellipse cx="291.2" cy="231.8" rx="3.5" ry="3.5" /><line fill="none" stroke="#000000" stroke-miterlimit="10" x1="291.2" y1="231.8" x2="291.2" y2="259.8" /><linearGradient id="SVGID_00000120528397129779781120000012903837417257993114_" gradientUnits="userSpaceOnUse" x1="284.3" y1="-535.3656" x2="295.1259" y2="-535.3656" gradientTransform="matrix(1 0 0 -1 0 -270)"><stop offset="0" style="stop-color:#FFB451" /><stop offset="0.5259" style="stop-color:#F7EC94" /><stop offset="1" style="stop-color:#FF9121" /></linearGradient><path  fill="url(#SVGID_00000120528397129779781120000012903837417257993114_)" d="M292.2,258.2c-2.5-1.2-5.5,0-6.7,2.5c-1.1,2.5,0,5.5,2.5,6.7c0.1,0.1,0.2,0.1,0.4,0.1c-0.9,3.2-4.1,5.5-4.1,5.5c6.6-1.9,9.1-5.6,10-7.4c0.1-0.2,0.3-0.4,0.4-0.7C295.8,262.4,294.7,259.4,292.2,258.2z M288.5,262.1c0.4-0.8,1.4-1.3,2.2-0.8c0.8,0.4,1.3,1.4,0.8,2.2c-0.4,0.8-1.4,1.3-2.2,0.8C288.5,264,288.1,262.9,288.5,262.1z" /></g><g display="inline" ><ellipse cx="139" cy="231.7" rx="2.6" ry="2.8" /><line fill="none" stroke="#000000" stroke-miterlimit="10" x1="138.5" y1="231.8" x2="138.5" y2="259.8" /><linearGradient id="SVGID_00000027574875614874123830000011265039474658243508_" gradientUnits="userSpaceOnUse" x1="132.3" y1="-536.087" x2="143.1259" y2="-536.087" gradientTransform="matrix(1 0 0 -1 0 -270)"><stop offset="0" style="stop-color:#FFB451" /><stop offset="0.5259" style="stop-color:#F7EC94" /><stop offset="1" style="stop-color:#FF9121" /></linearGradient><path  fill="url(#SVGID_00000027574875614874123830000011265039474658243508_)" d="M140.2,258.9c-2.5-1.1-5.5,0-6.7,2.5c-1.1,2.5,0,5.5,2.5,6.7c0.1,0.1,0.2,0.1,0.4,0.1c-0.9,3.2-4.1,5.5-4.1,5.5c6.8-2,9.3-5.9,10.1-7.6c0.1-0.2,0.2-0.3,0.3-0.5C143.8,263.1,142.7,260.1,140.2,258.9z M136.5,262.8c0.4-0.8,1.4-1.3,2.2-0.8s1.3,1.4,0.8,2.2c-0.4,0.8-1.4,1.3-2.2,0.8C136.5,264.7,136,263.7,136.5,262.8z" /></g>',
                "Tomoe Drop Gold"
            );
    }

    /// @notice Return the skin name of the given id
    /// @param id The skin Id
    function getItemNameById(uint8 id) public pure returns (string memory name) {
        name = "";
        if (id == 1) {
            name = "None";
        } else if (id == 2) {
            name = "Circle Blood";
        } else if (id == 3) {
            name = "Circle Moon";
        } else if (id == 4) {
            name = "Ring Blood";
        } else if (id == 5) {
            name = "Ring Moon";
        } else if (id == 6) {
            name = "Monk Blood";
        } else if (id == 7) {
            name = "Tomoe";
        } else if (id == 8) {
            name = "Circle Pure";
        } else if (id == 9) {
            name = "Ring Pure";
        } else if (id == 10) {
            name = "Monk Moon";
        } else if (id == 11) {
            name = "Tomoe Drop";
        } else if (id == 12) {
            name = "Tomoe Pure";
        } else if (id == 13) {
            name = "Monk Pure";
        } else if (id == 14) {
            name = "Tomoe Drop Pure";
        } else if (id == 15) {
            name = "Tomoe Drop Gold";
        }
    }

    /// @dev The base SVG for the body
    function base(string memory children, string memory name) private pure returns (string memory) {
        return string(abi.encodePacked('<g id="earrings"><g id="', name, '">', children, "</g></g>"));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

pragma abicoder v2;

import "base64-sol/base64.sol";

/// @title Mask SVG generator
library MaskDetail {
    /// @dev Mask N°1 => None
    function item_1() public pure returns (string memory) {
        return base("", "None");
    }

    /// @dev Mask N°2 => Uni Horn Blood
    function item_2() public pure returns (string memory) {
        return base(horn("E31466"), "Uni Horn Blood");
    }

    /// @dev Mask N°3 => Power Sticks
    function item_3() public pure returns (string memory) {
        return base(powerStick("000000"), "Power sticks");
    }

    /// @dev Mask N°4 => Uni Horn Moon
    function item_4() public pure returns (string memory) {
        return base(horn("2A2C38"), "Uni Horn Moon");
    }

    /// @dev Mask N°5 => Power Neck
    function item_5() public pure returns (string memory) {
        return
            base(
                '<g display="inline"><path stroke="#000000" stroke-miterlimit="10" d="M254,291l22.2-0.1c0.3,0.4,2.5,4.3,0,9H254C252.1,296.7,251.9,293.7,254,291z" /><g><path d="M251.9,289.3c-1,2-1.8,4-1.9,6c0,1,0,2.1,0.3,3.1c0.1,0.5,0.3,1,0.4,1.6c0.2,0.5,0.4,1,0.6,1.6c-0.4-0.4-0.7-0.8-1-1.4c-0.3-0.5-0.6-0.9-0.7-1.6c-0.4-1-0.6-2.2-0.6-3.4c0-1.1,0.3-2.3,0.8-3.3C250.4,290.9,251.1,289.9,251.9,289.3z" /></g></g><g display="inline"><path stroke="#000000" stroke-miterlimit="10" d="M177.4,292.4l-20-0.1c-0.3,0.4-2.3,4.3,0,9h20C179.2,298.1,179.5,295.2,177.4,292.4z" /><g><path d="M179.5,290.7c0.8,0.7,1.6,1.7,2.1,2.7s0.8,2.2,0.8,3.3s-0.1,2.3-0.6,3.4c-0.2,0.5-0.5,1-0.7,1.6c-0.3,0.5-0.7,0.9-1,1.4c0.2-0.5,0.4-1,0.6-1.6c0.1-0.5,0.3-1,0.4-1.6c0.3-1,0.3-2.1,0.3-3.1C181.3,294.7,180.5,292.7,179.5,290.7z" /></g></g>',
                "Power Neck"
            );
    }

    /// @dev Mask N°6 => Bouc
    function item_6() public pure returns (string memory) {
        return
            base(
                '<path id="Bouc"  d="M189.4,279c0,0,8.8,9.2,9.8,10c0.7-0.7,6.4-14.7,6.4-14.7l5.8,14.7l10.4-10l-16.3,71L189.4,279z"/>',
                "Bouc"
            );
    }

    /// @dev Mask N°7 => BlindFold Tomoe Blood
    function item_7() public pure returns (string memory) {
        return base(blindfold("D4004D", "FFEDED"), "Blindfold Tomoe Blood");
    }

    /// @dev Mask N°8 => Strap Blood
    function item_8() public pure returns (string memory) {
        return base(strap("D9005E"), "Strap Blood");
    }

    /// @dev Mask N°9 => Sun Glasses
    function item_9() public pure returns (string memory) {
        return
            base(
                '<g display="inline" opacity="0.95"><ellipse stroke="#000000" stroke-miterlimit="10" cx="164.6" cy="189.5" rx="24.9" ry="24.8" /><ellipse stroke="#000000" stroke-miterlimit="10" cx="236.3" cy="188.5" rx="24.9" ry="24.8" /></g><path display="inline" fill="none" stroke="#000000" stroke-miterlimit="10" d="M261.1,188.6l32.2-3.6 M187,188.6c0,0,15.3-3.2,24.5,0 M140.6,189l-7.1-3" />',
                "Sun glasses"
            );
    }

    /// @dev Mask N°10 => Uni Horn Pure
    function item_10() public pure returns (string memory) {
        return base(horn("FFDAEA"), "Uni Horn Pure");
    }

    /// @dev Mask N°11 => Strap Moon
    function item_11() public pure returns (string memory) {
        return base(strap("575673"), "Strap Moon");
    }

    /// @dev Mask N°12 => BlindFold Tomoe Moon
    function item_12() public pure returns (string memory) {
        return base(blindfold("000000", "B50D5E"), "BlindFold Tomoe Moon");
    }

    /// @dev Mask N°13 => Stitch
    function item_13() public pure returns (string memory) {
        return
            base(
                '<g display="inline"><path d="M175.8,299.3c7.2,1.8,14.4,2.9,21.7,3.9c1.9,0.2,3.5,0.5,5.4,0.7s3.6,0.3,5.4,0.5c3.6,0.2,7.2,0.2,10.9,0.1c3.6-0.1,7.2-0.5,10.9-0.7l5.4-0.6c0.9-0.1,1.9-0.2,2.7-0.3l2.7-0.4c7.2-1,14.4-2.9,21.5-4.8v0.1l-5.5,1.9l-2.7,0.8c-0.9,0.3-1.8,0.5-2.7,0.7l-5.4,1.4c-1.9,0.4-3.5,0.6-5.4,1c-3.5,0.7-7.2,0.9-10.9,1.4c-3.6,0.2-7.2,0.4-10.9,0.3c-7.2-0.1-14.6-0.3-21.8-0.9C190.1,303.1,182.8,301.8,175.8,299.3L175.8,299.3z" /></g><path display="inline" stroke="#000000" stroke-width="0.75" stroke-miterlimit="10" d="M206.9,304.5c0,0,5.3-2.1,11.8,0.2C218.8,304.7,212.8,307.6,206.9,304.5z" /><g display="inline"><path fill="#FFFFFF" stroke="#000000" stroke-width="0.75" stroke-miterlimit="10" d="M222.1,301c0,0,0.7-3.4,1.9-1c0,0,0.3,5.3-0.5,9.9c0,0-0.7,2.2-1-0.6C222.1,306.5,222.7,306.2,222.1,301z" /><path fill="#FFFFFF" stroke="#000000" stroke-width="0.75" stroke-miterlimit="10" d="M227.4,301.2c0,0,0.7-3.1,1.7-0.9c0,0,0.3,4.7-0.4,8.9c0,0-0.6,1.9-0.9-0.5C227.4,306.1,228.2,305.8,227.4,301.2z" /><path fill="#FFFFFF" stroke="#000000" stroke-width="0.75" stroke-miterlimit="10" d="M231.8,301.1c0,0,0.6-2.7,1.5-0.8c0,0,0.3,4.1-0.3,7.7c0,0-0.5,1.7-0.7-0.4C231.8,305.3,232.3,305.1,231.8,301.1z" /><path fill="#FFFFFF" stroke="#000000" stroke-width="0.75" stroke-miterlimit="10" d="M235.5,300.8c0,0,0.5-2.4,1.4-0.7c0,0,0.3,3.6-0.3,6.9c0,0-0.5,1.5-0.7-0.4C235.6,304.6,236,304.4,235.5,300.8z" /></g><g display="inline"><path fill="#FFFFFF" stroke="#000000" stroke-width="0.75" stroke-miterlimit="10" d="M203.8,300.5c0,0-0.7-3.4-1.9-1c0,0-0.3,5.3,0.5,9.9c0,0,0.7,2.2,1-0.6C203.8,306,203.1,305.8,203.8,300.5z" /><path fill="#FFFFFF" stroke="#000000" stroke-width="0.75" stroke-miterlimit="10" d="M198.5,300.8c0,0-0.7-3.1-1.7-0.9c0,0-0.3,4.7,0.4,8.9c0,0,0.6,1.9,0.9-0.5C198.5,305.8,197.7,305.3,198.5,300.8z" /><path fill="#FFFFFF" stroke="#000000" stroke-width="0.75" stroke-miterlimit="10" d="M194.1,300.6c0,0-0.6-2.7-1.5-0.8c0,0-0.3,4.1,0.3,7.7c0,0,0.5,1.7,0.7-0.4C193.9,305,193.6,304.7,194.1,300.6z" /><path fill="#FFFFFF" stroke="#000000" stroke-width="0.75" stroke-miterlimit="10" d="M190.4,300.3c0,0-0.5-2.4-1.4-0.7c0,0-0.3,3.6,0.3,6.9c0,0,0.5,1.5,0.7-0.4C190.4,304.2,189.9,304,190.4,300.3z" /></g>',
                "Stitch"
            );
    }

    /// @dev Mask N°14 => Strap Pure
    function item_14() public pure returns (string memory) {
        return base(strap("F2F2F2"), "Strap Pure");
    }

    /// @dev Mask N°15 => Eye Patch
    function item_15() public pure returns (string memory) {
        return
            base(
                '<g id="MASK EYE" display="inline"><g><path fill="#FCFEFF" d="M257.9,210.4h-36.1c-4.9,0-8.9-4-8.9-8.9v-21.7c0-4.9,4-8.9,8.9-8.9h36.1c4.9,0,8.9,4,8.9,8.9v21.8C266.6,206.4,262.8,210.4,257.9,210.4z"/><path d="M257.9,210.4l-10.7,0.1l-10.7,0.2c-3.6,0.1-7.1,0.1-10.7,0.1h-2.7h-1.3c-0.5,0-0.9,0-1.4-0.1c-1.9-0.3-3.6-1.2-4.9-2.5c-1.4-1.3-2.3-3-2.6-4.8c-0.2-0.9-0.2-1.9-0.2-2.7V198c0.1-3.6,0.1-7.1,0.1-10.7v-5.4c0-0.9,0-1.8,0-2.7c0.1-0.9,0.2-1.8,0.6-2.7c0.6-1.7,1.8-3.2,3.3-4.3c0.8-0.5,1.6-0.9,2.4-1.2c0.9-0.3,1.8-0.4,2.7-0.4l21.4-0.2l10.7-0.1h2.7h1.3c0.5,0,0.9,0,1.4,0.1c1.9,0.3,3.6,1.2,5,2.5s2.3,3,2.7,4.9c0.2,0.9,0.2,1.9,0.2,2.8v2.7l-0.1,10.7l-0.1,5.4c0,0.9,0,1.8-0.1,2.7s-0.3,1.8-0.7,2.6c-0.7,1.7-1.8,3.2-3.3,4.2c-0.7,0.5-1.6,0.9-2.4,1.2C259.7,210.3,258.8,210.4,257.9,210.4z M257.9,210.3c0.9,0,1.8-0.2,2.6-0.4c0.8-0.3,1.6-0.7,2.4-1.2c1.4-1,2.6-2.5,3.2-4.2c0.3-0.8,0.5-1.7,0.5-2.6c0.1-0.9,0-1.8,0-2.7l-0.1-5.4l-0.1-10.7v-2.7c0-0.9,0-1.7-0.2-2.6c-0.4-1.6-1.2-3.2-2.5-4.3c-1.2-1.2-2.8-1.9-4.5-2.2c-0.4-0.1-0.8-0.1-1.3-0.1h-1.3h-2.7l-10.7-0.1l-21.4-0.2c-3.5-0.1-6.9,2.2-8.1,5.5c-0.7,1.6-0.6,3.4-0.6,5.2v5.4c0,3.6,0,7.1,0.1,10.7v2.7c0,0.9,0,1.7,0.2,2.6c0.4,1.7,1.3,3.2,2.5,4.4s2.8,2,4.5,2.2c0.8,0.1,1.7,0.1,2.6,0.1h2.7c3.6,0,7.1,0,10.7,0.1l10.7,0.2L257.9,210.3z"/></g><g><path d="M254.2,206.4c-5.7,0-11.4,0.1-17,0.2c-2.8,0.1-5.7,0.1-8.5,0.1h-2.1c-0.7,0-1.4,0-2.2-0.1c-1.5-0.2-2.9-0.9-4-1.9s-1.8-2.4-2.2-3.8c-0.2-0.7-0.2-1.5-0.2-2.2v-2.1c0-2.8,0.1-5.7,0.1-8.5v-4.3c0-0.7,0-1.4,0-2.1c0.1-0.7,0.2-1.4,0.5-2.1c0.5-1.4,1.5-2.5,2.6-3.4c0.6-0.4,1.3-0.7,2-1c0.7-0.2,1.4-0.3,2.2-0.3l17-0.1h8.5h2.1c0.7,0,1.4,0,2.2,0.1c1.5,0.2,2.9,0.9,4,1.9s1.9,2.4,2.2,3.8c0.2,0.7,0.2,1.5,0.2,2.2v2.1l-0.1,8.5l-0.1,4.3c0,0.7,0,1.4-0.1,2.1c-0.1,0.7-0.2,1.4-0.5,2.1c-0.5,1.3-1.5,2.5-2.7,3.3C257.1,206,255.6,206.4,254.2,206.4z M254.2,206.4c1.4,0,2.8-0.4,4-1.2s2.1-1.9,2.6-3.3c0.2-0.7,0.4-1.4,0.4-2c0-0.7,0-1.4,0-2.1l-0.1-4.3L261,185v-2.1c0-0.7,0-1.4-0.2-2c-0.3-1.3-1-2.5-2-3.4s-2.3-1.5-3.6-1.7c-0.7-0.1-1.3-0.1-2.1-0.1H251h-8.5l-17-0.1c-2.8-0.1-5.5,1.7-6.5,4.3c-0.3,0.6-0.4,1.3-0.5,2s0,1.4,0,2.1v4.3c0,2.8,0,5.7,0.1,8.5v2.1c0,0.7,0,1.4,0.2,2.1c0.3,1.3,1,2.6,2.1,3.5c1,0.9,2.3,1.5,3.6,1.7c0.7,0.1,1.4,0.1,2.1,0.1h2.1c2.8,0,5.7,0,8.5,0.1C242.8,206.3,248.5,206.4,254.2,206.4z"/></g><g><path d="M214.4,174.8c-7-0.5-13.9-1.1-20.8-1.8c-3.5-0.4-6.9-0.8-10.4-1.1s-7-0.5-10.4-0.6c-7-0.3-13.9-0.5-20.9-0.9c-7-0.3-13.9-0.7-20.9-1.2c0,0,0,0,0-0.1l0,0c7-0.1,13.9,0,20.9,0.3s13.9,0.7,20.9,1.3c3.5,0.3,6.9,0.6,10.4,0.8l10.4,0.6C200.6,172.8,207.5,173.6,214.4,174.8C214.4,174.8,214.5,174.8,214.4,174.8C214.4,174.8,214.4,174.9,214.4,174.8z"/></g><g><path d="M265.2,175c2.8,0,5.5,0.3,8.2,0.7c1.4,0.3,2.7,0.6,4,0.8c1.4,0.2,2.7,0.4,4.1,0.5c2.7,0.2,5.5,0.6,8.2,1.1s5.4,1.2,8,2.1c0,0,0,0,0,0.1c0,0,0,0-0.1,0c-2.7-0.3-5.4-0.7-8.1-1.2s-5.4-1-8.1-1.6c-1.3-0.3-2.7-0.6-4.1-0.7c-1.4-0.2-2.7-0.2-4.1-0.3C270.6,176.2,267.9,175.8,265.2,175L265.2,175L265.2,175z"/></g><g><path d="M263.6,208.2c1.7,2.6,3.3,5.3,4.7,8.1c0.7,1.4,1.3,2.8,2.1,4.2c0.8,1.4,1.6,2.7,2.5,4c1.8,2.6,3.4,5.2,5.1,7.9c1.6,2.7,3.2,5.3,4.7,8.1v0.1c0,0,0,0-0.1,0c-2-2.4-3.8-5-5.6-7.6c-1.7-2.6-3.3-5.4-4.7-8.1c-0.7-1.4-1.5-2.8-2.3-4.1s-1.7-2.6-2.5-4C266,214,264.7,211.2,263.6,208.2C263.5,208.2,263.6,208.2,263.6,208.2C263.6,208.1,263.6,208.2,263.6,208.2z"/></g><g><path d="M213.9,206.7c-5.8,2.8-11.7,5.2-17.7,7.4l-4.5,1.5c-1.5,0.5-3,1-4.5,1.5c-3,1-6,2.1-9,3.2c-6,2.2-12.1,4.1-18.2,5.8c-6.1,1.7-12.3,3.2-18.6,4.4h-0.1v-0.1l36.7-10.7c3.1-0.9,6.1-1.9,9.1-3s5.9-2.3,8.9-3.5C201.9,211,207.9,208.8,213.9,206.7C213.9,206.6,213.9,206.7,213.9,206.7C214,206.7,213.9,206.7,213.9,206.7z"/></g></g>',
                "Eye Patch"
            );
    }

    /// @dev Mask N°16 => Eye
    function item_16() public pure returns (string memory) {
        return
            base(
                '<path d="M199.9,132.9s-15.2,17-.1,39.9C199.9,172.7,214.8,154.7,199.9,132.9Z" transform="translate(0 0.5)" /> <path d="M207,139.4c3.51,8.76,3.82,19.26-1,27.6C209.59,158.25,209.25,148.47,207,139.4Z" transform="translate(0 0.5)"/> <path d="M190.9,155.2c.81,5.6,1.84,11.19,4.9,16.1C192.1,167,191,160.73,190.9,155.2Z" transform="translate(0 0.5)"/> <path d="M202.27,142.35c1-.3,2.1,6.26,1.07,6.31C202.34,149,201.23,142.4,202.27,142.35Z" transform="translate(0 0.5)" fill="#fff"/>',
                "Eye"
            );
    }

    /// @dev Mask N°17 => Nihon
    function item_17() public pure returns (string memory) {
        return
            base(
                '<path id="Nihon" display="inline" fill="#FFFFFF" stroke="#000000" stroke-width="2" stroke-miterlimit="10" d="M175.3,307.1c0,0,21.5,15.8,85.9,0.3c0.3-0.1,0.4-0.3,0.4-0.5c0-2.7,0-17.9,4.6-46.5c0-0.1,0.1-0.2,0.1-0.3c1.1-1.6,13.5-17.6,15.9-20.6c0.2-0.3,0.1-0.6-0.2-0.8c-5.3-3.2-47.8-29-83-38c-1.1-0.3-3.1-0.7-4.2-0.2c-17.5,7.4-46.3,28.9-52.8,33.9c-0.8,0.6-0.9,1.7-0.7,2.7c1.5,5.3,8.2,19.9,10.2,21.8c1.8,1.7,23.1,18.5,23.1,18.5s0.7,0.2,0.7,0.3C175.8,278.6,177.7,287,175.3,307.1z" /><path display="inline" fill="none" stroke="#000000" stroke-linecap="round" stroke-miterlimit="10" d="M175.8,277.7c0,0,21.3,17.6,29.6,17.9s15.7-4,16.6-4.5c0.9-0.4,19-9.1,33.1-20.7 M267,259.4c-3.2,3.5-7.3,7.3-11.9,11" /><path display="inline" fill="#696969" d="M199.5,231.6l-8.2-3.6c-0.4-0.2-0.5-0.7-0.2-1.1l3.3-3.4c0.4-0.4,1-0.5,1.6-0.3l13.2,4.8c0.6,0.2,0.6,1.1-0.1,1.4l-9.1,2.5C199.8,231.7,199.5,231.7,199.5,231.6z M175.5,278.2c0,0,26.5,36.4,43.2,32c16.8-4.4,43.7-21.8,43.7-21.8c1.3-9.1,2.2-19.7,3.3-28.7c-4.8,4.9-13.3,13.8-21.8,19.1c-5.2,3.2-22.1,15.1-36.4,16.7C200,296.3,175.5,278.2,175.5,278.2z"  /><ellipse display="inline" opacity="0.87" fill="#FF0057" enable-background="new    " cx="239.4" cy="248.4" rx="14" ry="15.1"  />',
                "Nihon"
            );
    }

    /// @dev Mask N°18 => BlindFold Tomoe Pure
    function item_18() public pure returns (string memory) {
        return base(blindfold("FFEDED", "B50D5E"), "BlindFold Tomoe Pure");
    }

    /// @dev Mask N°19 => Power Sticks Pure
    function item_19() public pure returns (string memory) {
        return base(powerStick("FFEDED"), "Power Sticks Pure");
    }

    /// @dev Mask N°20 => ???
    function item_20() public pure returns (string memory) {
        return
            base(
                '<path display="inline" fill="#F5F4F3" stroke="#000000" stroke-width="3" stroke-miterlimit="10" d="M290.1,166.9c0,71-20.4,132.3-81.2,133.3c-60.9,0.9-77.5-59.4-77.5-130.4s15-107.6,75.8-107.6C270.4,62.3,290.1,96,290.1,166.9z" /><path display="inline" opacity="8.000000e-02" enable-background="new    " d="M290,165.9c0,71-20.2,132.7-81.3,134.4c28.3-18.3,29.5-51.1,29.5-121.9S263,89,206.9,62.4C270.2,62.4,290,95,290,165.9z" /><ellipse display="inline" cx="245.9" cy="169.9" rx="17.6" ry="6.4" /><path display="inline" d="M233.7,266.5c0.3-7.5-12.6-6.4-28.3-6.4s-28.6-1.5-28.3,6.4c0.1,3.5,12.6,6.4,28.3,6.4S233.6,270,233.7,266.5z"  /><ellipse display="inline" cx="161.5" cy="169.7" rx="17" ry="6.3"  /><path display="inline" fill="#F2EDED" stroke="#000000" stroke-linecap="round" stroke-miterlimit="10" d="M148.5,181c0,0,7,6,21.4,0.6"  /><path display="inline" fill="#F2EDED" stroke="#000000" stroke-linecap="round" stroke-miterlimit="10" d="M235.2,180.9c0,0,6.9,5.9,21.3,0.6"  /><path display="inline" fill="#F2EDED" stroke="#000000" stroke-linecap="round" stroke-miterlimit="10" d="M193.4,278.5c0,0,9.6,3.6,22.5,0"  /><path display="inline" fill="#996DAD" d="M149.8,190.5c1.6-3.8,17.9-3.5,19.6-0.4c1.9,3.3-5,47.5-6.9,47.8C159.2,238.6,146.9,201.5,149.8,190.5z"  /><path display="inline" fill="#996DAD" d="M236.3,189.8c1.6-3.8,18.8-2.8,20.5,0.3c3.9,6.7-6.8,47.3-9.7,47.2C243.6,237,233.4,200.8,236.3,189.8z"  /><path display="inline" fill="#996DAD" d="M233.6,149c1.4,2.4,15.3,2.2,16.8,0.2c1.7-2.1-4.3-28.8-7.5-29.3C239.4,119.5,231.1,142.3,233.6,149z"  /><path display="inline" fill="#996DAD" d="M151.9,151.7c1.4,2.4,15.3,2.2,16.8,0.2c1.7-2.1-4.3-28.8-7.5-29.3C157.8,122.1,149.5,144.9,151.9,151.7z"  />',
                "???"
            );
    }

    function powerStick(string memory color) private pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    abi.encodePacked(
                        '<path style="fill:#',
                        color,
                        ";stroke:#",
                        color,
                        ';stroke-miterlimit:10;" d="M276.3,325.2l9.2-20.2c0.5-0.2,5-0.4,8.1,3.8l-9.3,20.1C280.7,329.3,277.8,328.2,276.3,325.2z"/><ellipse transform="matrix(0.4183 -0.9083 0.9083 0.4183 -110.5579 441.5047)" style="fill:#',
                        color,
                        ';" cx="289.4" cy="307.1" rx="1.7" ry="4.4"/><path d="M273.9,326.4c2.6,3.8,6.4,5.6,10.9,5.5C280.5,333.5,275,331.1,273.9,326.4z"/><path style="fill:#',
                        color,
                        ";stroke:#",
                        color,
                        ';stroke-miterlimit:10;" d="M304,341.3l9.9-19.9c0.5-0.1,5-0.3,7.9,4.1l-9.9,19.8C308.3,345.6,305.4,344.5,304,341.3z"/>'
                    ),
                    abi.encodePacked(
                        '<ellipse transform="matrix(0.4485 -0.8938 0.8938 0.4485 -113.8785 462.7307)" style="fill:#',
                        color,
                        ';" cx="318" cy="323.6" rx="1.7" ry="4.4"/><path d="M301.6,342.6c2.5,3.9,6.3,5.8,10.8,6C308.1,350,302.6,347.2,301.6,342.6z"/> <path style="fill:#',
                        color,
                        ";stroke:#",
                        color,
                        ';stroke-miterlimit:10;" d="M154.7,323.7l-7.1-21.1c-0.4-0.2-4.9-0.9-8.4,2.9l7.1,21.1C150,327.3,152.9,326.6,154.7,323.7z"/><ellipse transform="matrix(0.9467 -0.322 0.322 0.9467 -90.3736 62.4201)" style="fill:#',
                        color,
                        ';" cx="143.5" cy="304.4" rx="4.4" ry="1.7"/><path d="M157.1,325.2c-1.7,4.4-7.2,6.4-11.5,4.5C150,330.3,154.2,328.7,157.1,325.2z"/>'
                    ),
                    abi.encodePacked(
                        '<path style="fill:#',
                        color,
                        ";stroke:#",
                        color,
                        ';stroke-miterlimit:10;" d="M122.5,334.4l-7.7-20.8c-0.4-0.2-4.9-0.8-8.3,3.1l7.8,20.7C117.9,338.2,120.6,337.3,122.5,334.4z"/> <ellipse transform="matrix(0.9364 -0.3508 0.3508 0.9364 -103.5719 58.8717)" style="fill:#',
                        color,
                        ';" cx="110.7" cy="315.3" rx="4.4" ry="1.7"/><path d="M124.8,335.9c-1.4,4.4-6.9,6.8-11.2,4.8C117.9,341.1,122.2,339.3,124.8,335.9z"/>'
                    )
                )
            );
    }

    function blindfold(string memory colorBlindfold, string memory colorTomoe) private pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    abi.encodePacked(
                        '<path display="inline" opacity="0.22"  enable-background="new " d="M135.7,204.6 c0,0,45,25.9,146.6,0.3C287.1,206.1,189.1,221.5,135.7,204.6z"/> <g display="inline"> <path fill="#',
                        colorBlindfold,
                        '" stroke="#000000" stroke-miterlimit="10" d="M202.4,212.5c-26.8,0-49.2-2.8-66.6-8.4 c-5.3-14.6-5.5-31.4-5.5-36.5c19,5.4,44.2,6.6,74.8,6.6c46.3,0,91.3-7.8,99.7-9.1c-0.3,2.1-1.4,9-1.5,10.4 c-1.1,1.3-4.4,4.5-5.5,5.3c-3.1,2.1-2.1,2.4-5.4,7.1c0,0-2.7,5.1-3.2,6.4c-4.8,12.1-6.1,9.6-18.8,13.3 C246.2,210.8,223.3,212.5,202.4,212.5z"/> </g> <g display="inline"> <path fill="none" stroke="#000000" stroke-miterlimit="10" d="M283.6,203.5c0,0,17-24.4,14.9-37.3"/> <g opacity="0.91"> <path d="M133.9,168.6c4,4.6,8,9.1,12.2,13.4c1,1.1,2.1,2.2,3.1,3.2l1.6,1.7l1.7,1.6c2.2,2.1,4.6,4,6.9,5.8 c4.8,3.8,9.8,7.1,14.9,10.2c5.2,3,10.6,5.6,16.4,7.7l0,0l0,0c-5.8-1.7-11.5-4.1-16.7-7.1c-5.2-3.1-10.1-6.7-14.8-10.5 c-2.3-2-4.6-4-6.8-6c-1.1-1-2.3-2-3.3-3c-1.1-1-2.2-2.1-3.3-3.1c-2.2-2.1-4.2-4.4-6.1-6.7C137.5,173.5,135.6,171.1,133.9,168.6 L133.9,168.6L133.9,168.6z"/> </g> <g opacity="0.91"> <path d="M201.4,212.6c3.6-0.5,7.2-1.8,10.6-3.1c3.4-1.4,6.9-2.8,10.2-4.3c3.4-1.5,6.8-3,10.1-4.7s6.6-3.5,9.7-5.4 c6.4-3.8,12.6-7.7,18.8-11.9c3-2.1,6-4.3,9-6.6c2.9-2.3,5.7-4.7,8.1-7.5c0,0,0,0,0.1,0c0,0,0,0,0,0.1c-2.2,3-5,5.5-7.8,7.9 s-5.8,4.6-8.9,6.8c-6.1,4.3-12.5,8-19.1,11.6l-9.8,5.2c-3.3,1.7-6.6,3.4-9.9,5.1c-3.3,1.6-6.8,3-10.3,4.3 C208.7,211.2,205,212.4,201.4,212.6L201.4,212.6L201.4,212.6z"/> </g> <path opacity="0.14"  enable-background="new " d="M278.4,169.7 c0,0-25.9,38-71.8,42.3C206.6,211.9,252.6,193.4,278.4,169.7z"/> <path opacity="0.14"  enable-background="new " d="M297.3,166.3c0,0,5,10-14.5,37.2 C282.8,203.5,293.4,184.2,297.3,166.3z"/> <path opacity="0.14"  enable-background="new " d="M133.6,169 c0,0,12.5,34.7,54.9,42.9C188.6,212.1,155.2,197,133.6,169z"/> <polygon opacity="0.18"  enable-background="new " points="298.4,166.6 295.8,181.6 303.6,175.7 304.9,165.1 "/> <path opacity="0.2"  stroke="#000000" stroke-miterlimit="10" enable-background="new " d=" M131.2,168.4c0,0,55.6,17.3,172.7-3.2C308.7,166.4,183.7,189.6,131.2,168.4z"/> </g> <g display="inline"> <g> <path  fill="#',
                        colorTomoe,
                        '" d="M202.3,199.8c0,0-0.6,5.1-8.1,8.1c0,0,2.5-2.3,2.9-5.2"/> <path  fill="#',
                        colorTomoe,
                        '" d="M202.3,200.1c0.8-2.3-0.4-4.7-2.7-5.4 c-2.3-0.8-4.7,0.4-5.4,2.7c-0.8,2.3,0.4,4.7,2.7,5.4C199,203.5,201.4,202.4,202.3,200.1z M196.7,198.2c0.3-0.8,1-1.1,1.8-0.9 c0.8,0.3,1.1,1,0.9,1.8c-0.3,0.8-1,1.1-1.8,0.9C196.9,199.9,196.5,199,196.7,198.2z"/> </g>'
                    ),
                    abi.encodePacked(
                        '<g> <path  fill="#',
                        colorTomoe,
                        '" d="M205.4,183.2c0,0,4.8-1.9,11,3.2c0,0-3.2-1.1-5.9-0.1"/> <path  fill="#',
                        colorTomoe,
                        '" d="M205.5,183.1c-2.4,0.4-4,2.7-3.4,5c0.4,2.4,2.7,4,5,3.4 c2.4-0.4,4-2.7,3.4-5C210.2,184.2,207.9,182.7,205.5,183.1z M206.6,188.8c-0.8,0.1-1.5-0.4-1.7-1.1c-0.1-0.8,0.4-1.5,1.1-1.7 c0.8-0.1,1.5,0.4,1.7,1.1S207.3,188.6,206.6,188.8z"/> </g> <g> <path  fill="#',
                        colorTomoe,
                        '" d="M187.5,190.7c0,0-4.4-2.6-4.3-10.7c0,0,1,3.2,3.5,4.7"/> <path  fill="#',
                        colorTomoe,
                        '" d="M187.3,190.6c1.8,1.7,4.5,1.5,6-0.3c1.7-1.8,1.5-4.5-0.3-6 c-1.8-1.7-4.5-1.5-6,0.3C185.4,186.3,185.4,188.9,187.3,190.6z M191.2,186.2c0.6,0.6,0.6,1.4,0.1,2c-0.6,0.6-1.4,0.6-2,0.1 c-0.6-0.6-0.6-1.4-0.1-2C189.6,185.8,190.4,185.8,191.2,186.2z"/> </g> </g>'
                    )
                )
            );
    }

    function horn(string memory color) private pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<g><path d="M199.5,130.4c-6.8-.1-13.1-6.5-15-15.2,1.5-25.1,9.6-74.1,12.4-90.7,1.5,30.2,18.4,88.63,19.5,92.33-4.2,10.6-10,13.67-16.9,13.57Z" transform="translate(0 0.5)" fill="#',
                    color,
                    '"/> <path d="M196.6,28.9c2.7,30.6,17.1,83.43,18.6,88.13-4.2,10.4-9.2,13-15.8,12.87s-12.6-6.3-14.5-14.7c1.6-23.3,8.6-66.7,11.7-86.3m.7-10.2S186,85.75,184.19,116.45c1.9,8.9,8.11,14.15,15.31,14.35,6.1.1,12.1-1.57,16.9-14,0,.1-19.9-68.83-19.1-98.13Z" transform="translate(0 0.5)"/> <path d="M185.38,115.74s1.09,14.54,12.58,15c10.49.43,13.21-4.4,16.69-13.85" transform="translate(0 0.5)" fill="#',
                    color,
                    '" stroke="#',
                    color,
                    '" stroke-linecap="round" stroke-miterlimit="10" /></g>'
                )
            );
    }

    function strap(string memory color) private pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<g><path id="Classic" d="M174.76,306.81s22.1,16.3,86.9.5c0,0-.5-15.3,4.6-47.1l16.5-21.3s-46-28.7-83.5-38.3c-1.1-.3-3.1-.7-4.2-.2-19.9,8.4-54.1,34.8-54.1,34.8s9,20.8,10.8,23.4c1.4,2,23.1,18.5,23.1,18.5s.7.2.7.3C175.76,278.61,177.06,286.71,174.76,306.81Z" transform="translate(0 0.5)" fill="#',
                    color,
                    '" stroke="#000" stroke-miterlimit="10"/><path d="M199.5,231.6l-8.2-3.6a.71.71,0,0,1-.2-1.1l3.3-3.4a1.53,1.53,0,0,1,1.6-.3l13.2,4.8a.75.75,0,0,1-.1,1.4l-9.1,2.5C199.8,231.7,199.5,231.7,199.5,231.6Zm-24,46.6s26.5,36.4,43.2,32,43.7-21.8,43.7-21.8c1.3-9.1,2.2-19.7,3.3-28.7-4.8,4.9-13.3,13.8-21.8,19.1-5.2,3.2-22.1,15.1-36.4,16.7C200,296.3,175.5,278.2,175.5,278.2Z" transform="translate(0 0.5)" opacity="0.21" style="isolation: isolate"/> <path d="M142.2,237.5c35.7-22.7,64-30.2,98.5-21.1m30.6,36.9c-21.9-16.9-64.5-38-78.5-32.4-13.3,7.4-37,18-46.8,25.3m88-15.4c-33.8,2.6-57.2.1-84.7,23.6m115.5,7.2c-20.5-14.5-48.7-25.1-73.9-27m23,3.8c-19.3,2-43.6,11.7-59.1,22.8m106.1,4.2c-47.9-12.4-52.5-26.6-98,2.8m69.2-11.5c-20.7.3-43.9,9.9-63.3,16.4m72.4,7.2c-11.5-4.1-40.1-14.8-52.5-14.2m28.3,6c-10.7-2.9-24,7.9-32,13.1m39.3,4.8c-4-5.7-23-7.4-28.1-11.9M175.5,302c4.3,3.8,21.4,7.3,39.5,7.2,18.5-.1,38.1-4,46.6-8.6M176.4,294c11.6,3.8,18.2,7.3,38.1,5.9,15.1-1,34.3-4,47.8-10.7m-38.25.63c9.4,0,29.85-4.63,38.65-7.53m-21.8-2c3.4.4,20-5.4,23.6-6.8m-47-60.8a141,141,0,0,0-19.8-3.2c-5-.3-15.5-.2-20.6.6" transform="translate(0 0.5)" fill="none" stroke="#000" stroke-miterlimit="10"/> </g>'
                )
            );
    }

    /// @notice Return the skin name of the given id
    /// @param id The skin Id
    function getItemNameById(uint8 id) public pure returns (string memory name) {
        name = "";
        if (id == 1) {
            name = "None";
        } else if (id == 2) {
            name = "Uni Horn Blood";
        } else if (id == 3) {
            name = "Power Sticks";
        } else if (id == 4) {
            name = "Uni Horn Moon";
        } else if (id == 5) {
            name = "Power Neck";
        } else if (id == 6) {
            name = "Bouc";
        } else if (id == 7) {
            name = "BlindFold Tomoe Blood";
        } else if (id == 8) {
            name = "Strap Blood";
        } else if (id == 9) {
            name = "Sun Glasses";
        } else if (id == 10) {
            name = "Uni Horn Pure";
        } else if (id == 11) {
            name = "Strap Moon";
        } else if (id == 12) {
            name = "BlindFold Tomoe Moon";
        } else if (id == 13) {
            name = "Stitch";
        } else if (id == 14) {
            name = "Strap Pure";
        } else if (id == 15) {
            name = "Eye Patch";
        } else if (id == 16) {
            name = "Eye";
        } else if (id == 17) {
            name = "Nihon";
        } else if (id == 18) {
            name = "BlindFold Tomoe Pure";
        } else if (id == 19) {
            name = "Power Sticks Pure";
        } else if (id == 20) {
            name = "???";
        }
    }

    /// @dev The base SVG for the body
    function base(string memory children, string memory name) private pure returns (string memory) {
        return string(abi.encodePacked('<g id="mask"><g id="', name, '">', children, "</g></g>"));
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

import "base64-sol/base64.sol";

/// @title Eyes SVG generator
library EyesParts1 {
    /// @dev Eyes N°23 => Moon Gold
    function item_1() public pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    eyes,
                    '<linearGradient id="Moon Aka" gradientUnits="userSpaceOnUse" x1="234.5972" y1="-460.8015" x2="246.3069" y2="-460.8015" gradientTransform="matrix(1 0 0 -1 0 -270)" ><stop offset="0" style="stop-color:#FFB451" /><stop offset="0.5259" style="stop-color:#F7EC94" /><stop offset="1" style="stop-color:#FF9121" /></linearGradient><path id="Moon Aka" display="inline" fill="url(#Moon_Aka_00000152984819707226930020000004625877956111571090_)" d="M246.3,190.5c0.1-2-0.9-3.8-2.4-4.9c0.7,0.8,1.3,1.9,1.1,3.1c-0.1,2.5-2.2,4.4-4.7,4.4c-2.6-0.1-4.6-2.1-4.5-4.6c0-1.1,0.5-2.3,1.4-3c-1.6,1-2.6,2.8-2.6,4.7c-0.1,3.2,2.5,5.9,5.7,5.9C243.6,196.2,246.2,193.7,246.3,190.5z"  /><linearGradient id="Moon Aka" gradientUnits="userSpaceOnUse" x1="157.8972" y1="-461.0056" x2="169.6069" y2="-461.0056" gradientTransform="matrix(1 0 0 -1 0 -270)" ><stop offset="0" style="stop-color:#FFB451" /><stop offset="0.5259" style="stop-color:#F7EC94" /><stop offset="1" style="stop-color:#FF9121" /></linearGradient><path id="Moon Aka" display="inline" fill="url(#Moon_Aka_00000178206716264067794300000007095126762428803473_)" d="M169.6,190.7c0.1-2-0.9-3.8-2.4-4.9c0.7,0.8,1.3,1.9,1.1,3.1c-0.1,2.5-2.2,4.4-4.7,4.4s-4.6-2.1-4.5-4.6c0-1.1,0.5-2.3,1.4-3c-1.6,1-2.6,2.8-2.6,4.7c-0.1,3.2,2.5,5.9,5.7,5.9C166.8,196.5,169.5,194,169.6,190.7z"  />'
                )
            );
    }

    /// @dev Eyes N°21 => Pupils White-Red
    function item_2() public pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    eyes,
                    '<ellipse display="inline" fill="#FFEDED" cx="239.1" cy="189.9" rx="5.7" ry="7.3"  /><ellipse display="inline" fill="#B50D5E" cx="164.4" cy="190.2" rx="5.7" ry="7.3"  />'
                )
            );
    }

    /// @dev Eyes N°20 => Tomoe White
    function item_3() public pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    eyes,
                    '<g display="inline" ><g><path  fill="#FFDAEA" d="M241.3,193.3c0,0-0.3,2-3.2,3.2c0,0,1-0.9,1.1-2.1" /><path  fill="#FFDAEA" d="M241.3,193.4c0.3-0.9-0.2-1.9-1-2.2c-0.9-0.3-1.9,0.2-2.2,1c-0.3,0.9,0.2,1.9,1,2.2C239.9,194.8,241,194.3,241.3,193.4z M239.1,192.7c0.1-0.3,0.4-0.4,0.7-0.4c0.3,0.1,0.4,0.4,0.4,0.7c-0.1,0.3-0.4,0.4-0.7,0.4C239.1,193.3,239.1,193,239.1,192.7z" /></g><g><path  fill="#FFDAEA" d="M242.5,186.6c0,0,1.9-0.7,4.4,1.3c0,0-1.3-0.4-2.4,0" /><path  fill="#FFDAEA" d="M242.5,186.6c-0.9,0.1-1.6,1-1.4,2c0.1,0.9,1,1.6,2,1.4c0.9-0.1,1.6-1,1.4-2C244.4,187.1,243.6,186.4,242.5,186.6z M243.1,188.9c-0.3,0-0.6-0.1-0.6-0.4c0-0.3,0.1-0.6,0.4-0.6s0.6,0.1,0.6,0.4C243.6,188.5,243.3,188.8,243.1,188.9z" /></g><g><path  fill="#FFDAEA" d="M235.5,189.7c0,0-1.8-1-1.7-4.3c0,0,0.4,1.3,1.5,1.9" /><path  fill="#FFDAEA" d="M235.2,189.7c0.7,0.6,1.8,0.6,2.4-0.1c0.6-0.7,0.6-1.8-0.1-2.4c-0.7-0.6-1.8-0.6-2.4,0.1C234.6,187.9,234.6,188.9,235.2,189.7z M236.8,187.9c0.2,0.2,0.2,0.5,0.1,0.8c-0.2,0.2-0.5,0.2-0.8,0.1c-0.2-0.2-0.2-0.5-0.1-0.8C236.3,187.7,236.7,187.7,236.8,187.9z" /></g></g><g display="inline" ><g><path  fill="#FFDAEA" d="M165.4,193.3c0,0-0.3,2-3.2,3.2c0,0,1-0.9,1.1-2.1" /><path  fill="#FFDAEA" d="M165.4,193.4c0.3-0.9-0.2-1.9-1-2.2c-0.9-0.3-1.9,0.2-2.2,1c-0.3,0.9,0.2,1.9,1,2.2C164.1,194.8,165.1,194.4,165.4,193.4z M163.3,192.7c0.1-0.3,0.4-0.4,0.7-0.4c0.3,0.1,0.4,0.4,0.4,0.7c-0.1,0.3-0.4,0.4-0.7,0.4C163.3,193.3,163.1,193,163.3,192.7z" /></g><g><path  fill="#FFDAEA" d="M166.7,186.7c0,0,1.9-0.7,4.4,1.3c0,0-1.3-0.4-2.4,0" /><path  fill="#FFDAEA" d="M166.7,186.6c-0.9,0.1-1.6,1-1.4,2c0.1,0.9,1,1.6,2,1.4c0.9-0.1,1.6-1,1.4-2C168.4,187.1,167.7,186.5,166.7,186.6z M167.2,188.9c-0.3,0-0.6-0.1-0.6-0.4c0-0.3,0.1-0.6,0.4-0.6c0.3,0,0.6,0.1,0.6,0.4C167.7,188.6,167.5,188.8,167.2,188.9z" /></g><g><path  fill="#FFDAEA" d="M159.6,189.7c0,0-1.8-1-1.7-4.3c0,0,0.4,1.3,1.5,1.9" /><path  fill="#FFDAEA" d="M159.4,189.7c0.7,0.6,1.8,0.6,2.4-0.1c0.6-0.7,0.6-1.8-0.1-2.4c-0.7-0.6-1.8-0.6-2.4,0.1S158.7,189,159.4,189.7z M160.9,187.9c0.2,0.2,0.2,0.5,0.1,0.8c-0.2,0.2-0.5,0.2-0.8,0.1c-0.2-0.2-0.2-0.5-0.1-0.8C160.4,187.8,160.7,187.8,160.9,187.9z" /></g></g>'
                )
            );
    }

    /// @dev Eyes N°18 => Tomoe Red
    function item_4() public pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    eyes,
                    '<g display="inline" ><g><path  fill="#E31466" d="M241.3,193.3c0,0-0.3,2-3.2,3.2c0,0,1-0.9,1.1-2.1" /><path  fill="#E31466" d="M241.3,193.4c0.3-0.9-0.2-1.9-1-2.2c-0.9-0.3-1.9,0.2-2.2,1c-0.3,0.9,0.2,1.9,1,2.2C239.9,194.8,241,194.3,241.3,193.4z M239.1,192.7c0.1-0.3,0.4-0.4,0.7-0.4c0.3,0.1,0.4,0.4,0.4,0.7c-0.1,0.3-0.4,0.4-0.7,0.4C239.1,193.3,239.1,193,239.1,192.7z" /></g><g><path  fill="#E31466" d="M242.5,186.6c0,0,1.9-0.7,4.4,1.3c0,0-1.3-0.4-2.4,0" /><path  fill="#E31466" d="M242.5,186.6c-0.9,0.1-1.6,1-1.4,2c0.1,0.9,1,1.6,2,1.4c0.9-0.1,1.6-1,1.4-2C244.4,187.1,243.6,186.4,242.5,186.6z M243.1,188.9c-0.3,0-0.6-0.1-0.6-0.4c0-0.3,0.1-0.6,0.4-0.6s0.6,0.1,0.6,0.4C243.6,188.5,243.3,188.8,243.1,188.9z" /></g><g><path  fill="#E31466" d="M235.5,189.7c0,0-1.8-1-1.7-4.3c0,0,0.4,1.3,1.5,1.9" /><path  fill="#E31466" d="M235.2,189.7c0.7,0.6,1.8,0.6,2.4-0.1c0.6-0.7,0.6-1.8-0.1-2.4c-0.7-0.6-1.8-0.6-2.4,0.1C234.6,187.9,234.6,188.9,235.2,189.7z M236.8,187.9c0.2,0.2,0.2,0.5,0.1,0.8c-0.2,0.2-0.5,0.2-0.8,0.1c-0.2-0.2-0.2-0.5-0.1-0.8C236.3,187.7,236.7,187.7,236.8,187.9z" /></g></g><g display="inline" ><g><path  fill="#E31466" d="M165.4,193.3c0,0-0.3,2-3.2,3.2c0,0,1-0.9,1.1-2.1" /><path  fill="#E31466" d="M165.4,193.4c0.3-0.9-0.2-1.9-1-2.2c-0.9-0.3-1.9,0.2-2.2,1c-0.3,0.9,0.2,1.9,1,2.2C164.1,194.8,165.1,194.4,165.4,193.4z M163.3,192.7c0.1-0.3,0.4-0.4,0.7-0.4c0.3,0.1,0.4,0.4,0.4,0.7c-0.1,0.3-0.4,0.4-0.7,0.4C163.3,193.3,163.1,193,163.3,192.7z" /></g><g><path  fill="#E31466" d="M166.7,186.7c0,0,1.9-0.7,4.4,1.3c0,0-1.3-0.4-2.4,0" /><path  fill="#E31466" d="M166.7,186.6c-0.9,0.1-1.6,1-1.4,2c0.1,0.9,1,1.6,2,1.4c0.9-0.1,1.6-1,1.4-2C168.4,187.1,167.7,186.5,166.7,186.6z M167.2,188.9c-0.3,0-0.6-0.1-0.6-0.4c0-0.3,0.1-0.6,0.4-0.6c0.3,0,0.6,0.1,0.6,0.4C167.7,188.6,167.5,188.8,167.2,188.9z" /></g><g><path  fill="#E31466" d="M159.6,189.7c0,0-1.8-1-1.7-4.3c0,0,0.4,1.3,1.5,1.9" /><path  fill="#E31466" d="M159.4,189.7c0.7,0.6,1.8,0.6,2.4-0.1c0.6-0.7,0.6-1.8-0.1-2.4c-0.7-0.6-1.8-0.6-2.4,0.1S158.7,189,159.4,189.7z M160.9,187.9c0.2,0.2,0.2,0.5,0.1,0.8c-0.2,0.2-0.5,0.2-0.8,0.1c-0.2-0.2-0.2-0.5-0.1-0.8C160.4,187.8,160.7,187.8,160.9,187.9z" /></g></g>'
                )
            );
    }

    /// @dev Eyes N°16 => Shine
    function item_5() public pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    eyes,
                    '<path display="inline" fill="#FFFFFF" stroke="#000000" stroke-width="0.5" stroke-miterlimit="10" d="M164.1,182.5c1.4,7,1.4,6.9,8.3,8.3c-7,1.4-6.9,1.4-8.3,8.3c-1.4-7-1.4-6.9-8.3-8.3C162.8,189.4,162.7,189.5,164.1,182.5z"  /><path display="inline" fill="#FFFFFF" stroke="#000000" stroke-width="0.5" stroke-miterlimit="10" d="M238.7,182.3c1.4,7,1.4,6.9,8.3,8.3c-7,1.4-6.9,1.4-8.3,8.3c-1.4-7-1.4-6.9-8.3-8.3C237.4,189.2,237.3,189.2,238.7,182.3z"  />'
                )
            );
    }

    /// @dev Eyes N°12 => Stitch Eyes
    function item_6() public pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    eyes,
                    '<g id="Strip"> <path d="M231.3,188.2s1-3.2,2.6-.9a30.48,30.48,0,0,1-.6,9.2s-.9,2-1.5-.5C231.3,193.3,232.3,193,231.3,188.2Z" transform="translate(-0.4)" fill="#fff" stroke="#000" stroke-miterlimit="10" stroke-width="0.75"/> <path d="M239.4,187.7s1-3.1,2.5-.9a28.56,28.56,0,0,1-.6,8.9s-.9,1.9-1.4-.5S240.5,192.4,239.4,187.7Z" transform="translate(-0.4)" fill="#fff" stroke="#000" stroke-miterlimit="10" stroke-width="0.75"/> <path d="M245.9,187.7s.9-2.7,2.2-.8a26.25,26.25,0,0,1-.5,7.7s-.8,1.7-1.1-.4S246.9,191.8,245.9,187.7Z" transform="translate(-0.4)" fill="#fff" stroke="#000" stroke-miterlimit="10" stroke-width="0.75"/> <path d="M251.4,187.4s.8-2.4,2-.7a21.16,21.16,0,0,1-.5,6.9s-.7,1.5-1-.4C251.4,191.2,252.1,191,251.4,187.4Z" transform="translate(-0.4)" fill="#fff" stroke="#000" stroke-miterlimit="10" stroke-width="0.75"/> </g> <g id="Strip-2" > <path d="M173.2,187.9s-1-3.1-2.5-.9a27.9,27.9,0,0,0,.6,8.8s.9,1.9,1.4-.5S172.2,192.5,173.2,187.9Z" transform="translate(-0.4)" fill="#fff" stroke="#000" stroke-miterlimit="10" stroke-width="0.75"/> <path d="M165.4,187.7s-1-3.1-2.5-.9a28.56,28.56,0,0,0,.6,8.9s.9,1.9,1.4-.5S164.4,192.4,165.4,187.7Z" transform="translate(-0.4)" fill="#fff" stroke="#000" stroke-miterlimit="10" stroke-width="0.75"/> <path d="M158.9,187.7s-.9-2.7-2.2-.8a26.25,26.25,0,0,0,.5,7.7s.8,1.7,1.1-.4C158.9,192,158.1,191.8,158.9,187.7Z" transform="translate(-0.4)" fill="#fff" stroke="#000" stroke-miterlimit="10" stroke-width="0.75"/> <path d="M153.4,187.4s-.8-2.4-2-.7a21.16,21.16,0,0,0,.5,6.9s.7,1.5,1-.4C153.4,191.2,152.6,191,153.4,187.4Z" transform="translate(-0.4)" fill="#fff" stroke="#000" stroke-miterlimit="10" stroke-width="0.75"/> </g>'
                )
            );
    }

    /// @dev Eyes N°11 => Globes
    function item_7() public pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    eyes,
                    '<ellipse fill="#FFFFFF" cx="244.6" cy="184.5" rx="4.1" ry="0.9"  /><ellipse fill="#FFFFFF" cx="154.6" cy="184.5" rx="4.1" ry="0.9"  />'
                )
            );
    }

    /// @dev Eyes N°8 => Akuma Eye
    function item_8() public pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    eyes,
                    '<path display="inline" fill="#FFFFFF" d="M246.5,192h-13c-0.7,0-1.3-0.5-1.3-1.3l0,0c0-0.7,0.5-1.3,1.3-1.3h13c0.7,0,1.3,0.5,1.3,1.3l0,0C247.8,191.3,247.1,192,246.5,192z"  /><path display="inline" fill="#FFFFFF" d="M169.9,192h-13c-0.7,0-1.3-0.5-1.3-1.3l0,0c0-0.7,0.5-1.3,1.3-1.3h13c0.7,0,1.3,0.5,1.3,1.3l0,0C171.1,191.3,170.5,192,169.9,192z"  />'
                )
            );
    }

    /// @dev Eyes N°19 => Pupils Kuro
    function item_9() public pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    eyes,
                    '<ellipse display="inline" cx="239.1" cy="189.9" rx="5.7" ry="7.3"  /><ellipse display="inline" cx="164.4" cy="190.2" rx="5.7" ry="7.3"  />'
                )
            );
    }

    /// @dev Eyes N°4 => Spiral
    function item_10() public pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    eyes,
                    '<g display="inline" ><path fill="#FFFFFF" d="M238.1,191.2c0.2-0.8,0.6-1.8,1.4-2.4c0.4-0.3,0.9-0.5,1.4-0.4s0.9,0.4,1.3,0.8c0.5,0.8,0.6,1.9,0.6,2.8c0,0.9-0.4,2-1.1,2.7s-1.8,1.1-2.8,1s-1.9-0.7-2.6-1.3c-0.7-0.5-1.5-1.3-2-2.1s-0.8-1.9-0.7-2.9s0.5-2,1.1-2.7s1.5-1.4,2.3-1.8c1.8-0.8,3.8-1,5.5-0.6c0.9,0.2,1.9,0.5,2.6,1.1c0.7,0.6,1.3,1.6,1.4,2.5c0.3,1.9-0.3,3.9-1.5,5.1c1-1.5,1.5-3.3,1-5c-0.2-0.8-0.6-1.6-1.4-2.1c-0.6-0.5-1.5-0.8-2.3-0.9c-1.7-0.2-3.5,0-5,0.7s-2.8,2.1-2.9,3.6c-0.2,1.6,0.9,3.1,2.3,4.2c0.7,0.5,1.4,1,2.2,1.1c0.7,0.1,1.6-0.2,2.2-0.7s0.9-1.4,1-2.2s0-1.8-0.4-2.4c-0.2-0.3-0.5-0.6-0.8-0.7c-0.4-0.1-0.8,0-1.1,0.2C238.9,189.6,238.4,190.4,238.1,191.2z" /></g><g display="inline" ><path fill="#FFFFFF" d="M161.7,189.8c0.7-0.4,1.7-0.8,2.6-0.7c0.4,0,0.9,0.3,1.3,0.7c0.3,0.4,0.3,0.9,0.2,1.5c-0.2,0.9-0.8,1.8-1.6,2.4c-0.7,0.6-1.7,1.1-2.7,1c-1,0-2.1-0.4-2.7-1.3c-0.7-0.8-0.8-1.9-1-2.7c-0.1-0.9-0.1-1.9,0.1-2.9c0.2-0.9,0.7-1.9,1.6-2.5c0.8-0.6,1.8-1,2.8-1c0.9-0.1,2,0.1,2.8,0.4c1.8,0.6,3.3,1.9,4.4,3.4c0.5,0.7,0.9,1.7,1,2.7c0.1,0.9-0.2,2-0.8,2.7c-1.1,1.6-2.9,2.5-4.7,2.6c1.8-0.3,3.4-1.4,4.3-2.8c0.4-0.7,0.6-1.6,0.5-2.4c-0.1-0.8-0.5-1.6-1-2.3c-1-1.4-2.5-2.5-4.1-3s-3.4-0.5-4.7,0.5s-1.6,2.8-1.4,4.5c0.1,0.8,0.2,1.7,0.7,2.3c0.4,0.6,1.3,0.9,2,1c0.8,0,1.6-0.2,2.3-0.8c0.6-0.5,1.3-1.3,1.5-2c0.1-0.4,0.1-0.8-0.1-1.1c-0.2-0.3-0.5-0.6-0.9-0.6C163.3,189.1,162.5,189.4,161.7,189.8z" /></g>'
                )
            );
    }

    /// @dev Eyes N°3 => Pupils Red
    function item_11() public pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    eyes,
                    '<ellipse display="inline" fill="#E31466" cx="239.1" cy="189.9" rx="5.7" ry="7.3"  /><ellipse display="inline" fill="#E31466" cx="164.4" cy="190.2" rx="5.7" ry="7.3"  />'
                )
            );
    }

    /// @dev Eyes N°2 => Moon
    function item_12() public pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    eyes,
                    '<path id="Moon Aka" display="inline" fill="#FFEDED" d="M246.3,190.5c0.1-2-0.9-3.8-2.4-4.9c0.7,0.8,1.3,1.9,1.1,3.1c-0.1,2.5-2.2,4.4-4.7,4.4c-2.6-0.1-4.6-2.1-4.5-4.6c0-1.1,0.5-2.3,1.4-3c-1.6,1-2.6,2.8-2.6,4.7c-0.1,3.2,2.5,5.9,5.7,5.9C243.6,196.2,246.2,193.7,246.3,190.5z"  /><path id="Moon Aka" display="inline" fill="#FFEDED" d="M169.6,190.7c0.1-2-0.9-3.8-2.4-4.9c0.7,0.8,1.3,1.9,1.1,3.1c-0.1,2.5-2.2,4.4-4.7,4.4s-4.6-2.1-4.5-4.6c0-1.1,0.5-2.3,1.4-3c-1.6,1-2.6,2.8-2.6,4.7c-0.1,3.2,2.5,5.9,5.7,5.9C166.8,196.5,169.5,194,169.6,190.7z"  />'
                )
            );
    }

    /// @dev Eyes N°1 => Kitsune Eye
    function item_13() public pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    eyes,
                    '<path display="inline"  fill="#FFFFFF" d="M238.6,181c0,0-4.7,7.9,0,18.7C238.6,199.6,243.2,191.2,238.6,181z"  /><path display="inline"  fill="#FFFFFF" d="M165.3,181c0,0-4.7,7.9,0,18.7C165.3,199.6,169.9,191.2,165.3,181z"  />'
                )
            );
    }

    /// @dev Eyes N°17 => shock
    function item_14() public pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    eyes,
                    '<circle  fill="#FFFFFF" cx="239.5" cy="190.8" r="1.4"/> <circle  fill="#FFFFFF" cx="164.4" cy="191.3" r="1.4"/>'
                )
            );
    }

    /// @dev Eyes N°7 => Pupils Pure
    function item_15() public pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    eyes,
                    '<ellipse display="inline" fill="#FFEDED" cx="239.1" cy="189.9" rx="5.7" ry="7.3"  /><ellipse display="inline" fill="#FFEDED" cx="164.4" cy="190.2" rx="5.7" ry="7.3"  />'
                )
            );
    }

    string internal constant eyes =
        '<g id="No_Fill"> <g> <path stroke="#000000" stroke-miterlimit="10" d="M219.1,197.3c0,0,3.1-22.5,37.9-15.5C257.1,181.7,261,208.8,219.1,197.3z"/> <g> <path d="M227.3,182.1c-1,0.5-1.9,1.3-2.7,2s-1.6,1.6-2.3,2.3c-0.7,0.8-1.5,1.7-2.1,2.5l-1,1.4c-0.3,0.4-0.6,0.9-1,1.4 c0.2-0.5,0.4-1,0.6-1.6c0.2-0.5,0.5-1,0.8-1.6c0.6-0.9,1.3-2,2.1-2.8s1.7-1.7,2.6-2.3C225,182.7,226.1,182.2,227.3,182.1z"/> </g> <g> <path d="M245.4,200.9c1.3-0.2,2.5-0.5,3.6-1s2.2-1,3.2-1.8c1-0.7,1.9-1.6,2.7-2.5s1.6-2,2.3-3c-0.3,1.3-0.8,2.5-1.7,3.5 c-0.7,1-1.7,2.1-2.8,2.8c-1,0.7-2.3,1.4-3.5,1.7C248,201,246.7,201.2,245.4,200.9z"/> </g> </g> <g> <path stroke="#000000" stroke-miterlimit="10" d="M183.9,197.3c0,0-3.1-22.5-37.9-15.5C146,181.7,142,208.8,183.9,197.3z"/> <g> <path d="M175.8,182.1c1,0.5,1.9,1.3,2.7,2s1.6,1.6,2.3,2.3c0.7,0.8,1.5,1.7,2.1,2.5l1,1.4c0.3,0.4,0.6,0.9,1,1.4 c-0.2-0.5-0.4-1-0.6-1.6c-0.2-0.5-0.5-1-0.8-1.6c-0.6-0.9-1.3-2-2.1-2.8s-1.7-1.7-2.6-2.3 C178.1,182.7,176.9,182.2,175.8,182.1z"/> </g> <g> <path d="M157.6,200.9c-1.3-0.2-2.5-0.5-3.6-1s-2.2-1-3.2-1.8c-1-0.7-1.9-1.6-2.7-2.5s-1.6-2-2.3-3c0.3,1.3,0.8,2.5,1.7,3.5 c0.7,1,1.7,2.1,2.8,2.8c1,0.7,2.3,1.4,3.5,1.7C155,201,156.5,201.2,157.6,200.9z"/> </g> </g> </g> <g id="Shadow" opacity="0.43"> <path opacity="0.5" enable-background="new " d="M218.3,191.6c0,0,4.6-10.8,19.9-13.6c0,0-12.2,0-16.1,2.8 C218.9,183.8,218.3,191.6,218.3,191.6z"/> </g> <g id="Shadow_00000029025467326919416900000002242143269665406345_" opacity="0.43"> <path opacity="0.5" enable-background="new " d="M184.9,191.3c0,0-4.8-10.6-20.1-13.4c0,0,12.4-0.2,16.3,2.6 C184.4,183.6,184.9,191.3,184.9,191.3z"/> </g>';

    //string internal constant eyes = '<g display="inline" ><ellipse  fill="#FFFFFF" cx="235.4" cy="190.9" rx="13.9" ry="16.4" /><path d="M221.3,190.9c0,4,1.1,8.1,3.5,11.4c1.2,1.7,2.8,3.1,4.6,4.1s3.8,1.6,5.9,1.6s4.1-0.6,5.8-1.7c1.8-1,3.3-2.4,4.6-4c2.4-3.2,3.7-7.2,3.8-11.2s-1.1-8.2-3.6-11.5c-1.2-1.7-2.9-3-4.7-4s-3.8-1.6-5.9-1.6s-4.2,0.5-5.9,1.6c-1.8,1-3.3,2.4-4.6,4.1C222.3,182.9,221.3,186.8,221.3,190.9z M221.4,190.9c0-2,0.3-4,1-5.8c0.6-1.9,1.7-3.5,2.9-5.1c2.4-3,6-5,10-5c3.9,0,7.4,2,9.9,5.1c2.4,3,3.6,6.9,3.7,10.8c0.1,3.8-1.1,8-3.5,11c-2.4,3.1-6.2,5.1-10.1,5c-3.8,0-7.5-2.1-10-5.1C223,198.8,221.4,194.8,221.4,190.9z" /></g><g display="inline" ><ellipse  fill="#FFFFFF" cx="165.8" cy="191.2" rx="13.9" ry="16.4" /><path d="M179.5,191.2c0,4-1.1,8.1-3.5,11.4c-1.2,1.7-2.8,3.1-4.6,4.1s-3.8,1.6-5.9,1.6c-2.1,0-4.1-0.6-5.8-1.7c-1.8-1-3.3-2.4-4.6-4c-2.4-3.2-3.7-7.2-3.8-11.2s1.1-8.2,3.6-11.5c1.2-1.7,2.9-3,4.7-4s3.8-1.6,5.9-1.6c2.1,0,4.2,0.5,5.9,1.6c1.8,1,3.3,2.4,4.6,4.1C178.5,183.2,179.5,187.2,179.5,191.2z M179.5,191.2c0-2-0.3-4-1-5.8c-0.6-1.9-1.7-3.5-2.9-5.1c-2.4-3-6-5-10-5c-3.9,0-7.4,2-9.9,5.1c-2.4,3-3.6,6.9-3.7,10.8c-0.1,3.8,1.1,8,3.5,11c2.4,3.1,6.2,5.1,10.1,5c3.8,0,7.5-2.1,10-5.1C178.3,199.2,179.5,195.1,179.5,191.2z" /></g>';
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

pragma abicoder v2;

import "base64-sol/base64.sol";

/// @title Eyes SVG generator
library EyesParts2 {
    /// @dev Eyes N°22 => Dubu
    function item_1() public pure returns (string memory) {
        return
            '<g> <path d="M243.2,185.8c-2.2-1.3-4.6-2.3-7-2.8c-1.2-0.3-2.4-0.4-3.6-0.4c-1.2,0-2.4,0.1-3.2,0.6c-0.4,0.2-0.5,0.5-0.5,0.9 c0,0.5,0.3,1,0.6,1.5c0.7,1,1.6,1.9,2.6,2.7c2,1.6,4.3,2.7,6.7,3.8l3.4,1.5l-3.7-0.4c-2.5-0.3-5-0.5-7.3-0.4 c-0.6,0.1-1.1,0.2-1.6,0.3c-0.4,0.2-0.7,0.4-0.7,0.5s0,0.5,0.3,0.9s0.6,0.8,1.1,1.2c1.7,1.5,3.9,2.7,6.1,3.4 c2.3,0.7,4.8,0.9,7-0.2h0.1v0.1c-0.9,0.9-2.2,1.4-3.5,1.7c-1.3,0.2-2.7,0.2-4-0.1c-2.6-0.5-5.1-1.6-7.2-3.3c-0.5-0.4-1-1-1.4-1.6 l-0.3-0.5c-0.1-0.2-0.2-0.4-0.2-0.6c-0.1-0.4-0.2-1,0-1.5c0.1-0.3,0.2-0.5,0.4-0.7c0.1-0.2,0.3-0.4,0.5-0.5 c0.2-0.2,0.4-0.2,0.6-0.3c0.2-0.1,0.4-0.2,0.6-0.2c0.7-0.2,1.4-0.3,2.1-0.3c2.7-0.1,5.2,0.5,7.7,1.1l-0.4,1.1l-1.7-1 c-0.6-0.3-1.1-0.7-1.6-1.1l-1.6-1.1c-0.5-0.4-1.1-0.7-1.6-1.1c-1.1-0.8-2.1-1.6-3-2.6c-0.4-0.5-0.9-1.1-1.1-2 c-0.1-0.4-0.1-0.9,0.1-1.3c0.2-0.4,0.5-0.8,0.8-1.1c1.4-1,2.9-1.1,4.2-1.1c1.4,0,2.7,0.3,4,0.7c2.6,0.8,4.9,2.2,6.7,4.1v0.1 C243.3,185.8,243.3,185.8,243.2,185.8z"/> </g> <g> <path d="M171.1,185.8c-2.2-1.3-4.6-2.3-7-2.8c-1.2-0.3-2.4-0.4-3.6-0.4c-1.2,0-2.4,0.1-3.2,0.6c-0.4,0.2-0.5,0.5-0.5,0.9 c0,0.5,0.3,1,0.6,1.5c0.7,1,1.6,1.9,2.6,2.7c2,1.6,4.3,2.7,6.7,3.8l3.4,1.5l-3.7-0.4c-2.5-0.3-5-0.5-7.3-0.4 c-0.6,0.1-1.1,0.2-1.6,0.3c-0.4,0.2-0.7,0.4-0.7,0.5s0,0.5,0.3,0.9s0.6,0.8,1.1,1.2c1.7,1.5,4.9,2.7,7.1,3.4 c2.3,0.7,3.8,0.9,6-0.2h0.1v0.1c-0.9,0.9-2.2,1.4-3.5,1.7c-1.3,0.2-2.7,0.2-4-0.1c-2.6-0.5-5.1-1.6-7.2-3.3c-0.5-0.4-1-1-1.4-1.6 l-0.3-0.5c-0.1-0.2-0.2-0.4-0.2-0.6c-0.1-0.4-0.2-1,0-1.5c0.1-0.3,0.2-0.5,0.4-0.7c0.1-0.2,0.3-0.4,0.5-0.5 c0.2-0.2,0.4-0.2,0.6-0.3c0.2-0.1,0.4-0.2,0.6-0.2c0.7-0.2,1.4-0.3,2.1-0.3c2.7-0.1,5.2,0.5,7.7,1.1l-0.4,1.1l-1.7-1 c-0.6-0.3-1.1-0.7-1.6-1.1l-1.6-1.1c-0.5-0.4-1.1-0.7-1.6-1.1c-1.1-0.8-2.1-1.6-3-2.6c-0.4-0.5-0.9-1.1-1.1-2 c-0.1-0.4-0.1-0.9,0.1-1.3c0.2-0.4,0.5-0.8,0.8-1.1c1.4-1,2.9-1.1,4.2-1.1c1.4,0,2.7,0.3,4,0.7c2.6,0.8,4.9,2.2,6.7,4.1v0.1 C171.2,185.8,171.2,185.8,171.1,185.8z"/> </g>';
    }

    /// @dev Eyes N°19 => Stitched
    function item_3() public pure returns (string memory) {
        return
            '<g display="inline" ><g><path d="M223.8,191.2c1.6,0.1,3.1,0.2,4.7,0.2c1.6,0.1,3.1,0.1,4.7,0c3.1,0,6.4-0.1,9.5-0.3c3.1-0.1,6.4-0.4,9.5-0.6l9.5-0.8c-1.6,0.3-3.1,0.5-4.7,0.8c-1.6,0.2-3.1,0.4-4.7,0.6c-3.1,0.4-6.4,0.6-9.5,0.8c-3.1,0.1-6.4,0.2-9.5,0.1C230,192,226.9,191.9,223.8,191.2z" /></g><g id="Strip_00000145047919819781265440000015374262668379115410_"><path fill="#FFFFFF" stroke="#000000" stroke-width="0.75" stroke-miterlimit="10" d="M231.3,188.2c0,0,1-3.2,2.6-0.9c0,0,0.5,4.9-0.6,9.2c0,0-0.9,2-1.5-0.5C231.3,193.3,232.3,193,231.3,188.2z" /><path fill="#FFFFFF" stroke="#000000" stroke-width="0.75" stroke-miterlimit="10" d="M239.4,187.7c0,0,1-3.1,2.5-0.9c0,0,0.5,4.7-0.6,8.9c0,0-0.9,1.9-1.4-0.5C239.4,192.7,240.5,192.4,239.4,187.7z" /><path fill="#FFFFFF" stroke="#000000" stroke-width="0.75" stroke-miterlimit="10" d="M245.9,187.7c0,0,0.9-2.7,2.2-0.8c0,0,0.4,4.1-0.5,7.7c0,0-0.8,1.7-1.1-0.4C246.1,192,246.9,191.8,245.9,187.7z" /><path fill="#FFFFFF" stroke="#000000" stroke-width="0.75" stroke-miterlimit="10" d="M251.4,187.4c0,0,0.8-2.4,2-0.7c0,0,0.4,3.6-0.5,6.9c0,0-0.7,1.5-1-0.4C251.4,191.2,252.1,191,251.4,187.4z" /></g></g><g display="inline" ><g><path d="M145.3,189.9c1.6,0.3,3,0.6,4.6,0.8s3.1,0.4,4.7,0.5c3.1,0.2,6.3,0.3,9.4,0.3s6.3-0.1,9.4-0.3c3.1-0.2,6.3-0.5,9.4-0.7c-1.6,0.3-3.1,0.5-4.7,0.8c-1.6,0.2-3.1,0.4-4.7,0.5c-1.6,0.1-3.1,0.3-4.7,0.3c-1.6,0.1-3.1,0.1-4.7,0.1c-3.1,0-6.3-0.1-9.4-0.5C151.4,191.3,148.2,190.9,145.3,189.9z" /></g><g id="Strip_00000020356765003249034850000016175079805633892000_"><path fill="#FFFFFF" stroke="#000000" stroke-width="0.75" stroke-miterlimit="10" d="M173.2,187.9c0,0-1-3.1-2.5-0.9c0,0-0.5,4.7,0.6,8.8c0,0,0.9,1.9,1.4-0.5C173.1,192.8,172.2,192.5,173.2,187.9z" /><path fill="#FFFFFF" stroke="#000000" stroke-width="0.75" stroke-miterlimit="10" d="M165.4,187.7c0,0-1-3.1-2.5-0.9c0,0-0.5,4.7,0.6,8.9c0,0,0.9,1.9,1.4-0.5C165.4,192.7,164.4,192.4,165.4,187.7z" /><path fill="#FFFFFF" stroke="#000000" stroke-width="0.75" stroke-miterlimit="10" d="M158.9,187.7c0,0-0.9-2.7-2.2-0.8c0,0-0.4,4.1,0.5,7.7c0,0,0.8,1.7,1.1-0.4C158.9,192,158.1,191.8,158.9,187.7z" /><path fill="#FFFFFF" stroke="#000000" stroke-width="0.75" stroke-miterlimit="10" d="M153.4,187.4c0,0-0.8-2.4-2-0.7c0,0-0.4,3.6,0.5,6.9c0,0,0.7,1.5,1-0.4C153.4,191.2,152.6,191,153.4,187.4z" /></g></g>';
    }

    /// @dev Eyes N°15 => Feels
    function item_4() public pure returns (string memory) {
        return
            '<g id="Eye_right"> <path d="M255.4,188.58c.65.72,1.18-.46,1.15.24-.08-.5-1.71,1.54-2.55,1l-.61.58c.45.82,1-.16,1,.44-.07-.51-1.59,1.13-2.44.6a21.79,21.79,0,0,1-11.26,4.05c-7.84.48-15.72-2.74-19.81-8.61,5.52,4,12.3,4.61,19.56,4.1,6.49-.54,12.93-1.09,17.25-5.11A5.22,5.22,0,0,1,255.4,188.58Z" transform="translate(-0.4)"/> <path d="M248.81,196a21.83,21.83,0,0,1-3.53,1.18,23.26,23.26,0,0,1-3.63.58c-1.12.08-2.56.1-3.7.08a14.12,14.12,0,0,1-3.6-.53h0c1.16.12,2.51.2,3.65.22a21.71,21.71,0,0,0,3.61-.07,22.4,22.4,0,0,0,3.64-.48c1.19-.29,2.28-.57,3.56-1Z" transform="translate(-0.4)"/> <path d="M233,197.34c-1-.5-2.25-.86-3.35-1.44a32.25,32.25,0,0,0-3.34-1.43,7,7,0,0,0,1.44.94,5.63,5.63,0,0,0,1.62.72,8.25,8.25,0,0,0,1.71.62A7.49,7.49,0,0,0,233,197.34Z" transform="translate(-0.4)"/> </g> <g id="Eye_left" > <path d="M148.17,188.24c-.64.72-1.18-.46-1.15.24.08-.5,1.71,1.54,2.55,1l.61.58c-.45.82-1-.16-1,.44.08-.51,1.59,1.13,2.44.6a21.79,21.79,0,0,0,11.27,4.05c7.83.48,15.71-2.74,19.8-8.61-5.52,4-12.3,4.61-19.56,4.1-6.49-.54-12.93-1.09-17.25-5.12A5.21,5.21,0,0,0,148.17,188.24Z" transform="translate(-0.4)"/> <path d="M170,197a21.46,21.46,0,0,1-3.67.6,22.49,22.49,0,0,1-3.67,0c-1.12-.1-2.55-.3-3.67-.5a14,14,0,0,1-3.47-1.1h0c1.12.3,2.45.6,3.57.8a21.91,21.91,0,0,0,3.57.5,22.51,22.51,0,0,0,3.67.1c1.23-.1,2.35-.2,3.67-.4Z" transform="translate(-0.4)"/> <path d="M174,195.68c.92-.6,2.14-1.1,3.16-1.8a32.35,32.35,0,0,1,3.16-1.8,6.71,6.71,0,0,1-1.32,1.1,5.62,5.62,0,0,1-1.53.9,8.23,8.23,0,0,1-1.63.8A7,7,0,0,1,174,195.68Z" transform="translate(-0.4)"/> </g>';
    }

    /// @dev Eyes N°14 => Happy
    function item_5() public pure returns (string memory) {
        return
            '<g id="Eye_right" > <path d="M255.4,191.94c.65-.72,1.18.46,1.15-.24-.08.5-1.71-1.54-2.55-1l-.61-.58c.45-.82,1,.16,1-.44-.07.51-1.59-1.13-2.44-.6A21.79,21.79,0,0,0,240.64,185c-7.84-.48-15.72,2.74-19.81,8.61,5.52-4,12.3-4.61,19.56-4.1,6.49.54,12.93,1.09,17.25,5.11A5.22,5.22,0,0,0,255.4,191.94Z" transform="translate(-0.4)"/> <path d="M232.53,181.2a21.63,21.63,0,0,1,3.67-.6,22.49,22.49,0,0,1,3.67,0c1.12.1,2.55.3,3.67.5a14,14,0,0,1,3.47,1.1h0c-1.12-.3-2.45-.6-3.57-.8a21.91,21.91,0,0,0-3.57-.5,22.51,22.51,0,0,0-3.67-.1c-1.22.1-2.35.2-3.67.4Z" transform="translate(-0.4)"/> <path d="M228.55,182.5c-.92.6-2.14,1.1-3.16,1.8a32.35,32.35,0,0,1-3.16,1.8,7,7,0,0,1,1.32-1.1,5.62,5.62,0,0,1,1.53-.9,8.23,8.23,0,0,1,1.63-.8A7,7,0,0,1,228.55,182.5Z" transform="translate(-0.4)"/> </g> <g id="Eye_left" > <path d="M148.17,192.28c-.64-.72-1.18.46-1.15-.24.08.5,1.71-1.54,2.55-1l.61-.58c-.45-.82-1,.16-1-.44.08.51,1.59-1.13,2.44-.6a21.79,21.79,0,0,1,11.27-4c7.83-.48,15.71,2.74,19.8,8.61-5.52-4-12.3-4.61-19.56-4.1-6.49.54-12.93,1.09-17.25,5.11A5.22,5.22,0,0,1,148.17,192.28Z" transform="translate(-0.4)"/> <path d="M171,181.54a21.46,21.46,0,0,0-3.67-.6,22.49,22.49,0,0,0-3.67,0c-1.12.1-2.55.3-3.67.5a14,14,0,0,0-3.47,1.1h0c1.12-.3,2.45-.6,3.57-.8a21.91,21.91,0,0,1,3.57-.5,22.51,22.51,0,0,1,3.67-.1c1.23.1,2.35.2,3.67.4Z" transform="translate(-0.4)"/> <path d="M175,182.84c.92.6,2.14,1.1,3.16,1.8a32.35,32.35,0,0,0,3.16,1.8,6.71,6.71,0,0,0-1.32-1.1,5.62,5.62,0,0,0-1.53-.9,8.23,8.23,0,0,0-1.63-.8A7,7,0,0,0,175,182.84Z" transform="translate(-0.4)"/> </g>';
    }

    /// @dev Eyes N°13 => Closed
    function item_6() public pure returns (string memory) {
        return
            '<g display="inline" ><path d="M219,191.1c1.7-0.5,3.3-0.7,5-0.9s3.3-0.3,5-0.3s3.4,0.3,5.1,0.2c1.7,0,3.4-0.2,5-0.5c1.7-0.3,3.3-0.5,5-0.7s3.4-0.3,5-0.4c3.4-0.1,6.7,0,10.1,0.4c0.1,0,0.1,0.1,0.1,0.1s0,0.1-0.1,0.1c-3.3,0.8-6.7,1.2-10,1.5c-1.7,0.1-3.4,0.1-5,0.1c-1.7,0-3.4,0-5.1-0.1c-1.7-0.1-3.4-0.1-5,0c-1.7,0.1-3.3,0.6-5,0.8s-3.4,0.2-5,0.2c-1.7,0-3.4-0.1-5.1-0.4C218.9,191.3,218.9,191.2,219,191.1C218.9,191.1,219,191.1,219,191.1z" /></g><g display="inline" ><path d="M180.5,191.3c-1.5,0.3-3,0.4-4.5,0.5c-1.5,0-3,0-4.5-0.1c-1.5-0.2-3-0.6-4.5-0.7c-1.5-0.1-3-0.1-4.5,0s-3,0.2-4.5,0.2s-3,0-4.5-0.1c-3-0.2-6-0.6-9-1.3c-0.1,0-0.1-0.1-0.1-0.1s0-0.1,0.1-0.1c3-0.5,6.1-0.6,9.1-0.6c1.5,0,3,0.2,4.5,0.3s3,0.3,4.5,0.6s3,0.4,4.5,0.4s3-0.3,4.5-0.3c1.5-0.1,3,0.1,4.5,0.2c1.5,0.2,3,0.4,4.5,0.9C180.6,191.1,180.6,191.2,180.5,191.3C180.6,191.3,180.5,191.3,180.5,191.3z" /></g>';
    }

    /// @dev Eyes N°10 => Arrow
    function item_7() public pure returns (string memory) {
        return
            '<g display="inline" ><path d="M254.5,182.3c-2.6,1.1-5.2,1.9-7.9,2.7c-2.6,0.8-5.3,1.6-8,2.1c-2.7,0.6-5.5,1-8.2,1.6s-5.3,1.4-8,2.3v-1.1c2.8,0.3,5.6,0.6,8.3,1.2c2.7,0.5,5.5,1.1,8.2,2c2.7,0.8,5.3,1.8,7.9,2.9c2.6,1.1,5.1,2.4,7.4,3.9l-0.1,0.2c-2.7-0.9-5.3-1.8-7.9-2.6c-2.6-0.8-5.3-1.6-7.9-2.4c-2.6-0.8-5.3-1.5-8-2.2l-8.1-1.9h-0.1c-0.3-0.1-0.5-0.4-0.4-0.6c0.1-0.2,0.2-0.4,0.4-0.4c2.7-0.5,5.4-1.1,8.1-1.9c2.7-0.8,5.3-1.7,7.9-2.6c2.6-0.8,5.3-1.4,8-2s5.4-1.1,8.2-1.4L254.5,182.3z" /></g><g display="inline" ><path d="M149.3,182.1c2.8,0.3,5.5,0.8,8.2,1.4c2.7,0.6,5.4,1.2,8,2l3.9,1.3c1.3,0.4,2.6,0.9,4,1.2c2.7,0.8,5.4,1.3,8.1,1.8c0.3,0.1,0.5,0.4,0.5,0.7c0,0.2-0.2,0.4-0.4,0.4h-0.1l-7.8,2c-2.6,0.7-5.1,1.5-7.7,2.2c-2.6,0.7-5.1,1.5-7.6,2.3c-2.6,0.8-5.1,1.7-7.6,2.5l-0.1-0.2c2.3-1.4,4.7-2.7,7.2-3.8s5-2.1,7.6-2.9c2.6-0.8,5.2-1.5,7.9-2c2.6-0.6,5.3-1,8-1.3v1.1c-2.6-0.9-5.3-1.7-8-2.3c-1.3-0.3-2.7-0.6-4.1-0.8l-4.1-0.8c-2.7-0.6-5.4-1.3-8-2.1S151.9,183.1,149.3,182.1L149.3,182.1z" /></g>';
    }

    /// @dev Eyes N°9 => Scribble
    function item_8() public pure returns (string memory) {
        return
            '<polyline display="inline" fill="none" stroke="#000000" stroke-linecap="round" stroke-miterlimit="10" points="225.3,188.1 256.3,188.1 225.3,192.5 254.5,192.5 226.9,196 251.4,196 "  /><polyline display="inline" fill="none" stroke="#000000" stroke-linecap="round" stroke-miterlimit="10" points="148.1,188.1 179,188.1 148.1,192.5 177.3,192.5 149.5,196 174,196 "  />';
    }

    /// @dev Eyes N°6 => Rip
    function item_9() public pure returns (string memory) {
        return
            '<line x1="230.98" y1="182.49" x2="248.68" y2="200.19" fill="none" stroke="#000" stroke-linecap="square" stroke-miterlimit="10" stroke-width="3"/> <line x1="230.47" y1="200.87" x2="248.67" y2="183.17" fill="none" stroke="#000" stroke-linecap="square" stroke-miterlimit="10" stroke-width="3"/> <line x1="155.53" y1="182.66" x2="173.23" y2="200.36" fill="none" stroke="#000" stroke-linecap="square" stroke-miterlimit="10" stroke-width="3"/> <line x1="154" y1="200.7" x2="172.2" y2="183" fill="none" stroke="#000" stroke-linecap="square" stroke-miterlimit="10" stroke-width="3"/>';
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
    string internal constant BLOODY = "E31466";
    string internal constant WHITEITEM = "FFDAEA";
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