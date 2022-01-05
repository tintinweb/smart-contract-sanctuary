// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Strings.sol";
import "./ITraits.sol";
import "./ICnM.sol";

contract Traits is Ownable, ITraits {

    using Strings for uint256;

    // struct to store each trait's data for metadata and rendering
    struct Trait {
        string name;
        string png;
    }

    // mapping from trait type (index) to its name
    string[13] private _traitTypes = [
    "Body",
    "Color",
    "Eyes",
    "Eyebrows",
    "Neck",
    "Glasses",
    "Hair",
    "Head",
    "Markings",
    "Mouth",
    "Nose",
    "Props",
    "Shirts"
    ];

    // storage of each traits name and base64 PNG data (traitType => (traitId => Trait))
    mapping(uint8 => mapping(uint8 => Trait)) public traitData;


    ICnM public cnmNFT;

    constructor() {}

    /** ADMIN */

    function setCnM(address _cnmNFT) external onlyOwner {
        cnmNFT = ICnM(_cnmNFT);
    }

    // Cat traitType : 1, 2, 9, 8, 11
    // 1: 5, 2: 11, 9: 3, 11: 7, 8: 3

    // Crazy Cat traitType : 13, 16, 15, 18, 19, 25
    // 13: 2, 16: 3, 15: 2, 18: 3, 19: 8, 25: 3

    // Mice traitType: 26, 27, 28, 33, 35, 36
    // 26: 4, 27: 10, 28: 10, 33: 9, 35: 5, 36: 2

    /**
     * administrative to upload the names and images associated with each trait
     * @param traitType the trait type to upload the traits for (see traitTypes for a mapping)
     * @param traits the names and base64 encoded PNGs for each trait
     * @param traitIds the ids for traits
   */
    function uploadTraits(uint8 traitType, uint8[] calldata traitIds, Trait[] calldata traits) external onlyOwner {
        require(traitIds.length == traits.length, "Mismatched inputs");
        for (uint i = 0; i < traits.length; i++) {
            traitData[traitType][traitIds[i]] = Trait(
                traits[i].name,
                traits[i].png
            );
        }
    }

    /** RENDER */

    /**
     * generates an <image> element using base64 encoded PNGs
     * @param trait the trait storing the PNG data
   * @return the <image> element
   */
    function drawTrait(Trait memory trait) internal pure returns (string memory) {
        return string(abi.encodePacked(
                '<image x="4" y="4" width="32" height="32" image-rendering="pixelated" preserveAspectRatio="xMidYMid" xlink:href="data:image/png;base64,',
                trait.png,
                '"/>'
            ));
    }

    /**
     * generates an entire SVG by composing multiple <image> elements of PNGs
     * @param tokenId the ID of the token to generate an SVG for
   * @return a valid SVG of the Cat / Mouse / Crazy cat
   */
    function drawSVG(uint256 tokenId) internal view returns (string memory) {
        ICnM.CatMouse memory s = cnmNFT.getTokenTraits(tokenId);
        // Trait data indexes 0 - 12 are reserved for Cats
        // Trait data indexes 13 - 25 are reserved for Crazy Cats
        // Trait data indexes 26 - 38 are reserved for Mouse.
        string memory svgString;
        if (s.isCat) {
            if (s.isCrazy) {
                // crazy cats
                svgString = string(abi.encodePacked(
                        drawTrait(traitData[13][s.body]),
                        drawTrait(traitData[16][s.eyebrows]),
                        drawTrait(traitData[15][s.eyes]),
                        drawTrait(traitData[18][s.glasses]),
                        drawTrait(traitData[19][s.hair]),
                        drawTrait(traitData[25][s.shirts])
                    ));
            } else {
                // cats
                svgString = string(abi.encodePacked(
                        drawTrait(traitData[1][s.color]),
                        drawTrait(traitData[2][s.eyes]),
                        drawTrait(traitData[9][s.mouth]),
                        drawTrait(traitData[8][s.markings]),
                        drawTrait(traitData[11][s.props])
                    ));
            }
        } else {
            // mice
            svgString = string(abi.encodePacked(
                    drawTrait(traitData[26][s.body]),
                    drawTrait(traitData[27][s.color]),
                    drawTrait(traitData[28][s.eyes]),
                    drawTrait(traitData[33][s.head]),
                    drawTrait(traitData[35][s.mouth]),
                    drawTrait(traitData[36][s.nose])
                ));
        }


        return string(abi.encodePacked(
                '<svg id="cnmNFT" width="100%" height="100%" version="1.1" viewBox="0 0 40 40" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">',
                svgString,
                "</svg>"
            ));
    }

    /**
     * generates an attribute for the attributes array in the ERC721 metadata standard
     * @param traitType the trait type to reference as the metadata key
   * @param value the token's trait associated with the key
   * @return a JSON dictionary for the single attribute
   */
    function attributeForTypeAndValue(string memory traitType, string memory value) internal pure returns (string memory) {
        return string(abi.encodePacked(
                '{"trait_type":"',
                traitType,
                '","value":"',
                value,
                '"}'
            ));
    }

    /**
     * generates an array composed of all the individual traits and values
     * @param tokenId the ID of the token to compose the metadata for
   * @return a JSON array of all of the attributes for given token ID
   */
    function compileAttributes(uint256 tokenId) internal view returns (string memory) {
        ICnM.CatMouse memory s = cnmNFT.getTokenTraits(tokenId);
        string memory traits;
        if (s.isCat) {
            if (s.isCrazy) {
                traits = string(abi.encodePacked(
                        attributeForTypeAndValue(_traitTypes[0], traitData[13][s.body].name), ',',
                        attributeForTypeAndValue(_traitTypes[3], traitData[16][s.eyebrows].name), ',',
                        attributeForTypeAndValue(_traitTypes[2], traitData[15][s.eyes].name), ',',
                        attributeForTypeAndValue(_traitTypes[5], traitData[18][s.glasses].name), ',',
                        attributeForTypeAndValue(_traitTypes[6], traitData[19][s.hair].name), ',',
                        attributeForTypeAndValue(_traitTypes[12], traitData[25][s.shirts].name), ','
                    ));
            } else {
                traits = string(abi.encodePacked(
                        attributeForTypeAndValue(_traitTypes[1], traitData[1][s.color].name), ',',
                        attributeForTypeAndValue(_traitTypes[2], traitData[2][s.eyes].name), ',',
                        attributeForTypeAndValue(_traitTypes[9], traitData[9][s.mouth].name), ',',
                        attributeForTypeAndValue(_traitTypes[11], traitData[11][s.props].name), ',',
                        attributeForTypeAndValue(_traitTypes[8], traitData[8][s.markings].name), ','
                    ));
            }
        } else {
            traits = string(abi.encodePacked(
                    attributeForTypeAndValue(_traitTypes[0], traitData[26][s.body].name), ',',
                    attributeForTypeAndValue(_traitTypes[1], traitData[27][s.color].name), ',',
                    attributeForTypeAndValue(_traitTypes[2], traitData[28][s.eyes].name), ',',
                    attributeForTypeAndValue(_traitTypes[7], traitData[33][s.head].name), ',',
                    attributeForTypeAndValue(_traitTypes[9], traitData[35][s.mouth].name), ',',
                    attributeForTypeAndValue(_traitTypes[10], traitData[36][s.nose].name), ','
                ));
        }
        return string(abi.encodePacked(
                '[',
                traits,
                '{"trait_type":"Generation","value":',
                tokenId <= cnmNFT.getPaidTokens() ? '"Gen 0"' : '"Gen 1"',
                '},{"trait_type":"Type","value":',
                s.isCat ? s.isCrazy ? '"Crazy Cat Lady"' : '"Cat"' : '"Mouse"',
                '}]'
            ));
    }

    /**
     * generates a base64 encoded metadata response without referencing off-chain content
     * @param tokenId the ID of the token to generate the metadata for
   * @return a base64 encoded JSON dictionary of the token's metadata and SVG
   */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_msgSender() == address(cnmNFT), "hmmmm what doing?");
        ICnM.CatMouse memory s = cnmNFT.getTokenTraits(tokenId);

        string memory metadata = string(abi.encodePacked(
                '{"name": "',
                s.isCat ? s.isCrazy ? 'Crazy Cat Lady #' : 'Cat #' : 'Mouse #',
                tokenId.toString(),
                '", "description": "Thousands of Cats and Mice compete in a habitat in the metadata. A tempting prize of $CHEDDAR awaits, with deadly high stakes. All the metadata and images are generated and stored 100% on-chain. No IPFS. NO API. Just the Ethereum blockchain.", "image": "data:image/svg+xml;base64,',
                base64(bytes(drawSVG(tokenId))),
                '", "attributes":',
                compileAttributes(tokenId),
                "}"
            ));

        return string(abi.encodePacked(
                "data:application/json;base64,",
                base64(bytes(metadata))
            ));
    }


    string internal constant TABLE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

    function base64(bytes memory data) internal pure returns (string memory) {
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
                mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(6, input), 0x3F)))))
                resultPtr := add(resultPtr, 1)
                mstore(resultPtr, shl(248, mload(add(tablePtr, and(input, 0x3F)))))
                resultPtr := add(resultPtr, 1)
            }

        // padding with '='
            switch mod(mload(data), 3)
            case 1 {mstore(sub(resultPtr, 2), shl(240, 0x3d3d))}
            case 2 {mstore(sub(resultPtr, 1), shl(248, 0x3d))}
        }

        return result;
    }
}