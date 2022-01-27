// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../utils/MintERC721Lib.sol";
import "../utils/SecurityLib.sol";

import "./ChocoMintERC721Base.sol";

contract ChocoMintERC721 is IChocoMintERC721, ChocoMintERC721Base {
  constructor(
    string memory name,
    string memory version,
    string memory symbol,
    address trustedForwarder,
    address[] memory defaultApprovals
  ) {
    initialize(name, version, symbol, trustedForwarder, defaultApprovals);
  }

  function mint(MintERC721Lib.MintERC721Data memory mintERC721Data, SignatureLib.SignatureData memory signatureData)
    external
    override
  {
    bytes32 mintERC721Hash = MintERC721Lib.hashStruct(mintERC721Data);
    (bool isSignatureValid, string memory signatureErrorMessage) = _validateTx(
      mintERC721Data.minter,
      mintERC721Hash,
      signatureData
    );
    require(isSignatureValid, signatureErrorMessage);

    _mint(mintERC721Hash, mintERC721Data);
  }

  function isMinted(uint256 tokenId) external view override returns (bool) {
    return _exists(tokenId);
  }

  function _mint(bytes32 mintERC721Hash, MintERC721Lib.MintERC721Data memory mintERC721Data) internal {
    (bool isValid, string memory errorMessage) = _validate(mintERC721Data);
    require(isValid, errorMessage);
    _revokeHash(mintERC721Hash);
    super._mint(mintERC721Data.to, mintERC721Data.tokenId);
    if (mintERC721Data.data.length > 0) {
      (
        string memory tokenStaticURI,
        bool tokenStaticURIFreezing,
        RoyaltyLib.RoyaltyData memory tokenRoyaltyData,
        bool tokenRoyaltyFreezing
      ) = abi.decode(mintERC721Data.data, (string, bool, RoyaltyLib.RoyaltyData, bool));
      if (bytes(tokenStaticURI).length > 0) {
        _setTokenStaticURI(mintERC721Data.tokenId, tokenStaticURI, tokenStaticURIFreezing);
      }
      if (RoyaltyLib.isNotNull(tokenRoyaltyData)) {
        _setTokenRoyalty(mintERC721Data.tokenId, tokenRoyaltyData, tokenRoyaltyFreezing);
      }
    }
    emit Minted(mintERC721Hash);
  }

  function _validate(MintERC721Lib.MintERC721Data memory mintERC721Data) internal view returns (bool, string memory) {
    (bool isMinterValid, string memory minterErrorMessage) = _validateAdminOrOwner(mintERC721Data.minter);
    if (!isMinterValid) {
      return (false, minterErrorMessage);
    }
    (bool isSecurityDataValid, string memory securityDataErrorMessage) = SecurityLib.validate(
      mintERC721Data.securityData
    );
    if (!isSecurityDataValid) {
      return (false, securityDataErrorMessage);
    }

    return (true, "");
  }

  // solhint-disable-next-line ordering
  uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SecurityLib.sol";
import "./SignatureLib.sol";

library MintERC721Lib {
  struct MintERC721Data {
    SecurityLib.SecurityData securityData;
    address minter;
    address to;
    uint256 tokenId;
    bytes data;
  }

  bytes32 private constant _MINT_ERC721_TYPEHASH =
    keccak256(
      bytes(
        "MintERC721Data(SecurityData securityData,address minter,address to,uint256 tokenId,bytes data)SecurityData(uint256 validFrom,uint256 validTo,uint256 salt)"
      )
    );

  function hashStruct(MintERC721Data memory mintERC721Data) internal pure returns (bytes32) {
    return
      keccak256(
        abi.encode(
          _MINT_ERC721_TYPEHASH,
          SecurityLib.hashStruct(mintERC721Data.securityData),
          mintERC721Data.minter,
          mintERC721Data.to,
          mintERC721Data.tokenId,
          keccak256(mintERC721Data.data)
        )
      );
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library SecurityLib {
  struct SecurityData {
    uint256 validFrom;
    uint256 validTo;
    uint256 salt;
  }

  bytes32 private constant _SECURITY_TYPEHASH =
    keccak256(abi.encodePacked("SecurityData(uint256 validFrom,uint256 validTo,uint256 salt)"));

  function validate(SecurityData memory securityData) internal view returns (bool, string memory) {
    if (securityData.validFrom > block.timestamp) {
      return (false, "SecurityLib: valid from verification failed");
    }

    if (securityData.validTo < block.timestamp) {
      return (false, "SecurityLib: valid to verification failed");
    }
    return (true, "");
  }

  function hashStruct(SecurityData memory securityData) internal pure returns (bytes32) {
    return keccak256(abi.encode(_SECURITY_TYPEHASH, securityData.validFrom, securityData.validTo, securityData.salt));
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/metatx/ERC2771ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";

import "../interfaces/IChocoMintERC721.sol";

import "../utils/AdminController.sol";
import "../utils/DefaultApproval.sol";
import "../utils/FreezableProvenance.sol";
import "../utils/FreezableRoot.sol";
import "../utils/FreezableTokenURI.sol";
import "../utils/FreezableRoyalty.sol";
import "../utils/TotalSupply.sol";
import "../utils/TxValidatable.sol";

abstract contract ChocoMintERC721Base is
  Initializable,
  ContextUpgradeable,
  EIP712Upgradeable,
  ERC2771ContextUpgradeable,
  ERC721Upgradeable,
  ERC721BurnableUpgradeable,
  AdminController,
  DefaultApproval,
  FreezableProvenance,
  FreezableRoot,
  FreezableTokenURI,
  FreezableRoyalty,
  TotalSupply,
  TxValidatable
{
  function freezeProvenance() external onlyAdminOrOwner {
    _freezeProvenance();
  }

  function setProvenance(string memory _provenance, bool freezing) external onlyAdminOrOwner {
    _setProvenance(_provenance, freezing);
  }

  function freezeRoot() external onlyAdminOrOwner {
    _freezeRoot();
  }

  function setRoot(bytes32 _root, bool freezing) external onlyAdminOrOwner {
    _setRoot(_root, freezing);
  }

  function freezeTokenURI() external onlyAdminOrOwner {
    _freezeAllTokenStaticURI();
    _freezeTokenURIBase();
  }

  function freezeAllTokenStaticURI() external onlyAdminOrOwner {
    _freezeAllTokenStaticURI();
  }

  function freezeTokenStaticURI(uint256 tokenId) external onlyAdminOrOwner {
    _freezeTokenStaticURI(tokenId);
  }

  function freezeTokenURIBase() external onlyAdminOrOwner {
    _freezeTokenURIBase();
  }

  function setTokenStaticURI(
    uint256 tokenId,
    string memory tokenStaticURI,
    bool freezing
  ) external onlyAdminOrOwner {
    _setTokenStaticURI(tokenId, tokenStaticURI, freezing);
  }

  function setTokenURIBase(string memory tokenURIBase, bool freezing) external onlyAdminOrOwner {
    _setTokenURIBase(tokenURIBase, freezing);
  }

  function freezeRoyalty() external onlyAdminOrOwner {
    _freezeAllTokenRoyalty();
    _freezeDefaultRoyalty();
  }

  function freezeAllTokenRoyalty() external onlyAdminOrOwner {
    _freezeAllTokenRoyalty();
  }

  function freezeDefaultRoyalty() external onlyAdminOrOwner {
    _freezeDefaultRoyalty();
  }

  function freezeTokenRoyalty(uint256 tokenId) external onlyAdminOrOwner {
    _freezeTokenRoyalty(tokenId);
  }

  function setTokenRoyalty(
    uint256 tokenId,
    RoyaltyLib.RoyaltyData memory royaltyData,
    bool freezing
  ) external onlyAdminOrOwner {
    _setTokenRoyalty(tokenId, royaltyData, freezing);
  }

  function setDefaultRoyalty(RoyaltyLib.RoyaltyData memory royaltyData, bool freezing) external onlyAdminOrOwner {
    _setDefaultRoyalty(royaltyData, freezing);
  }

  function initialize(
    string memory name,
    string memory version,
    string memory symbol,
    address trustedForwarder,
    address[] memory defaultApprovals
  ) public initializer {
    __Ownable_init_unchained();
    __EIP712_init_unchained(name, version);
    __ERC721_init_unchained(name, symbol);
    __ERC2771Context_init_unchained(trustedForwarder);
    for (uint256 i = 0; i < defaultApprovals.length; i++) {
      _setDefaultApproval(defaultApprovals[i], true);
    }
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC721Upgradeable, FreezableRoyalty)
    returns (bool)
  {
    return interfaceId == type(IChocoMintERC721).interfaceId || super.supportsInterface(interfaceId);
  }

  function isApprovedForAll(address owner, address operator)
    public
    view
    virtual
    override(ERC721Upgradeable, DefaultApproval)
    returns (bool)
  {
    return super.isApprovedForAll(owner, operator);
  }

  function tokenURI(uint256 tokenId)
    public
    view
    override(ERC721Upgradeable, FreezableTokenURI)
    returns (string memory)
  {
    return super.tokenURI(tokenId);
  }

  function _mint(address to, uint256 tokenId) internal virtual override(ERC721Upgradeable, TotalSupply) {
    super._mint(to, tokenId);
  }

  function _burn(uint256 tokenId)
    internal
    virtual
    override(ERC721Upgradeable, FreezableRoyalty, FreezableTokenURI, TotalSupply)
  {
    super._burn(tokenId);
  }

  function _msgSender() internal view override(ContextUpgradeable, ERC2771ContextUpgradeable) returns (address) {
    return super._msgSender();
  }

  function _msgData() internal view override(ContextUpgradeable, ERC2771ContextUpgradeable) returns (bytes memory) {
    return super._msgData();
  }

  function _baseURI() internal view virtual override(ERC721Upgradeable, FreezableTokenURI) returns (string memory) {
    return super._baseURI();
  }

  function _isApprovedOrOwner(address spender, uint256 tokenId)
    internal
    view
    virtual
    override(ERC721Upgradeable, DefaultApproval)
    returns (bool)
  {
    return super._isApprovedOrOwner(spender, tokenId);
  }

  // solhint-disable-next-line ordering
  uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library SignatureLib {
  struct SignatureData {
    bytes32 root;
    bytes32[] proof;
    bytes signature;
  }

  bytes32 private constant _SIGNATURE_DATA_TYPEHASH = keccak256(bytes("SignatureData(bytes32 root)"));

  function hashStruct(SignatureData memory signatureData) internal pure returns (bytes32) {
    return keccak256(abi.encode(_SIGNATURE_DATA_TYPEHASH, signatureData.root));
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Context variant with ERC2771 support.
 */
abstract contract ERC2771ContextUpgradeable is Initializable, ContextUpgradeable {
    address private _trustedForwarder;

    function __ERC2771Context_init(address trustedForwarder) internal initializer {
        __Context_init_unchained();
        __ERC2771Context_init_unchained(trustedForwarder);
    }

    function __ERC2771Context_init_unchained(address trustedForwarder) internal initializer {
        _trustedForwarder = trustedForwarder;
    }

    function isTrustedForwarder(address forwarder) public view virtual returns (bool) {
        return forwarder == _trustedForwarder;
    }

    function _msgSender() internal view virtual override returns (address sender) {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return super._msgSender();
        }
    }

    function _msgData() internal view virtual override returns (bytes calldata) {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return super._msgData();
        }
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;

import "./IERC721Upgradeable.sol";
import "./IERC721ReceiverUpgradeable.sol";
import "./extensions/IERC721MetadataUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../utils/StringsUpgradeable.sol";
import "../../utils/introspection/ERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721Upgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC721Upgradeable, IERC721MetadataUpgradeable {
    using AddressUpgradeable for address;
    using StringsUpgradeable for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    function __ERC721_init(string memory name_, string memory symbol_) internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __ERC721_init_unchained(name_, symbol_);
    }

    function __ERC721_init_unchained(string memory name_, string memory symbol_) internal initializer {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return
            interfaceId == type(IERC721Upgradeable).interfaceId ||
            interfaceId == type(IERC721MetadataUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
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
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
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
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
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
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

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
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
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
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
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

        _balances[to] += 1;
        _owners[tokenId] = to;

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

        _balances[owner] -= 1;
        delete _owners[tokenId];

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
        require(ERC721Upgradeable.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
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
            try IERC721ReceiverUpgradeable(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
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

pragma solidity ^0.8.0;

import "../ERC721Upgradeable.sol";
import "../../../utils/ContextUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @title ERC721 Burnable Token
 * @dev ERC721 Token that can be irreversibly burned (destroyed).
 */
abstract contract ERC721BurnableUpgradeable is Initializable, ContextUpgradeable, ERC721Upgradeable {
    function __ERC721Burnable_init() internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __ERC721Burnable_init_unchained();
    }

    function __ERC721Burnable_init_unchained() internal initializer {
    }
    /**
     * @dev Burns `tokenId`. See {ERC721-_burn}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function burn(uint256 tokenId) public virtual {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721Burnable: caller is not owner nor approved");
        _burn(tokenId);
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;

import "./ECDSAUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712Upgradeable is Initializable {
    /* solhint-disable var-name-mixedcase */
    bytes32 private _HASHED_NAME;
    bytes32 private _HASHED_VERSION;
    bytes32 private constant _TYPE_HASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    function __EIP712_init(string memory name, string memory version) internal initializer {
        __EIP712_init_unchained(name, version);
    }

    function __EIP712_init_unchained(string memory name, string memory version) internal initializer {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        return _buildDomainSeparator(_TYPE_HASH, _EIP712NameHash(), _EIP712VersionHash());
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSAUpgradeable.toTypedDataHash(_domainSeparatorV4(), structHash);
    }

    /**
     * @dev The hash of the name parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712NameHash() internal virtual view returns (bytes32) {
        return _HASHED_NAME;
    }

    /**
     * @dev The hash of the version parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712VersionHash() internal virtual view returns (bytes32) {
        return _HASHED_VERSION;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

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
pragma solidity ^0.8.0;

import "../utils/MintERC721Lib.sol";
import "../utils/SignatureLib.sol";

interface IChocoMintERC721 {
  event Minted(bytes32 indexed mintERC721Hash);

  function mint(MintERC721Lib.MintERC721Data memory mintERC721Data, SignatureLib.SignatureData memory signatureData)
    external;

  function isMinted(uint256 tokenId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";

abstract contract AdminController is ContextUpgradeable, OwnableUpgradeable {
  mapping(address => bool) private _admins;

  event AdminSet(address indexed account, bool indexed status);

  modifier onlyAdmin() {
    address sender = _msgSender();
    (bool isAdminValid, string memory errorAdminMessage) = _validateAdmin(sender);
    require(isAdminValid, errorAdminMessage);
    _;
  }

  modifier onlyAdminOrOwner() {
    address sender = _msgSender();
    (bool isAdminValid, string memory errorAdminMessage) = _validateAdminOrOwner(sender);
    require(isAdminValid, errorAdminMessage);
    _;
  }

  function setAdmin(address account, bool status) external onlyOwner {
    _setAdmin(account, status);
  }

  function renounceAdmin() external onlyAdmin {
    address sender = _msgSender();
    _setAdmin(sender, false);
  }

  function _setAdmin(address account, bool status) internal {
    require(_admins[account] != status, "AdminController: admin already set");
    _admins[account] = status;
    emit AdminSet(account, status);
  }

  function _isAdmin(address account) internal view returns (bool) {
    return _admins[account];
  }

  function _isAdminOrOwner(address account) internal view returns (bool) {
    return owner() == account || _isAdmin(account);
  }

  function _validateAdmin(address account) internal view returns (bool, string memory) {
    if (!_isAdmin(account)) {
      return (false, "AdminController: admin verification failed");
    }
    return (true, "");
  }

  function _validateAdminOrOwner(address account) internal view returns (bool, string memory) {
    if (!_isAdminOrOwner(account)) {
      return (false, "AdminController: admin or owner verification failed");
    }
    return (true, "");
  }

  // solhint-disable-next-line ordering
  uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";

abstract contract DefaultApproval is ERC721Upgradeable {
  mapping(address => bool) private _defaultApprovals;

  event DefaultApprovalSet(address indexed operator, bool indexed status);

  function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
    return _defaultApprovals[operator] || super.isApprovedForAll(owner, operator);
  }

  function _setDefaultApproval(address operator, bool status) internal {
    require(_defaultApprovals[operator] != status, "DefaultApproval: default approval already set");
    _defaultApprovals[operator] = status;
    emit DefaultApprovalSet(operator, status);
  }

  function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual override returns (bool) {
    return _defaultApprovals[spender] || super._isApprovedOrOwner(spender, tokenId);
  }

  // solhint-disable-next-line ordering
  uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract FreezableProvenance {
  string private _provenance;
  bool private _isProvenanceFreezed;

  event ProvenanceFreezed();
  event ProvenanceSet(string provenance);

  modifier whenNotProvenanceFreezed() {
    require(!_isProvenanceFreezed, "FreezableProvenance: provenance already freezed");
    _;
  }

  function provenance() public view returns (string memory) {
    return _provenance;
  }

  function _freezeProvenance() internal whenNotProvenanceFreezed {
    _isProvenanceFreezed = true;
    emit ProvenanceFreezed();
  }

  function _setProvenance(string memory provenance_, bool freezing) internal whenNotProvenanceFreezed {
    _provenance = provenance_;
    emit ProvenanceSet(provenance_);
    if (freezing) {
      _freezeProvenance();
    }
  }

  // solhint-disable-next-line ordering
  uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract FreezableRoot {
  bytes32 private _root;
  bool private _isRootFreezed;

  event RootFreezed();
  event RootSet(bytes32 root);

  modifier whenNotRootFreezed() {
    require(!_isRootFreezed, "FreezableRoot: root already freezed");
    _;
  }

  function root() public view returns (bytes32) {
    return _root;
  }

  function _freezeRoot() internal whenNotRootFreezed {
    _isRootFreezed = true;
    emit RootFreezed();
  }

  function _setRoot(bytes32 root_, bool freezing) internal whenNotRootFreezed {
    _root = root_;
    emit RootSet(root_);
    if (freezing) {
      _freezeRoot();
    }
  }

  function _validateRoot(bytes32 root_) internal view returns (bool, string memory) {
    if (_root != bytes32(0x0) && _root != root_) {
      return (false, "FreezableRoot: root verification failed");
    }
    return (true, "");
  }

  // solhint-disable-next-line ordering
  uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";

abstract contract FreezableTokenURI is ERC721Upgradeable {
  mapping(uint256 => string) private _tokenStaticURIs;
  mapping(uint256 => bool) private _isTokenStaticURIFreezed;
  bool private _isAllTokenStaticURIFreezed;
  bool private _isTokenURIBaseFreezed;
  string private _tokenURIBase;

  event AllTokenStaticURIFreezed();
  event TokenStaticURIFreezed(uint256 tokenId);
  event TokenStaticURIDefrosted(uint256 tokenId);
  event TokenStaticURISet(uint256 indexed tokenId, string tokenStaticURI);
  event TokenURIBaseFreezed();
  event TokenURIBaseSet(string tokenURIBase);

  modifier whenNotAllTokenStaticURIFreezed() {
    require(!_isAllTokenStaticURIFreezed, "FreezableTokenURI: all token static URI already freezed");
    _;
  }

  modifier whenNotTokenStaticURIFreezed(uint256 tokenId) {
    require(!_isTokenStaticURIFreezed[tokenId], "FreezableTokenURI: token static URI already freezed");
    _;
  }

  modifier whenNotTokenURIBaseFreezed() {
    require(!_isTokenURIBaseFreezed, "FreezableTokenURI: token URI base already freezed");
    _;
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), "FreezableTokenURI: URI query for nonexistent token");
    string memory _tokenStaticURI = _tokenStaticURIs[tokenId];
    if (bytes(_tokenStaticURI).length > 0) {
      return _tokenStaticURI;
    }
    return super.tokenURI(tokenId);
  }

  function _freezeAllTokenStaticURI() internal whenNotAllTokenStaticURIFreezed {
    _isAllTokenStaticURIFreezed = true;
    emit AllTokenStaticURIFreezed();
  }

  function _freezeTokenStaticURI(uint256 tokenId)
    internal
    whenNotAllTokenStaticURIFreezed
    whenNotTokenStaticURIFreezed(tokenId)
  {
    require(_exists(tokenId), "FreezableTokenURI: URI freeze for nonexistent token");
    _isTokenStaticURIFreezed[tokenId] = true;
    emit TokenStaticURIFreezed(tokenId);
  }

  function _setTokenStaticURI(
    uint256 tokenId,
    string memory _tokenStaticURI,
    bool freezing
  ) internal whenNotAllTokenStaticURIFreezed whenNotTokenStaticURIFreezed(tokenId) {
    require(_exists(tokenId), "FreezableTokenURI: URI set for nonexistent token");
    _tokenStaticURIs[tokenId] = _tokenStaticURI;
    emit TokenStaticURISet(tokenId, string(_tokenStaticURI));
    if (freezing) {
      _freezeTokenStaticURI(tokenId);
    }
  }

  function _freezeTokenURIBase() internal whenNotTokenURIBaseFreezed {
    _isTokenURIBaseFreezed = true;
    emit TokenURIBaseFreezed();
  }

  function _setTokenURIBase(string memory tokenURIBase, bool freezing) internal whenNotTokenURIBaseFreezed {
    _tokenURIBase = tokenURIBase;
    emit TokenURIBaseSet(tokenURIBase);
    if (freezing) {
      _freezeTokenURIBase();
    }
  }

  function _burn(uint256 tokenId) internal virtual override {
    super._burn(tokenId);
    if (bytes(_tokenStaticURIs[tokenId]).length > 0) {
      delete _tokenStaticURIs[tokenId];
      emit TokenStaticURISet(tokenId, "");
      if (_isTokenStaticURIFreezed[tokenId]) {
        _isTokenStaticURIFreezed[tokenId] = false;
        emit TokenStaticURIDefrosted(tokenId);
      }
    }
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return _tokenURIBase;
  }

  // solhint-disable-next-line ordering
  uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "../interfaces/IERC2981.sol";

import "./RoyaltyLib.sol";

contract FreezableRoyalty is ERC721Upgradeable, IERC2981 {
  mapping(uint256 => RoyaltyLib.RoyaltyData) private _tokenRoyalties;
  mapping(uint256 => bool) private _isTokenRoyaltyFreezed;

  RoyaltyLib.RoyaltyData private _defaultRoyalty;

  bool private _isAllTokenRoyaltyFreezed;
  bool private _isDefaultRoyaltyFreezed;

  event AllTokenRoyaltyFreezed();
  event TokenRoyaltyFreezed(uint256 tokenId);
  event TokenRoyaltyDefrosted(uint256 tokenId);
  event TokenRoyaltySet(uint256 tokenId, address recipient, uint256 bps);
  event DefaultRoyaltyFreezed();
  event DefaultRoyaltySet(address recipient, uint256 bps);

  modifier requireValidRoyalty(RoyaltyLib.RoyaltyData memory royaltyData) {
    (bool isValid, string memory errorMessage) = RoyaltyLib.validate(royaltyData);
    require(isValid, errorMessage);
    _;
  }

  modifier whenNotAllTokenRoyaltyFreezed() {
    require(!_isAllTokenRoyaltyFreezed, "FreezableRoyalty: all token royalty already freezed");
    _;
  }

  modifier whenNotTokenRoyaltyFreezed(uint256 tokenId) {
    require(!_isTokenRoyaltyFreezed[tokenId], "FreezableRoyalty: token royalty already freezed");
    _;
  }

  modifier whenNotDefaultRoyaltyFreezed() {
    require(!_isDefaultRoyaltyFreezed, "FreezableRoyalty: default royalty already freezed");
    _;
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
    return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
  }

  function royaltyInfo(uint256 tokenId, uint256 salePrice) public view override returns (address, uint256) {
    require(_exists(tokenId), "FreezableRoyalty: royalty query for nonexistent token");
    if (RoyaltyLib.isNotNull(_tokenRoyalties[tokenId])) {
      return (_tokenRoyalties[tokenId].recipient, RoyaltyLib.calc(salePrice, _tokenRoyalties[tokenId].bps));
    }
    if (RoyaltyLib.isNotNull(_defaultRoyalty)) {
      return (_defaultRoyalty.recipient, RoyaltyLib.calc(salePrice, _defaultRoyalty.bps));
    }
    return (address(0x0), 0);
  }

  function _freezeAllTokenRoyalty() internal whenNotAllTokenRoyaltyFreezed {
    _isAllTokenRoyaltyFreezed = true;
    emit AllTokenRoyaltyFreezed();
  }

  function _freezeTokenRoyalty(uint256 tokenId)
    internal
    whenNotAllTokenRoyaltyFreezed
    whenNotTokenRoyaltyFreezed(tokenId)
  {
    require(_exists(tokenId), "FreezableRoyalty: royalty freeze for nonexistent token");
    _isTokenRoyaltyFreezed[tokenId] = true;
    emit TokenRoyaltyFreezed(tokenId);
  }

  function _freezeDefaultRoyalty() internal whenNotDefaultRoyaltyFreezed {
    _isDefaultRoyaltyFreezed = true;
    emit DefaultRoyaltyFreezed();
  }

  function _setTokenRoyalty(
    uint256 tokenId,
    RoyaltyLib.RoyaltyData memory royaltyData,
    bool freezing
  ) internal whenNotAllTokenRoyaltyFreezed whenNotTokenRoyaltyFreezed(tokenId) requireValidRoyalty(royaltyData) {
    require(_exists(tokenId), "FreezableRoyalty: royalty set for nonexistent token");
    _tokenRoyalties[tokenId] = royaltyData;
    emit TokenRoyaltySet(tokenId, royaltyData.recipient, royaltyData.bps);
    if (freezing) {
      _freezeTokenRoyalty(tokenId);
    }
  }

  function _setDefaultRoyalty(RoyaltyLib.RoyaltyData memory royaltyData, bool freezing)
    internal
    whenNotDefaultRoyaltyFreezed
    requireValidRoyalty(royaltyData)
  {
    _defaultRoyalty = royaltyData;
    emit DefaultRoyaltySet(royaltyData.recipient, royaltyData.bps);
    if (freezing) {
      _freezeDefaultRoyalty();
    }
  }

  function _burn(uint256 tokenId) internal virtual override {
    super._burn(tokenId);
    if (RoyaltyLib.isNotNull(_tokenRoyalties[tokenId])) {
      delete _tokenRoyalties[tokenId];
      emit TokenRoyaltySet(tokenId, address(0x0), 0);
      if (_isTokenRoyaltyFreezed[tokenId]) {
        _isTokenRoyaltyFreezed[tokenId] = false;
        emit TokenRoyaltyDefrosted(tokenId);
      }
    }
  }

  // solhint-disable-next-line ordering
  uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";

abstract contract TotalSupply is ERC721Upgradeable {
  uint256 private _totalSupply;

  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }

  function _mint(address to, uint256 tokenId) internal virtual override {
    super._mint(to, tokenId);
    _totalSupply++;
  }

  function _burn(uint256 tokenId) internal virtual override {
    super._burn(tokenId);
    _totalSupply--;
  }

  // solhint-disable-next-line ordering
  uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/SignatureCheckerUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";

import "./FreezableRoot.sol";
import "./Revocable.sol";
import "./SignatureLib.sol";

abstract contract TxValidatable is ContextUpgradeable, EIP712Upgradeable, FreezableRoot, Revocable {
  using MerkleProofUpgradeable for bytes32[];
  using SignatureCheckerUpgradeable for address;

  function _validateTx(
    address signer,
    bytes32 hash,
    SignatureLib.SignatureData memory signatureData
  ) internal view returns (bool, string memory) {
    (bool isHashValid, string memory hashErrorMessage) = _validateHash(hash);
    if (!isHashValid) {
      return (false, hashErrorMessage);
    }
    (bool isRootValid, string memory rootErrorMessage) = _validateRoot(signatureData.root);
    if (!isRootValid) {
      return (false, rootErrorMessage);
    }

    if (!signatureData.proof.verify(signatureData.root, hash)) {
      return (false, "TxValidatable: proof verification failed");
    }

    if (signatureData.signature.length == 0) {
      address sender = _msgSender();
      if (signer != sender) {
        return (false, "TxValidatable: sender verification failed");
      }
    } else {
      if (
        !signer.isValidSignatureNow(_hashTypedDataV4(SignatureLib.hashStruct(signatureData)), signatureData.signature)
      ) {
        if (!signer.isValidSignatureNow(_hashTypedDataV4(hash), signatureData.signature)) {
          return (false, "TxValidatable: signature verification failed");
        }
      }
    }
    return (true, "");
  }

  // solhint-disable-next-line ordering
  uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSAUpgradeable {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC2981 {
  function royaltyInfo(uint256 tokenId, uint256 value) external view returns (address, uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SecurityLib.sol";
import "./HashLib.sol";

library RoyaltyLib {
  struct RoyaltyData {
    address recipient;
    uint256 bps;
  }

  uint256 private constant _BPS_BASE = 10000;

  bytes32 private constant _ROYALTY_TYPEHASH = keccak256(bytes("RoyaltyData(address recipient,uint256 bps)"));

  function hashStruct(RoyaltyData memory royaltyData) internal pure returns (bytes32) {
    return keccak256(abi.encode(_ROYALTY_TYPEHASH, royaltyData.recipient, royaltyData.bps));
  }

  function validate(RoyaltyData memory royaltyData) internal pure returns (bool, string memory) {
    if (royaltyData.recipient == address(0x0)) {
      return (false, "RoyaltyLib: recipient verification failed");
    }

    if (royaltyData.bps == 0 || royaltyData.bps > _BPS_BASE) {
      return (false, "RoyaltyLib: bps verification failed");
    }

    return (true, "");
  }

  function calc(uint256 salePrice, uint256 bps) internal pure returns (uint256) {
    return (salePrice * bps) / _BPS_BASE;
  }

  function isNotNull(RoyaltyLib.RoyaltyData memory royaltyData) internal pure returns (bool) {
    return (royaltyData.recipient != address(0x0) && royaltyData.bps != 0);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library HashLib {
  function hashBytesArray(bytes[] memory data) internal pure returns (bytes32) {
    uint256 length = data.length;
    bytes32[] memory result = new bytes32[](length);
    for (uint256 i = 0; i < length; i++) {
      result[i] = keccak256(abi.encodePacked(data[i]));
    }
    return keccak256(abi.encodePacked(result));
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 */
library MerkleProofUpgradeable {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }

        // Check if the computed hash (root) is equal to the provided root
        return computedHash == root;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ECDSAUpgradeable.sol";
import "../AddressUpgradeable.sol";
import "../../interfaces/IERC1271Upgradeable.sol";

/**
 * @dev Signature verification helper: Provide a single mechanism to verify both private-key (EOA) ECDSA signature and
 * ERC1271 contract sigantures. Using this instead of ECDSA.recover in your contract will make them compatible with
 * smart contract wallets such as Argent and Gnosis.
 *
 * Note: unlike ECDSA signatures, contract signature's are revocable, and the outcome of this function can thus change
 * through time. It could return true at block N and false at block N+1 (or the opposite).
 *
 * _Available since v4.1._
 */
library SignatureCheckerUpgradeable {
    function isValidSignatureNow(
        address signer,
        bytes32 hash,
        bytes memory signature
    ) internal view returns (bool) {
        (address recovered, ECDSAUpgradeable.RecoverError error) = ECDSAUpgradeable.tryRecover(hash, signature);
        if (error == ECDSAUpgradeable.RecoverError.NoError && recovered == signer) {
            return true;
        }

        (bool success, bytes memory result) = signer.staticcall(
            abi.encodeWithSelector(IERC1271Upgradeable.isValidSignature.selector, hash, signature)
        );
        return (success && result.length == 32 && abi.decode(result, (bytes4)) == IERC1271Upgradeable.isValidSignature.selector);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Revocable {
  mapping(bytes32 => bool) private _isRevoked;

  function _revokeHash(bytes32 hash) internal {
    require(!_isRevoked[hash], "Revocable: hash verification failed");
    _isRevoked[hash] = true;
  }

  function _validateHash(bytes32 hash) internal view returns (bool, string memory) {
    if (_isRevoked[hash]) {
      return (false, "Revocable: hash verification failed");
    }
    return (true, "");
  }

  // solhint-disable-next-line ordering
  uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC1271 standard signature validation method for
 * contracts as defined in https://eips.ethereum.org/EIPS/eip-1271[ERC-1271].
 *
 * _Available since v4.1._
 */
interface IERC1271Upgradeable {
    /**
     * @dev Should return whether the signature provided is valid for the provided data
     * @param hash      Hash of the data to be signed
     * @param signature Signature byte array associated with _data
     */
    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4 magicValue);
}