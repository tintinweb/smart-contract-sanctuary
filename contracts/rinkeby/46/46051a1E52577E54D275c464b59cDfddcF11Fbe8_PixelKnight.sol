// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ReentrancyGuard.sol";
import "./SafeMath.sol";
import "./Ownable.sol";


contract PixelKnight is ERC721, ERC721Enumerable, Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    string public baseURI;
    uint256 public mintPrice = 0.0333 ether;

    uint256 public constant maxSupply = 10000;
    uint256 private _reserved = 250;
    bool private _saleStarted = false;

    modifier reqSaleStarted() {
        require(_saleStarted, "Sale has not been started.");
        _;
    }

    function toggleStatus() external onlyOwner {
        _saleStarted = !_saleStarted;
    }

    function setBaseURI(string memory _URI) external onlyOwner {
        baseURI = _URI;
    }

    function _baseURI() internal view override(ERC721) returns(string memory) {
        return baseURI;
    }

    function withdraw() public onlyOwner {
        uint256 _balance = address(this).balance;
        require(payable(owner()).send(_balance));
    }

    function setMintPrice(uint256 price) external onlyOwner {
        mintPrice = price;
    }
    function getMintPrice() public view returns (uint256){
        return mintPrice;
    }

    function getSaleStarted() public view returns (bool) {
        return _saleStarted;
    }

    function mint(uint256 _nTokens) public payable nonReentrant reqSaleStarted {
        uint256 supply = totalSupply();
        require(_nTokens < 21, "You cannot mint more than 20 Tokens at once!");
        require(supply + _nTokens <= maxSupply - _reserved, "Not enough Tokens left.");
        require(_nTokens * mintPrice <= msg.value, "Inconsistent amount sent!");

        for (uint256 i; i < _nTokens; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

    function claimReserved(uint256 _number, address _receiver) external onlyOwner {
        require(_number <= _reserved, "That would exceed the max reserved.");

        uint256 _tokenId = totalSupply();
        for (uint256 i; i < _number; i++) {
            _safeMint(_receiver, _tokenId + i);
        }

        _reserved = _reserved - _number;
    }

    function getReservedLeft() public view returns (uint256) {
        return _reserved;
    }

    function walletOfOwner(address _owner) public view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for(uint256 i; i < tokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    constructor() ERC721("Pixel Knights", "PixelKnights") {}
}