// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

library Utils {

function parseString(string memory text) public pure returns (uint) {
    bytes memory text_bytes = bytes(text);
    uint length = text_bytes.length;
    for (uint i = 0; i < length; i++) {
        require(uint8(text_bytes[i]) < 127, "Only ASCII characters");
        require(uint8(text_bytes[i]) > 31, "Only printable characters");
        require(uint8(text_bytes[i]) != 34, "Illegal character");
        require(uint8(text_bytes[i]) != 38, "Illegal character");
        require(uint8(text_bytes[i]) != 60, "Illegal character");
        require(uint8(text_bytes[i]) != 92, "Illegal character");
    }
    return length;
}

function address2string(address _address) public pure returns(string memory) {
    return bytes32ToString(bytes32(abi.encodePacked(_address)));
}

function bytes32ToString(bytes32 _bytes32) public pure returns (string memory) {
    uint8 i = 0;
    bytes memory bytesArray = new bytes(40);
    for (i = 0; i < bytesArray.length; i++) {
        uint8 _f = uint8(_bytes32[i/2] >> 4);
        uint8 _l = uint8(_bytes32[i/2] & 0x0f);

        bytesArray[i] = toByte(_f);
        i = i + 1;
        bytesArray[i] = toByte(_l);
    }
    return string(abi.encodePacked("0x", bytesArray));
}

function toByte(uint8 _uint8) public pure returns (bytes1) {
    if(_uint8 < 10) {
        return bytes1(_uint8 + 48);
    } else {
        return bytes1(_uint8 + 87);
    }
}


function uint2str(uint _i) public pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }   
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    string public constant TABLE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

    function base64(bytes memory data) public pure returns (string memory) {
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
            mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr( 6, input), 0x3F)))))
            resultPtr := add(resultPtr, 1)
            mstore(resultPtr, shl(248, mload(add(tablePtr, and(        input,  0x3F)))))
            resultPtr := add(resultPtr, 1)
        }
        
        // padding with '='
        switch mod(mload(data), 3)
        case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
        case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }
        
        return result;
    }
}