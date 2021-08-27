// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./Ownable.sol";

/**
 * @title UglyAssChickGang contract
 */
contract UglyAssChickGang is ERC721Enumerable, ERC721URIStorage, Ownable {
    string public PROVENANCE_HASH = "";
    uint256 public MAX_CHICKS;
    uint256 public OFFSET_VALUE;
    bool public METADATA_FROZEN;
    bool public PROVENANCE_FROZEN;

    string public baseUri;
    bool public saleIsActive;
    uint256 public mintPrice;
    uint256 public maxPerMint;

    event SetBaseUri(string indexed baseUri);

    modifier whenSaleActive {
        require(saleIsActive, "Ugly Ass Chick Gang: Sale is not active");
        _;
    }

    modifier whenMetadataNotFrozen {
        require(!METADATA_FROZEN, "Ugly Ass Chick Gang: Metadata already frozen.");
        _;
    }

    modifier whenProvenanceNotFrozen {
        require(!PROVENANCE_FROZEN, "Ugly Ass Chick Gang: Provenance already frozen.");
        _;
    }

    constructor() ERC721("Ugly Ass Chick Gang", "CHICK") {
        saleIsActive = false;
        MAX_CHICKS = 8888;
        mintPrice = 80000000000000000; // 0.08 ETH
        maxPerMint = 100;
        METADATA_FROZEN = false;
        PROVENANCE_FROZEN = false;
    }

    // ------------------
    // Explicit overrides
    // ------------------

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal virtual override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId) public view virtual override(ERC721URIStorage, ERC721) returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return baseUri;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseUri;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Enumerable, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    // ------------------
    // Utility view functions
    // ------------------

    function exists(uint256 _tokenId) public view returns (bool) {
        return _exists(_tokenId);
    }

    // ------------------
    // Functions for external minting
    // ------------------

    function mintChicks(uint256 amount) external payable whenSaleActive {
        require(amount <= maxPerMint, "UglyAssChickens: Amount exceeds max per mint");
        require(totalSupply() + amount <= MAX_CHICKS, "UglyAssChickens: Purchase would exceed cap");
        require(mintPrice * amount <= msg.value, "UglyAssChickens: Ether value sent is not correct");

        for(uint256 i = 0; i < amount; i++) {
            uint256 mintIndex = totalSupply() + 1;
            if (totalSupply() < MAX_CHICKS) {
                _safeMint(msg.sender, mintIndex);
            }
        }
    }

    // ------------------
    // Functions for the owner
    // ------------------

    function setMaxPerMint(uint256 _maxPerMint) external onlyOwner {
        maxPerMint = _maxPerMint;
    }

    function setMintPrice(uint256 _mintPrice) external onlyOwner {
        mintPrice = _mintPrice;
    }

    function setBaseUri(string memory _baseUri) external onlyOwner whenMetadataNotFrozen {
        baseUri = _baseUri;
        emit SetBaseUri(baseUri);
    }

    function setTokenURI(uint256 tokenId, string memory _tokenURI) external onlyOwner whenMetadataNotFrozen {
        super._setTokenURI(tokenId, _tokenURI);
    }

    function mintForCommunity(address _to, uint256 _numberOfTokens) external onlyOwner {
        require(_to != address(0), "UglyAssChickens: Cannot mint to zero address.");
        require(totalSupply() + _numberOfTokens <= MAX_CHICKS, "UglyAssChickens: Minting would exceed cap");

        for(uint256 i = 0; i < _numberOfTokens; i++) {
            uint256 mintIndex = totalSupply() + 1;
            if (totalSupply() < MAX_CHICKS) {
                _safeMint(_to, mintIndex);
            }
        }
    }

    function setProvenanceHash(string memory _provenanceHash) external onlyOwner whenProvenanceNotFrozen {
        PROVENANCE_HASH = _provenanceHash;
    }

    function setOffsetValue(uint256 _offsetValue) external onlyOwner {
        OFFSET_VALUE = _offsetValue;
    }

    function toggleSaleState() external onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function freezeMetadata() external onlyOwner whenMetadataNotFrozen {
        METADATA_FROZEN = true;
    }

    function freezeProvenance() external onlyOwner whenProvenanceNotFrozen {
        PROVENANCE_FROZEN = true;
    }

    // ------------------
    // Utility function for getting the tokens of a certain address
    // ------------------

    function tokensOfOwner(address _owner) external view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            for (uint256 index; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }
}