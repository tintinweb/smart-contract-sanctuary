//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './Roc.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import './Randomize.sol';
import './Trignometry.sol';


/**
 * @title RocRenderer
 * @notice Renderer for roc-male-gen0
 * @author Tfs128.eth (@trickerfs128)
 */
contract RocRenderer {
    
    using Strings for uint256;
    using Strings for uint16;
    using Strings for uint8;
    using Randomize for Randomize.Random;


    Roc public immutable rocContract;
    address public immutable  pathsContractAddress;

    /** 
     * @notice constructor
     * @param pathsAddress - address of contract which contains paths.
     * @param rocMainContractAddress - Roc Main contract address
     */
    constructor(address pathsAddress, address rocMainContractAddress) {
        pathsContractAddress = pathsAddress;
        rocContract = Roc(rocMainContractAddress);
    }

    struct Info {
        uint8 facePoints;
        uint8 hat;
        uint8 glasses;
        uint8 moustache;
        uint8 race;
    }

    /** 
     * @notice render the svg.
     * @param tokenId - tokenId
     * @param dna - dna
     * @return json
     */
    function render(uint256 tokenId, uint256 dna)
        public
        view
        returns (string memory)
    {
        Randomize.Random memory random = Randomize.Random({seed: dna,nonce: 0});
        Info memory info = Info({
            facePoints: uint8(random.next(4, 40)),
            hat: uint8(random.next(1,8)), //≈62%
            glasses: uint8(random.next(1,10)), //10%
            moustache: uint8(random.next(1,9)), //≈%33
            race: uint8(random.next(1,4)) //Fency 25% Normal 75%;
        });
        uint16[] memory charAttributes = _getAttributesValues(info);
        bytes memory svg = _getSvg(info,random,charAttributes);
        bytes memory metaData = _getMetaData(info,charAttributes,rocContract._child_rem(tokenId));
        bytes memory json = abi.encodePacked(
            'data:application/json;utf8,{"name":"ROC #',
            tokenId.toString(),
            '","image":"data:image/svg+xml;utf8,',
            svg,
            '","description":"Rebels On Chain - Male Gen-0","attributes":[',
            metaData,
            ']}'
            );
        return string(json);
    }

    /**
     * @notice getSvg
     */
    function _getSvg(
        Info memory info,
        Randomize.Random memory random,
        uint16[] memory charAttributes
        )
    internal
    view
    returns (bytes memory)
    {
        uint256 clrHue = random.next(1,360);
        bytes memory facePath = _getFacePath(info,random);
        bytes memory background = _getBackground(random,info.race);
        (bytes memory face, bytes memory defs) = _getFaceAndDefs(random,info.race,facePath);
        bytes memory mouth = _getMouth(random.next(1,4));
        bytes memory hat;
        bytes memory glasses;
        bytes memory moustache;
        bytes memory eyes;
        bytes memory attributesSvg;
        if(info.hat < 6) {
            hat = _extractWearable(info.hat,clrHue);
        }

        if(info.moustache > 6) {
            moustache = _extractWearable(info.moustache,clrHue);
        }

        if(info.glasses == 6) {
            glasses = _extractWearable(info.glasses,clrHue);
        }
        else {
            eyes = _getEyes(random);
        }

        attributesSvg = _getCharAttributesSvg(charAttributes);
        bytes memory svg = abi.encodePacked(
            "<svg xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink' viewBox='0 0 200 200'>",
            background,
            face,
            eyes,
            mouth,
            moustache,
            glasses,
            hat,
            attributesSvg,
            defs,
            "</svg>"
            );
        return svg;
    }

    /**
     * @notice get path of svg layer stores in a seperate
     * @notice contract.
     */
    function _extractWearable(uint8 index,uint256 clrHue) 
    internal
    view
    returns(bytes memory)
    {
        bytes memory layer;

        uint24[3][] memory pathsInfo = _getPathsInfo(index);
        for(uint8 i = 0; i < pathsInfo.length; i++) {
            uint24 offset = pathsInfo[i][0];
            uint24 size = pathsInfo[i][1];
            bytes memory path_ = new bytes(size);
            address contractAddress = pathsContractAddress;
            assembly {
                extcodecopy(contractAddress, add(path_, 32), offset, size)
            }
            bytes memory clr;
            uint16 clr1Sat = (index == 6) ? 75 : 100;
            uint16 clr1Ligth = (index == 6) ? 40 : 55;
            if(pathsInfo[i][2] == 0x000000) {
                clr = abi.encodePacked('hsl(',clrHue.toString(),' ',clr1Sat.toString(),'% ',clr1Ligth.toString(),'%)');
            }
            else if(pathsInfo[i][2] == 0xffffff) {
                clr = abi.encodePacked('hsl(',clrHue.toString(),' 78% 50%)');
            }
            else {
                clr = abi.encodePacked('#',_bytes3ToHexBytes(bytes3(pathsInfo[i][2])));
            }

            if(index == 5 && i == 0) {
                layer = abi.encodePacked(layer,"<path fill='",clr,"' stroke='black' d='",path_,"' />");
            }
            else {
                layer = abi.encodePacked(
                    layer,"<path fill='",clr,"' d='",path_,"' />");
            }
        }
        bytes memory transform = (index > 1 && index < 6) ? bytes('5') : bytes('0');
        layer = abi.encodePacked( 
            "<g transform='matrix(1,0,0,1,0,",
            transform,
            ")'>",
            layer,
            "</g>"
             );
        return layer;
    }

    /**
     * @notice getMetaData
     */
    function _getMetaData(
        Info memory info,
        uint16[] memory charAttributes,
        uint256 childRemaining
        )
    internal
    pure
    returns(bytes memory metadata) {
        string[10] memory names = ['Null','Derby','Beret','Trilby','Witch','Cowboy','Yes','Chevron','Pencil','HandleBar'];
        string memory hatName;
        string memory glassesName;
        string memory moustacheName;
        string memory raceName;
        hatName = info.hat < 6 ? names[info.hat]: 'No';
        glassesName = (info.glasses == 6) ? names[info.glasses] : 'No';
        moustacheName = info.moustache > 6 ? names[info.moustache] : 'No';
        raceName = info.race == 4 ? 'Fency' : 'Normal';
        bytes memory scoreMeta;
        {
            scoreMeta = abi.encodePacked(
            '{"trait_type": "Strength", "value": ',
            charAttributes[0].toString(),
            '},{"trait_type": "Knowledge", "value": ',
            charAttributes[1].toString(),
            '},{"trait_type": "Charm", "value": ',
            charAttributes[2].toString(),
            '},{"trait_type": "Money", "value": ',
            charAttributes[3].toString(),
            '}'
            );
        }

        metadata = abi.encodePacked(
            '{"trait_type": "Childs Remaining", "value": "',
            childRemaining.toString(),
            '"},{"trait_type": "Hat", "value": "',
            hatName,
            '"},{"trait_type": "Glasses", "value": "',
            glassesName,
            '"},{"trait_type": "Moustache", "value": "',
            moustacheName,
            '"},{"trait_type": "Race", "value": "',
            raceName,
            '"},{"trait_type": "FacePoints", "value": "',
            info.facePoints.toString(),
            '"},',
            scoreMeta
            );
    }

    /**
     * @notice calculate character attributes
     */
    function _getAttributesValues(Info memory info)
    internal
    pure
    returns (uint16[] memory)
    {
        uint16 initialPoints = info.facePoints / 2;
        //Set initial score based on facepoints.
        uint16 knowledge = (20 + initialPoints);
        uint16 strength = (20 + initialPoints);
        uint16 charm = (40 - initialPoints);
        //if race == fency add charm and strength.
        if(info.race == 4) {
            strength += 5;
            charm += 5;
        }
        //if hat, add knowledge
        if(info.hat < 6) {
            knowledge += 10;
        }
        //if glasses, add charm
        if(info.glasses == 6) {
            knowledge += 10;
            charm += 25;
            strength += 5;
        }
        //if moustach, add stregth.
        if(info.moustache > 6) {
            strength += 15;
        }
        //if hat,moustach and glasses then add extra score
        if(info.hat < 6 && info.glasses == 6 && info.moustache > 6) {
            charm += 15;
            knowledge += 15;
            strength += 15;
        }
        uint16 money = (strength + knowledge + charm) / 3;
        uint16[] memory charAttributes = new uint16[](4);
        charAttributes[0] = strength;
        charAttributes[1] = knowledge;
        charAttributes[2] = charm;
        charAttributes[3] = money;
        return charAttributes;
    }

    /**
     * @notice getfacepath by generating random points around circumference
     * @notice of a circle and then generating path using spline.
     */
    function _getFacePath(Info memory info,Randomize.Random memory random)
    internal
    pure
    returns (bytes memory)
    {
        uint8 z = 4;
        uint8 facePoints = info.facePoints;
        int256[] memory points = new int256[](facePoints * 2 + 8);
        int256 oneAtPrecision = 18446744073709551616;  // 2**64
        int256 twoPi = 115904311329233965478; //2pi @ oneAtPrecision
        int256 angle = twoPi / int8(facePoints);
        for (int8 i = 1; i <= int8(facePoints); i++) {
            int8 pull = int8(uint8(random.next(80,100)));
            int256 xx = 100 + (Trignometry.cos(i * angle) * 50 * pull) / oneAtPrecision / 100;
            int256 yy = 100 + (Trignometry.sin(i * angle) * 50 * pull) / oneAtPrecision / 100;
            points[z] = xx;
            z++;
            points[z] = yy;
            z++;
        }
        points[0] = points[facePoints * 2];
        points[1] = points[facePoints * 2 + 1];
        points[2] = points[facePoints * 2 + 2];
        points[3] = points[facePoints * 2 + 3];
        points[facePoints * 2 + 4] = points[4];
        points[facePoints * 2 + 5] = points[5];
        points[facePoints * 2 + 6] = points[6];
        points[facePoints * 2 + 7] = points[7];
        return _calculateFacePath(points);
    }

    /**
     * @notice convert points into svg path.
     * @dev https://github.com/georgedoescode/splinejs/blob/main/spline.js
     */
    function _calculateFacePath(int256[] memory points)
    internal
    pure
    returns (bytes memory)
    {
        uint256 last = points.length - 4;
        uint256 maxIteration = last;
        bytes memory path = abi.encodePacked('M',uint256(points[2]).toString(),',',uint256(points[3]).toString());
        for (uint256 ii = 2; ii < maxIteration; ii+=2) {
           int256[] memory values = new int256[](6);
           values[0] = ii != last ? points[ii + 4] : points[ii + 2];
           values[1] = ii != last ? points[ii + 5] : points[ii + 3];
           values[2] = points[ii + 0] + ((points[ii + 2] - points[ii - 2]) / 6);
           values[3] = points[ii + 1] + ((points[ii + 3] - points[ii - 1]) / 6);
           values[4] = points[ii + 2] - ((values[0] - points[ii + 0] ) / 6);
           values[5] = points[ii + 3] - ((values[1] - points[ii + 1] ) / 6);
           path = abi.encodePacked(
            path,
            'C',
            uint256(values[2]).toString(),
            ',',
            uint256(values[3]).toString(),
            ',',
            uint256(values[4]).toString(),
            ',',
            uint256(values[5]).toString(),
            ',',
            uint256(points[ii + 2]).toString(),
            ',',
            uint256(points[ii + 3]).toString()
            );
        }
        return path;
    }

    /**
     * @notice getBackground
     */
    function _getBackground(Randomize.Random memory random, uint8 race)
    internal
    pure
    returns(bytes memory) {
        uint256 lightness = race == 4 ? 10 : 90;
        uint256 backgroundClrHue = random.next(1,360);
        bytes memory background = abi.encodePacked(
            "<rect width='200' height='200' fill='hsl(",
            backgroundClrHue.toString(),
            " 100% ",
            lightness.toString(),
            "%)' />"
            ); 
        return background;
    }

    /**
     * @notice getFaceAndDefs
     */
    function _getFaceAndDefs(Randomize.Random memory random ,uint256 race, bytes memory facePath)
    internal
    pure
    returns(bytes memory face, bytes memory defs)
    {
        if(race == 4) {
            defs = abi.encodePacked(
                "<defs>",
                "<clipPath id='face'><path d='",
                facePath,
                "'></path></clipPath></defs>"
                );
            bytes memory skin = _getSkin(random);
            face = abi.encodePacked(
                "<g clip-path='url(#face)'>",
                skin,
                "</g>"
                );
        }
        else {
            uint256 hue = random.next(1,360);
            uint256 saturation = random.next(75,100);
            uint256 lightness = random.next(50,90);
            face = abi.encodePacked(
                "<path d='",
                facePath,
                "' stroke-width='0.1' stroke='hsl(",
                hue.toString(),
                ", ",
                saturation.toString(),
                "%, 30%)' fill='hsl(",
                hue.toString(),
                ", ",
                saturation.toString(),
                "%, ",
                lightness.toString(),
                "%)'></path>"
                );
        }
        return (face, defs);

    }

    /**
     * @notice get skin by generating random Lines
     * @notice and filling with random colors
     */
    function _getSkin(Randomize.Random memory random)
    internal
    pure
    returns(bytes memory) {
        bytes memory lines = abi.encodePacked(
            "<rect width='200' height='200' fill='hsl(",
            random.next(1, 360).toString(),
            " ",
            random.next(1, 100).toString(),
            "% 25%)'></rect>"
            );
        uint256 totalLines = random.next(2,6);
        for(uint i; i <= totalLines; i++) {
            uint256[] memory points = new uint256[](8);
            points[0] = random.next(1,200);
            points[1] = random.next(1,200);
            points[2] = random.next(50,150);
            points[3] = random.next(50,150);
            points[4] = random.next(50,150);
            points[5] = random.next(50,150);
            points[6] = random.next(1,200);
            points[7] = random.next(1,200);
            uint256 hue = random.next(1, 360);
            uint256 saturation = random.next(75, 100);
            uint256 lightness = random.next(50, 90);
            bytes memory path = abi.encodePacked(
                points[0].toString(),
                ",",
                points[1].toString(),
                " ",
                points[2].toString(),
                ",",
                points[3].toString(),
                " ",
                points[4].toString(),
                ",",
                points[5].toString(),
                " S50,150 ",
                points[7].toString(),
                ",200'"
                );
            lines = abi.encodePacked(
                lines,
                "<path d='M",
                points[6].toString(),
                ",0 C",
                path,
                " stroke-width='3' fill='hsl(",
                hue.toString(),
                ",",
                saturation.toString(),
                "%,",
                lightness.toString(),
                "%)' fill-opacity='0.5'></path>"
                );
        }
        return lines;
    }

    /**
     * @notice getMouth
     */
    function _getMouth(uint256 mouthType)
    internal
    pure
    returns(bytes memory)
    {
        bytes memory mouth = abi.encodePacked(
            "<ellipse cx='100' cy='125' rx='20' ry='",
            mouthType.toString(),
            "' fill='white' stroke='black' stroke-width='2'></ellipse>"
            );
        return mouth;
    }

    /**
     * @notice getEyes
     */
    function _getEyes(Randomize.Random memory random) 
    internal 
    pure 
    returns(bytes memory)
    {
        uint256 eyeInnerType = random.next(1,2);
        uint256 eyePositionX = random.next(1,8); //random (-4,4);
        uint256 eyePositionY = random.next(1,10); //random(-5,5);
        uint256 circlePostionX = random.next(1,5); //random (-2,3);
        bytes memory inner;
        bytes memory outer;
        bytes memory eyePositionBytesX = eyePositionX < 5 ? abi.encodePacked('-',eyePositionX.toString()) : abi.encodePacked((eyePositionX - 4).toString());
        bytes memory eyePositionBytesY = eyePositionY < 6 ? abi.encodePacked('-',eyePositionY.toString()) : abi.encodePacked((eyePositionY - 5).toString());
        bytes memory circlePostionBytesX = circlePostionX < 3 ? abi.encodePacked('-',circlePostionX.toString()) : abi.encodePacked((circlePostionX - 2).toString());
        if(eyeInnerType == 1) {
            inner = "<ellipse rx='7' ry='5' cx='0' cy='0' fill='hsl(315, 87%, 2%)'></ellipse>";
        }
        else {
            inner = abi.encodePacked("<circle r='",random.next(4,7).toString(),"' cx='0' cy='0' fill='hsl(315, 87%, 2%)'></circle>"
                );
        }
        outer = abi.encodePacked(
            "<g transform='matrix(1,0,0,1,",
            eyePositionBytesX,
            ",",
            eyePositionBytesY,
            ")'><ellipse rx='7' ry='5' cx='0' cy='0' fill='hsl(315, 87%, 2%)'></ellipse>",
            "<circle r='2' cx='",
            circlePostionBytesX,
            "' cy='-2' fill='white'></circle></g>"
            );
        bytes memory eyes = abi.encodePacked(
            "<g transform='matrix(1,0,0,1,82.5,90)'><circle r='10' cx='0' cy='0' stroke-width='2' stroke='hsl(315, 87%, 2%)' fill='hsl(315, 87%, 98%)'></circle>",
            outer,
            "</g><g transform='matrix(1,0,0,1,117.5,90)'><circle r='10' cx='0' cy='0' stroke-width='2' stroke='hsl(315, 87%, 2%)' fill='hsl(315, 87%, 98%)'></circle>",
            outer,
            "</g>"
            );
        return eyes;
    }

    /**
     * @notice get Attributes Svg to display attributes score.
     */
    function _getCharAttributesSvg(uint16[] memory charAttributes)
    internal
    pure
    returns(bytes memory attributesSvg)
    {
        attributesSvg = abi.encodePacked(
            "<rect x='5' y='150' width='50' height='10' fill='#C2B280' stroke='#C2B280'></rect><text x='7' y='158' font-size='7'>Strength</text><rect x='45' y='150' width='20' height='10' fill='#000' stroke='#C2B280'></rect><text x='50' y='158' font-size='8' fill='#fff'>",
            charAttributes[0].toString(),
            "</text><rect x='5' y='162' width='50' height='10' fill='#C2B280' stroke='#C2B280'></rect><text x='7' y='170' font-size='7'>Knowledge</text><rect x='45' y='162' width='20' height='10' fill='#000' stroke='#C2B280'></rect><text x='50' y='170' font-size='8' fill='#fff'>",
            charAttributes[1].toString(),
            "</text><rect x='5' y='174' width='50' height='10' fill='#C2B280' stroke='#C2B280'></rect><text x='7' y='182' font-size='7'>Charm</text><rect x='45' y='174' width='20' height='10' fill='#000' stroke='#C2B280'></rect><text x='50' y='182' font-size='8' fill='#fff'>",
            charAttributes[2].toString(),
            "</text><rect x='5' y='186' width='50' height='10' fill='#C2B280' stroke='#C2B280'></rect><text x='7' y='194' font-size='7'>Money</text><rect x='45' y='186' width='20' height='10' fill='#000' stroke='#C2B280'></rect><text x='50' y='194' font-size='8' fill='#fff'>",
            charAttributes[3].toString(),
            "</text>"
            );
    }

    /**
     * @notice getPathsInfo
     * @dev 0=offset, 1=size, 2=clr
     */
    function _getPathsInfo(uint8 index)
    internal
    pure
    returns(uint24[3][] memory) {
        if(index == 1) {
            uint24[3][] memory info = new uint24[3][](6);
            info[0] = [uint24(0), uint24(175), 0x000001];
            info[1] = [uint24(175), uint24(121), 0x2b2c2d];
            info[2] = [uint24(296), uint24(89), 0x2b2c2d];
            info[3] = [uint24(385), uint24(117), 0x6a6a6d];
            info[4] = [uint24(502), uint24(86), 0x000000];
            info[5] = [uint24(588), uint24(63), 0xffffff];
            return (info);
        }
        else if(index == 2) {
            uint24[3][] memory info = new uint24[3][](4);
            info[0] = [uint24(651), uint24(128), 0x333333];
            info[1] = [uint24(779), uint24(209), 0x1e1e1e];
            info[2] = [uint24(988), uint24(49), 0x333333];
            info[3] = [uint24(1037), uint24(87), 0x474c51];
            return (info);
        }
        else if(index == 3) {
            uint24[3][] memory info = new uint24[3][](6);
            info[0] = [uint24(1124), uint24(93), 0x303030];
            info[1] = [uint24(1217), uint24(36), 0x303030];
            info[2] = [uint24(1253), uint24(33), 0x000000];
            info[3] = [uint24(1286), uint24(44), 0xffffff];
            info[4] = [uint24(1330), uint24(62), 0x000000];
            info[5] = [uint24(1392), uint24(90), 0x21201e];
            return (info);
        }
        else if(index == 4) {
            uint24[3][] memory info = new uint24[3][](4);
            info[0] = [uint24(1482), uint24(139), 0x2b2c2d];
            info[1] = [uint24(1621), uint24(183), 0x111111];
            info[2] = [uint24(1804), uint24(58), 0x000000];
            info[3] = [uint24(1862), uint24(96), 0xffffff];
            return (info);
        }
        else if(index == 5) {
            uint24[3][] memory info = new uint24[3][](2);
            info[0] = [uint24(1958), uint24(1436), 0x2b2c2d];
            info[1] = [uint24(3394), uint24(998), 0x222222];
            return (info);
        }
        else if(index == 6) {
            uint24[3][] memory info = new uint24[3][](3);
            info[0] = [uint24(4392), uint24(131), 0x272626];
            info[1] = [uint24(4523), uint24(420), 0x000000];
            info[2] = [uint24(4943), uint24(93), 0xfcfadd];
            return (info);
        }
        else if(index == 7) {
            uint24[3][] memory info = new uint24[3][](2);
            info[0] = [uint24(5036), uint24(535), 0x1c1c1c];
            info[1] = [uint24(5571), uint24(346), 0x848484];
            return (info);
        }
        else if(index == 8) {
            uint24[3][] memory info = new uint24[3][](2);
            info[0] = [uint24(5917), uint24(484), 0x1c1c1c];
            info[1] = [uint24(6401), uint24(488), 0x848484];
            return (info);
        }
        else { //index == 9
            uint24[3][] memory info = new uint24[3][](2);
            info[0] = [uint24(6889), uint24(734), 0x1c1c1c];
            info[1] = [uint24(7623), uint24(315), 0x848484];
            return (info);
        }
    }

    /**
     * @notice bytes3ToHexBytes
     */
    function _bytes3ToHexBytes(bytes3 _color)
    internal
    pure
    returns (bytes memory)
    {
        bytes memory numbers = "0123456789ABCDEF";
        bytes memory hexBytes = new bytes(6);
        uint256 pos;
        for (uint256 i; i < 3; i++) {
            hexBytes[pos] = numbers[uint8(_color[i] >> 4)];
            pos++;
            hexBytes[pos] = numbers[uint8(_color[i] & 0x0f)];
            pos++;
        }
        return hexBytes;
    }

}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Roc
 * @author Tfs128.eth (@trickerfs128)
 */
