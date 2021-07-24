// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";

contract CreateNFT is ERC721{
    
    uint256 public tokenCounter;
    // Optional mapping for token URIs


    constructor() public ERC721 ("PUPPYNFT", "PUPPY"){
        tokenCounter=0;
    }
    
     //ST
    // Optional mapping for token URIs
    mapping (uint256 => bytes) private _tokenData;

    function _createNFT (string memory tokenURI, string memory data) public virtual {
        uint256 newItemId = tokenCounter;
        bytes memory dataBytes = toBytes(stringToBytes32(data));
        _safeMint(msg.sender, newItemId, dataBytes);
        _setTokenURI(newItemId, tokenURI);
        _tokenData[newItemId] = dataBytes;
        tokenCounter = tokenCounter + 1;
    }
    

    function _getTokenData(uint256 tokenId) public view virtual returns (string memory) {
            require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
            return bytes32ToString(bytesToBytes32(_tokenData[tokenId],0));
    }
    
    function toBytes(bytes32 _data) internal pure returns (bytes memory) {
    return abi.encodePacked(_data);
    }
    
    function bytesToBytes32(bytes memory b, uint offset) private pure returns (bytes32) {
      bytes32 out;
    
      for (uint i = 0; i < 32; i++) {
        out |= bytes32(b[offset + i] & 0xFF) >> (i * 8);
      }
      return out;
    }
    
    function stringToBytes32(string memory source) public pure returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }
    
        assembly {
            result := mload(add(source, 32))
        }
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
   //ST
        
}