// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Strings.sol";
import "./ITraits.sol";
import "./ITaxOfficersVsDegens.sol";

contract Traits is Ownable, ITraits {

    using Strings for uint256;

    uint256 private alphaTypeIndex = 17;

    // struct to store each trait's data for metadata and rendering
    struct Trait {
        string name;
        string png;
    }

    string taxOfficerBody;
    string DegenBody;

    // mapping from trait type (index) to its name
    string[10] _traitTypes = [
        //For Degen 
        "DegenBody",
        "Accessories",
        "Glasses",
        "Chains",
        "Hats",

        //For TaxOfficers
        "TacOfficerBody",
        "Shoes",
        "Bottom",
        "Hand",
        "Top"
    ];
    // storage of each traits name and base64 PNG data
    mapping(uint8 => mapping(uint8 => Trait)) public traitData;
    mapping(uint8 => uint8) public traitCountForType;
    // mapping from alphaIndex to its score
    string[4] _alphas = [
    "8",
    "7",
    "6",
    "5"
    ];

    ITaxOfficersVsDegens public taxOfficersVsDegens;


    function selectTrait(uint16 seed, uint8 traitType) external view override returns(uint8) {
        if (traitType == alphaTypeIndex) {
            uint256 m = seed % 100;
            if (m > 95) {
                return 0;
            } else if (m > 80) {
                return 1;
            } else if (m > 50) {
                return 2;
            } else {
                return 3;
            }
        }
        return uint8(seed % traitCountForType[traitType]);
    }

    /***ADMIN */

    function setGame(address _taxOfficersVsDegens) external onlyOwner {
        taxOfficersVsDegens = ITaxOfficersVsDegens(_taxOfficersVsDegens);
    }

    function uploadBodies(string calldata _taxOfficer, string calldata _degen) external onlyOwner {
        taxOfficerBody = _taxOfficer;
        DegenBody = _degen;
    }

    /**
     * administrative to upload the names and images associated with each trait
     * @param traitType the trait type to upload the traits for (see traitTypes for a mapping)
   * @param traits the names and base64 encoded PNGs for each trait
   */
    function uploadTraits(uint8 traitType, uint8[] calldata traitIds, Trait[] calldata traits) external onlyOwner {
        require(traitIds.length == traits.length, "Mismatched inputs");
        for (uint i = 0; i < traits.length; i++) {
            traitData[traitType][traitIds[i]] = Trait(
                traits[i].name,
                traits[i].png
            );
        }
        traitCountForType[traitType] += uint8(traits.length);
    }

    /***RENDER */

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

    function draw(string memory png) internal pure returns (string memory) {
        return string(abi.encodePacked(
                '<image x="4" y="4" width="32" height="32" image-rendering="pixelated" preserveAspectRatio="xMidYMid" xlink:href="data:image/png;base64,',
                png,
                '"/>'
            ));
    }

    /**
     * generates an entire SVG by composing multiple <image> elements of PNGs
     * @param tokenId the ID of the token to generate an SVG for
   * @return a valid SVG of the Degen / TaxOfficer
   */
    function drawSVG(uint256 tokenId) public view returns (string memory) {
        ITaxOfficersVsDegens.OfficersDegens memory s = taxOfficersVsDegens.getTokenTraits(tokenId);
        uint8 shift = s.isDegen ? 0 : 10;

        string memory svgString = "";

        if (s.isDegen) {
            svgString = string(
                abi.encodePacked(
                    drawTrait(traitData[0][s.degenBody]),
                   //drawTrait(traitData[1][s.hands]),
                    drawTrait(traitData[1][s.accessories]),
                    drawTrait(traitData[2][s.degenGlasses]),
                    drawTrait(traitData[3][s.chains]),
                    //drawTrait(traitData[5][s.floor]),
                    drawTrait(traitData[4][s.hats])
                )
            );
        } else {
            svgString = string(
                abi.encodePacked(
                    drawTrait(traitData[5][s.taxBody]),
                    drawTrait(traitData[6][s.shoes]),
                    drawTrait(traitData[7][s.bottom]),
                    drawTrait(traitData[8][s.hand]),
                    //drawTrait(traitData[8][s.shirt]),
                    //drawTrait(traitData[12][s.tie]),
                    drawTrait(traitData[9][s.top])
                    //drawTrait(traitData[14][s.nose]),
                    //drawTrait(traitData[15][s.taxCard]),
                    //drawTrait(traitData[16][s.taxGlasses])
                )
            );
        }

        /*string memory svgString = string(abi.encodePacked(
                s.isDegen ? draw(DegenBody) : draw(taxOfficerBody),
                drawTrait(traitData[0 + shift][s.uniform]),
                drawTrait(traitData[1 + shift][s.hair]),
                drawTrait(traitData[2 + shift][s.facialHair]),
                drawTrait(traitData[3 + shift][s.eyes]),
                drawTrait(traitData[4 + shift][s.accessory]),
                s.isDegen ? drawTrait(traitData[5 + shift][s.headgear]) : drawTrait(traitData[5 + shift][s.alphaIndex]),
                !s.isDegen ? drawTrait(traitData[6 + shift][s.neckGear]) : ''
            ));*/

        return string(abi.encodePacked(
                '<svg id="taxOfficersVsDegens" width="100%" height="100%" version="1.1" viewBox="0 0 40 40" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">',
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
    function compileAttributes(uint256 tokenId) public view returns (string memory) {
        ITaxOfficersVsDegens.OfficersDegens memory s = taxOfficersVsDegens.getTokenTraits(tokenId);
        string memory traits;
        if (s.isDegen) {
            traits = string(abi.encodePacked(
                    attributeForTypeAndValue(_traitTypes[0], traitData[0][s.degenBody].name), ',',
                    attributeForTypeAndValue(_traitTypes[1], traitData[1][s.accessories].name), ',',
                    attributeForTypeAndValue(_traitTypes[2], traitData[2][s.degenGlasses].name), ',',
                    attributeForTypeAndValue(_traitTypes[3], traitData[3][s.chains].name), ',',
                    attributeForTypeAndValue(_traitTypes[4], traitData[4][s.hats].name), ','
                ));
        } else {
            traits = string(abi.encodePacked(
                    attributeForTypeAndValue(_traitTypes[5], traitData[5][s.taxBody].name), ',',
                    attributeForTypeAndValue(_traitTypes[6], traitData[6][s.shoes].name), ',',
                    attributeForTypeAndValue(_traitTypes[7], traitData[7][s.bottom].name), ',',
                    attributeForTypeAndValue(_traitTypes[8], traitData[8][s.hand].name), ',',
                    attributeForTypeAndValue(_traitTypes[9], traitData[9][s.top].name), ',',
                    attributeForTypeAndValue("Alpha Score", _alphas[s.alphaIndex]), ','
                ));
        }
        return string(abi.encodePacked(
                '[',
                traits,
                '{"trait_type":"Generation","value":',
                tokenId <= taxOfficersVsDegens.getPaidTokens() ? '"Gen 0"' : '"Gen 1"',
                '},{"trait_type":"Type","value":',
                s.isDegen ? '"Degen"' : '"TaxOfficer"',
                '}]'
            ));
    }

    /**
     * generates a base64 encoded metadata response without referencing off-chain content
     * @param tokenId the ID of the token to generate the metadata for
   * @return a base64 encoded JSON dictionary of the token's metadata and SVG
   */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        ITaxOfficersVsDegens.OfficersDegens memory s = taxOfficersVsDegens.getTokenTraits(tokenId);

        string memory metadata = string(abi.encodePacked(
                '{"name": "',
                s.isDegen ? 'Degen #' : 'TaxOfficer #',
                tokenId.toString(),
                '", "description": "", "image": "data:image/svg+xml;base64,',
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

    /***BASE 64 - Written by Brech Devos */

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