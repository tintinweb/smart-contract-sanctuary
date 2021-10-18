// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract NFTPlayground is ERC721, ERC721Enumerable {
    
    event SetContractURI(address indexed from, string uri);
    event SetBaseURI(address indexed from, string uri);
    event SetCustomTokenURI(address indexed from, uint256 indexed tokenId, string customTokenURI);
    event SetOptionalText(address indexed from, uint256 indexed tokenId, string optionalText);
    event Widthdraw(address indexed from);
    
    address payable public owner;
    string public contractURI;
    string public baseURI;
    mapping(uint256 => string) internal customTokenURIs;
    mapping(uint256 => string) internal optionalTexts;
    address public osRegistryAddress;
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only Owner");
        _;
    }

    modifier onlyTokenOwner(uint256 tokenId) {
        require(_exists(tokenId), "Token Not Exist");
        require(ownerOf(tokenId) == msg.sender, "Only Token Owner");
        _;
    }
    
    constructor() ERC721("NFT Playground", "NFTP") {
        owner = payable(0xEb7a77bA2046F3204071E78dbEb3Dd7520C353F7);
        contractURI = "https://nft.playground.io/meta/contract";
        baseURI = "https://nft.playground.io/meta/token/";
        osRegistryAddress = 0xa5409ec958C83C3f309868babACA7c86DCB077c1;
    }
    
    function isApprovedForAll(address _owner, address _operator) public view override returns (bool isOperator) {
        ProxyRegistry proxyRegistry = ProxyRegistry(osRegistryAddress);
        if (address(proxyRegistry.proxies(_owner)) == _operator) {
            return true;
        }
        return super.isApprovedForAll(_owner, _operator);
    } 
     
    function setOwner(address payable newOwner) external onlyOwner {
        require(newOwner != address(0x0));
        owner = newOwner;
    }

    function setOsRegistryAddress(address payable newOsRegistryAddress) external onlyOwner {
        require(newOsRegistryAddress != address(0x0));
        osRegistryAddress = newOsRegistryAddress;
    }

    function setContractURI(string memory newContractURI) external onlyOwner {
        contractURI = newContractURI;
        emit SetContractURI(msg.sender, contractURI);
    }
    
    function setBaseURI(string memory newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
        emit SetBaseURI(msg.sender, baseURI);
    }
    
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
    
    function setCustomTokenURI(uint256 tokenId, string memory newCustomTokenURI) external onlyTokenOwner(tokenId) {
        customTokenURIs[tokenId] = newCustomTokenURI;
        emit SetCustomTokenURI(msg.sender, tokenId, newCustomTokenURI);
    }
    
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory customTokenURI = customTokenURIs[tokenId];
        return bytes(customTokenURI).length > 0 ? customTokenURI : super.tokenURI(tokenId);
    }
    
    function setOptionalText(uint256 tokenId, string memory newOptionalText) external onlyTokenOwner(tokenId) {
        optionalTexts[tokenId] = newOptionalText;
        emit SetOptionalText(msg.sender, tokenId, newOptionalText);
    }
    
    function optionalText(uint256 tokenId) public view virtual returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: Text query for nonexistent token");
        return optionalTexts[tokenId];
    }
    
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }
    
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
    
    function withdraw() external onlyOwner {
        require(address(this).balance > 0, "Not Enough Balance In Contract");
        (bool success, ) = owner.call{value: address(this).balance}("");
        require(success, "Transfer Failed");
        emit Widthdraw(msg.sender);
    }
    
    function mint(uint256 tokenId) external {
        _mint(msg.sender, tokenId);
    }
    
    function burn(uint256 tokenId) external {
        _burn(tokenId);
    }

    receive() external payable {}
}