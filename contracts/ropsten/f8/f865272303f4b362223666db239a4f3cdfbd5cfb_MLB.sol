/**
 *Submitted for verification at Etherscan.io on 2021-10-06
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";


    /**
     * @dev Converts a `hex string` to uint256
     */
     function fromHex(string memory c) internal pure returns (uint256) {
        string memory s1 = Strings.substr(c,0,1);
        string memory s2 = Strings.substr(c,1,2);
        uint a;
        uint b;
        
        if (bytes1(bytes(s1)) >= bytes1('0') && bytes1(bytes(s1)) <= bytes1('9')) {
            a = strToUint(s1);
        }
        if (bytes1(bytes(s1)) >= bytes1('a') && bytes1(bytes(s1)) <= bytes1('f')) {
            a = 10 + uint256(uint8(bytes1(bytes(s1)))) -  uint256(uint8(bytes1('a')));
        }
        
        if (bytes1(bytes(s2)) >= bytes1('0') && bytes1(bytes(s2)) <= bytes1('9')) {
            b = strToUint(s2);
        }
        if (bytes1(bytes(s2)) >= bytes1('a') && bytes1(bytes(s2)) <= bytes1('f')) {
            b = 10 + uint256(uint8(bytes1(bytes(s2)))) -  uint256(uint8(bytes1('a')));
        }
        return b + 16 * a;
     }
     
    
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
            return "00";
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
        return Strings.substr(string(buffer), 2,4);
    }
    
      function strToUint(string memory s) internal pure returns (uint256) {
        bytes memory b = bytes(s);
        uint256 result = 0;
        for (uint256 i = 0; i < b.length; i++) { // c = b[i] was not needed
            if (b[i] >= 0x30 && b[i] <= 0x39) {
                result = result * 10 + (uint(uint8((b[i]))) - 48); // bytes and int are not compatible with the operator -.
            }
        }
        return result; // this was missing
    }

    function substr(
        string memory str,
        uint256 startIndex,
        uint256 endIndex
    ) internal pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(endIndex - startIndex);
        for (uint256 i = startIndex; i < endIndex; i++) {
            result[i - startIndex] = strBytes[i];
        }
        return string(result);
    }
}

/// [MIT License]
/// @title Spectacular mountains
/// @notice functions
/// @author @Cryptodizzie

