// SPDX-License-Identifier: Toknify.com
pragma solidity ^0.8.0;
import "./Context.sol";
import "./AccessControlEnumerable.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";
import "./ERC721Pausable.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Counters.sol";
contract Toknify is Context, AccessControlEnumerable, ERC721Enumerable, ERC721Burnable, ERC721Pausable, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    Counters.Counter private _tokenIdTracker;
    string private _baseTokenURI;
    constructor(string memory name, string memory symbol, string memory baseTokenURI) ERC721(name, symbol) {
        _baseTokenURI = baseTokenURI;
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, _msgSender());
    }
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }
    function setBaseURI(string calldata newBaseTokenURI) public {
        _baseTokenURI = newBaseTokenURI;
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Toknify: must have ADMIN ROLE");
    }
    function exists(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }
    function pause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "Toknify: must have pauser role to pause");
        _pause();
    }
    function unpause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "Toknify: must have pauser role to unpause");
        _unpause();
    }
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override(ERC721, ERC721Enumerable, ERC721Pausable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }
    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControlEnumerable, ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
    string public constant TOKNIFY_PROVENANCE = "toknify";
    uint256 public startingIndexBlock;
    uint256 public startingIndex;
    mapping (uint256 => bool) private _mintedBeforeReveal;
    function isMintedBeforeReveal(uint256 index) public view returns (bool) {
        return _mintedBeforeReveal[index];
    }
    function mint(address _to, string memory tokenURI_) public virtual {
        require(hasRole(MINTER_ROLE, _msgSender()), "Toknify: must have minter role to mint");
        _mint(_to, _tokenIdTracker.current());
        _setTokenURI(_tokenIdTracker.current(), tokenURI_);
        _tokenIdTracker.increment();
    }
    function mintToknify(address _to, uint256 tokenId, string memory tokenURI_) public virtual {
        require(hasRole(MINTER_ROLE, _msgSender()), "Toknify: must have minter role to mint");
        require(tokenId > 10000000000, "Toknify: ToknifyID must be over 10,000,000,000");
        _mint(_to, tokenId);
        _setTokenURI(tokenId, tokenURI_);
    }
    mapping (uint256 => string) private _tokenURIs;
        function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }
    function setTokenURI(uint256 tokenId, string memory _tokenURI) public {
        _setTokenURI(tokenId, _tokenURI);
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
    }
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }
        return string(abi.encodePacked(base, tokenId));
    }
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);
        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
}