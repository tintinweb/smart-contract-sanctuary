// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "./ERC721.sol";
import "./Ownable.sol";

contract Calaveras211 is ERC721, Ownable {
    uint public mintPrice = 0.07 ether;
    uint public maxItems = 10000;
    uint public totalSupply = 0;
    uint public maxItemsPerTx = 10;
    string public _baseTokenURI;
    bool public publicMintPaused = false;
    uint public startTimestamp = 1635868800; // Tuesday, 2 November 2021, 12:00pm EST

    event Mint(address indexed owner, uint indexed tokenId);

    constructor() ERC721("Calaveras 211", "CALAVERA") {}

    receive() external payable {}

    function giveawayMint(address to, uint amount) external onlyOwner {
        _mintWithoutValidation(to, amount);
    }

    function publicMint() external payable {
        require(block.timestamp >= startTimestamp, "Sell is not opened yet");
        require(!publicMintPaused, "Contract is paused");
        uint remainder = msg.value % mintPrice;
        uint amount = msg.value / mintPrice;
        require(remainder == 0, "Send a divisible amount of eth");
        require(amount <= maxItemsPerTx, "Over the maxItemsPerTx");

        _mintWithoutValidation(_msgSender(), amount);
    }

    function _mintWithoutValidation(address to, uint amount) internal {
        require(totalSupply + amount <= maxItems, "All items sold");
        for(uint i = 0; i < amount; i++) {
            _mint(to, totalSupply);
            emit Mint(to, totalSupply);
            totalSupply += 1;
        }
    }

    function isOpen() external view returns (bool) {
        return block.timestamp >= startTimestamp && !publicMintPaused && totalSupply < maxItems;
    }

    function setStartTimestamp(uint _startTimestamp) external onlyOwner {
        startTimestamp = _startTimestamp;
    }

    function setMintPrice(uint _mintPrice) external onlyOwner {
        mintPrice = _mintPrice;
    }

    function setPublicMintPaused(bool _publicMintPaused) external onlyOwner {
        publicMintPaused = _publicMintPaused;
    }

    function setMaxItemsPerTx(uint _maxItemsPerTx) external onlyOwner {
        maxItemsPerTx = _maxItemsPerTx;
    }

    function setBaseTokenURI(string memory __baseTokenURI) external onlyOwner {
        _baseTokenURI = __baseTokenURI;
    }

    function withdraw() external onlyOwner {
        (bool success,) = owner().call{value: address(this).balance}("");
        require(success, "Failed to withdraw");
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        return string(abi.encodePacked(_baseTokenURI, Strings.toString(_tokenId)));
    }
}