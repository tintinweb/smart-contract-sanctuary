//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

// import "./libraries/verifyIPFS.sol";


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

  function store(bytes1 _input) public {
    bytes1 aa = _input;
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

{
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "metadata": {
    "useLiteralContent": true
  },
  "libraries": {}
}