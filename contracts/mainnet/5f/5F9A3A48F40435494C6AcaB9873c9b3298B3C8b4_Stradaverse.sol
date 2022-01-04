// contracts/Stradaverse.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "./libs/Base64.sol";
import "./ProxyRegistry.sol";
import "./libs/TraitsNames.sol";
import "./libs/Utils.sol";

struct Traits {
  uint8 headgearId;
  uint8 faceMaskId;
  uint8 eyeId;
  uint8 corneaId;
  uint8 pupilId;
  uint8 footwearId;
  uint8 clothingId;
  uint8 backgroundId;
  uint8 skinColorId;
}

/// @title Stradaverse
/// @author Will Holley
contract Stradaverse is
  ERC721Upgradeable,
  OwnableUpgradeable,
  ReentrancyGuardUpgradeable
{
  using StringsUpgradeable for uint256;
  using StringsUpgradeable for uint8;

  //////////////////////////////
  /// State
  //////////////////////////////

  /// @dev Mapping of ID to traits
  mapping(uint256 => Traits) private _traitMaps;

  /// @dev Ensuring trait combinations are unique.
  mapping(bytes32 => uint8) private _traitCombinationUniquenessHashes;

  /// @notice Funds paid to mint.
  uint256 public mintPayments;

  string public viewerBaseUrl;

  address public proxyRegistryAddress;

  string public thumbnailBaseUrl;

  //////////////////////////////
  /// Constructor
  //////////////////////////////

  /// @param proxyRegistryAddress_ OpenSea Proxy Registry Address
  /// @param viewerBaseUrl_ Base url of the viewer
  function initialize(
    address proxyRegistryAddress_,
    string memory viewerBaseUrl_
  ) public initializer {
    __ERC721_init("StradaVerse", "STRADAVERSE");
    __Ownable_init();

    mintPayments = 0;

    viewerBaseUrl = viewerBaseUrl_;
    proxyRegistryAddress = proxyRegistryAddress_;
  }

  //////////////////////////////
  /// Minting
  //////////////////////////////

  /// @notice Creates a deterministicly unique hash a given set of traits.
  function computeTraitHash(
    uint8 headgearId_,
    uint8 faceMaskId_,
    uint8 eyeId_,
    uint8 corneaId_,
    uint8 pupilId_,
    uint8 footwearId_,
    uint8 clothingId_,
    uint8 backgroundId_,
    uint8 skinColorId_
  ) public pure returns (bytes32) {
    return
      keccak256(
        abi.encodePacked(
          headgearId_,
          faceMaskId_,
          eyeId_,
          corneaId_,
          pupilId_,
          footwearId_,
          clothingId_,
          backgroundId_,
          skinColorId_
        )
      );
  }

  /// @notice Verifies that a trait combination does not exist
  function validateTraitCombination(
    uint8 headgearId_,
    uint8 faceMaskId_,
    uint8 eyeId_,
    uint8 corneaId_,
    uint8 pupilId_,
    uint8 footwearId_,
    uint8 clothingId_,
    uint8 backgroundId_,
    uint8 skinColorId_
  ) public view returns (bytes32) {
    bytes32 traitHash = computeTraitHash(
      headgearId_,
      faceMaskId_,
      eyeId_,
      corneaId_,
      pupilId_,
      footwearId_,
      clothingId_,
      backgroundId_,
      skinColorId_
    );

    require(
      _traitCombinationUniquenessHashes[traitHash] == 0,
      "This trait combination has already been minted"
    );

    return traitHash;
  }

  /// @notice Mints one and sends it to message sender.
  /// @param headgearId_ Id
  /// @param faceMaskId_ Id
  /// @param eyeId_ Id
  /// @param corneaId_ Id
  /// @param pupilId_ Id
  /// @param footwearId_ Id
  /// @param clothingId_ Id
  /// @param backgroundId_ Id
  /// @param skinColorId_ Id
  function _mint(
    uint8 headgearId_,
    uint8 faceMaskId_,
    uint8 eyeId_,
    uint8 corneaId_,
    uint8 pupilId_,
    uint8 footwearId_,
    uint8 clothingId_,
    uint8 backgroundId_,
    uint8 skinColorId_
  ) internal {
    // Check that this trait has not already been minted.
    bytes32 traitHash = validateTraitCombination(
      headgearId_,
      faceMaskId_,
      eyeId_,
      corneaId_,
      pupilId_,
      footwearId_,
      clothingId_,
      backgroundId_,
      skinColorId_
    );

    // Save uniqueness hash
    _traitCombinationUniquenessHashes[traitHash] = 1;

    uint256 id = _owners.length;

    // Save traits struct
    _traitMaps[id] = Traits({
      headgearId: headgearId_,
      faceMaskId: faceMaskId_,
      eyeId: eyeId_,
      corneaId: corneaId_,
      pupilId: pupilId_,
      footwearId: footwearId_,
      clothingId: clothingId_,
      backgroundId: backgroundId_,
      skinColorId: skinColorId_
    });

    _safeMint(msg.sender, id);
  }

  /// @notice Mints one and sends it to message sender. Requires paying 0.777 Eth.
  /// @param headgearId_ Id
  /// @param faceMaskId_ Id
  /// @param eyeId_ Id
  /// @param corneaId_ Id
  /// @param pupilId_ Id
  /// @param footwearId_ Id
  /// @param clothingId_ Id
  /// @param backgroundId_ Id
  /// @param skinColorId_ Id
  function mint(
    uint8 headgearId_,
    uint8 faceMaskId_,
    uint8 eyeId_,
    uint8 corneaId_,
    uint8 pupilId_,
    uint8 footwearId_,
    uint8 clothingId_,
    uint8 backgroundId_,
    uint8 skinColorId_
  ) public payable nonReentrant {
    require(msg.value == 0.0777 ether, "Mint cost is 0.0777 ETH");

    _mint(
      headgearId_,
      faceMaskId_,
      eyeId_,
      corneaId_,
      pupilId_,
      footwearId_,
      clothingId_,
      backgroundId_,
      skinColorId_
    );

    // Collect payment
    mintPayments += msg.value;
  }

  /// @notice Owner-only mint function.  Only requires paying gas.
  function ownerMint(
    uint8 headgearId_,
    uint8 faceMaskId_,
    uint8 eyeId_,
    uint8 corneaId_,
    uint8 pupilId_,
    uint8 footwearId_,
    uint8 clothingId_,
    uint8 backgroundId_,
    uint8 skinColorId_
  ) public onlyOwner {
    _mint(
      headgearId_,
      faceMaskId_,
      eyeId_,
      corneaId_,
      pupilId_,
      footwearId_,
      clothingId_,
      backgroundId_,
      skinColorId_
    );
  }

  /// @notice Transfers funds to the contract owner.
  function collectMintPayments() public onlyOwner {
    require(mintPayments > 0, "No outstanding payments");
    address payable owner = payable(owner());
    owner.transfer(mintPayments);
    mintPayments = 0;
  }

  //////////////////////////////
  /// OpenSea
  //////////////////////////////

  /// @dev Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
  /// See: https://github.com/ProjectOpenSea/opensea-creatures/blob/a0db5ede13ffb2d43b3ebfc2c50f99968f0d1bbb/contracts/TradeableERC721Token.sol#L66
  function isApprovedForAll(address owner_, address operator_)
    public
    view
    override
    returns (bool)
  {
    ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
    if (address(proxyRegistry.proxies(owner_)) == operator_) {
      return true;
    }

    return super.isApprovedForAll(owner_, operator_);
  }

  //////////////////////////////
  /// Metadata
  //////////////////////////////

  /// @dev Creates a metadata attribute object
  function _makeAttribute(string memory traitType_, string memory value_)
    private
    pure
    returns (string memory)
  {
    return
      string(
        abi.encodePacked(
          '{"trait_type":"',
          traitType_,
          '", "value":"',
          value_,
          '"}'
        )
      );
  }

  function tokenURI(uint256 id_) public view override returns (string memory) {
    require(_exists(id_), "ERC721Metadata: URI query for nonexistent token");

    string memory id = id_.toString();
    string memory name = string(abi.encodePacked("Strada #", id));
    string
      memory description = "StradaVerse is a community-driven metaverse project featuring worlds created by top independent artists. Strada's are customized before they are minted with no duplicates with a 10,000 collection size. Each Strada allows its owner to vote on experiences, activations, and artist grants paid for by the StradaVerse Charity. ";
    string memory pageUrl = string(abi.encodePacked(viewerBaseUrl, "/", id));

    Traits memory traits = _traitMaps[id_];

    // Note: need to use multiple strings because abi.encodePacked
    // has a maximum stack depth that would be exceeded otherwise.

    string memory traitsA = string(
      abi.encodePacked(
        "[",
        _makeAttribute("Headgear", TraitsNames.headgear(traits.headgearId)),
        ",",
        _makeAttribute("Face Mask", TraitsNames.faceMask(traits.faceMaskId)),
        ",",
        _makeAttribute("Eyes", TraitsNames.eye(traits.eyeId)),
        ",",
        _makeAttribute("Corneas", TraitsNames.cornea(traits.corneaId)),
        ",",
        _makeAttribute("Pupils", TraitsNames.pupil(traits.pupilId)),
        ",",
        _makeAttribute("Footwear", TraitsNames.footwear(traits.footwearId)),
        ",",
        _makeAttribute("Clothing", TraitsNames.clothing(traits.clothingId)),
        ","
      )
    );

    string memory traitsString = string(
      abi.encodePacked(
        traitsA,
        _makeAttribute(
          "Background",
          TraitsNames.background(traits.backgroundId)
        ),
        ",",
        _makeAttribute("Skin Color", TraitsNames.skinColor(traits.skinColorId)),
        "]"
      )
    );

    bytes32 traitHash = computeTraitHash(
      traits.headgearId,
      traits.faceMaskId,
      traits.eyeId,
      traits.corneaId,
      traits.pupilId,
      traits.footwearId,
      traits.clothingId,
      traits.backgroundId,
      traits.skinColorId
    );
    string memory traitHashStr = Utils.toHex(traitHash);

    string memory imageUrl = string(
      abi.encodePacked(
        thumbnailBaseUrl,
        Utils.lower(traitHashStr),
        ".jpg?alt=media"
      )
    );

    return
      string(
        abi.encodePacked(
          "data:application/json;base64,",
          Base64.encode(
            bytes(
              abi.encodePacked(
                '{"name":"',
                name,
                '", "description":"',
                description,
                '", "animation_url": "',
                pageUrl,
                '", "image": "',
                imageUrl,
                '", "external_url": "',
                pageUrl,
                '", "attributes": ',
                traitsString,
                "}"
              )
            )
          )
        )
      );
  }

  //////////////////////////////
  /// Upgrades
  //////////////////////////////

  /// @dev 01-20211229
  function setThumbnailBaseUrl(string memory url_) public onlyOwner {
    thumbnailBaseUrl = url_;
  }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.10;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/// @dev Gas Optimized ERC721
/// see https://etherscan.io/address/0x0f78c6eee3c89ff37fd9ef96bd685830993636f2#code
/// see https://archive.ph/jlQfm
contract ERC721Upgradeable is
  Initializable,
  ContextUpgradeable,
  ERC165Upgradeable,
  IERC721Upgradeable,
  IERC721MetadataUpgradeable
{
  using AddressUpgradeable for address;
  using StringsUpgradeable for uint256;

  string private _name;
  string private _symbol;

  address[] internal _owners;

  mapping(uint256 => address) private _tokenApprovals;
  mapping(address => mapping(address => bool)) private _operatorApprovals;

  /**
   * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
   */
  function __ERC721_init(string memory name_, string memory symbol_)
    internal
    initializer
  {
    __Context_init_unchained();
    __ERC165_init_unchained();
    __ERC721_init_unchained(name_, symbol_);
  }

  function __ERC721_init_unchained(string memory name_, string memory symbol_)
    internal
    initializer
  {
    _name = name_;
    _symbol = symbol_;
  }

  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC165Upgradeable, IERC165Upgradeable)
    returns (bool)
  {
    return
      interfaceId == type(IERC721Upgradeable).interfaceId ||
      interfaceId == type(IERC721MetadataUpgradeable).interfaceId ||
      super.supportsInterface(interfaceId);
  }

  /// @dev Modified
  function balanceOf(address owner)
    public
    view
    virtual
    override
    returns (uint256)
  {
    require(owner != address(0), "ERC721: balance query for the zero address");

    uint256 count;
    for (uint256 i; i < _owners.length; ++i) {
      if (owner == _owners[i]) ++count;
    }
    return count;
  }

  /**
   * @dev See {IERC721-ownerOf}.
   */
  function ownerOf(uint256 tokenId)
    public
    view
    virtual
    override
    returns (address)
  {
    address owner = _owners[tokenId];
    require(owner != address(0), "ERC721: owner query for nonexistent token");
    return owner;
  }

  /**
   * @dev See {IERC721Metadata-name}.
   */
  function name() public view virtual override returns (string memory) {
    return _name;
  }

  /**
   * @dev See {IERC721Metadata-symbol}.
   */
  function symbol() public view virtual override returns (string memory) {
    return _symbol;
  }

  /**
   * @dev See {IERC721Metadata-tokenURI}.
   */
  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );

    string memory baseURI = _baseURI();
    return
      bytes(baseURI).length > 0
        ? string(abi.encodePacked(baseURI, tokenId.toString()))
        : "";
  }

  /**
   * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
   * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
   * by default, can be overriden in child contracts.
   */
  function _baseURI() internal view virtual returns (string memory) {
    return "";
  }

  /**
   * @dev See {IERC721-approve}.
   */
  function approve(address to, uint256 tokenId) public virtual override {
    address owner = ERC721Upgradeable.ownerOf(tokenId);
    require(to != owner, "ERC721: approval to current owner");

    require(
      _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
      "ERC721: approve caller is not owner nor approved for all"
    );

    _approve(to, tokenId);
  }

  /**
   * @dev See {IERC721-getApproved}.
   */
  function getApproved(uint256 tokenId)
    public
    view
    virtual
    override
    returns (address)
  {
    require(_exists(tokenId), "ERC721: approved query for nonexistent token");

    return _tokenApprovals[tokenId];
  }

  /**
   * @dev See {IERC721-setApprovalForAll}.
   */
  function setApprovalForAll(address operator, bool approved)
    public
    virtual
    override
  {
    require(operator != _msgSender(), "ERC721: approve to caller");

    _operatorApprovals[_msgSender()][operator] = approved;
    emit ApprovalForAll(_msgSender(), operator, approved);
  }

  /**
   * @dev See {IERC721-isApprovedForAll}.
   */
  function isApprovedForAll(address owner, address operator)
    public
    view
    virtual
    override
    returns (bool)
  {
    return _operatorApprovals[owner][operator];
  }

  /**
   * @dev See {IERC721-transferFrom}.
   */
  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public virtual override {
    //solhint-disable-next-line max-line-length
    require(
      _isApprovedOrOwner(_msgSender(), tokenId),
      "ERC721: transfer caller is not owner nor approved"
    );

    _transfer(from, to, tokenId);
  }

  /**
   * @dev See {IERC721-safeTransferFrom}.
   */
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public virtual override {
    safeTransferFrom(from, to, tokenId, "");
  }

  /**
   * @dev See {IERC721-safeTransferFrom}.
   */
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory _data
  ) public virtual override {
    require(
      _isApprovedOrOwner(_msgSender(), tokenId),
      "ERC721: transfer caller is not owner nor approved"
    );
    _safeTransfer(from, to, tokenId, _data);
  }

  /**
   * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
   * are aware of the ERC721 protocol to prevent tokens from being forever locked.
   *
   * `_data` is additional data, it has no specified format and it is sent in call to `to`.
   *
   * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
   * implement alternative mechanisms to perform token transfer, such as signature-based.
   *
   * Requirements:
   *
   * - `from` cannot be the zero address.
   * - `to` cannot be the zero address.
   * - `tokenId` token must exist and be owned by `from`.
   * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
   *
   * Emits a {Transfer} event.
   */
  function _safeTransfer(
    address from,
    address to,
    uint256 tokenId,
    bytes memory _data
  ) internal virtual {
    _transfer(from, to, tokenId);
    require(
      _checkOnERC721Received(from, to, tokenId, _data),
      "ERC721: transfer to non ERC721Receiver implementer"
    );
  }

  /// @dev Modified
  function _exists(uint256 tokenId) internal view virtual returns (bool) {
    return tokenId < _owners.length && _owners[tokenId] != address(0);
  }

  /**
   * @dev Returns whether `spender` is allowed to manage `tokenId`.
   *
   * Requirements:
   *
   * - `tokenId` must exist.
   */
  function _isApprovedOrOwner(address spender, uint256 tokenId)
    internal
    view
    virtual
    returns (bool)
  {
    require(_exists(tokenId), "ERC721: operator query for nonexistent token");
    address owner = ERC721Upgradeable.ownerOf(tokenId);
    return (spender == owner ||
      getApproved(tokenId) == spender ||
      isApprovedForAll(owner, spender));
  }

  /**
   * @dev Safely mints `tokenId` and transfers it to `to`.
   *
   * Requirements:
   *
   * - `tokenId` must not exist.
   * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
   *
   * Emits a {Transfer} event.
   */
  function _safeMint(address to, uint256 tokenId) internal virtual {
    _safeMint(to, tokenId, "");
  }

  /**
   * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
   * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
   */
  function _safeMint(
    address to,
    uint256 tokenId,
    bytes memory _data
  ) internal virtual {
    _mint(to, tokenId);
    require(
      _checkOnERC721Received(address(0), to, tokenId, _data),
      "ERC721: transfer to non ERC721Receiver implementer"
    );
  }

  /**
   * @dev Mints `tokenId` and transfers it to `to`.
   *
   * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
   *
   * Requirements:
   *
   * - `tokenId` must not exist.
   * - `to` cannot be the zero address.
   *
   * Emits a {Transfer} event.
   */
  function _mint(address to, uint256 tokenId) internal virtual {
    require(to != address(0), "ERC721: mint to the zero address");
    require(!_exists(tokenId), "ERC721: token already minted");

    _beforeTokenTransfer(address(0), to, tokenId);
    _owners.push(to);

    emit Transfer(address(0), to, tokenId);
  }

  /**
   * @dev Destroys `tokenId`.
   * The approval is cleared when the token is burned.
   *
   * Requirements:
   *
   * - `tokenId` must exist.
   *
   * Emits a {Transfer} event.
   */
  function _burn(uint256 tokenId) internal virtual {
    address owner = ERC721Upgradeable.ownerOf(tokenId);

    _beforeTokenTransfer(owner, address(0), tokenId);

    // Clear approvals
    _approve(address(0), tokenId);

    _owners[tokenId] = address(0);

    emit Transfer(owner, address(0), tokenId);
  }

  /**
   * @dev Transfers `tokenId` from `from` to `to`.
   *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
   *
   * Requirements:
   *
   * - `to` cannot be the zero address.
   * - `tokenId` token must be owned by `from`.
   *
   * Emits a {Transfer} event.
   */
  function _transfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual {
    require(
      ERC721Upgradeable.ownerOf(tokenId) == from,
      "ERC721: transfer of token that is not own"
    );
    require(to != address(0), "ERC721: transfer to the zero address");

    _beforeTokenTransfer(from, to, tokenId);

    // Clear approvals from the previous owner
    _approve(address(0), tokenId);

    _owners[tokenId] = to;

    emit Transfer(from, to, tokenId);
  }

  /**
   * @dev Approve `to` to operate on `tokenId`
   *
   * Emits a {Approval} event.
   */
  function _approve(address to, uint256 tokenId) internal virtual {
    _tokenApprovals[tokenId] = to;
    emit Approval(ERC721Upgradeable.ownerOf(tokenId), to, tokenId);
  }

  /**
   * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
   * The call is not executed if the target address is not a contract.
   *
   * @param from address representing the previous owner of the given token ID
   * @param to target address that will receive the tokens
   * @param tokenId uint256 ID of the token to be transferred
   * @param _data bytes optional data to send along with the call
   * @return bool whether the call correctly returned the expected magic value
   */
  function _checkOnERC721Received(
    address from,
    address to,
    uint256 tokenId,
    bytes memory _data
  ) private returns (bool) {
    if (to.isContract()) {
      try
        IERC721ReceiverUpgradeable(to).onERC721Received(
          _msgSender(),
          from,
          tokenId,
          _data
        )
      returns (bytes4 retval) {
        return retval == IERC721ReceiverUpgradeable.onERC721Received.selector;
      } catch (bytes memory reason) {
        if (reason.length == 0) {
          revert("ERC721: transfer to non ERC721Receiver implementer");
        } else {
          assembly {
            revert(add(32, reason), mload(reason))
          }
        }
      }
    } else {
      return true;
    }
  }

  /**
   * @dev Hook that is called before any token transfer. This includes minting
   * and burning.
   *
   * Calling conditions:
   *
   * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
   * transferred to `to`.
   * - When `from` is zero, `tokenId` will be minted for `to`.
   * - When `to` is zero, ``from``'s `tokenId` will be burned.
   * - `from` and `to` are never both zero.
   *
   * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
   */
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual {}

  uint256[44] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides a function for encoding some bytes in base64
