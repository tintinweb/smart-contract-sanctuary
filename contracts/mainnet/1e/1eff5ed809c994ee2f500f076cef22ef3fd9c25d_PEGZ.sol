// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

/// @title: PEGZ
/// @notice: https://pegz.fun

////////////////////////////////////////////////
//   _______   ________   ______   ________   //
//  /       \ /        | /      \ /        |  //
//  $$$$$$$  |$$$$$$$$/ /$$$$$$  |$$$$$$$$/   //
//  $$ |__$$ |$$ |__    $$ | _$$/     /$$/    //
//  $$    $$/ $$    |   $$ |/    |   /$$/     //
//  $$$$$$$/  $$$$$/    $$ |$$$$ |  /$$/      //
//  $$ |      $$ |_____ $$ \__$$ | /$$/____   //
//  $$ |      $$       |$$    $$/ /$$      |  //
//  $$/       $$$$$$$$/  $$$$$$/  $$$$$$$$/   //
//                                            //
////////////////////////////////////////////////

/*
* PEGZ is a series of 100 unique collectables, each one of a kind
* and drawn digitally by Matt Furie. Every Peg character is a member
* of a family, one of 10 types, including "Pepe" who is present here
* in the rarest of forms.
*
* Matt's vast world of characters come to life in the form of
* collectable/tradable files, each with a 2D avatar file, a 3D coin
* file, and an animated file.
*
* The PEGZ project came about as Matt focused on digitally created
* work, and provides a unique opportunity for collectors to get into
* his vast universe of bizarre mutants and characters, the same
* universe that single-handledly spawned the most iconic internet
* creature of all time, Pepe the Frog.
*/

import './Ownable-ERC721.sol';

contract OwnableDelegateProxy {}

contract ProxyRegistry {
  mapping(address => OwnableDelegateProxy) public proxies;
}

