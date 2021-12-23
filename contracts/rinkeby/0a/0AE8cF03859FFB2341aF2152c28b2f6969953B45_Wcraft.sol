// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";

contract Wcraft is ERC721, Ownable {

    uint256 public currentSupply;
    string public baseTokenURI;
    string public contractURI;
    bool public saleIsActive = false;
    uint256 public tokenPrice = 0.00 ether;
    uint8 public maxMint = 20; // 8bit 0-255
    mapping(uint256 => string) _tokens;

    constructor(string memory _baseTokenURI) ERC721("WitchCraft", "WCraft") {
        setBaseURI(_baseTokenURI);
    }

    function _burn(uint256 tokenId) internal override(ERC721) {
        super._burn(tokenId);
    }

    function totalSupply() public view returns (uint256) {
        return currentSupply;
    }

    function mint(address _to, uint _quantity, string memory _id) external payable {
        if (msg.sender != owner()) {
            require(saleIsActive, "Sale must be active to mint Item");
            require(_quantity > 0 && _quantity <= maxMint, "You can only mint 1 to 20 Item");
            require(msg.value >= tokenPrice * _quantity, "Ether sent is not correct");
            require(totalSupply() >= 0, "Ether sent is not correct");
        }

        for (uint i = 1; i <= _quantity; i++) {
            _tokens[currentSupply] = _id;
            _safeMint(_to, currentSupply);
            currentSupply++;
        }
    }

    function tokensOfOwner(address _owner) external view returns (string[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        if (tokenCount == 0) {
            return new string[](0);
        } else {
            string[] memory result = new string[](tokenCount);
            uint256 index = 0;

            for (uint i = 0; i < tokenCount; i++) {
                if (ownerOf(i) == _owner) {
                    result[index] = _tokens[i];
                    index++;
                }
            }

            return result;
        }
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "URI query for nonexistent token");

        return _tokens[tokenId];
    }

    function setTokenPrice(uint256 _tokenPrice) public onlyOwner() {
        tokenPrice = _tokenPrice;
    }

    function setBaseURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function setMaxMint(uint8 _maxMint) public onlyOwner() {
        maxMint = _maxMint;
    }

    function flipSaleState(bool _saleIsActive) external onlyOwner {
        saleIsActive = _saleIsActive;
    }

    function withdraw(uint256 _amount) public payable onlyOwner {
        require(payable(msg.sender).send(_amount));
    }

    function withdrawAll() public payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }
}