library Base64 {
  string internal constant TABLE =
    "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

  function encode(bytes memory data) internal pure returns (string memory) {
    if (data.length == 0) return "";

    // load the table into memory
    string memory table = TABLE;

    // multiply by 4/3 rounded up
    uint256 encodedLen = 4 * ((data.length + 2) / 3);

    // add some extra buffer at the end required for the writing
    string memory result = new string(encodedLen + 32);

    assembly {
      // set the actual output length
      mstore(result, encodedLen)

      // prepare the lookup table
      let tablePtr := add(table, 1)

      // input ptr
      let dataPtr := data
      let endPtr := add(dataPtr, mload(data))

      // result ptr, jump over length
      let resultPtr := add(result, 32)

      // run over the input, 3 bytes at a time
      for {

      } lt(dataPtr, endPtr) {

      } {
        dataPtr := add(dataPtr, 3)

        // read 3 bytes
        let input := mload(dataPtr)

        // write 4 characters
        mstore(
          resultPtr,
          shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F))))
        )
        resultPtr := add(resultPtr, 1)
        mstore(
          resultPtr,
          shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F))))
        )
        resultPtr := add(resultPtr, 1)
        mstore(
          resultPtr,
          shl(248, mload(add(tablePtr, and(shr(6, input), 0x3F))))
        )
        resultPtr := add(resultPtr, 1)
        mstore(resultPtr, shl(248, mload(add(tablePtr, and(input, 0x3F)))))
        resultPtr := add(resultPtr, 1)
      }

      // padding with '='
      switch mod(mload(data), 3)
      case 1 {
        mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
      }
      case 2 {
        mstore(sub(resultPtr, 1), shl(248, 0x3d))
      }
    }

    return result;
  }
}

