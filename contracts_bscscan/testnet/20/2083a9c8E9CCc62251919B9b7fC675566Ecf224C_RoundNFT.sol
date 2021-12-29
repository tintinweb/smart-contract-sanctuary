// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./Ownable.sol";
import "./Whitelist.sol";

/**
 * @title RoundNFT contract
 */
contract RoundNFT is ERC721Enumerable, ERC721URIStorage, Ownable {
    uint256 public maxRoundNFTs;
    address public incomePoolAddr;
    address public tradeMarketPoolAddr;
    mapping (address => bool) public whitelist;
    uint256 public freeMints;
    uint256 public freeMintEndTime;

    string public baseUri;
    bool public saleIsActive;

    bool public revealed;
    string public unrevealedTokenUri;

    event SetBaseUri(string indexed baseUri);

    modifier whenSaleIsActive() {
        require(saleIsActive, "PRP: Sale is not active");
        _;
    }

    constructor(address _incomePoolAddr,address _tradeMarketPoolAddr,uint256 _freeMintEndTime) ERC721("Round NFT", "ROUND") {
        incomePoolAddr = _incomePoolAddr;
        tradeMarketPoolAddr = _tradeMarketPoolAddr;
        saleIsActive = false;
        maxRoundNFTs = 5000;
        revealed = false;
        freeMints = 0;
        freeMintEndTime = _freeMintEndTime;
        Whitelist.generateWhiteList(whitelist);
    }



    /*Explicit overrides*/

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
        if (revealed) {
            return super.tokenURI(tokenId);
        } else {
            return unrevealedTokenUri;
        }
    }

    function _baseURI() internal view override returns (string memory) {
        return baseUri;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Enumerable, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /*Public functions*/

    function mint(uint256 amount) external payable whenSaleIsActive {
        require(amount <= 50, "ROUND: Amount exceeds max per mint");
        require(totalSupply() + amount <= maxRoundNFTs, "ROUND: Purchase would exceed cap");

        uint256 _mintPrice = 50000000000000000; // 0.05 BNB
        uint256 supplyAfterMint = totalSupply() + amount;

        if (supplyAfterMint > 9000) {
            _mintPrice = 100000000000000000; // 0.1 BNB
        } else if (supplyAfterMint > 6000) {
            _mintPrice = 75000000000000000; // 0.075 BNB
        }

        require(_mintPrice * amount <= msg.value, "PRP: BNB value sent is not correct");
        uint256 mintIndex = totalSupply() + 1;
        for (uint256 i = 0; i < amount; i++) {
            _safeMint(msg.sender, mintIndex);
            mintIndex += 1;
        }
        payable(incomePoolAddr).transfer(amount*3/10);
        payable(tradeMarketPoolAddr).transfer(amount*7/10);

    }

    function mintFree(uint256 amount) external whenSaleIsActive {
        require(freeMints + amount <= 1000, "ROUND: Free to mint limit reached");
        require(whitelist[msg.sender]==true || block.timestamp > freeMintEndTime,"Free mint only open to whitelist");
        require(totalSupply() + amount <= maxRoundNFTs, "ROUND: Mint would exceed cap");
        require(amount <= 3, "ROUND: Only 3 free mints per tx");
        require(balanceOf(msg.sender) + amount <= 3, "ROUND: Only 3 per address");

        uint256 mintIndex = totalSupply() + 1;
        for (uint256 i = 0; i < amount; i++) {
            _safeMint(msg.sender, mintIndex);
            mintIndex += 1;
        }
        freeMints += amount;
    }

    function exists(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }

    function tokensOfOwner(address owner) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(owner);
        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            for (uint256 index; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(owner, index);
            }
            return result;
        }
    }


    /*Owner functions*/

    function setBaseUri(string memory _baseUri) external onlyOwner {
        baseUri = _baseUri;
        emit SetBaseUri(baseUri);
    }

    function setTokenURI(uint256 _tokenId, string memory _tokenURI) external onlyOwner {
        super._setTokenURI(_tokenId, _tokenURI);
    }

    function mintForCommunity(address to, uint256 numberOfTokens) external onlyOwner {
        require(to != address(0), "ROUND: Cannot mint to zero address.");
        require(totalSupply() + numberOfTokens <= maxRoundNFTs, "ROUND: Mint would exceed cap");

        uint256 mintIndex = totalSupply() + 1;
        for (uint256 i = 0; i < numberOfTokens; i++) {
            _safeMint(to, mintIndex);
            mintIndex += 1;
        }
    }

    function reveal() external onlyOwner {
        revealed = true;
    }

    function toggleSaleState() external onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function reduceMaxRoundNFTs(uint256 newMaxRoundNFTs) external onlyOwner {
        require(newMaxRoundNFTs < maxRoundNFTs, "ROUND: Can only be reduced!");
        maxRoundNFTs = newMaxRoundNFTs;
    }
}