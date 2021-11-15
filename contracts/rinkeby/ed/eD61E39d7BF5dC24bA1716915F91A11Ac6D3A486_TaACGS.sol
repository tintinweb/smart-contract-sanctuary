// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./ECDSA.sol";
import "./Strings.sol";

contract TaACGS is ERC721Enumerable, Ownable {

    string public baseURI = "https://acg.ta2games.com/metadata/";

    uint256 public maxSupply = 8888;

    uint256 public publicSalePrice = 0.075 ether;
    bool public publicSaleEnable;
    uint256 public publicSaleMaxForOneWallets = 20;
    mapping(address => uint256) public publicSalePerWalletCounts;

    bool public presaleEnable;
    uint256 public presalePrice = 0.065 ether;
    uint256 public presaleTotals = 2000;
    uint256 public presaleMaxForOneWallets = 5;
    bool public presaleWhiteListEnables = true;
    address public presaleWhiteListVerifyAdr;
    mapping(address => uint256) public presalePerWalletCounts;

    constructor() ERC721("Sakura Women's Academy", "SWA") {   }

    function setBaseURI(string memory newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
    }
    
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function reclaimEther() external onlyOwner {
//        payable(owner()).transfer(address(this).balance);
        (bool success,) = owner().call{value: address(this).balance}("");
        require(success, "Failed to reclaimEther");
    }
    
    modifier whenPreSaleOpen() {
        require (presaleEnable, "presale is not open");
        _;
    }

    modifier whenPublicSaleOpen() {
        require (publicSaleEnable, "public sale is not open");
        _;
    }

    function setMaxSupply(uint256 supply) external onlyOwner {
        maxSupply = supply;
    }

    function setPreSalePrice(uint256 price) external onlyOwner {
        presalePrice = price;
    }

    function setPreSaleTotal(uint256 total) external onlyOwner {
        presaleTotals = total;
    }

    function setPreSaleMaxForOneWallet(uint256 limit) external onlyOwner {
        presaleMaxForOneWallets = limit;
    }

    function setPreSaleWhiteListEnable(bool whiteListEnable) external onlyOwner {
        presaleWhiteListEnables = whiteListEnable;
    }

    function setPreSaleWhiteListVerifyAdr(address whiltelistVerifyAdr) external onlyOwner {
        presaleWhiteListVerifyAdr = whiltelistVerifyAdr;
    }

    function trogglePreSale() external onlyOwner {
        presaleEnable = !presaleEnable;
    }

    function togglePublicSale() external onlyOwner {
        publicSaleEnable = !publicSaleEnable;
    }

    function setPublicSalePrice(uint256 price) external onlyOwner {
        publicSalePrice = price;
    }

    function setPublicSaleMaxForOneWallets(uint256 count) external onlyOwner {
        publicSaleMaxForOneWallets = count;
    }

    function giveawayMint(address[] memory winners) external onlyOwner {
        uint256 supply = totalSupply();
        uint256 count = winners.length;
        require(supply + count <= maxSupply, "Giveaway failed: Exceeds maximum");

        for (uint256 i = 0; i < count; i++) {
            _safeMint(winners[i], supply + i);
        }
    }

    function preSaleMint(uint256 count, uint256 timestamp, bytes memory sign) external payable whenPreSaleOpen {
        uint256 supply = totalSupply();
        
        require(supply + count <= presaleTotals, "Presale failed: Exceeds maximum");
        require(presalePerWalletCounts[msg.sender] + count <= presaleMaxForOneWallets, "Presale failed: you have too much in presale");
        require(msg.value >= presalePrice * count, "Presale failed: no enough ether");

        if(presaleWhiteListEnables) {
            require(_preSaleCheckSign(timestamp, msg.sender, sign), "Presale failed: whitelist sign failed");
        }

        for(uint256 i = 0; i < count; i++) {
            _safeMint(msg.sender, supply + i);
            presalePerWalletCounts[msg.sender]++;
        }
    }

    function _preSaleCheckSign(uint256 timestamp, address sender, bytes memory sign) private view returns (bool) {
        bytes32 messagesign = keccak256(abi.encodePacked(symbol(), Strings.toString(timestamp), sender));
        return ECDSA.recover(ECDSA.toEthSignedMessageHash(messagesign), sign) == presaleWhiteListVerifyAdr;
    }

    function publicSaleMint(uint256 count) external payable whenPublicSaleOpen {
        uint256 supply = totalSupply();
        require(publicSalePerWalletCounts[msg.sender] + count <= publicSaleMaxForOneWallets, "Public failed: max for user limit");
        require(supply + count <= maxSupply, "Public sale failed: Exceeds maximum");
        require(msg.value >= publicSalePrice * count, "Public sale failed: no enough ether");

        for(uint256 i = 0; i < count; i++) {
            _safeMint(msg.sender, supply + i);
            publicSalePerWalletCounts[msg.sender]++;
        }
    }
}