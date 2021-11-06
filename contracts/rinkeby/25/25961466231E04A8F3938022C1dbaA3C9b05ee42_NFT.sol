// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract NFT is ERC721Enumerable, Ownable {
    using Strings for uint256;

    uint256 public  COST_ONE = 0.05 ether;
    uint256 public  whitelistCost = 0.033 ether;

    uint256 public  MAX_MINT = 20;
    uint256 public  MAX_PRIVATE_SUPPLY = 33;
    uint256 public  MAX_PUBLIC_SUPPLY = 333;
    uint256 public  MAX_SUPPLY = 3333;
    uint256 public  publicMaxMint = 20;
    uint256 public  whitelistMaxMint = 5;

    function setCOST_ONE(uint256 val) external onlyOwner {
        COST_ONE = val;
    }
    function setWhitelistCost(uint256 val) external onlyOwner {
        whitelistCost = val;
    }
    function setMAX_MINT(uint256 val) external onlyOwner {
        MAX_MINT = val;
    }
    function setMAX_PRIVATE_SUPPLY(uint256 val) external onlyOwner {
        MAX_PRIVATE_SUPPLY = val;
    }
    function setMAX_PUBLIC_SUPPLY(uint256 val) external onlyOwner {
        MAX_PUBLIC_SUPPLY = val;
    }
    function setPublicMaxMint(uint256 val) external onlyOwner {
        publicMaxMint = val;
    }

    function setMAX_SUPPLY(uint256 val) external onlyOwner {
        MAX_SUPPLY = val;
    }
 
    address public money = 0xA6F0F3481c0990d5bfEDD9E2E74602B8C19C57eD;

    bool public isActive = false;
    bool public isWhitelistActive = false;

    uint256 public totalGiftSupply;
    uint256 public totalWhiteSupply;

    string private _baseTokenURI = "";
    mapping(address => uint256) private _publicClaimed;
    mapping(address => bool) private _whitelist;
    mapping(address => uint256) private _whitelistClaimed;

   constructor(string memory name, string memory symbol, string memory baseURI) ERC721(name, symbol) {
        setBaseURI(baseURI);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }
    
    function setBaseURI(string memory val) public onlyOwner {
        _baseTokenURI = val;
    }
    
    function setWhitelistActive(bool val) external onlyOwner {
        isWhitelistActive = val;
    }

    function setWhitelistMaxMint(uint256 val) external onlyOwner {
        whitelistMaxMint = val;
    }

    function addToWhitelist(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            _whitelist[addresses[i]] = true;
        }
    }

    function removeFromWhitelist(address[] calldata addresses) external onlyOwner{
        for (uint256 i = 0; i < addresses.length; i++) {
            require(addresses[i] != address(0), "Can't remove the null address");
            _whitelist[addresses[i]] = false;
        }
    }
    
    function addToWhite(address addresses) external onlyOwner {
            _whitelist[addresses] = true;
    }

    function removeToWhite(address addresses) external onlyOwner {
            _whitelist[addresses] = false;
    }

    function isOnWhitelist(address addr) external view returns (bool) {
        return _whitelist[addr];
    }

    function whitelistClaimedBy(address owner) external view returns (uint256) {
        require(owner != address(0), "Zero address not claimable");
        return _whitelistClaimed[owner];
    }

    function whitelistFreeMint(uint256 num) external payable {
        require(isWhitelistActive, "Whitelist is not active");
        require(_whitelist[msg.sender], "You are not on the Whitelist");
        require(num < whitelistMaxMint + 1, "Over max limit");
        require(
            _whitelistClaimed[msg.sender] + num < whitelistMaxMint + 1,
            " Free whitelist tokens already claimed"
        );
        require(totalSupply() < MAX_SUPPLY, "All tokens minted");
        require(totalWhiteSupply < MAX_PUBLIC_SUPPLY, "Over max public limit");
        require(whitelistCost * num <= msg.value, "ETH amount is not correct");

        for (uint256 i = 0; i < num; i++) {           
            totalWhiteSupply += 1;
            _whitelistClaimed[msg.sender] += 1;
            uint mintIndex = totalSupply();
            _safeMint(msg.sender, mintIndex);
        }
    }

     function gift(address to, uint256 num) external onlyOwner {
        require(totalSupply() < MAX_SUPPLY + 1, "All tokens minted");
        require(
            totalGiftSupply + num < MAX_PRIVATE_SUPPLY + 1,
            "Exceeds private supply"
        );

        for (uint256 i; i < num; i++) {
            totalGiftSupply += 1;
            _safeMint(to, totalGiftSupply);
        }
    }

    function publicClaimedBy(address owner) external view returns (uint256) {
        require(owner != address(0), "Zero address not claimable");
        return _publicClaimed[owner];
    }

    function getCost(uint256 num) public view returns (uint256) {
        return COST_ONE * num;
    }

    function setActive(bool val) external onlyOwner {
        require(
            bytes(_baseTokenURI).length != 0,
            "Set Base URI before activating"
        );
        isActive = val;
    }

    function mint(uint256 num) external payable {
        require(isActive, "Contract is inactive");
        require(num < MAX_MINT + 1, "You cannot mint more than 20 Tokens at once!");
        require(totalSupply() < MAX_SUPPLY, "All tokens minted");
        require(_publicClaimed[msg.sender] + num < publicMaxMint+ 1,"Over public sale max limit");
        require(msg.value >= getCost(num), "ETH sent is not correct");
       
        for (uint256 i; i < num; i++) {
             _publicClaimed[msg.sender] += 1;
            uint mintIndex = totalSupply();
            _safeMint(msg.sender, mintIndex);
        }
    }

    function withdraw() public payable onlyOwner {
         uint256 balance = address(this).balance;
        // payable(msg.sender).transfer(balance);
        require(payable(money).send(balance));
    }
}