// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";
import "./AccessControlEnumerable.sol";
import "./Ownable.sol";
import "./Context.sol";
import "./Counters.sol";

contract SimpleCollection is
    Context,
    Ownable,
    AccessControlEnumerable,
    ERC721Enumerable,
    ERC721Burnable
{
    using Counters for Counters.Counter;
    using Strings for uint256;

    bytes32 public constant CREATOR_ROLE = keccak256("CREATOR_ROLE");

    Counters.Counter private _tokenIdTracker;

    string private _collectionURI;

    mapping(uint256 => string) private _tokenURIs;

    constructor(
        string memory name,
        string memory symbol,
        string memory uri
    ) ERC721(name, symbol) {
        _collectionURI = uri;

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(CREATOR_ROLE, _msgSender());
    }
    
    /**
     * Returns the URI of this collection
     */
    function collectionURI() public view virtual returns (string memory) {
        return _collectionURI;
    }
    
    /**
     * Set the URI of this collection
     */
    function setCollectionURI(string memory _uri) public virtual {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "SimpleCollection: must have admin role to modify");
        _collectionURI = _uri;
    }

    /**
     * Mint NFT token with tokenURI
     * See {ERC721-_mint}.
     *
     * Requirements:
     * - the caller must have the `CREATOR_ROLE`.
     */
    function mint(address to, string memory _tokenURI) public virtual {
        require(hasRole(CREATOR_ROLE, _msgSender()), "SimpleCollection: must have creator role to mint");

        // Mint
        _mint(to, _tokenIdTracker.current());
        // Add URI to tokenId
        _tokenURIs[_tokenIdTracker.current()] = _tokenURI;
        // Increment the counter
        _tokenIdTracker.increment();
    }
    
    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "SimpleCollection: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        return _tokenURI;
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
    ) internal virtual override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControlEnumerable, ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}