//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./libraries/verifyIPFS.sol";


// contract Test {
//   uint256 private IPFS_HASH_LENGTH = 46;

//   string private _baseURI;
//   string private _tokenURIs;

//   constructor() {}

//   function setBaseURI(string memory baseURI_) public {
//     _baseURI = baseURI_;
//   }

//   function setTokenURIs(string memory tokenURIs_) public {
//     _tokenURIs = tokenURIs_;
//   }

//   function tokenURI(uint256 _id) external view returns (string memory){
//     uint256 startIndex = _id * IPFS_HASH_LENGTH;

//     bytes memory uri = new bytes(IPFS_HASH_LENGTH + 1);
//     for(uint i = 0; i < IPFS_HASH_LENGTH; i++) {
//       uri[i] = bytes(_tokenURIs)[i + startIndex];
//     }

//     return string(abi.encodePacked(_baseURI, string(uri)));
//   }
// }

contract Test {
  uint256 private IPFS_HASH_LENGTH = 46;

  string private _baseURI;
  //string private _tokenURIs;

  string[] private _tokenURIs;

  constructor() {}

  function getHash(string calldata _input) public view returns (bytes memory) {
    return verifyIPFS.generateHash(_input);
  }

  function toBase58(bytes calldata _input) public view returns (bytes memory) {
    return verifyIPFS.toBase58(_input);
  }

  function setBaseURI(string memory baseURI_) public {
    _baseURI = baseURI_;
  }

  function setTokenURIs(uint256[] memory _ids, string[] memory tokenURIs_) public {
    for(uint i = 0; i < _ids.length; i++) {
      _tokenURIs[_ids[i]] = tokenURIs_[i];
    }
  }

  function tokenURI(uint256 _id) external view returns (string memory){
    // uint256 startIndex = _id * IPFS_HASH_LENGTH;

    // bytes memory uri = new bytes(IPFS_HASH_LENGTH + 1);
    // for(uint i = 0; i < IPFS_HASH_LENGTH; i++) {
    //   uri[i] = bytes(_tokenURIs)[i + startIndex];
    // }

    return string(abi.encodePacked(_baseURI, string(_tokenURIs[_id])));
  }
}

pragma solidity ^0.8.0;


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
    return toBase58(concat(sha256MultiHash, toBytes(sha256(abi.encode(prefix1, len2, prefix2, len, content, postfix, len)))));
  }

  /// @dev Compares an IPFS hash with content
  function verifyHash(string memory contentString, string memory hash) internal pure returns (bool) {
    return equal(generateHash(contentString), bytes(hash));
  }
  
  
  /// @dev Converts hex string to base 58
  function toBase58(bytes memory source) internal pure returns (bytes memory) {
    if (source.length == 0) return new bytes(0);
        uint8[] memory digits = new uint8[](40); //TODO: figure out exactly how much is needed
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
    // bytes memory returnArray = new bytes(byteArray.length + byteArray2.length);
    // for (uint16 i = 0; i < byteArray.length; i++) {
    //   returnArray[i] = byteArray[i];
    // }
    // for (i; i < (byteArray.length + byteArray2.length); i++) {
    //   returnArray[i] = byteArray2[i - byteArray.length];
    // }
    // return returnArray;
    return bytes.concat();
  }
    
  function to_binary(uint256 x) internal pure returns (bytes memory) {
    if (x == 0) {
      return new bytes(0);
    }
    else {
      bytes1 s = bytes1(bytes32(x % 256));
      bytes memory r = new bytes(1);
      r[0] = s;
      return concat(to_binary(x / 256), r);
    }
  }
  
}

