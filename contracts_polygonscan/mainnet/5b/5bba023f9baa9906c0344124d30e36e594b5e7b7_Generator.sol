/**
 *Submitted for verification at polygonscan.com on 2021-10-18
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library Generator{
    bytes constant base64Symbols = bytes("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/");
    bytes constant hexSymbols = bytes("0123456789ABCDEF");

    bytes constant backgroundDesc=bytes("eyJiYWNrZ3JvdW5kX2NvbG9yIjoiMDAwMDAwIiwiZGVzY3JpcHRpb24iOiAi");
    bytes constant description=bytes("T25DaGFpbmVkIE9yYiB3aXRoIGNvbG9yICAj");
    bytes constant name=bytes("IiwibmFtZSI6ICJPcmIg");
    bytes constant imageDataB64=bytes("LCJpbWFnZSI6ImRhdGE6aW1hZ2Uvc3ZnK3htbDtiYXNlNjQs");
    bytes constant svgHeaderB64=bytes("UEhOMlp5QjJaWEp6YVc5dVBTSXhMakVpSUhacFpYZENiM2c5SWpBZ01DQXlJRElpSUhodGJHNXpQU0pvZEhSd09pOHZkM2QzTG5jekxtOXlaeTh5TURBd0wzTjJaeUkr");
    bytes constant darkColorB64x2=bytes("TURBd01EQXdJ");
    bytes constant lightColorB64x2=bytes("UmtaR1JrWkdJ");
    bytes constant darkColorEndTagPaddedB64x2="SXpBd01EQXdNQ0l2UGlBZ0lDQWdJQ0Fn";
    
    bytes constant defsStart = bytes("UEdSbFpuTStJQ0Fn");
    bytes constant gradientStartNoId = bytes("UEhKaFpHbGhiRWR5WVdScFpXNTBJR1o0UFNJd0xqVXdJaUJtZVQwaU1DNDFNQ0lnWm5JOUlqQXVNREFpSUNCamVEMGlNQzQxTUNJZ1kzazlJakF1TlRBaUlISTlJakF1TlRBaUlDQnBaRDBp");
    bytes constant gradientId = bytes("Y2lJK0lDQWdJQ0Fn");
    bytes constant offsetPercent = bytes("UEhOMGIzQWdJQ0J2Wm1aelpYUWdQU0Fp");
    bytes constant eightyPercent = "T0RB";
    bytes constant offsetColor = bytes("bElpQnpkRzl3TFdOdmJHOXlQU0lq");
    
    bytes constant gradientEnd = bytes("SUR3dmNtRmthV0ZzUjNKaFpHbGxiblEr");
    bytes constant defsEnd = bytes("SUNBOEwyUmxabk0r");
    bytes constant endOfColorB64x2 = bytes("aTgr");
    
    bytes constant circleBegin=bytes("UEdOcGNtTnNaU0JqZUQwaU1TNHdNQ0lnWTNrOUlqRXVNREFpSUdacGJHd3RiM0JoWTJsMGVUMGlNUzR3TUNJZ2NqMGl");
    bytes constant circleRadiusBig=bytes("PVGM");
    bytes constant circleRadiusPhi=bytes("NQzQ");
    bytes constant circleEndNoFill=bytes("zTUNJZ1ptbHNiRDBp");
    bytes constant fillGradientB64x2="ZFhKc0tDY2pjaWNw";
    bytes constant circleEndTag = bytes("UEM5amFYSmpiR1Ur");
    bytes constant endOfTagPadded = bytes("SWo0Z0lDQWdJQ0Fn");
    bytes constant closeSvgJson=bytes("UEM5emRtYysifQ==");

    bytes constant chars=bytes("SHlR6XpWpUlZ3RnUn1rieQQx");

    function getb64FromBytes3(bytes memory inputBytes) public pure returns (bytes memory)
    {
        bytes memory errMessage=bytes("Remove   characters for b64 conversion");
        errMessage[7]=hexSymbols[inputBytes.length%3];
        require(inputBytes.length%3 == 0, string(errMessage));
        bytes memory outputBytesB64 = new bytes(inputBytes.length*4/3);
        for(uint16 p=0; p < outputBytesB64.length/4; p++)
        {
            uint16 sIndex = p*3;
            uint16 bIndex = p*4;
            outputBytesB64[bIndex] = base64Symbols[(uint8(inputBytes[sIndex]) & 0xFC) >> 2];
            outputBytesB64[bIndex+1] = base64Symbols[(uint8(inputBytes[sIndex]) & 0x3) << 4 | (uint8(inputBytes[sIndex+1]) & 0xF0) >> 4];
            outputBytesB64[bIndex+2] = base64Symbols[(uint8(inputBytes[sIndex+1]) & 0xF) << 2 | (uint8(inputBytes[sIndex+2]) & 0xC0) >> 6];
            outputBytesB64[bIndex+3] = base64Symbols[uint8(inputBytes[sIndex+2]) & 0x3F];
        }
        return outputBytesB64;
    }

    function getColorHex(uint colorCode, uint totalColors, uint requiredLevels) public pure returns (bytes memory) {
        uint remainingLevels = totalColors - requiredLevels;
        uint[] memory colorLevel = new uint[](3);
        uint colorOffset = 255 % (totalColors-1);
        uint colorStep = 255 / (totalColors-1);
        if(colorCode < (requiredLevels*remainingLevels*remainingLevels))
        {
            uint mainColorComponent=colorCode % requiredLevels;
            uint colorComponent=colorCode / requiredLevels;
        
            colorLevel[2] = (mainColorComponent + remainingLevels)*colorStep+colorOffset;
            colorLevel[0] = (colorComponent % remainingLevels)*colorStep+colorOffset;
            colorLevel[1] = (colorComponent / remainingLevels)*colorStep+colorOffset;
        }
        else if(colorCode < (requiredLevels*remainingLevels*(remainingLevels+totalColors)))
        {
            colorCode -= requiredLevels*remainingLevels*remainingLevels;
            uint mainColorComponent=colorCode % requiredLevels;
            uint colorComponent=colorCode / requiredLevels;
        
            colorLevel[1] = (mainColorComponent + remainingLevels)*colorStep+colorOffset;
            colorLevel[0] = (colorComponent % remainingLevels)*colorStep+colorOffset;
            colorLevel[2] = (colorComponent / remainingLevels)*colorStep+colorOffset;
        }
        else
        {
            colorCode -= requiredLevels*remainingLevels*(remainingLevels+totalColors);
            uint mainColorComponent=colorCode % requiredLevels;
            uint colorComponent=colorCode / requiredLevels;
        
            colorLevel[0] = (mainColorComponent + remainingLevels)*colorStep+colorOffset;
            colorLevel[1] = (colorComponent % totalColors)*colorStep+colorOffset;
            colorLevel[2] = (colorComponent / totalColors)*colorStep+colorOffset;
        }

        bytes memory colorHex = new bytes(6);
        for(uint8 j=0; j < 3; j++)
        {
            if(colorLevel[j] == colorOffset)
            {
                colorLevel[j] = 0;
            }
            colorHex[2*j] = hexSymbols[colorLevel[j]/16];
            colorHex[2*j+1] = hexSymbols[colorLevel[j]%16];
        }

        return colorHex;
    }

    function fillString(uint value, bytes memory ret, uint lastPosition) public pure returns (bytes memory){
        uint16 h=0;
        while(value != 0)
        {
            ret[lastPosition - h] = hexSymbols[value % 10];
            h++;
            value /= 10;
        }
        return ret;
    }

    function getTokenMetadataURI(uint tokenId, uint totalColors, uint requiredLevels)
    public
    pure
    returns (string memory)
    {
        bytes memory initialColorHex = getColorHex(tokenId, totalColors, requiredLevels);
        bytes memory initialColorHexB64=getb64FromBytes3(initialColorHex);
        bytes memory colorB64x2=getb64FromBytes3(abi.encodePacked(initialColorHexB64,"I"));
        bytes memory numberB64 = getb64FromBytes3(fillString(tokenId, bytes("    0\""), 4));
        
        bytes memory gradientEffect = abi.encodePacked(gradientStartNoId,
            gradientId);
        
        for(uint i = 0;i<3;i++)
        {
            gradientEffect = abi.encodePacked(gradientEffect,
            offsetPercent,
            eightyPercent,
            offsetColor,
            i==0 ? lightColorB64x2 : colorB64x2,
            endOfColorB64x2);
        }
        gradientEffect = abi.encodePacked(gradientEffect,gradientEnd);
        
        
        gradientEffect = abi.encodePacked(gradientEffect,gradientStartNoId,
            gradientId);

        for(uint i = 0;i<3;i++)
        {
            gradientEffect = abi.encodePacked(gradientEffect,
            offsetPercent,
            eightyPercent,
            offsetColor,
            i==0 ? colorB64x2 : darkColorB64x2,
            endOfColorB64x2);
        }
        gradientEffect = abi.encodePacked(gradientEffect,gradientEnd);
        
        bytes memory circlePhi = abi.encodePacked(circleBegin,
            circleRadiusPhi,
            circleEndNoFill,
            fillGradientB64x2,
            endOfTagPadded,
            circleEndTag);        
        
        circlePhi = abi.encodePacked(circleBegin,
            circleRadiusPhi,
            circleEndNoFill,
            fillGradientB64x2,
            endOfTagPadded,
            circleEndTag,
            circlePhi);

        bytes memory orbEffect = abi.encodePacked(
            circleBegin,
            circleRadiusBig,
            circleEndNoFill,
            darkColorEndTagPaddedB64x2,
            defsStart);
        
        orbEffect = abi.encodePacked(orbEffect,
            gradientEffect,
            defsEnd,
            circlePhi,
            closeSvgJson);

        bytes memory retB64=abi.encodePacked(
            backgroundDesc,description,
            initialColorHexB64,
            name,
            numberB64,
            imageDataB64,
            svgHeaderB64,
            orbEffect);

        uint16[24] memory pos=[uint16(508),525,526,562,563,581,582,597,598,661,741,940,941,958,1045,1093,1175,1253,1255,1471,1472,1584,1586,1587];
        for(uint i=0;i<pos.length;i++)
        {
            retB64[pos[i]] = chars[i];
        }

        return string(abi.encodePacked(
            "data:application/json;base64,",
            retB64));
    }
}