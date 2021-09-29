// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Sample {
    mapping (uint256 => string) private _tokenMidContents;
    mapping (uint256 => bytes10) private _tokenMidContentHashes;
    
    constructor()
    {
        _tokenMidContentHashes[0] = 0x9650ce19ad7b524d1ffd;
        _tokenMidContentHashes[1] = 0xb336ae9b38480edf2d0a;
    }

    function getMidContent(uint256 _tokenId) public view returns (bytes memory) {
        return bytes(_tokenMidContents[_tokenId]);
    }

    function sliceBytes32To10(bytes32 input) public pure returns (bytes10 output) {
        assembly {
            output := input
        }
    }

    function claim(uint256 _tokenId, string memory _tokenMidContent) public {
        require(bytes(_tokenMidContent).length == 429, "Token Content Size invalid");
        require(_tokenMidContentHashes[_tokenId] == sliceBytes32To10(keccak256(abi.encodePacked(_tokenMidContent))), "Token Content invalid");
        _tokenMidContents[_tokenId] = _tokenMidContent;
    }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 20
  },
  "evmVersion": "london",
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