contract PEGZ is ProxyRegistry, ERC721, Ownable {
  address public proxyRegistryAddress;

  /**
    * @notice Each drop is stores an IPFS hash path that is a folder
    * containing all token metadata for that drop
  */
  mapping(uint256 => string) public dropPaths;

  /**
    * @param _proxyRegistryAddress The address of the OpenSea/Wyvern
    * proxy registry
  */
  constructor(address _proxyRegistryAddress) ERC721("PEGZ", "PEGZ") Ownable() public {
    proxyRegistryAddress = _proxyRegistryAddress;

    _setBaseURI("https://ipfs.io/ipfs/");
  }

  /**
    * @dev Override based on OpenSea proxyRegistry lookup
  */
  function isApprovedForAll(address owner, address operator) public view override returns (bool) {
    ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
    if (address(proxyRegistry.proxies(owner)) == operator) {
        return true;
    }

    return super.isApprovedForAll(owner, operator);
  }

  /**
    * @dev OpenSea specific contract metadata
  */
  function contractURI() external view returns (string memory) {
    return string(abi.encodePacked(baseURI(), "QmRG4HuaafM4eabDh2Wr3WCj8vstP6uGsiHN7JCCecxA2p"));
  }

  /**
    * @dev Mints a drop of regular PEGZ or a single Dazzler if it
    * hasn't been minted.
    * There can only be 10 PEGZ drops and 3 Dazzlers
    * Each PEGZ drop is for 10 tokens starting at tokenId 1.
    * Example: dropId 1 = tokens 1 - 10; dropId 2 = tokens 11 - 20
    * Dazzlers have tokenId 101-103
    *
    * Requirements:
    * - `dropId` must be between 1-10 inclusive or 101-103 inclusive
    *
    * @param dropId of the drop to mint
    * @param dropPath must not end with trailing slash (`/`)
  */
  function mint(uint256 dropId, string memory dropPath) onlyOwner public {
    /// @notice Mint regular PEGZ
    if (dropId < 101){
      require(dropId>=1 && dropId<=10, 'PEGZ: Only 1-10 drops allowed');

      uint256 maxId = dropId*10;

      for(uint256 id=maxId-9; id<=maxId; id++){
        _mint(msg.sender, id);
      }
    /// @notice Mint Dazzlers
    } else {
      require(dropId>=101 && dropId<=103, 'PEGZ: Only 3 Dazzlers allowed');

      _mint(msg.sender, dropId);
    }

    dropPaths[dropId] = dropPath;
  }

  /**
    * @dev public test of whether a PEGZ drop or Dazzler can be
    * burned.
    *
    * Requirements:
    * - `dropPaths[dropId]` must be set, i.e. there is a previous mint for this dropId
    * - For dropId 1-10, every tokenId in the drop must be owned by `owner`, i.e. tokens have not been transferred
    * - For dropId 101-103, the token with that id must be owned by `owner`
    *
    * @param dropId of the drop to check
  */
  function canBurn(uint256 dropId) public view returns (bool no){
    if (bytes(dropPaths[dropId]).length == 0) return no;

    /// @notice Check regular PEGZ
    if (dropId < 101){
      uint256 maxId = dropId*10;

      for(uint256 id=maxId-9; id<=maxId; id++){
        no = ownerOf(id) != owner();
        if (no) return !no;
      }
    /// @notice Check Dazzlers
    } else {
      no = ownerOf(dropId) != owner();
    }

    return !no;
  }

  /**
    * @dev Burns a PEGZ drop or Dazzler and its tokens only if all
    * of the tokens are held by the contract owner.
    *
    * Requirements:
    * - `dropPaths[dropId]` must be set, i.e. there is a previous
    * mint for this dropId
    * - For dropId 1-10, every tokenId in the drop must be owned by
    * `owner`, i.e. tokens have not been transferred
    * - For dropId 101-103, the token with that id must be owned by
    * `owner`
    *
    * @param dropId of the drop to burn
  */
  function burn(uint256 dropId) onlyOwner public {
    require(bytes(dropPaths[dropId]).length > 0, "PEGZ: Drop has not been minted");

    /// @notice Burn regular PEGZ
    if (dropId < 101){
      uint256 maxId = dropId*10;

      for(uint256 id=maxId-9; id<=maxId; id++){
        require(ownerOf(id) == msg.sender, 'PEGZ: A token in this drop has already been transfered; the drop cannot be burned');
        _burn(id);
      }
    /// @notice Burn Dazzlers
    } else {
      require(ownerOf(dropId) == msg.sender, 'PEGZ: This Dazzler has already been transfered and cannot be burned');
      _burn(dropId);
    }


    dropPaths[dropId] = "";
  }

  /**
    * @dev Finds the dropPath from the tokenId. Used in `tokenURI()`
    * to construct the fully URI from a `tokenId`
    * For `tokenId` 1-10 inclusive turn a `tokenId` into a `dropId`,
    * otherwise the token is a Dazzler and use it as is.
    * @param tokenId of the token to check
  */
  function dropPathFromTokenId(uint256 tokenId) public view returns (string memory) {
    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

    /// @notice Path for Dazzlers
    if (tokenId > 100) return dropPaths[tokenId];

    uint256 dropId;

    /// @notice Path for regular PEGZ
    if (tokenId%10 == 0){
      dropId = tokenId/10;
    } else {
      dropId = ((tokenId-(tokenId%10))/10)+1;
    }

    return dropPaths[dropId];
  }

  /**
    * @dev Override for standard tokenURI to use
    * `dropPathFromTokenId()` to look up which IPFS-stored folder
    * a given tokenId's metadata is stored in
  */
  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

    return string(abi.encodePacked(baseURI(), dropPathFromTokenId(tokenId), "/", convertUintToString(tokenId), '.json'));
  }

  /**
    * @dev Utility function turning uint into string
  */
  function convertUintToString(uint _index) internal pure returns (string memory _uintAsString) {
      if (_index == 0) {
        return "0";
      }
      uint j = _index;
      uint len;
      while (j != 0) {
        len++;
        j /= 10;
      }
      bytes memory bstr = new bytes(len);
      uint k = len - 1;
      while (_index != 0) {
          bstr[k--] = byte(uint8(48 + _index % 10));
          _index /= 10;
      }
      return string(bstr);
  }
}