library MLB {
    
      /* struct draw */
    struct draw {        
        uint move;
        uint direction;
        uint offset;
        uint flipflag;
        uint kflip;
        uint pointsMax;
        uint y1old; uint y1; uint x1;
        uint yc;
    }
    
    /* struct chartCoords */
    struct chartCoords {        
        uint n;
        uint sx; uint sy;  
        uint x; uint xold; uint xstep;          
        uint[5] y;
        uint[5] yold;
        uint sunOffset;
    }
    
    /* struct layerSettings */
    struct layerSettings {
        uint layersAmount;
        uint8[5] kHighs;
        uint8[5] maxHighs;
        uint8[5] probMove;
        uint8[5] moveThres;
    }

    struct layout {
        string[5] paths;
        string o;
        string pathCloud;
    }

    struct colorSettings{        
        uint256[3] delta;
        string sc;
        string sc2;
        string offset_canvas;
        string bottomcolor;
        string fillopacity;
        string[6] bc;
    }
    
        
    function getLP(uint tokenId, uint lp, colorSettings memory cs, chartCoords memory cr, layerSettings memory ls) public pure returns (string memory) {
        uint[13] memory rands = getRand(tokenId, lp);
        string memory dummy;
        
        cs.offset_canvas = "30%";
        
        string memory aer = string(abi.encodePacked('<g transform="translate(100,4720) scale(0.04,0.04)"><path style="fill-opacity:10%" fill="#264823" d="M',t(cr.sx + 150),',',t(cr.sy - 100),'.32c2.97-9.83,9.83-15.37,19.46-18.19c4.14-1.22,9.64-2.21,11.62-5.21c2.09-3.18,0.81-8.63,0.84-13.09c0.06-8.85-0.01-17.71,0.03-26.56c0.04-8.7,3.91-12.62,12.48-12.64c11.97-0.02,23.95,0.08,35.92-0.05c4.3-0.05,7.69,1.34,10.63,4.44c4.97,5.25,10.21,10.26,15.12,15.57c2.06,2.22,3.71,2.7,6.7,1.53c27.01-10.59,53.76-21.94,81.23-31.19c60.14-20.25,115.01-9.4,162.86,32.23c36.03,31.34,34.98,87.11-1.01,118.55c-12.77,11.16-26.8,20.3-42.42,26.93c-2.17,0.92-3.22,2.24-3.86,4.5c-2.9,10.3-5.99,20.56-9.07,30.81c-2.09,6.96-5.32,9.4-12.46,9.4c-27.44,0.02-54.88,0.02-82.31,0c-7.08-0.01-10.41-2.57-12.39-9.49c-3.11-10.89-6.08-21.83-9.36-32.67c-0.48-1.6-2.07-3.44-3.6-4.06c-22.97-9.27-46.04-18.32-69.03-27.55c-2.27-0.91-3.53-0.46-5.11,1.2c-5.05,5.35-10.33,10.49-15.41,15.8c-2.84,2.97-6.12,4.44-10.28,4.41c-12.22-0.1-24.44,0-36.67-0.05c-7.83-0.03-11.91-4.13-11.96-12.06c-0.07-12.47-0.08-24.94,0.03-37.41c0.02-2.46-0.54-3.85-3.08-4.65c-3.55-1.11-6.87-2.98-10.43-4.06c-9.4-2.86-15.83-8.57-18.47-18.2Cz"/><animateMotion dur="1800s" repeatCount="indefinite" path="M0,0 A 600,150 1 0 1 600,100 A 600,150 0 0 1 -600,150z" /></g>'));
        
        if (lp == 0) {
            /* sunrise */
            cs.bottomcolor = "#474747";
            cs.bc[1] = "#676767";
            cs.sc = "#e1866f";
            cs.sc2 = "#f7e68c";

            
            for (uint i = 1; i<=4; i++) {
                cs.bc[i+1] =  rgbTint(cs.bc[i], i, 1);
            }
            cs.sc  =  rgbShift(cs.sc, cs.delta[0]*2, cs.delta[1]*2, cs.delta[2]*2, 1);

            /* sunrise */            
            dummy = string(abi.encodePacked('<filter id="sun"><feGaussianBlur stdDeviation="3"/></filter>', stars(4, cr.sx, cr.sy - 300, cr.sx + 400, cr.sy - 100, tokenId),'<circle r="40" cx="',t(cr.sx + 200 + cr.sunOffset),'" cy="',t(cr.sy - 100),'" filter="url(#sun)" fill-opacity="100%" fill="#ffffaa"><animate attributeName="cy" begin="0s" dur="90s" repeatCount="0" from="',t(cr.sy - 100),'" to ="',t(cr.sy - 150),'" fill="freeze"/><animate attributeName="r" begin="0s" dur="15s" repeatCount="0" from="40" to="34" fill="freeze"/></circle>'));
            
        }
        if (lp == 1) {
            
            /* daylight */
            cs.bottomcolor = "#163042";
            cs.bc[1] = "#356382";
            cs.sc = "#0487e2";            
            cs.sc2 = "#afafaf";    
            
            cs.bottomcolor = rgbShift(cs.bottomcolor, cs.delta[0], cs.delta[1], cs.delta[2], 1);
            cs.bc[1] =  rgbShift(cs.bc[1], cs.delta[0], cs.delta[1], cs.delta[2], 1);
            
            /* daylight */
            for (uint i = 1; i<=4; i++) {
                cs.bc[i+1] = rgbTint(cs.bc[i], i, 1);
            }
            /* daylight sun */            
            dummy = string(abi.encodePacked('<filter id="sun" x="-50%" y="-50%" width="200%" height="200%"><feGaussianBlur stdDeviation="3"/></filter><circle r="20" cx="',t(cr.sx+100),'" cy="',t(cr.sy-200),'" filter="url(#sun)" fill="#ffffaa"><animateMotion dur="3600s" repeatCount="indefinite" path="M0,0 A 600,150 1 0 1 600,100 A 600,150 0 0 1 -600,150z" /></circle>'));
            
        }   
        
        if (lp == 2) {
            
             /* daycloudy */
            cs.bottomcolor = "#111111";
            cs.bc[1] = "#333333";
            cs.sc = "#cccccc";
            cs.sc2 = "#8f8f8f";
            
            if (cs.delta[0] > 5) cs.delta[0] -=4;
            if (cs.delta[1] > 5) cs.delta[1] -=4; 
            if (cs.delta[2] > 5) cs.delta[2] -=4;
            cs.bottomcolor =  rgbShift(cs.bottomcolor, cs.delta[0],cs.delta[1],cs.delta[2], 1);
            cs.bc[1] =  rgbShift(cs.bc[1], cs.delta[0],cs.delta[1],cs.delta[2], 1);
            
            /* daycloudy */
            for (uint i = 1; i<=4; i++) {
                cs.bc[i+1] =  rgbTint(cs.bc[i], i, 1);
            }

            /* daycloudy sun */            
            dummy = string(abi.encodePacked('<filter id="sun" x="-200%" y="-200%" width="400%" height="400%"><feGaussianBlur stdDeviation="8"/></filter><circle r="20" cx="',t(cr.sx+100),'" cy="',t(cr.sy-200),'" filter="url(#sun)" fill-opacity="60%" fill="#ffffff"><animateMotion dur="3600s" repeatCount="indefinite" path="M0,0 A 600,150 1 0 1 600,100 A 600,150 0 0 1 -600,150z" /></circle>','<circle r="80" cx="',t(cr.sx+100),'" cy="',t(cr.sy-200),'" filter="url(#sun)" fill-opacity="20%" fill="#ffffff"><animateMotion dur="3600s" repeatCount="indefinite" path="M0,0 A 600,150 1 0 1 600,100 A 600,150 0 0 1 -600,150z" /></circle>'));
     
        }
        
        if (lp == 3) {
             /* sunset */
            cs.bottomcolor = "#241818";
            cs.bc[1] = "#4d3535";
            cs.sc = "#0487e2";
            cs.sc2 = "#d44e41";
            cs.offset_canvas = "10%";

            cs.bc[1] =  rgbTint(cs.bc[1], 2, 1);
            cs.bc[2] =  rgbTint(cs.bc[1], 1, 1);
            cs.bc[3] =  rgbTint(cs.bc[1], 2, 1);            
            cs.bc[4] = "#8a5047";
            cs.bc[5] =  rgbTint(cs.bc[1], 4, 1);
            
            cs.sc  =  rgbShift(cs.sc, cs.delta[0]*2, cs.delta[1]*2, cs.delta[2]*2, 1);
            /* sunset */
            dummy = string(abi.encodePacked('<filter id="sun"><feGaussianBlur stdDeviation="3"/></filter><linearGradient id="sungrad" x1="0%" y1="0%" x2="0%" y2="100%"><stop offset="30%" stop-color="#ffff88"/><stop offset="90%" stop-color="#cf4b3e"/><animate attributeName="y2" begin="0s" dur="90s" repeatCount="0" from="100%" to="0%" fill="freeze"></animate></linearGradient>'));
            dummy = string(abi.encodePacked(dummy, stars(6, cr.sx, cr.sy - 300, cr.sx + 400, cr.sy - 150, tokenId),'<circle id="suncircle" r="34" cx="',t(cr.sx + 200 + cr.sunOffset),'" cy="',t(cr.sy - 150),'" filter="url(#sun)" fill-opacity="100%" fill="url(#sungrad)"><animate attributeName="cy" begin="0s" dur="90s" repeatCount="0" from="',t(cr.sy - 150),'" to ="',t(cr.sy - 50),'" fill="freeze"/><animate attributeName="r" begin="0s" dur="15s" repeatCount="0" from="34" to="40" fill="freeze"/></circle>'));
        }
        if (lp == 4) {
            /* night stars */  
            cs.sc = "#000000";
            cs.sc2 = "#99a0b4";
            cs.bottomcolor = "#272823";
            cs.bc[1] = "#292927";

            /* night */
            for (uint i = 1; i<=4; i++) {
                cs.bc[i+1] =  rgbTint(cs.bc[1], i, 1);
            }
            /* night stars */                
            dummy = string(abi.encodePacked(stars(100, cr.sx, cr.sy-300, cr.sx+400, cr.sy, tokenId)));                                 
        }
        if (lp == 5) {
            /* night crescent moon*/
            cs.sc = "#000000";
            cs.sc2 = "#99a0b4";
            cs.bottomcolor = "#272823";
            cs.bc[1] = "#292927";
            for (uint i = 1; i<=4; i++) {
                cs.bc[i+1] =  rgbTint(cs.bc[1], i, 1);
            }
            
            dummy = string(abi.encodePacked('<radialGradient id="half_moon" fx="15%" fy="40%" r="100%" spreadMethod="pad"><stop offset="50%" stop-color="#000"/><stop offset="100%" stop-color="#ffffdd"/></radialGradient>'));            
            dummy = string(abi.encodePacked(dummy, '<filter id="moon"><feGaussianBlur stdDeviation="1"/></filter>', stars(20, cr.sx, cr.sy - 300, cr.sx + 400, cr.sy, tokenId)));
            dummy = string(abi.encodePacked(dummy, '<circle r="20" cx="',t(cr.sx + 100),'" cy="',t(cr.sy - 200),'" filter="url(#moon)" fill-opacity="100%" fill="url(#half_moon)"><animateMotion dur="3600s" repeatCount="indefinite" path="M0,0 A 600,150 1 0 1 600,100 A 600,150 0 0 1 -600,150z" /></circle>'));
        }
        if (lp == 6) {
            /* night full moon */  
            cs.sc = "#000000";
            cs.sc2 = "#99a0b4";
            cs.bottomcolor = "#272823";
            cs.bc[1] = "#292927";
            for (uint i = 1; i<=4; i++) {
                cs.bc[i+1] =  rgbTint(cs.bc[1], i, 1);
            }
                                              
            dummy = string(abi.encodePacked('<filter id="moon"><feGaussianBlur stdDeviation="1"/></filter>', stars(20, cr.sx, cr.sy - 300, cr.sx + 400, cr.sy, tokenId)));
            dummy = string(abi.encodePacked(dummy, '<circle r="20" cx="',t(cr.sx + 100),'" cy="',t(cr.sy - 200),'" filter="url(#moon)" fill-opacity="100%" fill="#c8c0b9"><animateMotion dur="3600s" repeatCount="indefinite" path="M0,0 A 600,150 1 0 1 600,100 A 600,150 0 0 1 -600,150z" /></circle>'));
        }
        if (lp == 7) {
            cs.bottomcolor = "#413023";
            cs.bc[1] = "#754f33";
            cs.sc = "#f1e0c4";
            cs.sc2 = "#907c55";
            
            cs.bottomcolor =  rgbShift(cs.bottomcolor, cs.delta[0], 0, 0, 1);
            cs.bc[1] =  rgbShift(cs.bc[1], cs.delta[0], 0, 0, 1);
            
            /* mars */
            for (uint i = 1; i<=4; i++) {
                cs.bc[i+1] =  rgbTint(cs.bc[i], i, 1);
            }
            
            /* mars sun */            
            dummy = string(abi.encodePacked('<filter id="sun" x="-50%" y="-50%" width="200%" height="200%"><feGaussianBlur stdDeviation="2"/></filter><circle r="10" cx="',t(cr.sx + 100),'" cy="',t(cr.sy - 200),'" filter="url(#sun)" fill="#ffffff"><animateMotion dur="3600s" repeatCount="indefinite" path="M0,0 A 600,150 1 0 1 600,100 A 600,150 0 0 1 -600,150z" /></circle>'));  
        }
        if (lp == 8) {
            cs.bottomcolor = "#000000";
            cs.bc[1] = "#33394d";
            cs.sc = "#51698c";
            cs.sc2 = "#4d4240";
            cs.offset_canvas = "10%";
           
            /* mars sunset */
            cs.bc[1] =  rgbTint(cs.bc[1], 2, 0);
            cs.bc[2] =  rgbTint(cs.bc[1], 1, 1);
            cs.bc[3] =  rgbTint(cs.bc[1], 2, 1);            
            cs.bc[4] = "#33394d";
            cs.bc[5] =  rgbTint(cs.bc[1], 4, 1);            

            /* mars sunset */            
            dummy = string(abi.encodePacked('<filter id="sun" x="-200%" y="-200%" width="400%" height="400%"><feGaussianBlur stdDeviation="2"/></filter><filter id="sunhalo" x="-200%" y="-200%" width="400%" height="400%"><feGaussianBlur stdDeviation="18"/></filter><ellipse rx="70" ry="100" cx="',t(cr.sx + 200 + cr.sunOffset),'" cy="',t(cr.sy - 120),'" filter="url(#sunhalo)" fill-opacity="50%" fill="#a6b9dc"><animate attributeName="cy" begin="0s" dur="85s" repeatCount="0" from="',t(cr.sy - 120),'" to ="',t(cr.sy - 20),'" fill="freeze"/></ellipse>'));            
            dummy = string(abi.encodePacked(dummy, '<circle id="suncircle" r="10" cx="',t(cr.sx + 200 + cr.sunOffset),'" cy="',t(cr.sy - 150),'" filter="url(#sun)" fill-opacity="100%" fill="#fff"><animate attributeName="cy" begin="0s" dur="90s" repeatCount="0" from="',t(cr.sy - 150),'" to ="',t(cr.sy - 50),'" fill="freeze"/><animate attributeName="r" begin="0s" dur="15s" repeatCount="0" from="10" to="14" fill="freeze"/></circle>'));
        }
        if (lp == 9) {
            cs.sc = "#000000";
            cs.sc2 = "#99a0b4";
            cs.bottomcolor = "#000000";
            cs.bc[1] = "#4f1511";

            /* halloween */
            cs.bc[2] =  rgbTint(cs.bc[1], 1, 1);
            cs.bc[3] =  rgbTint(cs.bc[1], 2, 1);
            
            /* halloween */                                    
            dummy = string(abi.encodePacked('<filter x="-200%" y="-200%" width="400%" height="400%" id="pumpkin"><feColorMatrix type="matrix" result="color" values="1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0"></feColorMatrix><feGaussianBlur in="color" stdDeviation="40" result="blur"></feGaussianBlur><feOffset in="blur" dx="0" dy="0" result="offset"></feOffset><feMerge><feMergeNode in="bg"></feMergeNode><feMergeNode in="offset"></feMergeNode><feMergeNode in="SourceGraphic"></feMergeNode></feMerge></filter>',stars(20, cr.sx, cr.sy - 300, cr.sx + 400, cr.sy, tokenId)));

            uint trx; uint trxy;
            trx = rands[8] % 101;
            trxy = 50 + rands[9] % 251;
            dummy = string(abi.encodePacked(dummy , '<g transform="translate(100,4700) scale(0.04,0.04)"><animateMotion dur="600s" repeatCount="indefinite" path="M0,0 C',t(trx),',-100 200,',t(trxy),' 200,50 C200-100 20,',t(trxy),' ',t(trx),',50 z" />'));
            dummy = string(abi.encodePacked(dummy, '<path filter="url(#pumpkin)" style="stroke:none;fill:#c9782c;" d="M ',t(cr.sx + 400),' ',t(cr.sy - 100),'l-4,13l-4,12l-5,13l-5,12l-5,12l-8,11l-8,11l-8,10l-9,10l-8,11l-8,10l-10,9l-10,10l-10,9l-10,-14l-9,-14l-10,-13l-3,15l-4,15l-3,16l-3,15l-13,3l-13,3l-12,3l-13,2l-13,0l-13,1l-12,-1l-13,-3l-13,-1l-12,-4l-12,-3l-12,-4l-4,-15l-4,-14l-3,-15l-4,-15l-8,13l-7,14l-8,13l-12,-11l-12,-10l-11,-10l-10,-13l-10,-12l-10,-12l-8,-14l-8,-14l-7,-14l-5,-14l-6,-15l-6,-15l13,9l14,8l13,8l14,7l15,5l14,7l3,14l3,13l3,14l3,14l7,-11l8,-10l7,-11l6,-11l14,2l13,3l13,2l13,2l13,1l14,1l13,0l14,0l13,-1l13,-1l14,-2l13,-1l13,-4l13,-3l14,-1l9,13l9,14l9,14l4,-14l2,-13l3,-14l3,-13l13,-8l14,-7l13,-9l14,-7l13,-9l13,-9zm-420,-94l8,-20l11,-19l14,-15l15,-16l12,17l13,16l12,16l13,15l15,14l13,15l15,14l-22,3l-21,0l-21,0l-21,-2l-21,-5l-21,-5l-20,-8zm9,-66l8,-12l10,-13l9,-12l10,-10l6,-4l9,17l9,12l9,12l9,11l9,12l10,12l11,12l11,11l10,12l1,2l-1,-1l-13,-11l-13,-10l-12,-11l-9,-9l-9,-9l-9,-9l-6,-6l-9,-13l-11,-12l-13,9l-12,11l-15,11zm147,124l11,4l11,1l10,3l11,1l11,-2l10,-4l11,-3l10,-4l9,-5l-12,17l-9,18l-10,18l-8,18l-8,19l-10,-18l-11,-17l-11,-17l-12,-17l-12,-16zm102,-39l12,-16l13,-16l12,-16l12,-16l11,-17l10,-18l18,14l14,16l12,17l10,19l7,20l-19,10l-20,7l-21,5l-21,3l-21,3l-21,1l-21,-1zm-12,-18l9,-14l9,-13l9,-14l8,-15l8,-15l9,-14l5,-13l6,-13l5,-13l0,0l16,10l11,11l11,10l11,11l3,3l-3,-1l-10,-7l-12,-5l-11,-6l-10,-4l-8,14l-9,13l-8,14l-8,10l-7,11l-9,11l-8,10l-9,10l-9,11zm234,-133c-1,-1,-2,-2,-3,-2c2,6,3,14,5,18c4,8,8,15,11,19c3,4,6,23,5,43c-1,20,-5,30,-10,41c-1,-3,2,-19,2,-27c0,-8,0,-32,-1,-37c-3,-15,-24,-55,-36,-69c-6,-2,-12,-4,-18,-7c-16,-9,-22,-21,-49,-27c-18,-5,-34,-1,-46,1c2,3,10,9,10,9c5,6,9,13,13,20c1,5,3,10,3,13c0,3,9,16,13,21c7,10,3,26,4,36c-6,-8,-8,-18,-9,-25c-1,-7,-12,-20,-17,-30c-6,-10,-15,-16,-16,-20c1,-8,-4,-13,-7,-14c-3,-2,-14,-6,-21,-8c-4,-8,-14,-12,-44,-11c0,-7,-2,-10,-10,-12c-9,-4,-16,7,-23,-23c-7,-30,-52,-71,-67,-92c-15,-21,-32,17,-18,34c39,48,19,79,-3,78c-12,0,-16,6,-17,11c-9,0,-17,-2,-26,1c-4,1,-8,4,-9,6c-2,4,-18,24,-22,30c-2,12,-9,20,-15,28c1,-15,2,-25,6,-39c4,-7,9,-14,15,-20c-19,0,-30,-5,-58,-1c-14,3,-26,8,-36,14c-6,4,-13,11,-14,14c-1,2,-23,16,-24,28c-1,10,-6,25,-10,32c-6,12,-7,44,-7,44c0,0,-4,-23,-4,-23c1,-12,3,-24,4,-36c0,0,4,-18,9,-22c2,-2,5,-12,8,-19c-8,4,-17,9,-23,14c-53,43,-81,110,-84,188c-3,105,35,202,123,263c15,10,36,20,57,28c-17,-14,-36,-33,-51,-52c-5,-19,-10,-37,-11,-57c-1,-15,1,-26,6,-39c1,50,3,63,24,102c13,8,13,15,27,23c9,12,19,22,29,31c10,2,20,3,29,4c9,5,17,9,25,13c18,2,31,-1,49,-3c-8,-5,-17,-11,-20,-10c-8,3,-30,-26,-30,-31c-1,-9,-3,-23,-7,-36c12,16,21,36,24,45c4,5,11,8,24,12c9,9,18,20,28,25c10,2,86,8,102,-1c3,-6,14,-13,16,-18c4,-8,11,-14,16,-22c5,-7,9,-15,12,-24c5,-5,6,-13,14,-18c-4,11,-8,22,-13,33c0,8,-1,17,-4,24c-10,10,-18,19,-28,26c5,0,12,-1,18,-3c15,-3,42,-9,49,-12c3,-6,5,-12,7,-18c6,-5,13,-10,18,-16c9,-7,17,-15,24,-24c6,-7,12,-15,17,-23c5,-11,10,-24,14,-37c0,17,-2,34,-5,50c-9,11,-18,21,-27,30c-4,7,-8,12,-13,18c-3,4,-6,8,-9,12c10,-4,20,-9,30,-15c83,-55,142,-154,146,-253c3,-81,5,-146,-71,-206 "/></g>'));                            
        }
        
        if (rands[12] % 337 < 60 && lp < 4) dummy = string(abi.encodePacked(aer, dummy));
        
        dummy = string(abi.encodePacked(dummy, '<linearGradient id="lsstyle',t(lp),'" x1="0%" y1="0%" x2="0%" y2="100%"><stop offset="',cs.offset_canvas,'" stop-color="',cs.sc,'"/><stop offset="',(lp == 3 ? '60' : '100'),'%" stop-color="',cs.sc2,'"/>',(lp == 3 ? '<stop offset="70%" stop-color="#974638"/><animate attributeName="y2" begin="0s" dur="15s" repeatCount="0" from="100%" to="90%" fill="freeze"></animate>' : ''),'</linearGradient>'));
        
        /* mountains */
        for (uint layer = 1; layer <= ls.layersAmount; layer++) {    
            dummy = string(abi.encodePacked(dummy, '<linearGradient id="gradient',t(layer),'" x1="0%" y1="0%" x2="0%" y2="100%"><stop offset="',(layer == 3 ? "40%" : (layer == 2 ? "60%" : "20%")),'" stop-color="',cs.bc[layer],'"/><stop offset="100%" stop-color="',(layer == 1 ? cs.bottomcolor : cs.bc[5]),'"/></linearGradient>'));
        }
        return dummy;
    }
    
    function bytesToUint(bytes memory b) internal pure returns (uint256) {
        uint256 number;
        for(uint i=0;i<b.length;i++){
            number = number + uint(uint8(b[i])*(2**(8*(b.length-(i+1)))));
        }
        return number;
    }
    
    function t(uint256 value) internal pure returns (string memory) {
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
    
     function getRand(uint tokenId, uint lp) public pure returns(uint[13] memory) {
         string memory tid = t(tokenId);
         string memory lid = t(lp);
         
         return [
                random(abi.encodePacked("FIRST",  tid, lid)),
                random(abi.encodePacked("SECOND", tid, lid)),
                random(abi.encodePacked("THIRD",  tid, lid)),
                random(abi.encodePacked("FOURTH", tid, lid)),
                random(abi.encodePacked("FIFTH",  tid, lid)),
                random(abi.encodePacked("CLOUDS", tid, lid)),
                random(abi.encodePacked("CHANNEL",  tid, lid)),
                random(abi.encodePacked("RGBVALUE", tid, lid)),
                random(abi.encodePacked("TR1X",  tid, lid)),
                random(abi.encodePacked("TR1Y",  tid, lid)),
                random(abi.encodePacked("SUNOFFSET", tid, lid)),
                random(abi.encodePacked("LAYERS", tid, lid)),
                random(abi.encodePacked("AEROSTAT", tid, lid))
        ];
    } 
    
    function random(bytes memory input) public pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(string(input))));
    }
    
        

    function hexToRGB(string memory rgb) public pure returns (uint[3] memory) {
        return [
            Strings.fromHex(Strings.substr(rgb, 1, 3)),
            Strings.fromHex(Strings.substr(rgb, 3, 5)),
            Strings.fromHex(Strings.substr(rgb, 5, 7))
        ];
    }
    
    function rgbTint(string memory rgb, uint k, uint sig)  public pure returns (string memory) {
        return rgbShift(rgb, k*10, k*10, k*10, sig);
    }
    
    function rgbShift(string memory rgb, uint dr, uint dg, uint db, uint sig) public pure returns (string memory) {            
        uint[3] memory rgbarr = hexToRGB(rgb);
        uint[3] memory rgbres;
        
        if (sig == 1) {
            rgbres = [rgbarr[0] + (255 - rgbarr[0]) * dr / 100, rgbarr[1] + (255 - rgbarr[1]) * dg / 100, rgbarr[2] + (255 - rgbarr[2]) * db / 100];
        } else {
            rgbres = [rgbarr[0] - (255 - rgbarr[0]) * dr / 100, rgbarr[1] - (255 - rgbarr[1]) * dg / 100, rgbarr[2] - (255 - rgbarr[2]) * db / 100];
        }
        
        if (rgbres[0] > 255) rgbres[0] = 255; 
        if (rgbres[1] > 255) rgbres[1] = 255;
        if (rgbres[2] > 255) rgbres[2] = 255;        
        return rgbToHex(rgbres);
    }
    
    function rgbToHex(uint[3] memory rgbres) public pure returns (string memory)  {
        return string(abi.encodePacked("#",Strings.toHexString(rgbres[0]),Strings.toHexString(rgbres[1]),Strings.toHexString(rgbres[2])));
    }
      
    function stars(uint n, uint fromx, uint fromy, uint tox, uint toy, uint tokenId)  public pure returns (string memory)  {
        require(toy != fromy, "Error toy and fromy");
        string memory result = "";
        uint x; uint y; uint opacity; uint offsetx; uint offsety; 
        for (uint i = 1; i<=n; i++) {
            
            offsetx = random(abi.encodePacked("XFAEB", t(tokenId * i))) % 201;    
            offsety = random(abi.encodePacked("YF24C", t(tokenId * i))) % 201;    
            
            x = (fromx * 100 + (tox * 100 - fromx * 100) / 200 * offsetx) / 100;
            y = (fromy * 100 + (toy * 100 - fromy * 100) / 200 * offsety) / 100;            
            if (y < fromy && toy >= fromy)  {
                opacity = 0;
            } else if (toy < fromy && y >= fromy) {
                opacity = 0;
            } else {
                opacity = 100 - 100 * (y-fromy) / (toy-fromy);
            }
            result = string(abi.encodePacked(result, '<circle cx="',t(x),'" cy="',t(y),'" r="0.5" fill="#fff" fill-opacity="',t(opacity),'%"></circle>'));
        }
        return result;
    }
}