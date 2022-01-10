// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "Strings.sol";
import {ABDKMath64x64} from "ABDKMath64x64.sol";
import {Base64} from "Base64.sol";
import {Roots} from "Roots.sol";
import "PlanetDetail.sol";

import "SVG.sol";
import "Random.sol";
import "Colors.sol";
import "Animation.sol";
import "Utils.sol";

import "SafeMath.sol";
import "SignedSafeMath.sol";

interface IDynamicMetadata {
    function tokenMetadata(
        uint256 tokenId,
        PlanetDetail[] calldata planets,
        string memory contractAddress
    ) external view returns (string memory);

    function pickRandomColor(uint256 seed_)
        external
        view
        returns (string memory);

    function pickRandomPath(uint256 seed_) external view returns (uint8);
}

contract PlanetMetadata is IDynamicMetadata {
    using Strings for uint256;
    using Strings for uint16;
    using Utils for int16;
    using SafeMath for uint256;
    using SafeMath for uint8;
    using SafeMath for uint16;
    using SignedSafeMath for int256;

    struct ERC721MetadataStructure {
        bool isImageLinked;
        string name;
        string description;
        string createdBy;
        string image;
        ERC721MetadataAttribute[] attributes;
    }

    struct ERC721MetadataAttribute {
        bool includeDisplayType;
        bool includeTraitType;
        bool isValueAString;
        bool includeMaxValue;
        string displayType;
        string traitType;
        string value;
        string maxValue;
    }

    using ABDKMath64x64 for int128;
    using Base64 for string;
    using Roots for uint256;
    using Strings for uint256;
    using Strings for uint64;
    using Animation for PlanetDetail;

    address public owner;

    string private _name;
    string private _imageBaseURI;
    string private _imageExtension;
    uint256 private _maxSize;

    string[] public colorsPool;
    string[24] public pathPatterns;
    uint8[24] public patternThresholds;
    string[24] public pathPatternNames;

    //    string[] private _imageParts;

    /**
     * We use a randomed pool to generate a planet
     */
    constructor() {
        owner = msg.sender;
        _name = "Little Planet NFT";
        _imageBaseURI = ""; // Set to empty string - results in on-chain SVG generation by default unless this is set later
        _imageExtension = ""; // Set to empty string - can be changed later to remain empty, .png, .mp4, etc
        _maxSize = 800;

        _initColors();
        _initPathPatterns();
        /*
        _imageParts.push(
            "<svg xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink' width='500' height='500' viewplanet='-800 -800 1600 1600'>"
        );
        _imageParts.push(
            "<rect id='svg_3' height='1600' width='1600' y='-800' x='-800' stroke='#000' fill='#049191'/>"
        );
        _imageParts.push(
            "<path d='M-800,0 Q-400,-300 0,0 T800,0 L800 800 L-800 800 L -800 0 Z' fill='#B8860B' stroke='#B8860B' stroke-width='5'/>"
        );
        _imageParts.push(
            "<line x1='0' y1='0' x2='0' y2='800' style='stroke:#008000;stroke-width:30' />"
        );
        _imageParts.push(
            "<use xlink:href='#body' stroke-width='38' stroke='#008000'/>"
        );
        _imageParts.push("<g id='body' fill='#98FB98'>");
        _imageParts.push(
            "    <path id='leave' d='m-5 500 Q-100 450 -200 300 Q-100 300 -5 500 Z' />"
        );
        _imageParts.push(
            "    <path id='leave' d='m5 600 Q100 550 200 400 Q100 400 5 600 Z' />"
        );
        _imageParts.push("</g>");
        _imageParts.push(
            "<use xlink:href='#flower' stroke-width='38' stroke='#000'>"
        );
        _imageParts.push(
            "<animateTransform attributeName='transform' begin='0s' dur='10s' type='rotate' from='0 0 0' to='360 0 0' repeatCount='indefinite'/>"
        );
        _imageParts.push("</use>");
        _imageParts.push("<g id='flower' fill='#ffb13b'>");
        _imageParts.push(
            "    <path id='petal' d='m0 -300 Q100 0 0 300 Q-100 0 0 -300 Z' />"
        );
        _imageParts.push(
            "    <use xlink:href='#petal' transform='rotate(45)'/>"
        );
        _imageParts.push(
            "    <use xlink:href='#petal' transform='rotate(90)'/>"
        );
        _imageParts.push(
            "    <use xlink:href='#petal' transform='rotate(135)'/>"
        );
        _imageParts.push("</g>");
        _imageParts.push(
            "<circle cx='0' cy='0' r='40' stroke='#000' stroke-width='4' fill='yellow' />"
        );
        _imageParts.push("</svg>");
*/
    }

    function setName(string calldata name_) external {
        _requireOnlyOwner();
        _name = name_;
    }

    function setImageBaseURI(
        string calldata imageBaseURI_,
        string calldata imageExtension_
    ) external {
        _requireOnlyOwner();
        _imageBaseURI = imageBaseURI_;
        _imageExtension = imageExtension_;
    }

    function setMaxSize(uint256 maxSize_) external {
        _requireOnlyOwner();
        _maxSize = maxSize_;
    }

    function tokenMetadata(
        uint256 tokenId,
        PlanetDetail[] calldata planets,
        string memory contractAddress
    ) external view override returns (string memory) {
        string memory base64Json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        _getJson(tokenId, planets, contractAddress)
                    )
                )
            )
        );
        return
            string(
                abi.encodePacked("data:application/json;base64,", base64Json)
            );
    }

    function pickRandomColor(uint256 seed_)
        external
        view
        override
        returns (string memory)
    {
        return
            colorsPool[
                uint256(
                    Random.uniform(
                        Random.init(seed_),
                        0,
                        int256(colorsPool.length) - 1
                    )
                )
            ];
    }

    function pickRandomPath(uint256 seed_)
        external
        view
        override
        returns (uint8)
    {
        uint16 totalThresholds = 0;

        uint8[24] memory patternThresholdsParams;

        for (uint8 i = 0; i < patternThresholds.length; i++) {
            patternThresholdsParams[i] = patternThresholds[i];
            totalThresholds += patternThresholds[i];
        }

        return
            Random.weighted(
                Random.init(seed_),
                patternThresholdsParams,
                totalThresholds
            );
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function imageBaseURI() public view returns (string memory) {
        return _imageBaseURI;
    }

    function imageExtension() public view returns (string memory) {
        return _imageExtension;
    }

    function maxSize() public view returns (uint256) {
        return _maxSize;
    }

    function getClassString(
        uint256 tokenId,
        uint256 rarity,
        bool isAlpha,
        bool offchainImage
    ) public pure returns (string memory) {
        return _getClassString(tokenId, rarity, isAlpha, offchainImage);
    }

    function _getJson(
        uint256 tokenId,
        PlanetDetail[] calldata planets,
        string memory contractAddress
    ) private view returns (string memory) {
        /*
        string memory imageData = bytes(_imageBaseURI).length == 0
            ? _getSvg(tokenId, val)
            : string(abi.encodePacked(imageBaseURI(), imageExtension()));
        */
        string memory imageData = string(
            abi.encodePacked(
                "data:image/svg+xml;base64,",
                Base64.encode(bytes(_getSvg(tokenId, planets, contractAddress)))
            )
        );

        string memory planetName = name();
        if (bytes(planets[0].planetName).length > 0) {
            planetName = planets[0].planetName;
        }

        ERC721MetadataStructure memory metadata = ERC721MetadataStructure({
            isImageLinked: bytes(_imageBaseURI).length > 0,
            name: string(
                abi.encodePacked(planetName, "", " #", tokenId.toString())
            ),
            description: "Little Planets are generated randomly with colors and moving pathes.",
            createdBy: "shujip",
            image: imageData,
            attributes: _getJsonAttributes(tokenId, planets)
        });

        return _generateERC721Metadata(metadata);
    }

    function _getJsonAttributes(
        uint256 tokenId,
        PlanetDetail[] calldata planets
    ) private view returns (ERC721MetadataAttribute[] memory) {
        ERC721MetadataAttribute[]
            memory metadataAttributes = new ERC721MetadataAttribute[](7);

        metadataAttributes[0] = _getERC721MetadataAttribute(
            false,
            true,
            true,
            false,
            "",
            "PATH PATTERN",
            pathPatternNames[planets[0].pathPattern],
            ""
        );
        metadataAttributes[1] = _getERC721MetadataAttribute(
            true,
            true,
            false,
            false,
            "number",
            "History",
            planets[0].history.toString(),
            ""
        );
        metadataAttributes[2] = _getERC721MetadataAttribute(
            true,
            true,
            false,
            false,
            "number",
            "Distance",
            planets[0].distance.toString(),
            ""
        );
        metadataAttributes[3] = _getERC721MetadataAttribute(
            true,
            true,
            false,
            false,
            "number",
            "Radius",
            planets[0].radius.toString(),
            ""
        );
        metadataAttributes[4] = _getERC721MetadataAttribute(
            true,
            true,
            false,
            false,
            "number",
            "Speed",
            uint256(912811 / uint256(planets[0].rotationDuration)).toString(),
            ""
        );
        metadataAttributes[5] = _getERC721MetadataAttribute(
            true,
            true,
            false,
            false,
            "boost_number",
            "Planets Count",
            planets.length.toString(),
            ""
        );
        metadataAttributes[6] = _getERC721MetadataAttribute(
            true,
            true,
            false,
            true,
            "",
            "Varity",
            calculateRarity(planets).toString(),
            "10000"
        );

        //max_value

        return metadataAttributes;
    }

    function _getERC721MetadataAttribute(
        bool includeDisplayType,
        bool includeTraitType,
        bool isValueAString,
        bool includeMaxValue,
        string memory displayType,
        string memory traitType,
        string memory value,
        string memory maxValue
    ) private pure returns (ERC721MetadataAttribute memory) {
        ERC721MetadataAttribute memory attribute = ERC721MetadataAttribute({
            includeDisplayType: includeDisplayType,
            includeTraitType: includeTraitType,
            isValueAString: isValueAString,
            includeMaxValue: includeMaxValue,
            displayType: displayType,
            traitType: traitType,
            value: value,
            maxValue: maxValue
        });

        return attribute;
    }

    function _getSvg(
        uint256 tokenId,
        PlanetDetail[] calldata planets,
        string memory contractAddress
    ) private view returns (string memory) {
        // generate planets (planets + animations)
        string memory planetsSVG = "";
        for (uint256 i = 0; i < planets.length; i++) {
            PlanetDetail memory planet = planets[i];
            planetsSVG = string(
                abi.encodePacked(
                    planetsSVG,
                    SVG._circle(planet, _generatePath(planet))
                )
            );
        }

        string memory signatureWord = "";

        if (bytes(planets[0].planetName).length > 0) {
            signatureWord = string(
                abi.encodePacked(signatureWord, planets[0].planetName, " - ")
            );
        }

        signatureWord = string(
            abi.encodePacked(
                signatureWord,
                "PlanetNFT ",
                planets[0].id.toString(),
                " Smart Contract: ",
                contractAddress,
                " @Ethereum"
            )
        );

        string memory signatureSVG = SVG._text(signatureWord);

        // build up the SVG markup
        return
            SVG._SVG(
                planets[0].bkgColor,
                string(
                    abi.encodePacked(
                        //planet._generateMetadata(dVals, id, owner),
                        planetsSVG,
                        //_generateMirroring(planet.mirroring),
                        signatureSVG
                    )
                )
            );
    }

    function _generatePath(PlanetDetail memory planet)
        private
        view
        returns (string memory)
    {
        if (planet.pathPattern == 0) {
            return
                string(
                    abi.encodePacked(
                        "M ",
                        planet.positionX.toString(),
                        " ",
                        planet.positionY.toString(),
                        "a ",
                        planet.rotationX.toString(),
                        " ",
                        planet.rotationY.toString(),
                        " ",
                        planet.rotationAngle.toString(),
                        ' 1,0 1,0 z" />'
                    )
                );
        } else {
            return pathPatterns[planet.pathPattern];
        }
    }

    function _getScaledRadius(
        uint256 tokenMass,
        uint256 alphaMass,
        uint256 maximumRadius
    ) private pure returns (int128) {
        int128 radiusMass = _getRadius64x64(tokenMass);
        int128 radiusAlphaMass = _getRadius64x64(alphaMass);
        int128 scalePercentage = ABDKMath64x64.div(radiusMass, radiusAlphaMass);
        int128 scaledRadius = ABDKMath64x64.mul(
            ABDKMath64x64.fromUInt(maximumRadius),
            scalePercentage
        );
        if (uint256(int256(scaledRadius.toInt())) == 0) {
            scaledRadius = ABDKMath64x64.fromUInt(1);
        }
        return scaledRadius;
    }

    // Radius = Cube Root(Mass) * Cube Root (0.23873241463)
    // Radius = Cube Root(Mass) * 0.62035049089
    function _getRadius64x64(uint256 mass) private pure returns (int128) {
        int128 cubeRootScalar = ABDKMath64x64.divu(62035049089, 100000000000);
        int128 cubeRootMass = ABDKMath64x64.divu(
            mass.nthRoot(3, 6, 32),
            1000000
        );
        int128 radius = ABDKMath64x64.mul(cubeRootMass, cubeRootScalar);
        return radius;
    }

    function _generateERC721Metadata(ERC721MetadataStructure memory metadata)
        private
        pure
        returns (string memory)
    {
        bytes memory byteString;

        byteString = abi.encodePacked(byteString, _openJsonObject());

        byteString = abi.encodePacked(
            byteString,
            _pushJsonPrimitiveStringAttribute("name", metadata.name, true)
        );

        byteString = abi.encodePacked(
            byteString,
            _pushJsonPrimitiveStringAttribute(
                "description",
                metadata.description,
                true
            )
        );

        byteString = abi.encodePacked(
            byteString,
            _pushJsonPrimitiveStringAttribute(
                "created_by",
                metadata.createdBy,
                true
            )
        );

        if (metadata.isImageLinked) {
            byteString = abi.encodePacked(
                byteString,
                _pushJsonPrimitiveStringAttribute("image", metadata.image, true)
            );
        } else {
            byteString = abi.encodePacked(
                byteString,
                _pushJsonPrimitiveStringAttribute(
                    "image_data",
                    metadata.image,
                    true
                )
            );
        }

        byteString = abi.encodePacked(
            byteString,
            _pushJsonComplexAttribute(
                "attributes",
                _getAttributes(metadata.attributes),
                false
            )
        );

        byteString = abi.encodePacked(byteString, _closeJsonObject());

        return string(byteString);
    }

    function _getAttributes(ERC721MetadataAttribute[] memory attributes)
        private
        pure
        returns (string memory)
    {
        bytes memory byteString;

        byteString = abi.encodePacked(byteString, _openJsonArray());

        for (uint256 i = 0; i < attributes.length; i++) {
            ERC721MetadataAttribute memory attribute = attributes[i];

            byteString = abi.encodePacked(
                byteString,
                _pushJsonArrayElement(
                    _getAttribute(attribute),
                    i < (attributes.length - 1)
                )
            );
        }

        byteString = abi.encodePacked(byteString, _closeJsonArray());

        return string(byteString);
    }

    function _getAttribute(ERC721MetadataAttribute memory attribute)
        private
        pure
        returns (string memory)
    {
        bytes memory byteString;

        byteString = abi.encodePacked(byteString, _openJsonObject());

        if (attribute.includeDisplayType) {
            byteString = abi.encodePacked(
                byteString,
                _pushJsonPrimitiveStringAttribute(
                    "display_type",
                    attribute.displayType,
                    true
                )
            );
        }

        if (attribute.includeTraitType) {
            byteString = abi.encodePacked(
                byteString,
                _pushJsonPrimitiveStringAttribute(
                    "trait_type",
                    attribute.traitType,
                    true
                )
            );
        }

        if (attribute.includeMaxValue) {
            byteString = abi.encodePacked(
                byteString,
                _pushJsonPrimitiveStringAttribute(
                    "max_value",
                    attribute.maxValue,
                    true
                )
            );
        }

        if (attribute.isValueAString) {
            byteString = abi.encodePacked(
                byteString,
                _pushJsonPrimitiveStringAttribute(
                    "value",
                    attribute.value,
                    false
                )
            );
        } else {
            byteString = abi.encodePacked(
                byteString,
                _pushJsonPrimitiveNonStringAttribute(
                    "value",
                    attribute.value,
                    false
                )
            );
        }

        byteString = abi.encodePacked(byteString, _closeJsonObject());

        return string(byteString);
    }

    function _getClassString(
        uint256 tokenId,
        uint256 rarity,
        bool isAlpha,
        bool offchainImage
    ) private pure returns (string memory) {
        bytes memory byteString;

        byteString = abi.encodePacked(byteString, _getRarityClass(rarity));

        if (isAlpha) {
            byteString = abi.encodePacked(
                byteString,
                string(abi.encodePacked(offchainImage ? "_" : " ", "a"))
            );
        }

        uint256 tensDigit = (tokenId % 100) / 10;
        uint256 onesDigit = tokenId % 10;
        uint256 class = tensDigit * 10 + onesDigit;

        byteString = abi.encodePacked(
            byteString,
            string(
                abi.encodePacked(
                    offchainImage ? "_" : " ",
                    _getTokenIdClass(class)
                )
            )
        );

        return string(byteString);
    }

    function _getRarityClass(uint256 rarity)
        private
        pure
        returns (string memory)
    {
        return string(abi.encodePacked("m", rarity.toString()));
    }

    function _getTokenIdClass(uint256 class)
        private
        pure
        returns (string memory)
    {
        return string(abi.encodePacked("c", class.toString()));
    }

    function _checkTag(string storage a, string memory b)
        private
        pure
        returns (bool)
    {
        return (keccak256(abi.encodePacked((a))) ==
            keccak256(abi.encodePacked((b))));
    }

    function _floatToString(int128 value) private pure returns (string memory) {
        uint256 decimal4 = (value & 0xFFFFFFFFFFFFFFFF).mulu(10000);
        return
            string(
                abi.encodePacked(
                    uint256(int256(value.toInt())).toString(),
                    ".",
                    _decimal4ToString(decimal4)
                )
            );
    }

    function _decimal4ToString(uint256 decimal4)
        private
        pure
        returns (string memory)
    {
        bytes memory decimal4Characters = new bytes(4);
        for (uint256 i = 0; i < 4; i++) {
            decimal4Characters[3 - i] = bytes1(uint8(0x30 + (decimal4 % 10)));
            decimal4 /= 10;
        }
        return string(abi.encodePacked(decimal4Characters));
    }

    function _requireOnlyOwner() private view {
        require(msg.sender == owner, "You are not the owner");
    }

    function _openJsonObject() private pure returns (string memory) {
        return string(abi.encodePacked("{"));
    }

    function _closeJsonObject() private pure returns (string memory) {
        return string(abi.encodePacked("}"));
    }

    function _openJsonArray() private pure returns (string memory) {
        return string(abi.encodePacked("["));
    }

    function _closeJsonArray() private pure returns (string memory) {
        return string(abi.encodePacked("]"));
    }

    function _pushJsonPrimitiveStringAttribute(
        string memory key,
        string memory value,
        bool insertComma
    ) private pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '"',
                    key,
                    '": "',
                    value,
                    '"',
                    insertComma ? "," : ""
                )
            );
    }

    function _pushJsonPrimitiveNonStringAttribute(
        string memory key,
        string memory value,
        bool insertComma
    ) private pure returns (string memory) {
        return
            string(
                abi.encodePacked('"', key, '": ', value, insertComma ? "," : "")
            );
    }

    function _pushJsonComplexAttribute(
        string memory key,
        string memory value,
        bool insertComma
    ) private pure returns (string memory) {
        return
            string(
                abi.encodePacked('"', key, '": ', value, insertComma ? "," : "")
            );
    }

    function _pushJsonArrayElement(string memory value, bool insertComma)
        private
        pure
        returns (string memory)
    {
        return string(abi.encodePacked(value, insertComma ? "," : ""));
    }

    function _initColors() internal {
        colorsPool = [
            "#D77186",
            "#61A2DA",
            "#6CB7DA",
            "#b5b5b3",
            "#D75725",
            "#C00559",
            "#DE1F6C",
            "#F3A20D",
            "#F07A13",
            "#DE6716",
            "#171635",
            "#00225D",
            "#763262",
            "#CA7508",
            "#E9A621",
            "#F24D98",
            "#813B7C",
            "#59D044",
            "#F3A002",
            "#F2F44D",
            "#C2151B",
            "#2021A0",
            "#3547B3",
            "#E2C43F",
            "#E0DCDD",
            "#F3C937",
            "#7B533E",
            "#BFA588",
            "#604847",
            "#552723",
            "#E2CACD",
            "#2E7CA8",
            "#F1C061",
            "#DA7338",
            "#741D13",
            "#D6CFC4",
            "#466CA6"
        ];
    }

    function _initPathPatterns() internal {
        /** DEFAULT CIRCLE */
        pathPatterns[0] = "M 0 0a 400 400 0 1,0 1,0 z"; //just for sample
        patternThresholds[0] = 50;
        pathPatternNames[0] = "NORMAL";
        /** HEART PATTERN */
        pathPatterns[
            1
        ] = "M225.92-400c-96 0-192 64-224 160C-64-336-160-400-256-400-416-400-512-304-512-144c0 288 288 352 512 672 192-288 512-384 512-672C512-304 384-400 224-400z";
        patternThresholds[1] = 10;
        pathPatternNames[1] = "HEART";
        /** STAR PATTERN */
        pathPatterns[
            2
        ] = "M-300.48 451.2l768-614.4-921.6 0 768 614.4-307.2-921.6-307.2 921.6z";
        patternThresholds[2] = 5;
        pathPatternNames[2] = "STAR";

        pathPatterns[
            3
        ] = "M-572 14.3C-572-700.7 572 729.3 572 14.3 572-700.7-572 729.3-572 14.3z";
        patternThresholds[3] = 5;
        pathPatternNames[3] = "UNLIMIT CIRCLE";

        pathPatterns[4] = "M-480-340 480-340 0 620z";
        patternThresholds[4] = 5;
        pathPatternNames[4] = "TRIAGLE";
    }

    function updatePathPattern(
        uint8 index,
        string calldata dpath,
        uint8 thresholds,
        string calldata patternName
    ) public {
        _requireOnlyOwner();
        pathPatterns[index] = dpath;
        patternThresholds[index] = thresholds;
        pathPatternNames[index] = patternName;
    }

    function calculateRarity(PlanetDetail[] calldata planets)
        internal
        view
        returns (uint256)
    {
        uint256 chance = 0;
        if (planets[0].id <= 200) {
            //early planet
            chance = 2000 - planets[0].id.mul(10);
        }

        uint8 pattern = 0;
        uint16 radius = 0;
        uint16 sizeScore = 1;

        for (uint16 i = 0; i < planets.length; i++) {
            pattern = planets[0].pathPattern;
            radius = planets[0].radius;
            sizeScore = (radius * 100 + 17000) / 200;

            chance =
                chance +
                uint256(sizeScore)
                    .mul(2000)
                    .div(patternThresholds[pattern] + 50)
                    .div(i + 1);

            if (chance >= 10000) {
                chance = 9999;
                break;
            }
        }

        return chance;
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

// SPDX-License-Identifier: BSD-4-Clause
/*
 * ABDK Math 64.64 Smart Contract Library.  Copyright 漏 2019 by ABDK Consulting.
 * Author: Mikhail Vladimirov <[email protected]>
 */
pragma solidity ^0.8.6;

/**
 * Smart contract library of mathematical functions operating with signed
 * 64.64-bit fixed point numbers.  Signed 64.64-bit fixed point number is
 * basically a simple fraction whose numerator is signed 128-bit integer and
 * denominator is 2^64.  As long as denominator is always the same, there is no
 * need to store it, thus in Solidity signed 64.64-bit fixed point numbers are
 * represented by int128 type holding only the numerator.
 */
library ABDKMath64x64 {
    /*
     * Minimum value signed 64.64-bit fixed point number may have.
     */
    int128 private constant MIN_64x64 = -0x80000000000000000000000000000000;

    /*
     * Maximum value signed 64.64-bit fixed point number may have.
     */
    int128 private constant MAX_64x64 = 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

    /**
     * Convert signed 256-bit integer number into signed 64.64-bit fixed point
     * number.  Revert on overflow.
     *
     * @param x signed 256-bit integer number
     * @return signed 64.64-bit fixed point number
     */
    function fromInt(int256 x) internal pure returns (int128) {
        unchecked {
            require(x >= -0x8000000000000000 && x <= 0x7FFFFFFFFFFFFFFF);
            return int128(x << 64);
        }
    }

    /**
     * Convert signed 64.64 fixed point number into signed 64-bit integer number
     * rounding down.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 64-bit integer number
     */
    function toInt(int128 x) internal pure returns (int64) {
        unchecked {
            return int64(x >> 64);
        }
    }

    /**
     * Convert unsigned 256-bit integer number into signed 64.64-bit fixed point
     * number.  Revert on overflow.
     *
     * @param x unsigned 256-bit integer number
     * @return signed 64.64-bit fixed point number
     */
    function fromUInt(uint256 x) internal pure returns (int128) {
        unchecked {
            require(x <= 0x7FFFFFFFFFFFFFFF);
            return int128(int256(x << 64));
        }
    }

    /**
     * Convert signed 64.64 fixed point number into unsigned 64-bit integer
     * number rounding down.  Revert on underflow.
     *
     * @param x signed 64.64-bit fixed point number
     * @return unsigned 64-bit integer number
     */
    function toUInt(int128 x) internal pure returns (uint64) {
        unchecked {
            require(x >= 0);
            return uint64(uint128(x >> 64));
        }
    }

    /**
     * Convert signed 128.128 fixed point number into signed 64.64-bit fixed point
     * number rounding down.  Revert on overflow.
     *
     * @param x signed 128.128-bin fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function from128x128(int256 x) internal pure returns (int128) {
        unchecked {
            int256 result = x >> 64;
            require(result >= MIN_64x64 && result <= MAX_64x64);
            return int128(result);
        }
    }

    /**
     * Convert signed 64.64 fixed point number into signed 128.128 fixed point
     * number.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 128.128 fixed point number
     */
    function to128x128(int128 x) internal pure returns (int256) {
        unchecked {
            return int256(x) << 64;
        }
    }

    /**
     * Calculate x + y.  Revert on overflow.
     *
     * @param x signed 64.64-bit fixed point number
     * @param y signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function add(int128 x, int128 y) internal pure returns (int128) {
        unchecked {
            int256 result = int256(x) + y;
            require(result >= MIN_64x64 && result <= MAX_64x64);
            return int128(result);
        }
    }

    /**
     * Calculate x - y.  Revert on overflow.
     *
     * @param x signed 64.64-bit fixed point number
     * @param y signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function sub(int128 x, int128 y) internal pure returns (int128) {
        unchecked {
            int256 result = int256(x) - y;
            require(result >= MIN_64x64 && result <= MAX_64x64);
            return int128(result);
        }
    }

    /**
     * Calculate x * y rounding down.  Revert on overflow.
     *
     * @param x signed 64.64-bit fixed point number
     * @param y signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function mul(int128 x, int128 y) internal pure returns (int128) {
        unchecked {
            int256 result = (int256(x) * y) >> 64;
            require(result >= MIN_64x64 && result <= MAX_64x64);
            return int128(result);
        }
    }

    /**
     * Calculate x * y rounding towards zero, where x is signed 64.64 fixed point
     * number and y is signed 256-bit integer number.  Revert on overflow.
     *
     * @param x signed 64.64 fixed point number
     * @param y signed 256-bit integer number
     * @return signed 256-bit integer number
     */
    function muli(int128 x, int256 y) internal pure returns (int256) {
        unchecked {
            if (x == MIN_64x64) {
                require(
                    y >= -0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF &&
                        y <= 0x1000000000000000000000000000000000000000000000000
                );
                return -y << 63;
            } else {
                bool negativeResult = false;
                if (x < 0) {
                    x = -x;
                    negativeResult = true;
                }
                if (y < 0) {
                    y = -y; // We rely on overflow behavior here
                    negativeResult = !negativeResult;
                }
                uint256 absoluteResult = mulu(x, uint256(y));
                if (negativeResult) {
                    require(
                        absoluteResult <=
                            0x8000000000000000000000000000000000000000000000000000000000000000
                    );
                    return -int256(absoluteResult); // We rely on overflow behavior here
                } else {
                    require(
                        absoluteResult <=
                            0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
                    );
                    return int256(absoluteResult);
                }
            }
        }
    }

    /**
     * Calculate x * y rounding down, where x is signed 64.64 fixed point number
     * and y is unsigned 256-bit integer number.  Revert on overflow.
     *
     * @param x signed 64.64 fixed point number
     * @param y unsigned 256-bit integer number
     * @return unsigned 256-bit integer number
     */
    function mulu(int128 x, uint256 y) internal pure returns (uint256) {
        unchecked {
            if (y == 0) return 0;

            require(x >= 0);

            uint256 lo = (uint256(int256(x)) *
                (y & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)) >> 64;
            uint256 hi = uint256(int256(x)) * (y >> 128);

            require(hi <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
            hi <<= 64;

            require(
                hi <=
                    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF -
                        lo
            );
            return hi + lo;
        }
    }

    /**
     * Calculate x / y rounding towards zero.  Revert on overflow or when y is
     * zero.
     *
     * @param x signed 64.64-bit fixed point number
     * @param y signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function div(int128 x, int128 y) internal pure returns (int128) {
        unchecked {
            require(y != 0);
            int256 result = (int256(x) << 64) / y;
            require(result >= MIN_64x64 && result <= MAX_64x64);
            return int128(result);
        }
    }

    /**
     * Calculate x / y rounding towards zero, where x and y are signed 256-bit
     * integer numbers.  Revert on overflow or when y is zero.
     *
     * @param x signed 256-bit integer number
     * @param y signed 256-bit integer number
     * @return signed 64.64-bit fixed point number
     */
    function divi(int256 x, int256 y) internal pure returns (int128) {
        unchecked {
            require(y != 0);

            bool negativeResult = false;
            if (x < 0) {
                x = -x; // We rely on overflow behavior here
                negativeResult = true;
            }
            if (y < 0) {
                y = -y; // We rely on overflow behavior here
                negativeResult = !negativeResult;
            }
            uint128 absoluteResult = divuu(uint256(x), uint256(y));
            if (negativeResult) {
                require(absoluteResult <= 0x80000000000000000000000000000000);
                return -int128(absoluteResult); // We rely on overflow behavior here
            } else {
                require(absoluteResult <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
                return int128(absoluteResult); // We rely on overflow behavior here
            }
        }
    }

    /**
     * Calculate x / y rounding towards zero, where x and y are unsigned 256-bit
     * integer numbers.  Revert on overflow or when y is zero.
     *
     * @param x unsigned 256-bit integer number
     * @param y unsigned 256-bit integer number
     * @return signed 64.64-bit fixed point number
     */
    function divu(uint256 x, uint256 y) internal pure returns (int128) {
        unchecked {
            require(y != 0);
            uint128 result = divuu(x, y);
            require(result <= uint128(MAX_64x64));
            return int128(result);
        }
    }

    /**
     * Calculate -x.  Revert on overflow.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function neg(int128 x) internal pure returns (int128) {
        unchecked {
            require(x != MIN_64x64);
            return -x;
        }
    }

    /**
     * Calculate |x|.  Revert on overflow.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function abs(int128 x) internal pure returns (int128) {
        unchecked {
            require(x != MIN_64x64);
            return x < 0 ? -x : x;
        }
    }

    /**
     * Calculate 1 / x rounding towards zero.  Revert on overflow or when x is
     * zero.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function inv(int128 x) internal pure returns (int128) {
        unchecked {
            require(x != 0);
            int256 result = int256(0x100000000000000000000000000000000) / x;
            require(result >= MIN_64x64 && result <= MAX_64x64);
            return int128(result);
        }
    }

    /**
     * Calculate arithmetics average of x and y, i.e. (x + y) / 2 rounding down.
     *
     * @param x signed 64.64-bit fixed point number
     * @param y signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function avg(int128 x, int128 y) internal pure returns (int128) {
        unchecked {
            return int128((int256(x) + int256(y)) >> 1);
        }
    }

    /**
     * Calculate geometric average of x and y, i.e. sqrt (x * y) rounding down.
     * Revert on overflow or in case x * y is negative.
     *
     * @param x signed 64.64-bit fixed point number
     * @param y signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function gavg(int128 x, int128 y) internal pure returns (int128) {
        unchecked {
            int256 m = int256(x) * int256(y);
            require(m >= 0);
            require(
                m <
                    0x4000000000000000000000000000000000000000000000000000000000000000
            );
            return int128(sqrtu(uint256(m)));
        }
    }

    /**
     * Calculate x^y assuming 0^0 is 1, where x is signed 64.64 fixed point number
     * and y is unsigned 256-bit integer number.  Revert on overflow.
     *
     * @param x signed 64.64-bit fixed point number
     * @param y uint256 value
     * @return signed 64.64-bit fixed point number
     */
    function pow(int128 x, uint256 y) internal pure returns (int128) {
        unchecked {
            bool negative = x < 0 && y & 1 == 1;

            uint256 absX = uint128(x < 0 ? -x : x);
            uint256 absResult;
            absResult = 0x100000000000000000000000000000000;

            if (absX <= 0x10000000000000000) {
                absX <<= 63;
                while (y != 0) {
                    if (y & 0x1 != 0) {
                        absResult = (absResult * absX) >> 127;
                    }
                    absX = (absX * absX) >> 127;

                    if (y & 0x2 != 0) {
                        absResult = (absResult * absX) >> 127;
                    }
                    absX = (absX * absX) >> 127;

                    if (y & 0x4 != 0) {
                        absResult = (absResult * absX) >> 127;
                    }
                    absX = (absX * absX) >> 127;

                    if (y & 0x8 != 0) {
                        absResult = (absResult * absX) >> 127;
                    }
                    absX = (absX * absX) >> 127;

                    y >>= 4;
                }

                absResult >>= 64;
            } else {
                uint256 absXShift = 63;
                if (absX < 0x1000000000000000000000000) {
                    absX <<= 32;
                    absXShift -= 32;
                }
                if (absX < 0x10000000000000000000000000000) {
                    absX <<= 16;
                    absXShift -= 16;
                }
                if (absX < 0x1000000000000000000000000000000) {
                    absX <<= 8;
                    absXShift -= 8;
                }
                if (absX < 0x10000000000000000000000000000000) {
                    absX <<= 4;
                    absXShift -= 4;
                }
                if (absX < 0x40000000000000000000000000000000) {
                    absX <<= 2;
                    absXShift -= 2;
                }
                if (absX < 0x80000000000000000000000000000000) {
                    absX <<= 1;
                    absXShift -= 1;
                }

                uint256 resultShift = 0;
                while (y != 0) {
                    require(absXShift < 64);

                    if (y & 0x1 != 0) {
                        absResult = (absResult * absX) >> 127;
                        resultShift += absXShift;
                        if (absResult > 0x100000000000000000000000000000000) {
                            absResult >>= 1;
                            resultShift += 1;
                        }
                    }
                    absX = (absX * absX) >> 127;
                    absXShift <<= 1;
                    if (absX >= 0x100000000000000000000000000000000) {
                        absX >>= 1;
                        absXShift += 1;
                    }

                    y >>= 1;
                }

                require(resultShift < 64);
                absResult >>= 64 - resultShift;
            }
            int256 result = negative ? -int256(absResult) : int256(absResult);
            require(result >= MIN_64x64 && result <= MAX_64x64);
            return int128(result);
        }
    }

    /**
     * Calculate sqrt (x) rounding down.  Revert if x < 0.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function sqrt(int128 x) internal pure returns (int128) {
        unchecked {
            require(x >= 0);
            return int128(sqrtu(uint256(int256(x)) << 64));
        }
    }

    /**
     * Calculate binary logarithm of x.  Revert if x <= 0.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function log_2(int128 x) internal pure returns (int128) {
        unchecked {
            require(x > 0);

            int256 msb = 0;
            int256 xc = x;
            if (xc >= 0x10000000000000000) {
                xc >>= 64;
                msb += 64;
            }
            if (xc >= 0x100000000) {
                xc >>= 32;
                msb += 32;
            }
            if (xc >= 0x10000) {
                xc >>= 16;
                msb += 16;
            }
            if (xc >= 0x100) {
                xc >>= 8;
                msb += 8;
            }
            if (xc >= 0x10) {
                xc >>= 4;
                msb += 4;
            }
            if (xc >= 0x4) {
                xc >>= 2;
                msb += 2;
            }
            if (xc >= 0x2) msb += 1; // No need to shift xc anymore

            int256 result = (msb - 64) << 64;
            uint256 ux = uint256(int256(x)) << uint256(127 - msb);
            for (int256 bit = 0x8000000000000000; bit > 0; bit >>= 1) {
                ux *= ux;
                uint256 b = ux >> 255;
                ux >>= 127 + b;
                result += bit * int256(b);
            }

            return int128(result);
        }
    }

    /**
     * Calculate natural logarithm of x.  Revert if x <= 0.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function ln(int128 x) internal pure returns (int128) {
        unchecked {
            require(x > 0);

            return
                int128(
                    int256(
                        (uint256(int256(log_2(x))) *
                            0xB17217F7D1CF79ABC9E3B39803F2F6AF) >> 128
                    )
                );
        }
    }

    /**
     * Calculate binary exponent of x.  Revert on overflow.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function exp_2(int128 x) internal pure returns (int128) {
        unchecked {
            require(x < 0x400000000000000000); // Overflow

            if (x < -0x400000000000000000) return 0; // Underflow

            uint256 result = 0x80000000000000000000000000000000;

            if (x & 0x8000000000000000 > 0)
                result = (result * 0x16A09E667F3BCC908B2FB1366EA957D3E) >> 128;
            if (x & 0x4000000000000000 > 0)
                result = (result * 0x1306FE0A31B7152DE8D5A46305C85EDEC) >> 128;
            if (x & 0x2000000000000000 > 0)
                result = (result * 0x1172B83C7D517ADCDF7C8C50EB14A791F) >> 128;
            if (x & 0x1000000000000000 > 0)
                result = (result * 0x10B5586CF9890F6298B92B71842A98363) >> 128;
            if (x & 0x800000000000000 > 0)
                result = (result * 0x1059B0D31585743AE7C548EB68CA417FD) >> 128;
            if (x & 0x400000000000000 > 0)
                result = (result * 0x102C9A3E778060EE6F7CACA4F7A29BDE8) >> 128;
            if (x & 0x200000000000000 > 0)
                result = (result * 0x10163DA9FB33356D84A66AE336DCDFA3F) >> 128;
            if (x & 0x100000000000000 > 0)
                result = (result * 0x100B1AFA5ABCBED6129AB13EC11DC9543) >> 128;
            if (x & 0x80000000000000 > 0)
                result = (result * 0x10058C86DA1C09EA1FF19D294CF2F679B) >> 128;
            if (x & 0x40000000000000 > 0)
                result = (result * 0x1002C605E2E8CEC506D21BFC89A23A00F) >> 128;
            if (x & 0x20000000000000 > 0)
                result = (result * 0x100162F3904051FA128BCA9C55C31E5DF) >> 128;
            if (x & 0x10000000000000 > 0)
                result = (result * 0x1000B175EFFDC76BA38E31671CA939725) >> 128;
            if (x & 0x8000000000000 > 0)
                result = (result * 0x100058BA01FB9F96D6CACD4B180917C3D) >> 128;
            if (x & 0x4000000000000 > 0)
                result = (result * 0x10002C5CC37DA9491D0985C348C68E7B3) >> 128;
            if (x & 0x2000000000000 > 0)
                result = (result * 0x1000162E525EE054754457D5995292026) >> 128;
            if (x & 0x1000000000000 > 0)
                result = (result * 0x10000B17255775C040618BF4A4ADE83FC) >> 128;
            if (x & 0x800000000000 > 0)
                result = (result * 0x1000058B91B5BC9AE2EED81E9B7D4CFAB) >> 128;
            if (x & 0x400000000000 > 0)
                result = (result * 0x100002C5C89D5EC6CA4D7C8ACC017B7C9) >> 128;
            if (x & 0x200000000000 > 0)
                result = (result * 0x10000162E43F4F831060E02D839A9D16D) >> 128;
            if (x & 0x100000000000 > 0)
                result = (result * 0x100000B1721BCFC99D9F890EA06911763) >> 128;
            if (x & 0x80000000000 > 0)
                result = (result * 0x10000058B90CF1E6D97F9CA14DBCC1628) >> 128;
            if (x & 0x40000000000 > 0)
                result = (result * 0x1000002C5C863B73F016468F6BAC5CA2B) >> 128;
            if (x & 0x20000000000 > 0)
                result = (result * 0x100000162E430E5A18F6119E3C02282A5) >> 128;
            if (x & 0x10000000000 > 0)
                result = (result * 0x1000000B1721835514B86E6D96EFD1BFE) >> 128;
            if (x & 0x8000000000 > 0)
                result = (result * 0x100000058B90C0B48C6BE5DF846C5B2EF) >> 128;
            if (x & 0x4000000000 > 0)
                result = (result * 0x10000002C5C8601CC6B9E94213C72737A) >> 128;
            if (x & 0x2000000000 > 0)
                result = (result * 0x1000000162E42FFF037DF38AA2B219F06) >> 128;
            if (x & 0x1000000000 > 0)
                result = (result * 0x10000000B17217FBA9C739AA5819F44F9) >> 128;
            if (x & 0x800000000 > 0)
                result = (result * 0x1000000058B90BFCDEE5ACD3C1CEDC823) >> 128;
            if (x & 0x400000000 > 0)
                result = (result * 0x100000002C5C85FE31F35A6A30DA1BE50) >> 128;
            if (x & 0x200000000 > 0)
                result = (result * 0x10000000162E42FF0999CE3541B9FFFCF) >> 128;
            if (x & 0x100000000 > 0)
                result = (result * 0x100000000B17217F80F4EF5AADDA45554) >> 128;
            if (x & 0x80000000 > 0)
                result = (result * 0x10000000058B90BFBF8479BD5A81B51AD) >> 128;
            if (x & 0x40000000 > 0)
                result = (result * 0x1000000002C5C85FDF84BD62AE30A74CC) >> 128;
            if (x & 0x20000000 > 0)
                result = (result * 0x100000000162E42FEFB2FED257559BDAA) >> 128;
            if (x & 0x10000000 > 0)
                result = (result * 0x1000000000B17217F7D5A7716BBA4A9AE) >> 128;
            if (x & 0x8000000 > 0)
                result = (result * 0x100000000058B90BFBE9DDBAC5E109CCE) >> 128;
            if (x & 0x4000000 > 0)
                result = (result * 0x10000000002C5C85FDF4B15DE6F17EB0D) >> 128;
            if (x & 0x2000000 > 0)
                result = (result * 0x1000000000162E42FEFA494F1478FDE05) >> 128;
            if (x & 0x1000000 > 0)
                result = (result * 0x10000000000B17217F7D20CF927C8E94C) >> 128;
            if (x & 0x800000 > 0)
                result = (result * 0x1000000000058B90BFBE8F71CB4E4B33D) >> 128;
            if (x & 0x400000 > 0)
                result = (result * 0x100000000002C5C85FDF477B662B26945) >> 128;
            if (x & 0x200000 > 0)
                result = (result * 0x10000000000162E42FEFA3AE53369388C) >> 128;
            if (x & 0x100000 > 0)
                result = (result * 0x100000000000B17217F7D1D351A389D40) >> 128;
            if (x & 0x80000 > 0)
                result = (result * 0x10000000000058B90BFBE8E8B2D3D4EDE) >> 128;
            if (x & 0x40000 > 0)
                result = (result * 0x1000000000002C5C85FDF4741BEA6E77E) >> 128;
            if (x & 0x20000 > 0)
                result = (result * 0x100000000000162E42FEFA39FE95583C2) >> 128;
            if (x & 0x10000 > 0)
                result = (result * 0x1000000000000B17217F7D1CFB72B45E1) >> 128;
            if (x & 0x8000 > 0)
                result = (result * 0x100000000000058B90BFBE8E7CC35C3F0) >> 128;
            if (x & 0x4000 > 0)
                result = (result * 0x10000000000002C5C85FDF473E242EA38) >> 128;
            if (x & 0x2000 > 0)
                result = (result * 0x1000000000000162E42FEFA39F02B772C) >> 128;
            if (x & 0x1000 > 0)
                result = (result * 0x10000000000000B17217F7D1CF7D83C1A) >> 128;
            if (x & 0x800 > 0)
                result = (result * 0x1000000000000058B90BFBE8E7BDCBE2E) >> 128;
            if (x & 0x400 > 0)
                result = (result * 0x100000000000002C5C85FDF473DEA871F) >> 128;
            if (x & 0x200 > 0)
                result = (result * 0x10000000000000162E42FEFA39EF44D91) >> 128;
            if (x & 0x100 > 0)
                result = (result * 0x100000000000000B17217F7D1CF79E949) >> 128;
            if (x & 0x80 > 0)
                result = (result * 0x10000000000000058B90BFBE8E7BCE544) >> 128;
            if (x & 0x40 > 0)
                result = (result * 0x1000000000000002C5C85FDF473DE6ECA) >> 128;
            if (x & 0x20 > 0)
                result = (result * 0x100000000000000162E42FEFA39EF366F) >> 128;
            if (x & 0x10 > 0)
                result = (result * 0x1000000000000000B17217F7D1CF79AFA) >> 128;
            if (x & 0x8 > 0)
                result = (result * 0x100000000000000058B90BFBE8E7BCD6D) >> 128;
            if (x & 0x4 > 0)
                result = (result * 0x10000000000000002C5C85FDF473DE6B2) >> 128;
            if (x & 0x2 > 0)
                result = (result * 0x1000000000000000162E42FEFA39EF358) >> 128;
            if (x & 0x1 > 0)
                result = (result * 0x10000000000000000B17217F7D1CF79AB) >> 128;

            result >>= uint256(int256(63 - (x >> 64)));
            require(result <= uint256(int256(MAX_64x64)));

            return int128(int256(result));
        }
    }

    /**
     * Calculate natural exponent of x.  Revert on overflow.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function exp(int128 x) internal pure returns (int128) {
        unchecked {
            require(x < 0x400000000000000000); // Overflow

            if (x < -0x400000000000000000) return 0; // Underflow

            return
                exp_2(
                    int128(
                        (int256(x) * 0x171547652B82FE1777D0FFDA0D23A7D12) >> 128
                    )
                );
        }
    }

    /**
     * Calculate x / y rounding towards zero, where x and y are unsigned 256-bit
     * integer numbers.  Revert on overflow or when y is zero.
     *
     * @param x unsigned 256-bit integer number
     * @param y unsigned 256-bit integer number
     * @return unsigned 64.64-bit fixed point number
     */
    function divuu(uint256 x, uint256 y) private pure returns (uint128) {
        unchecked {
            require(y != 0);

            uint256 result;

            if (x <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
                result = (x << 64) / y;
            else {
                uint256 msb = 192;
                uint256 xc = x >> 192;
                if (xc >= 0x100000000) {
                    xc >>= 32;
                    msb += 32;
                }
                if (xc >= 0x10000) {
                    xc >>= 16;
                    msb += 16;
                }
                if (xc >= 0x100) {
                    xc >>= 8;
                    msb += 8;
                }
                if (xc >= 0x10) {
                    xc >>= 4;
                    msb += 4;
                }
                if (xc >= 0x4) {
                    xc >>= 2;
                    msb += 2;
                }
                if (xc >= 0x2) msb += 1; // No need to shift xc anymore

                result = (x << (255 - msb)) / (((y - 1) >> (msb - 191)) + 1);
                require(result <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);

                uint256 hi = result * (y >> 128);
                uint256 lo = result * (y & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);

                uint256 xh = x >> 192;
                uint256 xl = x << 64;

                if (xl < lo) xh -= 1;
                xl -= lo; // We rely on overflow behavior here
                lo = hi << 128;
                if (xl < lo) xh -= 1;
                xl -= lo; // We rely on overflow behavior here

                assert(xh == hi >> 128);

                result += xl / y;
            }

            require(result <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
            return uint128(result);
        }
    }

    /**
     * Calculate sqrt (x) rounding down, where x is unsigned 256-bit integer
     * number.
     *
     * @param x unsigned 256-bit integer number
     * @return unsigned 128-bit integer number
     */
    function sqrtu(uint256 x) private pure returns (uint128) {
        unchecked {
            if (x == 0) return 0;
            else {
                uint256 xx = x;
                uint256 r = 1;
                if (xx >= 0x100000000000000000000000000000000) {
                    xx >>= 128;
                    r <<= 64;
                }
                if (xx >= 0x10000000000000000) {
                    xx >>= 64;
                    r <<= 32;
                }
                if (xx >= 0x100000000) {
                    xx >>= 32;
                    r <<= 16;
                }
                if (xx >= 0x10000) {
                    xx >>= 16;
                    r <<= 8;
                }
                if (xx >= 0x100) {
                    xx >>= 8;
                    r <<= 4;
                }
                if (xx >= 0x10) {
                    xx >>= 4;
                    r <<= 2;
                }
                if (xx >= 0x8) {
                    r <<= 1;
                }
                r = (r + x / r) >> 1;
                r = (r + x / r) >> 1;
                r = (r + x / r) >> 1;
                r = (r + x / r) >> 1;
                r = (r + x / r) >> 1;
                r = (r + x / r) >> 1;
                r = (r + x / r) >> 1; // Seven iterations should be enough
                uint256 r1 = x / r;
                return uint128(r < r1 ? r : r1);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides functions for encoding/decoding base64
library Base64 {
    string internal constant TABLE_ENCODE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
    bytes internal constant TABLE_DECODE =
        hex"0000000000000000000000000000000000000000000000000000000000000000"
        hex"00000000000000000000003e0000003f3435363738393a3b3c3d000000000000"
        hex"00000102030405060708090a0b0c0d0e0f101112131415161718190000000000"
        hex"001a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132330000000000";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";

        // load the table into memory
        string memory table = TABLE_ENCODE;

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
            for {

            } lt(dataPtr, endPtr) {

            } {
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(
                    resultPtr,
                    mload(add(tablePtr, and(shr(18, input), 0x3F)))
                )
                resultPtr := add(resultPtr, 1)
                mstore8(
                    resultPtr,
                    mload(add(tablePtr, and(shr(12, input), 0x3F)))
                )
                resultPtr := add(resultPtr, 1)
                mstore8(
                    resultPtr,
                    mload(add(tablePtr, and(shr(6, input), 0x3F)))
                )
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }
        }

        return result;
    }

    function decode(string memory _data) internal pure returns (bytes memory) {
        bytes memory data = bytes(_data);

        if (data.length == 0) return new bytes(0);
        require(data.length % 4 == 0, "invalid base64 decoder input");

        // load the table into memory
        bytes memory table = TABLE_DECODE;

        // every 4 characters represent 3 bytes
        uint256 decodedLen = (data.length / 4) * 3;

        // add some extra buffer at the end required for the writing
        bytes memory result = new bytes(decodedLen + 32);

        assembly {
            // padding with '='
            let lastBytes := mload(add(data, mload(data)))
            if eq(and(lastBytes, 0xFF), 0x3d) {
                decodedLen := sub(decodedLen, 1)
                if eq(and(lastBytes, 0xFFFF), 0x3d3d) {
                    decodedLen := sub(decodedLen, 1)
                }
            }

            // set the actual output length
            mstore(result, decodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 4 characters at a time
            for {

            } lt(dataPtr, endPtr) {

            } {
                // read 4 characters
                dataPtr := add(dataPtr, 4)
                let input := mload(dataPtr)

                // write 3 bytes
                let output := add(
                    add(
                        shl(
                            18,
                            and(
                                mload(add(tablePtr, and(shr(24, input), 0xFF))),
                                0xFF
                            )
                        ),
                        shl(
                            12,
                            and(
                                mload(add(tablePtr, and(shr(16, input), 0xFF))),
                                0xFF
                            )
                        )
                    ),
                    add(
                        shl(
                            6,
                            and(
                                mload(add(tablePtr, and(shr(8, input), 0xFF))),
                                0xFF
                            )
                        ),
                        and(mload(add(tablePtr, and(input, 0xFF))), 0xFF)
                    )
                )
                mstore(resultPtr, shl(232, output))
                resultPtr := add(resultPtr, 3)
            }
        }

        return result;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

library Roots {
    // calculates a^(1/n) to dp decimal places
    // maxIts bounds the number of iterations performed
    function nthRoot(
        uint256 _a,
        uint256 _n,
        uint256 _dp,
        uint256 _maxIts
    ) internal pure returns (uint256) {
        assert(_n > 1);

        // The scale factor is a crude way to turn everything into integer calcs.
        // Actually do (a * (10 ^ ((dp + 1) * n))) ^ (1/n)
        // We calculate to one extra dp and round at the end
        uint256 one = 10**(1 + _dp);
        uint256 a0 = one**_n * _a;

        // Initial guess: 1.0
        uint256 xNew = one;

        uint256 iter = 0;
        while (iter < _maxIts) {
            uint256 x = xNew;
            uint256 t0 = x**(_n - 1);
            if (x * t0 > a0) {
                xNew = x - (x - a0 / t0) / _n;
            } else {
                xNew = x + (a0 / t0 - x) / _n;
            }
            ++iter;
            if (xNew == x) {
                break;
            }
        }

        // Round to nearest in the last dp.
        return (xNew + 5) / 10;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >0.6.4;

import "HSL.sol";

struct PlanetDetail {
    uint256 randomness;
    uint256 id;
    /** basic */
    string planetName;
    uint64 history;
    uint64 distance;
    /** bkgColor */
    string bkgColor;
    /** Color **/
    string color;
    string color2;
    /** lineColor **/
    string lineColor;
    /** radius */
    uint16 radius;
    /** path pattern */
    uint8 pathPattern;
    /** position */
    int16 positionX;
    int16 positionY;
    /** rotation */
    uint16 rotationX;
    uint16 rotationY;
    uint16 rotationAngle;
    uint16 rotationDuration;
}

// SPDX-License-Identifier: MIT
pragma solidity >0.6.4;

struct HSL {
    uint16 hue;
    uint8 saturation;
    uint8 lightness;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "Strings.sol";

import "Shape.sol";
import "PlanetDetail.sol";
import "Colors.sol";
import "Utils.sol";

library SVG {
    using Colors for HSL;
    using Strings for uint256;
    using Strings for uint16;
    using Utils for int16;

    /**
     * @dev render a rectangle SVG tag with nested content
     * @param shape object
     * @param slot for nested tags (animations)
     */
    function _rect(Shape memory shape, string memory slot)
        internal
        pure
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    '<rect x="',
                    shape.position[0],
                    '" y="',
                    shape.position[1],
                    '" width="',
                    shape.size[0],
                    '" height="',
                    shape.size[1],
                    '" transform-origin="300 300" style="fill:',
                    Colors.toString(shape.color),
                    bytes(slot).length == 0
                        ? '"/>'
                        : string(abi.encodePacked('">', slot, "</rect>"))
                )
            );
    }

    /**
    create planet and rotation by circle

    <path id="venere" fill="none" stroke="white" stroke-width="2" d="
    M 0, 0
    m 0, -75
    a 400,200 20 1,0 1,0
    z
    " />
    <circle cx="0" cy="0" r="20" fill="green">
        <animateMotion dur="5s" repeatCount="indefinite">
            <mpath xlink:href="#venere" />
        </animateMotion>
    </circle>
    * */
    function _circle(PlanetDetail memory planet, string memory dpath)
        internal
        pure
        returns (string memory)
    {
        //<circle cx="0" cy="0" r="40" stroke="#000" stroke-width="4" fill="yellow" id="circle" />
        return
            string(
                abi.encodePacked(
                    abi.encodePacked(
                        '<defs><linearGradient x1="-50" y1="0" x2="50" y2="0" gradientUnits="userSpaceOnUse" id="planet_color_',
                        planet.id.toString(),
                        '"><stop stop-color="',
                        planet.color,
                        '" offset="0.1"></stop><stop stop-color="',
                        planet.color2,
                        '" offset="0.9"></stop></linearGradient></defs>'
                    ),
                    abi.encodePacked(
                        '<path id="planet_path_',
                        planet.id.toString(),
                        '" fill="none" stroke="',
                        planet.lineColor,
                        '" stroke-width="1" d="',
                        dpath,
                        '" />'
                    ),
                    abi.encodePacked(
                        '<circle cx="0" cy="0" r="',
                        planet.radius.toString(),
                        '" stroke="',
                        planet.lineColor,
                        '" stroke-width="3" fill="url(#planet_color_',
                        planet.id.toString()
                    ),
                    abi.encodePacked(
                        ')" id="planet_',
                        planet.id.toString(),
                        '">',
                        '<animateMotion dur="',
                        planet.rotationDuration.toString(),
                        's" repeatCount="indefinite">',
                        '<mpath xlink:href="#planet_path_',
                        planet.id.toString(),
                        '" />',
                        "</animateMotion>",
                        "</circle>"
                    )
                )
            );
    }

    function _text(string memory text) internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<text x="-750" y="750" fill="white" font-size="20px">',
                    text,
                    "</text>"
                )
            );
    }

    /**
     * @dev render an g(group) SVG tag with attributes
     * @param attr string for attributes
     * @param slot for nested group content
     */
    function _g(string memory attr, string memory slot)
        internal
        pure
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    "<g",
                    bytes(attr).length == 0
                        ? ""
                        : string(abi.encodePacked(" ", attr, " ")),
                    ">",
                    slot,
                    "</g>"
                )
            );
    }

    /**
     * @dev render a use SVG tag
     * @param id of the new SVG use tag
     * @param link id of the SVG tag to reference
     */
    function _use(string memory link, string memory id)
        internal
        pure
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    "<use ",
                    bytes(id).length == 0
                        ? ""
                        : string(abi.encodePacked(' id="', id, '" ')),
                    'xlink:href="#',
                    link,
                    '"/>'
                )
            );
    }

    /**
     * @dev render the outer SVG markup. XML version, doctype and SVG tag
     * @param body of the SVG markup
     * @return header string
     */
    function _SVG(string memory bkgColor, string memory body)
        internal
        pure
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="800" height="800" viewBox="-800 -800 1600 1600" style="stroke-width:0;"><defs><radialGradient id="RadialGradient1"><stop offset="0%" stop-color="',
                    bkgColor,
                    '"/><stop offset="90%" stop-color="#000"/></radialGradient></defs> <rect id="svg_bg" height="1600" width="1600" y="-800" x="-800" stroke="#000" fill="url(#RadialGradient1)"></rect>',
                    body,
                    "</svg>"
                )
            );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >0.6.4;

