// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library BlitmapAnalysis {
    struct Colors {
        uint[4] r;
        uint[4] g;
        uint[4] b;
    }
    
    function byteToUint(bytes1 b) internal pure returns (uint) {
        return uint(uint8(b));
    }
    
    function tokenRGBColorsOf(bytes memory data) public pure returns (Colors memory) {
        Colors memory rgb;
        
        rgb.r[0] = byteToUint(data[0]);
        rgb.g[0] = byteToUint(data[1]);
        rgb.b[0] = byteToUint(data[2]);
        
        rgb.r[1] = byteToUint(data[3]);
        rgb.g[1] = byteToUint(data[4]);
        rgb.b[1] = byteToUint(data[5]);
        
        rgb.r[2] = byteToUint(data[6]);
        rgb.g[2] = byteToUint(data[7]);
        rgb.b[2] = byteToUint(data[8]);
        
        rgb.r[3] = byteToUint(data[9]);
        rgb.g[3] = byteToUint(data[10]);
        rgb.b[3] = byteToUint(data[11]);
        
        return rgb;
    }
    
    function tokenSlabsOf(bytes memory data) public pure returns (string[4] memory) {
        Colors memory rgb = tokenRGBColorsOf(data);
        
        string[4] memory chars = ["&#9698;", "&#9699;", "&#9700;", "&#9701;"];
        string[4] memory slabs;
        
        slabs[0] = chars[(rgb.r[0] + rgb.g[0] + rgb.b[0]) % 4];
        slabs[1] = chars[(rgb.r[1] + rgb.g[1] + rgb.b[1]) % 4];
        slabs[2] = chars[(rgb.r[2] + rgb.g[2] + rgb.b[2]) % 4];
        slabs[3] = chars[(rgb.r[3] + rgb.g[3] + rgb.b[3]) % 4];
        
        return slabs;
    }
    
    function tokenAffinityOf(bytes memory data) public pure returns (string[3] memory) {
        Colors memory rgb = tokenRGBColorsOf(data);
        
        uint r = rgb.r[0] + rgb.r[1] + rgb.r[2];
        uint g = rgb.g[0] + rgb.g[1] + rgb.g[2];
        uint b = rgb.b[0] + rgb.b[1] + rgb.b[2];
        
        string[3] memory essences;
        uint8 offset;
        
        if (r >= g && r >= b) {
            essences[offset] = "Fire";
            ++offset;
            
            if (g > 256) {
                essences[offset] = "Earth";
                ++offset;
            }
            
            if (b > 256) {
                essences[offset] = "Water";
                ++offset;
            }
        } else if (g >= r && g >= b) {
            essences[offset] = "Earth";
            ++offset;
            
            if (r > 256) {
                essences[offset] = "Fire";
                ++offset;
            }
            
            if (b > 256) {
                essences[offset] = "Water";
                ++offset;
            }
        } else if (b >= r && b >= g) {
            essences[offset] = "Water";
            ++offset;

            if (r > 256) {
                essences[offset] = "Fire";
                ++offset;
            }
            
            if (g > 256) {
                essences[offset] = "Earth";
                ++offset;
            }
        }
        
        if (offset == 1) {
            essences[0] = string(abi.encodePacked(essences[0], " III"));
        } else if (offset == 2) {
            essences[0] = string(abi.encodePacked(essences[0], " II"));
            essences[1] = string(abi.encodePacked(essences[1], " I"));
        } else if (offset == 3) {
            essences[0] = string(abi.encodePacked(essences[0], " I"));
            essences[1] = string(abi.encodePacked(essences[1], " I"));
            essences[2] = string(abi.encodePacked(essences[2], " I"));
        }
        
        return essences;
    }
}