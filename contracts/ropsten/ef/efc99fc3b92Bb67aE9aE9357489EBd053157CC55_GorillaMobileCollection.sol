// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AccessControlEnumerableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ERC721Upgradeable.sol";
import "./ERC721BurnableUpgradeable.sol";
import "./ERC721EnumerableUpgradeable.sol";
import "./ContextUpgradeable.sol";
import "./CountersUpgradeable.sol";

contract GorillaMobileCollection is
    ContextUpgradeable,
    OwnableUpgradeable,
    AccessControlEnumerableUpgradeable,
    ERC721EnumerableUpgradeable,
    ERC721BurnableUpgradeable
{
    using CountersUpgradeable for CountersUpgradeable.Counter;
    using StringsUpgradeable for uint256;

    bytes32 public constant CREATOR_ROLE = keccak256("CREATOR_ROLE");

    CountersUpgradeable.Counter private _tokenIdTracker;
    string private _gorillaMobileURI;
    mapping(uint256 => string) private _tokenURIs;

    /**
     * Initialises the contract
     */
    function initialize(string memory name_, string memory symbol_, string memory uri_) public initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
        __AccessControlEnumerable_init_unchained();
        __ERC721Enumerable_init_unchained();
        __ERC721Burnable_init_unchained();
        __ERC721_init_unchained(name_, symbol_);
        __GorillaMobileCollection_init_unchained(uri_);
    }

    /**
     * Initialises for GorillaMobileCollection
     */
    function __GorillaMobileCollection_init_unchained(string memory uri_) internal initializer {
        _gorillaMobileURI = uri_;

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(CREATOR_ROLE, _msgSender());
    }

    /**
     * Returns the URI of Gorilla Mobile
     */
    function gorillaMobileURI() public view virtual returns (string memory) {
        return _gorillaMobileURI;
    }

    /**
     * Set the URI of Gorilla Mobile collection
     */
    function setGorillaMobileURI(string memory _uri) public virtual {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "GorillaMobileCollection: must have admin role to modify");
        _gorillaMobileURI = _uri;
    }

    /**
     * Mint NFT token with tokenURI
     * See {ERC721-_mint}.
     *
     * Requirements:
     * - the caller must have the `CREATOR_ROLE`.
     */
    function mint(address to, string memory _tokenURI) public virtual {
        require(hasRole(CREATOR_ROLE, _msgSender()), "GorillaMobileCollection: must have creator role to mint");
        uint256 tokenId = _generateTokenId(_tokenURI);
        _mint(to, tokenId);
    }

    /**
     * Safely mint NFT token with tokenURI
     * See {ERC721-_mint}.
     *
     * Requirements:
     * - the caller must have the `CREATOR_ROLE`.
     */
    function safeMint(address to, string memory _tokenURI) public virtual {
        require(hasRole(CREATOR_ROLE, _msgSender()), "GorillaMobileCollection: must have creator role to mint");
        uint256 tokenId = _generateTokenId(_tokenURI);
        _safeMint(to, tokenId);
    }

    /**
     * Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon
     *   a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransfer(address to, uint256 tokenId) public virtual {
        require(_exists(tokenId), "GorillaMobileCollection: transfer for nonexistent token");
        _safeTransfer(_msgSender(), to, tokenId, "");
    }

    /**
     * Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon
     *   a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransfer(address to, uint256 tokenId, bytes memory _data) public virtual {
        require(_exists(tokenId), "GorillaMobileCollection: transfer for nonexistent token");
        _safeTransfer(_msgSender(), to, tokenId, _data);
    }

    /**
     * Generates a token ID and records the given token URI for said token ID.
     */
    function _generateTokenId(string memory _tokenURI) internal virtual returns (uint256) {
        uint256 tokenId = _tokenIdTracker.current();
        _tokenURIs[tokenId] = _tokenURI;
        _tokenIdTracker.increment();
        return tokenId;
    }
    
    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "GorillaMobileCollection: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        return _tokenURI;
    }

    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "GorillaMobileCollection: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override (ERC721Upgradeable, ERC721EnumerableUpgradeable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControlEnumerableUpgradeable, ERC721Upgradeable, ERC721EnumerableUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}