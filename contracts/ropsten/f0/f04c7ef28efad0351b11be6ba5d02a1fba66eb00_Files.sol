// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity ^0.6.2;

import "./verifyIPFS.sol";

contract Files {

    struct Metadata {
		bytes8 separator;
        bytes32 file_number;
		bytes32 title;
		bytes32 album;
		bytes32 website;
		bytes32 ipfs_hash;
		bytes32 comment;
		bytes32 copyright;
        bytes8 submission_date;
		bytes8 blockchain_date;
        bytes32 md_hash;
    }


    uint256 size;

    mapping(uint256 => Metadata) filesMetadata;


    constructor() public{
        size = 0;
    }

    function addFile(string[] memory _metadata) public returns (uint256){

        filesMetadata[size].separator = covertData8(_metadata[0]);
        filesMetadata[size].file_number = covertData8(_metadata[1]);
        filesMetadata[size].title = covertData(_metadata[2]);
        filesMetadata[size].album = covertData(_metadata[3]);
        filesMetadata[size].website = covertData(_metadata[4]);
        filesMetadata[size].ipfs_hash = covertData(_metadata[5]);
        filesMetadata[size].comment = covertData(_metadata[6]);
        filesMetadata[size].copyright = covertData(_metadata[7]);
        filesMetadata[size].submission_date = covertData8(_metadata[8]);
        filesMetadata[size].blockchain_date = covertData8(_metadata[9]);
        filesMetadata[size].md_hash = covertData(_metadata[10]);

        size = size + 1;

        return size;

    }

    function covertData(string memory _data) private pure returns (bytes32 _value){
        assembly{
            _value := mload(add(_data, 32))
        }
    }

    function covertData8(string memory _data) private pure returns (bytes8 _value){
        assembly{
            _value := mload(add(_data, 8))
        }
    }

    function decodeIPFS(string memory _data) public pure returns (string memory){
        return string(verifyIPFS.toBase58(bytes(_data)));
    }

    function encodeIPFS(string memory _data) public pure returns (string memory){
        return string(verifyIPFS.generateHash(_data));
    }

    // string => bs58 => hash => bs58 (then compare)
    function compareIPFS(string memory _data) public pure returns (bool){
        bytes memory firstBs = verifyIPFS.toBase58(bytes(_data));
        bytes memory hashGenerated = verifyIPFS.generateHash(string(firstBs));
        bytes memory secondBs = verifyIPFS.toBase58(hashGenerated);
        return verifyIPFS.equal(firstBs, secondBs);
    }


}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.2;

/// @title verifyIPFS
/// @author Martin Lundfall ([email protected])
library verifyIPFS {
  bytes constant prefix1 = hex"0a";
  bytes constant prefix2 = hex"080212";
  bytes constant postfix = hex"18";
  bytes constant sha256MultiHash = hex"1220";
  bytes constant ALPHABET = '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz';

  /// @dev generates the corresponding IPFS hash (in base 58) to the given string
  /// @param contentString The content of the IPFS object
  /// @return The IPFS hash in base 58
  function generateHash(string memory contentString) internal pure returns (bytes memory) {
    bytes memory content = bytes(contentString);
    bytes memory len = lengthEncode(content.length);
    bytes memory len2 = lengthEncode(content.length + 4 + 2*len.length);
    return toBase58(concat(sha256MultiHash, toBytes(sha256(abi.encodePacked(prefix1, len2, prefix2, len, content, postfix, len)))));
  }

  /// @dev Compares an IPFS hash with content
  function verifyHash(string memory contentString, string memory hash) internal pure returns (bool) {
    return equal(generateHash(contentString), bytes(hash));
  }
  
  /// @dev Converts hex string to base 58
  function toBase58(bytes memory source) internal pure returns (bytes memory) {
    if (source.length == 0) return new bytes(0);
    uint8[] memory digits = new uint8[](64); //TODO: figure out exactly how much is needed
    digits[0] = 0;
    uint8 digitlength = 1;
    for (uint256 i = 0; i<source.length; ++i) {
      uint carry = uint8(source[i]);
      for (uint256 j = 0; j<digitlength; ++j) {
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
    //return digits;
    return toAlphabet(reverse(truncate(digits, digitlength)));
  }

  function lengthEncode(uint256 length) internal pure returns (bytes memory) {
    if (length < 128) {
      return to_binary(length);
    }
    else {
      return concat(to_binary(length % 128 + 128), to_binary(length / 128));
    }
  }

  function toBytes(bytes32 input) internal pure returns (bytes memory) {
    bytes memory output = new bytes(32);
    for (uint8 i = 0; i<32; i++) {
      output[i] = input[i];
    }
    return output;
  }
    
  function equal(bytes memory one, bytes memory two) internal pure returns (bool) {
    if (!(one.length == two.length)) {
      return false;
    }
    for (uint256 i = 0; i<one.length; i++) {
      if (!(one[i] == two[i])) {
	return false;
      }
    }
    return true;
  }

  function truncate(uint8[] memory array, uint8 length) internal pure returns (uint8[] memory) {
    uint8[] memory output = new uint8[](length);
    for (uint256 i = 0; i<length; i++) {
        output[i] = array[i];
    }
    return output;
  }
  
  function reverse(uint8[] memory input) internal pure returns (uint8[] memory) {
    uint8[] memory output = new uint8[](input.length);
    for (uint256 i = 0; i<input.length; i++) {
        output[i] = input[input.length-1-i];
    }
    return output;
  }
  
  function toAlphabet(uint8[] memory indices) internal pure returns (bytes memory) {
    bytes memory output = new bytes(indices.length);
    for (uint256 i = 0; i<indices.length; i++) {
        output[i] = ALPHABET[indices[i]];
    }
    return output;
  }

  function concat(bytes memory byteArray, bytes memory byteArray2) internal pure returns (bytes memory) {
    bytes memory returnArray = new bytes(byteArray.length + byteArray2.length);
    uint i = 0;
    for (i; i < byteArray.length; i++) {
      returnArray[i] = byteArray[i];
    }
    for (i; i < (byteArray.length + byteArray2.length); i++) {
      returnArray[i] = byteArray2[i - byteArray.length];
    }
    return returnArray;
  }
    
  function to_binary(uint256 x) internal pure returns (bytes memory) {
    if (x == 0) {
      return new bytes(0);
    }
    else {
      bytes1 s = bytes1(uint8(x % 256));
      bytes memory r = new bytes(1);
      r[0] = s;
      return concat(to_binary(x / 256), r);
    }
  }
}