contract Roc {
    mapping(uint256 => uint256) public _child_rem;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant alphabet = "0123456789abcdef";

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
            buffer[i] = alphabet[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// small library to get random number
library Randomize {
    struct Random {
        uint256 seed;
        uint256 nonce;
    }

    function next(
        Random memory random,
        uint256 min,
        uint256 max
    ) internal pure returns (uint256 result) {
        max += 1;
        uint256 number = uint256(keccak256(abi.encode(random.seed,random.nonce))) % (max - min);
        random.nonce++;
        result = number + min;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @notice library to evaluate sin and cos using expanded taylor series by horner's rule.
 */
library Trignometry {

    int256 private constant PRECISION = 64;
    int256 private constant ONE_AT_PRECISION = 18446744073709551616; //2**64
    int256 private constant PI = 57952155664616982739; // PI * ONE_AT_PRECISION

    /**
     * @notice evaluate sin(x).
     * @dev sin(x) != sin(x + 2pi)
     */
    function sin(int256 x) internal pure returns(int256) {
        int256 value;
        assembly {
            let xsq := sar(PRECISION, mul(x, x)) // xsq = x^2
            let xx := add(51862, sar(PRECISION, mul(xsq, sub(0, 151)))) // b8 = 1/17! + xsq*(-1/19!)
            xx := add(sub(0, 14106527), sar(PRECISION, mul(xsq, xx))) // b7 = -1/15! + xsq*b8
            xx := add(2962370717, sar(PRECISION, mul(xsq, xx))) // b6 = 1/13! + xsq*b7
            xx := add(sub(0, 462129831893), sar(PRECISION, mul(xsq, xx))) // b5 = -1/11! + xsq*b6
            xx := add(50834281508238, sar(PRECISION, mul(xsq, xx))) // b4 = 1/9! + xsq*b5
            xx := add(sub(0, 3660068268593165), sar(PRECISION, mul(xsq, xx))) // b3 = -1/7! + xsq*b4
            xx := add(153722867280912930, sar(PRECISION, mul(xsq, xx))) // b2 = 1/5! + xsq*b3
            xx := add(sub(0, 3074457345618258602), sar(PRECISION, mul(xsq, xx))) // b1 = -1/3! + xsq*b2
            xx := add(ONE_AT_PRECISION, sar(PRECISION, mul(xsq, xx))) // t = 1 + xsq*b1
            xx := sar(PRECISION, mul(xx, x)) // sin(x) = t*x
            value := xx
           }
           return value;
       }

    /**
     * @notice evaluate cos(x)
     * @dev cos(x) = sin(90 - x)
     */
    function cos(int256 x) internal pure returns(int256) {
        int256 cx = PI/2 - x;
        if(cx < 0) {
            return -sin(cx * -1); //sin(-x) = -sin(x)
        }
        else {
            return sin(cx);
        }
    }


}