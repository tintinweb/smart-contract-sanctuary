// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract RGBlocks is ERC721Enumerable, Ownable {
    using Strings for uint256;
    
    address private _fyseAddress = 0x8A40dC0F722480D3292073154484444D2f882d36;
    address private _xenoAddress = 0x1e5C57CeDe8Aa8EB56b23E2bcAE17b64254A41a5;
    
    uint256 public constant MAX_SUPPLY = 4096;
    uint256 public constant RGBLOCK_PRICE = 0.01 ether;
    uint256 public constant MAX_MINT_PER_TX = 5;

    string private _contractURI;
    string private _tokenBaseURI;
    string private _defaultBaseURI;
    
    bool public saleStatus;

    constructor() ERC721("RGBlocks", "RGBL") {}

    function mint(uint256 tokenQuantity) external payable {
        require(saleStatus, "Sale is not currently live");
        require(totalSupply() < MAX_SUPPLY, "All RGBlocks have been minted");
        require(totalSupply() + tokenQuantity <= MAX_SUPPLY, "Minting that many would exceed the max supply");
        require(tokenQuantity <= MAX_MINT_PER_TX, "You can only a maximum of 5 RGBlocks per transaction");
        require(RGBLOCK_PRICE * tokenQuantity <= msg.value, "You have sent an insufficient ETH amount");
        
        for(uint256 i = 0; i < tokenQuantity; i++) {
            _safeMint(msg.sender, totalSupply() + 1);
        }
    }

    function withdraw() external onlyOwner {
        (bool sentFyse, bytes memory _data) = payable(_fyseAddress).call{value: address(this).balance * 1 / 2}("");
        (bool sentXeno, bytes memory __data) = payable(_xenoAddress).call{value: address(this).balance}("");
        require(sentFyse, "Failed sending fyse");
        require(sentXeno, "Failed sending xeno");
    }
    
    function isSaleActive() external view returns (bool) {
        return saleStatus;
    }
    
    function toggleSaleStatus() external onlyOwner {
        saleStatus = !saleStatus;
    }
    
    function setContractURI(string calldata URI) external onlyOwner {
        _contractURI = URI;
    }
    
    function setBaseURI(string calldata URI) external onlyOwner {
        _tokenBaseURI = URI;
    }
    
    function setDefaultBaseURI(string calldata URI) external onlyOwner {
        _defaultBaseURI = URI;
    }
    
    function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
        require(_exists(tokenId), "Cannot query non-existent token");
        return bytes(_tokenBaseURI).length > 0 ? string(abi.encodePacked(_tokenBaseURI, tokenId.toString())) : _defaultBaseURI;
    }
    
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }
}