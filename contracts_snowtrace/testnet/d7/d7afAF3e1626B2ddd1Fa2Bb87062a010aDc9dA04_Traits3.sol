// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Strings.sol";
import "./ITraits.sol";
import "./IPoliceAndThief.sol";

contract Traits3 is Ownable, ITraits {

    using Strings for uint256;

    uint256 private alphaTypeIndex = 17;

    // struct to store each trait's data for metadata and rendering
    struct Trait {
        string name;
        string png;
    }

    string policeBody;
    string thiefBody;

    // mapping from trait type (index) to its name
    string[9] _traitTypes = [
    "Uniform",
    "Clothes",
    "Hair",
    "Facial Hair",
    "Eyes",
    "Headgear",
    "Accessory",
    "Neck Gear",
    "Alpha"
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

    IPoliceAndThief public policeAndThief;


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
        uint8 modOf = traitCountForType[traitType] > 0 ? traitCountForType[traitType] : 10;
        return uint8(seed % modOf);
    }

    /***ADMIN */

    function setGame(address _policeAndThief) external onlyOwner {
        policeAndThief = IPoliceAndThief(_policeAndThief);
    }

    function uploadBodies(string calldata _police, string calldata _thief) external onlyOwner {
        policeBody = _police;
        thiefBody = _thief;
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
    }

    function setTraitCountForType(uint8[] memory _tType, uint8[] memory _len) public onlyOwner {
        for (uint i = 0; i < _tType.length; i++) {
            traitCountForType[_tType[i]] = _len[i];
        }
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
   * @return a valid SVG of the Thief / Police
   */
    function drawSVG(uint256 tokenId) public view returns (string memory) {
        IPoliceAndThief.ThiefPolice memory s = policeAndThief.getTokenTraits(tokenId);
        uint8 shift = s.isThief ? 0 : 10;

        string memory svgString = string(abi.encodePacked(
                s.isThief ? draw(thiefBody) : draw(policeBody),
                drawTrait(traitData[0 + shift][s.uniform % traitCountForType[0 + shift]]),
                drawTrait(traitData[1 + shift][s.hair % traitCountForType[1 + shift]]),
                drawTrait(traitData[2 + shift][s.facialHair % traitCountForType[2 + shift]]),
                drawTrait(traitData[3 + shift][s.eyes % traitCountForType[3 + shift]]),
                drawTrait(traitData[4 + shift][s.accessory % traitCountForType[4 + shift]]),
                s.isThief ? drawTrait(traitData[5 + shift][s.headgear % traitCountForType[5 + shift]]) : drawTrait(traitData[5 + shift][s.alphaIndex]),
                !s.isThief ? drawTrait(traitData[6 + shift][s.neckGear % traitCountForType[6 + shift]]) : ''
            ));

        return string(abi.encodePacked(
                '<svg id="policeAndThief" width="100%" height="100%" version="1.1" viewBox="0 0 40 40" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">',
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
        IPoliceAndThief.ThiefPolice memory s = policeAndThief.getTokenTraits(tokenId);
        string memory traits;
        if (s.isThief) {
            traits = string(abi.encodePacked(
                    attributeForTypeAndValue(_traitTypes[1], traitData[0][s.uniform % traitCountForType[0]].name), ',',
                    attributeForTypeAndValue(_traitTypes[2], traitData[1][s.hair % traitCountForType[1]].name), ',',
                    attributeForTypeAndValue(_traitTypes[3], traitData[2][s.facialHair % traitCountForType[2]].name), ',',
                    attributeForTypeAndValue(_traitTypes[4], traitData[3][s.eyes % traitCountForType[3]].name), ',',
                    attributeForTypeAndValue(_traitTypes[6], traitData[4][s.accessory % traitCountForType[4]].name), ',',
                    attributeForTypeAndValue(_traitTypes[5], traitData[5][s.headgear % traitCountForType[5]].name), ','
                ));
        } else {
            traits = string(abi.encodePacked(
                    attributeForTypeAndValue(_traitTypes[0], traitData[10][s.uniform % traitCountForType[10]].name), ',',
                    attributeForTypeAndValue(_traitTypes[2], traitData[11][s.hair % traitCountForType[11]].name), ',',
                    attributeForTypeAndValue(_traitTypes[3], traitData[12][s.facialHair % traitCountForType[12]].name), ',',
                    attributeForTypeAndValue(_traitTypes[4], traitData[13][s.eyes % traitCountForType[13]].name), ',',
                    attributeForTypeAndValue(_traitTypes[6], traitData[14][s.accessory % traitCountForType[14]].name), ',',
                    attributeForTypeAndValue(_traitTypes[5], traitData[15][s.alphaIndex % traitCountForType[15]].name), ',',
                    attributeForTypeAndValue(_traitTypes[7], traitData[16][s.neckGear % traitCountForType[16]].name), ',',
                    attributeForTypeAndValue("Alpha Score", _alphas[s.alphaIndex]), ','
                ));
        }
        return string(abi.encodePacked(
                '[',
                traits,
                '{"trait_type":"Generation","value":',
                tokenId <= policeAndThief.getPaidTokens() ? '"Gen 0"' : '"Gen 1"',
                '},{"trait_type":"Type","value":',
                s.isThief ? '"Thief"' : '"Police"',
                '}]'
            ));
    }

    /**
     * generates a base64 encoded metadata response without referencing off-chain content
     * @param tokenId the ID of the token to generate the metadata for
   * @return a base64 encoded JSON dictionary of the token's metadata and SVG
   */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        IPoliceAndThief.ThiefPolice memory s = policeAndThief.getTokenTraits(tokenId);

        string memory metadata = string(abi.encodePacked(
                '{"name": "',
                s.isThief ? 'Thief #' : 'Police #',
                tokenId.toString(),
                '", "description": "Police & Thief Game is a new generation play-to-earn NFT game on Avalanche that incorporates probability-based derivatives alongside NFTs. Through a vast array of choices and decision-making possibilities, Police & Thief Game promises to instil excitement and curiosity amongst the community as every individual adopts different strategies to do better than one another and to come out on top. The real question is, are you #TeamThief or #TeamPolice? Choose wisely or watch the other get rich!", "image": "data:image/svg+xml;base64,',
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