// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./Counters.sol";

contract Wcraft is ERC721, ERC721URIStorage, ERC721Enumerable, Ownable, Pausable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    string public baseTokenURI;
    string public contractURI;
    bool public saleIsActive = false;
    uint256 public tokenPrice = 0.01 ether;
    uint8 public maxMint = 20; // 8bit 0-255
    uint16 public constant MAX_TOKENS_COUNT = 10000; // 16 bit 0 to 65,535

    constructor(string memory _baseTokenURI, string memory _contractURI) ERC721("WitchCraft", "WCraft") {
        setBaseURI(_baseTokenURI);
        setContractURI(_contractURI);

        pause();
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function totalSupply() public view override returns (uint256) {
        return _tokenIdCounter.current();
    }

    function mint(address _to, uint _quantity) public payable {
        if (msg.sender != owner()) {
            require(saleIsActive, "Sale must be active to mint Item");
            require(_quantity > 0 && _quantity <= maxMint, "You can only mint 1 to 20 Item");
            require(msg.value >= tokenPrice * _quantity, "Ether sent is not correct");
        }

        require(totalSupply() + _quantity <= MAX_TOKENS_COUNT, "Exceeds maximum supply");

        for (uint i = 1; i <= _quantity; i++) {
            uint mintIndex = totalSupply();
            _safeMint(_to, mintIndex);
            _tokenIdCounter.increment();
        }
    }

    function walletOfOwner(address _owner) public view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);

        for (uint256 i; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }

        return tokensId;
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");

        return super.tokenURI(tokenId);
    }

    function setBaseURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function setContractURI(string memory _contractURI) public onlyOwner {
        contractURI = _contractURI;
    }

    function setTokenPrice(uint256 _tokenPrice) public onlyOwner() {
        tokenPrice = _tokenPrice;
    }

    function setMaxMint(uint8 _maxMint) public onlyOwner() {
        maxMint = _maxMint;
    }

    function flipSaleState(bool _saleIsActive) external onlyOwner {
        saleIsActive = _saleIsActive;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function start() public onlyOwner {
        _unpause();
    }

    function withdraw(uint256 _amount) public payable onlyOwner {
        require(payable(msg.sender).send(_amount));
    }

    function withdrawAll() public payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }

    function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721, ERC721Enumerable)
    returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
    internal
    whenNotPaused
    override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }
}