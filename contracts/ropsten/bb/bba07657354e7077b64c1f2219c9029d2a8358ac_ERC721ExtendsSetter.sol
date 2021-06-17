pragma solidity ^0.6.2;
pragma experimental ABIEncoderV2;

import "./ERC721PresetMinterPauserAutoId.sol";

contract ERC721ExtendsSetter is ERC721PresetMinterPauserAutoId {

    bytes32 public constant SETTER_ROLE = keccak256("SETTER_ROLE");

    mapping(uint256 => string) private _tokenTitles;
    mapping(uint256 => string) private _tokenArtists;

    constructor() public
    ERC721PresetMinterPauserAutoId("NgNFT Test4", "NgNFT04", "") {
        _setupRole(SETTER_ROLE, _msgSender());
    }

    function setTokenTitle(uint256 tokenId, string memory title) public virtual {
        require(hasRole(SETTER_ROLE, _msgSender()), "ERC721ExtendsSetter: must have setter role to set");
        _setTokenTitle(tokenId, title);
    }

    function tokenTitle(uint256 tokenId) public view virtual returns (string memory) {
        require(_exists(tokenId), "ERC721ExtendsSetter: Title query for nonexistent token");
        return _tokenTitles[tokenId];
    }

    function setTokenArtist(uint256 tokenId, string memory artist) public virtual {
        require(hasRole(SETTER_ROLE, _msgSender()), "ERC721ExtendsSetter: must have setter role to set");
        _setTokenArtist(tokenId, artist);
    }

    function tokenArtist(uint256 tokenId) public view virtual returns (string memory) {
        require(_exists(tokenId), "ERC721ExtendsSetter: Artist query for nonexistent token");
        return _tokenArtists[tokenId];
    }

    function setTokenURI(uint256 tokenId, string memory tokenURI) public virtual {
        require(hasRole(SETTER_ROLE, _msgSender()), "ERC721ExtendsSetter: must have setter role to set");
        _setTokenURI(tokenId, tokenURI);
    }

    function setBatchTokenURI(uint256[] memory tokenIds, string[] memory tokenURIs) public virtual {
        require(hasRole(SETTER_ROLE, _msgSender()), "ERC721ExtendsSetter: must have setter role to set");
        require(tokenIds.length == tokenURIs.length, "ERC721ExtendsSetter: tokenIds length and tokenURIs length mismatch");

        for (uint i = 0; i < tokenIds.length; i++) {
            _setTokenURI(tokenIds[i], tokenURIs[i]);
        }
    }

    function setBaseURI(string memory baseURI) public virtual {
        require(hasRole(SETTER_ROLE, _msgSender()), "ERC721ExtendsSetter: must have setter role to set");
        _setBaseURI(baseURI);
    }

    function _setTokenTitle(uint256 tokenId, string memory _title) internal virtual {
        require(_exists(tokenId), "ERC721ExtendsSetter: Title set of nonexistent token");
        _tokenTitles[tokenId] = _title;
    }

    function _setTokenArtist(uint256 tokenId, string memory _artist) internal virtual {
        require(_exists(tokenId), "ERC721ExtendsSetter: Artist set of nonexistent token");
        _tokenArtists[tokenId] = _artist;
    }
}