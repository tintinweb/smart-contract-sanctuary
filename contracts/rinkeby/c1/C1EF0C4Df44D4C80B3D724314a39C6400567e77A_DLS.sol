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
    bool public allowlistPresaleActive = false;

    mapping(address => uint256) public presaleWallets;

    event Mint(address owner, uint qty);

    modifier onlyHolder() {
        require(balanceOf(_msgSender()) > 0, "Only holder");
        _;
    }

    constructor() ERC721("Digital Landowners Society KEY", "DLS") {}

    function setPresaleWallets(address[] memory _a, uint256[] memory _amount) public onlyOwner {
        for (uint256 i; i < _a.length; i++) {
            presaleWallets[_a[i]] = _amount[i];
        }
    }

    function editPresaleWallets(address[] memory _a, uint256[] memory _amount) public onlyOwner {
        for (uint256 i; i < _a.length; i++) {
            presaleWallets[_a[i]] = _amount[i];
        }
    }

    function setAllowlistPresaleActive(bool val) public onlyOwner {
        allowlistPresaleActive = val;
    }

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

    function calculatePrice(uint qty) internal view returns (uint) {
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


    function allowlistPresale(uint qty) external payable {
        uint256 qtyAllowed = presaleWallets[msg.sender];
        require(allowlistPresaleActive, "TRANSACTION: Presale is not active");
        require(qtyAllowed > 0, "TRANSACTION: You can't mint on presale");
        require(qty + nonce <= presaleSupply, "SUPPLY: Value exceeds presale supply");
        require(msg.value == qty * presalePrice, "PAYMENT: invalid value");
        for (uint i = 0; i < qty; i++) {
            nonce++;
            uint tokenId = nonce;
            _safeMint(msg.sender, tokenId);
        }
    }

    function presale(uint qty) external payable {
        require(qty <= maxTx || qty < 1, "TRANSACTION: qty of mints not allowed");
        require(presaleActive, "TRANSACTION: Presale is not active");
        require(qty + nonce <= presaleSupply, "SUPPLY: Value exceeds presale supply");
        require(msg.value == qty * presalePrice, "PAYMENT: invalid value");
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