/**
 *Submitted for verification at Etherscan.io on 2021-11-22
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
    
  function balanceOf(address owner) external view returns (uint256 balance);
  function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);
  function getPaidTokens() external view returns (uint256);
  function getTokenTraits(uint256 tokenId) external view returns (SheepWolf memory);
}


contract checkWolfHelper{
    address public wolf = 0x90AAf09C983dfBD9024db8Ac133E012f69D42AD3;
    
    error customError(uint256 tokenId, string message);
    function isWolf() public view returns (bool) {
        uint256 size = IWoolf(wolf).balanceOf(msg.sender);
        uint256 tokenId = IWoolf(wolf).tokenOfOwnerByIndex(msg.sender,size-1);
        IWoolf.SheepWolf memory traits = IWoolf(wolf).getTokenTraits(tokenId);
        if (traits.isSheep) {
            revert customError({
                tokenId: tokenId,
                message: "not a wolf"
            });
        }
        return true;
    }
    function isSheep() public view returns (bool) {
        uint256 size = IWoolf(wolf).balanceOf(msg.sender);
        uint256 tokenId = IWoolf(wolf).tokenOfOwnerByIndex(msg.sender,size-1);
        IWoolf.SheepWolf memory traits = IWoolf(wolf).getTokenTraits(tokenId);
        if (!traits.isSheep) {
            revert customError({
                tokenId: tokenId,
                message: "not a sheep"
            });
        }
        return true;
    }
}