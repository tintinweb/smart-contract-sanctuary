pragma solidity ^0.8.0;
import "./main.sol";
import "./erc721.sol";

contract TheInfinityCollections is EternalHouseFactory, ERC721{



  mapping (uint256 => address) slotApprovals;

  

  function balanceOf(address _owner) external view  override(ERC721) returns (uint256) {
    return ownerSlotCount[_owner];
  }

  function ownerOf(uint256 _tokenId) external view override(ERC721) returns (address) {
      return slotToOwner[_tokenId];
  }

  function _transfer(address _from, address _to, uint256 _tokenId) private {
    ownerSlotCount[_to]++;
    ownerSlotCount[_from]--;

    emit Transfer(_from, _to, _tokenId);
  }

  // transfer NFT
  /// @dev -- require that slot isn't frozen
  function transferFrom(address _from, address _to, uint256 _tokenId) override(ERC721) external payable  {
    require (slotToOwner[_tokenId] == msg.sender || slotApprovals[_tokenId] == msg.sender);
    require(_isReady() == true, "Hibernation Period In Effect");
    slot storage mySlot = slots[_tokenId];
    slotToOwner[_tokenId] = _to;
    _restoreSlotChanged(mySlot); // restore some details of slot
    _transfer(_from, _to, _tokenId);
  }

 

  function approve(address _approved, uint256 _tokenId) external payable  override(ERC721) onlyOwnerOf(_tokenId) {
    slotApprovals[_tokenId] = _approved;
    emit Approval(msg.sender, _approved, _tokenId);
  }
}