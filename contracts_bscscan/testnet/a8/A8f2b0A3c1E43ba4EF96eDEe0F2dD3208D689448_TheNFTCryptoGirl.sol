pragma solidity 0.6.12;

import "./ERC721.sol";

contract TheNFTCryptoGirl is ERC721 {
    uint256 tokenCount;

    constructor() ERC721("CryptoGirl.finance | NFT", "CGNFT") public {

    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return "https://adsasdasdssadadas/asdasdsa";
    }

    function mintNFT(address to) public {
        tokenCount += 1;
        _mint(to, tokenCount);
    }

    function getRandom() private view returns (uint) {
        return block.timestamp % 10;
    }

    function seeRandom() external view returns (uint256) {
        return getRandom();
    }

}