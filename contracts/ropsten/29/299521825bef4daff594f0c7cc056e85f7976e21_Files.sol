// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity ^0.6.2;

import "./verifyIPFS.sol";
import "./Utils.sol";

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

       /*  Calculate Block Date */
        // (uint year, uint month, uint day) = Utils.timestampToDate(block.timestamp);
        // bytes8  _block_date = Utils.dataConvert8( Utils.concat(Utils.convertVaalue(day), ".",  Utils.convertVaalue(month), ".", Utils.convertVaalue(year)) );

        
        /* Convert IPFS Hash to bs56 encoding */

        // bytes32 _ipfs_hash = Utils.dataConvert(string(verifyIPFS.toBase58(bytes(_metadata[5]))));

        filesMetadata[size].separator = Utils.dataConvert8(_metadata[0]);
        filesMetadata[size].file_number = Utils.dataConvert(_metadata[1]);
        filesMetadata[size].title = Utils.dataConvert(_metadata[2]);
        filesMetadata[size].album = Utils.dataConvert(_metadata[3]);
        filesMetadata[size].website = Utils.dataConvert(_metadata[4]);
        filesMetadata[size].ipfs_hash = Utils.dataConvert(_metadata[5]);
        filesMetadata[size].comment = Utils.dataConvert(_metadata[6]);
        filesMetadata[size].copyright = Utils.dataConvert(_metadata[7]);
        filesMetadata[size].submission_date = Utils.dataConvert8(_metadata[8]);
        filesMetadata[size].blockchain_date = Utils.dataConvert8(_metadata[9]);
        filesMetadata[size].md_hash = Utils.dataConvert(_metadata[10]);

        size = size + 1;

        return size;

    }

    function decodeIPFS(string memory _data) public pure returns (string memory){
        return string(verifyIPFS.toBase58(bytes(_data)));
    }


    function getDate(uint256 _index) public view returns (string memory){
        return Utils.dataOutput8(filesMetadata[_index].blockchain_date);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.2;

library verifyIPFS {

  bytes constant ALPHABET = '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz';

  
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

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.2;

library Utils {

    function dataCheck(string memory str, uint length) private pure returns (bool value){
        if (bytes(str).length <= length) {
            value = true ;
        } else  {
            value = false;
        }
    }

    function dataConvert(string memory str) internal pure returns (bytes32 value){
        // require(dataCheck(str, 32));
        assembly {
            value := mload(add(str, 32))
        }     
    }

    function dataConvert8(string memory str) internal pure returns (bytes8 value){
        // require(dataCheck(str, 8));
        assembly {
            value := mload(add(str, 8))
        }     
    }

    

    function dataOutput(bytes32 c) internal pure returns (string memory value){
        value = string(abi.encodePacked(c));
    }

    function dataOutput8(bytes8 c) internal pure returns (string memory value){
        value = string(abi.encodePacked(c));
    }


    function timestampToDate(uint timestamp) internal pure returns (uint year, uint month, uint day) {
        (year, month, day) = daysToDate(timestamp / (24 * 60 * 60));
    }


    function convertVaalue(uint _value) internal pure returns (string memory value) {
        if( _value <10) {
            value = concat("0", uint2str(_value));
        } else {
            value = uint2str(_value);
        }
    }


    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
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

    function concat(string memory a, string memory b, string memory c, string memory d, string memory e) internal pure returns (string memory) {
		return string(abi.encodePacked(a, b, c, d, e));
	}

    function concat(string memory a, string memory b) internal pure returns (string memory) {
		return string(abi.encodePacked(a, b));
	}

    function daysToDate(uint _days) internal pure returns (uint year, uint month, uint day) {
        int __days = int(_days);

        int L = __days + 68569 + 2440588;
        int N = 4 * L / 146097;
        L = L - (146097 * N + 3) / 4;
        int _year = 4000 * (L + 1) / 1461001;
        L = L - 1461 * _year / 4 + 31;
        int _month = 80 * L / 2447;
        int _day = L - 2447 * _month / 80;
        L = _month / 11;
        _month = _month + 2 - 12 * L;
        _year = 100 * (N - 49) + _year + L;
        _year = _year % 100;

        year = uint(_year);
        month = uint(_month);
        day = uint(_day);
    }

}

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "evmVersion": "byzantium",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}