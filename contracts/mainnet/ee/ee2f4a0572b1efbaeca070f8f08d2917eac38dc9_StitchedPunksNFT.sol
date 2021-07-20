// SPDX-License-Identifier: MIT

// 2021-07-20 - Release Version

pragma solidity 0.7.6;

// @openzeppelin/contracts/utils/Context.sol introduces execution context to replace msg.sender with _msgSender()
// implement admin role
import "./Ownable.sol";

import "./ERC721.sol";

// interface for interacting with the StitchedPunks shop contract
interface IStitchedPunksShop {
	function updateOrderRedeemNFT(uint16 punkIndex) external;
}

contract StitchedPunksNFT is Ownable, ERC721 {
    constructor() ERC721("StitchedPunksToken", "SPT") {
        _setBaseURI(metadataBaseUri);
    }

    // access to existing StitchedPunksShop contract
	address public stitchedPunksShopAddress = address(0x9f4263370872b44EF46477DC9Bc67ca938e129c6);

    function setStitchedPunksShopAddress(address newAddress) public onlyOwner() {
        stitchedPunksShopAddress = newAddress;
    }

    // metadata for NFT
    string public metadataBaseUri = "https://stitchedpunks.com/metadata/";

    function setMetadataBaseUri(string memory newUri) public onlyOwner() {
        _setBaseURI(newUri);
    }

    // metadata for NFT: override from ERC721
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        // fetch token URI (returns e.g. "https://stitchedpunks.com/metadata/1234")
        string memory currentUri = ERC721.tokenURI(tokenId);

        // append ".json" (results e.g. in "https://stitchedpunks.com/metadata/1234.json")
        // returns empty string if no tokenURI exists (e.g. if no baseUri was set)
        return bytes(currentUri).length > 0 ? string(abi.encodePacked(currentUri, ".json")) : "";
    }

    // metadata for contract
    function contractURI() public view returns (string memory) {
        // returns e.g. "https://stitchedpunks.com/metadata/StitchedPunksNFT.json"
        return string(abi.encodePacked(baseURI(), "StitchedPunksNFT.json"));
    }

    // token minting
    function mintToken(uint16 punkIndex, address receiverAddress) external onlyOwner() {
        // mint token and send to receiverAddress
        _safeMint(receiverAddress, punkIndex);

        // connect to StitchedPunksShop contract instance and update punk order
        // this also makes sure that the punk was already ordered
        IStitchedPunksShop(stitchedPunksShopAddress).updateOrderRedeemNFT(punkIndex);
    }
}