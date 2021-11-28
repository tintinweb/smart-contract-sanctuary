/*===============================
                        _     _
                       (_)   | |
   ___  _ __ ___  _ __  _  __| |
  / _ \| '_ ` _ \| '_ \| |/ _` |
 | (_) | | | | | | | | | | (_| |
 \___/|_| |_| |_|_| |_|_|\__,_|
        NftDescriptorV2
===============================*/

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.10 <0.9.0;

import '@openzeppelin/contracts/utils/Strings.sol';
import 'base64-sol/base64.sol';

contract NftDescriptorV2 {

    using Strings for uint256;

    struct IdDetails {
        uint256 score;
        uint256 refreshTime;
        uint256 skinIndex;
        bytes32 etching;
    }

    struct Color {
        string rgb;
        string num;
    }

    address public admin;
    uint256 public skinCounter = 0;
    string[] public skins;

    event NewSkin(uint256 skinId, string skins);

    constructor(){
        admin = msg.sender;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Omnid:onlyAdmin");
        _;
    }

    function changeAdmin(address _newAdmin) external onlyAdmin {
        admin = _newAdmin;
    }

    function addSkin(string memory _newSkin) external onlyAdmin {
        skins.push(_newSkin);
        uint256 oldSkinId = skinCounter;
        skinCounter+=1;
        emit NewSkin(oldSkinId, _newSkin);
    }

    function getSkin(uint256 _skinId, address _address) public view returns(string memory) {
        string memory skin = skins[_skinId];
        return string(abi.encodePacked(skin, getGenerativeStyles(_address)));
    }

    function isValidSkinId(uint256 _skinId) external view returns(bool) {
        return _skinId < skinCounter ;
    }

    bytes1 constant a = bytes1('a');
    bytes1 constant f = bytes1('f');
    bytes1 constant A = bytes1('A');
    bytes1 constant F = bytes1('F');
    bytes1 constant zero = bytes1('0');
    bytes1 constant nine = bytes1('9');

    function hexCharToByte(uint8 c) pure public returns(uint8) {
        bytes1 b = bytes1(c);

        //convert ascii char to hex value
        if(b >= zero && b <= nine) {
            return c - uint8(zero);
        } else if(b >= a && b <= f) {
            return 10 + (c - uint8(a));
        }
        return 10 + (c - uint8(A));
    }

    function hexStringToUint(string memory hexValue) pure public returns(uint) {
        //convert string to bytes
        bytes memory b = bytes(hexValue);

        //make sure zero-padded
        require(b.length % 2 == 0, "String must have an even number of characters");

        //starting index to parse from
        uint i = 2;
        uint r = 0;
        for(;i<b.length;i++) {
            //convert each ascii char in string to its hex/byte value.
            uint b1 = hexCharToByte(uint8(b[i]));

            //shift over a nibble for each char since hex has 2 chars per byte
            //OR the result to fill in lower 4 bits with hex byte value.
            r = (r << 4) | b1;
        }
        //result is hex-shifted value of all bytes in input string.
        return r;
    }



    function bytesToUint(bytes memory hexValue) pure public returns(uint) {
        // Starting index to parse from, Skip the 0x Prefix
        uint i = 2;
        // result
        uint r = 0;
        for(;i<hexValue.length;i++) {
            //convert each ascii char in string to its hex/byte value.
            uint b1 = hexCharToByte(uint8(hexValue[i]));
            //shift over a nibble for each char since hex has 2 chars per byte
            //OR the result to fill in lower 4 bits with hex byte value.
            r = (r << 4) | b1;
        }
        //result is hex-shifted value of all bytes in input string.
        return r;
    }


    function has0xPrefix(bytes memory b) pure internal returns(bool) {
        if(b.length < 2) {
            return false;
        }
        return b[1] == 'x';
    }

    function stringToUint(string memory s) public pure returns (uint result) {
        bytes memory b = bytes(s);
        uint i;
        if (has0xPrefix(b) == true){
            i=2;
        }
        result = 0;

        for (i = 0; i < b.length; i++) {
            uint c = uint(uint8(b[i]));
            if (c >= 48 && c <= 57) {
                result = result * 10 + (c - 48);
            }
        }
    }

    function strlen(string memory str) pure public returns (uint length) {
        bytes memory vanityBytes = bytes(str);
        length = vanityBytes.length;
    }


    function uintToString(uint256 _i) private pure returns (string memory str) {
        if (_i == 0) return "0";

        uint256 j = _i;
        uint256 length;

        length = lengthOfUint(j);

        bytes memory bstr = new bytes(length);
        uint256 k = length;
        j = _i;

        while (j != 0) {
            bstr[--k] = bytes1(uint8(48 + (j % 10)));
            j /= 10;
        }

        str = string(bstr);

        return str;
    }

    function lengthOfUint(uint256 _num) private pure returns (uint256 length) {
        while (_num != 0) {
            length++;
            _num /= 10;
        }
    }

    function prettyAddress(address x) internal view returns (string memory) {
        string memory add = addressToString(x);
        return string(abi.encodePacked(substring(add, 0, 3),"...",substring(add, 37, 40)));
    }

    function addressToString(address _addr) internal pure returns (string memory) {
        uint256 value = uint256(uint160(_addr));
        bytes16 ALPHABET = '0123456789abcdef';
        bytes memory buffer = new bytes(2 * 20 + 2);
        buffer[0] = '0';
        buffer[1] = 'x';
        for (uint256 i = 2 * 20 + 1; i > 1; --i) {
            buffer[i] = ALPHABET[value & 0xf];
            value >>= 4;
        }
        return string(buffer);
    }

    function addressToBytes(address _addr) public pure returns (bytes memory) {
        uint256 value = uint256(uint160(_addr));
        bytes16 ALPHABET = '0123456789abcdef';
        bytes memory buffer = new bytes(2 * 20 + 2);
        buffer[0] = '0';
        buffer[1] = 'x';
        for (uint256 i = 2 * 20 + 1; i > 1; --i) {
            buffer[i] = ALPHABET[value & 0xf];
            value >>= 4;
        }
        return buffer;
    }

    function substring(string memory str, uint startIndex, uint endIndex) public view returns (string memory) {
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(endIndex-startIndex);
        for(uint i = startIndex; i < endIndex; i++) {
            result[i-startIndex] = strBytes[i];
        }
        return string(result);
    }

    function timestampToDate(uint _days) internal pure returns ( uint day, uint month, uint year) {
        uint SECONDS_PER_DAY = 24 * 60 * 60;
        int OFFSET19700101 = 2440588;
        int __days = int(_days/SECONDS_PER_DAY);

        int L = __days + 68569 + OFFSET19700101;
        int N = 4 * L / 146097;
        L = L - (146097 * N + 3) / 4;
        int _year = 4000 * (L + 1) / 1461001;
        L = L - 1461 * _year / 4 + 31;
        int _month = 80 * L / 2447;
        int _day = L - 2447 * _month / 80;
        L = _month / 11;
        _month = _month + 2 - 12 * L;
        _year = 100 * (N - 49) + _year + L;

        year = uint(_year);
        month = uint(_month);
        day = uint(_day);
    }

    function rgbify(string memory c) public pure returns (string memory) {
        return uintToString(stringToUint(c) % 255);
    }

    function bytes32ToString(bytes32 _bytes32) public pure returns (string memory) {
        uint8 i = 0;
        while(i < 32 && _bytes32[i] != 0) {
            i++;
        }
        bytes memory bytesArray = new bytes(i);
        for (i = 0; i < 32 && _bytes32[i] != 0; i++) {
            bytesArray[i] = _bytes32[i];
        }
        return string(bytesArray);
    }

    function constructDate(uint256 _refreshTime, uint256 _tokenId) internal pure returns(bytes memory) {
        ( uint256 dd, uint256 mm, uint256 yy) = timestampToDate(_refreshTime);
        return abi.encodePacked(
            dd.toString(),"/",
            mm.toString(),"/",
            yy.toString()," #",
            _tokenId.toString()
        );
    }


    function addressToColorIntStrings(address _add) view internal returns(string[5] memory) {

        string memory add = addressToString(_add);
        string[5] memory colors;
        uint index = 0;
        for (uint i = 0; i < 5; i++){

            string memory color = uintToString(hexStringToUint(string(
                abi.encodePacked(
                    "0x",
                    substring(add, index+2, index+3),
                    substring(add, index+3, index+4),
                    substring(add, index+4, index+5),
                    substring(add, index+5, index+6),
                    substring(add, index+6, index+7),
                    substring(add, index+7, index+8),
                    substring(add, index+8, index+9),
                    substring(add, index+9, index+10)
                )
            )));

            index+=8;
            colors[i] = color;
        }
        return colors;
    }

    function addressToColors(address _add) view public returns (Color[5] memory colors){
        string[5] memory colorInts = addressToColorIntStrings(_add);
        for (uint i = 0; i < 5; i++){
            string memory color = colorInts[i];
            uint256 colorLen = strlen(color);

            if (colorLen < 10){ // 3 + 3 + 3 + Excess bit in end
                for (uint256 j=0; j < 10-colorLen; j+=1){
                    color = string(abi.encodePacked(color, "0"));
                }
            }

            colors[i] = Color({
                rgb: string(abi.encodePacked("rgb(", rgbify(substring(color, 0, 3)), ",", rgbify(substring(color, 3, 6)), ",", rgbify(substring(color, 6, 9)), ")")) ,
                num: uintToString(stringToUint(substring(color, 9, 10))%5)
            });
        }
    }

    function getGenerativeStyles(address _userAddress) public view returns(string memory){

        Color[5] memory colors = addressToColors(_userAddress);

        string memory data = "<defs><style>:root {";

        for(uint256 index = 1; index <= 5; index++) {
            data = string(abi.encodePacked(data, "--color",index,":",colors[index-1].rgb,";"));
        }
        for(uint256 index = 1; index <= 5; index++) {
            data = string(abi.encodePacked(data, "--num",index,":",colors[index-1].num,";"));
        }

        data = string(abi.encodePacked(data,"}</style></defs>"));
        return data;
    }

    function constructTokenURI(uint256 _tokenId, address _address, IdDetails calldata _deets) external view returns (string memory) {

        uint256 _score = _deets.score;
        uint256 _refreshTime = _deets.refreshTime;
        uint256 skinIndex = _deets.skinIndex;
        string memory _etching = bytes32ToString(_deets.etching);


        bytes memory svg = abi.encodePacked(
            "<svg id='omnid' xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink' viewBox='0 0 250 400'><defs><linearGradient id='chipGradient' x1='125.05' y1='28.81' x2='124.95' y2='336.78' gradientUnits='userSpaceOnUse'><stop offset='0.19' stop-opacity='0.2'/><stop offset='1' stop-color='gray' stop-opacity='0'/></linearGradient><linearGradient id='tintGradeint' x1='194.93' y1='370.57' x2='221' y2='334.44' gradientTransform='matrix(1, 0, 0, -1, 4.69, 403.41)' gradientUnits='userSpaceOnUse'><stop offset='0.16' stop-color='#fff'/><stop offset='0.93' stop-color='gray'/></linearGradient><clipPath id='frame'><path d='M10.47,0H239.53A10.47,10.47,0,0,1,250,10.47V340a0,0,0,0,1,0,0H0a0,0,0,0,1,0,0V10.47A10.47,10.47,0,0,1,10.47,0Z'/></clipPath></defs><g clip-path='url(#frame)'>",
            getSkin(skinIndex, _address),
            "</g><path id='tint' d='M10.47,0H239.53A10.47,10.47,0,0,1,250,10.47V340a0,0,0,0,1,0,0H0a0,0,0,0,1,0,0V10.47A10.47,10.47,0,0,1,10.47,0Z' style='fill:url(#chipGradient)'/><g id='details'><path id='base' d='M0,340H250a0,0,0,0,1,0,0v48a12,12,0,0,1-12,12H12A12,12,0,0,1,0,388V340a0,0,0,0,1,0,0Z' style='fill:#000'/><text transform='translate(18.59 378.06) scale(1.02 1)' style='isolation:isolate;font-size:9.739181518554688px;fill:#b3b3b3;font-family:Consolas'>",
            constructDate(_refreshTime, _tokenId),
            "</text><text transform='translate(18.5 366.7) scale(1.02 1)' style='isolation:isolate;font-size:13.634854316711426px;fill:#b3b3b3;font-family:ArialMT, Arial'>",
            _etching,
            "</text></g><g id='logo'> <path d='M 218.798 384.637 L 218.236 384.637 C 218.216 384.612 218.192 384.588 218.167 384.567 L 217.465 384.497 C 216.623 384.286 215.921 383.865 215.29 383.374 C 214.518 382.742 213.957 381.971 213.395 381.128 C 212.693 380.006 212.132 378.743 211.711 377.48 C 210.784 374.65 210.333 371.686 210.378 368.709 C 210.358 368.682 210.334 368.658 210.307 368.639 L 210.307 368.287 C 210.333 368.266 210.356 368.243 210.378 368.218 L 210.448 365.551 C 210.535 364.539 210.676 363.531 210.869 362.534 C 211.22 360.92 211.641 359.376 212.273 357.903 C 212.764 356.85 213.325 355.868 214.026 354.956 C 214.588 354.184 215.29 353.552 216.131 353.061 C 216.767 352.663 217.489 352.422 218.236 352.36 C 219.092 352.312 219.943 352.507 220.693 352.92 C 221.382 353.301 222 353.8 222.517 354.394 C 224.411 356.909 225.663 359.847 226.166 362.955 C 226.326 363.79 226.442 364.633 226.517 365.48 L 226.657 367.516 L 226.657 369.059 C 226.652 369.106 226.652 369.153 226.657 369.199 L 226.587 371.235 C 226.506 372.271 226.365 373.302 226.166 374.322 C 225.902 375.638 225.526 376.929 225.043 378.181 C 224.622 379.374 224.06 380.567 223.289 381.69 C 222.657 382.462 222.026 383.233 221.184 383.795 C 220.572 384.201 219.876 384.465 219.149 384.567 L 218.798 384.637 Z M 223.921 368.498 L 223.921 366.884 C 223.844 364.973 223.609 363.072 223.219 361.201 C 222.961 359.883 222.585 358.591 222.096 357.341 C 221.745 356.429 221.324 355.587 220.763 354.886 C 220.412 354.465 220.061 354.043 219.64 353.763 C 219.29 353.552 218.938 353.412 218.447 353.412 C 218.071 353.429 217.706 353.55 217.395 353.763 C 216.974 354.043 216.623 354.465 216.272 354.886 C 215.781 355.587 215.36 356.359 215.009 357.201 C 214.307 358.885 213.886 360.71 213.535 362.604 C 213.392 363.581 213.299 364.565 213.255 365.551 C 213.148 368.031 213.195 370.515 213.395 372.989 C 213.501 374.027 213.665 375.057 213.886 376.076 C 214.167 377.339 214.518 378.602 215.009 379.866 C 215.36 380.707 215.781 381.479 216.342 382.181 C 216.693 382.672 217.044 383.023 217.535 383.304 C 218.097 383.654 218.728 383.725 219.359 383.374 C 219.755 383.184 220.113 382.923 220.412 382.602 C 220.973 381.971 221.324 381.269 221.675 380.567 C 222.236 379.514 222.588 378.321 222.938 377.199 C 223.37 375.448 223.652 373.664 223.78 371.866 C 223.921 370.744 223.921 369.621 223.921 368.498 Z' style='fill:#b3b3b3'/><path d='M 234.656 372.428 L 234.656 372.849 C 234.633 372.846 234.609 372.846 234.586 372.849 L 234.516 373.41 C 234.305 374.042 233.884 374.602 233.393 375.164 C 232.762 375.725 231.989 376.216 231.148 376.638 C 227.201 378.226 222.983 379.037 218.728 379.023 C 218.702 379.044 218.679 379.068 218.658 379.094 L 218.307 379.094 C 218.284 379.092 218.26 379.092 218.236 379.094 L 215.571 378.953 C 214.588 378.907 213.582 378.789 212.553 378.602 C 210.98 378.364 209.43 377.988 207.922 377.48 C 206.869 377.128 205.887 376.708 204.975 376.147 C 204.203 375.656 203.571 375.164 203.08 374.533 C 202.659 373.971 202.449 373.41 202.378 372.849 C 202.309 372.147 202.519 371.445 202.94 370.884 C 203.291 370.323 203.852 369.832 204.414 369.41 C 205.256 368.779 206.308 368.287 207.361 367.937 C 209.969 366.953 212.715 366.385 215.5 366.253 L 217.535 366.182 L 217.886 366.113 L 219.079 366.113 C 219.123 366.14 219.17 366.164 219.219 366.182 L 221.324 366.253 C 222.307 366.323 223.289 366.393 224.341 366.604 C 225.645 366.796 226.935 367.077 228.201 367.446 C 229.393 367.796 230.586 368.218 231.709 368.849 C 232.481 369.27 233.253 369.832 233.814 370.533 C 234.236 371.024 234.516 371.515 234.586 372.147 L 234.656 372.428 Z M 218.517 368.287 L 216.904 368.358 C 214.999 368.421 213.1 368.609 211.22 368.919 C 209.914 369.106 208.625 369.387 207.361 369.761 C 206.519 370.042 205.676 370.392 204.905 370.814 C 204.483 371.094 204.063 371.375 203.782 371.726 C 203.571 372.006 203.431 372.287 203.431 372.638 C 203.431 372.919 203.571 373.199 203.782 373.48 C 204.063 373.831 204.483 374.111 204.905 374.392 C 208.279 375.85 211.897 376.66 215.571 376.778 C 218.049 376.876 220.532 376.852 223.008 376.708 L 226.096 376.287 C 227.38 376.077 228.646 375.773 229.884 375.375 C 230.727 375.094 231.498 374.743 232.27 374.322 C 232.691 374.042 233.043 373.761 233.323 373.41 C 233.674 372.919 233.744 372.428 233.393 371.937 C 233.253 371.585 232.902 371.375 232.622 371.094 C 231.989 370.673 231.288 370.392 230.586 370.112 C 229.492 369.694 228.365 369.365 227.219 369.13 C 225.459 368.775 223.677 368.541 221.886 368.428 L 218.517 368.287 Z' style='fill:#b3b3b3;'/></g><text id='score' transform='translate(31.74 62.7) scale(0.88 1)' style='opacity:0.6499999761581421;isolation:isolate;font-size:39.33000183105469px;fill:#fff;font-family:Verdana;letter-spacing:-0.02700198407225477em'>",
            _score.toString(),
            "</text><path id='chip' d='M201.53,52.8V50.43H196.8v8.74a4.86,4.86,0,0,0,5,4.55h5v-8h-2.37A3.06,3.06,0,0,1,201.53,52.8Zm1.19-11.38V52.61a2,2,0,0,0,2.09,1.82h10.28a2,2,0,0,0,2.09-1.82V41.15a1.7,1.7,0,0,0-1.72-1.64H204.81a2.09,2.09,0,0,0-2.09,1.91Zm-1.19,2.64H196.8v5h4.73ZM208,63.72h4.37V54.43H208ZM218,30.5h-4.36V38h1.72a3,3,0,0,1,3.19,2.91V43h4.37V35C223,32.5,220.73,30.5,218,30.5Zm.64,18.56H223v-5h-4.37Zm-17.11-8.19A3,3,0,0,1,204.44,38h2.37V30.5h-5a4.8,4.8,0,0,0-5,4.55v8h4.73ZM218.64,52.8a3.06,3.06,0,0,1-3.18,2.91h-1.73v8h4.36a4.8,4.8,0,0,0,5-4.55V50.43h-4.37V52.8Zm-6.19-22.3h-4.37v9h4.37Z' transform='translate(0 0)' style='fill:url(#tintGradeint)'/></svg>"
        );

        bytes memory json = abi.encodePacked(
            '{"name":"OMNID #', _tokenId.toString(),
            '","description":"OMIND #', _tokenId.toString(),
            '","attributes":[{"trait_type": "score","value":', _score.toString(), '},{"trait_type": "etching","value":"',_etching, '"}, {"display_type": "date", "trait_type": "Last Updated","value":', _refreshTime.toString(),
            '}],"image":"data:image/svg+xml;base64,', Base64.encode(svg),'"}'
        );

        return string(abi.encodePacked("data:application/json;base64,",Base64.encode(json)));

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides functions for encoding/decoding base64
library Base64 {
    string internal constant TABLE_ENCODE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    bytes  internal constant TABLE_DECODE = hex"0000000000000000000000000000000000000000000000000000000000000000"
                                            hex"00000000000000000000003e0000003f3435363738393a3b3c3d000000000000"
                                            hex"00000102030405060708090a0b0c0d0e0f101112131415161718190000000000"
                                            hex"001a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132330000000000";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';

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
            for {} lt(dataPtr, endPtr) {}
            {
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr( 6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(        input,  0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
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
            for {} lt(dataPtr, endPtr) {}
            {
               // read 4 characters
               dataPtr := add(dataPtr, 4)
               let input := mload(dataPtr)

               // write 3 bytes
               let output := add(
                   add(
                       shl(18, and(mload(add(tablePtr, and(shr(24, input), 0xFF))), 0xFF)),
                       shl(12, and(mload(add(tablePtr, and(shr(16, input), 0xFF))), 0xFF))),
                   add(
                       shl( 6, and(mload(add(tablePtr, and(shr( 8, input), 0xFF))), 0xFF)),
                               and(mload(add(tablePtr, and(        input , 0xFF))), 0xFF)
                    )
                )
                mstore(resultPtr, shl(232, output))
                resultPtr := add(resultPtr, 3)
            }
        }

        return result;
    }
}