import "Decimal.sol";
import "HSL.sol";

struct Shape {
    uint256[2] position;
    uint256[2] size;
    HSL color;
}

// SPDX-License-Identifier: MIT
pragma solidity >0.6.4;

struct Decimal {
    int256 value;
    uint8 decimals;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;
pragma experimental ABIEncoderV2;

import "Strings.sol";
import "SafeCast.sol";
import "SafeMath.sol";

import "HSL.sol";
import "Random.sol";

library Colors {
    using Strings for uint256;
    using SafeCast for uint256;
    using SafeMath for uint256;
    using SafeMath for uint16;
    using SafeMath for uint8;

    function toString(HSL memory color) internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "hsl(",
                    uint256(color.hue).toString(),
                    ",",
                    uint256(color.saturation).toString(),
                    "%,",
                    uint256(color.lightness).toString(),
                    "%)"
                )
            );
    }

    function lookupHue(
        uint16 rootHue,
        uint8 scheme,
        uint8 index
    ) internal pure returns (uint16 hue) {
        uint16[3][10] memory schemes = [
            [uint16(30), uint16(330), uint16(0)], // analogous
            [uint16(120), uint16(240), uint16(0)], // triadic
            [uint16(180), uint16(180), uint16(0)], // complimentary
            [uint16(60), uint16(180), uint16(240)], // tetradic
            [uint16(30), uint16(180), uint16(330)], // analogous and complimentary
            [uint16(150), uint16(210), uint16(0)], // split complimentary
            [uint16(150), uint16(180), uint16(210)], // complimentary and analogous
            [uint16(30), uint16(60), uint16(90)], // series
            [uint16(90), uint16(180), uint16(270)], // square
            [uint16(0), uint16(0), uint16(0)] // mono
        ];

        require(scheme < schemes.length, "Invalid scheme id");
        require(index < 4, "Invalid color index");

        hue = index == 0
            ? rootHue
            : uint16(rootHue.mod(360).add(schemes[scheme][index - 1]));
    }

    function lookupColor(
        uint8 scheme,
        uint16 hue,
        uint8 saturation,
        uint8 lightness,
        uint8 shades,
        uint8 contrast,
        uint8 shade,
        uint8 hueIndex
    ) external pure returns (HSL memory) {
        uint16 h = lookupHue(hue, scheme, hueIndex);
        uint8 s = saturation;
        uint8 l = calcShade(lightness, shades, contrast, shade);
        return HSL(h, s, l);
    }

    function calcShade(
        uint8 lightness,
        uint8 shades,
        uint8 contrast,
        uint8 shade
    ) public pure returns (uint8 l) {
        if (shades > 1) {
            uint256 range = uint256(contrast);
            uint256 step = range.div(uint256(shades));
            uint256 offset = uint256(shade.mul(step));
            l = uint8(uint256(lightness).sub(offset));
        } else {
            l = lightness;
        }
    }

    /**
     * @dev parse the bkg value into an HSL color
     * @param bkg settings packed int 8 bits
     * @return HSL color style CSS string
     */
    function _parseBkg(uint8 bkg) external pure returns (string memory) {
        uint256 hue = (bkg / 16) * 24;
        uint256 sat = hue == 0 ? 0 : (((bkg / 4) % 4) + 1) * 25;
        uint256 lit = hue == 0
            ? (625 * (bkg % 16)) / 100
            : ((bkg % 4) + 1) * 20;
        return
            string(
                abi.encodePacked(
                    "background-color:hsl(",
                    hue.toString(),
                    ",",
                    sat.toString(),
                    "%,",
                    lit.toString(),
                    "%);"
                )
            );
    }
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

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >0.8.0;

