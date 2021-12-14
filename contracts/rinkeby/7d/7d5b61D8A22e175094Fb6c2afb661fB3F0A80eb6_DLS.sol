// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "ERC721.sol";
import "Ownable.sol";


contract DLS is ERC721, Ownable {

    string internal baseTokenURI = "https://storage.googleapis.com/dls-keys/metadata/";
    uint public presalePrice = 0.05 ether;
    uint public increasePrice = 0.0003 ether;
    uint public totalSupply = 10000;
    uint public presaleSupply = 1000;
    uint public nonce = 0;
    uint public maxTx = 10;

    bool public saleActive = false;
    bool public presaleActive = false;

    event Mint(address owner, uint qty);

    modifier onlyHolder() {
        require(balanceOf(_msgSender()) > 0, "Only holder");
        _;
    }

    constructor() ERC721("Digital Landowners Society KEY", "DLS") public {}

    function setPresaleActive(bool val) public onlyOwner {
        presaleActive = val;
    }

    function setSaleActive(bool val) public onlyOwner {
        saleActive = val;
    }

    function setMaxTx(uint newMax) external onlyOwner {
        maxTx = newMax;
    }

    function setBaseTokenURI(string calldata _uri) external onlyOwner {
        baseTokenURI = _uri;
    }

    function _baseURI() internal override view returns (string memory) {
        return baseTokenURI;
    }

    function calculatePrice(uint qty) internal returns (uint) {
        uint totalPrice = 0;
        for (uint i = 0; i < qty; i++) {
            uint tokenId = nonce + i;
            if (tokenId <= presaleSupply) {
                totalPrice += presalePrice;
            } else {
                totalPrice += presalePrice + (presaleSupply - tokenId) * increasePrice;
            }
        }
        return totalPrice;
    }

    function presale(uint qty) external payable {
        require(qty <= maxTx || qty < 1, "TRANSACTION: qty of mints not allowed");
        require(presaleActive, "TRANSACTION: Presale is not active");
        require(qty + nonce <= presaleSupply, "SUPPLY: Value exceeds presale supply");
        uint totalPrice = qty * presalePrice;
        require(msg.value == totalPrice, "PAYMENT: invalid value");
        for (uint i = 0; i < qty; i++) {
            nonce++;
            uint tokenId = nonce;
            _safeMint(msg.sender, tokenId);
        }
        emit Mint(msg.sender, qty);
    }

    function mint(uint qty) external payable onlyHolder {
        require(qty <= maxTx || qty < 1, "TRANSACTION: qty of mints not allowed");
        require(qty + nonce <= totalSupply, "SUPPLY: Value exceeds totalSupply");
        require(saleActive, "TRANSACTION: sale is not active");
        uint totalPrice = calculatePrice(qty);
        require(msg.value == totalPrice, "PAYMENT: invalid value");
        for (uint i = 0; i < qty; i++) {
            nonce++;
            uint tokenId = nonce;
            _safeMint(msg.sender, tokenId);
        }
        emit Mint(msg.sender, qty);
    }
}