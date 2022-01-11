// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import '@openzeppelin/contracts/utils/Strings.sol';

library Digits {
 
    uint16 constant private _digitheight = 3435; // needs div /10 // 4er-2061 * 0.6 3er evtl *.8

    // needs to be prefixed to be like: "<path transform='translate(%x%, %y%) scale(%x%, %y%)' ";
    function getDigitPath(uint256 tokenId) private pure returns (string memory) {
        require(tokenId >= 0 && tokenId <= 9, "Token Id invalid");
        
        if (tokenId == 0)
            return "d=' M 143.151 343.5 C 230.072 343.5 286.302 276.215 286.302 171.752 C 286.302 67.004 230.357 0 143.151 0 C 55.939 0 0 67.004 0 171.752 C 0 276.215 56.225 343.5 143.151 343.5 Z  M 143.151 265.588 C 108.697 265.588 89.651 232 89.651 171.752 C 89.651 111.5 108.697 77.912 143.151 77.912 C 177.319 77.912 196.646 111.785 196.646 172.033 C 196.646 232.285 177.605 265.588 143.151 265.588 Z ' fill='url(#digit)' />";
    
        if (tokenId == 1)
            return "d=' M 0 0 L 0 77.843 L 50.921 77.843 L 50.921 343.5 L 143.459 343.5 L 143.459 0 L 0 0 Z  M 0 343.5 L 0 265.657 L 50.921 265.657 L 50.921 0 L 143.459 0 L 143.459 343.5 L 0 343.5 Z  M 194.38 343.5 L 194.38 265.657 L 143.459 265.657 L 143.459 0 L 50.921 0 L 50.921 343.5 L 194.38 343.5 Z ' fill='url(#digit)' />";
            
        if (tokenId == 2)
            return "d=' M 156.002 264.058 C 227.642 181.076 243.236 148.719 243.236 106.57 C 243.236 43.685 194.177 0 123.127 0 C 49.79 0 5.4 44.768 5.4 112.494 L 5.4 118.689 L 93.943 118.689 L 93.943 112.217 C 93.943 92.054 105.407 79.371 124.209 79.371 C 141.365 79.371 153.333 91.55 153.333 109.713 C 153.333 138.469 134.772 164.157 0 323.111 L 0 343.5 L 249.124 343.5 L 249.124 264.058 L 156.002 264.058 Z ' fill='url(#digit)' />";
            
        if (tokenId == 3)
            return "d=' M 171.407 123.294 L 238.794 15.423 L 238.794 0 L 8.426 0 L 8.426 76.525 L 121.108 76.525 L 66.438 166.404 L 66.438 185.113 L 120.215 185.113 C 146.341 185.113 163.016 200.335 163.016 224.875 C 163.016 249.411 146.927 266.303 123.976 266.303 C 101.899 266.303 87.183 250.577 86.173 226.91 L 0 226.91 C 2.019 296.408 51.616 343.5 123.764 343.5 C 197.427 343.5 250.34 294.605 250.34 226.329 C 250.34 174.335 219.544 135.37 171.412 123.294 L 171.407 123.294 Z ' fill='url(#digit)' />";
            
        if (tokenId == 4)
            return "d=' M 284.201 204.819 L 253.162 204.819 L 253.162 129.166 L 191.27 129.166 L 171.125 204.819 L 116.186 204.819 L 201.265 0 L 110.039 0 L 0 264.986 L 0 281.784 L 164.901 281.784 L 164.901 343.5 L 253.167 343.5 L 253.167 281.784 L 284.206 281.784 L 284.201 204.819 Z ' fill='url(#digit)' />";
            
        if (tokenId == 5)
           return "d=' M 123.333 114.832 L 92.093 114.832 L 96.324 76.524 L 226.119 76.524 L 226.119 0 L 27.075 0 L 8.32 175.014 L 16.887 186.105 L 121.374 186.105 C 145.99 186.105 162.882 202.568 162.882 226.679 C 162.882 249.412 146.788 266.304 124.711 266.304 C 102.13 266.304 86.111 249.998 86.111 227.204 L 0 227.204 C 0 295.328 51.555 343.5 124.711 343.5 C 197.929 343.5 250.205 294.884 250.205 226.684 C 250.205 160.858 198.514 114.842 123.338 114.842 L 123.333 114.832 Z ' fill='url(#digit)' />";
            
        if (tokenId == 6)
            return "d=' M 152.692 109.295 C 145.089 109.295 137.718 109.82 130.479 110.926 C 152.626 73.91 174.971 37.046 197.073 0 L 100.112 0 L 38.399 104.029 C 10.279 151.122 0 185.189 0 219.61 C 0 292.874 54.433 343.5 133.664 343.5 C 212.451 343.5 266.743 292.798 266.743 219.181 C 266.743 154.287 219.882 109.295 152.692 109.295 L 152.692 109.295 Z  M 133.371 266.379 C 106.17 266.379 86.466 247.255 86.466 219.181 C 86.466 190.818 106.17 171.482 133.371 171.482 C 160.86 171.482 180.277 190.818 180.277 219.181 C 180.277 247.255 160.86 266.379 133.371 266.379 Z ' fill='url(#digit)' />";
            
        if (tokenId == 7)
            return "d=' M 0 0 L 0 80.487 L 141.739 80.487 L 36.736 343.5 L 133.629 343.5 L 263.798 13.399 L 263.798 0 L 0 0 Z ' fill='url(#digit)' />";
            
        if (tokenId == 8)
            return "d=' M 215.493 162.467 C 238.458 144.232 250.107 121.726 250.107 95.201 C 250.107 38.495 201.849 0 129.696 0 C 57.538 0 8.999 38.781 8.999 95.206 C 8.999 121.431 20.6 143.858 43.47 162.413 C 14.098 181.052 0 206.218 0 239.137 C 0 301.409 52.199 343.5 129.415 343.5 C 206.632 343.5 259.116 301.123 259.116 239.132 C 259.116 206.435 244.782 181.289 215.498 162.462 L 215.493 162.467 Z  M 129.701 65.119 C 151.882 65.119 166.96 78.926 166.96 97.866 C 166.96 116.81 151.882 130.617 129.701 130.617 C 107.52 130.617 92.162 116.81 92.162 97.866 C 92.162 78.926 107.52 65.119 129.701 65.119 Z  M 129.701 275.347 C 103.22 275.347 85.679 259.363 85.679 236.403 C 85.679 213.444 103.22 197.455 129.701 197.455 C 156.182 197.455 173.437 213.444 173.437 236.403 C 173.437 259.363 156.182 275.347 129.701 275.347 Z ' fill='url(#digit)' />";
            
        if (tokenId == 9)
            return "d=' M 132.772 0 C 54.167 0 0 50.585 0 124.033 C 0 188.777 46.752 233.666 113.788 233.666 C 121.369 233.666 128.722 233.142 135.94 232.039 C 113.808 269.035 91.268 306.63 69.217 343.5 L 165.955 343.5 L 227.818 238.919 C 255.657 191.935 266.128 157.946 266.128 123.605 C 266.128 50.51 211.821 0 132.772 0 L 132.772 0 Z  M 133.064 172.201 C 104.188 172.201 83.945 152.617 83.945 124.033 C 83.945 95.731 104.188 76.364 133.064 76.364 C 161.654 76.364 182.184 95.731 182.184 124.033 C 182.184 152.617 161.654 172.201 133.064 172.201 Z ' fill='url(#digit)' />";

        return "";
    }

    // needs div /10
    function getDigitWidth(uint256 tokenId) public pure returns (uint16) {
        require(tokenId >= 0 && tokenId <= 9, "Token Id invalid");

        if (tokenId == 0)
            return 2863;
    
        if (tokenId == 1)
            return 1944;
            
        if (tokenId == 2)
            return 2491;
            
        if (tokenId == 3)
            return 2503;
            
        if (tokenId == 4)
            return 2842;
            
        if (tokenId == 5)
            return 2502;
            
        if (tokenId == 6)
            return 2667;
            
        if (tokenId == 7)
            return 2638;
            
        if (tokenId == 8)
            return 2591;
            
        if (tokenId == 9)
            return 2661;
            
        return 0;
    }

    function getScaleFactor(uint256 numberCharCount) private pure returns (uint16) {
        
        if (numberCharCount == 1)
            return 9;

        if (numberCharCount == 2)
            return 7;
        
        return 6;
    }

    function getDigitBounds(uint16 number, uint256 numberDigitCount, uint16 scaleFactorTimesTen, uint16 currentIndex) public pure returns (uint16 x, uint16 y) {

        uint16 height = (_digitheight /* is x10 */ * scaleFactorTimesTen) / 100;
        uint16 width = (getDigitWidth(number) /* is x10 */ * scaleFactorTimesTen) / 100;
        uint16 distanceX = 50;
        uint16 distanceY = 40;
        uint16 alignWidth = (3000 /* is x10 */ * scaleFactorTimesTen) / 100;
        uint16 deltaX = (alignWidth - width) / 2;

        if (numberDigitCount == 1) 
        {
            x = (1000 - width) / 2;
            y = (1000 - height) / 2;
        }        
        else if (numberDigitCount == 2) 
        {
            distanceX = 30;
            x = (currentIndex == 0) ? 500 - width - deltaX - distanceX : 501 + deltaX + distanceX;
            y = (1000 - height) / 2;
        }
        else if (numberDigitCount == 3)            
        {
            if (currentIndex == 0)
                x = (1000 - width) / 2;
            else
                x = (currentIndex == 1) ? 500 - width - deltaX - distanceX : 501 + deltaX + distanceX;
            y = (currentIndex == 0) ? 500 - height - distanceY : 501 + distanceY;
            y -= 15; // -15 to the top because with three chars it seems like the text is too far away from the top while mathematically it would be correct 
        }
        else if (numberDigitCount == 4)
        {
            x = (currentIndex == 0 || currentIndex == 2) ? 500 - width - deltaX - distanceX : 501 + deltaX + distanceX;
            y = (currentIndex == 0 || currentIndex == 1) ? 500 - height - distanceY : 501 + distanceY;
        }
    }

    function generateDigits(uint256 tokenId) public pure returns (string memory) {
        require(tokenId >= 0 && tokenId <= 9999, "Token Id invalid");
        
        bytes memory stringBytes = bytes(Strings.toString(tokenId));
        
        string[] memory parts = new string[](stringBytes.length);
        
        for (uint16 i = 0; i < stringBytes.length; i++)
        {
            uint16 number = uint16(uint8(stringBytes[i])) - 48; // charIndex - 48 is the numeric value

            uint16 scaleFactor = getScaleFactor(stringBytes.length);
            (uint16 rectX, uint16 rectY) = getDigitBounds(number, stringBytes.length, scaleFactor, i);

            string memory scaleFactorString = string(abi.encodePacked("0.", Strings.toString(scaleFactor)));
            parts[i] = string(abi.encodePacked("<path transform='translate(", Strings.toString(rectX), ", ", Strings.toString(rectY), ") scale(", scaleFactorString, ", ", scaleFactorString, ")' ", getDigitPath(number)));
        }

        if (stringBytes.length == 1) 
            return parts[0];        
        if (stringBytes.length == 2) 
            return string(abi.encodePacked(parts[0], parts[1]));
        else if (stringBytes.length == 3)
            return string(abi.encodePacked(parts[0], parts[1], parts[2]));
        else
            return string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3]));
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