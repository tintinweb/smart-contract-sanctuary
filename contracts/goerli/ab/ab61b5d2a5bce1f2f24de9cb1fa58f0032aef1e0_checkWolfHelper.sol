/**
 *Submitted for verification at Etherscan.io on 2021-11-21
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
interface IWoolf {

  // struct to store each token's traits
  struct SheepWolf {
    bool isSheep;
    uint8 fur;
    uint8 head;
    uint8 ears;
    uint8 eyes;
    uint8 nose;
    uint8 mouth;
    uint8 neck;
    uint8 feet;
    uint8 alphaIndex;
  }
    

  function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);
  function getPaidTokens() external view returns (uint256);
  function getTokenTraits(uint256 tokenId) external view returns (SheepWolf memory);
}

contract checkWolfHelper{
    address public wolf = 0x90AAf09C983dfBD9024db8Ac133E012f69D42AD3;
    
    function isWolf(address owner, uint256 index) public view returns (bool) {
        uint256 tokenId = IWoolf(wolf).tokenOfOwnerByIndex(owner,index);
        IWoolf.SheepWolf memory traits = IWoolf(wolf).getTokenTraits(tokenId);
        require(traits.isSheep == false, "not a wolf, it is sheep");
        return true;
    }
}