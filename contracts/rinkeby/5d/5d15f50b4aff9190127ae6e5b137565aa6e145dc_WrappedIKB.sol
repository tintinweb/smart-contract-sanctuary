// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;
pragma abicoder v2;

import "./ERC721.sol";
import "./IKlein.sol";
import "./ProxyRegistry.sol";

contract WrappedIKB is ERC721, ERC721Burnable, Ownable {
  mapping (uint256 => string) private _tokenURIs;

  string private _baseURI;

  string private _contractURI;

  address public immutable IKBAddress;

  IKlein public immutable Klein;

  address public proxyRegistryAddress;

  constructor(address _IKBAddress, address _proxyRegistryAddress)
    ERC721("WrappedIKB", "wIKB")
    Ownable()
    public
  {
    IKBAddress = _IKBAddress;
    Klein = IKlein(_IKBAddress);
    proxyRegistryAddress = _proxyRegistryAddress;
  }

  /**************************************************************************
   * Opensea-specific methods
   *************************************************************************/

  function contractURI() external view returns (string memory) {
      return _contractURI;
  }

  /**
   * @dev Sets `_contractURI` once..
   *
   * Requirements:
   *
   * - `_contractURI` must not be set
   */
  function setContractURI(string memory contractURI_) public onlyOwner {
    require(bytes(_contractURI).length == 0, 'WrappedIKB: contractURI already set');
    require(bytes(contractURI_).length != 0, 'WrappedIKB: new contractURI string cannot be blank');
    _contractURI = contractURI_;
  }

  /**
   * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
   */
  function isApprovedForAll(address owner, address operator)
    public
    override
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
    * @dev Allows owner to set `_baseURI`
  */
  function setbaseURI(string memory baseURI) public onlyOwner {
    _setBaseURI(baseURI);
  }

  /**
    * @dev Modifies Open Zeppelin standard `_setTokenURI` to not require `tokenId` to exist
  */
  function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal override {
      _tokenURIs[tokenId] = _tokenURI;
  }

  /**
   * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
   *
   * Requirements:
   *
   * - The `tokenURI` of `tokenId` must not exist. It can only be set once.
   * - `tokenId` must be sequential. The previous `tokenUri` for `tokenId - 1` must exist.
   */
  function setTokenUri(uint256 tokenId, string memory _tokenURI)
    public
    onlyOwner
  {
    require(bytes(_tokenURIs[tokenId]).length == 0, 'WrappedIKB: tokenUri has already been set');

    require(tokenId == 0 || bytes(_tokenURIs[tokenId-1]).length > 0, 'WrappedIKB: tokenUri must be set sequentially');

    _setTokenURI(tokenId, _tokenURI);
  }

  /**
   * @dev Convenience function to batch set tokenURIs.
  */
  function setTokenURIs(uint[] memory tokenIds_, string[] memory tokenURIs_)
    public
    onlyOwner
  {
    require(tokenIds_.length == tokenURIs_.length, 'WrappedIKB: tokenIds and tokenURIs must be the same length');

    for (uint256 i; i < tokenIds_.length; i++){
      setTokenUri(tokenIds_[i], tokenURIs_[i]);
    }
  }

  /**
   * @dev `tokenURIs` is private but it's helpful for owner to check the
   * `tokenURI` of a `tokenId` when `tokenId` is not minted yet by its owner.
  */
  function tokenURIs(uint256 tokenId) public view onlyOwner returns(string memory tokenURI){
    return _tokenURIs[tokenId];
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
    burn(tokenId);
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