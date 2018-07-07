pragma solidity ^0.4.21;
library IPFSLib {
    bytes constant ALPHABET = &quot;123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz&quot;;

    /**
     * @dev Base58 encoding
     * @param _source Bytes data
     * @return Encoded bytes data
     */
    function base58Address(bytes _source) internal pure returns (bytes) {
        uint8[] memory digits = new uint8[](_source.length * 136/100 + 1);
        digits[0] = 0;
        uint8 digitlength = 1;
        for (uint i = 0; i < _source.length; ++i) {
            uint carry = uint8(_source[i]);
            for (uint j = 0; j<digitlength; ++j) {
                carry += uint(digits[j]) * 256;
                digits[j] = uint8(carry % 58);
                carry = carry / 58;
            }
            
            while (carry > 0) {
                digits[digitlength] = uint8(carry % 58);
                digitlength++;
                carry = carry / 58;
            }
        }
        return toAlphabet(reverse(truncate(digits, digitlength)));
    }

    /**
     * @dev Truncate `_array` by `_length`
     * @param _array The source array
     * @param _length The target length of the `_array`
     * @return The truncated array 
     */
    function truncate(uint8[] _array, uint8 _length) internal pure returns (uint8[]) {
        uint8[] memory output = new uint8[](_length);
        for (uint i = 0; i < _length; i++) {
            output[i] = _array[i];
        }
        return output;
    }
    
    /**
     * @dev Reverse `_input` array 
     * @param _input The source array 
     * @return The reversed array 
     */
    function reverse(uint8[] _input) internal pure returns (uint8[]) {
        uint8[] memory output = new uint8[](_input.length);
        for (uint i = 0; i < _input.length; i++) {
            output[i] = _input[_input.length - 1 - i];
        }
        return output;
    }

    /**
     * @dev Convert the indices to alphabet
     * @param _indices The indices of alphabet
     * @return The alphabets
     */
    function toAlphabet(uint8[] _indices) internal pure returns (bytes) {
        bytes memory output = new bytes(_indices.length);
        for (uint i = 0; i < _indices.length; i++) {
            output[i] = ALPHABET[_indices[i]];
        }
        return output;
    }

    /**
     * @dev Convert bytes32 to bytes
     * @param _input The source bytes32
     * @return The bytes
     */
    function toBytes(bytes32 _input) internal pure returns (bytes) {
        bytes memory output = new bytes(32);
        for (uint8 i = 0; i < 32; i++) {
            output[i] = _input[i];
        }
        return output;
    }

    /**
     * @dev Concat two bytes to one
     * @param _byteArray The first bytes
     * @param _byteArray2 The second bytes
     * @return The concated bytes
     */
    function concat(bytes _byteArray, bytes _byteArray2) internal pure returns (bytes) {
        bytes memory returnArray = new bytes(_byteArray.length + _byteArray2.length);
        for (uint16 i = 0; i < _byteArray.length; i++) {
            returnArray[i] = _byteArray[i];
        }
        for (i; i < (_byteArray.length + _byteArray2.length); i++) {
            returnArray[i] = _byteArray2[i - _byteArray.length];
        }
        return returnArray;
    }
}

contract IPFSAddress {
    using IPFSLib for bytes;
    using IPFSLib for bytes32;
    mapping(address => bytes32) public bytesIpfs;
    mapping (address=>string) public stringIpfs;
    
    function saveBytes(bytes32 ipfs) public {
        bytesIpfs[msg.sender] = ipfs;
    }
    
    function saveString(string ipfs) public {
        stringIpfs[msg.sender] = ipfs;
    }
    
    function ipfsAddress() external view returns (string) { 
        bytes memory prefix = new bytes(2);
        prefix[0] = 0x12;
        prefix[1] = 0x20;
        bytes memory value = prefix.concat(bytesIpfs[msg.sender].toBytes());
        bytes memory ipfsBytes = value.base58Address();
        return string(ipfsBytes);
    }
}