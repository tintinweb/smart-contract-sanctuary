// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./ERC721.sol";

contract CHICKNEW1 is ERC721 {
  uint public nextTokenId;
  address public admin;

  constructor() ERC721('ChickenRunNew1', 'CRN1') {
    admin = msg.sender;
  }

  function mint(address to) external {
    require(msg.sender == admin, 'only admin');
    _safeMint(to, nextTokenId);
    nextTokenId++;
  }

  function getAllTokensForUser(address user) public view returns (uint256[] memory ) {
    uint256 tokenCount = balanceOf(user);
    if(tokenCount == 0){
      return new uint256[](0);
    }
    else{
      uint[] memory result = new uint256[](tokenCount);
      uint256 totalPets = nextTokenId;
      uint256 resultIndex = 0;
      uint256 i;
      for(i = 0;i<totalPets;i++){
        if(ownerOf(i)== user){
          result[resultIndex] = i;
          resultIndex++;
        }
      }
    }
  }

  function _baseURI() internal view override returns (string memory) {
    return 'https://fathomless-atoll-87534.herokuapp.com/';
  } 

}