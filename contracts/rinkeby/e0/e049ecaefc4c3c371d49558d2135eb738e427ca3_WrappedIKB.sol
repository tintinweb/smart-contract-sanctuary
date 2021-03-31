// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;
pragma abicoder v2;

import "./ERC721.sol";
import "./IKlein.sol";
import "./ProxyRegistry.sol";

contract WrappedIKB is ERC721, ERC721Burnable, Ownable {

  string[31] private _tokenIpfsHashes = [
    "QmQEenaUuoprk4JfQCKCmPjkrEGQM2z3S89y4A36hNo95S",
    "QmQzVQYds86WAwo8mmvuDLSzkty5QkACxpspQenWbsz826",
    "Qma9FknpYaRP6ddRKrNjFhefkqJoeA61DtAYFgrwU9gYiW",
    "QmcVBK4oJ24MnioHdSB7bPh5JvYhfVVbCuuuogukxVPrt4",
    "QmURnFyxP2ePX3u8nKbwTdzh4rk8amjvBXdTFqhYaTU378",
    "QmaBxi6P6aLrrPbF3mqDcwCa3xjojM7o7UcibCJSvUeh3g",
    "QmVx3DXTfk13PmCrtbrFzZnuC8JR4egatkJBLEccfXj8vD",
    "QmZxAxk7NpbsBGjkbHBZ4dtadqPwXxHijUUY1sKAfxa6AW",
    "QmQNju3sAZ4YsZV77cco6ceZ4ThuBfzevfHmnob2Fn7qX6",
    "QmQRTwNSXbq5p6nvPKxeCdPgXujzMzBr2tQh2TdMpcbxbT",
    "QmP85Dts6rbbnDYahmq8dgV3fmPdvHdpQ8xdw6zY8VsMXr",
    "QmSJVnbrEhbpALE3CXho9t9mqG8ShBeGE3h8eAYHTS2zXG",
    "QmdHCAfrVr3a1YNDwiXFe9xWRQP2rwfULW4oiMPAMUbEJk",
    "QmduaZxbBdz5UbYemGNaAoV852Jz8SCNBmr2nenVvXp2T5",
    "QmVuEbj997T7s6xs4ceHxYFp6p9KbHKeFPPcqtULLufKny",
    "QmY6DUND3f4iffPGPDBGoT7cdLPu865e5SQJ5nnuEbMdiJ",
    "QmRsfyjmcuo6sfZHBmXysGPHHCVJDQ89xpYL41qXVQN8hg",
    "QmWbbKDQJYPtKHmzYVhiVKC3wnmpfotj87onytJiwyEt8C",
    "QmUoVf3qZ5rXwwVA4EEKk4Ty1VMxEA6EABxLezgVqzez9G",
    "QmP8UbVA1MgXCTfjTyAxyCrSxLY9fmgBtwR3rhG3aMpZYS",
    "QmZetbktBG87z3KzH8hnLWAPWNd97fqyp6XkiKmCQLJchB",
    "QmYzrbBz9GvApXFqkPiVrPxc9CmkJ2ewrqe3vX79hwZeBH",
    "QmNzBC199dQq44H5ZVRdqEnMQ5BqQ9CiJD4JumPcq9djui",
    "QmZZ1RBgXjcHDPrByZDNZRN14AS56GW17NCVJ3Nvt4qQdJ",
    "QmegfPLVFaUW2z8deEPQJ85yZHHfiBtSBAiZRzm5qN3wjt",
    "QmPueCcfMDhEnSEPPFwqteKWpU9kh9Y33EN8GPjBUkhhaC",
    "QmPdzjpaXKb3yYkuAE9jGAmgkfDeQBoDSExF2L5HK4xs4U",
    "QmTva7GEyG4hD5EnYYSNFkmtpXWxRNAZTKx1fAgooyG6qV",
    "QmaKW3uqAFPnEyX2zkK4Qf7KbM9aiX3wZJUGf8VeuRUdsx",
    "QmWFhX51KvQXKPuqEjfYmDLUFJbHUUwPin9mfSKNXUnPr5",
    "QmdEudtvKgArPoQgE7uKi3DBmpZrvMvcqTyF9b7rpnxL1C"
  ];

  string private _baseURI = "https://ipfs.io/ipfs/";

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
  * @dev Returns the base URI set via {_setBaseURI}. This will be
  * automatically added as a prefix in {tokenURI} to each token's URI, or
  * to the token ID if no specific URI is set for that token ID.
  */
  function baseURI() public view override returns (string memory) {
      return _baseURI;
  }

  /**
    * @dev Allows owner to set `_baseURI`
  */
  function setbaseURI(string memory baseURI) public onlyOwner {
    _setBaseURI(baseURI);
  }

  /**
   * @dev `tokenURIs` is private but it's helpful for owner to check the
   * `tokenURI` of a `tokenId` when `tokenId` is not minted yet by its owner.
  */
  function tokenIpfsHash(uint256 tokenId) public view returns(string memory tokenURI){
    return _tokenIpfsHashes[tokenId];
  }

  /**
   * @dev See {IERC721Metadata-tokenURI}.
   */
  function tokenURI(uint256 tokenId) public view override returns (string memory) {
      require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

      string memory _tokenURI = _tokenIpfsHashes[tokenId];
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