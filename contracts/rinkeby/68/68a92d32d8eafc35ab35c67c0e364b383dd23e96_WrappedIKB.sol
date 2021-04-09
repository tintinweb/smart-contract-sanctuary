// SPDX-License-Identifier: MIT

pragma solidity 0.5.17;
pragma experimental ABIEncoderV2;

import "./ERC721Full.sol";
import "./IKlein.sol";
import "./ProxyRegistry.sol";

contract WrappedIKB is ERC721Full, Ownable {

  mapping (uint256 => string) private _tokenURIs;


  string private _baseURI = "https://ipfs.io/ipfs/";

  string private constant _contractURI = "https://ipfs.io/ipfs/QmXgAWQ3mUexm4Jctfc5x7S6rbCaueEaZnxKsegemUjfac";

  IKlein public Klein;

  address public proxyRegistryAddress;

  constructor(address _IKBAddress, address _proxyRegistryAddress)
    ERC721Full("WrappedIKB", "wIKB")
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
    * @dev Allows owner to set `_baseURI`
  */
  function setbaseURI(string memory baseURI_) public onlyOwner {
    _setBaseURI(baseURI_);
  }

  function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal  {
      _tokenURIs[tokenId] = _tokenURI;
  }

  function setTokenUri(uint256 tokenId, string memory tokenURI)
    public
    onlyOwner
    returns (bool)
  {
    require(bytes(_tokenURIs[tokenId]).length == 0, 'WrappedIKB: tokenUri has already been set');

    _setTokenURI(tokenId, tokenURI);

    return true;
  }

  function setTokenURIs(uint[] memory tokenIds, string[] memory tokenURIs)
    public
    onlyOwner
    returns (bool)
  {
    require(tokenIds.length == tokenURIs.length, 'WrappedIKB: tokenIds and tokenURIs must be the same length');

    for (uint256 i; i < tokenIds.length; i++){
      setTokenUri(tokenIds[i], tokenURIs[i]);
    }

    return true;
  }

 /**
   * @dev `tokenURIs` is private but it's helpful for owner to check the
   * `tokenURI` of a `tokenId` when `tokenId` is not minted yet by its owner.
  */

  function revealTokenUri(uint256 tokenId) public view onlyOwner returns(string memory tokenUri){
    return _tokenURIs[tokenId];
  }




  /**
   * @dev Modifies Open Zeppelin's `tokenURI()` to read from `_tokenIPFSHashes`
   * instead of `_tokenUris`
  */

  function tokenURI(uint256 tokenId) public view returns (string memory) {
      require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

      string memory _tokenURI = _tokenURIs[tokenId];
      string memory base = baseURI();

      return string(abi.encodePacked(base, _tokenURI));
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
  function wrapAll() public returns (bool){
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
  function wrapSpecific(uint edition) public {
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

}