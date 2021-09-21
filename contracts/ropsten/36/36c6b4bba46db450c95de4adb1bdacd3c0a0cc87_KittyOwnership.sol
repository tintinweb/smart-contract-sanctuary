pragma solidity ^0.5.0;

import "./KittyFactory.sol";

contract KittyOwnership is KittyFactory{

  string public constant name = "IvanKitties";
  string public constant symbol = "CK";

  event Transfer(address from, address to, uint256 tokenId);
  event Approval(address owner, address approved, uint256 tokenId);

  /*
  *    We use the modulo of each function to set the interfaceId
  */
  bytes4 constant InterfaceSignature_ERC165 =
      bytes4(keccak256('supportsInterface(bytes4)'));

  bytes4 constant InterfaceSignature_ERC721 =
      bytes4(keccak256('name()')) ^
      bytes4(keccak256('symbol()')) ^
      bytes4(keccak256('totalSupply()')) ^
      bytes4(keccak256('balanceOf(address)')) ^
      bytes4(keccak256('ownerOf(uint256)')) ^
      bytes4(keccak256('approve(address,uint256)')) ^
      bytes4(keccak256('transfer(address,uint256)')) ^
      bytes4(keccak256('transferFrom(address,address,uint256)')) ^
      bytes4(keccak256('tokensOfOwner(address)')) ^
      bytes4(keccak256('tokenMetadata(uint256,string)'));

  function supportsInterface(bytes4 _interfaceID) external pure returns (bool)
  {
      return ((_interfaceID == InterfaceSignature_ERC165) || (_interfaceID == InterfaceSignature_ERC721));
  }

  function _owns(address _claimant, uint256 _tokenId) internal view returns (bool) {
      return kittyIndexToOwner[_tokenId] == _claimant;
  }

  function _approvedFor(address _claimant, uint256 _tokenId) internal view returns (bool) {
      return kittyIndexToApproved[_tokenId] == _claimant;
  }

  function _approve(uint256 _tokenId, address _approved) internal {
      kittyIndexToApproved[_tokenId] = _approved;
  }

  function _deleteApproval(uint256 _tokenId) internal {
      require(_owns(msg.sender, _tokenId));
      delete kittyIndexToApproved[_tokenId];
  }


  /*
  *   Function required by the erc 721 interface
  */

  function totalSupply() public view returns (uint) {
      return kitties.length - 1;
  }

  function balanceOf(address _owner) public view returns (uint256 count) {
      return ownershipTokenCount[_owner];
  }

  function ownerOf(uint256 _tokenId)
      external
      view
      returns (address owner)
  {
      owner = kittyIndexToOwner[_tokenId];

      require(owner != address(0));
  }

  function approve(
      address _to,
      uint256 _tokenId
  )
      public
  {
      require(_owns(msg.sender, _tokenId));

      _approve(_tokenId, _to);
      emit Approval(msg.sender, _to, _tokenId);
  }

  function transfer(
      address _to,
      uint256 _tokenId
  )
      public
  {
      require(_to != address(0));
      require(_owns(msg.sender, _tokenId));

      _transfer(msg.sender, _to, _tokenId);
  }

  function transferFrom(
      address _from,
      address _to,
      uint256 _tokenId
  )
      public
  {
      require(_to != address(0));
      require(_approvedFor(msg.sender, _tokenId));
      require(_owns(_from, _tokenId));

      _transfer(_from, _to, _tokenId);
  }

  function tokensOfOwner(address _owner) public view returns(uint256[] memory ownerTokens) {
    uint256 tokenCount = balanceOf(_owner);

    if (tokenCount == 0) {
        return new uint256[](0);
    } else {
        uint256[] memory result = new uint256[](tokenCount);
        uint256 totalCats = totalSupply();
        uint256 resultIndex = 0;

        uint256 catId;

        for (catId = 1; catId <= totalCats; catId++) {
            if (kittyIndexToOwner[catId] == _owner) {
                result[resultIndex] = catId;
                resultIndex++;
            }
        }

        return result;
    }
  }
}