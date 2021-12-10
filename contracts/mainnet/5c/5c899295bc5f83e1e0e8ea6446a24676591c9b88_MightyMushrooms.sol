// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721.sol";
import "./ERC721Enumerable.sol";

/**
 * @title Mighty Mushrooms contract
 */
contract MightyMushrooms is ERC721Enumerable, Ownable {
    using Strings for uint256;
    
    string public baseURI;
    uint256 public cost = 0.02 ether;
    uint256 public constant MAX_SUPPLY = 10000;
    uint256 public constant RESERVED_COUNT = 200;
    uint256 public maxMintAmount = 5;
    uint256 public reservedTokensMinted = 0;
    bool public paused = false;

    constructor(string memory _initBaseURI) ERC721("Mighty Mushrooms", "MIMU") {
        setBaseURI(_initBaseURI);
    }
    
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }
    
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory base = _baseURI();
        return bytes(base).length > 0 ? string(abi.encodePacked(base, tokenId.toString(), ".json") ) : "";
    }
    
    function accountTokensList(address _owner) public view returns (uint256[] memory) {
        uint256 ownerTokenCount  = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }
    
    function mint(address _to, uint256 _mintAmount) public payable {
        uint256 supply = totalSupply();
        require(!paused, "Sale must be active");
        require(_mintAmount > 0, "Invalid quantity");
        require(_mintAmount <= maxMintAmount, "Only 5 Mushrooms at a time");
        require(supply + _mintAmount <= MAX_SUPPLY - (RESERVED_COUNT - reservedTokensMinted), "Purchase would exceed max supply");
        
        if (msg.sender != owner()) {
            require(msg.value >= cost * _mintAmount);
        }
        
        for (uint256 i = 1; i <= _mintAmount; i++) {
            _safeMint(_to, supply + i);
        }
    }

    function mintReserved(uint256 _mintAmount) external onlyOwner {
        uint256 supply = totalSupply();
        require(reservedTokensMinted + _mintAmount <= RESERVED_COUNT, "Amount is more than max allowed");

        for (uint256 i = 1; i <= _mintAmount; i++) {
            _safeMint(owner(), supply + i);
            reservedTokensMinted++;
        }
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }
    
    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }
    
    function setMaxMintAmount(uint256 _newMaxMintAmount) public onlyOwner() {
        maxMintAmount = _newMaxMintAmount;
    }

    function pause(bool _state) public onlyOwner {
        paused = _state;
    }

    function withdraw() public payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }
}