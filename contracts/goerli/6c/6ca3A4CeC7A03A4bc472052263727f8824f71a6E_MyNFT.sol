// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract MyNFT is ERC721Enumerable, Ownable {
    mapping(address => bool) private miners;

    uint256 public immutable maxSupply;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    modifier onlyMiner {
        require(miners[msg.sender], "Caller is not the miner");
        _;
    }

    constructor (
        string memory _name,
        string memory _symbol,
        uint256 _maxSupply
    ) ERC721(_name, _symbol) Ownable() {
        maxSupply = _maxSupply;
    }

    function setMiner(address _address, bool _isAllow) public onlyOwner {
        miners[_address] = _isAllow;
    }

    function safeMint(address to, uint256 tokenId, string memory _tokenURI) public onlyMiner {
        require(totalSupply() < maxSupply, "NFT: Total supply reached");
        super._safeMint(to, tokenId);
        _setTokenURI(tokenId, _tokenURI);
    }

    function mint(address to, uint256 tokenId, string memory _tokenURI) public onlyMiner {
        require(totalSupply() < maxSupply, "NFT: Total supply reached");
        super._mint(to, tokenId);
        _setTokenURI(tokenId, _tokenURI);
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "NFT: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "NFT: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

}