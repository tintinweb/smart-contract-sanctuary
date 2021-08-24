// contracts/NCT.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract OnChainTesting {
    constructor() {}

    mapping(uint256 => bytes32) tokenIdToHash;
    uint256 currentToken = 0;

    function hash(uint256 _tokenId, address _addr)
        public
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(_tokenId, _addr));
    }

    function generateInputhash() public returns (bytes32) {
        uint256 thisTokenId = currentToken;

        tokenIdToHash[thisTokenId] = keccak256(
            abi.encodePacked(thisTokenId, msg.sender)
        );

        currentToken = currentToken + 1;

        return tokenIdToHash[thisTokenId];
    }

    function getHashForToken(uint256 tokenId) public view returns (bytes32) {
        return tokenIdToHash[tokenId];
    }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": false,
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