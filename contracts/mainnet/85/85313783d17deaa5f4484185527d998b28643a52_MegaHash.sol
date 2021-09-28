// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

contract MegaHash is ERC721Enumerable, Ownable {
    using Strings for uint256;
    using SafeMath for uint256;

    string public baseURI;
    uint256 public maxSupply = 10000;
    uint256 public maxMintAmount = 10;
    bool public paused = false;

    uint256 public SINGLE_PRICE = 40000000000000000; // 0.04 ether
    uint256 public FIVE_PRICE = 30000000000000000; // 0.03 ether
    uint256 public TEN_PRICE = 20000000000000000; // 0.02 ether

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI
    ) ERC721(_name, _symbol) {
        setBaseURI(_initBaseURI);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function calculatePrice(uint256 _mintAmount) public view returns (uint256) {
        require(_mintAmount == 1 || _mintAmount == 5 || _mintAmount == 10, "Mint amount must be either 1, 5, or 10");
        uint256 tokenPrice = SINGLE_PRICE;

        if (_mintAmount == 5) {
            tokenPrice = FIVE_PRICE;
        } else if (_mintAmount == 10) {
            tokenPrice = TEN_PRICE;
        }
        return tokenPrice;
    }

    function mint(address _to, uint256 _mintAmount) public payable {
        uint256 supply = totalSupply();
        require(!paused, "Sale hasn't started");
        require(_mintAmount > 0 && _mintAmount <= maxMintAmount, "You can get no fewer than 1, and no more than 10 tickets at a time");
        require(supply + _mintAmount <= maxSupply, "Not enough tickets available");
        require(msg.value >= SafeMath.mul(calculatePrice(_mintAmount), _mintAmount), "Amount of Ether sent is not correct");

        for (uint256 i = 1; i <= _mintAmount; i++) {
            _safeMint(_to, supply + i);
        }
    }

    function walletOfOwner(address _owner) public view returns (uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner() {
        maxMintAmount = _newmaxMintAmount;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function pause(bool _state) public onlyOwner {
        paused = _state;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}