import "SafeMath.sol";
import "SignedSafeMath.sol";

library Random {
    using SafeMath for uint256;
    using SignedSafeMath for int256;

    /**
     * Initialize the pool with the entropy of the blockhashes of the num of blocks starting from 0
     * The argument "seed" allows you to select a different sequence of random numbers for the same block range.
     */
    function init(uint256 seed) internal view returns (bytes32[] memory) {
        uint256 blocks = 2;
        bytes32[] memory pool = new bytes32[](3);
        bytes32 salt = keccak256(abi.encodePacked(uint256(0), seed));
        for (uint256 i = 0; i < blocks; i++) {
            // Add some salt to each blockhash
            pool[i + 1] = keccak256(abi.encodePacked(blockhash(i), salt));
        }
        return pool;
    }

    /**
     * Advances to the next 256-bit random number in the pool of hash chains.
     */
    function next(bytes32[] memory pool) internal pure returns (uint256) {
        require(pool.length > 1, "Random.next: invalid pool");
        uint256 roundRobinIdx = (uint256(pool[0]) % (pool.length - 1)) + 1;
        bytes32 hash = keccak256(abi.encodePacked(pool[roundRobinIdx]));
        pool[0] = bytes32(uint256(pool[0]) + 1);
        pool[roundRobinIdx] = hash;
        return uint256(hash);
    }

    /**
     * Produces random integer values, uniformly distributed on the closed interval [a, b]
     */
    function uniform(
        bytes32[] memory pool,
        int256 a,
        int256 b
    ) internal pure returns (int256) {
        require(a <= b, "Random.uniform: invalid interval");
        return int256(next(pool) % uint256(b - a + 1)) + a;
    }

    /**
     * Produces random integer values, with weighted distributions for values in a set
     */
    function weighted(
        bytes32[] memory pool,
        uint8[7] memory thresholds,
        uint16 total
    ) internal pure returns (uint8) {
        int256 p = uniform(pool, 1, int16(total));
        int256 s = 0;
        for (uint8 i = 0; i < 7; i++) {
            s = s.add(int8(thresholds[i]));
            if (p <= s) return i;
        }
        return 0;
    }

    /**
     * Produces random integer values, with weighted distributions for values in a set
     */
    function weighted(
        bytes32[] memory pool,
        uint8[24] memory thresholds,
        uint16 total
    ) internal pure returns (uint8) {
        int256 p = uniform(pool, 1, int16(total));
        int256 s = 0;
        for (uint8 i = 0; i < 24; i++) {
            s = s.add(int8(thresholds[i]));
            if (p <= s) return i;
        }
        return 0;
    }

    function simpleRandomNum(
        uint256 _mod,
        uint256 _seed,
        uint256 _salt
    ) internal view returns (uint256) {
        uint256 num = uint256(
            keccak256(
                abi.encodePacked(block.timestamp, msg.sender, _seed, _salt)
            )
        ) % _mod;
        return num;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SignedSafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SignedSafeMath {
    /**
     * @dev Returns the multiplication of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two signed integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(int256 a, int256 b) internal pure returns (int256) {
        return a / b;
    }

    /**
     * @dev Returns the subtraction of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        return a - b;
    }

    /**
     * @dev Returns the addition of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        return a + b;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >0.8.0;

import "SignedSafeMath.sol";
import "Strings.sol";

library Utils {
    using SignedSafeMath for int256;
    using Strings for uint256;

    function stringToUint(string memory s)
        internal
        pure
        returns (uint256 result)
    {
        bytes memory b = bytes(s);
        uint256 i;
        result = 0;
        for (i = 0; i < b.length; i++) {
            uint256 c = uint256(uint8(b[i]));
            if (c >= 48 && c <= 57) {
                result = result * 10 + (c - 48);
            }
        }
    }

    // special toString for signed ints
    function toString(int256 val) internal pure returns (string memory out) {
        out = (val < 0)
            ? string(abi.encodePacked("-", uint256(val.mul(-1)).toString()))
            : uint256(val).toString();
    }

    function zeroPad(int256 value, uint256 places)
        internal
        pure
        returns (string memory out)
    {
        out = toString(value);
        for (uint256 i = (places - 1); i > 0; i--)
            if (value < int256(10**i)) out = string(abi.encodePacked("0", out));
    }

    function addressToString(address _addr)
        internal
        pure
        returns (string memory)
    {
        bytes32 value = bytes32(uint256(uint160(_addr)));
        bytes memory alphabet = "0123456789abcdef";

        bytes memory str = new bytes(51);
        str[0] = "0";
        str[1] = "x";
        for (uint256 i = 0; i < 20; i++) {
            str[2 + i * 2] = alphabet[uint256(uint8(value[i + 12] >> 4))];
            str[3 + i * 2] = alphabet[uint256(uint8(value[i + 12] & 0x0f))];
        }
        return string(str);
    }

    function substring(
        string memory str,
        uint16 startIndex,
        uint16 endIndex
    ) internal pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(endIndex - startIndex);
        for (uint16 i = startIndex; i < endIndex; i++) {
            result[i - startIndex] = strBytes[i];
        }
        return string(result);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;
pragma experimental ABIEncoderV2;

import "SafeMath.sol";
import "SignedSafeMath.sol";
import "Strings.sol";

import "Decimal.sol";
import "Shape.sol";
import "PlanetDetail.sol";

library Animation {
    using SafeMath for uint256;
    using SignedSafeMath for int256;
    using Strings for uint256;

    /**
     * @dev render an animate SVG tag
     */
    function _animate(
        string memory attribute,
        string memory duration,
        string memory values,
        string memory attr
    ) internal pure returns (string memory) {
        return _animate(attribute, duration, values, "", attr);
    }

    /**
     * @dev render an animate SVG tag
     */
    function _animate(
        string memory attribute,
        string memory duration,
        string memory values,
        string memory calcMode,
        string memory attr
    ) internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<animate attributeName="',
                    attribute,
                    '" values="',
                    values,
                    '" dur="',
                    duration,
                    bytes(calcMode).length == 0
                        ? ""
                        : string(abi.encodePacked('" calcMode="', calcMode)),
                    '" ',
                    attr,
                    "/>"
                )
            );
    }

    /**
     * @dev render an animate SVG tag with keyTimes and keySplines
     */
    function _animate(
        string memory attribute,
        string memory duration,
        string memory values,
        string memory keyTimes,
        string memory keySplines,
        string memory attr
    ) internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<animate attributeName="',
                    attribute,
                    '" values="',
                    values,
                    '" dur="',
                    duration,
                    '" keyTimes="',
                    keyTimes,
                    '" keySplines="',
                    keySplines,
                    '" calcMode="spline" ',
                    attr,
                    "/>"
                )
            );
    }

    /**
     * @dev render an animateTransform SVG tag with keyTimes and keySplines
     */
    function _animateTransform(
        string memory typeVal,
        string memory duration,
        string memory values,
        string memory keyTimes,
        string memory keySplines,
        string memory attr,
        bool add
    ) internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<animateTransform attributeName="transform" attributeType="XML" type="',
                    typeVal,
                    '" dur="',
                    duration,
                    '" values="',
                    values,
                    bytes(keyTimes).length == 0
                        ? ""
                        : string(abi.encodePacked('" keyTimes="', keyTimes)),
                    bytes(keySplines).length == 0
                        ? ""
                        : string(
                            abi.encodePacked(
                                '" calcMode="spline" keySplines="',
                                keySplines
                            )
                        ),
                    add ? '" additive="sum' : "",
                    '" ',
                    attr,
                    "/>"
                )
            );
    }

    /**
     * @dev render an animateTransform SVG tag with keyTimes
     */
    function _animateTransform(
        string memory typeVal,
        string memory duration,
        string memory values,
        string memory keyTimes,
        string memory attr,
        bool add
    ) internal pure returns (string memory) {
        return
            _animateTransform(
                typeVal,
                duration,
                values,
                keyTimes,
                "",
                attr,
                add
            );
    }

    /**
     * @dev render an animateTransform SVG tag
     */
    function _animateTransform(
        string memory typeVal,
        string memory duration,
        string memory values,
        string memory attr,
        bool add
    ) internal pure returns (string memory) {
        return _animateTransform(typeVal, duration, values, "", "", attr, add);
    }

    /**
     * @dev render an animateTransform SVG tag with keyTimes
     */
    function _animateTransform(
        string memory typeVal,
        string memory duration,
        string memory values,
        string memory keyTimes,
        string memory keySplines,
        string memory attr
    ) internal pure returns (string memory) {
        return
            _animateTransform(
                typeVal,
                duration,
                values,
                keyTimes,
                keySplines,
                attr,
                false
            );
    }

    /**
     * @dev render an animateTransform SVG tag with keyTimes
     */
    function _animateTransform(
        string memory typeVal,
        string memory duration,
        string memory values,
        string memory keyTimes,
        string memory attr
    ) internal pure returns (string memory) {
        return
            _animateTransform(
                typeVal,
                duration,
                values,
                keyTimes,
                "",
                attr,
                false
            );
    }

    /**
     * @dev render an animateTransform SVG tag
     */
    function _animateTransform(
        string memory typeVal,
        string memory duration,
        string memory values,
        string memory attr
    ) internal pure returns (string memory) {
        return
            _animateTransform(typeVal, duration, values, "", "", attr, false);
    }

    // /**
    //  * @dev creata a keyTimes string, based on a range and division count
    //  */
    // function generateTimes() internal pure returns (string memory times) {}

    /**
     * @dev creata a keySplines string, with a bezier curve for each value transition
     */
    function generateSplines(uint8 transitions, uint8 curve)
        internal
        pure
        returns (string memory curves)
    {
        string[2] memory bezierCurves = [
            ".5 0 .75 1", // ease in and out fast
            ".4 0 .6 1" // ease in fast + soft
        ];
        for (uint8 i = 0; i < transitions; i++)
            curves = string(
                abi.encodePacked(curves, i > 0 ? ";" : "", bezierCurves[curve])
            );
    }

    /**
     * @dev select the animation
     * @param planet object to base animation around
     * @param shapeIndex index of the shape to animate
     * @return mod struct of modulator values
     */

    /*
    function _generateAnimation(
        PlanetDetail calldata planet,
        uint8 animation,
        Shape calldata shape,
        uint256 shapeIndex
    ) external pure returns (string memory) {
        string memory duration = string(
            abi.encodePacked(
                uint256(
                    planet.rotationDuration > 0 ? planet.rotationDuration : 10
                ).toString(),
                "s"
            )
        );
        string memory attr = "";
        // select animation based on animation id
        if (animation == 0) {
            // snap spin 90
            return
                _animateTransform(
                    "rotate",
                    duration,
                    "0;90;90;360;360",
                    "0;.2;.3;.9;1",
                    generateSplines(4, 0),
                    attr
                );
        } else if (animation == 1) {
            // snap spin 180
            return
                _animateTransform(
                    "rotate",
                    duration,
                    "0;180;180;360;360",
                    "0;.4;.5;.9;1",
                    generateSplines(4, 0),
                    attr
                );
        } else if (animation == 2) {
            // snap spin 270
            return
                _animateTransform(
                    "rotate",
                    duration,
                    "0;270;270;360;360",
                    "0;.6;.7;.9;1",
                    generateSplines(4, 0),
                    attr
                );
        } else if (animation == 3) {
            // snap spin tri
            return
                _animateTransform(
                    "rotate",
                    duration,
                    "0;120;120;240;240;360;360",
                    "0;.166;.333;.5;.666;.833;1",
                    generateSplines(6, 0),
                    attr
                );
        } else if (animation == 4) {
            // snap spin quad
            return
                _animateTransform(
                    "rotate",
                    duration,
                    "0;90;90;180;180;270;270;360;360",
                    "0;.125;.25;.375;.5;.625;.8;.925;1",
                    generateSplines(8, 0),
                    attr
                );
        } else if (animation == 5) {
            // snap spin tetra
            return
                _animateTransform(
                    "rotate",
                    duration,
                    "0;72;72;144;144;216;216;278;278;360;360",
                    "0;.1;.2;.3;.4;.5;.6;.7;.8;.9;1",
                    generateSplines(10, 0),
                    attr
                );
        } else if (animation == 6) {
            // Uniform Speed Spin
            return _animateTransform("rotate", duration, "0;360", "0;1", attr);
        } else if (animation == 7) {
            // 2 Speed Spin
            return
                _animateTransform(
                    "rotate",
                    duration,
                    "0;90;270;360",
                    "0;.1;.9;1",
                    attr
                );
        } else if (animation == 8) {
            // indexed speed
            return
                _animateTransform(
                    "rotate",
                    string(
                        abi.encodePacked(
                            uint256(
                                ((1000 *
                                    (
                                        planet.duration > 0
                                            ? planet.duration
                                            : 10
                                    )) / planet.shapes) * (shapeIndex + 1)
                            ).toString(),
                            "ms"
                        )
                    ),
                    "0;360",
                    "0;1",
                    attr
                );
        } else if (animation == 9) {
            // spread
            uint256 spread = uint256(300).div(uint256(planet.shapes));
            string memory angle = shapeIndex.add(1).mul(spread).toString();
            string memory values = string(
                abi.encodePacked("0;", angle, ";", angle, ";360;360")
            );
            return
                _animateTransform(
                    "rotate",
                    duration,
                    values,
                    "0;.5;.6;.9;1",
                    generateSplines(4, 0),
                    attr
                );
        } else if (animation == 10) {
            // spread w time
            string memory angle = shapeIndex
                .add(1)
                .mul(uint256(300).div(uint256(planet.shapes)))
                .toString();
            uint256 timeShift = uint256(900).sub(
                uint256(planet.shapes).sub(shapeIndex).mul(
                    uint256(800).div(uint256(planet.shapes))
                )
            );
            string memory times = string(
                abi.encodePacked("0;.", timeShift.toString(), ";.9;1")
            );
            return
                _animateTransform(
                    "rotate",
                    duration,
                    string(abi.encodePacked("0;", angle, ";", angle, ";360")),
                    times,
                    generateSplines(3, 0),
                    attr
                );
        } else if (animation == 11) {
            // jitter
            int256[2] memory amp = [int256(10), int256(10)]; // randomize amps for each shape?
            string[2] memory vals;
            for (uint256 i = 0; i < 2; i++) {
                int256 pos = shape.position[i];
                string memory min = pos.sub(amp[i]).toString();
                string memory max = pos.add(amp[i]).toString();
                vals[i] = string(
                    abi.encodePacked(
                        (i == 0) ? min : max,
                        ";",
                        (i == 0) ? max : min
                    )
                );
            }
            return
                string(
                    abi.encodePacked(
                        _animate(
                            "x",
                            string(
                                abi.encodePacked(
                                    uint256(
                                        planet.duration > 0
                                            ? planet.duration
                                            : 10
                                    ).div(10).toString(),
                                    "s"
                                )
                            ),
                            vals[0],
                            "discrete",
                            attr
                        ),
                        _animate(
                            "y",
                            string(
                                abi.encodePacked(
                                    uint256(
                                        planet.duration > 0
                                            ? planet.duration
                                            : 10
                                    ).div(5).toString(),
                                    "s"
                                )
                            ),
                            vals[1],
                            "discrete",
                            attr
                        )
                    )
                );
        } else if (animation == 12) {
            // giggle
            int256 amp = 5;
            string[2] memory vals;
            for (uint256 i = 0; i < 2; i++) {
                int256 pos = shape.position[i];
                string memory min = pos.sub(amp).toString();
                string memory max = pos.add(amp).toString();
                vals[i] = string(
                    abi.encodePacked(
                        (i == 0) ? min : max,
                        ";",
                        (i == 0) ? max : min,
                        ";",
                        (i == 0) ? min : max
                    )
                );
            }
            return
                string(
                    abi.encodePacked(
                        _animate(
                            "x",
                            string(
                                abi.encodePacked(
                                    uint256(
                                        planet.duration > 0
                                            ? planet.duration
                                            : 10
                                    ).mul(20).toString(),
                                    "ms"
                                )
                            ),
                            vals[0],
                            attr
                        ),
                        _animate(
                            "y",
                            string(
                                abi.encodePacked(
                                    uint256(
                                        planet.duration > 0
                                            ? planet.duration
                                            : 10
                                    ).mul(20).toString(),
                                    "ms"
                                )
                            ),
                            vals[1],
                            attr
                        )
                    )
                );
        } else if (animation == 13) {
            // jolt
            int256 amp = 5;
            string[2] memory vals;
            for (uint256 i = 0; i < 2; i++) {
                int256 pos = shape.position[i];
                string memory min = pos.sub(amp).toString();
                string memory max = pos.add(amp).toString();
                vals[i] = string(
                    abi.encodePacked(
                        (i == 0) ? min : max,
                        ";",
                        (i == 0) ? max : min
                    )
                );
            }
            return
                string(
                    abi.encodePacked(
                        _animate(
                            "x",
                            string(
                                abi.encodePacked(
                                    uint256(
                                        planet.duration > 0
                                            ? planet.duration
                                            : 10
                                    ).mul(25).toString(),
                                    "ms"
                                )
                            ),
                            vals[0],
                            attr
                        ),
                        _animate(
                            "y",
                            string(
                                abi.encodePacked(
                                    uint256(
                                        planet.duration > 0
                                            ? planet.duration
                                            : 10
                                    ).mul(25).toString(),
                                    "ms"
                                )
                            ),
                            vals[1],
                            attr
                        )
                    )
                );
        } else if (animation == 14) {
            // grow n shrink
            return
                _animateTransform(
                    "scale",
                    duration,
                    "1 1;1.5 1.5;1 1;.5 .5;1 1",
                    "0;.25;.5;.75;1",
                    attr
                );
        } else if (animation == 15) {
            // squash n stretch
            uint256 div = 7;
            string[2] memory vals;
            for (uint256 i = 0; i < 2; i++) {
                uint256 size = uint256(shape.size[i]);
                string memory avg = size.toString();
                string memory min = size.sub(size.div(div)).toString();
                string memory max = size.add(size.div(div)).toString();
                vals[i] = string(
                    abi.encodePacked(
                        avg,
                        ";",
                        (i == 0) ? min : max,
                        ";",
                        avg,
                        ";",
                        (i == 0) ? max : min,
                        ";",
                        avg
                    )
                );
            }
            return
                string(
                    abi.encodePacked(
                        _animate("width", duration, vals[0], attr),
                        _animate("height", duration, vals[1], attr)
                    )
                );
        } else if (animation == 16) {
            // Rounding corners
            return _animate("rx", duration, "0;100;0", attr);
        } else if (animation == 17) {
            // glide
            int256 amp = 20;
            string memory max = int256(0).add(amp).toString();
            string memory min = int256(0).sub(amp).toString();
            string memory values = string(
                abi.encodePacked(
                    "0 0;",
                    min,
                    " ",
                    min,
                    ";0 0;",
                    max,
                    " ",
                    max,
                    ";0 0"
                )
            );
            return _animateTransform("translate", duration, values, attr);
        } else if (animation == 18) {
            // Wave
            string memory values = string(
                abi.encodePacked("1 1;1 1;1.5 1.5;1 1;1 1")
            );
            int256 div = int256(10000).div(int256(uint256(planet.shapes) + 1));
            int256 peak = int256(10000).sub(div.mul(int256(shapeIndex).add(1)));
            string memory mid = peak.toDecimal(4).toString();
            string memory start = peak.sub(div).toDecimal(4).toString();
            string memory end = peak.add(div).toDecimal(4).toString();
            string memory times = string(
                abi.encodePacked("0;", start, ";", mid, ";", end, ";1")
            );
            return
                _animateTransform(
                    "scale",
                    duration,
                    values,
                    times,
                    generateSplines(4, 0),
                    attr
                );
        } else if (animation == 19) {
            // Phased Fade
            uint256 fadeOut = uint256(planet.shapes).sub(shapeIndex).mul(
                uint256(400).div(uint256(planet.shapes))
            );
            uint256 fadeIn = uint256(900).sub(
                uint256(planet.shapes).sub(shapeIndex).mul(
                    uint256(400).div(uint256(planet.shapes))
                )
            );
            string memory times = string(
                abi.encodePacked(
                    "0;.",
                    fadeOut.toString(),
                    ";.",
                    fadeIn.toString(),
                    ";1"
                )
            );
            return
                _animate(
                    "opacity",
                    duration,
                    "1;0;0;1",
                    times,
                    generateSplines(3, 0),
                    attr
                );
        } else if (animation == 20) {
            // Skew X
            return _animateTransform("skewX", duration, "0;50;-50;0", attr);
        } else if (animation == 21) {
            // Skew Y
            return _animateTransform("skewY", duration, "0;50;-50;0", attr);
        } else if (animation == 22) {
            // Stretch - (bounce skewX w/ ease-in-out)
            return
                _animateTransform(
                    "skewX",
                    string(
                        abi.encodePacked(
                            uint256(planet.duration > 0 ? planet.duration : 10)
                                .div(2)
                                .toString(),
                            "s"
                        )
                    ),
                    "0;-64;32;-16;8;-4;2;-1;.5;0;0",
                    "0;.1;.2;.3;.4;.5;.6;.7;.8;.9;1",
                    generateSplines(10, 0),
                    attr
                );
        } else if (animation == 23) {
            // Jello - (bounce skewX w/ ease-in)
            return
                _animateTransform(
                    "skewX",
                    duration,
                    "0;16;-12;8;-4;2;-1;.5;-.25;0;0",
                    "0;.1;.2;.3;.4;.5;.6;.7;.8;.9;1",
                    generateSplines(10, 1),
                    attr
                );
        }
    }
    */
}