// SPDX-License-Identifier: MIT

pragma solidity 0.5.17;
pragma experimental ABIEncoderV2;

import "./ERC721Full.sol";
import "./IKlein.sol";
import "./ProxyRegistry.sol";

contract WrappedIKB is ERC721Full, Ownable {

  // `baseURI` is an IPFS folder with a trailing slash
  
  string private _baseURI = "https://ipfs.io/ipfs/QmQ5yApMr1thk5gkFakFeJpSvKBPKbTAfkVG9FHpo2zuSY/";
  string private constant _contractURI = "https://ipfs.io/ipfs/Qmf2pwtBCsnWaFrtKq1RG3fod4iH66vfeoQdJifmmLm9TN";

  IKlein public Klein;

  address public proxyRegistryAddress;

  constructor(address _IKBAddress, address _proxyRegistryAddress)
    ERC721Full("IKB Cachet de Garantie", "wIKB")
    Ownable()
    public
  {
    Klein = IKlein(_IKBAddress);
    proxyRegistryAddress = _proxyRegistryAddress;

  }

  /**************************************************************************
   * Opensea-specific methods
   *************************************************************************/

  function contractURI() external pure returns (string memory) {
      return _contractURI;
  }

  /**
   * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
   */
  function isApprovedForAll(address owner, address operator)
    public
    view
    returns (bool)
  {
    // Whitelist OpenSea proxy contract for easy trading.
    ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
    if (address(proxyRegistry.proxies(owner)) == operator) {
        return true;
    }

    return super.isApprovedForAll(owner, operator);
  }

  /**************************************************************************
    * ERC721 methods
    *************************************************************************/

  /**
  * @dev Returns the base URI set via {_setBaseURI}. This will be
  * automatically added as a prefix in {tokenURI} to each token's URI, or
  * to the token ID if no specific URI is set for that token ID.
  */
  function baseURI() public view returns (string memory) {
      return _baseURI;
  }


  /**
    * @dev `baseURI` is a folder with a trailing slash.
    * The JSON metadata for `tokenId` can be found at `baseURI` + `tokenId` + .json
  */
  function tokenURI(uint256 tokenId) public view returns (string memory) {
    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

    return string(abi.encodePacked(baseURI(), uint2str(tokenId), '.json'));
  }


  /**************************************************************************
   * WrappedIKB-specific methods
   *************************************************************************/

  /**
   * @dev Uses `transferFrom` to transer all IKB Tokens from `msg.sender` to
   * this wrapper. Once the wrapper owns all editions, it mints new tokens with
   * the same `id` and sets `msg.sender` as the owner.
   *
   * Requirements:
   *
   * - All IKB tokens owned by `msg.sender` must be allowed to be transfered by WrappedIKB.
   *   To do this, call `approve()` with the address of WrappedIKB and the current
   *   balance of the owner
  */
  function mint() public returns (bool){
    uint256[] memory ownedRecords = Klein.getHolderEditions(_msgSender());
    uint ownedRecordsLength = ownedRecords.length;

    require(Klein.allowance(_msgSender(),address(this)) >= ownedRecordsLength, "WrappedIKB: must approve all IKB tokens to be transfered");

    require(Klein.transferFrom(_msgSender(),address(this), ownedRecordsLength), "WrappedIKB: IKB Token did not transferFrom");

    for (uint i = 0; i < ownedRecordsLength; i++){
      _safeMint(_msgSender(), ownedRecords[i]);
    }

    return true;
  }

  /**
   * @dev Uses `specificTransferFrom` to transer specific a IKB Token edition from
   * `msg.sender` to this wrapper. Once the wrapper owns the specified edition,
   *  it mints new tokens with
   * the same `id` and sets `msg.sender` as the owner.
   *
   * Requirements:
   *
   * - None. There is no way to check if the IKB contract allows a specific transfer.
   *   The transfer will fail on the IKB contract `specificApprove()` is not called
   *   with the correct edition.
  */
  function mint(uint edition) public {
    require(Klein.specificTransferFrom(_msgSender(), address(this), edition), "WrappedIKB: IKB Token did not specificTransferFrom");
    _safeMint(_msgSender(), edition);
  }

  /**
   * @dev Transfers the specified IKB token editions back to `msg.sender`
   * and burns the corresponding WrappedIKB tokens
   *
   * Requirements:
   *
   * - `msg.sender` must be the owner of the WrappedIKB tokens
  */
  function unwrapSpecific(uint tokenId) public{
    require(ownerOf(tokenId) == _msgSender(), "WrappedIKB: Token not owned by sender");
    require(Klein.specificTransfer(_msgSender(), tokenId), "WrappedIKB: Token transfer failed");
    _burn(tokenId);
  }

  /**
   * @dev Convenience function transfers all IKB token editions back to
   * `msg.sender` and burns the corresponding WrappedIKB tokens.
   * See `unwrapSpecific()` for implementation.
  */
  function unwrapAll() public{
    uint256 balance = balanceOf(_msgSender());

    uint[] memory tokenIds = new uint[](balance);

    for (uint256 i = 0; i < balance; i++){
      tokenIds[i] = (tokenOfOwnerByIndex(_msgSender(), i));
    }
    for (uint256 i = 0; i < balance; i++){
      unwrapSpecific(tokenIds[i]);
    }
  }

  /**************************************************************************
   * Utility methods
   *************************************************************************/

  // via https://github.com/ProjectOpenSea/opensea-creatures/blob/master/contracts/Strings.sol
  function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
      if (_i == 0) {
          return "0";
      }
      uint j = _i;
      uint len;
      while (j != 0) {
          len++;
          j /= 10;
      }
      bytes memory bstr = new bytes(len);
      uint k = len - 1;
      while (_i != 0) {
          bstr[k--] = byte(uint8(48 + _i % 10));
          _i /= 10;
      }
      return string(bstr);
  }

}