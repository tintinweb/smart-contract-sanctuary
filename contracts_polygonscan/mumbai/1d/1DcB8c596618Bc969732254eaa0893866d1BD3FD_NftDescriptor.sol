/*===============================
                        _     _
                       (_)   | |
   ___  _ __ ___  _ __  _  __| |
  / _ \| '_ ` _ \| '_ \| |/ _` |
 | (_) | | | | | | | | | | (_| |
 \___/|_| |_| |_|_| |_|_|\__,_|
          NftDescriptor
===============================*/

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.10 <0.9.0;

import '@openzeppelin/contracts/utils/Strings.sol';
import 'base64-sol/base64.sol';

contract NftDescriptor {

    using Strings for uint256;

    struct IdDetails {
        uint256 score;
        uint256 refreshTime;
        uint256 skinIndex;
        bytes32 etching;
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

    function getSkin(uint256 _skinId) public view returns(string memory skin) {
        skin = skins[_skinId];
    }

    function isValidSkinId(uint256 _skinId) external view returns(bool) {
        return _skinId < skinCounter ;
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

    function constructTokenURI(uint256 _tokenId, address _address, IdDetails calldata _deets) external view returns (string memory) {

        uint256 _score = _deets.score;
        uint256 _refreshTime = _deets.refreshTime;
        uint256 skinIndex = _deets.skinIndex;
        string memory _etching = bytes32ToString(_deets.etching);


        bytes memory svg = abi.encodePacked(
            "<svg id='omnid' xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink' viewBox='0 0 250 400'><defs><linearGradient id='chipGradient' x1='125.05' y1='28.81' x2='124.95' y2='336.78' gradientUnits='userSpaceOnUse'><stop offset='0.19' stop-opacity='0.4'/><stop offset='1' stop-color='gray' stop-opacity='0'/></linearGradient><linearGradient id='tintGradeint' x1='194.93' y1='370.57' x2='221' y2='334.44' gradientTransform='matrix(1, 0, 0, -1, 4.69, 403.41)' gradientUnits='userSpaceOnUse'><stop offset='0.16' stop-color='#fff'/><stop offset='0.93' stop-color='gray'/></linearGradient><clipPath id='frame'><path d='M10.47,0H239.53A10.47,10.47,0,0,1,250,10.47V340a0,0,0,0,1,0,0H0a0,0,0,0,1,0,0V10.47A10.47,10.47,0,0,1,10.47,0Z'/></clipPath></defs><g clip-path='url(#frame)'>",
            getSkin(skinIndex),
            "</g><path id='tint' d='M10.47,0H239.53A10.47,10.47,0,0,1,250,10.47V340a0,0,0,0,1,0,0H0a0,0,0,0,1,0,0V10.47A10.47,10.47,0,0,1,10.47,0Z' style='fill:url(#chipGradient)'/><path id='base' d='M0,340H250a0,0,0,0,1,0,0v48a12,12,0,0,1-12,12H12A12,12,0,0,1,0,388V340a0,0,0,0,1,0,0Z' style='fill:#f9f9f9'/><g id='details'><text transform='translate(18.59 378.06) scale(1.02 1)' style='isolation:isolate;font-size:9.739181518554688px;fill:#b3b3b3;font-family:Consolas'>",
            constructDate(_refreshTime, _tokenId),
            "</text><text transform='translate(18.5 366.7) scale(1.02 1)' style='isolation:isolate;font-size:13.634854316711426px;fill:#b3b3b3;font-family:ArialMT, Arial'>",
            _etching,
            "</text></g><g id='logo'><path d='M211.1,363.68a9,9,0,0,0,12.7,12.72l-6.29-6.3,6.29-6.29a8.72,8.72,0,0,0-12.33-.49C211.34,363.43,211.22,363.56,211.1,363.68Z' transform='translate(0 0)' style='fill:#ccc'/><ellipse cx='227.78' cy='369.98' rx='3.72' ry='3.73' style='fill:#ccc'/></g><text id='score' transform='translate(31.74 62.7) scale(0.88 1)' style='opacity:0.6499999761581421;isolation:isolate;font-size:39.33000183105469px;fill:#fff;font-family:Verdana;letter-spacing:-0.02700198407225477em'>",
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

    // Utility Functions
    function prettyAddress(address x) internal pure returns (string memory) {
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

    function substring(string memory str, uint startIndex, uint endIndex) internal pure returns (string memory) {
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