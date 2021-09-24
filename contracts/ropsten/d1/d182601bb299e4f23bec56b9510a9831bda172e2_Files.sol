// SPDX-License-Identifier: MIT
pragma solidity ^0.6.2;
pragma experimental ABIEncoderV2;


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


}

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "evmVersion": "istanbul",
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