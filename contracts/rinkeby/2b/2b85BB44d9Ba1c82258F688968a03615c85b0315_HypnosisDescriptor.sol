// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

pragma abicoder v2;

import "./interfaces/IHypnosisDescriptor.sol";
import "./interfaces/IHypnosis.sol";
import "./libraries/NFTDescriptor.sol";
import "./libraries/DetailHelper.sol";
import "base64-sol/base64.sol";
import "./Hypnosis.sol";

/// @title Describes Onii
/// @notice Produces a string containing the data URI for a JSON metadata string
contract HypnosisDescriptor is IHypnosisDescriptor {
    /// @dev Max value for defining probabilities
    uint256 internal constant MAX = 100000;

    uint256[] internal BACKGROUND_ITEMS = [750, 650, 575, 475, 400, 350, 300, 0];
    uint256[] internal SKIN_ITEMS = [2000, 1000, 0];
    uint256[] internal NOSE_ITEMS = [10, 0];
    uint256[] internal TATOO_ITEMS = [25000, 18000, 12000, 6000, 3000, 1000, 40, 10, 0];
    uint256[] internal EYEBROW_ITEMS = [50000, 20000, 0];
    uint256[] internal EXPRESSION_ITEMS = [25000, 17000, 10000, 6000, 3000, 1000, 0];
    uint256[] internal EARRINGS_ITEMS = [25000, 17000, 10000, 5000, 1000, 100, 30, 0];
    uint256[] internal ACCESSORY_ITEMS = [10000, 3000, 30, 10, 0];
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
        93500,
        87000,
        80500,
        74000,
        67500,
        61000,
        54500,
        48000,
        41500,
        35000,
        28500,
        26500,
        24500,
        22500,
        20500,
        18500,
        16500,
        14500,
        12500,
        10500,
        8500,
        6500,
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

    /// @inheritdoc IHypnosisDescriptor
    function tokenURI(IHypnosis hypnosis, uint256 tokenId) external view override returns (string memory) {
        NFTDescriptor.SVGParams memory params = getSVGParams(hypnosis, tokenId);
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

    /// @inheritdoc IHypnosisDescriptor
    function generateHairId(uint256 tokenId, uint256 seed) external view override returns (uint8) {
        return DetailHelper.generate(MAX, seed, HAIR_ITEMS, this.generateHairId.selector, tokenId);
    }

    /// @inheritdoc IHypnosisDescriptor
    function generateEyeId(uint256 tokenId, uint256 seed) external view override returns (uint8) {
        return DetailHelper.generate(MAX, seed, EYE_ITEMS, this.generateEyeId.selector, tokenId);
    }

    /// @inheritdoc IHypnosisDescriptor
    function generateEyebrowId(uint256 tokenId, uint256 seed) external view override returns (uint8) {
        return DetailHelper.generate(MAX, seed, EYEBROW_ITEMS, this.generateEyebrowId.selector, tokenId);
    }

    /// @inheritdoc IHypnosisDescriptor
    function generateNoseId(uint256 tokenId, uint256 seed) external view override returns (uint8) {
        return DetailHelper.generate(MAX, seed, NOSE_ITEMS, this.generateNoseId.selector, tokenId);
    }

    /// @inheritdoc IHypnosisDescriptor
    function generateMouthId(uint256 tokenId, uint256 seed) external view override returns (uint8) {
        return DetailHelper.generate(MAX, seed, MOUTH_ITEMS, this.generateMouthId.selector, tokenId);
    }

    /// @inheritdoc IHypnosisDescriptor
    function generateTatooId(uint256 tokenId, uint256 seed) external view override returns (uint8) {
        return DetailHelper.generate(MAX, seed, TATOO_ITEMS, this.generateTatooId.selector, tokenId);
    }

    /// @inheritdoc IHypnosisDescriptor
    function generateEarringsId(uint256 tokenId, uint256 seed) external view override returns (uint8) {
        return DetailHelper.generate(MAX, seed, EARRINGS_ITEMS, this.generateEarringsId.selector, tokenId);
    }

    /// @inheritdoc IHypnosisDescriptor
    function generateAccessoryId(uint256 tokenId, uint256 seed) external view override returns (uint8) {
        return DetailHelper.generate(MAX, seed, ACCESSORY_ITEMS, this.generateAccessoryId.selector, tokenId);
    }

    /// @inheritdoc IHypnosisDescriptor
    function generateExpressionId(uint256 tokenId, uint256 seed) external view override returns (uint8) {
        return DetailHelper.generate(MAX, seed, EXPRESSION_ITEMS, this.generateExpressionId.selector, tokenId);
    }

    /// @inheritdoc IHypnosisDescriptor
    function generateSkinId(uint256 tokenId, uint256 seed) external view override returns (uint8) {
        return DetailHelper.generate(MAX, seed, SKIN_ITEMS, this.generateSkinId.selector, tokenId);
    }

    /// @dev Get SVGParams from Hypnosis.Detail
    function getSVGParams(IHypnosis hypnosis, uint256 tokenId) private view returns (NFTDescriptor.SVGParams memory) {
        IHypnosis.Detail memory detail = hypnosis.details(tokenId);
        return
            NFTDescriptor.SVGParams({
                hair: detail.hair,
                eye: detail.eye,
                eyebrow: detail.eyebrow,
                nose: detail.nose,
                mouth: detail.mouth,
                tatoo: detail.tatoo,
                earring: detail.earrings,
                accessory: detail.accessory,
                expression: detail.expression,
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
            itemScoreProba(params.expression, EXPRESSION_ITEMS) +
            itemScorePosition(params.mouth, MOUTH_ITEMS) +
            (itemScoreProba(params.skin, SKIN_ITEMS) / 2) +
            itemScoreProba(params.skin, SKIN_ITEMS) +
            itemScoreProba(params.nose, NOSE_ITEMS) +
            itemScoreProba(params.tatoo, TATOO_ITEMS) +
            itemScorePosition(params.eye, EYE_ITEMS) +
            itemScoreProba(params.eyebrow, EYEBROW_ITEMS);
        return DetailHelper.pickItems(score, BACKGROUND_ITEMS);
    }

    /// @dev Get item score based on his probability
    function itemScoreProba(uint8 item, uint256[] memory ITEMS) private pure returns (uint256) {
        return ((item == 1 ? MAX : ITEMS[item - 2]) - ITEMS[item - 1]) / 1000;
    }

    /// @dev Get item score based on his index
    function itemScorePosition(uint8 item, uint256[] memory ITEMS) private pure returns (uint256) {
        return ITEMS[item - 1] / 1000;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

pragma abicoder v2;

import "./IHypnosis.sol";

/// @title Describes Onii via URI
interface IHypnosisDescriptor {
    /// @notice Produces the URI describing a particular Onii (token id)
    /// @dev Note this URI may be a data: URI with the JSON contents directly inlined
    /// @param hypnosis The hypnosis contract
    /// @param tokenId The ID of the token for which to produce a description
    /// @return The URI of the ERC721-compliant metadata
    function tokenURI(IHypnosis hypnosis, uint256 tokenId) external view returns (string memory);

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

    /// @notice Generate randomly an ID for the tatoo item
    /// @param tokenId the current tokenId
    /// @param seed Used for the initialization of the number generator.
    /// @return the tatoo item id
    function generateTatooId(uint256 tokenId, uint256 seed) external view returns (uint8);

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

    /// @notice Generate randomly an ID for the expression item
    /// @param tokenId the current tokenId
    /// @param seed Used for the initialization of the number generator.
    /// @return the expression item id
    function generateExpressionId(uint256 tokenId, uint256 seed) external view returns (uint8);

    /// @notice Generate randomly the skin colors
    /// @param tokenId the current tokenId
    /// @param seed Used for the initialization of the number generator.
    /// @return the skin item id
    function generateSkinId(uint256 tokenId, uint256 seed) external view returns (uint8);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

pragma abicoder v2;

/// @title Hypnosis NFTs Interface
interface IHypnosis {
    /// @notice Details about the Onii
    struct Detail {
        uint8 hair;
        uint8 eye;
        uint8 eyebrow;
        uint8 nose;
        uint8 mouth;
        uint8 tatoo;
        uint8 earrings;
        uint8 accessory;
        uint8 expression;
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
import "./details/TatooDetail.sol";
import "./details/AccessoryDetail.sol";
import "./details/EarringsDetail.sol";
import "./details/ExpressionDetail.sol";
import "./DetailHelper.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

library NFTDescriptor {
    struct SVGParams {
        uint8 hair;
        uint8 eye;
        uint8 eyebrow;
        uint8 nose;
        uint8 mouth;
        uint8 tatoo;
        uint8 earring;
        uint8 accessory;
        uint8 expression;
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
                    DetailHelper.getDetailSVG(address(ExpressionDetail), params.expression),
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
                    DetailHelper.getDetailSVG(address(TatooDetail), params.tatoo),
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
                    getJsonAttribute("Eyebrown", EyebrowDetail.getItemNameById(params.eyebrow), false),
                    abi.encodePacked(
                        getJsonAttribute("Tatoo", TatooDetail.getItemNameById(params.tatoo), false),
                        getJsonAttribute("Accessory", AccessoryDetail.getItemNameById(params.accessory), false),
                        getJsonAttribute("Earring", EarringsDetail.getItemNameById(params.earring), false),
                        getJsonAttribute("Expression", EarringsDetail.getItemNameById(params.expression), false),
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
        revert("HypnosisDescriptor::pickItems: No item");
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

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/IHypnosis.sol";
import "./interfaces/IHypnosisDescriptor.sol";
import "./chainlink/VRFConsumerBase.sol";

/// @title Hypnosis NFTs
/// @notice On-chain generated NFTs
contract Hypnosis is ERC721Enumerable, Ownable, IHypnosis, ReentrancyGuard, VRFConsumerBase {
    /// @dev Price for one Onii
    uint256 private constant _unitPrice = 0.01 ether;

    /// @dev Number of sales to increase the price
    uint256 private constant _step = 5000;

    /// @dev Count the number of calls to the create function
    uint256 private createCall = 0;

    /// @dev The token ID onii detail
    mapping(uint256 => Detail) private _detail;

    /// @dev The address of the token descriptor contract, which handles generating token URIs.
    address private immutable _tokenDescriptor;

    /// @dev all oniis generated based on ids hash
    mapping(bytes32 => bool) private oniis;

    /// @dev Chainlink keyhash
    bytes32 internal keyHash;

    /// @dev Chainlink RNG fee
    uint256 internal fee;

    /// @dev Number received from chainlink RNG
    uint256 internal randomResult = 0;

    constructor(address _tokenDescriptor_)
        ERC721("Hypnosis", "HYPNO")
        VRFConsumerBase(
            0xb3dCcb4Cf7a26f6cf6B120Cf5A73875B7BBc655B, // VRF Coordinator
            0x01BE23585060835E02B77ef475b0Cc51aA1e0709 // LINK Token
        )
    {
        _tokenDescriptor = _tokenDescriptor_;
        keyHash = 0x2ed0feb3e7fd2022120aa84fab1945545a9f2ffc9076fd6156fa96eaff4c1311;
        fee = 0.1 * 10**18;
    }

    // save bytecode by removing implementation of unused method
    function _baseURI() internal view virtual override returns (string memory) {}

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return IHypnosisDescriptor(_tokenDescriptor).tokenURI(this, tokenId);
    }

    /// @notice Create randomly an Onii
    /// @param qty The quantity to buy
    function create(uint256 qty) public payable nonReentrant {
        require(msg.value >= getUnitPrice() * qty, "Ether sent is not correct");
        for (uint256 i; i < qty; i++) {
            uint256 seed = (block.timestamp + randomResult) << (i + 1);
            uint256 nextTokenId = totalSupply() + 1;
            Detail memory newDetail = Detail({
                hair: IHypnosisDescriptor(_tokenDescriptor).generateHairId(nextTokenId, seed),
                eye: IHypnosisDescriptor(_tokenDescriptor).generateEyeId(nextTokenId, seed),
                eyebrow: IHypnosisDescriptor(_tokenDescriptor).generateEyebrowId(nextTokenId, seed),
                nose: IHypnosisDescriptor(_tokenDescriptor).generateNoseId(nextTokenId, seed),
                mouth: IHypnosisDescriptor(_tokenDescriptor).generateMouthId(nextTokenId, seed),
                tatoo: IHypnosisDescriptor(_tokenDescriptor).generateTatooId(nextTokenId, seed),
                earrings: IHypnosisDescriptor(_tokenDescriptor).generateEarringsId(nextTokenId, seed),
                accessory: IHypnosisDescriptor(_tokenDescriptor).generateAccessoryId(nextTokenId, seed),
                expression: IHypnosisDescriptor(_tokenDescriptor).generateExpressionId(nextTokenId, seed),
                skin: IHypnosisDescriptor(_tokenDescriptor).generateSkinId(nextTokenId, seed),
                original: true,
                timestamp: block.timestamp,
                creator: msg.sender
            });
            newDetail.original = copyOnii(newDetail);
            _detail[nextTokenId] = newDetail;
            _safeMint(msg.sender, nextTokenId);
        }
    }

    /// @notice Get the current price of one Onii
    /// The price is progressive. Every 5000 sales, the price increases by 0.01 ether
    /// @return The Onii price
    function getUnitPrice() public view returns (uint256) {
        return ((totalSupply() / _step) * _unitPrice) + _unitPrice;
    }

    /// @notice Send funds from sales to the owner
    function withdrawAll() public payable onlyOwner {
        require(payable(0x838D23a8A17adaa6866969b86D35Ac0941C67510).send(address(this).balance));
    }

    /// @inheritdoc IHypnosis
    function details(uint256 tokenId) external view override returns (Detail memory detail) {
        detail = _detail[tokenId];
    }

    /// @dev Callback function used by VRF Coordinator
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        randomResult = randomness;
    }

    /// @dev Check is an onii already exists (based on details)
    /// @return False if it already exists, true if not
    function copyOnii(Detail memory detail) internal returns (bool) {
        bytes32 hash = keccak256(
            abi.encode(
                detail.hair,
                detail.eye,
                detail.eyebrow,
                detail.nose,
                detail.mouth,
                detail.tatoo,
                detail.earrings,
                detail.accessory,
                detail.expression,
                detail.skin
            )
        );
        if (!oniis[hash]) {
            oniis[hash] = true;
            return true;
        } else {
            return false;
        }
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
                        '<path id="Mask" opacity="0.1" fill="#48005E" d="M390,420H30c-16.6,0-30-13.4-30-30V30C0,13.4,13.4,0,30,0h360c16.6,0,30,13.4,30,30v360C420,406.6,406.6,420,390,420z"/>',
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

/// @title Eyes SVG generator
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

    //////////

    /// @dev Hair N°12 => Short Brown
    function item_12() public pure returns (string memory) {
        return base(shortHairs(Colors.BROWN));
    }

    /// @dev Hair N°13 => Short Black
    function item_13() public pure returns (string memory) {
        return base(shortHairs(Colors.BLACK));
    }

    /// @dev Hair N°14 => Short Gray
    function item_14() public pure returns (string memory) {
        return base(shortHairs(Colors.GRAY));
    }

    /// @dev Hair N°15 => Short White
    function item_15() public pure returns (string memory) {
        return base(shortHairs(Colors.WHITE));
    }

    /// @dev Hair N°16 => Short Blue
    function item_16() public pure returns (string memory) {
        return base(shortHairs(Colors.BLUE));
    }

    /// @dev Hair N°17 => Short Yellow
    function item_17() public pure returns (string memory) {
        return base(shortHairs(Colors.YELLOW));
    }

    /// @dev Hair N°18 => Short Pink
    function item_18() public pure returns (string memory) {
        return base(shortHairs(Colors.PINK));
    }

    /// @dev Hair N°19 => Short Red
    function item_19() public pure returns (string memory) {
        return base(shortHairs(Colors.RED));
    }

    /// @dev Hair N°20 => Short Purple
    function item_20() public pure returns (string memory) {
        return base(shortHairs(Colors.PURPLE));
    }

    /// @dev Hair N°21 => Short Green
    function item_21() public pure returns (string memory) {
        return base(shortHairs(Colors.GREEN));
    }

    /// @dev Hair N°22 => Short Saiki
    function item_22() public pure returns (string memory) {
        return base(shortHairs(Colors.SAIKI));
    }

    /// @dev Hair N°23 => Monk
    function item_23() public pure returns (string memory) {
        return
            base(
                string(
                    abi.encodePacked(
                        '<path opacity="0.36" fill="#6E5454" stroke="#8A8A8A" stroke-width="0.5" stroke-miterlimit="10" d="M286.8,206.8c0,0,0.1-17.4-2.9-20.3c-3.1-2.9-7.3-8.7-7.3-8.7s0.6-24.8-2.9-31.8c-3.6-7-3.9-24.3-35-23.6c-30.3,0.7-42.5,5.4-42.5,5.4s-14.2-8.2-43-3.8c-19.3,4.9-17.2,50.1-17.2,50.1s-5.6,9.5-6.2,14.8c-0.6,5.3-0.3,8.3-0.3,8.3S110.3,72.1,216.1,70.4c108.4-1.7,87.1,121.7,85.1,122.4C294.7,190.1,293.2,197.7,286.8,206.8z"/>',
                        '<g id="Bald" opacity="0.33">',
                        '<ellipse transform="matrix(0.7071 -0.7071 0.7071 0.7071 0.1603 226.5965)" fill="#FFFFFF" cx="273.6" cy="113.1" rx="1.4" ry="5.3"/>',
                        '<ellipse transform="matrix(0.5535 -0.8328 0.8328 0.5535 32.0969 254.4865)" fill="#FFFFFF" cx="253.4" cy="97.3" rx="4.2" ry="16.3"/>',
                        "</g>"
                    )
                )
            );
    }

    /// @dev Hair N°24 => Bald
    function item_24() public pure returns (string memory) {
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

    /// @dev Generate classic hairs with the given color
    function shortHairs(string memory hairsColor) private pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "<path fill='#",
                    hairsColor,
                    "' d='M287.3,207.1c0,0-0.4-17.7-3.4-20.6c-3.1-2.9-7.3-8.7-7.3-8.7s0.6-24.8-2.9-31.8c-3.6-7-3.9-24.3-35-23.6c-30.3,0.7-42.5,5.4-42.5,5.4s-14.2-8.2-43-3.8c-19.3,4.9-17.2,50.1-17.2,50.1s-5.6,9.5-6.2,14.8c-0.6,5.3-0.3,8.3-0.3,8.3c0.9-0.2-19.1-126.3,86.7-126.8c108.4-0.3,87.1,121.7,85.1,122.4C294.5,191.6,293.7,198,287.3,207.1z'/>",
                    '<path fill-rule="evenodd" clip-rule="evenodd" fill="#212121" stroke="#000000" stroke-miterlimit="10" d="M196,124.6c0,0-30.3-37.5-20.6-77.7c0,0,0.7,18,12,25.1c0,0-8.6-13.4-0.3-33.4c0,0,2.7,15.8,10.7,23.4c0,0-2.7-18.4,2.2-29.6c0,0,9.7,23.2,13.9,26.3c0,0-6.5-17.2,5.4-27.7c0,0-0.8,18.6,9.8,25.4c0,0-2.7-11,4-18.9c0,0,1.2,25.1,6.6,29.4c0,0-2.7-12,2.1-20c0,0,6,24,8.6,28.5c-9.1-2.6-17.9-3.2-26.6-3C223.7,72.3,198,80.8,196,124.6z"/>',
                    '<g id="Light" opacity="0.14">',
                    '<ellipse transform="matrix(0.7071 -0.7071 0.7071 0.7071 0.1603 226.5965)" fill="#FFFFFF" cx="273.6" cy="113.1" rx="1.4" ry="5.3"/>',
                    '<ellipse transform="matrix(0.5535 -0.8328 0.8328 0.5535 32.0969 254.4865)" fill="#FFFFFF" cx="253.4" cy="97.3" rx="4.2" ry="16.3"/>',
                    "</g>",
                    '<path opacity="0.05" fill-rule="evenodd" clip-rule="evenodd" d="M276.4,163.7c0,0,0.2-1.9,0.2,14.1c0,0,6.5,7.5,8.5,11s2.6,17.8,2.6,17.8l7-11.2c0,0,1.8-3.2,6.6-2.6c0,0,5.6-13.1,2.2-42.2C303.5,150.6,294.2,162.1,276.4,163.7z"/>',
                    '<path opacity="0.1" fill-rule="evenodd" clip-rule="evenodd" d="M129.2,194.4c0,0-0.7-8.9,6.8-20.3c0,0-0.2-21.2,1.3-22.9c-3.7,0-6.7-0.5-7.7-2.4C129.6,148.8,125.8,181.5,129.2,194.4z"/>'
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
            name = "Short Brown";
        } else if (id == 13) {
            name = "Short Black";
        } else if (id == 14) {
            name = "Short Gray";
        } else if (id == 15) {
            name = "Short White";
        } else if (id == 16) {
            name = "Short Blue";
        } else if (id == 17) {
            name = "Short Yellow";
        } else if (id == 18) {
            name = "Short Pink";
        } else if (id == 19) {
            name = "Short Red";
        } else if (id == 20) {
            name = "Short Purple";
        } else if (id == 21) {
            name = "Short Green";
        } else if (id == 22) {
            name = "Short Saiki";
        } else if (id == 23) {
            name = "Monk";
        } else if (id == 24) {
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

    /// @dev Mouth N°9 => O
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

    /// @dev Mouth N°10 => Drool
    function item_10() public pure returns (string memory) {
        return
            base(
                string(
                    abi.encodePacked(
                        '<ellipse transform="matrix(0.9952 -9.745440e-02 9.745440e-02 0.9952 -24.6525 20.6528)" opacity="0.84" fill-rule="evenodd" clip-rule="evenodd" enable-background="new    " cx="199.1" cy="262.7" rx="3.2" ry="4.6"/>'
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
                        '<polyline fill="none" stroke="#000000" stroke-width="0.75" stroke-linejoin="round" stroke-miterlimit="10" points="165.1,258.9 167,256.3 170.3,264.6 175.4,257.7 179.2,271.9 187,259.1 190.8,276.5 197,259.7 202.1,277.5 207.8,259.1 213.8,275.4 217.9,258.7 224.1,271.2 226.5,257.9 232.7,266.2 235.1,256.8 238.6,262.1 241.3,255.8 243.8,257.6"/>'
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
            name = "O";
        } else if (id == 10) {
            name = "Drool";
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

    /// @dev Eyes N°11 => Color Black/Gray
    function item_11() public pure returns (string memory) {
        return eyesNoFillAndColorPupils(Colors.BLACK, Colors.GRAY);
    }

    /// @dev Eyes N°12 => Color Black/Yellow
    function item_12() public pure returns (string memory) {
        return eyesNoFillAndColorPupils(Colors.BLACK, Colors.YELLOW);
    }

    /// @dev Eyes N°13 => Color Black/White
    function item_13() public pure returns (string memory) {
        return eyesNoFillAndColorPupils(Colors.BLACK, Colors.WHITE);
    }

    /// @dev Eyes N°14 => Color Black/Black
    function item_14() public pure returns (string memory) {
        return eyesNoFillAndColorPupils(Colors.BLACK, Colors.BLACK_DEEP);
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
                        '<path fill="#FFFFFF" stroke="#000000" stroke-width="0.25" stroke-miterlimit="10" d="M169.2,204.2c0.1,11.3-14.1,11.3-13.9,0C155.1,192.9,169.3,192.9,169.2,204.2z"/>',
                        '<path fill="#FFFFFF" stroke="#000000" stroke-width="0.25" stroke-miterlimit="10" d="M243.1,204.3c0.1,11.3-14.1,11.3-13.9,0C229,193,243.2,193,243.1,204.3z"/>'
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
                        '<path opacity="0.81" fill="#F7F7F7" d="M176.5,200.1c2.9,16.9-10.8,14.8-23.7,13.2c-4.9-2-6.1-12.4-6.1-12.4C156.6,191.4,165.8,190.2,176.5,200.1z"/>',
                        '<path d="M147.5,198.7c-0.8,1-1.5,2.1-2,3.3c7.5-8.5,24.7-10.3,31.7-0.9c-5.8-10.3-17.5-13-26.4-5.8"/>',
                        '<path d="M149.4,196.6c-0.2,0.2-0.4,0.4-0.6,0.6"/>',
                        '<path d="M166.2,187.1c-4.3-0.8-8.8,0.1-13,1.4C157,186.4,162,185.8,166.2,187.1z"/>',
                        '<path d="M169.8,188.5c2.2,0.8,4.1,2.2,5.6,3.8C173.5,191.1,171.6,189.7,169.8,188.5z"/>',
                        '<path d="M174.4,211.8c-0.2,0.5-0.8,0.8-1.2,1c-0.5,0.2-1,0.4-1.5,0.6c-1,0.3-2.1,0.5-3.1,0.7c-2.1,0.4-4.2,0.5-6.3,0.7c-2.1,0.1-4.3,0.1-6.4-0.3c-1.1-0.2-2.1-0.5-3.1-0.9c-0.9-0.5-2-1.1-2.4-2.1c0.6,0.9,1.6,1.4,2.5,1.7c1,0.3,2,0.6,3,0.7c2.1,0.3,4.2,0.3,6.2,0.2c2.1-0.1,4.2-0.2,6.3-0.5c1-0.1,2.1-0.3,3.1-0.5c0.5-0.1,1-0.2,1.5-0.4c0.2-0.1,0.5-0.2,0.7-0.3C174.1,212.2,174.3,212.1,174.4,211.8z"/>'
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
                        '<path d="M255.5,203.5c0.7-0.7,0.9-2.5,0.9-3.2c-0.1,0.5-1.3,1.4-2.2,1.9c-0.2-0.2-0.4-0.4-0.6-0.6c0.5-0.8,0.7-2.4,0.7-3c-0.1,0.5-1.2,1.4-2.1,1.9c-2.6-1.9-6.2-3.8-11-4.3c-7.8-0.8-15.7,2-20.1,7.5c5.7-3.6,12.9-5.3,20.1-4.5c6.4,0.8,12.4,2.9,16.5,6.9C257.3,205.1,256.3,204,255.5,203.5z"/>',
                        '<path d="M254.3,198.6L254.3,198.6C254.4,198.2,254.4,198.3,254.3,198.6z"/>',
                        '<path d="M256.4,200.3L256.4,200.3C256.5,199.9,256.5,200,256.4,200.3z"/>',
                        '<path d="M232.2,192.6c1.1-0.3,2.3-0.5,3.5-0.6c1.1-0.1,2.4-0.1,3.5,0s2.4,0.3,3.5,0.5s2.3,0.6,3.3,1.1l0,0c-1.1-0.3-2.3-0.6-3.4-0.8c-1.1-0.3-2.3-0.4-3.4-0.5c-1.1-0.1-2.4-0.2-3.5-0.1C234.5,192.3,233.4,192.4,232.2,192.6L232.2,192.6z"/>',
                        '<path d="M232.2,192.6c1.1-0.3,2.3-0.5,3.5-0.6c1.1-0.1,2.4-0.1,3.5,0s2.4,0.3,3.5,0.5s2.3,0.6,3.3,1.1l0,0c-1.1-0.3-2.3-0.6-3.4-0.8c-1.1-0.3-2.3-0.4-3.4-0.5c-1.1-0.1-2.4-0.2-3.5-0.1C234.5,192.3,233.4,192.4,232.2,192.6L232.2,192.6z"/>',
                        '<path d="M161.3,195.8c-3.7,0.4-7.2,1.6-10.1,3.5c-0.6-0.3-2.8-1.6-3-2.3c0.1,0.7,0.3,2.6,1.1,3.3c0.1,0.1,0.2,0.2,0.3,0.2c-0.2,0.2-0.4,0.3-0.6,0.5c-0.7-0.4-2.7-1.5-2.9-2.2c0.1,0.7,0.3,2.6,1.1,3.3c0.1,0.1,0.3,0.2,0.4,0.2c-0.8,0.8-1.6,1.9-2.2,2.9c1.3-1.4,6.3-5,15.8-6.3c10.9-1.4,16.7,4.7,18,5.5C174.8,198.9,169.1,194.8,161.3,195.8z"/>',
                        '<path d="M148.2,196.9L148.2,196.9C148.2,196.8,148.2,196.7,148.2,196.9z"/>',
                        '<path d="M146.1,198.6L146.1,198.6C146.1,198.5,146.1,198.4,146.1,198.6z"/>',
                        '<path d="M167.5,192.2c-1.1-0.2-2.3-0.3-3.5-0.3c-1.1,0-2.4,0-3.5,0.2c-1.1,0.1-2.3,0.3-3.4,0.5c-1.1,0.3-2.3,0.5-3.4,0.8c2.1-0.9,4.3-1.5,6.7-1.7c1.1-0.1,2.4-0.1,3.5-0.1C165.3,191.7,166.4,191.9,167.5,192.2z"/>',
                        '<path d="M171.4,193.4c0.6,0.2,1.1,0.3,1.7,0.6c0.5,0.3,1,0.5,1.6,0.8c0.5,0.3,1,0.6,1.4,0.9c0.5,0.3,0.9,0.7,1.3,1c-1-0.5-2.1-1.1-3-1.6C173.3,194.5,172.3,193.9,171.4,193.4z"/>'
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
                    "<path opacity='0.81' fill='#",
                    scleraColor,
                    "' d='M221.2,202.4c0.6,4.1,1.2,11,6.6,11.5c9.9,0.3,21.2,4.1,23.4-9.5c1.3-7.1-9.8-11.4-15.4-11.2C230.7,194.7,220.9,195.5,221.2,202.4z'/>",
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
                    "<path opacity='0.81' fill='#",
                    scleraColor,
                    "' d='M176.5,200.1c2.9,16.9-10.8,14.8-23.7,13.2c-4.9-2-6.1-12.4-6.1-12.4C156.6,191.4,165.8,190.2,176.5,200.1z'/>",
                    '<path d="M147.5,198.7c-0.8,1-1.5,2.1-2,3.3c7.5-8.5,24.7-10.3,31.7-0.9c-5.8-10.3-17.5-13-26.4-5.8"/>',
                    '<path d="M149.4,196.6c-0.2,0.2-0.4,0.4-0.6,0.6"/>',
                    '<path d="M166.2,187.1c-4.3-0.8-8.8,0.1-13,1.4C157,186.4,162,185.8,166.2,187.1z"/>',
                    '<path d="M169.8,188.5c2.2,0.8,4.1,2.2,5.6,3.8C173.5,191.1,171.6,189.7,169.8,188.5z"/>',
                    '<path d="M174.4,211.8c-0.2,0.5-0.8,0.8-1.2,1c-0.5,0.2-1,0.4-1.5,0.6c-1,0.3-2.1,0.5-3.1,0.7c-2.1,0.4-4.2,0.5-6.3,0.7c-2.1,0.1-4.3,0.1-6.4-0.3c-1.1-0.2-2.1-0.5-3.1-0.9c-0.9-0.5-2-1.1-2.4-2.1c0.6,0.9,1.6,1.4,2.5,1.7c1,0.3,2,0.6,3,0.7c2.1,0.3,4.2,0.3,6.2,0.2c2.1-0.1,4.2-0.2,6.3-0.5c1-0.1,2.1-0.3,3.1-0.5c0.5-0.1,1-0.2,1.5-0.4c0.2-0.1,0.5-0.2,0.7-0.3C174.1,212.2,174.3,212.1,174.4,211.8z"/>'
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
            name = "Color Black/Gray";
        } else if (id == 12) {
            name = "Color Black/Yellow";
        } else if (id == 13) {
            name = "Color Black/White";
        } else if (id == 14) {
            name = "Color Black/Black";
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

    /// @dev Eyebrow N°3 => Small
    function item_3() public pure returns (string memory) {
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

    /// @notice Return the eyebrow name of the given id
    /// @param id The eyebrow Id
    function getItemNameById(uint8 id) public pure returns (string memory name) {
        name = "";
        if (id == 1) {
            name = "Classic";
        } else if (id == 2) {
            name = "Thick";
        } else if (id == 3) {
            name = "Small";
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

/// @title Tatoo SVG generator
library TatooDetail {
    /// @dev Tatoo N°1 => Nothing
    function item_1() public pure returns (string memory) {
        return "";
    }

    /// @dev Tatoo N°2 => Freckle
    function item_2() public pure returns (string memory) {
        return
            base(
                string(
                    abi.encodePacked(
                        '<circle fill="#E08F56" cx="242.5" cy="220.9" r="1.1"/>',
                        '<circle fill="#E08F56" cx="247.2" cy="223" r="1.1"/>',
                        '<circle fill="#E08F56" cx="238.7" cy="223.7" r="1.1"/>',
                        '<circle fill="#E08F56" cx="242.4" cy="225.8" r="1.1"/>',
                        '<circle fill="#E08F56" cx="153.7" cy="220.6" r="1.1"/>',
                        '<circle fill="#E08F56" cx="158.4" cy="222.7" r="1.1"/>',
                        '<circle fill="#E08F56" cx="149.9" cy="223.4" r="1.1"/>',
                        '<circle fill="#E08F56" cx="153.6" cy="225.5" r="1.1"/>'
                    )
                )
            );
    }

    /// @dev Tatoo N°3 => Chin
    function item_3() public pure returns (string memory) {
        return
            base(
                string(
                    abi.encodePacked(
                        '<path d="M201.3,291.9c0.2-0.6,0.4-1.3,1-1.8c0.3-0.2,0.7-0.4,1.1-0.3c0.4,0.1,0.7,0.4,0.9,0.7c0.4,0.6,0.5,1.4,0.5,2.1 c0,0.7-0.3,1.5-0.8,2c-0.5,0.6-1.3,0.9-2.1,0.8c-0.8-0.1-1.5-0.5-2-0.9c-0.6-0.4-1.1-1-1.5-1.6c-0.4-0.6-0.6-1.4-0.6-2.2 c0.2-1.6,1.4-2.8,2.7-3.4c1.3-0.6,2.8-0.8,4.2-0.5c0.7,0.1,1.4,0.4,2,0.9c0.6,0.5,0.9,1.2,1,1.9c0.2,1.4-0.2,2.9-1.2,3.9 c0.7-1.1,1-2.5,0.7-3.8c-0.2-0.6-0.5-1.2-1-1.5c-0.5-0.4-1.1-0.6-1.7-0.6c-1.3-0.1-2.6,0-3.7,0.6c-1.1,0.5-2,1.5-2.1,2.6 c-0.1,1.1,0.7,2.2,1.6,3c0.5,0.4,1,0.8,1.5,0.8c0.5,0.1,1.1-0.1,1.5-0.5c0.4-0.4,0.7-0.9,0.7-1.6c0.1-0.6,0-1.3-0.3-1.8 c-0.1-0.3-0.4-0.5-0.6-0.6c-0.3-0.1-0.6,0-0.8,0.1C201.9,290.7,201.5,291.3,201.3,291.9z"/>'
                    )
                )
            );
    }

    /// @dev Tatoo N°4 => Moon
    function item_4() public pure returns (string memory) {
        return
            base(
                string(
                    abi.encodePacked(
                        '<path fill="#7F0068" d="M197.2,142.1c-5.8,0-10.9,2.9-13.9,7.3c2.3-2.3,5.4-3.7,8.9-3.7c7.1,0,12.9,5.9,12.9,13.3 s-5.8,13.3-12.9,13.3c-3.4,0-6.6-1.4-8.9-3.7c3.1,4.4,8.2,7.3,13.9,7.3c9.3,0,16.9-7.6,16.9-16.9S206.6,142.1,197.2,142.1z"/>'
                    )
                )
            );
    }

    /// @dev Tatoo N°5 => Dot
    function item_5() public pure returns (string memory) {
        return base(string(abi.encodePacked('<circle cx="260.8" cy="215.8" r="2.1"/>')));
    }

    /// @dev Tatoo N°6 => Scars 1
    function item_6() public pure returns (string memory) {
        return
            base(
                string(
                    abi.encodePacked(
                        '<path id="Scar" fill="#FF7478" d="M236.2,148.7c0,0-7.9,48.9-1.2,97.3C235,246,243.8,201.5,236.2,148.7z"/>'
                    )
                )
            );
    }

    /// @dev Tatoo N°7 => Scars 2
    function item_7() public pure returns (string memory) {
        return
            base(
                string(
                    abi.encodePacked(
                        '<path fill="none" stroke="#000000" stroke-width="0.5" stroke-miterlimit="10" d="M153.8,228.8c0,0,37.7-3.7,39.1-9.4 c0,0,21.5,7.1,59.6,9.4"/>',
                        '<line fill="none" stroke="#000000" stroke-width="0.5" stroke-miterlimit="10" x1="162.6" y1="225.3" x2="162.6" y2="232.4"/>',
                        '<line fill="none" stroke="#000000" stroke-width="0.5" stroke-miterlimit="10" x1="174.1" y1="223.5" x2="174.1" y2="230.7"/>',
                        '<line fill="none" stroke="#000000" stroke-width="0.5" stroke-miterlimit="10" x1="221.2" y1="222.4" x2="221.2" y2="229.5"/>',
                        '<line fill="none" stroke="#000000" stroke-width="0.5" stroke-miterlimit="10" x1="242.1" y1="225.2" x2="242.1" y2="232.3"/>'
                    )
                )
            );
    }

    /// @dev Tatoo N°8 => Ether
    function item_8() public pure returns (string memory) {
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

    /// @dev Tatoo N°9 => Tori
    function item_9() public pure returns (string memory) {
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

    /// @notice Return the tatoo name of the given id
    /// @param id The tatoo Id
    function getItemNameById(uint8 id) public pure returns (string memory name) {
        name = "";
        if (id == 1) {
            name = "Nothing";
        } else if (id == 2) {
            name = "Freckle";
        } else if (id == 3) {
            name = "Chin";
        } else if (id == 4) {
            name = "Moon";
        } else if (id == 5) {
            name = "Dot";
        } else if (id == 6) {
            name = "Scars 1";
        } else if (id == 7) {
            name = "Scars 2";
        } else if (id == 8) {
            name = "Ether";
        } else if (id == 9) {
            name = "Tori";
        }
    }

    /// @dev The base SVG for the hair
    function base(string memory children) private pure returns (string memory) {
        return string(abi.encodePacked('<g id="Tatoo">', children, "</g>"));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

pragma abicoder v2;

import "base64-sol/base64.sol";

/// @title Accessory SVG generator
library AccessoryDetail {
    /// @dev Accessory N°1 => Nothing
    function item_1() public pure returns (string memory) {
        return "";
    }

    /// @dev Accessory N°2 => Glasses
    function item_2() public pure returns (string memory) {
        return
            base(
                string(
                    abi.encodePacked(
                        '<circle opacity="0.62" fill="#FFFFFF" stroke="#000000" stroke-miterlimit="10" cx="161.5" cy="201.7" r="23.9"/>',
                        '<circle opacity="0.62" fill="#FFFFFF" stroke="#000000" stroke-miterlimit="10" cx="232.9" cy="201.7" r="23.9"/>',
                        '<line fill="none" stroke="#000000" stroke-miterlimit="10" x1="256.8" y1="201.7" x2="292.6" y2="198.5"/>',
                        '<path fill="none" stroke="#000000" stroke-miterlimit="10" d="M185.5,201.7c0,0,14.7-3.1,23.5,0"/>',
                        '<line fill="none" stroke="#000000" stroke-miterlimit="10" x1="137.6" y1="201.7" x2="129.2" y2="198.5"/>'
                    )
                )
            );
    }

    /// @dev Accessory N°3 => Saiki
    function item_3() public pure returns (string memory) {
        return
            base(
                string(
                    abi.encodePacked(
                        '<polygon opacity="0.68" fill="#7FFF35" points="126,189.5 185.7,191.8 188.6,199.6 184.6,207.4 157.3,217.9 128.6,203.7"/>',
                        '<polygon opacity="0.68" fill="#7FFF35" points="265.7,189.5 206.7,191.8 203.8,199.6 207.7,207.4 234.8,217.9 263.2,203.7"/>',
                        '<polyline fill="#FFFFFF" stroke="#424242" stroke-width="0.5" stroke-miterlimit="10" points="196.5,195.7 191.8,195.4 187,190.9 184.8,192.3 188.5,198.9 183,206.8 187.6,208.3 193.1,201.2 196.5,201.2"/>',
                        '<polyline fill="#FFFFFF" stroke="#424242" stroke-width="0.5" stroke-miterlimit="10" points="196.4,195.7 201.1,195.4 205.9,190.9 208.1,192.3 204.4,198.9 209.9,206.8 205.3,208.3 199.8,201.2 196.4,201.2"/>',
                        '<polygon fill="#FFFFFF" stroke="#424242" stroke-width="0.5" stroke-miterlimit="10" points="123.8,189.5 126.3,203 129.2,204.4 127.5,189.5"/>',
                        '<polygon fill="#FFFFFF" stroke="#424242" stroke-width="0.5" stroke-miterlimit="10" points="265.8,189.4 263.3,203.7 284.3,200.6 285.3,189.4"/>'
                    )
                )
            );
    }

    /// @dev Accessory N°4 => Horns
    function item_4() public pure returns (string memory) {
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

    /// @dev Accessory N°5 => Halo
    function item_5() public pure returns (string memory) {
        return
            base(
                string(
                    abi.encodePacked(
                        '<path fill="#F6FF99" stroke="#000000" stroke-miterlimit="10" d="M136,67.3c0,14.6,34.5,26.4,77,26.4s77-11.8,77-26.4s-34.5-26.4-77-26.4S136,52.7,136,67.3L136,67.3z M213,79.7c-31.4,0-56.9-6.4-56.9-14.2s25.5-14.2,56.9-14.2s56.9,6.4,56.9,14.2S244.4,79.7,213,79.7z"/>'
                    )
                )
            );
    }

    /// @notice Return the accessory name of the given id
    /// @param id The accessory Id
    function getItemNameById(uint8 id) public pure returns (string memory name) {
        name = "";
        if (id == 1) {
            name = "Nothing";
        } else if (id == 2) {
            name = "Glasses";
        } else if (id == 3) {
            name = "Saiki";
        } else if (id == 4) {
            name = "Horns";
        } else if (id == 5) {
            name = "Halo";
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
    /// @dev Earrings N°1 => Nothing
    function item_1() public pure returns (string memory) {
        return "";
    }

    /// @dev Earrings N°2 => Circle
    function item_2() public pure returns (string memory) {
        return
            base(
                string(
                    abi.encodePacked(
                        '<ellipse cx="135.1" cy="243.2" rx="3" ry="3.4"/>',
                        '<ellipse cx="286.1" cy="243.2" rx="3.3" ry="3.4"/>'
                    )
                )
            );
    }

    /// @dev Earrings N°3 => Ring
    function item_3() public pure returns (string memory) {
        return
            base(
                string(
                    abi.encodePacked(
                        '<path fill="none" stroke="#000000" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" stroke-miterlimit="10" d="M283.5,246c0,0-4.2,2-3.1,6.1c1,4.1,5.1,3.6,5.4,3.5s3.1-0.9,3-5"/>',
                        '<path fill="none" stroke="#000000" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" stroke-miterlimit="10" d="M134.3,244.7c0,0-4.2,2-3.1,6.1c1,4.1,5.1,3.6,5.4,3.5c0.3-0.1,3.1-0.9,3-5"/>'
                    )
                )
            );
    }

    /// @dev Earrings N°4 => Heart
    function item_4() public pure returns (string memory) {
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

    /// @dev Earrings N°5 => Gold
    function item_5() public pure returns (string memory) {
        return
            base(
                string(
                    abi.encodePacked(
                        '<path d="M298.7,228.1l-4.7-1.6c0,0-0.1,0-0.1-0.1v-0.1c2.8-2.7,7.1-17.2,7.2-17.4c0-0.1,0.1-0.1,0.1-0.1l0,0c5.3,1.1,5.6,2.2,5.7,2.4c-3.1,5.4-8,16.7-8.1,16.8C298.9,228,298.8,228.1,298.7,228.1C298.8,228.1,298.8,228.1,298.7,228.1z" style="fill: #fff700;stroke: #000;stroke-miterlimit: 10;stroke-width: 0.25px"/>'
                    )
                )
            );
    }

    /// @dev Earrings N°6 => Drop Heart
    function item_6() public pure returns (string memory) {
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

    /// @dev Earrings N°7 => Ether
    function item_7() public pure returns (string memory) {
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

    /// @dev Earrings N°8 => Drop Ether
    function item_8() public pure returns (string memory) {
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

    /// @notice Return the earring name of the given id
    /// @param id The earring Id
    function getItemNameById(uint8 id) public pure returns (string memory name) {
        name = "";
        if (id == 1) {
            name = "Nothing";
        } else if (id == 2) {
            name = "Circle";
        } else if (id == 3) {
            name = "Ring";
        } else if (id == 4) {
            name = "Heart";
        } else if (id == 5) {
            name = "Gold";
        } else if (id == 6) {
            name = "Drop Heart";
        } else if (id == 7) {
            name = "Ether";
        } else if (id == 8) {
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

/// @title Expressions SVG generator
library ExpressionDetail {
    /// @dev Expressions N°1 => Expressionless
    function item_1() public pure returns (string memory) {
        return "";
    }

    /// @dev Expressions N°2 => Blush Cheeks
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

    /// @dev Expressions N°3 => Blush
    function item_3() public pure returns (string memory) {
        return
            base(
                string(
                    abi.encodePacked(
                        '<ellipse opacity="0.52" fill-rule="evenodd" clip-rule="evenodd" fill="#FF7F83" cx="196.8" cy="222" rx="32.8" ry="1.9"/>'
                    )
                )
            );
    }

    /// @dev Expressions N°4 => Dark Circle
    function item_4() public pure returns (string memory) {
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

    /// @dev Expressions N°5 => Blase
    function item_5() public pure returns (string memory) {
        return
            base(
                string(
                    abi.encodePacked(
                        '<line fill="none" stroke="#000000" stroke-linecap="round" stroke-miterlimit="10" x1="254.6" y1="158.2" x2="254.6" y2="188.8"/>',
                        '<line fill="none" stroke="#000000" stroke-linecap="round" stroke-miterlimit="10" x1="257.6" y1="158.2" x2="257.6" y2="188.8"/>',
                        '<line fill="none" stroke="#000000" stroke-linecap="round" stroke-miterlimit="10" x1="260.6" y1="162.8" x2="260.6" y2="193.3"/>',
                        '<line fill="none" stroke="#000000" stroke-linecap="round" stroke-miterlimit="10" x1="265" y1="159.8" x2="265" y2="190.4"/>'
                    )
                )
            );
    }

    /// @dev Expressions N°6 => Sweat
    function item_6() public pure returns (string memory) {
        return
            base(
                string(
                    abi.encodePacked(
                        '<path fill="#C9FFF5" stroke="#0064AA" stroke-width="0.25" stroke-miterlimit="10" d="M260.9,156.9c0,0-14.1,31.5,0,31.5C276,188.4,260.9,156.9,260.9,156.9z"/>',
                        '<ellipse fill="#8AF3FF" cx="261.1" cy="181.4" rx="3.9" ry="5.5"/>',
                        '<ellipse fill="#FFFFFF" cx="262.8" cy="185.1" rx="2.6" ry="1.3"/>'
                    )
                )
            );
    }

    /// @dev Expressions N°7 => Angry
    function item_7() public pure returns (string memory) {
        return
            base(
                string(
                    abi.encodePacked(
                        '<path fill="none" stroke="#B40005" stroke-width="2" stroke-miterlimit="10" d="M264.2,154.2c0,0,13.7,11.9-3.6,17.6"/>',
                        '<path fill="none" stroke="#B40005" stroke-width="2" stroke-miterlimit="10" d="M271.4,150.6c0,0,1.1,18.1,16.1,7.9"/>',
                        '<path fill="none" stroke="#B40005" stroke-width="2" stroke-miterlimit="10" d="M262.3,177c0,0,13.3-12.3,17.1,5.5"/>',
                        '<path fill="none" stroke="#B40005" stroke-width="2" stroke-miterlimit="10" d="M291,163.5c0,0-17.2,1.9-6.8,15.7"/>'
                    )
                )
            );
    }

    /// @notice Return the expression name of the given id
    /// @param id The expression Id
    function getItemNameById(uint8 id) public pure returns (string memory name) {
        name = "";
        if (id == 1) {
            name = "Expressionless";
        } else if (id == 2) {
            name = "Blush Cheeks";
        } else if (id == 3) {
            name = "Blush";
        } else if (id == 4) {
            name = "Dark Circle";
        } else if (id == 5) {
            name = "Blase";
        } else if (id == 6) {
            name = "Sweat";
        } else if (id == 7) {
            name = "Angry";
        }
    }

    /// @dev The base SVG for the eyes
    function base(string memory children) private pure returns (string memory) {
        return string(abi.encodePacked('<g id="Expressions">', children, "</g>"));
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
    string internal constant BLUE = "18D2F5";
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "./IERC721Enumerable.sol";

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
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/LinkTokenInterface.sol";

import "./VRFRequestIDBase.sol";

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constuctor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator, _link) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash), and have told you the minimum LINK
 * @dev price for VRF service. Make sure your contract has sufficient LINK, and
 * @dev call requestRandomness(keyHash, fee, seed), where seed is the input you
 * @dev want to generate randomness from.
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomness method.
 *
 * @dev The randomness argument to fulfillRandomness is the actual random value
 * @dev generated from your seed.
 *
 * @dev The requestId argument is generated from the keyHash and the seed by
 * @dev makeRequestId(keyHash, seed). If your contract could have concurrent
 * @dev requests open, you can use the requestId to track which seed is
 * @dev associated with which randomness. See VRFRequestIDBase.sol for more
 * @dev details. (See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.)
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ. (Which is critical to making unpredictable randomness! See the
 * @dev next section.)
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the ultimate input to the VRF is mixed with the block hash of the
 * @dev block in which the request is made, user-provided seeds have no impact
 * @dev on its economic security properties. They are only included for API
 * @dev compatability with previous versions of this contract.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request.
 */
abstract contract VRFConsumerBase is VRFRequestIDBase {
    /**
     * @notice fulfillRandomness handles the VRF response. Your contract must
     * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
     * @notice principles to keep in mind when implementing your fulfillRandomness
     * @notice method.
     *
     * @dev VRFConsumerBase expects its subcontracts to have a method with this
     * @dev signature, and will call it once it has verified the proof
     * @dev associated with the randomness. (It is triggered via a call to
     * @dev rawFulfillRandomness, below.)
     *
     * @param requestId The Id initially returned by requestRandomness
     * @param randomness the VRF output
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal virtual;

    /**
     * @dev In order to keep backwards compatibility we have kept the user
     * seed field around. We remove the use of it because given that the blockhash
     * enters later, it overrides whatever randomness the used seed provides.
     * Given that it adds no security, and can easily lead to misunderstandings,
     * we have removed it from usage and can now provide a simpler API.
     */
    uint256 private constant USER_SEED_PLACEHOLDER = 0;

    /**
     * @notice requestRandomness initiates a request for VRF output given _seed
     *
     * @dev The fulfillRandomness method receives the output, once it's provided
     * @dev by the Oracle, and verified by the vrfCoordinator.
     *
     * @dev The _keyHash must already be registered with the VRFCoordinator, and
     * @dev the _fee must exceed the fee specified during registration of the
     * @dev _keyHash.
     *
     * @dev The _seed parameter is vestigial, and is kept only for API
     * @dev compatibility with older versions. It can't *hurt* to mix in some of
     * @dev your own randomness, here, but it's not necessary because the VRF
     * @dev oracle will mix the hash of the block containing your request into the
     * @dev VRF seed it ultimately uses.
     *
     * @param _keyHash ID of public key against which randomness is generated
     * @param _fee The amount of LINK to send with the request
     *
     * @return requestId unique ID for this request
     *
     * @dev The returned requestId can be used to distinguish responses to
     * @dev concurrent requests. It is passed as the first argument to
     * @dev fulfillRandomness.
     */
    function requestRandomness(bytes32 _keyHash, uint256 _fee) internal returns (bytes32 requestId) {
        LINK.transferAndCall(vrfCoordinator, _fee, abi.encode(_keyHash, USER_SEED_PLACEHOLDER));
        // This is the seed passed to VRFCoordinator. The oracle will mix this with
        // the hash of the block containing this request to obtain the seed/input
        // which is finally passed to the VRF cryptographic machinery.
        uint256 vRFSeed = makeVRFInputSeed(_keyHash, USER_SEED_PLACEHOLDER, address(this), nonces[_keyHash]);
        // nonces[_keyHash] must stay in sync with
        // VRFCoordinator.nonces[_keyHash][this], which was incremented by the above
        // successful LINK.transferAndCall (in VRFCoordinator.randomnessRequest).
        // This provides protection against the user repeating their input seed,
        // which would result in a predictable/duplicate output, if multiple such
        // requests appeared in the same block.
        nonces[_keyHash] = nonces[_keyHash] + 1;
        return makeRequestId(_keyHash, vRFSeed);
    }

    LinkTokenInterface internal immutable LINK;
    address private immutable vrfCoordinator;

    // Nonces for each VRF key from which randomness has been requested.
    //
    // Must stay in sync with VRFCoordinator[_keyHash][this]
    mapping(bytes32 => uint256) /* keyHash */ /* nonce */
        private nonces;

    /**
     * @param _vrfCoordinator address of VRFCoordinator contract
     * @param _link address of LINK token contract
     *
     * @dev https://docs.chain.link/docs/link-token-contracts
     */
    constructor(address _vrfCoordinator, address _link) {
        vrfCoordinator = _vrfCoordinator;
        LINK = LinkTokenInterface(_link);
    }

    // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
    // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
    // the origin of the call
    function rawFulfillRandomness(bytes32 requestId, uint256 randomness) external {
        require(msg.sender == vrfCoordinator, "Only VRFCoordinator can fulfill");
        fulfillRandomness(requestId, randomness);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

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
                return retval == IERC721Receiver(to).onERC721Received.selector;
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721.sol";

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

// SPDX-License-Identifier: MIT

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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

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

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface LinkTokenInterface {
    function allowance(address owner, address spender) external view returns (uint256 remaining);

    function approve(address spender, uint256 value) external returns (bool success);

    function balanceOf(address owner) external view returns (uint256 balance);

    function decimals() external view returns (uint8 decimalPlaces);

    function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);

    function increaseApproval(address spender, uint256 subtractedValue) external;

    function name() external view returns (string memory tokenName);

    function symbol() external view returns (string memory tokenSymbol);

    function totalSupply() external view returns (uint256 totalTokensIssued);

    function transfer(address to, uint256 value) external returns (bool success);

    function transferAndCall(
        address to,
        uint256 value,
        bytes calldata data
    ) external returns (bool success);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool success);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract VRFRequestIDBase {
    /**
     * @notice returns the seed which is actually input to the VRF coordinator
     *
     * @dev To prevent repetition of VRF output due to repetition of the
     * @dev user-supplied seed, that seed is combined in a hash with the
     * @dev user-specific nonce, and the address of the consuming contract. The
     * @dev risk of repetition is mostly mitigated by inclusion of a blockhash in
     * @dev the final seed, but the nonce does protect against repetition in
     * @dev requests which are included in a single block.
     *
     * @param _userSeed VRF seed input provided by user
     * @param _requester Address of the requesting contract
     * @param _nonce User-specific nonce at the time of the request
     */
    function makeVRFInputSeed(
        bytes32 _keyHash,
        uint256 _userSeed,
        address _requester,
        uint256 _nonce
    ) internal pure returns (uint256) {
        return uint256(keccak256(abi.encode(_keyHash, _userSeed, _requester, _nonce)));
    }

    /**
     * @notice Returns the id for this request
     * @param _keyHash The serviceAgreement ID to be used for this request
     * @param _vRFInputSeed The seed to be passed directly to the VRF
     * @return The id for this request
     *
     * @dev Note that _vRFInputSeed is not the seed passed by the consuming
     * @dev contract, but the one generated by makeVRFInputSeed
     */
    function makeRequestId(bytes32 _keyHash, uint256 _vRFInputSeed) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_keyHash, _vRFInputSeed));
    }
}

{
  "metadata": {
    "bytecodeHash": "none"
  },
  "optimizer": {
    "enabled": true,
    "runs": 800
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {
    "contracts/libraries/details/AccessoryDetail.sol": {
      "AccessoryDetail": "0xe42d48a0b2bb6149a3bc39c2b02a0402c55caf36"
    },
    "contracts/libraries/details/BackgroundDetail.sol": {
      "BackgroundDetail": "0xc8fd386d44b2de829da057d2b7987e3fc25a87bc"
    },
    "contracts/libraries/details/BodyDetail.sol": {
      "BodyDetail": "0x8edb600ed2cae5669ebc6c31b9ebeeb0d2e8def1"
    },
    "contracts/libraries/details/EarringsDetail.sol": {
      "EarringsDetail": "0xb79e9ba483185478d6b0405e5754128dcfbb3e82"
    },
    "contracts/libraries/details/ExpressionDetail.sol": {
      "ExpressionDetail": "0x20d374b8c8b48e5d8c234b4d5dc8411e16bb97f6"
    },
    "contracts/libraries/details/EyebrowDetail.sol": {
      "EyebrowDetail": "0xa4e299943020ee48de2bd59d09770dd3414a3ecd"
    },
    "contracts/libraries/details/EyesDetail.sol": {
      "EyesDetail": "0x4ea2466ce99c5201820d2b8e2195a4d48e801f84"
    },
    "contracts/libraries/details/HairDetail.sol": {
      "HairDetail": "0x0c8233f5c2134d0d4755a73a58e95f5f6e98845d"
    },
    "contracts/libraries/details/MouthDetail.sol": {
      "MouthDetail": "0x3147d430762b3b4f7389cfd670ff1925de3aea96"
    },
    "contracts/libraries/details/NoseDetail.sol": {
      "NoseDetail": "0x9a9de6a90401342aa3cbdf556bfe1375de9dc297"
    },
    "contracts/libraries/details/TatooDetail.sol": {
      "TatooDetail": "0xd95cc21d374c31e853423691ced0697de14c45df"
    }
  }
}