// contracts/ProxyRegistry.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract OwnableDelegateProxy {}

/// @notice Used to delegate ownership of a contract to another address,
/// to save on unneeded transactions to approve contract use for users.
contract ProxyRegistry {
  mapping(address => OwnableDelegateProxy) public proxies;
}

// contracts/libs/Traits.sol
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

library TraitsNames {
  function _color(uint8 id) internal pure returns (string memory) {
    if (id == 0) {
      return "Pink";
    } else if (id == 1) {
      return "Gold";
    } else if (id == 2) {
      return "Green";
    } else if (id == 3) {
      return "Light Blue";
    } else if (id == 4) {
      return "Earth";
    } else if (id == 5) {
      return "Red";
    } else if (id == 6) {
      return "Cotton Candy";
    } else if (id == 7) {
      return "Space Black";
    } else if (id == 8) {
      return "Terra";
    } else if (id == 9) {
      return "Sunset Cloud";
    } else if (id == 10) {
      return "Lavender";
    } else if (id == 11) {
      return "Peach";
    } else if (id == 12) {
      return "Blue";
    } else {
      require(true, "Bad id");
    }

    return "";
  }

  function headgear(uint8 id) internal pure returns (string memory) {
    if (id == 0) {
      return "No Headgear";
    } else if (id == 1) {
      return "Aero Cap";
    } else if (id == 2) {
      return "Guardian Helmet";
    } else if (id == 3) {
      return "Headphones Helmet";
    } else if (id == 4) {
      return "Crown";
    } else if (id == 5) {
      return "Winged Headphones";
    } else {
      require(true, "Bad id");
    }

    return "";
  }

  function faceMask(uint8 id) internal pure returns (string memory) {
    if (id == 0) {
      return "No Facemask";
    } else if (id == 1) {
      return "Purifier";
    } else {
      require(true, "Bad id");
    }

    return "";
  }

  function eye(uint8 id) internal pure returns (string memory) {
    if (id == 0) {
      return "Happy";
    } else if (id == 1) {
      return "Rolling";
    } else if (id == 2) {
      return "Crushing";
    } else if (id == 3) {
      return "Sad";
    } else {
      require(true, "Bad id");
    }

    return "";
  }

  function cornea(uint8 id) internal pure returns (string memory) {
    return _color(id);
  }

  function pupil(uint8 id) internal pure returns (string memory) {
    return _color(id);
  }

  function footwear(uint8 id) internal pure returns (string memory) {
    if (id == 0) {
      return "No boots";
    } else if (id == 1) {
      return "Tech Boots";
    } else if (id == 2) {
      return "Terra Boots";
    } else if (id == 3) {
      return "Aero Boots";
    } else if (id == 4) {
      return "Guardian Boots";
    } else if (id == 5) {
      return "Cozy Slides";
    } else if (id == 6) {
      return "Sprinter Sneaker";
    } else {
      require(true, "Bad id");
    }

    return "";
  }

  function clothing(uint8 id) internal pure returns (string memory) {
    if (id == 0) {
      return "Birthday Suit";
    } else if (id == 1) {
      return "Vest";
    } else if (id == 2) {
      return "Turtle";
    } else if (id == 3) {
      return "Buttons";
    } else if (id == 4) {
      return "Kimono";
    } else if (id == 5) {
      return "Sweater";
    } else if (id == 6) {
      return "Apron";
    } else {
      require(true, "Bad id");
    }

    return "";
  }

  function background(uint8 id) internal pure returns (string memory) {
    if (id == 0) {
      return "Solar";
    } else if (id == 1) {
      return "Flare 2";
    } else if (id == 2) {
      return "Flare 1";
    } else if (id == 3) {
      return "Saturn";
    } else if (id == 4) {
      return "Neptune";
    } else if (id == 5) {
      return "Mars";
    } else if (id == 6) {
      return "Flare 3";
    } else if (id == 7) {
      return "Flare 5";
    } else if (id == 8) {
      return "Prarie";
    } else if (id == 9) {
      return "Hill";
    } else if (id == 10) {
      return "Strada Orb";
    } else if (id == 11) {
      return "Canyon";
    } else {
      require(true, "Bad id");
    }

    return "";
  }

  function skinColor(uint8 id) internal pure returns (string memory) {
    return _color(id);
  }
}

