// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";

library TreeGenerator {

    struct xmasTree {
        uint256 bg;
        uint256 bgCol;
        uint256 treeType;
        uint256 treeCol;
        uint256 snowCap;
        uint256 star;
        uint256 starCol;
        uint256 ribbon;
        uint256 ribbonCol;
        uint256 bulb;
        uint256 gifts;
    }

    function getTreeForSeed(uint256 tokenId) external pure returns (xmasTree memory, string memory) {
        string[2] memory bg = ['<path d="M0 0 H500 V500 H0"/>','<filter x="0" y="0" width="100%" height="100%" id="a"><feTurbulence baseFrequency=".1 0.1" numOctaves="3"/><feColorMatrix values="0 0 0 9 -6 0 0 0 9 -6 0 0 0 9 -6 0 0 0 0 0.7"/></filter><path d="M0 0h500v500H0" fill="#BEE1E6"/><path d="M0 0h500v500H0" filter="url(#a)"/>'];
        string[9] memory bgCols = ['#BFBFBF','#D4A783','#F1A6AB','#ADC8C0','#93C9D1', '#B5C9FF','#87B5DF','#939DB2',''];
        string memory setup = '<path d="M0 320c232-54 193 127 500-6v186H0" fill="#fff"/><ellipse cx="255" cy="400" fill="#efefef" rx="96.5" ry="14.5"/><path d="m245 400 12-150 13 150" fill="#8b4513"/>'; //snow, shadow and bark
        string[2] memory star = ['','<path d="m255 79-12 34 30-24h-36l30 24z"/>'];
        string[2] memory snowCap = ['','<path d="M220 160c40 40 45-10 70 0l-35-60" fill="#fff"/>'];
        string[5] memory cols = ['#9B2424','#E9A100','#427700','#1F95FC','none'];
        string[2] memory ribbon = ['','<path d="m336 318.5-4.5-10c-66.055 19.767-103.507 28.463-171 40L154 362c72.583-10.511 112.561-19.48 182-43.5ZM310.5 239l-5-10.5c-47.195 21.782-74.009 32.304-123 45.5l-7.5 16c53.873-12.08 83.544-23.227 135.5-51ZM288.5 174l-3-6.5c-35.166 16.398-51.197 22.513-74.5 29l-4.5 10.5c33.152-8.483 51.168-15.466 82-33Z"/>'];
        
        xmasTree memory xt;

        uint256 rand = random(string(abi.encodePacked('Background', tokenId)))%100;
        if(rand < 90) {xt.bg = 0;} else {xt.bg = 1;}

        xt.bgCol = getAttr(tokenId, 'Background Color', bgCols.length-1);
        if(xt.bg == 1) {xt.bgCol=bgCols.length-1;}
        
        xt.treeType = getAttr(tokenId, 'Tree', 8);

        rand = random(string(abi.encodePacked('Tree Color', tokenId)))%100;
        if(rand < 52) {xt.treeCol = 0;}
        else if(rand < 60) {xt.treeCol = 1;}
        else if(rand < 68) {xt.treeCol = 2;}
        else if(rand < 76) {xt.treeCol = 3;}
        else if(rand < 84) {xt.treeCol = 4;}
        else if(rand < 92) {xt.treeCol = 5;}
        else {xt.treeCol = 6;}

        xt.snowCap = getAttr(tokenId, 'Snow Cap', snowCap.length);

        xt.star = getAttr(tokenId, 'Star', star.length);

        xt.starCol = getAttr(tokenId, 'Star Color', cols.length-1);
        if(xt.star == 0) {xt.starCol=cols.length-1;}

        xt.ribbon = getAttr(tokenId, 'Ribbon', ribbon.length);

        xt.ribbonCol = getAttr(tokenId, 'Ribbon Color', cols.length-1);
        if(xt.ribbon == 0) {xt.ribbonCol=cols.length-1;}
        
        xt.bulb = getAttr(tokenId, 'Bulbs', 2);

        rand = random(string(abi.encodePacked('Gifts', tokenId)))%100; 
        if(rand < 50) {xt.gifts = 0;}
        else if(rand < 75) {xt.gifts = 1;}
        else if(rand < 90) {xt.gifts = 2;}
        else if(rand < 95) {xt.gifts = 3;}
        else {xt.gifts = 4;}

        string[7] memory parts;

        parts[0] = string(abi.encodePacked('<g fill="',bgCols[xt.bgCol],'">',bg[xt.bg],'</g>')); // background
        parts[1] = pluckTree(xt.treeType, xt.treeCol); // tree leaves and branches stucture
        parts[2] = snowCap[xt.snowCap]; //snow cap
        parts[3] = string(abi.encodePacked('<g fill="',cols[xt.starCol],'">',star[xt.star],'</g>')); // star
        parts[4] = string(abi.encodePacked('<g fill="',cols[xt.ribbonCol],'">',ribbon[xt.ribbon],'</g>')); //ribbon
        parts[5] = pluckBulb(xt.bulb); //string lights
        parts[6] = pluckGift(xt.gifts);

        string memory output = string(abi.encodePacked('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 500 500">', parts[0], setup, parts[1], parts[2], parts[3], parts[4], parts[5], parts[6], '</svg>'));

        return (xt,output);
    }

    function pluckBulb(uint256 rand) public pure returns (string memory) {

        string memory wire = '<path d="M289 177c-29 20-47 27-83 33M330 305c-65 19-101 27-166 35M204 231c34 31 63 41 125 47" fill="none" stroke="#000"/>';
        string[2] memory bulbs = ['<ellipse cx="-102.4" cy="-329.3" rx="2.6" ry="4.2" transform="matrix(.7914 -.6113 .65573 .755 291 179)" id="b1" fill="#E7FFFC"/>','<ellipse cx="-297.8" cy="-75" rx="2.6" ry="4.2" transform="matrix(.81792 .57533 -.52743 .8496 204 228)" id="b2" fill="#E7FFFC"/>'];
        uint16[24] memory b1x = [297,284,280,265,263,248,241,229,222,209,337,321,314,297,288,270,261,243,235,218,207,190,182,169];
        uint16[24] memory b1y = [187,187,199,197,208,204,215,210,219,214,314,312,323,319,330,325,336,331,342,336,346,340,350,345];
        uint16[13] memory b2x = [204,208,221,226,240,246,260,266,282,289,304,315,329];
        uint16[13] memory b2y = [235,247,246,261,259,272,268,279,274,284,278,288,282];
        if(rand==1) {
            string memory output = string(abi.encodePacked(wire, bulbs[0], bulbs[1]));
            for (uint256 i=0;i<b1x.length;i++) {
                output = string(abi.encodePacked(output,'<use href="#b1" x="',Strings.toString(b1x[i]),'" y="',Strings.toString(b1y[i]),'"/>'));
            }
            for (uint256 i=0;i<b2x.length;i++) {
                output = string(abi.encodePacked(output,'<use href="#b2" x="',Strings.toString(b2x[i]),'" y="',Strings.toString(b2y[i]),'"/>'));
            }
            return output;
        }
        return '';
    }

    function pluckGift(uint256 a) public pure returns (string memory) {
        string[5] memory gifts = ['','<path d="M260 420h73v-30h-73" fill="#853DBD"/><path d="M255 390h83v10h-83" fill="#A95BE7"/><path d="M292 420h10v-30h-10" fill="#F6A102"/><path d="M298 390c-34-5-12-32 0 0m0 0c4-28 40-10 0 0" stroke="#F6A102" stroke-width="3" fill="none"/>','<path d="M194 420h68v-61h-68" fill="#1F95FC"/><path d="M189 349h78v10h-78" fill="#4FBAFF"/><path d="M223 420h10v-71h-10" fill="#F6A102"/>','<path d="M132 432h68v-61h-68" fill="#AD4255"/><path d="M132 397v10h68v-10" fill="#F6A102"/>','<path d="M312 424h50v-45h-50" fill="#3A9981"/><path d="M307 369h60v10h-60" fill="#2E7B68"/><path d="M332 424h10v-55h-10" fill="#F6A102"/>'];
        if(a==0) { return '';}
        if(a==1) { return gifts[1];}
        if(a==2) { return string(abi.encodePacked(gifts[2], gifts[1])); }
        if(a==3) { return string(abi.encodePacked(gifts[2], gifts[3], gifts[1]));}
        return string(abi.encodePacked(gifts[1], gifts[3], gifts[2], gifts[4]));
    }

    function pluckTree(uint256 a, uint256 b) public pure returns (string memory) {
        string[8] memory trees = ['<path d="m149 371 31-64 141 22"/><path d="m282 202 77 167-181-53 103-114h1z"/><path d="m167 332 60-132 96 84-156 48z"/><path d="M274.617 176.521 335.32 296.25l-140.84-44.555 80.176-74.175-.039-.999z"/><path d="m230 172-56 120 127-75-70-45h-1z"/><path d="M312.5 243.5 270 145l-45 56 87.5 42.5z"/><path d="m254.5 103-55 117 82.5-55-27.5-62z"/><path d="m291 181-36-80-34.5 59h25"/>','<path d="m150 370 105-230 105 230"/><path d="m170 300 85-180 85 180"/><path d="m200 220 55-120 55 120"/><path d="m220 160 35-60 35 60"/>','<path d="M150 370c5-11 105-228 105-228s101 220 103 228-26-14-26-14.5c0 0-2 14-16 14s-15-14-15-14-6 14-21 14c-14 0-22-14-22-14s-6 16-20 14-19-14-19-14-8 14-21 14c-12 0-16-14-16-14s-35 26-30 14z"/><path d="M169 303c4-14 86-180 86-180s86 173 86 180-25-22-25-22 0 22-14 22-18-22-18-22-7 22-21 22-21-22-21-22-7 22-20 22-25-22-25-22-30 36-26 22z"/><path d="M200 222c2-12 55-120 55-120s51 112 55 123-22-22-22-22 5 17-8 18-22-19-22-19-4 21-17 21c-12 0-15-21-15-21s-27 33-25 21z"/><path d="M221 160c4-10 34-59 34-59s30 51 34 59-21-11-21-11-5 10-13 11c-7 1-11-11-11-11s-27 21-22 11h-1z"/>','<path d="M150 371c4-5 104-230 104-230s100 223 104 230c4 6-28 0-28 0s6 4 5 6c0 2-50 0-50 0s7 3 4 6-62 1-67 0 5-6 5-6-49.5 1-53 0c-3-1 4-6 4.5-6 0 0-33 5-29 0z"/><path d="M170 301c4-7 85-180 85-180s80 173 84 180-24 0-24 0 11 7 6 7h-28s11 7 5 7h-20s6 4 5 8-54 4-56 0c-1-4 5-8 5-8h-20c-6 0 5-7 5-7h-28c-5 0 5-7 5-7s-29 7-24 0z"/><path d="M200 221c2-5 55-120 55-120s52 116 55 120c2 4-15 0-15 0s7 5 4 5h-16s7 5 3 5h-17s5 2 3 5-31 2-34 0c-2-2 3-5 3-5h-17c-3 0 3-5 3-5h-14c-4 0 2-5 2-5s-18 5-15 0z"/><path d="M220 161c2-2 35-60 35-60s33 57 35 60c2 2-16 0-16 0s5 4 2 4h-13s3 2 0 3-17 1-20 0c-2-1 0-3 0-3h-12c-1 0 2-4 2-4s-16 2-13 0z"/>','<path d="m150 371 105-230 105 230-24 3-18-39 9 40-24 2-15-40 5 40-23 1-12-44v44h-23l-2-44-6 44-20-1 2-42-12 42-20-2 10-44-18 43-17-3z"/><path d="m170 301 85-180 85 180-21 3-17-38 10 40-22 3-11-38 2 40h-20l-4-39-4 39h-21l-3-41-4 40-24-3 9-38-18 37-20-3z"/><path d="m200 220 54-119 54 119-17 2-12-21 2 21-15 1-7-20-1 21h-17l-2-21-5 21-12-1 3-21-10 20-14-2z"/><path d="m220 161 35-60 34 60-14 3-7-13 3 14-13 1-2-14-3 14-12-1 1-15-6 14-14-4z"/>','<path d="m150 371 105-230 105 230-104-22-105 22z"/><path d="m170 301 85-180 84 179-84-20-85 21z"/><path d="m200 221 55-119 55 119-55-13-55 13z"/><path d="m220 161 35-60 35 60-34-9-35 9z"/>','<path d="m150 371 105-230 105 230-31-21-20 21-17-21-18 21-18-21-19 21-17-21-21 21.5-18-21.5-28 21z"/><path d="m170 301 85-180 85 180-29-19-19 19-19-19-20 19-22-19-17 19-18-19-24 19z"/><path d="m200 221 55-120 55 120-24-17-14 17-17-17-17 17-14-17-23 17z"/><path d="m220 161 35-60 35 60-21-11-13 11-15-11.5-19 11z"/>','<path d="M155.37 357.957C176.967 315.765 255.099 147 255.099 147s79.783 173.091 99.728 210.957c19.945 37.866-221.05 42.191-199.455 0z"/><path d="M175.5 289.569C193.674 253.855 255 107 255 107s60.714 150.517 77.5 182.569c16.785 32.053-175.175 35.714-157 0z"/><path d="M200.746 216.417C212.506 194.534 255.053 107 255.053 107s43.446 89.777 54.307 109.417c10.862 19.64-120.374 21.884-108.614 0z"/><path d="M220 161c7.58-12 35-60 35-60s28 49.23 35 60c7 10.77-77.579 12-70 0z"/>'];
        string[14] memory treeCols = ['#4D7C14','#8CB247','#FFFFFF','#CAE3FF','#F0AD15','#FFDA89','#213052','#6376A0','#831111','#E86161','#831177','#E861DA','#107099','#09BBF3'];
        return string(abi.encodePacked('<defs><linearGradient id="tc" x2="0" y2="1"><stop offset="0" stop-color="',treeCols[b*2],'"/><stop offset="1" stop-color="',treeCols[(b*2)+1],'" /></linearGradient></defs>', '<g style="fill:url(#tc)">', trees[a], '</g>'));
    }

    function getAttr(uint256 tokenId, string memory key, uint256 length) internal pure returns (uint256) {
        return (random(string(abi.encodePacked(key, tokenId)))%100)%length;
    }

    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Strings.sol)

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