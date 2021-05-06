// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

import './Ownable-ERC721.sol';

contract OwnableDelegateProxy {}

contract ProxyRegistry {
  mapping(address => OwnableDelegateProxy) public proxies;
}

contract PEGZ is ProxyRegistry, ERC721, Ownable {
  address public proxyRegistryAddress;

  // Each drop is stores an IPFS hash path that is a folder containing all token metadata for that drop
  mapping(uint256 => string) public dropPaths;

  /**
    * @param _proxyRegistryAddress The address of the OpenSea/Wyvern proxy registry
  */
  constructor(address _proxyRegistryAddress, string memory name, string memory symbol) ERC721(name, symbol) Ownable() public {
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
    return string(abi.encodePacked(baseURI(), "XXX"));
  }

  /**
    * @dev Mints a drop if it hasn't been minted. There can only be 10 drops, and drops are for 10 tokens starting at tokenId 1.
    * Example: dropId 1 = tokens 1 - 10; dropId 2 = tokens 11 - 20
    * @param dropId of the drop to mint
    * @param dropPath must not end with trailing /
  */
  function mint(uint256 dropId, string memory dropPath) onlyOwner public {
    require(bytes(dropPaths[dropId]).length == 0, "PEGZ: Drop already minted");

    require(dropId>=1 && dropId<=10, 'PEGZ: Only 1-10 drops allowed');

    uint256 maxId = dropId*10;

    for(uint256 id=maxId-9; id<=maxId; id++){
      _mint(msg.sender, id);
    }

    dropPaths[dropId] = dropPath;
  }

  /**
    * @dev Burns a drop and its tokens only if all of the tokens are held by the contract owner.
    * @param dropId of the drop to burn
  */
  function burn(uint256 dropId) onlyOwner public {
    require(bytes(dropPaths[dropId]).length > 0, "PEGZ: Drop has not been minted");

    uint256 maxId = dropId*10;

    for(uint256 id=maxId-9; id<=maxId; id++){
      require(ownerOf(id) == msg.sender, 'PEGZ: A token in this drop has already been transfered and so the drop cannot be burned');
      _burn(id);
    }

    dropPaths[dropId] = "";
  }

  /**
    * @dev Finds the dropPath from the tokenId. Used in `tokenURI()` to construct the fully URI from a `tokenId`
  */
  function dropPathFromTokenId(uint256 tokenId) public view returns (string memory) {
    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

    uint256 dropId;

    if (tokenId%10 == 0){
      dropId = tokenId/10;
    } else {
      dropId = ((tokenId-(tokenId%10))/10)+1;
    }

    return dropPaths[dropId];
  }

  /**
    * @dev Override for standard tokenURI to use `dropPathFromTokenId()` to look up which IPFS-stored folder
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