// contracts/libs/Utils.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

library Utils {
  function toHex(bytes32 data) internal pure returns (string memory) {
    return
      string(
        abi.encodePacked(
          "0x",
          _toHex16(bytes16(data)),
          _toHex16(bytes16(data << 128))
        )
      );
  }

  function _toHex16(bytes16 data) private pure returns (bytes32 result) {
    result =
      (bytes32(data) &
        0xFFFFFFFFFFFFFFFF000000000000000000000000000000000000000000000000) |
      ((bytes32(data) &
        0x0000000000000000FFFFFFFFFFFFFFFF00000000000000000000000000000000) >>
        64);
    result =
      (result &
        0xFFFFFFFF000000000000000000000000FFFFFFFF000000000000000000000000) |
      ((result &
        0x00000000FFFFFFFF000000000000000000000000FFFFFFFF0000000000000000) >>
        32);
    result =
      (result &
        0xFFFF000000000000FFFF000000000000FFFF000000000000FFFF000000000000) |
      ((result &
        0x0000FFFF000000000000FFFF000000000000FFFF000000000000FFFF00000000) >>
        16);
    result =
      (result &
        0xFF000000FF000000FF000000FF000000FF000000FF000000FF000000FF000000) |
      ((result &
        0x00FF000000FF000000FF000000FF000000FF000000FF000000FF000000FF0000) >>
        8);
    result =
      ((result &
        0xF000F000F000F000F000F000F000F000F000F000F000F000F000F000F000F000) >>
        4) |
      ((result &
        0x0F000F000F000F000F000F000F000F000F000F000F000F000F000F000F000F00) >>
        8);
    result = bytes32(
      0x3030303030303030303030303030303030303030303030303030303030303030 +
        uint256(result) +
        (((uint256(result) +
          0x0606060606060606060606060606060606060606060606060606060606060606) >>
          4) &
          0x0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F) *
        7
    );
  }

  /**
   * Lower
   *
   * Converts all the values of a string to their corresponding lower case
   * value.
   *
   * @param _base When being used for a data type this is the extended object
   *              otherwise this is the string base to convert to lower case
   * @return string
   */
  function lower(string memory _base) internal pure returns (string memory) {
    bytes memory _baseBytes = bytes(_base);
    for (uint256 i = 0; i < _baseBytes.length; i++) {
      _baseBytes[i] = _lower(_baseBytes[i]);
    }
    return string(_baseBytes);
  }

  /**
   * Lower
   *
   * Convert an alphabetic character to lower case and return the original
   * value when not alphabetic
   *
   * @param _b1 The byte to be converted to lower case
   * @return bytes1 The converted value if the passed value was alphabetic
   *                and in a upper case otherwise returns the original value
   */
  function _lower(bytes1 _b1) private pure returns (bytes1) {
    if (_b1 >= 0x41 && _b1 <= 0x5A) {
      return bytes1(uint8(_b1) + 32);
    }

    return _b1;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721MetadataUpgradeable is IERC721Upgradeable {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal initializer {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal initializer {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}