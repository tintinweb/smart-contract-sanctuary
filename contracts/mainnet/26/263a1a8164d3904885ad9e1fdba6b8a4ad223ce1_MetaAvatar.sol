/**
 *Submitted for verification at Etherscan.io on 2021-09-12
*/

//  SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MetaAvatar{

  mapping(address=>string) public metadatas;

    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    event URIChange(address indexed _owner, string newUri);

    function balanceOf(address _owner) external pure returns (uint256){
      return 1;
    }

    function ownerOf(uint256 _tokenId) public pure returns (address){
      return address(uint160(_tokenId));
    }

    function idOf(address _address) public pure returns (uint256){
    return uint256(uint160(_address));
    }

    function supportsInterface(bytes4 interfaceID) external pure returns (bool){
      return interfaceID == 0x80ac58cd || interfaceID == 0x5b5e139f;
    }
    function name() external pure returns (string memory){
      return "MetaAvatar";
    }

    function symbol() external pure returns (string memory){
      return "AVATAR";
    }

    function tokenURIAddress(address _address) public view returns (string memory){
      require(bytes(metadatas[_address]).length != 0, "Avatar URI not set for address");
      return metadatas[_address];
    }
    function tokenURI(uint256 _tokenId) external view returns (string memory){
      return tokenURIAddress(ownerOf(_tokenId));
    }

    function setTokenURI(string calldata _tokenUri) external {
      if(bytes(metadatas[msg.sender]).length == 0){
        emit Transfer(address(0), msg.sender, idOf(msg.sender));
      }
      metadatas[msg.sender] = _tokenUri;
      emit URIChange(msg.sender, _tokenUri);
    }
}