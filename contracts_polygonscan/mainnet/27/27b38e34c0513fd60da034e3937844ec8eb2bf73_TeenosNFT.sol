// SPDX-License-Identifier: GPL-3.0

// Created by HashLips
// The Nerdy Coder Clones

pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract TeenosNFT is ERC721Enumerable, Ownable {
    using Strings for uint256;

    string public baseURI;
    string public baseURIExtension = ".json";
    uint256 public cost = 15 ether;
    uint256 public maxSupply = 1000;
    uint256 public maxMintAmount = 20;
    bool public salePaused = false;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI
    ) ERC721(_name, _symbol) {
        setBaseURI(_initBaseURI);
        initialMint(70);
    }

    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    // public
    function mint(uint256 _mintAmount) public payable {
        uint256 totalSupply = totalSupply();
        require(totalSupply < maxSupply, "Max NFT Token Supply Reached!");
        require(!salePaused, "Sale is currently Paused");
        require(_mintAmount > 0, "Mint amount has to be greater then 0");
        require(
            _mintAmount <= maxMintAmount,
            "Mint amount exceeds The Max Mint Amount"
        );
        require(
            totalSupply + _mintAmount <= maxSupply,
            "Mint amount exceeds Max Supply"
        );
        require(
            msg.value >= cost * _mintAmount,
            "Value sent is incorrect, please check the cost amount"
        );

        for (uint256 i = 1; i <= _mintAmount; i++) {
            _safeMint(msg.sender, totalSupply + i);
        }
    }

    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        baseURIExtension
                    )
                )
                : "";
    }

    //only owner
    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }

    function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner {
        maxMintAmount = _newmaxMintAmount;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function pause(bool _state) public onlyOwner {
        salePaused = _state;
    }

    function withdraw() public payable onlyOwner {
        address payable _owner = payable(msg.sender);
        uint256 balance = address(this).balance;
        _owner.transfer(balance);
    }

    function initialMint(uint256 _mintAmount) internal {
        address _owner = owner();
        uint256 totalSupply = totalSupply();
        for (uint256 i = 1; i <= _mintAmount; i++) {
            _safeMint(_owner, totalSupply + i);
        }
    }
}