// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract NFT is ERC721Enumerable, Ownable {
    using Strings for uint256;

    uint256 public  COST_ONE = 0.05 ether;
    uint256 public  WHITE_ONE = 0.033 ether;

    uint256 public  MAX_WHITE_SUPPLY = 333;
    uint256 public  MAX_SUPPLY = 3333;
    uint256 public  MAX_MINT = 20;
    uint256 public  MAX_WHITE_MINT =2;

    bool public isActive = false;
    bool public isWhitelistActive = false;
    address public moneyAddress = 0xA6F0F3481c0990d5bfEDD9E2E74602B8C19C57eD;
    string private _baseTokenURI = "";

    mapping(address => bool) private _whitelist;
    mapping(address => uint256) private _whitelistClaimed;
    uint256 public totalWhiteSupply;

    constructor(string memory name, string memory symbol, string memory baseURI) ERC721(name, symbol) {
        setBaseURI(baseURI);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }
    
    function setBaseURI(string memory val) public onlyOwner {
        _baseTokenURI = val;
    }  

    function setCOST_ONE(uint256 val) external onlyOwner {
        COST_ONE = val;
    }
    function setWHITE_ONE(uint256 val) external onlyOwner {
        WHITE_ONE = val;
    }

    function setMAX_WHITE_SUPPLY(uint256 val) external onlyOwner {
        MAX_WHITE_SUPPLY = val;
    }

    function setMAX_SUPPLY(uint256 val) external onlyOwner {
        MAX_SUPPLY = val;
    }

    function setMAX_MINT(uint256 val) external onlyOwner {
        MAX_MINT = val;
    }

    function setMAX_WHITE_MINT(uint256 val) external onlyOwner {
        MAX_WHITE_MINT = val;
    }

    function setMoneyAddress(address addr) external onlyOwner {
        moneyAddress = addr;
    }

    function setActive(bool val) external onlyOwner {
        isActive = val;
    }

    function setWhitelistActive(bool val) external onlyOwner {
        require(bytes(_baseTokenURI).length != 0,"Set Base URI before activating");
        isWhitelistActive = val;
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
        require(_whitelistClaimed[msg.sender] + num <= MAX_WHITE_MINT," Free whitelist tokens already claimed");
        require(totalSupply() <= MAX_SUPPLY, "All tokens minted");
        require(totalWhiteSupply+num <= MAX_WHITE_SUPPLY, "Over max public limit");
        require(WHITE_ONE * num <= msg.value, "ETH amount is not correct");
        uint256 i = 0;
        for (; i < num; i++) {           
            _safeMint(msg.sender, totalSupply());
        }
        totalWhiteSupply += i;
        _whitelistClaimed[msg.sender] += i;
    }

     function gift(address to, uint256 num) external onlyOwner {
        require(totalSupply() <= MAX_SUPPLY, "All tokens minted");   
        for (uint256 i = 0; i < num; i++) {
            _safeMint(to, totalSupply());
        }
    }

    function mint(uint256 num) external payable {
        require(isActive, "Contract is inactive");
        require(totalSupply() <= MAX_SUPPLY, "All tokens minted");
        require(num <= MAX_MINT,"You cannot mint more than 20 Tokens,Over limit");
        require(msg.value >= COST_ONE * num, "ETH sent is not correct");
        for (uint256 i=0; i < num; i++) {             
            _safeMint(msg.sender, totalSupply());
        }
    }

    function withdraw() public payable onlyOwner {
         uint256 balance = address(this).balance;
        // payable(msg.sender).transfer(balance);
        require(payable(moneyAddress).send(balance));
    }
}